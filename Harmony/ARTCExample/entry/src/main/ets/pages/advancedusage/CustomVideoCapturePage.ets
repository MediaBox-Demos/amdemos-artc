import { common } from "@kit.AbilityKit";
import { RemoteVideoStream } from "../../common/Constants"
import {
  AliRtcEngine,
  AliRtcEngineEventListener,
  AliRtcVideoCanvas,
  AliRtcVideoTrack,
  AliRtcXComponentController,
  AliRtcChannelProfile,
  AliRtcClientRole,
  AliRtcAudioProfile,
  AliRtcAudioScenario,
  AliRtcVideoEncoderConfiguration,
  AliRtcVideoDimensions,
  AliRtcVideoEncoderOrientationMode,
  AliRtcVideoFormat,
  AliRtcRenderMode,
  AliRtcRenderMirrorMode,
  AliRtcStats,
  AliRtcAudioTrack,
  AliRtcPublishState,
  AliRtcConnectionStatus,
  AliRtcConnectionStatusChangeReason,
  AliRtcLocalDeviceType,
  AliRtcLocalDeviceExceptionType,
  AliRtcVideoFrame,
  AliRtcBufferType,
} from "@aliyun_video_cloud/alivcsdk_artc";
import { CustomTitle } from "../../common/components/CustomTitle";
import { promptAction } from '@kit.ArkUI';
import { ARTCTokenHelper } from '../../common/keycenter/ARTCTokenHelper';
import { GlobalConfig } from '../../common/keycenter/GlobalConfig';
import camera from '@ohos.multimedia.camera';
import image from '@ohos.multimedia.image';
import display from '@ohos.display';
import { BusinessError } from '@ohos.base';


// 自定义视频采集类型枚举
enum VideoInputType {
  YUV = 0,
  TEXTURE = 1
}

// 相机状态枚举
enum CameraState {
  CLOSED = 0,
  OPENING = 1,
  OPENED = 2,
  ERROR = 3
}

// YUV帧数据接口
interface YUVFrameData {
  yData: Uint8Array;
  uData: Uint8Array;
  vData: Uint8Array;
  width: number;
  height: number;
  timestamp: number;
  strideY: number;
  strideU: number;
  strideV: number;
}

@Entry
@Component
export struct CustomVideoCapturePage {
  @State channelId: string = Date.now().toString().slice(-6);
  private xcomponentController: XComponentController = new XComponentController();
  @State hasJoined: boolean = false;
  @State showPreview: boolean = false;
  @State isCustomVideoCapture: boolean = true; // 自定义视频采集开关
  @State currentInputType: VideoInputType = VideoInputType.YUV; // 当前输入类型
  // RTC引擎相关
  @State remoteVideoStreams: RemoteVideoStream[] = []
  private rtcEngine: AliRtcEngine | undefined;
  private context: common.UIAbilityContext | undefined;
  private localVideoCanvas: AliRtcVideoCanvas | undefined;
  private componentController: AliRtcXComponentController = new AliRtcXComponentController();
  @State localUserId: string = '';
  private rtcEngineEventListener: AliRtcEngineEventListener | undefined;
  // 视频采集相关
  private isPushingVideoData: boolean = false; // 是否正在推送视频数据
  private readonly VIDEO_WIDTH: number = 720;
  private readonly VIDEO_HEIGHT: number = 1280;
  private readonly VIDEO_FPS: number = 20;
  // 相机相关
  private cameraManager: camera.CameraManager | null = null;
  private cameraDevice: camera.CameraDevice | null = null;
  private cameraInput: camera.CameraInput | null = null;
  private previewOutput: camera.PreviewOutput | null = null;
  private previewOutput2: camera.PreviewOutput | null = null;
  private captureSession: camera.CaptureSession | null = null;
  private imageReceiver: image.ImageReceiver | null = null;
  private surfaceId: string = "-1";

  aboutToAppear() {
    this.context = getContext(this) as common.UIAbilityContext;
    this.initCameraManager();
  }

