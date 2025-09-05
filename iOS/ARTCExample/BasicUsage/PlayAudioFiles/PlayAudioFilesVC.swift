//
//  PlayAudioFiles.swift
//  ARTCExample
//
//  Created by wy on 2025/8/26.
//
import UIKit
import Foundation
import AliVCSDK_ARTC

class PlayAudioFilesSetParamsVC: UIViewController, UITextFieldDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Play Audio Files".localized
        
        self.channelIdTextField.delegate = self
    }
    
    
    @IBOutlet weak var channelIdTextField: UITextField!
    @IBAction func onJoinChannelBtnClicked(_ sender: UIButton) {
        guard let channelId = self.channelIdTextField.text, channelId.isEmpty == false else {
            return
        }
        
        let helper = ARTCTokenHelper()
        let userId = GlobalConfig.shared.userId
        let timestamp = Int64(Date().timeIntervalSince1970 + 24 * 60 * 60)
        let joinToken = helper.generateJoinToken(channelId: channelId, userId: userId, timestamp: timestamp)
        
        let vc = self.presentVC(storyboardName: "PlayAudioFiles", storyboardId: "MainVC") as? PlayAudioFilesMainVC
        vc?.channelId = channelId
        vc?.userId = userId
        vc?.joinToken = joinToken
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

class PlayAudioFilesMainVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = self.channelId
        
        self.initAudioControls()
        self.setupAudioEffectPicker()
        
        // 添加点击手势收起键盘
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        
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
    
    // Audio Accompany
    // 音频伴奏
    let AudioAccompanyFilePath = Bundle.main.path(forResource: "music", ofType: "wav")
    
    @IBOutlet weak var audioAccompanyFileLabel: UILabel!
    @IBOutlet weak var audioAccompanyVolumeSlider: UISlider!
    @IBAction func audioAccompanyVolumeSliderToggled(_ sender: Any) {
        guard let rtcEngine = self.rtcEngine else { return }
        let volume = Int(audioAccompanyVolumeSlider.value)
        rtcEngine.setAudioAccompanyVolume(volume)
    }
    @IBOutlet weak var audioAccompanyPublishVolumeSlider: UISlider!
    @IBAction func audioAccompanyPublishVolumeSliderToggled(_ sender: Any) {
        guard let rtcEngine = self.rtcEngine else { return }
        let volume = Int(audioAccompanyPublishVolumeSlider.value)
        rtcEngine.setAudioAccompanyPublishVolume(volume)
    }
    @IBOutlet weak var audioAccompanyPlayoutSlider: UISlider!
    @IBAction func audioAccompanyPlayoutVolumeSliderToggled(_ sender: Any) {
        guard let rtcEngine = self.rtcEngine else { return }
        let volume = Int(audioAccompanyPlayoutSlider.value)
        rtcEngine.setAudioAccompanyPlayoutVolume(volume)
    }
    @IBOutlet weak var audioAccompanyLoopCountText: UITextField!
    
    @IBAction func audioAccompanyStartBtnClicked(_ sender: UIButton) {
        guard let rtcEngine = self.rtcEngine else { return }
                
        guard let filePath = self.AudioAccompanyFilePath else {
            UIAlertController.showAlertWithMainThread(msg: "伴奏文件不存在", vc: self)
            return
        }
        
        let loopCount = Int32(audioAccompanyLoopCountText.text ?? "") ?? -1
        let publishVolume = Int32(audioAccompanyPublishVolumeSlider.value)
        let playoutVolume = Int32(audioAccompanyPlayoutSlider.value)
        
        let config = AliRtcAudioAccompanyConfig()
        config.loopCycles = loopCount
        config.publishVolume = publishVolume
        config.playoutVolume = playoutVolume
        config.startPosMs = 0
        
        let result = rtcEngine.startAudioAccompany(withFile: filePath, config: config)
        if result != 0 {
            UIAlertController.showAlertWithMainThread(msg: "播放伴奏失败，错误码: \(result)", vc: self)
        }
    }
    @IBAction func audioAccompanyPauseClicked(_ sender: UIButton) {
        guard let rtcEngine = self.rtcEngine else { return }
        rtcEngine.pauseAudioAccompany()
    }
    @IBAction func audioAccompanyResumeClicked(_ sender: UIButton) {
        guard let rtcEngine = self.rtcEngine else { return }
        rtcEngine.resumeAudioAccompany()
    }
    @IBAction func audioAccompanyStopClicked(_ sender: UIButton) {
        guard let rtcEngine = self.rtcEngine else { return }
        rtcEngine.stopAudioAccompany()
    }
    // Audio Effects
    // 音频音效
    let effect1FilePath = Bundle.main.path(forResource: "thunder", ofType: "wav")
    let effect2FilePath = Bundle.main.path(forResource: "applause", ofType: "wav")
    var currentEffectIndex : Int = 1
    @IBOutlet weak var audioEffectTextField: UITextField!
    @IBOutlet weak var audioEffectVolumeSlider: UISlider!
    @IBAction func audioEffectVolumeSliderToggled(_ sender: Any) {
        guard let rtcEngine = self.rtcEngine else { return }
        let volume = Int(audioEffectVolumeSlider.value)
        rtcEngine.setAudioEffectPublishVolumeWithSoundId(self.currentEffectIndex, volume: volume)
        rtcEngine.setAudioEffectPlayoutVolumeWithSoundId(self.currentEffectIndex, volume: volume)
    }
    @IBOutlet weak var audioEffectLoopCountTextField: UITextField!
    @IBAction func audioEffectPreloadBtnClicked(_ sender: UIButton) {
        guard let rtcEngine = self.rtcEngine else { return }
                
        let filePath = self.currentEffectIndex == 1 ? self.effect1FilePath : self.effect2FilePath
        guard let filePath = filePath else {
            UIAlertController.showAlertWithMainThread(msg: "音效文件不存在", vc: self)
            return
        }
        // soundId为业务自行组织的音效唯一标识
        rtcEngine.preloadAudioEffect(withSoundId: self.currentEffectIndex, filePath: filePath)
    }
    @IBAction func audioEffectUnloadBtnClicked(_ sender: UIButton) {
        guard let rtcEngine = self.rtcEngine else { return }
        rtcEngine.unloadAudioEffect(withSoundId: self.currentEffectIndex)
    }
    
    @IBAction func audioEffectStartBtnClicked(_ sender: UIButton) {
        guard let rtcEngine = self.rtcEngine else { return }
                
        let filePath = self.currentEffectIndex == 1 ? self.effect1FilePath : self.effect2FilePath
        guard let filePath = filePath else {
            UIAlertController.showAlertWithMainThread(msg: "音效文件不存在", vc: self)
            return
        }
        
        let loopCount = Int32(audioEffectLoopCountTextField.text ?? "") ?? 1
        let volume = Int32(audioEffectVolumeSlider.value)
        
        let config = AliRtcAudioEffectConfig()
        config.loopCycles = loopCount
        config.publishVolume = volume
        config.playoutVolume = volume
        let result = rtcEngine.playAudioEffect(withSoundId: self.currentEffectIndex, filePath: filePath, config: config)
        if result != 0 {
            UIAlertController.showAlertWithMainThread(msg: "播放音效失败，错误码: \(result)", vc: self)
        }
    }
    @IBAction func audioEffectPauseBtnClicked(_ sender: UIButton) {
        guard let rtcEngine = self.rtcEngine else { return }
        rtcEngine.pauseAudioEffect(withSoundId: self.currentEffectIndex)
    }
    @IBAction func audioEffectResumeBtnClicked(_ sender: UIButton) {
        guard let rtcEngine = self.rtcEngine else { return }
        rtcEngine.resumeAudioEffect(withSoundId: self.currentEffectIndex)
    }
    @IBAction func audioEffectStopBtnClicked(_ sender: UIButton) {
        guard let rtcEngine = self.rtcEngine else { return }
        rtcEngine.stopAudioEffect(withSoundId: self.currentEffectIndex)
    }
    
    @IBOutlet weak var allAudioEffectsVolumeSlider: UISlider!
    @IBAction func allAudioEffectsVolumeSliderToggled(_ sender: Any) {
        guard let rtcEngine = self.rtcEngine else { return }
        let volume = Int(allAudioEffectsVolumeSlider.value)
        rtcEngine.setAllAudioEffectsPlayoutVolume(volume)
        rtcEngine.setAllAudioEffectsPublishVolume(volume)
    }
    @IBAction func audioEffectStopAllBtnClicked(_ sender: UIButton) {
        guard let rtcEngine = self.rtcEngine else { return }
        rtcEngine.stopAllAudioEffects()
    }
    @IBAction func audioEffectPauseAllBtnClicked(_ sender: UIButton) {
        guard let rtcEngine = self.rtcEngine else { return }
        rtcEngine.pauseAllAudioEffects()
    }
    @IBAction func audioEffectResumeAllBtnClicked(_ sender: UIButton) {
        guard let rtcEngine = self.rtcEngine else { return }
        rtcEngine.resumeAllAudioEffects()
    }
    
    // UIPickerView for audio effects
   lazy var audioEffectPicker: UIPickerView = {
       let picker = UIPickerView()
       picker.delegate = self
       picker.dataSource = self
       return picker
   }()
   
   // Toolbar for picker
   lazy var toolbar: UIToolbar = {
       let toolbar = UIToolbar()
       toolbar.barStyle = .default
       toolbar.isTranslucent = true
       toolbar.sizeToFit()
       
       let doneButton = UIBarButtonItem(
           title: "完成",
           style: .done,
           target: self,
           action: #selector(self.donePicker)
       )
       
       let spaceButton = UIBarButtonItem(
           barButtonSystemItem: .flexibleSpace,
           target: nil,
           action: nil
       )
       
       let cancelButton = UIBarButtonItem(
           title: "取消",
           style: .plain,
           target: self,
           action: #selector(self.cancelPicker)
       )
       
       toolbar.setItems([cancelButton, spaceButton, doneButton], animated: false)
       toolbar.isUserInteractionEnabled = true
       
       return toolbar
   }()
    
    // Setup the audio effect picker
    func setupAudioEffectPicker() {
        audioEffectTextField.delegate = self
        audioEffectTextField.inputView = audioEffectPicker
        audioEffectTextField.inputAccessoryView = toolbar
        audioEffectTextField.text = "音效 1 (thunder.wav)"
        
        // Set border style for better UI
        audioEffectTextField.borderStyle = .roundedRect
        
        audioEffectPicker.selectRow(0, inComponent: 0, animated: false)
    }
    
    @objc func donePicker() {
        let row = audioEffectPicker.selectedRow(inComponent: 0)
        currentEffectIndex = row + 1
        updateEffectUI()
        self.view.endEditing(true)
    }
    
    @objc func cancelPicker() {
        audioEffectPicker.selectRow(currentEffectIndex - 1, inComponent: 0, animated: true)
        self.view.endEditing(true)
    }
    
    func updateEffectUI() {
        switch currentEffectIndex {
        case 1:
            audioEffectTextField.text = "音效 1 (thunder.wav)"
        case 2:
            audioEffectTextField.text = "音效 2 (applause.wav)"
        default:
            break
        }
        if let volume = self.rtcEngine?.getAudioEffectPlayoutVolume(withSoundId: self.currentEffectIndex) {
            if(volume >= 0 && volume <= 100) {
                self.audioEffectVolumeSlider.value = Float(volume)
            }
        } else {
            self.audioEffectVolumeSlider.value = 50.0
        }

    }
    
    // 初始化音频控件
   func initAudioControls() {
       // 初始化伴奏控件
       if let filePath = self.AudioAccompanyFilePath {
           self.audioAccompanyFileLabel.text = (filePath as NSString).lastPathComponent
       }
       
       // 初始化音效选择器
       self.audioEffectPicker.delegate = self
       self.audioEffectPicker.dataSource = self
       
       // 设置音量范围及默认值
       self.audioAccompanyVolumeSlider.minimumValue = 0
       self.audioAccompanyVolumeSlider.maximumValue = 100
       self.audioAccompanyVolumeSlider.value = 50
       self.audioAccompanyPublishVolumeSlider.minimumValue = 0
       self.audioAccompanyPublishVolumeSlider.maximumValue = 100
       self.audioAccompanyPublishVolumeSlider.value = 50
       self.audioAccompanyPlayoutSlider.minimumValue = 0
       self.audioAccompanyPlayoutSlider.maximumValue = 100
       self.audioAccompanyPlayoutSlider.value = 50
       self.audioAccompanyLoopCountText.text = "-1"
       
       self.audioEffectVolumeSlider.minimumValue = 0
       self.audioEffectVolumeSlider.maximumValue = 100
       self.audioEffectVolumeSlider.value = 50
       self.audioEffectLoopCountTextField.text = "1"
       self.allAudioEffectsVolumeSlider.minimumValue = 0
       self.allAudioEffectsVolumeSlider.maximumValue = 100
       self.allAudioEffectsVolumeSlider.value = 50
       
       // 设置文本框
       self.audioAccompanyLoopCountText.delegate = self
       self.audioEffectTextField.delegate = self
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
    
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
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
// MARK: - UIPickerViewDataSource & UIPickerViewDelegate
extension PlayAudioFilesMainVC: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch row {
        case 0:
            return "音效 1 (thunder.wav)"
        case 1:
            return "音效 2 (applause.wav)"
        default:
            return nil
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        currentEffectIndex = row + 1
        updateEffectUI()
    }
}

// MARK: - UITextFieldDelegate
extension PlayAudioFilesMainVC: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == audioEffectTextField {
            // Set the picker to the current selection
            audioEffectPicker.selectRow(currentEffectIndex - 1, inComponent: 0, animated: false)
            return true
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension PlayAudioFilesMainVC: AliRtcEngineDelegate {
    
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
