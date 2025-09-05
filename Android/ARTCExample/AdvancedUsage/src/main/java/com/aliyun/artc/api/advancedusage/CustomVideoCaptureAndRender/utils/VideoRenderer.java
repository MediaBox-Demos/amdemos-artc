// VideoRenderer.java
package com.aliyun.artc.api.advancedusage.CustomVideoCaptureAndRender.utils;

import android.opengl.GLES20;
import android.opengl.GLSurfaceView;
import android.util.Log;

import com.alivc.rtc.AliRtcEngine;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;

import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

public class VideoRenderer implements GLSurfaceView.Renderer {
    private static final String TAG = "VideoRenderer";

    // 顶点着色器
    private static final String VERTEX_SHADER_CODE =
            "attribute vec4 aPosition;" +
                    "attribute vec2 aTexCoord;" +
                    "varying vec2 vTexCoord;" +
                    "void main() {" +
                    "  gl_Position = aPosition;" +
                    "  vTexCoord = aTexCoord;" +
                    "}";

    // I420 (YUV420P) 转 RGB 片段着色器
    private static final String YUV_FRAGMENT_SHADER_CODE =
            "precision mediump float;" +
                    "varying vec2 vTexCoord;" +
                    "uniform sampler2D uYTexture;" +
                    "uniform sampler2D uUTexture;" +
                    "uniform sampler2D uVTexture;" +
                    "const mat3 yuv2rgb = mat3(" +
                    "    1.0,     1.0,       1.0," +
                    "    0.0,     -0.34414,  1.772," +
                    "    1.402,  -0.71414,  0.0" +
                    ");" +
                    "void main() {" +
                    "  float y = texture2D(uYTexture, vTexCoord).r;" +
                    "  float u = texture2D(uUTexture, vTexCoord).r - 0.5;" +
                    "  float v = texture2D(uVTexture, vTexCoord).r - 0.5;" +
                    "  vec3 rgb = yuv2rgb * vec3(y, u, v);" +
                    "  gl_FragColor = vec4(rgb, 1.0);" +
                    "}";

    // 顶点坐标（全屏四边形）
    private final float[] vertices = {
            -1.0f, -1.0f,
            1.0f, -1.0f,
            -1.0f,  1.0f,
            1.0f,  1.0f
    };

    // 纹理坐标（正向）
    private final float[] texCoords = {
            0.0f, 1.0f,
            1.0f, 1.0f,
            0.0f, 0.0f,
            1.0f, 0.0f
    };

    private FloatBuffer vertexBuffer;
    private FloatBuffer textureBuffer;

    private int program;
    private int positionHandle;
    private int texCoordHandle;
    private int yTextureHandle;
    private int uTextureHandle;
    private int vTextureHandle;

    private int[] yTexture = new int[1];
    private int[] uTexture = new int[1];
    private int[] vTexture = new int[1];

    // 当前帧数据（双缓冲）
    private volatile ByteBuffer yFrame;
    private volatile ByteBuffer uFrame;
    private volatile ByteBuffer vFrame;
    private volatile int frameWidth = 640;
    private volatile int frameHeight = 480;

    // 重用的ByteBuffer，避免频繁分配内存
    private ByteBuffer yBuffer;
    private ByteBuffer uBuffer;
    private ByteBuffer vBuffer;
    private int bufferWidth = 0;
    private int bufferHeight = 0;

    private final Object frameLock = new Object();

    public VideoRenderer() {
        vertexBuffer = ByteBuffer.allocateDirect(vertices.length * 4)
                .order(ByteOrder.nativeOrder())
                .asFloatBuffer();
        vertexBuffer.put(vertices);
        vertexBuffer.position(0);

        textureBuffer = ByteBuffer.allocateDirect(texCoords.length * 4)
                .order(ByteOrder.nativeOrder())
                .asFloatBuffer();
        textureBuffer.put(texCoords);
        textureBuffer.position(0);
    }

