import {
  AliRtcEngine,
  AliRtcVideoCanvas,
  AliRtcXComponentController,
  AliRtcEngineEventListener,
  AliRtcAudioFrameObserverConfig,
  AliRtcAudioSource,
  AliRtcAudioSampleRate,
  AliRtcAudioNumChannel,
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
  AliRtcUserOfflineReason,
  AliRtcAudioTrack,
  AliRtcStats,
  AliRtcLocalDeviceType,
  AliRtcLocalDeviceExceptionType,
  AliRtcVideoMirrorMode,
  AliRtcRotationMode,
  AliRtcRenderMode,
  AliRtcRenderMirrorMode,
  AliRtcAudioFrame,
  AliRtcEngineAudioFrameListener
} from '@aliyun_video_cloud/alivcsdk_artc';
import { CustomTitle } from '../../common/components/CustomTitle';
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { ARTCTokenHelper } from '../../common/keycenter/ARTCTokenHelper';
import { GlobalConfig } from '../../common/keycenter/GlobalConfig';
import { RemoteVideoStream } from "../../common/Constants"

@Entry
@Component
export struct ProcessAudioRawDataPage {
  @State initRoom: boolean = false
  @State channelId: string = Date.now().toString().slice(-6);
  @State ShowPreview: boolean = false;
  @State IsCaptureAudioFrame: boolean = false;
  @State IsProcessCapturedAudioFrame: boolean = false;
  @State IsPublishAudioFrame: boolean = false;
  @State IsPlaybackAudioFrame: boolean = false;
  @State IsRemoteUserAudioFrame: boolean = false;
  private rtcEngine: AliRtcEngine | undefined;
  private context: common.UIAbilityContext | undefined;
  private xcomponentController: XComponentController = new XComponentController();
  private aliRtcVideoCanvas: AliRtcVideoCanvas | undefined;
  private componentController: AliRtcXComponentController = new AliRtcXComponentController();
  @State hasJoined: boolean = false;
  @State localUserId: string = '';
  private rtcEngineEventListener: AliRtcEngineEventListener | undefined;
  @State remoteVideoStreams: RemoteVideoStream[] = []
  aboutToAppear() {
    this.context = getContext(this) as common.UIAbilityContext;
  }

