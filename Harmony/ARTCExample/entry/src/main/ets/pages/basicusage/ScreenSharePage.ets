import {
  AliRtcEngine,
  AliRtcVideoCanvas,
  AliRtcVideoTrack,
  AliRtcXComponentController,
  AliRtcVideoEncoderConfiguration,
  AliRtcEngineEventListener,
  AliRtcChannelProfile,
  AliRtcClientRole,
  AliRtcAudioProfile,
  AliRtcAudioScenario,
  AliRtcVideoEncoderOrientationMode,
  AliRtcVideoDimensions,
  AliRtcRenderMode,
  AliRtcRenderMirrorMode,
  AliRtcUserOfflineReason,
  AliRtcAudioTrack,
  AliRtcLocalDeviceType,
  AliRtcLocalDeviceExceptionType,
  AliRtcConnectionStatus,
  AliRtcConnectionStatusChangeReason,
  AliRtcStats,
  AliRtcCapturePipelineScaleMode
} from "@aliyun_video_cloud/alivcsdk_artc";
import { CustomTitle } from "../../common/components/CustomTitle"
import { common } from "@kit.AbilityKit";
import { prompt, promptAction } from "@kit.ArkUI";
import { RemoteVideoStream } from "../../common/Constants"
import { ARTCTokenHelper } from '../../common/keycenter/ARTCTokenHelper';
import { GlobalConfig } from '../../common/keycenter/GlobalConfig';

@Entry
@Component
export struct ScreenSharePage {
  // 页面状态变量
  @State isRoomJoined: boolean = false
  @State channelId: string = Date.now().toString().slice(-6);
  @State showPreview: boolean = false;
  @State isPublishLocalVideo: boolean = true;
  // 屏幕共享相关状态
  @State screenShareModeIndex: number = 3; // 默认选择"All"
  @State selectedScreenShareMode: string = 'All';
  @State screenShareEncoderConfig: ScreenShareEncoderConfig = {
    width: 0,
    height: 0,
    fps: 5,
    bitrate: 512,
    gop: 0,
    forceGOP: false
  };
  // 视频流管理
  @State remoteVideoStreams: RemoteVideoStream[] = [];
  // RTC引擎相关
  private rtcEngine: AliRtcEngine | undefined;
  private context: common.Context | undefined;
  private localXComponentController: XComponentController = new XComponentController();
  private localVideoCanvas: AliRtcVideoCanvas | undefined;
  private componentController: AliRtcXComponentController = new AliRtcXComponentController();
  private aliRtcScreenShareConfig: AliRtcVideoEncoderConfiguration | undefined;
  private rtcEventListener?: AliRtcEngineEventListener;

  // 页面生命周期
  async aboutToAppear(): Promise<void> {
    this.context = getContext() as common.Context;

    // 初始化屏幕共享编码配置
    this.aliRtcScreenShareConfig = new AliRtcVideoEncoderConfiguration();
    this.updateScreenShareEncoderConfig();
  }

  aboutToDisappear(): void {
    this.leaveChannelAndCleanup();
  }

