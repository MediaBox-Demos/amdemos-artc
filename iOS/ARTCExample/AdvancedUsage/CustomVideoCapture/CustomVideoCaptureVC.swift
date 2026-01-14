//
//  CustomVideoCpature.swift
//  ARTCExample
//
//  Created by wy on 2025/8/27.
//

import Foundation
import UIKit
import AVFoundation
import AliVCSDK_ARTC

class CustomVideoCaptureSetParamsVC: UIViewController, UITextFieldDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Custom Video Capture".localized
        
        self.channelIdTextField.delegate = self
    }
    
    @IBOutlet weak var channelIdTextField: UITextField!
    @IBOutlet weak var customVideoCaptureSwitch: UISwitch!
    
    @IBAction func onJoinChannelBtnClicked(_ sender: Any) {
        guard let channelId = self.channelIdTextField.text, channelId.isEmpty == false else {
            return
        }
        
        let helper = ARTCTokenHelper()
        let userId = GlobalConfig.shared.userId
        let timestamp = Int64(Date().timeIntervalSince1970 + 24 * 60 * 60)
        let joinToken = helper.generateJoinToken(channelId: channelId, userId: userId, timestamp: timestamp)
        
        let vc = self.presentVC(storyboardName: "CustomVideoCapture", storyboardId: "MainVC") as? CustomVideoCaptureMainVC
        vc?.channelId = channelId
        vc?.userId = userId
        vc?.joinToken = joinToken
        vc?.isEnableCustomVideoCapture = customVideoCaptureSwitch.isOn
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



class CustomVideoCaptureMainVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = self.channelId
        
        capturer.delegate = self
        capturer.startCapture()
        
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
    
    // 自定义采集
    var isEnableCustomVideoCapture: Bool = true
    let capturer = CameraCaptureHelper()
    
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
        
        // 关闭或开启SDK内部采集
        engine.enableLocalVideo(isEnableCustomVideoCapture)
        // 关闭或开启外部视频流，默认替换相机流
        engine.setExternalVideoSource(isEnableCustomVideoCapture, sourceType: .videosourceCameraType, renderMode: .auto)
        
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
        self.capturer.stopCapture()
        
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension CustomVideoCaptureMainVC: AliRtcEngineDelegate {
    
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

extension CustomVideoCaptureMainVC: CameraCaptureHelperDelegate {
    // pixelbuffer 转为NV12
    func copyNV12Data(from pixelBuffer: CVPixelBuffer) -> (UnsafeMutablePointer<UInt8>, Int, Int, Int)? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)

        // Y 平面
        guard let baseY = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0) else { return nil }
        let strideY = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)

        // UV 平面
        guard let baseUV = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1) else { return nil }
        let strideUV = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1)

        // 分配连续内存存储 NV12 数据
        let totalSize = strideY * height + strideUV * height / 2
        let rawPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: totalSize)

        // 复制 Y
        for row in 0..<height {
            let src = baseY.advanced(by: row * strideY)
            let dst = rawPtr.advanced(by: row * strideY)
            memcpy(dst, src, strideY)
        }

        // 复制 UV
        for row in 0..<(height/2) {
            let src = baseUV.advanced(by: row * strideUV)
            let dst = rawPtr.advanced(by: strideY*height + row * strideUV)
            memcpy(dst, src, strideUV)
        }

        return (rawPtr, width, height, totalSize)
    }
    
    // 相机采集的视频传入SDK
    func videoCapture(_ capture: CameraCaptureHelper, didCaptureOutputBuffer sampleBuffer: CMSampleBuffer) {
        guard let engine = self.rtcEngine else {return}
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}

        let dataSample = AliRtcVideoDataSample()
        let retainedPixelBuffer = Unmanaged<CVPixelBuffer>.passRetained(pixelBuffer) // 用于增加引用计数，放置sampleBuffer释放后pixelbuffer无效
        dataSample.pixelBuffer = pixelBuffer
        dataSample.format = .cvPixelBuffer
        dataSample.type = .cvPixelBuffer
        dataSample.width = Int32(CVPixelBufferGetWidth(pixelBuffer))
        dataSample.height = Int32(CVPixelBufferGetHeight(pixelBuffer))
        dataSample.dataLength = Int(CVPixelBufferGetDataSize(pixelBuffer));
        // 向SDK输入外部视频源
        let ret = engine.pushExternalVideoFrame(dataSample, sourceType: .videosourceCameraType)
        if ret != 0 {
            // 接口调用失败需要release
            "CVPixelBuffer Input Error!".printLog()
            retainedPixelBuffer.release()
        }
    }
        
}

