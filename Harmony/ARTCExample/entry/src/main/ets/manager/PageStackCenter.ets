import { ConstantsData } from 'common/src/main/ets/common/ConstantsData';
import { TokenGenerate } from 'quickstart/src/main/ets/pages/TokenGenerate';
import { VideoCall } from 'quickstart/src/main/ets/pages/VideoCall';
import { VoiceChat } from 'quickstart/src/main/ets/pages/VoiceChat';

//路由管理类,跳转都在这
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

  private pageStack: NavPathStack = new NavPathStack()

  getStack(): NavPathStack {
    return this.pageStack
  }


  pushPath(info: NavPathInfo, options?: NavigationOptions): void {
    this.pageStack.pushPath(info, options)
  }

  replacePath(info: NavPathInfo, options?: NavigationOptions): void {
    this.pageStack.replacePath(info, options)

  }


  clear(animated?: boolean) {
    this.pageStack.clear(animated)
  }

  pop(result: object, animated?: boolean): void {
    this.pageStack.pop(result, animated);
  }
}

@Builder
export function PageMap(name: string) {
  if (name === ConstantsData.TokenGenerate) {
    TokenGenerate()
  } else if (name === ConstantsData.VideoCall) {
    VideoCall()
  } else if (name === ConstantsData.VoiceChat) {
    VoiceChat()
  }
}