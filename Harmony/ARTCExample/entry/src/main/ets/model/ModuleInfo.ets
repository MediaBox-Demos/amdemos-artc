export class ModuleInfo {
  id: string; //模块的唯一标识符，用于区分不同的模块。
  name: string; //模块的显示名称，用于在界面上展示。
  category: string; //模块所属的分类，用于对模块进行分组。
  level: number = 1; //模块的层级，用于表示在界面上的层级关系（1表示一级标题，2表示二级标题，3表示功能项）
  targetPage: string; //点击模块后要跳转的页面路径
  isAvailable: boolean = true; //表示模块是否可用，如果为false则可能不显示或不可点击。
  sortOrder: number = 0; //模块的排序顺序，用于在列表中排序，数值越小越靠前。

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