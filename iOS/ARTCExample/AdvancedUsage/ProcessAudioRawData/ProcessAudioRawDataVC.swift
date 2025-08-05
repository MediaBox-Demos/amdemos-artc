//
//  ProcessAudioRawDataVC.swift
//  ARTCExample
//
//  Created by wy on 2025/7/16.
//

import Foundation
import AliVCSDK_ARTC

// 原始音频数据获取配置
// Audio Raw Frame Config
class AudioRawFrameConfig {
    var enable: Bool // 是否开启
    var observerConfig: AliRtcAudioFrameObserverConfig?
    
    init() {
        self.enable = false
        self.observerConfig = AliRtcAudioFrameObserverConfig()
        self.observerConfig?.channels = .monoAudio
        self.observerConfig?.sampleRate = ._48000
        self.observerConfig?.mode = .readOnly
    }
    
    init(enable: Bool, observerConfig: AliRtcAudioFrameObserverConfig? = nil) {
        self.enable = enable
        self.observerConfig = observerConfig
    }
}

class ProcessAudioRawDataSetParamsVC: UIViewController, UITextFieldDelegate {
    var audioSourceRawFrameConfigs: [AliRtcAudioSource: AudioRawFrameConfig] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Process Audio Raw Data".localized
        self.channelIdTextField.delegate = self
        
