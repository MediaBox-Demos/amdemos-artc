import { common } from '@kit.AbilityKit';
import { PiPWindow, BuilderNode, FrameNode, NodeController, UIContext } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

export interface PipConfiguration {
  context: common.Context;
  componentController: XComponentController;
  contentWidth?: number;
  contentHeight?: number;
  navigationId?: string;
  customMessage?: string;
}

// 定义画中画状态监听器接口
export interface PipStateListener {
  onPipStateChange?(state: PiPWindow.PiPState, reason: string): void;

  onPipActionEvent?(event: PiPWindow.PiPActionEventType, status?: number): void;
}

// 页面适配器类 - 在页面级别使用
export class PagePipAdapter implements PipStateListener {
  private stateChangeCallback?: (state: PiPWindow.PiPState, reason: string) => void;
  private actionEventCallback?: (event: PiPWindow.PiPActionEventType, status?: number) => void;

  constructor(
    stateChangeCallback?: (state: PiPWindow.PiPState, reason: string) => void,
    actionEventCallback?: (event: PiPWindow.PiPActionEventType, status?: number) => void
  ) {
    this.stateChangeCallback = stateChangeCallback;
    this.actionEventCallback = actionEventCallback;
  }

  onPipStateChange(state: PiPWindow.PiPState, reason: string): void {
    this.stateChangeCallback?.(state, reason);
  }

  onPipActionEvent(event: PiPWindow.PiPActionEventType, status?: number): void {
    this.actionEventCallback?.(event, status);
  }
}

export class PictureInPictureManager {
  private pipController: PiPWindow.PiPController | undefined;
  private isPipAvailable: boolean = false;
  private listeners: PipStateListener[] = [];

  // 初始化管理器
  constructor() {
    this.checkPipAvailability();
  }

  // 检查设备是否支持画中画
  private checkPipAvailability(): void {
    this.isPipAvailable = PiPWindow.isPiPEnabled();
    if (!this.isPipAvailable) {
      console.warn('当前设备不支持画中画功能');
    }
  }

  // 添加状态监听器
  addStateListener(listener: PipStateListener): void {
    this.listeners.push(listener);
  }

  // 移除状态监听器
  removeStateListener(listener: PipStateListener): void {
    const index = this.listeners.indexOf(listener);
    if (index >= 0) {
      this.listeners.splice(index, 1);
    }
  }

  // 通知状态变化
  private notifyStateChange(state: PiPWindow.PiPState, reason: string): void {
    this.listeners.forEach(listener => {
      listener.onPipStateChange?.(state, reason);
    });
  }

  // 通知操作事件
  private notifyActionEvent(event: PiPWindow.PiPActionEventType, status?: number): void {
    this.listeners.forEach(listener => {
      listener.onPipActionEvent?.(event, status);
    });
  }

  // 启动画中画
  async startPip(config: PipConfiguration): Promise<boolean> {
    if (!this.isPipAvailable) {
      console.error('设备不支持画中画');
      return false;
    }

    // 清理已有的控制器
    if (this.pipController) {
      await this.cleanup();
    }

    // 验证必要参数
    if (!config.context || !config.componentController) {
      console.error('画中画配置参数无效');
      return false;
    }

    // 获取surfaceId
    const surfaceId = config.componentController.getXComponentSurfaceId();
    if (!surfaceId) {
      console.error('XComponent surfaceId 无效');
      return false;
    }

    try {
      // 创建鸿蒙画中画配置
      const pipConfig: PiPWindow.PiPConfiguration = {
        context: config.context,
        componentController: config.componentController,
        templateType: PiPWindow.PiPTemplateType.VIDEO_PLAY,
        contentWidth: config.contentWidth || 150,
        contentHeight: config.contentHeight || 150,
      };

      if (config.navigationId) {
        pipConfig.navigationId = config.navigationId;
      }
      // 创建画中画控制器
      const controller = await PiPWindow.create(pipConfig);
      this.pipController = controller;

      // 初始化控制器
      this.initPipController();

      // 启动画中画
      await this.pipController.startPiP();

      console.info('画中画启动成功');
      return true;

    } catch (error) {
      console.error('启动画中画失败:', error);
      await this.cleanup();
      return false;
    }
  }

  // 停止画中画
  async stopPip(): Promise<boolean> {
    if (!this.pipController) {
      console.warn('画中画控制器不存在');
      return false;
    }

    try {
      await this.pipController.stopPiP();
      await this.cleanup();
      console.info('画中画已停止');
      return true;
    } catch (error) {
      console.error('停止画中画失败:', error);
      return false;
    }
  }

  // 更新内容尺寸
  updateContentSize(width: number, height: number): void {
    if (this.pipController) {
      this.pipController.updateContentSize(width, height);
    }
  }

  // 检查是否在画中画模式
  isInPipMode(): boolean {
    return !!this.pipController;
  }

  // 获取画中画控制器
  getPipController(): PiPWindow.PiPController | undefined {
    return this.pipController;
  }

  // 检查是否支持画中画
  isPipEnabled(): boolean {
    return this.isPipAvailable;
  }

  // 初始化画中画控制器
  private initPipController(): void {
    if (!this.pipController) {
      return;
    }

    // 设置自动启动（应用退到后台时自动开启画中画）
    this.pipController.setAutoStartEnabled(false);

    // 监听画中画状态变化
    this.pipController.on('stateChange', (state: PiPWindow.PiPState, reason: string) => {
      console.info(`画中画状态变化: ${state}, 原因: ${reason}`);
      this.handlePipStateChange(state, reason);
    });

    // 监听控制面板操作事件
    this.pipController.on('controlPanelActionEvent',
      (event: PiPWindow.PiPActionEventType, status?: number) => {
        console.info(`画中画操作事件: ${event}, 状态: ${status}`);
        this.handlePipActionEvent(event, status);
      }
    );
  }

  // 处理画中画状态变化
  private handlePipStateChange(state: PiPWindow.PiPState, reason: string): void {
    // 通知所有监听器
    this.notifyStateChange(state, reason);

    // 如果画中画已停止，清理资源
    if (state === PiPWindow.PiPState.STOPPED || state === PiPWindow.PiPState.ERROR) {
      this.cleanup();
    }
  }

  // 处理画中画操作事件
  private handlePipActionEvent(event: PiPWindow.PiPActionEventType, status?: number): void {
    // 通知所有监听器
    this.notifyActionEvent(event, status);
  }

  // 清理资源
  private async cleanup(): Promise<void> {
    if (this.pipController) {
      try {
        this.pipController.off('stateChange');
        this.pipController.off('controlPanelActionEvent');
        this.pipController = undefined;
      } catch (error) {
        console.error('清理画中画资源失败:', error);
      }
    }
  }
}