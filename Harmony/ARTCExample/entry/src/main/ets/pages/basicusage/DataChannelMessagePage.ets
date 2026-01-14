import {
  AliRtcEngine,
  AliRtcVideoCanvas,
  AliRtcXComponentController,
  AliRtcChannelProfile,
  AliRtcClientRole,
  AliRtcAudioProfile,
  AliRtcAudioScenario,
  AliRtcVideoEncoderOrientationMode,
  AliRtcVideoEncoderConfiguration,
  AliRtcEngineEventListener,
  AliRtcVideoTrack,
  AliRtcAudioTrack,
  AliRtcUserOfflineReason,
  AliRtcRenderMode,
  AliRtcRenderMirrorMode,
  AliRtcEngineAuthInfo,
  AliRtcDataChannelMsg,
  AliRtcDataMsgType
} from "@aliyun_video_cloud/alivcsdk_artc";
import { common } from "@kit.AbilityKit";
import { CustomTitle } from "../../common/components/CustomTitle";
import { prompt, promptAction } from "@kit.ArkUI";
import { RemoteVideoStream } from "../../common/Constants"
import { ARTCTokenHelper } from '../../common/keycenter/ARTCTokenHelper';
import { GlobalConfig } from '../../common/keycenter/GlobalConfig';

@Entry
@Component
export struct DataChannelMessagePage {
  @State initRoom: boolean = false;
  @State SendText: string = '';
  @State channelId: string = Date.now().toString().slice(-6);
  @State ShowPreview: boolean = false;
  @State receivedMessage: string = ''; // 接收到的消息
  // 远端视频流管理
  @State remoteVideoStreams: RemoteVideoStream[] = [];
  @State gridColumns: number = 2;
  private rtcEngine: AliRtcEngine | undefined;
  private context: common.Context | undefined;
  private xcomponentController: XComponentController = new XComponentController();
  private aliRtcVideoCanvas: AliRtcVideoCanvas | undefined;
  private componentController: AliRtcXComponentController = new AliRtcXComponentController();
  private rtcEventListener?: AliRtcEngineEventListener;

  async aboutToAppear(): Promise<void> {
    this.context = getContext() as common.Context;
  }

  aboutToDisappear(): void {
    this.leaveChannelAndCleanup();
  }

  // 处理加入/离开房间
  private async handleJoinRoom(): Promise<void> {
    if (this.initRoom) {
      this.leaveChannelAndCleanup();
      this.initRoom = false;
      this.ShowPreview = false;
      prompt.showToast({ message: 'Leave Channel', duration: 2000 });
    } else {
      try {
        // 验证必要参数
        if (!this.channelId.trim()) {
          prompt.showToast({ message: '请输入频道ID', duration: 2000 });
          return;
        }

        // 初始化RTC引擎
        await this.initAndSetupRtcEngine();

        // 开始本地预览
        await this.startPreview();

        // 加入频道
        await this.joinChannel();

        // 开启自定义消息通道
        this.enableCustomMsgChannel();

        this.initRoom = true;
        this.ShowPreview = true;
        console.info('成功加入房间');

      } catch (error) {
        console.error('加入房间失败:', error);
        prompt.showToast({
          message: `加入房间失败: ${error}`,
          duration: 3000
        });
        this.initRoom = false;
        this.ShowPreview = false;
      }
    }
  }

