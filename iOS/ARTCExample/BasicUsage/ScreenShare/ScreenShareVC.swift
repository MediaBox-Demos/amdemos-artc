//
//  ScreenShareVC.swift
//  ARTCExample
//
//  Created by wy on 2025/7/22.
//

import Foundation
import AliVCSDK_ARTC
import ReplayKit

class ScreenShareSetParamsVC: UIViewController, UITextFieldDelegate {
    var audioSourceRawFrameConfigs: [AliRtcAudioSource: AudioRawFrameConfig] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Screen Share".localized
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
        
        let vc = self.presentVC(storyboardName: "ScreenShare", storyboardId: "MainVC") as? ScreenShareMainVC
        vc?.channelId = channelId
        vc?.userId = userId
        vc?.joinToken = joinToken
        vc?.isPublishLocalVideoStreamEnalbe = publishLocalVideoStreamSwitch.isOn
    }
    
    @IBOutlet weak var publishLocalVideoStreamSwitch: UISwitch!
    
    
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

class ScreenShareMainVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        initUI()
        
        self.setup()
        self.startPreview()
        self.joinChannel()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.leaveAnddestroyEngine()
    }
    
    // MARK: UI
    @IBOutlet weak var contentScrollView: UIScrollView!
    
    let kAppGroup = "group.com.aliyun.video";
    let screenShareModeOptions = ["None", "Only Video", "Only Audio", "All"]
    private let screenShareModePickerView = UIPickerView()
    private let stackView = UIStackView()
    
    @IBOutlet weak var screenShareModeTextField: UITextField!
    @IBOutlet weak var screenShareAudioChannelNumSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var screenShareAudioSampleRateTextField: UITextField!
    @IBOutlet weak var screenShareVideoWidthTextField: UITextField!
    @IBOutlet weak var screenShareVideoHeightTextField: UITextField!
    @IBOutlet weak var screenShareVideoFPSTextField: UITextField!
    @IBOutlet weak var screenShareVideoBitrateTextField: UITextField!
    @IBOutlet weak var screenShareVideoGOPTextField: UITextField!
    
    @IBOutlet weak var screenShareAudioVolumeSlider: UISlider!
    @IBAction func onShareAudioVolumeSliderChanged(_ sender: UISlider) {
        let volume = Int32(sender.value)
        self.rtcEngine?.setAudioShareAppVolume(volume)
    }
    
    @IBAction func onStartScreenShareBtnClicked(_ sender: UIButton) {
        guard let alirtcEngine = self.rtcEngine else {return}
        
        alirtcEngine.setScreenShareEncoderConfiguration(screenShareConfig)
        startBroadcastPicker()
        // 开始屏幕共享
        alirtcEngine.startScreenShare(kAppGroup, mode: screenShareMode)
    }
    
    @IBAction func onStopScreenShareBtnClicked(_ sender: UIButton) {
        guard let alirtcEnging = self.rtcEngine else {return}
        if(alirtcEnging.isScreenSharePublished()) {
            alirtcEnging.stopScreenShare()
        }
    }
    @IBAction func onUpdateScreenShareBtnClicked(_ sender: UIButton) {
        guard let alirtcEngine = self.rtcEngine else {return}
        if(alirtcEngine.isScreenSharePublished()) {
            alirtcEngine.setScreenShareEncoderConfiguration(screenShareConfig)
        }
    }
    
    // 保存所有视图
    var videoSeatViewMap: [String: SeatView] = [:]
    
    // MARK: Join Channel Params
    var channelId: String = ""
    var userId: String = ""
    
    var rtcEngine: AliRtcEngine? = nil

    var joinToken: String? = nil
    
    var isPublishLocalVideoStreamEnalbe = true
    
    // Screen Share Configs
    var screenShareConfig: AliRtcScreenShareEncoderConfiguration = AliRtcScreenShareEncoderConfiguration()
    var screenShareMode:AliRtcScreenShareMode = .all
    
    private func initUI() {
        self.title = self.channelId
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboardAndPickers))
        self.view.addGestureRecognizer(tapGesture)
        
        self.screenShareModeTextField.inputView = self.screenShareModePickerView
        self.screenShareModePickerView.delegate = self
        self.screenShareModePickerView.dataSource = self
        self.screenShareModePickerView.tag = 0
        self.screenShareModeTextField.text = screenShareModeOptions[3]
        
        self.screenShareAudioVolumeSlider.maximumValue = 100
        self.screenShareAudioVolumeSlider.minimumValue = 0
        self.screenShareAudioVolumeSlider.value = 50
        
        self.screenShareVideoWidthTextField.delegate = self
        self.screenShareVideoHeightTextField.delegate = self
        self.screenShareVideoFPSTextField.delegate = self
        self.screenShareVideoBitrateTextField.delegate = self
        self.screenShareVideoGOPTextField.delegate = self
        
        screenShareVideoWidthTextField.text = "\(Int(screenShareConfig.dimensions.width))"
        screenShareVideoHeightTextField.text = "\(Int(screenShareConfig.dimensions.height))"
        screenShareVideoFPSTextField.text = "\(screenShareConfig.frameRate)"
        screenShareVideoBitrateTextField.text = "\(screenShareConfig.bitrate)"
        screenShareVideoGOPTextField.text = "\(screenShareConfig.keyFrameInterval)"
        
        // 创建垂直StackView用于显示视频
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.distribution = .fill
        stackView.alignment = .fill
        
        contentScrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.bottomAnchor, constant: -12),
            stackView.widthAnchor.constraint(equalTo: contentScrollView.frameLayoutGuide.widthAnchor, constant: -24)
        ])
    }
    
    @objc func dismissKeyboardAndPickers() {
        self.screenShareModeTextField.resignFirstResponder()
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
        engine.publishLocalVideoStream(isPublishLocalVideoStreamEnalbe)
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
    
    // 加入频道
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
        let seatView = self.createOrUpdateSeatView(uid: self.userId, streamType: .camera)
        
        let canvas = AliVideoCanvas()
        canvas.view = seatView.canvasView
        canvas.renderMode = .auto
        canvas.mirrorMode = .onlyFrontCameraPreviewEnabled
        canvas.rotationMode = ._0
        
        self.rtcEngine?.setLocalViewConfig(canvas, for: AliRtcVideoTrack.camera)
        self.rtcEngine?.startPreview()
    }
    
    func leaveAnddestroyEngine() {
        if self.rtcEngine?.isScreenSharePublished() == true {
            self.rtcEngine?.stopScreenShare()
        }
        self.rtcEngine?.stopPreview()
        self.rtcEngine?.leaveChannel()
        AliRtcEngine.destroy()
        self.rtcEngine = nil
    }
    
    // 创建并配置一个系统广播选择器视图，苹果要求屏幕共享需要用户显示触发
    func startBroadcastPicker() {
        if #available(iOS 12.0, *) {
            let broadcastPickerView = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
            
            guard let bundlePath = Bundle.main.path(forResource: "ScreenShareExtension", ofType: "appex", inDirectory: "PlugIns") else {
                self.showErrorAlertView("Can not find bundle at path", code: 0, forceShow: false)
                return
            }
            
            guard let bundle = Bundle(path: bundlePath) else {
                self.showErrorAlertView("Can not find bundle at path", code: 0, forceShow: false)
                return
            }
            
            broadcastPickerView.preferredExtension = bundle.bundleIdentifier
            
            // Traverse the subviews to find the button to skip the step of clicking the system view.
            // This solution is not officially recommended by Apple, and may be invalid in future system updates.
            for subView in broadcastPickerView.subviews {
                if let button = subView as? UIButton {
                    button.sendActions(for: .allEvents)
                }
            }
            
        } else {
            self.showErrorAlertView("This feature only supports iOS 12 or above", code: 0, forceShow: false)
            return
        }
    }
    
    private func showErrorAlertView(_ message: String, code: Int, forceShow: Bool) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: 视图管理核心逻辑
