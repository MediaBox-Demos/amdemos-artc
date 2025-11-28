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

    @IBOutlet weak var contentScrollView: UIScrollView!

    // MARK: - 画中画相关（使用可选类型，不使用 @available 修饰属性）
    private var pipManager: PIPSwitchManager?
    private var seatViews: [String: UserSeatView] = [:]

    var channelId: String = ""
    var userId: String = ""

    var rtcEngine: AliRtcEngine? = nil
    var joinToken: String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = self.channelId

        if PIPSwitchManager.isSupported {
            pipManager = PIPSwitchManager(hostVC: self)
        }
        self.setup()
        self.startPreview()
        self.joinChannel()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.updateLayout()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.leaveAnddestroyEngine()
    }

    // MARK: - Setup
    func setup() {
        // 画中画功能需要实现自定义渲染
        var customVideoRenderConfig: [String: String] = [:]
        // 开启自定义视频渲染，关闭SDK内部的渲染
        customVideoRenderConfig["user_specified_use_external_video_render"] = "TRUE"
        // 使用硬编硬解，目的是使的原始视频数据回调返回pixelbuffer格式，如果是软编软解，会返回yuv数据
        customVideoRenderConfig["user_specified_codec_type"] = "CODEC_TYPE_HARDWARE_ENCODER_HARDWARE_DECODER"
        
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

        // 配置视频编码配置
        let config = AliRtcVideoEncoderConfiguration()
        config.dimensions = CGSize(width: 720, height: 1280)
        config.frameRate = 20
        config.bitrate = 1200
        config.keyFrameInterval = 2000
        config.orientationMode = .adaptive
        config.backgroundHardwareToSoftware = 1 // 注意：设置切后台后允许硬编切换为软编，切后台后硬编会被系统终止
        engine.setVideoEncoderConfiguration(config)
        // 配置视频解码配置
        let decoderConfig = AliRtcVideoDecoderConfiguration()
        decoderConfig.backgroundHardwareToSoftware = 1 // 注意：设置切后台后允许硬解切换为软解，切后台后硬解会被系统终止
        engine.setVideoDecoderConfiguration(decoderConfig)
        
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
    }
    // MARK: - Enter PIP Mode
    @IBAction func onEnterPIPModeBtnClicked(_ sender: UIButton) {
        // 查找用户的seatView放入小窗
        guard let (_, seatView) = seatViews.first(where: { $0.key == userId }) else {
            UIAlertController.showAlertWithMainThread(msg: "未找到本地座位视图", vc: self)
            return
        }

        // 直接使用，无需解包
        pipManager?.startPIP(for: seatView.videoRenderView)
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
        let seatView = ensureSeatView(for: self.userId, isLocal: true)
        seatView.uid = self.userId
        let canvas = AliVideoCanvas()
        canvas.view = seatView.videoRenderView
        canvas.renderMode = .auto
        canvas.mirrorMode = .onlyFrontCameraPreviewEnabled
        canvas.rotationMode = ._0

        self.rtcEngine?.setLocalViewConfig(canvas, for: .camera)
        self.rtcEngine?.startPreview()
    }

    func leaveAnddestroyEngine() {
        self.rtcEngine?.stopPreview()
        self.rtcEngine?.leaveChannel()
        AliRtcEngine.destroy()
        self.rtcEngine = nil
    }

    // MARK: - Seat View Management
    private func ensureSeatView(for uid: String, isLocal: Bool = false) -> UserSeatView {
        if let seat = seatViews[uid] {
            return seat
        }

        let seatView = UserSeatView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        seatView.uid = uid
        seatView.isUserInteractionEnabled = true

        // 长按进入 PIP（仅本地）
        if isLocal, PIPSwitchManager.isSupported {
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(onLocalViewLongPressed(_:)))
            seatView.addGestureRecognizer(longPress)
        }

        contentScrollView.addSubview(seatView)
        seatViews[uid] = seatView
        updateLayout()
        return seatView
    }
    
    private func removeSeatView(for uid: String) {
        guard let seatView = seatViews[uid] else { return }
        seatView.removeFromSuperview()
        seatViews.removeValue(forKey: uid)
        updateLayout()
    }
    
    private func updateLayout() {
        let countPerRow: Int = 2
        let margin: CGFloat = 24
        let width = (contentScrollView.bounds.width - margin * CGFloat(countPerRow + 1)) / CGFloat(countPerRow)
        let height = width

        // 先排序：目标 userId 在最前面，其余按 key 字典序或任意稳定顺序
        let sortedSeats = seatViews.sorted { (item1, item2) -> Bool in
            let isUser1 = item1.key == userId
            let isUser2 = item2.key == userId
            
            if isUser1 && !isUser2 {
                return true   // item1 排前面
            } else if !isUser1 && isUser2 {
                return false  // item2 排前面
            } else {
                return item1.key < item2.key  // 否则按 key 字典序排序（保证稳定性）
            }
        }

        for (index, (_, seatView)) in sortedSeats.enumerated() {
            let row = index / countPerRow
            let col = index % countPerRow
            let x = CGFloat(col) * (width + margin) + margin
            let y = CGFloat(row) * (height + margin) + margin
            seatView.frame = CGRect(x: x, y: y, width: width, height: height)
        }

        let rowCount = ceil(Double(seatViews.count) / Double(countPerRow))
        contentScrollView.contentSize = CGSize(
            width: contentScrollView.bounds.width,
            height: margin + CGFloat(rowCount) * (height + margin)
        )
    }

    @objc private func onLocalViewLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              PIPSwitchManager.isSupported,
              let seatView = seatViews[userId] else {
            return
        }

        pipManager?.startPIP(for: seatView.videoRenderView)
    }
    

    @IBAction func onTogglePIP(_ sender: UIButton) {
        if pipManager?.isActivelyInPIP == true {
            pipManager?.stopPIP()
        } else {
            onLocalViewLongPressed(.init())
        }
    }
}

