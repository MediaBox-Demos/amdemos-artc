//
//  ProcessVideoRawData.swift
//  ARTCExample
//
//  Created by wy on 2025/7/17.
//

import Foundation
import AliVCSDK_ARTC

// 原始视频数据获取配置
// Video Raw Frame Config
class VideoRawFrameConfig {
    // 视频输出位置
    var isCaptureVideoFrameEnable: Bool
    var isRemoteVideoFrameEnable: Bool
    var isPreEncodeVideoFrameEnable: Bool
    // 期望视频输出格式
    var videoFormatPreference: AliRtcVideoFormat
    // 视频对齐格式，支持保持宽度、偶数对齐、4的倍数、8的倍数、16的倍数
    var videoAlignmentMode: AliRtcVideoObserAlignment
    // 镜像
    var mirrorMode: Bool
    // 写会SDK
    var isWriteBack: Bool // 是否写回SDK,仅支持I420和CVPixelBuffer
    
    init() {
        self.isCaptureVideoFrameEnable =  false
        self.isRemoteVideoFrameEnable = false
        self.isPreEncodeVideoFrameEnable = false
        self.videoFormatPreference = .I420
        self.videoAlignmentMode = AliRtcAlignmentDefault
        self.mirrorMode = false
        self.isWriteBack = true
    }
}


class ProcessVideoRawDataSetParamsVC: UIViewController, UITextFieldDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Process Video Raw Data".localized
        
        self.channelIdTextField.delegate = self
        
        self.videoFormatTextField.inputView = self.videoForamtPickerView
        self.videoForamtPickerView.dataSource = self
        self.videoForamtPickerView.delegate = self
        self.videoForamtPickerView.tag = 0
        self.videoFormatTextField.text = self.videoFormatOptions[0]
        
        self.videoAlignmentTextField.inputView = self.videoAlignmentPickerView
        self.videoAlignmentPickerView.dataSource = self
        self.videoAlignmentPickerView.delegate = self
        self.videoAlignmentPickerView.tag = 1
        self.videoAlignmentTextField.text = self.videoAlignmentModeOptions[0]
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboardAndPickers))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    var videoRawFrameConfig: VideoRawFrameConfig = VideoRawFrameConfig()
    // Video Format
    
    @IBOutlet weak var videoFormatTextField: UITextField!
    let videoFormatOptions = ["I420", "CVPixelBuffer"]
    let videoForamtPickerView = UIPickerView()
    // Video Alignment
    
    @IBOutlet weak var videoAlignmentTextField: UITextField!
    let videoAlignmentModeOptions = ["Default", "even alignment", "multiples of 4", "multiples of 8", "multiples of 16"]
    let videoAlignmentPickerView = UIPickerView()
    
    @IBAction func onCaptureVideoFrameSwitchToggled(_ sender: UISwitch) {
        self.videoRawFrameConfig.isCaptureVideoFrameEnable = sender.isOn
    }
    
    @IBAction func onPreEncoderVideoFrameSwitchToggled(_ sender: UISwitch) {
        self.videoRawFrameConfig.isPreEncodeVideoFrameEnable = sender.isOn
    }
    @IBAction func onRemoteVideoFrameSwitchToggled(_ sender: UISwitch) {
        self.videoRawFrameConfig.isRemoteVideoFrameEnable = sender.isOn
    }
    
    @IBAction func onMirrorModeSwitchToggled(_ sender: UISwitch) {
        self.videoRawFrameConfig.mirrorMode = sender.isOn
    }
    
    @IBAction func onWriteBackSwitchToggled(_ sender: UISwitch) {
        self.videoRawFrameConfig.isWriteBack = sender.isOn
    }
    
    @objc func dismissKeyboardAndPickers() {
        self.videoFormatTextField.resignFirstResponder()
        self.videoAlignmentTextField.resignFirstResponder()
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
        
        let vc = self.presentVC(storyboardName: "ProcessVideoRawData", storyboardId: "MainVC") as? ProcessVideoRawDataMainVC
        guard let vc = vc else { return }
        vc.channelId = channelId
        vc.userId = userId
        vc.joinToken = joinToken
        switch self.videoFormatTextField.text {
        case "I420": videoRawFrameConfig.videoFormatPreference = .I420
        case "CVPixelBuffer": videoRawFrameConfig.videoFormatPreference = .cvPixelBuffer
        default: break
        }
        
        switch self.videoAlignmentTextField.text {
        case "Default": self.videoRawFrameConfig.videoAlignmentMode = AliRtcAlignmentDefault
        case "even alignment": self.videoRawFrameConfig.videoAlignmentMode = AliRtcAlignmentEven
        case "multiples of 4": self.videoRawFrameConfig.videoAlignmentMode = AliRtcAlignment4
        case "multiples of 8": self.videoRawFrameConfig.videoAlignmentMode = AliRtcAlignment8
        case "multiples of 16": self.videoRawFrameConfig.videoAlignmentMode = AliRtcAlignment16
        default:
            break
        }
        if videoRawFrameConfig.isWriteBack && (videoRawFrameConfig.videoFormatPreference == .I420 || videoRawFrameConfig.videoFormatPreference == .cvPixelBuffer) {
            self.videoRawFrameConfig.isWriteBack = true
        } else {
            self.videoRawFrameConfig.isWriteBack = false
        }
        vc.videoRawFrameConfig = videoRawFrameConfig
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

extension ProcessVideoRawDataSetParamsVC: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView.tag {
        case 0:
            return self.videoFormatOptions.count
        case 1:
            return self.videoAlignmentModeOptions.count
        default:
            return 0
        }
    }
    
    // UIPickerViewDelegate Methods
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView.tag {
        case 0:
            return self.videoFormatOptions[row]
        case 1:
            return self.videoAlignmentModeOptions[row]
        default:
            return nil
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView.tag {
        case 0:
            let selectedText = self.videoFormatOptions[row]
            self.videoFormatTextField.text = selectedText
            break
        case 1:
            let selectedText = self.videoAlignmentModeOptions[row]
            self.videoAlignmentTextField.text = selectedText
            break
        default:
            break
        }
    }
}

class ProcessVideoRawDataMainVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = self.channelId
        
        if self.videoRawFrameConfig == nil {
            self.videoRawFrameConfig = VideoRawFrameConfig()
            "Warning: videoRawFrameConfig is nil, using default config.".printLog()
        }
        
        setupInfoLabel()
        
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

    @IBOutlet weak var contentScrollView: UIScrollView!
    
    var seatViewList: [SeatView] = []
    
    var channelId: String = ""
    var userId: String = ""
    
    var rtcEngine: AliRtcEngine? = nil

    var joinToken: String? = nil
    
    var videoRawFrameConfig: VideoRawFrameConfig? = nil
    // 信息显示Label
    private var captureInfoLabel: UILabel!
    private var preEncodeInfoLabel: UILabel!
    private var remoteInfoLabel: UILabel!
    
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
        
        // 注册视频数据回调
        engine.registerVideoSampleObserver()
        
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
        preEncodeInfoLabel = createLabel()
        remoteInfoLabel = createLabel()
        
        captureInfoLabel.text = "Capture: -"
        preEncodeInfoLabel.text = "PreEncode: -"
        remoteInfoLabel.text = "🌐 Remote -"
        
        self.view.addSubview(captureInfoLabel)
        self.view.addSubview(preEncodeInfoLabel)
        self.view.addSubview(remoteInfoLabel)
        // 布局：垂直排列在顶部 safeArea 下方
        NSLayoutConstraint.activate([
            captureInfoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            captureInfoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            captureInfoLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            captureInfoLabel.heightAnchor.constraint(equalToConstant: labelHeight),

            preEncodeInfoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            preEncodeInfoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            preEncodeInfoLabel.topAnchor.constraint(equalTo: captureInfoLabel.bottomAnchor, constant: margin),
            preEncodeInfoLabel.heightAnchor.constraint(equalToConstant: labelHeight),

            remoteInfoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            remoteInfoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            remoteInfoLabel.topAnchor.constraint(equalTo: preEncodeInfoLabel.bottomAnchor, constant: margin),
            remoteInfoLabel.heightAnchor.constraint(equalToConstant: labelHeight)
        ])
    }

    private func updateInfoLabel(_ label: UILabel, text: String) {
        DispatchQueue.main.async {
            label.text = text
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}

extension ProcessVideoRawDataMainVC: AliRtcEngineDelegate {
    
    // MARK: Video Sample Raw Frame Callback
    // 数据期望的输出格式
    func onGetVideoFormatPreference() -> AliRtcVideoFormat {
        guard let config = self.videoRawFrameConfig else {return .I420}
        return config.videoFormatPreference
    }
    // 对齐方式
    func onGetVideoAlignment() -> AliRtcVideoObserAlignment {
        guard let config = self.videoRawFrameConfig else {return AliRtcAlignmentDefault}
        return config.videoAlignmentMode
    }
    // 返回位置，默认全部不返回
    func onGetVideoObservedFramePosition() -> Int {
        guard let config = self.videoRawFrameConfig else {return 0}
        let captureFlag = AliRtcVideoObserPosition.positionPostCapture.rawValue
        let preEncoderFlag = AliRtcVideoObserPosition.positionPreEncoder.rawValue
        let preRenderFlag = AliRtcVideoObserPosition.positionPreRender.rawValue
        var ret = 0
        if config.isCaptureVideoFrameEnable {
            ret |= captureFlag
        }
        if config.isPreEncodeVideoFrameEnable {
            ret |= preEncoderFlag
        }
        if config.isRemoteVideoFrameEnable {
            ret |= preRenderFlag
        }
        return ret
    }
    // 输出是否镜像
    func onGetObserverDataMirrorApplied() -> Bool {
        guard let config = self.videoRawFrameConfig else {return false}
        return config.mirrorMode
    }
    // 本地采集视频数据
    func onCaptureVideoSample(_ videoSource: AliRtcVideoSource, videoSample: AliRtcVideoDataSample) -> Bool {
        let message = "onCaptureVideoSample: timestamp: \(videoSample.timeStamp), format: \(videoSample.format), width: \(videoSample.width), height: \(videoSample.height), dataLength: \(videoSample.dataLength)"
        message.printLog()
        updateInfoLabel(captureInfoLabel, text: message)
        return true
    }
    // 编码前视频数据
    func onPreEncodeVideoSample(_ videoSource: AliRtcVideoSource, videoSample: AliRtcVideoDataSample) -> Bool {
        let message = "onPreEncodeVideoSample: timestamp: \(videoSample.timeStamp), format: \(videoSample.format), width: \(videoSample.width), height: \(videoSample.height), dataLength: \(videoSample.dataLength)"
        message.printLog()
        updateInfoLabel(preEncodeInfoLabel, text: message)
        return true
    }
    // 远端视频数据
    func onRemoteVideoSample(_ uid: String, videoSource: AliRtcVideoSource, videoSample: AliRtcVideoDataSample) -> Bool {
        "onRemoteVideoSample".printLog()
        let message = "onRemoteVideoSample: uid: \(uid), timestamp: \(videoSample.timeStamp), format: \(videoSample.format), width: \(videoSample.width), height: \(videoSample.height), dataLength: \(videoSample.dataLength)"
        message.printLog()
        updateInfoLabel(remoteInfoLabel, text: message)
        return true
    }
    // MARK: Other Callback
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

