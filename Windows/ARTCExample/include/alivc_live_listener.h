#ifndef ali_vc_live_listener_h
#define ali_vc_live_listener_h
/**
* ref doc: https://aliyuque.antfin.com/zxhy15/wubm3l/kaigbrn3gu1klczx
* ref git: https://code.alibaba-inc.com/aliyun-live/AliLivePushSDK/
* ref branch: blob/release/aio/v1.9.0/
* ref code: android/alivc-livepusher-lib/src/main/java/com/alivc/live/pusher/AlivcLivePushInfoListener.java and other listener
**/
#include "alivc_live_define.h"
#include "alivc_live_utils.h"
#include <stdint.h>
/**
 * @brief AliVCSDK_ARTC namespace/
 */
namespace AliVCSDK_ARTC
{
    class AlivcLivePusher;
	class AlivcLivePlayer;
    class AlivcLiveExternalFileObserver;
    /**
     * @brief SDK错误码
     */
    typedef enum {
         /*  0.基础组件 0x10000000-0x1FFFFFFF */
        ALIVC_FRAMEWORK_ERROR_START = 0x10000000,
        /*  0.1.基础架构 0x10000000-0x10000FFF */
        /*  0.2.muxer\demuxer组件 0x10001000-0x10001FFF */
        ALIVC_FRAMEWORK_MUXER_ERROR_START = 0x10001000,

        /*  0.3.解码组件 0x10002000-0x10002FFF */
        ALIVC_FRAMEWORK_DECODER_ERROR_START = 0x10002000,

        /*  0.4.编码组件 0x10003000-0x10003FFF */
        ALIVC_FRAMEWORK_VIDEO_ENCODER_ERROR_START = 0x10003000,

        //0.5.audio encoder
        ALIVC_FRAMEWORK_AUDIO_ENCODER_START = 0x10003202,

        /*  0.6.渲染组件 0x10004000-0x10004FFF */
        ALIVC_FRAMEWORK_RENDER_ERROR_START = 0x10004000,

        /*  0.7.采集组件 0x10005000-0x10005FFF */
        ALIVC_PUSHER_ERROR_SDK_CAPTURE_START = 0x10005000,
        
        // 视频采集组件
        ALIVC_PUSHER_ERROR_SDK_VIDEO_CAPTURE_ERROR = 0x01400100,

        /*  1.系统错误 */
        ALIVC_LIVE_ERROR_SYSTEM_RTMP_START = 0x30010900,

        /*  2.SDK错误 */
        /*     2.1.NativeLivePush SDK错误 0x30020200-0x300202FF */
        ALIVC_PUSHER_ERROR_SDK_NATIVE_LIVE_PUSH_START = 0x30020200,

        /*     2.2.LivePushService SDK错误 0x30020300-0x300203FF */
        ALIVC_PUSHER_ERROR_SDK_LIVE_PUSH_START = 0x30020300,

        /*     2.3.RTMPService SDK错误 0x30020900-0x300209FF */
        ALIVC_PUSHER_ERROR_SDK_PUSH_START = 0x30020900,


        ALIVC_PUSHER_ERROR_SDK_BGM_START = 0x30010500,

        /*  3.网络错误 0x30030000-0x3003FFFF */
        /*  3.1.推流错误 0x30030900-0x300309FF */
        ALIVC_PUSHER_ERROR_NETWORK_RTMP_START = 0x30020900,

        ALIVC_PUSHER_ERROR_NETWORK_ARTP_START = 0x30020A00,
    }  ErrorCode;

