#ifndef ali_vc_live_pusher_h
#define ali_vc_live_pusher_h
/**
* ref doc: https://aliyuque.antfin.com/zxhy15/wubm3l/kaigbrn3gu1klczx
* ref git: https://code.alibaba-inc.com/aliyun-live/AliLivePushSDK/
* ref branch: blob/release/aio/v1.9.0/
* ref code: android/alivc-livepusher-lib/src/main/java/com/alivc/live/pusher/AlivcLivePusher.java
**/

#include "alivc_live_define.h"
#include "alivc_live_utils.h"
#include "alivc_live_listener.h"
/**
 * @brief AliVCSDK_ARTC namespace/
 */
namespace AliVCSDK_ARTC
{
    /**
     * @brief 【阿里云直播】-推拉流模式
     * 互动版SDK：支持基础模式、互动模式，即推送RTMP流(rtmp://)、RTS流(artc://)、直播连麦PK实时RTC流(artc://)
     * @see <a href="https://help.aliyun.com/document_detail/449478.html">直播连麦文档</a>
     */
    typedef enum {
        /**
         * 基础模式（默认模式）
         * 常规的RTMP推流、RTS推流，不支持连麦、PK等实时互动；
         * 如果一场直播没有互动需求，建议使用该模式；
         */
        AlivcLiveBasicMode = 0,

        /**
         * 互动模式
         * 支持连麦、PK等实时互动；
         * 如果一场直播有互动需求，建议使用该模式；
         */
        AlivcLiveInteractiveMode = 1,
    }AlivcLiveMode;

    /**
     * @brief 推流编码模式
     */
    typedef enum {
        /*硬件编码模式*/
        Encode_MODE_HARD = 0,
        /*软件编码模式*/
        Encode_MODE_SOFT = 1,
    }AlivcEncodeModeEnum;

    /**
    * @brief 设备连接类型
    */
    typedef enum {
        AlivcLiveDeviceTransportTypeUnknown         = 0,
        AlivcLiveDeviceTransportTypeBuiltIn         = 1,
        AlivcLiveDeviceTransportTypeBluetooth       = 2,
        AlivcLiveDeviceTransportTypeUSB             = 3,
        AlivcLiveDeviceTransportTypeAggregate       = 4,
        AlivcLiveDeviceTransportTypeVirtual         = 5,
        AlivcLiveDeviceTransportTypePCI             = 6,
        AlivcLiveDeviceTransportTypeFireWire        = 7,
        AlivcLiveDeviceTransportTypeBluetoothLE     = 8,
        AlivcLiveDeviceTransportTypeHDMI            = 9,
        AlivcLiveDeviceTransportTypeDisplayPort     = 10,
        AlivcLiveDeviceTransportTypeAirPlay         = 11,
        AlivcLiveDeviceTransportTypeAVB             = 12,
        AlivcLiveDeviceTransportTypeThunderbolt     = 13
    } AlivcLiveDeviceTransportType;

    /**
     * @brief 本地静音模式
     */
    typedef enum {
        /** 默认模式(静音全部，包括麦克风及外部输入音频) */
        AlivcLiveMuteLocalAudioModeDefault        = 0,
        /** 静音全部(包括麦克风及外部输入音频) */
        AlivcLiveMuteLocalAudioModeMuteAll,
        /** 只静音麦克风 */
        AlivcLiveMuteLocalAudioModeMuteOnlyMic,
    } AlivcLiveMuteLocalAudioMode;

	/**
     * @brief 采集偏好
     */
    typedef enum {
        AlivcLiveCaptureOutputPreferenceAuto = 0,
        /** 根据设置的publsh profile 分辨率和帧率，选择最接近的摄像头输出参数 */
        AlivcLiveCaptureOutputPreferencePerformance = 1,
        /** 选择较高的摄像头输出参数 */
        AlivcLiveCaptureOutputPreferencePreview = 2,
    } AlivcLiveCaptureOutputPreference;

    enum AlivcLiveResolutionEnum {
        /**
         * 180P
         */
        AlivcLiveResolution180P,

        /**
         * 240P
         */
        AlivcLiveResolution240P,

        /**
         * 360P
         */
        AlivcLiveResolution360P,

        /**
         * 480P
         */
        AlivcLiveResolution480P,

        /**
         * 540P
         */
        AlivcLiveResolution540P,

        /**
         * 720P
         */
        AlivcLiveResolution720P,

        /**
         * 1080P
         */
        AlivcLiveResolution1080P,

        /**
         * 自定义
         */
        AlivcLiveResolutionSelfDefine,
        /**
         * pass through only used for external main video stream
         */
        AlivcLivePushResolutionPassThrough,
    };

    /**
     * @brief 视频帧率
     */
    enum AlivcLiveFrameRate {
        /** 5: 5 fps */
        AlivcLiveFrameRateFps5 = 5,
        /** 10: 10 fps */
        AlivcLiveFrameRateFps10 = 10,
        /** 15: 15 fps */
        AlivcLiveFrameRateFps15 = 15,
        /** 20: 20 fps */
        AlivcLiveFrameRateFps20 = 20,
        /** 25: 25 fps */
        AlivcLiveFrameRateFps25 = 25,
        /** 30: 30 fps */
        AlivcLiveFrameRateFps30 = 30,
        /** 60: 60 fps */
        AlivcLiveFrameRateFps60 = 60,
    };

    enum AlivcLiveVideoEncodeGopEnum {
        /**
         * GOP 为1秒
         */
        AlivcLiveVideoEncodeGopOne = 1,

        /**
         * GOP 为2秒
         */
        AlivcLiveVideoEncodeGopTwo = 2,

        /**
         * GOP 为3秒
         */
        AlivcLiveVideoEncodeGopThree = 3,

        /**
         * GOP 为4秒
         */
        AlivcLiveVideoEncodeGopFour = 4,

        /**
         * GOP 为5秒
         */
        AlivcLiveVideoEncodeGopFive = 5,
    };

    enum AlivcLivePreviewOrientationEnum {
        /**
         * 竖屏
         */
        AlivcLivePreviewOrientationPortRait = 0,

        AlivcLivePreviewOrientationLandscape = 1,
    };

    typedef enum {
        AlivcLiveCapturePipelineSaleModePre = 0,
        AlivcLiveCapturePipelineSaleModePost = 1,
    } AlivcLiveCapturePipelineScaleMode;

    typedef enum  {
        /** 预览和编码均关闭镜像 */
        AlivcLiveVideoPipelineMirrorModeNoMirror = 0,
        /** 预览和编码均打开镜像 */
        AlivcLiveVideoPipelineMirrorModeBothMirror = 1,
        /** 仅预览打开镜像 */
        AlivcLiveVideoPipelineMirrorModeOnlyPreviewMirror = 2,
        /** 仅推流打开镜像 */
        AlivcLiveVideoPipelineMirrorModeOnlyPublishMirror = 3,
    } AlivcLiveVideoPipelineMirrorMode;
    /**
     * @brief 音频场景模式
     */
    typedef enum {
      /** 默认场景，一般的音视频通信场景推荐使用 */
      AlivcLiveSceneDefaultMode = 0x0000,
      /** 媒体场景，保真人声与音乐音质, 连麦直播间推荐使用 */
      AlivcLiveSeneMediaMode = 0x0200,
      /** 音乐场景，高保真音乐音质，乐器教学等对音乐音质有要求的场景推荐使用 */
      AlivcLiveSceneMusicMode = 0x0300,
    }AlivcLiveAudioScenario;
    /**
     * @brief 音频采样率
     */
    typedef enum AlivcLiveAudioSampleRateEnum{
        /** 16K */
        AlivcLiveAudioSampleRate16000 = 16000,
        /** 32K */
        AlivcLiveAudioSampleRate32000 = 32000,
        /** 44.1K */
        AlivcLiveAudioSampleRate44100 = 44100,
        /** 48K */
        AlivcLiveAudioSampleRate48000 = 48000,
    }AlivcLiveAudioSampleRateEnum;
    /**
     * @brief 音频通道数
     */
    typedef enum AlivcLiveAudioChannelEnum{
        /** 单通道 */
        AlivcLiveAudioChannelOne = 1,
        /** 双通道 */
        AlivcLiveAudioChannelTwo = 2,
    }AlivcLiveAudioChannelEnum;

