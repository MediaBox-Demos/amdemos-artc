/* Copyright (c) 2018, Alibaba Inc.
 * All rights reserved
 */

/* This header file is part of Alibaba RTC engine sdk for
 * Mac system.
 */

#import <AppKit/NSOpenGLView.h>
#import <AppKit/NSImage.h>
#import <AppKit/AppKit.h>

/**
 * @defgroup AliRtcDef_mac Mac关键类型定义
 * AliRTC功能的关键类型定义
 * @{
 */

/**
 * @brief 视频流类型
 */
typedef NS_ENUM(NSUInteger, AliRtcVideoTrack) {
    /** 无视频流 */
    AliRtcVideoTrackNo     = 0,
    /** 相机流 */
    AliRtcVideoTrackCamera = 1,
    /** 屏幕共享流 */
    AliRtcVideoTrackScreen = 2,
    /** 相机流和屏幕共享流 */
    AliRtcVideoTrackBoth   = 3,
};

/**
 *@brief 视频缩放时机
 */
typedef NS_ENUM(NSUInteger, AliRtcCapturePipelineScaleMode) {
    /* 采集后立即进行缩放，默认 */
    AliRtcCapturePipelineScaleModePre = 0,
    /* 编码时进行缩放 */
    AliRtcCapturePipelineScaleModePost = 1,
};

/**
 * @brief 音频流类型
 */
typedef NS_ENUM(NSUInteger, AliRtcAudioTrack) {
    /** 无麦克风 */
    AliRtcAudioTrackNo   = 0,
    /** 麦克风 */
    AliRtcAudioTrackMic  = 1,
    /** 第二流 */
    AliRtcAudioTrackDual = 2,
};

/**
 * @brief 网络质量
 */
typedef NS_ENUM(NSUInteger, AliRtcNetworkQuality) {
    /** 网络极好，流程度清晰度质量好 */
    AlivcRtcNetworkQualityExcellent  = 0,
    /** 网络好，流畅度清晰度和极好差不多 */
    AlivcRtcNetworkQualityGood       = 1,
    /** 网络较差，音视频流畅度清晰度有瑕疵，不影响沟通 */
    AlivcRtcNetworkQualityPoor       = 2,
    /** 网络差，视频卡顿严重，音频能正常沟通 */
    AlivcRtcNetworkQualityBad        = 3,
    /** 网络极差，基本无法沟通 */
    AlivcRtcNetworkQualityVeryBad    = 4,
    /** 网络中断 */
    AlivcRtcNetworkQualityDisconnect = 5,
    /** 未知 */
    AlivcRtcNetworkQualityUnknow     = 6,
};

/**
 * @brief 音频编码模式
 */
typedef NS_ENUM(NSInteger, AliRtcAudioProfile) {
    /** 音频低音质模式，默认8000Hz采样率，单声道，最大编码码率12kbps */
    AliRtcEngineLowQualityMode        = 0x0000, 
    /** （默认）标准音质模式，默认16000Hz采样率，单声道，最大编码码率24kbps */
    AliRtcEngineBasicQualityMode      = 0x0001,
    /** 高音质模式，默认48000Hz采样率，单声道，最大编码码率64kbps */
    AliRtcEngineHighQualityMode       = 0x0010,
    /** 立体声高音质模式，默认48000Hz采样率，双声道，最大编码码率80kbps */
    AliRtcEngineStereoHighQualityMode = 0x0011,
    /** 超高音质模式，默认48000Hz采样率，单声道，最大编码码率96kbps */
    AliRtcEngineSuperHighQualityMode = 0x0012,
    /** 立体声超高音质模式，默认48000Hz采样率，双声道，最大编码码率128kbps */
    AliRtcEngineStereoSuperHighQualityMode = 0x0013,
};

/**
 * @brief 音频场景模式
 */
typedef NS_ENUM(NSInteger, AliRtcAudioScenario) {
    /** 默认场景，一般的音视频通信场景推荐使用 */
    AliRtcSceneDefaultMode   = 0x0000,
    /** 教育场景，优先保证音频连续性与稳定性 */
    AliRtcSceneEducationMode = 0x0100,
    /** 媒体场景，保真人声与音乐音质, 连麦直播间推荐使用 */
    AliRtcSeneMediaMode      = 0x0200,
    /** 音乐场景，高保真音乐音质，乐器教学等对音乐音质有要求的场景推荐使用 */
    AliRtcSceneMusicMode     = 0x0300,
    /** 聊天室模式，适用于频繁上下麦的场景 */
    AliRtcSceneChatroomMode  = 0x0400,
    /** ktv模式，低延迟和ntp时间同步 */
    AliRtcSceneKtvMode = 0x0500,
};

/**
 * @brief 音频质量
*/
typedef NS_ENUM(NSInteger, AliRtcTranportAudioQuality) {
    /** 质量未知 */
    AliRtcAudioQulityUnknow = 0,
    /** 质量极好 */
    AliRtcAudioQulityExcellent = 1,
    /** 用户主观感觉和极好差不多 ，但码率可能略低于极好 */
    AliRtcAudioQulityGood = 2,
    /** 用户主观感受有瑕疵，但不影响沟通 */
    AliRtcAudioQulityPoor = 3,
    /** 勉强能沟通但不顺畅 */
    AliRtcAudioQulityBad = 4,
    /** 网络质量非常差，基本不能沟通 */
    AliRtcAudioQulityVeryBad = 5,
    /** 网络连接已断开，完全无法沟通 */
    AliRtcAudioQulityNetworkDisconnected = 6,
};


/**
 * @brief 视图显示模式
 */
typedef NS_ENUM(NSUInteger, AliRtcRenderMode) {
    /** 自动模式 */
    AliRtcRenderModeAuto    = 0,
    /** 拉伸平铺模式 ，如果外部输入的视频宽高比和推流设置的宽高比不一致时，将输入视频拉伸到推流设置的比例，画面会变形*/
    AliRtcRenderModeStretch = 1,
    /** 填充黑边模式，如果外部输入的视频宽高比和推流设置的宽高比不一致时，将输入视频上下或者左右填充黑边 */
    AliRtcRenderModeFill    = 2,
    /** 裁剪模式，如果外部输入的视频宽高比和推流设置的宽高比不一致时，将输入视频宽或者高进行裁剪，画面内容会丢失 */
    AliRtcRenderModeCrop    = 3,
};

/**
 * @brief 镜像模式
 */
typedef NS_ENUM(NSInteger, AliRtcRenderMirrorMode) {
    /** 镜像开启 */
    AliRtcRenderMirrorModeAllEnabled = 1,
    /** 镜像关闭 */
    AliRtcRenderMirrorModeAllDisabled = 2,
};

/**
 * @brief 音乐伴奏播放状态
 */
typedef NS_ENUM(NSInteger, AliRtcAudioAccompanyStateCode) {
    /** 开始播放 */
    AliRtcAudioAccompanyStarted       = 100,
    /** 停止播放 */
    AliRtcAudioAccompanyStopped       = 101,
    /** 播放暂停 */
    AliRtcAudioAccompanyPaused        = 102,
    /** 播放恢复 */
    AliRtcAudioAccompanyResumed       = 103,
    /** 播放完毕 */
    AliRtcAudioAccompanyEnded         = 104,
    /** 正在缓冲 */
    AliRtcAudioAccompanyBuffering     = 105,
    /** 缓冲结束 */
    AliRtcAudioAccompanyBufferingEnd  = 106,
    /** 播放失败 */
    AliRtcAudioAccompanyFailed        = 107,
};

/**
 * @brief 音乐伴奏播放错误码
 */
typedef NS_ENUM(NSInteger, AliRtcAudioAccompanyErrorCode) {
    /** 没有错误 */
    AliRtcAudioAccompanyNoError        = 0,
    /** 打开文件失败 */
    AliRtcAudioAccompanyOpenFailed     = -100,
    /** 解码文件失败 */
    AliRtcAudioAccompanyDecodeFailed   = -101,
};

/**
 * @brief 视频旋转角度
 */
typedef NS_ENUM(NSInteger, AliRtcRotationMode) {
    /** 视频旋转角度 - 0 */
    AliRtcRotationMode_0    = 0,
    /** 视频旋转角度 - 90 */
    AliRtcRotationMode_90   = 90,
    /** 视频旋转角度 - 180 */
    AliRtcRotationMode_180  = 180,
    /** 视频旋转角度 - 270 */
    AliRtcRotationMode_270  = 270,
};

/**
 * @brief Log级别
 */
typedef NS_ENUM(NSUInteger, AliRtcLogLevel) {
    /** 只输出>=AliEngineLogLevelInfo 级别的日志*/
    AliRtcLogLevelInfo = 3,
    /** 只输出>=AliEngineLogLevelWarn 级别的日志*/
    AliRtcLogLevelWarn,
    /** 只输出>=AliEngineLogLevelError 级别的日志*/
    AliRtcLogLevelError,
    /** 只输出>=AliEngineLogLevelFatal 级别的日志*/
    AliRtcLogLevelFatal,
    /** 不输出日志 */
    AliRtcLogLevelNone,
};

/**
 * @brief 相机流类型
 */
typedef NS_ENUM(NSInteger, AliRtcVideoStreamType) {
    /** 无，在OnSubscribeStreamTypeChanged回调表示当前未订阅 */
  AliRtcVideoStreamTypeNone = 0,
    /** 高码率，高分辨率流（大流） */
  AliRtcVideoStreamTypeHigh = 1,
    /** 低码率，低分辨率流（小流） */
  AliRtcVideoStreamTypeLow = 2,
};

/**
 * @brief 视频编码帧率
 */
typedef NS_ENUM(NSInteger, AliRtcVideoEncoderFrameRate) {
    /** 视频编码帧率 - 5帧 */
    AliRtcVideoEncoderFrameRate_FPS_5 = 5,
    /** 视频编码帧率 - 10帧 */
    AliRtcVideoEncoderFrameRate_FPS_10 = 10,
    /** 视频编码帧率 - 15帧 */
    AliRtcVideoEncoderFrameRate_FPS_15 = 15,
    /** 视频编码帧率 - 20帧 */
    AliRtcVideoEncoderFrameRate_FPS_20 = 20,
    /** 视频编码帧率 - 30帧 */
    AliRtcVideoEncoderFrameRate_FPS_30 = 30,
};

/**
 * @brief 视频编码码率
 */
typedef NS_ENUM(NSInteger, AliRtcVideoEncoderBitrate) {
    /** 视频编码标准码率 */
    AliRtcVideoEncoderStandardBitrate = 0,
};

/**
 * @brief 编码视频镜像模式
 */
typedef NS_ENUM(NSInteger, AliRtcVideoEncoderMirrorMode) {
    /** 视频编码不镜像 */
    AliRtcVideoEncoderMirrorModeDisabled = 0,
    /** 视频编码镜像 */
    AliRtcVideoEncoderMirrorModeEnabled = 1,
};

typedef NS_ENUM(NSInteger, AliRtcVideoEncodeCodecType) {
    /** 系统默认设置 */
    AliRtcVideoEncodeCodecTypeDefault = -1,
    /** h264编码 */
    AliRtcVideoEncodeCodecTypeH264 = 0,
    /** h265编码 */
    AliRtcVideoEncodeCodecTypeHevc = 1,
};


typedef NS_ENUM(NSInteger, AliRtcVideoCodecType) {
    /** 使用系统默认设置 */
    AliRtcVideoCodecTypeDefault = -1,             // not set
    /** 软件解码  */
    AliRtcVideoCodecTypeSoftware = 0 ,          // default set
    /** 硬件解码 */
    AliRtcVideoCodecTypeHardware = 1 ,          // hardware
};

/**
 * @brief 编码视频旋转模式
 */
typedef NS_ENUM(NSInteger, AliRtcVideoEncoderOrientationMode) {
    /** 自适应，和采集视频保持一致 */
    AliRtcVideoEncoderOrientationModeAdaptive = 0,
    /** 固定横屏 */
    AliRtcVideoEncoderOrientationModeFixedLandscape = 1,
    /** 固定竖屏 */
    AliRtcVideoEncoderOrientationModeFixedPortrait = 2,
};

/**
 * @brief 音频数据源类型
 */
typedef NS_ENUM(NSInteger, AliRtcAudioSource) {
    /** 采集的音频数据 */
    AliRtcAudioSourceCaptured = 0,
    /** 3A后的音频数据 */
    AliRtcAudioSourceProcessCaptured = 1,
    /** 推流的音频数据 */
    AliRtcAudioSourcePub = 2,
    /** 播放的音频数据 */
    AliRtcAudioSourcePlayback = 3,
    /** 推流和播放混音后的音频数据 */
    AliRtcAudioSourceMixedAll = 4,
    /** 拉流的远端音频数据 */
    AliRtcAudioSourceRemoteUser = 5,
};

/**
 * @brief 视频裸数据源类型
 
 - AliRtcVideosourceCameraType: 视频流
 - AliRtcVideosourceScreenShareType: 屏幕共享流
 - AliRtcVideosourceTypeMax: 占位符，无意义
 */
typedef NS_ENUM(NSInteger, AliRtcVideoSource) {
    /** 视频流 */
    AliRtcVideosourceCameraType = 0,
    /** 屏幕共享流 */
    AliRtcVideosourceScreenShareType = 1,
    /** 视频流 + 屏幕共享流 */
    AliRtcVideosourceBoth = 2,              // For video record
    /** 占位符，无意义 */
    AliRtcVideosourceTypeMax,
};

/**
 * @brief 音频声道数
 */
typedef NS_ENUM(NSInteger, AliRtcAudioNumChannel) {
    /** 单声道 */
    AliRtcMonoAudio = 1,
    /** 双声道 */
    AliRtcStereoAudio = 2,
};

/**
 * @brief 视频数据格式
 */
typedef NS_ENUM(NSInteger, AliRtcVideoFormat) {
    AliRtcVideoFormat_UNKNOW = -1,
    AliRtcVideoFormat_BGRA = 0,
    AliRtcVideoFormat_I420,
    AliRtcVideoFormat_NV21,
    AliRtcVideoFormat_NV12,
    AliRtcVideoFormat_RGBA,
    AliRtcVideoFormat_I422,
    AliRtcVideoFormat_ARGB,
    AliRtcVideoFormat_ABGR,
    AliRtcVideoFormat_RGB24,
    AliRtcVideoFormat_BGR24,
    AliRtcVideoFormat_RGB565,
    AliRtcVideoFormat_TextureOES,
    AliRtcVideoFormat_Texture2D,
    AliRtcVideoFormat_H264,
    AliRtcVideoFormat_H265,
    AliRtcVideoFormat_File,
};

/*
 * @brief 编码器解码器类型
*/
typedef NS_ENUM(NSInteger, AliRtcVideoCodecManufacturer) {
    AliRtcVideoCodecManufactureropenH264 = 0,
    AliRtcVideoCodecManufacturerX264 = 1,
    AliRtcVideoCodecManufacturerX265 = 2,
    AliRtcVideoCodecManufacturerS265 = 3,
    AliRtcVideoCodecManufacturerFFMPEG = 4 ,
    AliRtcVideoCodecManufacturerQsvIntel = 0x10,
    AliRtcVideoCodecManufacturerNvidia = 0x11,
    AliRtcVideoCodecManufacturerAMD = 0x12,
    AliRtcVideoCodecManufacturerMicrosoft = 0x13,
    AliRtcVideoCodecManufacturerVideoToolbox = 0x20,
    AliRtcVideoCodecManufacturerMediaCodec = 0x30,

    AliRtcVideoCodecManufacturerUnknown = 0xFFFF,
};

/**
 * @brief 视频编码器类型
 */
typedef NS_ENUM(NSInteger, AliRtcVideoCodecKindType) {
    AliRtcVideoCodecKind_UNKNOW = -1,
    AliRtcVideoCodecKind_Encoder = 0,
    AliRtcVideoCodecKind_Decoder,
};



/**
 * @brief 视频数据类型
 */
typedef NS_ENUM(NSInteger, AliRtcBufferType) {
    /** YUV裸数据 */
    AliRtcBufferType_Raw_Data = 0,
    /** opengl texture */
    AliRtcBufferType_Texture,
    /** CVPixelBuffer数据 */
    AliRtcBufferType_CVPixelBuffer,
    /** 文件路径 */
    AliRtcBufferType_File,
};

/**
 * @brief 变声音效模式
 */
typedef NS_ENUM(NSInteger, AliRtcAudioEffectVoiceChangerMode) {
    /** 关闭变声音效 */
    AliRtcAudioEffectvVoiceChanger_OFF = 0,
    /** 老人 */
    AliRtcAudioEffectvVoiceChanger_OLD_MAN,
    /** 男孩 */
    AliRtcAudioEffectvVoiceChanger_BABYBOY,
    /** 女孩 */
    AliRtcAudioEffectvVoiceChanger_BABYGILR,
    /** 机器人 */
    AliRtcAudioEffectvVoiceChanger_ROBOT,
    /** 大魔王 */
    AliRtcAudioEffectvVoiceChanger_DAIMO,
    /** KTV */
    AliRtcAudioEffectvVoiceChanger_KTV,
    /** 回声 */
    AliRtcAudioEffectvVoiceChangerR_ECHO,
    /** 方言 */
    AliRtcAudioEffectvVoiceChangerR_DIALECT,
    /** 怒吼 */
    AliRtcAudioEffectvVoiceChangerR_HOWL,
    /** 电音 */
    AliRtcAudioEffectvVoiceChangerR_ELECTRONIC,
    /** 留声机 */
    AliRtcAudioEffectvVoiceChangerR_PHONOGRAPH,
    /** 占位符 */
    AliRtcAudioEffectvVoiceChanger_MAX,
};

/**
 * @brief 音效混响模式
 */
typedef NS_ENUM(NSInteger, AliRtcAudioEffectReverbMode) {
    /** 关闭混响 */
    AliRtcAudioEffectReverb_Off = 0,
    /** 人声I */
    AliRtcAudioEffectReverb_Vocal_I,
    /** 人声II */
    AliRtcAudioEffectReverb_Vocal_II,
    /** 澡堂 */
    AliRtcAudioEffectReverb_Bathroom,
    /** 明亮小房间 */
    AliRtcAudioEffectReverb_Small_Room_Bright,
    /** 黑暗小房间 */
    AliRtcAudioEffectReverb_Small_Room_Dark,
    /** 中等房间 */
    AliRtcAudioEffectReverb_Medium_Room,
    /** 大房间 */
    AliRtcAudioEffectReverb_Large_Room,
    /** 教堂走廊 */
    AliRtcAudioEffectReverb_Church_Hall,
    /** 占位符 */
    AliRtcAudioEffectReverb_Mode_Max,
};


/** Audio equalization band frequency. */
typedef NS_ENUM(NSInteger, AliRtcAudioEffectEqualizationBandFrequency) {
  /** 31 Hz  */
  AliRtcAudioEffectEqualizationBand31 = 0,
  /** 62 Hz  */
  AliRtcAudioEffectEqualizationBand62 = 1,
  /** 125 Hz  */
  AliRtcAudioEffectEqualizationBand125 = 2,
  /** 250 Hz  */
  AliRtcAudioEffectEqualizationBand250 = 3,
  /** 500 Hz  */
  AliRtcAudioEffectEqualizationBand500 = 4,
  /** 1 kHz  */
  AliRtcAudioEffectEqualizationBand1K = 5,
  /** 2 kHz  */
  AliRtcAudioEffectEqualizationBand2K = 6,
  /** 4 kHz  */
  AliRtcAudioEffectEqualizationBand4K = 7,
  /** 8 kHz  */
  AliRtcAudioEffectEqualizationBand8K = 8,
  /** 16 kHz  */
  AliRtcAudioEffectEqualizationBand16K = 9,
};

/**
 * @brief 音效美声模式
 */
typedef NS_ENUM(NSInteger, AliRtcAudioEffectBeautifyMode) {
    /** 关闭 */
    AliRtcAudioEffectBeautify_Off = 0,
    /** 浑厚 */
    AliRtcAudioEffectBeautify_Vigorous,
    /** 嘹亮 */
    AliRtcAudioEffectBeautify_Ringing,
    /** 占位符 */
    AliRtcAudioEffectBeautify_Mode_Max,
};


/**
 * @brief 音效混响参数
 */
typedef NS_ENUM(NSInteger, AliRtcAudioEffectReverbParamType) {
    /** 房间大小，取值范围：[0, 100] */
    AliRtcAudioEffectReverb_Room_Size = 0,
    /** 预延时，单位ms，取值范围：[0, 200] */
    AliRtcAudioEffectReverb_Pre_Delay,
    /** 混响感，取值范围：[0, 100] */
    AliRtcAudioEffectReverb_Revetberance,
    /** 消声，取值范围：[0, 100] */
    AliRtcAudioEffectReverb_Hf_Damping,
    /** 低音调，取值范围：[0, 100] */
    AliRtcAudioEffectReverb_Tone_Low,
    /** 高音调，取值范围：[0, 100] */
    AliRtcAudioEffectReverb_Tone_High,
    /** 干增益，取值范围：[-20, 10] */
    AliRtcAudioEffectReverb_Dry_Gain,
    /** 湿增益，取值范围：[-20, 10] */
    AliRtcAudioEffectReverb_Wet_Gain,
    /** 占位符 */
    AliRtcAudioEffectReverb_Type_Max,
};

/**
 * @brief 网络连接状态
 */
typedef NS_ENUM(NSInteger, AliRtcConnectionStatus) {
    /** 初始化完成 */
    AliRtcConnectionStatusInit = 0,
    /** 网络连接断开 */
    AliRtcConnectionStatusDisconnected,
    /** 建立网络连接中 */
    AliRtcConnectionStatusConnecting,
    /** 网络已连接 */
    AliRtcConnectionStatusConnected,
    /** 重新建立网络连接中 */
    AliRtcConnectionStatusReconnecting,
    /** 网络连接失败 */
    AliRtcConnectionStatusFailed,
};

/**
 * @brief 引起网络状态变更原因
 */
typedef NS_ENUM(NSInteger, AliRtcConnectionStatusChangeReason) {
    /** 未知原因 */
    AliRtcConnectionChangedDummyReason = 0,
    /** 媒体通道变更 */
    AliRtcConnectionChangedMediaPathChanged,
    /** 心跳超时 */
    AliRtcConnectionChangedSignalingHeartbeatTimeout,
    /** 心跳恢复 */
    AliRtcConnectionChangedSignalingHeartbeatAlive,
    /** DNS解析成功 */
    AliRtcConnectionChangedSignalingHttpdnsResolved,
    /** DNS解析失败 */
    AliRtcConnectionChangedSignalingHttpdnsFailure,
    /** GSLB请求失败 */
    AliRtcConnectionChangedSignalingGslbFailure,
    /** GSLB请求成功 */
    AliRtcConnectionChangedSignalingGslbSucccess,
    /** 加入频道失败 */
    AliRtcConnectionChangedSignalingJoinChannelFailure,
    /** 加入频道成功 */
    AliRtcConnectionChangedSignalingJoinChannelSuccess,
    /** 离开频道 */
    AliRtcConnectionChangedSignalingLeaveRoom,
    /** 信令建立连接 */
    AliRtcConnectionChangedSignalingConnecting,
};

/**
 * @brief 频道类型
 
 - AliRtcCommunication: 通信模式
 - AliRtcInteractivelive: 直播模式
 - AliRtcInteractiveWithLowLatencyLive: 低延时互动直播模式
 */
typedef NS_ENUM(NSInteger, AliRtcChannelProfile) {
    AliRtcCommunication = 0,
    AliRtcInteractivelive,
    AliRtcInteractiveWithLowLatencyLive,
};

/**
 * @brief 角色类型
 */
typedef NS_ENUM(NSInteger, AliRtcClientRole) {
    /** 互动角色 */
    AliRtcClientRoleInteractive = 0,
    /** 观众角色 */
    AliRtcClientRolelive,
};

/**
 * @brief 功能聚合的profile
 */
typedef NS_ENUM(NSInteger, AliRtcCapabilityProfile) {
  /*! 默认值,*/
  AliRtcCapabilityProfileDefault = 0,
  /*! AI agent 通话场景下, 真实用户的功能 */
  AliRtcCapabilityProfileAiHuman = 1,
  /*! AI agent 通话场景下, 机器人的功能 */
  AliRtcCapabilityProfileAiRobot = 2,
};

/**
 * @brief 本地静音模式
*/
typedef NS_ENUM(NSInteger, AliRtcMuteLocalAudioMode) {
    /** 默认模式(静音全部，包括麦克风及外部输入音频) */
    AliRtcMuteAudioModeDefault = 0,
    /** 静音全部(包括麦克风及外部输入音频) */
    AliRtcMuteAllAudioMode,
    /** 只静音麦克风 */
    AliRtcMuteOnlyMicAudioMode,
    /** 占位符，无意义 */
    AliRtcMuteLocalAudioMax,
};


/**
 * @brief 桌面分享类型
 */
typedef NS_ENUM(NSInteger, AliRtcScreenShareType){
    AliRtcScreenShareDesktop = 0,      /* 桌面分享 */
    AliRtcScreenShareWindow  = 1,      /* 窗口分享 */
};

/**
 * @brief 错误码
 */
typedef NS_ENUM(NSInteger, AliRtcErrorCode) {
    /** 状态正常，无错误 */
    AliRtcErrNone                           = 0,
    /****************************************************
     * 入会错误码
     ****************************************************/
    /** AppId不存在，请在控制台创建应用 */
    AliRtcErrJoinBadAppId                   = 0x02010201,
    /** AppId已失效，请在控制台重新启用应用 */
    AliRtcErrJoinInvalidAppId               = 0x02010202,
    /**
     * 频道不存在，请尝试重新加入频道
     * 如会议发起者入会后又很快离会，第二个人随后入会，发现会议已经不存在了。
     */
    AliRtcErrJoinBadChannel                 = 0x02010204,
    /** 频道已经失效（目前频道有效期为48小时），请重新生成频道鉴权令牌（Token） */
    AliRtcErrJoinInvalidChannel             = 0x02010203,
    /** Token无效。 请重新生成频道鉴权令牌（Token） */
    AliRtcErrJoinBadToken                   = 0x02010205,
    /** 加入频道超时，请检查网络连接是否正常 */
    AliRtcErrJoinTimeout                    = 0x01020204,
    /** 参数错误，{@link AliRtcAuthInfo}中的字段为空或者timestamp<=0，请检查字段是否完整 */
    AliRtcErrJoinBadParam                   = 0x01030101,
    /** 加入频道失败 */
    AliRtcErrJoinChannelFailed              = 0x01030202,

    /****************************************************
     * 日志模块错误码
     ****************************************************/  
    /** 日志模块已经初始化 */
    AliRtcErrLogAlreadyInit = 0x01030105,
    /** 日志模块根路径错误，请检查路径是否存在或路径是否具有写入权限 */
    AliRtcErrLogRootPathError = 0x01030106,

    /****************************************************
     * 音频设备错误码
     ****************************************************/
    /**
     * 采集设备初始化失败、采集设备媒体服务异常、音频设备被占用。
     * - Mac端和Windows端查看系统设置中音频设备是否有能量条
     * - iOS端和Android端确认是否被其他应用占用
     * - 如果都正常，请重启设备
     */
    AliRtcErrMicOpenFail                    = 0x01040404,
    /**
     * 播放设备初始化失败、播放设备媒体服务异常、音频设备被占用。
     * - Mac端和Windows端查看系统设置中音频设备是否有能量条
     * - iOS端和Android端确认是否被其他应用占用
     * - 如果都正常，请重启设备
     */
    AliRtcErrSpeakerOpenFail                = 0x01040405,
    /** 系统性能不足、采集设备媒体服务异常、音频设备被占用。建议重启应用或重启设备 */
    AliRtcErrMicInterrupt                   = 0x01040406,
    /** 系统性能不足，播放设备媒体服务异常，音频设备被占用。建议重启应用或重启设备 */
    AliRtcErrSpeakerInterrupt               = 0x01040407,
    /** 麦克风设备未授权，建议去系统设置中，打开麦克风授权，并且重新加入频道 */
    AliRtcErrMicAuthFail                    = 0x01040408,
    /** 无可用的音频采集设备，检查是否接入了可用的麦克风，并检查系统设置中，该设备是否被禁用 */
    AliRtcErrMicNotAvailable                = 0x01040409,
    /** 无可用的音频播放设备，检查是否接入了可用的扬声器或耳机，并检查系统设置中，该设备是否被禁用 */
    AliRtcErrSpeakerNotAvailable            = 0x01040410,

    /****************************************************
     * 视频设备错误码
     ****************************************************/
    /** 采集设备初始化失败，检查系统相机是否可用，移动端App是否占用了相机 */
    AliRtcErrCameraOpenFail                 = 0x01040104,
    /** 采集过程中出现异常，Mac、Winodows电脑相机采集灯熄灭，设备被强制中断。建议重新加入频道或者重启App */
    AliRtcErrCameraInterrupt                = 0x01040106,
    /** 渲染设备初始化失败，检查Windows端显卡驱动是否需要升级，移动端手机型号或者Android平板盒子等外设是否支持OpenGL */
    AliRtcErrDisplayOpenFail                = 0x01040201,
    /** 渲染过程中出现异常，系统异常错误导致渲染引擎报错，重新加入频道或者重启App */
    AliRtcErrDisplayInterrupt               = 0x01040202,

    /****************************************************
     * 网络错误码
     ****************************************************/
    /** 媒体通道建立失败，检查网络连接是否正常 */
    AliRtcErrIceConnectionConnectFail       = 0x01050201,
    /** 媒体通道重连失败，检查网络连接是否正常 */
    AliRtcErrIceConnectionReconnectFail     = 0x01050202,
    /** 信令心跳超时，检查网络连接是否正常 */
    AliRtcErrIceConnectionHeartbeatTimeout  = 0x0102020C,

    /****************************************************
     * 低延时互动直播模式相关错误码
     ****************************************************/
    /** 低延时互动直播信令失败 */
    AliRtcErrCdnLiveCommunicationFailed     = 0x01070003,
    /** 低延时互动直播媒体设置错误 */
    AliRtcErrCdnLiveMeidaSettingFailed      = 0x01070004,
    /** 低延时互动直播当前房间没有主播推流 */
    AliRtcErrCdnLiveNoneBroadcaster         = 0x01070005,
    /** 低延时互动直播错误，应用层需要重新创建新的SDK实例 */
    AliRtcErrCdnLiveNeedRestart             = 0x01070006,
    /** 低延时互动直播错误，应用层需要稍等一定时间（自定义间隔）重新创建新的SDK实例 */
    AliRtcErrCdnLiveNeedRestartAgainLater   = 0x01070007,
    /** 低延迟互动直播服务不可用或者服务降级，客户端应该选择其它方式拉超大方会流，即不从cdn sfu拉流 */
    AliRtcErrCdnLiveServiceUnavailable      = 0x01070008,
    /** 低延迟互动直播网络中断错误，销毁当前sdk实例重新创建sdk后重新走订阅流程 */
    AliRtcErrCdnLiveMediaConnectionInterruption = 0x01070009,

    /****************************************************
     * 推流相关错误码
     ****************************************************/
    /** 推流无效 */
    AliRtcErrPublishInvaild                 = 0x01030305,
    /** 未进入频道推流失败 */
    AliRtcErrPublishNotJoinChannel          = 0x01010406,
    /** 推送音频流失败 */
    AliRtcErrPublishAudioStreamFailed       = 0x01010450,
    /** 推送视频流失败 */
    AliRtcErrPublishVideoStreamFailed       = 0x01010451,
    /** 推送小流失败 */
    AliRtcErrPublishDualStreamFailed        = 0x01010452,
    /** 推送屏幕共享失败 */
    AliRtcErrPublishScreenShareFailed       = 0x01010453,
    /** 屏幕共享配置错误 */
    AliRtcErrPublishScreenShareConfigError  = 0x01010454,

    /****************************************************
     * 订阅相关错误码
     ****************************************************/
    /** 订阅无效 */
    AliRtcErrSubscribeInvaild               = 0x01030404,
    /** 未进入频道订阅错误 */
    AliRtcErrSubscribeNotJoinChannel        = 0x01010550,
    /** 订阅音频流失败 */
    AliRtcErrSubscribeAudioStreamFailed     = 0x01010551,
    /** 订阅视频流失败 */
    AliRtcErrSubscribeVideoStreamFailed     = 0x01010552,
    /** 订阅小流失败 */
    AliRtcErrSubscribeDualStreamFailed      = 0x01010553,
    /** 订阅屏幕共享失败 */
    AliRtcErrSubscribeScreenShareFailed     = 0x01010554,
    /** 订阅RTS流失败*/
    AliRtcErrSubscribeRtsStreamFailed = 0x01010556,
    /** 暂停RTS流失败*/
    AliRtcErrPauseRtsStreamFailed = 0x01010557,

    /****************************************************
     * 其他错误码
     ****************************************************/
    /** SDK状态错误，建议销毁SDK重新创建实例。 */
    AliRtcErrSdkInvalidState                = 0x01030204,
    /** 参数不匹配 */
    AliRtcErrInvalidArguments               = 0x01030103,
    /** Session已经被移除，建议销毁实例之后重新创建实例并加入频道。 */
    AliRtcErrSessionRemoved                 = 0x02010105,
    /** buffer队列饱和，用于外部输送裸数据功能，建议降低外部输入频次，设置等待20ms，并且单次不超过40ms数据。 */
    AliRtcErrAudioBufferFull                = 0x01070101,
    /** buffer队列饱和，用于外部输送裸数据功能，建议降低外部输入频次，设置等待视频帧间隔后再输入。 */
    AliRtcErrVideoBufferFull                = 0x01070102,
    /** 互动模式下设置角色错误 */
    AliRtcErrUpdateRoleChannel              = 0x01020201,
    /** SDK内部错误 */
    AliRtcErrInner                          = -1,
};

/**
 * @brief OnBye类型
 */
typedef NS_ENUM(NSInteger, AliRtcOnByeType) {
    /** 当前user被踢出channel */
    AliRtcOnByeBeKickedOut          = 1,
    /** channel已结束，需要离开会议 */
    AliRtcOnByeChannelTerminated    = 2,
    /** 相同userID在其他设备joinChannel，当前设备被下线 */
    AliRtcOnByeUserReplaced         = 3,
    /** 超时 */
    AliRtcOnByeExpire               = 4,
    /** 重连 */
    AliRtcOnByeReconnect            = 5,
    /** 被封禁 */
    AliRtcOnByeBeBaned              = 6,
};

/**
 * @brief SDK问题反馈类型
 */
typedef NS_ENUM(NSInteger, AliRtcFeedbackType) {
    /** 视频设备问题 */
    AliRtcFeedbackVideoDeviceFail   = 101, 
    /** 视频无画面 */
    AliRtcFeedbackVideoNotRender    = 102, 
    /** 音频设备问题 */
    AliRtcFeedbackAudioDeviceFail   = 201, 
    /** 音频无声音 */
    AliRtcFeedbackAudioNotRender    = 202, 
    /** 音频回声异常 */
    AliRtcFeedbackAudioEchoError    = 203, 
    /** 会议状态异常：入会异常、离会异常等 */
    AliRtcFeedbackChannelTypeError  = 301, 
    /** SDK其他状态异常 */
    AliRtcFeedbackSDKTypeError      = 302, 
    /** 网络卡顿问题 */
    AliRtcFeedbackNetworkUnfluent   = 401, 
    /** 视频清晰问题 */
    AliRtcFeedbackVideoBlurring     = 402, 
    /** 未知类型 */
    AliRtcFeedbackUnkonw            = -1,  
};

/**
 * @brief 旁路推流LiveStream状态
 */
typedef NS_ENUM(NSInteger, AliRtcTrascodingLiveTaskStatus) {
    /** 任务开始 */
    AliRtcTrascodingLiveTaskStatusStart = 0,
    /** 任务更新 */
    AliRtcTrascodingLiveTaskStatusUpdate = 1,
    /** 任务已停止 */
    AliRtcTrascodingLiveTaskStatusStop = 2,
};

/**
 * @brief 旁路推流错误码
 */
typedef NS_ENUM(NSInteger, AliRtcTrascodingLiveStreamErrorCode) {
    AliRtcTrascodingLiveStreamErrorPublishOk            = 0,
    AliRtcTrascodingLiveStreamErrorStreamNotFound       = 0x01100001,
    AliRtcTrascodingLiveStreamErrorStreamAlreadyExist   = 0x01100002,
    AliRtcTrascodingLiveStreamErrorInvalidParam         = 0x01100003,
    AliRtcTrascodingLiveStreamErrorInternalError        = 0x01100004,
    AliRtcTrascodingLiveStreamErrorRtmpServerError      = 0x01100005,
    AliRtcTrascodingLiveStreamErrorRtmpStreamUrlError   = 0x01100006,
    AliRtcTrascodingLiveStreamErrorPublishTimeout       = 0x01100007,
    AliRtcTrascodingLiveStreamErrorNotAuthorized        = 0x01100008,
};

/**
 * @brief 跨频道转推事件
 */
typedef NS_ENUM(NSInteger, AliRtcChannelRelayEvent) {
    /** 跨频道转推开始 */
    AliRtcChannelRelayStart     = 0,
    /** 跨频道转推更新 */
    AliRtcChannelRelayUpdate    = 1,
    /** 跨频道转推结束 */
    AliRtcChannelRelayStop      = 2,
};

