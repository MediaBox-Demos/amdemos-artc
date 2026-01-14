package com.aliyun.artc.api.advancedusage.CustomVideoCaptureAndRender.utils;

import android.graphics.SurfaceTexture;
import android.opengl.GLES11Ext;
import android.opengl.GLES20;
import android.opengl.GLSurfaceView;
import android.util.Log;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;

import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

/**
 * 纹理渲染器 - 通过像素复制方式渲染 SDK 的纹理内容
 * 由于 SDK 的 EGLContext 与 GLSurfaceView 的 EGLContext 隔离，
 * 无法直接共享纹理，因此需要通过像素拷贝的方式传递视频帧
 */
public class TextureRenderer implements GLSurfaceView.Renderer {
    private static final String TAG = "TextureRenderer";

    // 顶点着色器
    private static final String VERTEX_SHADER_CODE =
            "attribute vec4 aPosition;" +
                    "attribute vec2 aTexCoord;" +
                    "varying vec2 vTexCoord;" +
                    "void main() {" +
                    "  gl_Position = aPosition;" +
                    "  vTexCoord = aTexCoord;" +
                    "}";

    // 片段着色器 (2D纹理)
    private static final String FRAGMENT_SHADER_CODE_2D =
            "precision mediump float;" +
                    "varying vec2 vTexCoord;" +
                    "uniform sampler2D sTexture;" +
                    "void main() {" +
                    "  gl_FragColor = texture2D(sTexture, vTexCoord);" +
                    "}";

    // 顶点坐标（全屏四边形）
    private final float[] vertices = {
            -1.0f, -1.0f,
            1.0f, -1.0f,
            -1.0f, 1.0f,
            1.0f, 1.0f
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

    private int program2D;     // 用于2D纹理的着色器程序
    private int positionHandle;
    private int texCoordHandle;
    private int textureHandle;

    private int displayTextureId = -1;  // 显示用的纹理 ID（在 GLSurfaceView 的 EGL 上下文中）
    private ByteBuffer pixelBuffer;     // 像素数据缓冲区
    private volatile byte[] latestPixelData = null;  // 最新的像素数据
    private volatile int latestWidth = 0;
    private volatile int latestHeight = 0;
    private final Object pixelLock = new Object();
    
    private int frameCount = 0;

    public TextureRenderer() {
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

        // 创建2D纹理着色器程序
        program2D = loadProgram(VERTEX_SHADER_CODE, FRAGMENT_SHADER_CODE_2D);
        if (program2D == 0) {
            Log.e(TAG, "Failed to create 2D OpenGL program");
            return;
        }
        Log.d(TAG, "2D Program created successfully: " + program2D);

        // 获取着色器属性位置
        positionHandle = GLES20.glGetAttribLocation(program2D, "aPosition");
        texCoordHandle = GLES20.glGetAttribLocation(program2D, "aTexCoord");
        textureHandle = GLES20.glGetUniformLocation(program2D, "sTexture");
        checkGLError("onSurfaceCreated");

        Log.d(TAG, "Shader handles - position: " + positionHandle + ", texCoord: " + texCoordHandle + ", texture: " + textureHandle);
        
        // 创建用于显示的2D纹理
        int[] textures = new int[1];
        GLES20.glGenTextures(1, textures, 0);
        displayTextureId = textures[0];
        
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, displayTextureId);
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR);
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR);
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE);
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0);
        checkGLError("create display texture");
        
        Log.d(TAG, "Display texture created: " + displayTextureId);
    }

    @Override
    public void onSurfaceChanged(GL10 gl, int width, int height) {
        GLES20.glViewport(0, 0, width, height);
        checkGLError("glViewport");
        Log.d(TAG, "onSurfaceChanged: " + width + "x" + height);
    }

    @Override
    public void onDrawFrame(GL10 gl) {
        // 清屏
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT);
        checkGLError("glClear");

        // 获取最新的像素数据
        byte[] pixelData;
        int width, height;
        synchronized (pixelLock) {
            if (latestPixelData == null) {
                // 没有数据，显示黑屏
                return;
            }
            pixelData = latestPixelData;
            width = latestWidth;
            height = latestHeight;
        }

        frameCount++;
        if (frameCount % 30 == 0) {
            Log.d(TAG, "Rendering frame #" + frameCount + ", size: " + width + "x" + height + ", data size: " + pixelData.length);
        }

        // 将像素数据上传到纹理
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, displayTextureId);
        ByteBuffer buffer = ByteBuffer.wrap(pixelData);
        GLES20.glTexImage2D(GLES20.GL_TEXTURE_2D, 0, GLES20.GL_RGBA, width, height, 0, 
                            GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, buffer);
        checkGLError("glTexImage2D");

        // 使用着色器程序
        GLES20.glUseProgram(program2D);
        checkGLError("glUseProgram");

        // 启用顶点
        GLES20.glEnableVertexAttribArray(positionHandle);
        checkGLError("glEnableVertexAttribArray positionHandle");
        GLES20.glVertexAttribPointer(positionHandle, 2, GLES20.GL_FLOAT, false, 8, vertexBuffer);
        checkGLError("glVertexAttribPointer positionHandle");

        GLES20.glEnableVertexAttribArray(texCoordHandle);
        checkGLError("glEnableVertexAttribArray texCoordHandle");
        GLES20.glVertexAttribPointer(texCoordHandle, 2, GLES20.GL_FLOAT, false, 8, textureBuffer);
        checkGLError("glVertexAttribPointer texCoordHandle");

        // 绑定纹理
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
        checkGLError("glActiveTexture");
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, displayTextureId);
        checkGLError("glBindTexture");
        GLES20.glUniform1i(textureHandle, 0);
        checkGLError("glUniform1i");

        // 绘制
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);
        checkGLError("glDrawArrays");

        // 禁用
        GLES20.glDisableVertexAttribArray(positionHandle);
        GLES20.glDisableVertexAttribArray(texCoordHandle);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0);
    }

    /**
     * 更新像素数据（通过像素复制方式）
     * @param pixelData RGBA 格式的像素数据
     * @param width 图像宽度
     * @param height 图像高度
     */
    public void updatePixelData(byte[] pixelData, int width, int height) {
        synchronized (pixelLock) {
            this.latestPixelData = pixelData;
            this.latestWidth = width;
            this.latestHeight = height;
        }
    }

    private int loadProgram(String vertexSource, String fragmentSource) {
        int vertexShader = loadShader(GLES20.GL_VERTEX_SHADER, vertexSource);
        if (vertexShader == 0) {
            Log.e(TAG, "Failed to compile vertex shader");
            return 0;
        }

        int fragmentShader = loadShader(GLES20.GL_FRAGMENT_SHADER, fragmentSource);
        if (fragmentShader == 0) {
            Log.e(TAG, "Failed to compile fragment shader");
            return 0;
        }

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

        Log.d(TAG, "Program created successfully: " + program);
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
            Log.e(TAG, "Shader source: " + source);
            GLES20.glDeleteShader(shader);
            return 0;
        }

        Log.d(TAG, "Shader compiled successfully: " + shader + " type: " + type);
        return shader;
    }

    private void checkGLError(String operation) {
        int error = GLES20.glGetError();
        if (error != GLES20.GL_NO_ERROR) {
            Log.e(TAG, operation + ": glError " + error);
        }
    }
}