// MARK: - AliRtcEngineDelegate
extension PictureInPictureMainVC: AliRtcEngineDelegate {
    
    func onGetVideoFormatPreference() -> AliRtcVideoFormat {
        .cvPixelBuffer
    }
    
    // 返回位置，默认全部不返回
    func onGetVideoObservedFramePosition() -> Int {
        let captureFlag = AliRtcVideoObserPosition.positionPostCapture.rawValue
        let preEncoderFlag = AliRtcVideoObserPosition.positionPreEncoder.rawValue
        let preRenderFlag = AliRtcVideoObserPosition.positionPreRender.rawValue
        var ret = 0
        ret |= captureFlag
        ret |= preRenderFlag
        return ret
    }
    
    func onCaptureVideoSample(_ videoSource: AliRtcVideoSource, videoSample: AliRtcVideoDataSample) -> Bool {
        guard let pixelBuffer = videoSample.pixelBuffer else { return false }
        let seatView = ensureSeatView(for: self.userId, isLocal: true)
        seatView.videoRenderView.render(pixelBuffer: pixelBuffer)
        return true
    }
    
    func onRemoteVideoSample(_ uid: String, videoSource: AliRtcVideoSource, videoSample: AliRtcVideoDataSample) -> Bool {
        guard let pixelBuffer = videoSample.pixelBuffer else {
            print("Remote video buffer is nil, uid: \(uid)")
            return false
        }

        let seatView = ensureSeatView(for: uid)
        seatView.videoRenderView.render(pixelBuffer: pixelBuffer)
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
        removeSeatView(for: uid)
    }

    func onRemoteTrackAvailableNotify(_ uid: String, audioTrack: AliRtcAudioTrack, videoTrack: AliRtcVideoTrack) {
        "onRemoteTrackAvailableNotify uid: \(uid) audioTrack: \(audioTrack) videoTrack: \(videoTrack)".printLog()

        if videoTrack != .no {
            let seatView = ensureSeatView(for: uid)
            seatView.uid = uid
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
