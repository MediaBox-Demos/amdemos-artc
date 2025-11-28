package com.aliyun.artc.api.advancedusage.CustomAudioCaptureAndRender.utils;

import android.content.Context;
import android.content.res.AssetManager;
import android.os.Process;
import android.util.Log;

import java.io.IOException;
import java.io.InputStream;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * 文件读取类，根据传入的时间间隔和文件参数，从assets文件夹中的指定音频文件中读取音频数据
 * 数据通过onAudioFrameCaptured回调返回
 */
public class FileAudioCaptureThread extends Thread {
    private static final String TAG = "FileAudioCapture";
    private String mAudioFileName;

    private AudioCaptureCallback mAudioCaptureCallback;
    private final AtomicBoolean isCapturing = new AtomicBoolean(false);
    private AssetManager assetManager;

    // 音频参数
    private int mSampleRate;
    private int mChannels;
    private int mBitsPerSample;

    // 计算得出的参数
    private int mBytesPerSample;
    private int mBufferSampleCount;
    private int mBufferByteSize;

    private InputStream inputStream;

    public FileAudioCaptureThread(String audioFileName,
                                  Context context,
                                  AudioCaptureCallback callback,
                                  int sampleRate,
                                  int channels,
                                  int bitsPerSample,
                                  int bufferMs) {
        this.mAudioFileName = audioFileName;
        this.assetManager = context.getAssets();
        this.mAudioCaptureCallback = callback;
        this.mSampleRate = sampleRate;
        this.mChannels = channels;

        this.mBitsPerSample = bitsPerSample; // 比特深度，通常位16
        this.mBytesPerSample = mBitsPerSample / 8 * mChannels; // 每个样本字节数，包含多个通道
        this.mBufferSampleCount =  (sampleRate / 1000); // 每ms有多少样本
        this.mBufferByteSize = bufferMs * mBufferSampleCount * mBytesPerSample;  // 缓冲区大小(字节)，用于分配缓冲区，公式：时间*每ms样本数*每个样本字节数
    }

    @Override
    public void run() {
        Process.setThreadPriority(Process.THREAD_PRIORITY_URGENT_AUDIO);

        try {
            inputStream = assetManager.open(mAudioFileName);
        } catch (IOException e) {
            Log.e(TAG, "打开音频文件失败", e);
            return;
        }

        byte[] buffer = new byte[mBufferByteSize];
        isCapturing.set(true);

        long startTime = System.nanoTime(); // 记录开始时间，用于控制播放速度
        long audioTime = 0; // 已播放的音频时间(微秒
        while (isCapturing.get()) {
            try {
                int bytesRead = readAudioFile(buffer);

                // 通过回调传递音频数据而不是直接推送
                if (mAudioCaptureCallback != null && bytesRead > 0) {
                    // 回调传递原始buffer数据和实际读取的字节数
                    mAudioCaptureCallback.onAudioFrameCaptured(
                            buffer,
                            bytesRead,
                            mSampleRate,
                            mChannels,
                            mBitsPerSample
                    );
                }

                // 计算已播放的音频时间
                int samplesRead = bytesRead / mBytesPerSample;
                audioTime += (samplesRead * 1000000L) / mSampleRate; // 转换为微秒

                // 根据实际播放时间控制发送速度
                long elapsedTime = (System.nanoTime() - startTime) / 1000; // 微秒
                long sleepTime = audioTime - elapsedTime;

                if (sleepTime > 0) {
                    // 将微秒转换为毫秒进行休眠
                    Thread.sleep(sleepTime / 1000);
                }
            } catch (InterruptedException e) {
                Log.w(TAG, "文件读取线程被中断", e);
                break;
            }
        }

        // 释放资源
        if (inputStream != null) {
            try {
                inputStream.close();
            } catch (IOException e) {
                Log.e(TAG, "关闭音频文件流失败", e);
            }
        }
    }

    private int readAudioFile(byte[] buffer) {
        try {
            int bytesRead = inputStream.read(buffer);
            if (bytesRead < 0) {
                inputStream.reset();
                return 0;
            }
            return bytesRead;
        } catch (IOException e) {
            Log.e(TAG, "读取音频文件失败", e);
            return 0;
        }
    }

    public void stopCapture() {
        if (!isCapturing.compareAndSet(true, false)) {
            return;
        }

        // 中断线程以确保能及时退出
        interrupt();

        synchronized (this) {
            if (inputStream != null) {
                try {
                    inputStream.close();
                } catch (IOException e) {
                    Log.e(TAG, "关闭音频文件流失败", e);
                } finally {
                    inputStream = null;
                }
            }
        }
    }
}
