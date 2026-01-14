//
//  LiveLinkMicVC.swift
//  ARTCExample
//
//  Created by wy on 2026/1/9.
//

import UIKit
import AliVCSDK_ARTC

// MARK: - 入会前配置页面：输入 ChannelID + 选择角色(主播/连麦观众)

class LiveLinkMicSetParamsVC: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var channelIdTextField: UITextField!
    @IBOutlet weak var roleSegmentedControl: UISegmentedControl!  // 0: 主播  1: 连麦观众

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Live Link Mic".localized
        self.channelIdTextField.delegate = self

        // 默认选中"主播"
        if roleSegmentedControl.numberOfSegments >= 2 {
            roleSegmentedControl.selectedSegmentIndex = 0
        }
    }

    @IBAction func onJoinChannelBtnClicked(_ sender: Any) {
        guard let channelId = self.channelIdTextField.text, channelId.isEmpty == false else {
            return
        }

        let isAnchor = (roleSegmentedControl.selectedSegmentIndex == 0)

        // 单参入会：生成 joinToken
        let helper = ARTCTokenHelper()
        let userId = GlobalConfig.shared.userId
        let timestamp = Int64(Date().timeIntervalSince1970 + 24 * 60 * 60)
        let joinToken = helper.generateJoinToken(channelId: channelId,
                                                 userId: userId,
                                                 timestamp: timestamp)

        // 跳转到主页面 LiveLinkMicMainVC
        let vc = self.presentVC(storyboardName: "LiveLinkMic",
                                storyboardId: "MainVC") as? LiveLinkMicMainVC
        vc?.channelId = channelId
        vc?.userId = userId
        vc?.joinToken = joinToken
        vc?.isAnchorRole = isAnchor
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - 主页面：视频 + 连麦 + 跨频道订阅(PK)

class LiveLinkMicMainVC: UIViewController {

    // UI
    @IBOutlet weak var contentScrollView: UIScrollView!

    // PK 跨频道订阅相关 UI（只对主播显示）
    @IBOutlet weak var pkContainerView: UIView!
    @IBOutlet weak var peerChannelIdTextField: UITextField!
    @IBOutlet weak var peerUidTextField: UITextField!
    @IBOutlet weak var pkSubscribeButton: UIButton!
    
    // CDN 旁路转推相关 UI（只对主播显示）
    @IBOutlet weak var publishContainerView: UIView!
    @IBOutlet weak var streamUrlTextField: UITextField!
    @IBOutlet weak var startPublishButton: UIButton!
    @IBOutlet weak var stopPublishButton: UIButton!

    // 座位布局
    var seatViewList: [SeatView] = []

    // 入会参数
    var channelId: String = ""
    var userId: String = ""
    var joinToken: String?

    // 角色：主播 / 连麦观众
    var isAnchorRole: Bool = true

    // RTC 引擎
    var rtcEngine: AliRtcEngine? = nil

    // PK 跨频道订阅状态
    var isSubscribingPeer: Bool = false
    var currentPeerChannelId: String?
    var currentPeerUid: String?
    
    // CDN 旁路转推状态
    var isPublishingLive: Bool = false
    var currentStreamUrl: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = self.channelId

        self.setup()
        self.setupPKUI()
        self.setupPublishUI()
        self.startPreview()
        self.joinChannel()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.updateSeatViewsLayout()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        self.stopCrossChannelSubscribeIfNeeded()
        self.stopLiveStreamingIfNeeded()
        self.leaveAndDestroyEngine()
    }

    // MARK: - 基础 RTC 配置

    func setup() {
        // 创建并初始化引擎
        let engine = AliRtcEngine.sharedInstance(self, extras: nil)

        // 设置日志级别
        engine.setLogLevel(.info)

        // 频道模式：互动直播
        engine.setChannelProfile(AliRtcChannelProfile.interactivelive)
        // 角色：需要推也需要拉 => Interactive
        engine.setClientRole(AliRtcClientRole.roleInteractive)

        // 音频 Profile
        engine.setAudioProfile(AliRtcAudioProfile.engineHighQualityMode,
                               audio_scene: AliRtcAudioScenario.sceneMusicMode)

        // 视频编码参数
        let config = AliRtcVideoEncoderConfiguration()
        config.dimensions = CGSize(width: 720, height: 1280)
        config.frameRate = 20
        config.bitrate = 1200
        config.keyFrameInterval = 2000
        config.orientationMode = AliRtcVideoEncoderOrientationMode.adaptive
        engine.setVideoEncoderConfiguration(config)
        engine.setCapturePipelineScaleMode(.post)

        // 发布本地音视频
        engine.publishLocalVideoStream(true)
        engine.publishLocalAudioStream(true)

        // 默认订阅远端音视频
        engine.setDefaultSubscribeAllRemoteAudioStreams(true)
        engine.subscribeAllRemoteAudioStreams(true)
        engine.setDefaultSubscribeAllRemoteVideoStreams(true)
        engine.subscribeAllRemoteVideoStreams(true)

        self.rtcEngine = engine
    }

    func joinChannel() {
        guard let joinToken = self.joinToken else { return }

        // 单参入会
        let msg = "JoinWithToken: \(joinToken)"

        let ret = self.rtcEngine?.joinChannel(joinToken,
                                             channelId: nil,
                                             userId: nil,
                                             name: nil) { [weak self] errCode, channelId, userId, elapsed in
            let resultMsg = "\(msg) \n CallbackErrorCode: \(errCode)"
            resultMsg.printLog()
            if errCode != 0 {
                if let self = self {
                    UIAlertController.showAlertWithMainThread(msg: resultMsg, vc: self)
                }
            }
        }

        let resultMsg = "\(msg) \n ReturnErrorCode: \(ret ?? 0)"
        resultMsg.printLog()
        if ret != 0 {
            UIAlertController.showAlertWithMainThread(msg: resultMsg, vc: self)
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

    func leaveAndDestroyEngine() {
        self.rtcEngine?.stopPreview()
        self.rtcEngine?.leaveChannel()
        AliRtcEngine.destroy()
        self.rtcEngine = nil
    }

    // MARK: - 座位视图管理

    /// 创建一个渲染视图，并加入到 contentScrollView 中
    func createSeatView(uid: String) -> SeatView {
        let view = SeatView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.uidLabel.text = uid

        self.contentScrollView.addSubview(view)
        self.seatViewList.append(view)
        self.updateSeatViewsLayout()
        return view
    }

    /// 从 contentScrollView 移除一个渲染视图
    func removeSeatView(uid: String) {
        let seatView = self.seatViewList.first { $0.uidLabel.text == uid }
        if let seatView = seatView {
            seatView.removeFromSuperview()
            self.seatViewList.removeAll(where: { $0 == seatView })
            self.updateSeatViewsLayout()
        }
    }

    /// 刷新 contentScrollView 的子视图布局
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

    // MARK: - PK 跨频道订阅 UI & 操作

    func setupPKUI() {
        // 非主播隐藏 PK 区域
        pkContainerView.isHidden = !isAnchorRole

        // 默认未订阅
        isSubscribingPeer = false
        updatePKButtonState()
    }

    func updatePKButtonState() {
        if isSubscribingPeer {
            pkSubscribeButton.setTitle("Stop PK Subscribe".localized, for: .normal)
        } else {
            pkSubscribeButton.setTitle("Start PK Subscribe".localized, for: .normal)
        }
    }

    @IBAction func onPkSubscribeTapped(_ sender: UIButton) {
        if isSubscribingPeer {
            stopCrossChannelSubscribe()
        } else {
            startCrossChannelSubscribe()
        }
    }

    /// 开始跨频道订阅：订阅目标频道中指定 uid 的音视频流
    private func startCrossChannelSubscribe() {
        guard isAnchorRole else { return }
        guard let engine = rtcEngine else {
            "rtcEngine is nil".printLog()
            return
        }

        let channelId = peerChannelIdTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let uid = peerUidTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard channelId.isEmpty == false else {
            "peerChannelId is empty".printLog()
            return
        }
        guard uid.isEmpty == false else {
            "peerUid is empty".printLog()
            return
        }

        // iOS 跨频道订阅接口
        let ret = engine.subscribeRemoteDestChannelStream(channelId,
                                                          uid: uid,
                                                          videoTrack: .camera,
                                                          audioTrack: .mic,
                                                          sub: true)
        "startCrossChannelSubscribe channelId:\(channelId) uid:\(uid) ret:\(ret)".printLog()

        if ret == 0 {
            isSubscribingPeer = true
            currentPeerChannelId = channelId
            currentPeerUid = uid

            DispatchQueue.main.async {
                self.peerChannelIdTextField.isEnabled = false
                self.peerUidTextField.isEnabled = false
                self.updatePKButtonState()
            }
        }
    }

    /// 停止跨频道订阅
    private func stopCrossChannelSubscribe() {
        guard let engine = rtcEngine else { return }
        guard let channelId = currentPeerChannelId,
              let uid = currentPeerUid else {
            return
        }

        let ret = engine.subscribeRemoteDestChannelStream(channelId,
                                                          uid: uid,
                                                          videoTrack: .no,
                                                          audioTrack: .no,
                                                          sub: false)
        "stopCrossChannelSubscribe channelId:\(channelId) uid:\(uid) ret:\(ret)".printLog()

        // 移除该 uid 的所有座位
        DispatchQueue.main.async {
            self.removeSeatView(uid: uid)
        }

        isSubscribingPeer = false
        currentPeerChannelId = nil
        currentPeerUid = nil

        DispatchQueue.main.async {
            self.peerChannelIdTextField.isEnabled = true
            self.peerUidTextField.isEnabled = true
            self.updatePKButtonState()
        }
    }

    private func stopCrossChannelSubscribeIfNeeded() {
        if isSubscribingPeer {
            stopCrossChannelSubscribe()
        }
    }
    
    // MARK: - CDN 旁路转推 UI & 操作
    
    func setupPublishUI() {
        // 非主播隐藏旁路区域
        publishContainerView.isHidden = !isAnchorRole
        
        // 设置默认推流 URL
        streamUrlTextField.text = "rtmp://rmspush.chinalivestream.top/AliRtcSdk/livelink"
        
        // 默认未推流
        isPublishingLive = false
        updatePublishButtonState()
    }
    
    func updatePublishButtonState() {
        if isPublishingLive {
            startPublishButton.isEnabled = false
            startPublishButton.alpha = 0.5
            
            stopPublishButton.isEnabled = true
            stopPublishButton.alpha = 1.0
        } else {
            startPublishButton.isEnabled = true
            startPublishButton.alpha = 1.0
            
            stopPublishButton.isEnabled = false
            stopPublishButton.alpha = 0.5
        }
    }
    
    @IBAction func onStartPublishTapped(_ sender: UIButton) {
        startLiveStreaming()
    }
    
    @IBAction func onStopPublishTapped(_ sender: UIButton) {
        stopLiveStreaming()
    }
    
    /// 开始 CDN 旁路转推
    private func startLiveStreaming() {
        guard isAnchorRole else { return }
        guard let engine = rtcEngine else {
            "rtcEngine is nil".printLog()
            return
        }
        
        let streamUrl = streamUrlTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard streamUrl.isEmpty == false else {
            "Stream URL is empty".printLog()
            return
        }
        
        // iOS 旁路转推接口
        let param = AliRtcLiveTranscodingParam()
        // 默认 single 模式，不设置 mixParam
        
        let ret = engine.startPublishLiveStream(withURL: streamUrl, liveTranscoding: param)
        "startLiveStreaming url:\(streamUrl) ret:\(ret)".printLog()
        
        if ret == 0 {
            isPublishingLive = true
            currentStreamUrl = streamUrl
            
            DispatchQueue.main.async {
                self.updatePublishButtonState()
            }
        }
    }
    
    /// 停止 CDN 旁路转推
    private func stopLiveStreaming() {
        guard let engine = rtcEngine else { return }
        guard let streamUrl = currentStreamUrl, !streamUrl.isEmpty else { return }
        
        let ret = engine.stopPublishLiveStream(withURL: streamUrl)
        "stopLiveStreaming url:\(streamUrl) ret:\(ret)".printLog()
        
        isPublishingLive = false
        currentStreamUrl = nil
        
        DispatchQueue.main.async {
            self.updatePublishButtonState()
        }
    }
    
    private func stopLiveStreamingIfNeeded() {
        if isPublishingLive {
            stopLiveStreaming()
        }
    }
}

// MARK: - AliRtcEngineDelegate

extension LiveLinkMicMainVC: AliRtcEngineDelegate {

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
        DispatchQueue.main.async {
            self.removeSeatView(uid: uid)
        }
    }

    func onRemoteTrackAvailableNotify(_ uid: String,
                                      audioTrack: AliRtcAudioTrack,
                                      videoTrack: AliRtcVideoTrack) {
        "onRemoteTrackAvailableNotify uid: \(uid) audioTrack: \(audioTrack)  videoTrack: \(videoTrack)".printLog()

        DispatchQueue.main.async {
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
                self.rtcEngine?.setRemoteViewConfig(canvas,
                                                    uid: uid,
                                                    for: AliRtcVideoTrack.camera)
            } else {
                self.rtcEngine?.setRemoteViewConfig(nil,
                                                    uid: uid,
                                                    for: AliRtcVideoTrack.camera)
            }

            if audioTrack == .no && videoTrack == .no {
                self.removeSeatView(uid: uid)
                self.rtcEngine?.setRemoteViewConfig(nil,
                                                    uid: uid,
                                                    for: AliRtcVideoTrack.camera)
            }
        }
    }

    func onAuthInfoWillExpire() {
        "onAuthInfoWillExpire".printLog()
        /* TODO: Token 即将过期，业务需要刷新 Token */
    }

    func onAuthInfoExpired() {
        "onAuthInfoExpired".printLog()
        /* TODO: Token 已过期，提示用户并执行离会 */
    }

    func onBye(_ code: Int32) {
        "onBye code: \(code)".printLog()
    }

    func onLocalDeviceException(_ deviceType: AliRtcLocalDeviceType,
                                exceptionType: AliRtcLocalDeviceExceptionType,
                                message msg: String?) {
        "onLocalDeviceException deviceType: \(deviceType)  exceptionType: \(exceptionType)".printLog()
    }

    func onConnectionStatusChange(_ status: AliRtcConnectionStatus,
                                  reason: AliRtcConnectionStatusChangeReason) {
        "onConnectionStatusChange status: \(status)  reason: \(reason)".printLog()
    }
}
