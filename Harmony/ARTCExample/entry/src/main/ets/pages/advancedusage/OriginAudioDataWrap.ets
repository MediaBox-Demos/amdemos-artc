import { AliRtcEngine } from "@aliyun_video_cloud/alivcsdk_artc";
import { CustomTitle } from "../../common/components/CustomTitle"
import { OriginAudioData } from "libadvancedusage.so"
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { GlobalConfig } from '../../common/keycenter/GlobalConfig';
import { ARTCTokenHelper } from '../../common/keycenter/ARTCTokenHelper';

@Component
export struct OriginAudioDataWrap {
  @State AppId: string = '';
  @State AppKey: string = '';
  @State UserId: string = '';
  @State Token: string = '';
  private rtcEngine: AliRtcEngine | undefined;
  private native: OriginAudioData | undefined;
  @State hasJoined: boolean = false;
  @State channelId: string = Date.now().toString().slice(-6);
  @State localUserId: string = '';
  @State isAudioProcessingEnabled: boolean = false;
  private context: common.UIAbilityContext | undefined;

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

  private initRtcEngine(): void {
    if (!this.context) {
      promptAction.showToast({ message: '上下文未初始化', duration: 2000 });
      return;
    }

    this.rtcEngine = AliRtcEngine.getInstance('', this.context);
    if (!this.rtcEngine) {
      promptAction.showToast({ message: 'RTC引擎初始化失败', duration: 2000 });
      return;
    }

    // 设置基本音频配置
    this.rtcEngine.setAudioProfile(3, 1);

    // 启用音频
    this.rtcEngine.startAudioCapture();

    const handle: number | undefined = this.rtcEngine.getNativeHandle();
    if (handle) {
      const native: OriginAudioData = new OriginAudioData(handle);
      this.native = native
    }
  }

  private async joinChannel(): Promise<void> {
    if (!this.rtcEngine || !this.channelId.trim()) {
      promptAction.showToast({ message: '频道ID不能为空', duration: 2000 });
      return;
    }

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

      const result: number = this.rtcEngine.joinChannelWithToken(token, '', '', '音频原始数据测试');
      console.info('加入频道调用结果:', result);

      this.hasJoined = true;
      this.localUserId = this.UserId;

      promptAction.showToast({ message: '加入频道成功', duration: 2000 });
    } catch (error) {
      const err = error as Error;
      console.error('加入频道失败:', err);
      promptAction.showToast({ message: `加入频道失败: ${err.message}`, duration: 3000 });
    }
  }

  private leaveChannel(): void {
    if (this.rtcEngine) {
      this.rtcEngine.leaveChannel();
      this.hasJoined = false;
      this.localUserId = '';

      if (this.native && this.isAudioProcessingEnabled) {
        this.native.enable(false);
        this.isAudioProcessingEnabled = false;
      }

      promptAction.showToast({ message: '离开频道', duration: 2000 });
    }
  }

  private toggleAudioProcessing(): void {
    if (this.native && this.rtcEngine) {
      const newState: boolean = !this.isAudioProcessingEnabled;
      const result: number = this.native.enable(newState);
      console.info(`切换原始音频数据处理: ${newState}, 结果: ${result}`);

      if (result === 0) {
        this.isAudioProcessingEnabled = newState;
      }

      promptAction.showToast({
        message: `原始音频数据处理${newState ? '开启' : '关闭'}, 结果: ${result}`,
        duration: 2000
      });
    } else {
      promptAction.showToast({ message: 'RTC引擎或原生模块未初始化', duration: 2000 });
    }
  }

  aboutToDisappear(): void {
    if (this.hasJoined) {
      this.leaveChannel();
    }

    // 清理资源
    if (this.native && this.isAudioProcessingEnabled) {
      this.native.enable(false);
    }
  }

  build() {
    NavDestination() {
      Column() {
        CustomTitle({
          titleText: '获取原始音频数据C++',
        })

        Scroll() {
          // 频道信息
          Column() {
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

          // 加入/离开频道按钮
          Button(this.hasJoined ? '离开频道' : '加入频道')
            .width('80%')
            .margin({ top: 20 })
            .onClick(() => {
              if (this.hasJoined) {
                this.leaveChannel();
              } else {
                this.joinChannel();
              }
            })

          Text(this.hasJoined ? `已加入频道: ${this.channelId}` : '未加入频道')
            .fontSize(14)
            .fontColor('#666')
            .margin({ top: 10 })

          Row() {
            Text('原始音频数据处理:')
              .fontSize(16)
              .fontColor('#333')
              .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.isAudioProcessingEnabled })
              .onChange((isOn: boolean): void => {
                if (this.native) {
                  const result: number = this.native.enable(isOn);
                  if (result === 0) {
                    this.isAudioProcessingEnabled = isOn;
                  }
                  console.info(`音频处理状态切换: ${isOn}, 结果: ${result}`);
                }
              })
          }
          .margin({ top: 30 })

          Button('切换音频处理状态')
            .width('80%')
            .margin({ top: 10 })
            .onClick(() => {
              this.toggleAudioProcessing();
            })
          }
          .margin(12)
        }
        .align(Alignment.TopStart)
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .width('100%')
        .layoutWeight(1)
      }
      .align(Alignment.TopStart)
      .width('100%')
      .height('100%')
      .backgroundColor('#f5f5f5')
    }
    .hideTitleBar(true)
  }
}
