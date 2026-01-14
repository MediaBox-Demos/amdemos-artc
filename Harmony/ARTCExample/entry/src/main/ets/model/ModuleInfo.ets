/**
 * 模块信息数据模型
 * 用于描述首页展示的功能模块的属性和配置
 */
export class ModuleInfo {
  /** 模块的唯一标识符，用于区分不同的模块 */
  id: string;
  
  /** 模块的显示名称，用于在界面上展示 */
  name: string;
  
  /** 模块所属的分类，用于对模块进行分组（如 quick_start、basic_functions 等） */
  category: string;
  
  /** 模块的层级，用于表示在界面上的层级关系
   * - 1: 一级标题（如"快速开始"）
   * - 2: 二级标题（保留）
   * - 3: 功能项（具体的功能页面）
   */
  level: number = 1;
  
  /** 点击模块后要跳转的页面标识（对应 ConstantsData 中的页面名称） */
  targetPage: string;
  
  /** 表示模块是否可用，如果为 false 则不显示或不可点击 */
  isAvailable: boolean = true;
  
  /** 模块的排序顺序，用于在列表中排序，数值越小越靠前 */
  sortOrder: number = 0;

  constructor(
    id: string,
    name: string,
    category: string = 'default',
    level: number = 3,
    targetPage: string = ''
  ) {
    this.id = id;
    this.name = name;
    this.category = category;
    this.level = level;
    this.targetPage = targetPage;
  }
}