/**
 * @brief 跨频道转推事件
 */
typedef NS_ENUM(NSInteger, AliRtcChannelRelayState) {
    /** 跨频道转推初始化状态 */
    AliRtcChannelRelayStateInit         = 3,
    /** 跨频道转推连接中状态*/
    AliRtcChannelRelayStateConnecting   = 4,
    /** 跨频道转推运行中状态 */
    AliRtcChannelRelayStateRunning      = 5,
    /** 跨频道转推失败状态 */
    AliRtcChannelRelayStateFailure      = 6,
};

/**
 * @brief 录制类型
 */
typedef NS_ENUM(NSUInteger, AliRtcRecordType) {
    /** 录制单个音频文件 */
    AliRtcRecordTypeAudio = 0,
    /** 录制单个音视频文件 */
    AliRtcRecordTypeVideo,
    /** 录制纯音频和音视频文件 */
    AliRtcRecordTypeBoth,
};

/**
 * @brief 录制格式
 */
typedef NS_ENUM(NSUInteger, AliRtcRecordFormat) {
    /** 录制AAC格式文件 */
    AliRtcRecordFormatAAC = 0,
    /** 录制WAV格式文件 */
    AliRtcRecordFormatWAV,
    /** 录制MP4格式文件 */
    AliRtcRecordFormatMP4,
};

typedef NS_ENUM(NSInteger, AliRtcRecordMediaEventCode) {
    /** 超过设置的时长 */
    AliRtcRecordTimeOverLimit = -4 ,
    /** 超过设置的文件大小 */
    AliRtcRecordSizeOverLimit = -3 ,
    /* 超过2G进行文件分块 */
    AliRtcRecordOutOfSize = -2 ,
    /** 写文件失败 */
    AliRtcRecordWriteFailed = -1,
    /** 开始录制 */
    AliRtcRecordStart = 0,
    /** 停止录制 */
    AliRtcRecordStop = 1,
};
/**
 * @brief 录制音频质量
 */
typedef NS_ENUM(NSUInteger, AliRtcAudioQuality) {
    /** 低质量文件录制，文件体积较小，音质一般 */
    AliRtcAudioQualityLow = 0,
    /** 中等质量文件录制，文件体积中等，音质中等 */
    AliRtcAudioQualityMidium,
    /** 高质量文件录制，文件体积较大，音质较好 */
    AliRtcAudioQualityHigh,
};

/**
 * @brief 录制视频质量
*/
typedef NS_ENUM(NSUInteger, AliRtcVideoQuality) {
    /** 录制默认质量视频, 和采集保持一致 */
    AliRtcVideoQualityDefault = 0,
};

/**
 * @brief 录制音频采样率
*/
typedef NS_ENUM(NSInteger, AliRtcAudioSampleRate) {
    /** 采样率：8000 */
    AliRtcAudioSampleRate_8000 = 0,
    /** deprecated 采样率：11025 */
    AliRtcAudioSampleRate_11025 = 1,
    /** 采样率：16000 */
    AliRtcAudioSampleRate_16000 = 2,
    /** deprecated 采样率：22050 */
    AliRtcAudioSampleRate_22050 = 3,
    /** 采样率：32000 */
    AliRtcAudioSampleRate_32000 = 4,
    /** 采样率：44100 */
    AliRtcAudioSampleRate_44100 = 5,
    /** 采样率：48000 */
    AliRtcAudioSampleRate_48000 = 6,
    /** 采样率：12000 */
    AliRtcAudioSampleRate_12000 = 7,
    /** 采样率：24000 */
    AliRtcAudioSampleRate_24000 = 8,
    /** 未知采样率 */
    AliRtcAudioSampleRate_Unknown = 100,
};

/**
 * @brief 推流状态
 
 - AliRtcStatsPublishIdle:初始状态
 - AliRtcStatsNoPublish: 未推流
 - AliRtcStatsPublishing:推流中
 - AliRtcStatsPublished: 已推流
*/
typedef NS_ENUM(NSInteger, AliRtcPublishState) {
    AliRtcStatsPublishIdle = 0,
    AliRtcStatsNoPublish   = 1,
    AliRtcStatsPublishing  = 2,
    AliRtcStatsPublished   = 3,
};

/**
 * @brief 推流状态变化原因
*/
typedef NS_ENUM(NSInteger, AliRtcPublishStateChangedReason) {
    /** 用户调用 */
    AliRtcPublishStateChangedByUser = 0,
    /** 推流被封禁 */
    AliRtcPublishStateChangedByBan = 1,
};


/**
 * @brief 订阅状态
 */
typedef NS_ENUM(NSInteger, AliRtcSubscribeState) {
    /** 初始状态 */
    AliRtcStatsSubscribeIdle = 0,
    /** 未订阅 */
    AliRtcStatsNoSubscribe   = 1,
    /** 订阅中 */
    AliRtcStatsSubscribing   = 2,
    /** 已订阅 */
    AliRtcStatsSubscribed    = 3,
};

/**
 * @brief 用户离线原因
 */
typedef NS_ENUM(NSInteger, AliRtcUserOfflineReason) {
    /** 用户主动离开 */
    AliRtcUserOfflineQuit = 0,
    /** 因过长时间收不到对方数据包，超时掉线 */
    AliRtcUserOfflineDropped = 1,
    /** 用户身份从主播切换为观众时触发 */
    AliRtcUserOfflineBecomeAudience = 2,
};

/**
 * @brief 采集偏好
 */
typedef NS_ENUM(NSInteger, AliRtcCaptureOutputPreference)  {
    /** SDK自动调整采集参数 */
    AliRtcCaptureOutputPreferenceAuto = 0,
    /** SDK优先保证设备性能，根据设置编码参数选择最接近的摄像头输出参数 */
    AliRtcCaptureOutputPreferencePerformance = 1,
    /** SDK优先保证视频预览质量，选择较高的摄像头输出参数 */
    AliRtcCaptureOutputPreferencePreview = 2,
};

/**
 * @brief 指定采集分辨率
 */
typedef NS_ENUM(NSInteger, AliRtcCameraCaptureProfile) {
    /** 默认 */
    AliRtcCameraCaptureProfileDefault = 0,
    /** 视频1080P使用，开启后摄像头使用1080P分辨率采集 */
    AliRtcCameraCaptureProfile1080P = 1,
};

/**
 * @brief 视频数据输出位置内容
 */
typedef NS_ENUM(NSInteger, AliRtcVideoObserPosition) {
    /** 采集视频数据，对应输出回调onCaptureVideoSample */
    AliRtcPositionPostCapture = 1 << 0,
    /** 渲染视频数据，对应输出回调onRemoteVideoSample */
    AliRtcPositionPreRender = 1 << 1,
    /** 编码前视频数据，对应输出回调onPreEncodeVideoSample */
    AliRtcPositionPreEncoder = 1 << 2,
};

/**
 * @brief 视频输出宽度对齐方式
 */
typedef enum {
    /** 保持原有视频宽度(默认值) */
    AliRtcAlignmentDefault = 0,
    /** 宽度偶数对齐 */
    AliRtcAlignmentEven = 1,
    /** 宽度是4的倍数 */
    AliRtcAlignment4 = 2,
    /** 宽度是8的倍数 */
    AliRtcAlignment8 = 3,
    /** 宽度是16的倍数 */
    AliRtcAlignment16 = 4,
} AliRtcVideoObserAlignment;


/**
 * @brief 外接设备类型
*/
typedef NS_ENUM(NSInteger, AliRtcExternalDeviceType) {
  AliRtcExternalTypeUnknown = -1,       /* 未知类型 */
  AliRtcExternalTypeAudioCapture = 0,   /* 音频采集设备 */
  AliRtcExternalTypeAudioPlayout = 1,   /* 音频播放设备 */
  AliRtcExternalTypeVideoCapture = 2,   /* 视频采集设备 */
};

/**
 * @brief 外接设备状态
 */
typedef NS_ENUM(NSInteger, AliRtcExternalDeviceState) {
  AliRtcExternalDeviceAdd = 0,      /* 新增外接设备 */
  AliRtcExternalDeviceRemove = 1,   /* 移除外接设备 */
};

/**
 * @brief 设备传输类型
*/
typedef NS_ENUM(NSInteger, AliRtcDeviceTransportType) {
  AliRtcDeviceTransportTypeUnknown      = 0,
  AliRtcDeviceTransportTypeBuiltIn      = 1,
  AliRtcDeviceTransportTypeBluetooth    = 2,
  AliRtcDeviceTransportTypeUSB          = 3,
  AliRtcDeviceTransportTypeAggregate    = 4,
  AliRtcDeviceTransportTypeVirtual      = 5,
  AliRtcDeviceTransportTypePCI          = 6,
  AliRtcDeviceTransportTypeFireWire     = 7,
  AliRtcDeviceTransportTypeBluetoothLE  = 8,
  AliRtcDeviceTransportTypeHDMI         = 9,
  AliRtcDeviceTransportTypeDisplayPort  = 10,
  AliRtcDeviceTransportTypeAirPlay      = 11,
  AliRtcDeviceTransportTypeAVB          = 12,
  AliRtcDeviceTransportTypeThunderbolt  = 13
};

/**
 * @brief Debug显示类型
 */
typedef NS_ENUM(NSInteger, AliRtcShowDebugViewType){
    /** 不显示 */
    AliRtcShowTypeNone     = 0,
    /** 音频 */
    AliRtcShowTypeAudio    = 1,
    /** 视频 */
    AliRtcShowTypeVideo    = 2,
    /** 网络 */
    AliRtcShowTypeNetwork  = 3,
    /** 全部 */
    AliRtcShowTypeAll      = 4,
};

/**
 * @brief 视频状态
 */
typedef NS_ENUM(NSInteger, AliRtcVideoState){
    /** 视频关闭 */
    AliRtcVideoClose     = 0,
    /** 视频打开 */
    AliRtcVideoOpen    = 1,
};

/**
 * @brief 视频状态变化原因
 */
typedef NS_ENUM(NSInteger, AliRtcVideoReason){
    /** 由客户端触发 */
    AliRtcVideoChangeByClient     = 0,
    /** 由服务器触发 */
    AliRtcVideoChangeByServer    = 1,
};

/**
 * @brief 录制音频设置
 */
typedef struct  {
    /** 音频采样率类型 */
    AliRtcAudioSampleRate sampleRate;
    /** 音频录制质量 */
    AliRtcAudioQuality quality;
    /** 是否允许录制外部pcm输入采集数据 */
    bool enableRecordExternalCapturePCM;
    /** 是否允许录制外部pcm输入渲染数据 */
    bool enableRecordExternalRenderPCM;
}AliRtcRecordAudioConfig;

/**
 * @brief 音频数据回调模式
 */
typedef NS_ENUM(NSInteger, AliRtcAudioFrameObserverOperationMode) {
    AliRtcAudioFrameObserverOperationModeReadOnly = 0,
    AliRtcAudioFrameObserverOperationModeWriteOnly = 1,
    AliRtcAudioFrameObserverOperationModeReadWrite = 2
};

/**
 * @brief 音频数据回调自定义参数
 */
typedef NS_OPTIONS(NSInteger, AliRtcAudioFrameObserverUserDefinedInfoBitMask) {
    /* onMixedAllAudioFrame回调混外部推流的音频 **/
    AliRtcAudioFrameObserverUserDefinedInfoBitMaskMixExCapture = 1 << 0,
    /* onMixedAllAudioFrame回调混外部渲染的音频 **/
    AliRtcAudioFrameObserverUserDefinedInfoBitMaskMixExRender = 1 << 1,
};

/**
 * @brief 音频数据回调参数设置
 *
 */
@interface AliRtcAudioFrameObserverConfig : NSObject
    /* 回调音频采样率 */
    @property (nonatomic, assign)AliRtcAudioSampleRate sampleRate;
    /* 回调音频声道数 */
    @property (nonatomic, assign)AliRtcAudioNumChannel channels;
    /* 回调模式 */
    @property (nonatomic, assign)AliRtcAudioFrameObserverOperationMode mode;
    /* 自定义参数 */
    @property (nonatomic, assign)AliRtcAudioFrameObserverUserDefinedInfoBitMask userDefinedInfo;
@end

/**
 * @brief 录制视频分辨率
 * @note 画布大小
 */
typedef struct {
    /** 录制视频宽 */
    int canvasWidth;
    /** 录制视频高 */
    int canvasHeight;
}AliRtcRecordVideoCanvasConfig;

/**
 * @brief 录制视频设置
 */
typedef struct  {
    /** 视频质量 */
    AliRtcVideoQuality quality;
    /** 录制文件源类型 */
    AliRtcVideoSource sourceType;
    /** 录制文件尺寸 */
    AliRtcRecordVideoCanvasConfig canvas;
    /** 录制帧率 */
    int fps;
    /** 录制码率 */
    int bitrate;
}AliRtcRecordVideoConfig;

/**
 * @brief 录制视频背景色
 */
typedef struct  {
    /** 红色分量 */
    uint8_t r;
    /** 绿色分量 */
    uint8_t g;
    /** 蓝色分量 */
    uint8_t b;
}AliRtcRecordVideoBgColor;

typedef struct {
    uint32_t numerator;
    uint32_t denominator;
}AliRtcRecordVideoRational;

/**
 * @brief 录制视频布局
 */
typedef NS_ENUM(NSUInteger, AliRtcRecordVideoLayoutMode) {
    /** 网格布局 */
    AliRtcRecordVideoLayoutMode_GRID = 0,
    /** 演讲者布局 */
    AliRtcRecordVideoLayoutMode_SPEAKER = 1,
    /** 只有一个画面布局 */
    AliRtcRecordVideoLayoutMode_UNIQUE = 2,
    /** 自定义布局 */
    AliRtcRecordVideoLayoutMode_CUSTOM = 3,
};

/**
 * @brief 录制视频编码模式
 */
typedef NS_ENUM(NSUInteger, AliRtcRecordVideoEncodeMode) {
    /* 重新编码模式 */
    AliRtcRecordRawEncodeMode = 0,
    /* 重用推流编码器的流 */
    AliRtcRecordReusingEncoderMode,
};

/**
 * @brief 录制视频坐标
*/
typedef struct  {
    AliRtcRecordVideoRational left;
    AliRtcRecordVideoRational top;
    AliRtcRecordVideoRational width;
    AliRtcRecordVideoRational height;
}AliRtcRecordVideoRectangle;

/**
 * @brief 实时数据
 */
typedef struct {
    /** 可用带宽(kb) */
    long long available_sent_kbitrate;
    /** 总发送码率(kb) */
    long long sent_kbitrate;
    /** 总接收码率(kb) */
    long long rcvd_kbitrate;
    /** 总发送数据量(bytes) */
    long long sent_bytes;
    /** 总接收数据量(bytes) */
    long long rcvd_bytes;
    /** 视频接受码率(kb) */
    long long video_rcvd_kbitrate;
    /** 视频发送码率(kb) */
    long long video_sent_kbitrate;
    /** 通话时长(s) */
    long long call_duration;
    /** 进程CPU使用量(%) */
    float cpu_usage;
    /** 系统CPU使用量(%) */
    float systemCpuUsage;
    /** 客户端到服务器的丢包率(%) */
    long long sent_loss_rate;
    /** 客户端到服务器的丢包数 */
    long long sent_loss_pkts;
    /** 客户端到服务器的总包数 */
    long long sent_expected_pkts;
    /** 服务器到客户端的下行丢包率（%） */
    long long rcvd_loss_rate;
    /** 服务器到客户端的下行丢包数 */
    long long rcvd_loss_pkts;
    /** 服务器到客户端的下行总包数 */
    long long rcvd_expected_pkts;
    /** 客户端到服务器的延迟(ms) */
    long long lastmile_delay;
} AliRtcStats;

/**
 * @brief 背景替换功能中背景图缩放模式
 */
typedef NS_ENUM(NSUInteger, AliRtcBokehScaleModel) {
    /** 等比裁剪，当背景图像宽高比和视频数据宽高比不一致时, 为了保持等比例缩放, 会将背景图像裁剪到视频比例, 超出部分背景图片内容将会丢失 */
    AliRtcBokehScaleModelCrop = 0,
    /** 填充黑边，当背景图像宽高比和视频数据宽高比不一致时, 为了保持等比例缩放, 会对背景进行黑边填充 */
    AliRtcBokehScaleModelFill = 1,
};

/**
 * @brief 视频流镜像模式
*/
typedef NS_ENUM(NSUInteger, AliRtcVideoPipelineMirrorMode) {
    /** 预览和编码均关闭镜像 */
    AliRtcVideoPipelineMirrorModeNoMirror = 0,
    /** 预览和编码均打开镜像 */
    AliRtcVideoPipelineMirrorModeBothMirror = 1,
    /** 仅预览打开镜像 */
    AliRtcVideoPipelineMirrorModeOnlyPreviewMirror = 2,
    /** 仅推流打开镜像 */
    AliRtcVideoPipelineMirrorModeOnlyPublishMirror = 3,
};


/**
 * @brief 外部音频流配置
 */
@interface AliRtcExternalAudioStreamConfig : NSObject
/** 声道数，默认值：1 */
@property (nonatomic, assign) int channels;
/** 采样率，默认值：48000，支持的采样率 8000, 12000, 16000, 24000, 32000, 44100, 48000, 64000, 88200, 96000, 176400, 192000 */
@property (nonatomic, assign) int sampleRate;
/** 播放音量，取值范围[0-100]，默认值：50 */
@property (nonatomic, assign) int playoutVolume;
/** 播放音量，取值范围[0-100]，默认值：50 */
@property (nonatomic, assign) int publishVolume;
/** 第二音频流，1-第二音频流，0-MIC流 */
@property (nonatomic, assign) int publishStream;
/** 输入PCM做3A处理 */
@property (nonatomic, assign) BOOL enable3A;
@end

@interface AliRtcRecordVideoRegion : NSObject
@property (nonatomic, retain) NSString * _Nonnull userId;
@property (nonatomic, assign) AliRtcVideoSource sourceType;
@property (nonatomic, assign) AliRtcRecordVideoRectangle area;

@end

/**
 * @brief 录制视频布局
*/
@interface AliRtcRecordVideoLayout : NSObject
/** 视频布局模式 */
@property (nonatomic, assign) AliRtcRecordVideoLayoutMode mode;
/** 录制视频背景色 */
@property (nonatomic, assign) AliRtcRecordVideoBgColor backColor;
/** 录制视频用户布局数组 */
@property (nonatomic, retain) NSMutableArray<AliRtcRecordVideoRegion *> * _Nullable shapes;
/** 录制视频编码类型 */
@property (nonatomic, assign) AliRtcRecordVideoEncodeMode encodeMode;
/** 录制视频最大文件长度 字节单位 */
@property (nonatomic, assign) int64_t maxSize;
/** 录制视频最大时长 秒单位 */
@property (nonatomic, assign) int64_t maxDuration;
@end

/**
 * @brief 录制视频模板
*/
@interface AliRtcRecordTemplate : NSObject
/** 录制类型 */
@property (nonatomic, assign) AliRtcRecordType recordType;
/** 录制格式 */
@property (nonatomic, assign) AliRtcRecordFormat recordFormat;
/** 音频采样率类型 */
@property (nonatomic, assign) AliRtcAudioSampleRate sampleRate;
/** 音频录制质量 */
@property (nonatomic, assign) AliRtcAudioQuality audioQuality;
/** 外部pcm采集 */
@property (nonatomic, assign) bool enableRecordExternalCapturePCM;
/** 外部pcm渲染 */
@property (nonatomic, assign) bool enableRecordExternalRenderPCM;
/** 录制视频分辨率 */
@property (nonatomic, assign) AliRtcRecordVideoCanvasConfig canvas;
/** 帧率 */
@property (nonatomic, assign) int fps;
/** 码率 */
@property (nonatomic, assign) int bitrate;
/** 分段录制 */
@property (nonatomic, assign) bool isFragment;

@end


/**
 * @brief 美颜参数
 */
@interface AliRtcBeautyConfig : NSObject
/** 美白等级，建议取值范围[0-1.0] */
@property (nonatomic, assign) float whiteningLevel;
/** 磨皮等级，建议取值范围[0-1.0] */
@property (nonatomic, assign) float smoothnessLevel;
@end



/**
 * @brief 本地视频统计信息
 */
@interface AliRtcLocalVideoStats : NSObject

@property (nonatomic, assign) AliRtcVideoTrack track; /*  视频流track类型 */
/*! 采集视频帧宽度 */
@property (nonatomic, assign) unsigned int capture_width;
/*! 采集视频帧高度 */
@property (nonatomic, assign) unsigned int capture_height;
/*! 编码视频帧宽度 */
@property (nonatomic, assign) unsigned int encode_width;
/*! 编码视频帧高度 */
@property (nonatomic, assign) unsigned int encode_height;
@property (nonatomic, assign) unsigned int sent_bitrate;  /*  发送码率 */
@property (nonatomic, assign) unsigned int sent_fps;      /*  发送帧率 */
@property (nonatomic, assign) unsigned int encode_fps;    /*  编码帧率 */

@end

/**
 * @brief 发言人音量信息
 */
@interface AliRtcUserVolumeInfo : NSObject

/** 发言人的用户ID */
@property (nonatomic, copy) NSString * _Nonnull uid;
/** 发言状态，YES：正在说话，NO：没有说话 */
@property (nonatomic, assign) BOOL speech_state;
/** 音量值，取值范围[0,255] */
@property (nonatomic, assign) int volume;

@end

/**
 * @brief 远端视频统计信息
 */
@interface AliRtcRemoteVideoStats : NSObject

@property (nonatomic, copy) NSString * _Nonnull userId; /*  远端用户userID */
@property (nonatomic, assign) AliRtcVideoTrack track;   /*  视频流track类型 */
@property (nonatomic, assign) unsigned int width;           // width
@property (nonatomic, assign) unsigned int height;          // height
@property (nonatomic, assign) unsigned int decode_fps;      /*  解码帧率 */
@property (nonatomic, assign) unsigned int render_fps;      /*  渲染帧率 */
@property (nonatomic, assign) unsigned int frozen_times;    /*  卡顿次数 */
/*! 视频播放的累计卡顿时长，单位ms */
@property (nonatomic, assign) unsigned int video_total_frozen_time;
/*! 视频播放的累计卡顿率，单位% 计算方法 视频播放卡顿率=视频播放的累计卡顿时长/视频播放的总时长 */
@property (nonatomic, assign) unsigned int video_total_frozen_rate;

@end

/**
 * @brief 本地音频统计信息
 */
@interface AliRtcLocalAudioStats : NSObject

@property (nonatomic, assign) AliRtcAudioTrack track;   /*  音频流track类型 */
@property (nonatomic, assign) unsigned int sent_bitrate;    /*  发送码率 */
@property (nonatomic, assign) unsigned int sent_samplerate; /*  发送帧率 */
@property (nonatomic, assign) unsigned int num_channel;     /*  声道数 */
/*! 发送端丢包率 */
@property (nonatomic, assign) unsigned int sent_loss;
@end

/**
 * @brief 音频统计信息
 */
@interface AliRtcRemoteAudioStats : NSObject

@property (nonatomic, copy) NSString * _Nonnull userId;   /*  远端用户userID */
@property (nonatomic, assign) AliRtcAudioTrack track;     /*  音频流track类型 */
/*! 音频流采样率 */
@property (nonatomic, assign) unsigned int sample_rate;
/*! 音频流声道数 */
@property (nonatomic, assign) unsigned int channels;
@property (nonatomic, assign) unsigned int quality;           /*  远端用户发送的音频流质量 */
@property (nonatomic, assign) unsigned int audio_loss_rate;   /*  回调周期内的音频丢帧率 */
@property (nonatomic, assign) unsigned int rcvd_bitrate;      /*  接收流的瞬时码率（Kbps） */
@property (nonatomic, assign) unsigned int total_frozen_times;/*  deprecated 废弃！远端用户加入频道后音频卡顿的累计时长 (ms)。 */
@property (nonatomic, assign) unsigned int audio_total_frozen_time;
/*! 远端用户加入频道后音频播放卡顿率 单位% 计算方法 音频播放卡顿率=音频播放的累计卡顿时长/音频播放的总时长 */
@property (nonatomic, assign) unsigned int audio_total_frozen_rate;
@property (nonatomic, assign) unsigned int network_transport_delay; /*  发送端到接收端的网络延时（ms) */
@property (nonatomic, assign) unsigned int jitter_buffer_delay; /*  接受端到网络抖动缓存的网络延时（ms) */

@end

/**
 * @brief 设备信息
 */
@interface AliRtcDeviceInfo : NSObject

@property (nonatomic, copy) NSString * _Nullable deviceName;   /*  设备名称 */
@property (nonatomic, copy) NSString * _Nullable deviceID;     /*  设备ID */
@property (nonatomic, assign) AliRtcDeviceTransportType deviceTransportType; /*  设备传输类型 */

@end


/**
 * @brief 入会鉴权参数
 */
@interface AliRtcAuthInfo : NSObject

@property (nonatomic, retain) NSString * _Nonnull channelId;
@property (nonatomic, retain) NSString * _Nonnull userId;
@property (nonatomic, retain) NSString * _Nonnull appId;
@property (nonatomic, retain) NSString * _Nonnull nonce;
@property (nonatomic, retain) NSString * _Nonnull token;
@property (nonatomic, retain) NSString * _Nullable session;
@property (nonatomic, retain) NSString * _Nullable role;
@property (nonatomic, retain) NSArray <NSString *> * _Nullable gslb;
@property (nonatomic, retain) NSArray <NSString *> * _Nullable agent;
@property (nonatomic, assign) long long timestamp;

@end


/**
 * @brief 入会参数
 */
@interface AliRtcChannelParam : NSObject
/*! 入会频道，必须和产生token时一样；可以不传，此时会默认使用产生token的channelId */
@property (nonatomic, copy) NSString * _Nullable channelId;
/*! 入会的userid，必须和产生token时一样；可以不传，此时会默认使用产生token的userId */
@property (nonatomic, copy) NSString * _Nullable userId;
/*! 任意用于显示的用户名称，不是User ID；可以不传,标识没有userName */
@property (nonatomic, copy) NSString * _Nullable userName;
/*! 功能profile，如在 AI agent 通话场景下有其他功能需求，可以直接选择porfile，不需要挨个打开功能  */
@property (nonatomic) AliRtcCapabilityProfile capabilityProfile;

@end

/**
 * @brief 加入AI房间的参数
 */
@interface AliRtcAIAgentParam : NSObject
/* ai agent id */
@property (nonatomic, copy) NSString * _Nullable agentId;
/* ai agent的区域 */
@property (nonatomic, copy) NSString * _Nullable region;
/* 启动ai agent的action */
@property (nonatomic, copy) NSString * _Nullable action;
/* 启动ai agent的参数 */
@property (nonatomic, copy) NSString * _Nullable params;

@end

/**
 * @brief 显示视图配置
*/
@interface AliVideoCanvas : NSObject
/** 显示视图 */
@property (nonatomic, strong) NSView * _Nonnull view;
/** 渲染模式，默认值为 {@link AliRtcRenderModeAuto} */
@property (nonatomic) AliRtcRenderMode renderMode;
/** 镜像模式，默认值为 {@link AliRtcRenderMirrorModeAllDisabled} */
@property (nonatomic) AliRtcRenderMirrorMode mirrorMode;
/** 背景颜色，格式为RGB的Hex */
@property (nonatomic) int backgroundColor;
/** 旋转角度，默认值为 {@link AliRtcRotationMode_0} */
@property (nonatomic, assign) AliRtcRotationMode rotation;

@end

/**
 * @brief 水印配置
 */
@interface AliRtcWatermarkConfig : NSObject
/** 预览水印是否可见  */
@property (nonatomic, assign) BOOL visibleInPreview;
/** 竖屏水印坐标信息  */
@property (nonatomic, assign) NSRect positionInPortraitMode;
/** 横屏水印坐标信息  */
@property (nonatomic, assign) NSRect positionInLandscapeMode;
/** 水印透明度  */
@property (nonatomic, assign) float alpha;
/** 归一化  */
@property (nonatomic, assign) BOOL normalized;

@end


/**
 * @brief 视频裸数据
 */
@interface AliRtcVideoDataSample : NSObject

@property (nonatomic, assign) AliRtcVideoFormat format;
@property (nonatomic, assign) AliRtcBufferType type;
@property (nonatomic, assign) CVPixelBufferRef _Nullable pixelBuffer;
@property (nonatomic, assign) uint8_t* _Nullable dataPtr;
@property (nonatomic, assign) uint8_t* _Nullable dataYPtr;
@property (nonatomic, assign) uint8_t* _Nullable dataUPtr;
@property (nonatomic, assign) uint8_t* _Nullable dataVPtr;
@property (nonatomic, assign) long dataLength;
@property (nonatomic, assign) int strideY;
@property (nonatomic, assign) int strideU;
@property (nonatomic, assign) int strideV;
@property (nonatomic, assign) int stride;
@property (nonatomic, assign) int height;
@property (nonatomic, assign) int width;
@property (nonatomic, assign) int rotation;
@property (nonatomic, assign) long long timeStamp;
@property (nonatomic, assign) int encodeCostMs;
@end

/**
 * @brief 音频文件信息
 */
@interface AliRtcAudioFileInfo : NSObject
/** 音频文件路径 */
@property (nonatomic, copy) NSString* _Nonnull filePath;
/** 音频文件时长，单位：ms */
@property (nonatomic, assign) NSInteger durationMs;

@end

/**
 * @brief 音频伴奏播放配置
 */
@interface AliRtcAudioAccompanyConfig : NSObject
/** 是否只本地播放，默认值：NO */
@property (nonatomic, assign) BOOL onlyLocalPlay;
/**
 * @deprecated
 * 是否替换掉MIC，默认值：NO
 * 使用 MuteLocalMic/SetRecordingVolume 替代
 */
@property (nonatomic, assign) BOOL replaceMic;
/** 循环次数，可以设置-1(无限循环)或者>0的正整数次，其他值无效，默认值：-1 */
@property (nonatomic, assign) int loopCycles;
/** 起播位置，单位：ms，默认值：0 */
@property (nonatomic, assign) NSInteger startPosMs;
/** 推流音量，取值范围[0-100]，默认值：50 */
@property (nonatomic, assign) int publishVolume;
/** 播放音量，取值范围[0-100]，默认值：50 */
@property (nonatomic, assign) int playoutVolume;

@end

/**
 * @brief 音频音效播放配置
 */
@interface AliRtcAudioEffectConfig : NSObject
/** 是否推流，默认值：false */
@property (nonatomic, assign) BOOL needPublish;
/** 循环次数，可以设置-1(无限循环)或者>0的正整数次，其他值无效，默认值：-1 */
@property (nonatomic, assign) int loopCycles;
/** 起播位置，单位：ms，默认值：0 */
@property (nonatomic, assign) NSInteger startPosMs;
/** 推流音量，取值范围[0-100]，默认值：50 */
@property (nonatomic, assign) int publishVolume;
/** 播放音量，取值范围[0-100]，默认值：50 */
@property (nonatomic, assign) int playoutVolume;

@end

/**
 * @brief 音频数据采样
 */
@interface AliRtcAudioFrame : NSObject

/** 音频数据指针 */
@property (nonatomic, assign) void* _Nullable dataPtr;
/** 采样点数 */
@property (nonatomic, assign) int numOfSamples;
/** 每个采样点字节数 */
@property (nonatomic, assign) int bytesPerSample;
/** 声道数 */
@property (nonatomic, assign) int numOfChannels;
/** 每秒采样点数 */
@property (nonatomic, assign) int samplesPerSec;

@end

/**
 * @brief 摄像头采集偏好
*/
@interface AliRtcCameraCapturerConfiguration : NSObject

@property (nonatomic) AliRtcCaptureOutputPreference preference;
@property (nonatomic) int fps ;
/** 指定视频采集的特定分辨率 */
@property (nonatomic) AliRtcCameraCaptureProfile cameraCaptureProfile;
/** 不根据纵横比设置翻转采集视频帧设置, -1：默认，0：不生效，1：生效 */
@property (nonatomic) int disableVideoCaptureReverse;
/** 是否回调原始的videoframe数据, -1：默认，0：关闭，1：开启 */
@property (nonatomic) int captureObserverOriginal;
/** 回调textureid, -1：默认，0：关闭，1：开启 */
@property (nonatomic) int nativeBufferObserver;
/** 视频采集callback使用cvPixelBuffer回调, -1：默认，0：关闭，1：开启 */
@property (nonatomic) int captureCallbackCvpixelbufferToRaw;

@end;

/**
 * @brief 相机流视频编码属性设置
*/
@interface AliRtcVideoEncoderConfiguration : NSObject

/** 视频分辨率，默认值640x480，最大值1920x1080
*/
@property (nonatomic, assign) CGSize dimensions;

/** 视频帧率，默认值15, 最大值30
*/
@property (nonatomic, assign) NSInteger frameRate;

/** 视频编码码率(Kbps)
- 默认值 512
- 设置为0，表示由SDK内部根据视频分辨率和码率计算合适的编码码率
- 码率设置根据分辨率和帧率有对应的合理范围，该值设置在合理范围内有效，否则SDK会自动调节码率到有效值
 
@note
以下码表列举常见的分辨率、帧率对应的编码码率设置的区间

 | 分辨率                  | 帧率(fps)     | 最小码率 (Kbps)                    | 推荐码率(Kbps)             |最大码率(Kbps)
 |--------------------- |--------------|---------------------------------|----------------------------|------------
 | 120 * 120              | 5                 | 10                                         | 25                                    | 75
 | 120 * 120              | 10               | 17                                         | 50                                    | 150
 | 120 * 120              | 15               | 25                                         | 70                                    | 210
 | 120 * 120              | 20               | 34                                         | 90                                    | 270
 | 120 * 120              | 30               | 50                                         | 115                                  | 345
 | 160 * 120              | 5                 | 10                                         | 30                                    | 90
 | 160 * 120              | 10               | 20                                         | 55                                    | 165
 | 160 * 120              | 15               | 30                                         | 80                                    | 240
 | 160 * 120              | 20               | 40                                         | 100                                  | 300
 | 160 * 120              | 30               | 60                                         | 130                                  | 390
 | 180 * 180              | 5                 | 10                                         | 50                                    | 150
 | 180 * 180              | 10               | 17                                         | 70                                    | 210
 | 180 * 180              | 15               | 26                                         | 100                                  | 300
 | 180 * 180              | 20               | 34                                         | 130                                  | 390
 | 180 * 180              | 30               | 51                                         | 180                                  | 540
 | 240 * 180              | 5                 | 15                                         | 60                                    | 180
 | 240 * 180              | 10               | 30                                         | 90                                    | 270
 | 240 * 180              | 15               | 45                                         | 130                                  | 390
 | 240 * 180              | 20               | 60                                         | 165                                  | 495
 | 240 * 180              | 30               | 90                                         | 230                                  | 690
 | 320 * 180              | 5                 | 15                                         | 65                                    | 195
 | 320 * 180              | 10               | 30                                         | 110                                  | 330
 | 320 * 180              | 15               | 45                                         | 170                                  | 510
 | 320 * 180              | 20               | 60                                         | 220                                  | 660
 | 320 * 180              | 30               | 90                                         | 300                                  | 900
 | 240 * 240              | 5                 | 15                                         | 70                                    | 140
 | 240 * 240              | 10               | 30                                         | 100                                  | 200
 | 240 * 240              | 15               | 45                                         | 150                                  | 300
 | 240 * 240              | 20               | 60                                         | 200                                  | 400
 | 240 * 240              | 30               | 90                                         | 256                                  | 512
 | 320 * 240              | 5                 | 20                                         | 100                                  | 200
 | 320 * 240              | 10               | 40                                         | 170                                  | 340
 | 320 * 240              | 15               | 60                                         | 256                                  | 512
 | 320 * 240              | 20               | 80                                         | 320                                  | 640
 | 320 * 240              | 30               | 120                                       | 400                                  | 800
 | 424 * 240              | 5                 | 26                                         | 100                                  | 200
 | 424 * 240              | 10               | 53                                         | 170                                  | 340
 | 424 * 240              | 15               | 79                                         | 260                                  | 520
 | 424 * 240              | 20               | 105                                       | 340                                  | 680
 | 424 * 240              | 30               | 158                                       | 430                                  | 860
 | 360 * 360              | 5                 | 30                                         | 120                                  | 240
 | 360 * 360              | 10               | 60                                         | 180                                  | 360
 | 360 * 360              | 15               | 90                                         | 260                                  | 520
 | 360 * 360              | 20               | 120                                       | 330                                  | 660
 | 360 * 360              | 30               | 180                                       | 400                                  | 800
 | 480 * 360              | 5                 | 40                                         | 150                                  | 300
 | 480 * 360              | 10               | 80                                         | 240                                  | 480
 | 480 * 360              | 15               | 120                                       | 350                                  | 700
 | 480 * 360              | 20               | 160                                       | 430                                  | 860
 | 480 * 360              | 30               | 240                                       | 512                                  | 1024
 | 640 * 360              | 5                 | 83                                         | 200                                  | 400
 | 640 * 360              | 10               | 165                                       | 340                                  | 680
 | 640 * 360              | 15               | 248                                       | 512                                  | 1024
 | 640 * 360              | 20               | 330                                       | 600                                  | 1200
 | 640 * 360              | 30               | 495                                       | 700                                  | 1400
 | 480 * 480              | 5                 | 83                                         | 170                                  | 340
 | 480 * 480              | 10               | 165                                       | 260                                  | 520
 | 480 * 480              | 15               | 248                                       | 400                                  | 800
 | 480 * 480              | 20               | 330                                       | 470                                  | 940
 | 480 * 480              | 30               | 495                                       | 600                                  | 1200
 | 640 * 480              | 5                 | 110                                       | 200                                  | 400
 | 640 * 480              | 10               | 220                                       | 350                                  | 700
 | 640 * 480              | 15               | 330                                       | 512                                  | 1024
 | 640 * 480              | 20               | 440                                       | 600                                  | 1200
 | 640 * 480              | 30               | 660                                       | 700                                  | 1400
 | 840 * 480              | 5                 | 180                                       | 256                                  | 512
 | 840 * 480              | 10               | 360                                       | 512                                  | 1024
 | 840 * 480              | 15               | 540                                       | 610                                  | 1220
 | 840 * 480              | 20               | 720                                       | 800                                  | 1600
 | 840 * 480              | 30               | 1080                                     | 930                                  | 1860
 | 960 * 720              | 5                 | 250                                       | 250                                  | 600
 | 960 * 720              | 10               | 500                                       | 500                                  | 750
 | 960 * 720              | 15               | 750                                       | 750                                  | 1125
 | 960 * 720              | 20               | 1000                                     | 1000                                | 1500
 | 960 * 720              | 30               | 1500                                     | 1500                                | 2250
 | 1280 * 720            | 5                 | 400                                       | 400                                  | 600
 | 1280 * 720            | 10               | 800                                       | 800                                  | 1200
 | 1280 * 720            | 15               | 1200                                     | 1200                                | 1800
 | 1280 * 720            | 20               | 1600                                     | 1600                                | 2400
 | 1280 * 720            | 30               | 2400                                     | 2400                                | 3600
 | 1920 * 1080          | 5                 | 500                                       | 500                                  | 750
 | 1920 * 1080          | 10               | 1000                                     | 1000                                | 1500
 | 1920 * 1080          | 15               | 1500                                     | 1500                                | 2250
 | 1920 * 1080          | 20               | 2000                                     | 2000                                | 3000
 | 1920 * 1080          | 30               | 3000                                     | 3000                                | 4500
 | 2560 * 1440          | 5                 | 800                                       | 800                                  | 1200
 | 2560 * 1440          | 10               | 1600                                     | 1600                                | 2400
 | 2560 * 1440          | 15               | 2400                                     | 2400                                | 3600
 | 2560 * 1440          | 20               | 3200                                     | 3200                                | 4800
 | 2560 * 1440          | 30               | 4800                                     | 4800                                | 7200
 | 3840 * 2160          | 5                 | 1000                                     | 1000                                | 1500
 | 3840 * 2160          | 10               | 2000                                     | 2000                                | 3000
 | 3840 * 2160          | 15               | 3000                                     | 3000                                | 4500
 | 3840 * 2160          | 20               | 4000                                     | 4000                                | 6000
 | 3840 * 2160          | 30               | 6000                                     | 6000                                | 9000
*/
@property (nonatomic, assign) NSInteger bitrate;
/** 最小视频编码码率(Kbps)
 * 默认值 0
 * 设置为0，表示由SDK内部根据视频分辨率和码率计算合适的编码码率
 */
