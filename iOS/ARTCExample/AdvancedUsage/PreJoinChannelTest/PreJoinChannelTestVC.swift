//
//  PreJoinChannelTestVC.swift
//  ARTCExample
//
//  Created by wy on 2025/8/27.
//

import Foundation
import AliVCSDK_ARTC

class PreJoinChannelTestSetParamsVC: UIViewController, UITextFieldDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Pre-Join Channel Test".localized
        
        self.channelIdTextField.delegate = self
        
        self.setup()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.updateSeatViewsLayout()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.leaveAnddestroyEngine()
    }
    
    @IBOutlet weak var channelIdTextField: UITextField!
    
    @IBAction func onJoinChannelBtnClicked(_ sender: Any) {
        guard let channelId = self.channelIdTextField.text, channelId.isEmpty == false else {
            return
        }
        self.channelId = channelId
        let helper = ARTCTokenHelper()
        self.userId = GlobalConfig.shared.userId
        let timestamp = Int64(Date().timeIntervalSince1970 + 24 * 60 * 60)
        self.joinToken = helper.generateJoinToken(channelId: channelId, userId: userId, timestamp: timestamp)
        
        if (self.rtcEngine == nil) {
            self.setup()
        }
        self.startPreview()
        self.joinChannel()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // 通话前设备检测
    var isTestingMicrophone = false
    var hasAppendedMicVolumeResult = false
    
    var isTestingSpeaker = false
    let testSpeakerFilePath: String? = Bundle.main.path(forResource: "music", ofType: "wav")
    
    var isTestingCamera = false
    @IBOutlet weak var testDeviceTextView: UITextView!
    @IBOutlet weak var testMicrophoneBtn: UIButton!
    @IBAction func testMicrophoneBtnClicked(_ sender: UIButton) {
        guard let engine = self.rtcEngine else {return}
        
        if !isTestingMicrophone {
            engine.startAudioCaptureTest()
            testMicrophoneBtn.setTitle("Stop Test".localized, for: .normal)
            isTestingMicrophone = true
            hasAppendedMicVolumeResult = false
            appendToDeviceTestResult("startAudioCaptureTest\n")
        } else {
            engine.stopAudioCaptureTest()
            testMicrophoneBtn.setTitle("Test Microphone".localized, for: .normal)
            isTestingMicrophone = false
            appendToDeviceTestResult("stopAudioCaptureTest\n")
        }
    }
    
    @IBOutlet weak var testSpeakderBtn: UIButton!
    @IBAction func testSpeakerBtnClicked(_ sender: UIButton) {
        guard let engine = rtcEngine else { return }
                
        if !isTestingSpeaker {
            guard let audioFilePath = testSpeakerFilePath else {
                showAlert(message: "Can not find Audio File")
                return
            }
            let result = engine.playAudioFileTest(audioFilePath)
            if result == 0 {
                testSpeakderBtn.setTitle("Stop Test".localized, for: .normal)
                isTestingSpeaker = true
                appendToDeviceTestResult("playAudioFileTest Result: \(result)\n")
            } else {
                showAlert(message: "播放文件失败")
                appendToDeviceTestResult("playAudioFileTest Failed with code: \(result)\n")
            }
        } else {
            let result = engine.stopAudioFileTest()
            testSpeakderBtn.setTitle("Test Speaker".localized, for: .normal)
            isTestingSpeaker = false
            appendToDeviceTestResult("stopAudioFileTest Result: \(result)\n")
        }
    }
    
    @IBOutlet weak var testCameraBtn: UIButton!
    @IBAction func testCameraBtnClicked(_ sender: UIButton) {
        guard let engine = rtcEngine else { return }
                
        if !isTestingCamera {
            startPreview()
            testCameraBtn.setTitle("Stop Test".localized, for: .normal)
            isTestingCamera = true
            appendToDeviceTestResult("startPreview\n")
        } else {
            engine.setLocalViewConfig(nil, for: .camera)
            engine.stopPreview()
            testCameraBtn.setTitle("Test Camera".localized, for: .normal)
            isTestingCamera = false
            
            // 移除预览视图
            if let localSeatView = seatViewList.first(where: { $0.uidLabel.text == userId }) {
                localSeatView.removeFromSuperview()
                seatViewList.removeAll { $0 == localSeatView }
                updateSeatViewsLayout()
            }
            appendToDeviceTestResult("stopPreview\n")
        }
    }
    
    // 通话前网络检测
    var isTestingNetwork = false
    @IBOutlet weak var testNetworkTextView: UITextView!
    @IBOutlet weak var testNetworkBtn: UIButton!
    @IBAction func testNetworkBtnClicked(_ sender: UIButton) {
        guard let engine = rtcEngine else { return }
                
        if !isTestingNetwork {
            let config = AliRtcNetworkQualityProbeConfig()
            config.probeUplink = true
            config.probeDownlink = true
            engine.startLastmileDetect(config)
            testNetworkBtn.setTitle("Stop Test".localized, for: .normal)
            isTestingNetwork = true
            appendToNetworkTestResult("startNetworkQualityProbeTest\n")
        } else {
            engine.stopLastmileDetect()
            testNetworkBtn.setTitle("Test Network".localized, for: .normal)
            isTestingNetwork = false
            appendToNetworkTestResult("stopNetworkQualityProbeTest\n")
        }
    }
    
    // 视频画面显示区域
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
    
    private func appendToDeviceTestResult(_ text: String) {
        testDeviceTextView.text.append(text)
        scrollToBottom(textView: testDeviceTextView)
    }
    
    private func appendToNetworkTestResult(_ text: String) {
        testNetworkTextView.text.append(text)
        scrollToBottom(textView: testNetworkTextView)
    }
    
    private func scrollToBottom(textView: UITextView) {
        let bottom = NSMakeRange(textView.text.count - 1, 1)
        textView.scrollRangeToVisible(bottom)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
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

extension PreJoinChannelTestSetParamsVC: AliRtcEngineDelegate {
    
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
    
    // 通话前麦克风测试音量数据回调
    func onTestAudioVolumeCallback(_ volume: Int32) {
        if !hasAppendedMicVolumeResult {
            hasAppendedMicVolumeResult = true
            let msg = "OnTestAudioVolume volume: \(volume), the mic is valid!\n"
            DispatchQueue.main.async {
                self.testDeviceTextView.text.append(msg)
                self.scrollToBottom(textView: self.testDeviceTextView)
            }
        }
    }
    
    func onConnectionStatusChange(_ status: AliRtcConnectionStatus, reason: AliRtcConnectionStatusChangeReason) {
        "onConnectionStatusChange status: \(status)  reason: \(reason)".printLog()

        if status == .failed {
            /* TODO: 务必处理；建议业务提示用户，此时SDK内部已经尝试了各种恢复策略已经无法继续使用时才会上报 */
        }
        else {
            /* TODO: 可选处理；增加业务代码，一般用于数据统计、UI变化 */
        }
        
        let msg = "onConnectionStatusChange status: \(status), reason: \(reason)\n"
        DispatchQueue.main.async {
            self.testDeviceTextView.text.append(msg)
            self.scrollToBottom(textView: self.testDeviceTextView)
        }
    }
    
    
    // 网络质量回调 startLastmileDetect后约3s触发
    func onLastmileDetectResult(with networkQuality: AliRtcNetworkQuality) {
        let qualityString: String
        switch networkQuality {
        case .AlivcRtcNetworkQualityExcellent:
            qualityString = "极好"
        case .AlivcRtcNetworkQualityGood:
            qualityString = "好"
        case .AlivcRtcNetworkQualityPoor:
            qualityString = "一般"
        case .AlivcRtcNetworkQualityBad:
            qualityString = "差"
        case .AlivcRtcNetworkQualityVeryBad:
            qualityString = "极差"
        case .AlivcRtcNetworkQualityDisconnect:
            qualityString = "断开"
        default:
            qualityString = "未知"
        }
        
        let msg = "OnNetworkQualityProbeTest quality: \(qualityString)\n"
        DispatchQueue.main.async {
            self.testNetworkTextView.text.append(msg)
            self.scrollToBottom(textView: self.testNetworkTextView)
        }
    }
    
    // 网络质量详细信息回调 startLastmileDetect后约30s触发
    func onLastmileDetectResult(withBandWidth code: Int32, result: AliRtcNetworkQualityProbeResult) {
        let msg = """
        网络质量测试结果:
          状态码: \(code)          往返延迟(RTT): \(result.rtt) ms
          上行丢包率: \(result.upLinkLossRate)%
          上行抖动: \(result.upLinkJitter) ms
          上行带宽: \(result.upLinkBandWidth) kbps
          下行丢包率: \(result.downLinkLossRate)%
          下行抖动: \(result.downLinkJitter) ms
          下行带宽: \(result.downLinkBandWidth) kbps
        """
        
        DispatchQueue.main.async {
            self.testNetworkTextView.text.append(msg + "\n")
            self.scrollToBottom(textView: self.testNetworkTextView)
        }
    }
}