extension ScreenShareMainVC {
    // 创建或更新一个视频通话渲染视图，并加入到contentScrollView中
    func createOrUpdateSeatView(uid: String, streamType: StreamType) ->SeatView {
        let key = "\(uid)_\(streamType)"
        
        // 1. 如果已有视图，直接返回
        if let existingView = videoSeatViewMap[key] {
            return existingView
        }
        
        // 2. 创建新视图
        let seatView = SeatView(frame: .zero)
        seatView.seatInfo = SeatInfo(uid: uid, streamType: streamType)
        
        if uid != self.userId {
            // 3. 配置视频画布
            let canvas = AliVideoCanvas()
            canvas.view = seatView.canvasView
            canvas.renderMode = .fill
            canvas.mirrorMode = streamType == .screen ? .allDisabled : .allEnabled
            canvas.rotationMode = ._0
            
            rtcEngine?.setRemoteViewConfig(canvas, uid: uid, for: streamType == .camera ? .camera : .screen)
        }
        
        // 4. 添加到管理字典
        videoSeatViewMap[key] = seatView
        
        // 6. 更新布局
        updateLayoutForUser(uid: uid)
        return seatView
    }
    
    private func updateLayoutForUser(uid: String) {
        // 1. 获取该用户的所有视图
        let cameraKey = "\(uid)_camera"
        let screenKey = "\(uid)_screen"
        let views = [
            videoSeatViewMap[cameraKey],
            videoSeatViewMap[screenKey]
        ].compactMap { $0 }
        
        guard !views.isEmpty else { return }
        
        // 2. 创建用户容器（垂直布局）
        let userContainer = UIView()
        userContainer.layer.cornerRadius = 12
        userContainer.layer.borderWidth = 0.5
        
        let userStack = UIStackView(arrangedSubviews: views)
        userStack.axis = .horizontal
        userStack.spacing = 4
        userStack.distribution = .fillEqually
        
        userContainer.addSubview(userStack)
        userStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            userStack.topAnchor.constraint(equalTo: userContainer.topAnchor, constant: 4),
            userStack.leadingAnchor.constraint(equalTo: userContainer.leadingAnchor, constant: 4),
            userStack.trailingAnchor.constraint(equalTo: userContainer.trailingAnchor, constant: -4),
            userStack.bottomAnchor.constraint(equalTo: userContainer.bottomAnchor, constant: -4),
            userStack.heightAnchor.constraint(greaterThanOrEqualToConstant: 200)
        ])
        
        // 3. 替换原有视图
        if let existingContainer = findUserContainer(for: uid) {
            let oldIndex = stackView.arrangedSubviews.firstIndex(of: existingContainer) ?? 0
            // 完全移除旧容器
            stackView.removeArrangedSubview(existingContainer)
            existingContainer.removeFromSuperview()
            
            // 插入新容器
            stackView.insertArrangedSubview(userContainer, at: oldIndex)
        } else {
            stackView.addArrangedSubview(userContainer)
        }
        userContainer.accessibilityIdentifier = uid
    }
    
    // 查找用户的容器视图
    private func findUserContainer(for uid: String) -> UIView? {
        return stackView.arrangedSubviews.first { container in
            container.accessibilityIdentifier == uid
        }
    }

    func removeSeatView(uid: String, streamType: StreamType) {
        let key = "\(uid)_\(streamType)"
        
        guard let seatView = videoSeatViewMap.removeValue(forKey: key) else { return }
        
        // 1. 从UI中移除
        seatView.removeFromSuperview()
        
        // 2. 清理视频资源
        rtcEngine?.setRemoteViewConfig(nil, uid: uid, for: streamType == .camera ? .camera : .screen)
        
        // 3. 检查是否还有该用户的其他视图
        let hasOtherViews = videoSeatViewMap.keys.contains { $0.hasPrefix("\(uid)_") }
        
        if !hasOtherViews {
            // 移除用户容器
            if let container = findUserContainer(for: uid) {
                container.removeFromSuperview()
            }
        } else {
            // 重新布局剩余视图
            updateLayoutForUser(uid: uid)
        }
    }
}

