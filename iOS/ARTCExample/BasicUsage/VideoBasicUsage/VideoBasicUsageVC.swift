//
//  VideoBasicUsage.swift
//  ARTCExample
//
//  Created by wy on 2025/7/3.
//

import Foundation
import AliVCSDK_ARTC

class VideoBasicUsageVC: UIViewController, UITextFieldDelegate {
    
    // MARK: UI
    // Video Capture Config
    var cameraCaptureConfig: AliRtcCameraCapturerConfiguration!
    
    @IBOutlet weak var cameraCaptureConfigStackView: UIStackView!
    @IBOutlet weak var cameraCapturePreferenceTextField: UITextField!
    let cameraCapturePreferenceOptions = ["SDK Auto", "Performance Priority", "Preview Priotity"]
    let cameraCapturePreferencePickerView = UIPickerView()
    
    @IBAction func onCameraCaptureDirectionConfigChanged(_ sender: UISegmentedControl) {
        let cameraPosition: AliRtcCameraDirection = sender.selectedSegmentIndex == 0 ? AliRtcCameraDirection.front : AliRtcCameraDirection.back
        self.cameraCaptureConfig.cameraDirection = cameraPosition
    }
    
    @IBOutlet weak var cameraCaptureFPSTextField: UITextField!
    
    @IBAction func onCameraCaptureFPSChanged(_ sender: UITextField) {
        guard let text = sender.text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return
        }
        let fps: Int?
        if let value = Int(text) {
            fps = value
        } else {
            fps = 15
        }
        guard let fpsValue = fps else {
            UIAlertController.showAlertWithMainThread(msg: "Please enter a valid integer".localized, vc: self)
            return
        }
        
