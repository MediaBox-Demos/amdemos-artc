import { ModuleManager } from '../model/ModuleManager';
import { ModuleInfo } from '../model/ModuleInfo';
import { SettingsDialog } from './SettingsDialog';
import { FunctionItemParam } from '../common/Constants';
import { common } from '@kit.AbilityKit';
import { PermissionManager } from '../common/utils/PermissionManager';
import { ConstantsData } from '../common/ConstantsData';
import { PageMap, PageStackCenter } from '../manager/PageStackCenter';
import { ARTCTokenHelper } from '../common/keycenter/ARTCTokenHelper';
import { promptAction } from '@kit.ArkUI';
import { GlobalConfig } from '../common/keycenter/GlobalConfig';

@Entry
@ComponentV2
struct Index {
  @Local level1Modules: ModuleInfo[] = []; // 一级标题
  @Local level2Modules: ModuleInfo[] = []; // 二级标题
  @Local level3Modules: ModuleInfo[] = []; // 功能项
  @Local appId: string = '';
  @Local appKey: string = '';
  @Local userId: string = '';
  @Local sdkVersion: string = '';
  @Local sdkRegion: number = 0;
  @Provider('pageInfo') pageStack: NavPathStack = PageStackCenter.getInstance().getStack()
  // 权限管理器实例
  private permissionManager: PermissionManager = PermissionManager.getInstance();
  settingsDialogController: CustomDialogController = new CustomDialogController({
    builder: SettingsDialog(),
    alignment: DialogAlignment.Center,
    offset: { dx: 0, dy: 0 },
    customStyle: true
  });

  async aboutToAppear(): Promise<void> {
    this.loadModules();
    try {
      AppStorage.SetOrCreate('pageInfo', this.pageStack)
    } catch (err) {
      console.error('Failed to load settings:', err);
    }

  }

  loadModules(): void {
    const manager = ModuleManager.getInstance();

    // 获取不同层级的模块
    this.level1Modules = manager.getModulesByLevel(1);
    this.level2Modules = manager.getModulesByLevel(2);
    this.level3Modules = manager.getModulesByLevel(3);
  }