    /**
    * @brief 音频编码模式
    */
    typedef enum {
      /** 音频低音质模式，默认8000Hz采样率，单声道，最大编码码率12kbps */  
      AlivcLiveLowQualityMode = 0x0000,
      /** （默认）标准音质模式，默认16000Hz采样率，单声道，最大编码码率24kbps */              
      AlivcLiveBasicQualityMode = 0x0001,
      /** 高音质模式，默认48000Hz采样率，单声道，最大编码码率48kbps */             
      AlivcLiveHighQualityMode = 0x0010,
      /** 立体声高音质模式，默认48000Hz采样率，双声道，最大编码码率64kbps */              
      AlivcLiveStereoHighQualityMode = 0x0011,
      /** 超高音质模式，默认48000Hz采样率，单声道，最大编码码率96kbps */        
      AlivcLiveSuperHighQualityMode = 0x0012,
      /** 立体声超高音质模式，默认48000Hz采样率，双声道，最大编码码率128kbps */        
      AlivcLiveStereoSuperHighQualityMode = 0x0013,   
    }AlivcLiveAudioProfile;

	/**
    * @brief 音频编码模式
    */
   typedef enum {
	/* 不设置 */
	AlivcLiveVideoRenderDowngradeMinNone = 0,
	/* 最小可以降级至GDI */
	AlivcLiveVideoRenderDowngradeMinGDI = 1,
	/* 最小可以降级至D3D9 */
	AlivcLiveVideoRenderDowngradeMinD3D9 = 2,
   }AlivcLiveVideoRenderDowngradeMinVersion;


#define MAX_ALIVC_VIDEO_CODEC_MANUFACTURER_COUNT		( 32 )
	typedef struct AlivcVideoCodecrManufacturerList {
		int codecCount = 0;
		AlivcVideoCodecManufacturer codecType[MAX_ALIVC_VIDEO_CODEC_MANUFACTURER_COUNT];
	}AlivcVideoCodecManufacturerList;

    /**
     * @brief 屏幕分享源信息
     */
    typedef struct AlivcLiveScreenSourcInfo {
        int sourceId;
        String sourceName;
        bool isSelf;
    } AlivcLiveScreenSourcInfo;

    typedef enum {
        /** 桌面分享 */
        AlivcLiveScreenShareDesktop,
        /** 窗口分享 */
        AlivcLiveScreenShareWindow,
    } AlivcLiveScreenShareType;

	typedef enum  {
		/* default use opus!   */
		AlivcAudioCodecOpus = 0,
	    AlivcAudioCodecAAC = 1 ,
	} AlivcAudioCodecEncodeType;


    /**
     * @brief 屏幕分享源列表
     */
    class ALIVC_LIVE_API AlivcLiveScreenSourceList {
    public:
        virtual unsigned int getCount() = 0;
        virtual AlivcLiveScreenSourcInfo getSourceInfo(unsigned int index) = 0;
        virtual void release() = 0;
    };
    
    /**
     * @brief 推流配置类
     * @note init初始化用
     */
    typedef struct AlivcLivePushConfig {
    public:
        /** 设置推流模式, 默认基础模式 */
        AlivcLiveMode mLivePushMode{ AlivcLiveMode::AlivcLiveBasicMode };
        /** 是否开启外置输入自定义音视频流 */
        bool externMainStream{false};
        /** 获取视频的编码模式 */
        AlivcEncodeModeEnum mVideoEncodeMode{AlivcEncodeModeEnum::Encode_MODE_SOFT};
        /** 获取音频的编码模式 TODO:暂未使用*/
        AlivcEncodeModeEnum mAudioEncodeMode{AlivcEncodeModeEnum::Encode_MODE_SOFT};
        /** 纯音频推流 */
        bool mAudioOnly{false};
        /** 镜像推流 */
        bool mPushMirror {false};
		/** 编码类型 */
		AlivcLiveVideoFormat videoEncoderCodecType{AlivcLiveVideoFormat::AlivcLiveVideoFormatH264};
		/** 允许视频编码类型降级 */
		bool mEnableVideoCodecDowngrade {true};
		/** 音频编码器类型  */
		AlivcAudioCodecEncodeType mAudioCodecEncodeType{ AlivcAudioCodecOpus };
        
        /** 视频分辨率，默认值640x480，最大值1920x1080,默认配置给摄像头
         */
        AlivcLiveResolutionEnum mResolution{AlivcLiveResolutionEnum::AlivcLiveResolution480P};
        /** 目标码率/最小码率/初始码率如果不进行配置，那么SDK会根据mResolution自动分配合适的码率进行发送，默认配置给摄像头
         */
        int mTargetVideoBitrate{-1};
        int mMinVideoBitrate{-1};
        int mInitialVideoBitrate{-1};

        /* 视频宽高：在mResolution为AlivcLiveResolutionSelfDefine下生效，默认配置给摄像头
         */
        int width{0};
        int height{0};

		AlivcLiveRenderMode renderMode{AlivcLiveRenderMode::AlivcLiveRenderModeAuto};
        
        /** 视频帧率，默认值15, 最大值30，默认配置给摄像头
        */
        AlivcLiveFrameRate frameRate{AlivcLiveFrameRate::AlivcLiveFrameRateFps15};
        /* 视频Gop时长，单位：秒，默认配置给摄像头
         */
        AlivcLiveVideoEncodeGopEnum mVideoEncodeGop{AlivcLiveVideoEncodeGopEnum::AlivcLiveVideoEncodeGopTwo};
        /* 视频旋转方式
         */
        AlivcLivePreviewOrientationEnum mPreviewOrientation{AlivcLivePreviewOrientationEnum::AlivcLivePreviewOrientationPortRait};
        /* 音频模式
         */
        AlivcLiveAudioScenario audioSceneMode {AlivcLiveAudioScenario::AlivcLiveSceneDefaultMode};
        /* 开启码率控制
         */
        bool enableBitrateControl{true};
        /* 开启变分辨率
         */
        bool enableAutoResolution{false};
        /* 暂停推流时推图片对应路径
         */
        String mPausePushImagePath;
        /* 网络不佳时推图片对应路径 TODO:待对接
         */
        String mNetworkPoorPushImagePath;

		/*
		忽略系统默认音频设备变化
		*/
		bool ignore_system_default_audio_device_change{false};

		/*
		推流音质模式
		*/
		AlivcLiveAudioProfile audioProfile {AlivcLiveAudioProfile::AlivcLiveHighQualityMode};
        
        /*
           开启采集回调未处理的原始数据
        */
        bool enableCaptureObserverOrignal{false};
		/*
		HEVC 编码B帧，仅在开启H265编码时生效
		*/
		bool enableEncodeHevcBFrame{false};
		/* 开启dsound音频采集*/
		bool enableDsoundCapture {false};

		/* 开启MPU旁路功能，默认打开 */
		bool enableStartMpu{true};
		/* 开启视频回调降低分辨率 */
		bool enable_obsever_frame_low_resolution {false};
		/*
		推流音质模式
		*/
		AlivcLiveVideoRenderDowngradeMinVersion videoRenderMin {AlivcLiveVideoRenderDowngradeMinVersion::AlivcLiveVideoRenderDowngradeMinNone};
    }AlivcLivePushConfig;

