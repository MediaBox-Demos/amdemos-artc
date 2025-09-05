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
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
        
        var timingInfo = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: 20),
            presentationTimeStamp: CMClockGetTime(CMClockGetHostTimeClock()),
            decodeTimeStamp: CMTime.invalid
        )
        
        // 创建视频格式描述
        var formatDescription: CMFormatDescription?
        let status = CMVideoFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            codecType: pixelFormat,
            width: Int32(width),
            height: Int32(height),
            extensions: nil,
            formatDescriptionOut: &formatDescription
        )
        
        guard status == noErr, let videoFormatDescription = formatDescription else {
            print("Failed to create video format description")
            return
        }
        
        var sampleBuffer: CMSampleBuffer?
        let status2 = CMSampleBufferCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: videoFormatDescription,
            sampleTiming: &timingInfo,
            sampleBufferOut: &sampleBuffer
        )
        
        if status2 == noErr, let sampleBuffer = sampleBuffer {
            sampleBufferDisplayLayer?.enqueue(sampleBuffer)
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
