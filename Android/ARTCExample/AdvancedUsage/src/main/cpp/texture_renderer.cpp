//
// 纹理渲染器 - 通过像素复制方式从 SDK 纹理读取数据
//

#include <jni.h>
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <android/log.h>
#include <cstring>
#include <vector>

#define LOG_TAG "TextureRenderer"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// OES 纹理类型
#define GL_TEXTURE_EXTERNAL_OES 0x8D65

// 顶点着色器
static const char* VERTEX_SHADER =
        "attribute vec4 aPosition;\n"
        "attribute vec2 aTexCoord;\n"
        "varying vec2 vTexCoord;\n"
        "void main() {\n"
        "    gl_Position = aPosition;\n"
        "    vTexCoord = aTexCoord;\n"
        "}\n";

// OES 纹理片段着色器
static const char* FRAGMENT_SHADER_OES =
        "#extension GL_OES_EGL_image_external : require\n"
        "precision mediump float;\n"
        "varying vec2 vTexCoord;\n"
        "uniform samplerExternalOES uTexture;\n"
        "void main() {\n"
        "    gl_FragColor = texture2D(uTexture, vTexCoord);\n"
        "}\n";

// 2D 纹理片段着色器
static const char* FRAGMENT_SHADER_2D =
        "precision mediump float;\n"
        "varying vec2 vTexCoord;\n"
        "uniform sampler2D uTexture;\n"
        "void main() {\n"
        "    gl_FragColor = texture2D(uTexture, vTexCoord);\n"
        "}\n";

// 编译着色器
static GLuint compileShader(GLenum type, const char* source) {
    GLuint shader = glCreateShader(type);
    if (shader == 0) {
        LOGE("Failed to create shader");
        return 0;
    }
    
    glShaderSource(shader, 1, &source, nullptr);
    glCompileShader(shader);
    
    GLint compiled = 0;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
    if (!compiled) {
        GLint infoLen = 0;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLen);
        if (infoLen > 0) {
            char* infoLog = new char[infoLen];
            glGetShaderInfoLog(shader, infoLen, nullptr, infoLog);
            LOGE("Shader compile error: %s", infoLog);
            delete[] infoLog;
        }
        glDeleteShader(shader);
        return 0;
    }
    
    return shader;
}

// 创建着色器程序
static GLuint createProgram(const char* vertexSource, const char* fragmentSource) {
    GLuint vertexShader = compileShader(GL_VERTEX_SHADER, vertexSource);
    if (vertexShader == 0) {
        return 0;
    }
    
    GLuint fragmentShader = compileShader(GL_FRAGMENT_SHADER, fragmentSource);
    if (fragmentShader == 0) {
        glDeleteShader(vertexShader);
        return 0;
    }
    
    GLuint program = glCreateProgram();
    if (program == 0) {
        LOGE("Failed to create program");
        glDeleteShader(vertexShader);
        glDeleteShader(fragmentShader);
        return 0;
    }
    
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    glLinkProgram(program);
    
    GLint linked = 0;
    glGetProgramiv(program, GL_LINK_STATUS, &linked);
    if (!linked) {
        GLint infoLen = 0;
        glGetProgramiv(program, GL_INFO_LOG_LENGTH, &infoLen);
        if (infoLen > 0) {
            char* infoLog = new char[infoLen];
            glGetProgramInfoLog(program, infoLen, nullptr, infoLog);
            LOGE("Program link error: %s", infoLog);
            delete[] infoLog;
        }
        glDeleteProgram(program);
        glDeleteShader(vertexShader);
        glDeleteShader(fragmentShader);
        return 0;
    }
    
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    
    return program;
}

/**
 * 从 SDK 的纹理中读取像素数据
 * 这个方法在 SDK 的 GL 线程中调用，SDK 的 EGLContext 已经是当前上下文
 */
