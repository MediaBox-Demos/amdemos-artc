#ifndef BIZ_ENGINE_API_ENGINE_API_ENGINE_MEDIA_ENGINE_H_
#define BIZ_ENGINE_API_ENGINE_API_ENGINE_MEDIA_ENGINE_H_

#include "engine_define.h"
#include "engine_utils.h"
/**
 * @brief AliRTCSdk namespace
 */
namespace AliRTCSdk
{
    class ALI_RTC_API IExternalFileObserver;
    /**
     * @addtogroup AliRtcDef_cpp 关键类型定义
     * AliRtc 关键类型定义
     * @{
     */

    /**
     * @brief 音频track的类型
    */
    typedef enum {
      /** 无麦克风 */
      AliEngineAudioTrackNo = 0,
      /** 麦克风 */
      AliEngineAudioTrackMic = 1,
      /** Dual流 */
      AliEngineAudioTrackDual = 2,
      /** 麦克风 + 第二流 */
      AliEngineAudioTrackBoth = 3,
      /** 占位符 */
      AliEngineAudioTrackEnd = 0xffffffff
    } AliEngineAudioTrack;

    /**
     * @brief 视频流类型
     */
    typedef enum {
        /** 无视频流 */
        AliEngineVideoTrackNo     = 0,
        /** 相机流 */
        AliEngineVideoTrackCamera = 1,
        /** 屏幕共享流 */
        AliEngineVideoTrackScreen = 2,
        /** 相机流和屏幕共享流 */
        AliEngineVideoTrackBoth   = 3,
    } AliEngineVideoTrack;

    /**
     * @brief 视频编码类型类型
     */
    typedef enum {
        /** 编码器 */
        AliEngineVideoEncoderType = 0,
        /** 解码器 */
        AliEngineVideoDecoderType = 1,
    } AliEngineVideoCodecKindType;


    /**
     * @brief 相机流类型
     */
    typedef enum {
      /** 无，在OnSubscribeStreamTypeChanged回调表示当前未订阅 */
      AliEngineVideoStreamTypeNone = 0,
      /** 高码率，高分辨率流（大流） */
      AliEngineVideoStreamTypeHigh = 1,
      /** 低码率，低分辨率流（小流） */
      AliEngineVideoStreamTypeLow = 2,
    } AliEngineVideoStreamType;

    /**
     * @brief 视频数据源
     */
    typedef enum {
      /** 相机流 */
      AliEngineVideoSourceCamera = 0,
      /** 屏幕共享流 */
      AliEngineVideoSourceScreenShare = 1,
      /** 占位符，无意义 */
      AliEngineVideosourceTypeMax,
    } AliEngineVideoSource;

    /**
     * @brief 录制视频数据源
    */
    typedef enum {
      /** 录制相机流视频 */
      AliEngineVideoRecordSourceCamera = 0,
      /** 录制屏幕流视频 */
      AliEngineVideoRecordSourceScreenShare = 1,
      /** 录制相机和屏幕流视频 */
      AliEngineVideoRecordSourceBoth = 2,
      /** 枚举边界（不允许使用） */
      AliEngineVideoRecordSourceTypeMax,
    } AliEngineVideoRecordSource;

    /**
     * @brief 视频数据类型
     */
    typedef enum {
        AliEngineVideoFormatUnknow  = -1,
        AliEngineVideoFormatBGRA    = 0,
        AliEngineVideoFormatI420    = 1,
        AliEngineVideoFormatNV21    = 2,
        AliEngineVideoFormatNV12    = 3,
        AliEngineVideoFormatRGBA    = 4,
        AliEngineVideoFormatI422    = 5,
        AliEngineVideoFormatARGB    = 6,
        AliEngineVideoFormatABGR    = 7,
        AliEngineVideoFormatRGB24   = 8,
        AliEngineVideoFormatBGR24   = 9,
        AliEngineVideoFormatRGB565  = 10,
        AliEngineVideoFormatTextureOES  = 11,
        AliEngineVideoFormatTexture2D  = 12,
        AliEngineVideoFormatH264  = 13,
        AliEngineVideoFormatH265  = 14,
        AliEngineVideoFormatFile = 15,
    } AliEngineVideoFormat;

    /**
     * @brief 视频数据格式
     */
    typedef enum {
        /** 裸数据格式 */
        AliEngineBufferTypeRawData          = 0,
        /** 纹理格式 */
        AliEngineBufferTypeTexture,
        /** apple cvPixelBuffer */
        AliEngineBufferTypeCVPixelBuffer,
        /** 文件路径格式 */
        AliEngineBufferTypeFile,
    } AliEngineBufferType;


    /**
     * @brief 视频纹理格式
     */
    typedef enum {
      AliEngineTextureTypeUnknown = -1,
      AliEngineTextureTypePre = 0,
      AliEngineTextureTypePost = 1,
    } AliEngineTextureType;

