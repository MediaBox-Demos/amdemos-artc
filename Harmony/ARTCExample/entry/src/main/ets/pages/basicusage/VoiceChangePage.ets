import {
  AliRtcEngine,
  AliRtcVideoCanvas,
  AliRtcVideoTrack,
  AliRtcXComponentController,
  AliRtcEngineEventListener,
  AliRtcVideoEncoderConfiguration,
  AliRtcEngineAuthInfo,
  AliRtcChannelProfile,
  AliRtcClientRole,
  AliRtcAudioProfile,
  AliRtcAudioScenario,
  AliRtcVideoMirrorMode,
  AliRtcRotationMode,
  AliRtcVideoEncoderOrientationMode,
  AliRtcRenderMode,
  AliRtcRenderMirrorMode,
  AliRtcUserOfflineReason,
  AliRtcAudioTrack,
  AliRtcLocalDeviceType,
  AliRtcLocalDeviceExceptionType,
  AliRtcAudioEffectVoiceChangerMode,
  AliRtcAudioEffectReverbMode,
  AliRtcAudioEffectBeautifyMode,
  AliRtcConnectionStatus,
  AliRtcConnectionStatusChangeReason,
  AliRtcVideoDimensions,
  AliRtcCapturePipelineScaleMode
} from "@aliyun_video_cloud/alivcsdk_artc";
import { CustomTitle } from "../../common/components/CustomTitle"
import { common } from "@kit.AbilityKit";
import { ISelectOption } from "../../common/Constants";
import { prompt, promptAction } from '@kit.ArkUI';
import { RemoteVideoStream } from "../../common/Constants"
import { ARTCTokenHelper } from '../../common/keycenter/ARTCTokenHelper';
import { GlobalConfig } from '../../common/keycenter/GlobalConfig';

@Entry
@Component
export struct VoiceChangePage {
  // 基本状态
  @State initRoom: boolean = false
  @State channelId: string = Date.now().toString().slice(-6);
  @State ShowPreview: boolean = false;
  // 远端视频流管理
  @State remoteVideoStreams: RemoteVideoStream[] = []
  private rtcEngine: AliRtcEngine | undefined;
  private context: common.Context | undefined;
  private xcomponentController: XComponentController = new XComponentController();
  private aliRtcVideoCanvas: AliRtcVideoCanvas | undefined;
  private componentController: AliRtcXComponentController = new AliRtcXComponentController();
  private voiceChangerModes: Map<number, AliRtcAudioEffectVoiceChangerMode> | undefined;
  private reverbModes: Map<number, AliRtcAudioEffectReverbMode> | undefined;
  private beautifyModes: Map<number, AliRtcAudioEffectBeautifyMode> | undefined;
  private rtcEventListener?: AliRtcEngineEventListener;
  // 音频效果状态
  @State audioRoute: string = '关闭'
  @State audioHunXiangRoute: string = '关闭'
  @State audioMeiShengRoute: string = '关闭'
  @State earBackEnabled: boolean = true
  // 音频效果选项
  private voiceChangeOptions: string[] = [
    '关闭', '老人', '男孩', '女孩', '机器人', '大魔王', 'KTV', '回声', '方言', '怒吼', '电音', '留声机'
  ];
  private reverbOptions: string[] = [
    '关闭', '人声I', '人声II', '澡堂', '明亮小房间', '黑暗小房间', '中等房间', '大房间', '教堂走廊'
  ];
  private voiceBeautifierOptions: string[] = [
    '关闭', '浑厚', '嘹亮'
  ];

  async aboutToAppear(): Promise<void> {
    this.context = getContext() as common.Context;
    this.initEnumMaps();
  }


  aboutToDisappear(): void {
    this.destroyRtcEngine();

  }

