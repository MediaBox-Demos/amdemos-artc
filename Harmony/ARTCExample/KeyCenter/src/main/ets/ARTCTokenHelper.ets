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

export class ARTCTokenHelper {
  // 示例 AppId/AppKey，可按实际需要覆盖
  static AppId: string = ""
  static AppKey: string = ""

  /**
   * 单参数入会：返回 Base64 编码后的 Token
   */
  static async generateSingleParameterToken(
    appId: string,
    appKey: string,
    channelId: string,
    userId: string,
    timestamp: number,
    nonce: string = ''
  ): Promise<string> {
    const raw = `${appId}${appKey}${channelId}${userId}${nonce}${timestamp}`;
    const token = await ARTCTokenHelper.stringToSha256(raw);

    const params: TokenParams = {
      appid: appId,
      channelid: channelId,
      userid: userId,
      nonce,
      timestamp,
      token
    };

    return await ARTCTokenHelper.encodeJsonToBase64(params);
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
    const raw = `${appId}${appKey}${channelId}${userId}${nonce}${timestamp}`;
    const token = await ARTCTokenHelper.stringToSha256(raw);
    return token;
  }

  /**
   * 获取 24 小时后的时间戳（秒）
   */
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

  /**
   * 内部：字节数组转十六进制字符串
   */
  private static bytesToHex(bytes: Uint8Array): string {
    return Array.from(bytes)
      .map(byte => byte.toString(16).padStart(2, '0'))
      .join('');
  }

  /**
   * 内部：构造 JSON 并 Base64 编码
   */
  private static async encodeJsonToBase64(params: TokenParams): Promise<string> {
    try {
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

      const base64 = new util.Base64();
      const encoded = await base64.encodeToString(data);

      return encoded.replace(/\n/g, '').replace(/\r/g, '');
    } catch (error) {
      console.error('Base64编码失败:', error);
      return '';
    }
  }
}