    /**
     * @brief 视图显示模式
     */
    typedef enum {
        /** 自动模式 */
        AliEngineRenderModeAuto     = 0,
        /** 拉伸平铺模式 ，如果外部输入的视频宽高比和推流设置的宽高比不一致时，将输入视频拉伸到推流设置的比例，画面会变形*/
        AliEngineRenderModeStretch  = 1,
        /** 填充黑边模式，如果外部输入的视频宽高比和推流设置的宽高比不一致时，将输入视频上下或者左右填充黑边 */
        AliEngineRenderModeFill     = 2,
        /** 裁剪模式，如果外部输入的视频宽高比和推流设置的宽高比不一致时，将输入视频宽或者高进行裁剪，画面内容会丢失 */
        AliEngineRenderModeCrop     = 3,
        /** 已废弃 */
        AliEngineRenderModeScroll   = 4,
        /** 沿用之前的显示模式 */
        AliEngineRenderModeNoChange = 99,
    } AliEngineRenderMode;

    /**
     * @brief 视频旋转角度
     */
    typedef enum {
        /** 沿用之前的旋转角度 */
      AliEngineRotationModeNoChange = -1,
        /** 0 */
      AliEngineRotationMode_0 = 0,
        /** 90 */
      AliEngineRotationMode_90 = 90,
        /** 180 */
      AliEngineRotationMode_180 = 180,
        /** 270 */
      AliEngineRotationMode_270 = 270,
    } AliEngineRotationMode;

    /**
     * @brief 音频声道类型
    */
    typedef enum {
      /** 单声道 */
      AliEngineMonoAudio = 1,
      /** 双声道 */
      AliEngineStereoAudio = 2,
    } AliEngineAudioNumChannelType;

    /**
     * @brief 音频采样率类型
     */
    typedef enum {
      /** 8000采样率 */
      AliEngineAudioSampleRate_8000 = 0,
      /** 11025采样率 */
      AliEngineAudioSampleRate_11025 = 1,
      /** 16000采样率 */
      AliEngineAudioSampleRate_16000 = 2,
      /** 22050采样率 */
      AliEngineAudioSampleRate_22050 = 3,
      /** 32000采样率 */
      AliEngineAudioSampleRate_32000 = 4,
      /** 44100采样率 */
      AliEngineAudioSampleRate_44100 = 5,
      /** 48000采样率 */
      AliEngineAudioSampleRate_48000 = 6,
      /** 未知采样率 */
      AliEngineAudioSampleRate_Unknown = 100,
    } AliEngineAudioSampleRate;

    /**
     * @brief 音频数据源类型
     */
    typedef enum {
        /** 采集的音频数据 */
        AliEngineAudioSourceCaptured = 0,
        /** 3A后的音频数据 */
        AliEngineAudioSourceProcessCaptured = 1,
        /** 推流的音频数据 */
        AliEngineAudioSourcePub = 2,
        /** 播放的音频数据 */
        AliEngineAudioSourcePlayback = 3,
        /** 推流和播放混音后的音频数据 */
        AliEngineAudioSourceMixedAll = 4,
        /** 拉流的远端音频数据 */
        AliEngineAudioSourceRemoteUser = 5,
    } AliEngineAudioSource;

    /**
     * @brief 视频数据输出位置
     */
    typedef enum {
      /** 采集视频数据，对应输出回调 OnCaptureVideoSample */
      AliEnginePositionPostCapture = 1 << 0,
      /** 渲染视频数据，对应输出回调 OnRemoteVideoSample */
      AliEnginePositionPreRender = 1 << 1,
      /** 编码前视频数据，对应输出回调 OnPreEncodeVideoSample */
      AliEnginePositionPreEncoder = 1 << 2,
    } AliEngineVideoObserPosition;

    /**
     * @brief 视频输出宽度对齐方式
     */
    typedef enum {
      /** 保持原有视频宽度 */
      AliEngineAlignmentDefault = 0,
      /** 宽度偶数对齐 */
      AliEngineAlignmentEven = 1,
      /** 宽度是4的倍数 */
      AliEngineAlignment4 = 2,
      /** 宽度是8的倍数 */
      AliEngineAlignment8 = 3,
      /** 宽度是16的倍数 */
      AliEngineAlignment16 = 4,
    } AliEngineVideoObserAlignment;
    /**
     * @brief 音频文件信息
     */
    typedef struct AliEngineAudioFileInfo {
        /** 音频文件路径 */
        const char* filePath;
        /** 音频文件时长，单位：ms */
        long durationMs;
    } AliEngineAudioFileInfo;

    /**
     * @brief 音频伴奏播放配置
     */
    typedef struct AliEngineAudioAccompanyConfig {
        /** 是否只本地播放，默认值：false */
        bool onlyLocalPlay = false;
        /** 是否替换掉MIC，默认值：false */
        bool replaceMic = false;
        /** 循环次数，可以设置-1(无限循环)或者>0的正整数次，其他值无效，默认值：-1 */
        int loopCycles = -1;
        /** 起播位置，单位：ms，默认值：0 */
        long startPosMs = 0;
        /** 推流音量，取值范围[0-100]，默认值：50 */
        int publishVolume = 50;
        /** 播放音量，取值范围[0-100]，默认值：50 */
        int playoutVolume = 50;
    } AliEngineAudioAccompanyConfig;

