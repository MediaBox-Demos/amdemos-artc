//
//  TokenGenerateVC.swift
//  ARTCExample
//
//  Created by Bingo on 2025/5/26.
//

import UIKit
import AliVCSDK_ARTC

class TokenGenerateSetParamsVC: UIViewController, UITextFieldDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.title = "Token Generate".localized
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        self.appIdTextField.delegate = self
        self.appKeyTextField.delegate = self
        self.userIdTextField.delegate = self
        self.channelIdTextField.delegate = self
        self.timestampTextField.delegate = self
        self.nonceTextField.delegate = self
        
        self.appIdTextField.text = GlobalConfig.shared.appId
        self.appKeyTextField.text = GlobalConfig.shared.appKey
        self.userIdTextField.text = GlobalConfig.shared.userId
        self.timestampTextField.text = "\(Int(Date().timeIntervalSince1970 + 24 * 60 * 60))" // 1 day
    }
    
    @IBOutlet weak var appIdTextField: UITextField!
    
    @IBOutlet weak var appKeyTextField: UITextField!
    
    @IBOutlet weak var userIdTextField: UITextField!
    
    @IBOutlet weak var channelIdTextField: UITextField!
    
    @IBOutlet weak var timestampTextField: UITextField!
    
    @IBOutlet weak var nonceTextField: UITextField!
    
    @IBAction func startJoinWithAuthInfo(_ sender: Any) {
        let helper = ARTCTokenHelper()
        let appId = self.appIdTextField.text ?? ""
        let appKey = self.appKeyTextField.text ?? ""
        let channelId = self.channelIdTextField.text ?? ""
        let userId = self.userIdTextField.text ?? ""
        let nonce = self.nonceTextField.text ?? ""
        let timestamp = Int64(self.timestampTextField.text ?? "") ?? Int64(Date().timeIntervalSince1970 + 24 * 60 * 60)
        let authToken = helper.generateAuthInfoToken(appId: appId, appKey: appKey, channelId: channelId, userId: userId, timestamp: timestamp)
        
        let authInfo = AliRtcAuthInfo()
        authInfo.appId = appId
        authInfo.channelId = channelId
        authInfo.nonce = nonce
        authInfo.userId = userId
        authInfo.timestamp = timestamp
        authInfo.token = authToken
        
        // 计算“过期时长 = 选择的 timestamp - 当前时间”
        let now = Int64(Date().timeIntervalSince1970)
        let expireDuration = max(timestamp - now, 0)
        
        let vc = self.presentVC(storyboardName: "TokenGenerate", storyboardId: "MainVC") as? TokenGenerateMainVC
        vc?.channelId = channelId
        vc?.userId = userId
        vc?.joinAuthInfo = authInfo
        
        // 传递用于后续刷新 Token 的参数
        vc?.appId = appId
        vc?.appKey = appKey
        vc?.nonce = nonce
        vc?.expireDurationSeconds = expireDuration
    }
    
    @IBAction func startJoinWithToken(_ sender: Any) {
        
        let helper = ARTCTokenHelper()
        let appId = self.appIdTextField.text ?? ""
        let appKey = self.appKeyTextField.text ?? ""
        let channelId = self.channelIdTextField.text ?? ""
        let userId = self.userIdTextField.text ?? ""
        let nonce = self.nonceTextField.text ?? ""
        let timestamp = Int64(self.timestampTextField.text ?? "") ?? Int64(Date().timeIntervalSince1970 + 24 * 60 * 60)
        let joinToken = helper.generateJoinToken(appId: appId, appKey: appKey, channelId: channelId, userId: userId, timestamp: timestamp, nonce: nonce)
        
        // 计算“过期时长 = 选择的 timestamp - 当前时间”
        let now = Int64(Date().timeIntervalSince1970)
        let expireDuration = max(timestamp - now, 0)
        
        let vc = self.presentVC(storyboardName: "TokenGenerate", storyboardId: "MainVC") as? TokenGenerateMainVC
        vc?.channelId = channelId
        vc?.userId = userId
        vc?.joinToken = joinToken
        
        // 传递用于后续刷新 Token 的参数
        vc?.appId = appId
        vc?.appKey = appKey
        vc?.nonce = nonce
        vc?.expireDurationSeconds = expireDuration
    }
    
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
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



class TokenGenerateMainVC: UIViewController {

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
    var joinAuthInfo: AliRtcAuthInfo? = nil
    
    // 用于刷新 Token 的原始参数和过期时长（秒）
    var appId: String = GlobalConfig.shared.appId
    var appKey: String = GlobalConfig.shared.appKey
    var nonce: String = ""
    var expireDurationSeconds: Int64 = 24 * 60 * 60
    
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

        // 设置默认订阅远端的音频和视频流
        engine.setDefaultSubscribeAllRemoteAudioStreams(true)
        engine.subscribeAllRemoteAudioStreams(true)
        engine.publishLocalAudioStream(true)
        engine.setDefaultSubscribeAllRemoteVideoStreams(true)
        engine.subscribeAllRemoteVideoStreams(true)
        