  build() {
    NavDestination() {
      Column() {
        CustomTitle({
          titleText: '自定义视频采集',
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

          Row() {
            Text("自定义视频采集")
              .fontSize(16)
              .fontColor('#636363')
              .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.isCustomVideoCapture })
              .onChange((isOn: boolean) => {
                this.isCustomVideoCapture = isOn;
              })
          }
          .width('100%')
          .height(36)
          .borderRadius(4)
          .margin({ top: 8 })

          Column() {
            Row() {
              Text('Video Source')
                .fontSize(16)
                .fontColor('#333')
                .margin({
                  left: 10
                })

              Blank()
              Row() {
                Row() {
                  Radio({ value: 'YUV', group: 'videoSourceGroup' })
                    .checked(this.currentInputType === VideoInputType.YUV)
                    .onChange((checked: boolean) => {
                      if (checked) {
                        this.currentInputType = VideoInputType.YUV;
                      }
                    })
                  Text('YUV')
                }

                Row() {
                  Radio({ value: '纹理', group: 'videoSourceGroup' })
                    .checked(this.currentInputType === VideoInputType.TEXTURE)
                    .onChange((checked: boolean) => {
                      if (checked) {
                        this.currentInputType = VideoInputType.TEXTURE;
                      }
                    })
                  Text('纹理')
                }
              }
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)

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
    }
    .hideTitleBar(true)
  }

  // 判断是否显示多人网格布局
  private shouldShowGridLayout(): boolean {
    return this.showPreview && this.remoteVideoStreams.length > 0;
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
              this.surfaceId = this.xcomponentController.getXComponentSurfaceId();
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
                this.surfaceId = this.xcomponentController.getXComponentSurfaceId();
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

  // ==================== 相机管理器初始化 ====================
  private async initCameraManager(): Promise<void> {
    try {
      this.cameraManager = camera.getCameraManager(this.context!);
      console.info('Camera manager initialized');
    } catch (error) {
      console.error('Failed to initialize camera manager:', error);
      promptAction.showToast({
        message: '初始化相机管理器失败',
        duration: 2000
      });
    }
  }

  private createImageReceiver(): image.ImageReceiver {
    const receiver: image.ImageReceiver = image.createImageReceiver(
      this.VIDEO_WIDTH,
      this.VIDEO_HEIGHT,
      4, // IMAGE_FORMAT_YUV_420
      8
    );

    receiver.on('imageArrival', () => {
      console.info('imageArrival callback');
      receiver.readNextImage((err: BusinessError, nextImage: image.Image) => {
        if (err || !nextImage) {
          console.error(`receiveImage error: ${JSON.stringify(err)}`);
          return;
        }
        this.processYUVImage(nextImage);
      });
    });

    return receiver;
  }

  private async processYUVImage(nextImage: image.Image): Promise<void> {
    if (!this.isPushingVideoData || !this.rtcEngine) {
      nextImage.release();
      return;
    }

    try {
      const yComponent: image.Component = await nextImage.getComponent(image.ComponentType.YUV_Y);
      const uComponent: image.Component = await nextImage.getComponent(image.ComponentType.YUV_U);
      const vComponent: image.Component = await nextImage.getComponent(image.ComponentType.YUV_V);

      const yuvFrame: YUVFrameData = await this.extractYUVDataFromComponents(
        yComponent,
        uComponent,
        vComponent,
        nextImage
      );

      this.pushYUVFrameToSDK(yuvFrame);
      nextImage.release();
    } catch (error) {
      nextImage.release();
    }
  }

  private async extractYUVDataFromComponents(
    yComponent: image.Component,
    uComponent: image.Component,
    vComponent: image.Component,
    img: image.Image
  ): Promise<YUVFrameData> {
    const yBuffer: ArrayBuffer = yComponent.byteBuffer;
    const uBuffer: ArrayBuffer = uComponent.byteBuffer;
    const vBuffer: ArrayBuffer = vComponent.byteBuffer;

    return {
      yData: new Uint8Array(yBuffer),
      uData: new Uint8Array(uBuffer),
      vData: new Uint8Array(vBuffer),
      width: img.size.width,
      height: img.size.height,
      timestamp: Date.now(),
      strideY: yComponent.rowStride,
      strideU: uComponent.rowStride,
      strideV: vComponent.rowStride
    };
  }

  // ==================== RTC引擎初始化 ====================
  private async initAndSetupRtcEngine(): Promise<void> {
    if (!this.context) {
      promptAction.showToast({ message: '上下文未初始化', duration: 2000 });
      return;
    }

    try {
      // 创建RTC引擎实例
      this.rtcEngine = AliRtcEngine.getInstance('', this.context);

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
      const dimensions: AliRtcVideoDimensions = new AliRtcVideoDimensions();
      dimensions.width = this.VIDEO_WIDTH;
      dimensions.height = this.VIDEO_HEIGHT;
      videoConfig.dimensions = dimensions;
      videoConfig.frameRate = this.VIDEO_FPS;
      videoConfig.bitrate = 1200;
      videoConfig.keyFrameInterval = 2000;
      videoConfig.orientationMode = AliRtcVideoEncoderOrientationMode.AliRtcVideoEncoderOrientationModeAdaptive;

      this.rtcEngine.setVideoEncoderConfiguration(videoConfig);
      const cameraDirection = this.rtcEngine.getCurrentCameraDirection()

      // 设置外部视频源
      if (this.isCustomVideoCapture) {
        if (cameraDirection == 1) {
          this.rtcEngine?.switchCamera()
        } else if (cameraDirection != 0 && cameraDirection != 1) {
          this.rtcEngine?.switchCamera()
        }
        const isTextureInput = this.currentInputType === VideoInputType.TEXTURE;
        // const externalVideoSourceConfig: AliRtcExternalVideoSourceConfig = {
        //   isTexture: isTextureInput,
        //   videoTrack: AliRtcVideoTrack.AliRtcVideoTrackCamera,
        //   renderMode: AliRtcRenderMode.AliRtcRenderModeAuto
        // };

        try {
          // this.rtcEngine.setExternalVideoSource(true, externalVideoSourceConfig);
          console.info('External video source set successfully');
        } catch (error) {
          console.error('Failed to set external video source:', error);
        }
      } else {
        if (cameraDirection == 0) {
          this.rtcEngine?.switchCamera()
        }
      }

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

    this.rtcEngineEventListener = new AliRtcEngineEventListener();

    // 加入频道结果回调
    this.rtcEngineEventListener.onJoinChannel((resultCode: number, channel: string, userId: string,
      elapsed: number) => {
      console.info(`加入频道结果: result=${resultCode}, channel=${channel}, userId=${userId}, elapsed=${elapsed}`);
      this.handleJoinResult(resultCode, channel, userId);
    });

    // 离开频道结果回调
    this.rtcEngineEventListener.onLeaveChannel((result: number, stats: AliRtcStats) => {
      console.info(`离开频道结果: result=${result}`);
      this.stopCustomCapture();
    });

    // 远端音视频流可用回调
    this.rtcEngineEventListener.onRemoteTrackAvailableNotify((userId: string, audioTrack: AliRtcAudioTrack,
      videoTrack: AliRtcVideoTrack) => {
      console.info(`远端音视频流可用: userId=${userId}, audioTrack=${audioTrack}, videoTrack=${videoTrack}`);

      // 处理视频流
      if (videoTrack === AliRtcVideoTrack.AliRtcVideoTrackCamera) {
        this.viewRemoteVideo(userId, AliRtcVideoTrack.AliRtcVideoTrackCamera);
        this.removeRemoteVideo(userId, AliRtcVideoTrack.AliRtcVideoTrackScreen);
      } else if (videoTrack === AliRtcVideoTrack.AliRtcVideoTrackNo) {
        this.removeAllRemoteVideo(userId);
      }
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
      }
    );

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
      if (!this.surfaceId || this.surfaceId === '-1') {
        console.error('surfaceId 未就绪');
        return;
      }
      console.info('获取到本地视频surfaceId:', this.surfaceId);

      this.localVideoCanvas = new AliRtcVideoCanvas();
      this.localVideoCanvas.surfaceId = this.surfaceId;
      this.localVideoCanvas.renderMode = AliRtcRenderMode.AliRtcRenderModeAuto;
      this.localVideoCanvas.mirrorMode = AliRtcRenderMirrorMode.AliRtcRenderMirrorModeAllMirror;

      console.info('本地视频画布设置完成');
      this.applyLocalVideoCanvas();

    } catch (error) {
      console.error('设置本地视频失败:', error);
    }
  }

  private applyLocalVideoCanvas(): void {
    if (!this.rtcEngine || !this.localVideoCanvas) {
      return;
    }
    try {
      this.rtcEngine.setLocalViewConfig(
        this.localVideoCanvas,
        this.componentController,
        AliRtcVideoTrack.AliRtcVideoTrackCamera
      );
      console.info('本地视频画布已应用到RTC引擎');
    } catch (error) {
      console.error('应用本地视频画布失败:', error);
    }
  }

  // ==================== 设置远端视频 ====================
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
        stream.videoTrack);

      console.info(`远端视频设置完成: ${stream.uid} - ${stream.videoTrack}`);

    } catch (error) {
      console.error(`设置远端视频失败 ${stream.uid}:`, error);
    }
  }

