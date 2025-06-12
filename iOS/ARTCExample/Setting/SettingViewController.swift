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
        self.appIdTextField.text = ARTCTokenHelper.AppId
        self.appKeyTextField.text = ARTCTokenHelper.AppKey
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
        if self.userIdTextField.text?.isEmpty == false {
            GlobalConfig.shared.userId = self.userIdTextField.text!
        }
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
