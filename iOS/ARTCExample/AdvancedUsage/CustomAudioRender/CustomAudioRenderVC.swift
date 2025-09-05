import Foundation
import AliVCSDK_ARTC
import AVFoundation
import AudioToolbox

class CustomAudioRenderSetParamsVC: UIViewController, UITextFieldDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Custom Audio Render".localized
        self.channelIdTextField.delegate = self
    }
    
    // join channel
    @IBOutlet weak var channelIdTextField: UITextField!
    @IBAction func onJoinChannelBtnClicked(_ sender: UIButton) {
        guard let channelId = self.channelIdTextField.text, channelId.isEmpty == false else {
            return
        }
        
        let helper = ARTCTokenHelper()
        let userId = GlobalConfig.shared.userId
        let timestamp = Int64(Date().timeIntervalSince1970 + 24 * 60 * 60)
        let joinToken = helper.generateJoinToken(channelId: channelId, userId: userId, timestamp: timestamp)
        
        let vc = self.presentVC(storyboardName: "CustomAudioRender", storyboardId: "MainVC") as? CustomAudioRenderMainVC
        vc?.channelId = channelId
        vc?.userId = userId
        vc?.joinToken = joinToken
        vc?.isCustomAudioRender = customAudioRenderSwitch.isOn
    }
    
    @IBOutlet weak var customAudioRenderSwitch: UISwitch!
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

class CustomAudioRenderMainVC: UIViewController {
    
    // MARK: - Properties
    @IBOutlet weak var contentScrollView: UIScrollView!
    
    var seatViewList: [SeatView] = []
    
    var channelId: String = ""
    var userId: String = ""
    
    var rtcEngine: AliRtcEngine? = nil

    var joinToken: String? = nil
    
    // Custom Audio Render
    var isCustomAudioRender = true
    let audioSource: AliRtcAudioSource = .playback
    var observerConfig: AliRtcAudioFrameObserverConfig = AliRtcAudioFrameObserverConfig()
    
    // 添加Audio Queue相关属性
    private var audioQueue: AudioQueueRef?
    private var audioQueueBuffers: [AudioQueueBufferRef?] = []
    private var audioStreamDescription: AudioStreamBasicDescription = AudioStreamBasicDescription()
    private var audioQueueBufferUsed: [Bool] = []
    private var audioProcessingQueue: DispatchQueue?
    
    // 信息显示Label
    private var captureInfoLabel: UILabel!
    private var processInfoLabel: UILabel!
    private var publishInfoLabel: UILabel!
    private var prePlaybackInfoLabel: UILabel!
    private var remoteUserInfoLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = self.channelId
        
