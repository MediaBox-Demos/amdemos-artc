//
//  ARTCTokenHelper.swift
//  ARTCExample
//
//  Created by Bingo on 2025/5/26.
//

import UIKit
import CommonCrypto


class ARTCTokenHelper: NSObject {
    
    /**
     * RTC AppId
     */
    public static let AppId = "<RTC AppId>"
    
    /**
     * RTC AppKey
     */
    public static let AppKey = "<RTC AppKey>"
    
    // MARK: - 最近一次 Token 生成的中间结果（用于 Demo 展示）
    public private(set) static var lastContent: String = ""
    public private(set) static var lastSha256Token: String = ""
    public private(set) static var lastJsonString: String = ""
    public private(set) static var lastBase64Token: String = ""

    /**
     * 根据channelId，userId, timestamp 生成多参数入会的 token
     * Generate a multi-parameter meeting token based on channelId, userId, and timestamp
     */
    public func generateAuthInfoToken(appId: String = ARTCTokenHelper.AppId, appKey: String =  ARTCTokenHelper.AppKey, channelId: String, userId: String, timestamp: Int64) -> String {
        let content = appId + appKey + channelId + userId + "\(timestamp)"
        let token = ARTCTokenHelper.GetSHA256(content)
        
        // 记录中间过程（多参：只有拼接 + SHA256）
        ARTCTokenHelper.lastContent = content
        ARTCTokenHelper.lastSha256Token = token
        ARTCTokenHelper.lastJsonString = ""
        ARTCTokenHelper.lastBase64Token = ""
        
        return token
    }
    
    /**
     * 根据channelId，userId, nonce 生成单参数入会 的token
     * Generate a single-parameter meeting token based on channelId, userId, and nonce
     */
    public func generateJoinToken(appId: String = ARTCTokenHelper.AppId, appKey: String =  ARTCTokenHelper.AppKey, channelId: String, userId: String, timestamp: Int64, nonce: String = "") -> String {
        // 先生成 SHA256 token
        let content = appId + appKey + channelId + userId + "\(timestamp)"
        let token = ARTCTokenHelper.GetSHA256(content)
        
        let tokenJson: [String: Any] = [
            "appid": appId,
            "channelid": channelId,
            "userid": userId,
            "nonce": nonce,
            "timestamp": timestamp,
            "token": token
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: tokenJson, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            let base64Token = jsonData.base64EncodedString()
            
            // 记录中间过程（单参：拼接 + SHA256 + JSON + Base64）
            ARTCTokenHelper.lastContent = content
            ARTCTokenHelper.lastSha256Token = token
            ARTCTokenHelper.lastJsonString = jsonString
            ARTCTokenHelper.lastBase64Token = base64Token
            
            return base64Token
        }
        
        // 失败时清空中间过程
        ARTCTokenHelper.lastContent = ""
        ARTCTokenHelper.lastSha256Token = ""
        ARTCTokenHelper.lastJsonString = ""
        ARTCTokenHelper.lastBase64Token = ""
        return ""
    }

    /**
     * 字符串签名
     * String signing (SHA256)
     */
    private static func GetSHA256(_ input: String) -> String {
        // 将输入字符串转换为数据
        let data = Data(input.utf8)
        
        // 创建用于存储哈希结果的缓冲区
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        
        // 计算 SHA-256 哈希值
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        
        // 将哈希值转换为十六进制字符串
        return hash.map { String(format: "%02hhx", $0) }.joined()
    }

}