    /**
     * @brief 设备信息
     */
    typedef struct AlivcLiveDeviceInfo {
        String deviceName;
        String deviceID;
        AlivcLiveDeviceTransportType deviceTransportType{ AlivcLiveDeviceTransportTypeUnknown };
    } AlivcLiveDeviceInfo;

	/**
	* @brief 分辨率信息
	*/
	typedef struct AlivcLiveVideoResolution {
		int width = 0;
		int height = 0;
	} AlivcLiveVideoResolution;

	/**
	* @brief 分辨率列表
	*/
	class ALIVC_LIVE_API AlivcLiveVideoResolutionList {
	public:
		virtual unsigned int getCount() = 0;
		virtual AlivcLiveVideoResolution getResolutionInfo(unsigned int index) = 0;
		virtual void release() = 0;
	};

    /**
     * @brief 设备列表
    */
    class ALIVC_LIVE_API AlivcLiveDeviceInfoList {
    public:
      virtual unsigned int getCount() = 0;
      virtual AlivcLiveDeviceInfo getDeviceInfo(unsigned int index) = 0;
      virtual void release() = 0;
    };

    /**
     * @brief 视频画面裁剪模式
     */
    enum AlivcLiveTranscodingCropModeEnum {
        /** 剪裁 */
        AlivcLiveTranscodingCrop = 1,
        /** 填充 */
        AlivcLiveTranscodingFill = 2
    };

    /**
    * @brief 旁路直播转推流模式
    */
    enum AlivcLiveMixStreamType {
        /** 原始流 */
        AlivcLiveMixStreamOrigin = 0,
        /** 音频 */
        AlivcLiveMixStreamAudio = 1,
        /** 视频 */
        AlivcLiveMixStreamVideo = 2
    };

    /**
     * @brief 云端混流（转码）中每一路子画面的位置信息
     * 常见布局格式请见Push Demo
     */
    struct AlivcLiveMixStream {
        /**
         * 参与混流的用户ID
         * 备注：和推拉地址中userId字段相同
         */
        String userId;

        /**
         * 图层位置 x 坐标（绝对像素值）
         */
        int x;

        /**
         * 图层位置 y 坐标（绝对像素值）
         */
        int y;

        /**
         * 图层宽度（绝对像素值）
         */
        int width;

        /**
         * 图层高度（绝对像素值）
         */
        int height;

        /**
         * 图层层次
         * 备注：（1 - 15）不可重复
         */
        int zOrder;
        
        /**
         混流类型
         */
        AlivcLiveMixStreamType mixType ;

		/**
		 * 背景图片url
		 * 如果不为空，则在主播不推流时显示背景图片
		 */
		String imageUrl;

    };
    
    /**
     * @brief AlivcLiveMixStream列表
     */
    class ALIVC_LIVE_API AlivcLiveMixStreamArray
    {
    public:
      AlivcLiveMixStreamArray();
      virtual ~AlivcLiveMixStreamArray();
      AlivcLiveMixStreamArray(const AlivcLiveMixStreamArray &other);
      AlivcLiveMixStreamArray & operator=(const AlivcLiveMixStreamArray& other);

      void Add(const AlivcLiveMixStream &item);
      AlivcLiveMixStream Get(int index) const;
      void Clear();
      int Count() const;

    private:
      void *data{ nullptr };
    };

    /**
     * @brief 云端混流（转码）配置
     * 备注：常见混流布局格式请见Push Demo或官网文档，如：连麦混流布局、PK混流布局
     */
    struct AlivcLiveTranscodingConfig
    {
        /**
         * @brief  背景颜色:获取混合后画面的底色颜色
         * 默认为黑色，0x000000
         * 格式为十六进制数字,0xRRGGBB
         */
        int backgroundColor;

        /**
         * @brief  视频宽
         */
        int width{0};

        /**
         * @brief  视频高
         */
        int height{0};

        /** 视频帧率，默认值15, 最大值30，默认配置给摄像头
        */
        AlivcLiveFrameRate frameRate{AlivcLiveFrameRate::AlivcLiveFrameRateFps15};

        /** 目标码率
         */
        int mTargetVideoBitrate{-1};

        /* 视频Gop时长，单位：秒，默认配置给摄像头
         */
        AlivcLiveVideoEncodeGopEnum mVideoEncodeGop{AlivcLiveVideoEncodeGopEnum::AlivcLiveVideoEncodeGopTwo};

        /** 音频采样率 */
        AlivcLiveAudioSampleRateEnum mAudioSampleRate{AlivcLiveAudioSampleRateEnum::AlivcLiveAudioSampleRate48000};

        /** 音频码率 */
        int audioBitRate {64};

        /** 音频通道数 */
        AlivcLiveAudioChannelEnum mAudioChannels {AlivcLiveAudioChannelEnum::AlivcLiveAudioChannelOne};
        
        /**
         * @brief 混合后视频画面裁剪模式
         * 默认：AlivcLiveTranscodingCropModeCrop
         */
        AlivcLiveTranscodingCropModeEnum cropMode{AlivcLiveTranscodingCrop};
        /**
         * @brief 多路混流，通过uid区分不同流
         */
        AlivcLiveMixStreamArray mixStreams;
    };

        /**
     * @brief 屏幕流编码属性设置
     */
    struct AlivcLiveScreenShareEncoderConfiguration{
        /** 视频分辨率，默认值640x480，最大值1920x1080, 可配置给屏幕共享
         */
        AlivcLiveResolutionEnum mResolution{AlivcLiveResolutionEnum::AlivcLiveResolution480P};

        /* 视频宽高：在mResolution为AlivcLiveResolutionSelfDefine下生效，可配置给屏幕共享
         */
        int width{0};
        int height{0};

        
        /** 视频帧率，默认值5, 最大值30
        */
		AlivcLiveFrameRate frameRate{AlivcLiveFrameRate::AlivcLiveFrameRateFps15 };
        
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
        int bitrate{512};

        /* 视频Gop时长，单位：秒，可配置给屏幕共享
         */
        AlivcLiveVideoEncodeGopEnum mVideoEncodeGop{AlivcLiveVideoEncodeGopEnum::AlivcLiveVideoEncodeGopTwo};
    };

	/**
     * @brief 音频数据回调参数设置
     *
     */
    typedef struct AlivcLiveAudioFrameListenerConfig{
        /* 回调音频采样率 */
        AlivcLiveAudioSampleRateEnum sampleRate = AlivcLiveAudioSampleRate48000;
        /* 回调音频声道数 */
        AlivcLiveAudioChannelEnum channels = AlivcLiveAudioChannelOne;
    } AlivcLiveAudioFrameListenerConfig;

