package com.aliyun.artc.api.advancedusage.CustomVideoCaptureAndRender;

import android.content.res.AssetFileDescriptor;
import android.content.res.AssetManager;
import android.graphics.SurfaceTexture;
import android.media.MediaCodec;
import android.media.MediaExtractor;
import android.media.MediaFormat;
import android.opengl.EGL14;
import android.opengl.EGLConfig;
import android.opengl.EGLContext;
import android.opengl.EGLDisplay;
import android.opengl.EGLSurface;
import android.opengl.GLES11Ext;
import android.opengl.GLES20;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.Process;
import android.util.Log;
import android.view.Surface;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;

/**
 * Mp4 Texture2D 播放器（工具类）
 * 
 * 功能说明：
 *  - 从 assets/video.mp4 解码视频到 OES 纹理
 *  - 在 FBO 中将 OES 渲染为 Texture2D
 *  - 通过回调输出 Texture2D 纹理信息和 EGLContext
 *  - 支持循环播放
 * 
 * 设计原则：
 *  - 不直接依赖 AliRtcEngine，作为独立的纹理转换工具
 *  - 调用方在回调中构建 AliRtcRawDataFrame(Texture2D) 并调用 pushExternalVideoFrame
 * 
 * 技术流程：
 *  MediaCodec 解码 → OES 纹理(SurfaceTexture) → FBO+Shader 渲染 → Texture2D
 * 
 * 使用示例：
 *  Mp4Texture2DPlayer player = new Mp4Texture2DPlayer(
 *      getAssets(),
 *      "video.mp4",
 *      (textureId, width, height, texMatrix, eglContext) -> {
 *          // 在回调中构造 Texture2D 帧并推送给 SDK
 *          AliRtcRawDataFrame frame = new AliRtcRawDataFrame(
 *              textureId,
 *              AliRtcVideoFormatTexture2D,
 *              width, height,
 *              texMatrix,
 *              0, 0, width, height,
 *              eglContext
 *          );
 *          mAliRtcEngine.pushExternalVideoFrame(frame, AliRtcVideoTrackCamera);
 *      }
 *  );
 *  player.start();
 */
public class Mp4Texture2DPlayer {
    private static final String TAG = "Mp4Texture2DPlayer";

    /**
     * Texture2D 帧回调接口
     * 
     * 回调参数说明：
     *  @param textureId   GL_TEXTURE_2D 纹理 ID，已经包含当前帧的视频画面
     *  @param width       视频宽度
     *  @param height      视频高度
     *  @param texMatrix   纹理坐标变换矩阵（4x4，已处理为单位矩阵）
     *  @param eglContext  当前纹理所在的 EGLContext，用于 SDK 共享纹理
     * 
     * 调用方应在此回调中：
     *  1. 构造 AliRtcEngine.AliRtcRawDataFrame（Texture2D 格式）
     *  2. 调用 mAliRtcEngine.pushExternalVideoFrame() 推送给 SDK
     */
    public interface TextureFrameListener {
        void onTextureFrame(int textureId,
                            int width,
                            int height,
                            float[] texMatrix,
                            EGLContext eglContext);
    }

    private final AssetManager assetManager;
    private final String videoFileName;
    private final TextureFrameListener frameListener;

    // GL 相关
    private HandlerThread glThread;
    private Handler glHandler;
    private EGLDisplay eglDisplay = EGL14.EGL_NO_DISPLAY;
    private EGLContext eglContext = EGL14.EGL_NO_CONTEXT;
    private EGLSurface eglSurface = EGL14.EGL_NO_SURFACE;

    // 纹理相关
    private int oesTextureId = -1;          // MediaCodec 输出的 OES 纹理
    private int texture2DId = -1;           // 转换后的 Texture2D
    private int fboId = -1;                 // 帧缓冲对象
    private SurfaceTexture surfaceTexture;
    private Surface decoderSurface;

    // 解码相关
    private MediaExtractor extractor;
    private MediaCodec decoder;
    private Thread playThread;

    // shader 程序
    private int shaderProgram = -1;
    private int aPositionHandle;
    private int aTexCoordHandle;
    private int uTexMatrixHandle;
    private int uTextureHandle;

    private volatile boolean isPlaying = false;
    private int videoWidth = 720;
    private int videoHeight = 1280;

    // 顶点坐标和纹理坐标
    private static final float[] VERTEX_COORDS = {
            -1.0f, -1.0f,
            1.0f, -1.0f,
            -1.0f, 1.0f,
            1.0f, 1.0f,
    };