  // 初始化并设置RTC引擎
  private async initAndSetupRtcEngine(): Promise<boolean> {
    if (this.rtcEngine) {
      return true;
    }

    if (!this.context) {
      throw new Error('Context未初始化');
    }

    try {
      // 创建RTC引擎实例
      this.rtcEngine = AliRtcEngine.getInstance('', this.context);
      if (this.rtcEngine === undefined) {
        promptAction.showToast({ message: 'RTC引擎未初始化成功', duration: 2000 });
        return false;
      }
      // 设置事件监听器
      this.setupEventListeners();

      // 设置频道模式为互动模式
      this.rtcEngine.setChannelProfile(AliRtcChannelProfile.AliRtcInteractiveLive);

      // 设置用户角色
      this.rtcEngine.setClientRole(AliRtcClientRole.AliRtcClientRoleInteractive);

      // 设置音频配置
      this.rtcEngine.setAudioProfile(
        AliRtcAudioProfile.AliRtcHighQualityMode,
        AliRtcAudioScenario.AliRtcSceneMusicMode
      );

      // 设置视频编码参数
      const videoEncoderConfig = new AliRtcVideoEncoderConfiguration();
      videoEncoderConfig.dimensions.width = 720;
      videoEncoderConfig.dimensions.height = 1280;
      videoEncoderConfig.frameRate = 20;
      videoEncoderConfig.bitrate = 1200;
      videoEncoderConfig.keyFrameInterval = 2000;
      videoEncoderConfig.orientationMode = AliRtcVideoEncoderOrientationMode.AliRtcVideoEncoderOrientationModeAdaptive;
      this.rtcEngine.setVideoEncoderConfiguration(videoEncoderConfig);

      // 发布本地音视频流
      this.rtcEngine.publishLocalAudioStream(true);
      this.rtcEngine.publishLocalVideoStream(true);

      // 设置默认订阅远端的音频和视频流
      this.rtcEngine.setDefaultSubscribeAllRemoteAudioStreams(true);
      this.rtcEngine.subscribeAllRemoteAudioStreams(true);
      this.rtcEngine.setDefaultSubscribeAllRemoteVideoStreams(true);
      this.rtcEngine.subscribeAllRemoteVideoStreams(true);

      console.info('RTC引擎初始化完成');
      return true;
    } catch (error) {
      console.error('RTC引擎初始化失败:', error);
      return false;
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
      });

      this.rtcEventListener.onLeaveChannel((resultCode: number) => {
        console.info(`离开频道结果: result=${resultCode}`);
        prompt.showToast({
          message: 'Leave Channel',
          duration: 2000
        });
      });

      this.rtcEventListener.onRemoteUserOnline((userId: string, elapsed: boolean) => {
        console.info(`远端用户上线: userId=${userId}, elapsed=${elapsed}`);
      });

      this.rtcEventListener.onRemoteUserOffline((userId: string, reason: AliRtcUserOfflineReason) => {
        console.info(`远端用户下线: userId=${userId}, reason=${reason}`);
        this.removeAllRemoteVideo(userId);
      });

      this.rtcEventListener.onRemoteTrackAvailableNotify((userId: string, audioTrack: AliRtcAudioTrack,
        videoTrack: AliRtcVideoTrack) => {
        console.info(`远端音视频流可用: userId=${userId}, videoTrack=${videoTrack}`);

        if (videoTrack === AliRtcVideoTrack.AliRtcVideoTrackCamera) {
          this.viewRemoteVideo(userId, AliRtcVideoTrack.AliRtcVideoTrackCamera);
        } else if (videoTrack === AliRtcVideoTrack.AliRtcVideoTrackNo) {
          this.removeAllRemoteVideo(userId);
        }
      });

      this.rtcEventListener.onDataChannelMessage((uid: string, msg: AliRtcDataChannelMsg) => {
        console.info(`收到数据通道消息: uid=${uid}, type=${msg.type}`);

        try {
          const receivedMsg = this.uint8ArrayToString(new Uint8Array(msg.data));

          let currentText = this.receivedMessage;
          if (currentText) {
            currentText += '\n';
          }
          currentText += `User ${uid}: ${receivedMsg}`;
          this.receivedMessage = currentText;


          console.info(`收到数据通道消息内容: ${receivedMsg}`);
        } catch (error) {
          console.error('解析数据通道消息失败:', error);
        }
      });

      this.rtcEventListener.onLocalDeviceException((deviceType: number, exceptionType: number, msg: string) => {
        console.error(`本地设备异常: ${msg}`);
        promptAction.showToast({
          message: `设备异常: ${msg}`,
          duration: 3000
        });
      });

