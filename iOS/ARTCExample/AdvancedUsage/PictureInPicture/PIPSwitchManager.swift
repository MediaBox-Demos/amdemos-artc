//
//  PIPSwitchManager.swift
//  ARTCExample
//
//  Created by wy on 2025/9/25.
//

import AVKit
import UIKit

class PIPSwitchManager: NSObject {

    private weak var hostVC: UIViewController?
    
    // 当前正在做 PiP 的视图及其原始父视图
    private weak var currentRenderView: VideoRenderView?
    private weak var originalSuperview: UIView?

    private var pipController: AVPictureInPictureController?
    private var callVC: AVPictureInPictureVideoCallViewController?

    init(hostVC: UIViewController) {
        self.hostVC = hostVC
        super.init()
    }

    deinit {
        stopPIP()
        print("❌ PIPSwitchManager 已销毁")
    }

    /// 启动画中画（传入要显示的 VideoRenderView）
    func startPIP(for renderView: VideoRenderView) {
        guard #available(iOS 16.0, *) else {
            DispatchQueue.main.async { [weak self] in
                let alert = UIAlertController(title: "不支持", message: "画中画功能需要 iOS 16 或更高版本", preferredStyle: .alert)
                alert.addAction(.init(title: "确定", style: .default))
                self?.hostVC?.present(alert, animated: true)
            }
            return
        }
        
        guard PIPSwitchManager.isSupported else { return }
        guard pipController == nil else {
            print("⚠️ PiP 已启动，请先停止")
            return
        }

        // 记录当前视图和原始父视图
        self.currentRenderView = renderView
        self.originalSuperview = renderView.superview

        // 创建 PiP 内容控制器
        let pipVC = AVPictureInPictureVideoCallViewController()
        pipVC.view.backgroundColor = .black

        // 设置 ContentSource
        let contentSource = AVPictureInPictureController.ContentSource(
            activeVideoCallSourceView: renderView, // 主界面上的源视图（用于检测大小等）
            contentViewController: pipVC
        )

        let controller = AVPictureInPictureController(contentSource: contentSource)
        controller.delegate = self
        controller.canStartPictureInPictureAutomaticallyFromInline = false

        self.pipController = controller
        self.callVC = pipVC

        // 延迟启动以确保视图已准备就绪
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self, let controller = self.pipController else { return }
            
            if controller.isPictureInPicturePossible {
                print("🔥 正在启动 PIP")
                controller.startPictureInPicture()
            } else {
                print("❌ 启动失败：isPictureInPicturePossible = false")
                self.cleanupResources()
                
                DispatchQueue.main.async { [weak self] in
                    let alert = UIAlertController(title: "无法启动", message: "设备不支持当前画面进入画中画", preferredStyle: .alert)
                    alert.addAction(.init(title: "确定", style: .default))
                    self?.hostVC?.present(alert, animated: true)
                }
            }
        }
    }

    /// 停止画中画
    func stopPIP() {
        guard #available(iOS 16.0, *),
              let controller = pipController,
              controller.isPictureInPictureActive else {
            cleanupResources()
            return
        }
        controller.stopPictureInPicture()
    }

    /// 清理资源（不依赖是否处于 PiP 状态）
    private func cleanupResources() {
        // 移除临时 VC
        if let callVC = callVC, callVC.parent != nil {
            callVC.willMove(toParent: nil)
            callVC.view.removeFromSuperview()
            callVC.removeFromParent()
        }

        pipController = nil
        self.callVC = nil
        self.currentRenderView = nil
        self.originalSuperview = nil
    }

    static var isSupported: Bool {
        if #available(iOS 16.0, *) {
            return AVPictureInPictureController.isPictureInPictureSupported()
        } else {
            return false
        }
    }

    var isActivelyInPIP: Bool {
        if #available(iOS 16.0, *) {
            return pipController?.isPictureInPictureActive == true
        }
        return false
    }
}

// MARK: - AVPictureInPictureControllerDelegate
@available(iOS 16.0, *)
extension PIPSwitchManager: AVPictureInPictureControllerDelegate {

    func pictureInPictureControllerWillStartPictureInPicture(_ controller: AVPictureInPictureController) {
        print("即将开始 PIP")
    }

    func pictureInPictureControllerDidStartPictureInPicture(_ controller: AVPictureInPictureController) {
        print("✅ PiP 已启动")
        guard let renderView = currentRenderView else { return }
           
       // 从原父视图移除
       renderView.removeFromSuperview()
        
        if let pipVC = callVC {
            pipVC.view.addSubview(renderView)
            renderView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                renderView.leadingAnchor.constraint(equalTo: pipVC.view.leadingAnchor),
                renderView.trailingAnchor.constraint(equalTo: pipVC.view.trailingAnchor),
                renderView.topAnchor.constraint(equalTo: pipVC.view.topAnchor),
                renderView.bottomAnchor.constraint(equalTo: pipVC.view.bottomAnchor)
            ])
        }
    }

    func pictureInPictureController(_ controller: AVPictureInPictureController,
                   failedToStartPictureInPictureWithError error: Error) {
        print("❌ PIP 启动失败: \(error)")

        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: "错误", message: "启动画中画失败: \(error.localizedDescription)", preferredStyle: .alert)
            alert.addAction(.init(title: "确定", style: .default))
            self?.hostVC?.present(alert, animated: true)
        }

        cleanupResources()
    }

    func pictureInPictureControllerWillStopPictureInPicture(_ controller: AVPictureInPictureController) {
        print("🛑 PiP 即将停止")
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ controller: AVPictureInPictureController) {
        print("✅ PiP 已停止")

        // 恢复视图到原始位置
        guard let renderView = currentRenderView,
              let originalSuperview = originalSuperview else {
            cleanupResources()
            return
        }

        // 从 PiP 视图中移除
        renderView.removeFromSuperview()

        // 重新加入原父视图
        originalSuperview.addSubview(renderView)
        renderView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            renderView.leadingAnchor.constraint(equalTo: originalSuperview.leadingAnchor),
            renderView.trailingAnchor.constraint(equalTo: originalSuperview.trailingAnchor),
            renderView.topAnchor.constraint(equalTo: originalSuperview.topAnchor),
            renderView.bottomAnchor.constraint(equalTo: originalSuperview.bottomAnchor)
        ])
        
        originalSuperview.setNeedsLayout()
        originalSuperview.layoutIfNeeded()

        // 清理状态
        cleanupResources()
    }

    func pictureInPictureController(_ controller: AVPictureInPictureController,
                   restoreUserInterfaceForPictureInPictureStopWithCompletionHandler handler: @escaping (Bool) -> Void) {
        // 可在此恢复主界面（如导航栏、工具栏），我们不需要特殊操作
        handler(true)
    }
}