  build() {
    NavDestination() {
      Column() {
        CustomTitle({
          titleText: '设置变声、混响、美声',
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
          .margin({ top: 20 })
          .height(50)

          Row() {
            Text("耳返")
              .fontSize(16)
              .fontColor('#636363')
              .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.earBackEnabled })
              .onChange((isOn: boolean) => {
                this.earBackEnabled = isOn;
                if (this.rtcEngine) {
                  this.rtcEngine.enableEarBack(isOn);
                }
              })
          }
          .width('100%')
          .height(36)
          .borderRadius(4)
          .margin({ top: 8 })

          // 变声选择
          this.buildConfigItem('变声', this.audioRoute, this.voiceChangeOptions,
            (value: string) => {
              this.audioRoute = value;
              this.setVoiceChangeMode(this.voiceChangeOptions.indexOf(value));
            })

          // 混响选择
          this.buildConfigItem('混响', this.audioHunXiangRoute, this.reverbOptions,
            (value: string) => {
              this.audioHunXiangRoute = value;
              this.setVoiceReverbEffect(this.reverbOptions.indexOf(value));
            })

          // 美声选择
          this.buildConfigItem('美声', this.audioMeiShengRoute, this.voiceBeautifierOptions,
            (value: string) => {
              this.audioMeiShengRoute = value;
              this.setVoiceBeautifyEffect(this.voiceBeautifierOptions.indexOf(value));
            })

          // 加入/离开房间按钮
          Text(this.initRoom ? '挂断' : '加入房间')
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
              await this.handleJoinRoom();
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
  private initEnumMaps(): void {
    // 初始化变声模式映射
    this.voiceChangerModes = new Map<number, AliRtcAudioEffectVoiceChangerMode>();
    this.voiceChangerModes.set(0, AliRtcAudioEffectVoiceChangerMode.AliRtcAudioEffectVoiceChangerOff);
    this.voiceChangerModes.set(1, AliRtcAudioEffectVoiceChangerMode.AliRtcAudioEffectVoiceChangerOldMan);
    this.voiceChangerModes.set(2, AliRtcAudioEffectVoiceChangerMode.AliRtcAudioEffectVoiceChangerBabyBoy);
    this.voiceChangerModes.set(3, AliRtcAudioEffectVoiceChangerMode.AliRtcAudioEffectVoiceChangerBabGirl);
    this.voiceChangerModes.set(4, AliRtcAudioEffectVoiceChangerMode.AliRtcAudioEffectVoiceChangerRobot);
    this.voiceChangerModes.set(5, AliRtcAudioEffectVoiceChangerMode.AliRtcAudioEffectVoiceChangerDaimo);
    this.voiceChangerModes.set(6, AliRtcAudioEffectVoiceChangerMode.AliRtcAudioEffectVoiceChangerKTV);
    this.voiceChangerModes.set(7, AliRtcAudioEffectVoiceChangerMode.AliRtcAudioEffectVoiceChangerEcho);
    this.voiceChangerModes.set(8, AliRtcAudioEffectVoiceChangerMode.AliRtcAudioEffectVoiceChangerDialect);
    this.voiceChangerModes.set(9, AliRtcAudioEffectVoiceChangerMode.AliRtcAudioEffectVoiceChangerHow);
    this.voiceChangerModes.set(10, AliRtcAudioEffectVoiceChangerMode.AliRtcAudioEffectVoiceChangerElectroinc);
    this.voiceChangerModes.set(11, AliRtcAudioEffectVoiceChangerMode.AliRtcAudioEffectVoiceChangerPhonograph);

    // 初始化混响模式映射
    this.reverbModes = new Map<number, AliRtcAudioEffectReverbMode>();
    this.reverbModes.set(0, AliRtcAudioEffectReverbMode.AliRtcAudioEffectReverbOff);
    this.reverbModes.set(1, AliRtcAudioEffectReverbMode.AliRtcAudioEffectReverbVocal_I);
    this.reverbModes.set(2, AliRtcAudioEffectReverbMode.AliRtcAudioEffectReverbVocal_II);
    this.reverbModes.set(3, AliRtcAudioEffectReverbMode.AliRtcAudioEffectReverbBathroom);
    this.reverbModes.set(4, AliRtcAudioEffectReverbMode.AliRtcAudioEffectReverbSmallRoomBright);
    this.reverbModes.set(5, AliRtcAudioEffectReverbMode.AliRtcAudioEffectReverbSmallRoomDark);
    this.reverbModes.set(6, AliRtcAudioEffectReverbMode.AliRtcAudioEffectReverbMediumRoom);
    this.reverbModes.set(7, AliRtcAudioEffectReverbMode.AliRtcAudioEffectReverbLargeRoom);
    this.reverbModes.set(8, AliRtcAudioEffectReverbMode.AliRtcAudioEffectReverbChurchHall);

    // 初始化美声模式映射
    this.beautifyModes = new Map<number, AliRtcAudioEffectBeautifyMode>();
    this.beautifyModes.set(0, AliRtcAudioEffectBeautifyMode.AliRtcAudioEffectBeautifyOff);
    this.beautifyModes.set(1, AliRtcAudioEffectBeautifyMode.AliRtcAudioEffectBeautifyVigorous);
    this.beautifyModes.set(2, AliRtcAudioEffectBeautifyMode.AliRtcAudioEffectBeautifyRinging);
  }

  @Builder
  private buildConfigItem(label: string, value: string, options: string[],
    onSelect: (value: string) => void, enabled: boolean = true) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor('#636363')
        .layoutWeight(0.8)

      Select(options.map((option: string) => {
        return { value: option } as ISelectOption;
      }))
        .selected(options.indexOf(value) >= 0 ? options.indexOf(value) : 0)
        .value(value)
        .font({ size: 16 })
        .fontColor(enabled ? '#000' : '#ccc')
        .backgroundColor('#fff')
        .onSelect((index: number) => {
          if (index >= 0 && index < options.length) {
            const selectedValue = options[index];
            onSelect(selectedValue);
          }
        })
        .layoutWeight(1.2)
        .margin({ right: 8 })
        .enabled(enabled)
    }
    .width('100%')
    .height(36)
    .borderRadius(4)
    .margin({ top: 8 })
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
            .width('100%')
            .height('100%')
            .onLoad(() => {
              this.setupLocalVideo();
            })
        }
        .backgroundColor('#000')
        .width('100%')
        .height('200vp')
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
    .height('400vp')
    .margin({
      top: 20
    })
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
  }

