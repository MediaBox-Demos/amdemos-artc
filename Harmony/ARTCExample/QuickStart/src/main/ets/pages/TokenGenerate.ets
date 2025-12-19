import { SettingsData } from 'common/src/main/ets/common/Constants';
import { CustomTitle } from 'common/src/main/ets/components/CustomTitle';
import { LightStorage } from 'common/src/main/ets/components/LightStorage';
import { ARTCTokenHelper } from 'keycenter/src/main/ets/ARTCTokenHelper';
import {
  AliRtcAudioProfile,
  AliRtcAudioScenario,
  AliRtcChannelProfile,
  AliRtcClientRole,
  AliRtcEngine,
  AliRtcEngineAuthInfo,
  AliRtcEngineEventListener,
  AliRtcRotationMode,
  AliRtcVideoDimensions,
  AliRtcVideoEncoderConfiguration,
  AliRtcVideoEncoderOrientationMode,
  AliRtcVideoMirrorMode,
  AliRtcVideoCanvas,
  AliRtcVideoTrack,
  AliRtcRenderMode,
  AliRtcRenderMirrorMode,
  AliRtcXComponentController
} from '@aliyun_video_cloud/alivcsdk_artc';
import common from '@ohos.app.ability.common';
import { prompt } from '@kit.ArkUI';


@Entry
@Component
export struct TokenGenerate {
  @State settingsData?: SettingsData = undefined
  @State AppId: string = '';
  @State AppKey: string = '';
  @State UserId: string = '';
  @State ChannelId: string = '';
  @State TimeStamp: number = 0;
  @State Nonce: string = '';
  @State MoreInto: boolean = false;
  @State SingleInto: boolean = false;
  @State Token: string = '';
  @State TokenExpire: string = '';
  @State ShowPreview: boolean = false;
  private rtcEngine: AliRtcEngine | null | undefined;
  private context: common.Context | undefined;
  private xcomponentController: XComponentController = new XComponentController();
  private aliRtcVideoCanvas: AliRtcVideoCanvas | undefined;
  private componentController: AliRtcXComponentController = new AliRtcXComponentController()

  async aboutToAppear(): Promise<void> {
    this.context = getContext() as common.Context;


    try {
      const data = await LightStorage.instance?.getObject<SettingsData>('settingData');
      if (data) {
        this.settingsData = data;
      }
    } catch (error) {
      console.error('Failed to load settings:', error);
    }
    this.generateTimestamp()
    this.ChannelId = Math.floor(100000 + Math.random() * 900000).toString();
  }

  aboutToDisappear(): void {
    this.leaveChannelAndCleanup();
  }

