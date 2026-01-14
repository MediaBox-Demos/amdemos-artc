import cryptoFramework from '@ohos.security.cryptoFramework';
import util from '@ohos.util';

interface TokenParams {
  appid: string;
  channelid: string;
  userid: string;
  token: string;
  nonce?: string;
  timestamp?: number;
}

/**
 * Token生成工具类，参考文档：https://help.aliyun.com/zh/live/token-based-authentication
 * 1. 获取Token参数： appId, appKey, channelId, userId, nonce, timestamp
 * 2. 拼接参数
 * 3. SHA265计算 -> 获取到 多参入会Token
 * 4. 将多参入会Token联同生成Token的参数构造为Json对象
 * 5. Base64 编码 -> 获取到 单参入会Token
 */
export class ARTCTokenHelper {
  // AppId 和 AppKey
  public static APP_ID: string = '';
  public static APP_KEY: string = '';

  static get AppId(): string {
    return ARTCTokenHelper.APP_ID;
  }

  static get AppKey(): string {
    return ARTCTokenHelper.APP_KEY;
  }

  // 最近一次 Token 生成的中间结果（用于 Demo 展示）
  private static lastContent: string = '';
  private static lastSha256Token: string = '';
  private static lastJsonString: string = '';
  private static lastBase64Token: string = '';

  static getLastContent(): string {
    return ARTCTokenHelper.lastContent;
  }

  static getLastSha256Token(): string {
    return ARTCTokenHelper.lastSha256Token;
  }

  static getLastJsonString(): string {
    return ARTCTokenHelper.lastJsonString;
  }

  static getLastBase64Token(): string {
    return ARTCTokenHelper.lastBase64Token;
  }

  /**
   * 单参数入会：返回 Base64 编码后的 Token
   * @param appId: 从控制台获取
   * @param appKey：从控制台获取
   * @param channelId: 频道ID，用户自定义，字符串类型，支持数字、大小写字母、短划线（-）、下划线（_），不超过64个字符。
   * @param userId: 用户ID，用户自定义，字符串类型，支持数字、大小写字母、短划线（-）、下划线（_），不超过64个字符。
   * @param timestamp: 时间戳，单位为秒，表示过期时间，整形。
   * @param nonce: 推荐为空。
   */
  static async generateSingleParameterToken(
    appId: string,
    appKey: string,
    channelId: string,
    userId: string,
    timestamp: number,
    nonce: string = ''
  ): Promise<string> {
    // 和 Android / iOS 保持一致：拼接顺序不包含 nonce
    const raw = `${appId}${appKey}${channelId}${userId}${timestamp}`;
    const token = await ARTCTokenHelper.stringToSha256(raw);

    const params: TokenParams = {
      appid: appId,
      channelid: channelId,
      userid: userId,
      nonce,
      timestamp,
      token
    };

    const base64Token = ARTCTokenHelper.encodeJsonToBase64(params);

    // 记录中间过程（单参：拼接 + SHA256 + JSON + Base64）
    ARTCTokenHelper.lastContent = raw;
    ARTCTokenHelper.lastSha256Token = token;
    ARTCTokenHelper.lastJsonString = JSON.stringify({
      appid: params.appid,
      channelid: params.channelid,
      userid: params.userid,
      nonce: params.nonce ?? '',
      timestamp: params.timestamp ?? 0,
      token: params.token
    });
    ARTCTokenHelper.lastBase64Token = base64Token;

    return base64Token;
  }

  /**
   * 多参数入会：返回十六进制 token（供 AliRtcEngineAuthInfo 使用）
   */
  static async generateMultiParameterToken(
    appId: string,
    appKey: string,
    channelId: string,
    userId: string,
    timestamp: number,
    nonce: string = ''
  ): Promise<string> {
    // 与单参保持一致：拼接顺序不包含 nonce
    const raw = `${appId}${appKey}${channelId}${userId}${timestamp}`;
    const token = await ARTCTokenHelper.stringToSha256(raw);

    // 记录中间过程（多参：只有拼接 + SHA256）
    ARTCTokenHelper.lastContent = raw;
    ARTCTokenHelper.lastSha256Token = token;
    ARTCTokenHelper.lastJsonString = '';
    ARTCTokenHelper.lastBase64Token = '';

    return token;
  }

  static getTimestamp(): number {
    return Math.floor(Date.now() / 1000) + 60 * 60 * 24;
  }

  /**
   * 内部：SHA256 计算
   */
  private static async stringToSha256(input: string): Promise<string> {
    try {
      const sha256 = cryptoFramework.createMd('SHA256');
      const encoder = new util.TextEncoder();
      const data = encoder.encodeInto(input);

      await sha256.update({ data });
      const hashData = await sha256.digest();

      return ARTCTokenHelper.bytesToHex(hashData.data);
    } catch (error) {
      console.error('SHA256计算失败:', error);
      const errorMessage = error instanceof Error ? error.message : String(error);
      throw new Error(`SHA256计算失败: ${errorMessage}`);
    }
  }

  private static bytesToHex(bytes: Uint8Array): string {
    return Array.from(bytes)
      .map(byte => byte.toString(16).padStart(2, '0'))
      .join('');
  }

  /**
   * 内部：构造 JSON 并 Base64 编码
   */
  private static encodeJsonToBase64(params: TokenParams): string {
    const jsonString = JSON.stringify({
      appid: params.appid,
      channelid: params.channelid,
      userid: params.userid,
      nonce: params.nonce ?? '',
      timestamp: params.timestamp ?? 0,
      token: params.token
    });

    const encoder = new util.TextEncoder();
    const data = encoder.encodeInto(jsonString);
    const base64Helper = new util.Base64Helper();
    const encoded = base64Helper.encodeToStringSync(data);

    return encoded.replace(/\n/g, '').replace(/\r/g, '');
  }
}
