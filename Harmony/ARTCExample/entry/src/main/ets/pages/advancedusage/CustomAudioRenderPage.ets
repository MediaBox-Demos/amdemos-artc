import { CustomTitle } from "../../common/components/CustomTitle"
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
  AliRtcVideoDimensions,
  AliRtcVideoEncoderOrientationMode,
  AliRtcVideoTrack,
  AliRtcConnectionStatus,
  AliRtcConnectionStatusChangeReason,
  AliRtcStats,
  AliRtcLocalDeviceType,
  AliRtcLocalDeviceExceptionType,
  AliRtcAudioTrack,
  AliRtcRenderMode,
  AliRtcRenderMirrorMode,
  AliRtcAudioSampleRate,
  AliRtcAudioNumChannel,
  AliRtcAudioSource,
  AliRtcAudioFrameObserverConfig,
  AliRtcAudioFrame,
  AliRtcEngineAudioFrameListener
} from '@aliyun_video_cloud/alivcsdk_artc';
import { common } from '@kit.AbilityKit';
import { RemoteVideoStream } from "../../common/Constants"
import { ARTCTokenHelper } from '../../common/keycenter/ARTCTokenHelper';
import { GlobalConfig } from '../../common/keycenter/GlobalConfig';
import audio from '@ohos.multimedia.audio';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
export struct CustomAudioRenderPage {
  @State channelId: string = Date.now().toString().slice(-6);
  @State ShowPreview: boolean = false;
  @State IsAudioCustom: boolean = false;
  @State hasJoined: boolean = false;
  @State localUserId: string = '';
  private xcomponentController: XComponentController = new XComponentController();
  // RTC引擎相关
  @State remoteVideoStreams: RemoteVideoStream[] = []
  private rtcEngine: AliRtcEngine | undefined;
  private context: common.UIAbilityContext | undefined;
  private aliRtcVideoCanvas: AliRtcVideoCanvas | undefined;
  private componentController: AliRtcXComponentController = new AliRtcXComponentController();
  private rtcEngineEventListener: AliRtcEngineEventListener | undefined;
  private audioFrameObserver: AliRtcEngineAudioFrameListener | undefined;
  // 音频播放相关
  private audioRenderer: audio.AudioRenderer | undefined;
  private audioPlayInterval: number = 0;
  private audioQueue: Array<AudioFrameData> = [];
  private readonly MAX_QUEUE_SIZE: number = 10;
  private currentSampleRate: number = 48000;
  private currentChannels: number = 1;
  private isAudioPlaying: boolean = false;

  aboutToAppear() {
    this.context = getContext(this) as common.UIAbilityContext;
  }

  build() {
    NavDestination() {
      Column() {
        CustomTitle({
          titleText: '自定义音频播放',
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
                await this.destroyRtcEngine();
              } else {
                if (!this.rtcEngine) {
                  await this.initAndSetupRtcEngine();
                }
                await this.startRTCCall();
              }
            })

          this.buildSwitchItem('Custom Audio Playback:', this.IsAudioCustom, (value: boolean) => {
            this.handleAudioCustomSwitch(value);
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
      // 创建RTC引擎实例 - 设置使用外部音频播放
      const extras = '{"user_specified_use_external_audio_player":"TRUE"}';
      this.rtcEngine = AliRtcEngine.getInstance(extras, this.context);
      if (this.rtcEngine === undefined) {
        promptAction.showToast({ message: 'RTC引擎未初始化成功', duration: 2000 });
        return;
      }
      // 设置事件监听器
      this.setupEventListeners();

      // 初始化音频帧观察者
      this.createAudioFrameObserver()

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

      console.info('RTC引擎初始化完成，使用外部音频播放');

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
      // 停止音频播放
      this.stopAudioPlayer();
    });

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

    this.rtcEngine.setRtcEngineEventListener(this.rtcEngineEventListener);
  }

  // ==================== 本地视频设置 ====================
  private setupLocalVideo(): void {
    console.info('setupLocalVideo 被调用');

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

      this.applyLocalVideoCanvas();

    } catch (error) {
      console.error('设置本地视频失败:', error);
    }
  }