    /**
     * @brief 音频音效播放配置
     */
    typedef struct AliEngineAudioEffectConfig {
        /** 是否推流，默认值：false */
        bool needPublish = false;
        /** 循环次数，可以设置-1(无限循环)或者>0的正整数次，其他值无效，默认值：-1 */
        int loopCycles = -1;
        /** 起播位置，单位：ms，默认值：0 */
        long startPosMs = 0;
        /** 推流音量，取值范围[0-100]，默认值：50 */
        int publishVolume = 50;
        /** 播放音量，取值范围[0-100]，默认值：50 */
        int playoutVolume = 50;
    } AliEngineAudioEffectConfig;
    /**
     * @brief 音频裸数据
     */
    typedef struct AliEngineAudioRawData {
        /** 音频数据 */
        void* dataPtr       = 0;
        /** 采样点数（单个声道） */
        int numOfSamples    = 0;
        /** 每个采样点的字节数 */
        int bytesPerSample  = 0;
        /** 声道数 */
        int numOfChannels   = 0;
        /** 每秒采样点数 */
        int samplesPerSec   = 0;

        /** 远端采集时间 */  
        unsigned int remoteCaptureTimeMs = 0;
        /** neteq耗时 */
        int neteqCostMs = 0;
        /** AI语句首帧标记 */
        bool requestDelaySend = false;
    } AliEngineAudioRawData;

    /**
     * @brief 视频裸数据
     */
    typedef struct AliEngineVideoRawData {
        AliEngineVideoFormat format = AliEngineVideoFormatUnknow;
        AliEngineBufferType type    = AliEngineBufferTypeRawData;
        int dataLength  = 0;
        void* pixelBuffer = 0;
        void* dataPtr    = 0;
        void* dataYPtr   = 0;
        void* dataUPtr   = 0;
        void* dataVPtr   = 0;
        int strideY      = 0;
        int strideU      = 0;
        int strideV      = 0;
        int height       = 0;
        int width        = 0;
        int rotation     = 0;
        int stride       = 0;
        long long timeStamp = 0;
        int textureId    = 0;
        float transformMatrix[16] = {0};
        int encodeCostMs = 0;
#if defined(WEBRTC_ANDROID) || defined(WEBRTC_OHOS) 
        long shared_context = 0;
        bool egl_change = false;
        void * egl_context = nullptr ;
#endif              
    } AliEngineVideoRawData;

    /**
     * @brief 视频NALU数据
     */
    typedef struct AliEngineVideoEncodedData {
        AliEngineVideoFormat format = AliEngineVideoFormatUnknow;
        AliEngineBufferType type    = AliEngineBufferTypeRawData;
        int dataLength  = 0;
        void* dataPtr    = 0;
        int height       = 0;
        int width        = 0;
        int rotation     = 0;
        long long timeStamp = 0;        
    } AliEngineVideoEncodedData;

    /**
     * @brief 外部音频流配置
     */
    typedef struct AliEngineExternalAudioStreamConfig {
        /** 声道数，默认值：1 */
        int channels = 1;
        /** 采样率，默认值：48000，支持的采样率 8000, 12000, 16000, 24000, 32000, 44100, 48000, 96000 */
        int sampleRate = 48000;
        /** 播放音量，取值范围[0-100]，默认值：50 */
        int playoutVolume = 50;
        /** 推流音量，取值范围[0-100]，默认值：50 */
        int publishVolume = 50;
        /** 1-作为Dual音频流推流，0-作为MIC音频流推流 */
        int publishStream = 0;
        /** 输入PCM做3A处理 */
        bool enable3A = false;
    } AliEngineExternalAudioStreamConfig;

    /**
     * @brief 音频数据回调模式
     */
    typedef enum {
        AliEngineAudioFrameObserverOperationModeReadOnly = 0,
        AliEngineAudioFrameObserverOperationModeWriteOnly = 1,
        AliEngineAudioFrameObserverOperationModeReadWrite = 2
    } AliEngineAudioFrameObserverOperationMode;

    typedef enum {
        /* onMixedAllAudioFrame回调混外部推流的音频 **/
        AliEngineAudioFrameObserverUserDefinedInfoBitMaskMixExCapture = 1 << 0,
        /* onMixedAllAudioFrame回调混外部渲染的音频 **/
        AliEngineAudioFrameObserverUserDefinedInfoBitMaskMixExRender = 1 << 1,
    } AliEngineAudioFrameObserverUserDefinedInfoBitMask;

    /**
     * @brief 音频数据回调参数设置
     *
     */
    typedef struct AliEngineAudioFrameObserverConfig{
        /* 回调音频采样率 */
        AliEngineAudioSampleRate sampleRate = AliEngineAudioSampleRate_48000;
        /* 回调音频声道数 */
        AliEngineAudioNumChannelType channels = AliEngineMonoAudio;
        /* 回调模式 */
        AliEngineAudioFrameObserverOperationMode mode = AliEngineAudioFrameObserverOperationModeReadOnly;
        /* 自定义参数, 取值见AliEngineAudioFrameObserverUserDefinedInfoBitMask*/
        int userDefinedInfo = AliEngineAudioFrameObserverUserDefinedInfoBitMaskMixExRender;
    } AliEngineAudioFrameObserverConfig;