    /**
     * @brief 推流异常/错误码枚举
     */
    typedef enum {
        /* 通用错误码 （部分负数）和0x00000000-0x0FFFFFFF */
        ALIVC_COMMON_INVALID_PARAM = -2,
        /* 尽量少用该错误，返回明确的错误值; */
        ALIVC_COMMON_RETURN_FAILED = -1,
        ALIVC_COMMON_RETURN_SUCCESS = 0x00000000,
        
        /* 0.基础组件 0x10000000-0x1FFFFFFF */
        ALIVC_FRAMEWORK_ERROR_THREAD_EXIT = ALIVC_FRAMEWORK_ERROR_START + 1,
        ALIVC_FRAMEWORK_DISPATCH_MSG_FAILED = ALIVC_FRAMEWORK_ERROR_START + 2,
        ALIVC_FRAMEWORK_IS_SYNC_MSG = ALIVC_FRAMEWORK_ERROR_START + 3,
        ALIVC_FRAMEWORK_ERROR_SERVICE_IS_ALREADY_EXIST = ALIVC_FRAMEWORK_ERROR_START + 4,
        ALIVC_FRAMEWORK_ERROR_INVALID_STATE = ALIVC_FRAMEWORK_ERROR_START + 5,
        ALIVC_FRAMEWORK_ERROR_INVALID_ARGUMENT = ALIVC_FRAMEWORK_ERROR_START + 6,
        ALIVC_FRAMEWORK_ERROR_SESSION_REMOVED = ALIVC_FRAMEWORK_ERROR_START + 7,
        ALIVC_FRAMEWORK_ERROR_AUDIO_BUFFER_FULL = ALIVC_FRAMEWORK_ERROR_START + 8,
        ALIVC_FRAMEWORK_ERROR_VIDEO_BUFFER_FULL = ALIVC_FRAMEWORK_ERROR_START + 9,
        ALIVC_FRAMEWORK_ERROR_AUDIO_STREAM = ALIVC_FRAMEWORK_ERROR_START + 10,
        ALIVC_FRAMEWORK_ERROR_AUDIO_FILE_OPEN = ALIVC_FRAMEWORK_ERROR_START + 11,
        ALIVC_FRAMEWORK_ERROR_AUDIO_FORMAT_NOT_SUP = ALIVC_FRAMEWORK_ERROR_START + 12,
        ALIVC_FRAMEWORK_ERROR_UPDATE_ROLE_CHANNEL = ALIVC_FRAMEWORK_ERROR_START + 13,

        /* 队列中没有待处理的命令，即将挂起线程 */
        ALIVC_FRAMEWORK_VIDEO_ENCODER_QUEUE_EMPTY_WARNING = ALIVC_FRAMEWORK_VIDEO_ENCODER_ERROR_START + 1,
        /* 队列中待处理的命令已经堆积超过一定数量，需要外部降低帧率 */
        ALIVC_FRAMEWORK_VIDEO_ENCODER_QUEUE_FULL_WARNING = ALIVC_FRAMEWORK_VIDEO_ENCODER_ERROR_START + 2,
        ALIVC_FRAMEWORK_VIDEO_ENCODER_CREATE_ENCODER_FAILED = ALIVC_FRAMEWORK_VIDEO_ENCODER_ERROR_START + 3,
        ALIVC_FRAMEWORK_VIDEO_ENCODER_WIDTHOUT_MATCH_ENCODER = ALIVC_FRAMEWORK_VIDEO_ENCODER_ERROR_START + 4,
        ALIVC_FRAMEWORK_VIDEO_ENCODER_ERROR_WITHOUT_WORK = ALIVC_FRAMEWORK_VIDEO_ENCODER_ERROR_START + 5,
        ALIVC_FRAMEWORK_VIDEO_ENCODER_ERROR_INTERRUPT = ALIVC_FRAMEWORK_VIDEO_ENCODER_ERROR_START + 6,
        /* 视频编码器出现错误，即将降级 */
        ALIVC_FRAMEWORK_VIDEO_ENCODER_ERROR_FALL_DOWN_CHANGE = ALIVC_FRAMEWORK_VIDEO_ENCODER_ERROR_START + 7,
        /* 视频编码器出现错误，降级动作被禁止 */
        ALIVC_FRAMEWORK_VIDEO_ENCODER_ERROR_DOWNGRADE_DISABLED = ALIVC_FRAMEWORK_VIDEO_ENCODER_ERROR_START + 8,
        /* 编码创建或者使用过程中返回 android 版本过低//0x10003100,以下更改需要对应修改java */
        ALIVC_FRAMEWORK_VIDEO_ENCODER_ERROR_ANDROID_API_LEVEL = 0x10003100,
        ALIVC_FRAMEWORK_VIDEO_ENCODER_ERROR_STATE = 0x10003101,
        ALIVC_FRAMEWORK_VIDEO_ENCODER_ERROR_INPUT = 0x10003102,
        ALIVC_FRAMEWORK_VIDEO_ENCODER_ERROR_NO_BUFFER_AVAILABLE = 0x10003103,

        //0.5.audio encoder
        ALIVC_FRAMEWORK_AUDIO_ENCODER_INIT_FAILED = ALIVC_FRAMEWORK_AUDIO_ENCODER_START + 1,
        ALIVC_FRAMEWORK_AUDIO_ENCODER_ERROR_STATE = ALIVC_FRAMEWORK_AUDIO_ENCODER_START + 2,
        ALIVC_FRAMEWORK_AUDIO_ENCODER_ERROR_INPUT = ALIVC_FRAMEWORK_AUDIO_ENCODER_START + 3,
        ALIVC_FRAMEWORK_AUDIO_ENCODER_ERROR_INTERRUPT = ALIVC_FRAMEWORK_AUDIO_ENCODER_START + 4,
        ALIVC_FRAMEWORK_AUDIO_ENCODER_ERROR_WITHOUT_WORK = ALIVC_FRAMEWORK_AUDIO_ENCODER_START + 5,
        ALIVC_FRAMEWORK_AUDIO_ENCODER_WIDTHOUT_MATCH_ENCODER = ALIVC_FRAMEWORK_AUDIO_ENCODER_START + 6,

        /*  0.6.渲染组件 0x10004000-0x10004FFF */
        ALIVC_FRAMEWORK_RENDER_FIRST_FRAME_PREVIEWED = ALIVC_FRAMEWORK_RENDER_ERROR_START + 1,
        ALIVC_FRAMEWORK_RENDER_ERROR_EGL = ALIVC_FRAMEWORK_RENDER_ERROR_START + 2,
        ALIVC_FRAMEWORK_RENDER_ERROR_GL = ALIVC_FRAMEWORK_RENDER_ERROR_START + 3,
        ALIVC_FRAMEWORK_RENDER_DISPLAY_OPEN_FAILED = ALIVC_FRAMEWORK_RENDER_ERROR_START + 4,
        ALIVC_FRAMEWORK_RENDER_DISPLAY_INTERRUPT = ALIVC_FRAMEWORK_RENDER_ERROR_START + 5,

        /*   0.7 .Capture组件 0x10005000-0x10005FFF */
        ALIVC_PUSHER_ERROR_SDK_CAPTURE_INVALID_STATE = ALIVC_PUSHER_ERROR_SDK_CAPTURE_START + 1,

        ALIVC_PUSHER_ERROR_SDK_CAPTURE_INIT_FAILED = ALIVC_PUSHER_ERROR_SDK_CAPTURE_START + 2,

        ALIVC_PUSHER_ERROR_SDK_CAPTURE_CAMERA_OPEN_FAILED = ALIVC_PUSHER_ERROR_SDK_CAPTURE_START + 3,

        ALIVC_PUSHER_ERROR_SDK_CAPTURE_MIC_OPEN_FAILED = ALIVC_PUSHER_ERROR_SDK_CAPTURE_START + 4,

        ALIVC_PUSHER_EVENT_CAPTURE_AUDIO_START_FAIL = ALIVC_PUSHER_ERROR_SDK_CAPTURE_START + 5,
        ALIVC_PUSHER_EVENT_CAPTURE_VIDEO_START_FAIL = ALIVC_PUSHER_ERROR_SDK_CAPTURE_START + 6,
        ALIVC_PUSHER_ERROR_SDK_CAPTURE_SCREEN_OPEN_FAILED = ALIVC_PUSHER_ERROR_SDK_CAPTURE_START + 7,
        ALIVC_PUSHER_ERROR_SDK_CAPTURE_MIC_INTERRUPT = ALIVC_PUSHER_ERROR_SDK_CAPTURE_START + 8,
        ALIVC_PUSHER_ERROR_SDK_CAPTURE_MIC_AUTH_FAILED = ALIVC_PUSHER_ERROR_SDK_CAPTURE_START + 9,
        ALIVC_PUSHER_ERROR_SDK_CAPTURE_MIC_NOT_AVALIABLE = ALIVC_PUSHER_ERROR_SDK_CAPTURE_START + 10,
        ALIVC_PUSHER_ERROR_SDK_CAPTURE_CAMERA_INTERRUPT = ALIVC_PUSHER_ERROR_SDK_CAPTURE_START + 11,
        ALIVC_PUSHER_ERROR_SDK_SPECIFIED_AUDIO_DEVICE_NOT_FOUND = ALIVC_PUSHER_ERROR_SDK_CAPTURE_START + 12,
        
        /*    1.4.RtmpService 系统错误 0x30010900-0x300109FF */
        ALIVC_LIVE_ERROR_SYSTEM_RTMP_OOM = ALIVC_LIVE_ERROR_SYSTEM_RTMP_START + 1,

        /*     2.1.NativeLivePush SDK错误 0x30020200-0x300202FF */
        ALIVC_PUSHER_ERROR_SDK_NATIVE_LIVE_PUSH_INVALID_STATE = ALIVC_PUSHER_ERROR_SDK_NATIVE_LIVE_PUSH_START + 1,

        /*     2.2.LivePushService SDK错误 0x30020300-0x300203FF */
        ALIVC_PUSHER_ERROR_SDK_LIVE_PUSH_NETWORK_TOO_POOR = ALIVC_PUSHER_ERROR_SDK_LIVE_PUSH_START + 1,
        ALIVC_PUSHER_ERROR_SDK_LIVE_PUSH_ADJUST_BITRATE_FAIL = ALIVC_PUSHER_ERROR_SDK_LIVE_PUSH_START + 2,
        ALIVC_PUSHER_ERROR_SDK_LIVE_PUSH_LOW_PERFORMANCE = ALIVC_PUSHER_ERROR_SDK_LIVE_PUSH_START + 3,
		ALIVC_PUSHER_ERROR_SDK_LIVE_PUSH_DEVICE_NOT_SUPPORT_HEVC = ALIVC_PUSHER_ERROR_SDK_LIVE_PUSH_START + 4,

        /*     2.4.PushService SDK错误 （统一的RTMP、RTS的枚举）0x30020900-0x300209FF */
        ALIVC_PUSHER_ERROR_SDK_PUSH_INVALID_STATE = ALIVC_PUSHER_ERROR_SDK_PUSH_START + 1,
        ALIVC_PUSHER_ERROR_SDK_PUSH_SETUPURL = ALIVC_PUSHER_ERROR_SDK_PUSH_START + 2,
        ALIVC_PUSHER_ERROR_SDK_PUSH_CONNECT = ALIVC_PUSHER_ERROR_SDK_PUSH_START + 3,
        ALIVC_PUSHER_ERROR_SDK_PUSH_CONNECT_STREAM = ALIVC_PUSHER_ERROR_SDK_PUSH_START + 4,
        ALIVC_PUSHER_ERROR_SDK_PUSH_INVALID_URL = ALIVC_PUSHER_ERROR_SDK_PUSH_START + 5,
        ALIVC_PUSHER_ERROR_SDK_PUSH_RECONNECT_FAIL = ALIVC_PUSHER_ERROR_SDK_PUSH_START + 6,
        ALIVC_PUSHER_ERROR_SDK_PUSH_SEND_DATA_TIMEOUT = ALIVC_PUSHER_ERROR_SDK_PUSH_START + 7,
        ALIVC_PUSHER_ERROR_SDK_PUSH_START_PUSH_TIMEOUT = ALIVC_PUSHER_ERROR_SDK_PUSH_START + 8,
        ALIVC_PUSHER_ERROR_SDK_PUSH_ILLEGAL_PARAM = ALIVC_PUSHER_ERROR_SDK_PUSH_START + 9,
        ALIVC_PUSHER_ERROR_SDK_PUSH_RTS_DOWN_TO_RTMP = ALIVC_PUSHER_ERROR_SDK_PUSH_START + 10,
        ALIVC_PUSHER_ERROR_SDK_PUSH_NOT_JOIN_CHANNEL = ALIVC_PUSHER_ERROR_SDK_PUSH_START + 11,
        ALIVC_PUSHER_ERROR_SDK_PUSH_AUDIO_FAIELD = ALIVC_PUSHER_ERROR_SDK_PUSH_START + 12,
        ALIVC_PUSHER_ERROR_SDK_PUSH_VIDEO_FAIELD = ALIVC_PUSHER_ERROR_SDK_PUSH_START + 13,
        ALIVC_PUSHER_ERROR_SDK_PUSH_DUAL_FAIELD = ALIVC_PUSHER_ERROR_SDK_PUSH_START + 14,
        ALIVC_PUSHER_ERROR_SDK_PUSH_SCREEN_SHARED_FAIELD = ALIVC_PUSHER_ERROR_SDK_PUSH_START + 15,
        ALIVC_PUSHER_ERROR_SDK_PUSH_SCREEN_SHARED_CONFIG_FAIELD = ALIVC_PUSHER_ERROR_SDK_PUSH_START + 16,

        ALIVC_PUSHER_ERROR_BGM_OPEN_FAILED = ALIVC_PUSHER_ERROR_SDK_BGM_START + 1,
        ALIVC_PUSHER_ERROR_BGM_TIMEOUT = ALIVC_PUSHER_ERROR_SDK_BGM_START + 2,

        ALIVC_PUSHER_ERROR_SDK_ARTP_INVALID_STATE = ALIVC_PUSHER_ERROR_NETWORK_ARTP_START + 1,

        ALIVC_PUSHER_ERROR_SDK_ARTP_CONNECT_FAILED = ALIVC_PUSHER_ERROR_NETWORK_ARTP_START + 1,
        ALIVC_PUSHER_ERROR_SDK_ARTP_SEND_DATA_TIMEOUT = ALIVC_PUSHER_ERROR_NETWORK_ARTP_START + 2,
        ALIVC_PUSHER_ERROR_SDK_ARTP_CONNECT_LOST = ALIVC_PUSHER_ERROR_NETWORK_ARTP_START + 3,
        ALIVC_PUSHER_ERROR_SDK_ARTP_RECONNECT_FAILED = ALIVC_PUSHER_ERROR_NETWORK_ARTP_START + 4,
        ALIVC_PUSHER_ERROR_SDK_ARTP_RECV_HEARTBEAT_TIMEOUT = ALIVC_PUSHER_ERROR_NETWORK_ARTP_START + 5,
        ALIVC_PUSHER_ERROR_SDK_ARTP_START_PUSH_TIMEOUT = ALIVC_PUSHER_ERROR_NETWORK_ARTP_START + 6,
        ALIVC_PUSHER_ERROR_SDK_ARTP_SEND_SPSPPS_TIMEOUT = ALIVC_PUSHER_ERROR_NETWORK_ARTP_START + 7,
        ALIVC_PUSHER_ERROR_SDK_ARTP_SEN_AACCONF_TIMEOUT = ALIVC_PUSHER_ERROR_NETWORK_ARTP_START + 8,
        ALIVC_PUSHER_ERROR_SDK_ARTP_ILLEGAL_PARAM = ALIVC_PUSHER_ERROR_NETWORK_ARTP_START + 9,
        ALIVC_PUSHER_ERROR_SDK_ARTP_BAD_APPID = ALIVC_PUSHER_ERROR_NETWORK_ARTP_START + 10,
        ALIVC_PUSHER_ERROR_SDK_ARTP_INVALID_APPID = ALIVC_PUSHER_ERROR_NETWORK_ARTP_START + 11,
        ALIVC_PUSHER_ERROR_SDK_ARTP_BAD_CHANNEL = ALIVC_PUSHER_ERROR_NETWORK_ARTP_START + 12,
        ALIVC_PUSHER_ERROR_SDK_ARTP_INVALID_CHANNEL = ALIVC_PUSHER_ERROR_NETWORK_ARTP_START + 13,
        ALIVC_PUSHER_ERROR_SDK_ARTP_BAD_TOKEN = ALIVC_PUSHER_ERROR_NETWORK_ARTP_START + 14,
        ALIVC_PUSHER_ERROR_SDK_ARTP_JOIN_TIMEOUT = ALIVC_PUSHER_ERROR_NETWORK_ARTP_START + 15,
        ALIVC_PUSHER_ERROR_SDK_ARTP_JOIN_BAD_PARAM = ALIVC_PUSHER_ERROR_NETWORK_ARTP_START + 16,
        ALIVC_PUSHER_ERROR_SDK_ARTP_JOIN_CHANNEL_FAILED = ALIVC_PUSHER_ERROR_NETWORK_ARTP_START + 17,
        ALIVC_PUSHER_ERROR_SDK_ARTP_MOBILITY_FAILED = ALIVC_PUSHER_ERROR_NETWORK_ARTP_START + 18,
        ALIVC_PUSHER_ERROR_SDK_ARTP_LOW_LATENCY_LIVE_COMMUNICATION_FAILED = ALIVC_PUSHER_ERROR_NETWORK_ARTP_START + 19,
        ALIVC_PUSHER_ERROR_SDK_ARTP_LOW_LATENCY_LIVE_MEDIA_SETTING_FAILED = ALIVC_PUSHER_ERROR_NETWORK_ARTP_START + 20,
        ALIVC_PUSHER_ERROR_SDK_ARTP_LOW_LATENCY_LIVE_NONE_BROADCAST = ALIVC_PUSHER_ERROR_NETWORK_ARTP_START + 21,
        ALIVC_PUSHER_ERROR_SDK_ARTP_LOW_LATENCY_LIVE_NEED_RESTART = ALIVC_PUSHER_ERROR_NETWORK_ARTP_START + 22,
        ALIVC_PUSHER_ERROR_SDK_ARTP_LOW_LATENCY_LIVE_NEED_RESTART_AGAIN_LATER = ALIVC_PUSHER_ERROR_NETWORK_ARTP_START + 23,
        ALIVC_PUSHER_ERROR_SDK_ARTP_LOW_LATENCY_LIVE_SERVICE_UNAVAILABLE = ALIVC_PUSHER_ERROR_NETWORK_ARTP_START + 24,
        ALIVC_PUSHER_ERROR_SDK_ARTP_LOW_LATENCY_LIVE_MEDIA_CONNECTION_INTERRUPTION = ALIVC_PUSHER_ERROR_NETWORK_ARTP_START + 25,

    }  AlivcLivePushErrorCode;

