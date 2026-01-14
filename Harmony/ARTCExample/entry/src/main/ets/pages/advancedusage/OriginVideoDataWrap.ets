import { CustomTitle } from "../../common/components/CustomTitle"
import {
  AliRtcEngine,
  AliRtcEngineEventListener,
  AliRtcVideoCanvas,
  AliRtcXComponentController,
  AliRtcVideoTrack,
  AliRtcChannelProfile,
  AliRtcClientRole,
  AliRtcRenderMode,
  AliRtcRenderMirrorMode,
  AliRtcAudioTrack
} from '@aliyun_video_cloud/alivcsdk_artc';
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { OriginVideoData } from 'libadvancedusage.so';
import { GlobalConfig } from '../../common/keycenter/GlobalConfig';
import { ARTCTokenHelper } from '../../common/keycenter/ARTCTokenHelper';

interface RemoteVideoStream {
  uid: string;
  videoTrack: AliRtcVideoTrack;
  xcomponentController: XComponentController;
  canvas: AliRtcVideoCanvas;
  surfaceId: string;
}

@Component
export struct OriginVideoDataWrap {
  @State AppId: string = '';
  @State AppKey: string = '';
  @State UserId: string = '';
  @State channelId: string = Date.now().toString().slice(-6);
  @State hasJoined: boolean = false;
  @State showPreview: boolean = false;
  @State isVideoEnabled: boolean = false;
  @State remoteVideos: RemoteVideoStream[] = [];
  private rtcEngine: AliRtcEngine | undefined;
  private nativeVideoData: OriginVideoData | undefined;
  private context: common.UIAbilityContext | undefined;
  private xcomponentController: XComponentController = new XComponentController();
  private aliRtcVideoCanvas: AliRtcVideoCanvas | undefined;
  private componentController: AliRtcXComponentController = new AliRtcXComponentController();
  private rtcEngineEventListener: AliRtcEngineEventListener | undefined;

  async aboutToAppear(): Promise<void> {
    this.context = getContext(this) as common.UIAbilityContext;
    await GlobalConfig.getInstance().init(this.context);
    await this.loadSettings();
    this.initRtcEngine();
  }

  async loadSettings(): Promise<void> {
    try {
      const globalConfig = GlobalConfig.getInstance();
      this.AppId = await globalConfig.getAppId();
      this.AppKey = await globalConfig.getAppKey();
      this.UserId = await globalConfig.getUserId();
    } catch (error) {
      console.error('Failed to load settings:', error);
    }
  }

  private initRtcEngine() {
    if (!this.context) {
      promptAction.showToast({ message: '上下文未初始化', duration: 2000 });
      return;
    }

    try {
      // 初始化RTC引擎
      this.rtcEngine = AliRtcEngine.getInstance('', this.context);
      if (!this.rtcEngine) {
        promptAction.showToast({ message: 'RTC引擎初始化失败', duration: 2000 });
        return;
      }

      // 设置事件监听器
      this.setupEventListeners();

      // 基本设置
      this.rtcEngine.setChannelProfile(AliRtcChannelProfile.AliRtcInteractiveLive);
      this.rtcEngine.setClientRole(AliRtcClientRole.AliRtcClientRoleInteractive);
      this.rtcEngine.publishLocalAudioStream(true);
      this.rtcEngine.publishLocalVideoStream(true);

      // 订阅远端音视频流
      this.rtcEngine.setDefaultSubscribeAllRemoteAudioStreams(true);
      this.rtcEngine.subscribeAllRemoteAudioStreams(true);
      this.rtcEngine.setDefaultSubscribeAllRemoteVideoStreams(true);
      this.rtcEngine.subscribeAllRemoteVideoStreams(true);

      // 初始化Native模块
      const nativeHandle: number | undefined = this.rtcEngine.getNativeHandle();
      if (nativeHandle !== undefined) {
        this.nativeVideoData = new OriginVideoData(nativeHandle);
        console.info('Native模块初始化成功');
      } else {
        promptAction.showToast({ message: '获取RTC引擎句柄失败', duration: 2000 });
      }

    } catch (error) {
      console.error('初始化RTC引擎失败:', error);
      promptAction.showToast({ message: `初始化失败: ${error}`, duration: 2000 });
    }
  }

