//
//  CustomAudioCaptureVC.swift
//  ARTCExample
//
//  Created by wy on 2025/8/4.
//

import Foundation
import AVFoundation
import AliVCSDK_ARTC

class CustomAudioCaptureSetParamsVC: UIViewController, UITextFieldDelegate {
    var audioSourceRawFrameConfigs: [AliRtcAudioSource: AudioRawFrameConfig] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Custom Audio Capture".localized
        self.channelIdTextField.delegate = self
        self.dumpAudioFileNameTextField.delegate = self
    }
    
    @IBOutlet weak var audioLocalPlayoutSwitch: UISwitch!
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
        
        let vc = self.presentVC(storyboardName: "CustomAudioCapture", storyboardId: "MainVC") as? CustomAudioCaptureMainVC
        vc?.channelId = channelId
        vc?.userId = userId
        vc?.joinToken = joinToken
        vc?.isEnableCustomAudioCapture = customAudioCaptureSwitch.isOn
        vc?.isEnableLocalPlayout = audioLocalPlayoutSwitch.isOn
        vc?.isMicroPhoneCapture = audioSourceSegmentedControl.selectedSegmentIndex != 0
        vc?.enableDumpAudio = enableDumpAudioSwitch.isOn
        vc?.dumpAudioFileName = dumpAudioFileNameTextField.text ?? "audio_dump_file"
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // Custom Audio Capture
    @IBOutlet weak var customAudioCaptureSwitch: UISwitch!
    @IBOutlet weak var audioSourceSegmentedControl: UISegmentedControl!
    
    // Audio Dump
    @IBOutlet weak var enableDumpAudioSwitch: UISwitch!
    @IBOutlet weak var dumpAudioFileNameTextField: UITextField!
}

class CustomAudioCaptureMainVC: UIViewController {
    // 外部音频采集相关变量
    private var externalPublishStreamId: Int32 = 0
    
    // PCM文件读取相关
    private var pcmSampleRate: Int32 = 48000
    private var pcmChannels: Int32 = 1
    private var pcmInputFile: UnsafeMutablePointer<FILE>?
    private var pcmData = [Int8](repeating: 0, count: 48 * 2 * 1000)
    private var pcmInputThread: Thread?
    
    // 麦克风采集相关
    private var audioEngine: AVAudioEngine?
    private var audioPlayerNode: AVAudioPlayerNode?
    private var mixerNode: AVAudioMixerNode?
    var isMicroPhoneCapture: Bool = false
    var isEnableLocalPlayout: Bool = false
    
    // 音频Dump
    var enableDumpAudio: Bool = false
    var dumpAudioFileName: String = "audio_dump_file"
    
    private var wavRecorder: WavRecorder?
    
    // 麦克风采集参数
    private let sampleRate: Int32 = 48000
    private let channels: Int32 = 1
    private let bytesPerSample: Int32 = 2 // 16-bit samples

    override func viewDidLoad() {
        super.viewDidLoad()

        initUI()
        
        self.setup()
        self.startPreview()
        self.joinChannel()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.leaveAnddestroyEngine()
    }
    
    // MARK: UI
    @IBOutlet weak var contentScrollView: UIScrollView!
    
    private let screenShareModePickerView = UIPickerView()
    private let stackView = UIStackView()
    
    // 保存所有视图
    var videoSeatViewMap: [String: SeatView] = [:]
    
    // MARK: Join Channel Params
    var channelId: String = ""
    var userId: String = ""
    var rtcEngine: AliRtcEngine? = nil
    var joinToken: String? = nil
    