    typedef enum {
      /** 相机流 */
      AlivcLiveVideoSourceCamera = 0,
      /** 屏幕共享流 */
      AlivcLiveVideoSourceScreenShare = 1,
      /** 占位符，无意义 */
      AlivcLiveVideosourceTypeMax,
    } AlivcLiveVideoSource;

    /**
     * @brief 视频数据类型
     */
    typedef enum {
        AlivcLiveVideoFormatUnknow  = -1,
        AlivcLiveVideoFormatBGRA    = 0,
        AlivcLiveVideoFormatI420    = 1,
        AlivcLiveVideoFormatNV21    = 2,
        AlivcLiveVideoFormatNV12    = 3,
        AlivcLiveVideoFormatRGBA    = 4,
        AlivcLiveVideoFormatI422    = 5,
        AlivcLiveVideoFormatARGB    = 6,
        AlivcLiveVideoFormatABGR    = 7,
        AlivcLiveVideoFormatRGB24   = 8,
        AlivcLiveVideoFormatBGR24   = 9,
        AlivcLiveVideoFormatRGB565  = 10,
        AlivcLiveVideoFormatTextureOES  = 11,
        AlivcLiveVideoFormatTexture2D  = 12,
        AlivcLiveVideoFormatH264  = 13,
        AlivcLiveVideoFormatH265  = 14,
        AlivcLiveVideoFormatFile = 15,
    } AlivcLiveVideoFormat;

