import { common } from "@kit.AbilityKit";
import {
  AliRtcEngine,
  AliRtcEngineEventListener,
  AliRtcVideoCanvas,
  AliRtcVideoTrack,
  AliRtcXComponentController,
  AliRtcChannelProfile,
  AliRtcClientRole,
  AliRtcAudioProfile,
  AliRtcAudioScenario,
  AliRtcVideoEncoderConfiguration,
  AliRtcVideoDimensions,
  AliRtcVideoEncoderOrientationMode,
  AliRtcVideoFormat,
  AliRtcRenderMode,
  AliRtcRenderMirrorMode,
  AliRtcStats,
  AliRtcAudioTrack,
  AliRtcPublishState,
  AliRtcConnectionStatus,
  AliRtcConnectionStatusChangeReason,
  AliRtcLocalDeviceType,
  AliRtcLocalDeviceExceptionType,
  AliRtcVideoMirrorMode,
  AliRtcRotationMode,
  AliRtcCapturePipelineScaleMode,
  AliRtcUserOfflineReason,
} from "@aliyun_video_cloud/alivcsdk_artc";
import { CustomTitle } from "../../common/components/CustomTitle";
import { promptAction } from '@kit.ArkUI';
import { ARTCTokenHelper } from '../../common/keycenter/ARTCTokenHelper';
import { GlobalConfig } from '../../common/keycenter/GlobalConfig';
import prompt from "@ohos.prompt";
import { RemoteVideoStream } from "../../common/Constants"

// 自定义视频渲染类型枚举
enum VideoRenderType {
  YUV = 0,
  TEXTURE = 1
}

interface VideoRenderer {
  // drawYUV(videoSample: AliRtcVideoSample): void;
}

interface TextureRenderer {
  updateTexture(textureId: number, width: number, height: number): void;
}

@Entry
@Component
export struct CustomVideoRenderPage {
  @State channelId: string = Date.now().toString().slice(-6);
  private xcomponentController: XComponentController = new XComponentController();
  @State hasJoined: boolean = false;
  @State showPreview: boolean = false;
  @State isCustomVideoRender: boolean = true; // 自定义视频渲染开关
  @State currentRenderType: VideoRenderType = VideoRenderType.YUV; // 当前渲染类型
  // RTC引擎相关
  @State remoteVideoStreams: RemoteVideoStream[] = []
  private rtcEngine: AliRtcEngine | undefined;
  private context: common.UIAbilityContext | undefined;
  private localVideoCanvas: AliRtcVideoCanvas | undefined;
  private componentController: AliRtcXComponentController = new AliRtcXComponentController();
  @State localUserId: string = '';
  private rtcEngineEventListener: AliRtcEngineEventListener | undefined;
  // 视频渲染相关
  private isPushingVideoData: boolean = false; // 是否正在推送视频数据
  private readonly VIDEO_WIDTH: number = 720;
  private readonly VIDEO_HEIGHT: number = 1280;
  private readonly VIDEO_FPS: number = 20;
  // 自定义渲染相关
  // private remoteRenderers: Map<string, VideoRenderer> = new Map();
  // private localRenderer: VideoRenderer | null = null;
  // private localTextureRenderer: TextureRenderer | null = null;
  // private localGLSurfaceView: any = null;

  // 日志引用计数
  private logRef: number = 0;
  // 视频源类型常量
  private readonly VIDEO_SOURCE_YUV: number = 0;
  private readonly VIDEO_SOURCE_TEXTURE: number = 1;

  aboutToAppear() {
    this.context = getContext(this) as common.UIAbilityContext;
  }

