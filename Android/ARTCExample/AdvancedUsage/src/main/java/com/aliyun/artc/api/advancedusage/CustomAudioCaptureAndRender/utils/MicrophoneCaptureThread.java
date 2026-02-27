package com.aliyun.artc.api.advancedusage.CustomAudioCaptureAndRender.utils;

import android.content.Context;
import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaRecorder;
import android.os.Environment;
import android.os.Process;
import android.util.Log;

import com.aliyun.artc.api.advancedusage.CustomAudioCaptureAndRender.utils.WavRecorder;

import java.io.File;
import java.io.IOException;
import java.util.concurrent.atomic.AtomicBoolean;

public class MicrophoneCaptureThread extends Thread {
    private static final String TAG = "MicrophoneCapture";

    private AudioCaptureCallback mAudioCaptureCallback;
    private final AtomicBoolean isCapturing = new AtomicBoolean(false);
    private AudioRecord audioRecord;
    private Context context;

    // 音频参数
    private int mSampleRate;
    private int mChannels;
    private int mBitsPerSample;

    // 计算得出的参数
    private int mBytesPerSample;
    private int mBufferSampleCount;
    private int mBufferByteSize;
    private static final int BUFFER_DURATION_MS = 20; // 20ms

    // Dump麦克风数据相关
    private boolean mEnableDumpAudio;
    private String mDumpAudioFileName;
    private WavRecorder wavRecorder;

    public MicrophoneCaptureThread(Context context,
                                   AudioCaptureCallback callback,
                                   int sampleRate,
                                   int channels,
                                   int bitsPerSample,
                                   boolean enableDumpAudio,
                                   String dumpFileName) {
        this.context = context;
        this.mAudioCaptureCallback = callback;
        this.mEnableDumpAudio = enableDumpAudio;
        this.mDumpAudioFileName = dumpFileName;

        // 固定音频参数
        this.mSampleRate = sampleRate;
        this.mChannels = channels;
        this.mBitsPerSample = bitsPerSample;

        // 内部计算参数
        this.mBytesPerSample = mBitsPerSample / 8 * mChannels;
        this.mBufferSampleCount = (int) (mSampleRate * BUFFER_DURATION_MS / 1000.0);
        this.mBufferByteSize = mBufferSampleCount * mBytesPerSample;
    }

    private void initAudioRecord() {
        int channelConfig = mChannels == 1 ? AudioFormat.CHANNEL_IN_MONO : AudioFormat.CHANNEL_IN_STEREO;
        int audioFormat = mBitsPerSample == 16 ? AudioFormat.ENCODING_PCM_16BIT : AudioFormat.ENCODING_PCM_8BIT;
        int minBufferSize = AudioRecord.getMinBufferSize(mSampleRate, channelConfig, audioFormat);
        int bufferSize = Math.max(minBufferSize, mBufferByteSize);

        audioRecord = new AudioRecord(
                MediaRecorder.AudioSource.MIC,
                mSampleRate,
                channelConfig,
                audioFormat,
                bufferSize);
    }

    @Override
    public void run() {
        Process.setThreadPriority(Process.THREAD_PRIORITY_URGENT_AUDIO);

        // 初始化AudioRecord
        initAudioRecord();

        // 打开一个文件用于dump音频数据
        if(mEnableDumpAudio) {
            String fileName = mDumpAudioFileName+"_" + mSampleRate + "_" + mChannels + "_" + System.currentTimeMillis() + ".wav";
            File wavFile = new File(context.getExternalFilesDir(Environment.DIRECTORY_DOCUMENTS), fileName);
            try {
                wavRecorder = new WavRecorder(wavFile, mSampleRate, mChannels, mBitsPerSample);
                Log.d(TAG, "wavFile Created");
            } catch (IOException e) {
                Log.e(TAG, "wavFile Created Failed", e);
            }
        }

        if (audioRecord != null) {
            audioRecord.startRecording();
        }

        byte[] buffer = new byte[mBufferByteSize];
        isCapturing.set(true);

        while (isCapturing.get()) {
            int bytesRead = 0;
            if (audioRecord != null) {
                bytesRead = audioRecord.read(buffer, 0, buffer.length);
            }

            if(mEnableDumpAudio && wavRecorder != null) {
                if(bytesRead > 0) {
                    // 写入 WAV 文件
                    try {
                        wavRecorder.writeAudioData(buffer, bytesRead);
                    } catch (IOException e) {
                        Log.e(TAG, "写入 WAV 文件失败", e);
                    }
                }
            }

            // 通过回调传递音频数据
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
        }

        // 关闭 WAV 录音器（自动回写 header）
        if (wavRecorder != null) {
            try {
                wavRecorder.close();
                Log.i(TAG, "WAV 文件已保存完成");
            } catch (IOException e) {
                Log.e(TAG, "关闭 WAV 文件失败", e);
            }
        }
    }

    public void stopCapture() {
        // 原子性地设置停止标志
        if (!isCapturing.compareAndSet(true, false)) {
            // 如果已经是停止状态，直接返回
            return;
        }

        // 中断线程以确保能及时退出
        interrupt();

        // 在单独的同步块中安全地释放资源
        synchronized (this) {
            if(audioRecord != null) {
                try {
                    if (audioRecord.getRecordingState() == AudioRecord.RECORDSTATE_RECORDING) {
                        audioRecord.stop();
                    }
                    audioRecord.release();
                } catch (Exception e) {
                    Log.e(TAG, "释放AudioRecord失败", e);
                } finally {
                    audioRecord = null;
                }
            }
        }
    }
}
