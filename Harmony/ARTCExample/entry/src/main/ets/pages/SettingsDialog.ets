import { SettingsData } from "../common/Constants";
import { LightStorage } from '../common/components/LightStorage';
import { AliRtcEngine } from "@aliyun_video_cloud/alivcsdk_artc";
import { ARTCTokenHelper } from '../common/keycenter/ARTCTokenHelper';
import { GlobalConfig } from '../common/keycenter/GlobalConfig';

@CustomDialog
export struct SettingsDialog {
  controller: CustomDialogController;
  // 设置参数
  @State appId: string = '';
  @State appKey: string = '';
  @State userId: string = '';
  @State sdkVersion: string = '';
  @State sdkRegion: string = 'cn';

  async aboutToAppear(): Promise<void> {
    try {
      // 获取 SDK 版本信息
      this.sdkVersion = AliRtcEngine.getSDKVersion();

      // 从 GlobalConfig 获取默认值
      const global: GlobalConfig = GlobalConfig.getInstance();
      this.appId = await global.getAppId();
      this.appKey = await global.getAppKey();
      this.userId = await global.getUserId();
      this.sdkRegion = await global.getSdkRegion();

      // 尝试从 LightStorage 读取用户自定义配置（如果有）
      const data: SettingsData | undefined | null = await LightStorage.instance?.getObject<SettingsData>('settingData');
      if (data) {
        if (data.userId) {
          this.userId = data.userId;
        }
        if (data.sdkRegion) {
          this.sdkRegion = data.sdkRegion;
        }
      }
    } catch (err) {
      console.error('Failed to load settings:', err);
    }
  }

  build() {
    Column() {
      // 弹窗标题
      Column() {
        Text('设置')
          .fontSize(18)
          .fontColor('#fff')
      }
      .width('100%')
      .padding(24)
      .backgroundColor('#000')

      // 设置项列表
      Column() {
        // AppId（可编辑）
        Row() {
          Text('AppId:')
            .fontSize(12)
            .fontColor('#fff')
            .width(100)

          TextInput({ text: this.appId })
            .fontSize(12)
            .height(28)
            .padding({ left: 3 })
            .fontColor('#fff')
            .layoutWeight(1)
            .textAlign(TextAlign.Start)
            .backgroundColor('#1a1a1a')
            .border({
              width: {
                top: 0,
                right: 0,
                bottom: 1,
                left: 0
              },
              color: '#007DFF',
              radius: 0
            })
            .onChange((text) => {
              this.appId = text;
            })
        }
        .width('100%')
        .padding({ bottom: 12 })

        // AppKey（可编辑）
        Row() {
          Text('AppKey:')
            .fontSize(12)
            .fontColor('#fff')
            .width(100)

          TextInput({ text: this.appKey })
            .fontSize(12)
            .height(28)
            .padding({ left: 3 })
            .fontColor('#fff')
            .layoutWeight(1)
            .textAlign(TextAlign.Start)
            .backgroundColor('#1a1a1a')
            .border({
              width: {
                top: 0,
                right: 0,
                bottom: 1,
                left: 0
              },
              color: '#007DFF',
              radius: 0
            })
            .onChange((text) => {
              this.appKey = text;
            })
        }
        .width('100%')
        .padding({ top: 12, bottom: 12 })

        // UserId（可编辑）
        Row() {
          Text('UserId:')
            .fontSize(12)
            .fontColor('#fff')
            .width(100)

          TextInput({ text: this.userId })
            .fontSize(12)
            .height(28)
            .padding({ left: 3 })
            .fontColor('#fff')
            .layoutWeight(1)
            .textAlign(TextAlign.Start)
            .backgroundColor('#1a1a1a')
            .border({
              width: {
                top: 0,
                right: 0,
                bottom: 1,
                left: 0
              },
              color: '#007DFF',
              radius: 0
            })
            .onChange((text) => {
              this.userId = text;
            })
        }
        .width('100%')
        .padding({ top: 12, bottom: 12 })

        // SDK Version（只读）
        Row() {
          Text('SDK Version:')
            .fontSize(12)
            .fontColor('#fff')
            .width(100)

          Text(this.sdkVersion)
            .fontSize(12)
            .fontColor('#aaa')
            .layoutWeight(1)
            .textAlign(TextAlign.Start)
        }
        .width('100%')
        .padding({ top: 12, bottom: 12 })

        // SDK Region（可选择）
        Row() {
          Text('SDK Region:')
            .fontSize(12)
            .fontColor('#fff')
            .width(100)

          Text('CN')
            .fontSize(12)
            .fontColor('#fff')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .borderWidth(1)
            .borderColor(this.sdkRegion === 'cn' ? '#007DFF' : '#31343b')
            .backgroundColor(this.sdkRegion === 'cn' ? '#1a3a5a' : 'transparent')
            .height(40)
            .borderRadius(20)
            .margin(10)
            .onClick(() => {
              this.sdkRegion = 'cn';
            })

          Text('SEA')
            .fontSize(12)
            .fontColor('#fff')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .borderWidth(1)
            .borderColor(this.sdkRegion === 'sea' ? '#007DFF' : '#31343b')
            .backgroundColor(this.sdkRegion === 'sea' ? '#1a3a5a' : 'transparent')
            .height(40)
            .margin(10)
            .borderRadius(20)
            .onClick(() => {
              this.sdkRegion = 'sea';
            })
        }
        .width('100%')
        .padding({ top: 12, bottom: 12 })
      }
      .width('100%')
      .padding({ left: 24, right: 24, bottom: 8 })
      .backgroundColor('#000')

      // 按钮区域
      Row({ space: 16 }) {
        Text('确定')
          .layoutWeight(1)
          .height(48)
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#007DFF')
          .borderRadius(8)
          .textAlign(TextAlign.Center)
          .onClick(async () => {
            try {
              // 保存用户设置到 GlobalConfig
              const global: GlobalConfig = GlobalConfig.getInstance();
              await global.setUserId(this.userId);
              await global.setSdkRegion(this.sdkRegion);
              await global.setAppId(this.appId);
              await global.setAppKey(this.appKey);

              // 同时保存到 LightStorage（兼容现有逻辑）
              const settings: SettingsData = {
                appId: this.appId,
                appKey: this.appKey,
                userId: this.userId,
                sdkVersion: this.sdkVersion,
                sdkRegion: this.sdkRegion
              };
              await LightStorage.instance?.putObject('settingData', settings);

              console.info('设置已保存:', settings);
            } catch (err) {
              console.error('Failed to save settings:', err);
            }

            this.controller.close();
          })

        Blank()
          .width(0.5)
          .height(48)
          .backgroundColor('#333')

        Text('取消')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .height(48)
          .fontSize(16)
          .fontColor('#999')
          .backgroundColor('#1a1a1a')
          .borderRadius(8)
          .onClick(() => {
            this.controller.close();
          })
      }
      .width('100%')
      .padding({
        left: 24,
        right: 24,
        bottom: 20
      })
      .backgroundColor('#000')
    }
    .margin(20)
    .backgroundColor('#000')
    .borderRadius(12)
  }
}
