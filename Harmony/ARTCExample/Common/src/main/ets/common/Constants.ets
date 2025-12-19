//常量定义
export interface SettingsData {
  appId?: string;
  appKey?: string;
  userId?: string;
  sdkVersion?: string;
  sdkRegion?: string;
}


export interface FunctionItemParam {
  id: string;
  name: string;
  level: number;
  category: string;
  subCategory?: string;
  targetPage?: string;
}

export interface AliRtcEngineAuthInfo{
  /** 频道ID */
  channelId: string;
  /** 用户ID */
  userId: string;
  /** 应用ID */
  appId: string;
  /** 随机串 */
  nonce: string;
  /** 令牌 */
  token: string;
  /*!
   * 角色类型。默认值为空，表示不涉及此功能。取值：
   * - pub：主播角色。
   * - sub：观众角色。
   *
   * 更多信息，请参见如何进行角色鉴权。
   */
  role: string;
  /** 时间戳 */
  timestamp: number;
  // tokenType: string;
}

export interface ISelectOption {
  value: string;
}