	/**
	 * @brief 外部音频流配置
	 */
	typedef struct AlivcLiveExternalAudioStreamConfig {
		/** 声道数，默认值：1 */
		int channels = 1;
		/** 采样率，默认值：48000 */
		int sampleRate = 48000;
		/** 播放音量，取值范围[0-100]，默认值：50 */
		int playoutVolume = 50;
		/** 推流音量，取值范围[0-100]，默认值：50 */
		int publishVolume = 50;
		/** 1-作为Dual音频流推流，0-作为MIC音频流推流 */
		int publishStream = 0;
	} AlivcLiveExternalAudioStreamConfig;

    /**
    * @brief 直播连麦的推流控制类
    */
	class ALIVC_LIVE_API AlivcLivePusher
	{
	public:
		/**
		 * @brief 创建一个AlivcLivePusher实例
		 */
		static AlivcLivePusher* Create(const char* extra);
		/**
		 * @brief 初始化一个AlivcLivePusher实例
		 * @param extras 用于接收来自客户灰度下发的参数，通过JSON配置SDK的特别功能，可以是空字符串。
		 * @details 该方法为同步调用，以单例的形式提供对象创建。
		 * @note 注意 同一时间只会存在一个主实例。
		 */
		virtual void init(AlivcLivePushConfig config) = 0;

		/**
		 * @brief 销毁AlivcLivePusher实例
		 * @details 调用该方法将会释放所有内部使用的资源,当完成音视频通信之后都建议调用该方法释放实例.调用该方法后，你将不能再使用 {@link AlivcLivePusher} 的其他方法和任何回调，如需要再次使用需要重新调用 {@link AlivcLive::Create} 方法创建一个新的实例。
		 * @note 该方法为同步调用,需要等待内部资源释放之后才能执行其他方法,为避免主线程阻塞，建议开发者放在子线程调用该方法，但需要注意的是如需在销毁后再次创建 {@link AlivcLivePusher} 实例，请开发者务必保证 Destroy 方法执行结束后再创建实例。
		 * @note 为避免死锁，不建议在任何SDK的回调中调用本方法
		 */
		static void destroy();

		/**
         * @brief 设置H5兼容模式
         * @details 是否需要与Web SDK互通。如果使用Native SDK用户加入频道，需要与通过Web SDK加入频道的用户进行互通，则必须使用H5兼容模式,否则，Web用户查看Native用户将是黑屏。
         * @param comp 
         * - true: 兼容H5。
         * - false: 传统模式，不兼容H5。
         * @note 不支持在创建AliEngine实例之后更改H5兼容模式，必须在创建实例之前就调用此方法。
         */
        static void setH5CompatibleMode(bool comp);
        
        /**
         * @brief 检查当前是否兼容H5、与Web SDK互通
         * @return 
         * - true: 兼容H5。
         * - false: 不兼容H5。
         */
        static bool getH5CompatibleMode();

		/**
		 * @brief 开启本地视频预览, Async为异步方法
		 * @param view  预览view, win是hwnd, iOS为UIView,Android为Surface View
		 * @return
		 * - 0: 成功
		 * - 非0: 失败
		 */
		virtual int startPreview(void* view, int width, int height) = 0;
		virtual int startPreviewAsync(void* view, int width, int height) = 0;

		/**
		 * @brief 停止预览;(异步)
		 * @return
		 * - 0: 成功
		 * - 非0: 失败
		 */
		virtual int stopPreview() = 0;

		/**
		 * @brief  开始推流, Async为异步方法
		 * @param url  推流地址
		 * @return
		 * - 0: 成功
		 * - 非0: 失败
		 */
		virtual int startPush(const char* url) = 0;
		virtual int startPushAsync(const char* url) = 0;
        
        /**
         * 暂停推流
         *
         */
        virtual int pause() = 0;
        
        /**
         * 恢复推流
         *
         */
        virtual int resume() = 0;
		/**
		 * @brief  停止推流;(异步)
		 * @return
		 * - 0: 成功
		 * - 非0: 失败
		 */
		virtual int stopPush() = 0;


		/**
		 * 录屏模式下，开启摄像头预览
		 * 如果不需要预览，则surfaceview填为null
		 *
		 * @param surfaceView
		 * @return
		 */
		virtual int startCamera() = 0;

		/**
		 * 录屏模式下，关闭摄像头预览
		 */
		virtual int stopCamera() = 0;

		/**
		* @brief 开启音频播放
		* @return 错误码
		*/
		virtual int startAudioPlayer() = 0;

		/**
		* @brief 关闭音频播放
		* @return 错误码
		*/
		virtual int stopAudioPlayer() = 0;

		/**
		* @brief 开启音频采集
		* @return 错误码
		*/
		virtual int startAudioCapture() = 0;

		/**
		* @brief 关闭音频采集
		* @return 错误码
		*/
		virtual int stopAudioCapture() = 0;

		/**
		 * @brief 获取系统中的录音设备列表
		 */
		virtual AlivcLiveDeviceInfoList* getAudioCaptureList() = 0;

		/**
		 * @brief 获取使用的录音设备名称
		 * @return 当前音频采集设备名称
		 */
		virtual String getCurrentAudioCaptureName() = 0;

		/**
		 * @brief 获取使用的录音设备ID
		 * @return 当前音频采集设备ID
		 */
		virtual String getCurrentAudioCaptureID() = 0;

		/**
		 * @brief 选择录音设备名称
		 * @param captureName 音频采集设备名称
		 * @return
		 * - 0: 成功
		 * - 非0: 失败
		 */
		virtual int setCurrentAudioCaptureName(const char* captureName) = 0;

		/**
		 * @brief 选择录音设备ID
		 * @param captureID 音频采集设备ID
		 * @return
		 * - 0: 成功
		 * - 非0: 失败
		 */
		virtual int setCurrentAudioCaptureID(const char* captureID) = 0;

		/**
		 * @brief 获取系统中的扬声器设备列表, Mac不支持
		 */
		virtual AlivcLiveDeviceInfoList* getAudioPlayerList() = 0;


		/**
		* @brief 获取可以系统录音的扬声器设备列表, Mac不支持
		*/
		virtual AlivcLiveDeviceInfoList* getSystemRecordAudioPlayerList() = 0;

		/**
		 * @brief 获取当前使用的扬声器名称
		 * @return 当前音频播放设备名
		 */
		virtual String getCurrentAudioPlayerName() = 0;

		/**
		 * @brief 获取当前使用的扬声器ID
		 * @return 当前音频播放设备ID
		 */
		virtual String getCurrentAudioPlayerID() = 0;

		/**
		 * @brief 选择扬声器名称
		 * @param playerName 音频播放设备名称
		 * @return
		 * - 0: 成功
		 * - 非0: 失败
		 */
		virtual int setCurrentAudioPlayerName(const char* playerName) = 0;

		/**
		 * @brief 选择扬声器ID
		 * @param playerID 音频播放设备ID
		 * @return
		 * - 0: 成功
		 * - 非0: 失败
		 */
		virtual int setCurrentAudioPlayerID(const char* playerID) = 0;

		/**
		 * @brief 开启/关闭系统声音采集推送, Mac不支持
		 * @param enable true为开启, false为关闭
		 * @param device_id path为空，则采集默认声卡设备的声音；否则采集device_id此设备的播放的声音
		 * @return
		 * - 0: 成功
		 * - <0: 失败
		 */
		virtual int enableSystemAudioRecording(bool enable, const char *device_id = nullptr) = 0;

