import {
  AliRtcEngine,
  AliRtcVideoCanvas,
  AliRtcVideoTrack,
  AliRtcXComponentController,
  AliRtcVideoEncoderConfiguration,
  AliRtcEngineAuthInfo,
  AliRtcEngineEventListener,
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
  AliRtcStats,
  AliRtcLocalAudioStats,
  AliRtcRemoteAudioStats,
  AliRtcLocalVideoStats,
  AliRtcRemoteVideoStats,
  AliRtcCapturePipelineScaleMode
} from "@aliyun_video_cloud/alivcsdk_artc";
import { CustomTitle } from "../../common/components/CustomTitle"
import { common } from "@kit.AbilityKit";
import { prompt, promptAction } from "@kit.ArkUI";
import { RemoteVideoStream } from "../../common/Constants"
import { ARTCTokenHelper } from '../../common/keycenter/ARTCTokenHelper';
import { GlobalConfig } from '../../common/keycenter/GlobalConfig';


// 统计信息接口
interface StatsDisplay {
  mRtcStats?: AliRtcStats;
  mLocalAudioStats?: AliRtcLocalAudioStats;
  mRemoteAudioStats?: AliRtcRemoteAudioStats;
  mLocalVideoStats?: AliRtcLocalVideoStats;
  mRemoteVideoStats?: AliRtcRemoteVideoStats;
}

@Entry
@Component
export struct StreamMonitoringPage {
  @State initRoom: boolean = false
  @State channelId: string = Date.now().toString().slice(-6);
  @State ShowPreview: boolean = false;
  @State remoteVideoStreams: RemoteVideoStream[] = []
  @State gridColumns: number = 2 // 网格列数，根据视频数量动态调整
  @State statsDisplay: string = '等待统计信息...'
  private rtcEngine: AliRtcEngine | undefined;
  private context: common.Context | undefined;
  private xcomponentController: XComponentController = new XComponentController();
  private aliRtcVideoCanvas: AliRtcVideoCanvas | undefined;
  private componentController: AliRtcXComponentController = new AliRtcXComponentController()
  private statsData: StatsDisplay = {};
  private updateTimer: number | undefined;
  private rtcEventListener?: AliRtcEngineEventListener;

  async aboutToAppear(): Promise<void> {
    this.context = getContext() as common.Context;
    // 初始化显示
    this.updateStatsDisplay();
  }

  aboutToDisappear(): void {
    this.leaveChannelAndCleanup();
    if (this.updateTimer) {
      clearTimeout(this.updateTimer);
    }
  }