  build(): void {
    Navigation(this.pageStack) {
      Column() {
        // 页面标题
        Row() {
          Text('ARTCExample')
            .fontSize(22)
            .fontColor('#ffffff')

          Blank()
            .layoutWeight(1)

          // 设置图标
          Image($r('app.media.setting'))
            .width(26)
            .height(26)
            .onClick(() => {
              this.settingsDialogController.open();
            })
        }
        .width('100%')
        .padding(20)
        .backgroundColor('#590ce4')
        .justifyContent(FlexAlign.Start)

        // 内容区域
        Scroll() {
          Column() {
            // 快速开始部分
            this.QuickStartSection()

            // 基础功能部分
            this.BasicFunctionsSection()

            // 进阶功能部分
            this.AdvancedFunctionsSection()
          }
          .width('100%')
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
    }
    .hideTitleBar(true)
    .navDestination(PageMap)
    .mode(NavigationMode.Stack)
    .width('100%')
    .height('100%')
    .id('mainNav')
  }

  // 获取相关的模块
  private getRouterModules(category: string): ModuleInfo[] {
    const manager = ModuleManager.getInstance();
    return manager.getModulesByCategory(category)
      .filter((module: ModuleInfo) => module.level === 3); // 只获取功能项
  }

  @Builder
  QuickStartSection() {
    Column() {
      // 一级标题
      Text('快速开始')
        .fontSize(14)
        .fontColor('#a6a6a6')
        .width('100%')
        .margin({
          top: 16,
          bottom: 12,
          right: 16
        })
        .padding({
          left: 20
        })
      Blank()
        .height(0.5)
        .backgroundColor('#b7b7b7')

      ForEach(this.getRouterModules('quick_start'), (module: ModuleInfo) => {
        this.FunctionItem({
          id: module.id,
          name: module.name,
          level: module.level,
          category: module.category,
          targetPage: module.targetPage
        })
      })
    }
    .width('100%')
  }

  @Builder
  BasicFunctionsSection() {
    Column() {
      // 一级标题
      Text('基础功能')
        .fontSize(14)
        .fontColor('#a6a6a6')
        .width('100%')
        .margin({
          top: 16,
          bottom: 12,
          right: 16
        })
        .padding({
          left: 20
        })
      Blank()
        .height(0.5)
        .backgroundColor('#b7b7b7')

      ForEach(this.getRouterModules('basic_functions'), (module: ModuleInfo) => {
        this.FunctionItem({
          id: module.id,
          name: module.name,
          level: module.level,
          category: module.category,
          targetPage: module.targetPage
        })
      })
    }
    .width('100%')
  }

  @Builder
  AdvancedFunctionsSection() {
    Column() {
      // 一级标题
      Text('进阶功能')
        .fontSize(14)
        .fontColor('#a6a6a6')
        .width('100%')
        .margin({
          top: 16,
          bottom: 12,
          right: 16
        })
        .padding({
          left: 20
        })
      Blank()
        .height(0.5)
        .backgroundColor('#b7b7b7')

      ForEach(this.getRouterModules('advanced_functions'), (module: ModuleInfo) => {
        this.FunctionItem({
          id: module.id,
          name: module.name,
          level: module.level,
          category: module.category,
          targetPage: module.targetPage
        })
      })
    }
    .width('100%')
  }

  @Builder
  FunctionItem(module: FunctionItemParam) {
    Column() {
      Row() {
        // 文本内容
        Column() {
          Text(module.name)
            .fontSize(16)
            .fontColor('#182431')
            .textAlign(TextAlign.Start)
            .width('100%')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
      .borderRadius(0)
      .onClick(() => {
        this.navigateToModule(module);
      })

      Blank()
        .height(0.5)
        .backgroundColor('#a4a4a4')
    }
    .height('auto')
  }

  /**
   * 跳转到模块页面
   * 使用权限管理工具类处理权限检查
   */
  async navigateToModule(module: FunctionItemParam): Promise<void> {
    const context = getContext() as common.UIAbilityContext;
    const validPageNames: Set<string> = new Set([
      ConstantsData.TokenGenerate,
      ConstantsData.VideoCall,
      ConstantsData.VoiceChat,
      ConstantsData.AudioBasicUsage,
      ConstantsData.VideoBasicUsage,
      ConstantsData.ProcessAudioRawDataPage,
      ConstantsData.ProcessVideoRawDataPage,
      ConstantsData.CustomAudioCapturePage,
      ConstantsData.CustomAudioRenderPage,
      ConstantsData.CameraPage,
      ConstantsData.SEIPage,
      ConstantsData.DataChannelMessagePage,
      ConstantsData.StreamMonitoringPage,
      ConstantsData.VoiceChangePage,
      ConstantsData.PlayAudioFilesPage,
      ConstantsData.ScreenSharePage,
      ConstantsData.CustomVideoCapturePage,
      ConstantsData.CustomVideoRenderPage,
      ConstantsData.PictureInPicturePage,
      ConstantsData.RecordingPage,
      ConstantsData.PreJoinChannelTestPage,
      ConstantsData.HEVCPage,
      ConstantsData.PublishLiveStreamPage,
      ConstantsData.LiveLinkMicPage,
      ConstantsData.OriginAudioDataWrap,
      ConstantsData.OriginVideoDataWrap,
    ]);

    if (!module.targetPage || !validPageNames.has(module.targetPage)) {
      console.error(`无法跳转：未知的目标页面 "${module.targetPage}"`);
      return;
    }

    // 确保 targetPage 不为 undefined
    const targetPage: string = module.targetPage;

    // 新增：检查 AppId 和 AppKey 是否为空
    const global: GlobalConfig = GlobalConfig.getInstance();
    const appId: string = await global.getAppId();
    const appKey: string = await global.getAppKey();
    if (!appId || appId.trim().length === 0 || !appKey || appKey.trim().length === 0) {
      promptAction.showToast({
        message: '请点击右上角设置，填写 AppId 和 AppKey 参数',
        duration: 2000
      });
      return;
    }

    try {
      // 使用权限管理器的综合方法检查并申请权限
      const hasPermission: boolean = await this.permissionManager.checkAndRequestMicrophoneAndCameraPermission(context);

      if (hasPermission) {
        // 权限已授权，跳转到目标页面
        PageStackCenter.getInstance().pushPath({
          name: targetPage,
        })
      } else {
        // 权限被拒绝，显示提示
        this.permissionManager.showPermissionDeniedToast();
      }
    } catch (err) {
      console.error('权限处理失败:', err);
      this.permissionManager.showPermissionDeniedToast();
    }
  }
}