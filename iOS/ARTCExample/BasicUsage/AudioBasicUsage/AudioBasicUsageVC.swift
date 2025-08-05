//
//  AudioBasicUsageVC.swift
//  ARTCExample
//
//  Created by wy on 2025/6/11.
//

import Foundation
import AliVCSDK_ARTC
import UIKit

class AudioBasicUsageSetParamsVC: UIViewController, UITextFieldDelegate {
    
    // MARK: - IBOutlets
    @IBOutlet weak var audioRouteTextField: UITextField!
    @IBOutlet weak var audioScenarioTextField: UITextField!
    @IBOutlet weak var audioProfileTextFiled: UITextField!
    @IBOutlet weak var earBackSwitch: UISwitch!
    @IBOutlet weak var earBackVolumeSlider: UISlider!
    @IBOutlet weak var muteLocalMicSwitch: UISwitch!
    @IBOutlet weak var channelIDTextField: UITextField!
    @IBOutlet weak var joinRoomBtn: UIButton!

    // MARK: - UIPickerView
    let audioRouteOptions = ["Speaker".localized, "Earpiece".localized]
    let audioScenarioOptions = ["DEFAULT", "MUSIC"]
    let audioProfileOptions = ["LowQualityMode", "BasicQualityMode", "HighQualityMode", "StereoHighQualityMode", "SuperHighQualityMode", "StereoSuperHighQualityMode"]
    private let audioRoutePicker = UIPickerView()
    private let audioScenarioPicker = UIPickerView()
    private let audioProfilePicker = UIPickerView()
    
    
    // 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Audio Basic Usage".localized

        self.setupPickers()
        
        self.channelIDTextField.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboardAndPickers))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    private func setupPickers() {
        self.audioRouteTextField.inputView = self.audioRoutePicker
        self.audioRoutePicker.dataSource = self
        self.audioRoutePicker.delegate = self
        self.audioRoutePicker.tag = 0
        
        self.audioScenarioTextField.inputView = self.audioScenarioPicker
        self.audioScenarioPicker.dataSource = self
        self.audioScenarioPicker.delegate = self
        self.audioScenarioPicker.tag = 1

        self.audioProfileTextFiled.inputView = self.audioProfilePicker
        self.audioProfilePicker.dataSource = self
        self.audioProfilePicker.delegate = self
        self.audioProfilePicker.tag = 2
        
        // MARK: - 设置默认值
        self.audioRouteTextField.text = NSLocalizedString(self.audioRouteOptions[0], comment: "")
        self.audioScenarioTextField.text = self.audioScenarioOptions[1]
        self.audioProfileTextFiled.text = self.audioProfileOptions[2]
    }

    @objc func dismissKeyboardAndPickers() {
        self.audioRouteTextField.resignFirstResponder()
        self.audioScenarioTextField.resignFirstResponder()
        self.audioProfileTextFiled.resignFirstResponder()
    }
    
    @IBAction func joinRoomTapped(_ sender: Any) {
        
        guard let channelId = self.channelIDTextField.text, channelId.isEmpty == false else {
            return
        }
        
        let helper = ARTCTokenHelper()
        let userId = GlobalConfig.shared.userId
        let timestamp = Int64(Date().timeIntervalSince1970 + 24 * 60 * 60)
        let joinToken = helper.generateJoinToken(channelId: channelId, userId: userId, timestamp: timestamp)
        
        let vc = self.presentVC(storyboardName: "AudioBasicUsage", storyboardId: "MainVC") as? AudioBasicUsageMainVC
        vc?.channelId = channelId
        vc?.userId = userId
        vc?.joinToken = joinToken
        
        switch self.audioRouteTextField.text {
        case "Speaker".localized: vc?.enableSpeakerphone = true
        case "Earpiece".localized: vc?.enableSpeakerphone = false
        default: break
        }
        
        switch self.audioScenarioTextField.text {
        case "DEFAULT": vc?.currentAudioScenario = .sceneDefaultMode
        case "MUSIC": vc?.currentAudioScenario = .sceneMusicMode
        default: break
        }
        
        switch self.audioProfileTextFiled.text {
        case "LowQualityMode": vc?.currentAudioProfile = .engineLowQualityMode
        case "BasicQualityMode": vc?.currentAudioProfile = .engineBasicQualityMode
        case "HighQualityMode": vc?.currentAudioProfile = .engineHighQualityMode
        case "StereoHighQualityMode": vc?.currentAudioProfile = .engineStereoHighQualityMode
        case "SuperHighQualityMode": vc?.currentAudioProfile = .engineSuperHighQualityMode
        case "StereoSuperHighQualityMode": vc?.currentAudioProfile = .engineStereoSuperHighQualityMode
        default: break
        }

        vc?.enableEarBack = self.earBackSwitch.isOn
        vc?.earBackVolume = Int(self.earBackVolumeSlider.value)
        vc?.isMuteMic = self.muteLocalMicSwitch.isOn
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension AudioBasicUsageSetParamsVC: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView.tag {
        case 0:
            return self.audioRouteOptions.count
        case 1:
            return self.audioScenarioOptions.count
        case 2:
            return self.audioProfileOptions.count
        default:
            return 0
        }
    }
    
    // UIPickerViewDelegate Methods
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView.tag {
        case 0:
            return NSLocalizedString(self.audioRouteOptions[row], comment: "")
        case 1:
            return self.audioScenarioOptions[row]
        case 2:
            return self.audioProfileOptions[row]
        default:
            return nil
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView.tag {
        case 0:
            let selectedText = self.audioRouteOptions[row]
            self.audioRouteTextField.text = selectedText
            break
        case 1:
            let selectedText = self.audioScenarioOptions[row]
            self.audioScenarioTextField.text = selectedText
            break
        case 2:
            let selectedText = self.audioProfileOptions[row]
            self.audioProfileTextFiled.text = NSLocalizedString(selectedText, comment: "")
            break
        default:
            break
        }
    }
}



class AudioBasicUsageMainVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = self.channelId

        self.setup()
        // 给自己分配一个麦位
        _ = self.createSeatView(uid: self.userId)
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
    
    // MARK: - Parameters
    var currentAudioScenario: AliRtcAudioScenario = .sceneMusicMode
    var currentAudioProfile: AliRtcAudioProfile = .engineHighQualityMode
    var isMuteMic: Bool = false
    var playVolume: Int = 100
    var enableEarBack: Bool = false
    var earBackVolume: Int = 100
    var enableSpeakerphone: Bool = true
    var isMuteAllRemoteAudioPlaying: Bool = false
    var isStartCapture: Bool = true

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
        engine.setAudioProfile(self.currentAudioProfile, audio_scene: self.currentAudioScenario)

        // 发布本地音视频流（默认开启）
        engine.publishLocalAudioStream(true)
        engine.publishLocalVideoStream(false)

        // 设置默认订阅远端的音频
        engine.setDefaultSubscribeAllRemoteAudioStreams(true)
        engine.subscribeAllRemoteAudioStreams(true)
        
        // 设置音频属性
        engine.muteLocalMic(self.isMuteMic, mode: .allAudioMode)
        engine.enableSpeakerphone(self.enableSpeakerphone)
        engine.enableEarBack(self.enableEarBack)
        engine.setEarBackVolume(self.earBackVolume)
        engine.muteAllRemoteAudioPlaying(self.isMuteAllRemoteAudioPlaying)
                
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
    
    func leaveAnddestroyEngine() {
        self.rtcEngine?.leaveChannel()
        AliRtcEngine.destroy()
        self.rtcEngine = nil
    }
    
    
    func createSeatView(uid: String) -> SeatView {
        let view = SeatView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.seatInfo = SeatInfo(uid: uid)
        view.clickBlock = {[weak self] view in
            if view.seatInfo.uid == self?.userId {
                self?.showMyAudioActions()
            }
            else {
                self?.showRemoteAudioActions(seatView: view)
            }
        }
        
        self.contentScrollView.addSubview(view)
        self.seatViewList.append(view)
        self.updateSeatViewsLayout()
        return view
    }
    
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
    
    func showMyAudioActions() {
        let actions = [self.isStartCapture ? "Stop Mic Capture".localized : "Start Mic Capture".localized,
                       self.isMuteMic ? "Cancel Mute Mic".localized : "Mute Mic".localized,
                       "Set Play Volume".localized,
                       self.enableSpeakerphone ? "Earpiece".localized : "Speaker".localized,
                       self.enableEarBack ? "Disable EarBack".localized : "Enable EarBack".localized,
                       "Set EarBack Volume".localized,
                       self.isMuteAllRemoteAudioPlaying ? "Cancel Mute All Remote User".localized : "Mute All Remote User".localized,
        ]
        UIAlertController.showSheet(dataList: actions, vc: self) { index, value in
            
            if index == 0 {
                if self.isStartCapture {
                    self.rtcEngine?.stopAudioCapture()
                }
                else {
                    self.rtcEngine?.startAudioCapture()
                }
                self.isStartCapture = !self.isStartCapture
            }
            else if index == 1 {
                if (self.rtcEngine?.muteLocalMic(!self.isMuteMic, mode: .allAudioMode) == 0) {
                    self.isMuteMic = !self.isMuteMic
                }
            }
            else if index == 2 {
                UIAlertController.showInput(title: "Set Play Volume".localized, defaultValue: "\(self.playVolume)", viewController: self) { [weak self] input in
                    if let input = input, let volume = Int(input) {
                        if self?.rtcEngine?.setPlayoutVolume(volume) == 0 {
                            self?.playVolume = volume
                        }
                    }
                }
            }
            else if index == 3 {
                if (self.rtcEngine?.enableSpeakerphone(!self.enableSpeakerphone) == 0) {
                    self.enableSpeakerphone = !self.enableSpeakerphone
                }
            }
            else if index == 4 {
                if (self.rtcEngine?.enableEarBack(!self.enableEarBack) == 0) {
                    self.enableEarBack = !self.enableEarBack
                }
            }
            else if index == 5 {
                UIAlertController.showInput(title: "Set EarBack Volume".localized, defaultValue: "\(self.earBackVolume)", viewController: self) {[weak self] input in
                    if let input = input, let volume = Int(input) {
                        if self?.rtcEngine?.setEarBackVolume(volume) == 0 {
                            self?.earBackVolume = volume
                        }
                    }
                }
            }
            else if index == 6 {
                if (self.rtcEngine?.muteAllRemoteAudioPlaying(!self.isMuteAllRemoteAudioPlaying) == 0) {
                    self.isMuteAllRemoteAudioPlaying = !self.isMuteAllRemoteAudioPlaying
                }
            }
        }
    }
    
    func showRemoteAudioActions(seatView: SeatView) {
        let info = seatView.seatInfo
        let actions = [info.isMuteAudio ? "Cancel Mute Play".localized : "Mute Play".localized,
                       "Set Play Volume".localized
        ]
        UIAlertController.showSheet(dataList: actions, vc: self) { index, value in
            
            if index == 0 {
                if (self.rtcEngine?.muteRemoteAudioPlaying(seatView.seatInfo.uid, mute: !seatView.seatInfo.isMuteAudio) == 0) {
                    seatView.seatInfo.isMuteAudio = !seatView.seatInfo.isMuteAudio
                }
            }
            else if index == 1 {
                UIAlertController.showInput(title: "Set Play Volume".localized, defaultValue: "\(seatView.seatInfo.audioVolume)", viewController: self) {[weak self] input in
                    if let input = input, let volume = Int(input) {
                        if (self?.rtcEngine?.setRemoteAudioVolume(seatView.seatInfo.uid, volume: volume) == 0) {
                            seatView.seatInfo.audioVolume = volume
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func onActionsBtnClicked(_ sender: Any) {
        self.showMyAudioActions()
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

extension AudioBasicUsageMainVC: AliRtcEngineDelegate {
    
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
    
    func onUserAudioMuted(_ uid: String, audioMuted isMute: Bool) {
        // 远端用户静音
        "onUserAUdioMuted uid: \(uid), isMute: \(isMute)".printLog()
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
        else {
            self.removeSeatView(uid: uid)
        }
    }
    
    func onAuthInfoWillExpire() {
        "onAuthInfoWillExpire".printLog()
        
        /* TODO: 务必处理；Token即将过期，需要业务触发重新获取当前channel，user的鉴权信息，然后设置refreshAuthInfo即可 */
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