  private setVoiceChangeMode(effectType: number): void {
    if (this.rtcEngine && this.voiceChangerModes) {
      const mode =
        this.voiceChangerModes.get(effectType) || AliRtcAudioEffectVoiceChangerMode.AliRtcAudioEffectVoiceChangerOff;
      this.rtcEngine.setAudioEffectVoiceChangerMode(mode);
      console.info(`设置变声效果: ${this.voiceChangeOptions[effectType]}, mode: ${mode}`);
    }
  }

  private setVoiceReverbEffect(effectType: number): void {
    if (this.rtcEngine && this.reverbModes) {
      const mode = this.reverbModes.get(effectType) || AliRtcAudioEffectReverbMode.AliRtcAudioEffectReverbOff;
      this.rtcEngine.setAudioEffectReverbMode(mode);
      console.info(`设置混响效果: ${this.reverbOptions[effectType]}, mode: ${mode}`);
    }
  }

  private setVoiceBeautifyEffect(effectType: number): void {
    if (this.rtcEngine && this.beautifyModes) {
      const mode = this.beautifyModes.get(effectType) || AliRtcAudioEffectBeautifyMode.AliRtcAudioEffectBeautifyOff;
      this.rtcEngine.setAudioEffectBeautifyMode(mode);
      console.info(`设置美声效果: ${this.voiceBeautifierOptions[effectType]}, mode: ${mode}`);
    }
  }

  // 处理加入/离开房间
  private async handleJoinRoom(): Promise<void> {
    if (this.initRoom) {
      this.destroyRtcEngine();
      this.initRoom = false;
      prompt.showToast({ message: '已离开房间', duration: 2000 });
      return;
    }

    try {
      // 验证必要参数
      if (!this.channelId.trim()) {
        prompt.showToast({ message: '请输入频道ID', duration: 2000 });
        return;
      }
      // 初始化RTC引擎
      this.initAndSetupRtcEngine();

      // 开始本地预览
      this.startPreview();

      // 加入频道
      await this.joinChannel();

      this.initRoom = true;
      console.info('成功加入房间');

    } catch (error) {
      console.error('加入房间失败:', error);
      prompt.showToast({
        message: `加入房间失败: ${error}`,
        duration: 3000
      });
      this.initRoom = false;
    }
  }

