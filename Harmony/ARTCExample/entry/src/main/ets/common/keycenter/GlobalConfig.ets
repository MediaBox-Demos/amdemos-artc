import { preferences } from '@kit.ArkData';
import { ARTCTokenHelper } from './ARTCTokenHelper';

/**
 * 全局配置管理类
 * 用于存储和管理 UserId、SDK Region 等全局信息
 */
export class GlobalConfig {
  // 单例实例
  private static instance: GlobalConfig;

  // 存储键名常量
  private static readonly KEY_USER_ID = 'user_id';
  private static readonly KEY_SDK_ENV_ID = 'sdk_env_id';
  private static readonly KEY_APP_ID = 'app_id';
  private static readonly KEY_APP_KEY = 'app_key';
  private static readonly PREFERENCES_NAME = 'artc_settings';

  // 成员变量
  private mUserId: string = '';
  private mSdkRegion: string = '';
  private mAppId: string = '';
  private mAppKey: string = '';
  private dataPreferences: preferences.Preferences | null = null;

  /**
   * 私有构造函数，防止外部实例化
   */
  private constructor() {
  }

  /**
   * 获取单例实例
   */
  static getInstance(): GlobalConfig {
    if (!GlobalConfig.instance) {
      GlobalConfig.instance = new GlobalConfig();
    }
    return GlobalConfig.instance;
  }

  /**
   * 初始化 Preferences（需在应用启动时调用）
   */
  async init(context: Context): Promise<void> {
    try {
      this.dataPreferences = await preferences.getPreferences(context, GlobalConfig.PREFERENCES_NAME);
    } catch (error) {
      console.error('GlobalConfig init failed:', error);
    }
  }

  /**
   * 获取用户 ID
   * 如果未设置，则自动生成一个随机 ID
   */
  async getUserId(): Promise<string> {
    if (this.mUserId) {
      return this.mUserId;
    }

    try {
      const storedUserId = await this.getPreference(GlobalConfig.KEY_USER_ID);
      if (storedUserId) {
        this.mUserId = storedUserId;
      } else {
        // 生成随机用户 ID
        const randomNum = Math.floor(Math.random() * 1000000);
        this.mUserId = `Harmony_${randomNum}`;
        await this.setPreference(GlobalConfig.KEY_USER_ID, this.mUserId);
      }
    } catch (error) {
      console.error('getUserId failed:', error);
      const randomNum = Math.floor(Math.random() * 1000000);
      this.mUserId = `Harmony_${randomNum}`;
    }

    return this.mUserId;
  }

  /**
   * 设置用户 ID
   */
  async setUserId(userId: string): Promise<void> {
    if (!userId) {
      return;
    }
    this.mUserId = userId;
    await this.setPreference(GlobalConfig.KEY_USER_ID, userId);
  }

  /**
   * 获取 SDK 区域配置
   * 默认为 'cn' (中国)
   */
  async getSdkRegion(): Promise<string> {
    if (this.mSdkRegion) {
      return this.mSdkRegion;
    }

    try {
      const storedRegion = await this.getPreference(GlobalConfig.KEY_SDK_ENV_ID);
      if (storedRegion) {
        this.mSdkRegion = storedRegion;
      } else {
        this.mSdkRegion = 'cn';
        await this.setPreference(GlobalConfig.KEY_SDK_ENV_ID, this.mSdkRegion);
      }
    } catch (error) {
      console.error('getSdkRegion failed:', error);
      this.mSdkRegion = 'cn';
    }

    return this.mSdkRegion;
  }

  /**
   * 设置 SDK 区域配置
   */
  async setSdkRegion(sdkRegion: string): Promise<void> {
    if (!sdkRegion) {
      return;
    }
    this.mSdkRegion = sdkRegion;
    await this.setPreference(GlobalConfig.KEY_SDK_ENV_ID, sdkRegion);
  }

  /**
   * 生成随机频道 ID
   */
  getRandomChannelId(): string {
    const randomNum = Math.floor(Math.random() * 1000000);
    return randomNum.toString();
  }

