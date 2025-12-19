import { CustomTitle } from 'common/src/main/ets/components/CustomTitle';
import {
  AliRtcEngine,
  AliRtcVideoEncoderConfiguration,
  AliRtcEngineAuthInfo,
  AliRtcEngineEventListener,
  AliRtcChannelProfile,
  AliRtcClientRole,
  AliRtcAudioProfile,
  AliRtcAudioScenario,
  AliRtcVideoMirrorMode,
  AliRtcRotationMode,
  AliRtcVideoEncoderOrientationMode,
  AliRtcVideoTrack,
  AliRtcVideoCanvas,
  AliRtcRenderMode,
  AliRtcRenderMirrorMode,
  AliRtcXComponentController,
  AliRtcUserOfflineReason,
  AliRtcAudioTrack,
  AliRtcLocalDeviceType,
  AliRtcLocalDeviceExceptionType,
} from '@aliyun_video_cloud/alivcsdk_artc';
import common from '@ohos.app.ability.common';
import { prompt } from '@kit.ArkUI';
import { LightStorage } from 'common/src/main/ets/components/LightStorage';
import { SettingsData } from 'common/src/main/ets/common/Constants';
import { ARTCTokenHelper } from 'keycenter/src/main/ets/ARTCTokenHelper';

// 定义远端视频流信息类型
interface RemoteVideoStream {
  uid: string; // 用户ID
  videoTrack: AliRtcVideoTrack; // 流类型
  canvas: AliRtcVideoCanvas; // 画布对象
  surfaceId: string; // Surface视图
  xcomponentController: XComponentController; // XComponent控制器
}

@Entry
@Component
export struct VideoCall {
  // 基本状态
  @State initRoom: boolean = false
  @State AppId: string = '';
  @State AppKey: string = '';
  @State UserId: string = '';
  @State TimeStamp: number = 0;
  @State Nonce: string = '';
  @State Token: string = '';
  @State channelId: string = Date.now().toString().slice(-6);
  @State ShowPreview: boolean = false;
  // 远端视频流管理
  @State remoteVideoStreams: RemoteVideoStream[] = []
  @State gridColumns: number = 2 // 网格列数，根据视频数量动态调整
  private rtcEngine: AliRtcEngine | null | undefined;
  private context: common.Context | undefined;
  private xcomponentController: XComponentController = new XComponentController();
  private aliRtcVideoCanvas: AliRtcVideoCanvas | undefined;
  private componentController: AliRtcXComponentController = new AliRtcXComponentController()

  async aboutToAppear(): Promise<void> {
    this.context = getContext() as common.Context;
    this.generateTimestamp();
    this.Nonce = 'nonce_' + Date.now();

    try {
      const data = await LightStorage.instance?.getObject<SettingsData>('settingData');
      if (data) {
        this.AppId = data.appId!;
        this.AppKey = data.appKey!;
        this.UserId = data.userId!;
      } else {
        // 设置默认值
        this.UserId = 'user_' + Math.floor(Math.random() * 10000);
      }
    } catch (error) {
      console.error('Failed to load settings:', error);
      this.UserId = 'user_' + Math.floor(Math.random() * 10000);
    }
  }

  aboutToDisappear(): void {
    this.leaveChannelAndCleanup();
  }