    typedef struct AliEngineFileInputConfig{
      bool enableVideo = false;
      bool enableAudioPush = false;
      bool enableAudioRender = false;

      String filePath;
      AliEngineVideoTrack type = AliEngineVideoTrackCamera;
      AliEngineRenderMode renderMode = AliEngineRenderModeAuto;
      bool enableLoop = false;

      int renderVolume = 100;
      int pushVolume = 100;
      IExternalFileObserver *observer = nullptr;
    } AliEngineFileInputConfig;

    /**
     * @brief 文件播放状态回调，当操作文件动作触发时，会触发相应状态改变
     */
    typedef enum {
        AliExternalFileStateNone = 0,
        /* 已准备好，可以开始播放文件 */
        AliExternalFileStateReady = 1,
        /* 暂停 */
        AliExternalFileStatePaused = 2,
        /* 播放中 */
        AliExternalFileStatePlaying = 3,
        /* 播放完成 */
        AliExternalFileStateEnd = 4,
        /* 已停止 */
        AliExternalFileStateStoped = 5,

        AliExternalFileStateInvalid = 0xFF,
    } AliEngineExternalFileState;

    /**
     * @brief 文件播放错误码，用于返回异常原因
     */
    typedef enum {
        AliEngineExternalFileErrorNone = 0,
        /* 打开文件失败，请检查文件路径是否正确 */
        AliEngineExternalFileErrorFileOpenFailed = 1,
        /* 文件格式不支持 */
        AliEngineExternalFileErrorNotAllowdMuxer = 2,
        /* 视频编码类型不支持 */
        AliEngineExternalFileErrorNotAllowdVideoCodec = 3,
        /* 音频编码类型不支持 */
        AliEngineExternalFileErrorNotAllowdAudioCodec = 4,
        /* 解码视频帧异常 */
        AliEngineExternalFileErrorDecodeVideo = 5,   
        /* 解码音频帧异常 */     
        AliEngineExternalFileErrorDecodeAudio = 6,   
        /* 跳转位置异常 */
        AliEngineExternalFileErrorSeekPos = 7,  
        /* 暂停异常，未处于可暂停的状态 */
        AliEngineExternalFileErrorPause = 8,
        /* 恢复播放异常，未处于暂停状态 */
        AliEngineExternalFileErrorResume = 9,
        /* 没有视频资源可以输入，视频外部输入资源已被占用 */
        AliEngineExternalNoVideoSourceUse = 10,
        /* 没有音频资源可以输入，音频外部输入资源已被占用 */
        AliEngineExternalNoAudioSourceUse = 11,
    } AliEngineExternalFileError;
    /**
     * @}
     */

    /**
     * @addtogroup AliEngineCallback 回调及监听
     * AliRtc 回调及监听
     * @{
     */
    /**
     * @brief 音频数据监听接口
     */
    class ALI_RTC_API IExternalFileObserver {
    public:
        virtual ~IExternalFileObserver() {}
        /**
         * @brief 文件播放状态回调
         * @param stateCode 播放状态，详情见AliEngineExternalFileState
         */
        virtual void OnExternalFileState(AliEngineExternalFileState stateCode) = 0;
        /**
         * @brief 文件播放异常状态回调
         * @param errorCode 异常状态，详情见AliEngineExternalFileError
         */
        virtual void OnExternalFileError(AliEngineExternalFileError errorCode) = 0;    

        /**
         * @brief 文件当前总长度回调
         * @param durationMs 文件长度，单位ms
         */    
        virtual void OnExternalFileDuration(int64_t durationMs) = 0;

        /**
         * @brief 文件当前播放位置回调
         * @param currentMs 文件长度，单位ms
         */    
        virtual void OnExternalFileCurrentPlayPosition(int64_t currentMs) = 0;
        
        /**
         * @brief 文件当前分辨率基本信息
         * @param width 宽
         * @param height 高
         */
        virtual void OnExternalFileResolution(int width, int height) = 0;
    };


    /**
     * @brief 音频数据监听接口
     */
    class ALI_RTC_API IAudioFrameObserver {
    public:
        virtual ~IAudioFrameObserver() {}
        /**
         * @brief 采集裸数据回调
         * @details 默认关闭，需要通过enableAudioFrameObserver : YES audioSource: AlEngineAudioSourceCaptured 开启
         *
         *  - 该接口支持设置采样率、声道数
         *  - 该接口支持读写模式
         *
         * @param audioRawData 音频数据,详见{@link AliEngineAudioRawData}
         * @return true: success
         * @note 请不要在此回调函数中做任何耗时操作，否则可能导致声音异常
         */
        virtual bool OnCapturedAudioFrame(AliEngineAudioRawData audioRawData) = 0;
        
        /**
         * @brief 3A后数据回调
         * @details 默认关闭，需要通过enableAudioFrameObserver : YES audioSource: AliEngineAudioSourceCaptured 开启
         *
         *  - 该接口支持设置采样率、声道数
         *  - 该接口支持读写模式
         *
         * @param audioRawData 音频数据,详见{@link AliEngineAudioRawData}
         * @return true: success
         * @note 请不要在此回调函数中做任何耗时操作，否则可能导致声音异常
        */
        virtual bool OnProcessCapturedAudioFrame(AliEngineAudioRawData audioRawData) = 0;

