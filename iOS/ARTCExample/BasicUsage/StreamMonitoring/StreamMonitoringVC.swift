//
//  StreamMonitoringVC.swift
//  ARTCExample
//
//  Created by wy on 2025/7/28.
//

import Foundation
import Foundation
import AliVCSDK_ARTC

class StreamMonitoringSetParamsVC: UIViewController, UITextFieldDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Stream Monitoring".localized
        
        self.channelIdTextField.delegate = self
    }
    
    @IBOutlet weak var channelIdTextField: UITextField!
    @IBAction func onJoinChannelBtnClicked(_ sender: UIButton) {
        guard let channelId = self.channelIdTextField.text, channelId.isEmpty == false else {
            return
        }
        
        let helper = ARTCTokenHelper()
        let userId = GlobalConfig.shared.userId
        let timestamp = Int64(Date().timeIntervalSince1970 + 24 * 60 * 60)
        let joinToken = helper.generateJoinToken(channelId: channelId, userId: userId, timestamp: timestamp)
        let vc = self.presentVC(storyboardName: "StreamMonitoring", storyboardId: "MainVC") as? StreamMonitoringMainVC
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

// MARK: - 统计模型
struct StatItem {
    let title: String
    let data: String
}
// MARK: - CollectionViewCell
class StatCell: UICollectionViewCell {
    static let reuseId = "StatCell"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 14)
        label.textColor = .black
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return label
    }()
    
    private let dataLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.textAlignment = .right
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        label.numberOfLines = 1
        return label
    }()
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .top
        stack.spacing = 8
        return stack
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(dataLabel)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
        ])
    }
    
    func configure(with item: StatItem) {
        titleLabel.text = item.title + ":"
        dataLabel.text = item.data
    }
}

class StreamMonitoringMainVC: UIViewController {
    
    var collectionView: UICollectionView!
    var statsData: [StatItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = self.channelId
        setupCollectionView()
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
    
    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumLineSpacing = 10
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.register(StatCell.self, forCellWithReuseIdentifier: StatCell.reuseId)
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
    
    func updateStatsData(with newStats: [StatItem]) {
        DispatchQueue.main.async {
            self.statsData = newStats
            self.collectionView.reloadData()
        }
    }
    
    @IBOutlet weak var contentScrollView: UIScrollView!
    
    var seatViewList: [SeatView] = []
    
    var channelId: String = ""
    var userId: String = ""
    
    var rtcEngine: AliRtcEngine? = nil

    var joinToken: String? = nil
    
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension StreamMonitoringMainVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return statsData.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StatCell.reuseId, for: indexPath) as! StatCell
        cell.configure(with: statsData[indexPath.item])
        cell.contentView.backgroundColor = UIColor(white: 0.95, alpha: 1)
        cell.contentView.layer.cornerRadius = 8
        cell.contentView.layer.masksToBounds = true
        return cell
    }
}

extension StreamMonitoringMainVC: AliRtcEngineDelegate {
    // MARK: Stream Monitoring Callback
    func onRtcStats(_ stats: AliRtcStats) {
        var newStats = statsData.filter { !$0.title.hasPrefix("GlobalStats") }
        newStats.append(StatItem(title: "GlobalStats Available Sent Bitrate", data: "\(stats.available_sent_kbitrate) kbps"))
        newStats.append(StatItem(title: "GlobalStats Sent Bitrate", data: "\(stats.sent_kbitrate) kbps"))
        newStats.append(StatItem(title: "GlobalStats Received Bitrate", data: "\(stats.rcvd_kbitrate) kbps"))
        newStats.append(StatItem(title: "GlobalStats Sent Bytes", data: "\(stats.sent_bytes) B"))
        newStats.append(StatItem(title: "GlobalStats Received Bytes", data: "\(stats.rcvd_bytes) B"))
        newStats.append(StatItem(title: "GlobalStats Video Received Bitrate", data: "\(stats.video_rcvd_kbitrate) kbps"))
        newStats.append(StatItem(title: "GlobalStats Video Sent Bitrate", data: "\(stats.video_sent_kbitrate) kbps"))
        newStats.append(StatItem(title: "GlobalStats Call Duration", data: "\(stats.call_duration) s"))
        newStats.append(StatItem(title: "GlobalStats CPU Usage", data: "\(stats.cpu_usage)%"))
        newStats.append(StatItem(title: "GlobalStats System CPU Usage", data: "\(stats.systemCpuUsage)%"))
        newStats.append(StatItem(title: "GlobalStats Sent Loss Rate", data: "\(stats.sent_loss_rate)%"))
        newStats.append(StatItem(title: "GlobalStats Sent Loss Packets", data: "\(stats.sent_loss_pkts)"))
        newStats.append(StatItem(title: "GlobalStats Sent Expected Packets", data: "\(stats.sent_expected_pkts)"))
        newStats.append(StatItem(title: "GlobalStats Received Loss Rate", data: "\(stats.rcvd_loss_rate)%"))
        newStats.append(StatItem(title: "GlobalStats Received Loss Packets", data: "\(stats.rcvd_loss_pkts)"))
        newStats.append(StatItem(title: "GlobalStats Received Expected Packets", data: "\(stats.rcvd_expected_pkts)"))
        newStats.append(StatItem(title: "GlobalStats Last Mile Delay", data: "\(stats.lastmile_delay) ms"))
        
        updateStatsData(with: newStats)
        
    }
    