		/**
		 * @brief 设置推流音频是否与麦克风采集音频混合, Mac不支持
		 * @param mixed 是否混音
		 * - true: 混音
		 * - false: 完全替换麦克风采集数据
		 * @return
		 * - 0: 成功
		 * - 非0: 失败
		 * @deprecated 建议使用调节音量接口代替
		 */
		virtual int setMixedWithMic(bool mixed) = 0;

		/**
		 * @brief 设置系统声音采集推送音量, Mac不支持, 默认50
		 * @param volume 设置音量
		 * @return
		 * - 0: 成功
		 * - <0: 失败
		 */
		virtual int setSystemAudioRecordingVolume(int volume) = 0;

		/**
		* @brief 设置录音音量, Mac不支持, 默认50
		* @param volume 录音音量，取值范围[0,400] 0：静音；>100：放大音量；<100：减小音量
		* @return
		* - 0: 成功
		* - 非0: 失败
		*/
		virtual int setRecordingVolume(int volume) = 0;

		/**
		* @brief 设置播放音量, Mac不支持, 默认50
		* @param volume 播放音量，取值范围[0,400] 0：静音; >100：放大音量； <100：减小音量
		* @return
		* - 0: 成功
		* - 非0: 失败
		*/
		virtual int setPlayoutVolume(int volume) = 0;

		/**
		 * @brief 设置音频采集设备音量，音量范围[0, 100], Mac不支持
		 * @param volume 音量值
		 * @return
		 * - 0: 成功
		 * - 非0: 失败
		 */
		virtual int setRecordingDeviceVolume(int volume) = 0;

		/**
		 * @brief 获取音频采集设备音量, Mac不支持,仅支持初始化后时获取，调用setRecordingDeviceVolume后立即获取会存在不准确性
		 * @return
		 * - >=0: 音量
		 * - <0: 失败
		 */
		virtual int getRecordingDeviceVolume() = 0;

		/**
		 * @brief 设置音频播放设备音量，音量范围[0, 100], Mac不支持
		 * @param volume 音量值
		 * @return
		 * - 0: 成功
		 * - 非0: 失败
		 */
		virtual int setPlaybackDeviceVolume(int volume) = 0;

		/**
		 * @brief 获取音频播放设备音量, Mac不支持,仅支持初始化后时获取，调用setPlaybackDeviceVolume后立即获取会存在不准确性
		 * @return 设备音量
		 */
		virtual int getPlaybackDeviceVolume() = 0;

		/**
		* @brief 停止/恢复本地音频数据发送
		* @param mute  true表示静音本地音频，发送静音帧; false表示取消静音;
		* @param mode  静音模式，静音模式分三种，详见{@link AlivcLiveMuteLocalAudioMode}, 默认模式为静音本地麦克风采集音频和所有外部输入音频;
		* @return
		* - 0: 成功
		* - 非0: 失败
		* @note 静音是指音频流发送静音帧,采集和编码模块仍然在工作
		*/
		virtual int setMute(bool mute, AlivcLiveMuteLocalAudioMode mode = AlivcLiveMuteLocalAudioModeDefault) = 0;

		/**
		 * @brief 获取摄像头列表
		 * @return {@link AlivcLiveDeviceInfoList} 设备列表
		 */
		virtual AlivcLiveDeviceInfoList* getCameraList() = 0;

		/**
		 * @brief 获取当前使用的摄像头名称
		 * @return 摄像头名称
		 */
		virtual String getCurrentCameraName() = 0;

		/**
		 * @brief 获取当前使用的摄像头ID
		 * @return 摄像头ID
		 */
		virtual String getCurrentCameraID() = 0;

		/**
		 * @brief 选择摄像头名称
		 * @param cameraName 摄像头名称
		 * @return
		 * - 0: 成功
		 * - 非0: 失败
		 */
		virtual int setCurrentCameraName(const char* cameraName) = 0;

		/**
		 * @brief 选择摄像头ID
		 * @param cameraID 摄像头ID
		 * @return
		 * - 0: 成功
		 * - 非0: 失败
		 */
		virtual int setCurrentCameraID(const char* cameraID) = 0;

		/**
         * @brief 设置摄像头采集偏好
         * @param preference 采集偏好
         *   - {@link AlivcLiveCaptureOutputPreference::AlivcLiveCaptureOutputPreferencePreview} 高清预览，采集优先保证视频预览质量
         *   - {@link AlivcLiveCaptureOutputPreference::AlivcLiveCaptureOutputPreferencePerformance} 采集选择最接近推流的分辨率，优先保证设备性能
         *   - {@link AlivcLiveCaptureOutputPreference::AlivcLiveCaptureOutputPreferenceAuto} 自动调整采集分辨率
         * 
         * @return
         * - 0: 成功
         * - 非0: 失败
         * @note 必须在打开摄像头之前设置，如 {@link StartPreview}，{@link StartPush}之前设置
         */

		virtual int setCameraCapturerConfiguration(AlivcLiveCaptureOutputPreference preference) = 0;

		/**
		* @brief 获取支持的分辨率
		* @param source 前后置摄像头 win/mac忽略
		* @return
		* - != NULL : 成功
		* - = NULL  : 失败
		*/
		virtual AlivcLiveVideoResolutionList * getCurrentCameraSupportedResolutionList(int source) = 0;


		/**
		 * 设置推流错误事件
		 *
		 * @param errorListener 错误监听器
		 */
		virtual int setLivePushErrorListener(AlivcLivePushErrorListener* errorListener) = 0;

		/**
		 * 设置推流通知事件
		 *
		 * @param infoListener 通知监听器
		 */
		virtual int setLivePushInfoListener(AlivcLivePushInfoListener* infoListener) = 0;

		/**
		 * 设置网络通知事件
		 *
		 * @param networkListener 通知监听器
		 */
		virtual int setLivePushNetworkListener(AlivcLivePushNetworkListener* networkListener) = 0;

		/**
		 * 设置视频帧通知事件,初始化之後生效
		 *
		 * @param videoFrameListener 通知监听器
		 */
		virtual int setLivePushVideoFrameListener(AlivcLiveVideoFrameListener* videoFrameListener) = 0;

		/**
		 * 设置音频帧通知事件
		 *
		 * @param audioFrameListener 通知监听器
		 */
		virtual int setLivePushAudioFrameListener(AlivcLiveAudioFrameListener* audioFrameListener) = 0;

		/**
		 * @brief 订阅音频数据
		 * @param enabled 是否允许数据回调
		 * @param config 回调参数设置，详见{@link AlivcLiveAudioFrameListenerConfig}, null时默认参数为48000，1
		 * @return 0: sucess
		 */
		virtual int enableAudioFrameListener(bool enabled, AlivcLiveAudioSource audioSource, AlivcLiveAudioFrameListenerConfig config) = 0;
		
        /**
        * @brief 设置音频profile
        * @param audioProfile 音频采集/编码模式参数, 详见{@link AlivcLiveAudioProfile};
        * @param audioScene 音频场景模式参数,详见{@link AlivcLiveAudioScenario};
        * @return 
        * - 0: 成功
        * - 其他: 失败
        * @note 只支持 {@link startPush} 前设置有效；
        */
        virtual int setAudioProfile(int audioProfile, int audioScene) = 0;

