import { SettingsData } from '../../common/Constants';
import { CustomTitle } from '../../common/components/CustomTitle';
import { LightStorage } from '../../common/components/LightStorage';
import { ARTCTokenHelper } from '../../common/keycenter/ARTCTokenHelper';
import { GlobalConfig } from '../../common/keycenter/GlobalConfig';
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
import { common } from '@kit.AbilityKit';
import { prompt, promptAction } from '@kit.ArkUI';


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
  @State JoinChannelResult: string = '';
  @State JoinResultColor: string = '#FF0000';
  @State ShowPreview: boolean = false;
  
  // Token 生成中间过程展示
  @State ContentRaw: string = '';
  @State Sha256Token: string = '';
  @State JsonString: string = '';
  @State Base64Token: string = '';
  private rtcEngine: AliRtcEngine | undefined;
  private context: common.UIAbilityContext | undefined;
  private xcomponentController: XComponentController = new XComponentController();
  private aliRtcVideoCanvas: AliRtcVideoCanvas | undefined;
  private componentController: AliRtcXComponentController = new AliRtcXComponentController()
  private rtcEventListener?: AliRtcEngineEventListener;

  async aboutToAppear(): Promise<void> {
    this.context = getContext(this) as common.UIAbilityContext;

    try {
      const data = await LightStorage.instance?.getObject<SettingsData>('settingData');
      if (data) {
        this.settingsData = data;
        this.AppId = data.appId ?? '';
        this.AppKey = data.appKey ?? '';
        this.UserId = data.userId ?? '';
      }
    } catch (error) {
      console.error('Failed to load settings:', error);
    }

    // 统一从 GlobalConfig 获取全局配置（AppId/AppKey/UserId）
    const global: GlobalConfig = GlobalConfig.getInstance();

    const globalAppId = await global.getAppId();
    const globalAppKey = await global.getAppKey();

    if (!this.AppId) {
      this.AppId = globalAppId || ARTCTokenHelper.AppId;
    }
    if (!this.AppKey) {
      this.AppKey = globalAppKey || ARTCTokenHelper.AppKey;
    }
    if (!this.UserId) {
      this.UserId = await global.getUserId();
    }

    this.TimeStamp = ARTCTokenHelper.getTimestamp();
    this.ChannelId = global.getRandomChannelId();
  }

  aboutToDisappear(): void {
    this.leaveChannelAndCleanup();
    // 销毁SDK单例,避免后台回前台时崩溃
    AliRtcEngine.destroyInstance();
  }

  build() {
    NavDestination(){
      Column() {
        CustomTitle({
          titleText: 'Token生成及入会',
        })

        // 添加 Scroll 支持整体滚动
        Scroll() {
          Column() {
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
                  engine!.setLocalViewConfig(this.aliRtcVideoCanvas, this.componentController,
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
              Text('Appid')
                .fontSize(14)
                .fontColor('#ff8c8787')
                .width(80)
                .margin({
                  left: 20
                })
              Text(this.AppId)
                .fontSize(16)
                .fontColor(Color.Black)
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
            }
            .margin({ top: 20 })

            Row() {
              Text('AppKey:')
                .fontSize(14)
                .fontColor('#ff8c8787')
                .width(80)
                .margin({
                  left: 20
                })
              Text(this.AppKey)
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
            }
            .margin({ top: 20 })

            Row() {
              Text('UserId:')
                .fontSize(14)
                .fontColor('#ff8c8787')
                .width(80)
                .margin({
                  left: 20
                })
              Text(this.UserId)
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
            }
            .margin({ top: 20 })

            Row() {
              Text('ChannelId:')
                .fontSize(14)
                .fontColor('#ff8c8787')
                .width(80)
                .margin({
                  left: 20
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
                .width(80)
                .margin({
                  left: 20
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
                .width(80)
                .margin({
                  left: 20
                })
              TextArea({
                text: this.Nonce,
                placeholder: '该参数可为空'
              })
                .fontSize(16)
                .fontColor(Color.Black)
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
            .fontColor('#ffffff')
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
            .fontColor('#ffffff')
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

        // Token 生成步骤展示区域
        if (this.Token && this.ContentRaw) {
          Column() {
            // Content
            Column() {
              Text('Content:')
                .fontSize(14)
                .fontColor('#ff8c8787')
                .width('100%')
                .margin({ bottom: 4 })
              Text(this.ContentRaw)
                .fontSize(13)
                .fontColor('#333333')
                .backgroundColor('#f5f5f5')
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .width('100%')
            }
            .alignItems(HorizontalAlign.Start)
            .margin({ top: 16, left: 16, right: 16 })

            // SHA256
            Column() {
              Text(this.MoreInto ? 'SHA256 (Token):' : 'SHA256:')
                .fontSize(14)
                .fontColor('#ff8c8787')
                .width('100%')
                .margin({ bottom: 4 })
              Text(this.Sha256Token)
                .fontSize(13)
                .fontColor('#333333')
                .backgroundColor('#f5f5f5')
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .width('100%')
            }
            .alignItems(HorizontalAlign.Start)
            .margin({ top: 12, left: 16, right: 16 })

            // JSON（仅单参入会时展示）
            if (!this.MoreInto && this.JsonString) {
              Column() {
                Text('JSON:')
                  .fontSize(14)
                  .fontColor('#ff8c8787')
                  .width('100%')
                  .margin({ bottom: 4 })
                Text(this.JsonString)
                  .fontSize(13)
                  .fontColor('#333333')
                  .backgroundColor('#f5f5f5')
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .width('100%')
              }
              .alignItems(HorizontalAlign.Start)
              .margin({ top: 12, left: 16, right: 16 })
            }

            // Base64(Token)（仅单参入会时展示）
            if (!this.MoreInto && this.Base64Token) {
              Column() {
                Text('Base64 (Token):')
                  .fontSize(14)
                  .fontColor('#ff8c8787')
                  .width('100%')
                  .margin({ bottom: 4 })
                Text(this.Base64Token)
                  .fontSize(13)
                  .fontColor('#333333')
                  .backgroundColor('#f5f5f5')
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .width('100%')
              }
              .alignItems(HorizontalAlign.Start)
              .margin({ top: 12, left: 16, right: 16 })
            }
          }
        }

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
              Text(this.JoinChannelResult)
                .fontColor(this.JoinResultColor)
                .layoutWeight(1)


            }.margin({
              top: 20,
              left: 16,
              right: 16
            })
          }
        }

          } // Column 结束（Scroll 内部）
          .alignItems(HorizontalAlign.Start) // 水平左对齐
        } // Scroll 结束
        .layoutWeight(1) // 让 Scroll 占满剩余高度
        .scrollBar(BarState.Auto) // 显示滚动条
        .align(Alignment.Top) // 内容从顶部开始

      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5') // 固定页面浅色背景，确保暗色模式下文字可见
    }
    .hideTitleBar(true)
  }

  // 处理多参数入会（演示用：AliRtcEngineAuthInfo + joinChannel）
  private async handleMultiParamJoin(): Promise<void> {
    if (this.MoreInto) {
      // 离开频道
      this.leaveChannelAndCleanup();
      this.MoreInto = false;
      return;
    }
    try {
      const global: GlobalConfig = GlobalConfig.getInstance();

      const appId = this.AppId || ARTCTokenHelper.AppId;
      const appKey = this.AppKey || ARTCTokenHelper.AppKey;

      // 校验 AppId / AppKey 是否已配置
      if (!appId || !appKey) {
        promptAction.showToast({
          message: '请点击右上角设置，填写 AppId 和 AppKey 参数',
          duration: 3000
        });
        return;
      }

      const userId = this.UserId || await global.getUserId();
      const timestamp = this.TimeStamp || ARTCTokenHelper.getTimestamp();

      this.AppId = appId;
      this.AppKey = appKey;
      this.UserId = userId;
      this.TimeStamp = timestamp;

      // 使用 KeyCenter 统一生成多参数 Token（十六进制）
      this.Token = await ARTCTokenHelper.generateMultiParameterToken(
        appId,
        appKey,
        this.ChannelId,
        userId,
        timestamp,
        this.Nonce
      );
      console.info('多参入会token:', this.Token);
      
      // 从 ARTCTokenHelper 读取中间过程，用于 UI 展示
      this.ContentRaw = ARTCTokenHelper.getLastContent();
      this.Sha256Token = ARTCTokenHelper.getLastSha256Token();
      this.JsonString = ARTCTokenHelper.getLastJsonString();
      this.Base64Token = ARTCTokenHelper.getLastBase64Token();

      // 初始化RTC引擎
      await this.initAndSetupRtcEngine();

      // 开始预览
      this.startPreview();

      // 构造鉴权信息并加入频道
      const authInfo: AliRtcEngineAuthInfo = new AliRtcEngineAuthInfo();
      authInfo.channelId = this.ChannelId;
      authInfo.userId = this.UserId;
      authInfo.appId = this.AppId;
      authInfo.nonce = this.Nonce;
      authInfo.timestamp = this.TimeStamp;
      authInfo.token = this.Token;
      authInfo.role = '';
      const result = this.rtcEngine?.joinChannel(authInfo, '多参数用户');
      console.info('多参数入会调用结果:', result);

      this.MoreInto = true;

    } catch (error) {
      console.error('多参数入会失败:', error);
      prompt.showToast({ message: `入会失败: ${error}`, duration: 3000 });
    }
  }

  // 处理单参数入会（规范用法：joinChannelWithToken）
  private async handleSingleParamJoin(): Promise<void> {
    if (this.SingleInto) {
      // 离开频道
      this.leaveChannelAndCleanup();
      this.SingleInto = false;
      return;
    }

    try {
      const global: GlobalConfig = GlobalConfig.getInstance();

      const appId = this.AppId || ARTCTokenHelper.AppId;
      const appKey = this.AppKey || ARTCTokenHelper.AppKey;

      // 校验 AppId / AppKey 是否已配置
      if (!appId || !appKey) {
        promptAction.showToast({
          message: '请点击右上角设置，填写 AppId 和 AppKey 参数',
          duration: 3000
        });
        return;
      }

      const userId = this.UserId || await global.getUserId();
      const timestamp = this.TimeStamp || ARTCTokenHelper.getTimestamp();

      this.AppId = appId;
      this.AppKey = appKey;
      this.UserId = userId;
      this.TimeStamp = timestamp;

      // 使用 KeyCenter 统一生成单参数 Token（Base64）
      const base64Token = await ARTCTokenHelper.generateSingleParameterToken(
        appId,
        appKey,
        this.ChannelId,
        userId,
        timestamp,
        this.Nonce
      );
      this.Token = base64Token;
      console.info('单参入会token:', this.Token);
      
      // 从 ARTCTokenHelper 读取中间过程，用于 UI 展示
      this.ContentRaw = ARTCTokenHelper.getLastContent();
      this.Sha256Token = ARTCTokenHelper.getLastSha256Token();
      this.JsonString = ARTCTokenHelper.getLastJsonString();
      this.Base64Token = ARTCTokenHelper.getLastBase64Token();

      // 初始化RTC引擎
      await this.initAndSetupRtcEngine();

      // 开始预览
      this.startPreview();

      // 单参数入会：使用 joinChannelWithToken
      const result = this.rtcEngine?.joinChannelWithToken(
        this.Token,
        '',              // channelId 可留空，使用 token 中信息
        '',              // userId 可留空，使用 token 中信息
        '单参数用户'      // userName 仅展示用
      );
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
      if (this.rtcEngine === undefined) {
        promptAction.showToast({ message: 'RTC引擎未初始化成功', duration: 2000 });
        return;
      }
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
  
    if (!this.rtcEventListener) {
      this.rtcEventListener = new AliRtcEngineEventListener();
  
      this.rtcEventListener.onJoinChannel((resultCode: number, channel: string, elapsed: string) => {
        console.info(`加入频道结果: result=${resultCode}, channel=${channel}, userId=${this.UserId}, elapsed=${elapsed}`);
  
        const resultText = resultCode === 0
          ? `User ${this.UserId} Join ${channel} Success`
          : `Join ${this.UserId} Join ${channel} Failed!，error: ${resultCode}`;
  
        this.JoinChannelResult = resultText;
          
        if (resultCode === 0) {
          this.JoinResultColor = '#00AA00';
        } else {
          this.JoinResultColor = '#FF0000';
        }
      })
  
      this.rtcEventListener.onLeaveChannel((resultCode: number) => {
        if (!this.SingleInto) {
          prompt.showToast({ message: 'Leave Channel', duration: 2000 });
        }
      })
  
      this.rtcEventListener.onAuthInfoWillExpire(() => {
        console.info('Token 即将过期（30秒后），需要刷新 Token');
          
        promptAction.showDialog({
          title: 'Token 即将过期',
          message: '当前 Token 即将在30秒后过期，是否刷新 Token 继续通话？',
          buttons: [
            { text: '稍后', color: '#999999' },
            { text: '刷新 Token', color: '#3295fb' }
          ]
        }).then((result) => {
          if (result.index === 1) {
            this.refreshToken();
          }
        }).catch((error: Error) => {
          console.error('弹窗显示失败:', error);
        });
      })
  
      this.rtcEventListener.onAuthInfoExpired(() => {
        console.error('Token 已过期，需要重新入会');
          
        promptAction.showDialog({
          title: 'Token 已过期',
          message: '当前 Token 已经过期，请重新加入会议。',
          buttons: [
            { text: '确定', color: '#3295fb' }
          ]
        }).then(() => {
          this.leaveChannelAndCleanup();
        }).catch((error: Error) => {
          console.error('弹窗显示失败:', error);
        });
      });
    }
  
    this.rtcEngine.setRtcEngineEventListener(this.rtcEventListener);
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

        console.info('已离开频道');
      } catch (error) {
        console.error('离开频道失败:', error);
      }
    }

    // 清理引擎实例
    this.rtcEngine = undefined;
    this.cleanupAfterLeave();
  }

  // 离开后的清理工作
  private cleanupAfterLeave(): void {
    this.ShowPreview = false;
    this.MoreInto = false;
    this.SingleInto = false;
  }

  /**
   * 刷新 Token（用于 Token 即将过期时延长有效期）
   */
  private async refreshToken(): Promise<void> {
    if (!this.rtcEngine || (!this.MoreInto && !this.SingleInto)) {
      promptAction.showToast({
        message: '当前不在频道中，无法刷新 Token',
        duration: 2000
      });
      return;
    }

    try {
      const global: GlobalConfig = GlobalConfig.getInstance();
      
      const appId = this.AppId || ARTCTokenHelper.AppId;
      const appKey = this.AppKey || ARTCTokenHelper.AppKey;
      
      if (!appId || !appKey) {
        promptAction.showToast({
          message: '请点击右上角设置，填写 AppId 和 AppKey 参数',
          duration: 3000
        });
        return;
      }

      const userId = this.UserId || await global.getUserId();
      
      // 重新生成过期时间戳（当前时间 + 24小时）
      const newTimestamp: number = ARTCTokenHelper.getTimestamp();
      this.TimeStamp = newTimestamp;

      console.info('开始刷新 Token...');

      if (this.MoreInto) {
        // 多参数入会模式：刷新多参数 Token
        const newToken = await ARTCTokenHelper.generateMultiParameterToken(
          appId,
          appKey,
          this.ChannelId,
          userId,
          newTimestamp,
          this.Nonce
        );

        // 构造鉴权信息
        const authInfo: AliRtcEngineAuthInfo = new AliRtcEngineAuthInfo();
        authInfo.channelId = this.ChannelId;
        authInfo.userId = userId;
        authInfo.appId = appId;
        authInfo.nonce = this.Nonce;
        authInfo.timestamp = newTimestamp;
        authInfo.token = newToken;
        authInfo.role = '';

        // 调用 SDK 刷新鉴权信息
        const result = this.rtcEngine.refreshAuthInfo(authInfo);
        
        if (result === 0) {
          this.Token = newToken;
          this.TimeStamp = newTimestamp;
          
          // 更新 UI 展示
          this.ContentRaw = ARTCTokenHelper.getLastContent();
          this.Sha256Token = ARTCTokenHelper.getLastSha256Token();
          
          promptAction.showToast({
            message: 'Token 刷新成功',
            duration: 2000
          });
          console.info('多参数 Token 刷新成功');
        } else {
          promptAction.showToast({
            message: `Token 刷新失败，错误码：${result}`,
            duration: 3000
          });
          console.error('多参数 Token 刷新失败:', result);
        }

      } else if (this.SingleInto) {
        // 单参数入会模式：刷新单参数 Token
        const newToken = await ARTCTokenHelper.generateSingleParameterToken(
          appId,
          appKey,
          this.ChannelId,
          userId,
          newTimestamp,
          this.Nonce
        );

        // 调用 SDK 刷新鉴权信息（单参数版本）
        const result = this.rtcEngine.refreshAuthInfoWithToken(newToken);
        
        if (result === 0) {
          this.Token = newToken;
          this.TimeStamp = newTimestamp;
          
          // 更新 UI 展示
          this.ContentRaw = ARTCTokenHelper.getLastContent();
          this.Sha256Token = ARTCTokenHelper.getLastSha256Token();
          this.JsonString = ARTCTokenHelper.getLastJsonString();
          this.Base64Token = ARTCTokenHelper.getLastBase64Token();
          
          promptAction.showToast({
            message: 'Token 刷新成功',
            duration: 2000
          });
          console.info('单参数 Token 刷新成功');
        } else {
          promptAction.showToast({
            message: `Token 刷新失败，错误码：${result}`,
            duration: 3000
          });
          console.error('单参数 Token 刷新失败:', result);
        }
      }

    } catch (error) {
      console.error('刷新 Token 失败:', error);
      promptAction.showToast({
        message: `刷新 Token 失败: ${error}`,
        duration: 3000
      });
    }
  }
}