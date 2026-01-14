import { ISelectOption } from "../../../common/Constants";
import { VideoConfig } from "../common/VideoConfig";
import { promptAction } from "@kit.ArkUI";
import { AliRtcCaptureOutputPreference } from "@aliyun_video_cloud/alivcsdk_artc";


@CustomDialog
export struct VideoConfigDialog {
  controller: CustomDialogController;
  @Link config: VideoConfig;
  callBack: (config: VideoConfig) => void = () => {
  }

  build() {
    Column() {
      Stack() {
        Row({ space: 8 }) {
          // 标题
          Text('视频配置')
            .fontSize(20)
            .fontColor('#fff')
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .height(46)
        .backgroundColor('#590ce4')

        Text('确定')
          .fontSize(15)
          .fontColor('#448cfe')
          .onClick(() => {
            // 应用配置并触发回调
            this.applyConfiguration();
            this.controller.close();
          })
          .height('100%')
          .textAlign(TextAlign.Center)
          .position({
            right: 30
          })
      }.height(46)

      // 配置内容
      Scroll() {
        Column() {
          // 摄像头采集配置部分
          this.buildCameraConfigSection()

          // 视频编码配置部分
          this.buildVideoConfigSection()
        }
        .padding({ bottom: 40 })
      }
      .width('100%')
      .scrollBar(BarState.Off)
      .backgroundColor('#fff')
    }
    .width('100%')
    .height('90%')
    .backgroundColor(Color.White)
  }

  @Builder
  private buildCameraConfigSection() {
    Column() {
      Row() {
        Text('摄像头采集配置(开启摄像头前设置)')
          .fontSize(18)
          .fontColor('#636363')
      }
      .width('100%')
      .height(35)
      .backgroundColor('#e0e0e0')
      .padding({ left: 12 })

      Column() {
        // 摄像头采集偏好
        this.buildConfigItem('摄像头采集偏好',
          this.getCameraPreferenceString(),
          ['SDK Auto', 'Performance Priority', 'Preview Priority'],
          (value: string) => {
            this.config.cameraPreference = this.getCameraPreferenceIndex(value);
          })

        // 摄像头方向
        this.buildConfigItem('摄像头方向',
          this.getCameraDirectionString(),
          ['前置', '后置'],
          (value: string) => {
            this.config.cameraDirection = value === '前置' ? 1 : 0;
          })

        // 帧率
        this.buildInputItem('帧率', this.config.fps.toString(),
          (value: string) => {
            let frameRate = parseInt(value) || 15;
            if (frameRate > 30) {
              frameRate = 30;
              promptAction.showToast({
                message: '帧率最大为30',
                duration: 1000
              });
            }
            if (frameRate < 0) {
              frameRate = -1;
            }
            this.config.fps = frameRate;
          })

        // 分辨率
        this.buildConfigItem('分辨率',
          this.getResolutionString(),
          ['default', '1080P'],
          (value: string) => {
            this.config.cameraCaptureProfile = value === 'default' ? 0 : 1;
          })

        // 是否启用纹理编码
        this.buildSwitchItem('是否启用纹理编码',
          this.config.textureEncode,
          (value: boolean) => {
            this.config.textureEncode = value;
          })

        // 摄像头纹理采集
        this.buildSwitchItem('摄像头纹理采集',
          this.config.cameraTextureCapture,
          (value: boolean) => {

            this.config.cameraTextureCapture = value;
          })
      }
    }
    .width('100%')
  }

  // 构建视频编码配置部分
  @Builder
  private buildVideoConfigSection() {
    Column() {
      Row() {
        Text('视频编码配置')
          .fontSize(18)
          .fontColor('#636363')
      }
      .backgroundColor('#e0e0e0')
      .width('100%')
      .padding({ left: 12 })
      .height(35)

      Column() {
        // 宽度
        this.buildInputItem('宽度', this.config.width.toString(),
          (value: string) => {
            const width = parseInt(value) || 640;
            this.config.width = width;
          })

        // 高度
        this.buildInputItem('高度', this.config.height.toString(),
          (value: string) => {
            const height = parseInt(value) || 480;
            this.config.height = height;
          })

        // 帧率
        this.buildInputItem('帧率', this.config.frameRate.toString(),
          (value: string) => {
            let frameRate = parseInt(value) || 15;
            if (frameRate > 30) {
              frameRate = 30;
              promptAction.showToast({
                message: '帧率最大为30',
                duration: 1000
              });
            }
            if (frameRate <= 1) {
              frameRate = 1;
            }
            this.config.frameRate = frameRate;
          })

        // 码率(kbps)
        this.buildInputItem('码率(kbps)', this.config.bitrate.toString(),
          (value: string) => {
            const bitrate = parseInt(value) || 512;
            this.config.bitrate = bitrate;
          })

        // 关键帧间隔（毫秒）
        this.buildInputItem('关键帧间隔（毫秒）', this.config.keyFrameInterval.toString(),
          (value: string) => {
            let keyFrameInterval = parseInt(value) || 0;
            this.config.keyFrameInterval = keyFrameInterval;
          })

        // 是否强制关键帧间隔
        this.buildSwitchItem('是否强制关键帧间隔',
          this.config.forceStrictKeyFrameInterval,
          (value: boolean) => {
            this.config.forceStrictKeyFrameInterval = value;
          })

        // 视频输出方向
        this.buildConfigItem('视频输出方向',
          this.getOrientationModeString(),
          ['跟随采集', '固定横屏', '固定竖屏'],
          (value: string) => {
            this.config.orientationMode =
              value === '跟随采集' ? 0 :
                value === '固定横屏' ? 1 : 2;
          })

        // 视频旋转模式
        this.buildConfigItem('旋转模式',
          this.config.rotationMode.toString(),
          ['0', '90', '180', '270'],
          (value: string) => {
            this.config.rotationMode = parseInt(value) || 0;
          })

        // 视频编码类型
        this.buildConfigItem('编码类型',
          this.config.encodeCodecType === 0 ? 'H264' : 'H265',
          ['H264', 'H265'],
          (value: string) => {
            this.config.encodeCodecType = value === 'H264' ? 0 : 1;
          })

        // 视频编码模式
        this.buildConfigItem('编码模式',
          this.getCodecTypeString(),
          ['软件编码', '硬件编码', '硬件纹理编码'],
          (value: string) => {
            this.config.codecType =
              value === '软件编码' ? 0 :
                value === '硬件编码' ? 1 : 2;
          })
      }
    }
    .width('100%')
  }

  @Builder
  private buildConfigItem(label: string, value: string, options: string[], onClick: (value: string) => void) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor('#636363')
        .layoutWeight(1)

      Select(options.map((option: string) => {
        return { value: option } as ISelectOption;
      }))
        .selected(options.indexOf(value) >= 0 ? options.indexOf(value) : 0)
        .value(value)
        .font({ size: 16 })
        .fontColor('#000')
        .backgroundColor('#fff')
        .onSelect((index: number) => {
          if (index >= 0 && index < options.length) {
            const selectedValue = options[index];
            onClick(selectedValue);
          }
        })
        .width(130)
        .margin({ right: 8 })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .borderRadius(4)
    .margin({ top: 8 })
  }