@property (nonatomic, assign) NSInteger min_bitrate;

/** 关键帧间隔，单位毫秒。默认值0，表示SDK内部控制关键帧间隔。
 */
@property (nonatomic, assign) NSInteger keyFrameInterval;
/** 是否强制编码器严格按照设置的关键帧间隔产生关键帧。默认值false。
 * false表示编码器会响应他人入会等关键帧请求，关键帧间隔和设置的值不严格匹配。
 * true表示编码器不响应其他关键帧请求，严格按照设置的值产生关键帧。可能会造成订阅者首帧变慢。
 */
@property (nonatomic, assign) bool forceStrictKeyFrameInterval;

/** 推流镜像，默认AliRtcVideoEncoderMirrorModeDisabled，详见 {@link AliRtcVideoEncoderMirrorMode}
*/
@property (nonatomic, assign) AliRtcVideoEncoderMirrorMode mirrorMode;

/** 视频输出方向，默认AliRtcVideoEncoderOrientationModeAdaptive，详见 {@link AliRtcVideoEncoderOrientationMode}
*/
@property (nonatomic, assign) AliRtcVideoEncoderOrientationMode orientationMode;

/** 推流旋转，默认AliRtcRotationMode_0，详见 {@link AliRtcRotationMode}
*/
@property (nonatomic, assign) AliRtcRotationMode rotation;

/*! 编码类型 默认-1，也就是软件编码 详见 {@link AliRtcVideoCodecType}
 */
@property (nonatomic, assign) AliRtcVideoCodecType codecType;

/*! 具体的编码类型，默认-1，是h264详见 {@link AliRtcVideoEncodeCodecType}
 */
@property (nonatomic, assign) AliRtcVideoEncodeCodecType encoderType;

/*! SEI发送之前强制I帧，默认是1
 */
@property (nonatomic,assign) NSInteger seiForceFrontIFrame;

/*! 开启动态编码，同时创建硬件编码和软件编码，在硬件编码异常会切换到软件编码，如果使用默认值建议设置为-1
 */
@property (nonatomic,assign) NSInteger enableDynamicEncode;

/*! 当QoS探测出带宽不够，支持分辨率降级
    默认关闭 0，设置为1则关掉分辨率降级能力，如果使用默认值建议设置为-1
 */
@property (nonatomic,assign) NSInteger disableDipenseResolutionChange;

/*! 是否允许QoS根据实际的带宽降低编码器码流
     默认开启，设置为0，关闭码流降级功能，如果使用默认值建议设置为-1
 */
@property (nonatomic,assign) NSInteger enableDowngrade;

/*! 是否启用h264B帧能力
     默认关闭，设置为1后开启，开启后要求解码器也必须打开B帧支持，如果使用默认值建议设置为-1
 */
@property (nonatomic,assign) NSInteger enableH264BFrame;

/*! 是否启用hevc B帧能力
     默认关闭，设置为1后开启，开启后要求解码器也必须打开B帧支持，如果使用默认值建议设置为-1
 */
@property (nonatomic,assign) NSInteger enableHevcBFrame;

@end

/**
 * @brief 屏幕流编码属性设置
*/
@interface AliRtcScreenShareEncoderConfiguration : NSObject

/** 视频分辨率，默认值0x0，最大值3840x2160
 @note
 默认值表示推流分辨率等于屏幕采集的分辨率
*/
@property (nonatomic, assign) CGSize dimensions;

/** 视频帧率，默认值5, 最大值30
*/
@property (nonatomic, assign) NSInteger frameRate;

/** 视频编码码率(Kbps)
- 默认值 512
- 设置为0，表示由SDK内部根据视频分辨率和码率计算合适的编码码率
- 码率设置根据分辨率和帧率有对应的合理范围，该值设置在合理范围内有效，否则SDK会自动调节码率到有效值
 
@note
以下码表列举常见的分辨率、帧率对应的编码码率设置的区间

 | 分辨率                  | 帧率(fps)     | 最小码率 (Kbps)                    | 推荐码率(Kbps)             |最大码率(Kbps)
 |--------------------- |--------------|---------------------------------|----------------------------|------------
 | 120 * 120              | 5                 | 10                                         | 25                                    | 75
 | 120 * 120              | 10               | 17                                         | 50                                    | 150
 | 120 * 120              | 15               | 25                                         | 70                                    | 210
 | 120 * 120              | 20               | 34                                         | 90                                    | 270
 | 120 * 120              | 30               | 50                                         | 115                                  | 345
 | 160 * 120              | 5                 | 10                                         | 30                                    | 90
 | 160 * 120              | 10               | 20                                         | 55                                    | 165
 | 160 * 120              | 15               | 30                                         | 80                                    | 240
 | 160 * 120              | 20               | 40                                         | 100                                  | 300
 | 160 * 120              | 30               | 60                                         | 130                                  | 390
 | 180 * 180              | 5                 | 10                                         | 50                                    | 150
 | 180 * 180              | 10               | 17                                         | 70                                    | 210
 | 180 * 180              | 15               | 26                                         | 100                                  | 300
 | 180 * 180              | 20               | 34                                         | 130                                  | 390
 | 180 * 180              | 30               | 51                                         | 180                                  | 540
 | 240 * 180              | 5                 | 15                                         | 60                                    | 180
 | 240 * 180              | 10               | 30                                         | 90                                    | 270
 | 240 * 180              | 15               | 45                                         | 130                                  | 390
 | 240 * 180              | 20               | 60                                         | 165                                  | 495
 | 240 * 180              | 30               | 90                                         | 230                                  | 690
 | 320 * 180              | 5                 | 15                                         | 65                                    | 195
 | 320 * 180              | 10               | 30                                         | 110                                  | 330
 | 320 * 180              | 15               | 45                                         | 170                                  | 510
 | 320 * 180              | 20               | 60                                         | 220                                  | 660
 | 320 * 180              | 30               | 90                                         | 300                                  | 900
 | 240 * 240              | 5                 | 15                                         | 70                                    | 140
 | 240 * 240              | 10               | 30                                         | 100                                  | 200
 | 240 * 240              | 15               | 45                                         | 150                                  | 300
 | 240 * 240              | 20               | 60                                         | 200                                  | 400
 | 240 * 240              | 30               | 90                                         | 256                                  | 512
 | 320 * 240              | 5                 | 20                                         | 100                                  | 200
 | 320 * 240              | 10               | 40                                         | 170                                  | 340
 | 320 * 240              | 15               | 60                                         | 256                                  | 512
 | 320 * 240              | 20               | 80                                         | 320                                  | 640
 | 320 * 240              | 30               | 120                                       | 400                                  | 800
 | 424 * 240              | 5                 | 26                                         | 100                                  | 200
 | 424 * 240              | 10               | 53                                         | 170                                  | 340
 | 424 * 240              | 15               | 79                                         | 260                                  | 520
 | 424 * 240              | 20               | 105                                       | 340                                  | 680
 | 424 * 240              | 30               | 158                                       | 430                                  | 860
 | 360 * 360              | 5                 | 30                                         | 120                                  | 240
 | 360 * 360              | 10               | 60                                         | 180                                  | 360
 | 360 * 360              | 15               | 90                                         | 260                                  | 520
 | 360 * 360              | 20               | 120                                       | 330                                  | 660
 | 360 * 360              | 30               | 180                                       | 400                                  | 800
 | 480 * 360              | 5                 | 40                                         | 150                                  | 300
 | 480 * 360              | 10               | 80                                         | 240                                  | 480
 | 480 * 360              | 15               | 120                                       | 350                                  | 700
 | 480 * 360              | 20               | 160                                       | 430                                  | 860
 | 480 * 360              | 30               | 240                                       | 512                                  | 1024
 | 640 * 360              | 5                 | 83                                         | 200                                  | 400
 | 640 * 360              | 10               | 165                                       | 340                                  | 680
 | 640 * 360              | 15               | 248                                       | 512                                  | 1024
 | 640 * 360              | 20               | 330                                       | 600                                  | 1200
 | 640 * 360              | 30               | 495                                       | 700                                  | 1400
 | 480 * 480              | 5                 | 83                                         | 170                                  | 340
 | 480 * 480              | 10               | 165                                       | 260                                  | 520
 | 480 * 480              | 15               | 248                                       | 400                                  | 800
 | 480 * 480              | 20               | 330                                       | 470                                  | 940
 | 480 * 480              | 30               | 495                                       | 600                                  | 1200
 | 640 * 480              | 5                 | 110                                       | 200                                  | 400
 | 640 * 480              | 10               | 220                                       | 350                                  | 700
 | 640 * 480              | 15               | 330                                       | 512                                  | 1024
 | 640 * 480              | 20               | 440                                       | 600                                  | 1200
 | 640 * 480              | 30               | 660                                       | 700                                  | 1400
 | 840 * 480              | 5                 | 180                                       | 256                                  | 512
 | 840 * 480              | 10               | 360                                       | 512                                  | 1024
 | 840 * 480              | 15               | 540                                       | 610                                  | 1220
 | 840 * 480              | 20               | 720                                       | 800                                  | 1600
 | 840 * 480              | 30               | 1080                                     | 930                                  | 1860
 | 960 * 720              | 5                 | 250                                       | 250                                  | 600
 | 960 * 720              | 10               | 500                                       | 500                                  | 750
 | 960 * 720              | 15               | 750                                       | 750                                  | 1125
 | 960 * 720              | 20               | 1000                                     | 1000                                | 1500
 | 960 * 720              | 30               | 1500                                     | 1500                                | 2250
 | 1280 * 720            | 5                 | 400                                       | 400                                  | 600
 | 1280 * 720            | 10               | 800                                       | 800                                  | 1200
 | 1280 * 720            | 15               | 1200                                     | 1200                                | 1800
 | 1280 * 720            | 20               | 1600                                     | 1600                                | 2400
 | 1280 * 720            | 30               | 2400                                     | 2400                                | 3600
 | 1920 * 1080          | 5                 | 500                                       | 500                                  | 750
 | 1920 * 1080          | 10               | 1000                                     | 1000                                | 1500
 | 1920 * 1080          | 15               | 1500                                     | 1500                                | 2250
 | 1920 * 1080          | 20               | 2000                                     | 2000                                | 3000
 | 1920 * 1080          | 30               | 3000                                     | 3000                                | 4500
 | 2560 * 1440          | 5                 | 800                                       | 800                                  | 1200
 | 2560 * 1440          | 10               | 1600                                     | 1600                                | 2400
 | 2560 * 1440          | 15               | 2400                                     | 2400                                | 3600
 | 2560 * 1440          | 20               | 3200                                     | 3200                                | 4800
 | 2560 * 1440          | 30               | 4800                                     | 4800                                | 7200
 | 3840 * 2160          | 5                 | 1000                                     | 1000                                | 1500
 | 3840 * 2160          | 10               | 2000                                     | 2000                                | 3000
 | 3840 * 2160          | 15               | 3000                                     | 3000                                | 4500
 | 3840 * 2160          | 20               | 4000                                     | 4000                                | 6000
 | 3840 * 2160          | 30               | 6000                                     | 6000                                | 9000
*/
@property (nonatomic, assign) NSInteger bitrate;

/** 关键帧间隔，单位毫秒。默认值0，表示SDK内部控制关键帧间隔。
 */
@property (nonatomic, assign) NSInteger keyFrameInterval;
/** 是否强制编码器严格按照设置的关键帧间隔产生关键帧。默认值false。
 * false表示编码器会响应他人入会等关键帧请求，关键帧间隔和设置的值不严格匹配。
 * true表示编码器不响应其他关键帧请求，严格按照设置的值产生关键帧。可能会造成订阅者首帧变慢。
 */
@property (nonatomic, assign) bool forceStrictKeyFrameInterval;

/** 推流旋转，默认AliRtcRotationMode_0，详见 {@link AliRtcRotationMode}
*/
@property (nonatomic, assign) AliRtcRotationMode rotation;

@end

/**
 * @brief 相机流视频编码属性设置
*/
@interface AliRtcVideoDecoderConfiguration : NSObject

/*! 解码器类型
*/
@property (nonatomic, assign) AliRtcVideoCodecType codecType;

/*! 解码器开启B帧支持，当编码器开启B帧支持之后，解码器必须打开这个选项
        默认值是-1，使用默认配置，不开启B帧支持
        1打开设置，0关闭设置
*/
@property (nonatomic, assign) NSInteger enableDecoderBframe;

/*! 切后台硬件解码器切换到软件解码器，
      默认值是-1，使用默认配置
      1 打开设置，0 关闭该设置
 */
@property (nonatomic, assign) NSInteger backgroundHardwareToSoftware;


@end

/**
 * @brief 屏幕分享区域
 */
@interface AliRtcScreenShareRegion : NSObject

@property (nonatomic, assign) float originX;
@property (nonatomic, assign) float originY;
@property (nonatomic, assign) float width;
@property (nonatomic, assign) float height;

@end


/**
 * @brief 屏幕分享配置
 */
@interface AliRtcScreenShareConfig : NSObject

@property (nonatomic, assign) bool isShareByRegion;
@property (nonatomic, strong) AliRtcScreenShareRegion * _Nonnull shareRegion;
@property (nonatomic, assign) bool isPushStream;

@end

/**
 * @brief 屏幕分享源信息
 */
@interface AliRtcScreenSourceInfo : NSObject

@property (nonatomic, copy) NSString * _Nonnull sourceId;
@property (nonatomic, copy) NSString * _Nonnull sourceName;

@end

/**
 * @brief 屏幕分享配置信息
 */
@interface AliRtcScreenShareInfo : NSObject

@property (nonatomic, assign) AliRtcScreenShareType sourceType;
@property (nonatomic, copy) NSString * _Nonnull sourceId;
@property (nonatomic, strong) AliRtcScreenShareConfig * _Nonnull config;

@end

/**
 * @brief 跨频道转推配置
 */
@interface AliRtcChannelRelayConfiguration : NSObject

@property (nonatomic, copy, readonly) NSDictionary<NSString*,AliRtcAuthInfo*> * _Nonnull destChannelInfos;

- (void)addDestChannelInfoWithChannelId:(NSString *_Nullable)channeId
                               authInfo:(AliRtcAuthInfo *_Nullable)authInfo;

- (void)removeDestChannelInfo:(NSString *_Nullable)channeId;

- (void)removeAllDestChannelInfo;

@end

typedef NS_ENUM(NSUInteger, AliRtcLiveTranscodingDisplayType) {
    AliRtcLiveTranscodingDisplayType_NOT_DISPLAY = 0,
    AliRtcLiveTranscodingDisplayType_ALWAYS = 1,
    AliRtcLiveTranscodingDisplayType_WHEN_NO_VIDEO = 2
};

/**
* @brief 旁路直播图片
*/
@interface AliRtcLiveTranscodingImage : NSObject
@property (nonatomic, copy) NSString *_Nullable url;
@property (nonatomic, assign) float alpha;
@property (nonatomic, assign) AliRtcLiveTranscodingDisplayType display;
@property (nonatomic, assign) int x;
@property (nonatomic, assign) int y;
@property (nonatomic, assign) int width;
@property (nonatomic, assign) int height;
@property (nonatomic, assign) int zOrder;
@end

typedef NS_ENUM(NSUInteger, AliRtcLiveTranscodingFontType) {
  NOTO_SERIF_CJKSC_REGULAR = 0,
  ALIBABA_PUHUITI_REGULAR = 1,
  ALIBABA_PUHUITI_BOLD = 2,
  ALIBABA_PUHUITI_Heavy = 3,
  ALIBABA_PUHUITI_LIGHT = 4,
  ALIBABA_PUHUITI_MEDIUM = 5
};

/**
* @brief 旁路直播文字格式
*/
@interface AliRtcLiveTranscodingText : NSObject
@property (nonatomic, copy) NSString *_Nullable text;
@property (nonatomic, assign) int x;
@property (nonatomic, assign) int y;
@property (nonatomic, assign) int zOrder;
@property (nonatomic, assign) AliRtcLiveTranscodingFontType fontType;
@property (nonatomic, assign) int fontSize;
@property (nonatomic, assign) int fontColor;//0xRRGGBB
@end

/**
* @brief 旁路直播输入类型
*/
typedef NS_ENUM(NSUInteger, AliRtcLiveTranscodingSegmentType) {
    /** 无人像分割 */
    AliRtcLiveTranscodingNoBody = 0,
    /** 人像分割 */
    AliRtcLiveTranscodingBody = 1
};

/**
* @brief 旁路直播转推流模式
*/
typedef NS_ENUM(NSUInteger, AliRtcLiveTranscodingStreamType) {
    /** 原始流 */
    AliRtcLiveTranscodingOrigin = 0,
    /** 音频 */
    AliRtcLiveTranscodingAudio = 1,
    /** 视频 */
    AliRtcLiveTranscodingVideo = 2
};

/**
* @brief 旁路直播输入类型
*/
typedef NS_ENUM(NSUInteger, AliRtcLiveTranscodingSourceType) {
    /** 相机流 */
    AliRtcLiveTranscodingCamera = 0,
    /** 屏幕流 */
    AliRtcLiveTranscodingShareScreen = 1
};

/**
 * @brief 旁路直播用户自定义流信息
*/
@interface AliRtcLiveTranscodingUser : NSObject
@property (nonatomic, assign) int x;
@property (nonatomic, assign) int y;
@property (nonatomic, assign) int width;
@property (nonatomic, assign) int height;
@property (nonatomic, assign) int zOrder;
@property (nonatomic, copy) NSString *_Nonnull userId;
@property (nonatomic, assign) AliRtcLiveTranscodingStreamType streamType;
@property (nonatomic, assign) AliRtcLiveTranscodingSourceType sourceType;
@property (nonatomic, assign) AliRtcLiveTranscodingSegmentType segmentType;
@property (nonatomic, copy) NSArray<AliRtcLiveTranscodingImage *> *_Nullable images;
@property (nonatomic, copy) NSArray<AliRtcLiveTranscodingText *> *_Nullable texts;
@end

/** 旁路直播 **/
typedef NS_ENUM(NSUInteger, AliRtcLiveTranscodingState) {
    AliRtcLiveTranscodingState_IDLE = 0,
    AliRtcLiveTranscodingState_CONNNECT = 1,
    AliRtcLiveTranscodingState_RUNNING = 2,
    AliRtcLiveTranscodingState_RECOVERING = 3,
    AliRtcLiveTranscodingState_FAILURE = 4,
    AliRtcLiveTranscodingState_END = 5
};

/**
* @brief 旁路模式
*/
typedef NS_ENUM(NSUInteger, AliRtcLiveTranscodingMixMode) {
    /** 单路模式 */
    AliRtcLiveTranscodingSINGLE = 0,
    /** 混流模式 */
    AliRtcLiveTranscodingMIX = 1
};

/**
* @brief 旁路直播媒体处理模式
*/
typedef NS_ENUM(NSUInteger, AliRtcLiveTranscodingMediaProcessMode) {
    /** 通用模式 */
    AliRtcLiveTranscodingNormal = 0,
    /** 虚拟背景模式 */
    AliRtcLiveTranscodingVirtualBackground = 1
};

/**
* @brief 旁路直播裁剪模式
*/
typedef NS_ENUM(NSUInteger, AliRtcLiveTranscodingCropMode) {
    /** 剪裁 */
    AliRtcLiveTranscodingCrop = 1,
    /** 填充 */
    AliRtcLiveTranscodingFill = 2
};

/**
* @brief 旁路直播视频编码器
*/
typedef NS_ENUM(NSUInteger, AliRtcLiveTranscodingVideoCodec) {
    /** H.264 */
    AliRtcLiveTranscodingVideoCodec_H264 = 1,
    /** H.265 */
    AliRtcLiveTranscodingVideoCodec_H265 = 2
};

/**
* @brief 旁路直播时钟格式
*/
@interface AliRtcLiveTranscodingClockWidget : NSObject
@property (nonatomic, assign) int x;
@property (nonatomic, assign) int y;
@property (nonatomic, assign) AliRtcLiveTranscodingFontType fontType;
@property (nonatomic, assign) int fontSize;
@property (nonatomic, assign) int fontColor;  // 0xRRGGBB
@property (nonatomic, assign) int zOrder;
@end

/**
* @brief 旁路直播音频采样
*/
typedef NS_ENUM(NSUInteger, AliRtcLiveTranscodingAudioSampleRate) {
    AliRtcLiveTranscoding_HZ_48000 = 48000,
    AliRtcLiveTranscoding_HZ_44100 = 44100,
    AliRtcLiveTranscoding_HZ_32000 = 32000,
    AliRtcLiveTranscoding_HZ_16000 = 16000,
    AliRtcLiveTranscoding_HZ_8000 = 8000
};

/**
* @brief 旁路直播自定义编码参数
*/
@interface AliRtcLiveTranscodingEncodeParam : NSObject
@property (nonatomic, assign) int videoWidth; //(0-1920]
@property (nonatomic, assign) int videoHeight; //(0-1920]
@property (nonatomic, assign) int videoFramerate; //[1,60]
@property (nonatomic, assign) int videoBitrate; //[1kbps,10000kbps]
@property (nonatomic, assign) int videoGop; //[1,60]
@property (nonatomic, assign) AliRtcLiveTranscodingVideoCodec videoCodec;
@property (nonatomic, assign) AliRtcLiveTranscodingAudioSampleRate audioSamplerate;
@property (nonatomic, assign) int audioBitrate; //[8kbps,500kbps]
@property (nonatomic, assign) int audioChannels; //[1,2]
@end

/**
* @brief 旁路直播计费规格
*/
typedef NS_ENUM(NSUInteger, AliRtcLiveTranscodingTaskProfile) {
    AliRtcLiveTranscoding_Profile_1IN_1080P = 0,
    AliRtcLiveTranscoding_Profile_1IN_720P = 1,
    AliRtcLiveTranscoding_Profile_1IN_360P = 2,
    AliRtcLiveTranscoding_Profile_2IN_1080P = 3,
    AliRtcLiveTranscoding_Profile_2IN_720P = 4,
    AliRtcLiveTranscoding_Profile_2IN_360P = 5,
    AliRtcLiveTranscoding_Profile_4IN_1080P = 6,
    AliRtcLiveTranscoding_Profile_4IN_720P = 7,
    AliRtcLiveTranscoding_Profile_4IN_360P = 8,
    AliRtcLiveTranscoding_Profile_9IN_1080P = 9,
    AliRtcLiveTranscoding_Profile_9IN_720P = 10,
    AliRtcLiveTranscoding_Profile_9IN_360P = 11,
    AliRtcLiveTranscoding_Profile_12IN_1080P = 12,
    AliRtcLiveTranscoding_Profile_12IN_720P = 13,
    AliRtcLiveTranscoding_Profile_12IN_360P = 14,
    AliRtcLiveTranscoding_Profile_16IN_1080P = 15,
    AliRtcLiveTranscoding_Profile_16IN_720P = 16,
    AliRtcLiveTranscoding_Profile_16IN_360P = 17,
    AliRtcLiveTranscoding_Profile_Mixed = 9999 // only audio
};

/**
* @brief 旁路模式单路参数
*/
@interface AliRtcLiveTranscodingSingleParam : NSObject
/** 用户id */
@property (nonatomic, copy) NSString *_Nullable userId;
/** 推流模式 */
@property (nonatomic, assign) AliRtcLiveTranscodingStreamType streamType;
/** 旁路直播输入类型 */
@property (nonatomic, assign) AliRtcLiveTranscodingSourceType sourceType;
@end

/**
* @brief 旁路模式混流参数
*/
@interface AliRtcLiveTranscodingMixParam : NSObject
/** 旁路直播计费规格 */
@property (nonatomic, assign) AliRtcLiveTranscodingTaskProfile taskProfile;
/** 旁路直播自定义编码参数 */
@property (nonatomic, strong) AliRtcLiveTranscodingEncodeParam *_Nullable encodeParam;
/** 旁路直播用户列表 */
@property (nonatomic, strong) NSArray<AliRtcLiveTranscodingUser *> *_Nullable users;
/** 背景色 */
@property (nonatomic, assign) int backgroundColor; //0xRRGGBB
/** 背景图片列表 */
@property (nonatomic, strong) NSArray<AliRtcLiveTranscodingImage *> *_Nullable backgrounds;
/** 水印列表 */
@property (nonatomic, strong) NSArray<AliRtcLiveTranscodingImage *> *_Nullable watermarks;
/** 时钟组件列表 */
@property (nonatomic, strong) NSArray<AliRtcLiveTranscodingClockWidget *> *_Nullable clockWidgets;
/** 剪裁模式 */
@property (nonatomic, assign) AliRtcLiveTranscodingCropMode cropMode;
/** 媒体处理模式 */
@property (nonatomic, assign) AliRtcLiveTranscodingMediaProcessMode mediaProcessMode;
@end

/**
 * @brief 旁路模式参数
*/
@interface AliRtcLiveTranscodingParam : NSObject
/** 旁路模式 */
@property (nonatomic, assign) AliRtcLiveTranscodingMixMode mixMode;
/** 路模式单路参数 */
@property (nonatomic, strong) AliRtcLiveTranscodingSingleParam *_Nullable singleParam;
/** 旁路模式混流参数 */
@property (nonatomic, strong) AliRtcLiveTranscodingMixParam *_Nullable mixParam;
@end

/**
 * @brief 消息通道消息
 * @note 已废弃使用
 */
@interface AliRtcMessage : NSObject

@property (nonatomic, strong) NSString * _Nullable tID;
@property (nonatomic, strong) NSString * _Nullable contentType;
@property (nonatomic, strong) NSString * _Nullable content;
@end

/**
 * @brief 消息通道Response
 * @note 已废弃使用
 */
@interface AliRtcMessageResponse : NSObject

@property (nonatomic, assign) int result;
@property (nonatomic, strong) NSString * _Nullable contentType;
@property (nonatomic, strong) NSString * _Nullable content;
@end

/**
 * @brief Qos反馈外置编码器请求帧类型
 */
typedef NS_ENUM(NSInteger, AliRtcVideoEncodedFrameType) {
    /** 默认无 */
    AliRtcVideoEncodedFrameNULL,
    /** IDR帧 */
    AliRtcVideoEncodedFrameIDR,
    /** LTR帧 */
    AliRtcVideoEncodedFrameLTR,
    /** B帧 */
    AliRtcVideoEncodedFrameB,
};

/**
 * @brief Qos反馈外置编码器参数结构体
 */
@interface AliRtcVideoExternalEncoderParameter : NSObject

@property (nonatomic, assign) NSInteger width;
@property (nonatomic, assign) NSInteger height;
@property (nonatomic, assign) NSInteger frame_rate;
@property (nonatomic, assign) NSInteger bitrate_bps;
@end

/**
 * @brief data消息类型
*/

typedef NS_ENUM(NSInteger, AliRtcDataMsgType) {
    AliRtcDataMsgNone,
    AliRtcDataMsgMusicProgress,
    AliRtcDataMsgCustom,
};


/**
 * @brief data消息定义
 */
@interface AliRtcDataChannelMsg : NSObject
@property (nonatomic, assign) AliRtcDataMsgType type;
@property (nonatomic, assign) long long networkTime;
@property (nonatomic, assign) int progress;
@property (nonatomic, strong) NSData* _Nonnull data;
@end

/**
 * @brief 网络探测的参数配置
 */
@interface AliRtcNetworkQualityProbeConfig : NSObject
/** 是否探测上行，默认值：NO */
@property (nonatomic, assign) BOOL probeUplink;
/** 是否探测下行，默认值：NO  暂不支持 */
@property (nonatomic, assign) BOOL probeDownlink;
/** 探测上行带宽峰值，单位kbps 默认值：10000 */
@property (nonatomic, assign) int upLinkBandWidth;
/** 探测下行带宽峰值，单位kbps 默认值：1000  暂不支持 */
@property (nonatomic, assign) int DownLinkBandWidth;
@end

/**
 * @brief 网络探测的结果
 */
@interface AliRtcNetworkQualityProbeResult : NSObject
/** 探测链路的rtt  单位ms*/
@property (nonatomic, assign) int rtt;
/** 上行的丢包率 最大值100 */
@property (nonatomic, assign) int upLinkLossRate;
/** 探测上行链路的jitter 单位ms  */
@property (nonatomic, assign) int upLinkJitter;
/** 探测上行链路的带宽，单位kbps */
@property (nonatomic, assign) int upLinkBandWidth;
/** 下行的丢包率 最大值100 暂不支持 */
@property (nonatomic, assign) int downLinkLossRate;
/** 探测下行链路的jitter 单位ms  暂不支持 */
@property (nonatomic, assign) int downLinkJitter;
/** 探测下行链路的带宽，单位kbps 暂不支持 */
@property (nonatomic, assign) int downLinkBandWidth;
@end

/**
 * @brief 本地设备类型
 */
typedef NS_ENUM(NSInteger, AliRtcLocalDeviceType) {
    /** 未知设备类型 */
    AliRtcLocalDeviceTypeUnknown = 0,
    /** 麦克风设备 */
    AliRtcLocalDeviceTypeMic = 1,
    /** 扬声器设备 */
    AliRtcLocalDeviceTypeSpeaker = 2,
    /** 音频设备 */
    AliRtcLocalDeviceTypeAudioDevice = 3,
    /** 摄像头设备 */
    AliRtcLocalDeviceTypeCamera = 4,
    /** 显示设备 */
    AliRtcLocalDeviceTypeDisplay = 5,
    /** 视频设备 */
    AliRtcLocalDeviceTypeVideoDevice = 6,
    /** 屏幕/窗口共享设备 */
    AliRtcLocalDeviceTypeScreenShareDevice = 7
};

/**
 * @brief 本地设备异常类型
 */
typedef NS_ENUM(NSInteger, AliRtcLocalDeviceExceptionType) {
    /** 未知异常类型 */
    AliRtcLocalDeviceExceptionTypeUnknown = 0,
    /** 麦克风打开失败 */
    AliRtcLocalDeviceExceptionTypeMicOpenFail = 1,
    /** 麦克风被打断 */
    AliRtcLocalDeviceExceptionTypeMicInterrupt = 2,
    /** 麦克风无权限 */
    AliRtcLocalDeviceExceptionTypeMicAuthFail = 3,
    /** 无可用麦克风 */
    AliRtcLocalDeviceExceptionTypeMicNotAvailable = 4,
    /** 扬声器打开失败 */
    AliRtcLocalDeviceExceptionTypeSpeakerOpenFail = 5,
    /** 扬声器被打断 */
    AliRtcLocalDeviceExceptionTypeSpeakerInterrupt = 6,
    /** 无可用扬声器 */
    AliRtcLocalDeviceExceptionTypeSpeakerNotAvailable = 7,
    /** 音频设备异常 */
    AliRtcLocalDeviceExceptionTypeAudioDeviceException = 8,
    /** 摄像头打开失败 */
    AliRtcLocalDeviceExceptionTypeCameraOpenFail = 9,
    /** 摄像头被打断 */
    AliRtcLocalDeviceExceptionTypeCameraInterrupt = 10,
    /** 摄像头无权限 */
    AliRtcLocalDeviceExceptionTypeCameraAuthFail = 11,
    /** 显示设备异常 */
    AliRtcLocalDeviceExceptionTypeDisplayExecption = 12,
    /** 视频设备异常 */
    AliRtcLocalDeviceExceptionTypeVideoDeviceException = 13,
    /** 屏幕共享被打断 */
    AliRtcLocalDeviceExceptionTypeScreenShareInterrupt = 14,
    /** 屏幕共享异常 */
    AliRtcLocalDeviceExceptionTypeScreenShareException = 15
};

/**
 * @brief 本地音频采集状态回调
 */
typedef NS_ENUM(NSInteger, AliRtcLocalAudioStateType) {
    AliRtcLocalAudioStateTypeStarting = 0,
    AliRtcLocalAudioStateTypeStarted = 1,
    AliRtcLocalAudioStateTypeStopping = 2,
    AliRtcLocalAudioStateTypeStopped = 3,
};

/**
 * @brief 本地视频采集状态回调
 */
typedef NS_ENUM(NSInteger, AliRtcLocalVideoStateType) {
    AliRtcLocalVideoStateTypeStarting = 0,
    AliRtcLocalVideoStateTypeStarted = 1,
    AliRtcLocalVideoStateTypeStopping = 2,
    AliRtcLocalVideoStateTypeStopped = 3,
};


/**
* @brief 音频能力
 */
@interface AliRtcAudioCapability : NSObject
/** true: 离会后采集设备保持开启状态；false: 离会后采集设备关闭 */
@property (nonatomic, assign) BOOL captureKeepAlive;
/** true: 离会后播放设备保持开启状态；false: 离会后播放设备关闭 */
@property (nonatomic, assign) BOOL playoutKeepAlive;
@end

/** @} AliRtcDef_mac */

#pragma mark - 回调

/**
 * @defgroup AliRtcEngineDelegate_mac AliRtcEngineDelegate
 * AliRTC功能的事件回调接口
 * @{
 */
@protocol AliRtcEngineDelegate <NSObject>
@optional

/**
 * @brief 加入频道回调
 * @details 当应用调用 {@link AliRtcEngine::joinChannel:name:onResult:} 方法时，该回调表示成功/失败加入频道，并且返回频道加入的相关信息以及加入频道耗时
 * @param result 加入频道结果
 * - 0：成功
 * - 非0：失败
 *   - {@link AliRtcErrJoinBadAppId} : AppId不存在，请检查入会参数authinfo中appId是否正确
 *   - {@link AliRtcErrJoinInvalidAppId} : AppId已失效，请检查入会参数authinfo中appId是否正确
 *   - {@link AliRtcErrJoinBadChannel} : 频道不存在，请检查入会参数authinfo中channelId是否正确
 *   - {@link AliRtcErrJoinInvalidChannel} : 频道已失效，请检查入会参数authinfo中channelId是否正确
 *   - {@link AliRtcErrJoinBadToken} : token不存在，请检查入会参数authinfo生成算法是否与官网文档一致
 *   - {@link AliRtcErrJoinTimeout} : 加入频道超时，请检查当前网络是否为弱网或限速
 *   - {@link AliRtcErrJoinBadParam} : 参数错误，请检查入会参数authinfo生成是否存在非法字符，或与官网文档是否一致
 *
 * @param channel 加入频道名
 * @param elapsed 加入频道耗时
 * @note 此回调等同于joinChannel接口的block参数，二者择一处理即可
 */
