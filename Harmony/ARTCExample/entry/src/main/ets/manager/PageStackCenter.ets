/**
 * 页面导航栈管理中心
 * 单例模式，负责管理应用的页面导航栈和路由映射
 * 提供页面跳转、返回等导航能力
 */
import { ConstantsData } from '../common/ConstantsData';
import { TokenGenerate } from '../pages/quickstart/TokenGenerate';
import { VideoCall } from '../pages/quickstart/VideoCall';
import { VoiceChat } from '../pages/quickstart/VoiceChat';
import { AudioBasicUsage } from '../pages/basicusage/AudioBasicUsage';
import { VideoBasicUsage } from '../pages/basicusage/VideoBasicUsage';
import { CameraPage } from '../pages/basicusage/CameraPage';
import { SEIPage } from '../pages/basicusage/SEIPage';
import { DataChannelMessagePage } from '../pages/basicusage/DataChannelMessagePage';
import { StreamMonitoringPage } from '../pages/basicusage/StreamMonitoringPage';
import { VoiceChangePage } from '../pages/basicusage/VoiceChangePage';
import { PlayAudioFilesPage } from '../pages/basicusage/PlayAudioFilesPage';
import { ScreenSharePage } from '../pages/basicusage/ScreenSharePage';
import { ProcessAudioRawDataPage } from '../pages/advancedusage/ProcessAudioRawDataPage';
import { ProcessVideoRawDataPage } from '../pages/advancedusage/ProcessVideoRawDataPage';
import { CustomAudioCapturePage } from '../pages/advancedusage/CustomAudioCapturePage';
import { CustomAudioRenderPage } from '../pages/advancedusage/CustomAudioRenderPage';
import { CustomVideoCapturePage } from '../pages/advancedusage/CustomVideoCapturePage';
import { CustomVideoRenderPage } from '../pages/advancedusage/CustomVideoRenderPage';
import { PictureInPicturePage } from '../pages/advancedusage/PictureInPicturePage';
import { RecordingPage } from '../pages/advancedusage/RecordingPage';
import { PreJoinChannelTestPage } from '../pages/advancedusage/PreJoinChannelTestPage';
import { HEVCPage } from '../pages/advancedusage/HEVCPage';
import { PublishLiveStreamPage } from '../pages/advancedusage/PublishLiveStreamPage';
import { LiveLinkMicPage } from '../pages/advancedusage/LiveLinkMicPage';
import { OriginAudioDataWrap } from '../pages/advancedusage/OriginAudioDataWrap';
import { OriginVideoDataWrap } from '../pages/advancedusage/OriginVideoDataWrap';

/**
 * 页面导航栈管理类
 * 封装了 NavPathStack 的操作，统一管理页面跳转
 */
export class PageStackCenter {
  private static instance: PageStackCenter;
  navigationMode: NavigationMode = NavigationMode.Stack

  private constructor() {
  }

  public static getInstance(): PageStackCenter {
    if (!PageStackCenter.instance) {
      PageStackCenter.instance = new PageStackCenter();
    }
    return PageStackCenter.instance;
  }

  /** 导航栈实例 */
  private pageStack: NavPathStack = new NavPathStack()

  /**
   * 获取导航栈实例
   * @returns NavPathStack 导航栈
   */
  getStack(): NavPathStack {
    return this.pageStack
  }


  /**
   * 推入新页面到导航栈
   * @param info 页面路径信息
   * @param options 导航选项
   */
  pushPath(info: NavPathInfo, options?: NavigationOptions): void {
    this.pageStack.pushPath(info, options)
  }

  /**
   * 替换当前页面
   * @param info 页面路径信息
   * @param options 导航选项
   */
  replacePath(info: NavPathInfo, options?: NavigationOptions): void {
    this.pageStack.replacePath(info, options)
  }


  /**
   * 清空导航栈
   * @param animated 是否使用动画
   */
  clear(animated?: boolean) {
    this.pageStack.clear(animated)
  }

  /**
   * 返回上一页
   * @param result 返回结果
   * @param animated 是否使用动画
   */
  pop(result: object, animated?: boolean): void {
    this.pageStack.pop(result, animated);
  }
}

/**
 * 页面路由映射表
 * 根据页面名称返回对应的页面组件
 * 在 Navigation.navDestination() 中使用
 * @param name 页面标识（对应 ConstantsData 中的常量）
 */
@Builder
export function PageMap(name: string) {
  if (name === ConstantsData.TokenGenerate) {
    TokenGenerate()
  } else if (name === ConstantsData.VideoCall) {
    VideoCall()
  } else if (name === ConstantsData.VoiceChat) {
    VoiceChat()
  } else if (name === ConstantsData.AudioBasicUsage) {
    AudioBasicUsage()
  } else if (name === ConstantsData.VideoBasicUsage) {
    VideoBasicUsage()
  } else if (name === ConstantsData.CameraPage) {
    CameraPage()
  } else if (name === ConstantsData.SEIPage) {
    SEIPage()
  } else if (name === ConstantsData.DataChannelMessagePage) {
    DataChannelMessagePage()
  } else if (name === ConstantsData.StreamMonitoringPage) {
    StreamMonitoringPage()
  } else if (name === ConstantsData.VoiceChangePage) {
    VoiceChangePage()
  } else if (name === ConstantsData.PlayAudioFilesPage) {
    PlayAudioFilesPage()
  } else if (name === ConstantsData.ScreenSharePage) {
    ScreenSharePage()
  } else if (name === ConstantsData.ProcessAudioRawDataPage) {
    ProcessAudioRawDataPage()
  } else if (name === ConstantsData.ProcessVideoRawDataPage) {
    ProcessVideoRawDataPage()
  } else if (name === ConstantsData.CustomAudioCapturePage) {
    CustomAudioCapturePage()
  } else if (name === ConstantsData.CustomAudioRenderPage) {
    CustomAudioRenderPage()
  } else if (name === ConstantsData.CustomVideoCapturePage) {
    CustomVideoCapturePage()
  } else if (name === ConstantsData.CustomVideoRenderPage) {
    CustomVideoRenderPage()
  } else if (name === ConstantsData.PictureInPicturePage) {
    PictureInPicturePage()
  }else if (name === ConstantsData.RecordingPage) {
    RecordingPage()
  }else if (name === ConstantsData.HEVCPage) {
    HEVCPage()
  }else if (name === ConstantsData.PreJoinChannelTestPage) {
    PreJoinChannelTestPage()
  }else if (name === ConstantsData.PublishLiveStreamPage) {
    PublishLiveStreamPage()
  }else if (name === ConstantsData.LiveLinkMicPage) {
    LiveLinkMicPage()
  }else if (name === ConstantsData.OriginAudioDataWrap) {
    OriginAudioDataWrap()
  }else if (name === ConstantsData.OriginVideoDataWrap) {
    OriginVideoDataWrap()
  }
}