    // custom audio capture
    var isEnableCustomAudioCapture: Bool = true
    
    
    private func initUI() {
        self.title = self.channelId
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboardAndPickers))
        self.view.addGestureRecognizer(tapGesture)
        
        // 创建垂直StackView用于显示视频
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.distribution = .fill
        stackView.alignment = .fill
        
        contentScrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.bottomAnchor, constant: -12),
            stackView.widthAnchor.constraint(equalTo: contentScrollView.frameLayoutGuide.widthAnchor, constant: -24)
        ])
    }
    
    @objc func dismissKeyboardAndPickers() {
//        self.screenShareModeTextField.resignFirstResponder()
    }
    
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
        
        if isEnableCustomAudioCapture {
            // 关闭SDK内部音频采集
            engine.setParameter("{\"audio\":{\"enable_system_audio_device_record\":\"FALSE\"}}")
        } else {
            engine.setParameter("{\"audio\":{\"enable_system_audio_device_record\":\"TRUE\"}}")
        }
        
        self.rtcEngine = engine
    }
    
    // 请求麦克风权限
    private func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if granted {
                    print("麦克风权限已授予")
                    self.startExternalAudioCapture()
                } else {
                    print("麦克风权限被拒绝")
                }
            }
        }
    }
    
    // 启动外部音频采集
    private func startExternalAudioCapture() {
        if isMicroPhoneCapture {
            startMicrophoneCapture()
        } else {
            // 例如读取PCM文件用于混音:
            if let path = Bundle.main.path(forResource: "music", ofType: "wav") {
                startPCMInput(sampleRate: 48000, channels: 1, path: path)
            }
        }
    }
    
    // 启动麦克风采集
    private func startMicrophoneCapture() {
        guard audioEngine == nil else {
            return
        }
        
        isMicroPhoneCapture = true
        
        // 初始化音频配置
        let config = AliRtcExternalAudioStreamConfig()
        config.channels = Int32(channels)
        config.sampleRate = Int32(sampleRate)
        config.publishVolume = 100
        config.playoutVolume = self.isEnableLocalPlayout ? 100 : 0;
        config.enable3A = true
        
        let ret = rtcEngine?.addExternalAudioStream(config)
        if ret ?? 0 < 0 {
            print("添加外部音频流失败")
            return
        }
        
        externalPublishStreamId = ret!
        
        // 设置AVAudioSession
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .videoChat, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            print("设置AVAudioSession失败: \(error)")
            return
        }
        
        // 如果启动音频dump，初始化并启动WavRecorder
        if enableDumpAudio {
            wavRecorder = WavRecorder(sampleRate: sampleRate, channels: channels, fileName: dumpAudioFileName)
            wavRecorder?.startRecording()
        }
        
        // 初始化音频引擎
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        
        // 获取输入节点（麦克风）
        let inputNode = audioEngine.inputNode
        
        /// 创建输出格式
        let outputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                         sampleRate: Double(sampleRate),
                                         channels: AVAudioChannelCount(channels),
                                         interleaved: true)
        
        // 在输入节点上安装tap来捕获音频数据
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: outputFormat) { [weak self] buffer, time in
            self?.processAudioBuffer(buffer)
        }
        
        // 启动音频引擎
        do {
            try audioEngine.start()
            print("音频引擎已启动")
        } catch {
            print("启动音频引擎失败: \(error)")
        }
    }
    
    // 处理音频缓冲区
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.int16ChannelData else { return }
        
        let frameLength = Int32(buffer.frameLength)
        let bytesCount = frameLength * Int32(bytesPerSample) * Int32(channels)
        
        // 写入到wav文件
        if enableDumpAudio, let recorder = wavRecorder {
            let data = Data(bytes:buffer.int16ChannelData![0], count: Int(bytesCount))
            recorder.writeAudioData(data)
        }
        
        // 创建音频帧
        let sample = AliRtcAudioFrame()
        sample.dataPtr = UnsafeMutableRawPointer(mutating: channelData.pointee)
        sample.samplesPerSec = sampleRate
        sample.bytesPerSample = bytesPerSample
        sample.numOfChannels = channels
        sample.numOfSamples = frameLength
        
        var success = false
        var retryCount = 0
        
        while retryCount < 20 {
            
            let rc = rtcEngine?.pushExternalAudioStream(externalPublishStreamId, rawData: sample) ?? 0
            
            // 0x01070101 SDK_AUDIO_INPUT_BUFFER_FULL 缓冲区满需要重传
            if rc == 0x01070101 {
                Thread.sleep(forTimeInterval: 0.03) //30 ms
                retryCount += 1
            } else {
                if rc < 0 {
                    "pushExternalAudioStream error, ret: \(rc)".printLog()
                }
                break
            }
        }
    }
    
    // 读取PCM文件并推送（混音）
    private func startPCMInput(sampleRate: Int32, channels: Int32, path: String?, isMixedMic: Bool = false) {
        guard pcmInputThread == nil else {
            return
        }
        
        pcmSampleRate = sampleRate
        pcmChannels = channels
        
        // 如果路径为空则使用麦克风采集
        if let path = path, !path.isEmpty {
            let fileExtension = (path as NSString).pathExtension.lowercased()
            if fileExtension == "wav" {
                if let wavInfo = parseWavHeader(filePath: path) {
                    pcmSampleRate = wavInfo.sampleRate
                    pcmChannels = wavInfo.channels
                    isMicroPhoneCapture = false
                    guard let file = fopen(path, "rb") else {
                        print("WAV文件为空")
                        return
                    }
                    pcmInputFile = file
                    fseek(file, wavInfo.dataOffset, SEEK_SET)
                }
            } else if fileExtension == "pcm" {
                isMicroPhoneCapture = false
                guard let file = fopen(path, "rb") else {
                    print("PCM文件为空")
                    return
                }
                pcmInputFile = file
            }
        } else {
            // 启动麦克风采集
            DispatchQueue.main.async { [weak self] in
                self?.startMicrophoneCapture()
            }
            return
        }
        
        let config = AliRtcExternalAudioStreamConfig()
        config.channels = pcmChannels
        config.sampleRate = pcmSampleRate
        config.publishVolume = 100
        config.playoutVolume = self.isEnableLocalPlayout ? 100 : 0;
        
        let ret = rtcEngine?.addExternalAudioStream(config)
        if ret ?? 0 < 0 {
            print("添加外部音频流失败")
            return
        }
        
        externalPublishStreamId = ret!
        
        // 启动读取线程
        pcmInputThread = Thread(target: self, selector: #selector(inputPCMRun), object: nil)
        pcmInputThread?.start()
    }
    
    // WAV文件信息结构体
    private struct WavFileInfo {
        let sampleRate: Int32
        let channels: Int32
        let bitsPerSample: Int32
        let dataOffset: Int
    }
    
    // 解析WAV文件头
    private func parseWavHeader(filePath: String) -> WavFileInfo? {
        guard let file = fopen(filePath, "rb") else {
            print("无法打开文件: \(filePath)")
            return nil
        }
        
        defer {
            fclose(file)
        }
        
        // 读取RIFF头
        var riffTag = [UInt8](repeating: 0, count: 4)
        fread(&riffTag, 1, 4, file)
        
        let riffString = String(bytes: riffTag, encoding: .ascii)
        guard riffString == "RIFF" else {
            print("不是有效的WAV文件(RIFF标签错误)")
            return nil
        }
        
        // 跳过文件大小字段(4字节)
        fseek(file, 4, SEEK_CUR)
        
        // 读取WAVE标签
        var waveTag = [UInt8](repeating: 0, count: 4)
        fread(&waveTag, 1, 4, file)
        
        let waveString = String(bytes: waveTag, encoding: .ascii)
        guard waveString == "WAVE" else {
            print("不是有效的WAV文件(WAVE标签错误)")
            return nil
        }
        
        // 查找fmt块
        var formatTag = [UInt8](repeating: 0, count: 4)
        var chunkSize: UInt32 = 0
        
        var formatFound = false
        var sampleRate: Int32 = 0
        var channels: Int32 = 0
        var bitsPerSample: Int32 = 0
        
        while !formatFound {
            // 读取块标签
            let readCount = fread(&formatTag, 1, 4, file)
            if readCount < 4 {
                print("文件读取错误")
                return nil
            }
            
            let tagString = String(bytes: formatTag, encoding: .ascii)
            
            // 读取块大小
            fread(&chunkSize, 4, 1, file)
            
            if tagString == "fmt " {
                formatFound = true
                
                // 读取音频格式信息
                var formatCode: UInt16 = 0
                fread(&formatCode, 2, 1, file) // 音频格式(2字节)
                
                guard formatCode == 1 else { // 1表示PCM格式
                    print("不支持的音频格式，仅支持PCM格式")
                    return nil
                }
                
                var tempChannels: UInt16 = 0
                fread(&tempChannels, 2, 1, file) // 声道数(2字节)
                channels = Int32(tempChannels)
                
                fread(&sampleRate, 4, 1, file) // 采样率(4字节)
                
                fseek(file, 4, SEEK_CUR) // 跳过字节率(4字节)
                
                fseek(file, 2, SEEK_CUR) // 跳过块对齐(2字节)
                
                var tempBitsPerSample: UInt16 = 0
                fread(&tempBitsPerSample, 2, 1, file) // 位深度(2字节)
                bitsPerSample = Int32(tempBitsPerSample)
                
                // 如果fmt块有额外数据，则跳过
                if chunkSize > 16 {
                    fseek(file, Int(chunkSize - 16), SEEK_CUR)
                }
            } else if tagString == "data" {
                // 找到data块，但我们还需要fmt块的信息
                // 先跳过这个块，继续寻找fmt块
                fseek(file, Int(chunkSize), SEEK_CUR)
            } else {
                // 跳过不关心的块
                fseek(file, Int(chunkSize), SEEK_CUR)
            }
            
            // 检查是否到达文件末尾
            if feof(file) != 0 {
                break
            }
        }
        
        // 确保找到了fmt块
        guard formatFound else {
            print("未找到fmt块")
            return nil
        }
        
        // 查找data块位置
        fseek(file, 12, SEEK_SET) // 回到WAVE标签后的位置
        var dataOffset = 12
        
        var dataFound = false
        while !dataFound {
            var tag = [UInt8](repeating: 0, count: 4)
            let readCount = fread(&tag, 1, 4, file)
            if readCount < 4 {
                break
            }
            
            let tagString = String(bytes: tag, encoding: .ascii)
            fread(&chunkSize, 4, 1, file)
            
            dataOffset += 8 // 标签(4) + 大小(4)
            
            if tagString == "data" {
                dataFound = true
                dataOffset += 4 // data块的4字节大小字段也跳过，从实际数据开始
            } else {
                // 跳过这个块
                fseek(file, Int(chunkSize), SEEK_CUR)
                dataOffset += Int(chunkSize)
            }
            
            if feof(file) != 0 {
                break
            }
        }
        
        guard dataFound else {
            print("未找到data块")
            return nil
        }
        
        print("WAV文件信息 - 采样率: \(sampleRate), 声道数: \(channels), 位深度: \(bitsPerSample)")
        
        return WavFileInfo(
            sampleRate: sampleRate,
            channels: channels,
            bitsPerSample: bitsPerSample,
            dataOffset: dataOffset
        )
    }
    
    // 读取PCM文件的线程方法（混音）
    @objc private func inputPCMRun() {
        print("开始读取PCM文件")
        Thread.sleep(forTimeInterval: 0.01)
        
        // 40ms数据
        let numOfSamples = (pcmSampleRate / 100) * 4
        let readbufSize = Int(numOfSamples) * MemoryLayout<Int16>.size * Int(pcmChannels)
        
        while true {
            if pcmInputThread?.isCancelled ?? true {
                break
            }
            
            var read: Int = 0
            if !isMicroPhoneCapture, let file = pcmInputFile {
                read = fread(&pcmData, 1, readbufSize, file)
            }
            
            if read > readbufSize {
                break
            }
            
            if read == 0, let file = pcmInputFile {
                fseek(file, 0, SEEK_SET)
                print("重置PCM文件读取位置")
                
                if pcmInputThread != nil {
                    continue
                } else {
                    break
                }
            }
            
            let sample = AliRtcAudioFrame()
            sample.dataPtr = UnsafeMutableRawPointer(mutating: pcmData)
            sample.samplesPerSec = pcmSampleRate
            sample.bytesPerSample = Int32(MemoryLayout<Int16>.size)
            sample.numOfChannels = pcmChannels
            sample.numOfSamples = numOfSamples
            
            var retryCount = 0
            
            while retryCount < 20 {
                if !(pcmInputThread?.isExecuting ?? false) {
                    break
                }
                
                let rc = rtcEngine?.pushExternalAudioStream(externalPublishStreamId, rawData: sample) ?? 0
                
                // 0x01070101 SDK_AUDIO_INPUT_BUFFER_FULL 缓冲区满了需要重传
                if rc == 0x01070101 && !(pcmInputThread?.isCancelled ?? true) {
                    Thread.sleep(forTimeInterval: 0.03) // 30ms
                    retryCount += 1;
                } else {
                    if rc < 0 {
                        "pushExternalAudioStream error, ret: \(rc)".printLog()
                    }
                    break
                }
            }
        }
        
        if let file = pcmInputFile {
            fclose(file)
            pcmInputFile = nil
        }
    }
    
    // 加入频道
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
        let seatView = self.createOrUpdateSeatView(uid: self.userId, streamType: .camera)
        
        let canvas = AliVideoCanvas()
        canvas.view = seatView.canvasView
        canvas.renderMode = .auto
        canvas.mirrorMode = .onlyFrontCameraPreviewEnabled
        canvas.rotationMode = ._0
        
        self.rtcEngine?.setLocalViewConfig(canvas, for: AliRtcVideoTrack.camera)
        self.rtcEngine?.startPreview()
    }
    
    func leaveAnddestroyEngine() {
        
        wavRecorder?.stopRecording()
        wavRecorder = nil

        // 停止外部音频采集线程
        pcmInputThread?.cancel()
        
        // 停止音频引擎
        audioEngine?.stop()
        audioEngine = nil
        
        // 移除音频抽头
        mixerNode?.removeTap(onBus: 0)
        mixerNode = nil
        
        if let file = pcmInputFile {
            fclose(file)
            pcmInputFile = nil
        }
        
        if self.rtcEngine?.isScreenSharePublished() == true {
            self.rtcEngine?.stopScreenShare()
        }
        self.rtcEngine?.stopPreview()
        self.rtcEngine?.leaveChannel()
        AliRtcEngine.destroy()
        self.rtcEngine = nil
    }
    
    private func showErrorAlertView(_ message: String, code: Int, forceShow: Bool) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: 视图管理核心逻辑
