/**
 * 模块注册中心
 * 负责在应用启动时注册所有功能模块到 ModuleManager
 * 定义了首页展示的所有功能模块的配置信息
 */
import { ModuleInfo } from './ModuleInfo';
import { ModuleManager } from './ModuleManager';
import { ConstantsData } from '../common/ConstantsData';

export class ModuleRegistry {
  /**
   * 注册所有功能模块
   * 在应用启动时（EntryAbility.onCreate）调用
   */
  public static registerAllModules(): void {
    const manager = ModuleManager.getInstance();

    // 注册快速开始模块
    ModuleRegistry.registerQuickStartModules(manager);

    // 注册视频通话模块
    ModuleRegistry.registerVideoCallModules(manager);

    // 注册基础功能模块
    ModuleRegistry.registerBasicFunctionModules(manager);

    // 注册进阶功能模块
    ModuleRegistry.registerAdvancedFunctionModules(manager);
  }

  /**
   * 注册"快速开始"分类及其功能项
   * 包含 Token 生成、视频通话、语聊房等快速入门功能
   */
  private static registerQuickStartModules(manager: ModuleManager): void {
    manager.registerModule(new ModuleInfo(
      'quick_start',
      '快速开始',
      '',
      1
    ));

    manager.registerModule(new ModuleInfo(
      'token_join',
      'Token生成及入会',
      'quick_start',
      3,
      ConstantsData.TokenGenerate
    ));
  }

  /**
   * 注册视频通话相关模块
   * 包含视频通话和语聊房功能
   */
  private static registerVideoCallModules(manager: ModuleManager): void {
    manager.registerModule(new ModuleInfo(
      'video_call',
      '实现视频通话',
      'quick_start',
      3,
      ConstantsData.VideoCall
    ));


    manager.registerModule(new ModuleInfo(
      'voice_chat',
      '语聊房功能',
      'quick_start',
      3,
      ConstantsData.VoiceChat
    ));
  }

  /**
   * 注册"基础功能"分类及其功能项
   * 包含音视频操作、摄像头控制、SEI、屏幕共享等常用功能
   */
  private static registerBasicFunctionModules(manager: ModuleManager): void {
    manager.registerModule(new ModuleInfo(
      'basic_functions',
      '基础功能',
      '',
      1
    ));

    // 音频操作
    manager.registerModule(new ModuleInfo(
      'audio_operations',
      '音频常用操作和配置',
      'basic_functions',
      3,
      ConstantsData.AudioBasicUsage
    ));

    // 视频操作
    manager.registerModule(new ModuleInfo(
      'video_operations',
      '视频常用操作和配置',
      'basic_functions',
      3,
      ConstantsData.VideoBasicUsage
    ));

    // 摄像头控制
    manager.registerModule(new ModuleInfo(
      'camera_control',
      '摄像头常规控制',
      'basic_functions',
      3,
      ConstantsData.CameraPage
    ));

    // SEI功能
    manager.registerModule(new ModuleInfo(
      'sei_operations',
      'SEI发送和接收',
      'basic_functions',
      3,
      ConstantsData.SEIPage
    ));

    // 自定义消息
    manager.registerModule(new ModuleInfo(
      'custom_message',
      '自定义消息发送和接收',
      'basic_functions',
      3,
      ConstantsData.DataChannelMessagePage
    ));

    // 屏幕共享
    manager.registerModule(new ModuleInfo(
      'screen_share',
      '屏幕共享',
      'basic_functions',
      3,
      ConstantsData.ScreenSharePage
    ));

    // 质量监测
    manager.registerModule(new ModuleInfo(
      'quality_monitor',
      '通话中推拉流质量监测',
      'basic_functions',
      3,
      ConstantsData.StreamMonitoringPage
    ));

    // 音效播放
    manager.registerModule(new ModuleInfo(
      'audio_effect',
      '播放伴奏和音效',
      'basic_functions',
      3,
      ConstantsData.PlayAudioFilesPage
    ));

    // 音效处理
    manager.registerModule(new ModuleInfo(
      'voice_effect',
      '设置变声、混响、美声',
      'basic_functions',
      3,
      ConstantsData.VoiceChangePage
    ));
  }

