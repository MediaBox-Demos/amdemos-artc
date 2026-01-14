import {
  AliRtcAudioProfile,
  AliRtcAudioScenario,
  AliRtcAudioTrack,
  AliRtcChannelProfile,
  AliRtcClientRole,
  AliRtcEngine,
  AliRtcEngineAuthInfo,
  AliRtcEngineEventListener,
  AliRtcRenderMirrorMode,
  AliRtcRenderMode,
  AliRtcUserOfflineReason,
  AliRtcVideoCanvas,
  AliRtcVideoTrack,
  AliRtcXComponentController,
  AliRtcCapturePipelineScaleMode,
  AliRtcVideoPipelineMirrorMode,
  AliRtcVideoEncoderConfiguration,
  AliRtcCameraCaptureConfiguration
} from '@aliyun_video_cloud/alivcsdk_artc';
import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { CustomTitle } from '../../common/components/CustomTitle';
import { VideoConfig } from './common/VideoConfig';
import { VideoConfigDialog } from './components/VideoConfigDialog';
import { RemoteVideoStream } from "../../common/Constants"
import { ARTCTokenHelper } from '../../common/keycenter/ARTCTokenHelper';
import { GlobalConfig } from '../../common/keycenter/GlobalConfig';


@Entry
@Component
export struct VideoBasicUsage {
  @State ChannelId: string = '';
  @State ShowPreview: boolean = false;
  private rtcEngine: AliRtcEngine | undefined;
  private context: common.Context | undefined;
  private xcomponentController: XComponentController = new XComponentController();
  private aliRtcVideoCanvas: AliRtcVideoCanvas | undefined;
  private componentController: AliRtcXComponentController = new AliRtcXComponentController()
  private hasJoined: boolean = false;
  private isLocalPreviewing: boolean = false;
  private isEnableCamera: boolean = true;
  private isMutedCamera: boolean = false;
  private rtcEventListener?: AliRtcEngineEventListener;
  // 镜像设置
  @State selectedValue: string = '均关闭镜像';
  @State mirrorModeIndex: number = 0;
  // 新增：管理远端视频流
  @State remoteVideoStreams: RemoteVideoStream[] = [];
  // 新增：本地SurfaceId
  @State localSurfaceId: string = '';
  @State isLocalVideoReady: boolean = false;
  @State videoConfig: VideoConfig = new VideoConfig();
  @State showVideoConfigDialog: boolean = false;
  @State isVideoConfig: boolean = false;
  @State name: string = '设置';
  videoConfigDialogController: CustomDialogController = new CustomDialogController({
    builder: VideoConfigDialog({
      callBack: (update: VideoConfig) => {
        this.videoConfig = update;
        this.isVideoConfig = true
      },
      config: this.videoConfig
    }),
    alignment: DialogAlignment.Center,
    offset: { dx: 0, dy: 0 },
    customStyle: true
  });

  async aboutToAppear(): Promise<void> {
    this.context = getContext() as common.Context;
    this.ChannelId = Math.floor(100000 + Math.random() * 900000).toString();
  }

  aboutToDisappear(): void {
    this.destroyRtcEngine();
  }