- (void)onJoinChannelResult:(int)result channel:(NSString *_Nonnull)channel elapsed:(int) elapsed;

/**
 * @brief 加入频道回调
 * @details 当应用调用 {@link AliRtcEngine::joinChannel:name:onResultWithUserId:} 方法时，该回调表示成功/失败加入频道，并且返回频道加入的相关信息以及加入频道耗时
 * @param result 加入频道结果
 * - 0：成功
 * - 非0：失败
 *   - {@link AliRtcErrJoinBadAppId} : AppId不存在，请检查入会参数authinfo中appId是否正确
 *   - {@link AliRtcErrJoinInvalidAppId} : AppId已失效，请检查入会参数authinfo中appId是否正确
 *   - {@link AliRtcErrJoinBadChannel} : 频道不存在，请检查入会参数authinfo中channelId是否正确
 *   - {@link AliRtcErrJoinInvalidChannel} : 频道已失效，请检查入会参数authinfo中channelId是否正确
 *   - {@link AliRtcErrJoinBadToken} : token不存在，请检查入会参数authinfo生成算法是否与官网文档一致
 *   - {@link AliRtcErrJoinTimeout} : 加入频道超时，请检查当前网络是否为弱网或限速
 *   - {@link AliRtcErrJoinBadParam} : 参数错误，请检查入会参数authinfo生成是否存在非法字符，或与官网文档是否一致
 *
 * @param channel 加入频道名
 * @param userId   用户ID
 * @param elapsed 加入频道耗时
 * @note 此回调等同于joinChannel接口的block参数，二者择一处理即可
 */

- (void)onJoinChannelResult:(int)result channel:(NSString *_Nonnull)channel userId:(NSString *_Nonnull)userId elapsed:(int) elapsed;

/**
 * @brief 离开频道回调
 * @details 调用 {@link  AliRtcEngine::leaveChannel} 方法后，该回调表示成功/失败离开频道，回调将会返回离会的result和该频道的基本信息
 * @param result 离开频道结果，成功返回0，失败返回错误码
 * @param stats 本次频道内会话的数据统计信息。
 * @note 调用 {@link AliRtcEngine::leaveChannel} 接口后返回，如果 {@link AliRtcEngine::leaveChannel} 后直接调用 {@link AliRtcEngine::destroy} 将不会收到此回调
 */
- (void)onLeaveChannelResult:(int)result stats:(AliRtcStats)stats;

/**
 * @brief 音频推流变更回调
 * @param oldState 之前的推流状态，详见 {@link AliRtcPublishState}
 * @param newState 当前的推流状态，详见 {@link AliRtcPublishState}
 * @param elapseSinceLastState 状态变更时间间隔(毫秒)
 * @param channel 当前频道id
 */
- (void)onAudioPublishStateChanged:(AliRtcPublishState)oldState
                          newState:(AliRtcPublishState)newState elapseSinceLastState:(NSInteger)elapseSinceLastState
                           channel:(NSString *_Nonnull)channel;

/**
 * @brief 音频推流变更回调
 * @param oldState 之前的推流状态，详见 {@link AliRtcPublishState}
 * @param newState 当前的推流状态，详见 {@link AliRtcPublishState}
 * @param elapseSinceLastState 状态变更时间间隔(毫秒)
 * @param channel 当前频道id
 * @param reason 推流状态变化原因
 */
- (void)onAudioPublishStateChanged:(AliRtcPublishState)oldState
                          newState:(AliRtcPublishState)newState
              elapseSinceLastState:(NSInteger)elapseSinceLastState
                           channel:(NSString *_Nonnull)channel
                            reason:(AliRtcPublishStateChangedReason)reason;

/**
 * @brief 音频推流变更回调
 * @param track 变化的track，详见 {@link AliRtcAudioTrack}
 * @param oldState 之前的推流状态，详见 {@link AliRtcPublishState}
 * @param newState 当前的推流状态，详见 {@link AliRtcPublishState}
 * @param elapseSinceLastState 状态变更时间间隔(毫秒)
 * @param channel 当前频道id
 */
- (void)onAudioPublishStateChanged:(AliRtcAudioTrack)track oldState:(AliRtcPublishState)oldState newState:(AliRtcPublishState)newState elapseSinceLastState:(NSInteger)elapseSinceLastState channel:(NSString *_Nonnull)channel;

/**
 * @brief 音频推流变更回调
 * @param track 变化的track，详见 {@link AliRtcAudioTrack}
 * @param oldState 之前的推流状态，详见 {@link AliRtcPublishState}
 * @param newState 当前的推流状态，详见 {@link AliRtcPublishState}
 * @param elapseSinceLastState 状态变更时间间隔(毫秒)
 * @param channel 当前频道id
 * @param reason 推流状态变化原因
 */
- (void)onAudioPublishStateChanged:(AliRtcAudioTrack)track oldState:(AliRtcPublishState)oldState newState:(AliRtcPublishState)newState elapseSinceLastState:(NSInteger)elapseSinceLastState channel:(NSString *_Nonnull)channel reason:(AliRtcPublishStateChangedReason)reason;

/**
 * @brief 视频推流变更回调
 * @param oldState 之前的推流状态，详见 {@link AliRtcPublishState}
 * @param newState 当前的推流状态，详见 {@link AliRtcPublishState}
 * @param elapseSinceLastState 状态变更时间间隔(毫秒)
 * @param channel 当前频道id
*/
- (void)onVideoPublishStateChanged:(AliRtcPublishState)oldState newState:(AliRtcPublishState)newState elapseSinceLastState:(NSInteger)elapseSinceLastState channel:(NSString *_Nonnull)channel;

/**
 * @brief 视频推流变更回调
 * @param oldState 之前的推流状态，详见 {@link AliRtcPublishState}
 * @param newState 当前的推流状态，详见 {@link AliRtcPublishState}
 * @param elapseSinceLastState 状态变更时间间隔(毫秒)
 * @param channel 当前频道id
 * @param reason 推流状态变化原因
*/
- (void)onVideoPublishStateChanged:(AliRtcPublishState)oldState newState:(AliRtcPublishState)newState elapseSinceLastState:(NSInteger)elapseSinceLastState channel:(NSString *_Nonnull)channel reason:(AliRtcPublishStateChangedReason)reason;

/**
 * @brief 次要流推流变更回调
 * @param oldState 之前的推流状态，详见 {@link AliRtcPublishState}
 * @param newState 当前的推流状态，详见 {@link AliRtcPublishState}
 * @param elapseSinceLastState 状态变更时间间隔(毫秒)
 * @param channel 当前频道id
*/
- (void)onDualStreamPublishStateChanged:(AliRtcPublishState)oldState newState:(AliRtcPublishState)newState elapseSinceLastState:(NSInteger)elapseSinceLastState channel:(NSString *_Nonnull)channel;

/**
 * @brief 次要流推流变更回调
 * @param oldState 之前的推流状态，详见 {@link AliRtcPublishState}
 * @param newState 当前的推流状态，详见 {@link AliRtcPublishState}
 * @param elapseSinceLastState 状态变更时间间隔(毫秒)
 * @param channel 当前频道id
 * @param reason 推流状态变化原因
*/
- (void)onDualStreamPublishStateChanged:(AliRtcPublishState)oldState newState:(AliRtcPublishState)newState elapseSinceLastState:(NSInteger)elapseSinceLastState channel:(NSString *_Nonnull)channel reason:(AliRtcPublishStateChangedReason)reason;

/**
 * @brief 屏幕分享推流变更回调
 * @param oldState 之前的推流状态，详见 {@link AliRtcPublishState}
 * @param newState 当前的推流状态，详见 {@link AliRtcPublishState}
 * @param elapseSinceLastState 状态变更时间间隔(毫秒)
 * @param channel 当前频道id
*/
- (void)onScreenSharePublishStateChanged:(AliRtcPublishState)oldState newState:(AliRtcPublishState)newState elapseSinceLastState:(NSInteger)elapseSinceLastState channel:(NSString *_Nonnull)channel;

/**
 * @brief 屏幕分享推流变更回调
 * @param oldState 之前的推流状态，详见 {@link AliRtcPublishState}
 * @param newState 当前的推流状态，详见 {@link AliRtcPublishState}
 * @param elapseSinceLastState 状态变更时间间隔(毫秒)
 * @param channel 当前频道id
 * @param reason 推流状态变化原因
*/
- (void)onScreenSharePublishStateChanged:(AliRtcPublishState)oldState newState:(AliRtcPublishState)newState elapseSinceLastState:(NSInteger)elapseSinceLastState channel:(NSString *_Nonnull)channel reason:(AliRtcPublishStateChangedReason)reason;

/**
 * @brief 屏幕分享推流变更回调
 * @param oldState 之前的推流状态，详见 {@link AliRtcPublishState}
 * @param newState 当前的推流状态，详见 {@link AliRtcPublishState}
 * @param elapseSinceLastState 状态变更时间间隔(毫秒)
 * @param channel 当前频道id
 * @param screenShareInfo 本次屏幕共享推流配置信息
 * @note 屏幕共享推流状态变更时与onScreenSharePublishStateChanged回调均会触发
*/
- (void)onScreenSharePublishStateChangedWithInfo:(AliRtcPublishState)oldState newState:(AliRtcPublishState)newState elapseSinceLastState:(NSInteger)elapseSinceLastState channel:(NSString *_Nonnull)channel info:(AliRtcScreenShareInfo* _Nonnull)screenShareInfo;

/**
 * @brief 使用RTS URL推流结果
 * @details 应用调用 {@link AliEngine::PublishStreamByRtsUrl} 方法时，该回调表示推流成功/失败
 * @param result 推流结果，成功返回0，失败返回错误码
 */
- (void)onPublishStreamByRtsUrlResult:(NSString *_Nonnull)rtsUrl result:(int)result;


/**
 * @brief 使用RTS URL结束推流结果
 * @details 应用调用 {@link AliEngine::PublishStreamByRtsUrl} 方法时，该回调表示结束推流成功/失败
 * @param result 推流结果，成功返回0，失败返回错误码
 */
- (void)onStopPublishStreamByRtsUrlResult:(NSString *_Nonnull)rtsUrl result:(int)result;

/**
 * @brief 使用RTS URL订阅结果回调
 * @details 应用调用 {@link AliEngine::SubscribeStreamByRtsUrl} 方法时，该回调表示订阅成功/失败
 * @param uid 订阅的用户ID
 * @param result 订阅结果，成功返回0，失败返回错误码
 */
- (void)onSubscribeStreamByRtsUrlResult:(NSString *_Nonnull)uid result:(int)result;

/**
 * @brief 使用RTS URL取消订阅结果回调
 * @details 应用调用 {@link AliEngine::StopSubscribeStreamByRtsUrl} 方法时，该回调表示取消订阅成功/失败
 * @param uid 取消订阅的用户ID
 * @param result 取消订阅结果，成功返回0，失败返回错误码
 */
- (void)onStopSubscribeStreamByRtsUrlResult:(NSString *_Nonnull)uid result:(int)result;


/**
 * @brief 预建联数目超限回调
 * @details 应用调用 {@link AliRtcEngine::subscribeStreamByRtsUrl} 方法时如果超出预建联流数上限，则会销毁最早的RTS流，
 * 停止订阅的结果将在{@link AliRtcEngineDelegate::onStopSubscribeStreamByRtsUrlResult}中回调。
 * @param uid 销毁订阅RTS流的用户ID
 * @param url 销毁订阅RTS流的URL
 */
- (void)onSubscribedRtsStreamBeyondLimit:(NSString *_Nonnull)uid url:(NSString *_Nonnull)url;

/**
 * @brief 使用RTS UID 暂停订阅结果回调
 * @details 应用调用 {@link AliEngine::PauseRtsStreamByRtsUserId} 方法时，该回调表示暂停订阅成功/失败
 * @param uid 暂停订阅的用户ID
 * @param result 暂停订阅结果，成功返回0，失败返回错误码
 */
- (void)onPauseRtsStreamResult:(NSString *_Nonnull)uid result:(int)result;

/**
 * @brief 使用RTS UID 恢复订阅结果回调
 * @details 应用调用 {@link AliEngine::ResumeRtsStreamByRtsUserId} 方法时，该回调表示恢复订阅成功/失败
 * @param uid 恢复订阅的用户ID
 * @param result 恢复订阅结果，成功返回0，失败返回错误码
 */
- (void)onResumeRtsStreamResult:(NSString *_Nonnull)uid result:(int)result;


/**
 * @brief 远端用户（通信模式）/（互动模式，主播角色）加入频道回调
 * @details 该回调在以下场景会被触发
 * - 通信模式：远端用户加入频道会触发该回调，如果当前用户在加入频道前已有其他用户在频道中，当前用户加入频道后也会收到已加入频道用户的回调
 * - 互动模式：
 *   - 远端主播角色用户加入频道会触发该回调，如果当前用户在加入频道前已有其他主播在频道中，当前用户加入频道后也会收到已加入频道主播的回调
 *   - 远端观众角色调用 {@link AliRtcEngine::setClientRole:} 切换为主播角色 {@link AliEngineClientRoleInteractive}，会触发该回调
 *
 * @param uid 用户ID 从App server分配的唯一标示符
 * @param elapsed 用户加入频道时的耗时
 * @note 互动模式下回调行为
 * - 主播间可以互相收到加入频道回调
 * - 观众可以收到主播加入频道回调
 * - 主播无法收到观众加入频道回调
 */
- (void)onRemoteUserOnLineNotify:(NSString *_Nonnull)uid elapsed:(int)elapsed;

/**
 * @brief 远端用户（通信模式）/（互动模式，主播角色）离开频道回调
 * @details 该回调在以下场景会被触发
 * - 通信模式：远端用户离开频道会触发该回调
 * - 互动模式：
 *   - 远端主播角色 {@link AliRtcClientRoleInteractive} 离开频道
 *   - 远端主播切换调用 {@link AliRtcEngine::setClientRole:} 切换为观众角色 {@link AliRtcClientRolelive}，会触发该回调
 * - 通信模式和互动模式主播角色情况下，当长时间收不到远端用户数据，超时掉线时，会触发该回调
 *
 * @param uid 用户ID 从App server分配的唯一标示符
 * @param reason 用户离线的原因，详见 {@link AliRtcUserOfflineReason}
 */
- (void)onRemoteUserOffLineNotify:(NSString *_Nonnull)uid offlineReason:(AliRtcUserOfflineReason)reason;

/**
 * @brief 远端用户的音视频流发生变化回调
 * @details 该回调在以下场景会被触发
 * - 当远端用户从未推流变更为推流（包括音频和视频）
 * - 当远端用户从已推流变更为未推流（包括音频和视频）
 * - 互动模式下，调用 {@link AliRtcEngine::setClientRole:} 切换为主播角色 {@link AliRtcClientRoleInteractive}，同时设置了推流时，会触发该回调
 * @param uid 用户ID，从App server分配的唯一标示符
 * @param audioTrack 音频流类型，详见 {@link AliRtcAudioTrack}
 * @param videoTrack 视频流类型，详见 {@link AliRtcVideoTrack}
 * @note 该回调仅在通信模式用户和互动模式下的主播角色才会触发
 */
- (void)onRemoteTrackAvailableNotify:(NSString *_Nonnull)uid audioTrack:(AliRtcAudioTrack)audioTrack videoTrack:(AliRtcVideoTrack)videoTrack;

/**
 * @brief 音频订阅情况变更回调
 * @param uid userId，从App server分配的唯一标示符
 * @param oldState 之前的订阅状态，详见 {@link AliRtcSubscribeState}
 * @param newState 当前的订阅状态，详见 {@link AliRtcSubscribeState}
 * @param elapseSinceLastState 两次状态变更时间间隔(毫秒)
 * @param channel 当前频道id
 */
- (void)onAudioSubscribeStateChanged:(NSString *_Nonnull)uid oldState:(AliRtcSubscribeState)oldState newState:(AliRtcSubscribeState)newState elapseSinceLastState:(NSInteger)elapseSinceLastState channel:(NSString *_Nonnull)channel;

- (void)onAudioSubscribeStateChanged:(NSString *_Nonnull)uid track:(AliRtcAudioTrack)track oldState:(AliRtcSubscribeState)oldState newState:(AliRtcSubscribeState)newState elapseSinceLastState:(NSInteger)elapseSinceLastState channel:(NSString *_Nonnull)channel;

/**
 * @brief 相机流订阅情况变更回调
 * @param uid userId，从App server分配的唯一标示符
 * @param oldState 之前的订阅状态，详见 {@link AliRtcSubscribeState}
 * @param newState 当前的订阅状态，详见 {@link AliRtcSubscribeState}
 * @param elapseSinceLastState 两次状态变更时间间隔(毫秒)
 * @param channel 当前频道id
 */
- (void)onVideoSubscribeStateChanged:(NSString *_Nonnull)uid oldState:(AliRtcSubscribeState)oldState newState:(AliRtcSubscribeState)newState elapseSinceLastState:(NSInteger)elapseSinceLastState channel:(NSString *_Nonnull)channel;

/**
 * @brief 屏幕分享流订阅情况变更回调
 * @param uid userId，从App server分配的唯一标示符
 * @param oldState 之前的订阅状态，详见 {@link AliRtcSubscribeState}
 * @param newState 当前的订阅状态，详见 {@link AliRtcSubscribeState}
 * @param elapseSinceLastState 两次状态变更时间间隔(毫秒)
 * @param channel 当前频道id
 */
- (void)onScreenShareSubscribeStateChanged:(NSString *_Nonnull)uid oldState:(AliRtcSubscribeState)oldState newState:(AliRtcSubscribeState)newState elapseSinceLastState:(NSInteger)elapseSinceLastState channel:(NSString *_Nonnull)channel;

/**
 * @brief 大小订阅情况变更回调
 * @param uid userId，从App server分配的唯一标示符
 * @param oldStreamType 之前的订阅的大小流类型，详见 {@link AliRtcVideoStreamType}
 * @param newStreamType 当前的订阅的大小流类型，详见 {@link AliRtcVideoStreamType}
 * @param elapseSinceLastState 大小流类型变更时间间隔(毫秒)
 * @param channel 当前频道id
 */
- (void)onSubscribeStreamTypeChanged:(NSString *_Nonnull)uid oldStreamType:(AliRtcVideoStreamType)oldStreamType newStreamType:(AliRtcVideoStreamType)newStreamType elapseSinceLastState:(NSInteger)elapseSinceLastState channel:(NSString *_Nonnull)channel;

/**
 * @brief 当用户角色发生变化时通知
 * @param oldRole 变化前角色类型，参考 {@link AliRtcClientRole}
 * @param newRole 变化后角色类型，参考 {@link AliRtcClientRole}
 * @note 调用 {@link AliRtcEngine::setClientRole:} 方法切换角色成功时触发此回调
 */
- (void)onUpdateRoleNotifyWithOldRole:(AliRtcClientRole)oldRole newRole:(AliRtcClientRole)newRole;

/**
 * @brief 网络质量变化时发出的消息
 * @param uid 网络质量发生变化的uid
 * @param upQuality  上行网络质量
 * @param downQuality  下行网络质量
 * @note 当网络质量发生变化时触发，uid为@""时代表self的网络质量变化
 */
- (void)onNetworkQualityChanged:(NSString *_Nonnull)uid
               upNetworkQuality:(AliRtcNetworkQuality)upQuality
             downNetworkQuality:(AliRtcNetworkQuality)downQuality;

/**
 * @brief 是否推静态图片
 * @details 通过 {@link AliRtcEngine::setPublishImage:} 设置替代图片，上行网络状态差的情况下触发该回调。
 * @param trackType 视频流类型
 * @param isStaticFrame
 * - YES: 上行网络差，开始推静态图片
 * - NO: 上行网络恢复，推正常采集数据
 */
- (void)onPublishStaticVideoFrame:(AliRtcVideoTrack)trackType
                   isStaticFrame:(BOOL)isStaticFrame;

/**
 * @deprecated
 * @brief 网络连接断开
 * @note 使用onConnectionStatusChange替换
 */
- (void)onConnectionLost;

/**
 * @deprecated
 * @brief 网络连接正在尝试重连中
 * @note 使用onConnectionStatusChange替换
 */
- (void)onTryToReconnect;

/**
 * @deprecated
 * @brief 网络连接重连成功
 * @note 使用onConnectionStatusChange替换
 */
- (void)onConnectionRecovery;

/**
 * @brief 网络连接状态改变的回调
 * @param status 当前状态值, 对应值参考枚举 {@link AliRtcConnectionStatus}
 * @param reason 引起状态变化的具体原因, 对应值参考枚举 {@link AliRtcConnectionStatusChangeReason}
 */
- (void)onConnectionStatusChange:(AliRtcConnectionStatus)status
                          reason:(AliRtcConnectionStatusChangeReason)reason;

/**
 * @brief 被服务器踢出/会议结束频道的消息
 * @param code 原因参考 {@link AliRtcOnByeType}
 */
- (void)onBye:(int)code;

/**
 * @brief 如果engine出现warning，通过这个回调通知app
 * @param warn  Warning type
 * @param message 警告描述
 */
- (void)onOccurWarning:(int)warn message:(NSString *_Nonnull)message;

/**
 * @brief 如果engine出现error，通过这个回调通知app
 * @param error  Error类型，参考 {@link AliRtcErrorCode}
 * @param message 错误描述
 */
- (void)onOccurError:(int)error  message:(NSString *_Nonnull)message;

/**
 * @brief 当前设备性能不足
 */
- (void)onPerformanceLow;

/**
 * @brief 当前设备性能恢复
 */
- (void)onPerformanceRecovery;

/**
 * @brief 音频首包发送回调
 * @details 在首个音频数据包发送出去时触发此回调
 * @param timeCost 发送耗时
 */
- (void)onFirstAudioPacketSentWithTimecost:(int)timeCost;

/**
 * @brief 音频首包发送回调
 * @details 在首个音频数据包发送出去时触发此回调
 * @param timeCost 发送耗时，从入会开始到音频首包发送出去的耗时
 * @param track 音频流类型 参考 {@link AliRtcAudioTrack}
 */
- (void)onFirstAudioPacketSentWithTimecost:(AliRtcAudioTrack)track timeCost:(int)timeCost;

/**
 * @brief 视频首帧接收回调
 * @param uid 远端用户ID，从App server分配的唯一标示符
 * @param videoTrack 接收视频track，参考 {@link AliRtcVideoTrack}
 * @param timeCost 耗时（毫秒）
 * @note 该接口用于视频首帧接收的回调
 */
- (void)onFirstVideoFrameReceivedWithUid:(NSString *_Nonnull)uid
                          videoTrack:(AliRtcVideoTrack)videoTrack
                            timeCost:(int)timeCost;


/**
 * @brief 视频首包发送回调
 * @param videoTrack 发送视频track，参考 {@link AliRtcVideoTrack}
 * @param timeCost 耗时（毫秒）
 * @note 该接口用于视频首包发送的回调
 */
- (void)onFirstVideoPacketSentWithVideoTrack:(AliRtcVideoTrack)videoTrack
                                    timeCost:(int)timeCost;

/**
 * @brief 音频首包接收回调
 * @details 在接收到远端首个音频数据包时触发此回调
 * @param uid 远端用户ID，从App server分配的唯一标识符
 * @param timeCost 接收耗时，从入会开始到音频首包接收到的耗时
 */
- (void)onFirstAudioPacketReceivedWithUid:(NSString *_Nonnull)uid
                                 timeCost:(int)timeCost;

/**
 * @brief 音频首包接收回调
 * @details 在接收到远端首个音频数据包时触发此回调
 * @param uid 远端用户ID，从App server分配的唯一标识符
 * @param track 音频流类型 {@link AliRtcAudioTrack}
 * @param timeCost 接收耗时，从入会开始到音频首包接收到的耗时
 */
- (void)onFirstAudioPacketReceivedWithUid:(NSString *_Nonnull)uid
                                 track:(AliRtcAudioTrack)track
                                 timeCost:(int)timeCost;

/**
 * @brief 视频首包接收回调
 * @param uid 远端用户ID，从App server分配的唯一标示符
 * @param videoTrack 接收视频track，参考 {@link AliRtcVideoTrack}
 * @param timeCost 耗时（毫秒）
 * @note 该接口用于视频首包接收的回调
 */
- (void)onFirstVideoPacketReceivedWithUid:(NSString *_Nonnull)uid
                          videoTrack:(AliRtcVideoTrack)videoTrack
                            timeCost:(int)timeCost;


/**
 * @brief 已解码远端视频首帧回调
 * @param uid 远端用户ID，从App server分配的唯一标识符
 * @param track音频流类型  {@link AliRtcVideoTrack}
 * @param elapsed 从本地用户加入频道直至该回调触发的延迟, 单位为毫秒
 */
- (void)onFirstRemoteVideoDecodedWithUid:(NSString *_Nonnull)uid track:(AliRtcVideoTrack)track elapsed:(int)elapsed;
/**
 * @brief 已解码远端音频首帧回调
 * @param uid 远端用户ID，从App server分配的唯一标识符
 * @param elapsed 从本地用户加入频道直至该回调触发的延迟, 单位为毫秒
 */
- (void)onFirstRemoteAudioDecodedWithUid:(NSString *_Nonnull)uid elapsed:(int)elapsed;

/**
 * @brief 已解码远端音频首帧回调
 * @param uid 远端用户ID，从App server分配的唯一标识符
 * @param track音频流类型  {@link AliRtcAudioTrack}
 * @param elapsed 从本地用户加入频道直至该回调触发的延迟, 单位为毫秒
 */
- (void)onFirstRemoteAudioDecodedWithUid:(NSString *_Nonnull)uid track:(AliRtcAudioTrack)track elapsed:(int)elapsed;

/**
 * @brief 远端用户的第一帧视频帧显示时触发这个消息
 * @param uid 远端用户ID，从App server分配的唯一标示符
 * @param videoTrack 屏幕流或者相机流，参考 {@link AliRtcVideoTrack}
 * @param width 视频宽度
 * @param height 视频高度
 * @param elapsed 本地用户加入频道直至该回调触发的延迟总耗时（毫秒）
 * @note 该接口用于远端用户的第一帧视频帧显示时的回调
 */
- (void)onFirstRemoteVideoFrameDrawn:(NSString *_Nonnull)uid videoTrack:(AliRtcVideoTrack)videoTrack width:(int)width height:(int)height elapsed:(int)elapsed;

/**
 * @brief 预览开始显示第一帧视频帧时触发这个消息
 * @param width 本地预览视频宽度
 * @param height 本地预览视频高度
 * @param elapsed 从本地用户加入频道直至该回调触发的延迟总耗时（毫秒）
 * @note 该接口用于预览开始显示第一帧视频帧时的回调
 */
- (void)onFirstLocalVideoFrameDrawn:(int)width height:(int)height elapsed:(int)elapsed;

/**
 * @brief 订阅的音频音量，语音状态和uid
 * @param array 表示回调用户音量信息数组，包含用户uid,语音状态以及音量，uid为"0"表示本地说话人, uid为“1”表示远端用户混音音量，其余表示指定uid用户音量。
 * @param totalVolume 混音后的总音量（0~255）。在本地用户的回调中，totalVolume 为本地用户混音后的音量;在远端用户的回调中，totalVolume 为所有说话者混音后的总音量。
 */
- (void)onAudioVolumeCallback:(NSArray <AliRtcUserVolumeInfo *> *_Nullable)array totalVolume:(int)totalVolume;

/**
 * @brief 订阅当前正在说话的人
 * @param uid 说话人uid, 为"0"表示本地说话人。其返回的是当前时间段内声音最大的用户id，而不是瞬时声音最大的用户id
*/
- (void)onActiveSpeaker:(NSString *_Nonnull)uid;

/**
 * @brief 通话前音频采集检测的音量回调
 * @param volume 音量
 */
- (void)onTestAudioVolumeCallback:(int)volume;


/**
 * @brief 音频采集设备测试回调
 * @param level 音频采集设备音量值
 */
- (void)onAudioDeviceRecordLevel:(int)level;

/**
 * @brief 音频播放设备测试回调
 * @param level 音频采集设备音量值
 */
- (void)onAudioDevicePlayoutLevel:(int) level;

/**
 * @brief 音频播放设备测试结束(音频文件播放完毕)
 */
- (void)onAudioDevicePlayoutEnd;

/**
 * @brief 音频设备状态变更
 * @param deviceInfo  外接设备信息
 * @param deviceType  外接设备类型
 * @param deviceState 外接设备状态
*/
- (void)onAudioDeviceStateChanged:(AliRtcDeviceInfo *_Nonnull)deviceInfo deviceType:(AliRtcExternalDeviceType)deviceType deviceState:(AliRtcExternalDeviceState)deviceState;

/**
 * @brief 视频设备状态变更
 * @param deviceInfo  外接设备信息
 * @param deviceType  外接设备类型
 * @param deviceState 外接设备状态
*/
- (void)onVideoDeviceStateChanged:(AliRtcDeviceInfo *_Nonnull)deviceInfo deviceType:(AliRtcExternalDeviceType)deviceType deviceState:(AliRtcExternalDeviceState)deviceState;

/**
 * @brief 视频分辨率变更
 * @param uid 用户ID。从App server分配的唯一标示符
 * @param videoTrack 屏幕流或者相机流
 * @param width 视频宽度
 * @param height 视频高度
*/
- (void)onVideoResolutionChanged:(NSString *_Nonnull)uid videoTrack:(AliRtcVideoTrack)videoTrack width:(int)width height:(int)height;

/**
 * @brief 网络质量探测回调
 * @param networkQuality 网络质量 {@link AliRtcNetworkQuality}
 * @note 当调用 {@link AliRtcEngine::startLastmileDetect} 后会触发该回调
 */
- (void)onLastmileDetectResultWithQuality:(AliRtcNetworkQuality)networkQuality;

/**
 * @brief 网络质量探测结果的回调
 * @param code 探测结果，0 成功，-1失败，网络状况较差
 * @param result 网络质量 {@link AliRtcNetworkQualityProbeResult}
 * @note 当调用 {@link AliRtcEngine::startLastmileDetect} 后会触发该回调
 */
- (void)onLastmileDetectResultWithBandWidth:(int)code result:(AliRtcNetworkQualityProbeResult* _Nonnull)result;


/**
 * @brief 视频输出数据是否由用户来获取
 * @return
 * - YES: 用户获取
 * - NO（默认）: sdk通过回调向外抛出
 */ 
- (BOOL)onGetIfUserFetchObserverData;

/**
 * @brief 视频数据输出格式
 * @return 期望视频输出格式
 * @note 在注册 {@link AliRtcEngine::registerVideoSampleObserver} 后触发回调，应用可返回期望输出的视频数据格式，默认返回AliRtcYUV420
 */
- (AliRtcVideoFormat)onGetVideoFormatPreference;

/**
 * @brief 视频数据输出对齐方式
 * @return 期望视频数据对齐方式
 * @note 在注册 {@link AliRtcEngine::registerVideoSampleObserver} 后触发回调，应用可返回期望输出的视频数据格式，默认返回AliRtcAlignmentDefault，不需要对齐
*/
- (AliRtcVideoObserAlignment)onGetVideoAlignment;

/**
 * @brief 视频数据输出位置
 * @return 期望视频输出，参考 {@link AliRtcVideoObserPosition}
 * @note 在注册 {@link AliRtcEngine::registerVideoSampleObserver} 后触发回调，应用可返回期望输出的视频内容，对应数据将分别从onCaptureVideoSample/onPreEncodeVideoSample/onRemoteVideoSample
 * @note 默认返回全部类型数据，即 {@link AliRtcPositionPostCapture} | {@link AliRtcPositionPreRender} | {@link AliRtcPositionPreEncoder}
 */
- (NSInteger)onGetVideoObservedFramePosition;

/**
 * @brief 视频输出数据是否需要镜像
 * @return
 * - YES: 镜像
 * - NO: 不镜像（默认）
 */ 
- (BOOL)onGetObserverDataMirrorApplied;

/**
 * @brief 拉流视频数据是否平滑输出
 * @return
 * - YES: 平滑输出
 * - NO: 直接输出（默认）
 * @note 只在 {@link onGetIfUserFetchObserverData} 为 NO 时有效
 */ 
- (BOOL)onGetSmoothRenderingEnabled;

/**
 * @brief 订阅的本地采集视频数据回调
 * @param videoSource 视频流类型
 * @param videoSample 视频裸数据
 * @return
 * - YES: 需要写回SDK（只对I420和CVPixelBuffer(ios/mac)有效）
 * - NO: 不需要写回SDK
 */
- (BOOL)onCaptureVideoSample:(AliRtcVideoSource)videoSource videoSample:(AliRtcVideoDataSample *_Nonnull)videoSample;

/**
 * @brief 订阅的本地编码前视频数据回调
 * @param videoSource 视频流类型
 * @param videoSample 视频裸数据
 * @return
 * - YES: 需要写回SDK（只对I420和CVPixelBuffer(ios/mac)有效）
 * - NO: 不需要写回SDK
*/
- (BOOL)onPreEncodeVideoSample:(AliRtcVideoSource)videoSource videoSample:(AliRtcVideoDataSample *_Nonnull)videoSample;

/**
 * @brief 订阅的远端视频数据回调
 * @param uid 用户ID
 * @param videoSource 视频流类型
 * @param videoSample 视频裸数据
 * @return
 * - YES: 需要写回SDK（只对I420和CVPixelBuffer(ios/mac)有效）
 * - NO: 不需要写回SDK
 */
- (BOOL)onRemoteVideoSample:(NSString *_Nonnull)uid videoSource:(AliRtcVideoSource)videoSource videoSample:(AliRtcVideoDataSample *_Nonnull)videoSample;
/**
 * @brief 文件录制回调事件
 * @param event 参考AliRtcRecordMediaEventCode
 * @param filePath 录制文件路径
 * @note 该接口用于文件录制时的事件回调
*/
- (void)onMediaRecordEvent:(AliRtcRecordMediaEventCode)event filePath:(NSString *_Nullable)filePath;

/**
 * @brief 实时数据回调(2s触发一次)
 * @param stats 统计信息
 */
- (void)onRtcStats:(AliRtcStats)stats;

/**
 * @brief 本地视频统计信息(2s触发一次)
 * @param localVideoStats 本地视频统计信息
 * @note SDK每两秒触发一次此统计信息回调
 */
- (void)onRtcLocalVideoStats:(AliRtcLocalVideoStats *_Nonnull)localVideoStats;

/**
 * @brief 远端视频统计信息(2s触发一次)
 * @param remoteVideoStats 远端视频统计信息
 */
- (void)onRtcRemoteVideoStats:(AliRtcRemoteVideoStats *_Nonnull)remoteVideoStats;

/**
 * @brief 本地音频统计信息(2s触发一次)
 * @param localAudioStats 本地视频统计信息
 * @note SDK每两秒触发一次此统计信息回调
 */
- (void)onRtcLocalAudioStats:(AliRtcLocalAudioStats *_Nonnull)localAudioStats;

/**
 * @brief 远端音频统计信息(2s触发一次)
 * @param remoteAudioStats 远端音频统计信息
 */
- (void)onRtcRemoteAudioStats:(AliRtcRemoteAudioStats *_Nonnull)remoteAudioStats;

/**
 * 收到媒体扩展信息回调
 * @param uid 发送用户userId
 * @param payloadType 载荷类型
 * @param data 媒体扩展信息
 * @note 当一端通过 {@link AliRtcEngine::sendMediaExtensionMsg:repeatCount:} 发送信息后，其他端通过该回调接收数据
 */
- (void)onMediaExtensionMsgReceived:(NSString *_Nonnull)uid payloadType:(int)payloadType message:(NSData *_Nonnull)data;

/**
 * 截图回调
 * @param uid 远端用户uid
 * @param videoTrack 截图视频track，参考 {@link AliRtcVideoTrack}
 * @param image 截图数据
 * @param success 截图结果
 * @note 成功image返回截图数据，失败返回nil
 */
- (void)onSnapshotComplete:(NSString*_Nullable)uid videoTrack:(AliRtcVideoTrack)videoTrack image:(NSImage* _Nullable)image success:(BOOL)success;

/**
 * @brief 远端用户静音/取消静音回调
 * @param uid 远端用户ID
 * @param isMute 该用户是否静音
 * - YES: 静音
 * - NO: 取消静音
 */
- (void)onUserAudioMuted:(NSString *_Nullable)uid audioMuted:(BOOL)isMute;

/**
 * @brief 对端用户发送视频黑帧数据发送通知
 * @param uid 执行muteVideo的用户
 * @param isMute
 * - YES: 推流黑帧
 * - NO: 正常推流
 * @note 该接口用于对端用户发送视频黑帧数据时的回调
 */
- (void)onUserVideoMuted:(NSString *_Nullable)uid videoMuted:(BOOL)isMute;