        self.cameraCaptureConfig.fps = Int32(fpsValue)
        sender.resignFirstResponder()
    }
    
    @IBAction func onCameraCaptureProfileChanged(_ sender: UISegmentedControl) {
        let cameraCaptureProfile: AliRtcCameraCaptureProfile = sender.selectedSegmentIndex == 0 ?
            .profileDefault : .profile1080P
        self.cameraCaptureConfig.cameraCaptureProfile = cameraCaptureProfile
    }
    
    func updateCaptureUIVisibility() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            let isCameraOn = self.rtcEngine?.isCameraOn() ?? false
            cameraCaptureConfigStackView.axis = isCameraOn ?  .horizontal : .vertical
            cameraCaptureConfigStackView.isHidden = isCameraOn
        }
    }
    
    // Video Encoder Config
    var videoEncoderConfig: AliRtcVideoEncoderConfiguration!
    
    
    @IBOutlet weak var videoEncoderWidthTextField: UITextField!
    @IBAction func onVideoEncoderWidthChanged(_ sender: UITextField) {
        guard let text = sender.text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return
        }
        let width: Int?
        if let value = Int(text) {
            width = value
        } else {
            width = 720
        }
        guard let widthValue = width else {
            UIAlertController.showAlertWithMainThread(msg: "Please enter a valid integer".localized, vc: self)
            return
        }
        self.videoEncoderConfig.dimensions = CGSize(width: Float64(widthValue), height: self.videoEncoderConfig.dimensions.height)
        sender.resignFirstResponder()
    }
    
    @IBOutlet weak var videoEncoderHeightTextField: UITextField!
    @IBAction func onVideoEncoderHeightChanged(_ sender: UITextField) {
        guard let text = sender.text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return
        }
        let height: Int?
        if let value = Int(text) {
            height = value
        } else {
            height = 720
        }
        guard let heighttValue = height else {
            UIAlertController.showAlertWithMainThread(msg: "Please enter a valid integer".localized, vc: self)
            return
        }
        self.videoEncoderConfig.dimensions = CGSize(width: self.videoEncoderConfig.dimensions.width, height: Float64(heighttValue))
        sender.resignFirstResponder()
    }
    
    @IBOutlet weak var videoEncoderFPSTextField: UITextField!
    @IBAction func onVideoEncoderFPSChanged(_ sender: UITextField) {
        guard let text = sender.text?.trimmingCharacters(in: .whitespacesAndNewlines) else{
            return
        }
        let fps: Int?
        if let value = Int(text) {
            fps = value
        } else {
            fps = 15
        }
        guard let fpsValue = fps else {
            UIAlertController.showAlertWithMainThread(msg: "Please enter a valid integer".localized, vc: self)
            return
        }
        self.videoEncoderConfig.frameRate = Int(fpsValue)
        sender.resignFirstResponder()
    }
    
    @IBOutlet weak var videoEncoderBitrateTextField: UITextField!
    @IBAction func onVideoEncoderBitrateChanged(_ sender: UITextField) {
        guard let text = sender.text?.trimmingCharacters(in: .whitespacesAndNewlines) else{
            return
        }
        let bitrate: Int?
        if let value = Int(text) {
            bitrate = value
        } else {
            bitrate = 0
        }
        guard let bitrateValue = bitrate else {
            UIAlertController.showAlertWithMainThread(msg: "Please enter a valid integer".localized, vc: self)
            return
        }
        self.videoEncoderConfig.frameRate = Int(bitrateValue)
        sender.resignFirstResponder()
    }
    

    @IBOutlet weak var videoEncoderMinBitrateTextField: UITextField!
    @IBAction func onVideoEncoderMinBitrateChanged(_ sender: UITextField) {
        guard let text = sender.text?.trimmingCharacters(in: .whitespacesAndNewlines) else{
            return
        }
        let minBitrate: Int?
        if let value = Int(text) {
            minBitrate = value
        } else {
            minBitrate = 0
        }
        guard let minBitrateValue = minBitrate else {
            UIAlertController.showAlertWithMainThread(msg: "Please enter a valid integer".localized, vc: self)
            return
        }
        self.videoEncoderConfig.frameRate = Int(minBitrateValue)
        sender.resignFirstResponder()
    }
    
    @IBOutlet weak var videoEncoderKeyFrameIntervalTextField: UITextField!
    @IBAction func onVideoEncoderKeyFrameIntervalChanged(_ sender: UITextField) {
        guard let text = sender.text?.trimmingCharacters(in: .whitespacesAndNewlines) else{
            return
        }
        let keyframeInterval: Int?
        if let value = Int(text) {
            keyframeInterval = value
        } else {
            keyframeInterval = 0
        }
        guard let keyframeIntervalValue = keyframeInterval else {
            UIAlertController.showAlertWithMainThread(msg: "Please enter a valid integer".localized, vc: self)
            return
        }
        self.videoEncoderConfig.frameRate = Int(keyframeIntervalValue)
        sender.resignFirstResponder()
    }
    
    @IBAction func onVideoEncoderForceKeyFrameIntervalSwitch(_ sender: UISwitch) {
        self.videoEncoderConfig.forceStrictKeyFrameInterval = sender.isOn
    }
    
    @IBOutlet weak var videoEncoderOrientationModeTextField: UITextField!
    let orientationModeOptions = ["Follow Capture".localized, "Fixed Landscape".localized, "Fixed Portrait".localized]
    let orientationModePickerView = UIPickerView()
    
    @IBOutlet weak var videoEncoderRotationModeTextField: UITextField!
    let rotationModeOptions = ["0", "90", "180", "270"]
    let rotationModePickerView = UIPickerView()
    
    @IBOutlet weak var videoEncoderEncodeCodecTypeTextField: UITextField!
    let encodeTypeModeOptions = ["H264", "H265"]
    let encodeTypeModePickerView = UIPickerView()
    
    @IBOutlet weak var videoEncoderCodecTypeTextField: UITextField!
    let codecTypeOptions = ["Software Encoding".localized, "Hardware Encoding".localized, "Hardware Texture Encoding".localized]
    let codecTypePickerView = UIPickerView()
    
    // MARK: rtc parameters
    @IBOutlet weak var channelIdTextField: UITextField!
    @IBOutlet weak var localViewContainer: UIView!
    @IBOutlet weak var remoteViewContainer: UIView!
    
    @IBOutlet weak var scrollerView: UIScrollView!
    private var localVideoView: SeatView?
    private var remoteVideoView: SeatView?
    
    var channelId: String = ""
    var userId: String = ""
    var rtcEngine: AliRtcEngine? = nil
    var joinToken: String? = nil
    var isPreviewOn: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateCaptureUIVisibility()
        
        self.cameraCaptureConfig = AliRtcCameraCapturerConfiguration()
        self.cameraCaptureConfig.cameraDirection = .front
        self.videoEncoderConfig = AliRtcVideoEncoderConfiguration()
        
        self.title = "Video Basic Usage".localized
        self.channelIdTextField.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapOutside))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        self.mirrorModeSelectedTextField.delegate = self
        self.mirrorModePickerView.delegate = self
        self.mirrorModePickerView.dataSource = self
        self.mirrorModeSelectedTextField.inputView = self.mirrorModePickerView
        self.mirrorModePickerView.tag = 1
        self.mirrorModePickerView.selectRow(0, inComponent: 0, animated: false)
        self.mirrorModeSelectedTextField.text = self.mirrorModeOptions[0]
        
        self.cameraCapturePreferenceTextField.delegate = self
        self.cameraCapturePreferencePickerView.delegate = self
        self.cameraCapturePreferencePickerView.dataSource = self
        self.cameraCapturePreferenceTextField.inputView = self.cameraCapturePreferencePickerView
        self.cameraCapturePreferencePickerView.tag = 2
        self.cameraCapturePreferencePickerView.selectRow(0, inComponent: 0, animated: false)
        self.cameraCapturePreferenceTextField.text = self.cameraCapturePreferenceOptions[0]
        
        self.cameraCaptureFPSTextField.delegate = self
        self.videoEncoderFPSTextField.delegate = self
        self.videoEncoderWidthTextField.delegate = self
        self.videoEncoderHeightTextField.delegate = self
        self.videoEncoderBitrateTextField.delegate = self
        self.videoEncoderMinBitrateTextField.delegate = self
        
        self.videoEncoderOrientationModeTextField.delegate = self
        self.videoEncoderOrientationModeTextField.inputView = self.orientationModePickerView
        self.orientationModePickerView.delegate = self
        self.orientationModePickerView.dataSource = self
        self.orientationModePickerView.tag = 3
        self.orientationModePickerView.selectRow(0, inComponent: 0, animated: false)
        self.videoEncoderOrientationModeTextField.text = self.orientationModeOptions[0]
        
        self.videoEncoderRotationModeTextField.delegate = self
        self.rotationModePickerView.delegate = self
        self.rotationModePickerView.dataSource = self
        self.videoEncoderRotationModeTextField.inputView = self.rotationModePickerView
        self.rotationModePickerView.tag = 4
        self.rotationModePickerView.selectRow(0, inComponent: 0, animated: false)
        self.videoEncoderRotationModeTextField.text = self.rotationModeOptions[0]
        
        self.videoEncoderEncodeCodecTypeTextField.delegate = self
        self.encodeTypeModePickerView.delegate = self
        self.encodeTypeModePickerView.dataSource = self
        self.videoEncoderEncodeCodecTypeTextField.inputView = self.encodeTypeModePickerView
        self.encodeTypeModePickerView.tag = 5
        self.encodeTypeModePickerView.selectRow(0, inComponent: 0, animated: false)
        self.videoEncoderEncodeCodecTypeTextField.text = self.encodeTypeModeOptions[0]
        
        self.videoEncoderCodecTypeTextField.delegate = self
        self.codecTypePickerView.delegate = self
        self.codecTypePickerView.dataSource = self
        self.videoEncoderCodecTypeTextField.inputView = self.codecTypePickerView
        self.codecTypePickerView.tag = 6
        self.codecTypePickerView.selectRow(0, inComponent: 0, animated: false)
        self.videoEncoderCodecTypeTextField.text = self.codecTypeOptions[0]
        
        // 进入界面就创建引擎并设置本地视图
        self.initAndSetupRtcEngine()
        self.setLocalView()
    }
    
    @objc private func handleTapOutside() {
        view .endEditing(true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.leaveAndDestroyEngine()
    }
    
    @IBAction func onCameraDirectionChanged(_ sender: UISegmentedControl) {
        rtcEngine?.switchCamera()
    }
    
    @IBAction func onCameraSwitch(_ sender: UISwitch) {
        if sender.isOn {
            rtcEngine?.enableLocalVideo(true)
        } else {
            rtcEngine?.enableLocalVideo(false)
        }
        updateCaptureUIVisibility()
    }
    
    @IBOutlet weak var previewSwitch: UISwitch!
    @IBAction func onPreviewChanged(_ sender: UISwitch) {
        if sender.isOn {
            rtcEngine?.startPreview()
        } else {
            rtcEngine?.stopPreview()
        }
        updateCaptureUIVisibility()
    }
    
    @IBAction func onVideoMuteSwitched(_ sender: UISwitch) {
        if sender.isOn {
            // 黑帧
            rtcEngine?.muteLocalCamera(false, for: AliRtcVideoTrack.camera)
        } else {
            rtcEngine?.muteLocalCamera(true, for: AliRtcVideoTrack.camera)
        }
    }
    
    @IBOutlet weak var mirrorModeSelectedTextField: UITextField!
    let mirrorModeOptions = ["Both Mirroring Enable".localized, "Both Mirroring Disabled".localized, "Preview Mirroring Only".localized, "Encoding Mirroring Only".localized]
    let mirrorModePickerView = UIPickerView()
    
    @IBOutlet weak var joinChannelButton: UIButton!
    @IBAction func onJoinChannelBtnClicked(_ sender: UIButton) {
        guard let channelId = self.channelIdTextField.text, channelId.isEmpty == false else {
            UIAlertController.showAlertWithMainThread(msg: "Input the Channel ID please.", vc: self)
            return
        }
        if rtcEngine == nil {
            self.initAndSetupRtcEngine()
            self.setLocalView()
        }
        // 生成入会参数
        let tokenHelper = ARTCTokenHelper()
        self.userId = GlobalConfig.shared.userId
        let timestamp = Int64(Date().timeIntervalSince1970 + 24 * 60 * 60)
        self.joinToken = tokenHelper.generateJoinToken(channelId: channelId, userId: userId, timestamp: timestamp)
        
        self.joinChannel()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func onConfigSaveButtonClicked(_ sender: UIButton) {
        if let engine = self.rtcEngine, !engine.isCameraOn() {
            engine.setCameraCapturerConfiguration(self.cameraCaptureConfig)
        }
        rtcEngine?.setVideoEncoderConfiguration(self.videoEncoderConfig)
    }
    
    func initAndSetupRtcEngine() {
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
        // 设置视频采集参数
        engine.setCameraCapturerConfiguration(self.cameraCaptureConfig)
        // 设置视频编码参数
        engine.setVideoEncoderConfiguration(self.videoEncoderConfig)
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
    
    func setLocalView() {
        // 创建视图
        guard let localContainer = self.localViewContainer else {return}
        let videoView = self.createSeatView(uid: self.userId)
        self.localVideoView = videoView
        
        let canvas = AliVideoCanvas()
        canvas.view = videoView.canvasView
        canvas.renderMode = .auto
        canvas.mirrorMode = .onlyFrontCameraPreviewEnabled
        canvas.rotationMode = ._0
        
        self.rtcEngine?.setLocalViewConfig(canvas, for: AliRtcVideoTrack.camera)
        localContainer.addSubview(videoView)
        NSLayoutConstraint.activate([
            videoView.topAnchor.constraint(equalTo: localContainer.topAnchor),
            videoView.bottomAnchor.constraint(equalTo: localContainer.bottomAnchor),
            videoView.leadingAnchor.constraint(equalTo: localContainer.leadingAnchor),
            videoView.trailingAnchor.constraint(equalTo: localContainer.trailingAnchor)
        ])
    }
    
    func leaveAndDestroyEngine() {
        self.rtcEngine?.stopPreview()
        self.rtcEngine?.leaveChannel()
        AliRtcEngine.destroy()
        self.rtcEngine = nil
        joinChannelButton.setTitle("Join Channel".localized, for: .normal)
    }
    
    // 创建一个视频通话渲染视图，并加入到contentScrollView中
    func createSeatView(uid: String) -> SeatView {
        let view = SeatView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.uidLabel.text = uid
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }
}

extension VideoBasicUsageVC: AliRtcEngineDelegate {
    
    func onJoinChannelResult(_ result: Int32, channel: String, elapsed: Int32) {
        "onJoinChannelResult1 result: \(result)".printLog()
    }
    
    func onJoinChannelResult(_ result: Int32, channel: String, userId: String, elapsed: Int32) {
        "onJoinChannelResult2 result: \(result)".printLog()
    }
    func onUserVideoMuted(_ uid: String, videoMuted isMute: Bool) {
        "onUserVideoMuted: user id \(uid) video muted: \(isMute)".printLog()
    }
    
    func onUserVideoEnabled(_ uid: String?, videoEnabled isEnable: Bool) {
        "onUserVideoEnabled: user id \(uid ?? "invalid uid") video enable: \(isEnable)".printLog()
    }
    
    func onLeaveChannelResult(_ result: Int32, stats: AliRtcStats) {
        "onLeaveChannelResult: \(result)".printLog()

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
        
        guard let remoteContainer = self.remoteViewContainer else {return}
        // 远端用户的流状态
        if videoTrack != .no {
            // 移除远端视图
            remoteVideoView?.removeFromSuperview()
            remoteVideoView = nil
            // 创建新的视图
            let videoView = self.createSeatView(uid: uid)
            remoteVideoView = videoView
            
            let canvas = AliVideoCanvas()
            canvas.view = videoView.canvasView
            canvas.renderMode = .auto
            canvas.mirrorMode = .onlyFrontCameraPreviewEnabled
            canvas.rotationMode = ._0
            self.rtcEngine?.setRemoteViewConfig(canvas, uid: uid, for: AliRtcVideoTrack.camera)
            
            remoteContainer.addSubview(videoView)
            NSLayoutConstraint.activate([
                videoView.topAnchor.constraint(equalTo: remoteContainer.topAnchor),
                videoView.bottomAnchor.constraint(equalTo: remoteContainer.bottomAnchor),
                videoView.leadingAnchor.constraint(equalTo: remoteContainer.leadingAnchor),
                videoView.trailingAnchor.constraint(equalTo: remoteContainer.trailingAnchor)
            ])
        }
        else {
            remoteVideoView?.removeFromSuperview()
            remoteVideoView = nil
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

extension VideoBasicUsageVC:UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch (pickerView.tag) {
        case 1:
            return self.mirrorModeOptions.count
        case 2:
            return self.cameraCapturePreferenceOptions.count
        case 3:
            return self.orientationModeOptions.count
        case 4:
            return self.rotationModeOptions.count
        case 5:
            return self.encodeTypeModeOptions.count
        case 6:
            return self.codecTypeOptions.count
        default:
            return 0
        }
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch (pickerView.tag) {
        case 1:
            let selected = self.mirrorModeOptions[row]
            self.mirrorModeSelectedTextField.text = selected
            let mirrorMode: AliRtcVideoPipelineMirrorMode = {
                switch row {
                case 0: return .bothMirror
                case 1: return .noMirror
                case 2: return .onlyPreviewMirror
                case 3: return .onlyPublishMirror
                default: return .bothMirror
                }
            }()
            self.rtcEngine?.setVideoMirrorMode(mirrorMode)
            self.mirrorModeSelectedTextField.resignFirstResponder()
        case 2:
            let selected = self.cameraCapturePreferenceOptions[row]
            self.cameraCapturePreferenceTextField.text = selected
            let cameraCapturePreference: AliRtcCaptureOutputPreference = {
                switch row {
                case 0: return .auto
                case 1: return .performance
                case 2: return .preview
                default: return .auto
                }
            }()
            self.cameraCaptureConfig.preference = cameraCapturePreference
            self.cameraCapturePreferenceTextField.resignFirstResponder()
        case 3:
            let selected = self.orientationModeOptions[row]
            self.videoEncoderOrientationModeTextField.text = selected
            let orientationMode: AliRtcVideoEncoderOrientationMode = {
                switch row {
                case 0: return .adaptive
                case 1: return .fixedLandscape
                case 2: return .fixedPortrait
                default: return .adaptive
                }
            }()
            self.videoEncoderConfig.orientationMode = orientationMode
            self.videoEncoderOrientationModeTextField.resignFirstResponder()
        case 4:
            let selected = self.rotationModeOptions[row]
            self.videoEncoderRotationModeTextField.text = selected
            let rotatioinMode: AliRtcRotationMode = {
                switch row {
                case 0: return ._0
                case 1: return ._90
                case 2: return ._180
                case 3: return ._270
                default: return ._0
                }
            }()
            self.videoEncoderConfig.rotationMode = rotatioinMode
            self.videoEncoderRotationModeTextField.resignFirstResponder()
        case 5:
            let selected = self.encodeTypeModeOptions[row]
            self.videoEncoderEncodeCodecTypeTextField.text = selected
            let encodeType:AliRtcVideoEncodeCodecType = {
                switch row{
                case 0: return .H264
                case 1: return .hevc
                default: return .default
                }
            } ()
            self.videoEncoderConfig.encoderType = encodeType
            self.videoEncoderEncodeCodecTypeTextField.resignFirstResponder()
        case 6:
            let selected = self.codecTypeOptions[row]
            self.videoEncoderCodecTypeTextField.text = selected
            let codecType: AliRtcVideoCodecType = {
                switch row {
                case 0: return .software
                case 1: return .hardware
                default: return .default
                }
            } ()
            self.videoEncoderConfig.codecType = codecType
            self.videoEncoderCodecTypeTextField.resignFirstResponder()
        default:
            break
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch(pickerView.tag) {
        case 1:
            return self.mirrorModeOptions[row]
        case 2:
            return self.cameraCapturePreferenceOptions[row]
        case 3:
            return self.orientationModeOptions[row]
        case 4:
            return self.rotationModeOptions[row]
        case 5:
            return self.encodeTypeModeOptions[row]
        case 6:
            return self.codecTypeOptions[row]
        default:
            return ""
        }
    }
}