    @Override
    public void onSurfaceCreated(GL10 gl, EGLConfig config) {
        GLES20.glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        checkGLError("glClearColor");

        program = loadProgram(VERTEX_SHADER_CODE, YUV_FRAGMENT_SHADER_CODE);
        if (program == 0) {
            Log.e(TAG, "Failed to create OpenGL program");
            return;
        }

        positionHandle = GLES20.glGetAttribLocation(program, "aPosition");
        texCoordHandle = GLES20.glGetAttribLocation(program, "aTexCoord");
        yTextureHandle = GLES20.glGetUniformLocation(program, "uYTexture");
        uTextureHandle = GLES20.glGetUniformLocation(program, "uUTexture");
        vTextureHandle = GLES20.glGetUniformLocation(program, "uVTexture");

        // 创建 Y、U、V 纹理
        GLES20.glGenTextures(1, yTexture, 0);
        GLES20.glGenTextures(1, uTexture, 0);
        GLES20.glGenTextures(1, vTexture, 0);

        setupTexture(yTexture[0]);
        setupTexture(uTexture[0]);
        setupTexture(vTexture[0]);
        checkGLError("onSurfaceCreated");
    }

    @Override
    public void onSurfaceChanged(GL10 gl, int width, int height) {
        GLES20.glViewport(0, 0, width, height);
        checkGLError("glViewport");
    }

    @Override
    public void onDrawFrame(GL10 gl) {
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT);
        checkGLError("glClear");

        ByteBuffer yBuf, uBuf, vBuf;
        int w, h;
        synchronized (frameLock) {
            if (yFrame == null || uFrame == null || vFrame == null) return;
            yBuf = yFrame;
            uBuf = uFrame;
            vBuf = vFrame;
            w = frameWidth;
            h = frameHeight;
        }

        GLES20.glUseProgram(program);
        checkGLError("glUseProgram");

        // 启用顶点
        GLES20.glEnableVertexAttribArray(positionHandle);
        GLES20.glVertexAttribPointer(positionHandle, 2, GLES20.GL_FLOAT, false, 8, vertexBuffer);

        GLES20.glEnableVertexAttribArray(texCoordHandle);
        GLES20.glVertexAttribPointer(texCoordHandle, 2, GLES20.GL_FLOAT, false, 8, textureBuffer);

