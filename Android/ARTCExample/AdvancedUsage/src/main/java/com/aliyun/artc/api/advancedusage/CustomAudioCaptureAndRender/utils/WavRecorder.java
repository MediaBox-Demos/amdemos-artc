package com.aliyun.artc.api.advancedusage.CustomAudioCaptureAndRender.utils;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;


/**
 * 工具类，将麦克风采集的buffer保存为wav文件。
 */
public class WavRecorder {
    private FileOutputStream outputStream;
    private long dataLengthOffset; // 数据长度字段在文件中的偏移位置
    private int totalAudioBytes = 0;
    private final int sampleRate;
    private final int channels;
    private final int bitsPerSample;

    public WavRecorder(File file, int sampleRate, int channels, int bitsPerSample) throws IOException {
        this.sampleRate = sampleRate;
        this.channels = channels;
        this.bitsPerSample = bitsPerSample;
        this.outputStream = new FileOutputStream(file);
        writeWavHeader();
    }

    private void writeWavHeader() throws IOException {
        byte[] buffer = new byte[44];

        // RIFF chunk
        buffer[0] = 'R'; buffer[1] = 'I'; buffer[2] = 'F'; buffer[3] = 'F';
        // Total file size will be filled later: 36 + data_size
        buffer[4] = 0x24; buffer[5] = 0x00; buffer[6] = 0x00; buffer[7] = 0x00; // placeholder

        // Wave format
        buffer[8] = 'W'; buffer[9] = 'A'; buffer[10] = 'V'; buffer[11] = 'E';

        // fmt sub-chunk
        buffer[12] = 'f'; buffer[13] = 'm'; buffer[14] = 't'; buffer[15] = ' ';
        buffer[16] = 0x10; buffer[17] = 0x00; buffer[18] = 0x00; buffer[19] = 0x00; // fmt chunk size (16)

        buffer[20] = 0x01; buffer[21] = 0x00; // Audio format (1 = PCM)
        buffer[22] = (byte) channels; buffer[23] = 0x00; // Channels
        buffer[24] = (byte) (sampleRate & 0xff);
        buffer[25] = (byte) ((sampleRate >> 8) & 0xff);
        buffer[26] = (byte) ((sampleRate >> 16) & 0xff);
        buffer[27] = (byte) ((sampleRate >> 24) & 0xff); // Sample rate
        int byteRate = sampleRate * channels * bitsPerSample / 8;
        buffer[28] = (byte) (byteRate & 0xff);
        buffer[29] = (byte) ((byteRate >> 8) & 0xff);
        buffer[30] = (byte) ((byteRate >> 16) & 0xff);
        buffer[31] = (byte) ((byteRate >> 24) & 0xff); // Byte rate
        int blockAlign = channels * bitsPerSample / 8;
        buffer[32] = (byte) blockAlign; buffer[33] = 0x00; // Block align
        buffer[34] = (byte) bitsPerSample; buffer[35] = 0x00; // Bits per sample

        // data sub-chunk
        buffer[36] = 'd'; buffer[37] = 'a'; buffer[38] = 't'; buffer[39] = 'a';
        buffer[40] = 0x00; buffer[41] = 0x00; buffer[42] = 0x00; buffer[43] = 0x00; // Data size (to be filled)

        outputStream.write(buffer);

        // 记录 data size 字段的偏移位置（从文件开头算起）
        dataLengthOffset = 40;
        totalAudioBytes = 0;
    }

    public void writeAudioData(byte[] data, int length) throws IOException {
        outputStream.write(data, 0, length);
        totalAudioBytes += length;
    }

    public void close() throws IOException {
        // 回写 data chunk size
        FileOutputStream tmpStream = new FileOutputStream(outputStream.getFD());
        tmpStream.getChannel().position(dataLengthOffset);
        tmpStream.write((byte) (totalAudioBytes & 0xff));
        tmpStream.write((byte) ((totalAudioBytes >> 8) & 0xff));
        tmpStream.write((byte) ((totalAudioBytes >> 16) & 0xff));
        tmpStream.write((byte) ((totalAudioBytes >> 24) & 0xff));

        // 回写 RIFF chunk size = 36 + data_size
        long riffChunkSize = 36 + totalAudioBytes;
        tmpStream.getChannel().position(4);
        tmpStream.write((byte) (riffChunkSize & 0xff));
        tmpStream.write((byte) ((riffChunkSize >> 8) & 0xff));
        tmpStream.write((byte) ((riffChunkSize >> 16) & 0xff));
        tmpStream.write((byte) ((riffChunkSize >> 24) & 0xff));

        tmpStream.close();

        outputStream.close();
    }
}