/**
 * @brief 对端用户关闭相机流采集发送通知
 * @param uid 执行EnableLocalVideo的用户
 * @param isEnable
 * - YES: 打开相机流采集
 * - NO: 关闭相机流采集
 * @note 该接口用于对端用户关闭相机流采集时的回调
 */
- (void)onUserVideoEnabled:(NSString *_Nullable)uid videoEnabled:(BOOL)isEnable;

/**
 * @brief 用户音频被中断通知（一般用户打电话等音频被抢占场景）
 * @param uid 音频被中断的用户ID
 */
- (void)onUserAudioInterruptedBegin:(NSString *_Nullable)uid;

/**
 * @brief 用户音频中断结束通知（对应onUserAudioInterruptedBegin）
 * @param uid 音频中断结束的用户ID
 */
- (void)onUserAudioInterruptedEnded:(NSString *_Nullable)uid;

/**
 * @brief 远端用户应用退到后台
 * @param uid 用户
 */
- (void)onUserWillResignActive:(NSString *_Nullable)uid;

/**
 * @brief 远端用户应用返回前台
 * @param uid 用户
 */
- (void)onUserWillBecomeActive:(NSString *_Nullable)uid;

/**
 * @brief 跨频道转推状态变化通知
 * @param state 当前连麦状态，参考 {@link AliRtcChannelRelayEvent}
 * @param code 当前错误码，参考 {@link AliRtcChannelRelayErrorCode}
 * @param message 状态描述信息
 */
- (void)onChannelRelayStateChanged:(int)state code:(int)code message:(NSString *_Nullable)message;

/**
 * @brief 跨频道转推事件通知
 * @param event 状态码，参考 {@link AliRtcChannelRelayEvent}
 */
- (void)onChannelRelayEvent:(int)event;

/**
 * @brief 用户remote video change通知
 * @param uid 需要被通知的用户
 * @param trackType 变化视频track
 * @param state 视频状态的类型
 * @param reason 触发状态变化的原因
 */
- (void)onRemoteVideoChanged:(NSString *_Nonnull)uid trackType:(AliRtcVideoTrack)trackType state:(AliRtcVideoState)state reason:(AliRtcVideoReason)reason;

/**
 * @brief 旁路推流状态改变回调
 * @param streamURL 流地址
 * @param state 推流状态, 参考 {@link AliRtcLiveTranscodingState}
 * @param errCode 错误码, 参考 {@link AliRtcTrascodingLiveStreamErrorCode}
 * @note 该接口用于旁路推流状态改变的回调
 */
- (void)onPublishLiveStreamStateChanged:(NSString *_Nonnull)streamURL state:(AliRtcLiveTranscodingState)state errCode:(AliRtcTrascodingLiveStreamErrorCode)errCode;

/**
 * @brief 旁路推流状态改变回调
 * @param taskId 任务Id
 * @param state 推流状态, 参考 {@link AliRtcLiveTranscodingState}
 * @param errCode 错误码, 参考 {@link AliRtcTrascodingLiveStreamErrorCode}
 * @note 该接口用于旁路推流状态改变的回调
 */
- (void)onPublishLiveStreamStateChangedWithTaskId:(NSString *_Nonnull)taskId state:(AliRtcLiveTranscodingState)state errCode:(AliRtcTrascodingLiveStreamErrorCode)errCode;

/**
 * @brief 旁路任务状态改变回调
 * @param streamURL  流地址
 * @param state 任务状态, 参考 {@link AliRtcTrascodingLiveTaskStatus}
 * @note 该接口用于旁路任务状态改变的回调
 */
- (void)onPublishTaskStateChanged:(NSString *_Nonnull)streamURL state:(AliRtcTrascodingLiveTaskStatus)state;

/**
 * @brief 旁路任务状态改变回调
 * @param taskId 任务Id
 * @param state 任务状态, 参考 {@link AliRtcTrascodingLiveTaskStatus}
 * @note 该接口用于旁路任务状态改变的回调
 */
- (void)onPublishTaskStateChangedWithTaskId:(NSString *_Nonnull)taskId state:(AliRtcTrascodingLiveTaskStatus)state;

/**
 * @brief 本地伴奏播放状态回调
 * @details 该回调在伴奏播放状态发生改变时触发，并通知当前的播放状态和错误码
 * @param playState 当前播放状态，详情参考 {@link AliRtcAudioAccompanyStateCode}
 * @param errorCode 播放错误码，详情参考 {@link AliRtcAudioAccompanyErrorCode}
 */
- (void)onAudioAccompanyStateChanged:(AliRtcAudioAccompanyStateCode)playState errorCode:(AliRtcAudioAccompanyErrorCode)errorCode;

/**
 * @brief 音频文件信息回调
 * @details 该回调在调用{@link AliRtcEngine::getAudioFileInfo}后触发，返回当前音频文件信息和错误码
 * @param info 音频文件信息，详情参考 {@link AliRtcAudioFileInfo}
 * @param errorCode 错误码，详情参考 {@link AliRtcAudioAccompanyErrorCode}
 */
- (void)onAudioFileInfo:(AliRtcAudioFileInfo* _Nonnull)info errorCode:(AliRtcAudioAccompanyErrorCode)errorCode;

/**
 * @brief 远端用户伴奏播放开始回调
 * @param uid 远端用户ID，从App server分配的唯一标识符
 */
- (void)onRemoteAudioAccompanyStarted:(NSString *_Nonnull)uid;

/**
 * @brief 远端用户伴奏播放结束回调
 * @param uid 远端用户ID，从App server分配的唯一标识符
 */
- (void)onRemoteAudioAccompanyFinished:(NSString *_Nonnull)uid;

/**
 * @brief 本地音效播放结束回调
 * @param soundId 用户给该音效文件分配的唯一ID
 */
- (void)onAudioEffectFinished:(int)soundId;

/**
 * @brief Qos参数发生变化通知
 * @param trackType 变化视频track
 * @param parameter qos参数结构体
 */
- (void)onRequestVideoExternalEncoderParameter:(AliRtcVideoTrack)trackType parameter:(AliRtcVideoExternalEncoderParameter *_Nullable)parameter;

/**
 * @deprecated
 * @brief Qos请求帧类型发生变化通知
 * @param trackType 变化视频track
 * @param frameType 请求参考帧类型
 */
- (void)onRequestVideoExternalEncoderFrame:(AliRtcVideoTrack)trackType frameType:(AliRtcVideoEncodedFrameType)frameType;

/**
 * @brief 本地设备异常回调
 * @param deviceType 设备类型, 参考{@link AliRtcLocalDeviceType}
 * @param exceptionType 设备异常类型, 参考{@link AliRtcLocalDeviceExceptionType}
 * @param msg 异常时携带的信息
 * @note 此回调标识了内部无法恢复了设备异常，收到此回调时用户需要检查设备是否可用
 */
- (void)onLocalDeviceException:(AliRtcLocalDeviceType)deviceType
                 exceptionType:(AliRtcLocalDeviceExceptionType)exceptionType
                       message:(NSString *_Nullable)msg;

/**
 * @brief 本地音频采集设备状态回调
 * @param state  设备状态，AliRtcLocalAudioStateType类型
 * @param msg  设备状态变化的描述信息
 * @note startAudioCapture 和 stopAudioCapture的结果回调
 */
- (void)onLocalAudioStateChanged:(AliRtcLocalAudioStateType)state message:(NSString *_Nullable)msg;

/**
 * @brief 本地视频采集设备状态回调
 * @param state  设备状态，AliRtcLocalVideoStateType类型
 * @param msg  设备状态变化的描述信息
 * @note startAudioCapture 和 stopAudioCapture的结果回调
 */
- (void)onLocalVideoStateChanged:(AliRtcLocalVideoStateType)state message:(NSString *_Nullable)msg;


/**
 * @brief 可以开始发送data channel消息回调
 * @param uid 用户
 * @note 收到此回调后，可以开始发送data channel消息
 */
- (void)onRemoteUserSubscribedDataChannel:(NSString *_Nonnull)uid;


/**
 * @brief 音频延迟信息
 * @param id 语句id
 * @param delayMs 延迟(毫秒)
 */
- (void)onAudioDelayInfo:(int)sentenceId questionEndTime:(long long)questionEndTime answerStartTime:(long long)answerStartTime;


/**
 * @brief AI agent处理结果
 * @param code 返回code码
 * @param action 结果对应的action
 * @param result 结果
 */
- (void)onAIAgentResult:(int)code action:(NSString *_Nonnull)action result:(NSString *_Nonnull)result;

/**
 * @brief Profile统计信息上报
 * @param type Profile类型 1-视频，10-音频，11-AI回环
 * @param result 统计信息，json格式
 */
- (void)onProfileStats:(int)type result:(NSString *_Nonnull)result;

/**
 * @brief 用户鉴权信息即将过期通知，收到后30秒鉴权过期
 * @note 该回调在鉴权信息30秒前触发，收到该回调后应该及时更新鉴权信息，参考 {@link AliRtcEngine::refreshAuthInfo:}
 */
- (void)onAuthInfoWillExpire;

/**
 * @brief 用户调用需要鉴权的接口，服务端返回信息过期
 * @note 该回调触发代表鉴权信息已过期，想要继续在会中，需要重新入会，参考 {@link AliRtcEngine::joinChannel:name:onResultWithUserId:}
 */
- (void)onAuthInfoExpired;

/**
 * @brief API 方法已执行回调。
 * @param error 接口返回值，Error类型，参考 {@link AliRtcErrorCode}
 * @param api api 名字
 * @param result api 调用结果
 */
- (void)onCalledApiExecuted:(int)error api:(NSString *_Nonnull)api result:(NSString *_Nonnull)result;

/**
 * @brief 伴奏控制消息
 * @param uid 用户
 * @param controlMsg 消息
 * @param 
 */
- (void)onDataChannelMessage:(NSString *_Nonnull)uid controlMsg:(AliRtcDataChannelMsg*_Nonnull)controlMsg;

@end
/** @} AliRtcEngineDelegate_mac AliRtcEngineDelegate */

@protocol AliRtcVideoFrameDelegate <NSObject>
@optional

/**
 * @brief 订阅的本地采集视频数据回调
 * @param videoSource 视频流类型
 * @param videoSample 视频裸数据
 * @return
 * - YES: 需要写回SDK（只对I420和CVPixelBuffer(ios/mac)有效）
 * - NO: 不需要写回SDK
*/
- (BOOL)onCaptureVideoSample:(AliRtcVideoSource)videoSource videoSample:(AliRtcVideoDataSample *_Nonnull)videoSample;

/**
 * @brief 订阅的本地编码前视频数据回调
 * @param videoSource 视频流类型
 * @param videoSample 视频裸数据
 * @return
 * - YES: 需要写回SDK（只对I420和CVPixelBuffer(ios/mac)有效）
 * - NO: 不需要写回SDK
*/
- (BOOL)onPreEncodeVideoSample:(AliRtcVideoSource)videoSource videoSample:(AliRtcVideoDataSample *_Nonnull)videoSample;

/**
 * @brief 订阅的远端视频数据回调
 * @param uid 用户ID
 * @param videoSource 视频流类型
 * @param videoSample 视频裸数据
 * @return
 * - YES: 需要写回SDK（只对I420和CVPixelBuffer(ios/mac)有效）
 * - NO: 不需要写回SDK
*/
- (BOOL)onRemoteVideoSample:(NSString *_Nonnull)uid videoSource:(AliRtcVideoSource)videoSource videoSample:(AliRtcVideoDataSample *_Nonnull)videoSample;

/**
 * @brief 视频输出数据是否由用户来获取
 * @return
 * - YES: 用户获取
 * - NO（默认）: sdk通过回调向外抛出
 */
- (BOOL)onGetIfUserFetchObserverData;

/**
 * @brief 视频数据输出格式
 * @return 期望视频输出格式
 * @note 应用可返回期望输出的视频数据格式，默认返回 AliRtcYUV420
 */
- (AliRtcVideoFormat)onGetVideoFormatPreference;

 /**
 * @brief 视频数据输出对齐方式
 * @return 期望视频数据对齐方式
 * @note 应用可返回期望输出的视频数据格式，默认返回  {@link AliRtcAlignmentDefault} ，不需要对齐
*/
- (AliRtcVideoObserAlignment)onGetVideoAlignment;

/**
 * @brief 视频数据输出位置
 * @return 期望视频输出，参考 {@link AliRtcVideoObserPosition}
 * @note 应用可返回期望输出的视频内容，对应数据将分别从onCaptureVideoSample/onPreEncodeVideoSample/onRemoteVideoSample
 * @note 默认返回全部类型数据，即 {@link AliRtcPositionPostCapture} | {@link AliRtcPositionPreRender} | {@link AliRtcPositionPreEncoder}
 */
- (NSInteger)onGetVideoObservedFramePosition;

/**
 * @brief 视频输出数据是否需要镜像
 * @return
 * - YES: 镜像
 * - NO: 不镜像（默认）
 */
- (BOOL)onGetObserverDataMirrorApplied;

/**
 * @brief 拉流视频数据是否平滑输出
 * @return
 * - YES: 平滑输出
 * - NO: 直接输出（默认）
 * @note 只在 {@link onGetIfUserFetchObserverData} 为 NO 时有效
 */
- (BOOL)onGetSmoothRenderingEnabled;

@end


#pragma mark - "音频数据回调Delegate"

@protocol AliRtcAudioFrameDelegate <NSObject>
@optional

/**
 * @brief 采集裸数据回调
 * @details 默认关闭，需要通过enableAudioFrameObserver : YES audioSource: AliRtcAudioSourceCaptured 开启
 *
 *  - 该接口支持设置采样率、声道数
 *  - 该接口支持读写模式
 *
 * @param frame 音频数据,详见{@link AliRtcAudioFrame}
 * @return true: success
 * @note 请不要在此回调函数中做任何耗时操作，否则可能导致声音异常
 */
- (BOOL)onCapturedAudioFrame:(AliRtcAudioFrame* _Nonnull)frame;

/**
 * @brief 3A后数据回调
 * @details 默认关闭，需要通过enableAudioFrameObserver : YES audioSource: AliRtcAudioSourceCaptured 开启
 *
 *  - 该接口支持设置采样率、声道数
 *  - 该接口支持读写模式
 *
 * @param frame 音频数据,详见{@link AliRtcAudioFrame}
 * @return true: success
 * @note 请不要在此回调函数中做任何耗时操作，否则可能导致声音异常
 */
- (BOOL)onProcessCapturedAudioFrame:(AliRtcAudioFrame* _Nonnull)frame;

/**
 * @brief 推流数据回调
 * @details 默认关闭，需要通过enableAudioFrameObserver : YES audioSource: AliRtcAudioSourcePub 开启
 *
 *  - 该接口支持设置采样率、声道数
 *  - 该接口只支持只读模式
 *
 * @param frame 音频数据,详见{@link AliRtcAudioFrame}
 * @return true: success
 * @note 请不要在此回调函数中做任何耗时操作，否则可能导致声音异常
 */
- (BOOL)onPublishAudioFrame:(AliRtcAudioFrame* _Nonnull)frame;

/**
 * @brief 播放数据回调
 * @details 默认关闭，需要通过enableAudioFrameObserver : YES audioSource: AliRtcAudioSourcePlayback 开启
 *
 *  - 该接口支持设置采样率、声道数
 *  - 该接口支持读写模式
 *
 * @param frame 音频数据,详见{@link AliRtcAudioFrame}
 * @return true: success
 * @note 请不要在此回调函数中做任何耗时操作，否则可能导致声音异常
 */
- (BOOL)onPlaybackAudioFrame:(AliRtcAudioFrame* _Nonnull)frame;

/**
 * @brief 推流数据和播放数据混音后回调
 * @details 默认关闭，需要通过enableAudioFrameObserver : YES audioSource: AliRtcAudioSourceMixedAll 开启
 *
 *  - 该接口支持设置采样率、声道数
 *  - 该接口支持读写模式
 *
 * @param frame 音频数据,详见{@link AliRtcAudioFrame}
 * @return true: success
 * @deprecated
 * @note 请不要在此回调函数中做任何耗时操作，否则可能导致声音异常
 */
- (BOOL)onMixedAllAudioFrame:(AliRtcAudioFrame* _Nonnull)frame;

/**
 * @brief 远端拉流数据回调
 * @details 默认关闭，需要通过enableAudioFrameObserver : YES audioSource: AliRtcAudioSourceRemoteUser 开启
 *
 *  - 该接口不支持设置采样率、声道数
 *  - 该接口支持读写模式
 *
 * @param frame 音频数据,详见{@link AliRtcAudioFrame}
 * @return true: success
 * @note 请不要在此回调函数中做任何耗时操作，否则可能导致声音异常
 */
- (BOOL)onRemoteUserAudioFrame:(NSString *_Nullable)uid frame:(AliRtcAudioFrame* _Nonnull)frame;
@end

@protocol AliRtcEngineDestroyDelegate <NSObject>
@optional

/**
 * @brief 用户调用需要鉴权的接口，服务端返回信息过期
 * @note 该回调触发代表鉴权信息已过期，想要继续在会中，需要重新入会，参考 {@link AliRtcEngine::joinChannel:name:onResultWithUserId:}
 */
- (void)onDestroyCompletion;
@end


#pragma mark - 接口主类

/**
 * @defgroup AliRtc_mac AliRtcEngine
 * AliRTC功能的主要接口类
 * @{
 */

@interface AliRtcEngine : NSObject <AliRtcEngineDelegate>

//- (instancetype)init __attribute__((unavailable("use sharedInstance to create the singletone")));

#pragma mark - "Engine的生命周期，工作参数以及频道操作"

/**
 * @brief 获取一个AliRtcEngine实例
 * @param delegate 用于接收AliRTC回调的代理。
 * @param extras 用于接收来自客户灰度下发的参数，通过JSON配置SDK的特别功能，可以是空字符串。详情请参见官网[有关extras功能说明](https://help.aliyun.com/document_detail/200048.htm )。
 * @details 该方法为同步调用，以单例的形式提供对象创建。
 * @note 注意 同一时间只会存在一个主实例。
 * @note 创建子实例，请参考使用 {@link createChannelWithDelegate:extras:}
 */
+ (instancetype _Nonnull )sharedInstance:(id<AliRtcEngineDelegate>_Nullable)delegate extras:(NSString *_Nullable)extras;

/**
 * @brief 销毁 {@link AliRtcEngine}
 * @details 调用该方法将会释放所有内部使用的资源,当完成音视频通信之后都建议调用该方法释放实例.调用该方法后，你将不能再使用 {@link AliRtcEngine} 的其他方法和任何回调，如需要再次使用需要重新调用 {@link AliRtcEngine::sharedInstance:extras:} 方法创建一个新的实例。
 * @note 该接口为同步接口，需要等待内部资源释放之后才能执行其他方法，为避免主线程阻塞，建议开发者放在子线程调用该方法，但需要注意的是如需在销毁后再次创建 {@link AliRtcEngine} 实例，请开发者务必保证 destroy 方法执行结束后再创建实例。
 * @note 为避免死锁，不建议在任何SDK的回调中调用本方法
 */
+ (void)destroy;

/**
 * @brief 销毁AliRtcEngine实例
 * @param delegate 用于接收AliRTC销毁回调的代理。
 * @details 调用该方法将会释放所有内部使用的资源,当完成音视频通信之后都建议调用该方法释放实例.调用该方法后，你将不能再使用 {@link AliRtcEngine} 的其他方法和任何回调，如需要再次使用需要重新调用 {@link AliRtcEngine::sharedInstance:extras:} 方法创建一个新的实例。
 * @note 该接口为异步接口，需要等待onDestroyCompletion回调之后才能执行其他方法，为避免主线程阻塞，建议开发者放在子线程调用该方法，但需要注意的是如需在销毁后再次创建 {@link AliRtcEngine} 实例，请开发者务必保证 destroy 方法执行结束后再创建实例。
 * @note 为避免死锁，不建议在任何SDK的回调中调用本方法
 */
+ (void)destroy:(id<AliRtcEngineDestroyDelegate>_Nullable)delegate;

/**
 * @brief 查询SDK当前版本号
 * @return 当前的SDK版本号，格式为字符串，例："2.5.0.x"
 * @note 在任何时刻都可以调用
 */
+ (NSString *_Nonnull)getSdkVersion;

/**
 * @brief 设置SDK日志文件保存路径
 * @param logDirPath 日志文件保存目录的绝对路径，该参数是一个目录路径，而不是文件的路径。
 * @return 
 * - 0，成功
 * - 非0，失败。其中有两种错误码，释义如下：
 *   - {@link AliRtcErrLogRootPathError} : 路径已存在或因权限问题不可访问。
 *   - {@link AliRtcErrLogAlreadyInit} : log对象已经初始化过。
 * 
 * @note 调用此接口，请在调用其他所有SDK接口前调用本接口，避免日志出现丢失。同时，App必须保证指定的目录已存在并且可以写入。
 * @note 如果，目标路径不可写入或创建日志文件失败，则会使用默认日志路径。本次设置将无效。
 */
+ (int)setLogDirPath:(NSString *_Nullable)logDirPath;

/**
 * @brief 上传日志文件
 * @details 用户主动调用此接口，将当前日志目录下的所有未上传的日志文件进行压缩、打包、上传。
 * @note 上传过程中，如果有进入频道等操作，会自动停止上传行为，避免影响入会体验。
 */
+ (void)uploadLog;

/**
 * @brief 根据错误码，获取错误码描述
 * @param errCode 错误码，详见 {@link AliRtcErrorCode}
 * @return 错误码描述字符串
 * @note 在任何时刻都可以调用
 */
+ (NSString *_Nullable)getErrorDescription:(NSInteger)errCode;

/**
 * @brief 设置音频模式还是音视频模式
 * @param audioOnly
 * - YES: 只有音频推流和拉流（纯音频）
 * - NO: 音视频都支持
 * @return 
 * - 0: 成功
 * - 非0: 失败
 * @note 只可以在 {@link joinChannel:name:onResultWithUserId:} 之前设置
 */
- (int)setAudioOnlyMode:(BOOL)audioOnly;

/**
 * @brief 加入频道
 * @param authInfo    认证信息，从App Server获取。
 * @param userName    任意用于显示的用户名称。不是用户ID
 * @param onResult    当joinChannel执行结束后调用这个回调
 * @return
 * - 0: 成功
 * - <0: 失败
 * @note 已废弃
 */
- (int)joinChannel:(AliRtcAuthInfo *_Nonnull)authInfo name:(NSString *_Nullable)userName onResult:(void(^_Nullable)(NSInteger errCode, NSString * _Nonnull channel, NSInteger elapsed))onResult;

/**
 * @brief 加入频道
 * @details 该方法让用户加入频道，一个频道内可以加入多个用户进行互相通话。
 * @details 一般在调用该方法前会根据场景先选择频道模式，通过调用 {@link setChannelProfile:} 实现，默认频道模式为通信模式 {@link AliRtcChannelProfile::AliRtcCommunication}
 * ``` objc
 *   设置频道为互动模式
 * [self.engine setChannelProfile:AliRtcInteractivelive];
 *   设置角色为主播角色
 * [self.engine setClientRole:AliRtcClientRoleInteractive];
 *   加入频道 onResult和onJoinChannelResult均会回调
 * [self.engine joinChannel:authInfo name:name onResult:^(NSInteger errCode, NSString * channel, NSString * userId, NSInteger elapsed){
 *  if (errCode == 0) {
 *       加入频道成功
 *  } else {
 *       加入频道失败
 *  }
 * }];
 * ```
 * @param token       认证信息，从App Server获取。
 * @param channelId   入会频道，必须和产生token时一样；可以不传，此时会默认使用产生token的channelId
 * @param userId      入会的userid，必须和产生token时一样；可以不传，此时会默认使用产生token的userId
 * @param userName    任意用于显示的用户名称，不是User ID；可以不传,标识没有userName
 * @param onResult    当joinChannel执行结束后调用这个回调
 * @return
 * - 0: 成功
 * - 非0: 失败
 *   - 失败原因错误码见回调函数：{@link  onJoinChannelResult:channel:userId:elapsed:}
 *
 * @note
 *    - 该接口异步接口。是否成功入会，通过 {@link onJoinChannelResult:channel:userId:elapsed:} 判断，参数onResult也会回调
 *    - 正常情况一个Appid对应一个App，只有同一个AppId的应用可进行互相童话,不同AppId和channelID不同都不能互通
 *    - 当入会成功后，会触发远端用户收到 {@link onRemoteUserOnLineNotify:elapsed:} 回调
 *    - 如果已在会中想重新入会，需要先调用 {@link leaveChannel} 离会，且确保 {@link onLeaveChannelResult:stats:} 回调收到后，再次调用进行入会
 *    - 如果用户是观众角色，已在会中，可以通过  {@link switchChannel:}  进行快速切换其他房间
 *    - 用户加入频道后，默认订阅频道内所有其他用户的音视频流，默认推送音视频流到远端，因此将会产生计费，如果想要取消默认订阅可以 {@link joinChannel:name:onResultWithUserId:} 前调用 {@link setDefaultSubscribeAllRemoteAudioStreams:} 和 {@link  setDefaultSubscribeAllRemoteVideoStreams:}
 *    - 不同频道中的主播可以通过调用 {@link startChannelRelay:} 实现跨频道通信，可以方便的实现两个不同直播间主播的互通联动
 */
- (int)joinChannel:(NSString *_Nonnull)token channelId:(NSString *_Nullable)channelId userId:(NSString *_Nullable)userId name:(NSString *_Nullable)userName onResultWithUserId:(void(^_Nullable)(NSInteger errCode, NSString * _Nonnull channel, NSString * _Nonnull userId, NSInteger elapsed))onResult;

/**
 * @brief 加入频道
 * @details 该方法让用户加入频道，一个频道内可以加入多个用户进行互相通话。
 * @details 一般在调用该方法前会根据场景先选择频道模式，通过调用 {@link setChannelProfile:} 实现，默认频道模式为通信模式 {@link AliRtcChannelProfile::AliRtcCommunication}
 * ``` objc
 *  设置频道为互动模式
 * [self.engine setChannelProfile:AliRtcInteractivelive];
 *   设置角色为主播角色
 * [self.engine setClientRole:AliRtcClientRoleInteractive];
 *   加入频道 onResult和onJoinChannelResult均会回调
 * [self.engine joinChannel:authInfo name:name onResult:^(NSInteger errCode, NSString * channel, NSString * userId, NSInteger elapsed){
 *  if (errCode == 0) {
 *       加入频道成功
 *  } else {
 *       加入频道失败
 *  }
 * }];
 * ```
 * @param token       认证信息，从App Server获取。
 * @param channelId   入会频道，必须和产生token时一样；可以不传，此时会默认使用产生token的channelId
 * @param userId      入会的userid，必须和产生token时一样；可以不传，此时会默认使用产生token的userId
 * @param userName    任意用于显示的用户名称，不是User ID；可以不传,标识没有userName
 * @param onResult    当joinChannel执行结束后调用这个回调
 * @return
 * - 0: 成功
 * - 非0: 失败
 *   - 失败原因错误码见回调函数：{@link  onJoinChannelResult:channel:userId:elapsed:}
 *
 * @note
 *    - 该接口异步接口。是否成功入会，通过 {@link onJoinChannelResult:channel:userId:elapsed:} 判断，参数onResult也会回调
 *    - 正常情况一个Appid对应一个App，只有同一个AppId的应用可进行互相童话,不同AppId和channelID不同都不能互通
 *    - 当入会成功后，会触发远端用户收到 {@link onRemoteUserOnLineNotify:elapsed:} 回调
 *    - 如果已在会中想重新入会，需要先调用 {@link leaveChannel} 离会，且确保 {@link onLeaveChannelResult:stats:} 回调收到后，再次调用进行入会
 *    - 如果用户是观众角色，已在会中，可以通过  {@link switchChannel:}  进行快速切换其他房间
 *    - 用户加入频道后，默认订阅频道内所有其他用户的音视频流，默认推送音视频流到远端，因此将会产生计费，如果想要取消默认订阅可以 {@link joinChannel:name:onResultWithUserId:} 前调用 {@link setDefaultSubscribeAllRemoteAudioStreams:} 和 {@link  setDefaultSubscribeAllRemoteVideoStreams:}
 *    - 不同频道中的主播可以通过调用 {@link startChannelRelay:} 实现跨频道通信，可以方便的实现两个不同直播间主播的互通联动
 */
- (int)joinChannel:(NSString *_Nonnull)token channelId:(NSString *_Nullable)channelId userId:(NSString *_Nullable)userId name:(NSString *_Nullable)userName onResultWithUserId:(void(^_Nullable)(NSInteger errCode, NSString * _Nonnull channel, NSString * _Nonnull userId, NSInteger elapsed))onResult;

/**
 * @brief 加入频道
 * @details 该方法让用户加入频道，一个频道内可以加入多个用户进行互相通话。
 * @details 一般在调用该方法前会根据场景先选择频道模式，通过调用 {@link setChannelProfile:} 实现，默认频道模式为通信模式 {@link AliRtcChannelProfile::AliRtcCommunication}
 * ``` objc
 * // 设置频道为互动模式
 * [self.engine setChannelProfile:AliRtcInteractivelive];
 * // 设置角色为主播角色
 * [self.engine setClientRole:AliRtcClientRoleInteractive];
 * // 加入频道 onResult和onJoinChannelResult均会回调
 * [self.engine joinChannel:authInfo name:name onResult:^(NSInteger errCode, NSString * channel, NSString * userId, NSInteger elapsed){
 *  if (errCode == 0) {
 *      //加入频道成功
 *  } else {
 *      //加入频道失败
 *  }
 * }];
 * ```
 * @param authInfo    认证信息，从App Server获取。
 * @param userName    任意用于显示的用户名称。不是用户ID
 * @param onResult    当joinChannel执行结束后调用这个回调
 * @return
 * - 0: 成功
 * - 非0: 失败
 *   - 失败原因错误码见回调函数：{@link  onJoinChannelResult:channel:userId:elapsed:}
 *
 * @note
 *    - 该接口异步接口。是否成功入会，通过 {@link onJoinChannelResult:channel:userId:elapsed:} 判断，参数onResult也会回调
 *    - 正常情况一个Appid对应一个App，只有同一个AppId的应用可进行互相童话,不同AppId和channelID不同都不能互通
 *    - 当入会成功后，会触发远端用户收到 {@link onRemoteUserOnLineNotify:elapsed:} 回调
 *    - 如果已在会中想重新入会，需要先调用 {@link leaveChannel} 离会，且确保 {@link onLeaveChannelResult:stats:} 回调收到后，再次调用进行入会
 *    - 如果用户是观众角色，已在会中，可以通过  {@link switchChannel:}  进行快速切换其他房间
 *    - 用户加入频道后，默认订阅频道内所有其他用户的音视频流，默认推送音视频流到远端，因此将会产生计费，如果想要取消默认订阅可以 {@link joinChannel:name:onResultWithUserId:} 前调用 {@link setDefaultSubscribeAllRemoteAudioStreams:} 和 {@link  setDefaultSubscribeAllRemoteVideoStreams:}
 *    - 不同频道中的主播可以通过调用 {@link startChannelRelay:} 实现跨频道通信，可以方便的实现两个不同直播间主播的互通联动
 */
- (int)joinChannel:(AliRtcAuthInfo *_Nonnull)authInfo name:(NSString *_Nullable)userName onResultWithUserId:(void(^_Nullable)(NSInteger errCode, NSString * _Nonnull channel, NSString * _Nonnull userId, NSInteger elapsed))onResult;

/**
 * @brief 加入频道
 * @details 该方法让用户加入频道，一个频道内可以加入多个用户进行互相通话。
 * @details 一般在调用该方法前会根据场景先选择频道模式，通过调用 {@link setChannelProfile:} 实现，默认频道模式为通信模式 {@link AliRtcChannelProfile::AliRtcCommunication}
 * ``` objc
 * // 设置频道为互动模式
 * [self.engine setChannelProfile:AliRtcInteractivelive];
 * // 设置角色为主播角色
 * [self.engine setClientRole:AliRtcClientRoleInteractive];
 * // 加入频道 onResult和onJoinChannelResult均会回调
 * [self.engine joinChannel:authInfo name:name onResult:^(NSInteger errCode, NSString * channel, NSString * userId, NSInteger elapsed){
 *  if (errCode == 0) {
 *      //加入频道成功
 *  } else {
 *      //加入频道失败
 *  }
 * }];
 * ```
 * @param token       认证信息，从App Server获取。
 * @param channelParam   入会参数，详见 {@link AliRtcChannelParam}
 * @param agentParam   入会参数，详见 {@link AliRtcAIAgentParam}
 * @param onResult    当joinChannel执行结束后调用这个回调
 * @return
 * - 0: 成功
 * - 非0: 失败
 *   - 失败原因错误码见回调函数：{@link  onJoinChannelResult:channel:userId:elapsed:}
 *
 * @note
 *    - 该接口异步接口。是否成功入会，通过 {@link onJoinChannelResult:channel:userId:elapsed:} 判断，参数onResult也会回调
 *    - 正常情况一个Appid对应一个App，只有同一个AppId的应用可进行互相童话,不同AppId和channelID不同都不能互通
 *    - 当入会成功后，会触发远端用户收到 {@link onRemoteUserOnLineNotify:elapsed:} 回调
 *    - 如果已在会中想重新入会，需要先调用 {@link leaveChannel} 离会，且确保 {@link onLeaveChannelResult:stats:} 回调收到后，再次调用进行入会
 *    - 如果用户是观众角色，已在会中，可以通过  {@link switchChannel:}  进行快速切换其他房间
 *    - 用户加入频道后，默认订阅频道内所有其他用户的音视频流，默认推送音视频流到远端，因此将会产生计费，如果想要取消默认订阅可以 {@link joinChannel:name:onResultWithUserId:} 前调用 {@link setDefaultSubscribeAllRemoteAudioStreams:} 和 {@link  setDefaultSubscribeAllRemoteVideoStreams:}
 *    - 不同频道中的主播可以通过调用 {@link startChannelRelay:} 实现跨频道通信，可以方便的实现两个不同直播间主播的互通联动
 */

- (int)joinAIChannel:(NSString *_Nonnull)token channelParam:(AliRtcChannelParam *_Nonnull)channelParam agentParam:(AliRtcAIAgentParam* _Nonnull)agentParam onResultWithUserId:(void(^_Nullable)(NSInteger errCode, NSString * _Nonnull channel, NSString * _Nonnull userId, NSInteger elapsed))onResult;

/**
 * @brief 设置自定义参数
 * @param param   自定义参数
 * @return
 * - 0: 成功
 * - 非0: 失败
 */
- (int)setParameter:(NSString * _Nonnull)param;

/**
 * @brief 获取自定义参数
 * @param param   自定义参数
 * @return 参数值 
 */
- (NSString * _Nonnull)getParameter:(NSString * _Nonnull)param;


/**
 * @brief  离开频道
 * @details 调用该方法代表离开频道，即挂断或者停止通话。
 * @details 该方法为异步方法，调用后收到 {@link onLeaveChannelResult:stats:} 代表退出频道完成，同时会触发远端用户收到 {@link onRemoteUserOffLineNotify:offlineReason:}   回调。
 * @details 如果未加入频道入会，{@link leaveChannel} 不会有任何影响。加入频道后，必须要调用该方法离开频道，否则无法加入其他频道。
 * @return
 * - 0: 成功
 * - 非0: 失败
 *   - 失败原因错误码见回调函数：{@link  onLeaveChannelResult:stats:}

 * @note
 *  - 如果调用了 {@link leaveChannel} 后立刻调用 {@link AliRtcEngine::destroy} 方法，SDK将会无法触发 {@link  onLeaveChannelResult:stats:} 回调
 *
 */
- (int)leaveChannel;

/**
 * @brief 切换频道
 * @details 当我们已经在一个频道中想要加入另外一个频道时，通常我们需要离会之后在收到离会回调之后再加入到另外一个频道中，调用方法可以实现快速切换频道。
 * @details 成功调用该方切换频道后，本地会先收到离开原频道的回调 {@link onLeaveChannelResult:stats:} ，再收到成功加入新频道的回调 {@link onJoinChannelResult:channel:userId:elapsed:}.
 * @param authInfo  认证信息，从App Server获取。
 * @return
 * - 0: 成功
 * - 非0: 失败
 *   - {@link AliRtcErrInner}：SDK未初始化或已销毁
 *   - {@link AliRtcErrSdkInvalidState}：当前未加入任何频道或者频道模式和角色不匹配，请确认频道为互动模式，用户角色为观众
 *   - {@link AliRtcErrInvalidArguments}：鉴权信息非法，请确认是否使用同一个authinfo多次加入同一个频道
 *
 * @note 该方法需要在加入一个频道后才可以调用
 * @note 该方法仅在互动模式AliRtcInteractiveLive和观看角色AliRtcClientRoleLive下调用有效
 */
- (int)switchChannel:(AliRtcAuthInfo *_Nonnull)authInfo;