      this.rtcEventListener.onBye((code: number) => {
        console.info(`被服务器踢出: code=${code}`);
        promptAction.showToast({
          message: `被服务器踢出: ${code}`,
          duration: 3000
        });
        this.leaveChannelAndCleanup();
      });
    }

    this.rtcEngine.setRtcEngineEventListener(this.rtcEventListener);
  }

  // 开始预览
  private async startPreview(): Promise<boolean> {
    if (!this.rtcEngine) {
      return false;
    }

    try {
      // 获取surfaceId
      const surfaceId = this.xcomponentController.getXComponentSurfaceId();
      if (!surfaceId) {
        console.error('surfaceId获取为空');
        return false;
      }

      // 创建视频画布
      this.aliRtcVideoCanvas = new AliRtcVideoCanvas();
      this.aliRtcVideoCanvas.surfaceId = surfaceId;
      this.aliRtcVideoCanvas.renderMode = AliRtcRenderMode.AliRtcRenderModeAuto;
      this.aliRtcVideoCanvas.mirrorMode = AliRtcRenderMirrorMode.AliRtcRenderMirrorModeAllMirror;

      // 设置本地视频配置
      this.rtcEngine.setLocalViewConfig(
        this.aliRtcVideoCanvas,
        this.componentController,
        AliRtcVideoTrack.AliRtcVideoTrackCamera
      );

      // 开始预览
      this.rtcEngine.startPreview();

      console.info('本地预览已启动');
      return true;
    } catch (error) {
      console.error('启动预览失败:', error);
      return false;
    }
  }

  // 加入频道
  private async joinChannel(): Promise<void> {
    if (!this.rtcEngine || !this.channelId.trim()) {
      throw new Error('RTC引擎未初始化或频道ID为空');
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

      const result = this.rtcEngine.joinChannelWithToken(base64Token, '', '', '数据通道用户');
      console.info('加入频道调用结果:', result);
    } catch (error) {
      console.error('加入频道失败:', error);
    }
  }

  // 将Uint8Array转换为字符串
  private uint8ArrayToString(uint8Array: Uint8Array): string {
    let result = '';
    for (let i = 0; i < uint8Array.length; i++) {
      result += String.fromCharCode(uint8Array[i]);
    }
    return result;
  }

  // 开启自定义消息通道
  private enableCustomMsgChannel(): void {
    if (!this.rtcEngine) {
      return;
    }

    try {
      // 调用setParameter接口设置自定义消息通道，包括pub和sub
      const param = '{"data":{"enablePubDataChannel":true,"enableSubDataChannel":true}}';
      this.rtcEngine.setParameter(param);

      console.info(`设置参数: ${param}`);
    } catch (error) {
      console.error('开启自定义消息通道失败:', error);
    }
  }


  // 发送数据通道消息
  private sendDataChannelMessage(): void {
    if (!this.rtcEngine) {
      promptAction.showToast({
        message: 'RTC引擎未初始化',
        duration: 2000
      });
      return;
    }

    if (!this.SendText.trim()) {
      promptAction.showToast({
        message: '请输入要发送的消息',
        duration: 2000
      });
      return;
    }

    try {
      // 创建数据通道消息对象
      const msg = new AliRtcDataChannelMsg();
      msg.type = AliRtcDataMsgType.AliRtcDataChannelCustom;

      const seiData = this.stringToArrayBuffer(this.SendText);
      msg.data = seiData;

      // 发送消息
      const res = this.rtcEngine.sendDataChannelMsg(msg);

      console.info(`发送数据通道消息: ${this.SendText}, 结果: ${res}`);
    } catch (error) {
      console.error('发送数据通道消息失败:', error);
      promptAction.showToast({
        message: '发送消息失败',
        duration: 2000
      });
    }
  }

  // 将字符串转换为Uint8Array
  private stringToArrayBuffer(str: string): ArrayBuffer {
    try {
      // 方法1：使用传统的字符编码方式
      const arrayBuffer = new ArrayBuffer(str.length);
      const uint8Array = new Uint8Array(arrayBuffer);

      for (let i = 0; i < str.length; i++) {
        uint8Array[i] = str.charCodeAt(i);
      }

      return arrayBuffer;
    } catch (error) {
      console.error('字符串转ArrayBuffer失败:', error);

      try {
        // 创建一个简单的转换
        const len = str.length;
        const bytes = new ArrayBuffer(len);
        const view = new DataView(bytes);

        for (let i = 0; i < len; i++) {
          view.setUint8(i, str.charCodeAt(i));
        }
        return bytes;
      } catch (innerError) {
        console.error('备用转换方法也失败:', innerError);
        return new ArrayBuffer(0);
      }
    }
  }

  // 查看远端视频
  private viewRemoteVideo(uid: string, videoTrack: AliRtcVideoTrack): void {
    console.info(`查看远端视频: uid=${uid}, videoTrack=${videoTrack}`);

    // 检查是否已存在相同的流
    const existingIndex = this.remoteVideoStreams.findIndex(
      s => s.uid === uid && s.videoTrack === videoTrack
    );

    if (existingIndex >= 0) {
      console.info(`远端视频已存在: uid=${uid}`);
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
    console.info(`添加远端视频成功: uid=${uid}`);
  }

  // 移除用户的所有视频
  private removeAllRemoteVideo(uid: string): void {
    console.info(`移除用户所有视频: uid=${uid}`);
    this.remoteVideoStreams = this.remoteVideoStreams.filter(s => s.uid !== uid);
    console.info(`移除用户所有视频成功: uid=${uid}`);
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
      return;
    }

    try {
      const surfaceId = stream.xcomponentController.getXComponentSurfaceId();
      if (!surfaceId) {
        console.error(`远端视频surfaceId为空: ${stream.uid}`);
        return;
      }

      console.info(`设置远端视频: ${stream.uid}, surfaceId: ${surfaceId}`);

      // 创建或重用canvas
      if (!stream.canvas) {
        stream.canvas = new AliRtcVideoCanvas();
      }

      stream.canvas.surfaceId = surfaceId;
      stream.canvas.renderMode = AliRtcRenderMode.AliRtcRenderModeAuto;
      stream.canvas.mirrorMode = AliRtcRenderMirrorMode.AliRtcRenderMirrorModeAllNoMirror;

      this.rtcEngine.setRemoteViewConfig(
        stream.canvas,
        this.componentController,
        stream.uid,
        stream.videoTrack
      );

      console.info(`远端视频设置完成: ${stream.uid}`);
    } catch (error) {
      console.error(`设置远端视频失败 ${stream.uid}:`, error);
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
    this.receivedMessage = '';
  }

  // 获取当前时间戳
  private generateTimestamp(): void {
    const seconds = Math.floor(Date.now() / 1000);
    const tomorrowSeconds = seconds + 86400;
    // timestamp 不再存储为成员变量
  }

  // 构建本地视频视图
  @Builder
  buildLocalVideoView() {
    Column() {
      if (!this.remoteVideoStreams[0]) {
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
        .width(180)
        .height('200vp')
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
          .layoutWeight(1)
          .height('200vp')

          Blank()
            .width(8)
          if (this.remoteVideoStreams[0]) {
            Column() {
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
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    NavDestination() {
      Column() {
        CustomTitle({
          titleText: '自定义消息发送和接收',
        })

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
          .height(50)

          Text(this.initRoom ? '离开频道' : '加入房间')
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

          Row() {
            TextInput({
              text: this.SendText,
              placeholder: '请输入消息内容'
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
                this.SendText = text;
              })

            Text('发送')
              .fontSize(16)
              .fontColor('#fff')
              .width(80)
              .margin({
                left: 10
              })
              .height('100%')
              .textAlign(TextAlign.Center)
              .backgroundColor('#590ce4')
              .onClick(() => {
                this.sendDataChannelMessage();
              })
          }
          .margin({ top: 20 })
          .height(50)

          // 显示接收到的消息区域
          Scroll() {
            Column() {
              if (this.receivedMessage) {
                Text(this.receivedMessage)
                  .fontSize(14)
                  .fontColor('#333')
                  .padding(10)
                  .width('100%')
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }
          .height(150)
          .backgroundColor('#ccc')
          .width('95%')
          .margin({ top: 20 })


          if (this.ShowPreview) {
            Column() {
              this.buildLocalVideoView()
            }
            .width('100%')
            .height('auto')
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
}