        /**
         * @brief 推流数据回调
         * @details 默认关闭，需要通过enableAudioFrameObserver : YES audioSource: AliEngineAudioSourcePub 开启
         *
         *  - 该接口支持设置采样率、声道数
         *  - 该接口只支持只读模式
         *
         * @param audioRawData 音频数据,详见{@link AliEngineAudioRawData}
         * @return true: success
         * @note 请不要在此回调函数中做任何耗时操作，否则可能导致声音异常
         */
        virtual bool OnPublishAudioFrame(AliEngineAudioRawData audioRawData) = 0;

        /**
         * @brief 播放数据回调
         * @details 默认关闭，需要通过enableAudioFrameObserver : YES audioSource: AliEngineAudioSourcePlayback 开启
         *
         *  - 该接口支持设置采样率、声道数
         *  - 该接口支持读写模式
         *
         * @param audioRawData 音频数据,详见{@link AliEngineAudioRawData}
         * @return true: success
         * @note 请不要在此回调函数中做任何耗时操作，否则可能导致声音异常
         */
        virtual bool OnPlaybackAudioFrame(AliEngineAudioRawData audioRawData) = 0;

        /**
         * @brief 推流数据和播放数据混音后回调
         * @details 默认关闭，需要通过enableAudioFrameObserver : YES audioSource: AliEngineAudioSourceMixedAll 开启
         *
         *  - 该接口支持设置采样率、声道数
         *  - 该接口支持读写模式
         *
         * @param audioRawData 音频数据,详见{@link AliEngineAudioRawData}
         * @return true: success
         * @note 请不要在此回调函数中做任何耗时操作，否则可能导致声音异常
         */
        virtual bool OnMixedAllAudioFrame(AliEngineAudioRawData audioRawData) = 0;

        /**
         * @brief 远端拉流数据回调
         * @details 默认关闭，需要通过enableAudioFrameObserver : YES audioSource: AliEngineAudioSourceRemoteUser 开启
         *
         *  - 该接口不支持设置采样率、声道数
         *  - 该接口支持读写模式
         *
         * @param audioRawData 音频数据,详见{@link AliEngineAudioRawData}
         * @return true: success
         * @note 请不要在此回调函数中做任何耗时操作，否则可能导致声音异常
         */
        virtual bool OnRemoteUserAudioFrame(const char *uid, AliEngineAudioRawData audioRawData) = 0; 
    };

    /**
     * @brief 视频数据对象
     */
    class ALI_RTC_API IVideoFrameObserver {
    public:
      virtual ~IVideoFrameObserver() {}
      /**
       * @brief 订阅的本地采集视频数据回调
       * @param videoSource 视频数据源
       * @param videoRawData 视频裸数据
       * @return
       * - true: 需要写回SDK（只对I420和native(ios/mac)有效）
       * - false: 不需要写回SDK
       */
      virtual bool OnCaptureVideoSample(AliEngineVideoSource videoSource, AliEngineVideoRawData &videoRawData) = 0;

      /**
       * @brief 订阅的本地编码前视频数据回调
       * @param videoSource 视频数据源
       * @param videoRawData 视频裸数据
       * @return
       * - true: 需要写回SDK（只对I420和native(ios/mac)有效）
       * - false: 不需要写回SDK
       */
      virtual bool OnPreEncodeVideoSample(AliEngineVideoSource videoSource, AliEngineVideoRawData &videoRawData) = 0;

      /**
       * @brief 订阅的远端视频数据回调
       * @param uid 用户ID
       * @param videoSource 视频数据源
       * @param videoRawData 视频裸数据
       * @return
       * - true: 需要写回SDK（只对I420和native(ios/mac)有效）
       * - false: 不需要写回SDK
       */
      virtual bool OnRemoteVideoSample(const char *uid,
        AliEngineVideoSource videoSource,
        AliEngineVideoRawData &videoRawData) = 0;
      
      /**
       * @brief 订阅的远端视频数据，以NALU形式回调
       * @param uid 用户ID
       * @param videoSource 视频数据源
       * @param videoEncodedData 视频编码数据（NALU）
       * @return
       * - true: 需要写回SDK
       * - false: 不需要写回SDK
       */
      virtual bool OnRemoteVideoEncodedSample(const char *uid, 
        AliRTCSdk::AliEngineVideoSource videoSource,
        AliRTCSdk::AliEngineVideoEncodedData &videoEncodedData) {return false;}

      /**
       * @brief 视频输出数据是否由用户来获取
       * @return
       * - true: 用户获取
       * - false（默认）: sdk通过回调向外抛出
       */ 
      virtual bool GetIfUserFetchObserverData() {return false;}
  
      /**
       * @brief 视频数据输出格式
       * @return 期望视频输出格式
       */ 
      virtual AliEngineVideoFormat GetVideoFormatPreference() { return AliEngineVideoFormatI420; }