  build() {
    NavDestination() {
      Column() {
        CustomTitle({
          titleText: '屏幕共享',
        })

        Scroll() {
          Column() {
            Text('如果要和其他用户进行通话，需要加入到同一个频道里，既保证双方的ChannelID相同。')
              .fontSize(14)
              .fontColor('#666')
              .width('100%')

          // 频道ID输入
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
          .margin({ top: 20 })
          .height(50)

          // 推送相机流开关
          Row() {
            Text("推送相机流")
              .fontSize(16)
              .fontColor('#636363')
              .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.isPublishLocalVideo })
              .onChange((isOn: boolean) => {
                this.isPublishLocalVideo = isOn;
              })
          }
          .width('100%')
          .height(36)
          .borderRadius(4)
          .margin({ top: 8 })

          // 加入/离开房间按钮
          Text(this.isRoomJoined ? '挂断' : '加入房间')
            .textAlign(TextAlign.Center)
            .fontSize(16)
            .backgroundColor('#3295fb')
            .width('95%')
            .height(48)
            .margin({
              top: 14, left: 10,
              right: 10
            })
            .onClick(async () => {
              await this.handleJoinRoom();
            })

          // 屏幕共享模式选择
          Row() {
            Text("屏幕共享模式")
              .fontSize(16)
              .fontColor('#636363')
              .layoutWeight(0.8)

            Select([{ value: 'None' },
              { value: 'Only Video' },
              { value: 'Only Audio' },
              { value: 'All' }])
              .selected(this.screenShareModeIndex)
              .value(this.selectedScreenShareMode)
              .font({ size: 16 })
              .fontColor('#333')
              .backgroundColor('#fff')
              .onSelect((index: number, text?: string | undefined) => {
                this.screenShareModeIndex = index;
                if (text) {
                  this.selectedScreenShareMode = text;
                }
              })
              .layoutWeight(1.2)
              .margin({ right: 8 })
          }
          .width('100%')
          .height(36)
          .borderRadius(4)
          .margin({ top: 8 })

          // 分辨率设置
          Row() {
            Text("分辨率:")
              .fontSize(16)
              .fontColor('#333')
              .width(80)
            TextInput({ text: this.screenShareEncoderConfig.width.toString() })
              .backgroundColor('#fff')
              .fontColor('#333')
              .border({
                width: 1,
                color: '#ddd',
                radius: 4
              })
              .onChange((text: string) => {
                const width = parseInt(text);
                if (!isNaN(width) && width > 0) {
                  this.screenShareEncoderConfig.width = width;
                  this.updateScreenShareEncoderConfig();
                }
              })
              .layoutWeight(1)
            Text('X')
            TextInput({ text: this.screenShareEncoderConfig.height.toString() })
              .layoutWeight(1)
              .backgroundColor('#fff')
              .fontColor('#333')
              .border({
                width: 1,
                color: '#ddd',
                radius: 4
              })
              .onChange((text: string) => {
                const height = parseInt(text);
                if (!isNaN(height) && height > 0) {
                  this.screenShareEncoderConfig.height = height;
                  this.updateScreenShareEncoderConfig();
                }
              })
          }
          .margin({ top: 6 })
          .height(50)

          // 帧率设置
          Row() {
            Text('帧率:')
              .fontSize(16)
              .fontColor('#333')
              .width(80)

            TextInput({
              text: this.screenShareEncoderConfig.fps.toString()
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
                const fps = parseInt(text);
                if (!isNaN(fps) && fps > 0) {
                  this.screenShareEncoderConfig.fps = fps;
                  this.updateScreenShareEncoderConfig();
                }
              })
          }
          .margin({ top: 6 })
          .height(50)

          // 码率设置
          Row() {
            Text('码率:')
              .fontSize(16)
              .fontColor('#333')
              .width(80)

            TextInput({
              text: this.screenShareEncoderConfig.bitrate.toString()
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
                const bitrate = parseInt(text);
                if (!isNaN(bitrate) && bitrate > 0) {
                  this.screenShareEncoderConfig.bitrate = bitrate;
                  this.updateScreenShareEncoderConfig();
                }
              })
          }
          .margin({ top: 6 })
          .height(50)

          // GOP设置
          Row() {
            Text('GOP:')
              .fontSize(16)
              .fontColor('#333')
              .width(80)

            TextInput({
              text: this.screenShareEncoderConfig.gop.toString()
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
                const gop = parseInt(text);
                if (!isNaN(gop) && gop >= 0) {
                  this.screenShareEncoderConfig.gop = gop;
                  this.updateScreenShareEncoderConfig();
                }
              })

            Text("强制GOP")
              .margin({ left: 5 })
            Toggle({ type: ToggleType.Switch, isOn: this.screenShareEncoderConfig.forceGOP })
              .onChange((isOn: boolean) => {
                this.screenShareEncoderConfig.forceGOP = isOn;
                this.updateScreenShareEncoderConfig();
              })
          }
          .margin({ top: 6 })
          .height(50)

          // 屏幕共享控制按钮
          Row() {
            Button('停止屏幕共享')
              .type(ButtonType.Normal)
              .backgroundColor('#590ce4')
              .layoutWeight(1)
              .onClick(() => {
                this.stopScreenShare();
              })
            Blank()
              .width(10)
            Button('开始屏幕共享')
              .type(ButtonType.Normal)
              .backgroundColor('#590ce4')
              .layoutWeight(1)
              .onClick(() => {
                this.startScreenShare();
              })
          }
          .width('100%')
          .margin({ top: 6 })

          // 视频预览区域
          if (this.showPreview) {
            Column() {
              this.buildLocalVideoView()
            }
            .width('100%')
            .height('auto')
            .justifyContent(FlexAlign.Start)
            .alignItems(HorizontalAlign.Start)
          }
        }
        .width('100%')
      }
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 12, right: 12, bottom: 12 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }
  .hideTitleBar(true)
}

  @Builder
  buildLocalVideoView() {
    Scroll() {
      Column() {
        if (!this.shouldShowGridLayout()) {
          Row() {
            Column() {
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
            .layoutWeight(1)
          }
          .height('180vp')
          .width('100%')
        } else {
          Column() {
            Row() {
              Column() {
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
              .layoutWeight(1)

              Blank()
                .width(10)

              Column() {
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
            }
            .height('180vp')

            if (this.remoteVideoStreams.length > 1) {
              Column() {
                // 视频渲染区域
                XComponent({
                  id: `remote_${this.remoteVideoStreams[1].uid}_${this.remoteVideoStreams[1].videoTrack}`,
                  type: 'surface',
                  controller: this.remoteVideoStreams[1].xcomponentController
                })
                  .width('100%')
                  .height('100%')
                  .onLoad(() => {
                    this.setupRemoteVideo(this.remoteVideoStreams[1]);
                  })
              }
              .backgroundColor('#000')
              .height('180vp')
              .layoutWeight(1)
            }
          }
          .height('100%')
        }
      }
      .width('100%')
      .height('360')
      .margin({ top: 6 })
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)
    }.height('180vp')
  }

  // ===================== 核心逻辑方法 =====================

  // 处理加入/离开房间
  private async handleJoinRoom(): Promise<void> {
    if (this.isRoomJoined) {
      this.leaveChannelAndCleanup();
      this.isRoomJoined = false;
      prompt.showToast({ message: 'Leave Channel', duration: 2000 });
      return;
    }

    try {
      // 验证必要参数
      if (!this.channelId.trim()) {
        prompt.showToast({ message: '请输入频道ID', duration: 2000 });
        return;
      }

      // 初始化RTC引擎
      await this.initAndSetupRtcEngine();

      // 开始本地预览
      this.startPreview();

      // 加入频道
      await this.joinChannel();

      this.isRoomJoined = true;
      console.info('成功加入房间');

    } catch (error) {
      console.error('加入房间失败:', error);
      prompt.showToast({
        message: `加入房间失败: ${error}`,
        duration: 3000
      });
      this.isRoomJoined = false;
    }
  }



  // 设置本地视频
  private setupLocalVideo(): void {
    if (!this.context || !this.rtcEngine) {
      console.error('Context或RTC引擎未初始化');
      return;
    }

    try {
      let surfaceId = this.localXComponentController.getXComponentSurfaceId();
      console.info('获取到本地视频surfaceId:', surfaceId);

      this.localVideoCanvas = new AliRtcVideoCanvas();
      this.localVideoCanvas.surfaceId = surfaceId;
      this.localVideoCanvas.renderMode = AliRtcRenderMode.AliRtcRenderModeAuto;
      this.localVideoCanvas.mirrorMode = AliRtcRenderMirrorMode.AliRtcRenderMirrorModeAllMirror;

      this.startPreview()
      console.info('本地视频画布设置完成');

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
      if (!stream.surfaceId) {
        console.warn(`获取surfaceId失败: ${stream.uid}_${stream.videoTrack}`);
        return;
      }

      // 配置视频画布
      if (!stream.canvas) {
        stream.canvas = new AliRtcVideoCanvas();
      }

      stream.canvas.surfaceId = stream.surfaceId;
      stream.canvas.renderMode = AliRtcRenderMode.AliRtcRenderModeAuto;
      stream.canvas.mirrorMode = AliRtcRenderMirrorMode.AliRtcRenderMirrorModeAllNoMirror;

      // 关键：设置远端视图配置
      this.rtcEngine.setRemoteViewConfig(
        stream.canvas,
        this.componentController,
        stream.uid,
        stream.videoTrack
      );
      // 确保订阅该视频流
      if (stream.videoTrack === AliRtcVideoTrack.AliRtcVideoTrackCamera) {
        this.rtcEngine.subscribeRemoteVideoStream(stream.uid, stream.videoTrack, true);
      } else if (stream.videoTrack === AliRtcVideoTrack.AliRtcVideoTrackScreen) {
        // 特别处理屏幕共享流
        this.rtcEngine.subscribeRemoteVideoStream(stream.uid, stream.videoTrack, true);
        console.info(`已订阅屏幕共享流: ${stream.uid}`);
      }

    } catch (error) {
    }
  }

  // 查看远端视频
  private viewRemoteVideo(uid: string, videoTrack: AliRtcVideoTrack): void {

    // 检查是否已存在相同的流
    const existingIndex = this.remoteVideoStreams.findIndex(
      s => s.uid === uid && s.videoTrack === videoTrack
    );

    if (existingIndex >= 0) {
      return;
    }

    // 创建新的远端视频流对象
    const newStream: RemoteVideoStream = {
      uid,
      videoTrack,
      canvas: new AliRtcVideoCanvas(),
      xcomponentController: new XComponentController(),
      surfaceId: ''
    };

    // 添加到数组并触发UI更新
    this.remoteVideoStreams = [...this.remoteVideoStreams, newStream];


    // 立即尝试设置视频
    setTimeout(() => {
      this.setupRemoteVideo(newStream);
    }, 100);
  }

  // 移除远端视频
  private removeRemoteVideo(uid: string, videoTrack: AliRtcVideoTrack): void {

    // 先停止订阅
    if (this.rtcEngine) {
      try {
        this.rtcEngine.subscribeRemoteVideoStream(uid, videoTrack, false);
      } catch (error) {
        console.error('停止订阅失败:', error);
      }
    }

    // 从数组中移除
    this.remoteVideoStreams = this.remoteVideoStreams.filter(
      s => !(s.uid === uid && s.videoTrack === videoTrack)
    );

  }

  // 移除用户的所有视频
  private removeAllRemoteVideo(uid: string): void {
    console.info(`移除用户所有视频: ${uid}`);

    // 从数组中移除该用户的所有流
    this.remoteVideoStreams = this.remoteVideoStreams.filter(s => s.uid !== uid);
    console.info(`移除用户所有视频成功: ${uid}`);
  }

  // 初始化并设置RTC引擎
  private async initAndSetupRtcEngine(): Promise<void> {
    if (this.rtcEngine) {
      return;
    }

    if (!this.context) {
      throw new Error('Context未初始化');
    }

    try {
      // 创建RTC引擎实例
      this.rtcEngine = AliRtcEngine.getInstance('', this.context);
      if (this.rtcEngine === undefined) {
        promptAction.showToast({ message: 'RTC引擎未初始化成功', duration: 2000 });
        return;
      }
      // 设置频道模式
      this.rtcEngine.setChannelProfile(AliRtcChannelProfile.AliRtcInteractiveLive);

      // 设置用户角色
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
      this.rtcEngine.publishLocalVideoStream(this.isPublishLocalVideo);

      // 设置默认订阅所有远端音视频流
      this.rtcEngine.setDefaultSubscribeAllRemoteAudioStreams(true);
      this.rtcEngine.setDefaultSubscribeAllRemoteVideoStreams(true);

      // 明确订阅所有远端音视频流
      this.rtcEngine.subscribeAllRemoteAudioStreams(true);
      this.rtcEngine.subscribeAllRemoteVideoStreams(true);

      // 设置事件监听器
      this.setupEventListeners();

      console.info('RTC引擎初始化完成');

    } catch (error) {
      console.error('RTC引擎初始化失败:', error);
    }
  }

  // 设置事件监听器
  private setupEventListeners(): void {
    if (!this.rtcEngine) {
      return;
    }

    if (!this.rtcEventListener) {
      this.rtcEventListener = new AliRtcEngineEventListener();

      this.rtcEventListener.onJoinChannel((resultCode: number, channel: string, elapsed: string) => {
        console.info(`加入频道结果: result=${resultCode}, channel=${channel}, elapsed=${elapsed}`);

        const resultText = resultCode === 0
          ? `Join ${channel} Success`
          : `Join ${channel} Failed!，error: ${resultCode}`;

        prompt.showToast({
          message: resultText,
          duration: 2000
        });

      })

      this.rtcEventListener.onLeaveChannel((resultCode: number) => {
        console.info(`离开频道结果: result=${resultCode}`);
        prompt.showToast({ message: 'Leave Channel', duration: 2000 });
      })

      this.rtcEventListener.onConnectionStatusChange((status: number, reason: number) => {
        console.info(`连接状态变更: status=${status}, reason=${reason}`);
        if (status === AliRtcConnectionStatus.AliRtcConnectionFailed) {
          prompt.showToast({
            message: '连接失败，请检查网络',
            duration: 3000
          });
        }
      })

      this.rtcEventListener.onRemoteUserOnline((userId: string, elapsed: boolean) => {
        console.info(`远端用户上线: userId=${userId}, elapsed=${elapsed}`);
      })

      this.rtcEventListener.onRemoteUserOffline((userId: string, reason: AliRtcUserOfflineReason) => {
        console.info(`远端用户下线: userId=${userId}, reason=${reason}`);
        this.removeAllRemoteVideo(userId);
      })

      this.rtcEventListener.onRemoteTrackAvailableNotify((userId: string, audioTrack: AliRtcAudioTrack,
        videoTrack: AliRtcVideoTrack) => {
        console.info(`远端音视频流可用: userId=${userId}, audioTrack=${audioTrack}, videoTrack=${videoTrack}`);

        if (videoTrack === AliRtcVideoTrack.AliRtcVideoTrackCamera) {
          this.viewRemoteVideo(userId, AliRtcVideoTrack.AliRtcVideoTrackCamera);
          this.removeRemoteVideo(userId, AliRtcVideoTrack.AliRtcVideoTrackScreen);
        } else if (videoTrack === AliRtcVideoTrack.AliRtcVideoTrackScreen) {
          this.viewRemoteVideo(userId, AliRtcVideoTrack.AliRtcVideoTrackScreen);
          this.removeRemoteVideo(userId, AliRtcVideoTrack.AliRtcVideoTrackCamera);
        } else if (videoTrack === AliRtcVideoTrack.AliRtcVideoTrackBoth) {
          this.viewRemoteVideo(userId, AliRtcVideoTrack.AliRtcVideoTrackCamera);
          this.viewRemoteVideo(userId, AliRtcVideoTrack.AliRtcVideoTrackScreen);
        } else if (videoTrack === AliRtcVideoTrack.AliRtcVideoTrackNo) {
          this.removeAllRemoteVideo(userId);
        }
      });


      this.rtcEventListener.onLocalDeviceException((deviceType: AliRtcLocalDeviceType, exceptionType: AliRtcLocalDeviceExceptionType,
        msg: string) => {
        console.error(`本地设备异常: deviceType=${deviceType}, exceptionType=${exceptionType}, msg=${msg}`);
        prompt.showToast({
          message: `设备异常: ${msg}`,
          duration: 3000
        });
      })

      this.rtcEventListener.onBye((code: number) => {
        console.info(`被服务器踢出: code=${code}`);
        prompt.showToast({
          message: `被服务器踢出: ${code}`,
          duration: 3000
        });
        this.leaveChannelAndCleanup();
      });
    }

    this.rtcEngine.setRtcEngineEventListener(this.rtcEventListener);
  }

  // 开始本地预览
  private startPreview(): void {
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

  // 加入频道
  private async joinChannel(): Promise<void> {
    if (!this.rtcEngine || !this.channelId.trim()) {
      prompt.showToast({
        message: '频道ID不能为空',
        duration: 2000
      });
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

      const result = this.rtcEngine.joinChannelWithToken(base64Token, '', '', '屏幕共享用户');
      console.info('加入频道调用结果:', result);

    } catch (error) {
      console.error('加入频道失败:', error);
    }
  }

  // 开始屏幕共享
  private startScreenShare(): void {
    if (!this.rtcEngine) {
      prompt.showToast({ message: '请先加入房间', duration: 2000 });
      return;
    }

    try {
      // 更新屏幕共享编码配置
      if (this.aliRtcScreenShareConfig) {
        this.rtcEngine.setScreenShareEncoderConfiguration(this.aliRtcScreenShareConfig);
      }

      // 根据界面选择计算屏幕共享模式
      let mode: AliRtcScreenShareMode;
      switch (this.selectedScreenShareMode) {
        case 'None':
          mode = AliRtcScreenShareMode.AliRtcScreenShareNoneMode;
          break;
        case 'Only Video':
          mode = AliRtcScreenShareMode.AliRtcScreenShareOnlyVideoMode;
          break;
        case 'Only Audio':
          mode = AliRtcScreenShareMode.AliRtcScreenShareOnlyAudioMode;
          break;
        case 'All':
        default:
          mode = AliRtcScreenShareMode.AliRtcScreenShareAllMode;
          break;
      }

      // 开始屏幕共享
      this.rtcEngine.startScreenShare(mode);

      console.info(`开始屏幕共享，模式: ${this.selectedScreenShareMode}(${mode})`);

    } catch (error) {
      console.error('开始屏幕共享失败:', error);
    }
  }

  // 停止屏幕共享
  private stopScreenShare(): void {
    if (!this.rtcEngine) {
      return;
    }

    try {
      this.rtcEngine.stopScreenShare();
      console.info('停止屏幕共享');

    } catch (error) {
      console.error('停止屏幕共享失败:', error);
    }
  }

  // 更新屏幕共享编码配置
  private updateScreenShareEncoderConfig(): void {
    if (this.aliRtcScreenShareConfig) {
      this.aliRtcScreenShareConfig.dimensions.width = 720
      this.aliRtcScreenShareConfig.dimensions.height = 1080
      this.aliRtcScreenShareConfig.frameRate = this.screenShareEncoderConfig.fps;
      this.aliRtcScreenShareConfig.bitrate = this.screenShareEncoderConfig.bitrate;
      this.aliRtcScreenShareConfig.keyFrameInterval = this.screenShareEncoderConfig.gop;
      this.aliRtcScreenShareConfig.forceStrictKeyFrameInterval = this.screenShareEncoderConfig.forceGOP ? 1 : 0;

      console.info('更新屏幕共享编码配置:', this.screenShareEncoderConfig);
    }
  }

  // 离开频道并清理资源
  private leaveChannelAndCleanup(): void {
    if (this.rtcEngine) {
      try {
        // 如果屏幕共享正在发布，先停止
        this.rtcEngine.stopScreenShare();


        if (this.isRoomJoined) {
          this.rtcEngine.stopPreview();
          this.rtcEngine.leaveChannel();
        }
        this.rtcEngine = undefined;
      } catch (error) {
        console.error('销毁RTC引擎失败:', error);
      }
    }

    // 清理所有视频资源
    this.remoteVideoStreams = [];
    this.localVideoCanvas = undefined;
    this.aliRtcScreenShareConfig = undefined;
    this.isRoomJoined = false;
    this.showPreview = false;
  }



  // 判断是否显示网格布局
  private shouldShowGridLayout(): boolean {
    return this.showPreview && this.remoteVideoStreams.length > 0;
  }
}

// 屏幕共享编码配置类型
interface ScreenShareEncoderConfig {
  width: number;
  height: number;
  fps: number;
  bitrate: number;
  gop: number;
  forceGOP: boolean;
}

// 屏幕共享模式枚举
enum AliRtcScreenShareMode {
  /** 不共享音视频 */
  AliRtcScreenShareNoneMode = 0,
  /** 仅共享视频 */
  AliRtcScreenShareOnlyVideoMode = 1,
  /** 仅共享音频 */
  AliRtcScreenShareOnlyAudioMode = 2,
  /** 共享音视频 */
  AliRtcScreenShareAllMode = 3
}