  // ==================== 查看远端视频 ====================
  private viewRemoteVideo(uid: string, videoTrack: AliRtcVideoTrack): void {
    console.info(`查看远端视频: ${uid} - ${videoTrack}`);

    const existingIndex = this.remoteVideoStreams.findIndex(
      s => s.uid === uid && s.videoTrack === videoTrack
    );

    if (existingIndex >= 0) {
      console.info(`远端视频已存在: ${uid} - ${videoTrack}`);
      return;
    }

    const newStream: RemoteVideoStream = {
      uid,
      videoTrack,
      canvas: new AliRtcVideoCanvas(),
      xcomponentController: new XComponentController(),
      surfaceId: ''
    };

    this.remoteVideoStreams.push(newStream);
    console.info(`添加远端视频成功: ${uid} - ${videoTrack}`);
  }

  // ==================== 移除远端视频 ====================
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

  // ==================== 移除用户的所有视频 ====================
  private removeAllRemoteVideo(uid: string): void {
    console.info(`移除用户所有视频: ${uid}`);
    this.remoteVideoStreams = this.remoteVideoStreams.filter(s => s.uid !== uid);
    console.info(`移除用户所有视频成功: ${uid}`);
  }

  // ==================== 频道操作 ====================
  private async startRTCCall(): Promise<void> {
    if (this.hasJoined) {
      return;
    }

    this.setupRtcEngineForCall();
    await this.startPreview();

    if (this.isCustomVideoCapture) {
      this.rtcEngine?.enableLocalVideo(false);
      await this.startCustomCapture();
    }

    await this.joinChannel();
  }

