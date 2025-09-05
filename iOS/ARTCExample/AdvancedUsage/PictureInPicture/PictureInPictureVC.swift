//
//  PictureInPictureMainVC.swift
//  ARTCExample
//
//  Created by wy on 2025/8/29.
//

import UIKit
import AliVCSDK_ARTC
import AVKit
import AVFoundation


class PictureInPictureSetParamsVC: UIViewController, UITextFieldDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Picture In Picture".localized
        
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
        
        let vc = self.presentVC(storyboardName: "PictureInPicture", storyboardId: "MainVC") as? PictureInPictureMainVC
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

// MARK: - UIView Extension to Save OriginalSuperview
private var originalSuperviewKey: UInt8 = 0

extension UIView {
    var originalSuperview: UIView? {
        get {
            return objc_getAssociatedObject(self, &originalSuperviewKey) as? UIView
        }
        set {
            objc_setAssociatedObject(self, &originalSuperviewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}


class PictureInPictureMainVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

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

    // MARK: - 画中画相关（使用可选类型，不使用 @available 修饰属性）
    private var pipController: AVPictureInPictureController?
    private var pipCallViewController: AnyObject?
    private var pipSourceView: UIView?

    var seatViewList: [PIPSeatView] = []

    var channelId: String = ""
    var userId: String = ""

    var rtcEngine: AliRtcEngine? = nil
    var joinToken: String? = nil

    // MARK: - Setup
    func setup() {
        // 画中画功能需要实现自定义渲染
        var customVideoRenderConfig: [String: String] = [:]
        // 自定义视频渲染开关
        customVideoRenderConfig["user_specified_use_external_video_render"] = "TRUE"
        // 是否允许回调cvPixelBuffer
        customVideoRenderConfig["user_specified_native_buffer_observer"] = "TRUE"
        // 序列化为Json
        guard let jsonData = try? JSONSerialization.data(withJSONObject: customVideoRenderConfig, options: []),
              let extras = String(data: jsonData, encoding: .utf8) else {
            print("JSON 序列化失败")
            return
        }
        let engine = AliRtcEngine.sharedInstance(self, extras: extras)
        engine.setLogLevel(.info)
        engine.setChannelProfile(.interactivelive)
        engine.setClientRole(.roleInteractive)
        engine.setAudioProfile(.engineHighQualityMode, audio_scene: .sceneMusicMode)

        let config = AliRtcVideoEncoderConfiguration()
        config.dimensions = CGSize(width: 720, height: 1280)
        config.frameRate = 20
        config.bitrate = 1200
        config.keyFrameInterval = 2000
        config.orientationMode = .adaptive
        engine.setVideoEncoderConfiguration(config)
        engine.setCapturePipelineScaleMode(.post)

        engine.publishLocalVideoStream(true)
        engine.publishLocalAudioStream(true)
        engine.setDefaultSubscribeAllRemoteAudioStreams(true)
        engine.subscribeAllRemoteAudioStreams(true)
        engine.setDefaultSubscribeAllRemoteVideoStreams(true)
        engine.subscribeAllRemoteVideoStreams(true)
        
        // 注册原始视频回调
        engine.registerVideoSampleObserver()

        self.rtcEngine = engine

        // 初始化画中画（运行时判断版本）
        self.setupPictureInPicture()
    }

    // MARK: - Setup Picture in Picture (iOS 15+)
    func setupPictureInPicture() {
        guard #available(iOS 15.0, *) else {
            print("iOS < 15.0，不支持系统画中画")
            return
        }

        let callVC = AVPictureInPictureVideoCallViewController()
        callVC.preferredContentSize = CGSize(width: 720, height: 1280)
        callVC.view.backgroundColor = .clear

        self.pipCallViewController = callVC
    }

    // MARK: - Enter PIP Mode
    @IBAction func onEnterPIPModeBtnClicked(_ sender: UIButton) {
        enterPictureInPictureMode()
    }

    func enterPictureInPictureMode() {
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            UIAlertController.showAlertWithMainThread(msg: "当前设备不支持画中画", vc: self)
            return
        }

        guard #available(iOS 15.0, *) else {
            UIAlertController.showAlertWithMainThread(msg: "画中画功能需要 iOS 15 或更高版本", vc: self)
            return
        }

        // 如果还没有创建控制器，尝试初始化
        if pipController == nil {
            guard let canvasView = self.seatViewList.first(where: { $0.uidLabel.text == self.userId })?.canvasView else {
                print("无法获取本地预览视图")
                return
            }
            setupPipController(with: canvasView)
        }

