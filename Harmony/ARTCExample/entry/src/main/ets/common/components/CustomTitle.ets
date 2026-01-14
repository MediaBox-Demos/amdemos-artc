import { LightStorage } from "./LightStorage";

@Component
export struct CustomTitle {
  @Prop titleText: string = '默认标题'
  private pageStack: NavPathStack = {} as NavPathStack

  async aboutToAppear(): Promise<void> {
    try {
      this.pageStack = await AppStorage.get('pageInfo') as NavPathStack;
      console.info('load settings:', this.pageStack.getAllPathName());
    } catch (error) {
      console.error('Failed to load settings:', error);
    }
  }

  build() {
    Row({ space: 8 }) {
      // 返回按钮区域
      Image($r('app.media.back'))
        .width(24)
        .height(24)
        .margin({
          left: 15
        })
        .onClick(() => {
          this.pageStack.pop()
        })

      // 标题
      Text(this.titleText)
        .fontSize(20)
        .fontColor('#fff')
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .margin({
          left: 20
        })
    }
    .width('100%')
    .height(66)
    .backgroundColor('#590ce4')
  }
}