  build() {
    NavDestination(){
      Column() {
        CustomTitle({
          titleText: 'Token生成及入会',
        })

        Stack() {
          if (this.ShowPreview) {
            XComponent({
              id: 'rtc_video_surface',
              type: 'surface',
              controller: this.xcomponentController
            })
              .onLoad(() => {
                let surfaceId = this.xcomponentController.getXComponentSurfaceId();
                console.info('获取到 surfaceId:', surfaceId);

                this.aliRtcVideoCanvas = new AliRtcVideoCanvas();
                this.aliRtcVideoCanvas.surfaceId = surfaceId;

                this.aliRtcVideoCanvas.renderMode = AliRtcRenderMode.AliRtcRenderModeAuto;
                this.aliRtcVideoCanvas.mirrorMode = AliRtcRenderMirrorMode.AliRtcRenderMirrorModeAllMirror;
                let engine = AliRtcEngine.getInstance('', this.context);
                let result =
                  engine.setLocalViewConfig(this.aliRtcVideoCanvas, this.componentController,
                    AliRtcVideoTrack.AliRtcVideoTrackCamera);
                console.info('setLocalViewConfig 调用结果:', result);
              })
              .onDestroy(() => {
                console.info('XComponent onDestroy');
                // 4. 清理时通知SDK表面销毁
                if (this.aliRtcVideoCanvas) {
                  this.aliRtcVideoCanvas?.displayView?.OnSurfaceDestroy();
                }
              })
              .width('100')
              .height('200')


          }
          Column() {
            Row() {
              Text('Appid:')
                .fontSize(14)
                .fontColor('#ff8c8787')
                .margin({
                  left: 16
                })
              TextArea({
                text: this.settingsData?.appId ?? '',
                placeholder: '请输入Appid'
              })
                .fontSize(16)
                .fontColor(Color.Black)
                .backgroundColor('#fff')
                .layoutWeight(1)
                .maxLines(2)
                .textAlign(TextAlign.Start)
                .padding({
                  left: 0
                })
                .margin({
                  right: 20
                })
                .height('auto')
                .border({
                  // 只设置底部边框
                  width: {
                    top: 0,
                    right: 0,
                    bottom: 1,
                    left: 0
                  },
                  color: '#000', // 下划线颜色
                  radius: 0
                })
                .onChange((text) => {
                  this.AppId = text
                })
            }
            .margin({ top: 20 })

            Row() {
              Text('AppKey:')
                .fontSize(14)
                .fontColor('#ff8c8787')
                .margin({
                  left: 16
                })
              TextArea({
                text: this.settingsData?.appKey ?? '',
                placeholder: '请输入AppKey'
              })
                .fontSize(16)
                .fontColor(Color.Black)
                .backgroundColor('#00fdfdfb') // 半透明白色背景
                .layoutWeight(1)
                .maxLines(2)
                .textAlign(TextAlign.Start)
                .padding({
                  left: 0
                })
                .margin({
                  right: 20
                })
                .height('auto')
                .border({
                  // 只设置底部边框
                  width: {
                    top: 0,
                    right: 0,
                    bottom: 1,
                    left: 0
                  },
                  color: '#000', // 下划线颜色
                  radius: 0
                })
                .onChange((text) => {
                  this.AppKey = text
                })
            }
            .margin({ top: 20 })

            Row() {
              Text('UserId:')
                .fontSize(14)
                .fontColor('#ff8c8787')
                .margin({
                  left: 16
                })
              TextArea({
                text: this.settingsData?.userId ?? '',
                placeholder: '请输入用户Id'
              })
                .fontSize(16)
                .fontColor(Color.Black)
                .backgroundColor('#00fdfdfb') // 半透明白色背景
                .layoutWeight(1)
                .maxLines(2)
                .textAlign(TextAlign.Start)
                .padding({
                  left: 0
                })
                .margin({
                  right: 20
                })
                .height('auto')
                .border({
                  // 只设置底部边框
                  width: {
                    top: 0,
                    right: 0,
                    bottom: 1,
                    left: 0
                  },
                  color: '#000', // 下划线颜色
                  radius: 0
                })
                .onChange((text) => {
                  this.UserId = text
                })
            }
            .margin({ top: 20 })

            Row() {
              Text('ChannelId:')
                .fontSize(14)
                .fontColor('#ff8c8787')
                .margin({
                  left: 16
                })
              TextArea({
                text: this.ChannelId ?? ''
              })
                .fontSize(16)
                .fontColor(Color.Black)
                .backgroundColor('#00fdfdfb') // 半透明白色背景
                .layoutWeight(1)
                .maxLines(2)
                .textAlign(TextAlign.Start)
                .padding({
                  left: 0
                })
                .margin({
                  right: 20
                })
                .height('auto')
                .border({
                  // 只设置底部边框
                  width: {
                    top: 0,
                    right: 0,
                    bottom: 1,
                    left: 0
                  },
                  color: '#000', // 下划线颜色
                  radius: 0
                })
                .onChange((text) => {
                  this.ChannelId = text
                })
            }
            .margin({ top: 20 })

            Row() {
              Text('TimeStamp:')
                .fontSize(14)
                .fontColor('#ff8c8787')
                .margin({
                  left: 16
                })
              TextArea({
                text: this.TimeStamp + '' ?? '',
              })
                .fontSize(16)
                .fontColor(Color.Black)
                .backgroundColor('#00fdfdfb') // 半透明白色背景
                .layoutWeight(1)
                .maxLines(2)
                .textAlign(TextAlign.Start)
                .padding({
                  left: 0
                })
                .margin({
                  right: 20
                })
                .height('auto')
                .border({
                  // 只设置底部边框
                  width: {
                    top: 0,
                    right: 0,
                    bottom: 1,
                    left: 0
                  },
                  color: '#000', // 下划线颜色
                  radius: 0
                })
                .onChange((text) => {
                  this.TimeStamp = parseInt(text)
                })
            }
            .margin({ top: 20 })

            Row() {
              Text('Nonce:')
                .fontSize(14)
                .fontColor('#ff8c8787')
                .margin({
                  left: 16
                })
              TextArea({
                text: this.Nonce,
                placeholder: '该参数可为空'
              })
                .fontSize(16)
                .fontColor(Color.Black)
                .backgroundColor('#fff')
                .layoutWeight(1)
                .maxLines(2)
                .textAlign(TextAlign.Start)
                .padding({
                  left: 0
                })
                .margin({
                  right: 20
                })
                .height('auto')
                .border({
                  // 只设置底部边框
                  width: {
                    top: 0,
                    right: 0,
                    bottom: 1,
                    left: 0
                  },
                  color: '#000', // 下划线颜色
                  radius: 0
                })
                .onChange((text) => {
                  this.Nonce = text
                })
            }
            .margin({ top: 20 })
          }
          .zIndex(99)
        }

        Row() {
          Text(this.MoreInto == true ? '挂断' : '多参数入会')
            .backgroundColor('#3295fb')
            .layoutWeight(1)
            .height(60)
            .textAlign(TextAlign.Center)
            .onClick(async () => {

              this.handleMultiParamJoin()
            })
          Blank()
            .layoutWeight(0.5)
          Text(this.SingleInto == true ? '挂断' : '单参数入会')
            .backgroundColor('#3295fb')
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
            .height(60)
            .onClick(async () => {
              this.handleSingleParamJoin()
            })
        }
        .margin({
          top: 20,
          left: 16,
          right: 16
        })

        if ((this.MoreInto || this.SingleInto) && this.Token) {
          Column() {
            Row() {
              Text('Token:')
              Text(this.Token)
                .layoutWeight(1)
            }
            .alignItems(VerticalAlign.Top)
            .margin({
              top: 20,
              left: 16,
              right: 16
            })

            Row() {
              Text('Join Result:')
              Text(this.TokenExpire)
                .fontColor('#f00')
                .layoutWeight(1)


            }.margin({
              top: 20,
              left: 16,
              right: 16
            })
          }
        }

      }
    }
    .hideTitleBar(true)
  }

