import { CustomTitle } from '../../common/components/CustomTitle';
import {
  AliRtcEngine,
  AliRtcEngineEventListener,
  AliRtcEngineAuthInfo,
  AliRtcChannelProfile,
  AliRtcClientRole,
  AliRtcAudioProfile,
  AliRtcAudioScenario,
  AliRtcAudioRouteType,
  AliRtcMuteLocalAudioMode,
  AliRtcConnectionStatus,
  AliRtcConnectionStatusChangeReason,
  AliRtcUserOfflineReason,
  AliRtcStats,
  AliRtcLocalDeviceType,
  AliRtcLocalDeviceExceptionType,
  AliRtcRemoteAudioStats,
  AliRtcAudioTrack,
  AliRtcVideoTrack,
} from '@aliyun_video_cloud/alivcsdk_artc';
import common from '@ohos.app.ability.common';
import { prompt, AlertDialog } from '@kit.ArkUI';
import { ISelectOption } from '../../common/Constants';
import { ARTCTokenHelper } from '../../common/keycenter/ARTCTokenHelper';
import { GlobalConfig } from '../../common/keycenter/GlobalConfig';

@CustomDialog
struct CustomDialogExample {
  controller?: CustomDialogController;
  dialogSelectedUserId: string = '';
  dialogMuteOption: string = '';
  cancel: () => void = () => {
  }
  confirm1: () => void = () => {
  }
  confirm2: () => void = () => {
  }

  build() {
    Column({ space: 10 }) {
      Text(this.dialogSelectedUserId ?? '1')
        .fontSize(20)
        .margin({
          left: 20
        })
        .height(40)
        .textAlign(TextAlign.Center)

      Text(this.dialogMuteOption ?? '1')
        .fontSize(13)
        .margin({
          left: 20
        })
        .height(40)
        .textAlign(TextAlign.Center)

        .onClick(() => {
          this.confirm1();
        })
      Text('设置播放音量')
        .fontSize(13)
        .margin({
          left: 20
        })
        .height(40)
        .textAlign(TextAlign.Center)

        .onClick(() => {
          this.confirm2();
        })
      Text('取消')
        .fontSize(13)
        .height(40)
        .textAlign(TextAlign.Center)
        .margin({
          left: 20
        })
        .onClick(() => {
          if (this.controller != undefined) {
            this.controller.close();
          }
        })

    }.height(200)
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
  }
}

