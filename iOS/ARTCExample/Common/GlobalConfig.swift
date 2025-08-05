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

    override init() {
        super.init()
        
        self.loadData()
    }
    
    func loadData() {
        
        let userId = UserDefaults.standard.object(forKey: "artc_user_id") as? String
        self.userId = userId ?? self.generateUserId()
        
        let sdkEnv = UserDefaults.standard.object(forKey: "artc_sdk_env") as? Int
        self.sdkEnv = AlivcGlobalEnv(rawValue: sdkEnv ?? 0) ?? .DEFAULT
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
    
    
}