        self.setup()
        self.startPreview()
        self.joinChannel()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.updateSeatViewsLayout()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.leaveAnddestroyEngine()
    }
    
    func setup() {
        
        // 创建并初始化引擎
        let engine = AliRtcEngine.sharedInstance(self, extras:nil)
        
        // 设置日志级别
        engine.setLogLevel(.info)
        
        // 设置频道模式为互动模式,RTC下都使用AliRtcInteractivelive
        engine.setChannelProfile(AliRtcChannelProfile.interactivelive)
        // 设置用户角色，既需要推流也需要拉流使用AliRtcClientRoleInteractive， 只拉流不推流使用AliRtcClientRolelive
        engine.setClientRole(AliRtcClientRole.roleInteractive)
        
        // 设置音频Profile，默认使用高音质模式AliRtcEngineHighQualityMode及音乐模式AliRtcSceneMusicMode
        engine.setAudioProfile(AliRtcAudioProfile.engineHighQualityMode, audio_scene: AliRtcAudioScenario.sceneMusicMode)
        
        // 设置视频编码参数
        let config = AliRtcVideoEncoderConfiguration()
        config.dimensions = CGSize(width: 720, height: 1280)
        config.frameRate = 20
        config.bitrate = 1200
        config.keyFrameInterval = 2000
        config.orientationMode = AliRtcVideoEncoderOrientationMode.adaptive
        engine.setVideoEncoderConfiguration(config)
        engine.setCapturePipelineScaleMode(.post)
        
        // SDK默认会publish音频，publishLocalVideoStream(true)可以不调用
        engine.publishLocalVideoStream(true)
        // SDK默认会publish视频，如果是视频通话，publishLocalAudioStream(true)可以不调用
        // 如果是纯语音通话 则需要设置publishLocalVideoStream(false)设置不publish视频
        engine.publishLocalAudioStream(true)

        // 设置默认订阅远端的音频和视频流
        engine.setDefaultSubscribeAllRemoteAudioStreams(true)
        engine.subscribeAllRemoteAudioStreams(true)
        engine.setDefaultSubscribeAllRemoteVideoStreams(true)
        engine.subscribeAllRemoteVideoStreams(true)
        
        if isCustomAudioRender {
            // 关闭SDK内部播放
            engine.setParameter("{\"audio\":{\"enable_system_audio_device_play\":\"FALSE\"}}")
            // 开启原始音频数据回调
            engine.enableAudioFrameObserver(true, audioSource: audioSource, config: observerConfig)
            // 注册原始音频数据监听器
            engine.registerAudioFrameObserver(self)
            
            // 初始化音频处理队列
            audioProcessingQueue = DispatchQueue(label: "custom.audio.render.queue", qos: .userInitiated)
            
            // 初始化Audio Queue
            setupAudioPlayer()
        }
        
        self.rtcEngine = engine
    }
    
    // 初始化Audio Queue播放器
    private func setupAudioPlayer() {
        DispatchQueue.main.async { [weak self] in
            self?.setupAudioSessionAndQueue()
        }
    }
    
    private func setupAudioSessionAndQueue() {
        do {
            // 配置音频会话
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
        
        // 初始化音频队列缓冲区状态
        audioQueueBuffers = [nil, nil, nil, nil] // 4个缓冲区
        audioQueueBufferUsed = [false, false, false, false]
        
        // 配置音频流描述（使用默认参数，后续会根据实际音频数据调整）
        audioStreamDescription.mSampleRate = 48000.0
        audioStreamDescription.mFormatID = kAudioFormatLinearPCM
        audioStreamDescription.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked
        audioStreamDescription.mChannelsPerFrame = 1
        audioStreamDescription.mFramesPerPacket = 1
        audioStreamDescription.mBitsPerChannel = 16
        audioStreamDescription.mBytesPerPacket = 2
        audioStreamDescription.mBytesPerFrame = 2
        
        // 创建Audio Queue，使用静态方法作为回调
        let status = AudioQueueNewOutput(&audioStreamDescription, CustomAudioRenderMainVC.audioQueueOutputCallback, Unmanaged.passUnretained(self).toOpaque(), nil, nil, 0, &audioQueue)
        
        if status != noErr {
            print("Failed to create audio queue: \(status)")
            return
        }
        
        // 分配音频缓冲区
        let bufferByteSize: UInt32 = 4096 // 根据音频数据大小调整
        for i in 0..<audioQueueBuffers.count {
            let status = AudioQueueAllocateBuffer(audioQueue!, bufferByteSize, &audioQueueBuffers[i])
            if status != noErr {
                print("Failed to allocate audio queue buffer \(i): \(status)")
            }
        }
        
        // 启动Audio Queue
        let startStatus = AudioQueueStart(audioQueue!, nil)
        if startStatus != noErr {
            print("Failed to start audio queue: \(startStatus)")
        }
    }
    
    func joinChannel() {
        
        // 单参数入会
        if let joinToken = self.joinToken {
            let msg =  "JoinWithToken: \(joinToken)"
            
            let ret = self.rtcEngine?.joinChannel(joinToken, channelId: nil, userId: nil, name: nil) { [weak self] errCode, channelId, userId, elapsed in
                let resultMsg = "\(msg) \n CallbackErrorCode: \(errCode)"
                resultMsg.printLog()
                if errCode != 0 {
                    UIAlertController.showAlertWithMainThread(msg: resultMsg, vc: self!)
                }
            }
            
            let resultMsg = "\(msg) \n ReturnErrorCode: \(ret ?? 0)"
            resultMsg.printLog()
            if ret != 0 {
                UIAlertController.showAlertWithMainThread(msg: resultMsg, vc: self)
            }
            return
        }
    }
    
    func startPreview() {
        let seatView = self.createSeatView(uid: self.userId)
        
        let canvas = AliVideoCanvas()
        canvas.view = seatView.canvasView
        canvas.renderMode = .auto
        canvas.mirrorMode = .onlyFrontCameraPreviewEnabled
        canvas.rotationMode = ._0
        
        self.rtcEngine?.setLocalViewConfig(canvas, for: AliRtcVideoTrack.camera)
        self.rtcEngine?.startPreview()
    }
    
    func leaveAnddestroyEngine() {
        // 停止并释放Audio Queue
        if let audioQueue = self.audioQueue {
            AudioQueueStop(audioQueue, true)
            AudioQueueDispose(audioQueue, true)
            self.audioQueue = nil
        }
        
        self.rtcEngine?.stopPreview()
        self.rtcEngine?.leaveChannel()
        AliRtcEngine.destroy()
        self.rtcEngine = nil
    }
    
    // 创建一个视频通话渲染视图，并加入到contentScrollView中
    func createSeatView(uid: String) -> SeatView {
        let view = SeatView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.uidLabel.text = uid
        
        self.contentScrollView.addSubview(view)
        self.seatViewList.append(view)
        self.updateSeatViewsLayout()
        return view
    }
    
    // 从contentScrollView移除一个视频通话渲染视图
    func removeSeatView(uid: String) {
        let seatView = self.seatViewList.first { $0.uidLabel.text == uid }
        if let seatView = seatView {
            seatView.removeFromSuperview()
            self.seatViewList.removeAll(where: { $0 == seatView})
            self.updateSeatViewsLayout()
        }
    }
    
    // 刷新contentScrollView的子视图布局
    func updateSeatViewsLayout() {
        let count: Int = 2
        let margin = 24.0
        let width = (self.contentScrollView.bounds.width - margin * Double(count + 1)) / Double(count)
        let height = width
        for i in 0..<self.seatViewList.count {
            let view = self.seatViewList[i]
            let x = Double(i % count) * (width + margin) + margin
            let y = Double(i / count) * (height + margin) + margin
            view.frame = CGRect(x: x, y: y, width: width, height: height)
        }
        self.contentScrollView.contentSize = CGSize(width: self.contentScrollView.bounds.width, height: margin + ceil(Double(self.seatViewList.count) / Double(count)) * height + margin)
    }
    
    private func setupInfoLabel() {
        let labelHeight: CGFloat = 60
        let margin: CGFloat = 8
        func createLabel() -> UILabel {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 12)
            label.textColor = .white
            label.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            label.layer.cornerRadius = 6
            label.clipsToBounds = true
            label.textAlignment = .left
            label.translatesAutoresizingMaskIntoConstraints = false
            label.numberOfLines = 3
            label.lineBreakMode = .byWordWrapping
            return label
        }
        
        captureInfoLabel = createLabel()
        processInfoLabel = createLabel()
        publishInfoLabel = createLabel()
        prePlaybackInfoLabel = createLabel()
        remoteUserInfoLabel = createLabel()
        
        captureInfoLabel.text = "Capture: -"
        processInfoLabel.text = "3A -"
        publishInfoLabel.text = "pubish -"
        prePlaybackInfoLabel.text = "prePlayback -"
        remoteUserInfoLabel.text = "remote user -"
        
        self.view.addSubview(captureInfoLabel)
        self.view.addSubview(processInfoLabel)
        self.view.addSubview(publishInfoLabel)
        self.view.addSubview(prePlaybackInfoLabel)
        self.view.addSubview(remoteUserInfoLabel)
        // 布局：垂直排列在顶部 safeArea 下方
        NSLayoutConstraint.activate([
            captureInfoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            captureInfoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            captureInfoLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            captureInfoLabel.heightAnchor.constraint(equalToConstant: labelHeight),

            processInfoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            processInfoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            processInfoLabel.topAnchor.constraint(equalTo: captureInfoLabel.bottomAnchor, constant: margin),
            processInfoLabel.heightAnchor.constraint(equalToConstant: labelHeight),

            publishInfoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            publishInfoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            publishInfoLabel.topAnchor.constraint(equalTo: processInfoLabel.bottomAnchor, constant: margin),
            publishInfoLabel.heightAnchor.constraint(equalToConstant: labelHeight),
            
            prePlaybackInfoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            prePlaybackInfoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            prePlaybackInfoLabel.topAnchor.constraint(equalTo: publishInfoLabel.bottomAnchor, constant: margin),
            prePlaybackInfoLabel.heightAnchor.constraint(equalToConstant: labelHeight),
            
            remoteUserInfoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            remoteUserInfoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            remoteUserInfoLabel.topAnchor.constraint(equalTo: prePlaybackInfoLabel.bottomAnchor, constant: margin),
            remoteUserInfoLabel.heightAnchor.constraint(equalToConstant: labelHeight),
        ])
    }
    
    private func updateInfoLabel(_ label: UILabel, text: String) {
        DispatchQueue.main.async {
            label.text = text
        }
    }
    
    // Audio Queue回调函数 - 静态方法，用于C兼容
    private static let audioQueueOutputCallback: AudioQueueOutputCallback = { (
        userData: UnsafeMutableRawPointer?,
        queue: AudioQueueRef,
        buffer: AudioQueueBufferRef
    ) in
        guard let userData = userData else { return }
        let `self` = Unmanaged<CustomAudioRenderMainVC>.fromOpaque(userData).takeUnretainedValue()
        
        for i in 0..<self.audioQueueBuffers.count {
            if self.audioQueueBuffers[i] == buffer {
                self.audioQueueBufferUsed[i] = false
                break
            }
        }
    }

}