/**
 * @brief 设置频道模式
 * @details 根据业务需求可以配置不同的频道模式，AliRTC会根据不用的频道模式模式采用不用的策略，目前主要提供通信模式(默认)、互动模式、低延迟互动直播模式
 *
 * 【通信模式 AliRtcCommunication】
 *  - 该适用于音视频通话场景，所有加入频道的人都可以推/拉音视频流
 *  - 该模式典型的应用场景：1v1语音聊天、1v1视频聊天、远程问诊、远程面试等
 *
 * 【互动模式 AliRtcInteractivelive】
 *  - 该模式适用于互动场景，在该模式下有主播和观众两种角色，主播、观众角色可以进行切换，可以通过 {@link setClientRole:} 进行设置。
 *    - 主播角色：可以推流、拉流
 *    - 观众角色：只可以拉流
 *  - 该模式典型的应用场景：语聊房、在线教育大班课等
 *
 * 【低延迟互动直播模式 AliRtcInteractiveWithLowLatencyLive】
 *  - 该模式适用于大型直播场景，与互动模式的差别是观众端使用 {@link startLiveStreamingWithAuthInfo:onResult:} 进行拉流
 *  - 该模式典型应用场景：千人大方会、在线直播培训等
 *
 * @param profile 频道模式类型, 详细请参考 {@link AliRtcChannelProfile}
 * @return
 * - 0: 成功
 * - 非0: 失败
 *   - AliRtcErrInner(-1) : SDK未初始化或已销毁
 *
 * @note
 *  - 相同频道内的用户必须使用同一种频道模式
 *  - 该方法只在入会之前调用有效，会议中不可以重新设置，{@link leaveChannel} 后可以重新设置
 */
- (int)setChannelProfile:(AliRtcChannelProfile)profile;

/**
 * @brief 设置互动模式下的用户角色
 * @details 该方法在 ChannelProfile 设置为 {@link AliRtcInteractivelive} 时有效
 * @details 该方法为异步方法，可以在入会前调用，也可以在入会后调用进行用户角色切换，默认角色为：观众角色
 * - 加入频道前，调用该方法，不会触发任何回调，在入会成功后角色自动生效：
 *   - 若设置的角色为主播，入会成功后将会触发一次开始推流动作，远端用户将会触发 {@link onRemoteUserOnLineNotify:elapsed:} 回调
 *     - 注意：是否真正触发推流，与是否设置过允许推流相关，详见：{@link publishLocalVideoStream:} 和 {@link publishLocalAudioStream:}
 *   - 若设置的角色为观众，本地不会推流，远端用户也不会收到相关回调
 * - 加入频道后，调用该方法，当前调用用户将会收到 {@link onUpdateRoleNotifyWithOldRole:newRole:} 回调：
 *   - 从观众变为主播时，将会触发一次开始推流动作，远端用户将会触发 {@link onRemoteUserOnLineNotify:elapsed:} 回调
 *     - 注意：是否真正触发推流，与是否设置过允许推流相关，详见：{@link publishLocalVideoStream:} 和 {@link publishLocalAudioStream:}
 *   - 从主播变为观众时，将会触发本地停止推流，同时远端用户将会触发 {@link onRemoteUserOffLineNotify:offlineReason:} 回调
 *
 * @param role 用户角色类型 {@link AliRtcClientRole}
 * @return
 * - 0: 成功
 * - <0: 失败
 *   - AliRtcErrInner(-1) : SDK未初始化或已销毁
 *
 * @note 只在频道模式为 {@link AliRtcInteractivelive} 下调用有意义，入会前/会议中均可设置
 * @note 加入频道后，调用该方法，需要等 {@link onUpdateRoleNotifyWithOldRole:newRole:} 回调后，才能再次调用有效
 */
- (int)setClientRole:(AliRtcClientRole)role;

/**
 * @brief 获取互动模式下当前用户角色
 * @return AliRtcClientRole 当前用户角色类型
 * @note 只在频道模式为 {@link AliRtcInteractivelive} 下调用有意义
 */
- (AliRtcClientRole)getClientRole;

/**
 * @brief 刷新鉴权信息
 * @details 该方法用于更新鉴权信息 {@link AliRtcAuthInfo} ，主要为了防止鉴权过期，导致推流失败，当我们收到 {@link onAuthInfoWillExpire} 回调时，应用应当更新鉴权信息
 * @param authInfo 鉴权信息
 * @return
 * - 0: 成功
 * - <0: 失败
 */
- (int)refreshAuthInfo:(AliRtcAuthInfo *_Nonnull)authInfo;

/**
 * @brief 刷新鉴权信息
 * @details 主要为了防止鉴权过期，导致推流失败，当我们收到 {@link onAuthInfoWillExpire} 回调时，应用应当更新鉴权信息
 * @param token 认证信息
 * @return
 * - 0: 成功
 * - <0: 失败
 */
- (int)refreshAuthInfoWithToken:(NSString *_Nonnull)token;

#pragma mark - "设置和操作本地的媒体"

/**
 * @brief 设置本地预览显示视图
 * @param viewConfig 本地视频显示属性, 详细见{@link AliVideoCanvas}
 * @param track  只支持{@link AliRtcVideoTrackCamera}和{@link AliRtcVideoTrackScreen}
 * @return
 * - 0 : 成功
 * - < 0 : 失败
 * @note 支持joinChannel之前和之后切换窗口。如果canvas或者{@link AliVideoCanvas::view}为nil，则停止显示。
 *       如果需要重新设置{@link AliVideoCanvas::renderMode}，请保持canvas中其他属性不变，仅修改
 *       {@link AliVideoCanvas::renderMode}。
 *       如果需要重新设置{@link AliVideoCanvas::mirrorMode}，请保持canvas中其他属性不变，仅修改
 *       {@link AliVideoCanvas::mirrorMode}。
 */
- (int)setLocalViewConfig:(AliVideoCanvas *_Nullable)viewConfig forTrack:(AliRtcVideoTrack)track;

/**
 * @brief 开启本地视频预览
 * @return
 * - 0 : 成功
 * - <0 : 失败
 * @note 如果没有调用 {@link setLocalViewConfig:forTrack:} 设置显示的view，则无法预览。
 * 可以在 {@link joinChannel:name:onResultWithUserId:} 之前就开启预览会自动打开摄像头。
 */
- (int)startPreview;

/**
 * @brief 关闭本地视频预览
 * @return
 * - 0 : 成功
 * - < 0 : 失败
 * @note {@link leaveChannel} 会自动停止本地预览；如果没有在推相机流，则会自动关闭摄像头。
 */
- (int)stopPreview;

/**
 * @brief 设置camera采集偏好
 * @param config 偏好设置
 *      - preference: {@link AliRtcCaptureOutputPreference::AliRtcCaptureOutputPreferencePreview} 高清预览，采集优先保证视频预览质量
 *                    {@link AliRtcCaptureOutputPreference::AliRtcCaptureOutputPreferencePerformance} 采集选择最接近推流的分辨率，优先保证设备性能
 *                    {@link AliRtcCaptureOutputPreference::AliRtcCaptureOutputPreferenceAuto} 自动调整采集分辨率
 *      - cameraDirection: 设置采集方向，前置摄像头或后置摄像头
 * @return
 * - 0: 成功
 * - 非0: 失败
 * @note 必须在打开摄像头之前设置，如 {@link AliRtcEngine::startPreview}，{@link AliRtcEngine::joinChannel:name:onResult:} / {@link AliRtcEngine::joinChannel:name:onResultWithUserId:}之前设置
 */
- (int)setCameraCapturerConfiguration:(AliRtcCameraCapturerConfiguration* _Nonnull )config;

/**
 * @brief 是否推送本地视频流
 * @param enabled 是否开启/关闭本地视频流推送
 - YES: 开启视频流推送
 - NO: 关闭视频流推送
 * @return
 - 0: 设置成功
 - <0: 设置失败，返回错误码
 * @note SDK默认设置推送视频流，在加入频道前也可以调用此接口修改默认值，并在加入频道成功时生效
 */
- (int)publishLocalVideoStream:(BOOL)enabled;

/**
 * @brief 禁用或启用本地视频采集
 * @param enabled
 * - YES : 启用本地视频采集
 * - NO : 禁用本地视频采集
 * @return
 * - 0 : 成功
 * - < 0 : 失败
 * @note 默认为开启状态, 通过监听{@link #onUserVideoEnabled:videoEnabled: }获取用法是否禁用或启用本地视频采集状态。
 */
- (int)enableLocalVideo:(BOOL)enabled;

/**
 * @brief 停止/恢复本地视频数据发送
 * @param mute  YES表示视频数据发送黑帧；NO表示恢复正常
 * @param track  只支持{@link AliRtcVideoTrackCamera}
 * @return 
 * - 0: 表示Success
 * - 非0: 表示Failure
 * @note 发送黑色的视频帧。采集，编码，发送模块仍然工作，
 *       只是视频内容是黑色帧
 */
- (int)muteLocalCamera:(BOOL)mute forTrack:(AliRtcVideoTrack)track;

/**
 * @brief 停止/恢复本地摄像头采集
 * @param enabled  NO表示关闭摄像头采集，YES表示开启摄像头采集
 * @return
 * - 0: 表示Success
 * - 非0: 表示Failure
 * @note 关闭摄像头后，发送黑色的视频帧。编码，发送模块仍然工作，
 *       只是视频内容是黑色帧
 */
- (int)enableVideoCapture:(BOOL)enabled;

/**
 * @brief 设置相机流视频编码属性
 * @details 该方法用于设置相机流视频编码属性对应的视频参数，如分辨率、帧率、码率、视频方向等 所有设置的参数都有相应的范围限制，如果设置的参数不在有效范围内，SDK会自动调节
 * @param config 预定义的编码属性，详见{@link AliRtcVideoEncoderConfiguration}
 * @return 0成功，其他失败，可能是参数不对
 * @note
 * - 该方法在入会前和入会后都可以调用，如果每次入会只需要设置一次相机流视频编码属性，建议在入会前调用
*/
- (int)setVideoEncoderConfiguration:(AliRtcVideoEncoderConfiguration* _Nullable)config;

/**
 * @brief 设置相机流视频解码属性
 * @details 该方法用于设置相机流视频解码属性对应的视频参数，如果设置的参数不在有效范围内，SDK会自动调节
 * @param config 预定义的解码属性，详见 {@link AliRtcVideoDecoderConfiguration}
 * @note
 * - 该方法建议在入会前调用
*/
- (void)setVideoDecoderConfiguration:(AliRtcVideoDecoderConfiguration* _Nonnull)config;


/**
 * @brief 设置屏幕流视频编码属性
 * @details 该方法用于设置屏幕流视频编码属性对应的视频参数，如分辨率、帧率、码率、视频方向等 所有设置的参数都有相应的范围限制，如果设置的参数不在有效范围内，SDK会自动调节
 * @param config 预定义的屏幕共享编码属性，详见{@link AliRtcScreenShareEncoderConfiguration}
 * @note
 * - 该方法在入会前和入会后都可以调用，如果每次入会只需要设置一次屏幕流视频编码属性，建议在入会前调用
*/
- (void)setScreenShareEncoderConfiguration:(AliRtcScreenShareEncoderConfiguration* _Nullable)config;

/**
 * @brief 停止/恢复本地音频数据发送
 * @param mute
 * - YES: 本地音频发送空帧
 * - NO: 恢复正常音频数据发送
 * @return
 * - 0: 成功
 * - 非0: 失败
 * @note mute是指音频流发送静音帧，采集和编码模块仍然在工作。
 */
- (int)muteLocalMic:(BOOL)mute mode:(AliRtcMuteLocalAudioMode)mode;

/**
 * @brief 是否推送音频流
 * @param enabled 是否开启/关闭本地音频流推流
 * - YES: 开启音频流推送
 * - NO: 关闭音频流推送
 * @return
 * - 0: 设置成功
 * - <0: 设置失败
 *  - AliRtcErrInner: SDK内部状态错误，需检查是否创建SDK实例成功
 *
 * @note
 * - SDK默认设置推送音频流，加入频道前调用此接口设置推送音频流，将在加入频道成功时生效，加入频道成功后可以随时调用此接口开启/关闭音频流推送
 * - 若当前频道模式为 {@link AliRtcInteractivelive} 模式，只有用户角色为 {@link AliRtcClientRoleInteractive} 时SDK才会允许推送视频流，因此该模式下调用此接口设置推流时，需要同时配合调用接口 {@link AliRtcEngine::setClientRole:} 更改角色
 * - 本地音频流内容默认为麦克风采集音频，如需自定义输入音频推送内容，可参考接口 {@link AliRtcEngine::addExternalAudioStream:AliRtcExternalAudioStreamConfig:} 使用外部音频输入替换麦克风采集
 * - 本地音频推流结果发生变化时，SDK会触发 {@link AliRtcEngineDelegate:onAudioPublishStateChanged:newState:elapseSinceLastState:channel:} 回调通知音频推流最新状态
 */
- (int)publishLocalAudioStream:(BOOL)enabled;

/**
 * @brief 是否推送第二条音频流
 * @param enabled 是否开启/关闭推送第二条音频流
 * - YES: 开启第二条音频流推送
 * - NO: 关闭第二条音频流推送
 * @return
 * - 0: 设置成功
 * - <0: 设置失败
 *  - AliRtcErrInner: SDK内部状态错误，需检查是否创建SDK实例成功
 *
 * @note
 * - SDK默认设置不会推送第二条音频流，加入频道前调用此接口设置是否推送第二条音频流，将在加入频道成功时生效，加入频道成功后可以随时调用此接口开启/关闭第二条音频流推送
 * - 若当前频道模式为 {@link AliRtcInteractivelive} 模式，只有用户角色为 {@link AliRtcClientRoleInteractive} 时SDK才会允许推送第二条视频流，因此该模式下调用此接口设置推流时，需要同时配合调用接口 {@link AliRtcEngine::setClientRole:} 更改角色
 * - 第二条音频流内容，需要设置自定义输入音频推送内容，可参考接口 {@link AliRtcEngine::addExternalAudioStream:AliRtcExternalAudioStreamConfig:} 使用外部音频输入
 * - 本地音频推流结果发生变化时，SDK会触发 {@link AliRtcEngineDelegate:onAudioPublishStateChanged:newState:elapseSinceLastState:channel:} 回调通知音频推流最新状态
 */
- (int)publishLocalDualAudioStream:(BOOL)enabled;

/**
 * @brief 设置预览和推流镜像能力
 * @param mirrorMode 设置镜像的模式
 * @return
 * - 0: 设置成功
 * - <0: 设置失败
 *  - AliRtcErrInner: SDK内部状态错误，需检查是否创建SDK实例成功
 *
 * @note
 * - 此接口在入会前和入会后均可以动态设置，SDK内部会记录状态，并在可以操作预览及编码的时候对视频进行操作；
 * - 使用此接口的优先级会高于setLocalViewConfig&setVideoEncoderConfig
 * - 此接口与setLocalViewConfig&setVideoEncoderConfig里面的mirror重合，使用时只要使用其中一个即可
 */
- (int)setVideoMirrorMode:(AliRtcVideoPipelineMirrorMode)mirrorMode;

/**
 * @brief 根据RtsUrl推流，目前同时只支持推一路流
 * @param rtsUrl rts url，不携带roomserver信息
 * @return 
 * - 0: 成功
 * - 非0: 失败
 * @note 该接口用于推送本地音视频流到指定的rts url
 */
- (int)publishStreamByRtsUrl:(NSString *_Nonnull)rtsUrl;

/**
 * @brief 根据RtsUrl停止推流
 * @param rtsUrl rts url，不携带roomserver信息
 * @return 
 * - 0: 成功
 * - 非0: 失败
 * @note 该接口用于停止推送本地音视频流
 */
- (int)stopPublishStreamByRtsUrl:(NSString *_Nonnull)rtsUrl;

/**
 * @brief 根据RtsUrl拉流，目前同时只支持拉一路流
 * @param rtsUrl rts url，不携带roomserver信息
 * @param uid 用户id，由调用者指定，并且需要保持唯一性
 * @return 
 * - 0: 成功
 * - 非0: 失败
 * @note 该接口用于推送本地音视频流到指定的rts url
 */
- (int)subscribeStreamByRtsUrl:(NSString *_Nonnull)rtsUrl uid:(NSString *_Nonnull)uid;

/**
 * @brief 根据RtsUrl停止拉流
 * @param rtsUrl rts url，不携带roomserver信息
 * @return 
 * - 0: 成功
 * - 非0: 失败
 * @note 该接口用于停止拉取音视频流
 */
- (int)stopSubscribeStreamByRtsUserId:(NSString *_Nonnull)uid;

/**
 * @brief 根据uid，暂停从服务端订阅RTS流
 * @param uid 用户id，由调用者指定，并且需要保持唯一性
 * @return
 * - 0: 成功
 * - 非0: 失败
 */
- (int)pauseRtsStreamByRtsUserId:(NSString *_Nonnull)uid;

/**
 * @brief 根据uid，恢复从服务端订阅RTS流
 * @param uid 用户id，由调用者指定，并且需要保持唯一性
 * @return
 * - 0: 成功
 * - 非0: 失败
 */
- (int)resumeRtsStreamByRtsUserId:(NSString *_Nonnull)uid;

/**
 *@brief 设置采集缩放时机，视频数据是采集的时候立即缩放还是编码时才进行缩放。
 *@param mode 控制采集缩放时机的模式，默认是采集的时候立即缩放
 *@note 必须在打开摄像头之前设置，如 {@link AliRtcEngine::startPreview}，{@link AliRtcEngine::joinChannel:name:onResult:} / {@link AliRtcEngine::joinChannel:name:onResultWithUserId:}之前设置
 */
-(void)setCapturePipelineScaleMode:(AliRtcCapturePipelineScaleMode)mode;

/**
 * @brief 根据桌面Id进行屏幕分享
 * @param desktopId 桌面Id(可通过GetScreenShareSourceInfo接口获取)
 * @param config 屏幕分享配置，详见 {@link AliRtcScreenShareConfig}
 * @return
 *  - 0: 设置成功
 *  - <0: 设置失败，返回错误码
*/
- (int)startScreenShareWithDesktopId:(int)desktopId config:(AliRtcScreenShareConfig * _Nonnull)config;

/**
 * @brief 根据窗口id进行屏幕分享
 * @param windowId 窗口id(可通过GetScreenShareSourceInfo接口获取)
 * @param config 屏幕分享配置，详见 {@link AliRtcScreenShareConfig}
 * @return
 *  - 0: 设置成功
 *  - <0: 设置失败，返回错误码
*/
- (int)startScreenShareWithWindowId:(int)windowId config:(AliRtcScreenShareConfig * _Nonnull)config;

/**
 * @brief 停止屏幕分享
 * @return
 *  - 0: 设置成功
 *  - <0: 设置失败，返回错误码
*/
- (int)stopScreenShare;

/**
 * @brief 更新屏幕分享配置
 * @param config 屏幕分享配置，详见 {@link AliRtcScreenShareConfig}
 * @return
 *  - 0: 设置成功
 *  - <0: 设置失败，返回错误码
*/
- (int)updateScreenShareConfig:(AliRtcScreenShareConfig * _Nonnull)config;

/**
 * @brief 获取屏幕分享源信息
 * @param type 屏幕分享类型，详见 {@link AliRtcScreenShareType}
 * @return 返回屏幕共享源列表
 */
- (NSArray<AliRtcScreenSourceInfo *> * _Nullable)getScreenShareSourceInfoWithType:(AliRtcScreenShareType)type;


#pragma mark - "操作来自远端的媒体"

/**
 * @brief 设置远端视频显示视图
 * @param canvas 本地视频显示属性, 详细见{@link AliVideoCanvas}
 * @param uid User ID，从App server分配的唯一标示符
 * @param track  只支持{@link AliRtcVideoTrack::AliRtcVideoTrackCamera}和{@link AliRtcVideoTrack::AliRtcVideoTrackScreen}
 * @return
 * - 0 : 成功
 * - < 0 : 失败
 * @note 支持joinChannel之前和之后切换窗口。如果canvas或者{@link AliVideoCanvas::view}为nil，则停止显示
 *       如果需要重新设置{@link AliVideoCanvas::renderMode}，请保持canvas中其他属性不变，仅修改
 *       {@link AliVideoCanvas::renderMode}
 *       如果需要重新设置{@link AliVideoCanvas::mirrorMode}，请保持canvas中其他属性不变，仅修改
 *       {@link AliVideoCanvas::mirrorMode}
 */
- (int)setRemoteViewConfig:(AliVideoCanvas *_Nonnull)canvas uid:(NSString *_Nonnull)uid forTrack:(AliRtcVideoTrack)track;


/**
 * @brief 调节本地播放的指定远端用户音量
 * @param uid 用户ID，从App server分配的唯一标示符
 * @param volume 播放音量，取值范围[0,100] 0：静音；100：原始音量
 * @return
 * - 0: 成功
 * - 非0: 失败
 */
- (int)setRemoteAudioVolume:(NSString *_Nonnull)uid volume:(NSInteger)volume;

/**
 * @brief 停止/恢复远端指定用户的音频流的播放
 * @param uid  用户ID , 从App server分配的唯一标示符
 * @param mute YES表示停止播放; NO表示恢复播放
 * @return
 * - 0: 成功
 * - 非0: 失败
 * @note 拉流和解码不受影响, 支持joinChannel之前和之后设置
 */
- (int)muteRemoteAudioPlaying:(NSString *_Nonnull)uid mute:(BOOL)mute;


/**
 * @brief 停止/恢复远端的所有音频流的播放
 * @param mute YES表示停止播放；NO表示恢复播放
 * @return
 * - 0: 成功
 * - 非0: 失败
 * @note 拉流和解码不受影响, 支持joinChannel之前和之后设置
 */
- (int)muteAllRemoteAudioPlaying:(BOOL)mute;

#pragma mark - "用户管理"

/**
 * @brief 查询是否设置推送视频流
 * @return
 - YES: 已设置推送
 - NO: 未设置推送
 * @note SDK默认设置推送视频流，如果需要取消推送视频流，可以通过{@link publishLocalVideoStream}方法设置为不推送
 */
- (BOOL)isLocalVideoStreamPublished;

/**
 * @brief 查询是否设置推送屏幕分享
 * @return
 - YES: 已设置推送
 - NO: 未设置推送
 * @note SDK默认设置不推送屏幕分享，如果需要推送屏幕共享，可以通过{@link startScreenShareWithDesktopId} 或 {@link startScreenShareWithWindowId}方法开启屏幕共享推送
 */
- (BOOL)isScreenSharePublished;

/**
 * @brief 查询是否设置推送音频流
 * @return
 - YES: 已设置推送
 - NO: 未设置推送
 * @note SDK默认设置推送音频流，如果需要取消推送音频流，可以通过 {@link publishLocalAudioStream} 方法设置为不推送
 */
- (BOOL)isLocalAudioStreamPublished;

- (BOOL)isLocalDualAudioStreamPublished;

/**
 * @brief 是否推送次要视频流
 * @param enabled 是否开启/关闭次要视频流推送
 - YES: 开启次要视频流推送
 - NO: 关闭次要视频流推送
 * @return
 - 0: 设置成功
 - <0: 设置失败，返回错误码
 * @note 次要视频流只在推送视频流的前提下才会推送，设置推送次要视频流时，请确认已通过 {@link publishLocalVideoStream} 方法开启视频流推送
 * @note SDK默认设置不推送次要视频流，在加入频道前也可以调用此接口修改默认值，并在推送视频流时生效
 */
- (int)publishLocalDualStream:(BOOL)enabled;

/**
 * @brief 查询是否设置推送次要流
 * @return
 - YES: 已设置推送
 - NO: 未设置推送
 * @note SDK默认设置不推送次要视频流，如果需要推送次要视频流，可以通过接口 {@link publishLocalDualStream} 方法设置为推送
 */
- (BOOL)isDualStreamPublished;

/**
 * @brief 设置订阅相机流格式，大流或小流
 * @param uid  userId，从App server分配的唯一标示符
 * @param streamType 流类型
 * - AliRtcVideoStreamTypeNone:无效参数，设置不会有任何效果
 * - AliRtcVideoStreamTypeHigh:大流
 * - AliRtcVideoStreamTypeLow:小流
 * @return
 * - 0:设置成功
 * - <0:设置失败
 * @note 推流端当前默认不推送小流，只有发送端调用了 {@link publishLocalDualStream:} 打开双流模式，接收端才可以选择订阅大流还是小流，否则订阅的只能是大流；
 */
- (int)setRemoteVideoStreamType:(NSString *_Nonnull)uid type:(AliRtcVideoStreamType)streamType;


/**
 * @brief 设置默认订阅的相机流格式，大流或小流；如果不设置，则默认订阅大流；
 * @param streamType 流类型
 * - AliRtcVideoStreamTypeNone:无效参数，设置不会有任何效果
 * - AliRtcVideoStreamTypeHigh:(Default)大流
 * - AliRtcVideoStreamTypeLow:小流
 * @return
 * - 0:设置成功
 * - <0:设置失败
 */
- (int)setRemoteDefaultVideoStreamType:(AliRtcVideoStreamType)streamType;

/**
 * @brief 停止/恢复订阅所有远端音频流
 * @param sub 是否订阅所有远端音频流
 * - YES:订阅所有用户的音频流
 * - NO:停止订阅所有用户的音频流
 * @return
 * - 0:设置成功
 * - <0:设置失败
 * @note
 * - 入会前入会后均可以调用；
 * - 如果设置了 subscribeAllRemoteAudioStreams:NO，后面调用 {@link setDefaultSubscribeAllRemoteAudioStreams:} 和 {@link subscribeRemoteAudioStream:sub:} 都不会生效；
 */
- (int)subscribeAllRemoteAudioStreams:(BOOL)sub;

- (int)subscribeAllRemoteDualAudioStreams:(BOOL)sub;

/**
 * @brief 停止/恢复订阅所有远端视频流
 * @param sub 是否订阅所有远端视频流
 * - YES:订阅所有用户的视频流
 * - NO:停止订阅所有用户的视频流
 * @return
 * - 0:设置成功
 * - <0:设置失败
 * @note
 * - 入会前入会后均可以调用
 * - 如果设置了 subscribeAllRemoteVideoStreams:NO，后面调用 {@link setDefaultSubscribeAllRemoteVideoStreams:} 和 {@link subscribeRemoteVideoStream:track:sub:} 都不会生效；
 */
- (int)subscribeAllRemoteVideoStreams:(BOOL)sub;

/**
 * @brief 停止/恢复订阅特定远端用户的音频流
 * @param uid userId，从App server分配的唯一标示符
 * @param sub 是否订阅远端用户的音频流
 * - YES:订阅指定用户的音频流
 * - NO:停止订阅指定用户的音频流
 * @return
 * - 0:设置成功
 * - <0:设置失败
 * @note
 * - 如果之前有调用过 {@link subscribeAllRemoteAudioStreams:} 停止订阅所有远端音频，则此接口调用无效；
 * - {@link subscribeAllRemoteAudioStreams:} 是全局控制，subscribeRemoteAudioStream 是单独控制。
 */
- (int)subscribeRemoteAudioStream:(NSString *_Nonnull)uid sub:(BOOL)sub;

/**
 * @brief 停止/恢复订阅特定远端用户的音频流
 * @param uid 用户ID，从App server分配的唯一标示符
 * @param track 视频流类型
 * - AliEngineAudioTrackNo: 无效参数，设置不会有任何效果
 * - AliEngineAudioTrackMic: 麦克风流
 * - AliEngineAudioTrackDual: 第二条音频流
 * - AliEngineAudioTrackBoth: 麦克风流和第二条音频流
 * @param sub 是否订阅远端用户的音频流
 * - true:订阅指定用户的音频流
 * - false:停止订阅指定用户的音频流
 * @return
 * - 0: 成功
 * - 非0: 失败
 * @note
 * - 如果之前有调用过 AliEngine::SubscribeAllRemoteAudioStreams(false) 停止订阅所有远端音频，则此接口调用无效；
 * - {@link AliEngine::SubscribeAllRemoteAudioStreams} 是全局控制，SubscribeRemoteAudioStream 是单独控制。
 */
- (int)subscribeRemoteAudioStream:(NSString *_Nonnull)uid track:(AliRtcAudioTrack)track sub:(BOOL)sub;

/**
 * @brief 停止/恢复订阅远端用户的视频流
 * @param uid userId，从App server分配的唯一标示符
 * @param track 视频流类型
 * - AliRtcVideoTrackNo:无效参数，设置不会有任何效果
 * - AliRtcVideoTrackCamera:相机流
 * - AliRtcVideoTrackScreen:屏幕共享流
 * - AliRtcVideoTrackBoth:相机流和屏幕共享流
 * @param sub 是否订阅远端用户的视频流
 * - YES:订阅指定用户的视频流
 * - NO:停止订阅指定用户的视频流
 * @return
 * - 0:设置成功
 * - <0:设置失败
 * @note
 * - 如果之前有调用过 {@link subscribeAllRemoteVideoStreams:} 停止订阅所有远端视频，则此接口调用无效；
 * - {@link subscribeAllRemoteVideoStreams:} 是全局控制，SubscribeRemoteVideoStream 是单独控制。
 */
- (int)subscribeRemoteVideoStream:(NSString *_Nonnull)uid track:(AliRtcVideoTrack)track sub:(BOOL)sub;

/**
 * @brief 停止/恢复订阅远端用户的音视频流
 * @param uid 用户ID，从App server分配的唯一标示符
 * @param videoTrack 视频流类型
 * - {@link AliRtcVideoTrackNo} : 无效参数，设置不会有任何效果
 * - {@link AliRtcVideoTrackCamera} : 相机流
 * - {@link AliRtcVideoTrackScreen} : 屏幕共享流
 * - {@link AliRtcVideoTrackBoth} : 相机流和屏幕共享流
 * @param subVideo 是否订阅远端用户的视频流
 * - YES:订阅指定用户的视频流
 * - NO:停止订阅指定用户的视频流
 * @param subAudio 是否订阅远端用户的音频流
 * - YES:订阅指定用户的音频流
 * - NO:停止订阅指定用户的音频流
 * @return
 * - 0:设置成功
 * - <0:设置失败
 *   - {@link AliRtcErrInner} :
 *     - SDK内部状态错误，需检查是否创建SDK实例成功
 *     - 音视频订阅禁止，请检查是否调用了subscribeAllRemoteVideoStreams:NO或者subscribeRemoteAudioStream:NO
 */
- (int)subscribeRemoteMediaStream:(NSString *_Nonnull)uid videoTrack:(AliRtcVideoTrack)videoTrack subVideo:(BOOL)subVideo subAudio:(BOOL)subAudio;

/**
 * @brief 停止/恢复订阅远端用户的音视频流
 * @param uid 用户ID，从App server分配的唯一标示符
 * @param videoTrack 视频流类型
 * - {@link AliRtcVideoTrackNo} : 无效参数，设置不会有任何效果
 * - {@link AliRtcVideoTrackCamera} : 相机流
 * - {@link AliRtcVideoTrackScreen} : 屏幕共享流
 * - {@link AliRtcVideoTrackBoth} : 相机流和屏幕共享流
 * @param subVideo 是否订阅远端用户的视频流
 * - true:订阅指定用户的视频流
 * - false:停止订阅指定用户的视频流
 * @param audioTrack 音频流类型
 * - AliRtcAudioTrackNo: 无效参数，设置不会有任何效果
 * - AliRtcAudioTrackMic: 麦克风流
 * - AliRtcAudioTrackDual: 第二条音频流
 * - AliRtcAudioTrackBoth: 麦克风流和第二条音频流
 * @param subAudio 是否订阅远端用户的音频流
 * - true:订阅指定用户的音频流
 * - false:停止订阅指定用户的音频流
 * @return
 * - 0:设置成功
 * - <0:设置失败
 * @note
 * - 这个接口标识当前的操作的流是，之前已设置的流不会发生变化
 */
- (int)subscribeRemoteMediaStream:(NSString *_Nonnull)uid videoTrack:(AliRtcVideoTrack)videoTrack subVideo:(BOOL)subVideo audioTrack:(AliRtcAudioTrack)audioTrack subAudio:(BOOL)subAudio;

/**
 * @brief 停止/恢复订阅远端用户的音视频流
 * @param uid 用户ID，从App server分配的唯一标示符
 * @param videoTrack 视频流类型
 * - {@link AliRtcVideoTrackNo} : 无效参数，设置不会有任何效果
 * - {@link AliRtcVideoTrackCamera} : 相机流
 * - {@link AliRtcVideoTrackScreen} : 屏幕共享流
 * - {@link AliRtcVideoTrackBoth} : 相机流和屏幕共享流
 * @param subVideo 是否订阅远端用户的视频流
 * - true:订阅指定用户的视频流
 * - false:停止订阅指定用户的视频流
 * @param audioTrack 音频流类型
 * - AliRtcAudioTrackNo: 无效参数，设置不会有任何效果
 * - AliRtcAudioTrackMic: 麦克风流
 * - AliRtcAudioTrackDual: 第二条音频流
 * - AliRtcAudioTrackBoth: 麦克风流和第二条音频流
 * @param subAudio 是否订阅远端用户的音频流
 * - true:订阅指定用户的音频流
 * - false:停止订阅指定用户的音频流
 * @return
 * - 0:设置成功
 * - <0:设置失败
 * @note
 * - 这个接口通过videoTrack、audioTrack通过一个接口把想要的状态告知SDK
 */
- (int)subscribeRemoteMediaStream:(NSString *_Nonnull)uid videoTrack:(AliRtcVideoTrack)videoTrack audioTrack:(AliRtcAudioTrack)audioTrack;

/**
 * @brief 订阅目标频道，指定用户的流
 * @param channelId 目标频道
 * @param uid 用户ID，从App server分配的唯一标示符
 * @param track 订阅的视频流类型
 * @param subAudio 是否订阅远端用户的音频流
 * - true:订阅目标频道用户的音频流
 * - false:停止订阅目标频道用户的音频流
 * @param sub 是否订阅远端频道用户的流
 * - true:订阅目标频道用户的流
 * - false:停止订阅目标频道用户的流
 * @return
 * - 0: 成功
 * - 非0: 失败
 */
- (int)subscribeRemoteDestChannelStream:(NSString *_Nonnull)channelId uid:(NSString *_Nonnull)uid track:(AliRtcVideoTrack)track subAudio:(BOOL)subAudio sub:(BOOL)sub;


/**
 * @brief 订阅目标频道，指定用户的流
 * @param channelId 目标频道
 * @param uid 用户ID，从App server分配的唯一标示符
 * @param videotrack 订阅的视频流类型
 * @param audioTrack 音频流类型
 * - AliRtcAudioTrackNo: 无效参数，设置不会有任何效果
 * - AliRtcAudioTrackMic: 麦克风流
 * - AliRtcAudioTrackDual: 第二条音频流
 * - AliRtcAudioTrackBoth: 麦克风流和第二条音频流
 * @param sub 是否订阅远端用户的流
 * - true:订阅指定用户的流
 * - false:停止订阅指定用户的流
 * @return
 * - 0: 成功
 * - 非0: 失败
 */
- (int)subscribeRemoteDestChannelStream:(NSString *_Nonnull)channelId uid:(NSString *_Nonnull)uid videoTrack:(AliRtcVideoTrack)videoTrack audioTrack:(AliRtcAudioTrack)audioTrack sub:(BOOL)sub;

/**
 * @brief 订阅目标频道，所有用户的流
 * @param channelId 目标频道
 * @param track 订阅的视频流类型
 * @param sub_audio 是否订阅远端用户的音频流
 * - true:订阅指定用户的音频流
 * - false:停止订阅指定用户的音频流
 * @param sub 是否订阅远端用户的流
 * - true:订阅指定用户的流
 * - false:停止订阅指定用户的流
 * @return
 * - 0: 成功
 * - 非0: 失败
 */
- (int)subscribeRemoteDestChannelAllStream:(NSString *_Nonnull)channelId track:(AliRtcVideoTrack)track subAudio:(BOOL)subAudio sub:(BOOL)sub;

/**
 * @brief 设置是否默认订阅音频流
 * @param sub 是否默认订阅音频流
 * - YES:(Default)默认订阅音频流，
 * - NO:默认不订阅音频流
 * @return
 * - 0:设置成功
 * - <0:设置失败
 * @note
 * - 入会前入会后均可调用；
 * - 如果在加入频道前调用 setDefaultSubscribeAllRemoteAudioStreams:NO，则入会后默认不再订阅任何音频流；
 * - 如果在加入频道后调用 setDefaultSubscribeAllRemoteAudioStreams:NO，默认不再订阅设置后加入频道的用户的音频流；
 * - 不管是否默认订阅，都可以调用 {@link subscribeRemoteAudioStream:sub:}，对指定的用户进行订阅或取消订阅操作；
 * - 订阅行为统一受到 {@link subscribeAllRemoteAudioStreams:} 这个总开关控制，假设 {@link subscribeAllRemoteAudioStreams:} 设置为NO，则订阅全部关闭，其他启动行为全部不生效；
 */
- (int)setDefaultSubscribeAllRemoteAudioStreams:(BOOL)sub;

/**
 * @brief 设置是否默认订阅视频流
 * @param sub 是否默认订阅视频流
 * - YES:(Default)默认订阅视频流
 * - NO:默认不订阅视频流
 * @return
 * - 0:设置成功
 * - <0:设置失败
 * @note
 * - 入会前入会后均可调用；
 * - 如果在加入频道前调用 setDefaultSubscribeAllRemoteVideoStreams:NO，则入会后默认不再订阅任何视频流；
 * - 如果在加入频道后调用 setDefaultSubscribeAllRemoteVideoStreams:NO，默认不再订阅设置后加入频道的用户的视频流；
 * - 不管是否默认订阅，都可以调用 {@link subscribeRemoteVideoStream:track:sub:}，对指定的用户进行订阅或取消订阅操作；
 * - 订阅行为统一受到 {@link subscribeAllRemoteVideoStreams:} 这个总开关控制，假设 {@link subscribeAllRemoteVideoStreams:} 设置为NO，则订阅全部关闭，其他启动行为全部不生效；
 */
