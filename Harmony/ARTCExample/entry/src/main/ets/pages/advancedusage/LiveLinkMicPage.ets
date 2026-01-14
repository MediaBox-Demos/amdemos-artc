import {
  AliRtcEngine,
  AliRtcEngineEventListener,
  AliRtcVideoCanvas,
  AliRtcXComponentController,
  AliRtcVideoTrack,
  AliRtcAudioProfile,
  AliRtcAudioScenario,
  AliRtcChannelProfile,
  AliRtcClientRole,
  AliRtcVideoEncoderConfiguration,
  AliRtcVideoDimensions,
  AliRtcVideoEncoderOrientationMode,
  AliRtcRenderMode,
  AliRtcRenderMirrorMode,
  AliRtcConnectionStatus,
  AliRtcConnectionStatusChangeReason,
  AliRtcUserOfflineReason,
  AliRtcStats,
  AliRtcLocalDeviceType,
  AliRtcLocalDeviceExceptionType,
  AliRtcAudioTrack,
  AliRtcCapturePipelineScaleMode,
  AliRtcLiveTranscodingParam
} from "@aliyun_video_cloud/alivcsdk_artc";
import { CustomTitle } from "../../common/components/CustomTitle";
import { common } from "@kit.AbilityKit";
import { promptAction } from "@kit.ArkUI";
import { ARTCTokenHelper } from '../../common/keycenter/ARTCTokenHelper';
import { GlobalConfig } from '../../common/keycenter/GlobalConfig';
import { RemoteVideoStream } from "../../common/Constants"

/**
 * 直播连麦功能页面
 * 功能说明:
 * 1. 支持主播和连麦观众角色选择
 * 2. 同一频道内实时音视频互动连麦
 * 3. 主播可选择开启CDN旁路转推
 * 4. 多人视频画面实时渲染
 * 
 * 使用场景:
 * - 主播：创建房间并推流，可开启旁路到CDN供普通观众观看
 * - 连麦观众：加入主播房间，与主播实时互动
 * - 普通观众：通过播放器从CDN拉流观看（本页面不实现）
 */
@Entry
@Component
export struct LiveLinkMicPage {
  // 频道相关状态
  @State channelId: string = '';
  @State hasJoined: boolean = false;
  @State role: string = 'anchor'; // 'anchor' | 'guest'

  // 视频预览相关状态
  @State showPreview: boolean = false;
  @State remoteVideoStreams: RemoteVideoStream[] = []

  // CDN旁路相关状态（主播专用）
  @State streamUrl: string = '';
  @State isPublishingLive: boolean = false;
  private currentStreamUrl: string | undefined = undefined;

  // 跨频道订阅相关状态（主播PK演示）
  @State peerChannelId: string = '';
  @State peerUid: string = '';
  @State isSubscribingPeer: boolean = false;

  // RTC 引擎相关
  private rtcEngine: AliRtcEngine | undefined;
  private context: common.UIAbilityContext | undefined;
  private xcomponentController: XComponentController = new XComponentController();
  private componentController: AliRtcXComponentController = new AliRtcXComponentController();
  private localVideoCanvas: AliRtcVideoCanvas | undefined;
  private rtcEngineEventListener: AliRtcEngineEventListener | undefined;

  aboutToAppear() {
    this.context = getContext(this) as common.UIAbilityContext;
    const global = GlobalConfig.getInstance();
    this.channelId = global.getRandomChannelId();
  }

