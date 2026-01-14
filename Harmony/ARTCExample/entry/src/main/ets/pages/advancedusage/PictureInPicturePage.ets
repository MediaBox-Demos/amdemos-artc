import { CustomTitle } from "../../common/components/CustomTitle";
import {
  AliRtcEngine,
  AliRtcVideoCanvas,
  AliRtcXComponentController,
  AliRtcEngineEventListener,
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
  AliRtcRenderMode,
  AliRtcRenderMirrorMode,
  AliRtcAudioProfile,
  AliRtcAudioScenario,
} from '@aliyun_video_cloud/alivcsdk_artc';
import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { window, PiPWindow } from '@kit.ArkUI';
import { ARTCTokenHelper } from '../../common/keycenter/ARTCTokenHelper';
import { GlobalConfig } from '../../common/keycenter/GlobalConfig';
import {
  PictureInPictureManager, PipConfiguration, PagePipAdapter
} from './pipManager/PictureInPictureManager'; // 导入管理器和适配器
import { RemoteVideoStream } from "../../common/Constants"


@Entry
@Component
export struct PictureInPicturePage {
  @State channelId: string = Date.now().toString().slice(-6);
  @State hasJoined: boolean = false;
  @State showPreview: boolean = false;
  @State isInPictureInPictureMode: boolean = false;
  @State localVideoVisible: boolean = true;
  @Watch('onAppForegroundStateChange')
  @StorageLink('isAppOnForeground') isAppOnForeground: boolean = true;
  // RTC引擎相关
  private rtcEngine: AliRtcEngine | undefined;
  private context: common.UIAbilityContext | undefined;
  private rtcEngineEventListener: AliRtcEngineEventListener | undefined;
  // 本地视频
  private localXComponentController: XComponentController = new XComponentController();
  private aliRtcVideoCanvas: AliRtcVideoCanvas | undefined;
  private componentController: AliRtcXComponentController = new AliRtcXComponentController();
  // 画中画管理器
  private pipManager: PictureInPictureManager = new PictureInPictureManager();
  private pipAdapter: PagePipAdapter | undefined; // 页面适配器
  // 存储远端视频视图的Map
  @State remoteVideoStreams: RemoteVideoStream[] = []
  private pageStack: NavPathStack = {} as NavPathStack

  async aboutToAppear() {
    this.context = getContext(this) as common.UIAbilityContext;
    this.pipAdapter = new PagePipAdapter(
      this.handlePipStateChange.bind(this),
      this.handlePipActionEvent.bind(this)
    );
    // 添加画中画状态监听器（使用适配器）
    if (this.pipAdapter) {
      this.pipManager.addStateListener(this.pipAdapter);

    }
    this.pageStack = await AppStorage.get('pageInfo') as NavPathStack;
  }

  private async onAppForegroundStateChange(): Promise<void> {
    console.info(`应用前台状态变化: ${this.isAppOnForeground}, 已加入频道: ${this.hasJoined}, 画中画状态: ${this.isInPictureInPictureMode}`);

    // 应用退到后台且已经在频道中 -> 自动进入画中画
    if (!this.isAppOnForeground && this.hasJoined) {
      await this.startPip();
      return;
    }

    // 应用回到前台 -> 自动退出画中画
    if (this.isAppOnForeground) {
      await this.stopPip();
    }
  }

