#ifndef ali_vc_live_player_h
#define ali_vc_live_player_h
/**
* ref doc: https://aliyuque.antfin.com/zxhy15/wubm3l/kaigbrn3gu1klczx
* ref git: https://code.alibaba-inc.com/aliyun-live/AliLivePushSDK/
* ref branch: blob/release/aio/v1.9.0/
* ref code: android/alivc-livepusher-lib/src/main/java/com/alivc/live/player/AlivcLivePlayer.java
**/
#include "alivc_live_define.h"
#include "alivc_live_listener.h"
#include "pusher/alivc_live_pusher.h"
/**
 * @brief AliVCSDK_ARTC namespace/
 */
namespace AliVCSDK_ARTC
{
    /**
     * @brief 视频纹理格式
     */
    typedef enum {
      AlivcLiveTextureTypeUnknown = -1,
      AlivcLiveTextureTypePre = 0,
      AlivcLiveTextureTypePost = 1,
    } AlivcLiveTextureType;


    /**
     * @brief 视频旋转角度
     */
    typedef enum {
        /** 沿用之前的旋转角度 */
      AlivcLiveRotationModeNoChange = -1,
        /** 0 */
      AlivcLiveRotationMode_0 = 0,
        /** 90 */
      AlivcLiveRotationMode_90 = 90,
        /** 180 */
      AlivcLiveRotationMode_180 = 180,
        /** 270 */
      AlivcLiveRotationMode_270 = 270,
    } AlivcLiveRotationMode;
    
    /**
     * @brief 视频窗口镜像模式
     */
    typedef enum {
        /** 只有前置摄像头预览镜像，其余不镜像 */
        AlivcLiveRenderMirrorModeOnlyFrontMirror  = 0,
        /** 镜像开启 */
        AlivcLiveRenderMirrorModeAllMirror        = 1,
        /** 镜像关闭 */
        AlivcLiveRenderMirrorModeAllNoMirror      = 2,
        /** 占位符，无意义 */
        AlivcLiveRenderMirrorModeNoChange         = 99,
    } AlivcLiveRenderMirrorMode;
    /**
     * @brief 视频宽高比
     */
    typedef enum  {
        /** 16 : 9 */
      AlivcLiveVideoScale_16_9 = 0,
        /** 4 : 3 */
      AlivcLiveVideoScale_4_3,
    }AlivcLiveVideoScale;

    /**
     * @brief 视频流类型
     */
    typedef enum {
      /** 摄像头流 */
      stream_camera = 1,
      /** 屏幕共享流 */
      stream_screen = 2,
    } AlivcLivePlayVideoStreamType;

    /**
     * @brief 音频流类型
     */
    typedef enum {
      /** mic流 */
      stream_mic = 1,
      stream_dual_audio = 2,
      /** mic流 */
    } AlivcLivePlayAudioStreamType;

    /**
     * @brief 拉流配置类
     * @note setup初始化用
     */
    typedef struct AlivcLivePlayConfig  {
        /** 拉流模式，默认：AlivcLiveBasicMode */
        AlivcLiveMode mode;
        /** 播放是否镜像, 默认：false，非镜像 */
        bool isMirror{false};
        /** 播放是否全屏, 默认：false，非全屏 */
        bool isFullScreen{false};
        /** 渲染模式，默认值为{@link AliRTCSdk::AlivcLiveRenderModeAuto} */
        AlivcLiveRenderMode renderMode = AlivcLiveRenderMode::AlivcLiveRenderModeAuto;
        /** 旋转角度，默认值为 {@link AliRTCSdk::AlivcLiveRotationMode_0} */
        AlivcLiveRotationMode rotation = AlivcLiveRotationMode_0;
        /** 指定播放的音频流类型 */
        AlivcLivePlayAudioStreamType audioType = AlivcLivePlayAudioStreamType::stream_mic;
        /** 指定播放的视频流类型*/
        AlivcLivePlayVideoStreamType videoType = AlivcLivePlayVideoStreamType::stream_camera;
    }AlivcLivePlayConfig ;

        
    /**
     * @brief 编解码器类型
     */
    typedef enum {
        /** 软件解码 */
        AlivcLiveVideoDecoderImplSoftware = 0,
        /** 硬件解码 */
        AlivcLiveVideoDecoderImplHardware = 1,
    }AlivcLiveVideoDecoderImplType;

    typedef struct AlivcLiveVideoDecoderConfig{
        AlivcLiveVideoDecoderConfig():
        implType(AlivcLiveVideoDecoderImplSoftware){}

        AlivcLiveVideoDecoderImplType implType;
    }AlivcLiveVideoDecoderConfig;    