// MARK: 音频数据回调
extension CustomAudioRenderMainVC: AliRtcAudioFrameDelegate {
    func onCapturedAudioFrame(_ frame: AliRtcAudioFrame) -> Bool {
        "onCapturedAudioFrame".printLog()
        return true
    }
    
    func onProcessCapturedAudioFrame(_ frame: AliRtcAudioFrame) -> Bool {
        "onProcessCapturedAudioFrame".printLog()
        return true
    }
    
    func onPublishAudioFrame(_ frame: AliRtcAudioFrame) -> Bool {
        "onPublishAudioFrame".printLog()
        return true
    }
    
    func onPlaybackAudioFrame(_ frame: AliRtcAudioFrame) -> Bool {
        // 在独立线程中处理音频播放，避免阻塞回调线程
        if isCustomAudioRender, let audioProcessingQueue = self.audioProcessingQueue {
            audioProcessingQueue.async { [weak self] in
                self?.playAudioFrameWithAudioQueue(frame)
            }
        }
        return true
    }
    
    func onRemoteUserAudioFrame(_ uid: String?, frame: AliRtcAudioFrame) -> Bool {
        "onRemoteUserAudioFrame".printLog()
        return true
    }
    
    // 使用Audio Queue播放音频帧
    private func playAudioFrameWithAudioQueue(_ frame: AliRtcAudioFrame) {
        guard let audioQueue = self.audioQueue,
              let dataPtr = frame.dataPtr else {
            return
        }
        
        let sampleRate = frame.samplesPerSec
        let channels = frame.numOfChannels
        let bytesPerSample = frame.bytesPerSample
        
        // 校验参数合法性
        guard sampleRate > 0, channels > 0, bytesPerSample > 0 else {
            print("Invalid frame parameters.")
            return
        }
        
        // 计算数据大小
        let byteSize = frame.numOfSamples * channels * bytesPerSample
        guard byteSize > 0 else {
            print("Invalid byte size")
            return
        }
        
        // 更新格式（如有必要）
        updateAudioStreamDescriptionIfNeeded(frame)
        
        // 获取一个可用缓冲区
        var bufferIndex: Int? = nil
        for i in 0..<audioQueueBufferUsed.count {
            if !audioQueueBufferUsed[i] {
                bufferIndex = i
                audioQueueBufferUsed[i] = true
                break
            }
        }
        
        guard let index = bufferIndex,
              let buffer = audioQueueBuffers[index] else {
            print("No available buffer")
            return
        }

        // 如果当前 buffer 太小，重新分配
        if buffer.pointee.mAudioDataByteSize < UInt32(byteSize) {
            AudioQueueFreeBuffer(audioQueue, buffer)
            let status = AudioQueueAllocateBuffer(audioQueue, UInt32(byteSize), &audioQueueBuffers[index])
            if status != noErr {
                print("Failed to reallocate buffer: \(status)")
                audioQueueBufferUsed[index] = false
                return
            }
        }
        
        // 再次确保 buffer 是有效的
        guard let validBuffer = audioQueueBuffers[index] else {
            audioQueueBufferUsed[index] = false
            return
        }

        // 复制数据
        validBuffer.pointee.mAudioDataByteSize = UInt32(byteSize)
        memcpy(validBuffer.pointee.mAudioData, dataPtr, Int(byteSize))

        // 入队
        let enqueueStatus = AudioQueueEnqueueBuffer(audioQueue, validBuffer, 0, nil)
        if enqueueStatus != noErr {
            print("Failed to enqueue buffer: \(enqueueStatus)")
            audioQueueBufferUsed[index] = false
        }
    }

    
    // 更新音频流描述（如果需要）
    private func updateAudioStreamDescriptionIfNeeded(_ frame: AliRtcAudioFrame) {
        let sampleRate = frame.samplesPerSec
        let channels = frame.numOfChannels
        let bytesPerSample = frame.bytesPerSample
        
        // 检查是否需要更新音频流描述
        if Int(audioStreamDescription.mSampleRate) != sampleRate ||
            audioStreamDescription.mChannelsPerFrame != UInt32(channels) ||
            audioStreamDescription.mBytesPerPacket != UInt32(bytesPerSample * channels) {
            
            // 更新音频流描述
            audioStreamDescription.mSampleRate = Double(sampleRate)
            audioStreamDescription.mChannelsPerFrame = UInt32(channels)
            audioStreamDescription.mFramesPerPacket = 1
            audioStreamDescription.mBitsPerChannel = UInt32(bytesPerSample * 8)
            audioStreamDescription.mBytesPerPacket = UInt32(bytesPerSample * channels)
            audioStreamDescription.mBytesPerFrame = UInt32(bytesPerSample * channels)
            
            // 重新配置Audio Queue
            if let audioQueue = self.audioQueue {
                AudioQueueStop(audioQueue, true)
                AudioQueueDispose(audioQueue, true)
            }
            
            setupAudioSessionAndQueue()
        }
    }
}

