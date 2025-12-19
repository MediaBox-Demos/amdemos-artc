import { CustomTitle } from 'common/src/main/ets/components/CustomTitle';
import {
  AliRtcEngine,
  AliRtcEngineAuthInfo,
  AliRtcEngineEventListener,
  AliRtcChannelProfile,
  AliRtcClientRole,
  AliRtcAudioProfile,
  AliRtcAudioScenario
} from '@aliyun_video_cloud/alivcsdk_artc';
import common from '@ohos.app.ability.common';
import { prompt } from '@kit.ArkUI';
import { LightStorage } from 'common/src/main/ets/components/LightStorage';
import { SettingsData } from 'common/src/main/ets/common/Constants';
import { ARTCTokenHelper } from 'keycenter/src/main/ets/ARTCTokenHelper';

@Entry
@Component
export struct VoiceChat {
  @State AppId: string = '';
  @State AppKey: string = '';
  @State UserId: string = '';
  @State TimeStamp: number = 0;
  @State Nonce: string = '';
  @State Token: string = '';
  @State host: boolean = false
  @State anchor: boolean = false
  @State hostAnchor: boolean = false
  @State channelId: string = Date.now().toString().slice(-6);
  @State hasJoined: boolean = false
  @State isAnchor: boolean = true
  private rtcEngine: AliRtcEngine | null | undefined;
  private context: common.Context | undefined;

  async aboutToAppear(): Promise<void> {
    this.generateTimestamp();
    this.context = getContext() as common.Context;
    try {
      const data = await LightStorage.instance?.getObject<SettingsData>('settingData');
      if (data) {
        this.AppId = data.appId!;
        this.AppKey = data.appKey!;
        this.UserId = data.userId!;
      }
    } catch (error) {
      console.error('Failed to load settings:', error);
    }
    // 生成随机频道ID
    this.channelId = Math.floor(100000 + Math.random() * 900000).toString();
  }

  private generateTimestamp(): void {
    const seconds = Math.floor(Date.now() / 1000)
    const tomorrowSeconds = seconds + 86400;
    this.TimeStamp = tomorrowSeconds
  }

  aboutToDisappear(): void {
    this.destroyRtcEngine();
  }

