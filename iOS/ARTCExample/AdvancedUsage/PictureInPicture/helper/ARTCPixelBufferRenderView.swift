//
//  ARTCPixelBufferRenderView.swift
//  ARTCExample
//
//  Created by wy on 2025/9/3.
//


import UIKit
import AVFoundation

class AliRTCPixelBufferRenderView: UIView {
    var uid: String = ""
    
    private lazy var displayLayer: AVSampleBufferDisplayLayer = {
        let layer = AVSampleBufferDisplayLayer()
        layer.videoGravity = .resizeAspect
        return layer
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }
    
    private func setupLayer() {
        self.layer.addSublayer(displayLayer)
        displayLayer.frame = bounds
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        displayLayer.frame = bounds
    }
    
    /// 渲染 CVPixelBuffer
    func render(pixelBuffer: CVPixelBuffer, width: Int, height: Int) {
        // 创建视频格式描述
        var formatDesc: CMVideoFormatDescription?
        let status = CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDesc
        )
        guard status == noErr, let formatDesc = formatDesc else {
            print("❌ Failed to create CMVideoFormatDescription")
            return
        }
        
        // 时间戳
        let pts = CMTime(seconds: CACurrentMediaTime(), preferredTimescale: 600)
        var timingInfo = CMSampleTimingInfo(
            duration: .invalid,
            presentationTimeStamp: pts,
            decodeTimeStamp: .invalid
        )
        
        // 创建 CMSampleBuffer
        var sampleBuffer: CMSampleBuffer?
        let bufferStatus = CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescription: formatDesc,
            sampleTiming: &timingInfo,
            sampleBufferOut: &sampleBuffer
        )
        
        guard bufferStatus == noErr, let sampleBuffer = sampleBuffer else {
            print("Failed to create CMSampleBuffer")
            return
        }
        
        // 提交到主线程渲染
        DispatchQueue.main.async {
            self.displayLayer.enqueue(sampleBuffer)
        }
        
        // 释放 sampleBuffer 引用
        CMSampleBufferInvalidate(sampleBuffer)
    }
    
    /// 清除画面
    func clear() {
        displayLayer.flushAndRemoveImage()
    }
}
