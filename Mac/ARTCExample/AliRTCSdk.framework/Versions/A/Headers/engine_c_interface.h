#ifndef ali_rtc_engine_c_interface_h
#define ali_rtc_engine_c_interface_h

#include "engine_define.h"

/**
 * @brief AliRTCSdk C Interfaces
 */

#if defined(__cplusplus)
extern "C"{
#endif

#include <stddef.h>
#include <stdio.h>

/**
 * @brief 视频数据类型
 * @note enum redefining.
 */

typedef enum {
    kAliEngineVideoFormatUnknow  = -1,
    kAliEngineVideoFormatBGRA    = 0,
    kAliEngineVideoFormatI420    = 1,
    kAliEngineVideoFormatNV21    = 2,
    kAliEngineVideoFormatNV12    = 3,
    kAliEngineVideoFormatRGBA    = 4,
    kAliEngineVideoFormatI422    = 5,
    kAliEngineVideoFormatARGB    = 6,
    kAliEngineVideoFormatABGR    = 7,
    kAliEngineVideoFormatRGB24   = 8,
    kAliEngineVideoFormatBGR24   = 9,
    kAliEngineVideoFormatRGB565  = 10,
    kAliEngineVideoFormatTextureOES  = 11,
    kAliEngineVideoFormatTexture2D  = 12,
    kAliEngineVideoFormatH264  = 13,
    kAliEngineVideoFormatH265  = 14,
    kAliEngineVideoFormatFile = 15,
} ali_engine_video_format;

/**
 * @brief 视频数据格式
 * @note enum redifining.
 */
typedef enum {
    /** 裸数据格式 */
    kAliEngineBufferTypeRawData          = 0,
    /** 纹理格式 */
    kAliEngineBufferTypeTexture,
    /** apple cvPixelBuffer */
    kAliEngineBufferTypeCVPixelBuffer,
    /** 文件路径格式 */
    kAliEngineBufferTypeFile,
} ali_engine_buffer_type;


/**
 * @brief 视频裸数据
 * @note struct redefining.
 */

typedef struct ali_engine_video_raw_data {
    ali_engine_video_format format;
    ali_engine_buffer_type type;
    int data_length;
    void* pixel_buffer;
    void* data_ptr;
    void* data_y_ptr;
    void* data_u_ptr;
    void* data_v_ptr;
    int stride_y;
    int stride_u;
    int stride_v;
    int height;
    int width;
    int rotation;
    int stride;
    long long time_stamp;
    int texture_id;
    float transform_matrix[16];
    int encode_cost_ms;
#if defined(WEBRTC_ANDROID)
    long shared_context;
    bool egl_change;
#endif
} ali_engine_video_raw_data_t;


/**
 * @brief 视频流类型
 * @note struct redefining.
 */
typedef enum {
    /** 无视频流 */
    kAliEngineVideoTrackNo     = 0,
    /** 相机流 */
    kAliEngineVideoTrackCamera = 1,
    /** 屏幕共享流 */
    kAliEngineVideoTrackScreen = 2,
    /** 相机流和屏幕共享流 */
    kAliEngineVideoTrackBoth   = 3,
} ali_engine_video_track;


/**
 * @brief 视频帧率
 */
typedef enum {
    /** 5: 5 fps */
    kAliEngineFrameRateFps5 = 5,
    /** 10: 10 fps */
    kAliEngineFrameRateFps10 = 10,
    /** 15: 15 fps */
    kAliEngineFrameRateFps15 = 15,
    /** 20: 20 fps */
    kAliEngineFrameRateFps20 = 20,
    /** 25: 25 fps */
    kAliEngineFrameRateFps25 = 25,
    /** 30: 30 fps */
    kAliEngineFrameRateFps30 = 30,
    /** 60: 60 fps */
    kAliEngineFrameRateFps60 = 60,
} ali_engine_frame_rate;

/**
 * @brief 视频旋转角度
 */
typedef enum {
    /** 沿用之前的旋转角度 */
  kAliEngineRotationModeNoChange = -1,
    /** 0 */
  kAliEngineRotationMode_0 = 0,
    /** 90 */
  kAliEngineRotationMode_90 = 90,
    /** 180 */
  kAliEngineRotationMode_180 = 180,
    /** 270 */
  kAliEngineRotationMode_270 = 270,
} ali_engine_rotation_mode;

/**
 * @brief 外部流视频编码属性配置
 */

typedef struct ali_engine_screen_share_encoder_configuration {
    /** 视频分辨率 */
    int width;
    int height;
    /** 视频帧率 */
    int frame_rate;
    /** 视频编码码率 */
    int bitrate;
    /** 关键帧间隔*/
    int key_frame_interval;
    /** 是否强制编码器严格按照设置的关键帧间隔产生关键帧 */
    bool force_strict_key_frame_interval;
    
    ali_engine_rotation_mode rotation_mode;
    
}ali_engine_screen_share_encoder_configuration_t;


/**
 * @brief 输入外部采集视频数据
 * @param frame 帧数据，详见 {@link ali_engine_video_raw_data}
 * @param type 视频流类型，详见{@link ali_engine_video_track}
 *
 * @return 0: 成功 非0: 失败
 * @note 如果返回值为errorCode中的AliRtcErrVideoBufferFull，代表当前buffer队列塞满，需要等待后再继续输送数据
 */
ALI_RTC_API int push_external_video_frame(ali_engine_video_raw_data_t *frame, ali_engine_video_track type);

#if defined(__ANDROID__) || (defined(__APPLE__) && TARGET_OS_IOS)
ALI_RTC_API int start_screen_share();
#endif

ALI_RTC_API int stop_screen_share();

ALI_RTC_API void set_screen_share_encoder_configuration(ali_engine_screen_share_encoder_configuration_t *config);
/**
 * TODO: More API
 *  - Callbacks?
 *  - StopScreenCapture from C++ SDK?
 */

#if defined(__cplusplus)
}
#endif

#endif /* ali_rtc_engine_c_interface_h */