  /**
   * 注册"进阶功能"分类及其功能项
   * 包含原始数据处理、自定义采集渲染、画中画、录制等高级功能
   */
  private static registerAdvancedFunctionModules(manager: ModuleManager): void {
    manager.registerModule(new ModuleInfo(
      'advanced_functions',
      '进阶功能',
      '',
      1
    ));

    // 原始音频数据
    manager.registerModule(new ModuleInfo(
      'raw_audio',
      '原始音频数据',
      'advanced_functions',
      3,
      ConstantsData.ProcessAudioRawDataPage
    ));

    // 原始视频数据
    manager.registerModule(new ModuleInfo(
      'raw_video',
      '原始视频数据',
      'advanced_functions',
      3,
      ConstantsData.ProcessVideoRawDataPage
    ));

    // 原始音频数据 C++
    manager.registerModule(new ModuleInfo(
      'raw_audio_c++',
      '原始音频数据C++',
      'advanced_functions',
      3,
      ConstantsData.OriginAudioDataWrap
    ));

    // 原始视频数据 C++
    manager.registerModule(new ModuleInfo(
      'raw_video_c++',
      '原始视频数据C++',
      'advanced_functions',
      3,
      ConstantsData.OriginVideoDataWrap
    ));
    // 自定义音频采集
    manager.registerModule(new ModuleInfo(
      'raw_audio_info',
      '自定义音频采集',
      'advanced_functions',
      3,
      ConstantsData.CustomAudioCapturePage
    ));
    // 自定义音频播放
    manager.registerModule(new ModuleInfo(
      'raw_audio_off',
      '自定义音频播放',
      'advanced_functions',
      3,
      ConstantsData.CustomAudioRenderPage
    ));
    // 自定义视频采集
    manager.registerModule(new ModuleInfo(
      'raw_video_info',
      '自定义视频采集',
      'advanced_functions',
      3,
      ConstantsData.CustomVideoCapturePage
    ));
    // 自定义视频渲染
    manager.registerModule(new ModuleInfo(
      'raw_video_Render',
      '自定义视频渲染',
      'advanced_functions',
      3,
      ConstantsData.CustomVideoRenderPage
    ));
    // 自定义视频处理（鸿蒙不支持美颜，暂时下线）
    const rawVideoDisposeModule: ModuleInfo = new ModuleInfo(
      'raw_video_dispose',
      '自定义视频处理',
      'advanced_functions',
      3,
      ""
    );
    rawVideoDisposeModule.isAvailable = false;
    manager.registerModule(rawVideoDisposeModule);
    // 入会前测试
    manager.registerModule(new ModuleInfo(
      'pre_join_channel_test',
      '入会前测试',
      'advanced_functions',
      3,
      ConstantsData.PreJoinChannelTestPage
    ));
    // 画中画
    manager.registerModule(new ModuleInfo(
      'pip_video_dispose',
      '画中画',
      'advanced_functions',
      3,
      ConstantsData.PictureInPicturePage
    ));
    // H265
    manager.registerModule(new ModuleInfo(
      'hevc_page',
      'H265',
      'advanced_functions',
      3,
      ConstantsData.HEVCPage
    ));
    // 本地录制
    manager.registerModule(new ModuleInfo(
      'recording_dispose',
      '本地录制',
      'advanced_functions',
      3,
      ConstantsData.RecordingPage
    ));
    // 旁路转推
    manager.registerModule(new ModuleInfo(
      'publish_live_stream',
      '旁路转推',
      'advanced_functions',
      3,
      ConstantsData.PublishLiveStreamPage
    ));
    // 直播连麦
    manager.registerModule(new ModuleInfo(
      'live_link_mic',
      '直播连麦',
      'advanced_functions',
      3,
      ConstantsData.LiveLinkMicPage
    ));
  }
}