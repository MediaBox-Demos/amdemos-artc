//
//  CustomVideoRenderSeatView.swift
//  ARTCExample
//
//  Created by wy on 2025/9/3.
//

import Foundation
import UIKit
import MetalKit
import AVFoundation
import AliVCSDK_ARTC

class CustomVideoRenderSeatView: UIView {
    // 保留canvasView以支持SDK内部渲染
    private var canvasView: UIView!
    private var sampleBufferDisplayLayer: AVSampleBufferDisplayLayer?
    private var uidLabel: UILabel!
    
    var uid: String = "" {
        didSet {
            uidLabel.text = uid
        }
    }
    
    // 提供对canvasView的访问以便SDK渲染
    var renderingView: UIView {
        return canvasView
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // 创建canvasView用于SDK内部渲染
        canvasView = UIView()
        canvasView.backgroundColor = UIColor.black
        addSubview(canvasView)
        
        // 创建并配置 AVSampleBufferDisplayLayer用于自定义渲染
        sampleBufferDisplayLayer = AVSampleBufferDisplayLayer()
        sampleBufferDisplayLayer?.videoGravity = .resizeAspect
        sampleBufferDisplayLayer?.frame = bounds
        layer.addSublayer(sampleBufferDisplayLayer!)
        
        // 创建并配置 uidLabel
        uidLabel = UILabel()
        uidLabel.textColor = .white
        uidLabel.font = UIFont.systemFont(ofSize: 12)
        uidLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        uidLabel.textAlignment = .center
        
        addSubview(uidLabel)
        
        // 添加约束
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        uidLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            canvasView.leadingAnchor.constraint(equalTo: leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: trailingAnchor),
            canvasView.topAnchor.constraint(equalTo: topAnchor),
            canvasView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            uidLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            uidLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            uidLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            uidLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        sampleBufferDisplayLayer?.frame = bounds
    }
    
    func renderPixelBuffer(_ pixelBuffer: CVPixelBuffer) {
        // 确保在主线程执行
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.renderPixelBuffer(pixelBuffer)
            }
            return
        }
        
        // 使用自定义渲染时隐藏 canvasView
        if canvasView.isHidden == false {
            canvasView.isHidden = true
        }
        
        // 获取 pixelBuffer 的格式信息
        let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
        
        // 创建视频格式描述
        var formatDescription: CMFormatDescription?
        let status = CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDescription
        )
        
        guard status == noErr, let videoFormatDescription = formatDescription else {
            print("Failed to create video format description, status: \(status), format: \(pixelFormat)")
            return
        }
        
        // 创建 timing 信息
        var timingInfo = CMSampleTimingInfo(
            duration: CMTime.invalid,
            presentationTimeStamp: CMClockGetTime(CMClockGetHostTimeClock()),
            decodeTimeStamp: CMTime.invalid
        )
        
        // 创建 sample buffer
        var sampleBuffer: CMSampleBuffer?
        let status2 = CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescription: videoFormatDescription,
            sampleTiming: &timingInfo,
            sampleBufferOut: &sampleBuffer
        )
        
        if status2 == noErr, let sampleBuffer = sampleBuffer {
            if let displayLayer = sampleBufferDisplayLayer {
                // 确保 layer 可见
                displayLayer.isHidden = false
                displayLayer.opacity = 1.0
                
                // 设置正确的视频方向
                var attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: true)
                if let attachments = attachments as? [[CFString: Any]] {
                    var dict = attachments[0]
                    dict[kCMSampleAttachmentKey_DisplayImmediately] = kCFBooleanTrue
                }
                
                // 显示新的帧
                displayLayer.enqueue(sampleBuffer)
            }
        } else {
            print("Failed to create sample buffer, status: \(status2)")
        }
    }
    
    // 渲染I420格式数据
    func renderI420Data(width: Int, height: Int, dataY: UnsafePointer<UInt8>, dataU: UnsafePointer<UInt8>, dataV: UnsafePointer<UInt8>, strideY: Int, strideU: Int, strideV: Int) {
        // 在后台线程处理图像数据
        DispatchQueue.global(qos: .userInitiated).async {
            // 创建YUV数据的CVPixelBuffer
            var pixelBuffer: CVPixelBuffer?
            let status = CVPixelBufferCreate(
                kCFAllocatorDefault,
                width,
                height,
                kCVPixelFormatType_420YpCbCr8Planar,
                nil,
                &pixelBuffer
            )
            
            if status == kCVReturnSuccess, let pixelBuffer = pixelBuffer {
                CVPixelBufferLockBaseAddress(pixelBuffer, [])
                
                // 复制Y平面数据
                let yDest = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0)
                let yBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
                for i in 0..<height {
                    memcpy(
                        yDest!.advanced(by: i * yBytesPerRow),
                        dataY.advanced(by: i * strideY),
                        width
                    )
                }
                
                // 复制U平面数据
                let uDest = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1)
                let uBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1)
                for i in 0..<height/2 {
                    memcpy(
                        uDest!.advanced(by: i * uBytesPerRow),
                        dataU.advanced(by: i * strideU),
                        width / 2
                    )
                }
                
                // 复制V平面数据
                let vDest = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 2)
                let vBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 2)
                for i in 0..<height/2 {
                    memcpy(
                        vDest!.advanced(by: i * vBytesPerRow),
                        dataV.advanced(by: i * strideV),
                        width / 2
                    )
                }
                
                CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
                
                // 在主线程更新UI
                DispatchQueue.main.async {
                    self.renderPixelBuffer(pixelBuffer)
                }
            }
        }
    }
    
    // 渲染NV12格式数据
    func renderNV12Data(width: Int, height: Int, dataY: UnsafePointer<UInt8>, dataUV: UnsafePointer<UInt8>, strideY: Int, strideUV: Int) {
        // 在后台线程处理图像数据
        DispatchQueue.global(qos: .userInitiated).async {
            // 创建YUV数据的CVPixelBuffer
            var pixelBuffer: CVPixelBuffer?
            let status = CVPixelBufferCreate(
                kCFAllocatorDefault,
                width,
                height,
                kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
                nil,
                &pixelBuffer
            )
            
            if status == kCVReturnSuccess, let pixelBuffer = pixelBuffer {
                CVPixelBufferLockBaseAddress(pixelBuffer, [])
                
                // 复制Y平面数据
                let yDest = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0)
                let yBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
                for i in 0..<height {
                    memcpy(
                        yDest!.advanced(by: i * yBytesPerRow),
                        dataY.advanced(by: i * strideY),
                        width
                    )
                }
                
                // 复制UV平面数据 (NV12格式中UV是交错存储的)
                let uvDest = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1)
                let uvBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1)
                for i in 0..<height/2 {
                    memcpy(
                        uvDest!.advanced(by: i * uvBytesPerRow),
                        dataUV.advanced(by: i * strideUV),
                        width
                    )
                }
                
                CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
                
                // 在主线程更新UI
                DispatchQueue.main.async {
                    self.renderPixelBuffer(pixelBuffer)
                }
            }
        }
    }
}