  build() {
    NavDestination() {
      Column() {
        CustomTitle({
          titleText: '通话质量检测',
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

          if (this.ShowPreview) {
            Column() {
              this.buildLocalVideoView()
            }
            .width('100%')
            .height('auto')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          }

          // 添加统计信息显示区域
          Scroll() {
            Text(this.statsDisplay)
              .fontSize(12)
              .fontColor('#333')
              .fontFamily('monospace')
              .width('100%')
              .padding(10)
              .backgroundColor('#00fdfdfb')
              .border({
                width: 1,
                color: '#ddd',
                radius: 4
              })
          }
          .height('220vp')
          .margin({ top: 20, left: 10, right: 10 })
          .padding({ bottom: 10 })
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
                this.setupLocalVideo();
              })
          }
          .backgroundColor('#000')
          .layoutWeight(1)
          .height('200vp')

          Blank().layoutWeight(1)
        }.width('100%')

      } else {
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
                this.setupLocalVideo();
              })
          }
          .backgroundColor('#000')
          .width('150')
          .layoutWeight(1)
          .height('200vp')

          Blank()
            .width(10)

          Column() {
            // 视频渲染区域
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
    .height('200vp')
    .margin({
      top: 20
    })
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
  }

  // 处理加入/离开房间
  private async handleJoinRoom(): Promise<void> {
    if (this.initRoom) {
      this.leaveChannelAndCleanup();
      this.initRoom = false;
      prompt.showToast({ message: 'Leave Channel', duration: 2000 });
      return;
    }

    try {
      // 验证必要参数
      if (!this.channelId.trim()) {
        prompt.showToast({ message: '请输入频道ID', duration: 2000 });
        return;
      }

      // 初始化RTC引擎
      await this.initAndSetupRtcEngine();

      // 开始本地预览
      this.startPreview();

      // 加入频道
      await this.joinChannel();

      this.initRoom = true;
      console.info('成功加入房间');

      // 开始定时更新统计信息
      this.startStatsUpdateTimer();

    } catch (error) {
      console.error('加入房间失败:', error);
      prompt.showToast({
        message: `加入房间失败: ${error}`,
        duration: 3000
      });
      this.initRoom = false;
    }
  }



  // 设置本地视频
  private setupLocalVideo(): void {
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
      this.startPreview();

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
        AliRtcVideoTrack.AliRtcVideoTrackCamera);

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
      surfaceId: ''
    };

    // 添加到数组
    this.remoteVideoStreams.push(newStream);

    // 动态调整网格列数
    this.updateGridColumns();

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

      // 动态调整网格列数
      this.updateGridColumns();

      console.info(`移除远端视频成功: ${uid} - ${videoTrack}`);
    }
  }

  // 移除用户的所有视频
  private removeAllRemoteVideo(uid: string): void {
    console.info(`移除用户所有视频: ${uid}`);

    // 从数组中移除该用户的所有流
    this.remoteVideoStreams = this.remoteVideoStreams.filter(s => s.uid !== uid);

    // 动态调整网格列数
    this.updateGridColumns();

    console.info(`移除用户所有视频成功: ${uid}`);
  }

  // 更新网格列数
  private updateGridColumns(): void {
    const count = this.remoteVideoStreams.length + (this.ShowPreview ? 1 : 0);
    if (count <= 2) {
      this.gridColumns = 2;
    } else if (count <= 4) {
      this.gridColumns = 3;
    } else {
      this.gridColumns = 4;
    }
    console.info(`更新网格列数: ${this.gridColumns}, 视频总数: ${count}`);
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
      // 设置频道模式
      this.rtcEngine.setChannelProfile(AliRtcChannelProfile.AliRtcInteractiveLive);

      // 设置用户角色
      this.rtcEngine.setClientRole(AliRtcClientRole.AliRtcClientRoleInteractive);

      // 设置音频配置
      this.rtcEngine.setAudioProfile(
        AliRtcAudioProfile.AliRtcHighQualityMode,
        AliRtcAudioScenario.AliRtcSceneMusicMode
      );

      // 设置采集管线缩放模式
      this.rtcEngine.setCapturePipelineScaleMode(AliRtcCapturePipelineScaleMode.AliRtcCapturePipelineScaleModePost);

      const videoConfig: AliRtcVideoEncoderConfiguration = new AliRtcVideoEncoderConfiguration();
      videoConfig.dimensions.width = 720;
      videoConfig.dimensions.height = 1280;
      videoConfig.frameRate = 20;
      videoConfig.bitrate = 1200;
      videoConfig.keyFrameInterval = 2000;
      videoConfig.orientationMode = AliRtcVideoEncoderOrientationMode.AliRtcVideoEncoderOrientationModeAdaptive;
      videoConfig.min_bitrate = 0;
      videoConfig.forceStrictKeyFrameInterval = 0;
      videoConfig.mirrorMode = AliRtcVideoMirrorMode.AliRtcVideoMirrorModeDisabled;
      videoConfig.rotationMode = AliRtcRotationMode.AliRtcRotationMode_0;
      this.rtcEngine.setVideoEncoderConfiguration(videoConfig);

      // 发布本地音视频流
      this.rtcEngine.publishLocalAudioStream(true);
      this.rtcEngine.publishLocalVideoStream(true);

      // 设置默认订阅所有远端音视频流
      this.rtcEngine.setDefaultSubscribeAllRemoteAudioStreams(true);
      this.rtcEngine.setDefaultSubscribeAllRemoteVideoStreams(true);

      // 明确订阅所有远端音视频流
      this.rtcEngine.subscribeAllRemoteAudioStreams(true);
      this.rtcEngine.subscribeAllRemoteVideoStreams(true);

      // 设置事件监听器
      this.setupEventListeners();

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
          : `Join ${channel} Failed!，error: ${resultCode}`;

        prompt.showToast({
          message: resultText,
          duration: 2000
        });

      })

      this.rtcEventListener.onLeaveChannel((resultCode: number) => {
        console.info(`离开频道结果: result=${resultCode}`);
        prompt.showToast({ message: 'Leave Channel', duration: 2000 });
      })

      this.rtcEventListener.onConnectionStatusChange((status: number, reason: number) => {
        console.info(`连接状态变更: status=${status}, reason=${reason}`);
        if (status === 5) {
          prompt.showToast({
            message: '连接失败，请检查网络',
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
          this.removeRemoteVideo(userId, AliRtcVideoTrack.AliRtcVideoTrackCamera);
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
        this.leaveChannelAndCleanup();
      });


      this.rtcEventListener.onStats((stats: AliRtcStats) => {
        console.info('onAliRtcStats 回调');
        this.statsData.mRtcStats = stats;
      });

      this.rtcEventListener.onLocalAudioStats((stats: AliRtcLocalAudioStats) => {
        console.info('onRtcLocalAudioStats 回调');
        this.statsData.mLocalAudioStats = stats;
      });

      this.rtcEventListener.onRemoteAudioStats((stats: AliRtcRemoteAudioStats) => {
        console.info('onRtcRemoteAudioStats 回调');
        this.statsData.mRemoteAudioStats = stats;
      });

      this.rtcEventListener.onLocalVideoStats((stats: AliRtcLocalVideoStats) => {
        console.info('onRtcLocalVideoStats 回调');
        this.statsData.mLocalVideoStats = stats;
      });

      this.rtcEventListener.onRemoteVideoStats((stats: AliRtcRemoteVideoStats) => {
        console.info('onRtcRemoteVideoStats 回调');
        this.statsData.mRemoteVideoStats = stats;
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

      const result = this.rtcEngine.joinChannelWithToken(base64Token, '', '', '通话质量监测用户');
      console.info('加入频道调用结果:', result);

    } catch (error) {
      console.error('加入频道失败:', error);
    }
  }

  // 离开频道并清理资源
  private leaveChannelAndCleanup(): void {
    if (this.rtcEngine) {
      try {
        if (this.initRoom) {
          this.rtcEngine.stopPreview();
          this.rtcEngine.leaveChannel();
        }
        this.rtcEngine = undefined;
      } catch (error) {
        console.error('销毁RTC引擎失败:', error);
      }
    }

    // 清理所有远端视频资源
    this.remoteVideoStreams = [];
    this.aliRtcVideoCanvas = undefined;
  }



  // 判断是否显示网格布局
  private shouldShowGridLayout(): boolean {
    return this.ShowPreview && this.remoteVideoStreams.length > 0;
  }

  // 开始统计信息更新定时器
  private startStatsUpdateTimer(): void {
    const update = () => {
      this.updateStatsDisplay();
      this.updateTimer = setTimeout(update, 1000); // 每2秒更新一次
    };

    update();
  }

  // 更新统计信息显示
  private updateStatsDisplay(): void {
    const currentTime = new Date().toLocaleTimeString('zh-CN', {
      hour12: false,
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit'
    });
    let statsText = `=== Update Time: ${currentTime} ===\n\n`;

    // 1. AliRtcStats
    statsText += '【1. (AliRtcStats)】\n';
    if (this.statsData.mRtcStats) {
      statsText += this.getObjectFieldsAsString(this.statsData.mRtcStats);
    } else {
      statsText += '暂无数据\n';
    }
    statsText += '\n';

    // 2. 本地音频统计
    statsText += '【2. (AliRtcLocalAudioStats)】\n';
    if (this.statsData.mLocalAudioStats) {
      statsText += this.getObjectAudioStatsString(this.statsData.mLocalAudioStats);
    } else {
      statsText += '暂无数据\n';
    }
    statsText += '\n';

    // 3. 远端音频统计
    statsText += '【3. (AliRtcRemoteAudioStats)】\n';
    if (this.statsData.mRemoteAudioStats) {
      statsText += this.getObjectRemoteAudioString(this.statsData.mRemoteAudioStats);
    } else {
      statsText += '暂无数据\n';
    }
    statsText += '\n';

    // 4. 本地视频统计
    statsText += '【4. (AliRtcLocalVideoStats)】\n';
    if (this.statsData.mLocalVideoStats) {
      statsText += this.getObjectVideoStatsString(this.statsData.mLocalVideoStats);
    } else {
      statsText += '暂无数据\n';
    }
    statsText += '\n';

    // 5. 远端视频统计
    statsText += '【5. (AliRtcRemoteVideoStats)】\n';
    if (this.statsData.mRemoteVideoStats) {
      statsText += this.getObjectRemoteVideoStatsString(this.statsData.mRemoteVideoStats);
    } else {
      statsText += '暂无数据\n';
    }

    statsText += '\n' + '='.repeat(44) + '\n';

    this.statsDisplay = statsText;
  }

  // 获取对象字段的字符串表示
  private getObjectFieldsAsString(stats: AliRtcStats): string {
    if (!stats) {
      return 'null\n';
    }

    let result = '';
    result += `  availableSendBitrate: ${stats.availableSendBitrate ?? 'N/A'}\n`;
    result += `  callDuration: ${stats.callDuration ?? 'N/A'}\n`;
    result += `  appCpu: ${stats.appCpu ?? 'N/A'}\n`;
    result += `  lastmileDelay: ${stats.lastmileDelay ?? 'N/A'}\n`;
    result += `  rcvdBytes: ${stats.rcvdBytes ?? 'N/A'}\n`;
    result += `  rcvdExpectedPkts: ${stats.rcvdExpectedPkts ?? 'N/A'}\n`;
    result += `  rcvdKBitrate: ${stats.rcvdKBitrate ?? 'N/A'}\n`;
    result += `  rcvdLossPkts: ${stats.rcvdLossPkts ?? 'N/A'}\n`;
    result += `  rcvdLossRate: ${stats.rcvdLossRate ?? 'N/A'}\n`;
    result += `  systemCpu: ${stats.systemCpu ?? 'N/A'}\n`;
    result += `  videoRcvdKBitrate: ${stats.videoRcvdKBitrate ?? 'N/A'}\n`;
    result += `  videoSentKBitrate: ${stats.videoSentKBitrate ?? 'N/A'}\n`;

    return result;
  }

  // 获取对象字段的字符串表示
  private getObjectAudioStatsString(stats: AliRtcLocalAudioStats): string {
    if (!stats) {
      return 'null\n';
    }

    let result = '';
    result += `  numChannel: ${stats.numChannel ?? 'N/A'}\n`;
    result += `  sentBitrate: ${stats.sentBitrate ?? 'N/A'}\n`;
    result += `  sentSamplerate: ${stats.sentSamplerate ?? 'N/A'}\n`;
    result += `  rcvdBytes: ${"AliRtcRemoteAudioStats" ?? 'N/A'}\n`;


    return result;
  }

  private getObjectRemoteAudioString(stats: AliRtcRemoteAudioStats): string {
    if (!stats) {
      return 'null\n';
    }

    let result = '';
    result += `  audioLossRate: ${stats.audioLossRate ?? 'N/A'}\n`;
    result += `  audioTotalFrozenRate: ${stats.audioTotalFrozenRate ?? 'N/A'}\n`;
    result += `  audioTotalFrozenTime: ${stats.audioTotalFrozenTime ?? 'N/A'}\n`;
    result += `  audioTrack: ${"AliRtcAudioTrackMic" ?? 'N/A'}\n`;
    result += `  jitterBufferDelay: ${stats.jitterBufferDelay ?? 'N/A'}\n`;
    result += `  network_transport_delay: ${stats.networkTransportDelay ?? 'N/A'}\n`;
    result += `  quality: ${stats.quality ?? 'N/A'}\n`;
    result += `  rcvdBitrate: ${stats.rcvdBitrate ?? 'N/A'}\n`;
    result += `  totalFrozenTimes: ${stats.totalFrozenTimes ?? 'N/A'}\n`;
    result += `  userId: ${stats.userId ?? 'N/A'}\n`;

    return result;
  }

  private getObjectVideoStatsString(stats: AliRtcLocalVideoStats): string {
    if (!stats) {
      return 'null\n';
    }

    let result = '';
    result += `  actualEncodeBitrate: ${stats.actualEncodeBitrate ?? 'N/A'}\n`;
    result += `  avgQpPerSec: ${stats.avgQpPerSec ?? 'N/A'}\n`;
    result += `  captureFps: ${stats.captureFps ?? 'N/A'}\n`;
    result += `  encodeFps: ${stats.encodeFps ?? 'N/A'}\n`;
    result += `  sentBitrate: ${stats.sentBitrate ?? 'N/A'}\n`;
    result += `  sentFps: ${stats.sentFps ?? 'N/A'}\n`;
    result += `  targetEncodeBitrate: ${stats.targetEncodeBitrate ?? 'N/A'}\n`;
    result += `  track: ${"AliRtcVideoTrackCamera" ?? 'N/A'}\n`;
    result += `  userId: ${'' ?? 'N/A'}\n`;

    return result;
  }

  private getObjectRemoteVideoStatsString(stats: AliRtcRemoteVideoStats): string {
    if (!stats) {
      return 'null\n';
    }

    let result = '';
    result += `  decodeFps: ${stats.decodeFps ?? 'N/A'}\n`;
    result += `  frozenTimes: ${stats.frozenTimes ?? 'N/A'}\n`;
    result += `  height: ${stats.height ?? 'N/A'}\n`;
    result += `  renderFps: ${stats.renderFps ?? 'N/A'}\n`;
    result += `  rtpCount: ${stats.rtpCount ?? 'N/A'}\n`;
    result += `  rtpLoss: ${stats.rtpLoss ?? 'N/A'}\n`;
    result += `  userId: ${stats.userId ?? 'N/A'}\n`;
    result += `  videoTotalFrozenRate: ${stats.videoTotalFrozenRate ?? 'N/A'}\n`;
    result += `  videoTotalFrozenTime: ${stats.videoTotalFrozenTime ?? 'N/A'}\n`;
    result += `  width: ${stats.width ?? 'N/A'}\n`;

    return result;
  }
}