extern "C" JNIEXPORT jbyteArray JNICALL
Java_com_aliyun_artc_api_advancedusage_CustomVideoCaptureAndRender_CustomVideoRenderActivity_nativeReadPixelsFromTexture(
        JNIEnv* env,
        jclass clazz,
        jlong eglContextHandle,
        jint textureId,
        jint width,
        jint height,
        jint format) {
    
    static int frameCount = 0;
    frameCount++;
    
    if (frameCount % 30 == 0) {
        LOGD("Reading pixels from texture: texId=%d, size=%dx%d, format=%d, frame=%d", 
             textureId, width, height, format, frameCount);
    }
    
    // 检查参数
    if (width <= 0 || height <= 0) {
        LOGE("Invalid size: %dx%d", width, height);
        return nullptr;
    }
    
    if (textureId <= 0) {
        LOGE("Invalid texture ID: %d", textureId);
        return nullptr;
    }
    
    // 保存当前 GL 状态（因为 dataspace 变化可能影响状态）
    GLint prevFbo = 0;
    GLint prevViewport[4] = {0};
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &prevFbo);
    glGetIntegerv(GL_VIEWPORT, prevViewport);
    
    // 清除任何之前的错误
    glGetError();
    
    // 创建 FBO 用于离屏渲染
    GLuint fbo = 0;
    glGenFramebuffers(1, &fbo);
    glBindFramebuffer(GL_FRAMEBUFFER, fbo);
    
    // 创建临时纹理用于存储渲染结果
    GLuint tempTexture = 0;
    glGenTextures(1, &tempTexture);
    glBindTexture(GL_TEXTURE_2D, tempTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, nullptr);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    // 将临时纹理绑定到 FBO
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, tempTexture, 0);
    
    // 检查 FBO 状态
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        LOGE("FBO incomplete: 0x%x", status);
        glDeleteTextures(1, &tempTexture);
        glDeleteFramebuffers(1, &fbo);
        return nullptr;
    }
    
    // 设置视口
    glViewport(0, 0, width, height);
    
    // 根据格式决定使用哪个着色器（format == 3 表示 OES 纹理）
    bool isOES = (format == 3);
    GLenum textureType = isOES ? GL_TEXTURE_EXTERNAL_OES : GL_TEXTURE_2D;
    
    // 创建着色器程序（每次都创建新的，避免跨上下文使用）
    GLuint program = isOES ? 
        createProgram(VERTEX_SHADER, FRAGMENT_SHADER_OES) : 
        createProgram(VERTEX_SHADER, FRAGMENT_SHADER_2D);
    
    if (program == 0) {
        LOGE("Failed to create program for format: %d", format);
        glBindTexture(textureType, 0);
        glBindTexture(GL_TEXTURE_2D, 0);
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
        glDeleteTextures(1, &tempTexture);
        glDeleteFramebuffers(1, &fbo);
        return nullptr;
    }
    
    // 使用着色器程序
    glUseProgram(program);
    
    // 获取属性位置
    GLint positionHandle = glGetAttribLocation(program, "aPosition");
    GLint texCoordHandle = glGetAttribLocation(program, "aTexCoord");
    GLint textureHandle = glGetUniformLocation(program, "uTexture");
    
    // 顶点坐标
    static const GLfloat vertices[] = {
        -1.0f, -1.0f,
         1.0f, -1.0f,
        -1.0f,  1.0f,
         1.0f,  1.0f,
    };
    
    // 纹理坐标（Y轴翻转，因为 OpenGL 和屏幕坐标系不同）
    static const GLfloat texCoords[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };
    
    // 设置顶点属性
    glVertexAttribPointer(positionHandle, 2, GL_FLOAT, GL_FALSE, 0, vertices);
    glEnableVertexAttribArray(positionHandle);
    
    glVertexAttribPointer(texCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, texCoords);
    glEnableVertexAttribArray(texCoordHandle);
    
    // 绑定输入纹理
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(textureType, textureId);
    glUniform1i(textureHandle, 0);
    
    // 渲染到 FBO
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    // 禁用顶点属性
    glDisableVertexAttribArray(positionHandle);
    glDisableVertexAttribArray(texCoordHandle);
    
    // 确保渲染完成
    glFinish();
    
    // 再次检查 FBO 状态（dataspace 变化可能导致 FBO 失效）
    GLenum fboStatus = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (fboStatus != GL_FRAMEBUFFER_COMPLETE) {
        LOGE("FBO status changed after render: 0x%x", fboStatus);
        glBindTexture(textureType, 0);
        glBindTexture(GL_TEXTURE_2D, 0);
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
        glDeleteTextures(1, &tempTexture);
        glDeleteFramebuffers(1, &fbo);
        glDeleteProgram(program);
        // 清除错误状态
        glGetError();
        return nullptr;
    }
    
    // 从 FBO 读取像素数据
    int dataSize = width * height * 4;  // RGBA
    std::vector<uint8_t> pixels(dataSize);
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, pixels.data());
    
    // 检查 GL 错误
    GLenum error = glGetError();
    if (error != GL_NO_ERROR) {
        LOGE("GL error after glReadPixels: 0x%x, FBO status was: 0x%x", error, fboStatus);
        // 即使有错误也继续，可能部分数据有效
    }
    
    // 清理资源
    glBindTexture(textureType, 0);
    glBindTexture(GL_TEXTURE_2D, 0);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glDeleteTextures(1, &tempTexture);
    glDeleteFramebuffers(1, &fbo);
    glDeleteProgram(program);  // 删除着色器程序
    
    // 恢复 GL 状态
    glBindFramebuffer(GL_FRAMEBUFFER, prevFbo);
    glViewport(prevViewport[0], prevViewport[1], prevViewport[2], prevViewport[3]);
    
    // 清除可能遗留的错误状态
    glGetError();
    
    // 创建 Java byte 数组
    jbyteArray result = env->NewByteArray(dataSize);
    if (result == nullptr) {
        LOGE("Failed to allocate byte array");
        return nullptr;
    }
    
    env->SetByteArrayRegion(result, 0, dataSize, reinterpret_cast<const jbyte*>(pixels.data()));
    
    if (frameCount % 30 == 0) {
        LOGD("Successfully read %d bytes from texture", dataSize);
    }
    
    return result;
}
