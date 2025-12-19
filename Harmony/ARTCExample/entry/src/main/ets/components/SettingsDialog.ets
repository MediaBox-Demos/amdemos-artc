import { SettingsData } from 'common/src/main/ets/common/Constants';
import { LightStorage } from 'common/src/main/ets/components/LightStorage';
import { AliRtcEngine } from "@aliyun_video_cloud/alivcsdk_artc/src/main/ets/a/b";

@CustomDialog
export struct SettingsDialog {
  controller: CustomDialogController;
  // 设置参数
  @State appId: string = '';
  @State appKey: string = '';
  @State userId: string = '3562365';
  @State sdkVersion: string = '';
  @State sdkRegion: number = 0;

  async aboutToAppear(): Promise<void> {
    try {
      // 获取sdk版本信息
      this.sdkVersion = AliRtcEngine.getSDKVersion()
      const data = await LightStorage.instance?.getObject<SettingsData>('settingData');
      if (data) {
        this.appId = data.appId!;
        this.appKey = data.appKey!;
        this.userId = data.userId!;
        this.sdkRegion = Number(data.sdkRegion); // 确保类型转换
      }
    } catch (error) {
      console.error('Failed to load settings:', error);
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
        // AppId
        Row() {
          Text('AppId:')
            .fontSize(12)
            .fontColor('#fff')

          Text(this.appId)
            .fontSize(12)
            .fontColor('#fff')
            .layoutWeight(1)
            .textAlign(TextAlign.Start)
        }
        .width('100%')
        .padding({ bottom: 12 })

        // AppKey
        Row() {
          Text('AppKey:')
            .fontSize(12)
            .fontColor('#fff')


          Text(this.appKey)
            .fontSize(12)
            .fontColor('#fff')
            .layoutWeight(1)
            .textAlign(TextAlign.Start)
        }
        .width('100%')
        .padding({ top: 12, bottom: 12 })

        // UserId
        Row() {
          Text('UserId:')
            .fontSize(12)
            .fontColor('#fff')

          TextInput({ text: this.userId })
            .fontSize(12)
            .height(28)
            .padding({ left: 3 })
            .fontColor('#fff')
            .layoutWeight(1)
            .textAlign(TextAlign.Start)
            .border({
              // 只设置底部边框
              width: {
                top: 0,
                right: 0,
                bottom: 1,
                left: 0
              },
              color: '#007DFF', // 下划线颜色
              radius: 0
            })
            .onChange((text) => {
              this.userId = text;
            })
        }
        .width('100%')
        .padding({ top: 12, bottom: 12 })

        // SDK Version
        Row() {
          Text('SDK Version:')
            .fontSize(12)
            .fontColor('#fff')


          Text(this.sdkVersion)
            .fontSize(12)
            .fontColor('#fff')
            .layoutWeight(1)
            .textAlign(TextAlign.Start)
        }
        .width('100%')
        .padding({ top: 12, bottom: 12 })

        // SDK Region
        Row() {
          Text('SDK Region:')
            .fontSize(12)
            .fontColor('#fff')


          Text('CN')
            .fontSize(12)
            .fontColor('#fff')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .borderWidth(1)
            .borderColor(this.sdkRegion === 0 ? '#496b78' : '#31343b')
            .height(40)
            .borderRadius(20)
            .margin(10)
            .onClick(() => {
              this.sdkRegion = 0;
            })

          Text('SEA')
            .fontSize(12)
            .fontColor('#fff')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .borderWidth(1)
            .borderColor(this.sdkRegion === 1 ? '#496b78' : '#31343b')
            .height(40)
            .margin(10)
            .borderRadius(20)
            .onClick(() => {
              this.sdkRegion = 1;
            })


        }
        .width('100%')
        .padding({ top: 12, bottom: 12 })
      }
      .width('100%')
      .padding({ left: 24, right: 24, bottom: 8 })
      .backgroundColor('#000')

      Row({ space: 16 }) {
        Text('确定')
          .layoutWeight(1)
          .height(48)
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#000')
          .borderRadius(8)
          .textAlign(TextAlign.Center)
          .onClick(async () => {
            const settings: SettingsData = {
              appId: this.appId,
              appKey: this.appKey,
              userId: this.userId,
              sdkVersion: this.sdkVersion,
              sdkRegion: this.sdkRegion.toString()
            };

            try {
              await LightStorage.instance?.putObject('settingData', settings);
            } catch (error) {
              console.error('Failed to load settings:', error);
            }

            this.controller.close();
          })
        Blank()
          .width(0.5)
          .height(48)
          .color('#E5E5E5')
        Text('取消')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .height(48)
          .fontSize(16)
          .fontColor('#4e7e93')
          .backgroundColor('#000')
          .borderRadius(8)
          .onClick(() => {
            this.controller.close(); // 直接关闭，不需要回调
          })
      }
      .width('100%')
      .padding({
        left: 24,
        right: 24
      })
      .backgroundColor('#000')
    }
    .margin(20)
    .backgroundColor('#000')
    .borderRadius(12)

  }
}