    typedef enum {
        AlivcLiveNetworkQualityExcellent = 0,
        AlivcLiveNetworkQualityGood = 1,
        AlivcLiveNetworkQualityPoor = 2,
        AlivcLiveNetworkQualityBad = 3,
        AlivcLiveNetworkQualityVeryBad = 4,
        AlivcLiveNetworkQualityDisconnect = 5,
        AlivcLiveNetworkQualityUnknown = 6,
    } AlivcLiveNetworkQuality;

    /**
     * @brief 视频数据输出位置
     */
    typedef enum {
      /** 采集视频数据，对应输出回调 OnCaptureVideoSample */
      AlivcLivePositionPostCapture = 1 << 0,
      /** 渲染视频数据，对应输出回调 OnRemoteVideoSample */
      AlivcLivePositionPreRender = 1 << 1,
      /** 编码前视频数据，对应输出回调 OnPreEncodeVideoSample */
      AlivcLivePositionPreEncoder = 1 << 2,
    } AlivcLiveVideoObserPosition;

    /**
     * @brief 网络连接状态
     */
    typedef enum {
        /** 初始化完成 */
        AlivcLiveConnectionInit = 0,
        /** 网络连接断开 */
        AlivcLiveConnectionDisconnected,
        /** 建立网络连接中 */
        AlivcLiveConnectionConnecting,
        /** 网络已连接 */
        AlivcLiveConnectionConnected,
        /** 重新建立网络连接中 */
        AlivcLiveConnectionReconnecting,
        /** 网络连接失败 */
        AlivcLiveConnectionFailed,
    } AlivcLiveConnectionStatus;

    /**
     * @brief 网络连接状态变更原因
    */
    typedef enum {
        /** 未知原因 */
        AlivcLiveConnectionChangedDummyReason = 0,
        /** 媒体通道变更 */
        AlivcLiveConnectionMediaPathChanged,
        /** 心跳超时 */
        AlivcLiveConnectionSignalingHeartbeatTimeout,
        /** 心跳恢复 */
        AlivcLiveConnectionSignalingHeartbeatAlive,
        /** DNS解析成功 */
        AlivcLiveConnectionSignalingHttpdnsResolved,
        /** DNS解析失败 */
        AlivcLiveConnectionSignalingHttpdnsFailure,
        /** GSLB请求失败 */
        AlivcLiveConnectionSignalingGslbFailure,
        /** GSLB请求成功 */
        AlivcLiveConnectionSignalingGslbSucccess,
        /** 加入频道失败 */
        AlivcLiveConnectionSignalingJoinChannelFailure,
        /** 加入频道成功 */
        AlivcLiveConnectionSignalingJoinChannelSuccess,
        /** 离开频道 */
        AlivcLiveConnectionSignalingLeaveChannel,
        /** 信令建立连接 */
        AlivcLiveConnectionSignalingConnecting,
        /** 网络连接中断 */
        AliRtcConnectionChangedNetworkInterrupted,
    } AlivcLiveConnectionStatusChangeReason;


        /**
     * @brief onBye类型
     */
    typedef enum {
        /** 当前user被踢出channel */
        AlivcLiveOnByeBeKickOut            = 1,
        /** channel已结束，需要离开会议 */
        AlivcLiveOnByeChannelTerminated    = 2,
        /** 相同userID在其他设备 JoinChannel，当前设备被下线 */
        AlivcLiveOnByeUserReplaced         = 3,
    } AlivcLiveOnByeType;

    /**
     * @brief 音频数据源类型
     */
    typedef enum {
        /** 采集的音频数据 */
        AlivcLiveAudioSourceCaptured = 0,
        /** 3A后的音频数据 */
        AlivcLiveAudioSourceProcessCaptured = 1,
        /** 推流的音频数据 */
        AlivcLiveAudioSourcePub = 2,
        /** 播放的音频数据 */
        AlivcLiveAudioSourcePlayback = 3,
        /** 推流和播放混音后的音频数据 */
        AlivcLiveAudioSourceMixedAll = 4,
        /** 拉流的远端音频数据 */
        AlivcLiveAudioSourceRemoteUser = 5,
    } AlivcLiveAudioSource;