@Entry
@Component
export struct AudioBasicUsage {
  @State InSilentMicrophone: boolean = false
  @State OnSilentMicrophone: boolean = false
  @State ChannelId: string = '';
  // RTC相关状态
  @State hasJoined: boolean = false
  @State isMute: boolean = false
  @State isMicrophoneClosed: boolean = false
  // 音频配置状态
  @State audioRoute: string = '扬声器'
  @State audioScenario: string = 'MUSIC'
  @State audioProfile: string = 'LowQualityMode'
  @State earBackEnabled: boolean = false
  @State earBackVolume: number = 100
  @State playoutVolume: number = 20
  @State muteAllRemoteUsers: boolean = false
  // 用户管理
  @State localUserId: string = ''
  @State remoteUsers: Array<string> = []
  // UI状态控制
  @State audioScenarioEnabled: boolean = true
  @State audioProfileEnabled: boolean = true
  @State channelIdEnabled: boolean = true
  @State stopCaptureEnabled: boolean = false
  @State playoutVolumeEnabled: boolean = false
  @State mirrorModeIndexMusic: number = 0;
  @State mirrorModeIndexHigh: number = 0;
  @State mirrorModeIndex: number = 0;
  // RTC引擎实例
  private rtcEngine: AliRtcEngine | undefined;
  private rtcEngineEventListener: AliRtcEngineEventListener | undefined;
  private rtcRemoteAudioStats: AliRtcRemoteAudioStats | undefined;
  private context: common.Context | undefined;
  // 远端用户静音状态映射
  private userMuteStatusMap: Map<string, boolean> = new Map();
  @State showVolumeSliderDialog: boolean = false;
  @State selectedRemoteUserId: string = '';
  @State volumeSliderValue: number = 100;
  @State dialogSelectedUserId: string = '';
  @State dialogMuteOption: string = '';
  dialogController: CustomDialogController = new CustomDialogController({
    builder: CustomDialogExample({
      dialogSelectedUserId: this.dialogSelectedUserId,
      dialogMuteOption: this.dialogMuteOption,
      cancel: () => {
      },
      confirm1: () => {
        this.toggleMuteRemoteUser(this.dialogSelectedUserId);
        this.dialogController.close();
      },
      confirm2: () => {
        this.selectedRemoteUserId = this.dialogSelectedUserId;
        this.volumeSliderValue = 100;
        this.showVolumeSliderDialog = true;
        this.dialogController.close();
      }
    }),
    autoCancel: true,
    onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
      if (dismissDialogAction.reason == DismissReason.PRESS_BACK) {
        dismissDialogAction.dismiss();
      }
      if (dismissDialogAction.reason == DismissReason.TOUCH_OUTSIDE) {
        dismissDialogAction.dismiss();
      }
    },
    alignment: DialogAlignment.Center,
    offset: { dx: 0, dy: -20 },
    customStyle: false,
    cornerRadius: 20,
    width: 300,
    height: 200,
    backgroundColor: Color.White,
    shadow: ({
      radius: 20,
      color: Color.Grey,
      offsetX: 50,
      offsetY: 0
    }),
  })

  aboutToAppear(): void {
    this.ChannelId = Math.floor(100000 + Math.random() * 900000).toString();
    this.context = getContext() as common.Context;
    // 初始化默认选中项
    this.audioScenario = 'MUSIC';
    this.audioProfile = 'HighQualityMode';
  }

  aboutToDisappear(): void {
    this.destroyRtcEngine();
    // 清除所有状态
    this.remoteUsers = [];
    this.userMuteStatusMap.clear();

    // 移除所有事件监听器
    if (this.rtcEngine) {
      this.rtcEngine.setRtcEngineEventListener(null);
    }
  }

  build() {
    NavDestination() {
      Column() {
        CustomTitle({
          titleText: '音频常用操作和配置',
        })
        this.buildAudio()
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#f5f5f5')  // 设置固定背景色以避免暗色模式下变黑
    }
    .hideTitleBar(true)
  }

  @Builder
  buildAudio() {
    Column() {
      Text('点击下方远端用户麦位进行更多操作')
        .fontSize('16')
        .width('100%')
        .textAlign(TextAlign.Start)
        .fontColor('#666666')  // 更好的对比度

      // 用户麦位显示区域
      this.builderUserGrid()

      this.builderAudioItem()
      // 添加自定义对话框
      if (this.showVolumeSliderDialog) {
        Stack({ alignContent: Alignment.Center }) {
          // 半透明背景
          Row()
            .width('100%')
            .height('100%')
            .backgroundColor('#000000')
            .opacity(0.5)
            .onClick(() => {
              this.showVolumeSliderDialog = false;
            })

          // 音量设置对话框
          this.buildVolumeSliderDialog()
        }
        .width('100%')
        .height('100%')
        .position({ x: 0, y: 0 })
      }
    }
    .width('100%')
    .height('100%')
  }

  // 显示音频用户麦位
  @Builder
  builderUserGrid() {
    Grid() {
      // 本地用户麦位
      if (this.localUserId) {
        GridItem() {
          this.buildUserItem(this.localUserId, true)
        }
      }

      // 远端用户麦位
      ForEach(this.remoteUsers, (userId: string) => {
        GridItem() {
          this.buildUserItem(userId, false, () => {
            this.showRemoteUserOptions(userId);
          })

        }
      }, (userId: string) => userId)
    }
    .columnsTemplate('1fr 1fr')
    .rowsTemplate('1fr')
    .columnsGap(8)
    .rowsGap(8)
    .width('100%')
    .height(180)
    .margin({ top: 8, bottom: 16 })
  }

  @Builder
  buildUserItem(userId: string, isLocal: boolean, onClick?: () => void) {
    Column() {
      Text(isLocal ? `Local: ${userId}` : `Remote: ${userId}`)
        .fontSize(14)
        .fontColor('#FFFFFF')
        .padding(8)
        .backgroundColor('#80000000')
        .width('100%')
        .textAlign(TextAlign.Start)

    }
    .onClick(() => {
      if (onClick) {
        onClick();
      }
    })
    .width('100%')
    .height('100%')
    .backgroundColor('#808080')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  builderAudioItem() {
    Column() {
      this.buildConfigItem('Audio Route', this.audioRoute, ['扬声器', '听筒'], (value: string) => {
        this.onAudioRouteChange(value);
      })
      Row() {
        Text('Audio Scenario')
          .fontSize(16)
          .fontColor('#636363')
          .layoutWeight(0.8)

        Select([{ value: 'DEFAULT' }, { value: 'MUSIC' }])
          .selected(this.mirrorModeIndexMusic)
          .value(this.audioScenario)
          .font({ size: 16 })
          .fontColor(this.audioScenarioEnabled ? '#000' : '#ccc')
          .backgroundColor('#00fdfdfb')
          .onSelect((index: number, text: string) => {
            this.mirrorModeIndexMusic = index;
            this.audioScenario = text;

          })
          .layoutWeight(1.2)
          .margin({ right: 8 })
          .enabled(this.audioScenarioEnabled)
      }
      .width('100%')
      .height(36)
      .borderRadius(4)
      .margin({ top: 8 })


      Row() {
        Text('Audio Profile')
          .fontSize(16)
          .fontColor('#636363')
          .layoutWeight(0.8)

        Select([{ value: 'LowQualityMode' }, { value: 'BasicQualityMode' }, { value: 'HighQualityMode' },
          { value: 'StereoHighQualityMode' }, { value: 'SuperHighQualityMode' },
          { value: 'StereoSuperHighQualityMode' }])
          .selected(this.mirrorModeIndexMusic)
          .value(this.audioProfile)
          .font({ size: 16 })
          .fontColor(this.audioScenarioEnabled ? '#000' : '#ccc')
          .backgroundColor('#00fdfdfb')
          .onSelect((index: number, text: string) => {
            this.mirrorModeIndexMusic = index;
            this.audioProfile = text;

          })
          .layoutWeight(1.2)
          .margin({ right: 8 })
          .enabled(this.audioScenarioEnabled)
      }
      .width('100%')
      .height(36)
      .borderRadius(4)
      .margin({ top: 8 })

      this.buildSwitchItem('耳返(请插入耳机后再体验耳返功能)', this.earBackEnabled, (value: boolean) => {
        this.onEarBackChange(value);
      })

      this.buildSliderItem('耳返音量', this.earBackVolume, (value: number) => {
        this.onEarBackVolumeChange(value);
      })

      this.buildButtonItem()

      Row() {
        Text('播放音量')
          .fontSize(16)
          .fontColor('#636363')
          .layoutWeight(0.5)

        Slider({
          value: this.playoutVolume,
          min: 0,
          max: 100,
          step: 1,
        })
          .blockColor('#05d8c5')
          .selectedColor(this.playoutVolumeEnabled ? '#05d8c5' : '#ffafb8b7')
          .onChange((isOn: number) => {
            this.onPlayoutVolumeChange(isOn);
          })
          .layoutWeight(1.5)
          .enabled(this.playoutVolumeEnabled)
      }
      .width('100%')
      .height(36)
      .borderRadius(4)
      .margin({ top: 8 })

      this.buildSwitchItem('静音所有远端用户', this.muteAllRemoteUsers, (value: boolean) => {
        this.onMuteAllRemoteUsersChange(value);
      })

      this.buildChannelId()

      this.buildJoinChannel()
    }
    .margin(12)
  }

  @Builder
  private buildConfigItem(label: string, value: string, options: string[], onClick: (value: string) => void,
    enabled: boolean = true) {
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
        .fontColor(enabled ? '#000000' : '#cccccc')
        .backgroundColor('#ffffff')  // 固定背景色
        .onSelect((index: number) => {
          if (index >= 0 && index < options.length) {
            const selectedValue = options[index];
            onClick(selectedValue);
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
  private buildSwitchItem(label: string, value: boolean, onValueChange: (value: boolean) => void) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor('#636363')
        .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: value })
        .selectedColor('#3295fb')  // 固定选中颜色
        .onChange((isOn: boolean) => {
          onValueChange(isOn);
        })
    }
    .width('100%')
    .height(36)
    .borderRadius(4)
    .margin({ top: 8 })
  }

  @Builder
  private buildSliderItem(label: string, value: number, onValueChange: (value: number) => void,
    enabled: boolean = true) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor('#636363')
        .layoutWeight(0.5)

      Slider({
        value: value,
        min: 0,
        max: 100,
        step: 1,
      })
        .blockColor('#05d8c5')
        .selectedColor('#05d8c5')
        .onChange((isOn: number) => {
          onValueChange(isOn);
        })
        .layoutWeight(1.5)
        .enabled(enabled)
    }
    .width('100%')
    .height(36)
    .borderRadius(4)
    .margin({ top: 8 })
  }

  @Builder
  private buildButtonItem() {
    Row() {
      Button(this.InSilentMicrophone ? '取消静音' : '静音麦克风')
        .fontSize(16)
        .fontColor('#000000')
        .backgroundColor('#d9dbda')
        .type(ButtonType.Normal)
        .onClick(() => {
          this.onMuteMicClick();
        })
        .layoutWeight(1)
        .margin({ top: 8 })

      Blank()
        .layoutWeight(0.2)

      Button(this.OnSilentMicrophone ? '打开麦克风采集' : '关闭麦克风采集')
        .fontSize(16)
        .type(ButtonType.Normal)
        .fontColor('#000000')
        .backgroundColor('#d9dbda')
        .onClick(() => {
          this.onStopCaptureClick();
        })
        .layoutWeight(1)
        .margin({ top: 8 })
        .enabled(this.stopCaptureEnabled)
    }
  }

  @Builder
  private buildChannelId() {
    Row() {
      Text('ChannelID:')
        .fontSize(16)
        .fontColor('#333333')  // 固定文字颜色

      TextInput({
        text: this.ChannelId
      })
        .padding({ left: 8, right: 8 })
        .backgroundColor('#ffffff')     // 固定白色背景
        .fontColor('#000000')          // 固定黑色文字
        .layoutWeight(1)
        .height(40)
        .border({
          width: 1,
          color: '#dddddd',           // 固定边框颜色
          radius: 4
        })
        .margin({ left: 10 })
        .onChange((text: string) => {
          this.ChannelId = text;
        })
        .enabled(this.channelIdEnabled)
    }
    .margin({ top: 20 })
    .height(50)
  }

  @Builder
  private buildJoinChannel() {
    Button(this.hasJoined ? '挂断' : '加入房间')
      .fontSize(16)
      .fontColor('#ffffff')         // 白色文字
      .backgroundColor('#3295fb')   // 固定蓝色背景
      .type(ButtonType.Normal)
      .width('100%')
      .onClick(() => {
        this.onJoinChannelClick();
      })
      .margin({ top: 20 })
  }

  // ==================== 业务逻辑实现 ====================

  // 创建RTC引擎
  private createRtcEngine(): void {
    if (!this.rtcEngine && this.context) {
      this.rtcEngine = AliRtcEngine.getInstance('', this.context);
      this.setupEventListeners();
    }
  }

  // 设置事件监听器
  private setupEventListeners(): void {
    if (!this.rtcEngine) {
      return;
    }

    // 设置事件监听器
    this.rtcEngineEventListener = new AliRtcEngineEventListener();

    this.rtcEngineEventListener.onJoinChannel((resultCode: number, channel: string, elapsed: string) => {
      console.info(`加入频道结果: result=${resultCode}, channel=${channel}, elapsed=${elapsed}`);
      this.handleJoinResult(resultCode, channel);
    });

    // ==================== 完善远端音视频流可用监听 ====================
    this.rtcEngineEventListener.onRemoteTrackAvailableNotify((userId: string, audioTrack: AliRtcAudioTrack,
      videoTrack: AliRtcVideoTrack) => {
      console.info(`远端音视频流可用: userId=${userId}, audioTrack=${audioTrack}, videoTrack=${videoTrack}`);

      // 处理音频流可用情况
      if (audioTrack === AliRtcAudioTrack.AliRtcAudioTrackNo) {
        console.info(`用户 ${userId} 没有音频流`);
      } else if (audioTrack === AliRtcAudioTrack.AliRtcAudioTrackMic) {
        console.info(`用户 ${userId} 有麦克风音频流`);
        // 用户有音频流，添加到UI显示
        setTimeout(() => {
          this.handleRemoteUserOnline(userId);
        }, 0);
      } else if (audioTrack === AliRtcAudioTrack.AliRtcAudioTrackDual) {
        console.info(`用户 ${userId} 有双声道音频流`);
        setTimeout(() => {
          this.handleRemoteUserOnline(userId);
        }, 0);
      } else if (audioTrack === AliRtcAudioTrack.AliRtcAudioTrackBoth) {
        console.info(`用户 ${userId} 有麦克风和屏幕共享音频流`);
        setTimeout(() => {
          this.handleRemoteUserOnline(userId);
        }, 0);
      } else {
        // 其他音频轨道类型
        console.info(`用户 ${userId} 有其他类型音频流: ${audioTrack}`);
        setTimeout(() => {
          this.handleRemoteUserOnline(userId);
        }, 0);
      }
    });

    this.rtcEngineEventListener.onOccurWarning((warn: number, message: string) => {
      console.warn(`发生警告: warn=${warn}, message=${message}`);
      prompt.showToast({ message: `警告: ${warn} - ${message}`, duration: 2000 });
    });

    this.rtcEngineEventListener.onLeaveChannel((result: number, stats: AliRtcStats) => {
      console.info(`离开频道结果: result=${result}`);
    });

    this.rtcEngineEventListener.onConnectionStatusChange
    ((status: AliRtcConnectionStatus, reason: AliRtcConnectionStatusChangeReason) => {
      console.info(`连接状态改变: status=${status}, reason=${reason}`);
      if (status === AliRtcConnectionStatus.AliRtcConnectionFailed) {
        prompt.showToast({ message: '连接失败', duration: 2000 });
      }
    });

    this.rtcEngineEventListener.onLocalDeviceException
    ((deviceType: AliRtcLocalDeviceType, exceptionType: AliRtcLocalDeviceExceptionType, msg: string) => {
      console.error(`本地设备异常: deviceType=${deviceType}, exceptionType=${exceptionType}, msg=${msg}`);
      prompt.showToast({ message: `设备异常: ${msg}`, duration: 2000 });
    });

    if (this.rtcEngineEventListener.onRemoteUserOffline) {
      this.rtcEngineEventListener.onRemoteUserOffline((uid: string, reason: AliRtcUserOfflineReason) => {
        console.info(`远端用户下线: uid=${uid}, reason=${reason}`);
        setTimeout(() => {
          this.handleRemoteUserOffline(uid);
        }, 0);
      });
    }

    this.rtcEngine.setRtcEngineEventListener(this.rtcEngineEventListener);
  }

  // 初始化和配置RTC引擎
  private async initAndSetupRtcEngine(): Promise<void> {
    this.createRtcEngine();

    if (!this.rtcEngine) {
      prompt.showToast({ message: 'RTC引擎创建失败', duration: 2000 });
      return;
    }

    try {
      // 设置频道模式为互动直播模式
      this.rtcEngine.setChannelProfile(AliRtcChannelProfile.AliRtcInteractiveLive);

      // 设置用户角色为互动模式
      this.rtcEngine.setClientRole(AliRtcClientRole.AliRtcClientRoleInteractive);

      // 设置音频配置
      const audioProfile = this.getAudioProfile();
      const audioScenario = this.getAudioScenario();
      this.rtcEngine.setAudioProfile(audioProfile, audioScenario);

      // 发布本地音频流
      this.rtcEngine.publishLocalAudioStream(true);
      this.rtcEngine.publishLocalVideoStream(false);

      // 设置默认订阅所有远端音频流
      this.rtcEngine.setDefaultSubscribeAllRemoteAudioStreams(true);
      this.rtcEngine.subscribeAllRemoteAudioStreams(true);

      // 开启音量指示器
      this.rtcEngine.enableAudioVolumeIndication(1000, 3, 1);

      console.info('RTC引擎初始化完成');
    } catch (error) {
      console.error('RTC引擎初始化失败:', error);
      prompt.showToast({ message: `引擎初始化失败: ${error}`, duration: 3000 });
    }
  }

  // 加入频道
  private async joinChannel(): Promise<void> {
    if (!this.rtcEngine || !this.ChannelId.trim()) {
      prompt.showToast({ message: '频道ID不能为空', duration: 2000 });
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
        this.ChannelId,
        userId,
        timestamp,
        nonce
      );
      console.info('音频通话 Token:', base64Token.substring(0, 20) + '...');

      // 加入频道
      const result = this.rtcEngine.joinChannelWithToken(base64Token, '', '', '音频基础功能用户');
      console.info('加入频道调用结果:', result);

      this.hasJoined = true;
      this.localUserId = userId;
      this.InSilentMicrophone = false;
      this.OnSilentMicrophone = false;
      this.isMute = false;
      this.isMicrophoneClosed = false;

    } catch (error) {
      console.error('加入频道失败:', error);
      prompt.showToast({ message: `加入频道失败: ${error}`, duration: 3000 });
    }
  }

  // 生成Token

  // 离开频道
  private leaveChannel(): void {
    if (this.rtcEngine && this.hasJoined) {
      this.rtcEngine.leaveChannel();
      this.resetUIToDefault();
      this.hasJoined = false;
      prompt.showToast({ message: '离开频道', duration: 2000 });
    }
  }

  // 处理加入频道结果
  private handleJoinResult(resultCode: number, channel: string): void {
    let resultText = '';
    if (resultCode === 0) {
      resultText = `User ${this.localUserId} Join ${channel} Success`;

      this.audioScenarioEnabled = false;
      this.audioProfileEnabled = false;
      this.channelIdEnabled = false;
      this.stopCaptureEnabled = true;
      this.playoutVolumeEnabled = true;
    } else {
      resultText = `User ${this.localUserId} Join ${channel} Failed!，error: ${resultCode}`;
    }
    prompt.showToast({ message: resultText, duration: 2000 });
  }

  // 处理远端用户上线
  private handleRemoteUserOnline(uid: string): void {
    if (!this.remoteUsers.includes(uid) && uid !== this.localUserId) {
      this.remoteUsers.push(uid);
      this.userMuteStatusMap.set(uid, false);
    }
  }

  // 处理远端用户下线
  private handleRemoteUserOffline(uid: string): void {
    const index = this.remoteUsers.indexOf(uid);
    if (index !== -1) {
      this.remoteUsers.splice(index, 1);
      this.userMuteStatusMap.delete(uid);
    }
  }

  // 显示远端用户操作选项
  private async showRemoteUserOptions(userId: string): Promise<void> {
    if (userId === this.localUserId) {
      return;
    }

    const isMuted = this.userMuteStatusMap.get(userId) || false;
    const muteOption = isMuted ? '取消静音该用户' : '静音该用户';
    this.dialogSelectedUserId = userId;
    this.dialogMuteOption = muteOption
    await this.dialogController.open();
  }

  // 添加自定义音量设置对话框的Builder
  @Builder
  buildVolumeSliderDialog() {
    if (this.showVolumeSliderDialog) {
      Column() {
        Text(`设置播放音量`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 20 })
          .width('100%')
          .textAlign(TextAlign.Center)

        Text(`音量: ${this.volumeSliderValue}`)
          .fontSize(16)
          .margin({ bottom: 20 })

        Slider({
          value: this.volumeSliderValue,
          min: 0,
          max: 100,
          step: 1
        })
          .width('80%')
          .blockColor('#05d8c5')
          .selectedColor('#05d8c5')
          .onChange((value: number) => {
            this.volumeSliderValue = value;
          })

        Row() {
          Button('取消')
            .fontSize(16)
            .fontColor('#666666')
            .backgroundColor('#E6E6E6')
            .layoutWeight(1)
            .onClick(() => {
              this.showVolumeSliderDialog = false;
            })

          Blank()
            .width(20)

          Button('确定')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor('#007DFF')
            .layoutWeight(1)
            .onClick(() => {
              this.setRemoteUserVolume(this.selectedRemoteUserId, this.volumeSliderValue);
              this.showVolumeSliderDialog = false;
            })
        }
        .width('80%')
        .margin({ top: 30, bottom: 20 })
      }
      .width('90%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .onClick(() => {
        // 阻止点击事件冒泡
      })
    }
  }

  // 切换远端用户静音状态
  private toggleMuteRemoteUser(userId: string): void {
    if (!this.rtcEngine) {
      return;
    }

    const isMuted = this.userMuteStatusMap.get(userId) || false;
    this.rtcEngine.muteRemoteAudioPlaying(userId, !isMuted);
    this.userMuteStatusMap.set(userId, !isMuted);
  }

  // 设置远端用户音量
  private setRemoteUserVolume(userId: string, volume: number): void {
    if (this.rtcEngine) {
      this.rtcEngine.setRemoteAudioVolume(userId, volume);
      prompt.showToast({ message: `已设置用户 ${userId} 的音量为 ${volume}`, duration: 1000 });
    }
  }

  // 销毁RTC引擎
  private destroyRtcEngine(): void {
    if (this.rtcEngine) {
      try {
        if (this.hasJoined) {
          this.rtcEngine.leaveChannel();
          this.hasJoined = false;
        }
        this.rtcEngine = undefined;
        this.rtcEngineEventListener = undefined;
      } catch (error) {
        console.error('销毁引擎失败:', error);
      }
    }
    this.resetUIToDefault();
  }

  // 重置UI到默认状态
  private resetUIToDefault(): void {
    this.InSilentMicrophone = false;
    this.OnSilentMicrophone = false;
    this.isMute = false;
    this.isMicrophoneClosed = false;
    this.earBackEnabled = false;
    this.earBackVolume = 100;
    this.playoutVolume = 20;
    this.muteAllRemoteUsers = false;
    this.remoteUsers = [];
    this.localUserId = '';
    this.userMuteStatusMap.clear();

    // 重置UI控件状态
    this.audioScenarioEnabled = true;
    this.audioProfileEnabled = true;
    this.channelIdEnabled = true;
    this.stopCaptureEnabled = false;
    this.playoutVolumeEnabled = false;
  }

  // ==================== 事件处理函数 ====================

  private onJoinChannelClick(): void {
    if (this.hasJoined) {
      this.destroyRtcEngine();
    } else {
      this.startRTCCall();
    }
  }

  private async startRTCCall(): Promise<void> {
    if (this.hasJoined) {
      return;
    }

    await this.initAndSetupRtcEngine();
    await this.joinChannel();
  }

  private onMuteMicClick(): void {
    if (!this.rtcEngine) {
      return;
    }

    this.isMute = !this.isMute;
    this.InSilentMicrophone = this.isMute;
    this.rtcEngine.muteLocalMic(this.isMute, AliRtcMuteLocalAudioMode.AliRtcMuteLocalAudioModeMuteAll);
  }

  private onStopCaptureClick(): void {
    if (!this.rtcEngine) {
      return;
    }

    this.isMicrophoneClosed = !this.isMicrophoneClosed;
    this.OnSilentMicrophone = this.isMicrophoneClosed;

    if (this.isMicrophoneClosed) {
      this.rtcEngine.stopAudioCapture();
    } else {
      this.rtcEngine.startAudioCapture();
    }
  }

  private onAudioRouteChange(value: string): void {
    if (!this.rtcEngine || !this.hasJoined) {
      return;
    }

    this.audioRoute = value;
    const isSpeaker = value === '扬声器';
    this.rtcEngine.enableSpeakerphone(isSpeaker);
  }

  private onEarBackChange(value: boolean): void {
    if (!this.rtcEngine) {
      return;
    }

    this.earBackEnabled = value;
    this.rtcEngine.enableEarBack(value);
  }

  private onEarBackVolumeChange(value: number): void {
    if (!this.rtcEngine) {
      return;
    }

    this.earBackVolume = value;
    this.rtcEngine.setEarBackVolume(value);
  }

  private onPlayoutVolumeChange(value: number): void {
    if (!this.rtcEngine) {
      return;
    }

    this.playoutVolume = value;
    try {
      this.rtcEngine.setPlayOutVolume(value);
    } catch (error) {
      console.error('设置播放音量失败:', error);
      try {
        this.rtcEngine.setPlayOutVolume(value);
      } catch (e) {
        console.error('setPlayOutVolume also failed:', e);
      }
    }
  }

  private onMuteAllRemoteUsersChange(value: boolean): void {
    if (!this.rtcEngine) {
      return;
    }

    this.muteAllRemoteUsers = value;
    this.rtcEngine.muteAllRemoteAudioPlaying(value);
  }

  // ==================== 辅助函数 ====================

  private getAudioProfile(): AliRtcAudioProfile {
    switch (this.audioProfile) {
      case 'LowQualityMode':
        return AliRtcAudioProfile.AliRtcLowQualityMode;
      case 'BasicQualityMode':
        return AliRtcAudioProfile.AliRtcBasicQualityMode;
      case 'HighQualityMode':
        return AliRtcAudioProfile.AliRtcHighQualityMode;
      case 'StereoHighQualityMode':
        return AliRtcAudioProfile.AliRtcStereoHighQualityMode;
      case 'SuperHighQualityMode':
        return AliRtcAudioProfile.AliRtcSuperHighQualityMode;
      case 'StereoSuperHighQualityMode':
        return AliRtcAudioProfile.AliRtcStereoSuperHighQualityMode;
      default:
        return AliRtcAudioProfile.AliRtcHighQualityMode;
    }
  }

  private getAudioScenario(): AliRtcAudioScenario {
    switch (this.audioScenario) {
      case 'DEFAULT':
        return AliRtcAudioScenario.AliRtcSceneDefaultMode;
      case 'MUSIC':
        return AliRtcAudioScenario.AliRtcSceneMusicMode;
      default:
        return AliRtcAudioScenario.AliRtcSceneMusicMode;
    }
  }
}