  // 生成timestamp
  private generateTimestamp(): void {
    const seconds = Math.floor(Date.now() / 1000);
    const timestamp = seconds + 86400;
    // timestamp 不再存储为成员变量
  }

  // 初始化并设置RTC引擎
  private async initAndSetupRtcEngine(): Promise<void> {
    if (this.rtcEngine) {
      return;
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
      // 设置事件监听器
      this.setupEventListeners();

      // 设置频道模式为互动模式
      this.rtcEngine.setChannelProfile(AliRtcChannelProfile.AliRtcInteractiveLive);

      // 设置用户角色
      this.rtcEngine.setClientRole(AliRtcClientRole.AliRtcClientRoleInteractive);

      // 设置音频Profile（高音质模式及音乐模式）
      this.rtcEngine.setAudioProfile(
        AliRtcAudioProfile.AliRtcHighQualityMode,
        AliRtcAudioScenario.AliRtcSceneMusicMode
      );

      // 设置视频编码配置
      const videoConfig: AliRtcVideoEncoderConfiguration = new AliRtcVideoEncoderConfiguration();
      videoConfig.dimensions.width = 720;
      videoConfig.dimensions.height = 1280;
      videoConfig.frameRate = 20;
      videoConfig.bitrate = 1200;
      videoConfig.keyFrameInterval = 2000;
      videoConfig.orientationMode = AliRtcVideoEncoderOrientationMode.AliRtcVideoEncoderOrientationModeAdaptive;
      videoConfig.mirrorMode = AliRtcVideoMirrorMode.AliRtcVideoMirrorModeDisabled;
      videoConfig.rotationMode = AliRtcRotationMode.AliRtcRotationMode_0;
      this.rtcEngine.setVideoEncoderConfiguration(videoConfig);

      // 设置
      this.rtcEngine.setCapturePipelineScaleMode(AliRtcCapturePipelineScaleMode.AliRtcCapturePipelineScaleModePost);

      // 发布本地音视频流
      this.rtcEngine.publishLocalAudioStream(true);
      this.rtcEngine.publishLocalVideoStream(true);

      // 设置默认订阅所有远端音视频流
      this.rtcEngine.setDefaultSubscribeAllRemoteAudioStreams(true);
      this.rtcEngine.setDefaultSubscribeAllRemoteVideoStreams(true);

      // 明确订阅所有远端音视频流
      this.rtcEngine.subscribeAllRemoteAudioStreams(true);
      this.rtcEngine.subscribeAllRemoteVideoStreams(true);

      // 开启耳返（根据开关状态）
      if (this.earBackEnabled) {
        this.rtcEngine.enableEarBack(true);
      }

      console.info('RTC引擎初始化完成');

    } catch (error) {
      console.error('RTC引擎初始化失败:', error);
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
          : `Join ${channel} Failed！， error：${resultCode}`;

        prompt.showToast({
          message: resultText,
          duration: 2000
        });

        this.initRoom = true;
      })

      this.rtcEventListener.onLeaveChannel((resultCode: number) => {
        console.info(`离开频道结果: result=${resultCode}`);
        prompt.showToast({
          message: 'Leave Channel',
          duration: 2000
        });
      })

      this.rtcEventListener.onConnectionStatusChange((status: number, reason: number) => {
        console.info(`连接状态变更: status=${status}, reason=${reason}`);

        if (status !== AliRtcConnectionStatus.AliRtcConnectionInit) {
          prompt.showToast({
            message: '连接失败',
            duration: 3000
          });
        }
      })

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

      this.rtcEventListener.onLocalDeviceException((deviceType: AliRtcLocalDeviceType, exceptionType: AliRtcLocalDeviceExceptionType,
        msg: string) => {
        console.error(`本地设备异常: deviceType=${deviceType}, exceptionType=${exceptionType}, msg=${msg}`);
        prompt.showToast({
          message: `设备异常: ${msg}`,
          duration: 3000
        });
      })