    typedef struct  {
        /**
         * 用户id
         */
        const char* userId;

        /**
         * 房间号
         */
        const char* channelId;

        /**
         * 视频宽度
         */
        int videoWidth;

        /**
         * 视频高度
         */
        int videoHeight;

        /**
         * 编码帧率
         */
        int decodeFps;

        /**
         * 渲染帧率
         */
        int renderFps;

        /**
         * 视频码率
         * <p>
         * 单位：kbps
         */
        int videoBitrate;

        /**
         * 音频码率
         * <p>
         * 单位：kbps
         */
        int audioBitrate;

        /**
         * 音频丢包率
         */
        int audioLossRate;

        /**
         * 丢包率
         */
        int lossRate;

        /**
         * 视频丢包率
         */
        int videoLossRate;

        /**
         * 视频播放的累计卡顿时长，单位ms
         */

        int totalVideoFrozenTime;

        /**
         视频播放的卡顿率，单位% 计算方法 视频播放卡顿率=视频播放的累计卡顿时长/视频播放的总时长
        */
        int videoFrozenRate;

        /**
         远端用户加入频道后音频卡顿的累计时长(ms)
        */
        int totalAudioFrozenTime;

        /**
         音频播放卡顿率 单位% 计算方法 音频播放卡顿率=音频播放的累计卡顿时长/音频播放的总时长
        */
        int audioFrozenRate;

        /**
         音频链路发送端到接收端的网络延时（ms)
        */
        int networkTransportDelay;

        /**
         音频链路接收端到网络抖动缓存的网络延时（ms)
        */
        int jitterBufferDelay;
    } AlivcLivePlayerStatsInfo;

    /**
     * @brief 视频数据格式
     */
    typedef enum {
        /** 裸数据格式 */
        AlivcLiveBufferTypeRawData          = 0,
        /** 纹理格式 */
        AlivcLiveBufferTypeTexture,
        /** 文件路径格式 */
        AlivcLiveBufferTypeFile,
    } AlivcLiveBufferType;

    /**
     * @brief 推流错误码及描述
     */
    typedef struct  
    {
        AlivcLivePushErrorCode code;
        const char* msg;
    }AlivcLivePushError;


    /**
     * @brief 视频裸数据
     */
    typedef struct AlivcLiveVideoRawData {
        AlivcLiveVideoFormat format = AlivcLiveVideoFormatUnknow;
        AlivcLiveBufferType type    = AlivcLiveBufferTypeRawData;
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
#if defined(WEBRTC_ANDROID)
        long shared_context = 0;
        bool egl_change = false;  
#endif              
    } AlivcLiveVideoRawData;

    /**
     * @brief 音频裸数据
     */
    typedef struct AlivcLiveAudioRawData {
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
    } AlivcLiveAudioRawData;

    /**
     * @brief 拉流异常/错误码枚举
     */
    typedef enum {
        /*  播放URL指定的播放流不存在 */
        AlivcLivePlayErrorStreamNotFound = 1,
        /*  播放URL指定的播放流已停止推流 */
        AlivcLivePlayErrorStreamStopped = 2,
    }  AlivcLivePlayError;

    /**
     * @brief 音频混流类型枚举
     */
    typedef enum {
        /*  本地音频 */
        AlivcLiveUserVolumeLocal = 0,
        /*  远端混流音频 */
        AlivcLiveUserVolumeRemoteMix = 1,
        /*  远端用户音频 */
        AlivcLiveUserVolumeRemoteUser = 2,
    }AlivcLiveUserVolumeEnum;

    /**
     * @brief 视频流类型
     */
    typedef enum {
        /** 无视频流 */
        AlivcLiveVideoTrackNo     = 0,
        /** 相机流 */
        AlivcLiveVideoTrackCamera = 1,
        /** 屏幕共享流 */
        AlivcLiveVideoTrackScreen = 2,
        /** 相机流和屏幕共享流 */
        AlivcLiveVideoTrackBoth   = 3,
    } AlivcLiveVideoTrack;

    /**
     * @brief 音频track的类型
    */
    typedef enum {
      /** 无麦克风 */
      AlivcLiveAudioTrackNo = 0,
      /** 麦克风 */
      AlivcLiveAudioTrackMic = 1,
      /** 占位符 */
      AlivcLiveAudioTrackEnd = 0xffffffff
    } AlivcLiveAudioTrack;

    
	/*
	编码器解码器类型 VideoCodecManufacturer
	*/
	typedef enum {
		AlivcVideoCodecManufactureropenH264 = 0,
		AlivcVideoCodecManufacturerX264 = 1,
		AlivcVideoCodecManufacturerX265 = 2,
		AlivcVideoCodecManufacturerS265 = 3,
		AlivcVideoCodecManufacturerFFMPEG = 4,
        AlivcVideoCodecManufacturerS264 = 5,
		AlivcVideoCodecManufacturerQsvIntel = 0x10,
		AlivcVideoCodecManufacturerNvidia = 0x11,
		AlivcVideoCodecManufacturerAMD = 0x12,
		AlivcVideoCodecManufacturerMicrosoft = 0x13,
		AlivcVideoCodecManufacturerVideoToolbox = 0x20,
		AlivcVideoCodecManufacturerMediaCodec = 0x30,

        AlivcVideoCodecManufacturerUnknown = 0xFFFF,
	}AlivcVideoCodecManufacturer;


    /**
     * @brief 本地视频统计信息
     */
    typedef struct AlivcLiveLocalVideoStats {
        AlivcLiveVideoTrack track;
        unsigned int targetEncodeBitrate = 0;
        unsigned int actualEncodeBitrate = 0;
        unsigned int sentBitrate = 0;
        unsigned int sentFps = 0;
        unsigned int encodeFps = 0;
        unsigned int avgQpPerSec = 0;
    } AlivcLiveLocalVideoStats;

    /**
     * @brief 本地音频统计信息
     */
    typedef struct AlivcLiveLocalAudioStats {
        AlivcLiveAudioTrack track;
        unsigned int sentBitrate = 0;
        unsigned int sentSamplerate = 0;
        unsigned int numChannel = 0;
        unsigned int inputLevel = 0;
    } AlivcLiveLocalAudioStats;

    /**
     * @brief 发言人音量信息
     */
    typedef struct AlivcLiveUserVolumeInfo {
        /** 用户类型 */
        AlivcLiveUserVolumeEnum userType = AlivcLiveUserVolumeEnum::AlivcLiveUserVolumeLocal;
        /** 用户对象指针 userType与userPtr对应关系为：
         * AlivcLiveUserVolumeLocal : AlivcLivePusher
         * AlivcLiveUserVolumeRemoteMix: nullptr
         * AlivcLiveUserVolumeRemoteUser: AlivcLivePlayer
         * */
        void *userPtr = nullptr;
        /** 语音状态，1：当前在说话，0：当前未说话 */
        bool speechState = 0;
        /** 音量，取值范围[0,255] */
        int volume = 0;
        /** 回调周期内累计的音量, 用于判别当前说话人，取值范围[0,255] */
        int sumVolume = 0;
    } AlivcLiveUserVolumeInfo;

