//
//  SettingViewController.swift
//  ARTCExample
//
//  Created by Bingo on 2025/5/23.
//

import UIKit
import AliVCSDK_ARTC


class SettingViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.appIdTextField.text = GlobalConfig.shared.appId
        self.appKeyTextField.text = GlobalConfig.shared.appKey
        self.regionBtn.setTitle(self.regionList[GlobalConfig.shared.sdkEnv == .SEA ? 1 : 0], for: .normal)
        self.userIdTextField.text = GlobalConfig.shared.userId
        self.versionLabel.text = AliRtcEngine.getSdkVersion()
    }
    
    @IBOutlet weak var appIdTextField: UITextField!
    
    @IBOutlet weak var appKeyTextField: UITextField!
    
    @IBOutlet weak var userIdTextField: UITextField!
    
    @IBOutlet weak var versionLabel: UILabel!
    
    @IBOutlet weak var regionBtn: UIButton!
    
    @IBAction func onRegionBtnClick(_ sender: Any) {
        UIAlertController.showSheet(dataList: self.regionList, vc: self) { index, value in
            self.regionBtn.setTitle(value as? String, for: .normal)
            
            let sdkEnv: AlivcGlobalEnv = index == 0 ? .DEFAULT : .SEA
            GlobalConfig.shared.sdkEnv = sdkEnv
            GlobalConfig.shared.applySdkEnv()
        }
    }
    
    @IBAction func onSavClick(_ sender: Any) {
        self.view.endEditing(true)
        
        // 保存 UserId
        if self.userIdTextField.text?.isEmpty == false {
            GlobalConfig.shared.userId = self.userIdTextField.text!
        }
        
        // 保存 AppId (允许保存空字符串)
        if let appId = self.appIdTextField.text {
            GlobalConfig.shared.appId = appId
        }
        
        // 保存 AppKey (允许保存空字符串)
        if let appKey = self.appKeyTextField.text {
            GlobalConfig.shared.appKey = appKey
        }
        
        // 显示保存成功提示
        let alert = UIAlertController(title: "提示", message: "保存成功", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        self.present(alert, animated: true)
    }
    
    let regionList = ["CN".localized, "SEA".localized]

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
