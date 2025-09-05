package com.aliyun.artc.api.advancedusage.CustomVideoCaptureAndRender.utils;

import android.opengl.GLES11Ext;
import android.opengl.GLES20;
import android.opengl.GLSurfaceView;
import android.util.Log;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;

import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

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

    // 片段着色器 (2D纹理) - 显示纹理内容，添加网格以便识别
    private static final String FRAGMENT_SHADER_CODE_2D =
            "precision mediump float;" +
                    "varying vec2 vTexCoord;" +
                    "uniform sampler2D sTexture;" +
                    "void main() {" +
                    "  vec4 color = texture2D(sTexture, vTexCoord);" +
                    // 添加网格线以便识别纹理是否有效
                    "  float grid1 = mod(vTexCoord.x * 10.0, 1.0) < 0.1 || mod(vTexCoord.y * 10.0, 1.0) < 0.1 ? 1.0 : 0.0;" +
                    "  float grid2 = mod(vTexCoord.x * 40.0, 1.0) < 0.05 || mod(vTexCoord.y * 40.0, 1.0) < 0.05 ? 1.0 : 0.0;" +
                    // 如果纹理是黑色，则显示带网格的蓝色
                    "  if (color.r == 0.0 && color.g == 0.0 && color.b == 0.0) {" +
                    "    gl_FragColor = vec4(0.0, 0.0, grid1 * 0.5 + 0.5, 1.0);" +
                    "  } else {" +
                    // 如果不是黑色，则正常显示，但添加网格
                    "    gl_FragColor = vec4(color.r, color.g, color.b + grid1 * 0.3 + grid2 * 0.2, color.a);" +
                    "  }" +
                    "}";

    // 片段着色器 (OES纹理) - 显示纹理内容，添加网格以便识别
    private static final String FRAGMENT_SHADER_CODE_OES =
            "#extension GL_OES_EGL_image_external : require\n" +
                    "precision mediump float;" +
                    "varying vec2 vTexCoord;" +
                    "uniform samplerExternalOES sTexture;" +
                    "void main() {" +
                    "  vec4 color = texture2D(sTexture, vTexCoord);" +
                    // 添加网格线以便识别纹理是否有效
                    "  float grid1 = mod(vTexCoord.x * 10.0, 1.0) < 0.1 || mod(vTexCoord.y * 10.0, 1.0) < 0.1 ? 1.0 : 0.0;" +
                    "  float grid2 = mod(vTexCoord.x * 40.0, 1.0) < 0.05 || mod(vTexCoord.y * 40.0, 1.0) < 0.05 ? 1.0 : 0.0;" +
                    // 如果纹理是黑色，则显示带网格的蓝色
                    "  if (color.r == 0.0 && color.g == 0.0 && color.b == 0.0) {" +
                    "    gl_FragColor = vec4(0.0, 0.0, grid1 * 0.5 + 0.5, 1.0);" +
                    "  } else {" +
                    // 如果不是黑色，则正常显示，但添加网格
                    "    gl_FragColor = vec4(color.r, color.g, color.b + grid1 * 0.3 + grid2 * 0.2, color.a);" +
                    "  }" +
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
    private int programOES;    // 用于OES纹理的着色器程序
    private int positionHandle;
    private int texCoordHandle;
    private int textureHandle;

    private volatile int currentTextureId = -1;
    private volatile boolean isOESTexture = false;  // 标记纹理类型
    private volatile int textureWidth = 0;  // 纹理宽度
    private volatile int textureHeight = 0; // 纹理高度
    private final Object textureLock = new Object();

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
        GLES20.glClearColor(0.0f, 1.0f, 0.0f, 1.0f); // 设置为绿色背景，用于测试
        checkGLError("glClearColor");

        // 创建2D纹理着色器程序
        program2D = loadProgram(VERTEX_SHADER_CODE, FRAGMENT_SHADER_CODE_2D);
        if (program2D == 0) {
            Log.e(TAG, "Failed to create 2D OpenGL program");
        } else {
            Log.d(TAG, "2D Program created successfully: " + program2D);
        }

        // 创建OES纹理着色器程序
        programOES = loadProgram(VERTEX_SHADER_CODE, FRAGMENT_SHADER_CODE_OES);
        if (programOES == 0) {
            Log.e(TAG, "Failed to create OES OpenGL program");
        } else {
            Log.d(TAG, "OES Program created successfully: " + programOES);
        }

        if (program2D == 0 && programOES == 0) {
            Log.e(TAG, "Failed to create any OpenGL program");
            return;
        }

        // 获取着色器属性位置（使用2D程序，因为属性位置应该是一样的）
        int program = program2D != 0 ? program2D : programOES;
        positionHandle = GLES20.glGetAttribLocation(program, "aPosition");
        texCoordHandle = GLES20.glGetAttribLocation(program, "aTexCoord");
        textureHandle = GLES20.glGetUniformLocation(program, "sTexture");
        checkGLError("onSurfaceCreated");

        Log.d(TAG, "Shader handles - position: " + positionHandle + ", texCoord: " + texCoordHandle + ", texture: " + textureHandle);
    }

    @Override
    public void onSurfaceChanged(GL10 gl, int width, int height) {
        GLES20.glViewport(0, 0, width, height);
        checkGLError("glViewport");
        Log.d(TAG, "onSurfaceChanged: " + width + "x" + height);
    }

    @Override
    public void onDrawFrame(GL10 gl) {
        // 先用绿色清屏，用于测试GL是否工作
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT);
        checkGLError("glClear");

        int textureId;
        boolean useOES;
        int width, height;
        synchronized (textureLock) {
            if (currentTextureId == -1) {
                Log.d(TAG, "currentTextureId is -1, drawing green screen only");
                return;
            }
            textureId = currentTextureId;
            useOES = isOESTexture;
            width = textureWidth;
            height = textureHeight;
        }

        Log.d(TAG, "Drawing with textureId: " + textureId + ", OES: " + useOES + ", size: " + width + "x" + height);

        // 选择合适的着色器程序
        int program = useOES ? programOES : program2D;
        if (program == 0) {
            Log.e(TAG, "No valid program for texture type: " + (useOES ? "OES" : "2D"));
            return;
        }

        GLES20.glUseProgram(program);
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

        int textureType = useOES ? GLES11Ext.GL_TEXTURE_EXTERNAL_OES : GLES20.GL_TEXTURE_2D;
        GLES20.glBindTexture(textureType, textureId);
        checkGLError("glBindTexture " + (useOES ? "OES" : "2D") + " with ID " + textureId);

        // 检查纹理是否有效
        int[] params = new int[1];
        GLES20.glGetTexParameteriv(textureType, GLES20.GL_TEXTURE_MIN_FILTER, params, 0);
        checkGLError("glGetTexParameteriv");
        Log.d(TAG, "Texture " + textureId + " min filter: " + params[0]);

        GLES20.glUniform1i(textureHandle, 0);
        checkGLError("glUniform1i");

        // 绘制
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);
        checkGLError("glDrawArrays");

        // 禁用
        GLES20.glDisableVertexAttribArray(positionHandle);
        GLES20.glDisableVertexAttribArray(texCoordHandle);
    }

    /**
     * 更新纹理ID和尺寸信息
     * @param textureId 纹理ID
     * @param isOES 是否为OES纹理
     * @param width 纹理宽度
     * @param height 纹理高度
     */
    public void updateTexture(int textureId, boolean isOES, int width, int height) {
        synchronized (textureLock) {
            this.currentTextureId = textureId;
            this.isOESTexture = isOES;
            this.textureWidth = width;
            this.textureHeight = height;
        }
        Log.d(TAG, "updateTexture: " + textureId + ", OES: " + isOES + ", size: " + width + "x" + height);
    }

    /**
     * 更新纹理ID（默认为2D纹理，尺寸为0）
     * @param textureId 纹理ID
     */
    public void updateTexture(int textureId) {
        updateTexture(textureId, false, 0, 0);
    }

    /**
     * 更新2D纹理ID和尺寸信息
     * @param textureId 纹理ID
     * @param width 纹理宽度
     * @param height 纹理高度
     */
    public void updateTexture(int textureId, int width, int height) {
        updateTexture(textureId, false, width, height);
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