        guard let pipController = self.pipController else { return }

        if pipController.isPictureInPictureActive {
            pipController.stopPictureInPicture()
        } else {
            pipController.startPictureInPicture()
        }
    }

    @available(iOS 15.0, *)
    func setupPipController(with sourceView: UIView) {
        
        guard let canvasView = seatViewList.first(where: { $0.uidLabel.text == userId })?.canvasView else {
            print("❌ 无法获取本地预览视图")
            return
        }

        // 保存源视图
        self.pipSourceView = canvasView
        canvasView.originalSuperview = canvasView.superview

        // 创建 contentViewController
        let callVC = AVPictureInPictureVideoCallViewController()
        callVC.preferredContentSize = CGSize(width: 720, height: 1280)
        callVC.view.backgroundColor = .clear

        self.pipCallViewController = callVC

        // 创建 ContentSource（必须传两个参数）
        let contentSource = AVPictureInPictureController.ContentSource(
            activeVideoCallSourceView: canvasView,
            contentViewController: callVC
        )

        // 创建 PIP 控制器
        let pipController = AVPictureInPictureController(contentSource: contentSource)
        pipController.canStartPictureInPictureAutomaticallyFromInline = false
        pipController.delegate = self

        self.pipController = pipController
    }

    // MARK: - RTC Lifecycle
    func joinChannel() {
        if let joinToken = self.joinToken {
            let msg = "JoinWithToken: \(joinToken)"
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
        }
    }

    func startPreview() {
        let seatView = self.createSeatView(uid: self.userId)

        let canvas = AliVideoCanvas()
        canvas.view = seatView.canvasView
        canvas.renderMode = .auto
        canvas.mirrorMode = .onlyFrontCameraPreviewEnabled
        canvas.rotationMode = ._0

        self.rtcEngine?.setLocalViewConfig(canvas, for: .camera)
        self.rtcEngine?.startPreview()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self,
                  #available(iOS 15.0, *),
                  let canvasView = seatView.canvasView,
                  self.pipController == nil else { return }
            self.setupPipController(with: canvasView)
        }
    }

    func leaveAnddestroyEngine() {
        self.rtcEngine?.stopPreview()
        self.rtcEngine?.leaveChannel()
        AliRtcEngine.destroy()
        self.rtcEngine = nil
    }

    // MARK: - Seat View Management
    func createSeatView(uid: String) -> PIPSeatView {
        let view = PIPSeatView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.uidLabel.text = uid

        self.contentScrollView.addSubview(view)
        self.seatViewList.append(view)
        self.updateSeatViewsLayout()
        return view
    }

    func removeSeatView(uid: String) {
        let seatView = self.seatViewList.first { $0.uidLabel.text == uid }
        if let seatView = seatView {
            seatView.removeFromSuperview()
            self.seatViewList.removeAll(where: { $0 == seatView })
            self.updateSeatViewsLayout()
        }
    }

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
        self.contentScrollView.contentSize = CGSize(
            width: self.contentScrollView.bounds.width,
            height: margin + ceil(Double(self.seatViewList.count) / Double(count)) * height + margin
        )
    }
}

// MARK: - AVPictureInPictureControllerDelegate
@available(iOS 15.0, *)
extension PictureInPictureMainVC: AVPictureInPictureControllerDelegate {

    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("即将进入画中画模式")
    }

    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("已进入画中画模式")
        
//        guard #available(iOS 15.0, *) else {return}
//        
//        guard let contentSource = pictureInPictureController.contentSource as? AVPictureInPictureController.ContentSource else {
//            print("无法获取 ContentSource")
//            return
//        }
//        
//        guard let callVC = contentSource.contentViewController as? AVPictureInPictureVideoCallViewController else {
//            print("无法获取 contentViewController 或类型不匹配")
//            return
//        }
//        
//        guard let sourceView = self.pipSourceView else {
//            print("无源视图")
//            return
//        }
//
//        sourceView.removeFromSuperview()
//
//        callVC.view.addSubview(sourceView)
//        sourceView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            sourceView.leadingAnchor.constraint(equalTo: callVC.view.leadingAnchor),
//            sourceView.trailingAnchor.constraint(equalTo: callVC.view.trailingAnchor),
//            sourceView.topAnchor.constraint(equalTo: callVC.view.topAnchor),
//            sourceView.bottomAnchor.constraint(equalTo: callVC.view.bottomAnchor)
//        ])
    }

    func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("即将退出画中画模式")
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("已退出画中画模式")

        guard let sourceView = self.pipSourceView,
              let originalSuperview = sourceView.originalSuperview else { return }
        
        sourceView.removeFromSuperview()
        originalSuperview.addSubview(sourceView)
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController,
                   restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        print("恢复用户界面")
        completionHandler(true)
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController,
                   failedToStartPictureInPictureWithError error: Error) {
        print("启动画中画失败: \(error.localizedDescription)")
        DispatchQueue.main.async {
            UIAlertController.showAlertWithMainThread(msg: "启动画中画失败: \(error.localizedDescription)", vc: self)
        }
    }
}