    /**
     * @brief 编码器使用信息信息
     */
    typedef struct AlivcLiveEncoderNotifyInfo {
        AlivcLiveVideoTrack videoTrack = AlivcLiveVideoTrack::AlivcLiveVideoTrackNo;
        AlivcVideoCodecManufacturer encoderManufacturer = AlivcVideoCodecManufacturer::AlivcVideoCodecManufacturerUnknown;
    } AlivcLiveEncoderNotifyInfo;

	/**
	* @brief 解码器使用信息信息
	*/
	typedef struct AlivcLiveDecoderNotifyInfo {
		AlivcLiveVideoTrack videoTrack = AlivcLiveVideoTrack::AlivcLiveVideoTrackNo;
		AlivcVideoCodecManufacturer decoderManufacturer = AlivcVideoCodecManufacturer::AlivcVideoCodecManufacturerUnknown;
	} AlivcLiveDecoderNotifyInfo;

    /**
     * @brief 视图显示模式
     */
    typedef enum {
        /** 自动模式 */
        AlivcLiveRenderModeAuto     = 0,
        /** 拉伸平铺模式 ，如果外部输入的视频宽高比和推流设置的宽高比不一致时，将输入视频拉伸到推流设置的比例，画面会变形*/
        AlivcLiveRenderModeStretch  = 1,
        /** 填充黑边模式，如果外部输入的视频宽高比和推流设置的宽高比不一致时，将输入视频上下或者左右填充黑边 */
        AlivcLiveRenderModeFill     = 2,
        /** 裁剪模式，如果外部输入的视频宽高比和推流设置的宽高比不一致时，将输入视频宽或者高进行裁剪，画面内容会丢失 */
        AlivcLiveRenderModeCrop     = 3,
        /** 已废弃 */
        AlivcLiveRenderModeScroll   = 4,
        /** 沿用之前的显示模式 */
        AlivcLiveRenderModeNoChange = 99,
    } AlivcLiveRenderMode;

