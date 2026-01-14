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
  AliRtcNetworkQuality,
  AliRtcAudioEffectConfig,
  AliRtcNetworkProbeConfig,
  AliRtcNetworkProbeResult,
} from "@aliyun_video_cloud/alivcsdk_artc";
import { CustomTitle } from "../../common/components/CustomTitle";
import { SandboxFileManager } from "../../common/utils/SandboxFileManager";
import { common } from "@kit.AbilityKit";
import { promptAction } from "@kit.ArkUI";
import { ARTCTokenHelper } from '../../common/keycenter/ARTCTokenHelper';
import { GlobalConfig } from '../../common/keycenter/GlobalConfig';
import { resourceManager } from "@kit.LocalizationKit";
import { fileIo as fs } from '@kit.CoreFileKit';
import { RemoteVideoStream } from "../../common/Constants"


@Entry
@Component
export struct PreJoinChannelTestPage {
  @State channelId: string = Date.now().toString().slice(-6);
  @State showPreview: boolean = false;
  @State hasJoined: boolean = false;
  @State localUserId: string = '';
  // 设备测试状态
  @State hasTestMicrophone: boolean = false;
  @State hasTestSpeaker: boolean = false;
  @State hasTestCamera: boolean = false;
  @State hasTestNetwork: boolean = false;
  // 测试结果文本
  @State deviceTestResultText: string = '';
  @State networkTestResultText: string = '';
  private xcomponentController: XComponentController = new XComponentController();
  private componentController: AliRtcXComponentController = new AliRtcXComponentController();
  @State remoteVideoStreams: RemoteVideoStream[] = []
  // RTC引擎相关
  private rtcEngine: AliRtcEngine | undefined;
  private context: common.UIAbilityContext | undefined;
  private localVideoCanvas: AliRtcVideoCanvas | undefined;
  private rtcEngineEventListener: AliRtcEngineEventListener | undefined;
  // 音频音量观察者
  // private audioVolumeObserver: AudioVolumeObserver | undefined;
  controller: TextAreaController = new TextAreaController()
  @State maxLength: number = 0
  @State hasAppended: boolean = false;
  @State sandboxDirectoryPath: string = ""; // 沙箱目录路径
  @State rawFileDescriptor: resourceManager.RawFileDescriptor | null = null; // rawfile压缩包描述符
  private sandboxManager = SandboxFileManager.getInstance();

  async aboutToAppear() {

    this.context = getContext(this) as common.UIAbilityContext;
    await this.initAndSetupRtcEngine();
    this.sandboxManager.initialize(this.context);

    // 立即拷贝必要的配置文件
    this.initConfigFiles();

    // 获取 UserId
    const global: GlobalConfig = GlobalConfig.getInstance();
    this.localUserId = await global.getUserId();
  }

  private initConfigFiles(): void {
    this.sandboxManager = SandboxFileManager.getInstance();

    // 拷贝配置文件到沙箱
    try {
      // 拷贝应用配置文件
      const configPath = this.sandboxManager.copyRawFileToSandbox('music.wav');
      console.info(`配置文件已拷贝到: ${configPath}`);

    } catch (error) {
      console.error('初始化配置文件失败:', error);
    }
  }