  build() {
    NavDestination() {
      Column() {
        CustomTitle({
          titleText: '画中画',
        })

        Column() {
          // 频道输入区域
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

            Row() {
              Text('开启画中画')
                .textAlign(TextAlign.Center)
                .fontSize(16)
                .backgroundColor('#3295fb')
                .layoutWeight(1)
                .height(48)
                .onClick(async () => {
                  await this.startPip();
                })
              Blank()
                .width(20)
              Text(this.hasJoined ? '挂断' : '加入频道')
                .textAlign(TextAlign.Center)
                .fontSize(16)
                .backgroundColor('#3295fb')
                .layoutWeight(1)
                .height(48)
                .onClick(async () => {
                  if (this.hasJoined) {
                    this.destroyRtcEngine();
                  } else {
                    await this.startRtcCall();
                  }
                })
            }
            .width('100%')
            .margin({
              top: 24, left: 10,
              right: 10
            })
          }

          // 视频预览区域
          if (this.showPreview) {
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
      .onAppear(() => {
        this.setupWindowCallbacks();
      })
      .onDisAppear(() => {
        this.cleanupPip();
      })
    }
    .hideTitleBar(true)
    .onShown(() => {
      // this.startPip();
    })
    .onHidden(() => {
      // if (!this.isInPictureInPictureMode) {
      //   this.destroyRtcEngine();
      //   this.cleanupPip();
      // }
    })
  }

  // 判断是否显示多人网格布局
  private shouldShowGridLayout(): boolean {
    return this.showPreview && this.remoteVideoStreams.length > 0;
  }

  @Builder
  buildLocalVideoView() {
    Column() {
      if (!this.shouldShowGridLayout()) {
        Column() {
          Text('Local')
            .fontSize(12)
            .fontColor(Color.White)
            .backgroundColor('#80000000')
            .padding(4)
            .borderRadius(4)
            .position({ x: 8, y: 8 })
            .zIndex(1)
          XComponent({
            id: 'local_video_surface',
            type: 'surface',
            controller: this.localXComponentController
          })
            .width('100%')
            .height('100%')
            .onLoad(() => {
              this.setupLocalVideo();
            })
        }
        .backgroundColor('#000')
        .width('100%')
        .height('200vp')
      } else {
        Row() {
          Column() {
            Text('Local')
              .fontSize(12)
              .fontColor(Color.White)
              .backgroundColor('#80000000')
              .padding(4)
              .borderRadius(4)
              .position({ x: 8, y: 8 })
              .zIndex(1)
            XComponent({
              id: 'local_video_surface',
              type: 'surface',
              controller: this.localXComponentController
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

          Column() {
            // 用户ID和流类型标签
            Row() {
              Text(this.remoteVideoStreams[0].uid)
                .fontSize(12)
                .fontColor(Color.White)

              Text(this.getTrackTypeText(this.remoteVideoStreams[0].videoTrack))
                .fontSize(12)
                .fontColor(Color.White)
            }
            .backgroundColor('#80000000')
            .padding(4)
            .borderRadius(4)
            .position({ x: 8, y: 8 })
            .zIndex(1)

            // 视频渲染区域
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

  private getTrackTypeText(track: AliRtcVideoTrack): string {
    switch (track) {
      case AliRtcVideoTrack.AliRtcVideoTrackCamera:
        return '-Camera';
      case AliRtcVideoTrack.AliRtcVideoTrackScreen:
        return '屏幕共享';
      case AliRtcVideoTrack.AliRtcVideoTrackBoth:
        return '双流';
      default:
        return '未知';
    }
  }

  // ==================== 窗口回调设置 ====================
  private async setupWindowCallbacks(): Promise<void> {
    try {
      const win = await window.getLastWindow(this.context!);
      // 监听窗口状态变化，自动进入/退出画中画
      // win.on('windowStageChange', (event: window.WindowStageEventType) => {
      //   console.info(`窗口状态变化: ${event}`);
      //   if (event === window.WindowStageEventType.INACTIVE && this.hasJoined) {
      //     // 应用进入后台时自动开启画中画
      //     this.startPip();
      //   } else if (event === window.WindowStageEventType.ACTIVE && this.isInPictureInPictureMode) {
      //     // 应用回到前台时退出画中画
      //     this.stopPip();
      //   }
      // });
    } catch (error) {
      console.error('设置窗口回调失败:', error);
    }
  }

  // ==================== 画中画功能 ====================
  private async startPip(): Promise<void> {
    if (!this.hasJoined) {
      promptAction.showToast({ message: '请先加入频道', duration: 2000 });
      return;
    }

    // 准备配置参数
    const pipConfig: PipConfiguration = {
      context: this.context!,
      componentController: this.localXComponentController,
      contentWidth: 150,
      contentHeight: 150,
      navigationId: 'mainNav'
    };

    // 使用管理器启动画中画
    const success: boolean = await this.pipManager.startPip(pipConfig);
    if (success) {
      this.pageStack.pop()
      this.isInPictureInPictureMode = true;
      promptAction.showToast({ message: '已进入画中画模式', duration: 2000 });
    } else {
      promptAction.showToast({ message: '启动画中画失败', duration: 2000 });
    }
  }

  private async stopPip(): Promise<void> {
    const success: boolean = await this.pipManager.stopPip();

    if (success) {
      this.isInPictureInPictureMode = false;
      promptAction.showToast({ message: '已退出画中画模式', duration: 2000 });
    }
  }

  private cleanupPip(): void {
    // 移除监听器
    if (this.pipAdapter) {
      this.pipManager.removeStateListener(this.pipAdapter);
    }
  }

  // ==================== 处理画中画状态变化 ====================
  private handlePipStateChange(state: PiPWindow.PiPState, reason: string): void {
    console.info(`画中画状态变化: ${state}, 原因: ${reason}`);

    // 更新本地状态
    if (state === PiPWindow.PiPState.STOPPED || state === PiPWindow.PiPState.ERROR) {
      this.isInPictureInPictureMode = false;

    } else if (state === PiPWindow.PiPState.STARTED) {
      this.isInPictureInPictureMode = true;
    } else if (state === PiPWindow.PiPState.ABOUT_TO_RESTORE) {
    }
  }

  private handlePipActionEvent(event: PiPWindow.PiPActionEventType, status?: number): void {
    console.info(`画中画操作事件: ${event}, 状态: ${status}`);

    switch (event) {
      case 'playbackStateChanged':
        if (status === 0 && this.rtcEngine) {
          // 暂停视频
          this.rtcEngine.stopPreview();
          this.rtcEngine.publishLocalVideoStream(false);
        } else if (status === 1 && this.rtcEngine) {
          // 播放视频
          this.rtcEngine.startPreview();
          this.rtcEngine.publishLocalVideoStream(true);

        }
        break;
      default:
        break;
    }
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
    videoConfig.dimensions = new AliRtcVideoDimensions();
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
    });

    // 连接状态变化回调
    this.rtcEngineEventListener.onConnectionStatusChange(
      (status: AliRtcConnectionStatus, reason: AliRtcConnectionStatusChangeReason) => {
        console.info(`连接状态改变: status=${status}, reason=${reason}`);
        if (status === AliRtcConnectionStatus.AliRtcConnectionFailed) {
          promptAction.showToast({ message: '连接失败，请检查网络', duration: 2000 });
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

    // 远端轨道可用通知
    this.rtcEngineEventListener.onRemoteTrackAvailableNotify(
      (uid: string, audioTrack: AliRtcAudioTrack, videoTrack: AliRtcVideoTrack) => {
        console.info(`远端轨道可用: uid=${uid}, audioTrack=${audioTrack}, videoTrack=${videoTrack}`);
        this.handleRemoteTrackAvailable(uid, videoTrack);
      }
    );

    // 设置事件监听器
    this.rtcEngine.setRtcEngineEventListener(this.rtcEngineEventListener);
  }

  // ==================== 频道操作 ====================
  private async startRtcCall(): Promise<void> {
    if (this.hasJoined) {
      return;
    }

    if (!this.rtcEngine) {
      await this.initAndSetupRtcEngine();
    }

    await this.startPreview();
    await this.joinChannel();
  }

  private setupLocalVideo(): void {
    if (!this.context) {
      console.error('Context未初始化');
      return;
    }

    try {
      let surfaceId = this.localXComponentController.getXComponentSurfaceId();
      console.info('获取到本地视频surfaceId:', surfaceId);

      this.aliRtcVideoCanvas = new AliRtcVideoCanvas();
      this.aliRtcVideoCanvas.surfaceId = surfaceId;
      this.aliRtcVideoCanvas.renderMode = AliRtcRenderMode.AliRtcRenderModeAuto;
      this.aliRtcVideoCanvas.mirrorMode = AliRtcRenderMirrorMode.AliRtcRenderMirrorModeAllMirror;

      // 启动预览
      this.startPreview();

      console.info('本地视频画布设置完成');
    } catch (error) {
      console.error('设置本地视频失败:', error);
    }
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
      this.showPreview = true;
      this.localVideoVisible = true;

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
      const result = this.rtcEngine.joinChannelWithToken(base64Token, '', '', '画中画');
      console.info('加入频道调用结果:', result);

      this.hasJoined = true;

    } catch (error) {
      console.error('加入频道失败:', error);
      promptAction.showToast({ message: `加入频道失败: ${error}`, duration: 3000 });
    }
  }

  // ==================== 远端视频处理 ====================
  private getStreamKey(uid: string, videoTrack: AliRtcVideoTrack): string {
    return `${uid}_${videoTrack}`;
  }

  private handleRemoteTrackAvailable(uid: string, videoTrack: AliRtcVideoTrack): void {
    const streamKey = this.getStreamKey(uid, videoTrack);

    switch (videoTrack) {
      case AliRtcVideoTrack.AliRtcVideoTrackCamera:
        this.viewRemoteVideo(uid, AliRtcVideoTrack.AliRtcVideoTrackCamera);
        this.removeRemoteVideo(uid, AliRtcVideoTrack.AliRtcVideoTrackScreen);
        break;
      case AliRtcVideoTrack.AliRtcVideoTrackScreen:
        this.viewRemoteVideo(uid, AliRtcVideoTrack.AliRtcVideoTrackScreen);
        this.removeRemoteVideo(uid, AliRtcVideoTrack.AliRtcVideoTrackCamera);
        break;
      case AliRtcVideoTrack.AliRtcVideoTrackBoth:
        this.viewRemoteVideo(uid, AliRtcVideoTrack.AliRtcVideoTrackCamera);
        this.viewRemoteVideo(uid, AliRtcVideoTrack.AliRtcVideoTrackScreen);
        break;
      case AliRtcVideoTrack.AliRtcVideoTrackNo:
        this.removeAllRemoteVideo(uid);
        break;
    }
  }

  // 设置远端视频
  private setupRemoteVideo(stream: RemoteVideoStream): void {
    if (!this.rtcEngine) {
      console.error('RTC引擎未初始化');
      return;
    }

    try {
      stream.surfaceId = stream.xcomponentController.getXComponentSurfaceId();
      console.info(`设置远端视频: ${stream.uid} - ${stream.videoTrack}, surfaceId: ${stream.surfaceId}`);

      if (!stream.canvas) {
        stream.canvas = new AliRtcVideoCanvas();
      }

      stream.canvas.surfaceId = stream.surfaceId;
      stream.canvas.renderMode = AliRtcRenderMode.AliRtcRenderModeAuto;
      stream.canvas.mirrorMode = AliRtcRenderMirrorMode.AliRtcRenderMirrorModeAllNoMirror;

      this.rtcEngine.setRemoteViewConfig(stream.canvas, this.componentController, stream.uid,
        AliRtcVideoTrack.AliRtcVideoTrackCamera);

      console.info(`远端视频设置完成: ${stream.uid} - ${stream.videoTrack}`);

    } catch (error) {
      console.error(`设置远端视频失败 ${stream.uid}:`, error);
    }
  }

  // 查看远端视频
  private viewRemoteVideo(uid: string, videoTrack: AliRtcVideoTrack): void {
    console.info(`查看远端视频: ${uid} - ${videoTrack}`);

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
      surfaceId: ''
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

    this.remoteVideoStreams = this.remoteVideoStreams.filter(s => s.uid !== uid);

    console.info(`移除用户所有视频成功: ${uid}`);
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
          this.rtcEngine.stopPreview();
          this.rtcEngine.leaveChannel();
          this.hasJoined = false;
        }

        // 清理远端视频
        this.remoteVideoStreams = [];

        this.rtcEngine = undefined;
        this.rtcEngineEventListener = undefined;

        promptAction.showToast({ message: '已离开频道', duration: 2000 });
      } catch (error) {
        console.error('销毁引擎失败:', error);
      }
    }

    // 重置状态
    this.showPreview = false;
    this.localVideoVisible = true;

    // 停止画中画
    this.stopPip();
  }

  aboutToDisappear(): void {
    if (!this.isInPictureInPictureMode) {
      this.destroyRtcEngine();
      this.cleanupPip();
    }
  }
}