    private static final float[] TEXTURE_COORDS = {
            0.0f, 0.0f,
            1.0f, 0.0f,
            0.0f, 1.0f,
            1.0f, 1.0f,
    };

    // Vertex Shader：处理顶点坐标和纹理坐标变换
    private static final String VERTEX_SHADER =
            "attribute vec4 aPosition;\n" +
            "attribute vec4 aTexCoord;\n" +
            "uniform mat4 uTexMatrix;\n" +
            "varying vec2 vTexCoord;\n" +
            "void main() {\n" +
            "    gl_Position = aPosition;\n" +
            "    vTexCoord = (uTexMatrix * aTexCoord).xy;\n" +
            "}\n";

    // Fragment Shader：从 OES 纹理采样（需要 GL_OES_EGL_image_external 扩展）
    private static final String FRAGMENT_SHADER =
            "#extension GL_OES_EGL_image_external : require\n" +
            "precision mediump float;\n" +
            "varying vec2 vTexCoord;\n" +
            "uniform samplerExternalOES uTexture;\n" +
            "void main() {\n" +
            "    gl_FragColor = texture2D(uTexture, vTexCoord);\n" +
            "}\n";

    public Mp4Texture2DPlayer(AssetManager assetManager,
                              String videoFileName,
                              TextureFrameListener frameListener) {
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

        // 启动 GL 线程
        glThread = new HandlerThread("Mp4Texture2DGLThread", Process.THREAD_PRIORITY_URGENT_DISPLAY);
        glThread.start();
        glHandler = new Handler(glThread.getLooper());

        glHandler.post(() -> {
            if (!initGLEnvironment()) {
                Log.e(TAG, "Failed to init GL environment");
                isPlaying = false;
                return;
            }

            if (!initMediaComponents()) {
                Log.e(TAG, "Failed to init media components");
                isPlaying = false;
                releaseGLEnvironment();
                return;
            }

            // 启动解码播放线程
            playThread = new Thread(this::decodeAndPushLoop, "Mp4DecodeThread");
            playThread.start();
        });
    }

    public void stop() {
        isPlaying = false;

        if (playThread != null) {
            try {
                playThread.join(2000);
            } catch (InterruptedException e) {
                Log.e(TAG, "playThread join interrupted", e);
            }
            playThread = null;
        }

        if (glHandler != null) {
            glHandler.post(this::releaseMediaComponents);
            glHandler.post(this::releaseGLEnvironment);
        }

        if (glThread != null) {
            glThread.quitSafely();
            try {
                glThread.join();
            } catch (InterruptedException e) {
                Log.e(TAG, "glThread join interrupted", e);
            }
            glThread = null;
            glHandler = null;
        }
    }

    private boolean initGLEnvironment() {
        // 1. 初始化 EGL Display
        eglDisplay = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY);
        if (eglDisplay == EGL14.EGL_NO_DISPLAY) {
            Log.e(TAG, "eglGetDisplay failed");
            return false;
        }

        int[] version = new int[2];
        if (!EGL14.eglInitialize(eglDisplay, version, 0, version, 1)) {
            Log.e(TAG, "eglInitialize failed");
            return false;
        }

        // 2. 选择配置
        int[] configAttribs = {
                EGL14.EGL_RED_SIZE, 8,
                EGL14.EGL_GREEN_SIZE, 8,
                EGL14.EGL_BLUE_SIZE, 8,
                EGL14.EGL_ALPHA_SIZE, 8,
                EGL14.EGL_RENDERABLE_TYPE, EGL14.EGL_OPENGL_ES2_BIT,
                EGL14.EGL_SURFACE_TYPE, EGL14.EGL_PBUFFER_BIT,
                EGL14.EGL_NONE
        };
        EGLConfig[] configs = new EGLConfig[1];
        int[] numConfigs = new int[1];
        EGL14.eglChooseConfig(eglDisplay, configAttribs, 0, configs, 0, 1, numConfigs, 0);
        if (numConfigs[0] == 0) {
            Log.e(TAG, "No EGLConfig found");
            return false;
        }

        // 3. 创建上下文
        int[] contextAttribs = {
                EGL14.EGL_CONTEXT_CLIENT_VERSION, 2,
                EGL14.EGL_NONE
        };
        eglContext = EGL14.eglCreateContext(eglDisplay, configs[0], EGL14.EGL_NO_CONTEXT, contextAttribs, 0);
        if (eglContext == null || eglContext == EGL14.EGL_NO_CONTEXT) {
            Log.e(TAG, "Failed to create EGLContext");
            return false;
        }