// 下拉菜单
extension ScreenShareMainVC: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView.tag {
        case 0:
            return self.screenShareModeOptions.count
        default:
            return 0
        }
    }
    
    // UIPickerViewDelegate Methods
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView.tag {
        case 0:
            return NSLocalizedString(self.screenShareModeOptions[row], comment: "")
        default:
            return nil
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView.tag {
        case 0:
            let selectedMode = AliRtcScreenShareMode(rawValue: Int(row)) ?? .none
            screenShareMode = selectedMode
            self.screenShareModeTextField.text = self.screenShareModeOptions[row]
            self.screenShareModeTextField.resignFirstResponder()
            break
        default:
            break
        }
    }
}

extension ScreenShareMainVC: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let text = textField.text, !text.isEmpty else {return}
        
        switch textField {
        case screenShareVideoWidthTextField,screenShareVideoHeightTextField:
            if let width = Int32(text), let height = Int32(textField == screenShareVideoWidthTextField ? text : screenShareVideoHeightTextField.text ?? "0") {
                // 验证分辨率范围3840x2160
                if (0...3840).contains(width) && (0...2160).contains(height) {
                    screenShareConfig.dimensions = CGSize(width: Int(width), height: Int(height))
                }
            }
        case screenShareVideoFPSTextField:
            if let fps = Int(text), (1...30).contains(fps) {
                screenShareConfig.frameRate = fps
            }
        case screenShareVideoBitrateTextField:
            if let bitrate = Int(text) {
                screenShareConfig.bitrate = bitrate
            }
        case screenShareVideoGOPTextField:
            if let gop = Int(text) {
                screenShareConfig.keyFrameInterval = gop
            }
        default:
            break
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension ScreenShareMainVC: AliRtcEngineDelegate {
    
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
    
    func onScreenSharePublishStateChanged(_ oldState: AliRtcPublishState, newState: AliRtcPublishState, elapseSinceLastState: Int, channel: String) {
        // 共享屏幕推流状态变化
        "onScreenSharePublishStateChanged, oldState: \(oldState) -> newState: \(newState), Since: \(elapseSinceLastState)".printLog()
    }
    
    func onScreenShareSubscribeStateChanged(_ uid: String, oldState: AliRtcSubscribeState, newState: AliRtcSubscribeState, elapseSinceLastState: Int, channel: String) {
        "onScreenShareSubscribeStateChanged, uid: \(uid), oldState: \(oldState) -> new State: \(newState) , Since: \(elapseSinceLastState)".printLog()
    }
    
    
    func onRemoteTrackAvailableNotify(_ uid: String, audioTrack: AliRtcAudioTrack, videoTrack: AliRtcVideoTrack) {
        "onRemoteTrackAvailableNotify uid: \(uid) audioTrack: \(audioTrack)  videoTrack: \(videoTrack)".printLog()
        // 远端用户的流状态
        DispatchQueue.main.async {
            switch videoTrack {
            case .no:
                // 移除所有该用户的视图
                self.removeSeatView(uid: uid, streamType: .camera)
                self.removeSeatView(uid: uid, streamType: .screen)
            case .camera:
                self.createOrUpdateSeatView(uid: uid, streamType: .camera)
                self.removeSeatView(uid: uid, streamType: .screen)
            case .screen:
                self.createOrUpdateSeatView(uid: uid, streamType: .screen)
                self.removeSeatView(uid: uid, streamType: .camera)
            case .both:
                self.createOrUpdateSeatView(uid: uid, streamType: .camera)
                self.createOrUpdateSeatView(uid: uid, streamType: .screen)
            @unknown default:
                break
            }
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