  build() {
    NavDestination() {
      Column() {
        CustomTitle({
          titleText: '实现视频通话',
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

          Text(this.initRoom ? '挂断' : '加入房间')
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
              await this.handleJoinRoom();
            })

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
            controller: this.xcomponentController
          })
            .width('100')
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

  @Builder
  buildRemoteVideoView(stream: RemoteVideoStream, height: string) {
    Column() {
      // 用户ID和流类型标签
      Row() {
        Text(stream.uid)
          .fontSize(12)
          .fontColor(Color.White)

        Text(this.getTrackTypeText(stream.videoTrack))
          .fontSize(10)
          .fontColor('#aaa')
          .margin({ left: 8 })
          .backgroundColor('#ff6b6b')
          .padding(2)
          .borderRadius(2)
      }
      .backgroundColor('#80000000')
      .padding(4)
      .borderRadius(4)
      .position({ x: 8, y: 8 })
      .zIndex(1)

      // 视频渲染区域
      XComponent({
        id: `remote_${stream.uid}_${stream.videoTrack}`,
        type: 'surface',
        controller: stream.xcomponentController
      })
        .width('100%')
        .height('100%')
        .onLoad(() => {
          this.setupRemoteVideo(stream);
        })
    }
    .width('100%')
    .height(height)
    .border({
      width: 2,
      color: '#ff6b6b',
      radius: 8
    })
    .backgroundColor('#000')
  }

  // 构建远端视频视图组件
  @Builder
  buildRemoteVideoView1(stream: RemoteVideoStream) {
    Column() {
      // 用户ID和流类型标签
      Row() {
        Text(stream.uid)
          .fontSize(12)
          .fontColor(Color.White)

        Text(this.getTrackTypeText(stream.videoTrack))
          .fontSize(10)
          .fontColor('#aaa')
          .margin({ left: 8 })
          .backgroundColor('#444')
          .padding(2)
          .borderRadius(2)
      }
      .backgroundColor('#80000000')
      .padding(4)
      .borderRadius(4)
      .position({ x: 8, y: 8 })
      .zIndex(1)

      // 视频渲染区域
      XComponent({
        id: `remote_${stream.uid}_${stream.videoTrack}`,
        type: 'surface',
        controller: stream.xcomponentController
      })
        .width('100%')
        .height('100%')
        .onLoad(() => {
          console.info(`XComponent加载: ${stream.uid} - ${stream.videoTrack}`);
          let surfaceId = stream.xcomponentController.getXComponentSurfaceId();
          console.info(`获取到surfaceId: ${surfaceId}`);
          this.setupRemoteVideo(stream);
        })
        .onDestroy(() => {
          console.info(`远端视频销毁: ${stream.uid} - ${stream.videoTrack}`);
        })
    }
    .width('100%')
    .height('240vp')
    .border({
      width: 2,
      color: '#ff6b6b',
      radius: 8
    })
    .backgroundColor('#000')
  }

  // 获取流类型文本
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

  // 处理加入/离开房间
  private async handleJoinRoom(): Promise<void> {
    if (this.initRoom) {
      this.leaveChannelAndCleanup();
      this.initRoom = false;
      prompt.showToast({ message: '已离开房间', duration: 2000 });
      return;
    }

    try {
      // 验证必要参数
      if (!this.channelId.trim()) {
        prompt.showToast({ message: '请输入频道ID', duration: 2000 });
        return;
      }

      // 生成Token
      await this.generateToken();

      // 初始化RTC引擎
      await this.initAndSetupRtcEngine();

      // 开始本地预览
      this.startPreview();

      // 加入频道
      await this.joinChannel();

      this.initRoom = true;
      console.info('成功加入房间');

    } catch (error) {
      console.error('加入房间失败:', error);
      prompt.showToast({
        message: `加入房间失败: ${error}`,
        duration: 3000
      });
      this.initRoom = false;
    }
  }

  // 生成Token
  private async generateToken(): Promise<void> {

    this.Token = await ARTCTokenHelper.generateSingleParameterToken(
      this.AppId,
      this.AppKey,
      this.channelId,
      this.UserId,
      this.TimeStamp,
      this.Nonce
    );
    console.info('生成的Token:', this.Token.substring(0, 20) + '...');
  }

  // 设置本地视频
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

      // 配置视频画布 - 直接使用surfaceId
      if (!stream.canvas) {
        stream.canvas = new AliRtcVideoCanvas();
      }

      // 【关键】将surfaceId赋值给canvas
      stream.canvas.surfaceId = stream.surfaceId;
      stream.canvas.renderMode = AliRtcRenderMode.AliRtcRenderModeAuto;
      stream.canvas.mirrorMode = AliRtcRenderMirrorMode.AliRtcRenderMirrorModeAllNoMirror;

      // 设置远端视图配置
      this.rtcEngine.setRemoteViewConfig(stream.canvas, this.componentController, stream.uid,
        AliRtcVideoTrack.AliRtcVideoTrackCamera);

      console.info(`远端视频设置完成: ${stream.uid} - ${stream.videoTrack}`);

    } catch (error) {
      console.error(`设置远端视频失败 ${stream.uid}:`, error);
    }
  }

  // 查看远端视频（对应Android的viewRemoteVideo）
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

    // 动态调整网格列数
    this.updateGridColumns();

    console.info(`添加远端视频成功: ${uid} - ${videoTrack}`);
  }

  // 移除远端视频（对应Android的removeRemoteVideo）
  private removeRemoteVideo(uid: string, videoTrack: AliRtcVideoTrack): void {
    console.info(`移除远端视频: ${uid} - ${videoTrack}`);

    const index = this.remoteVideoStreams.findIndex(
      s => s.uid === uid && s.videoTrack === videoTrack
    );

    if (index >= 0) {
      this.remoteVideoStreams.splice(index, 1);

      // 动态调整网格列数
      this.updateGridColumns();

      console.info(`移除远端视频成功: ${uid} - ${videoTrack}`);
    }
  }

  // 移除用户的所有视频（对应Android的removeAllRemoteVideo）
  private removeAllRemoteVideo(uid: string): void {
    console.info(`移除用户所有视频: ${uid}`);

    // 过滤出该用户的所有视频流
    const userStreams = this.remoteVideoStreams.filter(s => s.uid === uid);

    // 从数组中移除该用户的所有流
    this.remoteVideoStreams = this.remoteVideoStreams.filter(s => s.uid !== uid);

    // 动态调整网格列数
    this.updateGridColumns();

    console.info(`移除用户所有视频成功: ${uid}`);
  }

  // 更新网格列数
  private updateGridColumns(): void {
    const count = this.remoteVideoStreams.length + (this.ShowPreview ? 1 : 0);
    if (count <= 2) {
      this.gridColumns = 2;
    } else if (count <= 4) {
      this.gridColumns = 3;
    } else {
      this.gridColumns = 4;
    }
    console.info(`更新网格列数: ${this.gridColumns}, 视频总数: ${count}`);
  }

  // 根据流类型获取唯一标识（对应Android的getStreamKey）
  private getStreamKey(uid: string, videoTrack: AliRtcVideoTrack): string {
    return `${uid}_${videoTrack}`;
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

      // 设置频道模式
      this.rtcEngine.setChannelProfile(AliRtcChannelProfile.AliRtcInteractiveLive);

      // 设置用户角色
      this.rtcEngine.setClientRole(AliRtcClientRole.AliRtcClientRoleInteractive);

      // 设置音频配置
      this.rtcEngine.setAudioProfile(
        AliRtcAudioProfile.AliRtcHighQualityMode,
        AliRtcAudioScenario.AliRtcSceneMusicMode
      );

      // 发布本地音视频流
      this.rtcEngine.publishLocalAudioStream(true);
      this.rtcEngine.publishLocalVideoStream(true);

      // 设置视频编码配置（使用Android的720x1280分辨率）
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

    const listener = new AliRtcEngineEventListener()
    listener.onJoinChannel((resultCode: number, channel: string, elapsed: string) => {
      console.info(`加入频道结果: result=${resultCode}, channel=${channel}, userId=${this.UserId}, elapsed=${elapsed}`);

      const resultText = resultCode === 0
        ? `User ${this.UserId} Join ${channel} Success`
        : `Join ${this.UserId} Join ${channel} Failed!，error: ${resultCode}`;

      prompt.showToast({
        message: resultText,
        duration: 2000
      });
    })
    listener.onLeaveChannel((resultCode: number) => {
      console.info(`离开频道结果: result=${resultCode}`);
      prompt.showToast({
        message: 'Leave Channel',
        duration: 2000
      });
    })
    listener.onConnectionStatusChange((status: number, reason: number) => {
      console.info(`连接状态变更: status=${status}, reason=${reason}`);
      if (status === 5) { // AliRtcConnectionStatusFailed
        prompt.showToast({
          message: '连接失败，请检查网络',
          duration: 3000
        });
      }
    })
    listener.onRemoteUserOnline((userId: string, elapsed: boolean) => {
      console.info(`远端用户上线: userId=${userId}, elapsed=${elapsed}`);
      prompt.showToast({
        message: `User ${userId} Join ${this.channelId} Success`,
        duration: 2000
      });
    })
    listener.onRemoteUserOffline((userId: string, reason: AliRtcUserOfflineReason) => {
      console.info(`远端用户下线: userId=${userId}, reason=${reason}`);
      // 移除该用户的所有视频
      this.removeAllRemoteVideo(userId);
    })
    listener.onRemoteTrackAvailableNotify((userId: string, audioTrack: AliRtcAudioTrack,
      videoTrack: AliRtcVideoTrack) => {
      console.info(`远端音视频流可用: userId=${userId}, audioTrack=${audioTrack}, videoTrack=${videoTrack}`);

      // 核心逻辑：根据视频流类型处理, 在收到onRemoteTrackAvailableNotify的videoTrack时调用setRemoteViewConfig设置视频画面
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
    listener.onLocalDeviceException((deviceType: AliRtcLocalDeviceType, exceptionType: AliRtcLocalDeviceExceptionType,
      msg: string) => {
      console.error(`本地设备异常: deviceType=${deviceType}, exceptionType=${exceptionType}, msg=${msg}`);
      prompt.showToast({
        message: `设备异常: ${msg}`,
        duration: 3000
      });
    })
    listener.onBye((code: number) => {
      console.info(`被服务器踢出: code=${code}`);
      prompt.showToast({
        message: `被服务器踢出: ${code}`,
        duration: 3000
      });
      this.leaveChannelAndCleanup();
    });

    this.rtcEngine.setRtcEngineEventListener(listener);
  }

  // 开始本地预览
  private startPreview(): void {
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

      const result = this.rtcEngine.joinChannelWithToken(this.Token, "", "", '视频通话用户');
      console.info('加入频道调用结果:', result);

    } catch (error) {
      console.error('加入频道失败:', error);
    }
  }

  // 离开频道并清理资源
  private leaveChannelAndCleanup(): void {
    if (this.rtcEngine) {
      try {
        // 停止预览
        this.rtcEngine.stopPreview();

        // 离开频道
        this.rtcEngine.leaveChannel();

        console.info('已离开频道');

        // 销毁引擎实例
        AliRtcEngine.destroyInstance();

        this.rtcEngine = null;

      } catch (error) {
        console.error('离开频道失败:', error);
      }
    }

    this.cleanupAfterLeave();
  }

  // 离开后的清理工作
  private cleanupAfterLeave(): void {
    // 清理所有远端视频资源
    this.remoteVideoStreams = [];
    this.ShowPreview = false;
    this.initRoom = false;
    this.Token = '';
    this.gridColumns = 2;
    console.info('清理完成');
  }

  // 获取当前时间戳
  private generateTimestamp(): void {
    const seconds = Math.floor(Date.now() / 1000);
    const tomorrowSeconds = seconds + 86400; // 24小时后过期
    this.TimeStamp = tomorrowSeconds;
  }

  // 计算总视频数
  private getTotalVideos(): number {
    return (this.ShowPreview ? 1 : 0) + this.remoteVideoStreams.length;
  }

  // 判断是否显示多人网格布局
  private shouldShowGridLayout(): boolean {
    return this.ShowPreview && this.remoteVideoStreams.length > 0;
  }
}