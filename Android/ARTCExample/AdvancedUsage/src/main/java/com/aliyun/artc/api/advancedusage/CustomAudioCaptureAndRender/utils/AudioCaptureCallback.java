package com.aliyun.artc.api.advancedusage.CustomAudioCaptureAndRender.utils;

public interface AudioCaptureCallback {
    /**
     * 音频采集回调接口
     * @param audioData 音频数据缓冲区
     * @param bytesRead 实际读取的字节数
     * @param sampleRate 采样率
     * @param channels 声道数
     * @param bitsPerSample 采样位数
     */
    void onAudioFrameCaptured(byte[] audioData, int bytesRead, int sampleRate, int channels, int bitsPerSample);
}
