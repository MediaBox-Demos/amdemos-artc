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

    /**
     * 根据channelId，userId, timestamp 生成多参数入会的 token
     * Generate a multi-parameter meeting token based on channelId, userId, and timestamp
     */
    public func generateAuthInfoToken(appId: String = ARTCTokenHelper.AppId, appKey: String =  ARTCTokenHelper.AppKey, channelId: String, userId: String, timestamp: Int64) -> String {
        let stringBuilder = appId + appKey + channelId + userId + "\(timestamp)"
        let token = ARTCTokenHelper.GetSHA256(stringBuilder)
        return token
    }
    
    /**
     * 根据channelId，userId, nonce 生成单参数入会 的token
     * Generate a single-parameter meeting token based on channelId, userId, and nonce
     */
    public func generateJoinToken(appId: String = ARTCTokenHelper.AppId, appKey: String =  ARTCTokenHelper.AppKey, channelId: String, userId: String, timestamp: Int64, nonce: String = "") -> String {
        let token = self.generateAuthInfoToken(appId: appId, appKey: appKey, channelId: channelId, userId: userId, timestamp: timestamp)
        
        let tokenJson: [String: Any] = [
            "appid": appId,
            "channelid": channelId,
            "userid": userId,
            "nonce": nonce,
            "timestamp": timestamp,
            "token": token
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: tokenJson, options: []),
           let base64Token = jsonData.base64EncodedString() as String? {
            return base64Token
        }
        
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
