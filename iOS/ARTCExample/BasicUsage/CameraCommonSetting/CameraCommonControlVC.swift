//
//  CameraCommonControlVC.swift
//  ARTCExample
//
//  Created by wy on 2025/7/8.
//

import Foundation
import AliVCSDK_ARTC

class CameraCommonControlSetParamsVC: UIViewController, UITextFieldDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Camera Common Control".localized
        
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
        
        let vc = self.presentVC(storyboardName: "CameraCommonControl", storyboardId: "MainVC") as? CameraCommonControlMainVC
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



class CameraCommonControlMainVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = self.channelId
        self.setup()
        self.startPreview()
        self.joinChannel()
        
        self.contentScrollView.isPagingEnabled = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.updateSeatViewsLayout()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.leaveAnddestroyEngine()
    }
    // MARK: UI
    @IBOutlet weak var contentScrollView: UIScrollView!
    var seatViewList: [SeatView] = []
    
    @IBOutlet weak var cameraDirectionSegmentedControl: UISegmentedControl!
    @IBAction func onCameraDirectionChanged(_ sender: UISegmentedControl) {
        
        if self.rtcEngine?.getCurrentCameraDirection() == .back {
            // 由于当前手后置摄像头，即将切换到前置摄像头，先关闭闪光灯
            self.cameraFlashSwitch.isOn = false
            self.rtcEngine?.setCameraFlash(false)
        }
        
        self.rtcEngine?.switchCamera()
        
        self.updateCameraUI()
    }
    
    func updateCameraUI() {
        guard let rtcEngine = self.rtcEngine else {
            return
        }
        // Zoom
        self.cameraZoomSlider.isEnabled = true
        let maxZoom = rtcEngine.getCameraMaxZoomFactor()
        let currZoom = rtcEngine.getCurrentZoom()
        "Get maxZoom=\(maxZoom), currZoom=\(currZoom)".printLog()

        self.cameraZoomSlider.minimumValue = 1.0
        if maxZoom > 1.0 {
            self.cameraZoomSlider.maximumValue = maxZoom
        } else {
            self.cameraZoomSlider.isEnabled = false
        }
        if currZoom >= 1.0 && currZoom <= maxZoom {
            self.cameraZoomSlider.value = currZoom
            self.cameraZoomValueLabel.text = String(format: "%.1f", self.cameraZoomSlider.value)
        }
        else {
            self.cameraZoomSlider.value = self.cameraZoomSlider.minimumValue
            self.cameraZoomValueLabel.text = "\(self.cameraZoomSlider.minimumValue)"
        }
        
        
        // Exposure
        self.cameraExposureSlider.isEnabled = true
        let minExposure = rtcEngine.getMinExposure()
        let maxExposure = rtcEngine.getMaxExposure()
        let currExposure = rtcEngine.getCurrentExposure()
        "Get minExposure=\(minExposure), maxExposure=\(maxExposure), currExposure=\(currExposure)".printLog()
        if maxExposure > minExposure {
            self.cameraExposureSlider.minimumValue = minExposure
            self.cameraExposureSlider.maximumValue = maxExposure
        } else {
            self.cameraExposureSlider.isEnabled = false
        }
        if currExposure >= minExposure && currExposure <= maxExposure {
            self.cameraExposureSlider.value = currExposure
            self.cameraExposureValueLabel.text = String(format: "%.1f", self.cameraExposureSlider.value)
        }
        else {
            self.cameraExposureSlider.value = self.cameraExposureSlider.minimumValue
            self.cameraExposureValueLabel.text = "\(self.cameraExposureSlider.minimumValue)"
        }
        
        let isCameraExposurePointSupported = rtcEngine.isCameraExposurePointSupported()
        "Get isCameraExposurePointSupported=\(isCameraExposurePointSupported)".printLog()
        self.cameraExposurePointXTextField.text = isCameraExposurePointSupported ? "" : "Not Support"
        self.cameraExposurePointYTextField.text = ""
        self.cameraExposurePointYTextField.isHidden = !isCameraExposurePointSupported
        self.cameraExposurePointXTextField.updateConstraintsIfNeeded()
        self.cameraExposurePointYTextField.updateConstraintsIfNeeded()
        
        let isCameraFocusPointSupported = rtcEngine.isCameraFocusPointSupported()
        "Get isCameraFocusPointSupported=\(isCameraFocusPointSupported)".printLog()
        self.cameraFocusPointXTextField.text = isCameraFocusPointSupported ? "" : "Not Support"
        self.cameraFocusPointYTextField.text = ""
        self.cameraFocusPointYTextField.isHidden = !isCameraFocusPointSupported
        self.cameraFocusPointXTextField.updateConstraintsIfNeeded()
        self.cameraFocusPointYTextField.updateConstraintsIfNeeded()
        
        let isCameraAutoFocusFaceModeSupported = rtcEngine.isCameraAutoFocusFaceModeSupported()
        "Get isCameraAutoFocusFaceModeSupported=\(isCameraAutoFocusFaceModeSupported)".printLog()
        self.cameraAudoFocusFaceModeSwitch.isEnabled = isCameraAutoFocusFaceModeSupported
        
        if rtcEngine.getCurrentCameraDirection() == .back {
            self.cameraFlashSwitch.isEnabled = true
        }
        else {
            self.cameraFlashSwitch.isEnabled = false
        }
    }
    
    @IBOutlet weak var cameraZoomSlider: UISlider!
    @IBOutlet weak var cameraZoomValueLabel: UILabel!
    @IBAction func onCameraZoomChanged(_ sender: UISlider) {
        let currValue = sender.value
        self.cameraZoomValueLabel.text = String(format: "%.1f", currValue)
        self.rtcEngine?.setCameraZoom(currValue)
    }
    
    @IBOutlet weak var cameraExposureValueLabel: UILabel!
    @IBOutlet weak var cameraExposureSlider: UISlider!
    @IBAction func onCameraExposureChanged(_ sender: UISlider) {
        let currValue = sender.value
        self.cameraExposureValueLabel.text = String(format: "%.1f", currValue)
        self.rtcEngine?.setExposure(currValue)
    }
    
    @IBOutlet weak var cameraExposurePointXTextField: UITextField!
    
    @IBOutlet weak var cameraExposurePointYTextField: UITextField!
    
    @IBOutlet weak var cameraFocusPointXTextField: UITextField!
    
    @IBOutlet weak var cameraFocusPointYTextField: UITextField!
    
    @IBOutlet weak var cameraAudoFocusFaceModeSwitch: UISwitch!
    @IBAction func onCameraAudoFocusSwitch(_ sender: UISwitch) {
        if ((self.rtcEngine?.isCameraAutoFocusFaceModeSupported()) != nil) {
            self.rtcEngine?.setCameraAutoFocusFaceModeEnabled(sender.isOn)
        }
    }
    @IBOutlet weak var cameraFlashSwitch: UISwitch!
    @IBAction func onCameraFlashSwitch(_ sender: UISwitch) {
        if self.rtcEngine?.getCurrentCameraDirection() == .back {
            self.rtcEngine?.setCameraFlash(sender.isOn)
        }
    }
    
    
    // MARK: SDK JoinChannel Param
    var channelId: String = ""
    var userId: String = ""
    
    var rtcEngine: AliRtcEngine? = nil

    var joinToken: String? = nil
    
    var localPreviewSeatView: SeatView? = nil
    
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
        self.localPreviewSeatView = seatView
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSeatViewDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        seatView.addGestureRecognizer(doubleTapGesture)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSeatViewTap(_:)))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.require(toFail: doubleTapGesture)
        seatView.addGestureRecognizer(tapGesture)
        seatView.isUserInteractionEnabled = true
        
        let canvas = AliVideoCanvas()
        canvas.view = seatView.canvasView
        canvas.renderMode = .auto
        canvas.mirrorMode = .onlyFrontCameraPreviewEnabled
        canvas.rotationMode = ._0
        
        self.rtcEngine?.setLocalViewConfig(canvas, for: AliRtcVideoTrack.camera)
        self.rtcEngine?.startPreview()
    }
    
    @objc func handleSeatViewTap(_ gesture: UITapGestureRecognizer) {
        guard let localSeatView = self.localPreviewSeatView else {
            return
        }
        guard let rtcEngine = self.rtcEngine, rtcEngine.isCameraExposurePointSupported() else { return }
        
        
        let tapPoint = gesture.location(in: localSeatView)
        // 将点击坐标转换为视频帧的归一化坐标（0~1 范围）
        let normalizedX = tapPoint.x / localSeatView.bounds.width
        let normalizedY = tapPoint.y / localSeatView.bounds.height
        
        rtcEngine.setCameraExposurePoint(CGPoint(x: normalizedX, y: normalizedY))
        self.cameraExposurePointXTextField.text = String(format: "%.2f", normalizedX)
        self.cameraExposurePointYTextField.text = String(format: "%.2f", normalizedY)
    }
    
    @objc func handleSeatViewDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard let localSeatView = self.localPreviewSeatView else {
            return
        }
        guard let rtcEngine = self.rtcEngine, rtcEngine.isCameraFocusPointSupported() else { return }
        
        let tapPoint = gesture.location(in: localSeatView)
        // 将点击坐标转换为视频帧的归一化坐标（0~1 范围）
        let normalizedX = tapPoint.x / localSeatView.bounds.width
        let normalizedY = tapPoint.y / localSeatView.bounds.height
        
        rtcEngine.setCameraFocus(CGPoint(x: normalizedX, y: normalizedY))
        self.cameraFocusPointXTextField.text = String(format: "%.2f", normalizedX)
        self.cameraFocusPointYTextField.text = String(format: "%.2f", normalizedY)
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
        let count: Int = 1
        let margin = 0.0
        let width = (self.contentScrollView.bounds.width - margin * Double(count + 1)) / Double(count)
        let height = self.contentScrollView.bounds.height
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

extension CameraCommonControlMainVC: AliRtcEngineDelegate {
    
    func onJoinChannelResult(_ result: Int32, channel: String, elapsed: Int32) {
        "onJoinChannelResult1 result: \(result)".printLog()
    }
    
    func onJoinChannelResult(_ result: Int32, channel: String, userId: String, elapsed: Int32) {
        "onJoinChannelResult2 result: \(result)".printLog()
    }
    
    func onFirstLocalVideoFrameDrawn(_ width: Int32, height: Int32, elapsed: Int32) {
        "onFirstLocalVideoFrameDrawn".printLog()
        self.updateCameraUI()
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