  build() {
    NavDestination() {
      Column() {
        CustomTitle({
          titleText: '直播连麦',
        })

        Scroll() {
          Column() {
            // 说明文字
            Text('主播和连麦观众加入同一频道实现实时互动，主播可开启旁路转推到CDN供普通观众观看。主播还可通过跨频道订阅模拟PK场景。')
              .fontSize(14)
              .fontColor('#666')
              .width('100%')
              .margin({ bottom: 10 })

            // 角色选择
            Row() {
              Text('选择角色:')
                .fontSize(16)
                .fontColor('#333')
                .width(80)

              Row() {
                Text('主播')
                  .fontSize(14)
                  .fontColor(this.role === 'anchor' ? '#fff' : '#333')
                  .backgroundColor(this.role === 'anchor' ? '#3295fb' : '#e0e0e0')
                  .padding({ left: 20, right: 20, top: 8, bottom: 8 })
                  .borderRadius(20)
                  .onClick(() => {
                    if (!this.hasJoined) {
                      this.role = 'anchor';
                    }
                  })

                Text('连麦观众')
                  .fontSize(14)
                  .fontColor(this.role === 'guest' ? '#fff' : '#333')
                  .backgroundColor(this.role === 'guest' ? '#3295fb' : '#e0e0e0')
                  .padding({ left: 20, right: 20, top: 8, bottom: 8 })
                  .borderRadius(20)
                  .margin({ left: 10 })
                  .onClick(() => {
                    if (!this.hasJoined) {
                      this.role = 'guest';
                    }
                  })
              }
              .margin({ left: 10 })
            }
            .margin({ top: 10 })
            .height(50)
            .alignItems(VerticalAlign.Center)

            // ChannelID 输入
            Row() {
              Text('ChannelID:')
                .fontSize(16)
                .fontColor('#333')
                .width(80)

              TextInput({
                text: this.channelId
              })
                .padding({ left: 5 })
                .layoutWeight(1)
                .backgroundColor('#fff')
                .fontColor('#333')
                .height(40)
                .border({
                  width: 1,
                  color: '#ddd',
                  radius: 4
                })
                .margin({ left: 10 })
                .enabled(!this.hasJoined)
                .onChange((text: string) => {
                  this.channelId = text;
                })
            }
            .margin({ top: 10 })
            .height(50)

            // 加入/离开频道按钮
            Text(this.hasJoined ? '离开频道' : '加入频道')
              .textAlign(TextAlign.Center)
              .fontSize(16)
              .fontColor('#fff')
              .backgroundColor('#3295fb')
              .width('95%')
              .height(48)
              .borderRadius(5)
              .margin({ top: 20, left: 10, right: 10 })
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

            // 主播专用：跨频道订阅（PK演示）
            if (this.role === 'anchor') {
              Text('跨频道订阅 (模拟PK)')
                .fontSize(15)
                .fontColor('#333')
                .fontWeight(FontWeight.Bold)
                .width('100%')
                .margin({ top: 15, bottom: 5 })

              // 目标频道ID输入
              Row() {
                Text('目标频道:')
                  .fontSize(16)
                  .fontColor('#333')
                  .width(80)

                TextInput({
                  text: this.peerChannelId,
                  placeholder: '输入对方主播频道ID'
                })
                  .padding({ left: 5 })
                  .layoutWeight(1)
                  .backgroundColor('#fff')
                  .fontColor('#333')
                  .height(40)
                  .border({
                    width: 1,
                    color: '#ddd',
                    radius: 4
                  })
                  .margin({ left: 10 })
                  .enabled(!this.isSubscribingPeer)
                  .onChange((text: string) => {
                    this.peerChannelId = text;
                  })
              }
              .margin({ top: 5 })
              .height(50)

              // 目标用户ID输入
              Row() {
                Text('目标用户:')
                  .fontSize(16)
                  .fontColor('#333')
                  .width(80)

                TextInput({
                  text: this.peerUid,
                  placeholder: '输入对方主播UID'
                })
                  .padding({ left: 5 })
                  .layoutWeight(1)
                  .backgroundColor('#fff')
                  .fontColor('#333')
                  .height(40)
                  .border({
                    width: 1,
                    color: '#ddd',
                    radius: 4
                  })
                  .margin({ left: 10 })
                  .enabled(!this.isSubscribingPeer)
                  .onChange((text: string) => {
                    this.peerUid = text;
                  })
              }
              .margin({ top: 10 })
              .height(50)

              // 跨频道订阅按钮
              Row() {
                Text(this.isSubscribingPeer ? '停止PK订阅' : '开始PK订阅')
                  .textAlign(TextAlign.Center)
                  .fontSize(16)
                  .fontColor('#fff')
                  .backgroundColor(this.hasJoined ? '#ff6b35' : '#aaa')
                  .layoutWeight(1)
                  .height(48)
                  .borderRadius(5)
                  .margin({ left: 10, right: 10 })
                  .enabled(this.hasJoined)
                  .opacity(this.hasJoined ? 1.0 : 0.5)
                  .onClick(async () => {
                    if (this.isSubscribingPeer) {
                      await this.stopCrossChannelSubscribe();
                    } else {
                      await this.startCrossChannelSubscribe();
                    }
                  })
              }
              .width('100%')
              .margin({ top: 10 })
            }

            // 主播专用：CDN旁路控制
            if (this.role === 'anchor') {
              // Stream URL 输入
              Row() {
                Text('CDN URL:')
                  .fontSize(16)
                  .fontColor('#333')
                  .width(80)

                TextInput({
                  text: this.streamUrl
                })
                  .padding({ left: 5 })
                  .layoutWeight(1)
                  .backgroundColor('#fff')
                  .fontColor('#333')
                  .height(40)
                  .border({
                    width: 1,
                    color: '#ddd',
                    radius: 4
                  })
                  .margin({ left: 10 })
                  .enabled(!this.isPublishingLive)
                  .onChange((text: string) => {
                    this.streamUrl = text;
                  })
              }
              .margin({ top: 15 })
              .height(50)

              // 旁路按钮
              Row() {
                Text('开始旁路')
                  .textAlign(TextAlign.Center)
                  .fontSize(16)
                  .fontColor('#fff')
                  .backgroundColor(this.hasJoined && !this.isPublishingLive ? '#590ce4' : '#aaa')
                  .layoutWeight(1)
                  .height(48)
                  .borderRadius(5)
                  .margin({ left: 10 })
                  .enabled(this.hasJoined && !this.isPublishingLive)
                  .opacity(this.hasJoined && !this.isPublishingLive ? 1.0 : 0.5)
                  .onClick(async () => {
                    await this.startLiveStreaming();
                  })

                Text('停止旁路')
                  .textAlign(TextAlign.Center)
                  .fontSize(16)
                  .fontColor('#fff')
                  .backgroundColor(this.hasJoined && this.isPublishingLive ? '#590ce4' : '#aaa')
                  .layoutWeight(1)
                  .height(48)
                  .borderRadius(5)
                  .margin({ left: 10, right: 10 })
                  .enabled(this.hasJoined && this.isPublishingLive)
                  .opacity(this.hasJoined && this.isPublishingLive ? 1.0 : 0.5)
                  .onClick(async () => {
                    await this.stopLiveStreaming();
                  })
              }
              .width('100%')
              .margin({ top: 10 })
            }

            // 视频预览区域
            if (this.showPreview) {
              Column() {
                this.buildVideoView()
              }
              .width('100%')
              .height('400vp')
              .margin({ top: 20 })
              .justifyContent(FlexAlign.Start)
              .alignItems(HorizontalAlign.Center)
            }
          }
          .margin(12)
        }
        .align(Alignment.TopStart)
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#f5f5f5')
    }
    .hideTitleBar(true)
  }

  // ==================== 视频布局 ====================
  private shouldShowGridLayout(): boolean {
    return this.showPreview && this.remoteVideoStreams.length > 0;
  }

  @Builder
  buildVideoView() {
    Column() {
      if (!this.shouldShowGridLayout()) {
        // 单视频布局 - 仅本地预览
        Column() {
          Text(`Local (${this.role === 'anchor' ? '主播' : '观众'})`)
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
            controller: this.xcomponentController
          })
            .layoutWeight(1)
            .height('100%')
            .onLoad(() => {
              this.setupLocalVideo();
            })
        }
        .backgroundColor('#000')
        .height('200vp')
        .width('100%')

      } else {
        // 多视频布局 - 本地 + 远端
        Row() {
          // 本地视频
          Column() {
            Text(`Local (${this.role === 'anchor' ? '主播' : '观众'})`)
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

          // 第一路远端视频
          Column() {
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

  // ==================== RTC引擎初始化 ====================
  private async initAndSetupRtcEngine(): Promise<void> {
    if (!this.context) {
      promptAction.showToast({ message: '上下文未初始化', duration: 2000 });
      return;
    }

    try {
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

      // 设置用户角色为互动模式（主播和连麦观众都是互动角色）
      this.rtcEngine.setClientRole(AliRtcClientRole.AliRtcClientRoleInteractive);

      // 设置音频配置
      this.rtcEngine.setAudioProfile(
        AliRtcAudioProfile.AliRtcHighQualityMode,
        AliRtcAudioScenario.AliRtcSceneMusicMode
      );

      // 设置采集管线缩放模式
      this.rtcEngine.setCapturePipelineScaleMode(AliRtcCapturePipelineScaleMode.AliRtcCapturePipelineScaleModePost);

      // 设置视频编码参数
      const videoConfig: AliRtcVideoEncoderConfiguration = new AliRtcVideoEncoderConfiguration();
      videoConfig.dimensions = new AliRtcVideoDimensions();
      videoConfig.dimensions.width = 720;
      videoConfig.dimensions.height = 1280;
      videoConfig.frameRate = 20;
      videoConfig.bitrate = 1200;
      videoConfig.keyFrameInterval = 2000;
      videoConfig.orientationMode = AliRtcVideoEncoderOrientationMode.AliRtcVideoEncoderOrientationModeAdaptive;
      videoConfig.min_bitrate = 0;
      videoConfig.forceStrictKeyFrameInterval = 0;
      this.rtcEngine.setVideoEncoderConfiguration(videoConfig);

      // 发布本地音视频流
      this.rtcEngine.publishLocalAudioStream(true);
      this.rtcEngine.publishLocalVideoStream(true);

      // 设置默认订阅远端音视频流
      this.rtcEngine.setDefaultSubscribeAllRemoteAudioStreams(true);
      this.rtcEngine.subscribeAllRemoteAudioStreams(true);
      this.rtcEngine.setDefaultSubscribeAllRemoteVideoStreams(true);
      this.rtcEngine.subscribeAllRemoteVideoStreams(true);

      console.info('RTC引擎初始化完成');
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
      this.hasJoined = false;
      this.showPreview = false;
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
        const str = `设备异常: ${deviceType} ${exceptionType} ${msg}`;
        promptAction.showToast({ message: str, duration: 3000 });
      }
    );

    // 远端用户上线通知
    this.rtcEngineEventListener.onRemoteUserOnline((uid: string, elapsed: boolean) => {
      console.info(`远端用户上线: uid=${uid}, elapsed=${elapsed}`);
      const roleText = this.role === 'anchor' ? '观众' : '主播/观众';
      promptAction.showToast({ message: `${roleText} ${uid} 加入了`, duration: 2000 });
    });

    // 远端用户下线通知
    this.rtcEngineEventListener.onRemoteUserOffline((uid: string, reason: AliRtcUserOfflineReason) => {
      console.info(`远端用户下线: uid=${uid}, reason=${reason}`);
      this.removeAllRemoteVideo(uid);
      promptAction.showToast({ message: `用户 ${uid} 离开了`, duration: 2000 });
    });

    // 远端轨道可用通知 - 核心连麦逻辑
    this.rtcEngineEventListener.onRemoteTrackAvailableNotify((userId: string, audioTrack: AliRtcAudioTrack,
      videoTrack: AliRtcVideoTrack) => {
      console.info(`远端轨道可用: uid=${userId}, audioTrack=${audioTrack}, videoTrack=${videoTrack}`);

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
    });

    // 被踢出频道通知
    this.rtcEngineEventListener.onBye((code: number) => {
      console.info(`被踢出频道: code=${code}`);
      const msg = `onBye code: ${code}`;
      promptAction.showToast({ message: msg, duration: 2000 });
      this.destroyRtcEngine();
    });

    // 旁路转推状态变化回调（主播专用）
    if (this.role === 'anchor') {
      this.rtcEngineEventListener.onPublishLiveStreamStateChanged(
        (streamUrl: string, state: number, errCode: number) => {
          console.info(`旁路转推状态变化: url=${streamUrl}, state=${state}, errCode=${errCode}`);
          const msg = `旁路状态: state=${state} err=${errCode}`;
          promptAction.showToast({ message: msg, duration: 2000 });
        }
      );

      this.rtcEngineEventListener.onPublishLiveTaskStatusChanged((streamUrl: string, status: number) => {
        console.info(`旁路任务状态变化: url=${streamUrl}, status=${status}`);
        const msg = `旁路任务: status=${status}`;
        promptAction.showToast({ message: msg, duration: 2000 });
      });
    }

    // 设置事件监听器
    this.rtcEngine.setRtcEngineEventListener(this.rtcEngineEventListener);
  }

  // ==================== 本地视频设置 ====================
  private setupLocalVideo(): void {
    if (!this.context || !this.rtcEngine) {
      console.error('Context或RTC引擎未初始化');
      return;
    }

    try {
      const surfaceId = this.xcomponentController.getXComponentSurfaceId();
      console.info('获取到本地视频surfaceId:', surfaceId);

      this.localVideoCanvas = new AliRtcVideoCanvas();
      this.localVideoCanvas.surfaceId = surfaceId;
      this.localVideoCanvas.renderMode = AliRtcRenderMode.AliRtcRenderModeAuto;
      this.localVideoCanvas.mirrorMode = AliRtcRenderMirrorMode.AliRtcRenderMirrorModeAllMirror;

      console.info('本地视频画布设置完成');
      this.startPreview()

    } catch (error) {
      console.error('设置本地视频失败:', error);
    }
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
      this.rtcEngine.setRemoteViewConfig(stream.canvas, this.componentController, stream.uid, stream.videoTrack);

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
      if (this.localVideoCanvas) {
        this.rtcEngine.setLocalViewConfig(
          this.localVideoCanvas,
          this.componentController,
          AliRtcVideoTrack.AliRtcVideoTrackCamera
        );
      }

      // 开始预览
      this.rtcEngine.startPreview();
      this.showPreview = true;

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
      const displayName = this.role === 'anchor' ? '主播示例' : '连麦观众示例';
      const result = this.rtcEngine.joinChannelWithToken(base64Token, '', '', displayName);
      console.info('加入频道调用结果:', result);

      this.hasJoined = true;

    } catch (error) {
      console.error('加入频道失败:', error);
      promptAction.showToast({ message: `加入频道失败: ${error}`, duration: 3000 });
    }
  }

  // ==================== 跨频道订阅功能（主播PK演示）====================
  /**
   * 开始跨频道订阅
   * 模拟主播PK场景：订阅另一个频道中指定用户的音视频流
   */
  private async startCrossChannelSubscribe(): Promise<void> {
    if (!this.rtcEngine) {
      promptAction.showToast({ message: 'RTC引擎未初始化', duration: 2000 });
      return;
    }

    if (!this.peerChannelId || this.peerChannelId.trim().length === 0) {
      promptAction.showToast({ message: '请输入目标频道ID', duration: 2000 });
      return;
    }

    if (!this.peerUid || this.peerUid.trim().length === 0) {
      promptAction.showToast({ message: '请输入目标用户ID', duration: 2000 });
      return;
    }

    try {
      console.info(`开始跨频道订阅: channelId=${this.peerChannelId}, uid=${this.peerUid}`);

      // 调用跨频道订阅接口
      const ret = this.rtcEngine.subscribeRemoteDestChannelStream(
        this.peerChannelId,                              // 目标频道
        this.peerUid,                                    // 目标用户
        AliRtcVideoTrack.AliRtcVideoTrackCamera,        // 订阅相机流
        AliRtcAudioTrack.AliRtcAudioTrackMic,           // 订阅麦克风流
        true                                             // 开始订阅
      );

      if (ret === 0) {
        this.isSubscribingPeer = true;
        promptAction.showToast({ 
          message: `开始PK订阅: ${this.peerChannelId}/${this.peerUid}`, 
          duration: 2000 
        });
        console.info('跨频道订阅请求成功');
      } else {
        promptAction.showToast({ message: `跨频道订阅失败, ret=${ret}`, duration: 2000 });
        console.error(`跨频道订阅失败, ret=${ret}`);
      }

    } catch (error) {
      console.error('跨频道订阅异常:', error);
      promptAction.showToast({ message: '跨频道订阅异常', duration: 2000 });
    }
  }

  /**
   * 停止跨频道订阅
   */
  private async stopCrossChannelSubscribe(): Promise<void> {
    if (!this.rtcEngine) {
      return;
    }

    if (!this.peerChannelId || !this.peerUid) {
      return;
    }

    try {
      console.info(`停止跨频道订阅: channelId=${this.peerChannelId}, uid=${this.peerUid}`);

      // 取消订阅
      const ret = this.rtcEngine.subscribeRemoteDestChannelStream(
        this.peerChannelId,
        this.peerUid,
        AliRtcVideoTrack.AliRtcVideoTrackNo,            // 不订阅视频
        AliRtcAudioTrack.AliRtcAudioTrackNo,            // 不订阅音频
        false                                            // 停止订阅
      );

      console.info(`停止跨频道订阅结果: ret=${ret}`);

      // 移除远端画面
      this.removeAllRemoteVideo(this.peerUid);

      this.isSubscribingPeer = false;
      promptAction.showToast({ message: '已停止PK订阅', duration: 2000 });

    } catch (error) {
      console.error('停止跨频道订阅异常:', error);
      promptAction.showToast({ message: '停止订阅异常', duration: 2000 });
    }
  }

  // ==================== CDN旁路转推功能（主播专用）====================
  /**
   * 开始旁路转推到CDN
   */
  private async startLiveStreaming(): Promise<void> {
    if (!this.rtcEngine) {
      promptAction.showToast({ message: 'RTC引擎未初始化', duration: 2000 });
      return;
    }

    if (!this.streamUrl || this.streamUrl.trim().length === 0) {
      promptAction.showToast({ message: 'CDN URL不能为空', duration: 2000 });
      return;
    }

    try {
      // 创建旁路转推参数
      const transcodingParam: AliRtcLiveTranscodingParam = new AliRtcLiveTranscodingParam();

      // 调用 SDK 开始旁路转推
      const ret = this.rtcEngine.startPublishLiveStream(this.streamUrl, transcodingParam);

      if (ret === 0) {
        this.isPublishingLive = true;
        this.currentStreamUrl = this.streamUrl;
        promptAction.showToast({ message: '开始旁路到CDN', duration: 2000 });
        console.info('开始旁路转推成功: ' + this.streamUrl);
      } else {
        promptAction.showToast({ message: '开始旁路失败, ret=' + ret, duration: 2000 });
        console.error('开始旁路转推失败, ret=' + ret);
      }

    } catch (error) {
      console.error('开始旁路转推异常:', error);
      promptAction.showToast({ message: '开始旁路异常', duration: 2000 });
    }
  }

  /**
   * 停止旁路转推
   */
  private async stopLiveStreaming(): Promise<void> {
    if (!this.rtcEngine) {
      return;
    }

    if (!this.isPublishingLive || !this.currentStreamUrl) {
      return;
    }

    try {
      const streamUrl = this.currentStreamUrl;
      const ret = this.rtcEngine.stopPublishLiveStream(streamUrl);

      console.info(`停止旁路转推: url=${streamUrl}, ret=${ret}`);

      this.isPublishingLive = false;
      this.currentStreamUrl = undefined;

      promptAction.showToast({ message: '停止旁路', duration: 2000 });

    } catch (error) {
      console.error('停止旁路转推异常:', error);
      promptAction.showToast({ message: '停止旁路异常', duration: 2000 });
    }
  }

  // ==================== 结果处理 ====================
  private handleJoinResult(resultCode: number, channel: string): void {
    const roleText = this.role === 'anchor' ? '主播' : '连麦观众';
    const resultText = resultCode === 0
      ? `${roleText}加入 ${channel} 成功`
      : `${roleText}加入 ${channel} 失败，error: ${resultCode}`;

    promptAction.showToast({ message: resultText, duration: 2000 });

    // 更新按钮文本
    if (resultCode === 0) {
      this.hasJoined = true;
    }
  }

  // ==================== 清理资源 ====================
  private destroyRtcEngine(): void {
    if (this.rtcEngine) {
      try {
        // 离开频道前先停止跨频道订阅
        if (this.isSubscribingPeer) {
          this.stopCrossChannelSubscribe();
        }

        // 离开频道前先停止旁路
        if (this.isPublishingLive) {
          this.stopLiveStreaming();
        }

        if (this.hasJoined) {
          this.rtcEngine.stopPreview();
          this.rtcEngine.leaveChannel();
        }

        // 销毁引擎
        this.rtcEngine = undefined;
        this.rtcEngineEventListener = undefined;

        promptAction.showToast({ message: '离开频道', duration: 2000 });
      } catch (error) {
        console.error('销毁引擎失败:', error);
      }
    }

    // 清理远端视频
    this.remoteVideoStreams = [];

    // 重置状态
    this.showPreview = false;
    this.hasJoined = false;
    this.isPublishingLive = false;
    this.currentStreamUrl = undefined;
    this.isSubscribingPeer = false;
    this.localVideoCanvas = undefined;
  }

  aboutToDisappear(): void {
    this.destroyRtcEngine();
  }
}
