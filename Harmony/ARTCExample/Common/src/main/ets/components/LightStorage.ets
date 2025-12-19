// LightStorage.ets - 轻量型存储工具类
import preferences from '@ohos.data.preferences';

// 定义存储键值类型
type StorageKey = string;
type StorageValue = string | number | boolean | object;

export class LightStorage {
  // 单例模式
  static instance: LightStorage | null = null;
  preferences: preferences.Preferences | null = null;

  // 存储文件名称
  private static readonly STORAGE_NAME = 'light_storage';

  /**
   * 私有构造函数
   */
  private constructor() {}

  /**
   * 获取存储实例（单例）
   * @param context UI上下文
   * @returns LightStorage实例
   */
  public static async getInstance(context: Context): Promise<LightStorage> {
    if (!LightStorage.instance) {
      LightStorage.instance = new LightStorage();
      await LightStorage.instance.init(context);
    }
    return LightStorage.instance;
  }

  /**
   * 初始化存储
   * @param context UI上下文
   */
  private async init(context: Context): Promise<void> {
    try {
      this.preferences = await preferences.getPreferences(context, LightStorage.STORAGE_NAME);
    } catch (error) {
      console.error('LightStorage初始化失败:', error);
    }
  }

  /**
   * 保存字符串
   * @param key 键名
   * @param value 字符串值
   * @returns Promise<boolean>
   */
  public async putString(key: StorageKey, value: string): Promise<boolean> {
    return this.put(key, value);
  }

  /**
   * 保存数字
   * @param key 键名
   * @param value 数字值
   * @returns Promise<boolean>
   */
  public async putNumber(key: StorageKey, value: number): Promise<boolean> {
    return this.put(key, value);
  }

  /**
   * 保存布尔值
   * @param key 键名
   * @param value 布尔值
   * @returns Promise<boolean>
   */
  public async putBoolean(key: StorageKey, value: boolean): Promise<boolean> {
    return this.put(key, value);
  }

  /**
   * 保存对象（自动转为JSON字符串）
   * @param key 键名
   * @param value 对象值
   * @returns Promise<boolean>
   */
  public async putObject(key: StorageKey, value: object): Promise<boolean> {
    try {
      const jsonString = JSON.stringify(value);
      return this.put(key, jsonString);
    } catch (error) {
      console.error('对象转为JSON失败:', error);
      return false;
    }
  }

  /**
   * 通用保存方法
   * @param key 键名
   * @param value 值
   * @returns Promise<boolean>
   */
  private async put(key: StorageKey, value: StorageValue): Promise<boolean> {
    if (!this.preferences) {
      console.error('Preferences未初始化');
      return false;
    }

    try {
      await this.preferences.put(key, value);
      await this.preferences.flush();
      return true;
    } catch (error) {
      console.error('保存数据失败:', error);
      return false;
    }
  }

  /**
   * 获取字符串
   * @param key 键名
   * @param defaultValue 默认值
   * @returns Promise<string>
   */
  public async getString(key: StorageKey, defaultValue: string = ''): Promise<string> {
    const value = await this.get(key, defaultValue);
    return String(value);
  }

  /**
   * 获取数字
   * @param key 键名
   * @param defaultValue 默认值
   * @returns Promise<number>
   */
  public async getNumber(key: StorageKey, defaultValue: number = 0): Promise<number> {
    const value = await this.get(key, defaultValue);
    return Number(value);
  }

  /**
   * 获取布尔值
   * @param key 键名
   * @param defaultValue 默认值
   * @returns Promise<boolean>
   */
  public async getBoolean(key: StorageKey, defaultValue: boolean = false): Promise<boolean> {
    const value = await this.get(key, defaultValue);
    return Boolean(value);
  }

