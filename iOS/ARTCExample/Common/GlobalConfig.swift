//
//  GlobalConfig.swift
//  ARTCExample
//
//  Created by Bingo on 2025/5/26.
//

import UIKit
import AliVCSDK_ARTC

class GlobalConfig: NSObject {
    
    static let shared: GlobalConfig = GlobalConfig()

    var userId: String = "0" {
        didSet {
            UserDefaults.standard.set(self.userId, forKey: "artc_user_id")
        }
    }
    var sdkEnv: AlivcGlobalEnv = .DEFAULT {
        didSet {
            UserDefaults.standard.set(self.sdkEnv.rawValue, forKey: "artc_sdk_env")
        }
    }
    
    var appId: String = "" {
        didSet {
            UserDefaults.standard.set(self.appId, forKey: "artc_app_id")
        }
    }
    
    var appKey: String = "" {
        didSet {
            UserDefaults.standard.set(self.appKey, forKey: "artc_app_key")
        }
    }

    override init() {
        super.init()
        
        // 先加载数据,但不触发 didSet
        let savedUserId = UserDefaults.standard.object(forKey: "artc_user_id") as? String
        let savedSdkEnv = UserDefaults.standard.object(forKey: "artc_sdk_env") as? Int
        let savedAppId = UserDefaults.standard.object(forKey: "artc_app_id") as? String
        let savedAppKey = UserDefaults.standard.object(forKey: "artc_app_key") as? String
        
        self.userId = savedUserId ?? self.generateUserId()
        self.sdkEnv = AlivcGlobalEnv(rawValue: savedSdkEnv ?? 0) ?? .DEFAULT
        self.appId = savedAppId ?? ARTCTokenHelper.AppId
        self.appKey = savedAppKey ?? ARTCTokenHelper.AppKey
    }
    
    func applySdkEnv() {
        let sdkEnvResult = AlivcBase.environmentManager.setGlobalEnvironment(self.sdkEnv)
        "Set RTC environment to: \(sdkEnv) result: \(sdkEnvResult)".printLog()
    }
    
    func generateUserId() -> String {
        
        var index = arc4random() % 1000
        if index < 1000 {
            index += 1000
        }
        return "\(index)"
    }
    
    /**
     * 检查 AppId 和 AppKey 是否已配置
     * @return true 表示已配置,false 表示未配置
     */
    func isAppConfigured() -> Bool {
        return !self.appId.isEmpty && !self.appKey.isEmpty
    }
    
}
