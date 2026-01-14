import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { prompt } from '@kit.ArkUI';

/**
 * 权限管理工具类
 * 负责管理应用所需的权限检查和申请
 */
export class PermissionManager {
  private static instance: PermissionManager;

  private constructor() {}

  /**
   * 获取单例实例
   */
  public static getInstance(): PermissionManager {
    if (!PermissionManager.instance) {
      PermissionManager.instance = new PermissionManager();
    }
    return PermissionManager.instance;
  }

  /**
   * 检查麦克风和摄像头权限状态
   * @param context UIAbility上下文
   * @returns 是否已授权
   */
  async checkMicrophoneAndCameraPermission(context: common.UIAbilityContext): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();

      // 检查麦克风权限
      const microphoneGranted = atManager.checkAccessTokenSync(
        0,
        'ohos.permission.MICROPHONE'
      ) === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;

      // 检查摄像头权限
      const cameraGranted = atManager.checkAccessTokenSync(
        1,
        'ohos.permission.CAMERA'
      ) === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;

      return microphoneGranted && cameraGranted;
    } catch (err) {
      console.error(`检查权限失败: ${(err as BusinessError).code}, ${(err as BusinessError).message}`);
      return false;
    }
  }

  /**
   * 申请麦克风和摄像头权限
   * @param context UIAbility上下文
   * @returns 是否授权成功
   */
  async requestMicrophoneAndCameraPermission(context: common.UIAbilityContext): Promise<boolean> {
    return new Promise((resolve) => {
      const atManager = abilityAccessCtrl.createAtManager();
      const permissions: Permissions[] = [
        'ohos.permission.MICROPHONE',
        'ohos.permission.CAMERA'
      ];

      atManager.requestPermissionsFromUser(context, permissions)
        .then((data) => {
          const results = data.authResults;
          const allGranted = results.every(status =>
          status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
          );

          if (allGranted) {
            console.debug('麦克风和摄像头授权成功');
            resolve(true);
          } else {
            console.debug('麦克风和摄像头授权失败');
            resolve(false);
          }
        })
        .catch((err: BusinessError) => {
          console.error(`申请权限失败 Code: ${err.code}, Msg: ${err.message}`);
          resolve(false);
        });
    });
  }

  /**
   * 显示权限被拒绝的提示
   */
  showPermissionDeniedToast(): void {
    prompt.showToast({
      message: '需要麦克风和摄像头权限才能使用视频功能',
      duration: 3000
    });
  }

  /**
   * 检查并申请麦克风和摄像头权限
   * 如果已授权直接返回true，否则申请权限
   * @param context UIAbility上下文
   * @returns 是否最终获得授权
   */
  async checkAndRequestMicrophoneAndCameraPermission(context: common.UIAbilityContext): Promise<boolean> {
    // 先检查是否已有权限
    const hasPermission = await this.checkMicrophoneAndCameraPermission(context);

    if (hasPermission) {
      return true;
    }

    // 申请权限
    return await this.requestMicrophoneAndCameraPermission(context);
  }
}