      /**
       * @brief 视频输出宽度对齐方式
       * @return 期望视频输出宽度对齐方式
       */ 
      virtual AliEngineVideoObserAlignment GetVideoAlignment() { return AliEngineAlignmentDefault; }

      /**
       * @brief 视频数据输出内容
       * @return 期望视频输出内容，参考 {@link AliEngineVideoObserPosition}
       */
      virtual uint32_t GetObservedFramePosition() { return static_cast<uint32_t>(AliEnginePositionPostCapture | AliEnginePositionPreRender); };

      /**
       * @brief 视频输出数据是否需要镜像
       * @return true, 镜像；false（默认）, 不镜像
       */
      virtual bool GetObserverDataMirrorApplied() {return false;}

      /**
       * @brief 拉流视频数据是否平滑输出
       * @return 
       * - true: 平滑输出
       * - false（默认）: 直接输出，只在 GetIfUserFetchObserverData 为false时有效
       */
      virtual bool GetSmoothRenderingEnabled() {return false;}
    };


    /**
     * @brief OpenGL纹理数据观测器
     */
    class ALI_RTC_API IVideoTextureObserver {
    public:
      virtual ~IVideoTextureObserver() {}
      /**
       * @brief OpenGL上下文创建回调
       * @param context OpenGL上下文
       * @note 该回调是在SDK内部OpenGL上下文创建的时候触发
       */
      virtual void OnTextureCreate(void* context) {}

      /**
       * @brief OpenGL纹理更新回调
       * @param textureId OpenGL纹理ID
       * @param width OpenGL纹理高
       * @param height OpenGL纹理宽
       * @param videoRawData 视频帧数据，详见 {@link AliEngineVideoRawData}
       * @return OpenGL纹理ID
       * @note
       * - 该回调会在每一帧视频数据上传到OpenGL纹理之后触发，当外部注册了OpenGL纹理数据观测器，在该回调中可以对纹理进行处理，并返回处理后的纹理ID
       * - 注意该回调返回值必须为有效的纹理ID，如果不做任何处理必须返回参数textureId
       */
      virtual int OnTextureUpdate(int textureId, int width, int height, AliEngineVideoRawData &videoRawData) { return 0; }

      /**
       * @brief OpenGL上下文销毁回调
       * @note 该回调是在SDK内部OpenGL上下文销毁的时候触发
       */
      virtual void OnTextureDestory() {}
    };

    /**
     * @}
     */

    /**
     * @addtogroup AliEngine AliEngine
     * AliRtc 核心接口类
     * @{
     */

    /**
     * @brief 音视频媒体数据相关功能
     */
    class ALI_RTC_API IAliEngineMediaEngine
    {
    public:
      /**
       * @brief 释放IAliEngineMediaEngine资源
       * @note 请确保不再使用时调用，防止泄漏
       */
      virtual void Release() = 0;

      /**
       * @brief 订阅视频数据输出
       * @param observer 视频数据接收对象
       * @note 输出数据将通过 {@link IVideoFrameObserver} 回调返回
       */
      virtual void RegisterVideoSampleObserver(IVideoFrameObserver* observer) = 0;

      /**
       * @brief 取消订阅视频数据输出
       * @param observer 视频数据接收对象
       */
      virtual void UnRegisterVideoSampleObserver(IVideoFrameObserver* observer) = 0;

      /**
       * @brief 主动获取采集数据
       * @param type 视频流类型 {@link AliRTCSdk::AliEngineVideoTrack}
       * @param videoRaw 数据接收对象
       * @return
       * - true: 成功
       * - false: 失败
       * @note 仅在 {@link IVideoFrameObserver::GetIfUserFetchObserverData} 返回true时有效
       */
      virtual bool GetVideoCaptureData(AliEngineVideoTrack type, AliEngineVideoRawData &videoRaw) = 0;

      /**
       * @brief 主动获取编码前数据
       * @param type 视频流类型 {@link AliRTCSdk::AliEngineVideoTrack}
       * @param videoRaw 数据接收对象
       * @return
       * - true: 成功
       * - false: 失败
       * @note 仅在 {@link IVideoFrameObserver::GetIfUserFetchObserverData} 返回true时有效
       */
      virtual bool GetVideoPreEncoderData(AliEngineVideoTrack type, AliEngineVideoRawData &videoRaw) = 0;

      /**
       * @brief 主动获取拉流数据
       * @param uid 用户ID。从App server分配的唯一标示符
       * @param type 视频流类型 {@link AliRTCSdk::AliEngineVideoTrack}
       * @param videoRaw 数据接收对象
       * @return
       * - true: 成功
       * - false: 失败
       * @note 仅在 {@link IVideoFrameObserver::GetIfUserFetchObserverData} 返回true时有效
       */
      virtual bool GetVideoRenderData(const char *uid,AliEngineVideoTrack type, AliEngineVideoRawData &videoRaw) = 0;