    /**
     * @brief 直播连麦的拉流控制类
     */
    class ALIVC_LIVE_API AlivcLivePlayer
    {
    public:
        /**
         * @brief 创建一个拉流实例
         */
        static AlivcLivePlayer* Create(const char* extra);
        /**
         * @brief 初始化配置, 依赖于AlivcLivePusher的init方法来初始化实例
         *
         * @param playConfig 播放配置
         * @return 返回0，表示调用成功；非0，表示调用失败
         */
        virtual int setupWithConfig(AlivcLivePlayConfig playConfig) = 0;

        /**
         * @brief 设置播放View
         * <p>
         * 当前接口只在互动模式下生效!!!
         * <p>
         * 该接口用于设置互动场景下(连麦或者PK)场景下设置远端流的播放控件
         * 在连麦场景下，主播通过setPlayView接口设置连麦观众视频的播放view，连麦观众通过setPlayView接口设置主播的视频播放view
         * 在PK场景下，主播A和主播B PK,主播A和主播B分别调用setPlayView设置要PK的另一个主播的视频播放view
         *
         * @param view 布局，RTC内部根据view信息进行绘制
         * @return 返回0，表示调用成功；非0，表示调用失败
         */
        virtual int setPlayView(void *view, int width, int height) = 0;
        
        /**
         * @brief 开始播放音视频流
         * <p>
         * 当前接口只在互动模式下生效!!!
         * <p>
         * 该接口用于互动场景下(连麦或者PK)场景下播放连麦观众或者PK主播的音视频流
         * 在连麦场景下，主播通过startPlay接口播放连麦观众实时音视频流，连麦观众通过startPlay播放主播实时音视频流
         * 在PK场景下，主播A和主播B PK,主播A和主播B分别调用startPlay来播放要PK的另一个主播的音视频流
         *
         * @param url 主播或连麦观众的拉流(播放)地址
         * @return 返回0，表示调用成功；非0，表示调用失败
         */
        virtual int startPlay(const char* url) = 0;

        /**
         * @brief 停止播放视频流
         * <p>
         * 当前接口只在互动模式下生效!!!
         * <p>
         * 该接口和startPlay接口相对应
         *
         * @return 返回0，表示调用成功；非0，表示调用失败
         */
        virtual int stopPlay() = 0;
        
        /**
         * @brief 释放拉流
         * <p>
         * 当前接口只在互动模式下生效!!!
         */
        virtual void destroy() = 0;

        /**
         * @brief 调节本地播放的指定远端用户音量
         * @param volume 播放音量，取值范围[0,100] 0：静音；100：原始音量
         * @return
         * - 0: 成功
         * - 非0: 失败
         */
        virtual int setRemoteAudioVolume(int volume) = 0;

        /**
         * @brief 设置拉流通知事件
         * <p>
         * 当前接口只在互动模式下生效!!!
         *
         * @param infoListener 拉流播放监听器
         */
        virtual int setPlayInfoListener(AlivcLivePlayInfoListener *infoListener) = 0;

        /**
         * @brief 设置视频帧通知事件
         *
         * @param infoListener 通知监听器
         */
        virtual int setLivePlayVideoFrameListener(AlivcLiveVideoFrameListener* infoListener) = 0;

        /**
         * 设置音频帧通知事件
         *
         * @param audioFrameListener 通知监听器
         */
        virtual int setLivePlayAudioFrameListener(AlivcLiveAudioFrameListener* audioFrameListener) = 0;

        /**
         * @brief 获取当前拉流模式
         *
         * @return 拉流模式
         * @see AlivcLiveMode
         */
        virtual AlivcLiveMode getMode() = 0;

         /**
         * @brief 暂停播放音频流
         * @return
         * - 0: 成功
         * - 非0: 失败
         */
        virtual int pauseAudioPlaying() = 0;

        /**
         * @brief 恢复播放音频流
         * @return
         * - 0: 成功
         * - 非0: 失败
         */
        virtual int resumeAudioPlaying() = 0;

        /**
         * @brief 设置全局视频解码参数
         * <p>
         * 当前接口仅在拉流之前配置生效，拉流之后配置无效!!!
         * <p>
         * 此接口当前会修改所有的player解码参数，请谨慎修改
         * @param decoder_config 解码器配置结构AlivcLiveVideoDecoderConfig
         * @return
         * - 0: 成功
         * - 非0: 失败
         */
        static int setVideoDecoderConfig(const AlivcLiveVideoDecoderConfig decoder_config);

        /**
         * @brief 获取全局视频解码参数
         * <p>
         * 获取当前配置的全局解码期望参数，并不一定是每个player实际使用的解码参数
         * @param decoder_config 解码器配置结构AlivcLiveVideoDecoderConfig
         * @return
         * - 0: 成功
         * - 非0: 失败
         */
        static int getVideoDecoderConfig(AlivcLiveVideoDecoderConfig& decoder_config);        
    };
};
#endif /* ali_vc_live_player_h */