extension CustomAudioCaptureMainVC {
    // 创建或更新一个视频通话渲染视图，并加入到contentScrollView中
    func createOrUpdateSeatView(uid: String, streamType: StreamType) ->SeatView {
        let key = "\(uid)_\(streamType)"
        
        // 1. 如果已有视图，直接返回
        if let existingView = videoSeatViewMap[key] {
            return existingView
        }
        
        // 2. 创建新视图
        let seatView = SeatView(frame: .zero)
        seatView.seatInfo = SeatInfo(uid: uid, streamType: streamType)
        
        if uid != self.userId {
            // 3. 配置视频画布
            let canvas = AliVideoCanvas()
            canvas.view = seatView.canvasView
            canvas.renderMode = .fill
            canvas.mirrorMode = streamType == .screen ? .allDisabled : .allEnabled
            canvas.rotationMode = ._0
            
            rtcEngine?.setRemoteViewConfig(canvas, uid: uid, for: streamType == .camera ? .camera : .screen)
        }
        
        // 4. 添加到管理字典
        videoSeatViewMap[key] = seatView
        
        // 6. 更新布局
        updateLayoutForUser(uid: uid)
        return seatView
    }
    
    private func updateLayoutForUser(uid: String) {
        // 1. 获取该用户的所有视图
        let cameraKey = "\(uid)_camera"
        let screenKey = "\(uid)_screen"
        let views = [
            videoSeatViewMap[cameraKey],
            videoSeatViewMap[screenKey]
        ].compactMap { $0 }
        
        guard !views.isEmpty else { return }
        
        // 2. 创建用户容器（垂直布局）
        let userContainer = UIView()
        userContainer.layer.cornerRadius = 12
        userContainer.layer.borderWidth = 0.5
        
        let userStack = UIStackView(arrangedSubviews: views)
        userStack.axis = .horizontal
        userStack.spacing = 4
        userStack.distribution = .fillEqually
        
        userContainer.addSubview(userStack)
        userStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            userStack.topAnchor.constraint(equalTo: userContainer.topAnchor, constant: 4),
            userStack.leadingAnchor.constraint(equalTo: userContainer.leadingAnchor, constant: 4),
            userStack.trailingAnchor.constraint(equalTo: userContainer.trailingAnchor, constant: -4),
            userStack.bottomAnchor.constraint(equalTo: userContainer.bottomAnchor, constant: -4),
            userStack.heightAnchor.constraint(greaterThanOrEqualToConstant: 200)
        ])
        
        // 3. 替换原有视图
        if let existingContainer = findUserContainer(for: uid) {
            let oldIndex = stackView.arrangedSubviews.firstIndex(of: existingContainer) ?? 0
            // 完全移除旧容器
            stackView.removeArrangedSubview(existingContainer)
            existingContainer.removeFromSuperview()
            
            // 插入新容器
            stackView.insertArrangedSubview(userContainer, at: oldIndex)
        } else {
            stackView.addArrangedSubview(userContainer)
        }
        userContainer.accessibilityIdentifier = uid
    }
    
    // 查找用户的容器视图
    private func findUserContainer(for uid: String) -> UIView? {
        return stackView.arrangedSubviews.first { container in
            container.accessibilityIdentifier == uid
        }
    }

    func removeSeatView(uid: String, streamType: StreamType) {
        let key = "\(uid)_\(streamType)"
        
        guard let seatView = videoSeatViewMap.removeValue(forKey: key) else { return }
        
        // 1. 从UI中移除
        seatView.removeFromSuperview()
        
        // 2. 清理视频资源
        rtcEngine?.setRemoteViewConfig(nil, uid: uid, for: streamType == .camera ? .camera : .screen)
        
        // 3. 检查是否还有该用户的其他视图
        let hasOtherViews = videoSeatViewMap.keys.contains { $0.hasPrefix("\(uid)_") }
        
        if !hasOtherViews {
            // 移除用户容器
            if let container = findUserContainer(for: uid) {
                container.removeFromSuperview()
            }
        } else {
            // 重新布局剩余视图
            updateLayoutForUser(uid: uid)
        }
    }
}