        // 4. 创建 Pbuffer Surface
        int[] surfaceAttribs = {EGL14.EGL_WIDTH, 1, EGL14.EGL_HEIGHT, 1, EGL14.EGL_NONE};
        eglSurface = EGL14.eglCreatePbufferSurface(eglDisplay, configs[0], surfaceAttribs, 0);
        if (eglSurface == null || eglSurface == EGL14.EGL_NO_SURFACE) {
            Log.e(TAG, "Failed to create EGLSurface");
            return false;
        }

        // 5. 绑定上下文
        if (!EGL14.eglMakeCurrent(eglDisplay, eglSurface, eglSurface, eglContext)) {
            Log.e(TAG, "eglMakeCurrent failed");
            return false;
        }

        // 6. 创建 OES 纹理（用于接收 MediaCodec 输出）
        oesTextureId = createOESTexture();
        if (oesTextureId == -1) {
            Log.e(TAG, "Failed to create OES texture");
            return false;
        }

        // 7. 创建 SurfaceTexture
        surfaceTexture = new SurfaceTexture(oesTextureId);
        surfaceTexture.setDefaultBufferSize(videoWidth, videoHeight);

        // 8. 编译 shader 程序
        if (!createShaderProgram()) {
            Log.e(TAG, "Failed to create shader program");
            return false;
        }

