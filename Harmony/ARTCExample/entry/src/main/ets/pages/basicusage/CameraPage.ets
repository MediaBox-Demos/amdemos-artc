import {
  AliRtcEngine,
  AliRtcEngineEventListener,
  AliRtcVideoCanvas,
  AliRtcVideoTrack,
  AliRtcVideoEncoderOrientationMode,
  AliRtcChannelProfile,
  AliRtcClientRole,
  AliRtcAudioProfile,
  AliRtcAudioScenario,
  AliRtcCapturePipelineScaleMode,
  AliRtcVideoEncoderConfiguration,
  AliRtcXComponentController,
  AliRtcEngineAuthInfo,
  AliRtcRenderMode,
  AliRtcRenderMirrorMode,
  AliRtcUserOfflineReason,
  AliRtcAudioTrack
} from '@aliyun_video_cloud/alivcsdk_artc';
import { prompt, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { CustomTitle } from "../../common/components/CustomTitle";
import { RemoteVideoStream } from "../../common/Constants"
import { ARTCTokenHelper } from '../../common/keycenter/ARTCTokenHelper';
import { GlobalConfig } from '../../common/keycenter/GlobalConfig';

// 定义变量类型
interface CameraInfo {
  maxZoom: number;
  minZoom: number;
  currZoom: number;
  maxExposure: number;
  minExposure: number;
  currExposure: number;
}


@Entry
@Component
export struct CameraPage {
  @State channelId: string = Date.now().toString().slice(-6);
  @State ShowPreview: boolean = false;
  @State hasJoined: boolean = false;
  @State zoomValue: string = '1.0';
  @State exposureValue: string = '0.0';
  @State exposurePointX: string = '';
  @State exposurePointY: string = '';
  @State focusPointX: string = '';
  @State focusPointY: string = '';
  @State cameraAutoFaceFocus: boolean = false;
  @State cameraFlash: boolean = false;
  @State isFrontCamera: boolean = true;
  @State zoomSliderValue: number = 0;
  @State exposureSliderValue: number = 0;
  @State zoomMaxProgress: number = 90; // (10-1)*10 = 90
  private rtcEngine: AliRtcEngine | undefined;
  private context: common.Context | undefined;
  private xcomponentController: XComponentController = new XComponentController();
  private aliRtcVideoCanvas: AliRtcVideoCanvas | undefined;
  private componentController: AliRtcXComponentController = new AliRtcXComponentController()
  private lastTapTime: number = 0;
  private rtcEventListener?: AliRtcEngineEventListener;
  @State remoteVideoStreams: RemoteVideoStream[] = []
  private doubleTapTimeout: number = 300;
  private cameraInfo: CameraInfo = {
    maxZoom: 10.0,
    minZoom: 1.0,
    currZoom: 1.0,
    maxExposure: 12.0,
    minExposure: -12.0,
    currExposure: 0.0
  };
  private clickTimerId: number = -1;
  // 曝光补偿常量定义
  private readonly EXPOSURE_MIN: number = -120 // 对应-12.0（-12×10）
  private readonly EXPOSURE_MAX: number = 120 // 对应12.0（12×10）
  private readonly EXPOSURE_STEP: number = 1 // Slider步长
  private readonly EXPOSURE_DEFAULT: number = 0 // 默认值0.0

  async aboutToAppear(): Promise<void> {
    this.context = getContext() as common.Context;
  }

  aboutToDisappear(): void {
    this.destroyRtcEngine();
  }

  build() {
    NavDestination() {
      Column() {
        CustomTitle({
          titleText: '相机常规控制',
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
              .layoutWeight(0.2)

            TextInput({
              text: this.channelId
            })
              .padding({ left: 5 })
              .layoutWeight(0.5)
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

            Text(this.hasJoined ? '挂断' : '加入房间')
              .textAlign(TextAlign.Center)
              .fontSize(16)
              .backgroundColor('#3295fb')
              .height(48)
              .layoutWeight(0.2)
              .onClick(async () => {
                await this.handleJoinRoom();
              })
              .margin({
                left: 8
              })
          }
          .margin({ top: 10 })
          .height(50)

          if (this.hasJoined) {
            Text(this.isFrontCamera ? '切换为后置摄像头' : '切换为前置摄像头')
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
                await this.switchCamera();
              })
          } else {
            Text('切换摄像头')
              .textAlign(TextAlign.Center)
              .fontSize(16)
              .backgroundColor('#e0e0e0')
              .width('95%')
              .height(48)
              .margin({
                top: 24, left: 10,
                right: 10
              })
          }

          // 变焦倍数
          Row() {
            Text("变焦倍数")
              .fontSize(16)
              .fontColor('#636363')
              .layoutWeight(0.4)

            Text(this.zoomValue)
              .fontSize(14)
              .fontColor('#636363')
              .layoutWeight(0.2)

            Slider({
              value: this.zoomSliderValue,
              min: 0,
              max: this.zoomMaxProgress, // 90
              step: 1,
            })
              .blockColor('#05d8c5')
              .selectedColor('#05d8c5')
              .onChange((value: number) => {
                this.handleZoomChange(value);
              })
              .layoutWeight(1.4)
              .enabled(this.hasJoined)
          }
          .width('100%')
          .height(36)
          .borderRadius(4)
          .margin({ top: 8 })

          // 曝光补偿
          Row() {
            Text("曝光补偿")
              .fontSize(16)
              .fontColor('#636363')
              .layoutWeight(0.4)

            // 显示当前曝光值（带正负号）
            Row() {
              Text(this.exposureValue.startsWith('-') ? '' : '')
                .fontSize(14)
                .fontColor('#636363')
              Text(this.exposureValue)
                .fontSize(14)
                .fontColor('#636363')
            }
            .layoutWeight(0.2)
            .justifyContent(FlexAlign.Center)

            // 滑块控件
            Slider({
              value: this.exposureSliderValue,
              min: this.EXPOSURE_MIN, // -120
              max: this.EXPOSURE_MAX, // 120
              step: this.EXPOSURE_STEP, // 1
            })
              .blockColor('#05d8c5')
              .selectedColor('#05d8c5')
              .onChange((value: number) => {
                this.handleExposureChange(value);
              })
              .layoutWeight(1.4)
              .enabled(this.hasJoined)
          }
          .width('100%')
          .height(36)
          .borderRadius(4)
          .margin({ top: 8 })

          // 曝光点
          Row() {
            Text('单击预览画面区域设置摄像头曝光点')
              .fontSize(16)
              .fontColor('#636363')
              .layoutWeight(1)

            Button(this.exposurePointX || 'X')
              .fontSize(9)
              .backgroundColor('#00fdfdfb')
              .height(36)
              .fontColor('#636363')
              .type(ButtonType.Normal)
              .border({
                width: {
                  top: 1,
                  right: 1,
                  bottom: 1,
                  left: 1
                },
                color: '#636363',
                radius: 5
              })
              .layoutWeight(0.2)
              .enabled(false)

            Button(this.exposurePointY || 'Y')
              .type(ButtonType.Normal)
              .fontSize(9)
              .backgroundColor('#00fdfdfb')
              .height(36)
              .fontColor('#636363')
              .border({
                width: {
                  top: 1,
                  right: 1,
                  bottom: 1,
                  left: 1
                },
                color: '#636363',
                radius: 5
              })
              .layoutWeight(0.2)
              .enabled(false)

          }
          .width('100%')
          .height(36)
          .borderRadius(4)
          .margin({ top: 8 })

          // 对焦点
          Row() {
            Text('双击预览画面区域设置摄像头对焦点')
              .fontSize(16)
              .fontColor('#636363')
              .layoutWeight(1)

            Button(this.focusPointX || 'X')
              .fontSize(9)
              .backgroundColor('#00fdfdfb')
              .height(36)
              .layoutWeight(0.2)
              .fontColor('#636363')
              .type(ButtonType.Normal)
              .border({
                width: {
                  top: 1,
                  right: 1,
                  bottom: 1,
                  left: 1
                },
                color: '#636363',
                radius: 5
              })
              .enabled(false)

            Button(this.focusPointY || 'Y')
              .fontSize(9)
              .fontColor('#636363')
              .type(ButtonType.Normal)
              .border({
                width: {
                  top: 1,
                  right: 1,
                  bottom: 1,
                  left: 1
                },
                color: '#636363',
                radius: 5
              })
              .backgroundColor('#00fdfdfb')
              .height(36)
              .layoutWeight(0.2)
              .enabled(false)

          }
          .width('100%')
          .height(36)
          .borderRadius(4)
          .margin({ top: 8 })

          // 摄像头自动人脸聚焦
          this.buildSwitchItem('摄像头自动人脸聚焦', this.cameraAutoFaceFocus, (value: boolean) => {
            this.handleAutoFaceFocusChange(value);
          })

          // 闪光灯
          this.buildSwitchItem('闪光灯', this.cameraFlash, (value: boolean) => {
            this.handleFlashChange(value);
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
              this.setupStateVideo();
            }).onTouch((event: TouchEvent) => {
            // 处理触摸开始事件
            if (event.type === TouchType.Down) {
              this.handleStateVideoTouch(event);
            }
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
                this.setupStateVideo();
              }).onTouch((event: TouchEvent) => {
              // 处理触摸开始事件
              if (event.type === TouchType.Down) {
                this.handleStateVideoTouch(event);
              }
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

    // 过滤出该用户的所有视频流
    const userStreams = this.remoteVideoStreams.filter(s => s.uid === uid);

    // 从数组中移除该用户的所有流
    this.remoteVideoStreams = this.remoteVideoStreams.filter(s => s.uid !== uid);

    console.info(`移除用户所有视频成功: ${uid}`);
  }

  // 判断是否显示多人网格布局
  private shouldShowGridLayout(): boolean {
    return this.ShowPreview && this.remoteVideoStreams.length > 0;
  }

  // 设置本地视频
  private setupStateVideo(): void {
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
      console.info('本地视频画布设置完成');
      this.startPreview()
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
        .enabled(this.hasJoined)
    }
    .width('100%')
    .height(36)
    .borderRadius(4)
    .margin({ top: 8 })
  }

  // 切换摄像头
  private async switchCamera(): Promise<void> {
    if (!this.rtcEngine) {
      return;
    }

    try {
      this.rtcEngine.switchCamera();
      this.isFrontCamera = !this.isFrontCamera;

      // 延迟更新变焦和曝光条
      setTimeout(() => {
        this.initZoomSeekBar();
        this.initExposureSeekBar();

        // TODO api暂不支持 检查是否支持自动人脸对焦
        if (this.rtcEngine) {
          // const supported = this.rtcEngine.isCameraAutoFocusFaceModeSupported();
          // if (!supported) {
          //   this.cameraAutoFaceFocus = false;
          // }
        }
      }, 300);
    } catch (error) {
      console.error('切换摄像头失败:', error);
    }
  }

  // 初始化变焦SeekBar
  private initZoomSeekBar(): void {
    if (!this.rtcEngine) {
      return;
    }

    try {
      // 根据新设置：默认1，最大10，最小1
      // 进度计算：(zoom - 1) * 10
      const currZoom = this.rtcEngine.getCurrentZoom();

      // 限制变焦值在1.0到10.0之间
      const clampedZoom = Math.max(1.0, Math.min(10.0, currZoom));
      this.cameraInfo.currZoom = clampedZoom;

      // 计算进度值
      this.zoomSliderValue = Math.round((clampedZoom - 1.0) * 10);
      this.zoomValue = clampedZoom.toFixed(1);

      console.info(`变焦初始化: 当前值=${clampedZoom}, 进度=${this.zoomSliderValue}`);
    } catch (error) {
      console.error('初始化变焦条失败:', error);
    }
  }

  // 初始化曝光SeekBar
  private initExposureSeekBar(): void {
    if (!this.rtcEngine) {
      return;
    }

    try {
      // 获取当前曝光值
      const currExposure = this.rtcEngine.getCurrentExposure();

      // 限制曝光值在-12.0到12.0之间
      const clampedExposure = Math.max(-12.0, Math.min(12.0, currExposure));
      this.cameraInfo.currExposure = clampedExposure;

      // 进度值计算：进度值 = 曝光值 × 10
      this.exposureSliderValue = Math.round(clampedExposure * 10);
      this.exposureValue = clampedExposure.toFixed(1);

      console.info(`曝光初始化: 当前值=${clampedExposure.toFixed(1)}, 进度=${this.exposureSliderValue}`);
    } catch (error) {
      console.error('初始化曝光条失败:', error);
    }
  }

  // 处理变焦变化
  private handleZoomChange(value: number): void {
    if (!this.rtcEngine) {
      return;
    }

    // 根据进度计算变焦值: zoom = 1.0 + (value / 10.0)
    const newZoom = 1.0 + (value / 10.0);

    // 限制变焦值在1.0到10.0之间
    const clampedZoom = Math.max(1.0, Math.min(10.0, newZoom));

    this.rtcEngine.setCameraZoom(clampedZoom);
    this.zoomValue = clampedZoom.toFixed(1);

    console.info(`设置变焦: ${clampedZoom}`);
  }

  // 处理曝光变化
  private handleExposureChange(value: number): void {
    if (!this.rtcEngine) {
      return;
    }

    // 转换公式：曝光值 = 进度值 / 10
    const actualValue = value / 10.0;

    // 限制曝光值在-12.0到12.0之间
    const clampedExposure = Math.max(-12.0, Math.min(12.0, actualValue));

    // 更新状态
    this.exposureSliderValue = value;
    this.exposureValue = this.formatExposureValue(clampedExposure);

    // 调用RTC引擎设置曝光补偿
    try {
      this.rtcEngine.setExposure(clampedExposure);
      console.info(`设置曝光补偿: ${clampedExposure}`);
    } catch (error) {
      console.error('设置曝光补偿失败:', error);
    }
  }

  // 格式化曝光补偿显示值（保留1位小数）
  private formatExposureValue(value: number): string {
    // 处理边界情况
    if (value > 12.0) {
      return '12.0';
    }
    if (value < -12.0) {
      return '-12.0';
    }

    // 保留1位小数，避免浮点数精度问题
    return value.toFixed(1);
  }

  // 重置曝光补偿到默认值
  private resetExposure(): void {
    const defaultExposure = this.EXPOSURE_DEFAULT / 10.0; // 转换为实际值0.0
    this.exposureSliderValue = this.EXPOSURE_DEFAULT;
    this.exposureValue = '0.0';

    if (this.rtcEngine && this.hasJoined) {
      try {
        this.rtcEngine.setExposure(defaultExposure);
        console.info('重置曝光补偿到默认值: 0.0');
      } catch (error) {
        console.error('重置曝光补偿失败:', error);
      }
    }
  }

  // TODO 处理自动人脸对焦切换
  private handleAutoFaceFocusChange(value: boolean): void {
    if (!this.rtcEngine) {
      return;
    }

    // if (this.rtcEngine.isCameraAutoFocusFaceModeSupported()) {
    //   this.rtcEngine.setCameraAutoFocusFaceModeEnabled(value);
    // } else {
    //   promptAction.showToast({
    //     message: '不支持摄像头自动人脸对焦模式',
    //     duration: 2000
    //   });
    //   this.cameraAutoFaceFocus = false;
    // }
  }

  // 处理闪光灯切换
  private handleFlashChange(value: boolean): void {
    if (!this.rtcEngine) {
      return;
    }

    this.rtcEngine.setCameraFlash(value);
  }

  // 改进触摸事件处理
  private handleStateVideoTouch(event: TouchEvent): void {
    if (!this.rtcEngine || !event.touches || event.touches.length === 0) {
      return;
    }

    // 获取第一个触摸点
    const touch = event.touches[0];
    const touchX = touch.x;
    const touchY = touch.y;
    const currentTime = Date.now();

    // 检查是否为双击
    if (currentTime - this.lastTapTime < this.doubleTapTimeout) {
      // 双击 - 设置对焦点
      // 清除之前设置的单击定时器
      if (this.clickTimerId !== -1) {
        clearTimeout(this.clickTimerId);
        this.clickTimerId = -1;
      }

      this.handleDoubleTap(touchX, touchY);
      this.lastTapTime = 0;
    } else {
      // 单击 - 设置曝光点
      // 清除之前的定时器（如果有）
      if (this.clickTimerId !== -1) {
        clearTimeout(this.clickTimerId);
        this.clickTimerId = -1;
      }

      this.lastTapTime = currentTime;

      // 设置新的定时器
      this.clickTimerId = setTimeout(() => {
        // 检查是否仍然是单击（不是双击的一部分）
        if (this.lastTapTime !== 0) {
          this.handleSingleTap(touchX, touchY);
        }
        this.lastTapTime = 0;
        this.clickTimerId = -1;
      }, this.doubleTapTimeout) as number;
    }
  }

  // 处理单击（设置曝光点）
  private handleSingleTap(touchX: number, touchY: number): void {
    if (!this.rtcEngine) {
      return;
    }

    // 获取归一化坐标
    const normalizedCoords = this.getNormalizedCoordinates(touchX, touchY);
    if (normalizedCoords[0] !== -1 && normalizedCoords[1] !== -1) {
      this.rtcEngine.setCameraExposurePoint(normalizedCoords[0], normalizedCoords[1]);
      this.exposurePointX = normalizedCoords[0].toFixed(2);
      this.exposurePointY = normalizedCoords[1].toFixed(2);
      console.info('设置曝光点:', this.exposurePointX, this.exposurePointY);
    }
  }

  // 处理双击（设置对焦点）
  private handleDoubleTap(touchX: number, touchY: number): void {
    if (!this.rtcEngine) {
      return;
    }

    // 获取归一化坐标
    const normalizedCoords = this.getNormalizedCoordinates(touchX, touchY);
    if (normalizedCoords[0] !== -1 && normalizedCoords[1] !== -1) {
      this.rtcEngine.setCameraFocusPoint(normalizedCoords[0], normalizedCoords[1]);
      this.focusPointX = normalizedCoords[0].toFixed(2);
      this.focusPointY = normalizedCoords[1].toFixed(2);
      console.info('设置对焦点:', this.focusPointX, this.focusPointY);
    }
  }

  // 获取归一化坐标
  private getNormalizedCoordinates(touchX: number, touchY: number): number[] {
    const componentWidth = 180;
    const componentHeight = 180; // 修改为实际高度

    if (componentWidth <= 0 || componentHeight <= 0) {
      return [-1.0, -1.0];
    }

    // 计算归一化坐标
    const cameraX = touchX / componentWidth;
    const cameraY = touchY / componentHeight;

    // 确保坐标在0-1之间
    return [
      Math.max(0, Math.min(1, cameraX)),
      Math.max(0, Math.min(1, cameraY))
    ];
  }

  // 处理加入/离开房间
  private async handleJoinRoom(): Promise<void> {
    if (this.hasJoined) {
      this.destroyRtcEngine();
      this.hasJoined = false;
      this.ShowPreview = false;
      prompt.showToast({ message: 'Leave Channel', duration: 2000 });
    } else {
      try {
        // 验证必要参数
        if (!this.channelId.trim()) {
          prompt.showToast({ message: '请输入频道ID', duration: 2000 });
          return;
        }

        // 初始化RTC引擎
        await this.initAndSetupRtcEngine();

        // 开始本地预览
        await this.startPreview();

        // 加入频道
        await this.joinChannel();

        this.hasJoined = true;
        this.ShowPreview = true;

        // 初始化变焦和曝光条
        this.initZoomSeekBar();
        this.initExposureSeekBar();

        console.info('成功加入房间');

      } catch (error) {
        console.error('加入房间失败:', error);
        prompt.showToast({
          message: `加入房间失败: ${error}`,
          duration: 3000
        });
        this.hasJoined = false;
        this.ShowPreview = false;
      }
    }
  }

  // 初始化并设置RTC引擎
  private async initAndSetupRtcEngine(): Promise<boolean> {
    if (this.rtcEngine) {
      return true;
    }

    if (!this.context) {
      throw new Error('Context未初始化');
    }

    try {
      // 创建RTC引擎实例
      this.rtcEngine = AliRtcEngine.getInstance('', this.context);
      if (this.rtcEngine === undefined) {
        promptAction.showToast({ message: 'RTC引擎未初始化成功', duration: 2000 });
        return  false;
      }
      // 设置事件监听器
      this.setupEventListeners();

      // 设置频道模式为互动模式
      this.rtcEngine.setChannelProfile(AliRtcChannelProfile.AliRtcInteractiveLive);

      // 设置用户角色
      this.rtcEngine.setClientRole(AliRtcClientRole.AliRtcClientRoleInteractive);

      // 设置音频配置
      this.rtcEngine.setAudioProfile(
        AliRtcAudioProfile.AliRtcHighQualityMode,
        AliRtcAudioScenario.AliRtcSceneMusicMode
      );

      // 设置视频编码参数
      const videoEncoderConfig = new AliRtcVideoEncoderConfiguration();
      videoEncoderConfig.dimensions.width = 720;
      videoEncoderConfig.dimensions.height = 1280;
      videoEncoderConfig.frameRate = 20;
      videoEncoderConfig.bitrate = 1200;
      videoEncoderConfig.keyFrameInterval = 2000;
      videoEncoderConfig.orientationMode = AliRtcVideoEncoderOrientationMode.AliRtcVideoEncoderOrientationModeAdaptive;
      this.rtcEngine.setVideoEncoderConfiguration(videoEncoderConfig);

      // 发布本地音视频流
      this.rtcEngine.publishLocalAudioStream(true);
      this.rtcEngine.publishLocalVideoStream(true);

      // 设置默认订阅远端的音频和视频流
      this.rtcEngine.setDefaultSubscribeAllRemoteAudioStreams(true);
      this.rtcEngine.subscribeAllRemoteAudioStreams(true);
      this.rtcEngine.setDefaultSubscribeAllRemoteVideoStreams(true);
      this.rtcEngine.subscribeAllRemoteVideoStreams(true);

      console.info('RTC引擎初始化完成');
      return true;
    } catch (error) {
      console.error('RTC引擎初始化失败:', error);
      return false;
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
      });

      this.rtcEventListener.onLeaveChannel((resultCode: number) => {
        console.info(`离开频道结果: result=${resultCode}`);
        prompt.showToast({
          message: 'Leave Channel',
          duration: 2000
        });
      });

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
      })

      this.rtcEventListener.onLocalDeviceException((deviceType: number, exceptionType: number, msg: string) => {
        console.error(`本地设备异常: ${msg}`);
        promptAction.showToast({
          message: `设备异常: ${msg}`,
          duration: 3000
        });
      });

      this.rtcEventListener.onBye((code: number) => {
        console.info(`被服务器踢出: code=${code}`);
        promptAction.showToast({
          message: `被服务器踢出: ${code}`,
          duration: 3000
        });
        this.destroyRtcEngine();
      });
    }

    this.rtcEngine.setRtcEngineEventListener(this.rtcEventListener);
  }

  // 开始预览
  private async startPreview(): Promise<boolean> {
    if (!this.rtcEngine) {
      return false;
    }

    try {
      // 获取surfaceId
      const surfaceId = this.xcomponentController.getXComponentSurfaceId();
      if (!surfaceId) {
        console.error('surfaceId获取为空');
        return false;
      }

      // 创建视频画布
      this.aliRtcVideoCanvas = new AliRtcVideoCanvas();
      this.aliRtcVideoCanvas.surfaceId = surfaceId;
      this.aliRtcVideoCanvas.renderMode = AliRtcRenderMode.AliRtcRenderModeAuto;
      this.aliRtcVideoCanvas.mirrorMode = AliRtcRenderMirrorMode.AliRtcRenderMirrorModeAllMirror;

      // 设置本地视频配置
      this.rtcEngine.setLocalViewConfig(
        this.aliRtcVideoCanvas,
        this.componentController,
        AliRtcVideoTrack.AliRtcVideoTrackCamera
      );

      // 开始预览
      this.rtcEngine.startPreview();

      console.info('本地预览已启动');
      return true;
    } catch (error) {
      console.error('启动预览失败:', error);
      return false;
    }
  }

  // 加入频道
  private async joinChannel(): Promise<void> {
    if (!this.rtcEngine || !this.channelId.trim()) {
      throw new Error('RTC引擎未初始化或频道ID为空');
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
      console.info('相机控制 Token:', base64Token.substring(0, 20) + '...');

      const result = this.rtcEngine.joinChannelWithToken(base64Token, '', '', '相机功能用户');
      console.info('加入频道调用结果:', result);
    } catch (error) {
      console.error('加入频道失败:', error);
    }
  }

  // 销毁RTC引擎
  private destroyRtcEngine(): void {
    if (this.rtcEngine) {
      try {
        if (this.hasJoined) {
          this.rtcEngine.stopPreview();
          this.rtcEngine.leaveChannel();
        }
        this.rtcEngine = undefined;
      } catch (error) {
        console.error('销毁RTC引擎失败:', error);
      }
    }

    // 重置状态
    this.hasJoined = false;
    this.ShowPreview = false;
    this.remoteVideoStreams = [];

    this.aliRtcVideoCanvas = undefined;
  }
}