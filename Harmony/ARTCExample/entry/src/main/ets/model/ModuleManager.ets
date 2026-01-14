/**
 * 模块管理器
 * 单例模式，负责管理所有功能模块的注册、存储和查询
 * 提供按层级、分类等维度查询模块的能力
 */
import { ModuleInfo } from './ModuleInfo';

export class ModuleManager {
  private static instance: ModuleManager = new ModuleManager();
  private modules: Map<string, ModuleInfo> = new Map();

  private constructor() {
  }

  public static getInstance(): ModuleManager {
    return ModuleManager.instance;
  }

  /**
   * 注册一个模块到管理器中
   * @param module 要注册的模块信息
   */
  public registerModule(module: ModuleInfo): void {
    if (this.modules.has(module.id)) {
      console.warn(`Module ${module.id} already exists, will be replaced.`);
    }
    this.modules.set(module.id, module);
  }

  /**
   * 获取所有可用的模块
   * @returns 所有已注册且可用的模块数组，按 sortOrder 排序
   */
  public getAllModules(): ModuleInfo[] {
    const modulesArray: ModuleInfo[] = [];
    this.modules.forEach((value: ModuleInfo) => {
      if (value.isAvailable) {
        modulesArray.push(value);
      }
    });

    return modulesArray.sort((a, b) => a.sortOrder - b.sortOrder);
  }

  /**
   * 按层级获取模块
   * @param level 层级（1: 一级标题，3: 功能项）
   * @returns 指定层级的所有模块
   */
  public getModulesByLevel(level: number): ModuleInfo[] {
    return this.getAllModules().filter((module: ModuleInfo) => module.level === level);
  }

  /**
   * 按分类获取模块
   * @param category 分类名称（如 'quick_start', 'basic_functions' 等）
   * @returns 指定分类的所有模块
   */
  public getModulesByCategory(category: string): ModuleInfo[] {
    return this.getAllModules().filter((module: ModuleInfo) => module.category === category);
  }

  /**
   * 获取指定分类下的所有功能项（level=3）
   * @param category 分类名称
   * @returns 指定分类下的所有功能项模块
   */
  public getSubCategoryModules(category: string): ModuleInfo[] {
    return this.getAllModules().filter((module: ModuleInfo) =>
    module.category === category && module.level === 3
    );
  }

  /**
   * 根据模块 ID 获取单个模块
   * @param moduleId 模块唯一标识符
   * @returns 找到的模块，如果不存在则返回 undefined
   */
  public getModule(moduleId: string): ModuleInfo | undefined {
    return this.modules.get(moduleId);
  }
}