    typedef struct AlivcLiveFileInputConfig{
      bool enableVideo = false;
      bool enableAudioPush = false;
      bool enableAudioRender = false;

      String filePath;
      AlivcLiveVideoTrack type = AlivcLiveVideoTrackCamera;
      bool enableLoop = false;

      int renderVolume = 100;
      int pushVolume = 100;
      AlivcLiveExternalFileObserver *observer = nullptr;
    } AlivcLiveFileInputConfig;

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
    } AlivcLiveExternalFileState;

    /**
     * @brief 文件播放错误码，用于返回异常原因
     */
    typedef enum {
        AlivcLiveExternalFileErrorNone = 0,
        /* 打开文件失败，请检查文件路径是否正确 */
        AlivcLiveExternalFileErrorFileOpenFailed = 1,
        /* 文件格式不支持 */
        AlivcLiveExternalFileErrorNotAllowdMuxer = 2,
        /* 视频编码类型不支持 */
        AlivcLiveExternalFileErrorNotAllowdVideoCodec = 3,
        /* 音频编码类型不支持 */
        AlivcLiveExternalFileErrorNotAllowdAudioCodec = 4,
        /* 解码视频帧异常 */
        AlivcLiveExternalFileErrorDecodeVideo = 5,   
        /* 解码音频帧异常 */     
        AlivcLiveExternalFileErrorDecodeAudio = 6,   
        /* 跳转位置异常 */
        AlivcLiveExternalFileErrorSeekPos = 7,  
        /* 暂停异常，未处于可暂停的状态 */
        AlivcLiveExternalFileErrorPause = 8,
        /* 恢复播放异常，未处于暂停状态 */
        AlivcLiveExternalFileErrorResume = 9,
        /* 没有视频资源可以输入，视频外部输入资源已被占用 */
        AlivcLiveExternalNoVideoSourceUse = 10,
        /* 没有音频资源可以输入，音频外部输入资源已被占用 */
        AlivcLiveExternalNoAudioSourceUse = 11,
    } AlivcLiveExternalFileError;

    /**
     * @brief 推流错误监听器
     */
    class ALIVC_LIVE_API AlivcLivePushErrorListener {
    public:
        
        virtual ~AlivcLivePushErrorListener() = default;

        /**
         * @brief 系统错误回调
         * @param livePusher AlivcLivePusher实例
         * @param error      异常
         */
        virtual void onSystemError(AlivcLivePusher* livePusher, AlivcLivePushError error){};

        /**
         * @brief SDK错误回调
         * @param livePusher AlivcLivePusher实例
         * @param error      异常
         */
        virtual void onSDKError(AlivcLivePusher* livePusher, AlivcLivePushError error) {};
    };

    /**
     * @brief 推流通知监听器
     */
    class ALIVC_LIVE_API AlivcLivePushInfoListener  {
    public:
        virtual ~AlivcLivePushInfoListener() = default;

        /**
         * @brief 预览开始回调
         * @param pusher AlivcLivePusher实例
         */
        virtual void onPreviewStarted(AlivcLivePusher* pusher){};

         /**
         * @brief 预览结束回调
         * @param pusher AlivcLivePusher实例
         */
        virtual void onPreviewStopped(AlivcLivePusher* pusher){};

        /**
         * @brief  推流开始回调
         * @param pusher AlivcLivePusher实例
         */
        virtual void onPushStarted(AlivcLivePusher* pusher){};

         /**
         * @brief 推流结束回调
         * @param pusher AlivcLivePusher实例
         */
        virtual void onPushStopped(AlivcLivePusher* pusher){};

        /**
         * @brief  暂停开始回调
         * @param pusher AlivcLivePusher实例
         */
        virtual void onPushPaused(AlivcLivePusher* pusher){};

         /**
         * @brief 恢复结束回调
         * @param pusher AlivcLivePusher实例
         */
        virtual void onPushResume(AlivcLivePusher* pusher){};
        
        /**
         * @brief 首帧发送回调
         * @param pusher AlivcLivePusher实例
         */
        virtual void onFirstFramePushed(AlivcLivePusher* pusher){};
        
        /**
         * @brief 订阅的音频音量回调，其中uid为"0"表示本地推流音量
         * @param volumeInfo 说话人音量信息
         * @param volumeInfoCount 回调的说话人的个数
         * @param totalVolume 混音后的总音量，范围[0,255]。在本地用户的回调中，totalVolume;为本地用户混音后的音量
         */
        virtual void onAudioVolumeCallback(const AlivcLiveUserVolumeInfo* volumeInfo, int volumeInfoCount, int totalVolume) {};

        /**
         * @brief 订阅的当前说话人，当前时间段说话可能性最大的用户uid。
         * @param userPtr 说话人的对象指针
         */
        virtual void onActiveSpeaker(AlivcLivePusher *userPtr) {};

        /**
         * @brief 设置云端的混流（转码）参数回调，对应于setLiveMixTranscodingConfig接口
         * 仅互动模式下生效！！！
         *
         * @param pusher    AlivcLivePusher实例
         * @param isSuccess true表示成功，false表示失败
         * @param msg       错误信息
         */
        virtual void onSetLiveMixTranscodingConfig(AlivcLivePusher* pusher, bool isSuccess, String msg){};

        /**
         * @brief 被服务器踢出频道的消息
         * @param pusher    AlivcLivePusher实例
         * @param code onBye类型，详见 {@link AlivcLiveOnByeType}
         */
        virtual void onBye(AlivcLivePusher* pusher, int code) {};

        /**
         * @brief 本地视频统计信息
         * @param localVideoStats 本地视频统计信息
         * @note SDK每两秒触发一次此统计信息回调
         */
        virtual void onLocalVideoStats(AlivcLivePusher* pusher, const AlivcLiveLocalVideoStats& localVideoStats) {};

        /**
         * @brief 本地音频统计信息
         * @param localAudioStats 本地视频统计信息
         * @note SDK每两秒触发一次此统计信息回调
         */
        virtual void onLocalAudioStats(AlivcLivePusher* pusher, const AlivcLiveLocalAudioStats& localAudioStats) {};

        /**
         * @brief 推流使用的编码器信息回调
         * @param localAudioStats 本地视频统计信息
         * @note 推流开始后通知用户
         */
        virtual void onPushEncoderNotify(AlivcLivePusher* pusher, const AlivcLiveEncoderNotifyInfo& encoderNotifyInfo) {};

    };

    /**
     * @brief 拉流播放通知回调
     */
    class ALIVC_LIVE_API AlivcLivePlayInfoListener   {
    public:
         /**
          * 
         * @brief 开始播放回调
         * @param player AlivcLivePlayer
         */
        virtual void onPlayStarted(AlivcLivePlayer* player){};

        /**
         * @brief 结束播放回调
         * @param player AlivcLivePlayer
         */
        virtual void onPlayStopped(AlivcLivePlayer* player){};

        /**
         * @brief 视频播放回调
         * @param player AlivcLivePlayer
         */
        virtual void onFirstVideoFrameDrawn(AlivcLivePlayer* player){};

        /**
         * @brief 错误回调
         * @param player AlivcLivePlayer
         * @param code 错误码
         * @param msg  错误信息
         */
        virtual void onError(AlivcLivePlayer* player, AlivcLivePlayError code, const char* msg){};

        /**
         * 拉流网络状态变化回调
         * @param player AlivcLivePlayer
         * @param quality 状态值
         */
        virtual void onNetworkQualityChange(AlivcLivePlayer* player, AlivcLiveNetworkQuality quality) {};

        /**
         * @brief 拉流统计数据回调
         * @param player AlivcLivePlayer
         * @param statsInfo 统计数据
         */
        virtual void onPlayerStatistics(AlivcLivePlayer* player, AlivcLivePlayerStatsInfo statsInfo) {};
        
        /**
         * @brief 订阅的音频音量回调，其中uid为"1"表示远端混音音量，其他表示远端用户音量
         * @param volumeInfo 说话人音量信息
         * @param volumeInfoCount 回调的说话人的个数
         * @param totalVolume 混音后的总音量，范围[0,255]。在远端用户的回调中，totalVolume; 为所有说话者混音后的总音量
         */
        virtual void onAudioVolumeCallback(const AlivcLiveUserVolumeInfo* volumeInfo, int volumeInfoCount, int totalVolume) {};

        /**
         * @brief 订阅的当前说话人，当前时间段说话可能性最大的用户uid。
         * @param userType 说话人的用户类型
         * @param userPtr 说话人的对象指针
         * AlivcLiveUserVolumeRemoteMix: nullptr
         * AlivcLiveUserVolumeRemoteUser: AlivcLivePlayer
         */
        virtual void onActiveSpeaker(AlivcLiveUserVolumeEnum userType, AlivcLivePlayer *userPtr) {};

		/**
		* @brief 使用的解码器变更通知
		* @param decoderNotifyInfo 解码器变更通知
		* @note 解码器变更时通知客户
		*/
		virtual void onPlayerDecoderNotify(AlivcLivePlayer* player, const AlivcLiveDecoderNotifyInfo& decoderNotifyInfo) {};

    };

    /**
     * @brief 网络状态通知回调
     */
    class ALIVC_LIVE_API AlivcLivePushNetworkListener {
    public:
        /**
         * 网络差通知
         *
         * @param pusher AlivcLivePusher实例
         */
        virtual void onNetworkPoor(AlivcLivePusher* livePusher) = 0;
        /**
         * 网络恢复通知
         *
         * @param pusher AlivcLivePusher实例
         */
        virtual void onNetworkRecovery(AlivcLivePusher* livePusher) = 0;
        /**
         * 重连开始
         *
         * @param pusher AlivcLivePusher实例
         */
        virtual void onReconnectStart(AlivcLivePusher* livePusher) = 0;
        /**
         * 连接被断开
         *
         * @param pusher AlivcLivePusher实例
         */
        virtual void onConnectionLost(AlivcLivePusher* livePusher) = 0;
        /**
         * 重连失败
         *
         * @param pusher AlivcLivePusher实例
         */
        virtual void onReconnectFail(AlivcLivePusher* livePusher) = 0;
        /**
         * 重连失败
         *
         * @param pusher AlivcLivePusher实例
         */
        virtual void onReconnectSucceed(AlivcLivePusher* livePusher) = 0;
        /**
         * 发送数据超时
         *
         * @param pusher AlivcLivePusher实例
         */
        virtual void onSendDataTimeout(AlivcLivePusher* livePusher) = 0;
        /**
         * 连接失败
         *
         * @param pusher AlivcLivePusher实例
         */
        virtual void onConnectFail(AlivcLivePusher* livePusher) = 0;
        /**
         * 鉴权过期
         *
         * @param pusher AlivcLivePusher实例
         * @return 推流地址
         */
        virtual void onPushURLAuthenticationOverdue(AlivcLivePusher* livePusher) = 0;
        /**
         * 发送sei
         *
         * @param pusher AlivcLivePusher实例
         */
        virtual void onSendMessage(AlivcLivePusher* livePusher) = 0;
        /**
         * 推流过程丢包回调
         *
         * @param pusher AlivcLivePusher实例
         */
        virtual void onPacketsLost(AlivcLivePusher* livePusher) = 0;

        /**
         * @brief 网络连接状态改变的回调
         * @param status 当前网络链接状态，参考 {@link AlivcLiveConnectionStatus}
         * @param reason 网络链接状态改变原因，参考 {@link AlivcLiveConnectionStatusChangeReason}
         */
        virtual void onConnectionStatusChange(int status, int reason) = 0;

        /**
         * 推流网络状态变化回调
         * @param quality 状态值
         */
        virtual void onNetworkQualityChange(AlivcLiveNetworkQuality quality) = 0;
    };

    /**
     * @brief 视频帧通知回调
     */
    class ALIVC_LIVE_API AlivcLiveVideoFrameListener   {
    public:
        /**
         * @brief 订阅的本地采集视频数据回调
         * @param livePusher AlivcLivePusher实例
         * @param videoSource 视频数据源
         * @param videoRawData 视频裸数据
         * @return
         * - true: 需要写回SDK（只对I420）
         * - false: 不需要写回SDK
         */
        virtual bool onCaptureVideoSample(AlivcLivePusher* livePusher, AlivcLiveVideoSource videoSource, AlivcLiveVideoRawData &videoRawData) = 0;
        
        /**
         * @brief 订阅的远端视频数据回调
         * @param player AlivcLivePlayer实例
         * @param videoSource 视频数据源
         * @param videoRawData 视频裸数据
         * @return
         * - true: 需要写回SDK（只对I420）
         * - false: 不需要写回SDK
         */
        virtual bool onRemoteVideoSample(AlivcLivePlayer* player, AlivcLiveVideoSource videoSource, AlivcLiveVideoRawData &videoRawData) = 0;

        /**
         * @brief 订阅的本地编码前视频数据回调
         * @param livePusher AlivcLivePusher实例
         * @param videoSource 视频数据源
         * @param videoRawData 视频裸数据
         * @return
         * - true: 需要写回SDK（只对I420）
         * - false: 不需要写回SDK
         */
        virtual bool onPreEncodeVideoSample(AlivcLivePusher* livePusher, AlivcLiveVideoSource videoSource, AlivcLiveVideoRawData &videoRawData) = 0;
          
        /**
         * @brief 视频数据输出内容
         * @return 期望视频输出内容，参考 {@link AliEngineVideoObserPosition}
         */
        virtual uint32_t getObservedFramePosition() { return static_cast<uint32_t>(AlivcLivePositionPostCapture | AlivcLivePositionPreRender); };

    };

    /**
     * @brief 音频数据监听接口
     */
    class ALIVC_LIVE_API AlivcLiveAudioFrameListener {
    public:
        virtual ~AlivcLiveAudioFrameListener() {}
        /**
         * @brief 推流数据回调
         * @details 默认关闭，需要通过enableAudioFrameObserver : YES audioSource: AlivcLiveAudioSourcePlayback 开启
         * 
         *  - 该接口支持设置采样率、声道数
         *  - 该接口只支持只读模式
         *
         * @param audioRawData 音频数据,详见{@link AlivcLiveAudioRawData}
         * @return true: success
         * @note 请不要在此回调函数中做任何耗时操作，否则可能导致声音异常
         */
        virtual bool onPublishAudioFrame(AlivcLiveAudioRawData audioRawData) = 0;

        /**
         * @brief 播放数据回调
         * @details 默认关闭，需要通过enableAudioFrameObserver : YES audioSource: AlivcLiveAudioSourcePlayback 开启
         *
         *  - 该接口支持设置采样率、声道数
         *  - 该接口支持读写模式
         *
         * @param audioRawData 音频数据,详见{@link AlivcLiveAudioRawData}
         * @return true: success
         * @note 请不要在此回调函数中做任何耗时操作，否则可能导致声音异常
         */
        virtual bool onPlaybackAudioFrame(AlivcLiveAudioRawData audioRawData) = 0;

        /**
         * @brief 采集裸数据回调
         * @details 默认关闭，需要通过enableAudioFrameObserver : YES audioSource: AlivcLiveAudioSourceCaptured 开启
         *
         *  - 该接口支持设置采样率、声道数
         *  - 该接口支持读写模式
         *
         * @param audioRawData 音频数据,详见{@link AlivcLiveAudioRawData}
         * @return true: success
         * @note 请不要在此回调函数中做任何耗时操作，否则可能导致声音异常
         */
        virtual bool onCapturedAudioFrame(AlivcLiveAudioRawData audioRawData) = 0;
        
        /**
         * @brief 3A后数据回调
         * @details 默认关闭，需要通过enableAudioFrameObserver : YES audioSource: AlivcLiveAudioSourceCaptured 开启
         *
         *  - 该接口支持设置采样率、声道数
         *  - 该接口支持读写模式
         *
         * @param audioRawData 音频数据,详见{@link AlivcLiveAudioRawData}
         * @return true: success
         * @note 请不要在此回调函数中做任何耗时操作，否则可能导致声音异常
        */
        virtual bool onProcessCapturedAudioFrame(AlivcLiveAudioRawData audioRawData) = 0;

        /**
         * @brief 推流数据和播放数据混音后回调
         * @details 默认关闭，需要通过enableAudioFrameObserver : YES audioSource: AlivcLiveAudioSourceMixedAll 开启
         *
         *  - 该接口支持设置采样率、声道数
         *  - 该接口支持读写模式
         *
         * @param audioRawData 音频数据,详见{@link AlivcLiveAudioRawData}
         * @return true: success
         * @note 请不要在此回调函数中做任何耗时操作，否则可能导致声音异常
         */
        virtual bool onMixedAllAudioFrame(AlivcLiveAudioRawData audioRawData) = 0;

        /**
         * @brief 远端拉流数据回调，player使用
         * @details 默认关闭，需要通过player的enableAudioFrameObserver : YES 开启
         *
         *  - 该接口不支持设置采样率、声道数
         *  - 该接口支持读写模式
         *
         * @param audioRawData 音频数据,详见{@link AlivcLiveAudioRawData}
         * @return true: success
         * @note 请不要在此回调函数中做任何耗时操作，否则可能导致声音异常
         */
        virtual bool onRemoteUserAudioFrame(AlivcLivePlayer* player, AlivcLiveAudioRawData audioRawData) = 0; 
    };


    /**
     * @addtogroup AlivcLiveCallback 回调及监听
     * AliRtc 回调及监听
     * @{
     */
    /**
     * @brief 音频数据监听接口
     */
    class ALIVC_LIVE_API AlivcLiveExternalFileObserver {
    public:
        virtual ~AlivcLiveExternalFileObserver() {}
        /**
         * @brief 文件播放状态回调
         * @param stateCode 播放状态，详情见AlivcLiveExternalFileState
         */
        virtual void onExternalFileState(AlivcLiveExternalFileState stateCode) = 0;
        /**
         * @brief 文件播放异常状态回调
         * @param errorCode 异常状态，详情见AlivcLiveExternalFileError
         */
        virtual void onExternalFileError(AlivcLiveExternalFileError errorCode) = 0;    

        /**
         * @brief 文件当前总长度回调
         * @param durationMs 文件长度，单位ms
         */    
        virtual void onExternalFileDuration(int64_t durationMs) = 0;

        /**
         * @brief 文件当前播放位置回调
         * @param currentMs 文件长度，单位ms
         */    
        virtual void onExternalFileCurrentPlayPosition(int64_t currentMs) = 0;
        
        /**
         * @brief 文件当前分辨率基本信息
         * @param width 宽
         * @param height 高
         */
        virtual void onExternalFileResolution(int width, int height) = 0;
    };


}; // namespace AliVCSDK_ARTC
#endif /* ali_vc_live_listener_h */