  build() {
    NavDestination() {
      Column() {
        CustomTitle({
          titleText: '实现语聊房',
        })

        Column() {
          Text('如果要和其他用户加入同一个语聊房，需要加入到同一个频道里，既保证双方的ChannelID相同。')
            .fontSize(14)
            .fontColor('#666')
            .margin({ bottom: 16 })

          Row() {
            Text('ChannelID:')
              .fontSize(16)
              .fontColor('#333')

            TextInput({
              text: this.channelId
            })
              .padding({ left: 8, right: 8 })
              .layoutWeight(1)
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

          Row() {
            // 主播/观众切换按钮
            if (this.anchor && this.hasJoined) {
              Text(this.hostAnchor ? '切换为观众' : '切换为主播')
                .textAlign(TextAlign.Center)
                .fontSize(16)
                .backgroundColor('#3295fb')
                .layoutWeight(1)
                .height(40)
                .borderRadius(4)
                .onClick(() => {
                  this.hostAnchor = !this.hostAnchor;
                  this.switchClientRole();
                })
            } else {
              Text(this.host ? '挂断' : '主播')
                .textAlign(TextAlign.Center)
                .fontSize(16)
                .backgroundColor('#3295fb')
                .layoutWeight(1)
                .height(40)
                .borderRadius(4)
                .onClick(() => {
                  this.handleAnchorClick();
                })
            }

            if (!this.host) {
              Blank()
                .layoutWeight(0.3)
            }

            if (!this.host) {
              Text(this.anchor ? '挂断' : '观众')
                .textAlign(TextAlign.Center)
                .fontSize(16)
                .backgroundColor('#3295fb')
                .layoutWeight(1)
                .height(40)
                .borderRadius(4)
                .onClick(() => {
                  this.handleAudienceClick();
                })
            }
          }
          .width('100%')
          .margin({ top: 20 })
        }
        .margin(12)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#f5f5f5')
    }.hideTitleBar(true)

  }

  // 处理主播按钮点击
  private async handleAnchorClick(): Promise<void> {
    if (this.hasJoined) {
      this.destroyRtcEngine();
      this.host = false;
      this.anchor = false;
      this.hasJoined = false;
      return;
    }

    this.isAnchor = true;
    this.host = true;
    await this.startRTCCall();
  }

  // 处理观众按钮点击
  private async handleAudienceClick(): Promise<void> {
    if (this.hasJoined) {
      this.destroyRtcEngine();
      this.host = false;
      this.anchor = false;
      this.hasJoined = false;
      return;
    }

    this.isAnchor = false;
    this.anchor = true;
    await this.startRTCCall();
  }

  // 开始RTC通话
  private async startRTCCall(): Promise<void> {
    if (this.hasJoined) {
      return;
    }

    await this.initAndSetupRtcEngine();
    await this.joinChannel();
  }

  // 初始化和设置RTC引擎
  private async initAndSetupRtcEngine(): Promise<void> {
    if (!this.context) {
      prompt.showToast({ message: 'Context未初始化', duration: 2000 });
      return;
    }

    try {
      // 创建RTC引擎实例
      this.rtcEngine = AliRtcEngine.getInstance('', this.context);

      // 设置频道模式为互动直播模式
      this.rtcEngine.setChannelProfile(AliRtcChannelProfile.AliRtcInteractiveLive);

      // 设置用户角色
      if (this.isAnchor) {
        // 主播角色：需要推流
        this.rtcEngine.setClientRole(AliRtcClientRole.AliRtcClientRoleInteractive);
      } else {
        // 观众角色：只拉流
        this.rtcEngine.setClientRole(AliRtcClientRole.AliRtcClientRoleLive);
      }

      // 设置音频配置（高音质模式 + 音乐场景）
      this.rtcEngine.setAudioProfile(
        AliRtcAudioProfile.AliRtcHighQualityMode,
        AliRtcAudioScenario.AliRtcSceneMusicMode
      );
      this.rtcEngine.publishLocalAudioStream(true);
      // 语聊场景不需要发布视频
      this.rtcEngine.publishLocalVideoStream(false);

      // 设置默认订阅所有远端音频流
      this.rtcEngine.setDefaultSubscribeAllRemoteAudioStreams(true);
      this.rtcEngine.subscribeAllRemoteAudioStreams(true);


      // 设置事件监听器
      this.setupEventListeners();

      console.info('RTC引擎初始化完成');

    } catch (error) {
      console.error('RTC引擎初始化失败:', error);
      prompt.showToast({ message: `引擎初始化失败: ${error}`, duration: 3000 });
    }
  }

  private setupEventListeners(): void {
    if (!this.rtcEngine) {
      return;
    }
    const listener = new AliRtcEngineEventListener()
      .onJoinChannel((resultCode: number, channel: string, elapsed: string) => {
        console.info(`加入频道结果: result=${resultCode}, channel=${channel}, userId=${this.UserId}, elapsed=${elapsed}`);
        this.handleJoinResult(resultCode, channel);
      })
    this.rtcEngine.setRtcEngineEventListener(listener);
  }

  // 加入频道
  private async joinChannel(): Promise<void> {
    if (!this.rtcEngine || !this.channelId.trim()) {
      prompt.showToast({ message: '频道ID不能为空', duration: 2000 });
      return;
    }
    try {
      this.Token = await ARTCTokenHelper.generateSingleParameterToken(
        this.AppId,
        this.AppKey,
        this.channelId,
        this.UserId,
        this.TimeStamp,
        this.Nonce
      );
      console.info('单参入会token:', this.Token);

      // 加入频道
      const result = this.rtcEngine.joinChannelWithToken(this.Token, '', '', '语聊房用户');
      console.info('加入频道调用结果:', result);

      this.hasJoined = true;

    } catch (error) {
      console.error('加入频道失败:', error);
      prompt.showToast({ message: `加入频道失败: ${error}`, duration: 3000 });
    }
  }

  // 切换客户端角色（主播/观众）
  private switchClientRole(): void {
    if (!this.rtcEngine) {
      return;
    }

    try {
      if (this.hostAnchor) {
        // 切换为主播角色
        this.rtcEngine.setClientRole(AliRtcClientRole.AliRtcClientRoleInteractive);
      } else {
        // 切换为观众角色
        this.rtcEngine.setClientRole(AliRtcClientRole.AliRtcClientRoleLive);
      }
    } catch (error) {
      console.error('切换角色失败:', error);
      prompt.showToast({ message: `切换角色失败: ${error}`, duration: 3000 });
    }
  }

  // 处理加入频道结果
  private handleJoinResult(resultCode: number, channel: string): void {
    let resultText = '';
    if (resultCode === 0) {
      resultText = `User ${this.UserId} Join ${channel} Success`;
    } else {
      resultText = `Join ${this.UserId} Join ${channel} Failed!，error: ${resultCode}`;
    }
    prompt.showToast({ message: resultText, duration: 2000 });

    if (resultCode === 0) {
      if (this.isAnchor) {
        // 主播加入成功
        this.host = true;
        this.anchor = false;
      } else {
        // 观众加入成功
        this.anchor = true;
        this.host = false;
        this.hostAnchor = false; // 初始为观众角色
      }
    }
  }

  // 销毁RTC引擎
  private destroyRtcEngine(): void {
    if (this.rtcEngine) {
      try {
        // 离开频道
        this.rtcEngine.leaveChannel();

        this.rtcEngine = undefined;

        this.hasJoined = false;
        AliRtcEngine.destroyInstance();

        this.rtcEngine = null;

        prompt.showToast({ message: 'Leave Channel', duration: 2000 });

      } catch (error) {
        console.error('销毁引擎失败:', error);
      }
    }

    this.cleanupAfterLeave();
  }

  // 离开后的清理工作
  private cleanupAfterLeave(): void {
    this.host = false;
    this.anchor = false;
    this.hostAnchor = false;
    this.hasJoined = false;
  }
}