  // 处理多参数入会
  private async handleMultiParamJoin(): Promise<void> {
    if (this.MoreInto) {
      // 离开频道
      this.leaveChannelAndCleanup();
      this.MoreInto = false;
      return;
    }
    try {
      this.Token = await ARTCTokenHelper.generateMultiParameterToken(
        this.AppId,
        this.AppKey,
        this.ChannelId,
        this.UserId,
        this.TimeStamp,
        this.Nonce
      );
      console.info('多参入会token:', this.Token);

      // 初始化RTC引擎
      await this.initAndSetupRtcEngine();

      // 开始预览
      this.startPreview();

      // 构造鉴权信息并加入频道
      const authInfo: AliRtcEngineAuthInfo = new AliRtcEngineAuthInfo()
      authInfo.channelId = this.ChannelId;
      authInfo.userId = this.UserId;
      authInfo.appId = this.AppId;
      authInfo.nonce = this.Nonce;
      authInfo.timestamp = this.TimeStamp;
      authInfo.token = this.Token;
      authInfo.role = ''
      const result = this.rtcEngine?.joinChannel(authInfo, `默认名字`);
      console.info('多参数入会调用结果:', result);

      this.MoreInto = true;

    } catch (error) {
      console.error('多参数入会失败:', error);
      prompt.showToast({ message: `入会失败: ${error}`, duration: 3000 });
    }
  }