  private setupEventListeners() {
    if (!this.rtcEngine) {
      return;
    }

    this.rtcEngineEventListener = new AliRtcEngineEventListener();

    // 加入频道结果回调
    this.rtcEngineEventListener.onJoinChannel((resultCode: number, channel: string) => {
      console.info(`加入频道结果: ${resultCode}, 频道: ${channel}`);
      if (resultCode === 0) {
        this.hasJoined = true;
        promptAction.showToast({ message: `加入频道 ${channel} 成功`, duration: 2000 });
      } else {
        promptAction.showToast({ message: `加入频道失败: ${resultCode}`, duration: 2000 });
      }
    });

    // 离开频道结果回调
    this.rtcEngineEventListener.onLeaveChannel(() => {
      this.hasJoined = false;
      this.showPreview = false;
      this.remoteVideos = [];
      promptAction.showToast({ message: '已离开频道', duration: 2000 });
    });

    // 远端轨道可用通知 - 核心逻辑
    this.rtcEngineEventListener.onRemoteTrackAvailableNotify(
      (userId: string, audioTrack: AliRtcAudioTrack, videoTrack: AliRtcVideoTrack) => {
        console.info(`远端轨道可用: uid=${userId}, videoTrack=${videoTrack}`);

        // 只处理摄像头视频流
        if (videoTrack === AliRtcVideoTrack.AliRtcVideoTrackCamera) {
          this.addRemoteVideo(userId, videoTrack);
        }
      }
    );

    // 远端用户下线通知
    this.rtcEngineEventListener.onRemoteUserOffline((uid: string) => {
      console.info(`远端用户下线: ${uid}`);
      this.removeRemoteVideo(uid);
    });

    this.rtcEngine.setRtcEngineEventListener(this.rtcEngineEventListener);
  }