  /**
   * 获取 AppId
   * 未设置时返回默认的 ARTCTokenHelper.AppId
   */
  async getAppId(): Promise<string> {
    if (this.mAppId) {
      // 同步给 ARTCTokenHelper，保证业务使用的是最新值
      ARTCTokenHelper.APP_ID = this.mAppId;
      return this.mAppId;
    }

    try {
      const storedAppId = await this.getPreference(GlobalConfig.KEY_APP_ID);
      if (storedAppId) {
        // 有用户配置，优先用用户配置
        this.mAppId = storedAppId;
      } else {
        // 没有存储时，用当前 ARTCTokenHelper.AppId 作为默认值并写回
        this.mAppId = ARTCTokenHelper.AppId;
        await this.setPreference(GlobalConfig.KEY_APP_ID, this.mAppId);
      }
    } catch (error) {
      console.error('getAppId failed:', error);
      // 兜底还是走当前 ARTCTokenHelper.AppId
      this.mAppId = ARTCTokenHelper.AppId;
    }

    // 最终统一同步一次
    ARTCTokenHelper.APP_ID = this.mAppId;
    return this.mAppId;
  }

  /**
   * 设置 AppId
   */
  async setAppId(appId: string): Promise<void> {
    // 允许为空（清空时写入空字符串）
    this.mAppId = appId || '';
    await this.setPreference(GlobalConfig.KEY_APP_ID, this.mAppId);
    // 同步给 ARTCTokenHelper：允许为空时 APP_ID 也变成空，Index.ets 会做未配置检查
    ARTCTokenHelper.APP_ID = this.mAppId;
  }

  /**
   * 获取 AppKey
   * 未设置时返回默认的 ARTCTokenHelper.AppKey
   */
  async getAppKey(): Promise<string> {
    if (this.mAppKey) {
      // 同步给 ARTCTokenHelper，保证业务使用的是最新值
      ARTCTokenHelper.APP_KEY = this.mAppKey;
      return this.mAppKey;
    }

    try {
      const storedAppKey = await this.getPreference(GlobalConfig.KEY_APP_KEY);
      if (storedAppKey) {
        // 有用户配置，优先用用户配置
        this.mAppKey = storedAppKey;
      } else {
        // 没有存储时，用当前 ARTCTokenHelper.AppKey 作为默认值并写回
        this.mAppKey = ARTCTokenHelper.AppKey;
        await this.setPreference(GlobalConfig.KEY_APP_KEY, this.mAppKey);
      }
    } catch (error) {
      console.error('getAppKey failed:', error);
      // 兜底还是走当前 ARTCTokenHelper.AppKey
      this.mAppKey = ARTCTokenHelper.AppKey;
    }

    // 最终统一同步一次
    ARTCTokenHelper.APP_KEY = this.mAppKey;
    return this.mAppKey;
  }

  /**
   * 设置 AppKey
   */
  async setAppKey(appKey: string): Promise<void> {
    this.mAppKey = appKey || '';
    await this.setPreference(GlobalConfig.KEY_APP_KEY, this.mAppKey);
    // 同步给 ARTCTokenHelper：允许为空时 APP_KEY 也变成空，Index.ets 会做未配置检查
    ARTCTokenHelper.APP_KEY = this.mAppKey;
  }

  /**
   * 检查 AppId 和 AppKey 是否已配置
   * @return true 表示已配置，false 表示未配置
   */
  async isAppConfigured(): Promise<boolean> {
    const appId = await this.getAppId();
    const appKey = await this.getAppKey();
    return appId !== '' && appKey !== '';
  }

  /**
   * 从 Preferences 获取值
   */
  private async getPreference(key: string): Promise<string> {
    if (!this.dataPreferences) {
      return '';
    }
    try {
      const value = await this.dataPreferences.get(key, '');
      return value as string;
    } catch (error) {
      console.error(`getPreference failed for key ${key}:`, error);
      return '';
    }
  }

  /**
   * 向 Preferences 保存值
   */
  private async setPreference(key: string, value: string): Promise<void> {
    if (!this.dataPreferences) {
      return;
    }
    try {
      await this.dataPreferences.put(key, value);
      await this.dataPreferences.flush();
    } catch (error) {
      console.error(`setPreference failed for key ${key}:`, error);
    }
  }
}
