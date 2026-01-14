package com.aliyun.artc.api.advancedusage.CustomVideoProcess;

import android.content.Context;
import android.util.Log;

import com.alivc.rtc.AliRtcEngine;
import com.aliyun.android.libqueen.QueenEngine;
import com.aliyun.android.libqueen.models.BeautyFilterType;
import com.aliyun.android.libqueen.models.BeautyParams;
import com.aliyun.android.libqueen.models.FaceShapeType;
import com.aliyun.android.libqueen.QueenBeautyEffector;

/**
 * Queen 美颜封装类：
 * - 创建 / 复用 QueenBeautyEffector
 * - 统一处理纹理 / buffer 两种输入
 * - 对应文档中的 QueenBeautyImp 实现
 */
public class QueenBeautyImp {
    private static final String TAG = "QueenBeautyImp";

    private final Context mContext;
    private QueenBeautyEffector mQueenBeautyEffector;

    public QueenBeautyImp(Context context, long glShareContext) {
        // 使用 applicationContext 避免泄漏 Activity
        mContext = context.getApplicationContext();
        ensureQueenEngine(mContext, glShareContext);
        updateQueenEngineParams();
    }

    /**
     * 创建美颜处理器
     * 增加同步锁，防止创建多个
     */
    private synchronized void ensureQueenEngine(Context context, long glShareContext) {
        if (mQueenBeautyEffector == null) {
            try {
                mQueenBeautyEffector = new QueenBeautyEffector();
                // 创建 Queen 引擎
                mQueenBeautyEffector.onCreateEngine(context);
                
                // 高级美颜调试功能（如需可打开）
                // mQueenBeautyEffector.getEngine().enableFacePointDebug(true);    // 开启人脸关键点调试
                // mQueenBeautyEffector.getEngine().enableFaceDetectGPUMode(false);  // 关闭人脸检测 GPU 模式
                
                Log.d(TAG, "QueenBeautyEffector 创建成功, glShareContext=" + glShareContext);
            } catch (Exception ex) {
                Log.e(TAG, "QueenBeautyEffector 创建失败", ex);
            }
        }
    }

    /**
     * 美颜参数设置
     */
    private void updateQueenEngineParams() {
        if (mQueenBeautyEffector == null) {
            return;
        }
        
        QueenEngine queenEngine = mQueenBeautyEffector.getEngine();
        if (queenEngine == null) {
            return;
        }
        
        // 磨皮&锐化，共用一个功能开关
        queenEngine.enableBeautyType(BeautyFilterType.kSkinBuffing, true); // 磨皮开关
        queenEngine.setBeautyParam(BeautyParams.kBPSkinBuffing, 0.85f);    // 磨皮 [0,1]
        queenEngine.setBeautyParam(BeautyParams.kBPSkinSharpen, 0.2f);     // 锐化 [0,1]

        // 美白&红润，共用一个功能开关
        queenEngine.enableBeautyType(BeautyFilterType.kSkinWhiting, true); // 美白开关
        queenEngine.setBeautyParam(BeautyParams.kBPSkinWhitening, 0.5f);   // 美白范围 [0,1]

        // 大眼，瘦脸
        queenEngine.enableBeautyType(BeautyFilterType.kFaceShape, true);
        queenEngine.updateFaceShape(FaceShapeType.typeBigEye, 1.0f);
        queenEngine.updateFaceShape(FaceShapeType.typeCutFace, 1.0f);
        
        Log.d(TAG, "美颜参数设置完成");
    }

    /**
     * 处理帧：根据回调数据类型，区分处理是纹理，还是 buffer
     * 增加同步锁，防止多线程下 mQueenBeautyEffector 已被销毁
     */
    public synchronized boolean onBeautyProcess(AliRtcEngine.AliRtcVideoSample videoSample) {
        if (videoSample == null) {
            return false;
        }

        // 确保引擎已创建（包括 buffer 模式 glContex 为 0 的情况）
        ensureQueenEngine(mContext, videoSample.glContex);
        if (mQueenBeautyEffector == null) {
            Log.e(TAG, "mQueenBeautyEffector is null");
            return false;
        }

        // 更新美颜参数
        updateQueenEngineParams();

        boolean result;
        if (videoSample.glContex != 0 && videoSample.textureid > 0) {
            // 纹理模式
            result = onProcessBeautyTexture(videoSample);
        } else {
            // buffer 模式
            result = onProcessBeautyBuffer(videoSample);
        }
        return result;
    }