extension CustomAudioCaptureMainVC: AliRtcEngineDelegate {
    
    func onAudioPublishStateChanged(_ track: AliRtcAudioTrack, oldState: AliRtcPublishState, newState: AliRtcPublishState, elapseSinceLastState: Int, channel: String) {
        if newState == .statsPublished && isEnableCustomAudioCapture {
            requestMicrophonePermission();
        }
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
    
    func onScreenSharePublishStateChanged(_ oldState: AliRtcPublishState, newState: AliRtcPublishState, elapseSinceLastState: Int, channel: String) {
        // 共享屏幕推流状态变化
        "onScreenSharePublishStateChanged, oldState: \(oldState) -> newState: \(newState), Since: \(elapseSinceLastState)".printLog()
    }
    
    func onScreenShareSubscribeStateChanged(_ uid: String, oldState: AliRtcSubscribeState, newState: AliRtcSubscribeState, elapseSinceLastState: Int, channel: String) {
        "onScreenShareSubscribeStateChanged, uid: \(uid), oldState: \(oldState) -> new State: \(newState) , Since: \(elapseSinceLastState)".printLog()
    }
    
    
    func onRemoteTrackAvailableNotify(_ uid: String, audioTrack: AliRtcAudioTrack, videoTrack: AliRtcVideoTrack) {
        "onRemoteTrackAvailableNotify uid: \(uid) audioTrack: \(audioTrack)  videoTrack: \(videoTrack)".printLog()
        // 远端用户的流状态
        DispatchQueue.main.async {
            switch videoTrack {
            case .no:
                // 移除所有该用户的视图
                self.removeSeatView(uid: uid, streamType: .camera)
                self.removeSeatView(uid: uid, streamType: .screen)
            case .camera:
                self.createOrUpdateSeatView(uid: uid, streamType: .camera)
                self.removeSeatView(uid: uid, streamType: .screen)
            case .screen:
                self.createOrUpdateSeatView(uid: uid, streamType: .screen)
                self.removeSeatView(uid: uid, streamType: .camera)
            case .both:
                self.createOrUpdateSeatView(uid: uid, streamType: .camera)
                self.createOrUpdateSeatView(uid: uid, streamType: .screen)
            @unknown default:
                break
            }
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
