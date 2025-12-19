import { ModuleInfo } from '../../model/ModuleInfo';

// 定义统一的执行结果类型
export interface ModuleExecuteResult {
  success: boolean;
  message: string;
  data?: object; // 可选的数据字段
}

export abstract class BaseModule {
  protected moduleInfo: ModuleInfo;

  constructor(moduleInfo: ModuleInfo) {
    this.moduleInfo = moduleInfo;
  }

  // 获取模块信息
  public getModuleInfo(): ModuleInfo {
    return this.moduleInfo;
  }

  // 模块初始化
  public abstract onInitialize(): Promise<void>;

  // 模块销毁
  public abstract onDestroy(): Promise<void>;

  // 执行模块功能 - 使用明确的类型
  public abstract execute(...args: string[]): Promise<ModuleExecuteResult>;
}