import { CustomTitle } from "../../common/components/CustomTitle"
import { RemoteVideoStream } from "../../common/Constants"
import {
  AliRtcEngine,
  AliRtcVideoCanvas,
  AliRtcXComponentController,
  AliRtcEngineEventListener,
  AliRtcAudioProfile,
  AliRtcAudioScenario,
  AliRtcChannelProfile,
  AliRtcClientRole,
  AliRtcVideoEncoderConfiguration,
  AliRtcVideoEncoderOrientationMode,
  AliRtcVideoTrack,
  AliRtcConnectionStatus,
  AliRtcConnectionStatusChangeReason,
  AliRtcStats,
  AliRtcLocalDeviceType,
  AliRtcLocalDeviceExceptionType,
  AliRtcAudioTrack,
  AliRtcExternalAudioStreamConfig,
  AliRtcRenderMode,
  AliRtcRenderMirrorMode,
  AliRtcPublishState,
  AliRtcAudioFrame
} from '@aliyun_video_cloud/alivcsdk_artc';
import { common } from '@kit.AbilityKit';
import { ARTCTokenHelper } from '../../common/keycenter/ARTCTokenHelper';
import { GlobalConfig } from '../../common/keycenter/GlobalConfig';
import { promptAction } from '@kit.ArkUI';


@Entry
@Component
export struct CustomAudioCapturePage {
  @State channelId: string = Date.now().toString().slice(-6);
  private xcomponentController: XComponentController = new XComponentController();
  @State hasJoined: boolean = false;
  @State ShowPreview: boolean = false;
  @State IsAudioFrame: boolean = false; // 本地播放开关
  @State IsDumpAudioFrame: boolean = false; // 音频Dump开关
  @State textDump: string = '';
  // 新增状态变量
  @State isMicrophoneCapture: boolean = true; // 音频源选择：true=麦克风，false=本地媒体
  @State selectedAudioSource: string = 'Microphone'; // 当前选中的音频源
  // RTC引擎相关
  @State remoteVideoStreams: RemoteVideoStream[] = []
  private rtcEngine: AliRtcEngine | undefined;
  private context: common.UIAbilityContext | undefined;
  private aliRtcVideoCanvas: AliRtcVideoCanvas | undefined;
  private componentController: AliRtcXComponentController = new AliRtcXComponentController();
  @State localUserId: string = '';
  private rtcEngineEventListener: AliRtcEngineEventListener | undefined;
  // 音频采集相关
  private externalAudioStreamId: number = 0; // 外部音频流ID
  private isAudioPublishing: boolean = false; // 音频是否正在推流
  // 音频参数配置
  private readonly audioMicrophoneSampleRate: number = 48000;
  private readonly audioMicrophoneChannel: number = 1;
  private readonly audioMicrophoneBitsPerSample: number = 16;
  private readonly audioFileSampleRate: number = 16000;
  private readonly audioFileChannel: number = 1;
  private readonly audioFileBitsPerSample: number = 16;
  private readonly bufferDuration: number = 10; // 10ms

  aboutToAppear() {
    this.context = getContext(this) as common.UIAbilityContext;
    this.textDump = 'audio_dump_file'; // 设置默认dump文件名
  }