        Log.d(TAG, "GL environment initialized");
        return true;
    }

    private int createOESTexture() {
        int[] textures = new int[1];
        GLES20.glGenTextures(1, textures, 0);
        int textureId = textures[0];

        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, textureId);
        GLES20.glTexParameterf(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR);
        GLES20.glTexParameterf(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR);
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE);
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE);
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, 0);

        return textureId;
    }

    private boolean createShaderProgram() {
        int vertexShader = loadShader(GLES20.GL_VERTEX_SHADER, VERTEX_SHADER);
        int fragmentShader = loadShader(GLES20.GL_FRAGMENT_SHADER, FRAGMENT_SHADER);

        if (vertexShader == 0 || fragmentShader == 0) {
            return false;
        }

        shaderProgram = GLES20.glCreateProgram();
        GLES20.glAttachShader(shaderProgram, vertexShader);
        GLES20.glAttachShader(shaderProgram, fragmentShader);
        GLES20.glLinkProgram(shaderProgram);

        int[] linkStatus = new int[1];
        GLES20.glGetProgramiv(shaderProgram, GLES20.GL_LINK_STATUS, linkStatus, 0);
        if (linkStatus[0] != GLES20.GL_TRUE) {
            Log.e(TAG, "Could not link program: " + GLES20.glGetProgramInfoLog(shaderProgram));
            GLES20.glDeleteProgram(shaderProgram);
            return false;
        }

        // 获取 handle
        aPositionHandle = GLES20.glGetAttribLocation(shaderProgram, "aPosition");
        aTexCoordHandle = GLES20.glGetAttribLocation(shaderProgram, "aTexCoord");
        uTexMatrixHandle = GLES20.glGetUniformLocation(shaderProgram, "uTexMatrix");
        uTextureHandle = GLES20.glGetUniformLocation(shaderProgram, "uTexture");

        return true;
    }

    private int loadShader(int type, String shaderCode) {
        int shader = GLES20.glCreateShader(type);
        GLES20.glShaderSource(shader, shaderCode);
        GLES20.glCompileShader(shader);

        int[] compiled = new int[1];
        GLES20.glGetShaderiv(shader, GLES20.GL_COMPILE_STATUS, compiled, 0);
        if (compiled[0] == 0) {
            Log.e(TAG, "Could not compile shader: " + GLES20.glGetShaderInfoLog(shader));
            GLES20.glDeleteShader(shader);
            return 0;
        }
        return shader;
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
                    // 获取视频尺寸
                    if (videoFormat.containsKey(MediaFormat.KEY_WIDTH)) {
                        videoWidth = videoFormat.getInteger(MediaFormat.KEY_WIDTH);
                    }
                    if (videoFormat.containsKey(MediaFormat.KEY_HEIGHT)) {
                        videoHeight = videoFormat.getInteger(MediaFormat.KEY_HEIGHT);
                    }
                    break;
                }
            }

            if (videoTrackIndex < 0 || videoFormat == null) {
                Log.e(TAG, "No video track found in " + videoFileName);
                afd.close();
                return false;
            }

            extractor.selectTrack(videoTrackIndex);

            // 创建解码器并配置为输出到 Surface
            decoderSurface = new Surface(surfaceTexture);
            String mime = videoFormat.getString(MediaFormat.KEY_MIME);
            decoder = MediaCodec.createDecoderByType(mime);
            decoder.configure(videoFormat, decoderSurface, null, 0);
            decoder.start();

            // 创建 Texture2D 和 FBO
            if (!createTexture2DAndFBO()) {
                Log.e(TAG, "Failed to create Texture2D and FBO");
                afd.close();
                return false;
            }

            Log.d(TAG, "Media components initialized: " + mime + ", " + videoWidth + "x" + videoHeight);
            afd.close();
            return true;

        } catch (Exception e) {
            Log.e(TAG, "Failed to init media components", e);
            return false;
        }
    }

    private boolean createTexture2DAndFBO() {
        // 创建 Texture2D
        int[] textures = new int[1];
        GLES20.glGenTextures(1, textures, 0);
        texture2DId = textures[0];

        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, texture2DId);
        GLES20.glTexParameterf(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR);
        GLES20.glTexParameterf(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR);
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE);
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE);
        GLES20.glTexImage2D(GLES20.GL_TEXTURE_2D, 0, GLES20.GL_RGBA, videoWidth, videoHeight,
                0, GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, null);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0);

        // 创建 FBO
        int[] fbos = new int[1];
        GLES20.glGenFramebuffers(1, fbos, 0);
        fboId = fbos[0];

        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, fboId);
        GLES20.glFramebufferTexture2D(GLES20.GL_FRAMEBUFFER, GLES20.GL_COLOR_ATTACHMENT0,
                GLES20.GL_TEXTURE_2D, texture2DId, 0);

        int status = GLES20.glCheckFramebufferStatus(GLES20.GL_FRAMEBUFFER);
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0);

        if (status != GLES20.GL_FRAMEBUFFER_COMPLETE) {
            Log.e(TAG, "FBO not complete: " + status);
            return false;
        }

        Log.d(TAG, "Created Texture2D(" + texture2DId + ") and FBO(" + fboId + ")");
        return true;
    }

    private void decodeAndPushLoop() {
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
                        continue;
                    }
                    int sampleSize = extractor.readSampleData(inBuf, 0);
                    long sampleTimeUs = extractor.getSampleTime();

                    if (sampleSize < 0) {
                        // 循环播放：不发送 EOS，seek 回开头，并重置解码器内部状态
                        Log.d(TAG, "End of file reached, looping playback: seekTo(0) and flush decoder");
                        extractor.seekTo(0, MediaExtractor.SEEK_TO_CLOSEST_SYNC);

                        // 清空解码器内部缓冲和参考帧，避免第二轮加速或卡住
                        decoder.flush();

                        // 重置时间基准
                        startPtsUs = -1;
                        startMs = System.currentTimeMillis();
                        continue;
                    } else {
                        decoder.queueInputBuffer(inIndex, 0, sampleSize, sampleTimeUs, 0);
                        extractor.advance();
                    }
                }

                // 输出：渲染一帧到 Surface
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

                    // 渲染到 Surface（更新 OES 纹理）
                    decoder.releaseOutputBuffer(outIndex, true);

                    // 在 GL 线程中转换 OES -> Texture2D 并通过回调交给上层
                    convertAndNotifyFrame();
                }

            } catch (Exception e) {
                Log.e(TAG, "Error in decode loop", e);
                break;
            }
        }

        Log.d(TAG, "Decode loop exited");
    }

    /**
     * 请求进行 OES → Texture2D 转换并通知上层
     */
    private void convertAndNotifyFrame() {
        if (!isPlaying || frameListener == null) {
            return;
        }

        if (glHandler != null) {
            glHandler.post(this::convertOESToTexture2DAndNotify);
        }
    }

    /**
     * 在 GL 线程中执行 OES → Texture2D 转换
     * 
     * 流程：
     *  1. 更新 SurfaceTexture（OES 纹理）
     *  2. 绑定 FBO，使用 shader 将 OES 渲染到 Texture2D
     *  3. 通过回调把 Texture2D + EGLContext 交给上层（Activity）
     */
    private void convertOESToTexture2DAndNotify() {
        try {
            // 确保 GL 上下文
            if (!EGL14.eglMakeCurrent(eglDisplay, eglSurface, eglSurface, eglContext)) {
                Log.e(TAG, "eglMakeCurrent failed: " + EGL14.eglGetError());
                return;
            }

            // 更新 SurfaceTexture（OES 纹理）
            surfaceTexture.updateTexImage();
            float[] transformMatrix = new float[16];
            surfaceTexture.getTransformMatrix(transformMatrix);

            // 绑定 FBO，准备渲染到 Texture2D
            GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, fboId);
            GLES20.glViewport(0, 0, videoWidth, videoHeight);

            // 使用 shader 程序
            GLES20.glUseProgram(shaderProgram);

            // 设置顶点坐标
            FloatBuffer vertexBuffer = ByteBuffer.allocateDirect(VERTEX_COORDS.length * 4)
                    .order(ByteOrder.nativeOrder()).asFloatBuffer();
            vertexBuffer.put(VERTEX_COORDS).position(0);
            GLES20.glEnableVertexAttribArray(aPositionHandle);
            GLES20.glVertexAttribPointer(aPositionHandle, 2, GLES20.GL_FLOAT, false, 0, vertexBuffer);

            // 设置纹理坐标
            FloatBuffer texCoordBuffer = ByteBuffer.allocateDirect(TEXTURE_COORDS.length * 4)
                    .order(ByteOrder.nativeOrder()).asFloatBuffer();
            texCoordBuffer.put(TEXTURE_COORDS).position(0);
            GLES20.glEnableVertexAttribArray(aTexCoordHandle);
            GLES20.glVertexAttribPointer(aTexCoordHandle, 2, GLES20.GL_FLOAT, false, 0, texCoordBuffer);

            // 设置纹理变换矩阵
            GLES20.glUniformMatrix4fv(uTexMatrixHandle, 1, false, transformMatrix, 0);

            // 绑定 OES 纹理
            GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
            GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, oesTextureId);
            GLES20.glUniform1i(uTextureHandle, 0);

            // 绘制
            GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);

            // 解绑 FBO
            GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0);

            // Texture2D 中现在已经是校正后的画面，
            // 上层在使用 SDK 时可以直接使用单位矩阵。
            float[] identityMatrix = {
                    1, 0, 0, 0,
                    0, 1, 0, 0,
                    0, 0, 1, 0,
                    0, 0, 0, 1
            };

            // 通过回调交给上层（Activity）推送到 SDK
            frameListener.onTextureFrame(texture2DId, videoWidth, videoHeight, identityMatrix, eglContext);

        } catch (Exception e) {
            Log.e(TAG, "Error converting OES to Texture2D", e);
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

        if (decoderSurface != null) {
            decoderSurface.release();
            decoderSurface = null;
        }

        if (surfaceTexture != null) {
            surfaceTexture.release();
            surfaceTexture = null;
        }

        if (extractor != null) {
            extractor.release();
            extractor = null;
        }

        Log.d(TAG, "Media components released");
    }

    private void releaseGLEnvironment() {
        if (fboId > 0) {
            GLES20.glDeleteFramebuffers(1, new int[]{fboId}, 0);
            fboId = -1;
        }

        if (texture2DId > 0) {
            GLES20.glDeleteTextures(1, new int[]{texture2DId}, 0);
            texture2DId = -1;
        }

        if (oesTextureId > 0) {
            GLES20.glDeleteTextures(1, new int[]{oesTextureId}, 0);
            oesTextureId = -1;
        }

        if (shaderProgram > 0) {
            GLES20.glDeleteProgram(shaderProgram);
            shaderProgram = -1;
        }

        if (eglDisplay != EGL14.EGL_NO_DISPLAY) {
            EGL14.eglMakeCurrent(eglDisplay, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_CONTEXT);
            if (eglSurface != EGL14.EGL_NO_SURFACE) {
                EGL14.eglDestroySurface(eglDisplay, eglSurface);
                eglSurface = EGL14.EGL_NO_SURFACE;
            }
            if (eglContext != EGL14.EGL_NO_CONTEXT) {
                EGL14.eglDestroyContext(eglDisplay, eglContext);
                eglContext = EGL14.EGL_NO_CONTEXT;
            }
            EGL14.eglTerminate(eglDisplay);
            EGL14.eglReleaseThread();
            eglDisplay = EGL14.EGL_NO_DISPLAY;
        }

        Log.d(TAG, "GL environment released");
    }
}