        // init audio raw frame config
        // 初始化音频配置
        let audioSourceList: [AliRtcAudioSource] = [.captured, .processCaptured, .pub, .playback, .remoteUser]
        for audioSource in audioSourceList {
            let config = AudioRawFrameConfig()
            audioSourceRawFrameConfigs[audioSource] = config
        }
    }
    // Audio Raw Frame Setting UI
    @IBOutlet weak var captureAudioFrameSwitch: UISwitch!
    @IBAction func onCaptureAudioFrameSwitchToggled(_ sender: UISwitch) {
        guard let config = audioSourceRawFrameConfigs[.captured] else { return }
        handleSwitchToggle(sender, for: .captured, with: config)
    }
    @IBOutlet weak var processAudioFrameSwitch: UISwitch!
    @IBAction func onProcessAudioFrameSwitchToggled(_ sender: UISwitch) {
        guard let config = audioSourceRawFrameConfigs[.processCaptured] else { return }
        handleSwitchToggle(sender, for: .processCaptured, with: config)
    }
    @IBOutlet weak var publishAudioFrameSwitch: UISwitch!
    @IBAction func onPublishAudioFrameSwitchToggled(_ sender: UISwitch) {
        guard let config = audioSourceRawFrameConfigs[.pub] else { return }
        handleSwitchToggle(sender, for: .pub, with: config)
    }
    @IBOutlet weak var playbackAudioFrameSwitch: UISwitch!
    @IBAction func onPlaybackAudioFrameSwitchToggled(_ sender: UISwitch) {
        guard let config = audioSourceRawFrameConfigs[.playback] else { return }
        handleSwitchToggle(sender, for: .playback, with: config)
    }
    @IBOutlet weak var remoteUserAudioFrameSwitch: UISwitch!
    @IBAction func onRemoteUserAudioFrameSwitchToggled(_ sender: UISwitch) {
        guard let config = audioSourceRawFrameConfigs[.remoteUser] else { return }
        handleSwitchToggle(sender, for: .remoteUser, with: config)
    }
    
    private func handleSwitchToggle(_ sender: UISwitch, for source: AliRtcAudioSource, with config: AudioRawFrameConfig) {
        if sender.isOn {
            let configVC = ConfigViewController()
            
            var configData: [ConfigModel] = []
            // 初始化配置界面数据
            switch source {
            case .remoteUser: // 不支持设置通道数和采样率
                configData = [
                    ConfigModel(title: "Read Write Mode".localized, type: .picker, value: {
                        switch config.observerConfig?.mode {
                        case .readOnly: return "Read Only"
                        case .writeOnly: return "Write Only"
                        case .readWrite: return "Read Write"
                        default: return "Read Only"
                        }
                    }(), options: ["Read Only", "Write Only", "Read Write"])
                ]
            case .pub:
                configData = [
                    ConfigModel(title: "Channel Num".localized, type: .segmented, value: config.observerConfig?.channels == .monoAudio ? "Mono" : "Stereo", options: ["Mono", "Stereo"]),
                    ConfigModel(title: "SampleRate".localized, type: .picker, value: "48000", options: ["8000", "16000", "32000", "44100", "48000"]),
                    ConfigModel(title: "Read Write Mode".localized, type: .picker, value: "Read Only", options: ["Read Only"])
                ]
            default:
                configData = [
                    ConfigModel(title: "Channel Num".localized, type: .segmented, value: config.observerConfig?.channels == .monoAudio ? "Mono" : "Stereo", options: ["Mono", "Stereo"]),
                    ConfigModel(title: "SampleRate".localized, type: .picker, value: "48000", options: ["8000", "16000", "32000", "44100", "48000"]),
                    ConfigModel(title: "Read Write Mode".localized, type: .picker, value: {
                        switch config.observerConfig?.mode {
                        case .readOnly: return "Read Only"
                        case .writeOnly: return "Write Only"
                        case .readWrite: return "Read Write"
                        default: return "Read Only"
                        }
                    }(), options: ["Read Only", "Write Only", "Read Write"])
                ]
                
            }
            configVC.configData = configData
            // 取消回调
            configVC.onCancel = { [weak self, weak sender] in
                guard let self = self, let sender = sender else { return }
                sender.isOn = false
                config.enable = false
                self.audioSourceRawFrameConfigs[.captured] = config
            }
            
            // 配置变更回调
            configVC.onConfigChanged = { [weak self] updatedConfigData in
                guard let self = self else { return }
                
                // 获取配置项索引
                guard let channelIndex = updatedConfigData.firstIndex(where: { $0.title == "Channel Num".localized }),
                      let sampleRateIndex = updatedConfigData.firstIndex(where: { $0.title == "SampleRate".localized }),
                      let modeIndex = updatedConfigData.firstIndex(where: { $0.title == "Read Write Mode".localized }) else {
                    return
                }
                
                // 解析通道数
                guard let channelString = updatedConfigData[channelIndex].value as? String else { return }
                let channels: AliRtcAudioNumChannel = channelString == "Mono" ? .monoAudio : .stereoAudio
                
                // 解析采样率
                guard let sampleRateString = updatedConfigData[sampleRateIndex].value as? String else { return }
                let sampleRate: AliRtcAudioSampleRate = {
                    switch sampleRateString {
                    case "8000": return ._8000
                    case "16000": return ._16000
                    case "32000": return ._32000
                    case "44100": return ._44100
                    default: return ._48000
                    }
                }()
                
                // 解析写模式
                guard let modeString = updatedConfigData[modeIndex].value as? String else { return }
                let mode: AliRtcAudioFrameObserverOperationMode = {
                    switch modeString {
                    case "Write Only": return .writeOnly
                    case "Read Write": return .readWrite
                    default: return .readOnly
                    }
                }()
                
                // 更新配置
                let observerConfig = AliRtcAudioFrameObserverConfig()
                observerConfig.channels = channels
                observerConfig.sampleRate = sampleRate
                observerConfig.mode = mode
                config.observerConfig = observerConfig
                
                config.enable = true
                self.audioSourceRawFrameConfigs[source] = config
            }
            
            // 弹出配置界面
            configVC.modalPresentationStyle = .formSheet
            self.present(configVC, animated: true, completion: nil)
        } else {
            config.enable = false
            audioSourceRawFrameConfigs[source] = config
        }
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
        
        let vc = self.presentVC(storyboardName: "ProcessAudioRawData", storyboardId: "MainVC") as? ProcessAudioRawDataMainVC
        vc?.channelId = channelId
        vc?.userId = userId
        vc?.joinToken = joinToken
        vc?.audioSourceConfigs = self.audioSourceRawFrameConfigs
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

class ProcessAudioRawDataMainVC: UIViewController {
    
    var audioSourceConfigs: [AliRtcAudioSource: AudioRawFrameConfig]?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = self.channelId
        self.setupInfoLabel()
        
        self.setup()
        self.enableAndRegisterAudioFrameObserver()
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
    
    @IBOutlet weak var contentScrollView: UIScrollView!
    
    var seatViewList: [SeatView] = []
    
    var channelId: String = ""
    var userId: String = ""
    
    var rtcEngine: AliRtcEngine? = nil

    var joinToken: String? = nil
    
    // Audio Raw Frame
    var isAudioCaptureCallbak = false
    
    // 信息显示Label
    private var captureInfoLabel: UILabel!
    private var processInfoLabel: UILabel!
    private var publishInfoLabel: UILabel!
    private var prePlaybackInfoLabel: UILabel!
    private var remoteUserInfoLabel: UILabel!
    
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
        
        self.rtcEngine = engine
    }
    
    func enableAndRegisterAudioFrameObserver() {
        var isEnableAudioRawFrame: Bool = false
        if let configs = self.audioSourceConfigs {
            for (source, config) in configs {
                if config.enable, let observerConfig = config.observerConfig {
                    // 启用音频数据监听器
                    self.rtcEngine?.enableAudioFrameObserver(config.enable, audioSource: source, config: observerConfig)
                    isEnableAudioRawFrame = true
                }
            }
            // 注册
            if isEnableAudioRawFrame {
                self.rtcEngine?.registerAudioFrameObserver(self)
            }
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
// MARK: 音频数据回调
extension ProcessAudioRawDataMainVC: AliRtcAudioFrameDelegate {
    func onCapturedAudioFrame(_ frame: AliRtcAudioFrame) -> Bool {
        let message = "onCaptureVideoSample: numofSamples: \(frame.numOfSamples), numofChannels: \(frame.numOfChannels), SampleRate: \(frame.samplesPerSec)"
        message.printLog()
        updateInfoLabel(captureInfoLabel, text: message)
        return true
    }
    
    func onProcessCapturedAudioFrame(_ frame: AliRtcAudioFrame) -> Bool {
        let message = "onProcessCapturedAudioFrame: numofSamples: \(frame.numOfSamples), numofChannels: \(frame.numOfChannels), SampleRate: \(frame.samplesPerSec)"
        message.printLog()
        updateInfoLabel(processInfoLabel, text: message)
        return true
    }
    
    func onPublishAudioFrame(_ frame: AliRtcAudioFrame) -> Bool {
        let message = "onPublishAudioFrame: numofSamples: \(frame.numOfSamples), numofChannels: \(frame.numOfChannels), SampleRate: \(frame.samplesPerSec)"
        message.printLog()
        updateInfoLabel(publishInfoLabel, text: message)
        return true
    }
    
    func onPlaybackAudioFrame(_ frame: AliRtcAudioFrame) -> Bool {
        let message = "onPlaybackAudioFrame: numofSamples: \(frame.numOfSamples), numofChannels: \(frame.numOfChannels), SampleRate: \(frame.samplesPerSec)"
        message.printLog()
        updateInfoLabel(prePlaybackInfoLabel, text: message)
        return true
    }
    
    func onRemoteUserAudioFrame(_ uid: String?, frame: AliRtcAudioFrame) -> Bool {
        let message = "onRemoteUserAudioFrame: uid: \(uid ?? "invalid"), numofSamples: \(frame.numOfSamples), numofChannels: \(frame.numOfChannels), SampleRate: \(frame.samplesPerSec)"
        message.printLog()
        updateInfoLabel(remoteUserInfoLabel, text: message)
        return true
    }
}

extension ProcessAudioRawDataMainVC: AliRtcEngineDelegate {
    
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

