//
//  VoiceChangeVC.swift
//  ARTCExample
//
//  Created by wy on 2025/9/3.
//

import Foundation
import Foundation
import AliVCSDK_ARTC
import UIKit

class VoiceChangeSetParamsVC: UIViewController, UITextFieldDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Set Voice Change、Reverb、Beautify".localized
        
        self.channelIdTextField.delegate = self
    }
    
    @IBOutlet weak var channelIdTextField: UITextField!
    @IBAction func onJoinChannelBtnClicked(_ sender: Any) {
        guard let channelId = self.channelIdTextField.text, channelId.isEmpty == false else {
            return
        }
        
        let helper = ARTCTokenHelper()
        let userId = GlobalConfig.shared.userId
        let timestamp = Int64(Date().timeIntervalSince1970 + 24 * 60 * 60)
        let joinToken = helper.generateJoinToken(channelId: channelId, userId: userId, timestamp: timestamp)
        
        let vc = self.presentVC(storyboardName: "VoiceChange", storyboardId: "MainVC") as? VoiceChangeMainVC
        vc?.channelId = channelId
        vc?.userId = userId
        vc?.joinToken = joinToken
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}


class VoiceChangeMainVC: UIViewController {
    var isEnableEarBack: Bool = true
    
    let voiceChangeOptions = ["Off", "Old Man", "Baby Boy", "Baby Girl", "Robot", "Daimo", "KTV", "Echo", "Dialect", "How", "Electroinc", "Phonograph"]
    let reverbOptions = ["Off", "Vocal I", "Vocal II", "Bathroom", "Small Room Bright", "Small Room Dark", "Medium Room", "Large Room", "Church Hall"]
    let voiceBeautifyOptions = ["Off", "Vigorous", "Ringing"]
        
    
    @IBAction func onAudioEarBackSwitchToggled(_ sender: UISwitch) {
        self.rtcEngine?.enableEarBack(sender.isOn)
    }
    @IBOutlet weak var voiceChangeTextField: UITextField!
    @IBOutlet weak var reverbTextField: UITextField!
    @IBOutlet weak var voiceBeautifierTextField: UITextField!
    
    private let voiceChangePicker = UIPickerView()
    private let reverbPicker = UIPickerView()
    private let voiceBeautifierPicker = UIPickerView()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = self.channelId
        // 初始化Pickers
        setupPickers()
        
        self.setup()
        self.startPreview()
        self.joinChannel()
    }
    
    private func setupPickers() {
        // 变声选择器
        self.voiceChangeTextField.inputView = self.voiceChangePicker
        self.voiceChangePicker.dataSource = self
        self.voiceChangePicker.delegate = self
        self.voiceChangePicker.tag = 0
        
        // 混响选择器
        self.reverbTextField.inputView = self.reverbPicker
        self.reverbPicker.dataSource = self
        self.reverbPicker.delegate = self
        self.reverbPicker.tag = 1
        
        // 美声选择器
        self.voiceBeautifierTextField.inputView = self.voiceBeautifierPicker
        self.voiceBeautifierPicker.dataSource = self
        self.voiceBeautifierPicker.delegate = self
        self.voiceBeautifierPicker.tag = 2
        
        // 设置默认值
        self.voiceChangeTextField.text = self.voiceChangeOptions[0]
        self.reverbTextField.text = self.reverbOptions[0]
        self.voiceBeautifierTextField.text = self.voiceBeautifyOptions[0]
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissPickers))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    @objc func dismissKeyboardAndPickers() {
        self.voiceChangeTextField.resignFirstResponder()
        self.reverbTextField.resignFirstResponder()
        self.voiceBeautifierTextField.resignFirstResponder()
    }
    
    @objc func dismissPickers() {
        self.voiceChangeTextField.resignFirstResponder()
        self.reverbTextField.resignFirstResponder()
        self.voiceBeautifierTextField.resignFirstResponder()
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
        
        engine.enableEarBack(isEnableEarBack)
        
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
    
    // 设置变声效果
    func setVoiceChangeMode(_ mode: AliRtcAudioEffectVoiceChangerMode) {
        self.rtcEngine?.setAudioEffectVoiceChangerMode(mode)
    }
    
    // 设置混响效果
    func setReverbMode(_ mode: AliRtcAudioEffectReverbMode) {
        self.rtcEngine?.setAudioEffectReverbMode(mode)
    }
    
    // 设置美声效果
    func setVoiceBeautifyMode(_ mode: AliRtcAudioEffectBeautifyMode) {
        self.rtcEngine?.setAudioEffectBeautifyMode(mode)
    }
}

extension VoiceChangeMainVC: AliRtcEngineDelegate {
    
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

extension VoiceChangeMainVC: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView.tag {
        case 0: // voice change
            return self.voiceChangeOptions.count
        case 1: // reverb
            return self.reverbOptions.count
        case 2: // voice beautifier
            return self.voiceBeautifyOptions.count
        default:
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView.tag {
        case 0: // voice change
            return self.voiceChangeOptions[row]
        case 1: // reverb
            return self.reverbOptions[row]
        case 2: // voice beautifier
            return self.voiceBeautifyOptions[row]
        default:
            return nil
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView.tag {
        case 0: // voice change
            self.voiceChangeTextField.text = self.voiceChangeOptions[row]
            if let voiceChangeMode = AliRtcAudioEffectVoiceChangerMode(rawValue: Int(row)) {
                self.setVoiceChangeMode(voiceChangeMode)
            }
            // 选择后自动关闭选择器
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.voiceChangeTextField.resignFirstResponder()
            }
        case 1: // reverb
            self.reverbTextField.text = self.reverbOptions[row]
            // 获取对应的混响模式并设置
            if let reverbMode = AliRtcAudioEffectReverbMode(rawValue: Int(row)) {
                self.setReverbMode(reverbMode)
            }
            // 选择后自动关闭选择器
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.reverbTextField.resignFirstResponder()
            }
        case 2: // voice beautifier
            self.voiceBeautifierTextField.text = self.voiceBeautifyOptions[row]
            // 获取对应的美声模式并设置
            if let beautifyMode = AliRtcAudioEffectBeautifyMode(rawValue: Int(row)) {
                self.setVoiceBeautifyMode(beautifyMode)
            }
            // 选择后自动关闭选择器
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.voiceBeautifierTextField.resignFirstResponder()
            }
        default:
            break
        }
    }
}
