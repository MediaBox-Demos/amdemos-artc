package com.aliyun.artc.api.advancedusage.CustomVideoCaptureAndRender;

import android.content.res.AssetFileDescriptor;
import android.content.res.AssetManager;
import android.media.Image;
import android.media.MediaCodec;
import android.media.MediaExtractor;
import android.media.MediaFormat;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.Process;
import android.util.Log;

import java.nio.ByteBuffer;

/**
 * Mp4 视频播放器（工具类）
 * 
 * 功能说明：
 *  - 从 assets 中指定的 mp4 文件解码视频
 *  - 以 YUV I420 格式，通过回调输出每一帧数据
 *  - 支持循环播放
 * 
 * 设计原则：
 *  - 不依赖 AliRtcEngine，作为独立的解码工具
 *  - 由调用方（例如 CustomVideoCaptureActivity）在回调中
 *    构造 AliRtcRawDataFrame 并调用 pushExternalVideoFrame 推给 RTC SDK
 * 
 * 使用示例：
 *  Mp4TexturePlayer player = new Mp4TexturePlayer(
 *      getAssets(), 
 *      "video.mp4",
 *      (data, width, height, lineSize) -> {
 *          // 在回调中构造帧数据并推送给 SDK
 *          AliRtcEngine.AliRtcVideoFormat format = AliRtcVideoFormatI420;
 *          AliRtcEngine.AliRtcRawDataFrame frame = new AliRtcRawDataFrame(
 *              data, format, width, height, lineSize, 0, data.length
 *          );
 *          mAliRtcEngine.pushExternalVideoFrame(frame, AliRtcVideoTrackCamera);
 *      }
 *  );
 *  player.start();
 */
public class Mp4TexturePlayer {
    private static final String TAG = "Mp4TexturePlayer";

    /**
     * 解码后的 YUV 帧回调接口
     * 
     * 回调参数说明：
     *  @param data     连续的 I420 数据(Y + U + V)，长度 = width*height*3/2
     *  @param width    视频宽度
     *  @param height   视频高度
     *  @param lineSize 各平面的步长数组 {strideY, strideU, strideV}，
     *                  通常为 {width, width/2, width/2}
     * 
     * 调用方应在此回调中：
     *  1. 构造 AliRtcEngine.AliRtcRawDataFrame
     *  2. 调用 mAliRtcEngine.pushExternalVideoFrame() 推送给 SDK
     */
    public interface YuvFrameListener {
        void onYuvFrame(byte[] data, int width, int height, int[] lineSize);
    }

    private final AssetManager assetManager;
    private final String videoFileName;
    private final YuvFrameListener frameListener;

    private HandlerThread decodeThread;
    private MediaExtractor extractor;
    private MediaCodec decoder;

    private volatile boolean isPlaying = false;

    public Mp4TexturePlayer(AssetManager assetManager,
                            String videoFileName,
                            YuvFrameListener frameListener) {
        this.assetManager = assetManager;
        this.videoFileName = videoFileName;
        this.frameListener = frameListener;
    }

    public void start() {
        if (isPlaying) {
            Log.w(TAG, "Already playing");
            return;
        }
        isPlaying = true;

        // 启动解码线程
        decodeThread = new HandlerThread("Mp4DecodeThread", Process.THREAD_PRIORITY_URGENT_DISPLAY);
        decodeThread.start();
        Handler handler = new Handler(decodeThread.getLooper());
        handler.post(this::decodeAndPushLoop);
    }

    public void stop() {
        isPlaying = false;

        if (decodeThread != null) {
            decodeThread.quitSafely();
            try {
                decodeThread.join(2000);
            } catch (InterruptedException e) {
                Log.e(TAG, "decodeThread join interrupted", e);
            }
            decodeThread = null;
        }
    }