		/**
		 * @brief 设置音量回调频率和平滑系数
		 * @param interval 时间间隔，单位毫秒，最小值不得小于10ms, 建议设置300-500ms, <= 0表示不启用音量提示和说话人提示功能
		 * @param smooth 平滑系数，数值越大平滑程度越高，反之越低，实时性越好，建议设置3，范围[0, 9];
		 * @param reportVad 说话人检测开关
		 * - 1: 开启
		 * - 0: 关闭
		 * @return
		 * - 0: 成功
		 * - <0: 失败
		 * @note 设置之后，音频音量和说话人uid会分别通过 {@link AlivcLiveEventListener::OnAudioVolumeCallback} 和 {@link AlivcLiveEventListener::OnActiveSpeaker} 回调
		 */
		virtual int enableAudioVolumeIndication(int interval, int smooth, int reportVad) = 0;

		/**
		 * @brief 设置目标码率
		 * @param targetBitrate 目标码率 [100  5000](Kbps)
		 * @return 0:success  非0:failure
		 */
		virtual int setTargetVideoBitrate(int targetBitrate) = 0;

		/**
		 * @brief 设置GOP大小
		 * @param gopSize AlivcLiveVideoEncodeGopEnum
		 * @return 0:success  非0:failure
		 */
		virtual int setGopSize(AlivcLiveVideoEncodeGopEnum gopSize) = 0;

		/**
		 * @brief 设置最小码率
		 * @param minBitrate 最小码率 [100  5000](Kbps)
		 * @return 0:success  非0:failure
		 */
		virtual int setMinVideoBitrate(int minBitrate) = 0;

		/**
		 * @brief 设置推流分辨率
		 * @param resolution 推流分辨率
		 * @param width 推流分辨率宽
		 * @param height 推流分辨率高
		 */
		virtual int setResolution(AlivcLiveResolutionEnum resolution, int width = 0, int height = 0) = 0;

		/**
		 * @brief 设置推流帧率
		 * @param fps 推流帧率
		 */
		virtual int setFps(AlivcLiveFrameRate fps) = 0;
        
        /**
         * @brief 设置横竖屏
         * @param previewOrientation 横屏/竖屏
         */
        virtual int setOrientation(AlivcLivePreviewOrientationEnum previewOrientation) = 0;

		/**
		*@brief 设置采集缩放时机，视频数据是采集的时候立即缩放还是编码时才进行缩放。
		*@param mode 控制采集缩放时机的模式，默认是采集的时候立即缩放
		*@note 必须在打开摄像头之前设置，如 {@link AliRtcEngine::startPreview}，{@link AliRtcEngine::joinChannel:name:onResult:} / {@link AliRtcEngine::joinChannel:name:onResultWithUserId:}之前设置
		*/
		virtual void setCapturePipelineScaleMode(const AlivcLiveCapturePipelineScaleMode mode) = 0;
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
		virtual int setVideoMirrorMode(const AlivcLiveVideoPipelineMirrorMode mirrorMode) = 0;

		/* **********************互动模式下特定API******************************** */
		/** 以下API是只在livePushMode为AlivcLivePushInteractiveMode，即只在直播SDK工作在互动模式下才可以使用
		 *  非互动模式调用以下API将无任何效果，特定API包括：
		 *  setLiveMixTranscodingConfig
		 */

		 /**
		  * @brief 设置云端的混流（转码）参数
		  * 一个直播间中可能有不止一位主播，而且每个主播都有自己的画面和声音，但对于 CDN 观众来说，他们只需要一路直播流
		  * 所以您需要将多路音视频流混成一路标准的直播流，这就需要混流转码
		  * 在连麦场景下，需要将主播和连麦观众音视频流混成一路标准的直播流，供CDN观众观看
		  * 在PK场景下，需要将进行PK的多个主播的音视频流混成一路标准的直播流，供CDN观众观看
		  * @param config 参考AlivcLiveDef.h中关于AlivcLiveTranscodingConfig的介绍，如果传入nil，则取消云端混流转码
		  * @return
		  * - 0: 成功
		  * - <0: 失败
		  * @note 若主播还在房间中但不再需要混流，请务必传入 nil 进行取消，因为当发起混流后，云端混流模块就会开始工作，
		  * 不及时取消混流可能会引起不必要的计费损失
		  */
		virtual int setLiveMixTranscodingConfig(AlivcLiveTranscodingConfig* config) = 0;

		/**
		 * @brief 停止/恢复本地视频数据数据发送
		 * @param mute true表示视频数据发送黑帧；false表示恢复正常
		 * @return
		 * - 0: 成功
		 * - 非0: 失败
		 * @note 此接口只是控制指定视频流上是否发送黑帧，采集和数据发送不会停止
		 */
		virtual int muteLocalCamera(bool mute) = 0;

		/**
		 * @brief 根据桌面Id进行屏幕分享
		 * @param desktopId 桌面Id(可通过GetScreenShareSourceInfo接口获取)
		 * @return
		 * - 0: 成功
		 * - <0: 失败
		 * @note
		 * - 配置指定区域分享时，分享区域最小分辨率为16 x 16，设置区域小于最小分辨率时重置为最小分辨率
		 * - 配置指定区域分享时，设置分享区域超过实际桌面分辨率时，将分享整个桌面
		*/
		virtual int startScreenShareByDesktopId(unsigned int desktopId) = 0;

		/**
		 * @brief 设置屏幕共享编码参数
		 * @param config 编码参数参考AlivcLiveScreenShareEncoderConfiguration的介绍
		 * @return
		 * - 0: 成功
		 * - <0: 失败
		*/
		virtual int setScreenShareEncoderConfiguration(const AlivcLiveScreenShareEncoderConfiguration& config) = 0;

		/**
		 * @brief 获取屏幕共享编码参数
		 * @return
		 * 当前编码参数AlivcLiveScreenShareEncoderConfiguration
		*/
		virtual AlivcLiveScreenShareEncoderConfiguration getScreenShareEncoderConfiguration() = 0;

		/**
		 * @brief 切换屏幕共享至摄像头
		 * @return
		 * - 0: 成功
		 * - <0: 失败
		*/
		virtual int switchScreenToCamera() = 0;

		/**
		 * @brief 暂停屏幕分享
		 * @return
		 * - 0: 成功
		 * - <0: 失败
		*/
		virtual int pauseScreenShare() = 0;

		/**
		 * @brief 恢复屏幕分享
		 * @return
		 * - 0: 成功
		 * - <0: 失败
		*/
		virtual int resumeScreenShare() = 0;

		/**
		 * @brief 停止屏幕分享
		 * @return
		 * - 0: 成功
		 * - <0: 失败
		*/
		virtual int stopScreenShare() = 0;

		/**
		 * @brief 获取屏幕分享源信息
		 * @return AlivcLiveScreenSourceList 返回屏幕共享源列表，详见 {@link AliRTCSdk::AlivcLiveScreenSourceList}
		 * @note 请在遍历完屏幕共享源列表后调用其release成员方法，由SDK内部释放相关资源
		 */
		virtual AlivcLiveScreenSourceList* getScreenShareSourceInfo(AlivcLiveScreenShareType shareType) = 0;

		/**
		 * @brief 获取当前屏幕共享源Id
		 * @return 当前屏幕共享源Id
		*/
		virtual unsigned int getCurrentScreenShareSourceId() = 0;

