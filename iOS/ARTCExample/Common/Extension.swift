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
        debugPrint("[\(isError ? "Error" : "Debug")][ARTC-Example] \(self)")
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
    
}

extension UIAlertController {
    
    static func showSheet(dataList: [Any], vc: UIViewController, title: String? = nil, msg: String? = nil, selectedHandler: ((_ index: Int, _ data: Any) -> Void)? = nil ) {
        
        let alert = UIAlertController.init(title: title, message: msg, preferredStyle: .actionSheet)
        for i in 0..<dataList.count {
            let obj = dataList[i]
            let action = UIAlertAction(title: "\(obj)", style: .default) { handler in
                selectedHandler?(i, obj)
            }
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel))
        vc.present(alert, animated: true)
    }
    
    static func showAlertWithMainThread(msg: String, vc: UIViewController) {
        if Thread.isMainThread {
            let alert = UIAlertController(title: "", message: msg, preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(action)
            vc.present(alert, animated: true)
        }
        else {
            DispatchQueue.main.async {
                self.showAlertWithMainThread(msg: msg, vc: vc)
            }
        }
    }
}