      this.rtcEventListener.onBye((code: number) => {
        console.info(`被服务器踢出: code=${code}`);
        prompt.showToast({
          message: `被服务器踢出: ${code}`,
          duration: 3000
        });
        this.destroyRtcEngine();
      })
    }

    this.rtcEngine.setRtcEngineEventListener(this.rtcEventListener);
  }

  // 设置本地视频
  private setupLocalVideo(): void {
    if (!this.context || !this.rtcEngine) {
      console.error('Context或RTC引擎未初始化');
      return;
    }

    try {
      let surfaceId = this.xcomponentController.getXComponentSurfaceId();
      console.info('获取到本地视频surfaceId:', surfaceId);

      this.aliRtcVideoCanvas = new AliRtcVideoCanvas();
      this.aliRtcVideoCanvas.surfaceId = surfaceId;
      this.aliRtcVideoCanvas.renderMode = AliRtcRenderMode.AliRtcRenderModeAuto;
      this.aliRtcVideoCanvas.mirrorMode = AliRtcRenderMirrorMode.AliRtcRenderMirrorModeAllMirror;
      this.startPreview()
      console.info('本地视频画布设置完成');

    } catch (error) {
      console.error('设置本地视频失败:', error);
    }
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

  // 开始本地预览
  private startPreview(): void {
    if (!this.rtcEngine) {
      return;
    }

    try {
      if (this.aliRtcVideoCanvas) {
        this.rtcEngine.setLocalViewConfig(
          this.aliRtcVideoCanvas,
          this.componentController,
          AliRtcVideoTrack.AliRtcVideoTrackCamera
        );
      }

      // 开始预览
      this.rtcEngine.startPreview();
      this.ShowPreview = true;

      console.info('本地预览已启动');

    } catch (error) {
      console.error('启动预览失败:', error);
    }
  }

  // 加入频道
  private async joinChannel(): Promise<void> {
    if (!this.rtcEngine || !this.channelId.trim()) {
      prompt.showToast({
        message: '频道ID不能为空',
        duration: 2000
      });
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
        appId,
        appKey,
        this.channelId,
        userId,
        timestamp,
        nonce
      );

      // 加入频道
      const result = this.rtcEngine.joinChannelWithToken(base64Token, '', '', '变声混响用户');
      console.info('加入频道调用结果:', result);

    } catch (error) {
      console.error('加入频道失败:', error);
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


    // 从数组中移除该用户的所有流
    this.remoteVideoStreams = this.remoteVideoStreams.filter(s => s.uid !== uid);

    console.info(`移除用户所有视频成功: ${uid}`);
  }

  // 根据流类型获取唯一标识
  private getStreamKey(uid: string, videoTrack: AliRtcVideoTrack): string {
    return `${uid}_${videoTrack}`;
  }

  // 获取流类型文本
  private getTrackTypeText(track: AliRtcVideoTrack): string {
    switch (track) {
      case AliRtcVideoTrack.AliRtcVideoTrackCamera:
        return '-Camera';
      case AliRtcVideoTrack.AliRtcVideoTrackScreen:
        return '-Screen';
      case AliRtcVideoTrack.AliRtcVideoTrackBoth:
        return '-Both';
      default:
        return '-Unknown';
    }
  }

  // 销毁RTC引擎
  private destroyRtcEngine(): void {
    if (this.rtcEngine) {
      try {
        if (this.initRoom) {
          this.rtcEngine.leaveChannel();
          this.initRoom = false;
        }
        // 销毁引擎
        this.rtcEngine = undefined;
        console.info('RTC引擎已销毁');
        this.rtcEngine = undefined;
      } catch (error) {
        console.error('销毁RTC引擎失败:', error);
      }
    }

    // 清理状态
    this.initRoom = false;
    this.ShowPreview = false;
    this.remoteVideoStreams = [];
    this.aliRtcVideoCanvas = undefined;
  }



  // 判断是否显示多人网格布局
  private shouldShowGridLayout(): boolean {
    return this.ShowPreview && this.remoteVideoStreams.length > 0;
  }
}