    /**
     * 纹理回调的处理
     */
    private boolean onProcessBeautyTexture(AliRtcEngine.AliRtcVideoSample videoSample) {
        boolean result = false;
        boolean isOesTexture =
                videoSample.format == AliRtcEngine.AliRtcVideoFormat.AliRtcVideoFormatTextureOES;

        // 因 Android 相机采集纹理默认是旋转 270 度后的横屏画面，
        // Queen-sdk 内部会自动进行宽高互换。
        // 但此处 videoSample 回调的宽高，rtc-sdk 内部也已进行修正，
        // 因此此处需要手动进行宽高互换。
        int w = isOesTexture ? videoSample.height : videoSample.width;
        int h = isOesTexture ? videoSample.width : videoSample.height;

        int newTexId;
        if (isOesTexture) {
            // OES 纹理处理
            newTexId = mQueenBeautyEffector.onProcessOesTexture(
                    (int) videoSample.textureid,
                    videoSample.matrix,
                    w,
                    h,
                    270,   // 相机默认 270 度
                    0,     // outAngle
                    0      // flipAxis
            );
        } else {
            // 2D 纹理处理
            newTexId = mQueenBeautyEffector.onProcess2DTexture(
                    (int) videoSample.textureid,
                    w,
                    h,
                    270,   // 相机默认 270 度
                    0,     // outAngle
                    0      // flipAxis
            );
        }

        if (newTexId != videoSample.textureid && newTexId > 0) {
            // 修改纹理 id 和格式，告诉上层使用新的 2D 纹理
            videoSample.textureid = newTexId;
            videoSample.format = AliRtcEngine.AliRtcVideoFormat.AliRtcVideoFormatTexture2D;
            result = true;
            Log.d(TAG, "纹理美颜处理成功: oldTexId=" + (int)videoSample.textureid + 
                    ", newTexId=" + newTexId + ", size=" + w + "x" + h);
        }
        return result;
    }

    /**
     * buffer 回调的处理
     */
    private boolean onProcessBeautyBuffer(AliRtcEngine.AliRtcVideoSample videoSample) {
        boolean result = false;
        try {
            // I420 格式常量值：
            // 在 Queen SDK 中，I420 通常使用 0 或者特定的常量值
            // 根据 ARTC SDK 的 AliRtcVideoFormat.AliRtcVideoFormatI420 对应的值是 0
            final int FORMAT_I420 = 0;
            
            int queenResult = mQueenBeautyEffector.onProcessDataBuf(
                    videoSample.data,           // in
                    videoSample.data,           // out（就地修改）
                    FORMAT_I420,                // format: I420 格式
                    videoSample.width,
                    videoSample.height,
                    0, 0, 0, 0
            );
            if (queenResult == 0) { // 0 == QueenResult.QUEEN_OK
                result = true;
                Log.d(TAG, "Buffer 美颜处理成功: size=" + videoSample.width + "x" + videoSample.height);
            } else {
                Log.w(TAG, "Buffer 美颜处理失败: queenResult=" + queenResult);
            }
        } catch (Exception e) {
            Log.e(TAG, "Buffer 美颜处理异常", e);
        }
        return result;
    }

    /**
     * 退出销毁
     * 增加同步锁，防止多线程下 mQueenBeautyEffector 已被销毁
     */
    public synchronized void release() {
        if (mQueenBeautyEffector != null) {
            try {
                mQueenBeautyEffector.onReleaseEngine();
                Log.d(TAG, "QueenBeautyEffector 已释放");
            } catch (Exception e) {
                Log.e(TAG, "释放 QueenBeautyEffector 异常", e);
            }
            mQueenBeautyEffector = null;
        }
    }
}