        self.rtcEngine = engine
    }
    
    func joinChannel() {
        
        // 单参数入会
        if let joinToken = self.joinToken {
            let msg =  "JoinWithToken: \(joinToken)"
            
            let ret = self.rtcEngine?.joinChannel(joinToken, channelId: nil, userId: nil, name: nil) { [weak self] errCode, channelId, userId, elapsed in
                if errCode == 0 {
                    // success

                }
                else {
                    // failed
                }
                
                let resultMsg = "\(msg) \n CallbackErrorCode: \(errCode)"
                resultMsg.printLog()
                UIAlertController.showAlertWithMainThread(msg: resultMsg, vc: self!)
            }
            
            let resultMsg = "\(msg) \n ReturnErrorCode: \(ret ?? 0)"
            resultMsg.printLog()
            if ret != 0 {
                UIAlertController.showAlertWithMainThread(msg: resultMsg, vc: self)
            }
            return
        }
        
        // 多参数入会
        if let authInfo = self.joinAuthInfo {
            let msgDict: [String: Any] = [
                "appid": authInfo.appId,
                "channelid": authInfo.channelId,
                "userid": authInfo.userId,
                "nonce": authInfo.nonce,
                "timestamp": authInfo.timestamp,
                "token": authInfo.token
            ]
            let msg = "AuthInfo: \(msgDict.jsonString)"
            let ret = self.rtcEngine?.joinChannel(authInfo, name: nil) { [weak self] errCode, channelId, userId, elapsed in
                if errCode == 0 {
                    // success

                }
                else {
                    // failed
                }
                
                let resultMsg = "\(msg) \n CallbackErrorCode: \(errCode)"
                resultMsg.printLog()
                UIAlertController.showAlertWithMainThread(msg: resultMsg, vc: self!)
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
        
        self.rtcEngine?.setLocalViewConfig(canvas, for: AliRtcVideoTrack.camera)
        self.rtcEngine?.startPreview()
    }
    
    func leaveAnddestroyEngine() {
        self.rtcEngine?.stopPreview()
        self.rtcEngine?.leaveChannel()
        AliRtcEngine.destroy()
        self.rtcEngine = nil
    }
    
    /// 刷新 Token（对应 Android 的 refreshToken）
    func refreshToken() {
        guard let engine = self.rtcEngine else { return }
        
        // 基于“当前时间 + 当初记录的过期时长”重新计算新的 timestamp
        let now = Int64(Date().timeIntervalSince1970)
        let newTimestamp = now + self.expireDurationSeconds
        
        if var authInfo = self.joinAuthInfo {
            // 多参数入会：重新生成多参 Token
            let helper = ARTCTokenHelper()
            let newToken = helper.generateAuthInfoToken(appId: self.appId,
                                                        appKey: self.appKey,
                                                        channelId: self.channelId,
                                                        userId: self.userId,
                                                        timestamp: newTimestamp)
            authInfo.timestamp = newTimestamp
            authInfo.token = newToken
            self.joinAuthInfo = authInfo
            
            let ret = engine.refreshAuthInfo(authInfo)
            let msg = "refreshAuthInfo(AliRtcAuthInfo) ret: \(ret)"
            msg.printLog()
            
            if ret != 0 {
                UIAlertController.showAlertWithMainThread(msg: "Token 刷新失败，错误码: \(ret)", vc: self)
            } else {
                UIAlertController.showAlertWithMainThread(msg: "Token 刷新成功", vc: self)
            }
        } else if self.joinToken != nil {
            // 单参数入会：重新生成单参 Token
            let helper = ARTCTokenHelper()
            let newToken = helper.generateJoinToken(appId: self.appId,
                                                    appKey: self.appKey,
                                                    channelId: self.channelId,
                                                    userId: self.userId,
                                                    timestamp: newTimestamp,
                                                    nonce: self.nonce)
            self.joinToken = newToken
            
            let ret = engine.refreshAuthInfo(withToken: newToken)
            let msg = "refreshAuthInfoWithToken ret: \(ret)"
            msg.printLog()
            
            if ret != 0 {
                UIAlertController.showAlertWithMainThread(msg: "Token 刷新失败，错误码: \(ret)", vc: self)
            } else {
                UIAlertController.showAlertWithMainThread(msg: "Token 刷新成功", vc: self)
            }
        }
    }
    
    
    func createSeatView(uid: String) -> SeatView {
        let view = SeatView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
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

extension TokenGenerateMainVC: AliRtcEngineDelegate {
    
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
        
        // Token 即将过期（提前 30s），弹窗提示并提供刷新按钮
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let alert = UIAlertController(title: "Token 即将过期",
                                          message: "当前 Token 即将在 30 秒后过期，是否刷新 Token 继续通话？",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "刷新 Token", style: .default, handler: { _ in
                self.refreshToken()
            }))
            alert.addAction(UIAlertAction(title: "稍后", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func onAuthInfoExpired() {
        "onAuthInfoExpired".printLog()
        
        // Token 已过期，提示用户重新入会
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let alert = UIAlertController(title: "Token 已过期",
                                          message: "当前 Token 已经过期，请重新加入会议。",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default, handler: { _ in
                // 挂断并关闭当前页面，返回到 SetParamsVC
                self.leaveAnddestroyEngine()
                self.navigationController?.popViewController(animated: true)
            }))
            self.present(alert, animated: true, completion: nil)
        }
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