extension CustomAudioRenderMainVC: AliRtcEngineDelegate {
    
    func onJoinChannelResult(_ result: Int32, channel: String, elapsed: Int32) {
        "onJoinChannelResult1 result: \(result)".printLog()
    }
    
    func onJoinChannelResult(_ result: Int32, channel: String, userId: String, elapsed: Int32) {
        "onJoinChannelResult2 result: \(result)".printLog()
    }
    
    func onRemoteUser(onLineNotify uid: String, elapsed: Int32) {
        // 远端用户的上线
        "onRemoteUserOlineNotify uid: \(uid)".printLog()
    }
    
    func onRemoteUserOffLineNotify(_ uid: String, offlineReason reason: AliRtcUserOfflineReason) {
        // 远端用户的下线
        "onRemoteUserOffLineNotify uid: \(uid) reason: \(reason)".printLog()
    }
    
    
    func onRemoteTrackAvailableNotify(_ uid: String, audioTrack: AliRtcAudioTrack, videoTrack: AliRtcVideoTrack) {
        "onRemoteTrackAvailableNotify uid: \(uid) audioTrack: \(audioTrack)  videoTrack: \(videoTrack)".printLog()
        // 远端用户的流状态
        if audioTrack != .no {
            let seatView = self.seatViewList.first { $0.uidLabel.text == uid }
            if seatView == nil {
                _ = self.createSeatView(uid: uid)
            }
        }
        if videoTrack != .no {
            var seatView = self.seatViewList.first { $0.uidLabel.text == uid }
            if seatView == nil {
                seatView = self.createSeatView(uid: uid)
            }
            
            let canvas = AliVideoCanvas()
            canvas.view = seatView!.canvasView
            canvas.renderMode = .auto
            canvas.mirrorMode = .onlyFrontCameraPreviewEnabled
            canvas.rotationMode = ._0
            self.rtcEngine?.setRemoteViewConfig(canvas, uid: uid, for: AliRtcVideoTrack.camera)
        }
        else {
            self.rtcEngine?.setRemoteViewConfig(nil, uid: uid, for: AliRtcVideoTrack.camera)
        }
        
        if audioTrack == .no && videoTrack == .no {
            self.removeSeatView(uid: uid)
            self.rtcEngine?.setRemoteViewConfig(nil, uid: uid, for: AliRtcVideoTrack.camera)
        }
    }
    