- (int)setDefaultSubscribeAllRemoteVideoStreams:(BOOL)sub;

/**
 * @brief 获取远端在线用户列表
 * @return 当前频道内所有在线用户userid列表
 * @note 若当前频道ChannelProfile设置为 {@link AliRtcInteractivelive} 模式，只有设置角色为 {@link AliRtcClientRoleInteractive} 的用户为在线用户，本方法不返回角色为 {@link AliRtcClientRoleLive} 的用户
 */
- (NSArray<NSString *> *_Nullable)getOnlineRemoteUsers;

/**
 * @brief 查询用户是否在线
 * @param uid 用户ID，从App server分配的唯一标示符。不可为NULL
 * @return 
 *  - YES，用户在线
 *  - NO，用户不在线
 * @note 根据特定的UserID，查询该用户是否在线。
 */
- (BOOL)isUserOnline:(NSString *_Nonnull)uid;

/**
 * @brief 获取当前网络链接状态
 * @return 当前链接状态, 参考 {@link AliRtcConnectionStatus}
 * @note 网络链接状态发生变化时，SDK会通过 {@link onConnectionStatusChange:reason:} 回调通知
 * @note 入会前调用此接口，均返回状态 {@link AliRtcConnectionStatusDisconnected}
 */
- (AliRtcConnectionStatus)getCurrentConnectionStatus;


#pragma mark - "设备管理"

/**
 * @brief 获取系统中的录音设备列表
 */
- (NSArray<AliRtcDeviceInfo *> *_Nullable)getAudioCaptures;

/**
 * @brief 获取使用的录音设备名称
 */
- (NSString *_Nullable)getCurrentAudioCapture;

/**
 * @brief 获取使用的录音设备ID
 */
- (NSString *_Nullable)getCurrentAudioCaptureID;

/**
 * @brief 选择录音设备(Name)
 * @param capture  音频采集设备名称
 */
- (void)setCurrentAudioCapture:(NSString *_Nonnull)capture;

/**
 * @brief 选择录音设备(ID)
 * @param captureID  音频采集设备Id
 */
- (void)setCurrentAudioCaptureWithID:(NSString *_Nonnull)captureID;

/**
 * @brief 获取系统中的扬声器列表
 */
- (NSArray<AliRtcDeviceInfo *> *_Nullable)getAudioRenderers;

/**
 * @brief 获取当前使用的扬声器名称
 */
- (NSString *_Nullable)getCurrentAudioRenderer;

/**
 * @brief 获取当前使用的扬声器ID
 */
- (NSString *_Nullable)getCurrentAudioRendererID;

/**
 * @brief 选择扬声器(Name)
 * @param renderer  音频播放设备名称
 */
- (void)setCurrentAudioRenderer:(NSString *_Nonnull)renderer;

/**
 * @brief 选择扬声器(ID)
 * @param rendererID  音频播放设备id
 */
- (void)setCurrentAudioRendererWithID:(NSString *_Nonnull)rendererID;

/**
 * @brief 获取摄像头列表
 * @return 找到的系统中摄像头名称列表
 */
- (NSArray<AliRtcDeviceInfo *> *_Nullable)getCameraList;

/**
 * @brief 获取当前使用的摄像头名称
 */
- (NSString *_Nullable)getCurrentCamera;

/**
 * @brief 获取当前使用的摄像头ID
 */
- (NSString *_Nullable)getCurrentCameraID;

/**
 * @brief 选择摄像头(Name)
 * @param camera   摄像头名称
 */
- (void)setCurrentCamera:(NSString *_Nonnull)camera;

/**
 * @brief 选择摄像头(ID)
 * @param cameraID   摄像头ID
 */
- (void)setCurrentCameraWithID:(NSString *_Nonnull)cameraID;

/**
 * @brief 开启音频采集
 * @details 此接口可以控制提前打开音频采集，如果不设置，则SDK会自动控制音频采集设备：
 * - 如果打开推送音频流 {@link publishLocalAudioStream:}，SDK在入会后会打开音频采集
 * - 如果关闭推送音频流 {@link publishLocalAudioStream:}，SDK在入会后不会打开音频采集
 *
 * @note 
 * - 调用此接口后，离会后采集设备保持开启状态
 */
- (void)startAudioCapture;

/**
 * @brief 开启音频采集
 * @details 此接口可以控制提前打开音频采集，如果不设置，则SDK会自动控制音频采集设备：
 * - 如果打开推送音频流 {@link publishLocalAudioStream:}，SDK在入会后会打开音频采集
 * - 如果关闭推送音频流 {@link publishLocalAudioStream:}，SDK在入会后不会打开音频采集
 * @deprecated keepAlive 参数废弃无效 建议参考 {@link setAudioCapability:} 接口
 * @param keepAlive YES: 离会后采集设备保持开启状态；NO: 离会后采集设备关闭
 */
- (void)startAudioCapture:(BOOL)keepAlive;

/**
 * @brief 关闭音频采集
 * @note 调用此接口后，入会后、离会再入会，采集设备保持关闭状态
 */
- (void)stopAudioCapture;

/**
 * @brief 通话前，开启音频采集设备检测
 * @details 此接口可以控制打开音频采集
 * - 通过{@link onTestAudioVolumeCallback}判断采集是否正常
 * @note 只能入会前{@link joinChannel}调用此接口
 */
- (void)startAudioCaptureTest;

/**
 * @brief 关闭音频采集检测
 * @note 只能入会前{@link joinChannel}调用此接口
 */
- (void)stopAudioCaptureTest;

/**
 * @brief 开启音频播放
 * @note 此接口可以控制提前打开音频播放，如果不设置，则SDK会在订阅到音频流后自动打开音频播放
 */
- (void)startAudioPlayer;

/**
 * @brief 关闭音频播放
 * @note 此接口可以控制关闭音频播放，与 {@link startAudioPlayer} 对应
 */
- (void)stopAudioPlayer;

/**
 * @brief 是否开启语音活动检测
 * @param enable YES表示开启, NO表示关闭, 默认关闭
 * @return
 * - 0: 成功
 * - <0: 失败
 * @note
 * - 入会前调用或入会后推音频流之前调用有效。
 * - 开启语音活动检测可以在检测到没有语音的情况下，每隔400ms编码发送静音包，节省用户流量。
*/
- (int)enableAudioDTX:(BOOL)enable;

/**
 * @brief 开启音频静音检测（Audio Mute Detection, 静音不发送音频包）
 * @param enable YES表示开启,NO表示关闭,默认关闭;
 * @return
 * - 0: 成功
 * - <0: 失败
 * @note
 * - 入会前调用或入会后推音频流之前调用有效。
 * - 开启此选项可以在关闭麦克风或者静音 {@link muteLocalMic:mode:} 并且静音模式为 {@link AliRtcMuteLocalAudioMode:AliRtcMuteAudioModeDefault} 或者 {@link AliRtcMuteLocalAudioMode:AliRtcMuteAllAudioMode} 的模式下，停止音频编码和音频包的发送，节省用户流量。
*/
- (int)enableAudioAMD:(BOOL)enable;

/**
 * @brief 开启智能降噪
 * @return 
 * - 0: 成功
 * - 非0: 返回错误码
 * @note
 * - 智能降噪以插件形式提供，调用该接口前，请确保已集成了AliRTC提供的pulginAliDenoise.framework
 * - 此接口可以通话过程中控制打开智能降噪功能，通话过程中可以支持开启和关闭智能降噪
 * - 默认关闭，开启后可能导致功耗增加，智能降噪适合于会议，教育等语音通讯为主的场景，不适合有背景音乐的场景
 */
- (int)startIntelligentDenoise;

/**
 * @brief 关闭智能降噪
 * @note 此接口可以通话过程中控制关闭智能降噪功能
 */
- (void)stopIntelligentDenoise;

/**
 * @brief 启用音乐模式
 * @param enable 是否启用音乐模式, YES表示开启, NO表示关闭, 默认关闭
 * @return 
 * - 0: 成功
 * - <0: 失败
 * @note 此接口支持会议中过程中动态开启关闭，对有音乐的场景有一定程度的音质提升，最佳的音乐场景体检建议通过接口 {@link setAudioProfile:audio_scene:} 中设置场景为 {@link AliRtcAudioScenario::AliRtcSceneMusicMode} 来实现;
 */
- (int)enableMusicMode:(BOOL)enable;

/**
 * @brief 静音音频采集设备
 * @param mute TRUE：设备设置为静音，FALSE: 设备设置为不静音
 * @return 0：方法调用成功，<0：方法调用失败
 */
- (int)setRecordingDeviceMute:(BOOL)mute;

/**
 * @brief 获取音频采集设备静音状态
 * @return TRUE：已静音状态，FALSE: 非静音状态
 */
- (BOOL)getRecordingDeviceMute;

/**
 * @brief 静音音频播放设备
 * @param mute TRUE：设备设置为静音，FALSE: 设备设置为不静音
 * @return 0：方法调用成功，<0：方法调用失败
*/
- (int)setPlaybackDeviceMute:(BOOL)mute;

/**
 * @brief 获取音频播放设备静音状态
 * @return TRUE：已静音状态，FALSE: 非静音状态
*/
- (BOOL)getPlaybackDeviceMute;

#pragma mark - "其他"

/**
 * @brief 设置日志等级
 * @param logLevel Log级别，详见 {@link AliRtcLogLevel} 枚举类型
 * @note 设置 SDK 的输出日志等级。默认值为 {@link AliRtcLogLevel::AliRtcLogLevelInfo}。
 * @note 调用此接口，请在仅次于 SetLogDirPath 接口调用之后再调用本接口，避免因日志等级切换造成的打印丢失。
 */
- (void)setLogLevel:(AliRtcLogLevel)logLevel;

/**
 * @brief 设置是否上传日志文件，默认上传
 * @param enable
 *  - true 上传日志文件
 *  - false 不上传日志文件
 *  @note 入会前调用此接口，请在SetLogLevel接口调用之后立即调用本接口。
 */
- (void)enableUploadLog:(BOOL)enable;

/**
 * @brief 设置是否上传业务埋点，默认上传
 * @param enable
 *  - true 上传业务埋点
 *  - false 不上传业务埋点
 * @note 在调用{@link Create}创建AliRtcEngine实例后，应立即调用此接口，避免预期之外的埋点上传
 */
- (void)enableStatsReport:(BOOL)enable;

/**
 * @brief 设置录音音量
 * @param volume 录音音量，取值范围[0,400]
 * - 0：静音
 * - <100：减小音量
 * - >100：放大音量
 * @return
 * - 0: 成功
 * - 非0: 失败
 */
- (int)setRecordingVolume:(NSInteger)volume;

/**
 * @brief 设置播放音量
 * @param volume 播放音量，取值范围[0,400]
 * - 0：静音
 * - <100：减小音量
 * - >100：放大音量
 * @return
 * - 0: 成功
 * - 非0: 失败
 */
- (int)setPlayoutVolume:(NSInteger)volume;

/**
 * @brief 设置音频采集设备音量
 * @param volume 音量范围 [0, 100]
 * @return 0表示Success 非0表示Failure
 */
- (int)setRecordingDeviceVolume:(NSInteger)volume;

/**
 * @brief 获取音频采集设备音量
 * @return 音频采集设备音量，音量范围 [0, 100]，返回-1表示失败
 */
- (int)getRecordingDeviceVolume;

/**
 * @brief 设置音频播放设备音量
 * @param volume 音量范围 [0, 100]
 * @return 0表示Success 非0表示Failure
 */
- (int)setPlayoutDeviceVolume:(NSInteger)volume;

/**
 * @brief 获取音频播放设备音量
 * @return 音频播放设备音量，音量范围 [0, 100]，返回-1表示失败
 */
- (int)getPlayoutDeviceVolume;

/**
 * @brief 设置音频profile
 * @param audio_profile 音频采集/编码模式参数, 详见 {@link AliRtcAudioProfile}
 * @param audio_scene 音频场景模式参数,详见 {@link AliRtcAudioScenario}
 * @return 
 * - 0: 成功
 * - 其他: 失败
 * @note 只支持 {@link joinChannel:name:onResultWithUserId:} 前设置有效；
 */
- (int)setAudioProfile:(AliRtcAudioProfile)audio_profile audio_scene:(AliRtcAudioScenario)audio_scene;

/**
 * @brief 是否开启回声消除
 *
 * @param enable 开启状态
 * @note 默认是开启，一般场景建议使用默认配置
 */
- (void)enableAEC:(bool)enable;

/**
 * @brief 是否开启自动增益
 *
 * @param enable 开启状态
 * @note 默认是开启，一般场景建议使用默认配置
 */
- (void)enableAGC:(bool)enable;

/**
 * @brief 是否开启自动降噪
 *
 * @param enable 开启状态
 * @note 默认是开启，一般场景建议使用默认配置
 */
- (void)enableANS:(bool)enable;

/**
 * @brief 设置变声音效模式
 * @param mode 参考 {@link AliRtcAudioEffectVoiceChangerMode} 对应的变声音效模式值
 * @return
 * - 0：成功
 * - 非0：失败
 * @note 加入频道前和频道过程中调用都生效
 */
- (int)setAudioEffectVoiceChangerMode:(AliRtcAudioEffectVoiceChangerMode)mode;

/**
 * @brief 设置变调参数
 * @param value 变调参数，范围：[0.5, 2.0]，1.0表示音调不变，小于1.0表示音调降低，大于1.0表示音调升高，默认1.0
 * @return
 * - 0：成功
 * - 非0：失败
 * @note 加入频道前和频道过程中调用都生效
 */
- (int)setAudioEffectPitchValue:(double)value;

/**
 * @brief 设置混响音效模式
 * @param mode 参考 {@link AliRtcAudioEffectReverbMode} 对应的混响模式
 * @return
 * - 0：成功
 * - 非0：失败
 * @note 加入频道前和频道过程中调用都生效
 */
- (int)setAudioEffectReverbMode:(AliRtcAudioEffectReverbMode)mode;

/**
 * @brief 设置美声音效模式
 * @param mode 参考 {@link AliRtcAudioEffectBeautifyMode} 对应的美声模式
 * @return
 * - 0：成功
 * - 非0：失败
 * @note 加入频道前和频道过程中调用都生效
 */
- (int)setAudioEffectBeautifyMode:(AliRtcAudioEffectBeautifyMode)mode;

/**
 * @brief 设置混响音效类型
 * @param type 参考 {@link AliRtcAudioEffectReverbParamType} 对应的混响类型
 * @param value 混响参数值，不同混响类型的取值范围参考 {@link AliRtcAudioEffectReverbParamType} 中取值说明
 * @return
 * - 0：成功
 * - 非0：失败
 * @note 需要在 {@link setAudioEffectReverbMode:} 之后调用
 */
- (int)setAudioEffectReverbParamType:(AliRtcAudioEffectReverbParamType)type value:(float)value;

/**
 * @brief 设置均衡器参数
 * @param bandIndex 均衡器段数[0,9]  center frequency [31,62,125,250,500,1000,2000,4000,8000,16000] Hz {@link AliRtcAudioEffectEqualizationBandFrequency}
 * @param gain 均衡器增益db   [-15,15]  default 0
 * @return
 * - 0：成功
 * - 非0：失败
 * @note 需要在 {@link setAudioEffectBeautifyMode:} 之后调用
 */
- (int)setAudioEffectEqualizationParam:(AliRtcAudioEffectEqualizationBandFrequency)bandIndex gain:(float)gain;

/**
 * @brief 检查camera是否打开
 * @return YES表示摄像头已打开；NO表示摄像头没有打开
 * @note 该接口用于检查当前camera的状态
 */
- (BOOL)isCameraOn;

/**
 * @brief 获取状态：当前是否在频道中
 * @return 
 *  - YES: 表示当前已经加入了频道。
 *  - NO: 表示当前不在频道中。
 * @note 该方法可在加入频道前或加入频道后调用。
 */
- (BOOL)isInCall;

/**
 * @brief 查询是否纯音频模式
 * @return 
 * - YES: 表示纯音频模式  
 * - NO: 表示非纯音频模式
 */
- (BOOL)isAudioOnly;

/**
 * @brief 查询远端用户状态
 * @param uid 用户ID。从App server分配的唯一标示符
 * @return dict App提供的容器，用于存放用户数据，dict类型为字典类型，通过{Key,Value}进行访问。
 *  - dict[userID] != @""  成功
 *  - dict[userID] == @""  失败
 * @note 通过 uid 查询，指定远端用户的状态信息，在参数dict中，以字典{key,value}的形式，返回用户的全部状态信息。
 * @note Key信息: 
 *  - userID: 远端用户的ID。
 *  - isOnline: 远端用户是否在线。
 *  - sessionID: 远端用户的会话ID。
 *  - callID: 当前会话的callID。
 *  - displayName: 远端用户的名称。
 *  - hasAudio: 远端用户是否推送了音频流。
 *  - hasCameraMaster: 远端用户是否推送了相机大流。
 *  - hasCameraSlave: 远端用户是否推送了相机小流。
 *  - hasScreenSharing: 远端用户是否推送了屏幕流。
 *  - requestAudio, 本端是否订阅了此远端用户的音频流。
 *  - requestCameraMaster, 本端是否订阅了此远端用户的相机大流。此状态，系在成功订阅该用户摄像头大流前的状态。
 *  - requestCameraSlave, 本端是否订阅了此远端用户的相机小流。此状态，系在成功订阅该用户摄像头小流前的状态。
 *  - requestScreenSharing, 本端是否订阅了此远端用户的屏幕流。此状态，系在成功订阅该用户屏幕共享前的状态。
 *  - preferCameraMaster, 远端用户是否开启了大流优先。
 *  - subScribedAudio: 本端是否拉到了此远端用户的音频流。
 *  - subScribedCameraMaster: 本端是否拉到了此远端用户的相机大流。 
 *  - subScribedCamearSlave: 本端是否拉到了此远端用户的相机小流。
 *  - subScribedScreenSharing: 本端是否拉到了此远端用户的屏幕流。
 *  - hasCameraView: 本端是否设置了此远端用户相机流的view。
 *  - hasScreenView: 本端是否设置了此远端用户屏幕流的view。
 *  - muteAudioPlaying: 本端是否静音了此远端用户。
 */
- (NSDictionary * _Nullable)getUserInfo:(NSString *_Nonnull)uid;

/**
 * @brief 设置H5兼容模式
 * @details 互动模式下，是否需要与Web SDK互通。如果使用Native SDK用户加入频道，需要与通过Web SDK加入频道的用户进行互通，则必须使用H5兼容模式,否则，Web用户查看Native用户将是黑屏。
 * @param comp 
 * - YES: 兼容H5。
 * - NO: 传统模式，不兼容H5。
 * 
 * @note 不支持在创建AliRtcEngine实例之后更改H5兼容模式，必须在创建实例之前就调用此方法。
 */
+ (void)setH5CompatibleMode:(BOOL)comp;

/**
 * @brief 检查当前是否兼容H5、与Web SDK互通
 * @return 
 * - YES: 兼容H5。
 * - NO: 不兼容H5。
 */
+ (BOOL)getH5CompatibleMode;

/**
 * 展示用户Debug数据
 * @param view 对外展示的View，由客户传入，显示样式由客户指定
 * @param showType 展示类型:0: 不显示 1.音频 2.视频 3.全部；另外可以传入特殊的值来展示
 * @param userId 对应用户数据
 */
- (int)showDebugView:(NSTextView * _Nonnull)view showType:(AliRtcShowDebugViewType)showType userId:(NSString * _Nullable)userId;

/**
 * @deprecated
 * @brief 添加水印
 * @details SDK提供了添加水印的功能，适用于推送屏幕流或者相机流场景
 * @param track 视频流类型，只支持 {@link AliRtcVideoTrack::AliRtcVideoTrackCamera} 和 {@link AliRtcVideoTrack::AliRtcVideoTrackScreen}
 * @param imageUrl png 文件路径
 * @param config 水印配置 详细定义见 {@link AliRtcWatermarkConfig}
 * @return
 * - 0 : 成功
 * - -1 : 失败
 * @note 目前水印图片仅仅支持png格式
 */
- (int)addVideoWatermark:(AliRtcVideoTrack)track image:(NSString*_Nonnull)imageUrl config:(AliRtcWatermarkConfig *_Nonnull)config;

/**
 * @deprecated
 * @brief 去除水印
 * @details SDK提供了清理水印的功能，适用于推送屏幕流或者相机流场景
 * @param track 视频流类型，只支持 {@link AliRtcVideoTrack::AliRtcVideoTrackCamera} 和 {@link AliRtcVideoTrack::AliRtcVideoTrackScreen}
 * @return
 * - 0 : 成功
 * - -1 : 失败
 */
- (int)clearVideoWatermark:(AliRtcVideoTrack)track;

/**
 * @deprecated
 * @brief 设置上行弱网替代图片
 * @param imageUrl 图片路径
 * @return
 * - 0: 成功
 * - 非0: 失败
 *
 * @note 当遇到弱网时，回调 {@link onPublishStaticVideoFrame:isStaticFrame:} 将触发，并使用该接口设置图片进行推流
 */
- (int)setPublishImage:(NSString*_Nullable)imageUrl;

/**
 * @brief 是否开启系统音频采集
 * @param enabled 是否开启
 * @param deviceName 音频播放设备
 * @return
 * - 0 : 成功
 * - -1 : 失败
 * @note
 * - mac端默认不支持采集系统音频，常见方案是通过安装Core Audio Plug-ins（https://developer.apple.com/documentation/coreaudio/creating_an_audio_server_driver_plug-in?language=objc）支持
 * - 基本原理是Core Audio Plug-ins允许创建一对虚拟采集/播放设备，通过把系统默认输出设备设为虚拟播放设备，再打开同名的虚拟采集设备就可以采集到系统音频
 * - 开启系统音频采集时，deviceName必须是虚拟播放设备，SDK会将系统音频输出切换为该虚拟播放设备，并打开同名的虚拟采集设备
 * - 关闭系统音频采集时，deviceName可以是当前任意音频播放设备，SDK会将系统音频输出切换为该播放设备，并关闭虚拟采集设备
 * - 请确保调用该接口前mac设备已经安装了虚拟采集/播放设备，安装虚拟设备的示例代码及详细说明请参考官网相关文档
*/
-(int)enableSystemAudio:(BOOL)enabled
             deviceName:(NSString * _Nullable)deviceName;

/**
 * @brief 系统音频采集是否处于开启状态
 * @return
 * - YES : 开启
 * - NO : 关闭
*/
- (bool)isSystemAudioEnabled;

/**
 * @brief 设置系统音频采集后的推流音量
 * @param volume 推流音量
 * @return
 * - 0 : 成功
 * - -1 : 失败
*/
- (int)setSystemAudioRecordingVolume:(int)volume;

/**
 * @brief 获取系统音频采集后的推流音量
 * @return 推流音量
 * @return
 * - 0 : 成功
 * - -1 : 失败
*/
- (int)getSystemAudioRecordingVolume;

/**
 * @brief 设置系统音频采集后的播放音量
 * @param volume 播放音量
 * @return
 * - 0 : 成功
 * - -1 : 失败
*/
- (int)setSystemAudioPlayoutVolume:(int)volume;

/**
 * @brief 获取系统音频采集后的播放音量
 * @return 播放音量
 * @return
 * - 0 : 成功
 * - -1 : 失败
*/
- (int)getSystemAudioPlayoutVolume;

#pragma mark - "设备检测"

/**
 * @brief 开始测试音频采集设备
 * @param deviceName 音频采集设备Name
 * @return 0表示Success 非0表示Failure
 * @note 请在joinChannel之前调用
 */
- (int)startTestAudioRecordWithName:(NSString *_Nonnull)deviceName;

/**
 * @brief 停止测试音频采集设备
 * @return 0表示Success 非0表示Failure
 * @note 请在joinChannel之前调用
 */
- (int)stopTestAudioRecord;

/**
 * @brief 开始测试音频播放设备
 * @param deviceName 音频播放设备Name
 * @param filePath 音频文件路径
 * @param loopCycles 循环次数，可以设置-1(无限循环)或者>0的正整数次，其他值无效
 * @return 0表示Success 非0表示Failure
 * @note 请在joinChannel之前调用
 */
- (int)startTestAudioPlayoutWithName:(NSString *_Nonnull)deviceName filePath:(NSString *_Nonnull)filePath loopCycles:(NSInteger)loopCycles;

/**
 * @brief 停止测试音频播放设备
 * @return 0表示Success 非0表示Failure
 * @note 请在joinChannel之前调用
 */
- (int)stopTestAudioPlayout;


#pragma mark - "网络测试"

/**
 * @name  网络测试
 * @{
 */

/**
 * @brief 开始网络质量探测
 * @details 网络质量探测需要在未入会  {@link joinChannel:name:onResultWithUserId:} 情况下调用，探测结果
 * - 在3s左右，粗略的结果会在  {@link onLastmileDetectResultWithQuality:} 中回调
 * - 在30s左右，更多的结果会在 {@link onLastmileDetectResultWithBandWidth:} 中回调
 * @return
 * - 0: 成功
 * - <0: 失败
 */
- (int)startLastmileDetect:(AliRtcNetworkQualityProbeConfig *_Nonnull)config;


/**
 * @brief 停止网络质量探测
 * @return
 * - 0: 成功
 * - <0: 失败
 */
- (int)stopLastmileDetect;


#pragma mark - "音视频裸数据输入输出"

/**
 * @brief 注册音频数据回调
 * @param observer 音频数据回调，delegate = nil 则停止回调数据
 * @note 需要调用enableAudioFrameObserver开启具体AliRtcAudioSource的回调
 * @return
 *  - 0: 成功
 *  - 非0: 失败
 */
- (int)registerAudioFrameObserver:(id<AliRtcAudioFrameDelegate> _Nullable)observer;

/**
 * @brief 设置音频回调参数
 * @param enable 是否允许数据回调
 * @param audioSource 回调数据源类型，详见 {@link AliRtcAudioSource}
 * @param config 回调参数设置，详见{@link AliRtcAudioFrameObserverConfig}, null时默认参数为48000，1，ReadOnly
 * @details
 *  - AliRtcAudioSourcePub、AliRtcAudioSourceMixedAll只支持ReadOnly模式
 *  - AliRtcAudioSourceRemoteUser不支持修改采样率、通道数
 * @return 0: sucess
 *
 */
- (int)enableAudioFrameObserver:(bool)enable audioSource: (AliRtcAudioSource)audioSource config:(AliRtcAudioFrameObserverConfig*_Nullable)config;

/**
 * @brief 设置音量回调频率和平滑系数
 * @param interval 时间间隔，单位毫秒，最小值不得小于10ms, 建议设置300-500ms, <= 0表示不启用音量提示和说话人提示功能
 * @param smooth 平滑系数，数值越大平滑程度越高，反之越低，实时性越好，建议设置3，范围[0, 9];
 * @param reportVad 说话人检测开关，1: 开启，0: 关闭
 * @return
 * - 0: 成功
 * - <0: 失败
 * @note 设置之后，音频音量和说话人uid会分别通过 {@link AliRtcEngineDelegate::onAudioVolumeCallback:totalVolume:} 和 {@link AliRtcEngineDelegate::onActiveSpeaker:} 回调
 */
- (int)enableAudioVolumeIndication:(NSInteger)interval smooth:(NSInteger)smooth reportVad:(NSInteger)reportVad;

/**
 * @brief 订阅视频数据
 */
- (void)registerVideoSampleObserver;

/**
 * @brief 取消订阅视频数据
 */
- (void)unregisterVideoSampleObserver;

/**
 * @brief 注册视频数据输出对象
 * @param observer 视频数据输出对象
 */
- (void)registerVideoFrameWithObserver:(id<AliRtcVideoFrameDelegate> _Nullable)observer;

/**
 * @brief 取消视频数据输出对象
 * @param observer 视频数据输出对象
 */
- (void)unregisterVideoSampleWithObserver:(id<AliRtcVideoFrameDelegate> _Nullable)observer;


NS_ASSUME_NONNULL_BEGIN
/**
 * @brief 主动获取采集数据
 * @param videoTrack 视频流类型
 * @param p_sample 数据接收对象
 * @return
 * - YES: 成功
 * - NO: 失败
 *
 * @note 仅在 {@link onGetIfUserFetchObserverData} 返回 YES 时有效
 */
- (BOOL)getVideoCaptureData:(AliRtcVideoTrack)videoTrack videoSample:(AliRtcVideoDataSample**)p_sample;

/**
 * @brief 主动获取编码前数据
 * @param videoTrack 视频流类型
 * @param p_sample 数据接收对象
 * @return
 * - YES: 成功
 * - NO: 失败
 *
 * @note 仅在 {@link onGetIfUserFetchObserverData} 返回 YES 时有效
 */
- (BOOL)getVideoPreEncoderData:(AliRtcVideoTrack)videoTrack videoSample:(AliRtcVideoDataSample**)p_sample;

/**
 * @brief 主动获取拉流数据，onGetIfUserFetchObserverData 返回 YES 时有效
 * @param uid 远端用户ID
 * @param videoTrack 视频流类型
 * @param p_sample 数据接收对象
 * @return
 * - YES: 成功
 * - NO: 失败
 *
 * @note 仅在 {@link onGetIfUserFetchObserverData} 返回 YES 时有效
 */
- (BOOL)getVideoRenderData:(NSString*)uid videoTrack:(AliRtcVideoTrack)videoTrack videoSample:(AliRtcVideoDataSample**)p_sample;

NS_ASSUME_NONNULL_END

/**
 * @brief 启用外部视频输入源
 * @param enable YES 开启，NO 关闭
 * @param type 流类型
 * @param renderMode 外部输入视频源宽高比和推流profile不一致时，会按照对应的rendermode做对应处理
 */

/**
 * @brief 启用外部视频输入源
 * @param enable
 * - YES 开启
 * - NO 关闭
 * @param type 流类型，详见 {@link AliRtcVideoSource}
 * - AliRtcVideosourceCameraType 外部输入视频数据走相机流通道，如果当前相机采集打开中，调用该接口设置enable为YES，sdk会替换掉相机采集
 * - AliRtcVideosourceScreenShareType 外部输入视频数据走屏幕流通道，如果当前屏幕共享采集打开中，调用该接口设置enable为YES，sdk会替换掉屏幕共享采集
 * @param renderMode 处理模式，外部输入视频源宽高比和推流profile不一致时，会按照对应的rendermode做对应处理，详见 {@link AliRtcRenderMode}
 * - AliRtcRenderModeAuto 自动（默认） 如果外部输入的视频宽高比和推流设置的宽高比不一致时，维持外部输入的视频宽高比，等比例缩放宽高到推流设置的宽高范围内，注意此模式下为了保证原始视频的比例和内容完整性，会导致实际推流的分辨率和设置的不一致
 * - AliRtcRenderModeStretch 拉伸平铺，如果外部输入的视频宽高比和推流设置的宽高比不一致时，将输入视频拉伸到推流设置的比例，画面会变形
 * - AliRtcRenderModeFill 填充黑边，如果外部输入的视频宽高比和推流设置的宽高比不一致时，将输入视频上下或者左右填充黑边
 * - AliRtcRenderModeCrop 裁剪，如果外部输入的视频宽高比和推流设置的宽高比不一致时，将输入视频宽或者高进行裁剪，画面内容会丢失
 * @return
 * - 0: 成功
 * - 非0: 失败
 */
- (int)setExternalVideoSource:(BOOL)enable sourceType:(AliRtcVideoSource)type renderMode:(AliRtcRenderMode)renderMode;

/**
 * @brief 输入视频数据
 * @param frame 帧数据，详见 {@link AliRtcVideoDataSample}
 * @param type 流类型，详见 {@link AliRtcVideoSource}
 * - AliRtcVideosourceCameraType 外部输入视频数据走相机流通道
 * - AliRtcVideosourceScreenShareType 外部输入视频数据走屏幕流通道
 *  @return
 * - 0: 成功
 * - 非0: 失败
 * @note 如果返回值为errorCode中的AliRtcErrVideoBufferFull，代表当前buffer队列塞满，需要等待后再继续输送数据
 */
- (int)pushExternalVideoFrame:(AliRtcVideoDataSample *_Nonnull)frame sourceType:(AliRtcVideoSource)type;

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
- (int)setExternalImageData:(AliRtcVideoDataSample *_Nonnull)frame sourceType:(AliRtcVideoSource)type;


/**
 * @deprecated 建议参考 {@link addExternalAudioStream:} 及相关接口
 * @brief 设置是否启用外部音频输入源
 * @param enable YES:开启; NO:关闭
 * @param sampleRate 采样率 16000 48000...
 * @param channelsPerFrame 声道数 1:单声道; 2:双声道
 * @return
 * - >=0: 成功
 * - <0: 失败
 */
- (int)setExternalAudioSource:(BOOL)enable withSampleRate:(NSUInteger)sampleRate channelsPerFrame:(NSUInteger)channelsPerFrame;

/**
 * @deprecated 建议参考 {@link pushExternalAudioStream:rawData:} 及相关接口
 * @brief 输入外部音频数据推流到远端
 * @param data 音频数据buffer
 * @param samples 音频数据buffer长度
 * @param timestamp 时间戳
 * @return 
 * - <0: 表示失败;
 * - 0: 表示成功;
 * - 返回值为 {@link AliRtcErrorCode::AliRtcErrAudioBufferFull} 时，需要在间隔投递数据时间长度后再次重试投递
 * @note 为了保证语音连续性，sdk内部会有buffer缓存送进来的音频数据，以每次送10ms数据为例，如果返回 {@link AliRtcErrorCode::AliRtcErrAudioBufferFull} 时，说明内部缓冲区已满，建议等待20ms后再重新送当前数据帧；
 */
- (int)pushExternalAudioFrameRawData:(void *_Nonnull)data samples:(NSUInteger)samples timestamp:(NSTimeInterval)timestamp;

/**
 * @deprecated 建议参考 {@link setExternalAudioStream:publishVolume:} 接口
 * @brief 设置外部音频音量
 * @param vol 音量，取值范围[0,100]
 * @return
 * - >=0: 成功
 * - <0: 失败
 * @note 同时设置外部音频输入音量与外部音频播放音量
 */
- (int)setExternalAudioVolume:(int)vol;

/**
 * @deprecated 建议参考 {@link getExternalAudioStreamPublishVolume:} 接口
 * @brief 获取混音音量
 * @return 
 * - >=0: 正常混音音量,范围[0-100]
 * - <0: 失败
 */
- (int)getExternalAudioVolume;

/**
 * @deprecated 建议使用调节音量接口代替
 * @brief 设置是否与麦克风采集音频混合
 * @param mixed YES：混音；NO：完全替换麦克风采集数据
 * @return
 * - 0: 成功
 * - 非0: 失败
*/
- (int)setMixedWithMic:(BOOL)mixed;

/**
 * @deprecated 建议参考 {@link addExternalAudioStream:} 及相关接口
 * @brief 设置是否启用外部输入音频播放
 * @param enable YES:开启; NO:关闭
 * @param sampleRate 采样率 16000 48000...
 * @param channelsPerFrame 声道数 1:单声道; 2:双声道
 * @return
 * - >=0: 成功
 * - <0: 失败
 */
- (int)setExteranlAudioRender:(BOOL)enable sampleRate:(NSUInteger)sampleRate channelsPerFrame:(NSUInteger)channelsPerFrame;

/**
 * @deprecated 建议参考 {@link pushExternalAudioStream:rawData:} 及相关接口
 * @brief 输入外部音频数据本地播放
 * @param audioSamples 音频数据buffer
 * @param sampleLength 音频数据buffer长度
 * @param sampleRate 输入音频数据的采样率
 * @param channelsPerFrame 输入音频数据的声道数
 * @param timestamp 时间戳
 * @return 
 * - <0: 表示失败;
 * - 0: 表示成功;
 * - 返回值为 {@link ErrorCodeEnum::ERR_AUDIO_BUFFER_FULL} 时，需要在间隔投递数据时间长度后再次重试投递
 * @note 为了保证语音连续性，sdk内部会有buffer缓存送进来的音频数据，以每次送10ms数据为例，如果返回 {@link ErrorCodeEnum::ERR_AUDIO_BUFFER_FULL} 时，说明内部缓冲区已满，建议等待20ms后再重新送当前数据帧；
 */
- (int)pushExternalAudioRenderRawData:(const void* _Nullable)audioSamples sampleLength:(NSUInteger)sampleLength sampleRate:(NSUInteger)sampleRate channelsPerFrame:(NSUInteger)channelsPerFrame timestamp:(long long)timestamp;

/**
 * @brief 新增外部音频流
 * @param config 外部音频流配置，详见{@link AliRtcExternalAudioStreamConfig}
 * @return
 * - <=0: 表示失败;
 * - >0: 表示成功;
 * - 返回值为 外部音频流Id
 */
- (int)addExternalAudioStream:(AliRtcExternalAudioStreamConfig *_Nonnull)config;