  /**
   * 获取对象（自动解析JSON字符串）
   * @param key 键名
   * @param defaultValue 默认值
   * @returns Promise<object | null>
   */
  public async getObject<T = object>(key: StorageKey, defaultValue: T | null = null): Promise<T | null> {
    const value = await this.get(key, '');

    if (!value || typeof value !== 'string') {
      return defaultValue;
    }

    try {
      return JSON.parse(value) as T;
    } catch (error) {
      console.error('JSON解析失败:', error);
      return defaultValue;
    }
  }
  /**
   * 通用获取方法
   * @param key 键名
   * @param defaultValue 默认值
   * @returns Promise<StorageValue>
   */
  private async get(key: StorageKey, defaultValue: StorageValue): Promise<StorageValue> {
    if (!this.preferences) {
      console.error('Preferences未初始化');
      return defaultValue;
    }

    try {
      const value = await this.preferences.get(key, defaultValue);
      // 处理 bigint 类型转换
      if (typeof value === 'bigint') {
        return Number(value) as StorageValue;
      }
      return value as StorageValue;
    } catch (error) {
      console.error('获取数据失败:', error);
      return defaultValue;
    }
  }


  /**
   * 删除指定键值
   * @param key 键名
   * @returns Promise<boolean>
   */
  public async remove(key: StorageKey): Promise<boolean> {
    if (!this.preferences) {
      console.error('Preferences未初始化');
      return false;
    }

    try {
      await this.preferences.delete(key);
      await this.preferences.flush();
      return true;
    } catch (error) {
      console.error('删除数据失败:', error);
      return false;
    }
  }

  /**
   * 清空所有存储数据
   * @returns Promise<boolean>
   */
  public async clear(): Promise<boolean> {
    if (!this.preferences) {
      console.error('Preferences未初始化');
      return false;
    }

    try {
      await this.preferences.clear();
      await this.preferences.flush();
      return true;
    } catch (error) {
      console.error('清空数据失败:', error);
      return false;
    }
  }

}

// 快捷方法封装 - 用于快速使用
export class StorageHelper {
  private static storage: LightStorage | null = null;

  /**
   * 初始化存储
   * @param context UI上下文
   */
  public static async init(context: Context): Promise<void> {
    StorageHelper.storage = await LightStorage.getInstance(context);
  }

  /**
   * 检查是否已初始化
   */
  private static checkInitialized(): boolean {
    if (!StorageHelper.storage) {
      console.error('StorageHelper未初始化，请先调用init方法');
      return false;
    }
    return true;
  }

  // 快捷方法
  public static async putString(key: string, value: string): Promise<boolean> {
    if (!StorageHelper.checkInitialized()) return false;
    return StorageHelper.storage!.putString(key, value);
  }

  public static async getString(key: string, defaultValue: string = ''): Promise<string> {
    if (!StorageHelper.checkInitialized()) return defaultValue;
    return StorageHelper.storage!.getString(key, defaultValue);
  }

  public static async putNumber(key: string, value: number): Promise<boolean> {
    if (!StorageHelper.checkInitialized()) return false;
    return StorageHelper.storage!.putNumber(key, value);
  }

  public static async getNumber(key: string, defaultValue: number = 0): Promise<number> {
    if (!StorageHelper.checkInitialized()) return defaultValue;
    return StorageHelper.storage!.getNumber(key, defaultValue);
  }

  public static async putBoolean(key: string, value: boolean): Promise<boolean> {
    if (!StorageHelper.checkInitialized()) return false;
    return StorageHelper.storage!.putBoolean(key, value);
  }

  public static async getBoolean(key: string, defaultValue: boolean = false): Promise<boolean> {
    if (!StorageHelper.checkInitialized()) return defaultValue;
    return StorageHelper.storage!.getBoolean(key, defaultValue);
  }

  public static async putObject(key: string, value: object): Promise<boolean> {
    if (!StorageHelper.checkInitialized()) return false;
    return StorageHelper.storage!.putObject(key, value);
  }

  public static async getObject<T = object>(key: string, defaultValue: T | null = null): Promise<T | null> {
    if (!StorageHelper.checkInitialized()) return defaultValue;
    return StorageHelper.storage!.getObject<T>(key, defaultValue);
  }

  public static async remove(key: string): Promise<boolean> {
    if (!StorageHelper.checkInitialized()) return false;
    return StorageHelper.storage!.remove(key);
  }

  public static async clear(): Promise<boolean> {
    if (!StorageHelper.checkInitialized()) return false;
    return StorageHelper.storage!.clear();
  }
}
