//
//  CustomVideoRenderVC.swift
//  ARTCExample
//
//  Created by wy on 2025/8/27.
//

import Foundation
import UIKit
import MetalKit
import AliVCSDK_ARTC

class CustomVideoRenderSetParamsVC: UIViewController, UITextFieldDelegate {
    
    var aliRtcRemoteVideoSampleFormat: AliRtcVideoFormat = .cvPixelBuffer
    var isEnableTextureCallback: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Custom Video Render".localized
        
        self.channelIdTextField.delegate = self
    }
    
    @IBOutlet weak var channelIdTextField: UITextField!
    @IBOutlet weak var customVideoRenderSwitch: UISwitch!
    @IBAction func onLocalVideoSampleFormatSegmentedControlToggled(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            isEnableTextureCallback = false
        case 1:
            isEnableTextureCallback = true
        default:
            isEnableTextureCallback = true
        }
    }
    
    @IBAction func onJoinChannelBtnClicked(_ sender: Any) {
        guard let channelId = self.channelIdTextField.text, channelId.isEmpty == false else {
            return
        }
        
        let helper = ARTCTokenHelper()
        let userId = GlobalConfig.shared.userId
        let timestamp = Int64(Date().timeIntervalSince1970 + 24 * 60 * 60)
        let joinToken = helper.generateJoinToken(channelId: channelId, userId: userId, timestamp: timestamp)
        
        let vc = self.presentVC(storyboardName: "CustomVideoRender", storyboardId: "MainVC") as? CustomVideoRenderMainVC
        vc?.channelId = channelId
        vc?.userId = userId
        vc?.joinToken = joinToken
        vc?.isEnableCustomVideoRender = customVideoRenderSwitch.isOn
        vc?.isEnableTextureCallback = isEnableTextureCallback
        vc?.aliRtcVideoFormat = aliRtcRemoteVideoSampleFormat
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

class CustomVideoRenderMainVC: UIViewController {

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
    
    @IBOutlet weak var contentScrollView: UIScrollView!
    var seatViewList: [CustomVideoRenderSeatView] = []
    
    var channelId: String = ""
    var userId: String = ""
    
    var rtcEngine: AliRtcEngine? = nil

    var joinToken: String? = nil
    var isEnableCustomVideoRender: Bool = true
    var isEnableTextureCallback: Bool = false
    var aliRtcVideoFormat: AliRtcVideoFormat = .I420
    
    func setup() {
        // 创建引擎对象时控制是否开启自定义视频渲染
        var customVideoRenderConfig: [String: String] = [:]
        if isEnableCustomVideoRender {
            // 自定义视频渲染开关
            customVideoRenderConfig["user_specified_use_external_video_render"] = "TRUE"
            // 是否允许回调cvPixelBuffer
            customVideoRenderConfig["user_specified_native_buffer_observer"] = "TRUE"
        }
        // 序列化为Json
        guard let jsonData = try? JSONSerialization.data(withJSONObject: customVideoRenderConfig, options: []),
              let extras = String(data: jsonData, encoding: .utf8) else {
            print("JSON 序列化失败")
            return
        }

        // 创建并初始化引擎
        let engine = AliRtcEngine.sharedInstance(self, extras:extras)
        
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
        
        // 注册视频数据回调
        if isEnableCustomVideoRender {
            engine.registerVideoSampleObserver()
            if isEnableTextureCallback {
                engine.registerLocalVideoTexture()
            }
        }
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
        canvas.view = seatView.renderingView
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
    func createSeatView(uid: String) -> CustomVideoRenderSeatView {
        let view = CustomVideoRenderSeatView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.uid = uid
        
        self.contentScrollView.addSubview(view)
        self.seatViewList.append(view)
        self.updateSeatViewsLayout()
        return view
    }
    
    // 从contentScrollView移除一个视频通话渲染视图
    func removeSeatView(uid: String) {
        let seatView = self.seatViewList.first { $0.uid == uid }
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

extension CustomVideoRenderMainVC: AliRtcEngineDelegate {
    
    // 视频输出的节点
    func onGetVideoObservedFramePosition() -> Int {
        let captureFlag = AliRtcVideoObserPosition.positionPostCapture.rawValue
        let preRenderFlag = AliRtcVideoObserPosition.positionPreRender.rawValue
        var ret = 0
        ret |= captureFlag
        ret |= preRenderFlag
        return ret
    }
    // 视频输出的格式
    func onGetVideoFormatPreference() -> AliRtcVideoFormat {
        return aliRtcVideoFormat
    }
    
    // 本地采集视频数据回调，默认只返回CVPixelBuffer
    func onCaptureVideoSample(_ videoSource: AliRtcVideoSource, videoSample: AliRtcVideoDataSample) -> Bool {
        // 如果启用了纹理渲染，则不使用此回调
        if isEnableTextureCallback {
            return false
        }
        var seatView = self.seatViewList.first { $0.uid == self.userId}
        if seatView == nil {
            seatView = self.createSeatView(uid: self.userId)
        }
        
        switch videoSample.type {
        case .cvPixelBuffer:
            self.renderCVPixelBuffer(videoSample, on: seatView!)
        case .raw_Data:
            switch videoSample.format {
            case .I420:
                self.renderI420Data(videoSample, on: seatView!)
            case .NV12:
                self.renderNV12Data(videoSample, on: seatView!)
            default:
                print("Other Video Format: \(videoSample.format)")
            }
        default:
            print("Other Video Type: \(videoSample.type)")
        }
        return true
    }
    
    // 远端视频数据回调
    func onRemoteVideoSample(_ uid: String, videoSource: AliRtcVideoSource, videoSample: AliRtcVideoDataSample) -> Bool {
        "onRemoteVideoSample".printLog()
        
        var seatView = self.seatViewList.first { $0.uid == uid}
        if seatView == nil {
            seatView = self.createSeatView(uid: uid)
        }
        
        switch videoSample.type {
        case .cvPixelBuffer:
            self.renderCVPixelBuffer(videoSample, on: seatView!)
        case .raw_Data:
            switch videoSample.format {
            case .I420:
                self.renderI420Data(videoSample, on: seatView!)
            case .NV12:
                self.renderNV12Data(videoSample, on: seatView!)
            default:
                print("Other Video Format: \(videoSample.format)")
            }
        default:
            print("Other Video Type: \(videoSample.type)")
        }
        return true
    }
    
    // 本地采集纹理回调
    func onTextureCreate(_ context: UnsafeMutableRawPointer?) {
        "onTextureCreate".printLog()
    }
    
    func onTextureUpdate(_ textureId: Int32, width: Int32, height: Int32, videoSample: AliRtcVideoDataSample) -> Int32 {
        "onTextureUpdate".printLog()
        // 这里可以进行美颜等逻辑处理
        
        // 自定义渲染，ios 12.0开始废弃了opengl，推荐使用Metal，这里演示使用pixelbuffer桥接
        if self.isEnableTextureCallback {
            
        }
        
        return textureId
    }
    
    func onTextureDestory() {
        "onTextureDestory".printLog()
    }
    
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
            let seatView = self.seatViewList.first { $0.uid == uid }
            if seatView == nil {
                _ = self.createSeatView(uid: uid)
            }
        }
        if videoTrack != .no {
            var seatView = self.seatViewList.first { $0.uid == uid }
            if seatView == nil {
                seatView = self.createSeatView(uid: uid)
            }
            
            let canvas = AliVideoCanvas()
            canvas.view = seatView!.renderingView
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
    
    private func renderI420Data(_ videoSample: AliRtcVideoDataSample, on seatView: CustomVideoRenderSeatView) {
        let width = 640
        let height = 480
        let ySize = width * height
        let uvSize = (width / 2) * (height / 2)
        
        // 分配内存：Y + U + V
        var testData = [UInt8](repeating: 0, count: ySize + uvSize * 2)
        
        // 填充 Y 平面：红色亮度 Y ≈ 76
        for i in 0..<ySize {
            testData[i] = 76
        }
        
        // 填充 U 平面：U ≈ 149
        for i in 0..<uvSize {
            testData[ySize + i] = 149  // U
        }
        
        // 填充 V 平面：V ≈ 226
        for i in 0..<uvSize {
            testData[ySize + uvSize + i] = 226  // V
        }
        
        // 转为指针并调用渲染
        testData.withUnsafeBytes { buffer in
            let base = buffer.baseAddress!
            let dataY = base.assumingMemoryBound(to: UInt8.self)
            let dataU = (base + ySize).assumingMemoryBound(to: UInt8.self)
            let dataV = (base + ySize + uvSize).assumingMemoryBound(to: UInt8.self)
            
            DispatchQueue.global().async {
                seatView.renderI420Data(
                    width: width,
                    height: height,
                    dataY: dataY,
                    dataU: dataU,
                    dataV: dataV,
                    strideY: width,
                    strideU: width / 2,
                    strideV: width / 2
                )
            }
        }
    }
    
    // 渲染NV12格式视频数据
    private func renderNV12Data(_ videoSample: AliRtcVideoDataSample, on seatView: CustomVideoRenderSeatView) {
        guard let dataY = videoSample.dataYPtr,
              let dataUV = videoSample.dataUPtr else { // NV12格式中，U和V数据在同一个平面
            return
        }
        
        let width = Int(videoSample.width)
        let height = Int(videoSample.height)
        let strideY = Int(videoSample.strideY)
        let strideUV = Int(videoSample.strideU) // NV12格式中，UV平面的步长
        
        seatView.renderNV12Data(width: width, height: height, dataY: dataY, dataUV: dataUV, strideY: strideY, strideUV: strideUV)
    }
    
    // 渲染CVPixelBuffer格式视频数据
    private func renderCVPixelBuffer(_ videoSample: AliRtcVideoDataSample, on seatView: CustomVideoRenderSeatView) {
        guard let pixelBuffer = videoSample.pixelBuffer else {
            return
        }
        
        // 直接在主线程更新UI
        DispatchQueue.main.async {
            seatView.renderPixelBuffer(pixelBuffer)
        }
    }
}