/**
 * @brief 输入外部音频流数据
 * @param streamId 外部音频流Id
 * @param rawData 音频数据，详见{@link AliRtcAudioDataSample}
 * @return
 * - <0: 表示失败;
 * - 0: 表示成功;
 * - 返回值为 {@link AliRtcErrorCode::AliRtcErrAudioBufferFull} 时，需要在间隔投递数据时间长度后再次重试投递
 * @note 为了保证语音连续性，sdk内部会有buffer缓存送进来的音频数据，以每次送10ms数据为例，如果返回 {@link AliRtcErrorCode::AliRtcErrAudioBufferFull} 时，说明内部缓冲区已满，建议等待20ms后再重新送当前数据帧；
 */
- (int)pushExternalAudioStream:(int)streamId
                       rawData:(AliRtcAudioFrame* _Nonnull)rawData;


/**
 * @brief 设置外部音频流播放音量
 * @param streamId 外部音频流Id
 * @param playoutVolume 播放音量，取值范围[0, 100]
 * @return
 * - <0: 表示失败;
 * - 0: 表示成功;
 */
- (int)setExternalAudioStream:(int)streamId
                playoutVolume:(int)playoutVolume;

/**
 * @brief 获取外部音频流播放音量
 * @param streamId 外部音频流Id
 * @return
 * - [0, 100]: 播放音量
 * - < 0: 失败
 */
- (int)getExternalAudioStreamPlayoutVolume:(int)streamId;

/**
 * @brief 设置外部音频流推流音量
 * @param streamId 外部音频流Id
 * @param publishVolume 推流音量，取值范围[0, 100]
 * @return
 * - <0: 表示失败;
 * - 0: 表示成功;
 */
- (int)setExternalAudioStream:(int)streamId
                publishVolume:(int)publishVolume;

/**
 * @brief 获取外部音频流推流音量
 * @param streamId 外部音频流Id
 * @return
 * - [0, 100]: 推流音量
 * - < 0: 失败
 */
- (int)getExternalAudioStreamPublishVolume:(int)streamId;

/**
 * @brief 删除外部音频流
 * @param streamId 外部音频流Id
 * @return
 * - <0: 表示失败;
 * - 0: 表示成功;
 */
- (int)removeExternalAudioStream:(int)streamId;

#pragma mark - "伴奏音效"

/**
 * @brief 获取音频文件信息
 * @param filePath 音频文件路径
 * @return
 * - 0: 成功
 * - 非0: 返回错误码
 * @note 异步接口，可通过 {@link onAudioFileInfo:errorCode:} 获取音频文件信息
 */
- (int)getAudioFileInfo:(NSString *_Nonnull)filePath;

/**
 * @brief 播放音频文件
 * @param filePath 文件路径
 * @return
 * - =0 成功
 * - <0 失败
 * @note 只能入会前{@link joinChannel}调用此接口
 */
- (int)playAudioFileTest:(NSString *_Nonnull)filePath;

/**
 * @brief 停止播放音频文件
 * @return
 * - =0 成功
 * - <0 失败
 * @note 只能入会前{@link joinChannel}调用此接口
 */
- (int)stopAudioFileTest;

/**
 * @brief 开始伴奏混音
 * @param filePath 伴奏文件路径
 * @param config 伴奏播放配置，详见{@link AliRtcAudioAccompanyConfig}
 * @return
 * - 0: 成功
 * - 非0: 返回错误码
 * @note 异步接口，可通过 {@link onAudioAccompanyStateChanged:errorCode:} 监听播放器状态
 */
- (int)startAudioAccompanyWithFile:(NSString *_Nonnull)filePath config:(AliRtcAudioAccompanyConfig *_Nonnull)config;

/**
 * @brief 停止伴奏混音
 * @return 
 * - 0: 成功
 * - 非0: 返回错误码
 */
- (int)stopAudioAccompany;

/**
 * @brief 设置伴奏音量
 * @param volume 伴奏音量，取值范围[0,100]
 * @return 
 * - 0: 成功
 * - 非0: 返回错误码
 * @note 同时设置伴奏本地播放音量与伴奏推流音量
 */
- (int)setAudioAccompanyVolume:(NSInteger)volume;

/**
 * @brief 设置伴奏推流音量
 * @param volume 伴奏推流音量，取值范围[0,100]
 * @return 
 * - 0: 成功
 * - 非0: 返回错误码
 */
- (int)setAudioAccompanyPublishVolume:(NSInteger)volume;

/**
 * @brief 获取伴奏推流音量
 * @return 
 * - [0, 100]: 成功
 * - 其他值: 返回错误码
 */
- (int)getAudioAccompanyPublishVolume;

/**
 * @brief 设置伴奏本地播放音量
 * @param volume 伴奏本地播放音量，取值范围[0,100]
 * @return 
 * - 0: 成功
 * - 非0: 返回错误码
 */
- (int)setAudioAccompanyPlayoutVolume:(NSInteger)volume;

/**
 * @brief 获取伴奏本地播放音量
 * @return 
 * - [0, 100]: 成功
 * - 其他值: 返回错误码
 */
- (int)getAudioAccompanyPlayoutVolume;


/**
 * @brief 暂停伴奏混音
 * @return 
 * - 0: 成功
 * - 非0: 返回错误码
 */
- (int)pauseAudioAccompany;

/**
 * @brief 重新开始伴奏混音
 * @return 
 * - 0: 成功
 * - 非0: 返回错误码
 */
- (int)resumeAudioAccompany;

/**
 * @brief 获取伴奏文件时长, 单位为毫秒
 * @return
 * - >=0: 伴奏文件时长
 * - <0: 返回错误码
 */
- (int)getAudioAccompanyDuration;

/**
 * @brief 获取伴奏文件播放进度，单位为毫秒
 * @return
 * - >=0: 伴奏文件播放进度
 * - <0: 返回错误码
 */
- (int)getAudioAccompanyCurrentPosition;

/**
 * @brief 设置伴奏文件的播放位置
 * @param pos 进度条位置，单位为毫秒
 * @return 
 * - 0: 成功
 * - 非0: 返回错误码
 */
- (int)setAudioAccompanyPosition:(int)pos;

/**
 * @brief 预加载音效文件
 * @param soundId 用户给该音效文件分配的ID
 * @param filePath 音效文件路径，支持本地文件和网络url
 * @return
 * - 0：成功
 * - 非0：失败
 * @note 音效相关接口为同步接口, 建议使用本地文件
 */
- (int)preloadAudioEffectWithSoundId:(NSInteger)soundId filePath:(NSString *_Nonnull)filePath;

/**
 * @brief 删除预加载的音效文件
 * @param soundId 用户给该音效文件分配的ID
 * @return
 * - 0：成功
 * - 非0：失败
 * @note 音效soundId应与预加载 {@link preloadAudioEffectWithSoundId:filePath:} 时传入的ID相同
 */
- (int)unloadAudioEffectWithSoundId:(NSInteger)soundId;

/**
 * @brief 开始播放音效
 * @details 开始播放音效接口，可以多次调用该方法传入不同的soundId和filePath，同时播放多个音效文件，音效文件播放结束后，SDK 会触发 {@link onAudioEffectFinished:} 回调
 * @param soundId 用户给该音效文件分配的ID，每个音效均有唯一的ID，如果你已通过 {@link preloadAudioEffectWithSoundId:filePath:} 将音效加载至内存，确保这里的soundId与 {@link preloadAudioEffectWithSoundId:filePath:} 设置的soundId相同
 * @param filePath 文件路径，支持本地文件和网络url
 * @param config 音效播放配置，详见{@link AliRtcAudioEffectConfig}
 * @return
 * - 0：成功
 * - 非0：失败
 */
- (int)playAudioEffectWithSoundId:(NSInteger)soundId filePath:(NSString *_Nonnull)filePath config:(AliRtcAudioEffectConfig *_Nonnull)config;

/**
 * @brief 停止播放音效
 * @param soundId 用户给该音效文件分配的ID，每个音效均有唯一的ID，如果你已通过 {@link preloadAudioEffectWithSoundId:filePath:} 将音效加载至内存，确保这里的soundId与 {@link preloadAudioEffectWithSoundId:filePath:} 设置的soundId相同
 * @return
 * - 0：成功
 * - 非0：失败
 */
- (int)stopAudioEffectWithSoundId:(NSInteger)soundId;

/**
 * @brief 停止播放所有音效
 * @return
 * - 0：成功
 * - 非0：失败
 */
- (int)stopAllAudioEffects;

/**
 * @brief 设置音效推流混音音量
 * @param soundId 用户给该音效文件分配的ID
 * @param volume 推流混音音量，范围是：[0, 100]，默认值：50
 * @return
 * - 0：成功
 * - 非0：失败
 * @note 该方法需要在 {@link playAudioEffectWithSoundId:filePath:cycles:publish:} 后调用
 */
- (int)setAudioEffectPublishVolumeWithSoundId:(NSInteger)soundId volume:(NSInteger)volume;

/**
 * @brief 获取音效推流混音音量
 * @param soundId 用户给该音效文件分配的ID
 * @return
 * - [0, 100]：音效推流混音音量
 * - 其他：错误值
 * @note 音效推流混音音量有效范围为：[0, 100]，该方法需要在 {@link playAudioEffectWithSoundId:filePath:cycles:publish:} 后调用
 */
- (int)getAudioEffectPublishVolumeWithSoundId:(NSInteger)soundId;

/**
 * @brief 设置音效本地播放音量
 * @param soundId 用户给该音效文件分配的ID
 * @param volume 音效本地播放音量，范围：[0, 100]，默认值：50
 * @return
 * - 0：成功
 * - 非0：失败
 * @note 该方法需要在 {@link playAudioEffectWithSoundId:filePath:cycles:publish:} 后调用
 */
- (int)setAudioEffectPlayoutVolumeWithSoundId:(NSInteger)soundId volume:(NSInteger)volume;

/**
 * @brief 获取音效本地播放音量
 * @param soundId 用户给该音效文件分配的ID
 * @return
 * - [0, 100]：音效本地播放音量
 * - 其他：错误值
 * @note 音效本地播放音量有效范围为：[0, 100]，该方法需要在 {@link playAudioEffectWithSoundId:filePath:cycles:publish:} 后调用
 */
- (int)getAudioEffectPlayoutVolumeWithSoundId:(NSInteger)soundId;

/**
 * @brief 设置所有音效本地播音量
 * @param volume 音效本地播放音量，范围：[0, 100]，默认值：50
 * @return
 * - 0：成功
 * - 非0：失败
 */
- (int)setAllAudioEffectsPlayoutVolume:(NSInteger)volume;

/**
 * @brief 设置所有音效推流混音音量
 * @param volume 推流混音音量，范围是：[0, 100]，默认值：50
 * @return
 * - 0：成功
 * - 非0：失败
 */
- (int)setAllAudioEffectsPublishVolume:(NSInteger)volume;

/**
 * @brief 暂停音效
 * @param soundId 用户给该音效文件分配的ID
 * @return
 * - 0：成功
 * - 非0：失败
 */
- (int)pauseAudioEffectWithSoundId:(NSInteger)soundId;

/**
 * @brief 暂停所有音效
 * @return
 * - 0：成功
 * - 非0：失败
 */
- (int)pauseAllAudioEffects;

/**
 * @brief 恢复指定音效文件
 * @param soundId 用户给该音效文件分配的ID
 * @return
 * - 0：成功
 * - 非0：失败
 */
- (int)resumeAudioEffectWithSoundId:(NSInteger)soundId;

/**
 * @brief 恢复所有音效文件
 * @return
 * - 0：成功
 * - 非0：失败
 */
- (int)resumeAllAudioEffects;


#pragma mark - "文件录制"

/**
 * @brief 开始录制
 * @details SDK提供了屏录录制的功能，可以录制本地或远端的音频流、视频流、相机流
 * @param recordType 录制类型 详细定义见 {@link AliRtcRecordType}
 * @param recordFormat 录制文件格式 详细定义见 {@link AliRtcRecordFormat}
 * @param filePath 文件路径
 * @param audioConfig 音频设置 详细定义见 {@link AliRtcRecordAudioConfig}
 * @param videoConfig 视频设置 详细定义见 {@link AliRtcRecordVideoConfig}
 * @param isFragment 是否支持mp4内部分段，只在录制mp4时有效
 * @return
 * - YES: 成功
 * - NO: 失败
 * @note 此接口为旧接口，新接口为 {@link startRecord:filePath:recordLayout}
 */
- (BOOL)startRecord:(AliRtcRecordType)recordType recordFormat:(AliRtcRecordFormat)recordFormat filePath:(NSString*_Nonnull)filePath audioConfig:(AliRtcRecordAudioConfig*_Nonnull)audioConfig videoConfig:(AliRtcRecordVideoConfig*_Nonnull)videoConfig isFragment:(BOOL)isFragment;

/**
 * @brief 更新录制内容信息
 * @details SDK提供了更新录制内容信息的功能,用于实时更新录制模板内容设置
 * @param layout 录制视频内容及布局, 详细定义见 {@link AliRtcRecordVideoLayout}
 * @return
 * - YES: 成功
 * - NO: 失败
 * @note updateRecordLayout更新录制内容信息应该在录制过程中调用
 */
- (BOOL)updateRecordLayout:(AliRtcRecordVideoLayout*_Nonnull)layout;

/**
 * @brief 添加录制模板
 * @details SDK提供了添加录制模板的功能,用于添加录制模板
 * @param recordTemplate 录制模板, 详细定义见 {@link AliRtcRecordTemplate}
 * @return
 * - YES: 成功
 * - NO: 失败
 * @note addRecordTemplate添加录制模板必须在StartRecord之前调用
 */
- (BOOL)addRecordTemplate:(AliRtcRecordTemplate*_Nonnull)recordTemplate;

/**
 * @brief 开始录制
 * @details SDK提供了屏录录制的功能，可以录制本地或远端的音频流、视频流、相机流，窗口布局设置参考 {@link AliEngineRecordVideoLayout}
 * @param filePath 文件路径
 * @param recordLayout 视频窗口布局设置, 详细定义见 {@link AliRtcRecordVideoLayout}
 * @return
 * - YES: 成功
 * - NO: 失败
 * @note startRecord之前调用必须先调用addRecordTemplate添加录制模板
 */
- (BOOL)startRecord:(NSString*_Nonnull)filePath recordLayout:(AliRtcRecordVideoLayout*_Nonnull)recordLayout;

/**
 * @brief 暂停录制
 * @details SDK提供了暂停录制的功能
 * @return
 * - YES: 成功
 * - NO: 失败
 */
- (BOOL)pauseRecord;

/**
 * @brief 重新开启录制
 * @details SDK提供了重新开始录制的功能
 * @return
 * - YES: 成功
 * - NO: 失败
 */
- (BOOL)resumeRecord;

/**
 * @brief 停止录制
 * @details SDK提供了停止录制的功能
 */
- (void)stopRecord;

/**
 * @brief 美颜功能是否可用
 */
- (BOOL)isBeautifierAvailable;

/**
 * @brief 美颜功能是否开启
 */
- (BOOL)isBeautifierEnabled;

/**
 * @brief 开启或关闭美颜功能, 并设置美颜效果参数
 * @deprecated
 * @param enable
 * - YES 开启美颜功能
 * - NO 关闭美颜功能
 * @param confg 美颜效果参数, 详细定义见 {@link AliRtcBeautyConfig}
 * @return
 * - 0 : 成功
 * - < 0 : 失败
 */
- (int)setBeautyEffect:(bool)enable config:(AliRtcBeautyConfig *_Nonnull)confg;

#pragma mark - "视频画面截图"

/**
 * @brief 视频截图功能
 * @param userId 用户ID，userId 为nil或者为""代表本地用户
 * @param trackType 视频流类型，只支持 {@link AliRtcVideoTrack::AliRtcVideoTrackCamera} 和 {@link AliRtcVideoTrack::AliRtcVideoTrackScreen}
 * @return
 * - 0 : 仅代表调用该接口成功，是否获取到截图画面，详细见 {@link onSnapshotComplete: videoTrack: image: success:}
 * - < 0 : 失败
 * @note 视频截图功能为异步接口, 通过监听 {@link onSnapshotComplete: videoTrack: image: success:} 回调获取当前截图画面。
 */
- (int)snapshotVideo:(NSString*_Nullable)userId type:(AliRtcVideoTrack)trackType;

#pragma mark - "低延时互动直播模式"

/**
 * @deprecated
 * @brief 开始低延时互动直播拉流
 * @details 该方法仅在低延迟互动模式 {@link AliRtcInteractiveWithLowLatencyLive } 下，角色为观众 {@link AliRtcClientRolelive } 时调用有意义
 * @param authInfo 入会鉴权信息
 * @param onResult 拉流结果，errCode
 * - 0: 成功
 * - <0: 失败
 * @note 该接口已废弃
 */
- (void)startLiveStreamingWithAuthInfo:(AliRtcAuthInfo *_Nonnull)authInfo onResult:(void(^_Nullable)(int errCode))onResult;

/**
 * @deprecated
 * @brief 停止低延时互动直播拉流
 * @return
 * - 0: 成功
 * - <0: 失败
 * @note 该方法仅在低延迟互动模式下，角色为观众时调用有意义
 * @note 该接口已废弃
 */
- (int)stopLiveStreaming;

/**
 * @brief 设置低延时互动直播拉流渲染Canvas
 * @param canvas 渲染参数，包含了窗口以及渲染方式
 * @return
 * - 0: 成功
 * - <0: 失败
 * @note 该接口已废弃
 */
- (int)setLiveStreamingViewConfig:(AliVideoCanvas *_Nullable)canvas;

/**
 * @deprecated 建议参考 {@link setExternalAudioStream:playoutVolume:} 接口
 * @brief 设置音频播放音量
 * @param vol 音量 0-100
*/
- (int)setExternalAudioRenderVolume:(int)vol;

/**
 * @deprecated 建议参考 {@link getExternalAudioStreamPlayoutVolume:} 接口
 * @brief 获取音频播放音量
 * @return vol 音量
*/
- (int)getExternalAudioRenderVolume;

#pragma mark - "媒体扩展信息"
/**
 * @brief 发送媒体扩展信息，底层使用SEI实现
 * @details SDK提供了发送和接收媒体扩展信息的功能，接收端参考 {@link AliRtcEngineDelegate::onMediaExtensionMsgReceived:message:}，使用场景：
 * - 使用媒体扩展信息传递各类少量数据，长度限制为4K 字节，建议使用文本；
 *
 * @param data 扩展信息内容, 长度限制为最大4K 字节
 * @param repeatCount 重复次数，代表消息冗余度，用于防止网络丢包导致的消息丢失-1表示无限重发，除非再一次调用sendMediaExtensionMsg
 * @param delay 延迟多少毫秒发送 用来延迟多少毫秒之后再发送SEI，因SEI是附在编码之后的h264/h265流，所以实际的延迟会比设置的延迟略大
 * @param isKeyFrame 是否只给关键帧加SEI 设置为true，则只给关键帧加SEI信息
 * @return
 * - 0: 成功
 * - <0: 失败
 *      - ERR_INNER(-1): SDK内部错误，可能的情况为SDK未初始化或者SDK销毁后调用
 * 
 * @note 使用媒体扩展信息时需要复用音视频数据通道，因此必须控制自定义消息的发送频率和消息数据长度，使用限制如下：
 * - 每秒最多发送profile设置的fps条消息
 * - 为了不影响媒体数据的传输质量，自定义消息体长度限制为4K Bytes，可以可以用来传输少量数据
 * - sendMediaExtensionMsg函数中repeatCount参数为自定义消息冗余度，若大于1，则会发送多次，防止网络丢包导致的消息丢失，此时房间里的其他人也会收到多次相同的消息，需要去重
 * - 发送的自定义消息，在旁路直播时，房间里的订阅者也一样会收到，设置为-1为永久发送data数据，除非重新设置sendMediaExtensionMsg
 * - 目前H5端不支持发送和接收媒体扩展信息
 * - 同一时刻只有一个 sendMediaExtensionMsg 会被发送，意味着调用sendMediaExtensionMsg会覆盖上一次调用的sendMediaExtensionMsg，如果上次的调用没有发送或者没有发送完成；
 */
- (int)sendMediaExtensionMsg:(NSData *_Nonnull)data repeatCount:(int)repeatCount delay:(int)delay isKeyFrame:(bool)isKeyFrame;


/**
 * @brief 发送媒体扩展信息，底层使用SEI实现
 * @details SDK提供了发送和接收媒体扩展信息的功能，接收端参考 {@link AliRtcEngineDelegate::onMediaExtensionMsgReceived:message:}，使用场景：
 * - 使用媒体扩展信息传递各类少量数据，长度限制为4K 字节，建议使用文本；
 *
 * @param data 扩展信息内容, 长度限制为最大4K 字节
 * @param repeatCount 重复次数，代表消息冗余度，用于防止网络丢包导致的消息丢失-1表示无限重发，除非再一次调用sendMediaExtensionMsg
 * @param delay 延迟多少毫秒发送 用来延迟多少毫秒之后再发送SEI，因SEI是附在编码之后的h264/h265流，所以实际的延迟会比设置的延迟略大
 * @param isKeyFrame 是否只给关键帧加SEI 设置为true，则只给关键帧加SEI信息
 * @param payloadType 类型，带UUID的请用5，范围是[5,100..254]
 * @return
 * - 0: 成功
 * - <0: 失败
 *      - ERR_INNER(-1): SDK内部错误，可能的情况为SDK未初始化或者SDK销毁后调用
 *
 * @note 使用媒体扩展信息时需要复用音视频数据通道，因此必须控制自定义消息的发送频率和消息数据长度，使用限制如下：
 * - 每秒最多发送profile设置的fps条消息
 * - 为了不影响媒体数据的传输质量，自定义消息体长度限制为4K Bytes，可以可以用来传输少量数据
 * - sendMediaExtensionMsg函数中repeatCount参数为自定义消息冗余度，若大于1，则会发送多次，防止网络丢包导致的消息丢失，此时房间里的其他人也会收到多次相同的消息，需要去重
 * - 发送的自定义消息，在旁路直播时，房间里的订阅者也一样会收到，设置为-1为永久发送data数据，除非重新设置sendMediaExtensionMsg
 * - 目前H5端不支持发送和接收媒体扩展信息
 * - 同一时刻只有一个 sendMediaExtensionMsg 会被发送，意味着调用sendMediaExtensionMsg会覆盖上一次调用的sendMediaExtensionMsg，如果上次的调用没有发送或者没有发送完成；
 */
- (int)sendMediaExtensionMsgEx:(NSData *_Nonnull)data repeatCount:(int)repeatCount delay:(int)delay isKeyFrame:(bool)isKeyFrame payloadType:(int)payloadType;

#pragma mark - "问题上报"

/**
 * @deprecated
 * @brief SDK问题反馈
 * @param uid 问题用户id (允许为nil)
 * @param channelId 问题频道id (允许为nil)
 * @param description 问题描述(支持中英文, 必填)
 * @param type 问题类型，参考 {@link AliRtcFeedbackType}
 * @param timeStamp 问题发生的时间戳 (Unix时间戳，大致时间，无需特别精确，可以为0)
 * @note 该接口在入会前、会中、离会后均可以调用，推荐会中或者离会前调用，尽可能带上所有参数信息
 */
- (void)postFeedbackWithUid:(NSString *_Nullable)uid channleId:(NSString *_Nullable)channelId description:(NSString *_Nonnull)description type:(AliRtcFeedbackType)type timeStamp:(NSTimeInterval)timeStamp;

#pragma mark - "多频道"

/**
 * @brief 创建子频道
 * @param delegate delegate
 * @param extras extras [可以为空 @""]，参考文档：[extras参数配置说明](https://help.aliyun.com/document_detail/200048.html)。
 * @note 创建的子频道实例，需要通过 {@link destroyChannel} 进行释放
 * @return 成功返回子频道实例，失败返回nil
 */
- (AliRtcEngine *_Nullable)createChannelWithDelegate:(id<AliRtcEngineDelegate>_Nonnull)delegate extras:(NSString *_Nullable)extras;

/**
 * @brief 销毁子频道
 * @details 使用 {@link joinChannel:name:onResultWithUserId:} 加入的是主频道，不需要调用destroyChannel销毁
 */
- (void)destroyChannel;

#pragma mark - "旁路转推"

/**
 * @brief 开启旁路直播
 * @details SDK提供了开启旁路直播的功能，可以把实时音视频流经过混流、混音处理转为标准直播流并推送至指定CDN供应商
 * @param streamURL 推流地址
 * @param trancoding 推流所需参数 详细定义见 {@link AliRtcLiveTranscodingParam}
 * @return
 * - 0 : 成功
 * - 非0 : 失败
 *   - ERR_INNER(-1) : SDK内部错误，可能的情况为SDK未初始化或者SDK销毁后调用
 *   - 其他 : 返回值参考官网错误码
 */
- (int)startPublishLiveStreamWithURL:(NSString *_Nonnull)streamURL liveTranscoding:(AliRtcLiveTranscodingParam *_Nonnull)trancoding;

/**
 * @brief 更新旁路直播相关参数
 * @details SDK提供了更新旁路直播的功能，用于实时更新旁路直播参数
 * @param streamURL 推流地址
 * @param trancoding 推流所需参数 详细定义见 {@link AliRtcLiveTranscodingParam}
 * @return
 * - 0 : 成功
 * - 非0 : 失败
 *   - ERR_INNER(-1) : SDK内部错误，可能的情况为SDK未初始化或者SDK销毁后调用
 *   - 其他 : 返回值参考官网错误码
 */
- (int)updatePublishLiveStreamWithURL:(NSString *_Nonnull)streamURL liveTranscoding:(AliRtcLiveTranscodingParam *_Nonnull)trancoding;

/**
 * @brief 更新旁路直播相关参数
 * @details SDK提供了更新旁路直播的功能，用于实时更新旁路直播参数
 * @param taskId 任务id
 * @param trancoding 推流所需参数 详细定义见 {@link AliRtcLiveTranscodingParam}
 * @return
 * - 0 : 成功
 * - 非0 : 失败
 *   - ERR_INNER(-1) : SDK内部错误，可能的情况为SDK未初始化或者SDK销毁后调用
 *   - 其他 : 返回值参考官网错误码
 */
- (int)updatePublishLiveStreamWithTaskId:(NSString *_Nonnull)taskId liveTranscoding:(AliRtcLiveTranscodingParam *_Nonnull)trancoding;

/**
 * @brief 停止旁路直播
 * @details SDK提供了停止旁路直播的功能
 * @param streamURL 推流地址
 * @return
 * - 0 : 成功
 * - 非0 : 失败
 *   - ERR_INNER(-1) : SDK内部错误，可能的情况为SDK未初始化或者SDK销毁后调用
 *   - 其他 : 返回值参考官网错误码
 */
- (int)stopPublishLiveStreamWithURL:(NSString *_Nonnull)streamURL;

/**
 * @brief 停止旁路直播
 * @details SDK提供了停止旁路直播的功能
 * @param taskId 任务id
 * @return
 * - 0 : 成功
 * - 非0 : 失败
 *   - ERR_INNER(-1) : SDK内部错误，可能的情况为SDK未初始化或者SDK销毁后调用
 *   - 其他 : 返回值参考官网错误码
 */
- (int)stopPublishLiveStreamWithTaskId:(NSString *_Nonnull)taskId;

/**
* @brief 获得旁路直播状态
* @param streamURL 推流地址
* @return AliRtcLiveTranscodingState
*/
- (AliRtcLiveTranscodingState)GetPublishLiveStreamStateWithURL:(NSString *_Nonnull)streamURL;

/**
* @brief 获得旁路直播状态
* @param taskId 任务id
* @return AliRtcLiveTranscodingState
*/
- (AliRtcLiveTranscodingState)GetPublishLiveStreamStateWithTaskId:(NSString *_Nonnull)taskId;

#pragma mark - "跨频道转推"

/**
 * @brief 开启跨频道转推
 * @details 普通情况下，一个主播只可以在一个频道内推拉流，该接口可以实现跨频道能力，支持主播（在A频道）将A频道的流推送到B频道，B频道相当于一个新主播入会并推流，对应的入会和推流回调依然会回调，与主播直接加入B频道行为一致。
 * @details 如果两个频道内的两个主播互相向对应的频道进行跨频道转推，就可以实现主播间的跨频道连麦，典型场景如：两个直播间的主播PK功能。如下图示例：
 * <pre>
 *                  channel-A                     channel-B
 *               ---------------                ---------------
 *  跨频道转发前: |  主播 A       |              |  主播 B        |
 *              |  观众 U1 U2   |              |  观众 U3 U4    |
 *               ---------------                ---------------
 *
 *                  channel-A                     channel-B
 *               ---------------                ---------------
 *  跨频道转发后: |  主播 A B     |              |  主播 B A      |
 *              |  观众 U1 U2   |              |  观众 U3 U4    |
 *               ---------------                ---------------
 * </pre>
 * @param configuration 频道配置信息 {@link AliRtcChannelRelayConfiguration}
 * @return
 * - 0: 成功
 * - <0: 失败
 * @note 发起跨频道转推需要满足三个条件
 * - 会议模式为互动模式或者低延迟互动模式
 * - 必须是主播角色
 * - 必须在会议中
 */
- (int)startChannelRelay:(AliRtcChannelRelayConfiguration *_Nonnull)configuration;

/**
 * @brief 更新跨频道转推
 * @param configuration 频道配置信息 {@link AliRtcChannelRelayConfiguration}
 * @return
 * - 0: 成功
 * - <0: 失败
 */
- (int)updateChannelRelay:(AliRtcChannelRelayConfiguration *_Nonnull)configuration;

/**
 * @brief 停止跨频道转推
 * @return
 * - 0: 成功
 * - <0: 失败
 */
- (int)stopChannelRelay;

/**
 * @brief 设置视频流属性
 * @param track 视频流类型，详细见 {@link AliRtcVideoTrack}
 * @param attr 视频流属性
 * @note 已废弃使用。
 */
- (void)setPublishVideoStreamAttribute:(AliRtcVideoTrack)track attr:(NSString *_Nullable)attr ;

/**
 * @brief 开启/关闭内置加解密功能：需要在入会前调用
 * @param enable 是否开启
 * @return
 * - 0 : 成功
 * - 非0 : 失败
 */
- (int)enableEncryption:(BOOL)enable;

#pragma mark - "虚拟背景"

/**
 * @brief 开启/关闭虚拟背景替换功能
 * @details 需要集成虚拟背景插件，虚拟背景简介及下载详见[官网组件文档](https://help.aliyun.com/document_detail/260223.html) ；
 * @param enable 是否开启；
 * @param path 虚拟背景本地图片路径，支持JPG，PNG 格式；
 * @param model 背景图缩放模式，裁剪或缩放；
 * - AliRtcBokehScaleModelCrop: 等比裁剪，当背景图像宽高比和视频数据宽高比不一致时, 为了保持等比例缩放, 会将背景图像裁剪到视频比例, 超出部分背景图片内容将会丢失；
 * - AliRtcBokehScaleModelFill: 填充黑边，当背景图像宽高比和视频数据宽高比不一致时, 为了保持等比例缩放， 会对背景进行黑边填充，背景图片内容会全部保留；
 * @return
 * - 0: 成功
 * - < 0: 失败 详见 {@link AliRtcPluginErrorCode}；
 *   - AliRtcPluginErrorLoadError：未进行官网组件集成，详见[虚拟背景集成文档](https://help.aliyun.com/document_detail/254861.html) ；
 *   - AliRtcPluginErrorInitError： 参数错误，请检查图片路径地址；
 *
 * @note
 * - 支持平台详见[官网发布日志](https://help.aliyun.com/document_detail/261183.html) ；
 * - 可重复调用，背景图及缩放模式与之前设置不一致，会进行实时更新；
 * - 与背景虚化为替换关系，如开启虚拟背景开关后再次开启背景虚化，则只有背景虚化效果；
*/
- (int)enableBackgroundExchange:(BOOL)enable imagePath:(NSString *_Nonnull)path scalMode:(AliRtcBokehScaleModel)model;

/**
 * @deprecated
 * @brief 开启/关闭虚拟背景虚化功能
 * @details 需要集成虚拟背景插件，虚拟背景简介及下载详见[官网组件文档](https://help.aliyun.com/document_detail/260223.html) ；
 *  需要下载及集成虚拟背景插件，背景替换与背景虚化不可同时使用，如开启虚拟背景开关后再次开启背景虚化，则只有背景虚化效果；
 * @param enable 是否开启；
 * @param blurDegree  虚化程度 取值范围 [0-100]；
 * @return
 * - 0: 成功
 * - < 0: 失败 详见 {@link AliRtcPluginErrorCode}；
 *   - AliRtcPluginErrorLoadError：未进行官网组件集成，详见[虚拟背景集成文档](https://help.aliyun.com/document_detail/254861.html) ；
 *   - AliRtcPluginErrorInitError： 参数错误，请检查虚化程度取值；
 *
 * @note
 * - 支持平台详见[官网发布日志](https://help.aliyun.com/document_detail/261183.html) ；
 * - 虚化程度范围  [0-100]；
 * - 可重复调用，虚化值如果与之前设置不一致，会进行实时更新；
 * - 与虚拟背景为替换关系，如开启背景虚化开关后再次开启虚拟背景，则只有虚拟背景效果；
*/
- (int)enableBackgroundBlur:(BOOL)enable blurDegree:(uint32_t)blurDegree;

/**
 * @brief 获取当前使用的编码器/解码器类型
 * @details 提供接口获取当前使用的编码器类型，某些场景会改变编码器类型，因此获取的值只说明当前值，不表示后续不变更；
 * @param codec_kind 编码器类型 AliRtcVideoCodecKind_Encoder/AliRtcVideoCodecKind_Decoder
 * @param videoFormat  获取的编码类型 可能的返回值(AliRtcVideoFormat_H264/AliRtcVideoFormat_H265/AliRtcVideoFormat_UNKNOW)
 * @return
 * - 0: 成功
 * - < 0: 失败 详见 {@link AliRtcPluginErrorCode}；
 *   - AliRtcPluginErrorInitError： 参数错误，请检查codec_kind取值；
 *
 * @note
 * - AliRtcVideoCodecKind_Encoder/AliRtcVideoCodecKind_Decoder；
 * - 可重复调用，获取当前使用的编码器类型和支持的最高级的解码器类型，因所有的RTC引擎都集成了hevc解码器，
 * - 获取解码器类型，会返回AliRtcVideoFormat_H265；
*/
- (int)getVideoCodecType:(AliRtcVideoCodecKindType)codec_kind videoFormat:(AliRtcVideoFormat * _Nonnull)videoFormat ;

/**
* @brief 获取当前使用的编码器类型,如未开始推流，返回无效类型
* @param track AliRtcVideoTrack
* @return AliRtcVideoCodecManufacturer 编码器类型
*/
- (AliRtcVideoCodecManufacturer)getCurrentEncoderManufacturer:(AliRtcVideoTrack)track;
/**
* @brief 获取时间轴时间
* @return 时间戳
*/
-(long long)getNetworkTime;

/**
* @brief 发送伴奏控制消息
* @param controlMsg 伴奏控制消息
* @return
* - 0: 成功
* - 非0: 失败
*/
-(int) sendDataChannelMessage:(AliRtcDataChannelMsg* _Nonnull)controlMsg;

/**
 * @brief 开启SEI视频流，内部将使用16x16全黑图片流/20fps
 * @param enable true=开启 false=关闭
 * @return
 * - 0: 成功
 * - 非0: 失败
 */
-(int) enableSEIVideoStream:(bool)enable ;


/**
* @brief 设置订阅音频的黑名单，不允许订阅列表内的用户的音频
* @param  uidArray = nil 说明清空黑名单 非nil为设置黑名单列表
* @return
* - 0: 成功
* - 非0: 失败
*/
-(int) setSubscribeRemoteAudioStreamBlockList:(NSMutableArray<NSString * > * _Nullable)uidArray;

/**
* @brief 设置订阅音频的白名单，只允许订阅列表内的用户的音频
* @param uidArray = nil 说明清空白名单 非nil为设置白名单列表
* @return
* - 0: 成功
* - 非0: 失败
*/
-(int) setSubscribeRemoteAudioStreamAllowList:(NSMutableArray<NSString *> *_Nullable)uidArray;

/**
* @brief 设置订阅音频的黑名单，不允许订阅列表内的用户的视频
* @param uidArray = nil 说明清空黑名单 非nil为设置黑名单列表
* @return
* - 0: 成功
* - 非0: 失败
*/
-(int) setSubscribeRemoteVideoStreamBlockList:(NSMutableArray<NSString *> *_Nullable)uidArray;

/**
* @brief 设置订阅音频的白名单，只允许订阅列表内的用户的视频
* @param uidArray  = nil 说明清空白名单 非nil为设置白名单列表
* @return
* - 0: 成功
* - 非0: 失败
*/
-(int) setSubscribeRemoteVideoStreamAllowList:(NSMutableArray<NSString *> *_Nullable)uidArray;

/**
* @brief 设置音频能力
* @param ability 能力项
* @return
* - 0: 成功
* - 非0: 失败
*/
-(int) setAudioCapability:(AliRtcAudioCapability* _Nonnull)ability;

@end
/** @} AliRtc_mac AliRtcEngine */
