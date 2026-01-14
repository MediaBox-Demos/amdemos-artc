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
import OpenGLES

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
    
    // OpenGL 纹理渲染相关属性
    private var glContext: EAGLContext?
    private var glFramebuffer: GLuint = 0
    private var textureCache: CVOpenGLESTextureCache?
    
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
        
        // 只有在非自定义渲染模式下才设置 SDK 的 canvas
        if !isEnableCustomVideoRender {
            let canvas = AliVideoCanvas()
            canvas.view = seatView.renderingView
            canvas.renderMode = .auto
            canvas.mirrorMode = .onlyFrontCameraPreviewEnabled
            canvas.rotationMode = ._0
            
            self.rtcEngine?.setLocalViewConfig(canvas, for: AliRtcVideoTrack.camera)
        }
        self.rtcEngine?.startPreview()
    }
    
    func leaveAnddestroyEngine() {
        self.rtcEngine?.stopPreview()
        self.rtcEngine?.leaveChannel()
        AliRtcEngine.destroy()
        self.rtcEngine = nil
        
        // 清理 OpenGL 资源
        self.cleanupOpenGLResources()
    }
    
    // 清理 OpenGL 资源
    private func cleanupOpenGLResources() {
        if let context = glContext {
            EAGLContext.setCurrent(context)
            
            if glFramebuffer != 0 {
                var fbo = glFramebuffer
                glDeleteFramebuffers(1, &fbo)
                glFramebuffer = 0
            }
            
            if textureCache != nil {
                textureCache = nil
            }
            
            EAGLContext.setCurrent(nil)
            glContext = nil
        }
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
        
        // 添加调试日志
        print("[Local] type: \(videoSample.type.rawValue), format: \(videoSample.format.rawValue), size: \(videoSample.width)x\(videoSample.height)")
        
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
        // 添加调试日志
        print("[Remote \(uid)] type: \(videoSample.type.rawValue), format: \(videoSample.format.rawValue), size: \(videoSample.width)x\(videoSample.height)")
        
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
        
        // 初始化 OpenGL 上下文
        if let ctx = context {
            // SDK 传入的是 EAGLContext 指针
            glContext = Unmanaged<EAGLContext>.fromOpaque(ctx).takeUnretainedValue()
        } else {
            // 如果 SDK 没有传入，创建一个新的
            glContext = EAGLContext(api: .openGLES2)
        }
        
        guard let glContext = glContext else {
            print("Failed to create OpenGL ES context")
            return
        }
        
        EAGLContext.setCurrent(glContext)
        
        // 创建 Framebuffer
        if glFramebuffer == 0 {
            var fbo: GLuint = 0
            glGenFramebuffers(1, &fbo)
            glFramebuffer = fbo
        }
        
        // 创建纹理缓存
        if textureCache == nil {
            var cache: CVOpenGLESTextureCache?
            let result = CVOpenGLESTextureCacheCreate(
                kCFAllocatorDefault,
                nil,
                glContext,
                nil,
                &cache
            )
            if result == kCVReturnSuccess {
                textureCache = cache
            }
        }
        
        print("OpenGL context initialized successfully")
    }
    
    func onTextureUpdate(_ textureId: Int32, width: Int32, height: Int32, videoSample: AliRtcVideoDataSample) -> Int32 {
        print("[Texture] textureId: \(textureId), size: \(width)x\(height)")
        
        guard isEnableTextureCallback,
              let glContext = glContext else {
            return textureId
        }
        
        // 使用 OpenGL 渲染纹理
        self.renderTexture(textureId: textureId, width: width, height: height)
        
        return textureId
    }
    
    // 使用 OpenGL 渲染纹理数据
    private func renderTexture(textureId: Int32, width: Int32, height: Int32) {
        guard let glContext = glContext else { return }
        
        EAGLContext.setCurrent(glContext)
        
        let w = Int(width)
        let h = Int(height)
        
        // 绑定 FBO 并附加纹理
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), glFramebuffer)
        glFramebufferTexture2D(
            GLenum(GL_FRAMEBUFFER),
            GLenum(GL_COLOR_ATTACHMENT0),
            GLenum(GL_TEXTURE_2D),
            GLuint(textureId),
            0
        )
        
        // 检查 FBO 状态
        let status = glCheckFramebufferStatus(GLenum(GL_FRAMEBUFFER))
        if status != GL_FRAMEBUFFER_COMPLETE {
            print("FBO not complete: \(status)")
            glBindFramebuffer(GLenum(GL_FRAMEBUFFER), 0)
            return
        }
        
        // 从 FBO 读取像素数据（RGBA 格式）
        let bytesPerPixel = 4
        let dataSize = w * h * bytesPerPixel
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: dataSize)
        defer { buffer.deallocate() }
        
        glReadPixels(
            0,
            0,
            GLsizei(width),
            GLsizei(height),
            GLenum(GL_RGBA),
            GLenum(GL_UNSIGNED_BYTE),
            buffer
        )
        
        // 解绑 FBO
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), 0)
        
        // 创建 CVPixelBuffer
        var pixelBuffer: CVPixelBuffer?
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
            kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary
        ]
        
        let createStatus = CVPixelBufferCreate(
            kCFAllocatorDefault,
            w,
            h,
            kCVPixelFormatType_32BGRA,
            attrs as CFDictionary,
            &pixelBuffer
        )
        
        guard createStatus == kCVReturnSuccess, let pixelBuffer = pixelBuffer else {
            print("Failed to create CVPixelBuffer: \(createStatus)")
            return
        }
        
        // 锁定 PixelBuffer 并拷贝数据
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }
        
        guard let dest = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            print("Failed to get pixel buffer base address")
            return
        }
        
        let destBytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        // 将 UnsafeMutableRawPointer 转换为可以下标访问的类型
        let destPtr = dest.assumingMemoryBound(to: UInt8.self)
        
        // 逐行拷贝数据（处理可能的行对齐差异）
        // OpenGL 读取的数据原点在左下角，iOS 在左上角，所以需要垂直翻转
        for y in 0..<h {
            // 从 OpenGL 底部开始读（翻转）
            let srcRow = buffer.advanced(by: y * w * bytesPerPixel)
            let destRow = destPtr.advanced(by: y * destBytesPerRow)
            
            // RGBA -> BGRA 转换
            for x in 0..<w {
                let srcPixel = srcRow.advanced(by: x * bytesPerPixel)
                let destPixel = destRow.advanced(by: x * bytesPerPixel)
                
                destPixel[0] = srcPixel[2] // B
                destPixel[1] = srcPixel[1] // G
                destPixel[2] = srcPixel[0] // R
                destPixel[3] = srcPixel[3] // A
            }
        }
        
        // 在主线程更新 UI
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let seatView = self.seatViewList.first(where: { $0.uid == self.userId }) {
                seatView.renderPixelBuffer(pixelBuffer)
            }
        }
    }
    
    func onTextureDestory() {
        "onTextureDestory".printLog()
        
        // 清理 OpenGL 资源
        self.cleanupOpenGLResources()
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
            
            // 只有在非自定义渲染模式下才设置 SDK 的 canvas
            if !isEnableCustomVideoRender {
                let canvas = AliVideoCanvas()
                canvas.view = seatView!.renderingView
                canvas.renderMode = .auto
                canvas.mirrorMode = .onlyFrontCameraPreviewEnabled
                canvas.rotationMode = ._0
                self.rtcEngine?.setRemoteViewConfig(canvas, uid: uid, for: AliRtcVideoTrack.camera)
            }
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
    
    // 渲染 I420 格式视频数据（使用 SDK 实际回调的数据）
    private func renderI420Data(_ videoSample: AliRtcVideoDataSample, on seatView: CustomVideoRenderSeatView) {
        // 从 sample 中取出 Y / U / V 平面指针
        guard let dataY = videoSample.dataYPtr,
              let dataU = videoSample.dataUPtr,
              let dataV = videoSample.dataVPtr else {
            return
        }

        let width   = Int(videoSample.width)
        let height  = Int(videoSample.height)
        let strideY = Int(videoSample.strideY)
        let strideU = Int(videoSample.strideU)
        let strideV = Int(videoSample.strideV)

        // UI 渲染必须在主线程
        DispatchQueue.main.async {
            seatView.renderI420Data(
                width:   width,
                height:  height,
                dataY:   dataY,
                dataU:   dataU,
                dataV:   dataV,
                strideY: strideY,
                strideU: strideU,
                strideV: strideV
            )
        }
    }
    
    // 渲染 NV12 格式视频数据（使用 SDK 实际回调的数据）
    private func renderNV12Data(_ videoSample: AliRtcVideoDataSample, on seatView: CustomVideoRenderSeatView) {
        // NV12: Y 在 dataYPtr，UV 在 dataUPtr
        guard let dataY = videoSample.dataYPtr,
              let dataUV = videoSample.dataUPtr else {
            return
        }

        let width    = Int(videoSample.width)
        let height   = Int(videoSample.height)
        let strideY  = Int(videoSample.strideY)
        let strideUV = Int(videoSample.strideU)

        // UI 渲染必须在主线程
        DispatchQueue.main.async {
            seatView.renderNV12Data(
                width:   width,
                height:  height,
                dataY:   dataY,
                dataUV:  dataUV,
                strideY: strideY,
                strideUV: strideUV
            )
        }
    }
    
    // 渲染CVPixelBuffer格式视频数据
    private func renderCVPixelBuffer(_ videoSample: AliRtcVideoDataSample, on seatView: CustomVideoRenderSeatView) {
        guard let pixelBuffer = videoSample.pixelBuffer else {
            print("CVPixelBuffer is nil")
            return
        }
        
        // 输出 pixelBuffer 信息
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let format = CVPixelBufferGetPixelFormatType(pixelBuffer)
        print("Rendering CVPixelBuffer: \(width)x\(height), format: \(format)")
        
        // 直接在主线程更新UI
        DispatchQueue.main.async {
            seatView.renderPixelBuffer(pixelBuffer)
        }
    }
}