    private void decodeAndPushLoop() {
        try {
            if (!initMediaComponents()) {
                Log.e(TAG, "Failed to init media components");
                return;
            }

            long startPtsUs = -1;
            long startMs = System.currentTimeMillis();
            MediaCodec.BufferInfo info = new MediaCodec.BufferInfo();

            while (isPlaying) {
                try {
                    // 输入：从 extractor 读数据喂给 codec
                    int inIndex = decoder.dequeueInputBuffer(10_000);
                    if (inIndex >= 0) {
                        ByteBuffer inBuf = decoder.getInputBuffer(inIndex);
                        if (inBuf == null) {
                            Log.e(TAG, "Input buffer is null");
                            continue;
                        }
                        int sampleSize = extractor.readSampleData(inBuf, 0);
                        long sampleTimeUs = extractor.getSampleTime();

                        if (sampleSize < 0) {
                            // 循环播放：不发送 EOS，seek 回开头，并重置解码器内部状态
                            Log.d(TAG, "End of file reached, looping playback: seekTo(0) and flush decoder");
                            extractor.seekTo(0, MediaExtractor.SEEK_TO_CLOSEST_SYNC);
                        
                            // 清空解码器内部缓冲和时间戳状态，准备下一轮解码
                            decoder.flush();
                        
                            // 重置时间基准，让第二轮从头开始按正常速度播放
                            startPtsUs = -1;
                            startMs = System.currentTimeMillis();
                            continue;
                        } else {
                            decoder.queueInputBuffer(inIndex, 0, sampleSize, sampleTimeUs, 0);
                            extractor.advance();
                        }
                    }

                    // 输出：获取解码后的 YUV 数据
                    int outIndex = decoder.dequeueOutputBuffer(info, 10_000);
                    if (outIndex >= 0) {
                        // 控制播放节奏
                        if (startPtsUs < 0) {
                            startPtsUs = info.presentationTimeUs;
                            startMs = System.currentTimeMillis();
                        }
                        long ptsMs = (info.presentationTimeUs - startPtsUs) / 1000;
                        long now = System.currentTimeMillis() - startMs;
                        if (ptsMs > now) {
                            Thread.sleep(ptsMs - now);
                        }

                        // 获取 YUV 数据并通过回调交给调用方
                        Image image = decoder.getOutputImage(outIndex);
                        if (image != null) {
                            notifyYuvFrameToListener(image);
                            image.close();
                        }

                        decoder.releaseOutputBuffer(outIndex, false);
                    } else if (outIndex == MediaCodec.INFO_TRY_AGAIN_LATER) {
                        // 正常情况，继续
                    } else if (outIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                        MediaFormat newFormat = decoder.getOutputFormat();
                        Log.d(TAG, "Output format changed: " + newFormat);
                    }

                } catch (Exception e) {
                    Log.e(TAG, "Error in decode loop", e);
                    break;
                }
            }

            Log.d(TAG, "Decode loop exited");

        } finally {
            releaseMediaComponents();
        }
    }