      /**
       * @brief 注册本地相机流视频OpenGL纹理数据观测器
       * @param observer OpenGL纹理数据观测器。非空值，传空调用失败。详见 {@link AliRTCSdk::IVideoTextureObserver}
       * @note
       * - 成功注册本地相机流视频OpenGL纹理数据观测器后，SDK会在捕捉到每个视频帧时，触发你在 IVideoTextureObserver 接口中实现的回调
       * - 该接口只能对本地相机流视频有效
       * - 该接口只适用于Android和iOS平台
       */
      virtual void RegisterLocalVideoTextureObserver(IVideoTextureObserver* observer) = 0;

      /**
       * @brief 取消注册本地相机流视频OpenGL纹理数据观测器
       * @param observer OpenGL纹理数据观测器
       * @note 该接口只适用于Android和iOS平台
       */
      virtual void UnRegisterLocalVideoTextureObserver(IVideoTextureObserver* observer) = 0;

      /**
       * @brief 注册音频数据回调
       * @param observer 音频数据回调，delegate = nil 则停止回调数据 {@link AliRTCSdk::IAudioFrameObserver}
       * @note 需要调用EnableAudioFrameObserver开启具体AliEngineAudioSource的回调
       * @return
       * - 0: 成功
       * - 非0: 失败
      */
      virtual int RegisterAudioFrameObserver(IAudioFrameObserver* observer) = 0;
        
      /**
       * @brief 取消订阅音频数据输出
       * @param observer 音频数据监听对象实例: {@link AliRTCSdk::IAudioFrameObserver}
       */
      virtual void UnRegisterAudioFrameObserver(IAudioFrameObserver* observer) = 0;
        
      /**
       * @brief 订阅音频数据
       * @param enabled 是否允许数据回调
       * @param audioSource 音频裸数据源类型，详见 {@link AliRtcAudioSource}
       * @param config 回调参数设置，详见{@link AliEngineAudioFrameObserverConfig}, null时默认参数为48000，1，ReadOnly
       * @details
       *  - AliEngineAudioSourcePub、AliEngineAudioSourceMixedAll只支持ReadOnly模式
       *  - AliEngineAudioSourceRemoteUser不支持修改采样率、通道数
       * @return 0: sucess
       */
       virtual int EnableAudioFrameObserver(bool enabled, AliEngineAudioSource audioSource, AliEngineAudioFrameObserverConfig config) = 0;
      
      /**
       * @brief 订阅音频事件（默认订阅）, 如音频啸叫
       * @return
       * - 0: 成功
       * - 非0: 失败
       */
      virtual int RegisterAudioEventObserver() = 0;
        
      /**
       * @brief 取消订阅音频事件
       */
      virtual void UnRegisterAudioEventObserver() = 0;

      /**
       * @brief 启用外部视频输入源
       * @param enable
       * - true 开启
       * - false 关闭
       * @param type 流类型，详见 {@link AliRTCSdk::AliEngineVideoTrack}
       * - AliEngineVideoTrackCamera 外部输入视频数据走相机流通道，如果当前相机采集打开中，调用该接口设置enable为true，sdk会替换掉相机采集
       * - AliEngineVideoTrackScreen 外部输入视频数据走屏幕流通道，如果当前屏幕共享采集打开中，调用该接口设置enable为true，sdk会替换掉屏幕共享采集
       * @param renderMode 处理模式，外部输入视频源宽高比和推流profile不一致时，会按照对应的rendermode做对应处理，详见 {@link AliRTCSdk::AliEngineRenderMode}
       * - AliEngineRenderModeAuto 自动（默认），如果外部输入的视频宽高比和推流设置的宽高比不一致时，维持外部输入的视频宽高比，等比例缩放宽高到推流设置的宽高范围内，注意此模式下为了保证原始视频的比例和内容完整性，会导致实际推流的分辨率和设置的不一致
       * - AliEngineRenderModeStretch 拉伸平铺，如果外部输入的视频宽高比和推流设置的宽高比不一致时，将输入视频拉伸到推流设置的比例，画面会变形
       * - AliEngineRenderModeFill 填充黑边，如果外部输入的视频宽高比和推流设置的宽高比不一致时，将输入视频上下或者左右填充黑边
       * - AliEngineRenderModeCrop 裁剪，如果外部输入的视频宽高比和推流设置的宽高比不一致时，将输入视频宽或者高进行裁剪，画面内容会丢失
       * @return
       * - 0: 成功
       * - 非0: 失败
       */
      virtual int SetExternalVideoSource(bool enable,
        AliEngineVideoTrack type,
        AliEngineRenderMode renderMode) = 0;

      /**
       * @brief 输入视频数据
       * @param frame 帧数据，详见 {@link AliEngineVideoRawData}
       * @param type 流类型，详见 {@link AliEngineVideoTrack}
       * - AliEngineVideoTrackCamera 外部输入视频数据走相机流通道
       * - AliEngineVideoTrackScreen 外部输入视频数据走屏幕流通道
       * @return
       * - 0: 成功
       * - 非0: 失败
       * @note 如果返回值为errorCode中的AliRtcErrVideoBufferFull，代表当前buffer队列塞满，需要等待后再继续输送数据
       */
      virtual int PushExternalVideoFrame(const AliEngineVideoRawData &frame,
        AliEngineVideoTrack type) = 0;
        
        
     /**
      * @brief 输入视频数据
      * @param frame 帧数据，详见 {@link AliEngineVideoRawData}
      * @param type 流类型，详见 {@link AliEngineVideoTrack}
      * - AliEngineVideoTrackCamera 外部输入视频数据走相机流通道
      * - AliEngineVideoTrackScreen 外部输入视频数据走屏幕流通道
      * @return
      * - 0: 成功
      * - 非0: 失败
      * @note
      */
      virtual int SetExternalImageData(const AliEngineVideoRawData &frame, AliEngineVideoTrack type) = 0;

