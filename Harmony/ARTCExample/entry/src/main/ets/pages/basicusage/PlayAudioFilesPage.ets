import { CustomTitle } from "../../common/components/CustomTitle"
import { prompt, promptAction } from '@kit.ArkUI';
import { ISelectOption } from "../../common/Constants";
import { common } from "@kit.AbilityKit";
import fs from '@ohos.file.fs';
import { ARTCTokenHelper } from '../../common/keycenter/ARTCTokenHelper';
import { GlobalConfig } from '../../common/keycenter/GlobalConfig';
import {
  AliRtcEngine,
  AliRtcEngineEventListener,
  AliRtcEngineAuthInfo,
  AliRtcChannelProfile,
  AliRtcClientRole,
  AliRtcAudioProfile,
  AliRtcAudioScenario,
  AliRtcVideoEncoderConfiguration,
  AliRtcVideoDimensions,
  AliRtcVideoEncoderOrientationMode,
  AliRtcVideoMirrorMode,
  AliRtcRotationMode,
  AliRtcVideoTrack,
  AliRtcAudioTrack,
  AliRtcConnectionStatus,
  AliRtcUserOfflineReason,
  AliRtcLocalDeviceType,
  AliRtcLocalDeviceExceptionType,
  AliRtcAudioAccompanyConfig,
  AliRtcAudioEffectConfig,
  AliRtcAudioAccompanyStateCode,
  AliRtcAudioAccompanyErrorCode,
  AliRtcAudioFileInfo,
  AliRtcVideoCanvas,
  AliRtcXComponentController,
  AliRtcRenderMode,
  AliRtcRenderMirrorMode,
  AliRtcCapturePipelineScaleMode,
  AliRtcPublishState
} from '@aliyun_video_cloud/alivcsdk_artc';
import { resourceManager } from "@kit.LocalizationKit";
import { SandboxFileManager } from "../../common/utils/SandboxFileManager";
import { RemoteVideoStream } from "../../common/Constants"

interface RawFileDescriptor {
  fd: number;
  offset: number;
  length: number;
}


@Entry
@Component
export struct PlayAudioFilesPage {
  @State initRoom: boolean = false
  @State channelId: string = Date.now().toString().slice(-6);
  @State ShowPreview: boolean = false;
  // 伴奏相关状态
  @State accompanimentExpanded: boolean = true
  @State accompanimentFile: string = 'music.wav'
  @State accompanimentVolume: number = 60
  @State pushVolume: number = 60
  @State playVolume: number = 60
  @State loopCount: string = ''
  @State playProgress: number = 0
  @State audioDuration: number = 0 // 音频总时长
  // 音效相关状态
  @State soundEffectExpanded: boolean = true
  @State selectedSoundEffect: string = '音效 1 (effect1.wav)'
  @State soundEffectVolume: number = 60
  @State soundEffectLiangVolume: number = 60
  @State playCount: string = '1'
  // 当前选中的音效ID
  private currSoundID: number = 1;
  // 音效选项
  private soundEffectOptions: string[] = [
    '音效 1 (effect1.wav)',
    '音效 2 (effect2.wav)',
  ]
  // 音效文件路径
  private audioEffectFilePath1: string = 'thunder.wav';
  private audioEffectFilePath2: string = 'applause.wav';
  // RTC引擎相关
  private rtcEngine: AliRtcEngine | undefined;
  private context: common.UIAbilityContext | undefined;
  private xcomponentController: XComponentController = new XComponentController();
  private componentController: AliRtcXComponentController = new AliRtcXComponentController();
  private hasJoined: boolean = false;
  private rtcEventListener?: AliRtcEngineEventListener;
  // 远端视频流管理
  @State remoteVideoStreams: RemoteVideoStream[] = []
  private remoteViews: Map<string, RemoteVideoStream> = new Map();
  private aliRtcVideoCanvas: AliRtcVideoCanvas | undefined;
  @State sandboxDirectoryPath: string = ""; // 沙箱目录路径
  @State rawFileDescriptor: resourceManager.RawFileDescriptor | null = null; // rawfile压缩包描述符
  private sandboxManager = SandboxFileManager.getInstance();

  async aboutToAppear(): Promise<void> {
    this.context = getContext(this) as common.UIAbilityContext;
    // 初始化RTC引擎（但未加入频道）
    this.initAndSetupRtcEngine();
    this.sandboxManager.initialize(this.context);

    this.initConfigFiles();
  }