        // 上传 Y 纹理
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, yTexture[0]);
        GLES20.glTexImage2D(GLES20.GL_TEXTURE_2D, 0, GLES20.GL_LUMINANCE, w, h, 0,
                GLES20.GL_LUMINANCE, GLES20.GL_UNSIGNED_BYTE, yBuf);
        GLES20.glUniform1i(yTextureHandle, 0);

        // 上传 U 纹理
        GLES20.glActiveTexture(GLES20.GL_TEXTURE1);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, uTexture[0]);
        GLES20.glTexImage2D(GLES20.GL_TEXTURE_2D, 0, GLES20.GL_LUMINANCE, w / 2, h / 2, 0,
                GLES20.GL_LUMINANCE, GLES20.GL_UNSIGNED_BYTE, uBuf);
        GLES20.glUniform1i(uTextureHandle, 1);

        // 上传 V 纹理
        GLES20.glActiveTexture(GLES20.GL_TEXTURE2);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, vTexture[0]);
        GLES20.glTexImage2D(GLES20.GL_TEXTURE_2D, 0, GLES20.GL_LUMINANCE, w / 2, h / 2, 0,
                GLES20.GL_LUMINANCE, GLES20.GL_UNSIGNED_BYTE, vBuf);
        GLES20.glUniform1i(vTextureHandle, 2);

        // 绘制
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);
        checkGLError("glDrawArrays");

        // 禁用
        GLES20.glDisableVertexAttribArray(positionHandle);
        GLES20.glDisableVertexAttribArray(texCoordHandle);
    }

    /**
     * 接收 AliRtcVideoSample 并渲染（I420 格式）
     */
    public void drawYUV(AliRtcEngine.AliRtcVideoSample sample) {
        if (sample.data == null || sample.data.length == 0) {
            Log.e(TAG, "YUV data is null or empty");
            return;
        }

        int w = sample.width;
        int h = sample.height;
        int ySize = w * h;
        int uSize = (w >> 1) * (h >> 1);
        int vSize = uSize;
        int expectedLen = ySize + uSize + vSize;

        if (sample.data.length < expectedLen) {
            Log.e(TAG, "Invalid YUV data length: " + sample.data.length + ", expected: " + expectedLen);
            return;
        }

        // 检查是否需要重新分配缓冲区
        synchronized (frameLock) {
            if (bufferWidth != w || bufferHeight != h || yBuffer == null || uBuffer == null || vBuffer == null) {
                // 重新分配直接内存缓冲区
                if (yBuffer == null || yBuffer.capacity() < ySize) {
                    yBuffer = ByteBuffer.allocateDirect(ySize);
                }
                if (uBuffer == null || uBuffer.capacity() < uSize) {
                    uBuffer = ByteBuffer.allocateDirect(uSize);
                }
                if (vBuffer == null || vBuffer.capacity() < vSize) {
                    vBuffer = ByteBuffer.allocateDirect(vSize);
                }
                bufferWidth = w;
                bufferHeight = h;
            }

            // 清空缓冲区并重新填充数据
            yBuffer.clear();
            uBuffer.clear();
            vBuffer.clear();

            // 从sample.data复制数据到各缓冲区
            yBuffer.put(sample.data, 0, ySize);
            uBuffer.put(sample.data, ySize, uSize);
            vBuffer.put(sample.data, ySize + uSize, vSize);

            // 翻转缓冲区，准备读取
            yBuffer.flip();
            uBuffer.flip();
            vBuffer.flip();

            // 更新当前帧引用
            this.yFrame = yBuffer;
            this.uFrame = uBuffer;
            this.vFrame = vBuffer;
            this.frameWidth = w;
            this.frameHeight = h;
        }
    }

    private int loadProgram(String vertexSource, String fragmentSource) {
        int vertexShader = loadShader(GLES20.GL_VERTEX_SHADER, vertexSource);
        if (vertexShader == 0) return 0;

        int fragmentShader = loadShader(GLES20.GL_FRAGMENT_SHADER, fragmentSource);
        if (fragmentShader == 0) return 0;

        int program = GLES20.glCreateProgram();
        GLES20.glAttachShader(program, vertexShader);
        GLES20.glAttachShader(program, fragmentShader);
        GLES20.glLinkProgram(program);

        int[] linkStatus = new int[1];
        GLES20.glGetProgramiv(program, GLES20.GL_LINK_STATUS, linkStatus, 0);
        if (linkStatus[0] != GLES20.GL_TRUE) {
            Log.e(TAG, "Link program failed: " + GLES20.glGetProgramInfoLog(program));
            GLES20.glDeleteProgram(program);
            return 0;
        }
        return program;
    }

    private int loadShader(int type, String source) {
        int shader = GLES20.glCreateShader(type);
        GLES20.glShaderSource(shader, source);
        GLES20.glCompileShader(shader);

        int[] compiled = new int[1];
        GLES20.glGetShaderiv(shader, GLES20.GL_COMPILE_STATUS, compiled, 0);
        if (compiled[0] == 0) {
            Log.e(TAG, "Compile shader failed: " + GLES20.glGetShaderInfoLog(shader));
            GLES20.glDeleteShader(shader);
            return 0;
        }
        return shader;
    }

    private void setupTexture(int textureId) {
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId);
        GLES20.glTexParameterf(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR);
        GLES20.glTexParameterf(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR);
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE);
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE);
        checkGLError("setupTexture");
    }

    private void checkGLError(String operation) {
        int error = GLES20.glGetError();
        if (error != GLES20.GL_NO_ERROR) {
            Log.e(TAG, operation + ": glError " + error);
        }
    }
}