  build() {
    NavDestination() {
      Column() {
        CustomTitle({
          titleText: '自定义音频采集',
        })

        Column() {
          Text('如果要和其他用户进行通话，需要加入到同一个频道里，既保证双方的ChannelID相同。')
            .fontSize(14)
            .fontColor('#666')
            .width('100%')

          Row() {
            Text('ChannelID:')
              .fontSize(16)
              .fontColor('#333')
              .width(80)

            TextInput({
              text: this.channelId
            })
              .padding({ left: 5 })
              .layoutWeight(0.6)
              .backgroundColor('#fff')
              .fontColor('#333')
              .height(40)
              .border({
                width: 1,
                color: '#ddd',
                radius: 4
              })
              .margin({ left: 10 })
              .onChange((text: string) => {
                this.channelId = text;
              })
          }
          .margin({ top: 10 })
          .height(50)

          Column() {
            Row() {
              Text('音频源')
                .fontSize(16)
                .fontColor('#333')
                .margin({
                  left: 10
                })

              Blank()
              Column() {
                Row() {
                  Radio({ value: 'LocalMedia', group: 'audioSourceGroup' })
                    .checked(!this.isMicrophoneCapture)
                    .onChange((checked: boolean) => {
                      if (checked) {
                        this.isMicrophoneCapture = false;
                        this.selectedAudioSource = 'LocalMedia';
                      }
                    })
                  Text('本地媒体')
                }

                Row() {
                  Radio({ value: 'Microphone', group: 'audioSourceGroup' })
                    .checked(this.isMicrophoneCapture)
                    .onChange((checked: boolean) => {
                      if (checked) {
                        this.isMicrophoneCapture = true;
                        this.selectedAudioSource = 'Microphone';
                      }
                    })
                  Text('麦克风')
                }
              }
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)

            this.buildSwitchItem('本地播放:', this.IsAudioFrame, (value: boolean) => {
              this.IsAudioFrame = value;
            })

            this.buildSwitchItem('音频Dump:', this.IsDumpAudioFrame, (value: boolean) => {
              this.IsDumpAudioFrame = value;
            })

            Row() {
              Text('Dump音频文件名前缀')
                .fontSize(16)
                .fontColor('#636363')
                .layoutWeight(1)

              TextInput({
                text: this.textDump,
                placeholder: "audio_dump_file"
              })
                .backgroundColor('#fff')
                .fontColor('#333')
                .borderRadius(4)
                .layoutWeight(1)
                .border({
                  // 只设置底部边框
                  width: {
                    top: 0,
                    right: 0,
                    bottom: 1,
                    left: 0
                  },
                  radius: 0
                })
                .margin({ left: 10 })
                .onChange((text: string) => {
                  this.textDump = text;
                })
            }
            .width('100%')
            .height(36)
            .borderRadius(4)
            .margin({ top: 8 })
          }

          Text(this.hasJoined ? '挂断' : '加入频道')
            .textAlign(TextAlign.Center)
            .fontSize(16)
            .backgroundColor('#3295fb')
            .width('95%')
            .height(48)
            .margin({
              top: 24, left: 10,
              right: 10
            })
            .onClick(async () => {
              if (this.hasJoined) {
                this.destroyRtcEngine();
              } else {
                if (!this.rtcEngine) {
                  await this.initAndSetupRtcEngine();
                }
                await this.startRTCCall();
              }
            })

          // 视频预览区域
          if (this.ShowPreview) {
            Column() {
              this.buildLocalVideoView()
            }
            .width('100%')
            .height('400vp')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          }

        }
        .margin(12)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#f5f5f5')
    }
    .hideTitleBar(true)
  }

  // 判断是否显示多人网格布局
  private shouldShowGridLayout(): boolean {
    return this.ShowPreview && this.remoteVideoStreams.length > 0;
  }

  @Builder
  buildLocalVideoView() {
    Column() {
      if (!this.shouldShowGridLayout()) {
        // 单视频布局
        Row() {
          XComponent({
            id: 'local_video_surface',
            type: 'surface',
            controller: this.xcomponentController
          })
            .layoutWeight(1)
            .height('100%')
            .onLoad(() => {
              this.setupLocalVideo();
            })
          Blank().layoutWeight(1)
        }
        .height('200vp')
        .width('100%')

      } else {
        // 多个视频布局
        Row() {
          Column() {
            XComponent({
              id: 'local_video_surface',
              type: 'surface',
              controller: this.xcomponentController
            })
              .width('100%')
              .height('100%')
              .onLoad(() => {
                this.setupLocalVideo();
              })
          }
          .backgroundColor('#000')
          .width('150')
          .layoutWeight(1)
          .height('200vp')

          Blank()
            .width(10)

          // 显示第一个远端视频
          Column() {
            XComponent({
              id: `remote_${this.remoteVideoStreams[0].uid}_${this.remoteVideoStreams[0].videoTrack}`,
              type: 'surface',
              controller: this.remoteVideoStreams[0].xcomponentController
            })
              .width('100%')
              .height('100%')
              .onLoad(() => {
                this.setupRemoteVideo(this.remoteVideoStreams[0]);
              })
          }
          .backgroundColor('#000')
          .layoutWeight(1)
          .height('200vp')
        }
      }
    }
    .width('100%')
    .height('400vp')
    .margin({
      top: 20
    })
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
  }

  // 设置远端视频
  private setupRemoteVideo(stream: RemoteVideoStream): void {
    if (!this.rtcEngine) {
      console.error('RTC引擎未初始化');
      return;
    }

    try {
      // 获取XComponent的surfaceId
      stream.surfaceId = stream.xcomponentController.getXComponentSurfaceId();
      console.info(`设置远端视频: ${stream.uid} - ${stream.videoTrack}, surfaceId: ${stream.surfaceId}`);

      // 配置视频画布
      if (!stream.canvas) {
        stream.canvas = new AliRtcVideoCanvas();
      }

      stream.canvas.surfaceId = stream.surfaceId;
      stream.canvas.renderMode = AliRtcRenderMode.AliRtcRenderModeAuto;
      stream.canvas.mirrorMode = AliRtcRenderMirrorMode.AliRtcRenderMirrorModeAllNoMirror;

      // 设置远端视图配置
      this.rtcEngine.setRemoteViewConfig(stream.canvas, this.componentController, stream.uid,
        stream.videoTrack);

      console.info(`远端视频设置完成: ${stream.uid} - ${stream.videoTrack}`);

    } catch (error) {
      console.error(`设置远端视频失败 ${stream.uid}:`, error);
    }
  }

  // 查看远端视频
  private viewRemoteVideo(uid: string, videoTrack: AliRtcVideoTrack): void {
    console.info(`查看远端视频: ${uid} - ${videoTrack}`);

    // 检查是否已存在相同的流
    const existingIndex = this.remoteVideoStreams.findIndex(
      s => s.uid === uid && s.videoTrack === videoTrack
    );

    if (existingIndex >= 0) {
      console.info(`远端视频已存在: ${uid} - ${videoTrack}`);
      return;
    }

    // 创建新的远端视频流
    const newStream: RemoteVideoStream = {
      uid,
      videoTrack,
      canvas: new AliRtcVideoCanvas(),
      xcomponentController: new XComponentController(),
      surfaceId: '' // 初始为空，在onLoad中设置
    };

    // 添加到数组
    this.remoteVideoStreams.push(newStream);

    console.info(`添加远端视频成功: ${uid} - ${videoTrack}`);
  }

  // 移除远端视频
  private removeRemoteVideo(uid: string, videoTrack: AliRtcVideoTrack): void {
    console.info(`移除远端视频: ${uid} - ${videoTrack}`);

    const index = this.remoteVideoStreams.findIndex(
      s => s.uid === uid && s.videoTrack === videoTrack
    );

    if (index >= 0) {
      this.remoteVideoStreams.splice(index, 1);
      console.info(`移除远端视频成功: ${uid} - ${videoTrack}`);
    }
  }

  // 移除用户的所有视频
  private removeAllRemoteVideo(uid: string): void {
    console.info(`移除用户所有视频: ${uid}`);

    // 从数组中移除该用户的所有流
    this.remoteVideoStreams = this.remoteVideoStreams.filter(s => s.uid !== uid);

    console.info(`移除用户所有视频成功: ${uid}`);
  }

  @Builder
  private buildSwitchItem(label: string, value: boolean, onValueChange: (value: boolean) => void) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor('#636363')
        .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: value })
        .onChange((isOn: boolean) => {
          onValueChange(isOn);
        })
    }
    .width('100%')
    .height(36)
    .borderRadius(4)
    .margin({ top: 8 })
  }

  // ==================== RTC引擎初始化 ====================
  private async initAndSetupRtcEngine(): Promise<void> {
    if (!this.context) {
      promptAction.showToast({ message: '上下文未初始化', duration: 2000 });
      return;
    }

    try {
      // 创建RTC引擎实例 - 设置使用外部音频采集
      const extras = '{"user_specified_use_external_audio_record":"TRUE"}';
      this.rtcEngine = AliRtcEngine.getInstance(extras, this.context);
      if (this.rtcEngine !== undefined) {

        // 设置事件监听器
        this.setupEventListeners();

        // 设置频道模式为互动直播模式
        this.rtcEngine.setChannelProfile(AliRtcChannelProfile.AliRtcInteractiveLive);

        // 设置用户角色
        this.rtcEngine.setClientRole(AliRtcClientRole.AliRtcClientRoleInteractive);

        // 设置音频配置
        this.rtcEngine.setAudioProfile(
          AliRtcAudioProfile.AliRtcHighQualityMode,
          AliRtcAudioScenario.AliRtcSceneMusicMode
        );

        // 设置视频编码参数
        const videoConfig: AliRtcVideoEncoderConfiguration = new AliRtcVideoEncoderConfiguration();
        videoConfig.dimensions.width = 720;
        videoConfig.dimensions.height = 1280;
        videoConfig.frameRate = 20;
        videoConfig.bitrate = 1200;
        videoConfig.keyFrameInterval = 2000;
        videoConfig.orientationMode = AliRtcVideoEncoderOrientationMode.AliRtcVideoEncoderOrientationModeAdaptive;

        this.rtcEngine.setVideoEncoderConfiguration(videoConfig);

        // 发布本地音视频流
        this.rtcEngine.publishLocalAudioStream(true);
        this.rtcEngine.publishLocalVideoStream(true);

        // 设置默认订阅远端音视频流
        this.rtcEngine.setDefaultSubscribeAllRemoteAudioStreams(true);
        this.rtcEngine.subscribeAllRemoteAudioStreams(true);
        this.rtcEngine.setDefaultSubscribeAllRemoteVideoStreams(true);
        this.rtcEngine.subscribeAllRemoteVideoStreams(true);

        console.info('RTC引擎初始化完成，使用外部音频采集');
        if (this.aliRtcVideoCanvas) {
          this.applyLocalVideoCanvas();
        }
        }

    } catch (error) {
      console.error('初始化RTC引擎失败:', error);
      promptAction.showToast({ message: '初始化引擎失败', duration: 2000 });
    }
  }

  // ==================== 事件监听器设置 ====================
  private setupEventListeners(): void {
    if (!this.rtcEngine) {
      return;
    }

    this.rtcEngineEventListener = new AliRtcEngineEventListener();

    // 加入频道结果回调
    this.rtcEngineEventListener.onJoinChannel((resultCode: number, channel: string, elapsed: string) => {
      console.info(`加入频道结果: result=${resultCode}, channel=${channel}, elapsed=${elapsed}`);
      this.handleJoinResult(resultCode, channel);
    });

    // 离开频道结果回调
    this.rtcEngineEventListener.onLeaveChannel((result: number, stats: AliRtcStats) => {
      console.info(`离开频道结果: result=${result}`);
      this.stopAudioCapture();
      this.rtcEngine?.refreshAuthInfoWithToken(null);
    });

    // 音频推流状态变化回调 - 重要：推流成功后开始外部音频采集
    this.rtcEngineEventListener.onAudioPublishStateChanged((audioTrack: AliRtcAudioTrack, oldState: AliRtcPublishState,
      newState: AliRtcPublishState, elapseSinceLastState: number, channel: string) => {
      console.info(`音频推流状态变化: oldState=${oldState}, newState=${newState}, channel=${channel}`);

      if (newState === AliRtcPublishState.AliRtcPublishStatePublished) {
        this.isAudioPublishing = true;
        // 推流成功后开始外部音频采集
        this.startAudioCapture();
      } else if (newState === AliRtcPublishState.AliRtcPublishStatePublishing) {
        this.isAudioPublishing = false;
        this.stopAudioCapture();
      }
    });


    // 远端音视频流可用（核心逻辑）
    this.rtcEngineEventListener.onRemoteTrackAvailableNotify((userId: string, audioTrack: AliRtcAudioTrack,
      videoTrack: AliRtcVideoTrack) => {
      console.info(`远端音视频流可用: userId=${userId}, audioTrack=${audioTrack}, videoTrack=${videoTrack}`);

      // 处理视频流
      if (videoTrack === AliRtcVideoTrack.AliRtcVideoTrackCamera) {
        // 摄像头流可用
        this.viewRemoteVideo(userId, AliRtcVideoTrack.AliRtcVideoTrackCamera);
        this.removeRemoteVideo(userId, AliRtcVideoTrack.AliRtcVideoTrackScreen);
      } else if (videoTrack === AliRtcVideoTrack.AliRtcVideoTrackScreen) {
        // 屏幕共享流可用
        this.viewRemoteVideo(userId, AliRtcVideoTrack.AliRtcVideoTrackScreen);
        this.removeRemoteVideo(userId, AliRtcVideoTrack.AliRtcVideoTrackCamera);
      } else if (videoTrack === AliRtcVideoTrack.AliRtcVideoTrackBoth) {
        // 双流可用（摄像头+屏幕共享）
        this.viewRemoteVideo(userId, AliRtcVideoTrack.AliRtcVideoTrackCamera);
        this.viewRemoteVideo(userId, AliRtcVideoTrack.AliRtcVideoTrackScreen);
      } else if (videoTrack === AliRtcVideoTrack.AliRtcVideoTrackNo) {
        // 无视频流
        this.removeAllRemoteVideo(userId);
      }
    })


    // 连接状态变化回调
    this.rtcEngineEventListener.onConnectionStatusChange(
      (status: AliRtcConnectionStatus, reason: AliRtcConnectionStatusChangeReason) => {
        console.info(`连接状态改变: status=${status}, reason=${reason}`);
        if (status === AliRtcConnectionStatus.AliRtcConnectionFailed) {
          promptAction.showToast({ message: '连接失败', duration: 2000 });
        }
      }
    );

    // 本地设备异常回调
    this.rtcEngineEventListener.onLocalDeviceException(
      (deviceType: AliRtcLocalDeviceType, exceptionType: AliRtcLocalDeviceExceptionType, msg: string) => {
        console.error(`本地设备异常: deviceType=${deviceType}, exceptionType=${exceptionType}, msg=${msg}`);
        promptAction.showToast({ message: `设备异常: ${msg}`, duration: 2000 });
      }
    );

    this.rtcEngine.setRtcEngineEventListener(this.rtcEngineEventListener);
  }

  // ==================== 本地视频设置 ====================
  private setupLocalVideo(): void {
    if (!this.rtcEngine) {
      console.warn('RTC引擎未初始化，延迟设置视频画布');
      return;
    }

    try {
      let surfaceId = this.xcomponentController.getXComponentSurfaceId();
      if (!surfaceId) {
        console.error('获取surfaceId失败，XComponent可能未就绪');
        return;
      }
      console.info('获取到本地视频surfaceId:', surfaceId);

      this.aliRtcVideoCanvas = new AliRtcVideoCanvas();
      this.aliRtcVideoCanvas.surfaceId = surfaceId;
      this.aliRtcVideoCanvas.renderMode = AliRtcRenderMode.AliRtcRenderModeAuto;
      this.aliRtcVideoCanvas.mirrorMode = AliRtcRenderMirrorMode.AliRtcRenderMirrorModeAllMirror;

      console.info('本地视频画布设置完成');

      this.startPreview()

    } catch (error) {
      console.error('设置本地视频失败:', error);
    }
  }

  private applyLocalVideoCanvas(): void {
    if (!this.rtcEngine) {
      return;
    }
    try {
      this.rtcEngine.setLocalViewConfig(
        this.aliRtcVideoCanvas,
        this.componentController,
        AliRtcVideoTrack.AliRtcVideoTrackCamera
      );
      console.info('本地视频画布已应用到RTC引擎');
    } catch (error) {
      console.error('应用本地视频画布失败:', error);
    }
  }

  // ==================== 音频采集相关方法 ====================
  private startAudioCapture(): void {
    if (!this.rtcEngine || !this.isAudioPublishing) {
      console.warn('音频采集未启动：RTC引擎未初始化或音频未推流');
      return;
    }

    try {
      // 配置外部音频流参数
      const config: AliRtcExternalAudioStreamConfig = new AliRtcExternalAudioStreamConfig();

      if (this.isMicrophoneCapture) {
        // 麦克风采集参数
        config.sampleRate = this.audioMicrophoneSampleRate;
        config.channels = this.audioMicrophoneChannel;
      } else {
        // 本地媒体文件参数
        config.sampleRate = this.audioFileSampleRate;
        config.channels = this.audioFileChannel;
      }

      config.publishVolume = 100; // 推流音量
      config.playoutVolume = this.IsAudioFrame ? 100 : 0; // 本地播放音量
      config.enable3A = true; // 启用3A处理

      // 添加外部音频流
      const result = this.rtcEngine.addExternalAudioStream(config);

      if (result <= 0) {
        console.error(`添加外部音频流失败，错误码: ${result}`);
        promptAction.showToast({ message: '启动音频采集失败', duration: 2000 });
        return;
      }

      this.externalAudioStreamId = result;
      console.info(`外部音频流添加成功，streamId: ${this.externalAudioStreamId}`);

      // 根据选择的音频源启动相应的采集
      if (this.isMicrophoneCapture) {
        this.startMicrophoneCapture();
      } else {
        this.startFileAudioCapture();
      }

      promptAction.showToast({ message: '音频采集已启动', duration: 1000 });

    } catch (error) {
      console.error('启动音频采集失败:', error);
      promptAction.showToast({ message: '启动音频采集失败', duration: 2000 });
    }
  }

  private startMicrophoneCapture(): void {
    console.info('启动麦克风音频采集');
    this.simulateAudioCapture('microphone');
  }

  private startFileAudioCapture(): void {
    console.info('启动本地媒体文件音频采集');

    this.simulateAudioCapture('file');
  }

  private stopAudioCapture(): void {
    console.info('停止音频采集');

    // 停止模拟的音频采集
    this.stopSimulatedCapture();

    // 移除外部音频流
    if (this.rtcEngine && this.externalAudioStreamId > 0) {
      try {
        this.rtcEngine.removeExternalAudioStream(this.externalAudioStreamId);
        this.externalAudioStreamId = 0;
        console.info('外部音频流已移除');
      } catch (error) {
        console.error('移除外部音频流失败:', error);
      }
    }
  }

  // ==================== 模拟音频数据采集和推送 ====================
  private simulateCaptureInterval: number = 0;
  private isSimulatingCapture: boolean = false;

  private simulateAudioCapture(sourceType: string): void {
    if (this.isSimulatingCapture) {
      return;
    }

    this.isSimulatingCapture = true;
    // 模拟音频数据采集和推送
    this.simulateCaptureInterval = setInterval(() => {
      if (!this.rtcEngine || this.externalAudioStreamId <= 0) {
        this.stopSimulatedCapture();
        return;
      }

      // 生成模拟的音频数据
      const sampleRate = this.isMicrophoneCapture ? this.audioMicrophoneSampleRate : this.audioFileSampleRate;
      const channels = this.isMicrophoneCapture ? this.audioMicrophoneChannel : this.audioFileChannel;
      const bitsPerSample = this.isMicrophoneCapture ? this.audioMicrophoneBitsPerSample : this.audioFileBitsPerSample;

      // 计算每个buffer的样本数 (10ms的数据)
      const samplesPerBuffer = Math.floor(sampleRate * this.bufferDuration / 1000);
      const bytesPerSample = bitsPerSample / 8;
      const bufferSize = samplesPerBuffer * channels * bytesPerSample;

      // 创建模拟音频数据 (静音或简单波形)
      const audioData = new Uint8Array(bufferSize);
      for (let i = 0; i < audioData.length; i++) {
        // 简单的正弦波模拟，实际应根据具体需求实现
        audioData[i] = Math.floor(Math.sin(i * 0.1) * 127 + 128);
      }

      const newBuffer = new ArrayBuffer(audioData.buffer.byteLength);
      const view = new Uint8Array(newBuffer);
      view.set(audioData);
      this.pushAudioData(newBuffer, sampleRate, channels, bitsPerSample);

    }, this.bufferDuration) as number;
  }

  private stopSimulatedCapture(): void {
    if (this.simulateCaptureInterval) {
      clearInterval(this.simulateCaptureInterval);
      this.simulateCaptureInterval = 0;
    }
    this.isSimulatingCapture = false;
  }

  private pushAudioData(audioBuffer: ArrayBuffer, sampleRate: number, channels: number, bitsPerSample: number): void {
    if (!this.rtcEngine || this.externalAudioStreamId <= 0) {
      return;
    }

    try {
      // 创建音频帧对象
      const audioFrame: AliRtcAudioFrame = new AliRtcAudioFrame();
      audioFrame.buffer = audioBuffer;
      audioFrame.bytesPerSample = bitsPerSample / 8;
      audioFrame.numOfChannels = channels;
      audioFrame.samplesPerSec = sampleRate;

      // 推送音频数据
      const result = this.rtcEngine.pushExternalAudioStreamRawData(this.externalAudioStreamId, audioFrame);

      if (result !== 0) {
        console.warn(`推送音频数据失败，错误码: ${result}`);

        if (result === -1001) {
          console.warn('音频输入缓冲区已满');
        }
      }

    } catch (error) {
      console.error('推送音频数据异常:', error);
    }
  }

  // ==================== 频道操作 ====================
  private async startRTCCall(): Promise<void> {
    if (this.hasJoined) {
      return;
    }

    await this.startPreview();
    await this.joinChannel();
  }

  private async startPreview(): Promise<void> {
    if (!this.rtcEngine) {
      return;
    }

    try {
      if (this.aliRtcVideoCanvas) {
        this.applyLocalVideoCanvas();
      } else {
        this.setupLocalVideo();
      }
      this.rtcEngine.startPreview();
      this.ShowPreview = true;
      console.info('本地预览已启动');
    } catch (error) {
      console.error('启动预览失败:', error);
    }
  }

  private async joinChannel(): Promise<void> {
    if (!this.rtcEngine || !this.channelId.trim()) {
      promptAction.showToast({ message: '频道ID不能为空', duration: 2000 });
      return;
    }

    try {
      // 从 KeyCenter 获取所有入会参数
      const global: GlobalConfig = GlobalConfig.getInstance();
      const userId = await global.getUserId();
      const appId = ARTCTokenHelper.AppId;
      const appKey = ARTCTokenHelper.AppKey;
      const timestamp = ARTCTokenHelper.getTimestamp();
      const nonce = '';

      // 使用 KeyCenter 生成单参数 Token
      const base64Token = await ARTCTokenHelper.generateSingleParameterToken(
        appId,
        appKey,
        this.channelId,
        userId,
        timestamp,
        nonce
      );

      const result = this.rtcEngine.joinChannelWithToken(base64Token, '', '', '自定义音频采集用户');

      console.info('加入频道调用结果:', result);
      this.hasJoined = true;
      this.localUserId = userId;
    } catch (error) {
      console.error('加入频道失败:', error);
      promptAction.showToast({ message: `加入频道失败: ${error}`, duration: 3000 });
    }
  }

  // ==================== 结果处理 ====================
  private handleJoinResult(resultCode: number, channel: string): void {
    const resultText = resultCode === 0
      ? `Join ${channel} Success`
      : `Join ${channel} Failed!，error: ${resultCode}`;

    promptAction.showToast({ message: resultText, duration: 2000 });
  }

  // ==================== 清理资源 ====================
  private destroyRtcEngine(): void {
    // 停止音频采集
    this.stopAudioCapture();

    if (this.rtcEngine) {
      try {
        if (this.hasJoined) {
          this.rtcEngine.leaveChannel();
          this.hasJoined = false;
        }

        this.rtcEngine.stopPreview();
        this.rtcEngine = undefined;
        this.rtcEngineEventListener = undefined;

        promptAction.showToast({ message: 'Leave Channel', duration: 2000 });
      } catch (error) {
        console.error('销毁引擎失败:', error);
      }
    }

    // 重置状态
    this.ShowPreview = false;
    this.isAudioPublishing = false;
    this.externalAudioStreamId = 0;
    this.localUserId = '';
    this.remoteVideoStreams = [];

  }

  aboutToDisappear(): void {
    this.destroyRtcEngine();
  }
}