    private boolean initMediaComponents() {
        try {
            AssetFileDescriptor afd = assetManager.openFd(videoFileName);
            extractor = new MediaExtractor();
            extractor.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());

            int videoTrackIndex = -1;
            MediaFormat videoFormat = null;
            for (int i = 0; i < extractor.getTrackCount(); i++) {
                MediaFormat format = extractor.getTrackFormat(i);
                String mime = format.getString(MediaFormat.KEY_MIME);
                if (mime != null && mime.startsWith("video/")) {
                    videoTrackIndex = i;
                    videoFormat = format;
                    break;
                }
            }

            if (videoTrackIndex < 0 || videoFormat == null) {
                Log.e(TAG, "No video track found in " + videoFileName);
                afd.close();
                return false;
            }

            extractor.selectTrack(videoTrackIndex);

            // 创建解码器，输出到 YUV Buffer
            String mime = videoFormat.getString(MediaFormat.KEY_MIME);
            decoder = MediaCodec.createDecoderByType(mime);
            decoder.configure(videoFormat, null, null, 0);  // surface 参数为 null，输出到 Buffer
            decoder.start();

            Log.d(TAG, "Media components initialized: " + mime);
            afd.close();
            return true;

        } catch (Exception e) {
            Log.e(TAG, "Failed to init media components", e);
            return false;
        }
    }

    /**
     * 从 Image 中提取 YUV I420 数据，并通过回调通知给上层
     * 
     * 处理流程：
     *  1. 从 Image.Plane 中分别提取 Y/U/V 三个平面的数据
     *  2. 根据 stride 和 pixelStride 将数据拷贝为连续的 I420 格式
     *  3. 通过 YuvFrameListener 回调通知上层
     */
    private void notifyYuvFrameToListener(Image image) {
        if (!isPlaying || frameListener == null || image == null) {
            return;
        }

        try {
            Image.Plane[] planes = image.getPlanes();
            if (planes.length < 3) {
                Log.e(TAG, "Invalid plane count: " + planes.length);
                return;
            }

            ByteBuffer bufferY = planes[0].getBuffer();
            ByteBuffer bufferU = planes[1].getBuffer();
            ByteBuffer bufferV = planes[2].getBuffer();

            int width = image.getWidth();
            int height = image.getHeight();

            int yRowStride = planes[0].getRowStride();
            int uRowStride = planes[1].getRowStride();
            int vRowStride = planes[2].getRowStride();
            int yPixelStride = planes[0].getPixelStride();
            int uPixelStride = planes[1].getPixelStride();
            int vPixelStride = planes[2].getPixelStride();

            int ySize = width * height;
            int uSize = width * height / 4;
            int vSize = width * height / 4;
            byte[] yuvData = new byte[ySize + uSize + vSize];

            // 拷贝 Y 平面
            for (int i = 0; i < height; i++) {
                int srcPos = i * yRowStride;
                int dstPos = i * width;
                if (yPixelStride == 1) {
                    bufferY.position(srcPos);
                    bufferY.get(yuvData, dstPos, width);
                } else {
                    for (int j = 0; j < width; j++) {
                        yuvData[dstPos + j] = bufferY.get(srcPos + j * yPixelStride);
                    }
                }
            }

            // 拷贝 U 平面
            int uOffset = ySize;
            for (int i = 0; i < height / 2; i++) {
                int srcPos = i * uRowStride;
                int dstPos = uOffset + i * (width / 2);
                if (uPixelStride == 1) {
                    bufferU.position(srcPos);
                    bufferU.get(yuvData, dstPos, width / 2);
                } else {
                    for (int j = 0; j < width / 2; j++) {
                        yuvData[dstPos + j] = bufferU.get(srcPos + j * uPixelStride);
                    }
                }
            }

            // 拷贝 V 平面
            int vOffset = ySize + uSize;
            for (int i = 0; i < height / 2; i++) {
                int srcPos = i * vRowStride;
                int dstPos = vOffset + i * (width / 2);
                if (vPixelStride == 1) {
                    bufferV.position(srcPos);
                    bufferV.get(yuvData, dstPos, width / 2);
                } else {
                    for (int j = 0; j < width / 2; j++) {
                        yuvData[dstPos + j] = bufferV.get(srcPos + j * vPixelStride);
                    }
                }
            }

            int[] lineSize = {width, width / 2, width / 2};

            // 通过回调交给上层（Activity）去构造 AliRtcRawDataFrame 并 push
            frameListener.onYuvFrame(yuvData, width, height, lineSize);

        } catch (Exception e) {
            Log.e(TAG, "Error extracting YUV frame", e);
        }
    }

    private void releaseMediaComponents() {
        if (decoder != null) {
            try {
                decoder.stop();
                decoder.release();
            } catch (Exception e) {
                Log.e(TAG, "decoder release error", e);
            }
            decoder = null;
        }

        if (extractor != null) {
            extractor.release();
            extractor = null;
        }

        Log.d(TAG, "Media components released");
    }
}