  private applyLocalVideoCanvas(): void {
    if (!this.rtcEngine || !this.aliRtcVideoCanvas) {
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

  // ==================== 音频自定义播放开关处理 ====================
  private async handleAudioCustomSwitch(isChecked: boolean): Promise<void> {
    if (!this.rtcEngine) {
      promptAction.showToast({ message: 'RTC引擎未初始化', duration: 2000 });
      this.IsAudioCustom = false;
      return;
    }

    const config: AliRtcAudioFrameObserverConfig = new AliRtcAudioFrameObserverConfig();
    config.sampleRate = AliRtcAudioSampleRate.AliRtcAudioSampleRate_48000;
    config.channels = AliRtcAudioNumChannel.AliRtcMonoAudio;

    if (isChecked) {
      // 打开外部播放，关闭内部播放
      try {
        const result =
          this.rtcEngine.enableAudioFrameObserver(true, AliRtcAudioSource.AliRtcAudioSourcePlayback, config);

        if (result === 0) {
          // 注册音频帧观察者
          if (this.audioFrameObserver) {
            this.rtcEngine.registerAudioFrameObserver(this.audioFrameObserver);
          }

          // 设置参数关闭系统音频设备播放
          const parameter = '{"audio":{"enable_system_audio_device_play":"FALSE"}}';
          this.rtcEngine.setParameter(parameter);

          // 启动音频播放
          this.startAudioPlayer();

          promptAction.showToast({ message: '开始回调获取原始数据，需要用户自定义', duration: 2000 });
          console.info('外部音频播放已启用');
        } else {
          promptAction.showToast({ message: '获取原始数据失败', duration: 2000 });
          this.IsAudioCustom = false;
        }
      } catch (error) {
        console.error('启用音频帧观察者失败:', error);
        promptAction.showToast({ message: '启用失败', duration: 2000 });
        this.IsAudioCustom = false;
      }
    } else {
      // 关闭外部播放，打开内部播放
      try {
        const result =
          this.rtcEngine.enableAudioFrameObserver(false, AliRtcAudioSource.AliRtcAudioSourcePlayback, config);

        if (result === 0) {
          // 取消注册音频帧观察者
          this.rtcEngine.registerAudioFrameObserver(null);

          // 设置参数开启系统音频设备播放
          const parameter = '{"audio":{"enable_system_audio_device_play":"TRUE"}}';
          this.rtcEngine.setParameter(parameter);

          // 停止音频播放
          this.stopAudioPlayer();

          promptAction.showToast({ message: '关闭自定义音频播放', duration: 2000 });
          console.info('外部音频播放已禁用');
        } else {
          promptAction.showToast({ message: '停止原始数据失败', duration: 2000 });
          this.IsAudioCustom = true;
        }
      } catch (error) {
        console.error('禁用音频帧观察者失败:', error);
        promptAction.showToast({ message: '禁用失败', duration: 2000 });
        this.IsAudioCustom = true;
      }
    }
  }

  // ==================== 音频帧处理 ====================
  public handlePlaybackAudioFrame(frame: AliRtcAudioFrame): void {
    // 数据有效性检查
    if (!frame || !frame.buffer || frame.samplesPerSec <= 0 || frame.numOfChannels <= 0 || frame.bytesPerSample <= 0) {
      console.error('无效的音频帧!');
      return;
    }

    // 创建音频帧副本
    const frameCopy: AudioFrameData = {
      data: new Uint8Array(frame.buffer as ArrayBuffer).slice(),
      samplesPerSec: frame.samplesPerSec,
      numChannels: frame.numOfChannels,
      bytesPerSample: frame.bytesPerSample,
      timestamp: Date.now()
    };

    // 添加到队列，限制队列大小
    if (this.audioQueue.length >= this.MAX_QUEUE_SIZE) {
      this.audioQueue.shift();
    }
    this.audioQueue.push(frameCopy);
  }

  // ==================== 音频播放器 ====================
  private async startAudioPlayer(): Promise<void> {
    if (this.isAudioPlaying) {
      return;
    }

    this.isAudioPlaying = true;

    // 使用定时器播放音频数据
    this.audioPlayInterval = setInterval(() => {
      this.processAudioQueue();
    }, 10) as number; // 每10ms处理一次

    console.info('音频播放器已启动');
  }

  private stopAudioPlayer(): void {
    if (this.audioPlayInterval) {
      clearInterval(this.audioPlayInterval);
      this.audioPlayInterval = 0;
    }

    this.isAudioPlaying = false;

    // 释放音频渲染器
    this.releaseAudioRenderer();

    // 清空音频队列
    this.audioQueue = [];

    console.info('音频播放器已停止');
  }

  private async processAudioQueue(): Promise<void> {
    if (this.audioQueue.length === 0) {
      return;
    }

    const frame = this.audioQueue.shift();
    if (!frame) {
      return;
    }

    try {
      // 检查音频参数是否变化，需要重新初始化音频渲染器
      if (!this.audioRenderer ||
        this.currentSampleRate !== frame.samplesPerSec ||
        this.currentChannels !== frame.numChannels) {

        await this.initAudioRenderer(frame.samplesPerSec, frame.numChannels);
      }

      // 播放音频数据
      if (this.audioRenderer) {
        const bytesToWrite = frame.data.length;
        const writeResult = this.audioRenderer.write(frame.data.buffer, (err) => {
          if (err) {
            console.error('写入音频数据失败:', err);
          }
        });

        if (writeResult !== undefined) {
          console.debug(`写入音频数据: ${writeResult} bytes`);
        }
      }
    } catch (error) {
      console.error('处理音频数据失败:', error);
    }
  }

  private async initAudioRenderer(sampleRate: number, channels: number): Promise<void> {
    // 释放旧的音频渲染器
    this.releaseAudioRenderer();

    try {
      // 映射采样率
      let audioSampleRate: audio.AudioSamplingRate;
      switch (sampleRate) {
        case 8000:
          audioSampleRate = audio.AudioSamplingRate.SAMPLE_RATE_8000;
          break;
        case 16000:
          audioSampleRate = audio.AudioSamplingRate.SAMPLE_RATE_16000;
          break;
        case 32000:
          audioSampleRate = audio.AudioSamplingRate.SAMPLE_RATE_32000;
          break;
        case 44100:
          audioSampleRate = audio.AudioSamplingRate.SAMPLE_RATE_44100;
          break;
        case 48000:
        default:
          audioSampleRate = audio.AudioSamplingRate.SAMPLE_RATE_48000;
          break;
      }

      // 映射声道数
      let audioChannels: audio.AudioChannel;
      if (channels === 1) {
        audioChannels = audio.AudioChannel.CHANNEL_1; // 单声道
      } else {
        audioChannels = audio.AudioChannel.CHANNEL_2; // 立体声
      }

      // 配置音频流信息
      const audioStreamInfo: audio.AudioStreamInfo = {
        samplingRate: audioSampleRate,
        channels: audioChannels,
        sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
        encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
      };

      // 配置音频渲染器信息
      const audioRendererInfo: audio.AudioRendererInfo = {
        usage: audio.StreamUsage.STREAM_USAGE_MEDIA,
        rendererFlags: 0
      };
      const audioRendererOptions: audio.AudioRendererOptions = {
        streamInfo: audioStreamInfo, // 将流信息作为属性传入
        rendererInfo: audioRendererInfo // 将渲染器信息作为属性传入
      };
      try {
        // 2. 传入正确的配置对象创建音频渲染器
        this.audioRenderer = await audio.createAudioRenderer(audioRendererOptions);

        // 3. 启动音频渲染器
        await this.audioRenderer.start();

        // 更新当前参数
        this.currentSampleRate = sampleRate;
        this.currentChannels = channels;

        console.info(`音频渲染器初始化成功: ${sampleRate}Hz, ${channels}声道`);
      } catch (error) {
        console.error('初始化音频渲染器失败:', error);
        this.audioRenderer = undefined;
      }

    } catch (error) {
      console.error('初始化音频渲染器失败:', error);
      this.audioRenderer = undefined;
    }
  }

  private releaseAudioRenderer(): void {
    if (this.audioRenderer) {
      try {
        this.audioRenderer.stop();
        this.audioRenderer.release();
        this.audioRenderer = undefined;
        console.info('音频渲染器已释放');
      } catch (error) {
        console.error('释放音频渲染器失败:', error);
      }
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

      const result = this.rtcEngine.joinChannelWithToken(base64Token, '', '', '自定义音频播放用户');

      console.info('加入频道调用结果:', result);
      this.hasJoined = true;
      this.localUserId = userId;
    } catch (error) {
      console.error('加入频道失败:', error);
      promptAction.showToast({ message: `加入频道失败: ${error}`, duration: 3000 });
    }
  }

  // ====================结果处理 ====================
  private handleJoinResult(resultCode: number, channel: string): void {
    const resultText = resultCode === 0
      ? `Join ${channel} Success`
      : `Join ${channel} Failed!，error: ${resultCode}`;

    promptAction.showToast({ message: resultText, duration: 2000 });

    // 更新按钮文本
    if (resultCode === 0) {
      this.hasJoined = true;
    }
  }

  // ==================== 清理资源 ====================
  private async destroyRtcEngine(): Promise<void> {
    // 停止音频播放
    this.stopAudioPlayer();

    if (this.rtcEngine) {
      try {
        if (this.hasJoined) {
          this.rtcEngine.leaveChannel();
          this.hasJoined = false;
        }

        // 取消音频帧观察者
        if (this.IsAudioCustom) {
          this.rtcEngine.registerAudioFrameObserver(null);
          this.rtcEngine.enableAudioFrameObserver(false, AliRtcAudioSource.AliRtcAudioSourcePlayback,
            new AliRtcAudioFrameObserverConfig());
        }

        this.rtcEngine.stopPreview();
        this.rtcEngine = undefined;
        this.rtcEngineEventListener = undefined;
        this.audioFrameObserver = undefined;

        promptAction.showToast({ message: 'Leave Channel', duration: 2000 });
      } catch (error) {
        console.error('销毁引擎失败:', error);
      }
    }

    // 重置状态
    this.ShowPreview = false;
    this.IsAudioCustom = false;
    this.localUserId = '';
    this.remoteVideoStreams = [];
  }

  aboutToDisappear(): void {
    this.destroyRtcEngine();
  }

  private createAudioFrameObserver(): void {
    const rtcAudioFrameObserver: AliRtcEngineAudioFrameListener = {} as AliRtcEngineAudioFrameListener
    rtcAudioFrameObserver.onCapturedAudioFrame((frame: AliRtcAudioFrame) => {
      // 本地采集音频数据回调
      console.info('onCaptureAudioFrame');
      return true;
    });

    rtcAudioFrameObserver.onProcessCapturedAudioFrame((frame: AliRtcAudioFrame) => {
      // 3A处理后音频数据回调
      console.info('onProcessCaptureAudioFrame');
      return true;
    });

    rtcAudioFrameObserver.onPublishAudioFrame((frame: AliRtcAudioFrame) => {
      // 推流音频数据回调
      console.info('onPublishAudioFrame');
      return true;
    });

    rtcAudioFrameObserver.onPlaybackAudioFrame((frame: AliRtcAudioFrame) => {
      // 播放数据（混音后）回调
      console.info('onPlaybackAudioFrame');
      return true;
    });

    rtcAudioFrameObserver.onRemoteUserAudioFrame((uid: string, frame: AliRtcAudioFrame) => {
      // 远端用户音频数据回调
      console.info(`onRemoteUserAudioFrame, uid: ${uid}`);
      return true;
    })

    // 注册音频帧观察者
    if (this.rtcEngine) {
      this.rtcEngine.registerAudioFrameObserver(rtcAudioFrameObserver);
    }
  }
}


// ==================== 音频帧数据类型 ====================
interface AudioFrameData {
  data: Uint8Array;
  samplesPerSec: number;
  numChannels: number;
  bytesPerSample: number;
  timestamp: number;
}