		/**
		 * @brief 启用外部视频输入源
		 * @param enable
		 * - true 开启
		 * - false 关闭
		 * @param type 流类型，详见 {@link AliRTCSdk::AlivcLiveVideoTrack}
		 * - AlivcLiveVideoTrackCamera 外部输入视频数据走相机流通道，如果当前相机采集打开中，调用该接口设置enable为true，sdk会替换掉相机采集
		 * - AlivcLiveVideoTrackScreen 外部输入视频数据走屏幕流通道，如果当前屏幕共享采集打开中，调用该接口设置enable为true，sdk会替换掉屏幕共享采集
		 * @return
		 * - 0: 成功
		 * - 非0: 失败
		 */
		virtual int setExternalVideoSource(bool enable, AlivcLiveVideoTrack type) = 0;

		/**
		 * @brief 输入视频数据
		 * @param frame 帧数据，详见 {@link AlivcLiveVideoRawData}
		 * @param type 流类型，详见 {@link AlivcLiveVideoTrack}
		 * - AlivcLiveVideoTrackCamera 外部输入视频数据走相机流通道
		 * - AlivcLiveVideoTrackScreen 外部输入视频数据走屏幕流通道
		 * @return
		 * - 0: 成功
		 * - 非0: 失败
		 */
		virtual int pushExternalVideoFrame(const AlivcLiveVideoRawData &frame, AlivcLiveVideoTrack type) = 0;

		/**
		 * @brief 新增外部音频流
		 * @param config 外部音频流配置 详见 {@link AlivcLiveExternalAudioStreamConfig}
		 * @return
		 * - >0: 外部音频流Id
		 * - <0: 失败
		 */
		virtual int AddExternalAudioStream(const AlivcLiveExternalAudioStreamConfig& config) = 0;

		/**
	     * @brief 移除外部音频流
	     * @param streamId 外部音频流Id
	     * @return
	     * - 0: 成功
	     * - 非0: 失败
	     */
		virtual int RemoveExternalAudioStream(int streamId) = 0;

		/**
		 * @brief 输入外部音频数据
		 * @param streamId 外部音频流Id
		 * @param data 外部音频裸数据 详见 {@link AlivcLiveAudioRawData}
		 * @return
		 * - <0: 表示失败;
		 * - 0: 表示成功;
		 * - 返回值为 {@link AliEngineErrorAudioBufferFull} 时，需要在间隔投递数据时间长度后再次重试投递
		 * @note 为了保证语音连续性，sdk内部会有buffer缓存送进来的音频数据，以每次送10ms数据为例，如果返回{@link AliEngineErrorAudioBufferFull}时，说明内部缓冲区已满，建议等待20ms后再重新送当前数据帧；
		 */
		virtual int PushExternalAudioStreamRawData(int streamId, AlivcLiveAudioRawData& data) = 0;

		/**
		 * @brief 设置是否启用外部音频输入推流
		 * @param enable true:开启; false:关闭
		 * @param sampleRate 采样率 16k 48k...
		 * @param channelsPerFrame 声道数 1:单声道; 2:双声道
		 * @return
		 * - >=0: 成功
		 * - <0: 失败
		 */
		virtual int setExternalAudioSource(bool enable, unsigned int sampleRate, unsigned int channelsPerFrame) = 0;

		/**
		 * @brief 输入外部音频数据推流到远端
		 * @param data 音频数据buffer
		 * @param sampleLen 音频数据buffer长度
		 * @return 
		 * - <0: 表示失败;
		 * - 0: 表示成功;
		 * - 返回值为 {@link ALIVC_FRAMEWORK_ERROR_AUDIO_BUFFER_FULL} 时，需要在间隔投递数据时间长度后再次重试投递
		 * @note 为了保证语音连续性，sdk内部会有buffer缓存送进来的音频数据，以每次送10ms数据为例，如果返回 {@link ALIVC_FRAMEWORK_ERROR_AUDIO_BUFFER_FULL} 时，说明内部缓冲区已满，建议等待20ms后再重新送当前数据帧；
		 */
		virtual int pushExternalAudioFrameRawData(const void * data, unsigned int sampleLen) = 0;

		/**
		 * @brief 获取视频编码类型
		 * @param codecKind 视频codec类型 编码/解码
		 * @param videoFormat 视频codec格式 h264/h265
		 * @return
		 * - 0: 成功
		 * - 非0: 失败
		 */
		virtual int getVideoEncoderCodecType(AlivcLiveVideoFormat & videoFormat) = 0;

		/**
		 * @brief 获取推流对应的拉流url，该接口仅在推流成功后获取有效
		 * @return
		 * - 0: 成功
		 * - 非0: 失败
		 */
		virtual String getPullUrl() = 0;

		/**
		* @brief 设置全局视频编码提供商参数
		* <p>
		* 当前接口仅在拉流之前配置生效，拉流之后配置无效!!!
		* <p>
		* 此接口当前会修改所有的拉流用户解码参数，请谨慎修改
		* @param codecManufacturer AlivcVideoCodecManufacturer
		* @return
		* - 0: 成功
		* - 非0: 失败
		*/
		virtual int setVideoEncoderCodecManufacturerConfig(const AlivcVideoCodecManufacturer codecManufacturer) = 0;

		/**
		* @brief 获取全局支持的视频编码厂商编码列表
		* @param codecManufacturerList AlivcVideoCodecManufacturerList
		* @return
		* - 0: 成功
		* - 非0: 失败
		*/
		virtual int getVideoSupportEncoderManufacturerList(AlivcVideoCodecManufacturerList & codecManufacturerList) = 0;

        /**
        * @brief 设置允许视频编码H265降级H264开关
        * @param enableDowngrade bool
        * - true:  打开，允许视频编码由H265降级H264
        * - false: 关闭，禁止视频编码由H265降级H264
        * @return
        * - 0: 成功
        * - 非0: 失败
        */
        virtual int setVideoEncoderCodecDowngradeSwitch(const bool enableDowngrade) = 0;
        
        /**
        * @brief 获取允许视频编码H265降级H264开关
        * @param enableDowngrade bool
        * - true:  打开，允许视频编码由H265降级H264
        * - false: 关闭，禁止视频编码由H265降级H264
        * @return
        * - 0: 成功
        * - 非0: 失败
        */
        virtual int getVideoEncoderCodecDowngradeSwitch(bool & enableDowngrade) = 0;

 
        /**
        * @brief 设置是否开启RTMP转推
        * @return
        * - true: 开启
        * - false: 失败
        */
        virtual void setRtmpRelay(const bool enableRtmpRelay) = 0;
        /**
        * @brief 获取是否开启RTMP转推
        * @return
        * - true: 开启
        * - false: 失败
        */
        virtual bool getRtmpRelay() = 0;

		/**
		* @brief 设置全局视频编码厂商参数
		* <p>
		* 当前接口仅在拉流之前配置生效，拉流之后配置无效!!!
		* <p>
		* 此接口当前会修改所有的拉流用户解码参数，请谨慎修改
		* @param codecManufacturer AlivcVideoCodecManufacturer
		* @return
		* - 0: 成功
		* - 非0: 失败
		*/
		virtual int setVideoDecoderCodecManufacturerConfig(const AlivcVideoCodecManufacturer codecManufacturer) = 0;

		/**
		* @brief 获取全局支持的视频解码器厂商列表
		* @param codecManufacturerList AlivcVideoCodecManufacturerList
		* @return
		* - 0: 成功
		* - 非0: 失败
		*/
		virtual int getVideoSupportDecoderManufacturerList(AlivcVideoCodecManufacturerList & codecManufacturerList) = 0;

