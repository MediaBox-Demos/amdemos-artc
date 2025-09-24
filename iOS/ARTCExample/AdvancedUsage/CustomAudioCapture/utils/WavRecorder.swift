//
//  WavRecorder.swift
//  ARTCExample
//
//  Created by wy on 2025/9/3.
//

import Foundation

class WavRecorder {
    private var fileHandle: FileHandle?
    private var headerSize = 44 // 标准wav头大小
    private var totalAudioBytesWritten: Int = 0
    private var isRecording = false
    
    private let sampleRate: Int32
    private let channels: Int32
    private let bytesPerSample: Int32 = 2 // 16bit
    
    private let fileName: String
    
    init(sampleRate: Int32 = 48000, channels: Int32 = 1, fileName: String = "audio_dump") {
        self.sampleRate = sampleRate
        self.channels = channels
        self.fileName = fileName
    }
    
    /// 开始录制
    func startRecording() -> Bool {
        guard !isRecording else {return false}
        
        guard let fileURL = getDocumentsDirectory().appendingPathComponent("\(fileName).wav") as URL? else {
            print("无法生成文件 URL")
            return false
        }
        
        // 删除旧文件
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.removeItem(at: fileURL)
        }
        
        // 创建空文件
        fileManager.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
        
        guard let handle = try? FileHandle(forWritingTo: fileURL) else {
            print("无法创建文件句柄")
            return false
        }
        
        self.fileHandle = handle
        self.totalAudioBytesWritten = 0
        self.isRecording = true
        
        // 写入占位头部
        let placeholder = Data(repeating: 0, count: headerSize)
        handle.write(placeholder)
        
        print("WAVRecorder: 开始录制，文件路径： \(fileURL.path)")
        return true
    }
    
    /// 写入
    func writeAudioData(_ data: Data) {
        guard isRecording, let handle = fileHandle else { return }
        handle.write(data)
        totalAudioBytesWritten += data.count
    }

    /// 停止录制并更新 WAV 头部
    func stopRecording() {
        guard isRecording, let handle = fileHandle else { return }

        // 更新 WAV 头部
        updateWAVHeader(in: handle)

        // 关闭文件
        handle.closeFile()
        self.fileHandle = nil
        self.isRecording = false

        print("WAVRecorder: 录制完成，总写入字节数: \(totalAudioBytesWritten)")
    }

    /// 获取输出文件的完整路径（用于调试或分享）
    func getRecordedFilePath() -> String? {
        let fileURL = getDocumentsDirectory().appendingPathComponent("\(fileName).wav")
        return FileManager.default.fileExists(atPath: fileURL.path) ? fileURL.path : nil
    }

    // MARK: - Private Helpers

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private func updateWAVHeader(in handle: FileHandle) {
        var header = [UInt8](repeating: 0, count: headerSize)

        // RIFF
        writeString(&header, offset: 0, string: "RIFF")
        writeInt32LE(&header, offset: 4, value: UInt32(totalAudioBytesWritten + 36))
        writeString(&header, offset: 8, string: "WAVE")

        // fmt
        writeString(&header, offset: 12, string: "fmt ")
        writeInt32LE(&header, offset: 16, value: 16)
        writeInt16LE(&header, offset: 20, value: 1) // PCM
        writeInt16LE(&header, offset: 22, value: Int16(channels))
        writeInt32LE(&header, offset: 24, value: UInt32(sampleRate))
        writeInt32LE(&header, offset: 28, value: UInt32(sampleRate * bytesPerSample * channels))
        writeInt16LE(&header, offset: 32, value: Int16(bytesPerSample * channels))
        writeInt16LE(&header, offset: 34, value: Int16(bytesPerSample * 8))

        // data
        writeString(&header, offset: 36, string: "data")
        writeInt32LE(&header, offset: 40, value: UInt32(totalAudioBytesWritten))

        // 写回头部
        handle.seek(toFileOffset: 0)
        handle.write(Data(header))
    }

    private func writeInt16LE(_ bytes: inout [UInt8], offset: Int, value: Int16) {
        bytes[offset] = UInt8(value & 0xff)
        bytes[offset + 1] = UInt8((value >> 8) & 0xff)
    }

    private func writeInt32LE(_ bytes: inout [UInt8], offset: Int, value: UInt32) {
        bytes[offset] = UInt8(value & 0xff)
        bytes[offset + 1] = UInt8((value >> 8) & 0xff)
        bytes[offset + 2] = UInt8((value >> 16) & 0xff)
        bytes[offset + 3] = UInt8((value >> 24) & 0xff)
    }

    private func writeString(_ bytes: inout [UInt8], offset: Int, string: String) {
        let data = Array(string.utf8)
        for i in 0..<min(data.count, 4) {
            bytes[offset + i] = data[i]
        }
    }
}
