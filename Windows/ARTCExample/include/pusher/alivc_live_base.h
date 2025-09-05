#ifndef ali_vc_live_base_h
#define ali_vc_live_base_h
/**
* ref doc: https://aliyuque.antfin.com/zxhy15/wubm3l/kaigbrn3gu1klczx
* ref git: https://code.alibaba-inc.com/aliyun-live/AliLivePushSDK/
* ref branch: blob/release/aio/v1.9.0/
* ref code: android/alivc-livepusher-lib/src/main/java/com/alivc/live/pusher/AlivcLiveBase.java
**/
#include "alivc_live_define.h"
#include "alivc_live_pusher.h"

/**
 * @brief AliVCSDK_ARTC namespace/
 */
namespace AliVCSDK_ARTC
{
    /**
     * @brief 日志级别
     */
    typedef enum {
        /** 只输出>=AlivcLivePushLogLevelAll 级别的日志 */
        AlivcLivePushLogLevelAll = 0,
        /** 只输出>=AlivcLivePushLogLevelVerbose 级别的日志 */
        AlivcLivePushLogLevelVerbose = 1,
        /** 只输出>=AlivcLivePushLogLevelDebug 级别的日志 */
        AlivcLivePushLogLevelDebug = 2,
        /** 只输出>=AlivcLivePushLogLevelInfo 级别的日志 */
        AlivcLivePushLogLevelInfo = 3,
        /** 只输出>=AlivcLivePushLogLevelWarn 级别的日志 */
        AlivcLivePushLogLevelWarn = 4,
        /** 只输出>=AlivcLivePushLogLevelError 级别的日志 */
        AlivcLivePushLogLevelError = 5,
        /** 不输出日志 */  
        AlivcLivePushLogLevelNone = 6,      
    } AlivcLivePushLogLevel;

    /**
     * @brief 直播连麦的基础控制类
     */
    class ALIVC_LIVE_API AlivcLiveBase
    {
    public:
        /**
         * @brief 查询sdk当前版本号
         * @return 当前的SDK版本号，格式为字符串，例："3.2.0.x"
         * @note 在任何时刻都可以调用
         */
        static const char* GetSDKVersion();

        /**
         * 判断SDK支持的推流模式
         * 基本版：只支持AlivcLiveBasicMode
         * 互动版：支持AlivcLiveBasicMode/AlivcLiveInteractiveMode
         *
         * @param liveMode 推拉流模式
         * @return true->支持；false->不支持
         */
        static bool isSupportLiveMode(AlivcLiveMode liveMode);

        /**
         * @brief 设置日志路径及日志分片大小，确保路径存在，可写
         * @param logDirPath 日志文件保存目录的绝对路径，该参数是一个目录路径，而不是文件的路径。
         * @param maxPartFileSizeInKB 每个分片最大大小。最终日志总体积是 5*最大分片大小
         * @return 
         * - 0，成功
         * - 非0，失败。其中有两种错误码，释义如下：
         *   - {@link AliEngineErrorLogRootPathError}: 路径已存在或因权限问题不可访问。
         *   - {@link AliEngineErrorLogAlreadyInit}：log对象已经初始化过。
         * 
         * @note 调用此接口，请在调用其他所有SDK接口前调用本接口，避免日志出现丢失。同时，App必须保证指定的目录已存在并且可以写入。
         * @note 如果，目标路径不可写入或创建日志文件失败，则会使用默认日志路径。本次设置将无效。
         */
        static int SetLogDirPath(const char *logDirPath, int maxPartFileSizeInKB);

        /**
         * @brief 设置日志等级
         * @param logLevel Log级别，详见{@link AlivcLivePushLogLevel}枚举类型
         * @note 设置 SDK 的输出日志等级。默认值为 {@link AlivcLivePushLogLevelInfo}。
         * @note 调用此接口，请在仅次于SetLogDirPath接口调用之后再调用本接口，避免因日志等级切换造成的打印丢失。
         */
        static void SetLogLevel(AlivcLivePushLogLevel logLevel);

        /**
         * 启用或禁用控制台日志打印
         *
         * @param enabled 指定是否启用
         */
        static void setConsoleEnabled(bool enabled);

        /**
         * 设置推流基础回调通知
         * 用于：
         * 异步接收License注册结果回调
         */
//        static void setListener(AlivcLiveBaseListener listener);

        /**
         * SDK注册License
         * 请先调用setListener接口，用于异步接收License注册结果回调
         *
         * @see <a href="https://help.aliyun.com/document_detail/431730.html">推流SDK License文档</a>
         */
//        static bool registerSDK();
    };
};  // namespace AliVCSDK_ARTC
#endif /* ali_vc_live_base_h */

