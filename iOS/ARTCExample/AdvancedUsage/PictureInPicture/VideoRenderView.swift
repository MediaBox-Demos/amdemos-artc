//
//  VideoRenderView.swift
//  ARTCExample
//
//  Created by wy on 2025/9/25.
//

import Foundation
import UIKit
import AVKit

// VideoRenderView.swift

class VideoRenderView: UIView {
    let sampleBufferLayer = AVSampleBufferDisplayLayer()

    override class var layerClass: AnyClass {
        return AVSampleBufferDisplayLayer.self
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }

    private func setupLayer() {
        // 强转为 AVSampleBufferDisplayLayer
        guard let layer = self.layer as? AVSampleBufferDisplayLayer else { return }
        layer.videoGravity = .resizeAspect
    }

    var displayLayer: AVSampleBufferDisplayLayer {
        return self.layer as! AVSampleBufferDisplayLayer
    }

    // MARK: - 外部调用此方法更新画面
    func render(pixelBuffer: CVPixelBuffer, timestamp: CMTime? = nil, frameRate: Int = 20) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.render(pixelBuffer: pixelBuffer, timestamp: timestamp, frameRate: frameRate)
            }
            return
        }

        guard let formatDesc = getCachedFormatDescription(for: pixelBuffer) ?? makeFormatDescription(from: pixelBuffer) else {
            print("Failed to create CMFormatDescription")
            return
        }

        let duration = CMTimeMake(value: 1, timescale: Int32(frameRate))
        let pts = timestamp ?? CMClockGetTime(CMClockGetHostTimeClock())

        var timingInfo = CMSampleTimingInfo(duration: duration,
                                           presentationTimeStamp: pts,
                                           decodeTimeStamp: .invalid)

        var sampleBuffer: CMSampleBuffer?
        CMSampleBufferCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: formatDesc,
            sampleTiming: &timingInfo,
            sampleBufferOut: &sampleBuffer
        )

        if let sb = sampleBuffer {
            displayLayer.enqueue(sb)
        }
    }

    // MARK: - Format Description Cache
    private var cachedFormatDesc: CMFormatDescription?
    private var lastPixelFormat: UInt32 = 0
    private var lastWidth = 0, lastHeight = 0

    private func getCachedFormatDescription(for pb: CVPixelBuffer) -> CMFormatDescription? {
        let w = CVPixelBufferGetWidth(pb)
        let h = CVPixelBufferGetHeight(pb)
        let pf = CVPixelBufferGetPixelFormatType(pb)
        if let desc = cachedFormatDesc,
           w == lastWidth, h == lastHeight, pf == lastPixelFormat {
            return desc
        }
        return nil
    }

    private func makeFormatDescription(from pb: CVPixelBuffer) -> CMFormatDescription? {
        let w = CVPixelBufferGetWidth(pb)
        let h = CVPixelBufferGetHeight(pb)
        let pf = CVPixelBufferGetPixelFormatType(pb)
        
        var desc: CMFormatDescription?
        // 使用 CMVideoFormatDescriptionCreateForImageBuffer 以兼容新旧SDK的像素格式
        let status = CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pb,
            formatDescriptionOut: &desc
        )
        
        if status != noErr {
            print("⚠️ Failed to create format description for image buffer: \(status)")
            // 降级尝试：使用旧方法（兼容某些特殊场景）
            let fallbackStatus = CMVideoFormatDescriptionCreate(
                allocator: kCFAllocatorDefault,
                codecType: pf,
                width: Int32(w),
                height: Int32(h),
                extensions: nil,
                formatDescriptionOut: &desc
            )
            if fallbackStatus != noErr {
                print("❌ Fallback format description creation also failed: \(fallbackStatus)")
                return nil
            }
            print("✅ Fallback to legacy CMVideoFormatDescriptionCreate succeeded")
        }
        
        // 缓存描述及尺寸/像素格式信息
        cachedFormatDesc = desc
        lastWidth = w
        lastHeight = h
        lastPixelFormat = pf
        
        return desc
    }
}