  build() {
    NavDestination() {
      Column() {
        CustomTitle({
          titleText: '获取原始视频数据C++',
        })

        Scroll() {
          Column() {
          // 频道ID输入
          Row() {
            Text('频道ID:')
              .fontSize(16)
              .fontColor('#333')
              .width(80)

            TextInput({
              text: this.channelId
            })
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
              .onChange((text: string) => {
                this.channelId = text;
              })
          }
          .margin({ top: 10 })

          // 视频帧监听开关
          Row() {
            Text('视频帧监听:')
              .fontSize(16)
              .fontColor('#333')
              .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.isVideoEnabled })
              .onChange((isOn: boolean) => {
                this.handleVideoSwitch(isOn);
              })
          }
          .margin({ top: 10 })

          // 操作按钮
          Button(this.hasJoined ? '离开频道' : '加入频道')
            .width('80%')
            .backgroundColor(this.hasJoined ? '#FF6347' : '#3295fb')
            .fontColor('#fff')
            .margin({ top: 20 })
            .onClick(() => {
              if (this.hasJoined) {
                this.leaveChannel();
              } else {
                this.joinChannel();
              }
            })

          Row() {
            // 本地视频
            Column() {
              Text('本地摄像头')
                .fontSize(12)
                .fontColor('#666')
                .margin({ bottom: 4 })

              XComponent({
                id: 'local_video',
                type: 'surface',
                controller: this.xcomponentController
              })
                .width(180)
                .height(180)
                .borderRadius(8)
                .onLoad(() => {
                  this.setupLocalVideo();
                })
            }
            .margin({ right: 10 })

            if (this.remoteVideos.length > 0) {
              Column() {
                Text(`远端用户: ${this.remoteVideos[0].uid}`)
                  .fontSize(12)
                  .fontColor('#666')
                  .margin({ bottom: 4 })

                XComponent({
                  id: `remote_${this.remoteVideos[0].uid}`,
                  type: 'surface',
                  controller: this.remoteVideos[0].xcomponentController
                })
                  .width(180)
                  .height(180)
                  .borderRadius(8)
                  .onLoad(() => {
                    this.setupRemoteVideo(this.remoteVideos[0]);
                  })
              }
            } else {
              // 远端视频占位符
              Column() {
                Text('等待远端加入')
                  .fontSize(14)
                  .fontColor('#999')
              }
              .width(180)
              .height(180)
              .borderRadius(8)
              .backgroundColor('#f5f5f5')
              .justifyContent(FlexAlign.Center)
            }
          }
          .justifyContent(FlexAlign.Center)
          .margin({ top: 20 })
          .opacity(this.showPreview ? 1 : 0)

          }
          .padding(12)
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

  private setupLocalVideo() {
    if (!this.rtcEngine) {
      return;
    }

    try {
      const surfaceId = this.xcomponentController.getXComponentSurfaceId();
      this.aliRtcVideoCanvas = new AliRtcVideoCanvas();
      this.aliRtcVideoCanvas.surfaceId = surfaceId;
      this.aliRtcVideoCanvas.renderMode = AliRtcRenderMode.AliRtcRenderModeAuto;
      this.aliRtcVideoCanvas.mirrorMode = AliRtcRenderMirrorMode.AliRtcRenderMirrorModeAllMirror;
    } catch (error) {
      console.error('设置本地视频失败:', error);
    }
  }

  private startPreview() {
    if (!this.rtcEngine || !this.aliRtcVideoCanvas) {
      return;
    }

    try {
      this.rtcEngine.setLocalViewConfig(
        this.aliRtcVideoCanvas,
        this.componentController,
        AliRtcVideoTrack.AliRtcVideoTrackCamera
      );

      this.rtcEngine.startPreview();
      this.showPreview = true;
      console.info('本地预览已启动');
    } catch (error) {
      console.error('启动预览失败:', error);
      promptAction.showToast({ message: `启动预览失败: ${error}`, duration: 2000 });
    }
  }

  // 添加远端视频
  private addRemoteVideo(uid: string, videoTrack: AliRtcVideoTrack) {
    // 检查是否已存在
    const existingIndex = this.remoteVideos.findIndex(video => video.uid === uid);
    if (existingIndex >= 0) {
      console.info(`远端视频已存在: ${uid}`);
      return;
    }

    // 创建新的远端视频
    const newVideo: RemoteVideoStream = {
      uid,
      videoTrack,
      xcomponentController: new XComponentController(),
      canvas: new AliRtcVideoCanvas(),
      surfaceId: ''
    };

    this.remoteVideos.push(newVideo);
    console.info(`添加远端视频成功: ${uid}`);
  }

  // 设置远端视频
  private setupRemoteVideo(remoteVideo: RemoteVideoStream) {
    if (!this.rtcEngine) {
      return;
    }

    try {
      // 获取XComponent的surfaceId
      remoteVideo.surfaceId = remoteVideo.xcomponentController.getXComponentSurfaceId();
      console.info(`设置远端视频: ${remoteVideo.uid}, surfaceId: ${remoteVideo.surfaceId}`);

      // 配置视频画布
      remoteVideo.canvas.surfaceId = remoteVideo.surfaceId;
      remoteVideo.canvas.renderMode = AliRtcRenderMode.AliRtcRenderModeAuto;
      remoteVideo.canvas.mirrorMode = AliRtcRenderMirrorMode.AliRtcRenderMirrorModeAllNoMirror;

      // 设置远端视图配置
      this.rtcEngine.setRemoteViewConfig(
        remoteVideo.canvas,
        this.componentController,
        remoteVideo.uid,
        remoteVideo.videoTrack
      );

      console.info(`远端视频设置完成: ${remoteVideo.uid}`);
    } catch (error) {
      console.error(`设置远端视频失败 ${remoteVideo.uid}:`, error);
    }
  }

  // 移除远端视频
  private removeRemoteVideo(uid: string) {
    console.info(`移除远端视频: ${uid}`);
    this.remoteVideos = this.remoteVideos.filter(video => video.uid !== uid);
    console.info(`移除远端视频成功: ${uid}`);
  }

  private async joinChannel(): Promise<void> {
    if (!this.channelId.trim()) {
      promptAction.showToast({ message: '请输入频道ID', duration: 2000 });
      return;
    }

    if (!this.rtcEngine) {
      promptAction.showToast({ message: 'RTC引擎未初始化', duration: 2000 });
      return;
    }

    this.startPreview();

    try {
      // 使用 ARTCTokenHelper 生成 Token
      const timestamp = Math.floor(Date.now() / 1000) + 86400; // 24小时后过期
      const token = await ARTCTokenHelper.generateSingleParameterToken(
        this.AppId,
        this.AppKey,
        this.channelId,
        this.UserId,
        timestamp,
        ''
      );

      const result: number = this.rtcEngine.joinChannelWithToken(token, '', '', '视频原始数据测试');
      console.info('加入频道调用结果:', result);
    } catch (error) {
      const err = error as Error;
      console.error('加入频道失败:', err);
      promptAction.showToast({ message: `加入频道失败: ${err.message}`, duration: 2000 });
    }
  }

  private leaveChannel() {
    if (this.rtcEngine && this.hasJoined) {
      this.rtcEngine.leaveChannel();
      this.rtcEngine.stopPreview();
      promptAction.showToast({ message: '已离开频道', duration: 2000 });
    }
  }

  private handleVideoSwitch(isOn: boolean): void {
    if (this.nativeVideoData) {
      const result: number = this.nativeVideoData.enable(isOn);
      if (result === 0) {
        this.isVideoEnabled = isOn;
        promptAction.showToast({
          message: `视频帧监听${isOn ? '启用' : '禁用'}成功`,
          duration: 2000
        });
      } else {
        promptAction.showToast({
          message: `视频帧监听${isOn ? '启用' : '禁用'}失败: 错误码${result}`,
          duration: 2000
        });
        this.isVideoEnabled = false;
      }
    } else {
      promptAction.showToast({ message: 'Native模块未初始化', duration: 2000 });
      this.isVideoEnabled = false;
    }
  }

  aboutToDisappear() {
    this.leaveChannel();
    this.rtcEngine = undefined;
    this.nativeVideoData = undefined;
  }
}