  build() {
    NavDestination() {
      Column() {
        CustomTitle({
          titleText: '获取原始音频数据',
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
                this.destroyRtcEngine();
              } else {
                if (!this.rtcEngine) {
                  await this.initAndSetupRtcEngine();
                }
                await this.startRTCCall();
              }
            })

          // 视频预览区域
            Column() {
              this.buildLocalVideoView()
            }
            .width('100%')
            .height('280')
            .opacity(this.ShowPreview ? 1 : 0)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)


          Column() {
            this.buildSwitchItem('CaptureAudioFrame:', this.IsCaptureAudioFrame, (value: boolean) => {
              this.handleCaptureAudioFrameSwitch(value);
            })
            this.buildSwitchItem('ProcessCapturedAudioFrame:', this.IsProcessCapturedAudioFrame, (value: boolean) => {
              this.handleProcessCapturedAudioFrameSwitch(value);
            })
            this.buildSwitchItem('PublishAudioFrame:', this.IsPublishAudioFrame, (value: boolean) => {
              this.handlePublishAudioFrameSwitch(value);
            })
            this.buildSwitchItem('PlaybackAudioFrame:', this.IsPlaybackAudioFrame, (value: boolean) => {
              this.handlePlaybackAudioFrameSwitch(value);
            })
            this.buildSwitchItem('RemoteUserAudioFrame:', this.IsRemoteUserAudioFrame, (value: boolean) => {
              this.handleRemoteUserAudioFrameSwitch(value);
            })
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
    .height('240')
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

  private setupLocalVideo(): void {
    if (!this.context) {
      console.error('Context未初始化');
      return;
    }

    try {
      let surfaceId = this.xcomponentController.getXComponentSurfaceId();
      console.info('获取到本地视频surfaceId:', surfaceId);

      this.aliRtcVideoCanvas = new AliRtcVideoCanvas();
      this.aliRtcVideoCanvas.surfaceId = surfaceId;
      this.aliRtcVideoCanvas.renderMode = AliRtcRenderMode.AliRtcRenderModeAuto;
      this.aliRtcVideoCanvas.mirrorMode = AliRtcRenderMirrorMode.AliRtcRenderMirrorModeAllMirror;

      this.startPreview()

      console.info('本地视频画布设置完成');

    } catch (error) {
      console.error('设置本地视频失败:', error);
    }
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

    // 创建RTC引擎实例
    if (!this.rtcEngine) {
      this.rtcEngine = AliRtcEngine.getInstance('', this.context);
    }
    if (this.rtcEngine === undefined) {
      promptAction.showToast({ message: 'RTC引擎未初始化成功', duration: 2000 });
      return;
    }
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
    videoConfig.min_bitrate = 0;
    videoConfig.forceStrictKeyFrameInterval = 0;
    videoConfig.mirrorMode = AliRtcVideoMirrorMode.AliRtcVideoMirrorModeDisabled;
    videoConfig.rotationMode = AliRtcRotationMode.AliRtcRotationMode_0;
    this.rtcEngine.setVideoEncoderConfiguration(videoConfig);

    // 发布本地音视频流
    this.rtcEngine.publishLocalAudioStream(true);
    this.rtcEngine.publishLocalVideoStream(true);

    // 设置默认订阅远端音视频流
    this.rtcEngine.setDefaultSubscribeAllRemoteAudioStreams(true);
    this.rtcEngine.subscribeAllRemoteAudioStreams(true);
    this.rtcEngine.setDefaultSubscribeAllRemoteVideoStreams(true);
    this.rtcEngine.subscribeAllRemoteVideoStreams(true);

    // 创建音频帧观察者
    this.createAudioFrameObserver();
  }

  // ==================== 事件监听器设置 ====================
  private setupEventListeners(): void {
    if (!this.rtcEngine) {
      return;
    }

    // 创建引擎事件监听器
    this.rtcEngineEventListener = new AliRtcEngineEventListener();

    // 加入频道结果回调
    this.rtcEngineEventListener.onJoinChannel((resultCode: number, channel: string, elapsed: string) => {
      console.info(`加入频道结果: result=${resultCode}, channel=${channel}, elapsed=${elapsed}`);
      this.handleJoinResult(resultCode, channel);
    });

    // 离开频道结果回调
    this.rtcEngineEventListener.onLeaveChannel((result: number, stats: AliRtcStats) => {
      console.info(`离开频道结果: result=${result}`);
      // 离开频道后移除音频帧观察者
      this.rtcEngine?.refreshAuthInfoWithToken(null);
    });

    // 连接状态变化回调
    this.rtcEngineEventListener.onConnectionStatusChange(
      (status: AliRtcConnectionStatus, reason: AliRtcConnectionStatusChangeReason) => {
        console.info(`连接状态改变: status=${status}, reason=${reason}`);
        if (status === AliRtcConnectionStatus.AliRtcConnectionInit) {
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
    // 设置事件监听器
    this.rtcEngine.setRtcEngineEventListener(this.rtcEngineEventListener);
  }

  // ==================== 音频帧观察者 ====================
  private createAudioFrameObserver(): void {
     const rtcAudioFrameObserver :AliRtcEngineAudioFrameListener = {} as AliRtcEngineAudioFrameListener
    rtcAudioFrameObserver.onCapturedAudioFrame ((frame: AliRtcAudioFrame) => {
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

  // ==================== 开关处理函数 ====================
  private handleCaptureAudioFrameSwitch(isChecked: boolean): void {
    if (!this.rtcEngine) {
      promptAction.showToast({ message: 'RTC引擎未初始化', duration: 2000 });
      this.IsCaptureAudioFrame = false;
      return;
    }

    const config: AliRtcAudioFrameObserverConfig = new AliRtcAudioFrameObserverConfig();
    config.sampleRate = AliRtcAudioSampleRate.AliRtcAudioSampleRate_48000;
    config.channels = AliRtcAudioNumChannel.AliRtcMonoAudio;

    this.rtcEngine.enableAudioFrameObserver(isChecked, AliRtcAudioSource.AliRtcAudioSourceCaptured, config);
    this.IsCaptureAudioFrame = isChecked;
  }

  private handleProcessCapturedAudioFrameSwitch(isChecked: boolean): void {
    if (!this.rtcEngine) {
      promptAction.showToast({ message: 'RTC引擎未初始化', duration: 2000 });
      this.IsProcessCapturedAudioFrame = false;
      return;
    }
    const config: AliRtcAudioFrameObserverConfig = new AliRtcAudioFrameObserverConfig();
    config.sampleRate = AliRtcAudioSampleRate.AliRtcAudioSampleRate_48000;
    config.channels = AliRtcAudioNumChannel.AliRtcMonoAudio;


    this.rtcEngine.enableAudioFrameObserver(isChecked, AliRtcAudioSource.AliRtcAudioSourceProcessCaptured, config);
    this.IsProcessCapturedAudioFrame = isChecked;
  }

  private handlePublishAudioFrameSwitch(isChecked: boolean): void {
    if (!this.rtcEngine) {
      promptAction.showToast({ message: 'RTC引擎未初始化', duration: 2000 });
      this.IsPublishAudioFrame = false;
      return;
    }

    const config: AliRtcAudioFrameObserverConfig = new AliRtcAudioFrameObserverConfig();
    config.sampleRate = AliRtcAudioSampleRate.AliRtcAudioSampleRate_48000;
    config.channels = AliRtcAudioNumChannel.AliRtcMonoAudio;

    this.rtcEngine.enableAudioFrameObserver(isChecked, AliRtcAudioSource.AliRtcAudioSourcePub, config);
    this.IsPublishAudioFrame = isChecked;
  }

  private handlePlaybackAudioFrameSwitch(isChecked: boolean): void {
    if (!this.rtcEngine) {
      promptAction.showToast({ message: 'RTC引擎未初始化', duration: 2000 });
      this.IsPlaybackAudioFrame = false;
      return;
    }

    const config: AliRtcAudioFrameObserverConfig = new AliRtcAudioFrameObserverConfig();
    config.sampleRate = AliRtcAudioSampleRate.AliRtcAudioSampleRate_48000;
    config.channels = AliRtcAudioNumChannel.AliRtcMonoAudio;

    this.rtcEngine.enableAudioFrameObserver(isChecked, AliRtcAudioSource.AliRtcAudioSourcePlayback, config);
    this.IsPlaybackAudioFrame = isChecked;
  }

  private handleRemoteUserAudioFrameSwitch(isChecked: boolean): void {
    if (!this.rtcEngine) {
      promptAction.showToast({ message: 'RTC引擎未初始化', duration: 2000 });
      this.IsRemoteUserAudioFrame = false;
      return;
    }
    const config: AliRtcAudioFrameObserverConfig = new AliRtcAudioFrameObserverConfig();


    this.rtcEngine.enableAudioFrameObserver(isChecked, AliRtcAudioSource.AliRtcAudioSourceRemoteUser, config);
    this.IsRemoteUserAudioFrame = isChecked;
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
        this.rtcEngine.setLocalViewConfig(
          this.aliRtcVideoCanvas,
          this.componentController,
          AliRtcVideoTrack.AliRtcVideoTrackCamera
        );
      }

      // 开始预览
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
        appId, appKey, this.channelId, userId, timestamp, nonce
      );

      // 加入频道
      const result = this.rtcEngine.joinChannelWithToken(base64Token, '', '', '音频原始数据');
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
    if (this.rtcEngine) {
      try {
        if (this.hasJoined) {
          this.rtcEngine.leaveChannel();
          this.hasJoined = false;
        }

        // 停止预览
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
    this.initRoom = false;
    this.localUserId = '';

    // 重置开关状态
    this.IsCaptureAudioFrame = false;
    this.IsProcessCapturedAudioFrame = false;
    this.IsPublishAudioFrame = false;
    this.IsPlaybackAudioFrame = false;
    this.IsRemoteUserAudioFrame = false;
    this.remoteVideoStreams = [];
  }

  aboutToDisappear(): void {
    this.destroyRtcEngine();
  }
}