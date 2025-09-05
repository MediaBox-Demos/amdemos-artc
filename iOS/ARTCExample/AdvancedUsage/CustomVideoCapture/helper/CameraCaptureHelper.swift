//
//  CameraCaptureHelper.swift
//  ARTCExample
//
//  Created by wy on 2025/9/1.
//

import Foundation
import AVFoundation

protocol CameraCaptureHelperDelegate: AnyObject {
    func videoCapture(_ capture: CameraCaptureHelper, didCaptureOutputBuffer sampleBuffer: CMSampleBuffer)
}

class CameraCaptureHelper: NSObject {
    
    weak var delegate: CameraCaptureHelperDelegate?
    
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "camera.capture.queue")
    
    private var isRunning = false
    
    deinit {
        videoOutput.setSampleBufferDelegate(nil, queue: nil)
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
        print("CameraCaptureHelper deinit")
    }
    
    // MARK: - Public Methods
    func startCapture() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if !self.isRunning {
                self.setupSession()
                
                self.videoOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
                
                self.captureSession.startRunning()
                self.isRunning = true
            }
        }
    }
    
    func stopCapture() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if self.isRunning, self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
            self.videoOutput.setSampleBufferDelegate(nil, queue: nil)
            self.isRunning = false
        }
    }
    
    // MARK: - Setup Session
    private func setupSession() {
        guard captureSession.isRunning == false else { return }
        
        captureSession.beginConfiguration()
        defer {
            captureSession.commitConfiguration()
        }
        if captureSession.canSetSessionPreset(.hd1280x720) {
            captureSession.sessionPreset = .hd1280x720
        } else if captureSession.canSetSessionPreset(.high) {
            captureSession.sessionPreset = .high
        }
        
        // 添加摄像头输入
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .front) else {
            print("Camera not available")
            captureSession.commitConfiguration()
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            } else {
                print("Cannot add camera input")
            }
        } catch {
            print("Failed to create AVCaptureDeviceInput: $error)")
            captureSession.commitConfiguration()
            return
        }
        
        // 视频输出设置
        let pixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: pixelFormat]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            print("Cannot add video output")
            captureSession.commitConfiguration()
            return
        }
        
        // 提交配置
        captureSession.commitConfiguration()
        print("Camera session configured")
    }
    
    // 将CVPixelBuffer转换为NV12格式的Data
    private func convertCVPixelBufferToNV12Data(_ pixelBuffer: CVPixelBuffer) -> Data? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            print("Failed to get base address")
            return nil
        }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
        
        // 确保是正确的像素格式
        guard pixelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange else {
            print("Unsupported pixel format: $pixelFormat)")
            return nil
        }
        
        // 验证内存大小
        let expectedBytesPerRow = width
        guard bytesPerRow >= expectedBytesPerRow else {
            print("Invalid bytes per row: expected at least $expectedBytesPerRow), got $bytesPerRow)")
            return nil
        }
        
        let ySize = width * height
        let uvSize = ySize / 2 // NV12格式UV平面大小是Y平面的一半
        let totalSize = ySize + uvSize
        
        var nv12Data = Data(count: totalSize)
        
        // 逐行拷贝Y平面数据
        let yPlaneSrc = baseAddress
        nv12Data.withUnsafeMutableBytes { dataPtr in
            guard let dataPtr = dataPtr.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                print("Failed to get data pointer")
                return
            }
            
            // 逐行拷贝Y平面
            for y in 0..<height {
                let srcLine = yPlaneSrc.advanced(by: y * bytesPerRow)
                let dstLine = dataPtr.advanced(by: y * width)
                memcpy(dstLine, srcLine, width)
            }
            
            // 逐行拷贝UV平面
            let uvPlaneSrc = baseAddress.advanced(by: bytesPerRow * height)
            let uvDstPtr = dataPtr.advanced(by: ySize)
            let uvHeight = height / 2
            
            for y in 0..<uvHeight {
                let srcLine = uvPlaneSrc.advanced(by: y * bytesPerRow)
                let dstLine = uvDstPtr.advanced(by: y * width)
                memcpy(dstLine, srcLine, width)
            }
        }
        
        return nv12Data
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraCaptureHelper: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        self.delegate?.videoCapture(self, didCaptureOutputBuffer: sampleBuffer)
    }
}