  @Builder
  private buildSwitchItem(label: string, value: boolean, onValueChange: (value: boolean) => void) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor('#333333')
        .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: value })
        .onChange((isOn: boolean) => {
          onValueChange(isOn);
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .borderRadius(4)
    .margin({ top: 8 })
  }

  @Builder
  private buildInputItem(label: string, value: string, onValueChange: (value: string) => void) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor('#333333')
        .layoutWeight(1)

      TextInput({
        text: value
      })
        .width(120)
        .height(40)
        .fontSize(16)
        .fontColor('#000')
        .textAlign(TextAlign.Center)
        .backgroundColor(Color.White)
        .border({
          width: {
            top: 0,
            right: 0,
            bottom: 1,
            left: 0
          },
          color: '#000',
          radius: 0
        })
        .onChange((text: string) => {
          onValueChange(text);
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .borderRadius(4)
    .backgroundColor(Color.White)
    .margin({ top: 8 })
  }

  // 应用配置并触发回调
  private applyConfiguration() {
    this.adjustConfigValues();
    // 触发回调
    this.callBack(this.config)
  }

  private adjustConfigValues() {
    // 摄像头帧率调整（根据Android代码：>30设为30，<0设为-1）
    if (this.config.fps > 30) {
      this.config.fps = 30;
    } else if (this.config.fps < 0) {
      this.config.fps = -1;
    }

    // 编码帧率调整（根据Android代码：>30设为30，<=1设为1）
    if (this.config.frameRate > 30) {
      this.config.frameRate = 30;
    } else if (this.config.frameRate <= 1) {
      this.config.frameRate = 1;
    }

    // 关键帧间隔（根据Android代码：只有大于1时才设置）
    if (this.config.keyFrameInterval <= 1) {
      this.config.keyFrameInterval = 0;
    }
  }

  // 辅助方法
  private getCameraPreferenceString(): string {
    switch (this.config.cameraPreference) {
      case 0:
        return 'SDK Auto';
      case 1:
        return 'Performance Priority';
      case 2:
        return 'Preview Priority';
      default:
        return 'SDK Auto';
    }
  }

  private getCameraPreferenceIndex(value: string): AliRtcCaptureOutputPreference {
    switch (value) {
      case 'SDK Auto':
        return AliRtcCaptureOutputPreference.AliRtcCaptureOutputPreferenceAuto;
      case 'Performance Priority':
        return AliRtcCaptureOutputPreference.AliRtcCaptureOutputPreferencePerformance;
      case 'Preview Priority':
        return AliRtcCaptureOutputPreference.AliRtcCaptureOutputPreferencePreview;
      default:
        return AliRtcCaptureOutputPreference.AliRtcCaptureOutputPreferenceAuto;
    }
  }

  private getCameraDirectionString(): string {
    return this.config.cameraDirection === 0 ? '后置' : '前置';
  }

  private getResolutionString(): string {
    return this.config.cameraCaptureProfile === 0 ? 'default' : '1080P';
  }

  private getOrientationModeString(): string {
    switch (this.config.orientationMode) {
      case 0:
        return '跟随采集';
      case 1:
        return '固定横屏';
      case 2:
        return '固定竖屏';
      default:
        return '固定横屏';
    }
  }

  private getCodecTypeString(): string {
    switch (this.config.codecType) {
      case 0:
        return '软件编码';
      case 1:
        return '硬件编码';
      case 2:
        return '硬件纹理编码';
      default:
        return '软件编码';
    }
  }
}