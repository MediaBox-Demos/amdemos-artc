//
//  PublishLiveStreamVC.swift
//  ARTCExample
//
//  Created by wy on 2025/12/25.
//

import UIKit
import AliVCSDK_ARTC

/// 入会前配置页面：输入 ChannelID 和 Stream URL
class PublishLiveStreamSetParamsVC: UIViewController, UITextFieldDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Publish Live Stream".localized
        
        self.channelIdTextField.delegate = self
        self.streamUrlTextField.delegate = self
    }
    
    @IBOutlet weak var channelIdTextField: UITextField!
    @IBOutlet weak var streamUrlTextField: UITextField!
    
    @IBAction func onJoinChannelBtnClicked(_ sender: Any) {
        guard let channelId = self.channelIdTextField.text, channelId.isEmpty == false else {
            return
        }
        
        let streamUrl = self.streamUrlTextField.text ?? ""
        
        let helper = ARTCTokenHelper()
        let userId = GlobalConfig.shared.userId
        let timestamp = Int64(Date().timeIntervalSince1970 + 24 * 60 * 60)
        let joinToken = helper.generateJoinToken(channelId: channelId, userId: userId, timestamp: timestamp)
        
        let vc = self.presentVC(storyboardName: "PublishLiveStream", storyboardId: "MainVC") as? PublishLiveStreamMainVC
        vc?.channelId = channelId
        vc?.userId = userId
        vc?.joinToken = joinToken
        vc?.streamUrl = streamUrl
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}


/// 主页面：视频通话 + 旁路操作
class PublishLiveStreamMainVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = self.channelId
        
        self.setup()
        self.startPreview()
        self.joinChannel()
        
        updateButtonStates()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.updateSeatViewsLayout()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.stopLiveStreamingIfNeeded()
        self.leaveAnddestroyEngine()
    }
    
    @IBOutlet weak var contentScrollView: UIScrollView!
    @IBOutlet weak var startPublishButton: UIButton!
    @IBOutlet weak var updatePublishButton: UIButton!
    @IBOutlet weak var stopPublishButton: UIButton!
    
    var seatViewList: [SeatView] = []
    
    var channelId: String = ""
    var userId: String = ""
    var streamUrl: String = ""
    
    var rtcEngine: AliRtcEngine? = nil
    var joinToken: String? = nil
    
    var isPublishingLive: Bool = false
    var currentStreamUrl: String?
    
    func setup() {
        
        // 创建并初始化引擎
        let engine = AliRtcEngine.sharedInstance(self, extras: nil)
        
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
    
    // MARK: - 旁路操作
    
    @IBAction func onStartPublishTapped(_ sender: UIButton) {
        startLiveStreaming()
    }
    
    @IBAction func onUpdatePublishTapped(_ sender: UIButton) {
        updateLiveStreaming()
    }
    
    @IBAction func onStopPublishTapped(_ sender: UIButton) {
        stopLiveStreaming()
    }
    
    /// 启动旁路（使用 streamUrl 版 API）
    private func startLiveStreaming() {
        guard let engine = rtcEngine else {
            "rtcEngine is nil".printLog()
            return
        }
        
        guard !streamUrl.isEmpty else {
            "Stream URL is empty".printLog()
            return
        }
        
        let param = AliRtcLiveTranscodingParam()
        // 默认 single 模式，不设置 mixParam，演示流程即可
        
        let ret = engine.startPublishLiveStream(withURL: streamUrl, liveTranscoding: param)
        "startPublishLiveStream url:\(streamUrl) ret:\(ret)".printLog()
        if ret == 0 {
            isPublishingLive = true
            currentStreamUrl = streamUrl
            updateButtonStates()
        }
    }
    
    /// 更新旁路参数
    private func updateLiveStreaming() {
        guard let engine = rtcEngine else { return }
        guard let streamUrl = currentStreamUrl, !streamUrl.isEmpty else { return }
        
        let param = AliRtcLiveTranscodingParam()
        // 这里可以演示修改参数，例如切换 TaskProfile / 分辨率等
        
        let ret = engine.updatePublishLiveStream(withURL: streamUrl, liveTranscoding: param)
        "updatePublishLiveStream url:\(streamUrl) ret:\(ret)".printLog()
    }
    
    /// 停止旁路
    private func stopLiveStreaming() {
        guard let engine = rtcEngine else { return }
        guard let streamUrl = currentStreamUrl, !streamUrl.isEmpty else { return }
        
        let ret = engine.stopPublishLiveStream(withURL: streamUrl)
        "stopPublishLiveStream url:\(streamUrl) ret:\(ret)".printLog()
        isPublishingLive = false
        currentStreamUrl = nil
        updateButtonStates()
    }
    
    private func stopLiveStreamingIfNeeded() {
        if isPublishingLive {
            stopLiveStreaming()
        }
    }
    
    /// 按钮状态控制：未推流时只能 Start，推流中启用 Update/Stop
    private func updateButtonStates() {
        if isPublishingLive {
            startPublishButton.isEnabled = false
            startPublishButton.alpha = 0.5
            
            updatePublishButton.isEnabled = true
            updatePublishButton.alpha = 1.0
            
            stopPublishButton.isEnabled = true
            stopPublishButton.alpha = 1.0
        } else {
            startPublishButton.isEnabled = true
            startPublishButton.alpha = 1.0
            
            updatePublishButton.isEnabled = false
            updatePublishButton.alpha = 0.5
            
            stopPublishButton.isEnabled = false
            stopPublishButton.alpha = 0.5
        }
    }
}

extension PublishLiveStreamMainVC: AliRtcEngineDelegate {
    
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
    
    // 旁路状态回调（streamUrl 版）
    func onPublishLiveStreamStateChanged(_ streamURL: String,
                                         state: AliRtcLiveTranscodingState,
                                         errCode: AliRtcTrascodingLiveStreamErrorCode) {
        "onPublishLiveStreamStateChanged url:\(streamURL) state:\(state) err:\(errCode)".printLog()
    }
    
    func onPublishTaskStateChanged(_ streamURL: String,
                                   state: AliRtcTrascodingLiveTaskStatus) {
        "onPublishTaskStateChanged url:\(streamURL) state:\(state)".printLog()
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