  private initConfigFiles(): void {
    this.sandboxManager = SandboxFileManager.getInstance();

    // 拷贝配置文件到沙箱
    try {
      // 拷贝应用配置文件
      this.sandboxManager.copyRawFileToSandbox('music.wav');
      this.sandboxManager.copyRawFileToSandbox('thunder.wav');
      this.sandboxManager.copyRawFileToSandbox('applause.wav');

    } catch (error) {
      console.error('初始化配置文件失败:', error);
    }
  }

  aboutToDisappear(): void {
    this.destroyRtcEngine();
  }

  build() {
    NavDestination() {
      Column() {
        CustomTitle({
          titleText: '播放伴奏和音效',
        })

        Column() {
          Row() {
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

            // 加入/离开房间按钮
            Text(this.initRoom ? '挂断' : '加入房间')
              .textAlign(TextAlign.Center)
              .fontSize(16)
              .backgroundColor('#590ce4')
              .fontColor(Color.White)
              .width(80)
              .height(48)
              .margin({
                left: 10,
                right: 10
              })
              .borderRadius(8)
              .onClick(async () => {
                await this.handleJoinRoom();
              })
          }
          .margin({ top: 20 })
          .height(50)

          Scroll() {
            Column() {
              Row() {
                Text(this.accompanimentFile)
                  .fontSize(16)
                  .fontColor('#333')
                  .width(80)
                  .layoutWeight(1)

                Button('获取音频文件信息')
                  .type(ButtonType.Normal)
                  .layoutWeight(1)
                  .backgroundColor("#590ce4")
                  .fontColor(Color.White)
                  .onClick(() => {
                    this.getAudioFileInfo();
                  })
              }.width('100%')
              .margin({ bottom: 8 })

              // 伴奏区域
              Column() {
                // 伴奏标题栏（可点击折叠/展开）
                Row() {
                  Text('伴奏')
                    .fontSize(18)
                    .fontColor('#333')
                    .fontWeight(FontWeight.Bold)
                  Image(this.accompanimentExpanded ? $r('app.media.arrow_up') :
                    $r('app.media.arrow_down'))
                    .width(24)
                    .height(24)

                }
                .onClick(() => {
                  this.accompanimentExpanded = !this.accompanimentExpanded;
                })
                .width('100%')
                .height(50)
                .backgroundColor('#ffffff')
                .borderRadius(8)
                .padding({ left: 12, right: 12 })
                .alignItems(VerticalAlign.Center)

                if (this.accompanimentExpanded) {
                  Column() {
                    // 伴奏音乐文件
                    Row() {
                      Text('伴奏音乐文件:')
                        .fontSize(16)
                        .fontColor('#333')
                        .width(120)
                      Blank().layoutWeight(1)

                      Text(this.accompanimentFile)
                        .fontSize(16)
                        .fontColor('#666')
                        .layoutWeight(1)
                        .margin({ left: 10 })
                    }
                    .width('100%')
                    .height(40)
                    .margin({ top: 10 })

                    // 音量调节
                    this.buildVolumeControl('音量:', this.accompanimentVolume, (value: number) => {
                      this.accompanimentVolume = value;
                      this.setAudioAccompanyVolume(value);
                    })

                    // 推流音量
                    this.buildVolumeControl('推流音量:', this.pushVolume, (value: number) => {
                      this.pushVolume = value;
                      this.setAudioAccompanyPublishVolume(value);
                    })

                    // 播放音量
                    this.buildVolumeControl('播放音量:', this.playVolume, (value: number) => {
                      this.playVolume = value;
                      this.setAudioAccompanyPlayoutVolume(value);
                    })

                    // 循环播放设置
                    Row() {
                      Text('循环播放:')
                        .fontSize(16)
                        .fontColor('#333')
                        .width(80)

                      TextInput({ text: this.loopCount, placeholder: "-1(无限循环) or >0" })
                        .layoutWeight(1)
                        .height(40)
                        .backgroundColor('#fff')
                        .fontColor('#333')
                        .border({
                          width: {
                            top: 0,
                            right: 0,
                            bottom: 1,
                            left: 0
                          },
                          color: '#000',
                          radius: 0
                        })
                        .margin({ left: 10 })
                        .onChange((text: string) => {
                          this.loopCount = text;
                        })
                    }
                    .width('100%')
                    .height(50)
                    .margin({ top: 10 })

                    // 播放进度
                    Row() {
                      Text('播放进度:')
                        .fontSize(16)
                        .fontColor('#333')
                        .width(80)

                      Slider({
                        value: this.playProgress,
                        min: 0,
                        max: this.audioDuration > 0 ? this.audioDuration : 100
                      })
                        .blockColor('#05d8c5')
                        .selectedColor('#05d8c5')
                        .onChange((value: number) => {
                          this.playProgress = value;
                          this.setAudioAccompanyPosition(value);
                        })
                        .layoutWeight(1.5)
                        .showTips(true)
                        .margin({ left: 10 })
                    }
                    .width('100%')
                    .height(36)
                    .margin({ top: 10 })

                    // 控制按钮
                    Row() {
                      Button('开始')
                        .type(ButtonType.Normal)
                        .backgroundColor('#00fdfdfb')
                        .fontColor('#30839b')
                        .layoutWeight(1)
                        .margin({ right: 10 })
                        .onClick(() => {
                          this.startAudioAccompany();
                        })

                      Button('暂停')
                        .type(ButtonType.Normal)
                        .backgroundColor('#00fdfdfb')
                        .fontColor('#30839b')
                        .layoutWeight(1)
                        .margin({ right: 10 })
                        .onClick(() => {
                          this.pauseAudioAccompany();
                        })

                      Button('恢复')
                        .type(ButtonType.Normal)
                        .backgroundColor('#00fdfdfb')
                        .fontColor('#30839b')
                        .layoutWeight(1)
                        .margin({ right: 10 })
                        .onClick(() => {
                          this.resumeAudioAccompany();
                        })

                      Button('停止')
                        .type(ButtonType.Normal)
                        .backgroundColor('#00fdfdfb')
                        .fontColor('#30839b')
                        .layoutWeight(1)
                        .onClick(() => {
                          this.stopAudioAccompany();
                        })
                    }
                    .width('100%')
                    .height(48)
                  }
                  .width('100%')
                  .padding({ left: 20, right: 20, bottom: 20 })
                  .backgroundColor('#ffffff')
                  .border({
                    width: 1,
                    color: '#e0e0e0',
                    radius: 4
                  })
                }
              }
              .width('100%')
              .margin({ bottom: 20 })

              // 音效区域
              Column() {
                // 音效标题栏（可点击折叠/展开）
                Row() {
                  Text('音效')
                    .fontSize(18)
                    .fontColor('#333')
                    .fontWeight(FontWeight.Bold)
                  Image(this.soundEffectExpanded ? $r('app.media.arrow_up') :
                    $r('app.media.arrow_down'))
                    .width(24)
                    .height(24)
                }
                .onClick(() => {
                  this.soundEffectExpanded = !this.soundEffectExpanded;
                })
                .width('100%')
                .height(50)
                .backgroundColor('#ffffff')
                .borderRadius(8)
                .padding({ left: 12, right: 12 })
                .alignItems(VerticalAlign.Center)

                // 音效内容区域
                if (this.soundEffectExpanded) {
                  Column() {
                    // 音效文件选择
                    Row() {
                      Text('音效文件:')
                        .fontSize(16)
                        .fontColor('#333')
                        .width(80)

                      Select(this.soundEffectOptions.map((option: string) => {
                        return { value: option } as ISelectOption;
                      }))
                        .selected(this.soundEffectOptions.indexOf(this.selectedSoundEffect))
                        .value(this.selectedSoundEffect)
                        .backgroundColor('#fff')
                        .fontColor('#333')
                        .layoutWeight(1)
                        .margin({ left: 10 })
                        .onSelect((index: number) => {
                          if (index >= 0 && index < this.soundEffectOptions.length) {
                            this.selectedSoundEffect = this.soundEffectOptions[index];
                            this.currSoundID = index + 1; // 更新当前音效ID
                          }
                        })
                    }
                    .width('100%')
                    .height(50)
                    .margin({ top: 10 })

                    // 音量调节
                    this.buildVolumeControl('音量:', this.soundEffectVolume, (value: number) => {
                      this.soundEffectVolume = value;
                      this.setAudioEffectVolume(this.currSoundID, value);
                    })

                    // 播放次数
                    Row() {
                      Text('播放次数:')
                        .fontSize(16)
                        .fontColor('#333')
                        .width(80)

                      TextInput({ text: this.playCount })
                        .layoutWeight(1)
                        .height(40)
                        .backgroundColor('#fff')
                        .fontColor('#333')
                        .border({
                          width: {
                            top: 0,
                            right: 0,
                            bottom: 1,
                            left: 0
                          },
                          color: '#000',
                          radius: 0
                        })
                        .margin({ left: 10 })
                        .onChange((text: string) => {
                          this.playCount = text;
                        })
                    }
                    .width('100%')
                    .height(50)
                    .margin({ top: 10 })

                    // 控制按钮 - 两行布局
                    Column() {
                      // 第一行：预加载和取消加载
                      Row() {
                        Button('预加载')
                          .type(ButtonType.Normal)
                          .backgroundColor('#00fdfdfb')
                          .fontColor('#30839b')
                          .layoutWeight(1)
                          .margin({ right: 10 })
                          .onClick(() => {
                            this.preloadAudioEffect();
                          })

                        Button('取消加载')
                          .type(ButtonType.Normal)
                          .backgroundColor('#00fdfdfb')
                          .fontColor('#30839b')
                          .layoutWeight(1)
                          .onClick(() => {
                            this.unloadAudioEffect();
                          })
                      }
                      .width('100%')
                      .height(48)

                      // 第二行：开始、暂停、恢复、停止
                      Row() {
                        Button('开始')
                          .type(ButtonType.Normal)
                          .backgroundColor('#00fdfdfb')
                          .fontColor('#30839b')
                          .layoutWeight(1)
                          .margin({ right: 10 })
                          .onClick(() => {
                            this.playAudioEffect();
                          })

                        Button('暂停')
                          .type(ButtonType.Normal)
                          .backgroundColor('#00fdfdfb')
                          .fontColor('#30839b')
                          .layoutWeight(1)
                          .margin({ right: 10 })
                          .onClick(() => {
                            this.pauseAudioEffect(this.currSoundID);
                          })

                        Button('恢复')
                          .type(ButtonType.Normal)
                          .backgroundColor('#00fdfdfb')
                          .fontColor('#30839b')
                          .layoutWeight(1)
                          .margin({ right: 10 })
                          .onClick(() => {
                            this.resumeAudioEffect(this.currSoundID);
                          })

                        Button('停止')
                          .type(ButtonType.Normal)
                          .backgroundColor('#00fdfdfb')
                          .fontColor('#30839b')
                          .layoutWeight(1)
                          .onClick(() => {
                            this.stopAudioEffect(this.currSoundID);
                          })
                      }
                      .width('100%')
                      .height(48)

                      // 所有音效音量控制
                      this.buildVolumeControl('所有音效音量:', this.soundEffectLiangVolume, (value: number) => {
                        this.soundEffectLiangVolume = value;
                        this.setAllAudioEffectsVolume(value);
                      })

                      // 所有音效控制
                      Row() {
                        Button('停止所有')
                          .type(ButtonType.Normal)
                          .backgroundColor('#00fdfdfb')
                          .fontColor('#30839b')
                          .layoutWeight(1)
                          .margin({ right: 10 })
                          .onClick(() => {
                            this.stopAllAudioEffect();
                          })

                        Button('暂停所有')
                          .type(ButtonType.Normal)
                          .backgroundColor('#00fdfdfb')
                          .fontColor('#30839b')
                          .layoutWeight(1)
                          .margin({ right: 10 })
                          .onClick(() => {
                            this.pauseAllAudioEffects();
                          })

                        Button('恢复所有')
                          .type(ButtonType.Normal)
                          .backgroundColor('#00fdfdfb')
                          .fontColor('#30839b')
                          .layoutWeight(1)
                          .margin({ right: 10 })
                          .onClick(() => {
                            this.resumeAllAudioEffects();
                          })
                      }
                      .width('100%')
                      .height(48)
                    }
                    .width('100%')
                    .margin({ top: 20 })
                  }
                  .width('100%')
                  .padding({ left: 20, right: 20, bottom: 20 })
                  .backgroundColor('#ffffff')
                  .border({
                    width: 1,
                    color: '#e0e0e0',
                    radius: 4
                  })
                }
              }
              .width('100%')
              .margin({ bottom: 20 })

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
            .height('auto')
            .justifyContent(FlexAlign.Start)
          }
          .margin({ top: 20 })
          .width('100%')
          .align(Alignment.Top)
          .height('100%')
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
            .width('100')
            .height('100%')
            .onLoad(() => {
              this.setupLocalVideo();
            })
        }
        .backgroundColor('#000')
        .width('100%')
        .height('200vp')
      } else {
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


          Column() {
            // 用户ID和流类型标签
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
    .height('400vp')
    .margin({
      top: 20
    })
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
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

      // 配置视频画布 - 直接使用surfaceId
      if (!stream.canvas) {
        stream.canvas = new AliRtcVideoCanvas();
      }

      // 【关键】将surfaceId赋值给canvas
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

      this.startPreview()

      console.info('本地视频画布设置完成');

    } catch (error) {
      console.error('设置本地视频失败:', error);
    }
  }

  @Builder
  private buildVolumeControl(label: string, volume: number, onChange: (value: number) => void) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor('#333')
        .width(80)

      Slider({
        value: volume,
        min: 0,
        max: 100
      })
        .blockColor('#05d8c5')
        .selectedColor('#05d8c5')
        .onChange((isOn: number) => {
          onChange(isOn);
        })
        .layoutWeight(1.5)
        .showTips(true)
        .margin({ left: 10 })
    }
    .width('100%')
    .height(36)
    .margin({ top: 10 })
  }

  // ==================== RTC引擎相关方法 ====================

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

      // 设置Capture Pipeline Scale Mode
      this.rtcEngine.setCapturePipelineScaleMode(AliRtcCapturePipelineScaleMode.AliRtcCapturePipelineScaleModePost);

      // 设置视频编码配置
      const videoConfig: AliRtcVideoEncoderConfiguration = new AliRtcVideoEncoderConfiguration();
      videoConfig.dimensions.width = 720;
      videoConfig.dimensions.width = 1280;
      videoConfig.frameRate = 20;
      videoConfig.bitrate = 1200;
      videoConfig.keyFrameInterval = 2000;
      videoConfig.orientationMode = AliRtcVideoEncoderOrientationMode.AliRtcVideoEncoderOrientationModeAdaptive;
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

        this.hasJoined = true;
        this.initRoom = true;
      });

      this.rtcEventListener.onLeaveChannel((resultCode: number) => {
        console.info(`离开频道结果: result=${resultCode}`);
        prompt.showToast({
          message: 'Leave Channel',
          duration: 2000
        });
        this.hasJoined = false;
        this.initRoom = false;
      });

      this.rtcEventListener.onAudioPublishStateChanged((audioTrack: AliRtcAudioTrack, oldState: AliRtcPublishState,
        newState: AliRtcPublishState, elapseSinceLastState: number, channel: string) => {
        console.info(`音频发布状态变化: oldState=${oldState}, newState=${newState}, channel=${channel}`);

        if (newState === 3) {
          prompt.showToast({
            message: 'Audio Stream has been published!',
            duration: 2000
          });
        }
      });

      this.rtcEventListener.onConnectionStatusChange((status: number, reason: number) => {
        console.info(`连接状态变更: status=${status}, reason=${reason}`);

        if (status === AliRtcConnectionStatus.AliRtcConnectionFailed) {
          prompt.showToast({
            message: '连接失败',
            duration: 3000
          });
        }
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
      });

      this.rtcEventListener.onLocalDeviceException((deviceType: AliRtcLocalDeviceType, exceptionType: AliRtcLocalDeviceExceptionType,
        msg: string) => {
        console.error(`本地设备异常: deviceType=${deviceType}, exceptionType=${exceptionType}, msg=${msg}`);
        prompt.showToast({
          message: `设备异常: ${msg}`,
          duration: 3000
        });
      });

      this.rtcEventListener.onBye((code: number) => {
        console.info(`被服务器踢出: code=${code}`);
        prompt.showToast({
          message: `被服务器踢出: ${code}`,
          duration: 3000
        });
        this.destroyRtcEngine();
      });

      this.rtcEventListener.onAudioAccompanyStateChanged((playState: AliRtcAudioAccompanyStateCode,
        errorCode: AliRtcAudioAccompanyErrorCode) => {
        console.info(`伴奏状态变化: playState=${playState}, errorCode=${errorCode}`);
      });

      this.rtcEventListener.onRemoteAudioAccompanyStarted((uid: string) => {
        console.info(`远端用户开始播放伴奏: uid=${uid}`);
        prompt.showToast({
          message: `用户 ${uid} 开始播放伴奏`,
          duration: 2000
        });
      });

      this.rtcEventListener.onRemoteAudioAccompanyFinished((uid: string) => {
        console.info(`远端用户停止播放伴奏: uid=${uid}`);
        prompt.showToast({
          message: `用户 ${uid} 停止播放伴奏`,
          duration: 2000
        });
      });

      this.rtcEventListener.onAudioEffectFinished((soundId: number) => {
        console.info(`音效播放完成: soundId=${soundId}`);
        prompt.showToast({
          message: `音效 ${soundId} 播放完成`,
          duration: 2000
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

      const result = this.rtcEngine.joinChannelWithToken(base64Token, '', '', '播放伴奏和音效用户');
      console.info('加入频道调用结果:', result);

    } catch (error) {
      console.error('加入频道失败:', error);
    }
  }





  // 销毁RTC引擎
  private destroyRtcEngine(): void {
    if (this.rtcEngine) {
      try {
        // 停止预览
        this.rtcEngine.stopPreview();

        // 离开频道
        this.rtcEngine.leaveChannel();
        this.rtcEngine.stopAudioAccompany();
        this.stopAudioEffect(this.currSoundID);

        // 销毁引擎
        this.rtcEngine = undefined;


        prompt.showToast({
          message: 'Leave Channel',
          duration: 2000
        });

        console.info('RTC引擎已销毁');

      } catch (error) {
        console.error('销毁RTC引擎失败:', error);
      }
    }

    // 清理状态
    this.hasJoined = false;
    this.initRoom = false;
    this.ShowPreview = false;
    this.remoteVideoStreams = [];
    this.remoteViews.clear();
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
      await this.initAndSetupRtcEngine();

      // 开始本地预览
      this.startPreview();

      // 加入频道
      await this.joinChannel();

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

  // ==================== 伴奏相关方法 ====================

  // 开始伴奏
  private async startAudioAccompany(): Promise<void> {
    if (!this.rtcEngine) {
      prompt.showToast({ message: 'RTC引擎未初始化', duration: 2000 });
      return;
    }

    if (!this.hasJoined) {
      prompt.showToast({ message: 'RTC引擎未初始化', duration: 2000 });
      return;
    }

    try {
      // 获取循环次数
      const loopCount = this.loopCount.trim() === '' ? -1 : parseInt(this.loopCount);
      const publishVolume = this.pushVolume;
      const playbackVolume = this.playVolume;

      // 创建伴奏配置
      const config: AliRtcAudioAccompanyConfig = new AliRtcAudioAccompanyConfig();
      config.loopCycles = loopCount;
      config.publishVolume = publishVolume;
      config.playoutVolume = playbackVolume;
      config.startPosMs = 0;

      const audioPath = this.sandboxManager.getSandboxFilePath(this.accompanimentFile);

      this.rtcEngine.startAudioAccompany(audioPath, config);

      // 获取音频时长并更新进度条
      const audioDuration = this.rtcEngine.getAudioAccompanyDuration(); // ms
      if (audioDuration > 0) {
        this.audioDuration = audioDuration;
      }

      console.info('开始播放伴奏');

    } catch (error) {
      console.error('播放背景音乐异常:', error);
      prompt.showToast({ message: '播放背景音乐异常', duration: 2000 });
    }
  }

  // 停止伴奏
  private stopAudioAccompany(): void {
    if (!this.rtcEngine) {
      prompt.showToast({ message: 'RTC引擎未初始化', duration: 2000 });
      return;
    }
    this.rtcEngine.stopAudioAccompany();
    console.info('停止播放伴奏');
  }

  // 暂停伴奏
  private pauseAudioAccompany(): void {
    if (!this.rtcEngine) {
      prompt.showToast({ message: 'RTC引擎未初始化', duration: 2000 });
      return;
    }
    this.rtcEngine.pauseAudioAccompany();
    console.info('暂停播放伴奏');
  }

  // 恢复伴奏
  private resumeAudioAccompany(): void {
    if (!this.rtcEngine) {
      prompt.showToast({ message: 'RTC引擎未初始化', duration: 2000 });
      return;
    }
    this.rtcEngine.resumeAudioAccompany();
    console.info('恢复播放伴奏');
  }

  // 设置伴奏音量
  private setAudioAccompanyVolume(volume: number): void {
    if (this.rtcEngine && this.hasJoined) {
      this.rtcEngine.setAudioAccompanyVolume(volume);
    }
  }

  // 设置伴奏推流音量
  private setAudioAccompanyPublishVolume(volume: number): void {
    if (this.rtcEngine && this.hasJoined) {
      this.rtcEngine.setAudioAccompanyPublishVolume(volume);
    }
  }

  // 设置伴奏播放音量
  private setAudioAccompanyPlayoutVolume(volume: number): void {
    if (this.rtcEngine && this.hasJoined) {
      this.rtcEngine.setAudioAccompanyPlayOutVolume(volume);
    }
  }

  // 设置伴奏播放位置
  private setAudioAccompanyPosition(position: number): void {
    if (this.rtcEngine && this.hasJoined) {
      if (position >= 0 && position <= this.audioDuration) {
        this.rtcEngine.setAudioAccompanyPosition(position);
      }
    }
  }

  // 获取音频文件信息
  private getAudioFileInfo(): void {
    if (!this.rtcEngine) {
      prompt.showToast({ message: '请先初始化AliRtcEngine', duration: 2000 });
      return;
    }

    // 文件路径 - 使用本地资源
    const audioPath = this.sandboxManager.getSandboxFilePath(this.accompanimentFile);

    this.rtcEngine.preloadAudioEffect(1, audioPath);
    console.info('获取音频文件信息:', audioPath);
  }

  // 获取流类型文本
  private getTrackTypeText(track: AliRtcVideoTrack): string {
    switch (track) {
      case AliRtcVideoTrack.AliRtcVideoTrackCamera:
        return '-Camera';
      case AliRtcVideoTrack.AliRtcVideoTrackScreen:
        return '屏幕共享';
      case AliRtcVideoTrack.AliRtcVideoTrackBoth:
        return '双流';
      default:
        return '未知';
    }
  }

  // ==================== 音效相关方法 ====================

  // 预加载音效
  private preloadAudioEffect(): void {
    if (!this.rtcEngine) {
      prompt.showToast({ message: 'RTC引擎未初始化', duration: 2000 });
      return;
    }

    if (!this.hasJoined) {
      prompt.showToast({ message: 'RTC引擎未初始化', duration: 2000 });
      return;
    }

    const filePath = this.currSoundID === 1 ? this.audioEffectFilePath1 : this.audioEffectFilePath2;
    this.rtcEngine.preloadAudioEffect(this.currSoundID, filePath);
    prompt.showToast({ message: `预加载音效 ${this.currSoundID}`, duration: 2000 });
  }

  // 取消加载音效
  private unloadAudioEffect(): void {
    if (!this.rtcEngine) {
      prompt.showToast({ message: 'RTC引擎未初始化', duration: 2000 });
      return;
    }

    this.rtcEngine.unloadAudioEffect(this.currSoundID);
    prompt.showToast({ message: `取消加载音效 ${this.currSoundID}`, duration: 2000 });
  }

  // 播放音效
  private playAudioEffect(): void {
    if (!this.rtcEngine) {
      prompt.showToast({ message: 'RTC引擎未初始化', duration: 2000 });
      return;
    }

    if (!this.hasJoined) {
      prompt.showToast({ message: 'RTC引擎未初始化', duration: 2000 });
      return;
    }

    try {
      const filePath = this.currSoundID === 1 ? this.audioEffectFilePath1 : this.audioEffectFilePath2;

      // 获取循环次数
      const loopCount = this.playCount.trim() === '' ? 1 : parseInt(this.playCount);

      const config: AliRtcAudioEffectConfig = new AliRtcAudioEffectConfig();
      config.loopCycles = loopCount;
      config.startPosMs = 0;
      config.publishVolume = this.soundEffectVolume;
      config.playoutVolume = this.soundEffectVolume;
      const audioPath = this.sandboxManager.getSandboxFilePath(filePath);

      this.rtcEngine.playAudioEffect(this.currSoundID, audioPath, config);
      prompt.showToast({ message: `播放音效 ${this.currSoundID}`, duration: 2000 });
    } catch (error) {
      console.error('播放音效异常:', error);
      prompt.showToast({ message: `播放音效异常: ${error}`, duration: 2000 });
    }
  }

  // 停止音效
  private stopAudioEffect(soundId: number): void {
    if (!this.rtcEngine) {
      prompt.showToast({ message: 'RTC引擎未初始化', duration: 2000 });
      return;
    }

    this.rtcEngine.stopAudioEffect(soundId);
    prompt.showToast({ message: `停止音效 ${soundId}`, duration: 2000 });
  }

  // 停止所有音效
  private stopAllAudioEffect(): void {
    if (!this.rtcEngine) {
      prompt.showToast({ message: 'RTC引擎未初始化', duration: 2000 });
      return;
    }

    this.rtcEngine.stopAllAudioEffects();
    prompt.showToast({ message: '停止所有音效', duration: 2000 });
  }

  // 暂停音效
  private pauseAudioEffect(soundId: number): void {
    if (!this.rtcEngine) {
      prompt.showToast({ message: 'RTC引擎未初始化', duration: 2000 });
      return;
    }

    this.rtcEngine.pauseAudioEffect(soundId);
    prompt.showToast({ message: `暂停音效 ${soundId}`, duration: 2000 });
  }

  // 暂停所有音效
  private pauseAllAudioEffects(): void {
    if (!this.rtcEngine) {
      prompt.showToast({ message: 'RTC引擎未初始化', duration: 2000 });
      return;
    }
    this.rtcEngine.pauseAllAudioEffects();
    prompt.showToast({ message: '暂停所有音效', duration: 2000 });
  }

  // 恢复音效
  private resumeAudioEffect(soundId: number): void {
    if (!this.rtcEngine) {
      prompt.showToast({ message: 'RTC引擎未初始化', duration: 2000 });
      return;
    }
    this.rtcEngine.resumeAudioEffect(soundId);
    prompt.showToast({ message: `恢复音效 ${soundId}`, duration: 2000 });
  }

  // 恢复所有音效
  private resumeAllAudioEffects(): void {
    if (!this.rtcEngine) {
      prompt.showToast({ message: 'RTC引擎未初始化', duration: 2000 });
      return;
    }
    this.rtcEngine.resumeAllAudioEffects();
    prompt.showToast({ message: '恢复所有音效', duration: 2000 });
  }

  // 设置音效音量
  private setAudioEffectVolume(soundId: number, volume: number): void {
    if (this.rtcEngine && this.hasJoined) {
      this.rtcEngine.setAudioEffectPublishVolume(soundId, volume);
      this.rtcEngine.setAudioEffectPlayOutVolume(soundId, volume);
    }
  }

  // 设置所有音效音量
  private setAllAudioEffectsVolume(volume: number): void {
    if (this.rtcEngine && this.hasJoined) {
      this.rtcEngine.setAllAudioEffectsPlayoutVolume(volume);
      this.rtcEngine.setAllAudioEffectsPublishVolume(volume);
    }
  }

  // ==================== 远端视频相关方法 ====================

  // 查看远端视频
  private viewRemoteVideo(uid: string, videoTrack: AliRtcVideoTrack): void {
    console.info(`查看远端视频: ${uid} - ${videoTrack}`);

    // 检查是否已存在相同的流
    const streamKey = this.getStreamKey(uid, videoTrack);

    if (this.remoteViews.has(streamKey)) {
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

    // 添加到Map和数组
    this.remoteViews.set(streamKey, newStream);
    this.remoteVideoStreams.push(newStream);

    console.info(`添加远端视频成功: ${uid} - ${videoTrack}`);
  }

  // 移除远端视频
  private removeRemoteVideo(uid: string, videoTrack: AliRtcVideoTrack): void {
    console.info(`移除远端视频: ${uid} - ${videoTrack}`);

    const streamKey = this.getStreamKey(uid, videoTrack);

    if (this.remoteViews.has(streamKey)) {
      const stream = this.remoteViews.get(streamKey);
      if (stream) {
        // 从数组中移除
        const index = this.remoteVideoStreams.findIndex(
          s => s.uid === uid && s.videoTrack === videoTrack
        );
        if (index >= 0) {
          this.remoteVideoStreams.splice(index, 1);
        }

        // 从Map中移除
        this.remoteViews.delete(streamKey);
        console.info(`移除远端视频成功: ${uid} - ${videoTrack}`);
      }
    }
  }

  // 移除用户的所有视频
  private removeAllRemoteVideo(uid: string): void {
    console.info(`移除用户所有视频: ${uid}`);

    // 移除摄像头流
    this.removeRemoteVideo(uid, AliRtcVideoTrack.AliRtcVideoTrackCamera);

    // 移除屏幕共享流
    this.removeRemoteVideo(uid, AliRtcVideoTrack.AliRtcVideoTrackScreen);

    console.info(`移除用户所有视频成功: ${uid}`);
  }

  // 根据流类型获取唯一标识
  private getStreamKey(uid: string, videoTrack: AliRtcVideoTrack): string {
    return `${uid}_${videoTrack}`;
  }

  // 判断是否显示多人网格布局
  private shouldShowGridLayout(): boolean {
    return this.ShowPreview && this.remoteVideoStreams.length > 0;
  }
}