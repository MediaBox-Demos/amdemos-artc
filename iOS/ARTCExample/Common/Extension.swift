//
//  Extension.swift
//  ARTCExample
//
//  Created by Bingo on 2025/5/26.
//

import UIKit

extension String {
    
    var localized: String { NSLocalizedString(self, comment: "") }
    
    func printLog(isError: Bool = false) {
        debugPrint("[\(Date())][\(isError ? "Error" : "Debug")][ARTC-Example] \(self)")
    }
    
}

extension Dictionary {
    
    /**
     * 转化为Json字符串
     * Convert to a JSON string
     */
    public var jsonString: String {
        do {
            let stringData = try JSONSerialization.data(withJSONObject: self as NSDictionary, options: JSONSerialization.WritingOptions.prettyPrinted)
            if let string = String(data: stringData, encoding: String.Encoding.utf8){
                return string
            }
        } catch _ {
            
        }
        return "{}"
    }
}

extension UIViewController {
    
    @discardableResult
    func presentVC(storyboardName: String, storyboardId: String = "EntranceVC") -> UIViewController? {
        if storyboardName.isEmpty {
            return nil
        }
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: storyboardId)
        self.navigationController?.pushViewController(vc, animated: true)
        return vc
    }
    
    func showToast(message: String) {
        DispatchQueue.main.async {
            // 获取当前 KeyWindow
            guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else { return }
            
            // 创建 Toast Label
            let toastLabel = UILabel()
            toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            toastLabel.textColor = .white
            toastLabel.textAlignment = .center
            toastLabel.font = UIFont.systemFont(ofSize: 18)
            toastLabel.text = message
            toastLabel.alpha = 1.0
            toastLabel.layer.cornerRadius = 8
            toastLabel.clipsToBounds = true
            toastLabel.numberOfLines = 0
            toastLabel.translatesAutoresizingMaskIntoConstraints = false
            
            // 添加到窗口
            window.addSubview(toastLabel)
            
            // 设置约束（居中于底部）
            NSLayoutConstraint.activate([
                toastLabel.centerXAnchor.constraint(equalTo: window.centerXAnchor),
                toastLabel.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor, constant: -32),
                toastLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 250)
            ])
            
            // 动画消失
            UIView.animate(withDuration: 0.5, delay: 2.0, options: .curveEaseOut, animations: {
                toastLabel.alpha = 0
            }) { _ in
                toastLabel.removeFromSuperview()
            }
        }
    }
}

extension UIAlertController {
    
    /// 显示一个带有输入框的 Alert
    /// - Parameters:
    ///   - title: 提示标题
    ///   - defaultValue: 输入框默认值
    ///   - viewController: 要展示 Alert 的视图控制器
    ///   - completed: 输入完成后的回调（返回输入内容）
    static func showInput(title: String?, defaultValue: String?, viewController: UIViewController?, onCompleted completed: ((String?) -> Void)? = nil) {
        // 创建 AlertController
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        
        // 添加 OK 按钮
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            let inputText = alertController.textFields?.first?.text
            completed?(inputText)
        }))
        
        // 添加 Cancel 按钮
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        
        // 添加输入框
        alertController.addTextField { textField in
            textField.text = defaultValue
        }
        
        // 弹出 Alert
        viewController?.present(alertController, animated: true, completion: nil)
    }
    
    static func showSheet(dataList: [Any], vc: UIViewController?, title: String? = nil, msg: String? = nil, selectedHandler: ((_ index: Int, _ data: Any) -> Void)? = nil ) {
        
        let alert = UIAlertController.init(title: title, message: msg, preferredStyle: .actionSheet)
        for i in 0..<dataList.count {
            let obj = dataList[i]
            let action = UIAlertAction(title: "\(obj)", style: .default) { handler in
                selectedHandler?(i, obj)
            }
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel))
        vc?.present(alert, animated: true)
    }
    
    static func showAlertWithMainThread(msg: String, vc: UIViewController?) {
        if Thread.isMainThread {
            let alert = UIAlertController(title: "", message: msg, preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(action)
            vc?.present(alert, animated: true)
        }
        else {
            DispatchQueue.main.async {
                self.showAlertWithMainThread(msg: msg, vc: vc)
            }
        }
    }
}