  private setupRtcEngineForCall(): void {
    if (!this.rtcEngine) {
      return;
    }

    // 设置外部视频源
    if (this.isCustomVideoCapture) {
      // const isTextureInput = this.currentInputType === VideoInputType.TEXTURE;
      // const externalVideoSourceConfig: AliRtcExternalVideoSourceConfig = {
      //   isTexture: isTextureInput,
      //   videoTrack: AliRtcVideoTrack.AliRtcVideoTrackCamera,
      //   renderMode: AliRtcRenderMode.AliRtcRenderModeAuto
      // };

      try {
        // this.rtcEngine.setExternalVideoSource(true, externalVideoSourceConfig);
        console.info('External video source set successfully');
      } catch (error) {
        console.error('Failed to set external video source:', error);
      }
    }
  }

  private async startPreview(): Promise<void> {
    if (!this.rtcEngine) {
      return;
    }

    try {
      if (this.localVideoCanvas) {
        this.applyLocalVideoCanvas();
      } else {
        this.setupLocalVideo();
      }

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

      const result = this.rtcEngine.joinChannelWithToken(base64Token, '', '', '自定义视频采集用户');

      console.info('加入频道调用结果:', result);
      this.hasJoined = true;
      this.localUserId = userId;
    } catch (error) {
      console.error('加入频道失败:', error);
      promptAction.showToast({ message: `加入频道失败: ${error}`, duration: 3000 });
    }
  }