      /**
       * @brief 新增外部音频流
       * @param config 外部音频流配置 详见 {@link AliEngineExternalAudioStreamConfig}
       * @return
       * - >0: 外部音频流Id
       * - <0: 失败
       */
      virtual int AddExternalAudioStream(const AliEngineExternalAudioStreamConfig& config) = 0;
        
      /**
       * @brief 输入外部音频数据
       * @param streamId 外部音频流Id
       * @param data 外部音频裸数据 详见 {@link AliEngineAudioRawData}
       * @return
       * - <0: 表示失败;
       * - 0: 表示成功;
       * - 返回值为 {@link AliEngineErrorAudioBufferFull} 时，需要在间隔投递数据时间长度后再次重试投递
       * @note 为了保证语音连续性，sdk内部会有buffer缓存送进来的音频数据，以每次送10ms数据为例，如果返回{@link AliEngineErrorAudioBufferFull}时，说明内部缓冲区已满，建议等待20ms后再重新送当前数据帧；
       */
      virtual int PushExternalAudioStreamRawData(int streamId, AliEngineAudioRawData& data) = 0;
        
      /**
       * @brief 设置外部音频流播放音量
       * @param streamId 外部音频流Id
       * @param vol 音量 0-100
       * @return
       * - 0: 成功
       * - 非0: 失败
       */
      virtual int SetExternalAudioStreamPlayoutVolume(int streamId, int vol) = 0;
        
      /**
       * @brief 获取外部音频流播放音量
       * @param streamId 外部音频流Id
       * @return
       * - [0, 100]: 播放音量
       * - < 0: 失败
       */
      virtual int GetExternalAudioStreamPlayoutVolume(int streamId) = 0;
        
      /**
       * @brief 设置外部音频流推流音量
       * @param streamId 外部音频流Id
       * @param vol 音量 0-100
       * @return
       * - 0: 成功
       * - 非0: 失败
       */
      virtual int SetExternalAudioStreamPublishVolume(int streamId, int vol) = 0;
      
      /**
       * @brief 获取外部音频流推流音量
       * @param streamId 外部音频流Id
       * @return
       * - [0, 100]: 推流音量
       * - < 0: 失败
       */
      virtual int GetExternalAudioStreamPublishVolume(int streamId) = 0;
        
      /**
       * @brief 移除外部音频流
       * @param streamId 外部音频流Id
       * @return
       * - 0: 成功
       * - 非0: 失败
       */
      virtual int RemoveExternalAudioStream(int streamId) = 0;

      /**
       * @brief 开始外部文件播放
       * @return
       * - 0: 成功
       * - 非0: 失败
       */
      virtual int StartExternalFile(AliEngineFileInputConfig config) = 0;

      /**
       * @brief 停止外部文件播放
       * @return
       * - 0: 成功
       * - 非0: 失败
       */
      virtual int StopExternalFile() = 0;

      /**
       * @brief 设置外部文件音频推流音量
       * @param pushVol 推流音量
       * @return
       * - 0: 成功
       * - 非0: 失败
       */
      virtual int SetExternalFileAudioPublishVolume(int pushVol) = 0;

      /**
       * @brief 获取外部文件音频推流音量
       * @return
       * - >=0: 音量值
       * - -1: 失败
       */
      virtual int GetExternalFileAudioPublishVolume() = 0;

      /**
       * @brief 设置外部文件音频本地渲染音量
       * @param renderVol 本地播放音量
       * @return
       * - 0: 成功
       * - 非0: 失败
       */
      virtual int SetExternalFileAudioRenderVolume(int renderVol) = 0;

      /**
       * @brief 获取外部文件音频渲染音量
       * @return
       * - >=0: 音量值
       * - -1: 失败
       */
      virtual int GetExternalFileAudioRenderVolume() = 0;

      /**
       * @brief 暂停外部文件播放
       * @return
       * - 0: 成功
       * - 非0: 失败
       */
      virtual int PauseExternalFile() = 0;

      /**
       * @brief 恢复外部文件播放
       * @return
       * - 0: 成功
       * - 非0: 失败
       */
      virtual int ResumeExternalFile() = 0;

      /**
       * @brief 跳转到对应文件播放位置
       * @param posMs 跳转对应的位置
       * @return
       * - 0: 成功
       * - 非0: 失败
       */
      virtual int SeekExternalFilePosMs(int64_t posMs) = 0;


    protected:
      virtual ~IAliEngineMediaEngine() {}
    };

    /**
     * @}
     */
    
}

#endif /* BIZ_ENGINE_API_ENGINE_API_ENGINE_MEDIA_ENGINE_H_ */