  // 处理单参数入会
  private async handleSingleParamJoin(): Promise<void> {
    if (this.SingleInto) {
      // 离开频道
      this.leaveChannelAndCleanup();
      this.SingleInto = false;
      return;
    }


    try {
      this.Token = await ARTCTokenHelper.generateSingleParameterToken(
        this.AppId,
        this.AppKey,
        this.ChannelId,
        this.UserId,
        this.TimeStamp,
        this.Nonce
      );
      console.info('单参入会token:', this.Token);

      // 初始化RTC引擎
      await this.initAndSetupRtcEngine();

      // 开始预览
      this.startPreview();
      // 单参数入会
      const result = this.rtcEngine?.joinChannelWithToken(this.Token,"", "", '默认名字');
      console.info('单参数入会调用结果:', result);

      this.SingleInto = true;

    } catch (error) {
      console.error('单参数入会失败:', error);
      prompt.showToast({ message: `入会失败: ${error}`, duration: 3000 });
    }
  }

  // 初始化并设置RTC引擎
  private async initAndSetupRtcEngine(): Promise<void> {
    if (this.rtcEngine) {
      return; // 已经初始化
    }

    if (!this.context) {
      throw new Error('Context未初始化');
    }

    try {
      // 创建RTC引擎实例
      this.rtcEngine = AliRtcEngine.getInstance('', this.context);

      // 设置频道模式为互动直播模式
      this.rtcEngine.setChannelProfile(AliRtcChannelProfile.AliRtcInteractiveLive);

      // 设置用户角色为互动角色（主播）
      this.rtcEngine.setClientRole(AliRtcClientRole.AliRtcClientRoleInteractive);

      // 设置音频配置（高质量模式 + 音乐场景）
      this.rtcEngine.setAudioProfile(
        AliRtcAudioProfile.AliRtcHighQualityMode,
        AliRtcAudioScenario.AliRtcSceneDefaultMode
      );
      this.rtcEngine.publishLocalAudioStream(true);


      const videoConfig: AliRtcVideoEncoderConfiguration = new AliRtcVideoEncoderConfiguration()
      videoConfig.dimensions.width = 640;
      videoConfig.dimensions.height = 480;
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

      this.rtcEngine.subscribeAllRemoteAudioStreams(true);
      // 设置事件监听器
      this.setupEventListeners();

      console.info('RTC引擎初始化完成');

    } catch (error) {
      console.error('RTC引擎初始化失败:', error);
    }
  }

  private setupEventListeners(): void {
    if (!this.rtcEngine) {
      return;
    }
    const listener = new AliRtcEngineEventListener()
      .onJoinChannel((resultCode: number, channel: string, elapsed: string) => {
        console.info(`加入频道结果: result=${resultCode}, channel=${channel}, userId=${this.UserId}, elapsed=${elapsed}`);

        const resultText = resultCode === 0
          ? `User ${this.UserId} Join ${channel} Success`
          : `Join ${this.UserId} Join ${channel} Failed!，error: ${resultCode}`;

        this.TokenExpire = resultText;
      })
      .onLeaveChannel((resultCode: number) => {
        if (!this.SingleInto) {
          prompt.showToast({ message: 'Leave Channel', duration: 2000 });
        }

      });
    this.rtcEngine.setRtcEngineEventListener(listener);
  }

  // 开始本地预览
  private startPreview(): void {
    if (!this.rtcEngine) {
      return;
    }

    try {
      // 开始本地视频预览
      if (this.aliRtcVideoCanvas) {
        this.rtcEngine.setLocalViewConfig(this.aliRtcVideoCanvas, null, AliRtcVideoTrack.AliRtcVideoTrackCamera);
      }
      this.rtcEngine.startPreview();
      this.ShowPreview = true;
      console.info('本地预览已启动');
    } catch (error) {
      console.error('启动预览失败:', error);
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

        AliRtcEngine.destroyInstance();

        this.rtcEngine = null;

        console.info('已离开频道');
      } catch (error) {
        console.error('离开频道失败:', error);
      }
    }

    this.cleanupAfterLeave();
  }

  // 离开后的清理工作
  private cleanupAfterLeave(): void {
    this.ShowPreview = false;
    this.MoreInto = false;
    this.SingleInto = false;
  }

  //获取当前时间戳
  private generateTimestamp(): void {
    const seconds = Math.floor(Date.now() / 1000)
    const tomorrowSeconds = seconds + 86400;
    this.TimeStamp = tomorrowSeconds
  }
}