  // ==================== 自定义视频采集 ====================
  private async startCustomCapture(): Promise<void> {
    this.isPushingVideoData = true;
    console.info('开始自定义视频采集');

    if (this.currentInputType === VideoInputType.YUV) {
      await this.startYUVCapture();
    } else if (this.currentInputType === VideoInputType.TEXTURE) {
      await this.startTextureCapture();
    }
  }

  private async createDualChannelPreview(): Promise<void> {
    if (!this.cameraManager || !this.surfaceId || this.surfaceId === '-1') {
      console.error('Camera manager or surface not ready');
      return;
    }

    this.releaseCamera();

    const cameras: Array<camera.CameraDevice> = this.cameraManager.getSupportedCameras();
    if (cameras.length === 0) {
      console.error('No cameras available');
      return;
    }

    let selectedCamera: camera.CameraDevice | null = null;
    for (const cam of cameras) {
      if (cam.cameraPosition === camera.CameraPosition.CAMERA_POSITION_BACK) {
        selectedCamera = cam;
        break;
      }
    }
    if (!selectedCamera) {
      selectedCamera = cameras[0];
    }

    const profiles: camera.CameraOutputCapability =
      this.cameraManager.getSupportedOutputCapability(selectedCamera);
    const previewProfiles: Array<camera.Profile> = profiles.previewProfiles;

    if (!previewProfiles || previewProfiles.length === 0) {
      console.error('No preview profiles available');
      return;
    }

    let previewProfile: camera.Profile | null = null;
    for (const profile of previewProfiles) {
      if (profile.format === camera.CameraFormat.CAMERA_FORMAT_YUV_420_SP) {
        previewProfile = profile;
        break;
      }
    }
    if (!previewProfile) {
      previewProfile = previewProfiles[0];
    }

    this.imageReceiver = this.createImageReceiver();

    try {
      if (!this.cameraManager || !this.imageReceiver) {
        return;
      }
      this.previewOutput = this.cameraManager.createPreviewOutput(
        previewProfile,
        this.surfaceId
      );

      const imageSurfaceId: string = await this.imageReceiver.getReceivingSurfaceId();
      this.previewOutput2 = this.cameraManager.createPreviewOutput(
        previewProfile,
        imageSurfaceId
      );

      this.cameraInput = this.cameraManager.createCameraInput(selectedCamera);

      await this.cameraInput.open();

      this.captureSession = this.cameraManager.createCaptureSession();
      this.captureSession.beginConfig();
      this.captureSession.addInput(this.cameraInput);
      this.captureSession.addOutput(this.previewOutput);
      this.captureSession.addOutput(this.previewOutput2);
      await this.captureSession.commitConfig();

      await this.captureSession.start();

      console.info('Dual channel preview started successfully');
    } catch (error) {
      console.error('Failed to create dual channel preview:', error);
      this.releaseCamera();
    }
  }

  private async releaseCamera(): Promise<void> {
    try {
      if (this.captureSession) {
        await this.captureSession.stop();
        this.captureSession.release();
        this.captureSession = null;
      }

      if (this.cameraInput) {
        await this.cameraInput.close();
        this.cameraInput = null;
      }

      if (this.previewOutput) {
        this.previewOutput.release();
        this.previewOutput = null;
      }

      if (this.previewOutput2) {
        this.previewOutput2.release();
        this.previewOutput2 = null;
      }

      this.imageReceiver = null;

      console.info('Camera resources released');
    } catch (error) {
      console.error('Failed to release camera:', error);
    }
  }