  build() {
    NavDestination() {
      Column() {
        CustomTitle({
          titleText: '视频常用操作和配置',
        })
        Stack() {
          Column() {
            // 视频展示区域
            this.buildVideoDisplayArea()
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
            }
            .margin({ top: 20 })
            .height(50)

            Select([{ value: '均关闭镜像' },
              { value: '均开启镜像' },
              { value: '仅预览镜像' },
              { value: '仅编码镜像' }])
              .margin({
                bottom: 5
              })
              .width('100%')
              .backgroundColor('#ffffff')      // 固定白色背景
              .selected(this.mirrorModeIndex)
              .value(this.selectedValue)
              .font({ size: 16, weight: 500 })
              .fontColor('#000000')           // 固定黑色文字
              .selectedOptionFont({ size: 16, weight: 400 })
              .optionFont({ size: 16, weight: 400 })
              .menuAlign(MenuAlignType.START, { dx: 0, dy: 0 })
              .optionWidth(200)
              .optionHeight(300)
              .onSelect((index: number, text?: string | undefined) => {
                console.info('Select:' + index);
                this.mirrorModeIndex = index;
                if (text) {
                  this.selectedValue = text;
                  this.applyMirrorMode(index); // 应用镜像设置
                }
              })

            Row({ space: 15 }) {
              // 开启/关闭预览按钮
              Button({
                type: ButtonType.Normal
              }) {
                Text(this.isLocalPreviewing ? '关闭预览' : '开启预览')
                  .fontSize(14)
              }
              .onClick(() => {
                this.togglePreview();
              })
              .backgroundColor('#3295fb')
              .layoutWeight(1)
              .height(40)

              // 切换摄像头按钮
              Button({
                type: ButtonType.Normal
              }) {
                Text('切换摄像头')
                  .fontSize(14)
              }
              .onClick(() => {
                this.switchCamera();
              })
              .backgroundColor('#3295fb')
              .layoutWeight(1)
              .height(40)

              // 开启/关闭摄像头按钮
              Button({
                type: ButtonType.Normal
              }) {
                Text(this.isEnableCamera ? '关闭摄像头' : '开启摄像头')
                  .fontSize(14)
              }
              .onClick(() => {
                this.toggleCamera();
              })
              .backgroundColor('#3295fb')
              .layoutWeight(1)
              .height(40)
            }
            .justifyContent(FlexAlign.Center)

            Row({ space: 15 }) {
              // 停止/开始视频发送按钮
              Button({
                type: ButtonType.Normal
              }) {
                Text(this.isMutedCamera ? '开始发送视频' : '停止发送视频')
                  .fontSize(14)
              }
              .onClick(() => {
                this.toggleVideoSending();
              })
              .backgroundColor('#3295fb')
              .layoutWeight(1)
              .height(40)

              // 加入/离开房间按钮
              Button({
                type: ButtonType.Normal
              }) {
                Text(this.hasJoined ? '挂断' : '加入房间')
                  .fontSize(14)
              }
              .onClick(() => {
                this.toggleJoinRoom();
              })
              .backgroundColor('#ff5df343')
              .layoutWeight(1)
              .height(40)

              // 设置按钮
              Button({
                type: ButtonType.Normal
              }) {
                Text(this.name)
                  .fontSize(14)
              }
              .onClick(() => {
                this.openVideoConfigDialog();
              })
              .backgroundColor('#3295fb')
              .layoutWeight(1)
              .height(40)
            }
            .justifyContent(FlexAlign.Center)
            .margin({
              top: 20,
            })
          }
          .margin(12)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#f5f5f5')  // 设置固定背景色以避免暗色模式下变黑
    }
    .hideTitleBar(true)
  }

  // 构建视频显示区域
  @Builder
  buildVideoDisplayArea() {
    Column() {
      Scroll() {
        Column() {
          if (!this.remoteVideoStreams) {
            Column() {
              XComponent({
                id: 'local_video_surface',
                type: 'surface',
                controller: this.xcomponentController
              })
                .width('100%')
                .height('200vp')
                .onLoad(() => {
                  console.info('XComponent onLoad 触发');
                  this.handleLocalVideoLoad();
                })
                .onDestroy(() => {
                  console.info('XComponent onDestroy');
                  this.localSurfaceId = '';
                  this.isLocalVideoReady = false;
                })
            }
            .width('100%')
            .height('200vp')
            .backgroundColor('#000')
            .margin({ bottom: 8 })
            .opacity(this.ShowPreview ? 1 : 0)
          } else {
            Row() {
              Column() {
                XComponent({
                  id: 'local_video_surface',
                  type: 'surface',
                  controller: this.xcomponentController
                })
                  .width('180')
                  .height('180vp')
                  .onLoad(() => {
                    console.info('XComponent onLoad 触发');
                    this.handleLocalVideoLoad();
                  })
                  .onDestroy(() => {
                    console.info('XComponent onDestroy');
                    this.localSurfaceId = '';
                    this.isLocalVideoReady = false;
                  })
              }
              .layoutWeight(1)
              .height('180vp')
              .backgroundColor('#000')
              .margin({ bottom: 8 })
              .opacity(this.ShowPreview ? 1 : 0)

              Blank()
                .width(8)

              // 远端视频流
              ForEach(this.remoteVideoStreams, (stream: RemoteVideoStream) => {
                Column() {
                  XComponent({
                    id: `remote_${stream.uid}_${stream.videoTrack}`,
                    type: 'surface',
                    controller: stream.xcomponentController
                  })
                    .layoutWeight(1)
                    .height('180vp')
                    .onLoad(() => {
                      console.info(`远端XComponent加载: ${stream.uid}`);
                      const surfaceId = stream.xcomponentController.getXComponentSurfaceId();
                      console.info(`远端获取到surfaceId: ${surfaceId}`);
                      if (surfaceId && this.rtcEngine) {
                        this.setupRemoteVideo(stream);
                      }
                    })
                }
                .layoutWeight(1)
                .height('180vp')
                .backgroundColor('#000')
                .margin({ bottom: 8 })
                .borderRadius(8)
              })
            }

          }


        }
        .justifyContent(FlexAlign.Start)
        .width('100%')
        .height('100%')
      }
      .height('450vp')
      .width('100%')
    }
    .width('100%')
  }

  // ==================== 视频功能实现 ====================

  // 处理本地视频加载
  private handleLocalVideoLoad(): void {
    try {
      this.localSurfaceId = this.xcomponentController.getXComponentSurfaceId();
      console.info('获取到本地视频surfaceId:', this.localSurfaceId);

      if (!this.localSurfaceId) {
        console.error('surfaceId获取为空，XComponent可能未完全加载');
        return;
      }

      this.isLocalVideoReady = true;

      // 如果已经有RTC引擎，立即设置本地视频
      if (this.rtcEngine && this.isLocalPreviewing) {
        this.setupLocalVideo();
      }
    } catch (error) {
      console.error('处理本地视频加载失败:', error);
    }
  }



  // 初始化RTC引擎
  private initAndSetupRtcEngine(): boolean {
    if (this.rtcEngine) {
      console.info('RTC引擎已存在，跳过初始化');
      return true;
    }

    if (!this.context) {
      console.error('Context未初始化');
      return false;
    }

    try {
      // 创建RTC引擎实例
      this.rtcEngine = AliRtcEngine.getInstance('', this.context);

      if (!this.rtcEngine) {
        console.error('创建RTC引擎失败');
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

      // 设置捕获管道缩放模式
      this.rtcEngine.setCapturePipelineScaleMode(AliRtcCapturePipelineScaleMode.AliRtcCapturePipelineScaleModePre);

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
      console.error('RTC引擎未初始化，无法设置事件监听器');
      return;
    }

    try {
      if (!this.rtcEventListener) {
        this.rtcEventListener = new AliRtcEngineEventListener();

        this.rtcEventListener.onJoinChannel((resultCode: number, channel: string, elapsed: string) => {
          console.info(`加入频道结果: result=${resultCode}, channel=${channel}, elapsed=${elapsed}`);

          if (resultCode === 0) {
            this.hasJoined = true;
            promptAction.showToast({
              message: `Join ${channel} Success`,
              duration: 2000
            });
          } else {
            promptAction.showToast({
              message: `加入房间失败: ${resultCode}`,
              duration: 2000
            });
          }
        });

        this.rtcEventListener.onLeaveChannel((resultCode: number) => {
          console.info(`离开频道: result=${resultCode}`);
          this.cleanupAfterLeave();
          promptAction.showToast({
            message: 'Leave Channel',
            duration: 2000
          });
        });

        this.rtcEventListener.onConnectionStatusChange((status: number, reason: number) => {
          console.info(`连接状态变更: status=${status}, reason=${reason}`);
          if (status === 5) {
            promptAction.showToast({
              message: '连接失败，请检查网络',
              duration: 3000
            });
          }
        });

        this.rtcEventListener.onLocalDeviceException((deviceType: number, exceptionType: number, msg: string) => {
          console.error(`本地设备异常: deviceType=${deviceType}, exceptionType=${exceptionType}, msg=${msg}`);
          promptAction.showToast({
            message: `设备异常: ${msg}`,
            duration: 3000
          });
        });

        this.rtcEventListener.onRemoteUserOnline((userId: string, elapsed: boolean) => {
          console.info(`远端用户上线: userId=${userId}, elapsed=${elapsed}`);
          promptAction.showToast({
            message: `remote user uid ${userId} camera enable: ${elapsed}`,
            duration: 2000
          });
        });

        this.rtcEventListener.onRemoteUserOffline((userId: string, reason: AliRtcUserOfflineReason) => {
          console.info(`远端用户下线: userId=${userId}, reason=${reason}`);
          this.removeAllRemoteVideo(userId);
          promptAction.showToast({
            message: `User ${userId} offline`,
            duration: 2000
          });
        });

        this.rtcEventListener.onRemoteTrackAvailableNotify((userId: string, audioTrack: AliRtcAudioTrack,
          videoTrack: AliRtcVideoTrack) => {
          console.info(`远端音视频流可用: userId=${userId}, videoTrack=${videoTrack}`);

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
        });

        this.rtcEventListener.onBye((code: number) => {
          console.info(`被服务器踢出: code=${code}`);
          promptAction.showToast({
            message: `被服务器踢出: ${code}`,
            duration: 3000
          });
          this.destroyRtcEngine();
        });

        this.rtcEventListener.onUserVideoEnabled((userId: string, isEnable: boolean) => {
          console.info(`远端用户视频状态: userId=${userId}, isEnable=${isEnable}`);
        });
      }

      this.rtcEngine.setRtcEngineEventListener(this.rtcEventListener);
      console.info('事件监听器设置完成');
    } catch (error) {
      console.error('设置事件监听器失败:', error);
    }
  }

  // 设置本地视频（仅创建canvas，不启动预览）
  private setupLocalVideo(): boolean {
    if (!this.rtcEngine) {
      console.error('RTC引擎未初始化');
      return false;
    }

    if (!this.localSurfaceId) {
      console.error('localSurfaceId为空，无法设置本地视频');
      return false;
    }

    try {
      // 创建或重用canvas
      if (!this.aliRtcVideoCanvas) {
        this.aliRtcVideoCanvas = new AliRtcVideoCanvas();
      }

      this.aliRtcVideoCanvas.surfaceId = this.localSurfaceId;
      this.aliRtcVideoCanvas.renderMode = AliRtcRenderMode.AliRtcRenderModeAuto;
      this.aliRtcVideoCanvas.mirrorMode = AliRtcRenderMirrorMode.AliRtcRenderMirrorModeAllMirror;

      this.rtcEngine.setLocalViewConfig(
        this.aliRtcVideoCanvas,
        this.componentController,
        AliRtcVideoTrack.AliRtcVideoTrackCamera
      );

      console.info('本地视频画布设置完成');
      return true;
    } catch (error) {
      console.error('设置本地视频失败:', error);
      return false;
    }
  }

  // 设置远端视频
  private setupRemoteVideo(stream: RemoteVideoStream): boolean {
    if (!this.rtcEngine) {
      console.error('RTC引擎未初始化');
      return false;
    }

    try {
      const surfaceId = stream.xcomponentController.getXComponentSurfaceId();
      if (!surfaceId) {
        console.error(`远端视频surfaceId为空: ${stream.uid}`);
        return false;
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
      return true;
    } catch (error) {
      console.error(`设置远端视频失败 ${stream.uid}:`, error);
      return false;
    }
  }

  // 开始预览
  private startPreview(): boolean {
    if (!this.rtcEngine) {
      console.error('RTC引擎未初始化，无法开始预览');
      return false;
    }

    try {
      const setupSuccess = this.setupLocalVideo();
      if (!setupSuccess) {
        console.error('设置本地视频失败，无法开始预览');
        return false;
      }
      this.joinChannelSetting()

      this.rtcEngine.startPreview();
      this.isLocalPreviewing = true;
      this.ShowPreview = true;
      // 恢复摄像头启用状态
      this.isEnableCamera = true;
      console.info('本地预览已启动');
      return true;
    } catch (error) {
      console.error('启动预览失败:', error);
      return false;
    }
  }

  private async joinChannelSetting(): Promise<boolean> {
    //开启预览不设置视频配置
    if (!this.isLocalPreviewing || !this.hasJoined) {
      if (this.isVideoConfig) {
        console.info('加入房间前，应用已保存的视频配置...');
        this.applyCameraCaptureConfiguration(this.videoConfig);
        this.applyVideoEncoderConfiguration(this.videoConfig)
        //每次都从新赋值
        this.isVideoConfig = false
        this.videoConfig = new VideoConfig()
      } else {
        this.applyCameraCaptureConfiguration(this.videoConfig);
        this.applyVideoEncoderConfiguration(this.videoConfig)
      }
    }
    return true
  }

  // 停止预览
  private stopPreview(): void {
    if (this.rtcEngine && this.isLocalPreviewing) {
      try {
        this.rtcEngine.stopPreview();
        this.isLocalPreviewing = false;
        this.ShowPreview = false;
        console.info('本地预览已停止');
      } catch (error) {
        console.error('停止预览失败:', error);
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

  // 移除指定用户视频流
  private removeRemoteVideo(uid: string, videoTrack: AliRtcVideoTrack): void {
    console.info(`移除远端视频: uid=${uid}, videoTrack=${videoTrack}`);

    const streamKey = this.getStreamKey(uid, videoTrack);
    const index = this.remoteVideoStreams.findIndex(
      s => this.getStreamKey(s.uid, s.videoTrack) === streamKey
    );

    if (index >= 0) {
      this.remoteVideoStreams.splice(index, 1);
      console.info(`移除远端视频成功: uid=${uid}`);
    }
  }

  // 移除用户的所有视频
  private removeAllRemoteVideo(uid: string): void {
    console.info(`移除用户所有视频: uid=${uid}`);
    this.remoteVideoStreams = this.remoteVideoStreams.filter(s => s.uid !== uid);
    console.info(`移除用户所有视频成功: uid=${uid}`);
  }

  // 根据用户ID和流类型生成唯一标识
  private getStreamKey(uid: string, videoTrack: AliRtcVideoTrack): string {
    return `${uid}_${videoTrack}`;
  }

  // ==================== 按钮功能实现 ====================

  // 切换预览
  private togglePreview(): void {
    // 入会前开启预览
    const initSuccess = this.initAndSetupRtcEngine();
    if (!initSuccess) {
      promptAction.showToast({
        message: 'RTC引擎初始化失败',
        duration: 2000
      });
      return;
    }


    if (this.isLocalPreviewing) {
      this.stopPreview();
    } else {
      const previewSuccess = this.startPreview();
      if (!previewSuccess) {
        promptAction.showToast({
          message: '开始预览失败，请检查视频权限',
          duration: 2000
        });
      }
    }

  }

  // 切换摄像头
  private switchCamera(): void {
    if (this.rtcEngine) {
      try {
        this.rtcEngine.switchCamera();
      } catch (error) {
        console.error('切换摄像头失败:', error);
      }
    }
  }

  // 开关摄像头
  private toggleCamera(): void {
    if (this.rtcEngine) {
      if (this.isEnableCamera) {
        this.rtcEngine.enableLocalVideo(false);
        this.isEnableCamera = false;
      } else {
        this.rtcEngine.enableLocalVideo(true);
        this.isEnableCamera = true;

      }
    }
  }

  // 开关视频发送
  private toggleVideoSending(): void {
    if (this.rtcEngine) {
      if (!this.isMutedCamera) {
        this.rtcEngine.muteLocalCamera(true, AliRtcVideoTrack.AliRtcVideoTrackCamera);
        this.isMutedCamera = true;
      } else {
        this.rtcEngine.muteLocalCamera(false, AliRtcVideoTrack.AliRtcVideoTrackCamera);
        this.isMutedCamera = false;
      }
    }
  }

  // 应用镜像设置
  private applyMirrorMode(index: number): void {
    if (this.rtcEngine) {
      try {
        const mirrorMode = index as AliRtcVideoPipelineMirrorMode;
        this.rtcEngine.setVideoMirrorMode(mirrorMode);
        console.info(`应用镜像模式: ${index}`);
      } catch (error) {
        console.error('应用镜像设置失败:', error);
      }
    }
  }

  // 加入/离开房间
  private async toggleJoinRoom(): Promise<void> {
    if (this.hasJoined) {
      if (this.rtcEngine) {
        try {
          this.stopPreview();
          this.rtcEngine.leaveChannel();
          this.hasJoined = false;
          promptAction.showToast({
            message: 'Leave Channel',
            duration: 2000
          });

        } catch (error) {
          console.error('销毁RTC引擎失败:', error);
        }
      }
      return;
    }

    // 加入房间逻辑
    const channelId = this.ChannelId.trim();
    if (!channelId) {
      promptAction.showToast({
        message: '请输入频道ID',
        duration: 1000
      });
      return;
    }

    try {
      // 初始化RTC引擎
      const engineReady = this.initAndSetupRtcEngine();
      if (!engineReady) {
        throw new Error('RTC引擎初始化失败');
      }

      // 确保本地视频已准备好
      if (!this.isLocalVideoReady) {
        promptAction.showToast({
          message: '视频组件未准备好，请稍后重试',
          duration: 2000
        });
        return;
      }
      // 开始预览
      const previewSuccess = this.startPreview();
      if (!previewSuccess) {
        throw new Error('开始预览失败');
      }

      // 加入频道
      await this.joinChannel();

      console.info('成功加入房间');

    } catch (error) {
      console.error('加入房间失败:', error);
      promptAction.showToast({
        message: `加入房间失败: ${error}`,
        duration: 3000
      });
      this.hasJoined = false;
    }
  }

  // 加入频道
  private async joinChannel(): Promise<void> {
    if (!this.rtcEngine) {
      throw new Error('RTC引擎未初始化');
    }

    if (!this.ChannelId.trim()) {
      throw new Error('频道ID不能为空');
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

      const result = this.rtcEngine.joinChannelWithToken(base64Token, '', '', '视频通话用户');
      console.info('加入频道调用结果:', result);

    } catch (error) {
      console.error('加入频道失败:', error);
    }
  }

  // 销毁RTC引擎
  private destroyRtcEngine(): void {
    if (this.rtcEngine) {
      try {
        if (this.hasJoined) {
          this.rtcEngine.leaveChannel();
          this.hasJoined = false;
          promptAction.showToast({
            message: 'Leave Channel',
            duration: 2000
          });
        }

        if (this.isLocalPreviewing) {
          this.rtcEngine.stopPreview();
          this.isLocalPreviewing = false;
          this.ShowPreview = false;
        }

        this.rtcEngine = undefined;

        console.info('RTC引擎销毁完成');
      } catch (error) {
        console.error('销毁RTC引擎失败:', error);
      }
    }

    // 清理所有远端视频资源
    this.remoteVideoStreams = [];
    this.localSurfaceId = '';
    this.isLocalVideoReady = false;
    this.isEnableCamera = true;
    this.isMutedCamera = false;
  }

  // 离开后的清理工作
  private cleanupAfterLeave(): void {
    this.hasJoined = false;
    this.ShowPreview = false;
    this.remoteVideoStreams = [];
    this.isLocalPreviewing = false;
    this.isEnableCamera = true;
    this.isMutedCamera = false;
    console.info('清理完成');
  }

  private applyCameraCaptureConfiguration(config: VideoConfig): void {
    try {
      console.info('正在设置摄像头采集配置:', JSON.stringify(config));
      // 创建新的配置对象
      const cameraConfig = new AliRtcCameraCaptureConfiguration();
      cameraConfig.preference = config.cameraPreference;
      cameraConfig.cameraDirection = config.cameraDirection;
      cameraConfig.cameraCaptureProfile = config.cameraCaptureProfile;
      cameraConfig.textureEncode = config.textureEncode ? 1 : 0;
      cameraConfig.cameraTextureCapture = config.cameraTextureCapture ? 1 : 0;

      // 调用RTC引擎设置配置
      this.rtcEngine?.setCameraCaptureConfiguration(cameraConfig);
      console.info('摄像头采集配置设置成功，方向为:', config.cameraDirection === 0 ? '后置' : '前置');
    } catch (error) {
      console.error('设置摄像头采集配置失败:', error);
      promptAction.showToast({
        message: '设置摄像头采集配置失败',
        duration: 1500
      });
    }

  }

  // 应用视频编码配置
  private applyVideoEncoderConfiguration(config: VideoConfig): void {
    console.info('应用视频编码配置:', config);

    try {
      console.info('视频编码配置:', config);

      // 创建新的配置对象，复制属性
      const encoderConfig = new AliRtcVideoEncoderConfiguration();
      encoderConfig.dimensions.width = config.width;
      encoderConfig.dimensions.height = config.height;
      encoderConfig.bitrate = config.bitrate;
      encoderConfig.frameRate = config.frameRate;
      encoderConfig.keyFrameInterval = config.keyFrameInterval;
      encoderConfig.forceStrictKeyFrameInterval = config.forceStrictKeyFrameInterval ? 1 : 0;
      encoderConfig.orientationMode = config.orientationMode;
      encoderConfig.rotationMode = config.rotationMode;

      // 根据Android代码逻辑验证和调整配置
      this.adjustVideoEncoderConfig(encoderConfig);

      console.info('调整后的视频编码配置:', encoderConfig);

      // 调用RTC引擎设置配置
      this.rtcEngine?.setVideoEncoderConfiguration(encoderConfig);

    } catch (error) {
      console.error('设置视频编码配置失败:', error);
      promptAction.showToast({
        message: '设置视频编码配置失败',
        duration: 1500
      });
    }
  }

  // 调整视频编码配置（根据Android代码逻辑）
  private adjustVideoEncoderConfig(config: AliRtcVideoEncoderConfiguration): void {
    // 验证帧率（根据Android代码逻辑）
    if (config.frameRate > 30) {
      config.frameRate = 30;
      console.info('帧率限制为30');
    }
    if (config.frameRate <= 1) {
      config.frameRate = 1;
      console.info('帧率调整为1');
    }

    // 关键帧间隔（根据Android代码逻辑，大于1时才设置）
    if (config.keyFrameInterval && config.keyFrameInterval <= 1) {
      config.keyFrameInterval = 0;
    }
  }

  // 打开视频配置对话框
  private openVideoConfigDialog(): void {
    // 首先确保RTC引擎已初始化（根据Android代码逻辑）
    if (!this.rtcEngine) {
      const initSuccess = this.initAndSetupRtcEngine();
      if (!initSuccess) {
        promptAction.showToast({
          message: 'RTC引擎初始化失败，无法打开配置',
          duration: 1500
        });
        return;
      }
    }

    // 打开视频配置对话框
    this.videoConfigDialogController.open();
  }


}