    func onRtcLocalAudioStats(_ localAudioStats: AliRtcLocalAudioStats) {
        var newStats = statsData.filter { !$0.title.hasPrefix("LocalAudio") }
                
        newStats.append(StatItem(title: "LocalAudio Track", data: "\(localAudioStats.track)"))
        newStats.append(StatItem(title: "LocalAudio Channels", data: "\(localAudioStats.num_channel)"))
        newStats.append(StatItem(title: "LocalAudio Samplerate", data: "\(localAudioStats.sent_samplerate) Hz"))
        newStats.append(StatItem(title: "LocalAudio Sent Bitrate", data: "\(localAudioStats.sent_bitrate) kbps"))
        
        updateStatsData(with: newStats)
    }
    
    func onRtcRemoteAudioStats(_ remoteAudioStats: AliRtcRemoteAudioStats) {
        var newStats = statsData.filter { !$0.title.hasPrefix("RemoteAudio-\(remoteAudioStats.userId)") }
                
        newStats.append(StatItem(title: "RemoteAudio-\(remoteAudioStats.userId) Track", data: "\(remoteAudioStats.track)"))
        newStats.append(StatItem(title: "RemoteAudio-\(remoteAudioStats.userId) Quality", data: "\(remoteAudioStats.quality)"))
        newStats.append(StatItem(title: "RemoteAudio-\(remoteAudioStats.userId) Loss Rate", data: "\(remoteAudioStats.audio_loss_rate)%"))
        newStats.append(StatItem(title: "RemoteAudio-\(remoteAudioStats.userId) Bitrate", data: "\(remoteAudioStats.rcvd_bitrate) kbps"))
        newStats.append(StatItem(title: "RemoteAudio-\(remoteAudioStats.userId) Frozen Time", data: "\(remoteAudioStats.audio_total_frozen_time) ms"))
        newStats.append(StatItem(title: "RemoteAudio-\(remoteAudioStats.userId) Frozen Rate", data: "\(remoteAudioStats.audio_total_frozen_rate)%"))
        newStats.append(StatItem(title: "RemoteAudio-\(remoteAudioStats.userId) Network Delay", data: "\(remoteAudioStats.network_transport_delay) ms"))
        newStats.append(StatItem(title: "RemoteAudio-\(remoteAudioStats.userId) Jitter Delay", data: "\(remoteAudioStats.jitter_buffer_delay) ms"))
        
        updateStatsData(with: newStats)
        
    }
    
    func onRtcLocalVideoStats(_ localVideoStats: AliRtcLocalVideoStats) {
        var newStats = statsData.filter { !$0.title.hasPrefix("LocalVideo") } // 移除旧的本地视频数据
        newStats.append(StatItem(title: "LocalVideo Track", data: "\(localVideoStats.track)"))
        newStats.append(StatItem(title: "LocalVideo Target Bitrate", data: "\(localVideoStats.target_encode_bitrate) kbps"))
        newStats.append(StatItem(title: "LocalVideo Actual Bitrate", data: "\(localVideoStats.actual_encode_bitrate) kbps"))
        newStats.append(StatItem(title: "LocalVideo Sent Bitrate", data: "\(localVideoStats.sent_bitrate) kbps"))
        newStats.append(StatItem(title: "LocalVideo Capture FPS", data: "\(localVideoStats.capture_fps) fps"))
        newStats.append(StatItem(title: "LocalVideo Sent FPS", data: "\(localVideoStats.sent_fps) fps"))
        newStats.append(StatItem(title: "LocalVideo Encode FPS", data: "\(localVideoStats.encode_fps) fps"))
        newStats.append(StatItem(title: "LocalVideo Avg QP", data: "\(localVideoStats.avg_qp)"))
        
        updateStatsData(with: newStats)
        
    }
    
    func onRtcRemoteVideoStats(_ remoteVideoStats: AliRtcRemoteVideoStats) {
        "onRtcRemoteVideoStats".printLog()
        var newStats = statsData.filter { !$0.title.hasPrefix("RemoteVideo-\(remoteVideoStats.userId)") }
                
        newStats.append(StatItem(title: "RemoteVideo-\(remoteVideoStats.userId) Track", data: "\(remoteVideoStats.track)"))
        newStats.append(StatItem(title: "RemoteVideo-\(remoteVideoStats.userId) Resolution", data: "\(remoteVideoStats.width)x\(remoteVideoStats.height)"))
        newStats.append(StatItem(title: "RemoteVideo-\(remoteVideoStats.userId) Decode FPS", data: "\(remoteVideoStats.decode_fps) fps"))
        newStats.append(StatItem(title: "RemoteVideo-\(remoteVideoStats.userId) Render FPS", data: "\(remoteVideoStats.render_fps) fps"))
        newStats.append(StatItem(title: "RemoteVideo-\(remoteVideoStats.userId) Frozen Times", data: "\(remoteVideoStats.frozen_times) times"))
        newStats.append(StatItem(title: "RemoteVideo-\(remoteVideoStats.userId) Frozen Time", data: "\(remoteVideoStats.video_total_frozen_time) ms"))
        newStats.append(StatItem(title: "RemoteVideo-\(remoteVideoStats.userId) Frozen Rate", data: "\(remoteVideoStats.video_total_frozen_rate)%"))
        
        updateStatsData(with: newStats)
    }
    
    // MARK: Other Callback
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

