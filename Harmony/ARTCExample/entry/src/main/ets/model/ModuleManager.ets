// 模块管理
import { ModuleInfo } from './ModuleInfo';

export class ModuleManager {
  private static instance: ModuleManager = new ModuleManager();
  private modules: Map<string, ModuleInfo> = new Map();

  private constructor() {
  }

  public static getInstance(): ModuleManager {
    return ModuleManager.instance;
  }

  // 注册模块
  public registerModule(module: ModuleInfo): void {
    if (this.modules.has(module.id)) {
      console.warn(`Module ${module.id} already exists, will be replaced.`);
    }
    this.modules.set(module.id, module);
  }

  // 获取所有模块
  public getAllModules(): ModuleInfo[] {
    const modulesArray: ModuleInfo[] = [];
    this.modules.forEach((value: ModuleInfo) => {
      if (value.isAvailable) {
        modulesArray.push(value);
      }
    });

    return modulesArray.sort((a, b) => a.sortOrder - b.sortOrder);
  }

  // 按层级获取模块
  public getModulesByLevel(level: number): ModuleInfo[] {
    return this.getAllModules().filter((module: ModuleInfo) => module.level === level);
  }

  // 按分类获取模块
  public getModulesByCategory(category: string): ModuleInfo[] {
    return this.getAllModules().filter((module: ModuleInfo) => module.category === category);
  }

  // 获取子分类模块
  public getSubCategoryModules(category: string): ModuleInfo[] {
    return this.getAllModules().filter((module: ModuleInfo) =>
    module.category === category && module.level === 3
    );
  }

  // 获取模块
  public getModule(moduleId: string): ModuleInfo | undefined {
    return this.modules.get(moduleId);
  }
}