  build() {
    NavDestination() {
      Column() {
        CustomTitle({
          titleText: '自定义视频渲染',
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
          .margin({ top: 10 })
          .height(50)

          Row() {
            Text("自定义视频渲染")
              .fontSize(16)
              .fontColor('#636363')
              .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.isCustomVideoRender })
              .onChange((isOn: boolean) => {
                this.isCustomVideoRender = isOn;
              })
          }
          .width('100%')
          .height(36)
          .borderRadius(4)
          .margin({ top: 8 })

          Column() {
            Row() {
              Text('Video Source')
                .fontSize(16)
                .fontColor('#333')
                .margin({
                  left: 10
                })

              Blank()
              Row() {
                Row() {
                  Radio({ value: 'YUV', group: 'videoSourceGroup' })
                    .checked(this.currentRenderType === VideoRenderType.YUV)
                    .onChange((checked: boolean) => {
                      if (checked) {
                        this.currentRenderType = VideoRenderType.YUV;
                      }
                    })
                  Text('YUV')
                }

                Row() {
                  Radio({ value: '纹理', group: 'videoSourceGroup' })
                    .checked(this.currentRenderType === VideoRenderType.TEXTURE)
                    .onChange((checked: boolean) => {
                      if (checked) {
                        this.currentRenderType = VideoRenderType.TEXTURE;
                      }
                    })
                  Text('纹理')
                }
              }
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)

          }

          Text(this.hasJoined ? '挂断' : '加入频道')
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
              if (this.hasJoined) {
                this.destroyRtcEngine();
              } else {
                if (!this.rtcEngine) {
                  await this.initAndSetupRtcEngine();
                }
                await this.startRTCCall();
              }
            })

          // 视频预览区域
          if (this.showPreview) {
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

  // 判断是否显示多人网格布局
  private shouldShowGridLayout(): boolean {
    return this.showPreview && this.remoteVideoStreams.length > 0;
  }

  @Builder
  buildLocalVideoView() {
    Column() {
      if (!this.shouldShowGridLayout()) {
        // 单视频布局
        Row() {
          XComponent({
            id: 'local_video_surface',
            type: 'surface',
            controller: this.xcomponentController
          })
            .layoutWeight(1)
            .height('100%')
            .onLoad(() => {
              this.setupLocalVideo();
            })
          Blank().layoutWeight(1)
        }
        .height('200vp')
        .width('100%')

      } else {
        // 多个视频布局
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

          // 显示第一个远端视频
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
    .width('100%')
    .height('400vp')
    .margin({
      top: 20
    })
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
  }

  // ==================== RTC引擎初始化 ====================
  private async initAndSetupRtcEngine(): Promise<void> {
    if (!this.context) {
      promptAction.showToast({ message: '上下文未初始化', duration: 2000 });
      return;
    }

    try {
      // 构建引擎额外参数
      let extras: string = '';
      if (this.isCustomVideoRender) {
        if (this.currentRenderType === VideoRenderType.YUV) {
          extras = '{"user_specified_use_external_video_render":"TRUE"}';
        } else if (this.currentRenderType === VideoRenderType.TEXTURE) {
          extras =
            '{"user_specified_use_external_video_render":"TRUE","user_specified_camera_texture_capture":"TRUE","user_specified_texture_encode":"TRUE" }';
        }
      } else {
        extras = '{"user_specified_use_external_video_render":"FALSE"}';
      }

      //TODO  api支持替换 创建RTC引擎实例
      // this.rtcEngine = AliRtcEngine.getInstance(extras, this.context);
      this.rtcEngine = AliRtcEngine.getInstance('', this.context);
      if (this.rtcEngine === undefined) {
        promptAction.showToast({ message: 'RTC引擎未初始化成功', duration: 2000 });
        return;
      }
      // 设置事件监听器
      this.setupEventListeners();

      // 注册视频观察者
      this.setupVideoObservers();

      // 设置频道模式为互动直播模式
      this.rtcEngine.setChannelProfile(AliRtcChannelProfile.AliRtcInteractiveLive);

      // 设置用户角色
      this.rtcEngine.setClientRole(AliRtcClientRole.AliRtcClientRoleInteractive);

      // 设置音频配置
      this.rtcEngine.setAudioProfile(
        AliRtcAudioProfile.AliRtcHighQualityMode,
        AliRtcAudioScenario.AliRtcSceneMusicMode
      );

      // 设置视频编码参数
      const videoConfig: AliRtcVideoEncoderConfiguration = new AliRtcVideoEncoderConfiguration();
      const dimensions: AliRtcVideoDimensions = new AliRtcVideoDimensions();
      dimensions.width = this.VIDEO_WIDTH;
      dimensions.height = this.VIDEO_HEIGHT;
      videoConfig.dimensions = dimensions;
      videoConfig.frameRate = this.VIDEO_FPS;
      videoConfig.bitrate = 1200;
      videoConfig.keyFrameInterval = 2000;
      videoConfig.orientationMode = AliRtcVideoEncoderOrientationMode.AliRtcVideoEncoderOrientationModeAdaptive;

      this.rtcEngine.setVideoEncoderConfiguration(videoConfig);

      // 发布本地音视频流
      this.rtcEngine.publishLocalAudioStream(true);
      this.rtcEngine.publishLocalVideoStream(true);

      // 设置默认订阅远端音视频流
      this.rtcEngine.setDefaultSubscribeAllRemoteAudioStreams(true);
      this.rtcEngine.subscribeAllRemoteAudioStreams(true);
      this.rtcEngine.setDefaultSubscribeAllRemoteVideoStreams(true);
      this.rtcEngine.subscribeAllRemoteVideoStreams(true);

      console.info('RTC引擎初始化完成');
    } catch (error) {
      console.error('初始化RTC引擎失败:', error);
      promptAction.showToast({ message: '初始化引擎失败', duration: 2000 });
    }
  }

  // ==================== 设置视频观察者 ====================
  private setupVideoObservers(): void {
    // if (!this.rtcEngine) {
    //   return;
    // }
    //
    // // 注册buffer格式数据回调
    // this.videoSampleObserver = new AliRtcVideoObserver();
    //
    // // 设置期望的数据输出格式
    // this.videoSampleObserver.onGetVideoFormatPreference = (): AliRtcVideoFormat => {
    //   return AliRtcVideoFormat.AliRtcVideoFormatI420;
    // };
    //
    // // 本地视频数据回调
    // this.videoSampleObserver.onLocalVideoSample = (sourceType: AliRtcVideoSourceType, videoSample: AliRtcVideoSample): boolean => {
    //   console.info('onLocalVideoSample');
    //
    //   // 处理本地采集的视频数据(YUV格式)
    //   if (videoSample.format === AliRtcVideoFormat.AliRtcVideoFormatI420) {
    //     if (this.isCustomVideoRender && this.currentRenderType === VideoRenderType.YUV && this.localRenderer) {
    //       this.localRenderer.drawYUV(videoSample);
    //     }
    //   }
    //   return true;
    // };
    //
    // // 远端视频数据回调
    // this.videoSampleObserver.onRemoteVideoSample = (callId: string, sourceType: AliRtcVideoSourceType, videoSample: AliRtcVideoSample): boolean => {
    //   if (videoSample.format === AliRtcVideoFormat.AliRtcVideoFormatI420) {
    //     // 处理远端视频数据
    //     let remoteRenderer = this.remoteRenderers.get(callId);
    //     if (!remoteRenderer) {
    //       // 创建新的渲染器
    //       remoteRenderer = this.createVideoRenderer();
    //       this.remoteRenderers.set(callId, remoteRenderer);
    //     }
    //     remoteRenderer.drawYUV(videoSample);
    //   } else {
    //     // TODO 其他格式数据处理
    //     console.info('其他格式视频数据:', videoSample.format);
    //   }
    //   return false;
    // };
    //
    // // 注册纹理数据回调
    // this.textureObserver = new AliRtcTextureObserver();
    //
    // let context: number = 0;
    //
    // this.textureObserver.onTextureCreate = (ctx: number) => {
    //   context = ctx;
    //   console.info('texture context: ' + context + ' create!');
    // };
    //
    // this.textureObserver.onTextureUpdate = (textureId: number, width: number, height: number, videoSample: AliRtcVideoSample): number => {
    //   if (this.logRef % 30 === 0) {
    //     console.info('texture update w: ' + width + ' h: ' + height + ' text_id: ' + textureId + ' rotate:' + videoSample.rotate);
    //   }
    //
    //   if (this.isCustomVideoRender && this.currentRenderType === VideoRenderType.TEXTURE && this.localTextureRenderer) {
    //     console.info('Updating 2D texture with ID: ' + textureId + ', size: ' + width + 'x' + height + ', context: ' + context + ', format: ' + videoSample.format);
    //     this.localTextureRenderer.updateTexture(textureId, width, height);
    //     if (this.localGLSurfaceView) {
    //       // 请求渲染
    //       // this.localGLSurfaceView.requestRender();
    //     }
    //   }
    //
    //   ++this.logRef;
    //   return textureId;
    // };
    //
    // this.textureObserver.onTextureDestroy = () => {
    //   console.info('texture context: ' + context + ' destroy!');
    // };
    //
    // // 注册观察者
    // this.rtcEngine.registerVideoSampleObserver(this.videoSampleObserver);
    // this.rtcEngine.registerLocalVideoTextureObserver(this.textureObserver);
  }

  // ==================== 创建视频渲染器 ====================
  private createVideoRenderer(): VideoRenderer {
    return {
      // drawYUV(videoSample: AliRtcVideoSample): void {
      //   // 这里实现具体的YUV渲染逻辑
      //   console.info('绘制YUV数据:', videoSample.width, 'x', videoSample.height);
      //   // TODO: 实现OpenGL ES渲染逻辑
      // }
    };
  }

  // ==================== 创建纹理渲染器 ====================
  // private createTextureRenderer(): TextureRenderer {
  // return {
  //   updateTexture(textureId: number, width: number, height: number): void {
  //     // 这里实现具体的纹理更新逻辑
  //     console.info('更新纹理:', textureId, '尺寸:', width, 'x', height);
  //     // TODO: 实现OpenGL ES纹理更新逻辑
  //   }
  // };
  // }

  // ==================== 事件监听器设置 ====================
  private setupEventListeners(): void {
    if (!this.rtcEngine) {
      return;
    }

    this.rtcEngineEventListener = new AliRtcEngineEventListener();

    // 加入频道结果回调
    this.rtcEngineEventListener.onJoinChannel((resultCode: number, channel: string, userId: string,
      elapsed: number) => {
      console.info(`加入频道结果: result=${resultCode}, channel=${channel}, userId=${userId}, elapsed=${elapsed}`);
      this.handleJoinResult(resultCode, channel, userId);
    });

    // 离开频道结果回调
    this.rtcEngineEventListener.onLeaveChannel((result: number, stats: AliRtcStats) => {
      console.info(`离开频道结果: result=${result}`);
      this.cleanupRenderers();
    });

    // 远端音视频流可用回调
    this.rtcEngineEventListener.onRemoteTrackAvailableNotify((userId: string, audioTrack: AliRtcAudioTrack,
      videoTrack: AliRtcVideoTrack) => {
      console.info(`远端音视频流可用: userId=${userId}, audioTrack=${audioTrack}, videoTrack=${videoTrack}`);

      // 处理视频流
      if (videoTrack === AliRtcVideoTrack.AliRtcVideoTrackCamera) {
        this.viewRemoteVideo(userId, AliRtcVideoTrack.AliRtcVideoTrackCamera);
      } else if (videoTrack === AliRtcVideoTrack.AliRtcVideoTrackNo) {
        this.removeAllRemoteVideo(userId);
      }
    });

    // 连接状态变化回调
    this.rtcEngineEventListener.onConnectionStatusChange(
      (status: AliRtcConnectionStatus, reason: AliRtcConnectionStatusChangeReason) => {
        console.info(`连接状态改变: status=${status}, reason=${reason}`);
        if (status === AliRtcConnectionStatus.AliRtcConnectionFailed) {
          promptAction.showToast({ message: '连接失败', duration: 2000 });
        }
      }
    );

    // 本地设备异常回调
    this.rtcEngineEventListener.onLocalDeviceException(
      (deviceType: AliRtcLocalDeviceType, exceptionType: AliRtcLocalDeviceExceptionType, msg: string) => {
        console.error(`本地设备异常: deviceType=${deviceType}, exceptionType=${exceptionType}, msg=${msg}`);
      }
    );

    this.rtcEngineEventListener.onAudioPublishStateChanged((audioTrack: AliRtcAudioTrack, oldState: AliRtcPublishState,
      newState: AliRtcPublishState, elapseSinceLastState: number, channel: string) => {
      console.info(`视频发布状态变化: oldState=${oldState}, newState=${newState}, channel=${channel}`);

      if (newState === 3) {
        prompt.showToast({
          message: 'Audio Stream has been published!',
          duration: 2000
        });
      }
    });

    // 鉴权信息即将过期
    this.rtcEngineEventListener.onAuthInfoWillExpire(() => {
      console.info('鉴权信息即将过期，需要更新Token');
      // TODO: 更新Token逻辑
    });

    // 被踢下线
    this.rtcEngineEventListener.onBye((code: number) => {
      console.info(`被踢下线: code=${code}`);
      promptAction.showToast({
        message: `被踢下线 code: ${code}`,
        duration: 2000
      });
    });

    this.rtcEngine.setRtcEngineEventListener(this.rtcEngineEventListener);
  }

  // ==================== 本地视频设置 ====================
  private setupLocalVideo(): void {
    console.info('setupLocalVideo 被调用');

    if (!this.rtcEngine) {
      console.warn('RTC引擎未初始化，延迟设置视频画布');
      return;
    }

    try {
      let surfaceId = this.xcomponentController.getXComponentSurfaceId();
      if (!surfaceId) {
        console.error('获取surfaceId失败，XComponent可能未就绪');
        return;
      }
      console.info('获取到本地视频surfaceId:', surfaceId);

      if (this.isCustomVideoRender) {
        // 自定义渲染
        if (this.currentRenderType === VideoRenderType.YUV) {
          // YUV格式使用自定义渲染器
          // this.localRenderer = this.createVideoRenderer();
          // TODO: 设置GLSurfaceView并关联渲染器
          this.localVideoCanvas = new AliRtcVideoCanvas();
          this.localVideoCanvas.surfaceId = surfaceId;
          this.localVideoCanvas.renderMode = AliRtcRenderMode.AliRtcRenderModeAuto;
          this.localVideoCanvas.mirrorMode = AliRtcRenderMirrorMode.AliRtcRenderMirrorModeAllMirror;
          console.info('本地视频画布设置完成');
          this.applyLocalVideoCanvas();
        } else if (this.currentRenderType === VideoRenderType.TEXTURE) {
          // 纹理格式使用自定义渲染器
          // this.localTextureRenderer = this.createTextureRenderer();
          // TODO: 设置GLSurfaceView并关联渲染器
          this.localVideoCanvas = new AliRtcVideoCanvas();
          this.localVideoCanvas.surfaceId = surfaceId;
          this.localVideoCanvas.renderMode = AliRtcRenderMode.AliRtcRenderModeAuto;
          this.localVideoCanvas.mirrorMode = AliRtcRenderMirrorMode.AliRtcRenderMirrorModeAllMirror;
          console.info('本地视频画布设置完成');
          this.applyLocalVideoCanvas();
        }
      } else {
        // 使用SDK默认渲染
        this.localVideoCanvas = new AliRtcVideoCanvas();
        this.localVideoCanvas.surfaceId = surfaceId;
        this.localVideoCanvas.renderMode = AliRtcRenderMode.AliRtcRenderModeAuto;
        this.localVideoCanvas.mirrorMode = AliRtcRenderMirrorMode.AliRtcRenderMirrorModeAllMirror;
        console.info('本地视频画布设置完成');
        this.applyLocalVideoCanvas();
      }

    } catch (error) {
      console.error('设置本地视频失败:', error);
    }
  }

  private applyLocalVideoCanvas(): void {
    if (!this.rtcEngine || !this.localVideoCanvas) {
      return;
    }
    try {
      this.rtcEngine.setLocalViewConfig(
        this.localVideoCanvas,
        this.componentController,
        AliRtcVideoTrack.AliRtcVideoTrackCamera
      );
      console.info('本地视频画布已应用到RTC引擎');
    } catch (error) {
      console.error('应用本地视频画布失败:', error);
    }
  }

  // ==================== 设置远端视频 ====================
  private setupRemoteVideo(stream: RemoteVideoStream): void {
    if (!this.rtcEngine) {
      console.error('RTC引擎未初始化');
      return;
    }

    try {
      stream.surfaceId = stream.xcomponentController.getXComponentSurfaceId();
      console.info(`设置远端视频: ${stream.uid} - ${stream.videoTrack}, surfaceId: ${stream.surfaceId}`);

      if (!stream.canvas) {
        stream.canvas = new AliRtcVideoCanvas();
      }

      stream.canvas.surfaceId = stream.surfaceId;
      stream.canvas.renderMode = AliRtcRenderMode.AliRtcRenderModeAuto;
      stream.canvas.mirrorMode = AliRtcRenderMirrorMode.AliRtcRenderMirrorModeAllNoMirror;

      if (this.isCustomVideoRender) {
        // 自定义渲染远端视频
        const renderer = this.createVideoRenderer();
        // this.remoteRenderers.set(stream.uid, renderer);
        // TODO: 设置GLSurfaceView并关联渲染器 替换
      } else {
        // 使用SDK渲染
        this.rtcEngine.setRemoteViewConfig(stream.canvas, this.componentController, stream.uid,
          stream.videoTrack);
      }

      console.info(`远端视频设置完成: ${stream.uid} - ${stream.videoTrack}`);

    } catch (error) {
      console.error(`设置远端视频失败 ${stream.uid}:`, error);
    }
  }

  // ==================== 查看远端视频 ====================
  private viewRemoteVideo(uid: string, videoTrack: AliRtcVideoTrack): void {
    console.info(`查看远端视频: ${uid} - ${videoTrack}`);

    const existingIndex = this.remoteVideoStreams.findIndex(
      s => s.uid === uid && s.videoTrack === videoTrack
    );

    if (existingIndex >= 0) {
      console.info(`远端视频已存在: ${uid} - ${videoTrack}`);
      return;
    }

    const newStream: RemoteVideoStream = {
      uid,
      videoTrack,
      canvas: new AliRtcVideoCanvas(),
      xcomponentController: new XComponentController(),
      surfaceId: ''
    };

    this.remoteVideoStreams.push(newStream);
    console.info(`添加远端视频成功: ${uid} - ${videoTrack}`);
  }

  // ==================== 移除远端视频 ====================
  private removeRemoteVideo(uid: string, videoTrack: AliRtcVideoTrack): void {
    console.info(`移除远端视频: ${uid} - ${videoTrack}`);

    const index = this.remoteVideoStreams.findIndex(
      s => s.uid === uid && s.videoTrack === videoTrack
    );

    if (index >= 0) {
      this.remoteVideoStreams.splice(index, 1);
      // this.remoteRenderers.delete(uid);
      console.info(`移除远端视频成功: ${uid} - ${videoTrack}`);
    }
  }

  // ==================== 移除用户的所有视频 ====================
  private removeAllRemoteVideo(uid: string): void {
    console.info(`移除用户所有视频: ${uid}`);
    this.remoteVideoStreams = this.remoteVideoStreams.filter(s => s.uid !== uid);
    // this.remoteRenderers.delete(uid);
    console.info(`移除用户所有视频成功: ${uid}`);
  }

  // ==================== 频道操作 ====================
  private async startRTCCall(): Promise<void> {
    if (this.hasJoined) {
      return;
    }

    await this.startPreview();
    await this.joinChannel();
  }

  private async startPreview(): Promise<void> {
    if (!this.rtcEngine) {
      return;
    }

    try {
      if (this.localVideoCanvas) {
        this.applyLocalVideoCanvas();
      } else {
        this.setupLocalVideo();
      }

      this.rtcEngine.startPreview();
      this.showPreview = true;
      console.info('本地预览已启动');
    } catch (error) {
      console.error('启动预览失败:', error);
    }
  }

  private async joinChannel(): Promise<void> {
    if (!this.rtcEngine || !this.channelId.trim()) {
      promptAction.showToast({ message: '频道ID不能为空', duration: 2000 });
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
        appId, appKey, this.channelId, userId, timestamp, nonce
      );

      const result = this.rtcEngine.joinChannelWithToken(base64Token, '', '', '自定义视频渲染用户');

      console.info('加入频道调用结果:', result);
      this.hasJoined = true;
      this.localUserId = userId;
    } catch (error) {
      console.error('加入频道失败:', error);
      promptAction.showToast({ message: `加入频道失败: ${error}`, duration: 3000 });
    }
  }

  // ==================== 结果处理 ====================
  private handleJoinResult(resultCode: number, channel: string, userId: string): void {
    const resultText = resultCode === 0
      ? `User ${userId} Join ${channel} Success`
      : `Join ${userId} Join ${channel} Failed!，error: ${resultCode}`;

    promptAction.showToast({ message: resultText, duration: 2000 });

  }

  // ==================== 清理渲染器 ====================
  private cleanupRenderers(): void {
    // this.remoteRenderers.clear();
    // this.localRenderer = null;
    // this.localTextureRenderer = null;
    // this.localGLSurfaceView = null;
  }

  // ==================== 清理资源 ====================
  private destroyRtcEngine(): void {
    if (this.rtcEngine) {
      try {
        // 取消视频数据回调
        // this.rtcEngine.unRegisterVideoSampleObserver();
        // this.rtcEngine.unRegisterLocalVideoTextureObserver();

        if (this.hasJoined) {
          this.rtcEngine.stopPreview();
          this.rtcEngine.leaveChannel();
          this.hasJoined = false;
        }

        this.rtcEngine = undefined;
        this.rtcEngineEventListener = undefined;

        promptAction.showToast({ message: 'Leave Channel', duration: 2000 });
      } catch (error) {
        console.error('销毁引擎失败:', error);
      }
    }

    // 清理渲染器
    this.cleanupRenderers();

    // 重置状态
    this.showPreview = false;
    this.isPushingVideoData = false;
    this.localUserId = '';
    this.remoteVideoStreams = [];

    // 清理本地视频视图
    if (this.localVideoCanvas) {
      this.localVideoCanvas = undefined;
    }
  }

  aboutToDisappear(): void {
    this.destroyRtcEngine();
  }
}