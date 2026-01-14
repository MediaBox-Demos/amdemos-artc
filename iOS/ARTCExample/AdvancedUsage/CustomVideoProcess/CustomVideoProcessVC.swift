//
//  CustomVideoProcessVC.swift
//  ARTCExample
//
//  Created by wy on 2025/7/17.
//

import Foundation
import AliVCSDK_ARTC
import queen

// Custom Video Process Demo
// This example demonstrates custom video processing: obtaining raw video data (from local camera capture),
// processing it with Queen beauty library, and passing it back to SDK.
// Supports two implementations: Buffer (CVPixelBuffer) and Texture (OpenGL texture)

class CustomVideoProcessSetParamsVC: UIViewController, UITextFieldDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Custom Video Process".localized
        
        self.channelIdTextField.delegate = self
    }
    @IBOutlet weak var textureModeSwitch: UISwitch!
    @IBOutlet weak var enableBeautifySwitch: UISwitch!
    
    // Action methods for switches (required by storyboard connections)
    @objc func onTextureDataSwitchToggled(_ sender: UISwitch) {
        // Switch state is automatically updated via outlet
        // No additional action needed
    }
    
    @objc func onBeautifySwitchToggled(_ sender: UISwitch) {
        // Switch state is automatically updated via outlet
        // No additional action needed
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
        
        let vc = self.presentVC(storyboardName: "CustomVideoProcess", storyboardId: "MainVC") as? CustomVideoProcessMainVC
        guard let vc = vc else { return }
        vc.channelId = channelId
        vc.userId = userId
        vc.joinToken = joinToken
        
        vc.isTextureMode = textureModeSwitch.isOn
        vc.isEnableBeautify = enableBeautifySwitch.isOn
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

class CustomVideoProcessMainVC: UIViewController {

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
    
    var seatViewList: [SeatView] = []
    
    var channelId: String = ""
    var userId: String = ""
    
    var rtcEngine: AliRtcEngine? = nil

    var joinToken: String? = nil
    
    var isEnableBeautify: Bool = false
    var isTextureMode: Bool = true
    
    // Queen beauty engine
    var beautyEngine: QueenEngine? = nil
    
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
        
        // 纹理数据回调
        if(isTextureMode) {
            engine.registerLocalVideoTexture()
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
        
        // Release beauty engine (for buffer mode)
        if beautyEngine != nil {
            beautyEngine?.destroy()
            beautyEngine = nil
        }
    }
    
    // MARK: - Queen Beauty Processing
    
    /// Initialize Queen beauty engine
    /// - Parameter processBuffer: true for buffer mode, false for texture mode
    func initBeautyEngine(processBuffer: Bool) {
        if beautyEngine != nil {
            return
        }
        
        let configInfo = QueenEngineConfigInfo()
        
        // Auto adjust image rotation angle for camera capture
        configInfo.autoSettingImgAngle = true
        
        if processBuffer {
            // Buffer mode: Process CVPixelBuffer, Queen creates its own GLContext
            configInfo.withContext = true          // Required for CVPixelBuffer processing
            configInfo.runOnCustomThread = false   // Process in current thread
        } else {
            // Texture mode: Use SDK's render context, don't create internal GLContext
            configInfo.withContext = false         // Don't create internal GLContext
            configInfo.runOnCustomThread = true    // Run algorithm in Queen's own thread
        }
        
        // Initialize engine
        beautyEngine = QueenEngine(configInfo: configInfo)
        
        guard let engine = beautyEngine else { return }
        
        // === Basic Beauty Settings ===
        // Skin buffing & sharpening
        engine.setQueenBeautyType(.queenBeautyTypeSkinBuffing,
                                  enable: true,
                                  mode: .queenBeautyFilterModeSkinBuffing_Natural)
        engine.setQueenBeautyParams(.queenBeautyParamsSkinBuffing, value: 0.5)
        engine.setQueenBeautyParams(.queenBeautyParamsSharpen, value: 0.5)
        
        // Skin whitening
        engine.setQueenBeautyType(.queenBeautyTypeSkinWhiting, enable: true)
        engine.setQueenBeautyParams(.queenBeautyParamsWhitening, value: 0.5)
        
        // Advanced beauty
        engine.setQueenBeautyType(.queenBeautyTypeFaceBuffing, enable: true)
        engine.setQueenBeautyParams(.queenBeautyParamsWrinkles, value: 0.5)
        engine.setQueenBeautyParams(.queenBeautyParamsPouch, value: 0.5)
        engine.setQueenBeautyParams(.queenBeautyParamsNasolabialFolds, value: 0.5)
        engine.setQueenBeautyParams(.queenBeautyParamsWhiteTeeth, value: 0.5)
        
        // Face shape (big eye & cut face)
        engine.setQueenBeautyType(.queenBeautyTypeFaceShape,
                                  enable: true,
                                  mode: .queenBeautyFilterModeFaceShape_Main)
        engine.setFaceShape(.queenBeautyFaceShapeTypeCutFace, value: 0.5)
        engine.setFaceShape(.queenBeautyFaceShapeTypeBigEye, value: 0.9)
        
        // Debug: show face detect points
        // engine.showFaceDetectPoint(true)
        
        "Queen beauty engine initialized (processBuffer: \(processBuffer))".printLog()
    }
    
    /// Process beauty for CVPixelBuffer (Buffer mode)
    /// - Parameter pixelBuffer: Input CVPixelBuffer
    /// - Returns: true if processed successfully
    func handleBeautyProcessBuffer(_ pixelBuffer: CVPixelBuffer) -> Bool {
        if beautyEngine == nil {
            // Buffer mode: processBuffer = true
            initBeautyEngine(processBuffer: true)
        }
        guard let engine = beautyEngine else {
            return false
        }
        
        // Process CVPixelBuffer using QEPixelBufferData
        let bufferData = QEPixelBufferData()
        bufferData.bufferIn = pixelBuffer
        bufferData.bufferOut = pixelBuffer  // In-place processing
        
        let result = engine.processPixelBuffer(bufferData)
        
        if result == .queenResultCodeOK {
            "Beauty processing succeeded (buffer mode)".printLog()
            return true
        }
        return false
    }
    
    /// Process beauty for texture (Texture mode)
    /// - Parameters:
    ///   - textureId: Input texture ID
    ///   - width: Texture width
    ///   - height: Texture height
    ///   - videoSample: Video sample containing CVPixelBuffer for face detection
    /// - Returns: Output texture ID
    func handleBeautyProcessTexture(_ textureId: Int32,
                                    width: Int32,
                                    height: Int32,
                                    videoSample: AliRtcVideoDataSample) -> Int32 {
        if beautyEngine == nil {
            // Texture mode: processBuffer = false
            initBeautyEngine(processBuffer: false)
        }
        guard let engine = beautyEngine else {
            return textureId
        }
        
        // Optional: For advanced beauty features that require face detection,
        // process CVPixelBuffer first if available
        if let pixelBuffer = videoSample.pixelBuffer {
            let bufferData = QEPixelBufferData()
            bufferData.bufferIn = pixelBuffer
            bufferData.bufferOut = pixelBuffer
            _ = engine.processPixelBuffer(bufferData)
        }
        
        // Process texture using QETextureData
        let textureData = QETextureData()
        textureData.inputTextureID = UInt32(textureId)
        textureData.width = Int32(width)
        textureData.height = Int32(height)
        
        let result = engine.processTexture(textureData)
        
        if result == .queenResultCodeOK {
            let outputId = Int32(textureData.outputTextureID)
            "Beauty processing succeeded (texture mode), input: \(textureId), output: \(outputId)".printLog()
            return outputId
        } else {
            "Beauty processing failed (texture mode), code: \(result.rawValue), returning original textureId: \(textureId)".printLog()
        }
        
        return textureId
    }
    
    // Create a video call rendering view and add it to contentScrollView
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

extension CustomVideoProcessMainVC: AliRtcEngineDelegate {
    
    // MARK: Video Sample Raw Frame Callback
    // Expected output format (use CVPixelBuffer for better compatibility with beauty SDK)
    func onGetVideoFormatPreference() -> AliRtcVideoFormat {
        // For buffer beauty processing, prefer CVPixelBuffer format
        // Note: If SDK doesn't support cvPixelBuffer enum, fallback to I420
        return .cvPixelBuffer  // Or .I420 if cvPixelBuffer is not available
    }
    
    // Return position flags (only PostCapture for beauty processing)
    func onGetVideoObservedFramePosition() -> Int {
        let captureFlag = AliRtcVideoObserPosition.positionPostCapture.rawValue
        // Only observe post-capture for beauty processing on local camera data
        return captureFlag
    }
    // Whether output data should be mirrored
    func onGetObserverDataMirrorApplied() -> Bool {
        return true
    }
    // Local captured video data callback (Buffer mode)
    func onCaptureVideoSample(_ videoSource: AliRtcVideoSource, videoSample: AliRtcVideoDataSample) -> Bool {
        let message = "onCaptureVideoSample: timestamp: \(videoSample.timeStamp), format: \(videoSample.format), width: \(videoSample.width), height: \(videoSample.height), dataLength: \(videoSample.dataLength)"
        message.printLog()
        
        // If texture mode is enabled, skip buffer processing (use texture callback instead)
        if isTextureMode {
            return true
        }
        
        // If beauty is not enabled, return original data
        guard isEnableBeautify else {
            return true
        }
        
        // Process beauty with CVPixelBuffer (recommended format)
        if videoSample.type == .cvPixelBuffer, let pixelBuffer = videoSample.pixelBuffer {
            let processed = handleBeautyProcessBuffer(pixelBuffer)
            // Return true to write back processed data to SDK
            return processed
        }
        
        // For other formats, keep original data
        return true
    }
    // Pre-encode video data callback
    func onPreEncodeVideoSample(_ videoSource: AliRtcVideoSource, videoSample: AliRtcVideoDataSample) -> Bool {
        let message = "onPreEncodeVideoSample: timestamp: \(videoSample.timeStamp), format: \(videoSample.format), width: \(videoSample.width), height: \(videoSample.height), dataLength: \(videoSample.dataLength)"
        message.printLog()
        return true
    }
    // Remote video data callback
    func onRemoteVideoSample(_ uid: String, videoSource: AliRtcVideoSource, videoSample: AliRtcVideoDataSample) -> Bool {
        let message = "onRemoteVideoSample: uid: \(uid), timestamp: \(videoSample.timeStamp), format: \(videoSample.format), width: \(videoSample.width), height: \(videoSample.height), dataLength: \(videoSample.dataLength)"
        message.printLog()
        return true
    }
    // MARK: Texture Callback
    // Texture created callback
    func onTextureCreate(_ context: UnsafeMutableRawPointer?) {
        let message = "onTextureCreate"
        message.printLog()
    }
    
    // Texture update callback (Texture mode)
    func onTextureUpdate(_ textureId: Int32, width: Int32, height: Int32, videoSample: AliRtcVideoDataSample) -> Int32 {
        let message = "onTextureUpdate: textureId: \(textureId), timestamp: \(videoSample.timeStamp), format: \(videoSample.format), width: \(width), height: \(height)"
        message.printLog()
        
        // If texture mode and beauty are both enabled, process beauty
        guard isTextureMode, isEnableBeautify else {
            return textureId
        }
        
        return handleBeautyProcessTexture(textureId,
                                          width: width,
                                          height: height,
                                          videoSample: videoSample)
    }
    
    // Texture destroy callback - MUST release beauty engine here for texture mode
    func onTextureDestory() {
        let message = "onTextureDestroy"
        message.printLog()
        
        // For texture mode, MUST destroy beauty engine here to ensure same thread
        if beautyEngine != nil {
            beautyEngine?.destroy()
            beautyEngine = nil
            "Beauty engine destroyed in texture thread".printLog()
        }
    }
    // MARK: RTC Engine Callbacks
    func onJoinChannelResult(_ result: Int32, channel: String, elapsed: Int32) {
        "onJoinChannelResult1 result: \(result)".printLog()
    }
    
    func onJoinChannelResult(_ result: Int32, channel: String, userId: String, elapsed: Int32) {
        "onJoinChannelResult2 result: \(result)".printLog()
    }
    
    func onRemoteUser(onLineNotify uid: String, elapsed: Int32) {
        // Remote user online
        "onRemoteUserOlineNotify uid: \(uid)".printLog()
    }
    
    func onRemoteUserOffLineNotify(_ uid: String, offlineReason reason: AliRtcUserOfflineReason) {
        // Remote user offline
        "onRemoteUserOffLineNotify uid: \(uid) reason: \(reason)".printLog()
    }
    
    
    func onRemoteTrackAvailableNotify(_ uid: String, audioTrack: AliRtcAudioTrack, videoTrack: AliRtcVideoTrack) {
        "onRemoteTrackAvailableNotify uid: \(uid) audioTrack: \(audioTrack)  videoTrack: \(videoTrack)".printLog()
        // Remote user track availability changed
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
        
        /* TODO: IMPORTANT - Token is about to expire, need to refresh auth info */
    }
    
    func onAuthInfoExpired() {
        "onAuthInfoExpired".printLog()
        
        /* TODO: IMPORTANT - Token has expired, need to leave channel and destroy engine */
    }
    
    func onBye(_ code: Int32) {
        "onBye code: \(code)".printLog()
        
        /* TODO: IMPORTANT - Handle device preemption scenario */
    }
    
    func onLocalDeviceException(_ deviceType: AliRtcLocalDeviceType, exceptionType: AliRtcLocalDeviceExceptionType, message msg: String?) {
        "onLocalDeviceException deviceType: \(deviceType)  exceptionType: \(exceptionType)".printLog()

        /* TODO: IMPORTANT - Notify user about device error */
    }
    
    func onConnectionStatusChange(_ status: AliRtcConnectionStatus, reason: AliRtcConnectionStatusChangeReason) {
        "onConnectionStatusChange status: \(status)  reason: \(reason)".printLog()

        if status == .failed {
            /* TODO: IMPORTANT - Notify user about connection failure */
        }
        else {
            /* TODO: Optional - Handle other connection status changes */
        }
    }
}