		/**
		* @brief 获取当前使用的编码器类型,如未开始推流，返回无效类型
		* @param type AlivcLiveVideoTrack
		* @return AlivcVideoCodecManufacturer 编码器类型
		*/
		virtual AlivcVideoCodecManufacturer getCurrentEncoderManufacturer(AlivcLiveVideoTrack type) = 0;

		/**
		* @brief 获取使用的编码器参数
		* @param type AlivcLiveVideoTrack [IN]
		* @param codecManufacturerList AlivcLiveVideoCodecManufacturerList [IN]
		* @param codecSpecific Dictionary	[OUT]	
		* @return 
		* - 0: 成功
		* - 非0: 失败
		*/
		virtual int getEncoderManufacturerSpecificParam(AlivcLiveVideoTrack type, AlivcVideoCodecManufacturer codecManufacturer, Dictionary &codecSpecific) = 0;

		/**
		* @brief 设置当前使用的编码器参数，内部会更新需要更新的参数，若已推流，则更新该流参数
		* 格式：
		* [编码器名称]：
		*     [key]: [value1(brief1), value2(brief2)..., valueN(briefN)]
		*     key:表示对应编码器可配置的选项
		*     valueN: 表示对应选项可以配置的字符串
		*     briefN：表示该value值对应的中文描述，仅作界面展示使用，不允许出现在codecSpecific的值中
		* Qsv:
		*     qsv_preset（目标使用）: slowest, balanced, fastest, slower, slow, fast, faster
    	*     qsv_tune（延迟）: ultra-low, low, normal
		*     qsv_profile（配置文件）: baseline, main, high
		* Nvidia:
		*     nvidia_preset（预设）: mq（P7:最慢（质量最高））, hq（P6:更慢（质量更高））, default（P5:慢速（质量高））, hp（P4:中等（质量中等））, 
		*					 ll（P3:快速（质量低））, llhq（P2:更快(质量更低)）, llhp（P1:最快（质量最低））
    	*     nvidia_tune（调节）: ll（低延迟）, ull（超低延迟）, hq（高质量）
		*     nvidia_profile（配置）: baseline, main, high
		*     nvidia_multipass（多次编码模式）: singlepass（单次编码）, fullres（二次编码（全分辨率））, qres（二次编码（1/4分辨率））
		* X264:
		*     x264_preset（CPU使用预设）: ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow, placebo
    	*     x264_tune（微调）: film, animation, grain, stillimage, psnr, ssim, fastdecode, zerolatency
		*     x264_profile（配置）: baseline, main, high
		* X265:
		*     x265_preset（CPU使用预设）: ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow, placebo
    	*     x265_tune（微调）: psnr, ssim, grain, zerolatency, fastdecode, animation
		*     x265_profile（配置）: main, main10, mainstillpicture
		* @param type AlivcLiveVideoTrack
		* @param codecManufacturer AlivcVideoCodecManufacturer
		* @param codecSpecific Dictionary
		*	格式：[key] : [value]
		* @return 
		* - 0: 成功
		* - 非0: 失败
		*/
		virtual int setEncoderManufacturerSpecificParam(AlivcLiveVideoTrack type, AlivcVideoCodecManufacturer codecManufacturer, const Dictionary &codecSpecific) = 0;

		/**
		 * @brief 开始外部文件播放
		 * @return
		 * - 0: 成功
		 * - 非0: 失败
		 */
		virtual int startExternalFile(AlivcLiveFileInputConfig config) = 0;

		/**
		 * @brief 停止外部文件播放
		 * @return
		 * - 0: 成功
		 * - 非0: 失败
		 */
		virtual int stopExternalFile() = 0;

		/**
		 * @brief 设置外部文件音频推流音量
		 * @param pushVol 推流音量
		 * @return
		 * - 0: 成功
		 * - 非0: 失败
		 */
		virtual int setExternalFileAudioPublishVolume(int pushVol) = 0;

		/**
		 * @brief 获取外部文件音频推流音量
		 * @return
		 * - >=0: 音量值
		 * - -1: 失败
		 */
		virtual int getExternalFileAudioPublishVolume() = 0;

		/**
		 * @brief 设置外部文件音频本地渲染音量
		 * @param renderVol 本地播放音量
		 * @return
		 * - 0: 成功
		 * - 非0: 失败
		 */
		virtual int setExternalFileAudioRenderVolume(int renderVol) = 0;

		/**
		 * @brief 获取外部文件音频渲染音量
		 * @return
		 * - >=0: 音量值
		 * - -1: 失败
		 */
		virtual int getExternalFileAudioRenderVolume() = 0;

		/**
		 * @brief 暂停外部文件播放
		 * @return
		 * - 0: 成功
		 * - 非0: 失败
		 */
		virtual int pauseExternalFile() = 0;

		/**
		 * @brief 恢复外部文件播放
		 * @return
		 * - 0: 成功
		 * - 非0: 失败
		 */
		virtual int resumeExternalFile() = 0;

		/**
		 * @brief 跳转到对应文件播放位置
		 * @param posMs 跳转对应的位置
		 * @return
		 * - 0: 成功
		 * - 非0: 失败
		 */
		virtual int seekExternalFilePosMs(int64_t posMs) = 0;
        
        /**
        * @brief 根据桌面Id进行屏幕分享
        * @param windowId 窗口Id(可通过GetScreenShareSourceInfo接口获取)
        * @return
        * - 0: 成功
        * - <0: 失败
        * @note
        * - 配置指定区域分享时，分享区域最小分辨率为16 x 16，设置区域小于最小分辨率时重置为最小分辨率
        * - 配置指定区域分享时，设置分享区域超过实际桌面分辨率时，将分享整个桌面
        */
        virtual int starScreenShareByWindowId(unsigned int windowId) = 0;

        /**
        * @brief 获取分享的窗口是否有效
        * @param windowId 窗口Id(可通过GetScreenShareSourceInfo接口获取)
        * @return
        * - true:  有效
        * - false: 无效
        * @note
        * - 多次无效可判定为用户窗口分享结束
        */
        virtual bool checkScreenShareWindowIdValid(unsigned int windowId) = 0;

        /**
         * @brief 以josn字符串的格式，设置自定义属性
         * @param parameter 自定义属性参数
         * @return
         * - 0: 成功
         * - 非0: 失败
        */
        virtual int setParameter(const char* parameter) = 0;
        
        /**
         * @brief 以字符串的格式，获取自定义属性
         * @param parameter 自定义属性参数
         * @return 属性值
        */
        virtual String getParameter(const char* parameter) = 0;
		/**
		 * @brief 是否推送第二条音频流
		 * @param enabled 是否开启/关闭第二条音频流推送
		 - true: 开启音频流推送
		 - false: 关闭音频流推送
		 * @return
		 - 0: 设置成功
		 - <0: 设置失败，返回错误码
		 * @note SDK默认设置推送音频流，在加入频道前也可以调用此接口修改默认值，并在加入频道成功时生效
		 */
		virtual int publishLocalDualAudioStream(bool enabled) = 0;

		/**
		 * @brief 扩展API
		 * @param parameter 扩展参数
		 * @return
		 - 0: 设置成功
		 - <0: 设置失败，返回错误码
		 * @note 扩展设置接口
		 */
		virtual int SetParameter(const char* parameter) = 0;
	
	};
};  // namespace AliVCSDK_ARTC
#endif /* ali_vc_live_pusher_h */