// MARK: - AliRtcEngineDelegate
extension PictureInPictureMainVC: AliRtcEngineDelegate {
    
    func onGetVideoFormatPreference() -> AliRtcVideoFormat {
        .cvPixelBuffer
    }
    
    func onCaptureVideoSample(_ videoSource: AliRtcVideoSource, videoSample: AliRtcVideoDataSample) -> Bool {
        guard let pixelBuffer = videoSample.pixelBuffer else {
            print("Local video buffer is not CVPixelBuffer")
            return false
        }
        
        if let seatView = seatViewList.first(where: { $0.uidLabel.text == self.userId }),
           let renderView = seatView.canvasView {
            renderView.render(pixelBuffer: pixelBuffer, width: Int(videoSample.width), height: Int(videoSample.height))
        }
        return true
                
    }
    
    func onRemoteVideoSample(_ uid: String, videoSource: AliRtcVideoSource, videoSample: AliRtcVideoDataSample) -> Bool {
        guard let pixelBuffer = videoSample.pixelBuffer else {
            print("Remote video buffer is not CVPixelBuffer, uid: \(uid)")
            return false
        }
        
        if let seatView = seatViewList.first(where: { $0.uidLabel.text == uid }),
           let renderView = seatView.canvasView {
            renderView.render(pixelBuffer: pixelBuffer, width: Int(videoSample.width), height: Int(videoSample.height))
        }
        
        return true
    }
    
    // （保持原有实现不变）
    func onJoinChannelResult(_ result: Int32, channel: String, elapsed: Int32) {
        "onJoinChannelResult1 result: \(result)".printLog()
    }

    func onJoinChannelResult(_ result: Int32, channel: String, userId: String, elapsed: Int32) {
        "onJoinChannelResult2 result: \(result)".printLog()
    }

    func onRemoteUser(onLineNotify uid: String, elapsed: Int32) {
        "onRemoteUserOlineNotify uid: \(uid)".printLog()
    }

    func onRemoteUserOffLineNotify(_ uid: String, offlineReason reason: AliRtcUserOfflineReason) {
        "onRemoteUserOffLineNotify uid: \(uid) reason: \(reason)".printLog()
        self.removeSeatView(uid: uid)
    }

    func onRemoteTrackAvailableNotify(_ uid: String, audioTrack: AliRtcAudioTrack, videoTrack: AliRtcVideoTrack) {
        "onRemoteTrackAvailableNotify uid: \(uid) audioTrack: \(audioTrack) videoTrack: \(videoTrack)".printLog()

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
            self.rtcEngine?.setRemoteViewConfig(canvas, uid: uid, for: .camera)
        } else {
            self.rtcEngine?.setRemoteViewConfig(nil, uid: uid, for: .camera)
        }

        if audioTrack == .no && videoTrack == .no {
            self.removeSeatView(uid: uid)
            self.rtcEngine?.setRemoteViewConfig(nil, uid: uid, for: .camera)
        }
    }

    func onAuthInfoWillExpire() {
        "onAuthInfoWillExpire".printLog()
    }

    func onAuthInfoExpired() {
        "onAuthInfoExpired".printLog()
    }

    func onBye(_ code: Int32) {
        "onBye code: \(code)".printLog()
    }

    func onLocalDeviceException(_ deviceType: AliRtcLocalDeviceType, exceptionType: AliRtcLocalDeviceExceptionType, message msg: String?) {
        "onLocalDeviceException deviceType: \(deviceType) exceptionType: \(exceptionType)".printLog()
    }

    func onConnectionStatusChange(_ status: AliRtcConnectionStatus, reason: AliRtcConnectionStatusChangeReason) {
        "onConnectionStatusChange status: \(status) reason: \(reason)".printLog()
    }
}