  // ==================== 开始YUV采集 ====================
  private async startYUVCapture(): Promise<void> {
    console.info('开始YUV视频采集');

    try {
      await this.createDualChannelPreview();
      console.info('YUV采集已启动');
    } catch (error) {
      const err = error as BusinessError;
      console.error('启动YUV采集失败:', JSON.stringify(err));
      this.rtcEngine?.enableLocalVideo(true);
    }
  }

  // ==================== 推送YUV帧到RTC SDK ====================
  private pushYUVFrameToSDK(frame: YUVFrameData): void {
    if (!this.rtcEngine || !this.isPushingVideoData) {
      return;
    }

    try {
      const ySize: number = frame.width * frame.height;
      const uvSize: number = ySize / 4;
      const totalSize: number = ySize + uvSize * 2;
      const arrayBuffer: ArrayBuffer = new ArrayBuffer(totalSize);
      const i420Data: Uint8Array = new Uint8Array(arrayBuffer);

      // 拷贝 Y/U/V 数据到 I420 buffer
      i420Data.set(frame.yData.subarray(0, ySize), 0);
      i420Data.set(frame.uData.subarray(0, uvSize), ySize);
      i420Data.set(frame.vData.subarray(0, uvSize), ySize + uvSize);

      const yuvFrame: AliRtcVideoFrame = new AliRtcVideoFrame();
      yuvFrame.data = arrayBuffer;
      yuvFrame.format = AliRtcVideoFormat.AliRtcVideoFormatI420;
      yuvFrame.type = AliRtcBufferType.AliRtcBufferTypeRawData;
      yuvFrame.width = frame.width;
      yuvFrame.height = frame.height;
      yuvFrame.strideY = frame.strideY;
      yuvFrame.strideU = frame.strideU;
      yuvFrame.strideV = frame.strideV;
      yuvFrame.rotation = 0;
      yuvFrame.textureId = 0;
      yuvFrame.transformMatrix = [];
      yuvFrame.sharedContext = 0;
      yuvFrame.eglChanged = false;
      yuvFrame.eglContext = 0;

      this.rtcEngine.pushExternalVideoFrame(yuvFrame, AliRtcVideoTrack.AliRtcVideoTrackCamera);

      console.info(`推送YUV帧: ${frame.width}x${frame.height}, timestamp: ${frame.timestamp}`);
    } catch (error) {
      console.error('推送YUV帧失败:', error);
    }
  }

  private async startTextureCapture(): Promise<void> {
    console.info('开始纹理视频采集');
    // 这里可以添加纹理采集的实现
    this.rtcEngine?.enableLocalVideo(true);
  }

  private stopCustomCapture(): void {
    console.info('停止自定义视频采集');
    this.isPushingVideoData = false;

    // 停止相机采集
    this.stopCameraCapture();
  }

  private async stopCameraCapture(): Promise<void> {
    try {
      await this.releaseCamera();
      console.info('相机采集已停止');
    } catch (error) {
      const err = error as BusinessError;
      console.error('停止相机采集失败:', JSON.stringify(err));
    }
  }

  // ==================== 结果处理 ====================
  private handleJoinResult(resultCode: number, channel: string, userId: string): void {
    const resultText = resultCode === 0
      ? `User ${userId} Join ${channel} Success`
      : `Join ${userId} Join ${channel} Failed!，error: ${resultCode}`;

    promptAction.showToast({ message: resultText, duration: 2000 });
  }

  // ==================== 清理资源 ====================
  private destroyRtcEngine(): void {
    // 停止视频采集
    this.stopCustomCapture();

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
    this.showPreview = false;
    this.isPushingVideoData = false;
    this.localUserId = '';
    this.remoteVideoStreams = [];
    this.localVideoCanvas = undefined;
  }

  aboutToDisappear(): void {
    this.destroyRtcEngine();
  }
}