    func onAuthInfoWillExpire() {
        "onAuthInfoWillExpire".printLog()
        
        /* TODO: 务必处理；Token即将过期，需要业务触发重新获取当前channel，user的鉴权信息，然后设置refreshAuthInfo即可 */
    }
    
    func onAuthInfoExpired() {
        "onAuthInfoExpired".printLog()
        
        /* TODO: 务必处理；提示Token失效，并执行离会与释放引擎 */
    }
    
    func onBye(_ code: Int32) {
        "onBye code: \(code)".printLog()
        
        /* TODO: 务必处理；业务可能会触发同一个UserID的不同设备抢占的情况 */
    }
    
    func onLocalDeviceException(_ deviceType: AliRtcLocalDeviceType, exceptionType: AliRtcLocalDeviceExceptionType, message msg: String?) {
        "onLocalDeviceException deviceType: \(deviceType)  exceptionType: \(exceptionType)".printLog()

        /* TODO: 务必处理；建议业务提示设备错误，此时SDK内部已经尝试了各种恢复策略已经无法继续使用时才会上报 */
    }
    
    func onConnectionStatusChange(_ status: AliRtcConnectionStatus, reason: AliRtcConnectionStatusChangeReason) {
        "onConnectionStatusChange status: \(status)  reason: \(reason)".printLog()

        if status == .failed {
            /* TODO: 务必处理；建议业务提示用户，此时SDK内部已经尝试了各种恢复策略已经无法继续使用时才会上报 */
        }
        else {
            /* TODO: 可选处理；增加业务代码，一般用于数据统计、UI变化 */
        }
    }
}
