import { ModuleInfo } from "../model/ModuleInfo";
import { ModuleManager } from "../model/ModuleManager";
import { ConstantsData } from 'common/src/main/ets/common/ConstantsData';

// 跳转模块声明
export class ModuleRegistry {
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

  private static registerBasicFunctionModules(manager: ModuleManager): void {
    manager.registerModule(new ModuleInfo(
      'basic_functions',
      '基础功能(未实现)',
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
      'pages/ScreenSharePage'
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

  private static registerAdvancedFunctionModules(manager: ModuleManager): void {
    manager.registerModule(new ModuleInfo(
      'advanced_functions',
      '进阶功能（未实现）',
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
      ConstantsData.CustomAudioRenderPage
    ));
    // 自定义视频播放
    manager.registerModule(new ModuleInfo(
      'raw_video_off',
      '自定义视频播放',
      'advanced_functions',
      3,
      ConstantsData.CustomAudioRenderPage
    ));
    // 自定义视频渲染
    manager.registerModule(new ModuleInfo(
      'raw_video_Render',
      '自定义视频渲染',
      'advanced_functions',
      3,
      ConstantsData.CustomAudioRenderPage
    ));
    // 自定义视频处理
    manager.registerModule(new ModuleInfo(
      'raw_video_dispose',
      '自定义视频处理',
      'advanced_functions',
      3,
      ConstantsData.CustomAudioRenderPage
    ));
  }
}