  build() {
    NavDestination() {
      Column() {
        CustomTitle({
          titleText: '入会前测试',
        })
        Scroll() {
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

            Text(this.hasJoined ? '离开频道' : '加入频道')
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
                  this.hasJoined = false;
                } else {
                  await this.startRTCCall();
                }
              })

            // 设备测试区域
            Column({ space: 10 }) {
              Text('设备测试')
                .fontSize(16)
                .fontColor('#333')
                .width('100%')

              Row({ space: 8 }) {
                Button(this.hasTestMicrophone ? '停止麦克风测试' : '麦克风测试')
                  .type(ButtonType.Normal)
                  .layoutWeight(1)
                  .fontColor('#fff')
                  .backgroundColor('#590ce4')
                  .onClick(() => {
                    this.handleMicrophoneTest();
                  })
                Button(this.hasTestSpeaker ? '停止扬声器测试' : '扬声器测试')
                  .type(ButtonType.Normal)
                  .layoutWeight(1)
                  .fontColor('#fff')
                  .backgroundColor('#590ce4')
                  .onClick(() => {
                    this.handleSpeakerTest();
                  })
                Button(this.hasTestCamera ? '停止摄像头测试' : '摄像头测试')
                  .type(ButtonType.Normal)
                  .layoutWeight(1)
                  .fontColor('#fff')
                  .backgroundColor('#590ce4')
                  .onClick(() => {
                    this.handleCameraTest();
                  })
              }

              // 设备测试结果显示
              TextArea({
                text: this.deviceTestResultText,
                placeholder: '设备测试结果将显示在这里',
                controller: this.controller
              })
                .width('100%')
                .height(100)
                .backgroundColor('#fff')
                .border({
                  width: 1,
                  color: '#ddd',
                  radius: 4
                })
                .padding(8)
                .fontSize(14)
                .fontColor('#333')
                .caretColor('transparent')
                .onChange((value) => {
                  let Length: number = value.length;
                  if (this.maxLength < Length) {
                    this.maxLength = Length
                    console.log('length=' + this.maxLength)
                  }
                  this.controller.caretPosition(this.maxLength)
                })

            }.width('100%')
            .margin({ top: 20 })
            .alignItems(HorizontalAlign.Start)

            // 网络测试区域
            Column({ space: 10 }) {
              Text('网络测试')
                .fontSize(16)
                .fontColor('#333')
                .width('100%')

              Row({ space: 8 }) {
                Button(this.hasTestNetwork ? '停止网络测试' : '网络测试')
                  .type(ButtonType.Normal)
                  .layoutWeight(1)
                  .fontColor('#fff')
                  .backgroundColor('#590ce4')
                  .onClick(() => {
                    this.handleNetworkTest();
                  })
                Blank()
                  .layoutWeight(1)
                Blank()
                  .layoutWeight(1)
              }

              // 网络测试结果显示
              TextArea({
                text: this.networkTestResultText,
                placeholder: '网络测试结果将显示在这里',
                controller: this.controller
              })
                .width('100%')
                .height(240)
                .backgroundColor('#fff')
                .border({
                  width: 1,
                  color: '#ddd',
                  radius: 4
                })
                .padding(8)
                .fontSize(14)
                .fontColor('#333')
                .caretColor('transparent')
                .onChange((value) => {
                  let Length: number = value.length;
                  if (this.maxLength < Length) {
                    this.maxLength = Length
                    console.log('length=' + this.maxLength)
                  }
                  this.controller.caretPosition(this.maxLength)
                })

            }.width('100%')
            .margin({ top: 20 })
            .alignItems(HorizontalAlign.Start)

            // 视频预览区域
            if (this.showPreview) {
              Column() {
                this.buildLocalVideoView()
              }
              .width('100%')
              .height('auto')
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
            }
          }
          .margin(12)
          .height('auto')
        }.height('auto')

      }
      .width('100%')
      .height('100%')
      .backgroundColor('#f5f5f5')
    }
    .hideTitleBar(true)
  }

  private shouldShowGridLayout(): boolean {
    return this.showPreview && this.remoteVideoStreams.length > 0;
  }

  @Builder
  buildLocalVideoView() {
    Column() {
      if (!this.shouldShowGridLayout()) {
        // 单视频布局
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
        // 多个视频布局
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

          // 显示第一个远端视频
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
    .height('auto')
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
      if (this.rtcEngine !== undefined) {
        // 设置事件监听器
        this.setupEventListeners();

        // 设置频道模式为互动直播模式
        this.rtcEngine.setChannelProfile(AliRtcChannelProfile.AliRtcInteractiveLive);

        // 设置用户角色为互动模式
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
        const str = `设备异常: ${deviceType} ${exceptionType} ${msg}`;
        this.deviceTestResultText += str + '\n';
        promptAction.showToast({ message: str, duration: 3000 });
      }
    );

    // 远端用户上线通知
    this.rtcEngineEventListener.onRemoteUserOnline((uid: string, elapsed: boolean) => {
      console.info(`远端用户上线: uid=${uid}, elapsed=${elapsed}`);
    });

    // 远端用户下线通知
    this.rtcEngineEventListener.onRemoteUserOffline((uid: string, reason: AliRtcUserOfflineReason) => {
      console.info(`远端用户下线: uid=${uid}, reason=${reason}`);
      // 移除该用户的所有视频
      this.removeAllRemoteVideo(uid);
    });

    // 远端轨道可用通知
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

    // 网络质量变化回调
    this.rtcEngineEventListener.onNetworkQualityChanged((uid: string, upQuality: AliRtcNetworkQuality,
      downQuality: AliRtcNetworkQuality) => {
      const message = this.getNetworkQualityString(upQuality);
      this.networkTestResultText += `网络质量: ${message}\n`;
    });

    // lastmile 网络探测结果回调
    this.rtcEngineEventListener.onLastmileDetectResultWithBandWidth((code: number,
      result: AliRtcNetworkProbeResult) => {
      const message = this.buildNetworkTestResultMessage(code, result);
      this.networkTestResultText += `${message}\n`;
    });

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

  // ==================== 远端视频管理 ====================

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
    // 创建新的远端视频流
    const newStream: RemoteVideoStream = {
      uid,
      videoTrack,
      canvas: new AliRtcVideoCanvas(),
      xcomponentController: new XComponentController(),
      surfaceId: '' // 初始为空，在onLoad中设置
    };

    this.remoteVideoStreams.push(newStream);

    console.info(`添加远端视频成功: ${uid} - ${videoTrack}`);
  }

  // 移除远端视频
  private removeRemoteVideo(uid: string, videoTrack: AliRtcVideoTrack): void {
    console.info(`移除远端视频: ${uid} - ${videoTrack}`);

    // 从数组中移除
    const index = this.remoteVideoStreams.findIndex(
      s => s.uid === uid && s.videoTrack === videoTrack
    );
    if (index >= 0) {
      this.remoteVideoStreams.splice(index, 1);
    }

    console.info(`移除远端视频成功: ${uid} - ${videoTrack}`);
  }

  // 移除用户的所有视频
  private removeAllRemoteVideo(uid: string): void {
    console.info(`移除用户所有视频: ${uid}`);

    // 移除摄像头流
    this.removeRemoteVideo(uid, AliRtcVideoTrack.AliRtcVideoTrackCamera);

    // 移除屏幕共享流
    this.removeRemoteVideo(uid, AliRtcVideoTrack.AliRtcVideoTrackScreen);

    console.info(`移除用户所有视频成功: ${uid}`);
  }

  // ==================== 设备测试功能 ====================
  // 麦克风测试
  private async handleMicrophoneTest(): Promise<void> {
    if (!this.rtcEngine) {
      promptAction.showToast({ message: 'RTC引擎未初始化', duration: 2000 });
      return;
    }

    if (this.hasJoined) {
      promptAction.showToast({ message: '已加入频道，无法进行设备测试', duration: 2000 });
      return;
    }

    try {
      if (!this.hasTestMicrophone) {
        // 创建音频音量观察者
        // this.audioVolumeObserver = new AudioVolumeObserver();
        // this.audioVolumeObserver.onTestAudioVolume = (volume: number) => {
        //   if (!this.hasAppended) {
        //     this.hasAppended = true;
        //     const msg = `OnTestAudioVolume volume: ${volume}, the mic is valid!\n`;
        //     this.deviceTestResultText += msg;
        //   }
        // };

        // 注册音量观察者并开始测试
        // this.rtcEngine.registerAudioVolumeObserver(this.audioVolumeObserver);
        const result = this.rtcEngine.startAudioCapture();

        if (result === 0) {
          this.hasTestMicrophone = true;
          this.hasAppended = false;
        }

        this.deviceTestResultText += `startAudioCaptureTest Result: ${result}\n`;
      } else {
        const result = this.rtcEngine.stopAudioCapture();
        this.deviceTestResultText += `stopAudioCaptureTest Result: ${result}\n`;

        // this.rtcEngine.unRegisterAudioVolumeObserver();
        this.hasTestMicrophone = false;
        // this.audioVolumeObserver = undefined;
      }
    } catch (error) {
      console.error('麦克风测试失败:', error);
      promptAction.showToast({ message: '麦克风测试失败', duration: 2000 });
    }
  }

  // 扬声器测试（使用沙箱中的音频文件）
  private async handleSpeakerTest(): Promise<void> {
    if (!this.rtcEngine) {
      promptAction.showToast({ message: 'RTC引擎未初始化', duration: 2000 });
      return;
    }

    if (this.hasJoined) {
      promptAction.showToast({ message: '已加入频道，无法进行设备测试', duration: 2000 });
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

      this.rtcEngine.joinChannelWithToken(base64Token, '', '', '入会前测试示例');

      const config: AliRtcAudioEffectConfig = new AliRtcAudioEffectConfig();
      config.needPublish = false;
      config.loopCycles = -1;
      config.startPosMs = 0;
      config.publishVolume = 60;
      config.playoutVolume = 60;

      if (!this.hasTestSpeaker) {
        const audioPath = this.sandboxManager.getSandboxFilePath('music.wav');
        const result = this.rtcEngine.playAudioEffect(1, audioPath, config);
        this.deviceTestResultText += `playAudioFileTest Result: ${result}（路径：${audioPath}）\n`;

        if (result === 0) {
          this.hasTestSpeaker = true;
          promptAction.showToast({ message: '扬声器测试中', duration: 2000 });
        } else {
          promptAction.showToast({ message: `播放失败，错误码：${result}`, duration: 2000 });
        }
      } else {
        // 停止播放
        const result = this.rtcEngine.stopAudioEffect(1);
        this.hasTestSpeaker = false;
        this.deviceTestResultText += `stopAudioFileTest Result: ${result}\n`;
        promptAction.showToast({ message: '扬声器测试停止', duration: 2000 });
      }
    } catch (error) {
      console.error('扬声器测试失败:', error);
      this.deviceTestResultText += `扬声器测试异常：${JSON.stringify(error)}\n`;
      promptAction.showToast({ message: '扬声器测试失败', duration: 2000 });
    }
  }

  // 摄像头测试
  private async handleCameraTest(): Promise<void> {
    if (!this.rtcEngine) {
      promptAction.showToast({ message: 'RTC引擎未初始化', duration: 2000 });
      return;
    }

    if (this.hasJoined) {
      promptAction.showToast({ message: '已加入频道，无法进行设备测试', duration: 2000 });
      return;
    }

    try {
      if (!this.hasTestCamera) {
        await this.startPreview();
        this.hasTestCamera = true;
        this.deviceTestResultText += 'startPreview\n';
      } else {
        this.rtcEngine.stopPreview();

        // 清理视频容器
        this.remoteVideoStreams = [];
        this.showPreview = false;
        this.hasTestCamera = false;
        this.deviceTestResultText += 'stopPreview\n';
      }
    } catch (error) {
      console.error('摄像头测试失败:', error);
      promptAction.showToast({ message: '摄像头测试失败', duration: 2000 });
    }
  }

  // 网络测试
  private async handleNetworkTest(): Promise<void> {
    if (!this.rtcEngine) {
      promptAction.showToast({ message: 'RTC引擎未初始化', duration: 2000 });
      return;
    }

    if (this.hasJoined) {
      promptAction.showToast({ message: '已加入频道，无法进行网络测试', duration: 2000 });
      return;
    }

    try {
      if (!this.hasTestNetwork) {
        const config: AliRtcNetworkProbeConfig = new AliRtcNetworkProbeConfig();
        config.probeUplink = true;
        config.probeDownlink = true;

        this.rtcEngine.startLastmileDetect(config);
        this.hasTestNetwork = true;
        this.networkTestResultText += 'startLastmileDetect\n';
      } else {
        this.rtcEngine.stopLastmileDetect();
        this.hasTestNetwork = false;
        this.networkTestResultText += 'stopLastmileDetect\n';
      }
    } catch (error) {
      console.error('网络测试失败:', error);
      promptAction.showToast({ message: '网络测试失败', duration: 2000 });
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
      const result = this.rtcEngine.joinChannelWithToken(base64Token, '', '', '入会前测试示例');
      console.info('加入频道调用结果:', result);

      this.hasJoined = true;

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

    // 更新按钮文本
    if (resultCode === 0) {
      this.hasJoined = true;
    }
  }

  // 网络质量描述转换
  private getNetworkQualityString(quality: AliRtcNetworkQuality): string {
    switch (quality) {
      case AliRtcNetworkQuality.AliRtcNetworkQualityExcellent:
        return '极好';
      case AliRtcNetworkQuality.AliRtcNetworkQualityGood:
        return '好';
      case AliRtcNetworkQuality.AliRtcNetworkQualityPoor:
        return '不好';
      case AliRtcNetworkQuality.AliRtcNetworkQualityBad:
        return '差';
      case AliRtcNetworkQuality.AliRtcNetworkQualityVeryBad:
        return '极差';
      case AliRtcNetworkQuality.AliRtcNetworkQualityDisconnect:
        return '断开';
      case AliRtcNetworkQuality.AliRtcNetworkQualityUnknow:
      default:
        return '未知';
    }
  }

  // 构建网络测试结果消息
  private buildNetworkTestResultMessage(code: number, result: AliRtcNetworkProbeResult): string {
    const msg = new Array<string>();
    msg.push('网络质量测试结果:\n');
    msg.push(`  状态码: ${code}\n`);
    msg.push(`  往返延迟(RTT): ${result.rtt} ms\n`);
    msg.push(`  上行丢包率: ${result.uplinkLoss}%\n`);
    msg.push(`  上行抖动: ${result.uplinkJitter} ms\n`);
    msg.push(`  上行带宽: ${result.uplinkBandWidth} kbps\n`);
    msg.push(`  下行丢包率: ${result.downlinkLoss}%\n`);
    msg.push(`  下行抖动: ${result.downlinkJitter} ms\n`);
    msg.push(`  下行带宽: ${result.downlinkBandWidth} kbps\n`);
    return msg.join('');
  }

  // ==================== 清理资源 ====================
  private destroyRtcEngine(): void {
    if (this.rtcEngine) {
      try {
        // 停止所有测试
        if (this.hasTestMicrophone) {
          this.rtcEngine.stopAudioCapture();
          // this.rtcEngine.unRegisterAudioVolumeObserver();
        }

        if (this.hasTestSpeaker) {
          this.rtcEngine.stopAudioEffect(1);
        }

        if (this.hasTestCamera) {
          this.rtcEngine.stopPreview();
        }

        if (this.hasTestNetwork) {
          this.rtcEngine.stopLastmileDetect();
        }

        if (this.hasJoined) {
          this.rtcEngine.stopPreview();
          this.rtcEngine.leaveChannel();
        }

        promptAction.showToast({ message: 'Leave Channel', duration: 2000 });
      } catch (error) {
        console.error('销毁引擎失败:', error);
      }
    }

    // 清理远端视频
    this.remoteVideoStreams = [];

    // 重置状态
    this.showPreview = false;
    this.hasJoined = false;
    this.hasTestMicrophone = false;
    this.hasTestSpeaker = false;
    this.hasTestCamera = false;
    this.hasTestNetwork = false;
    this.localVideoCanvas = undefined;
  }

  aboutToDisappear(): void {
    this.destroyRtcEngine();
    // 销毁引擎
    this.rtcEngine = undefined;
    this.rtcEngineEventListener = undefined;
  }
}

// 音频音量观察者类
// class AudioVolumeObserver implements AliRtcAudioVolumeObserver {
//   onTestAudioVolume?: (volume: number) => void;
// }