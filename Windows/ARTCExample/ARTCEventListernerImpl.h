#pragma once

#include "include\rtc\engine_interface.h"

using namespace AliRTCSdk;

#define MAX_LOG_STRING_SIZE		( 256 )
#define USE_LOG_STRING_SIZE		( MAX_LOG_STRING_SIZE-6 )

class CARTCExampleDlg;

class ARTCEventListernerImpl :public AliRTCSdk::AliEngineEventListener
{
public:
	ARTCEventListernerImpl();
	virtual ~ARTCEventListernerImpl();


		/**
		* @brief 加入频道结果
		* @param result 加入频道结果，成功返回0，失败返回错误码
		* @param channel 频道id.
		* @param userId  用户ID
		* @note 已废弃
		*/
		virtual void OnJoinChannelResult(int result, const char *channel, int elapsed) {
		}

		/**
		* @brief 加入频道结果
		* @details 当应用调用 {@link AliEngine::JoinChannel} 方法时，该回调表示成功/失败加入频道，并且返回频道加入的相关信息以及加入频道耗时
		* @param result 加入频道结果，成功返回0，失败返回错误码
		* @param channel 频道id.
		* @param userId  用户ID
		* @param elapsed 加入频道耗时
		*/
		virtual void OnJoinChannelResult(int result, const char *channel, const char *userId, int elapsed) {
			char logBuffer[MAX_LOG_STRING_SIZE];
			snprintf(logBuffer, USE_LOG_STRING_SIZE, "Login code:%d channel:%s userid:%s elapsed:%d", result, channel, userId, elapsed);

			SendMessageA(this->mLogHandle, LB_ADDSTRING, WPARAM(), (LPARAM)logBuffer);
		}

		/**
		* @brief 离开频道结果
		* @details 应用调用 {@link AliEngine::LeaveChannel} 方法时，该回调表示成功/失败离开频道，回调将会返回离会的result和该频道的基本信息,如果 {@link AliEngine::LeaveChannel} 后直接 {@link AliEngine::Destory} SDK，将不会收到此回调
		* @param result 离开频道结果，成功返回0，失败返回错误码
		* @param stats 本次频道内会话的数据统计汇总。
		*/
		virtual void OnLeaveChannelResult(int result, AliEngineStats stats) {
			char logBuffer[MAX_LOG_STRING_SIZE];
			snprintf(logBuffer, USE_LOG_STRING_SIZE, "leave channel result:%d", result);
			SendMessageA(this->mLogHandle, LB_ADDSTRING, WPARAM(), (LPARAM)logBuffer);
		}

		/**
		* @brief 远端用户（通信模式）/（互动模式，主播角色）加入频道回调
		* @details 该回调在以下场景会被触发
		* - 通信模式：远端用户加入频道会触发该回调，如果当前用户在加入频道前已有其他用户在频道中，当前用户加入频道后也会收到已加入频道用户的回调
		* - 互动模式：
		*   - 远端主播角色用户加入频道会触发该回调，如果当前用户在加入频道前已有其他主播在频道中，当前用户加入频道后也会收到已加入频道主播的回调
		*   - 远端观众角色调用 {@link AliEngine::SetClientRole} 切换为主播角色 {@link AliEngineClientRoleInteractive}，会触发该回调
		*
		* @param uid 用户ID 从App server分配的唯一标示符
		* @param elapsed 用户加入频道时的耗时
		* @note 互动模式下回调行为
		* - 主播间可以互相收到加入频道回调
		* - 观众可以收到主播加入频道回调
		* - 主播无法收到观众加入频道回调
		*/
		virtual void OnRemoteUserOnLineNotify(const char *uid, int elapsed) {
			char logBuffer[MAX_LOG_STRING_SIZE];
			snprintf(logBuffer, USE_LOG_STRING_SIZE, "user %s enter!", uid);
			SendMessageA(this->mLogHandle, LB_ADDSTRING, WPARAM(), (LPARAM)logBuffer);
		}

		/**
		* @brief 远端用户（通信模式）/（互动模式，主播角色）离开频道回调
		* @details 该回调在以下场景会被触发
		* - 通信模式：远端用户离开频道会触发该回调
		* - 互动模式：
		*   - 远端主播角色{@link AliEngineClientRoleInteractive}离开频道
		*   - 远端主播切换调用 {@link AliEngine::SetClientRole} 切换为观众角色{@link AliEngineClientRoleLive}，会触发该回调
		* - 通信模式和互动模式主播角色情况下，当长时间收不到远端用户数据，超时掉线时，会触发该回调
		*
		* @param uid 用户ID 从App server分配的唯一标示符
		* @param reason 用户离线的原因，详见 {@link AliEngineUserOfflineReason}
		*/
		virtual void OnRemoteUserOffLineNotify(const char *uid, AliEngineUserOfflineReason reason) {
			char logBuffer[MAX_LOG_STRING_SIZE];
			snprintf(logBuffer, USE_LOG_STRING_SIZE, "user %s leave! reason:%d ", uid, (int)reason);
			SendMessageA(this->mLogHandle, LB_ADDSTRING, WPARAM(), (LPARAM)logBuffer);
		}

		/**
		* @brief 音频推流变更回调
		* @param oldState 之前的推流状态
		* @param newState 当前的推流状态
		* @param elapseSinceLastState 状态变更时间间隔
		* @param channel 当前频道id
		*/
		virtual void OnAudioPublishStateChanged(AliEnginePublishState oldState, AliEnginePublishState newState, int elapseSinceLastState, const char *channel) {};


		virtual void OnAudioPublishStateChanged(AliEngineAudioTrack audioTrack, AliEnginePublishState oldState, AliEnginePublishState newState, int elapseSinceLastState, const char *channel) {};

		/**
		* @brief 视频推流变更回调
		* @param oldState 之前的推流状态
		* @param newState 当前的推流状态
		* @param elapseSinceLastState 状态变更时间间隔
		* @param channel 当前频道id
		*/
		virtual void OnVideoPublishStateChanged(AliEnginePublishState oldState, AliEnginePublishState newState, int elapseSinceLastState, const char *channel) {};

		/**
		* @brief 次要流推流变更回调
		* @param oldState 之前的推流状态
		* @param newState 当前的推流状态
		* @param elapseSinceLastState 状态变更时间间隔
		* @param channel 当前频道id
		*/
		virtual void OnDualStreamPublishStateChanged(AliEnginePublishState oldState, AliEnginePublishState newState, int elapseSinceLastState, const char *channel) {};

		/**
		* @brief 屏幕分享推流变更回调
		* @param oldState 之前的推流状态
		* @param newState 当前的推流状态
		* @param elapseSinceLastState 状态变更时间间隔
		* @param channel 当前频道id
		*/
		virtual void OnScreenSharePublishStateChanged(AliEnginePublishState oldState, AliEnginePublishState newState, int elapseSinceLastState, const char *channel) {};


		virtual void OnScreenSharePublishStateChangedWithInfo(AliEnginePublishState oldState, AliEnginePublishState newState, int elapseSinceLastState, const char *channel, AliEngineScreenShareInfo& screenShareInfo) {};


		/**
		* @brief 使用RTS URL推流结果
		* @details 应用调用 {@link AliEngine::PublishStreamByRtsUrl} 方法时，该回调表示推流成功/失败
		* @param result 推流结果，成功返回0，失败返回错误码
		*/
		virtual void OnPublishStreamByRtsUrlResult(const char* rts_url, int result) {};

		/**
		* @brief 使用RTS URL结束推流结果
		* @details 应用调用 {@link AliEngine::PublishStreamByRtsUrl} 方法时，该回调表示结束推流成功/失败
		* @param result 推流结果，成功返回0，失败返回错误码
		*/
		virtual void OnStopPublishStreamByRtsUrlResult(const char* rts_url, int result) {};

		/**
		* @brief 使用RTS URL订阅结果回调
		* @details 应用调用 {@link AliEngine::SubscribeStreamByRtsUrl} 方法时，该回调表示订阅成功/失败
		* @param uid 订阅的用户ID
		* @param result 订阅结果，成功返回0，失败返回错误码
		KNetOk = 0,
		KNetErrUnknown = -1,
		KNetRetry = -2,
		KNetAuthFailed = -3,
		kNetTimeout = -4,
		kNetNoStream = -5,
		KNetStopStream = -6,
		KNetRepeatRequest = -7,
		KNetDownRTMP = -8,
		KNetRtpHeaderExtFail = -9,
		KNetConnectionMobility = -10,
		KNetConnectionHertbeatTimeout = -11,
		kNetGslbFailed = -12,
		KNetEngineReset = -13,
		KNetOkWithoutStream = -14,
		KNetDisconnectStream = -15,
		KNetDnsFail = -16,
		KNetServerStopStream = -17,
		*/
		virtual void OnSubscribeStreamByRtsUrlResult(const char* uid, int result) {};

		/**
		* @brief 使用RTS URL取消订阅结果回调
		* @details 应用调用 {@link AliEngine::StopSubscribeStreamByRtsUrl} 方法时，该回调表示取消订阅成功/失败
		* @param uid 取消订阅的用户ID
		* @param result 取消订阅结果，成功返回0，失败返回错误码
		*/
		virtual void OnStopSubscribeStreamByRtsUrlResult(const char* uid, int result) {};

		/**
		* @brief 预建联数目超限回调
		* @details 应用调用 {@link AliEngine::SubscribeStreamByRtsUrl} 方法时如果超出预建联流数上限，则会停止订阅并销毁最早的RTS流，停止订阅的结果将在{@link AliEngineEventListener::OnStopSubscribeStreamByRtsUrlResult}中回调。
		* @param uid 销毁订阅RTS流的用户ID
		* @param url 销毁订阅RTS流的URL
		*/
		virtual void OnSubscribedRtsStreamBeyondLimit(const char* uid, const char* url) {};

		/**
		* @brief 使用RTS UID 暂停订阅结果回调
		* @details 应用调用 {@link AliEngine::PauseRtsStreamByRtsUserId} 方法时，该回调表示暂停订阅成功/失败
		* @param uid 暂停订阅的用户ID
		* @param result 暂停订阅结果，成功返回0，失败返回错误码
		*/
		virtual void OnPauseRtsStreamResult(const char* uid, int result) {};

		/**
		* @brief 使用RTS UID 恢复订阅结果回调
		* @details 应用调用 {@link AliEngine::ResumeRtsStreamByRtsUserId} 方法时，该回调表示恢复订阅成功/失败
		* @param uid 恢复订阅的用户ID
		* @param result 恢复订阅结果，成功返回0，失败返回错误码
		*/
		virtual void OnResumeRtsStreamResult(const char* uid, int result) {};

		/**
		* @brief 远端用户的音视频流发生变化回调
		* @details 该回调在以下场景会被触发
		* - 当远端用户从未推流变更为推流（包括音频和视频）
		* - 当远端用户从已推流变更为未推流（包括音频和视频）
		* - 互动模式下，调用 {@link AliEngine::SetClientRole} 切换为主播角色 {@link AliEngineClientRoleInteractive}，同时设置了推流时，会触发该回调
		* @param uid userId，从App server分配的唯一标示符
		* @param audioTrack 音频流类型，详见 {@link AliEngineAudioTrack}
		* @param videoTrack 视频流类型，详见 {@link AliEngineVideoTrack}
		* @note 该回调仅在通信模式用户和互动模式下的主播角色才会触发
		*/
		virtual void OnRemoteTrackAvailableNotify(const char *uid,
			AliEngineAudioTrack audioTrack,
			AliEngineVideoTrack videoTrack);
		/**
		* @brief 远端用户设备id回调
		* @details 一旦开启声纹降噪，该回调必会触发
		* - 当远端用户sdk版本较低，不透传设备id时，则回调魔数
		*/
		virtual void OnRemoteDeviceIdNotify(const char *uid, const char *deviceId) {}

		/**
		* @brief 音频订阅情况变更回调
		* @param uid userId，从App server分配的唯一标示符
		* @param oldState 之前的订阅状态，详见 {@link AliRTCSdk::AliEngineSubscribeState}
		* @param newState 当前的订阅状态，详见 {@link AliRTCSdk::AliEngineSubscribeState}
		* @param elapseSinceLastState 两次状态变更时间间隔(毫秒)
		* @param channel 当前频道id
		*/
		virtual void OnAudioSubscribeStateChanged(const char *uid,
			AliEngineSubscribeState oldState,
			AliEngineSubscribeState newState,
			int elapseSinceLastState,
			const char *channel) {};


		virtual void OnAudioSubscribeStateChanged(const char *uid,
			AliEngineAudioTrack audioTrack,
			AliEngineSubscribeState oldState,
			AliEngineSubscribeState newState,
			int elapseSinceLastState,
			const char *channel) {};

		/**
		* @brief 相机流订阅情况变更回调
		* @param uid userId，从App server分配的唯一标示符
		* @param oldState 之前的订阅状态，详见 {@link AliRTCSdk::AliEngineSubscribeState}
		* @param newState 当前的订阅状态，详见 {@link AliRTCSdk::AliEngineSubscribeState}
		* @param elapseSinceLastState 两次状态变更时间间隔(毫秒)
		* @param channel 当前频道id
		*/
		virtual void OnVideoSubscribeStateChanged(const char *uid,
			AliEngineSubscribeState oldState,
			AliEngineSubscribeState newState,
			int elapseSinceLastState,
			const char *channel) {};

		/**
		* @brief 屏幕分享流订阅情况变更回调
		* @param uid userId，从App server分配的唯一标示符
		* @param oldState 之前的订阅状态，详见 {@link AliRTCSdk::AliEngineSubscribeState}
		* @param newState 当前的订阅状态，详见 {@link AliRTCSdk::AliEngineSubscribeState}
		* @param elapseSinceLastState 两次状态变更时间间隔(毫秒)
		* @param channel 当前频道id
		*/
		virtual void OnScreenShareSubscribeStateChanged(const char *uid,
			AliEngineSubscribeState oldState,
			AliEngineSubscribeState newState,
			int elapseSinceLastState,
			const char *channel) {};

		/**
		* @brief 大小订阅情况变更回调
		* @param uid userId，从App server分配的唯一标示符
		* @param oldStreamType 之前的订阅的大小流类型，详见 {@link AliRTCSdk::AliEngineVideoStreamType}
		* @param newStreamType 当前的订阅的大小流类型，详见 {@link AliRTCSdk::AliEngineVideoStreamType}
		* @param elapseSinceLastState 大小流类型变更时间间隔(毫秒)
		* @param channel 当前频道id
		*/
		virtual void OnSubscribeStreamTypeChanged(const char *uid,
			AliEngineVideoStreamType oldStreamType,
			AliEngineVideoStreamType newStreamType,
			int elapseSinceLastState,
			const char *channel) {};

		/**
		* @brief 网络质量变化时发出的消息
		* @param uid  网络质量发生变化的用户uid
		* @param upQuality 上行网络质量，详见 {@link AliRTCSdk::AliEngineNetworkQuality}
		* @param downQuality 下行网络质量，详见 {@link AliRTCSdk::AliEngineNetworkQuality}
		* @note 当网络质量发生变化时触发，uid为空时代表用户自己的网络质量发生变化
		*/
		virtual void OnNetworkQualityChanged(const char *uid,
			AliEngineNetworkQuality upQuality,
			AliEngineNetworkQuality downQuality) {}

		/**
		* @brief 是否推静态图片。在通过 {@link AliEngine::SetPublishImage}设置了替代图片，上行网络状态差的情况下回调。
		* @param trackType 视频流类型
		* @param isStaticFrame
		* - true: 上行网络差，开始推静态图片
		* - false: 上行网络恢复，推正常采集数据
		*/
		virtual void OnPublishStaticVideoFrame(AliEngineVideoTrack trackType, bool isStaticFrame) {}

		/**
		* @brief 被服务器踢出频道的消息
		* @param code onBye类型，详见 {@link AliEngineOnByeType}
		*/
		virtual void OnBye(int code) {}

		/**
		* @brief 如果engine出现warning，通过这个消息通知app
		* @param warn 警告类型
		* @param msg 警告信息
		*/
		virtual void OnOccurWarning(int warn, const char *msg) {}

		/**
		* @brief 如果engine出现error，通过这个回调通知app
		* @param error  错误类型，参考 {@link AliEngineErrorCode}
		* @param msg 错误描述
		*/
		virtual void OnOccurError(int error, const char *msg) {}

		/**
		* @brief 当前设备性能不足
		*/
		virtual void OnPerformanceLow() {}

		/**
		* @brief 当前设备性能恢复
		*/
		virtual void OnPerformanceRecovery() {}

		/**
		* @brief 远端用户的第一帧视频帧显示时触发这个消息
		* @param uid User ID，从App server分配的唯一标示符
		* @param videoTrack 屏幕流或者相机流，参考 {@link AliEngineVideoTrack}
		* @param width 视频宽度
		* @param height 视频高度
		* @param elapsed 本地用户加入频道直至该回调触发的延迟总耗时（毫秒）
		* @note 该接口用于远端用户的第一帧视频帧显示时的回调
		*/
		virtual void OnFirstRemoteVideoFrameDrawn(const char *uid,
			AliEngineVideoTrack videoTrack,
			int width,
			int height,
			int elapsed) {}

		/**
		* @brief 预览开始显示第一帧视频帧时触发这个消息
		* @param width 本地预览视频宽度
		* @param height 本地预览视频高度
		* @param elapsed 从本地用户加入频道直至该回调触发的延迟总耗时（毫秒）
		* @note 该接口用于预览开始显示第一帧视频帧时的回调
		*/
		virtual void OnFirstLocalVideoFrameDrawn(int width, int height, int elapsed) {}

		/**
		* @brief 音频首包发送回调
		* @details 在首个音频数据包发送出去时触发此回调
		* @param timeCost 发送耗时，从入会开始到音频首包发送出去的耗时
		*/
		virtual void OnFirstAudioPacketSend(int timeCost) {};


		virtual void OnFirstAudioPacketSend(AliEngineAudioTrack audioTrack, int timeCost) {};

		/**
		* @brief 音频首包接收回调
		* @details 在接收到远端首个音频数据包时触发此回调
		* @param uid 远端用户ID，从App server分配的唯一标识符
		* @param timeCost 接收耗时，从入会开始到音频首包接收到的耗时
		*/
		virtual void OnFirstAudioPacketReceived(const char* uid, int timeCost) {}


		virtual void OnFirstAudioPacketReceived(const char* uid, AliEngineAudioTrack audioTrack, int timeCost) {}

		/**
		* @brief 已解码远端音频首帧回调
		* @param uid 远端用户ID，从App server分配的唯一标识符
		* @param elapsed 从本地用户加入频道直至该回调触发的延迟, 单位为毫秒
		*/
		virtual void OnFirstRemoteAudioDecoded(const char* uid, int elapsed) {}


		virtual void OnFirstRemoteAudioDecoded(const char* uid, AliEngineAudioTrack audioTrack, int elapsed) {}

		/**
		* @brief 视频首包发送回调
		* @param videoTrack 发送视频track，参考 {@link AliEngineVideoTrack}
		* @param timeCost 耗时（毫秒）
		* @note 该接口用于视频首包发送的回调
		*/
		virtual void OnFirstVideoPacketSend(AliEngineVideoTrack videoTrack, int timeCost) {};

		/**
		* @brief 视频首包接收回调
		* @param uid User ID，从App server分配的唯一标示符
		* @param videoTrack 接收视频track，参考 {@link AliEngineVideoTrack}
		* @param timeCost 耗时（毫秒）
		* @note 该接口用于视频首包接收的回调
		*/
		virtual void OnFirstVideoPacketReceived(const char* uid,
			AliEngineVideoTrack videoTrack,
			int timeCost) {}

		/**
		* @brief 收到远端用户视频首帧的回调
		* @param uid User ID，从App server分配的唯一标示符
		* @param videoTrack 接收视频track，参考 {@link AliEngineVideoTrack}
		* @param timeCost 耗时（毫秒）
		* @note 该接口用于收到远端用户视频首帧的回调
		*/
		virtual void OnFirstVideoFrameReceived(const char* uid,
			AliEngineVideoTrack videoTrack,
			int timeCost) {};

		/**
		* @brief 网络断开
		*/
		virtual void OnConnectionLost() {}

		/**
		* @brief 开始重连
		*/
		virtual void OnTryToReconnect() {}

		/**
		* @brief 重连成功
		*/
		virtual void OnConnectionRecovery() {}

		/**
		* @brief 网络连接状态改变的回调
		* @param status 当前网络链接状态，参考 {@link AliRTCSdk::AliEngineConnectionStatus}
		* @param reason 网络链接状态改变原因，参考 {@link AliRTCSdk::AliEngineConnectionStatusChangeReason}
		*/
		virtual void OnConnectionStatusChange(int status, int reason) {};

		/**
		* @brief 远端用户静音/取消静音回调
		* @param uid 远端用户ID
		* @param isMute 该用户是否静音
		* - true: 静音
		* - false: 取消静音
		*/
		virtual void OnUserAudioMuted(const char* uid, bool isMute) {}

		/**
		* @brief 对端用户发送视频黑帧数据发送通知
		* @param uid 执行muteVideo的用户
		* @param isMute
		* - true: 推流黑帧
		* - false: 正常推流
		* @note 该接口用于对端用户发送视频黑帧数据时的回调
		*/
		virtual void OnUserVideoMuted(const char* uid, bool isMute) {}

		/**
		* @brief 对端用户关闭相机流采集发送通知
		* @param uid 执行EnableLocalVideo的用户
		* @param isEnable
		* - true: 打开相机流采集
		* - false: 关闭相机流采集
		* @note 该接口用于对端用户关闭相机流采集时的回调
		*/
		virtual void OnUserVideoEnabled(const char* uid, bool isEnable) {}

		/**
		* @brief 用户音频被中断通知（一般用户打电话等音频被抢占场景）
		* @param uid 音频被中断的用户ID
		*/
		virtual void OnUserAudioInterruptedBegin(const char* uid) {}

		/**
		* @brief 用户音频中断结束通知（对应 {@link OnUserAudioInterruptedBegin}）
		* @param uid 音频中断结束的用户ID
		*/
		virtual void OnUserAudioInterruptedEnded(const char* uid) {}

		/**
		* @brief 远端用户伴奏播放开始回调
		* @param uid 远端用户ID，从App server分配的唯一标识符
		*/
		virtual void OnRemoteAudioAccompanyStarted(const char* uid) {}

		/**
		* @brief 远端用户伴奏播放结束回调
		* @param uid 远端用户ID，从App server分配的唯一标识符
		*/
		virtual void OnRemoteAudioAccompanyFinished(const char* uid) {}

		/**
		* @brief 远端用户应用退到后台
		* @param uid 用户
		*/
		virtual void OnUserWillResignActive(const char* uid) {}

		/**
		* @brief 远端用户应用返回前台
		* @param uid 用户
		*/
		virtual void OnUserWillBecomeActive(const char* uid) {}

		/**
		* @brief 当用户角色发生变化时通知
		* @param oldRole 变化前角色类型，参考{@link AliEngineClientRole}
		* @param newRole 变化后角色类型，参考{@link AliEngineClientRole}
		* @note 调用{@link setClientRole}方法切换角色成功时触发此回调
		*/
		virtual void OnUpdateRoleNotify(const AliEngineClientRole oldRole,
			const AliEngineClientRole newRole) {}

		/**
		* @brief 订阅的音频音量回调，其中callid为"0"表示本地推流音量，"1"表示远端混音音量，其他表示远端用户音量
		* @param volumeInfo 说话人音量信息
		* @param volumeInfoCount 回调的说话人的个数
		* @param totalVolume 混音后的总音量，范围[0,255]。在本地用户的回调中，totalVolume;为本地用户混音后的音量；在远端用户的回调中，totalVolume; 为所有说话者混音后的总音量
		*/
		virtual void OnAudioVolumeCallback(const AliEngineUserVolumeInfo* volumeInfo, int volumeInfoCount, int totalVolume) {}

		/**
		* @brief 订阅的当前说话人，当前时间段说话可能性最大的用户uid。如果返回的uid为0，则默认为本地用户
		* @param uid 说话人的用户ID
		*/
		virtual void OnActiveSpeaker(const char *uid) {}

		/**
		* @brief 本地伴奏播放状态回调
		* @details 该回调在伴奏播放状态发生改变时触发，并通知当前的播放状态和错误码
		* @param type 当前播放状态，详情参考{@link AliEngineAudioPlayingType}
		* @param errorCode 播放错误码，详情参考{@link AliEngineAudioPlayingErrorCode}
		*/
		virtual void OnAudioAccompanyStateChanged(AliEngineAudioAccompanyStateCode playState,
			AliEngineAudioAccompanyErrorCode errorCode) {}
		/**
		* @brief 音频文件信息回调
		* @details 该回调在调用{@link AliEngine::GetAudioFileInfo}后触发，返回当前音频文件信息和错误码
		* @param info 音频文件信息，详情参考 {@link AliRtcAudioFileInfo}
		* @param errorCode 错误码，详情参考 {@link AliRtcAudioAccompanyErrorCode}
		*/
		virtual void OnAudioFileInfo(AliEngineAudioFileInfo info,
			AliEngineAudioAccompanyErrorCode errorCode) {}

		/**
		* @brief 本地音效播放结束回调
		* @param soundId 用户给该音效文件分配的唯一ID
		*/
		virtual void OnAudioEffectFinished(int soundId) {}

		/**
		* @brief 网络质量探测回调
		* @param networkQuality 网络质量 {@link AliEngineNetworkQuality}
		* @note 当调用 {@link AliEngine::StartLastmileDetect} 3s后会触发该回调
		*/
		virtual void OnLastmileDetectResultWithQuality(AliEngineNetworkQuality networkQuality) {}

		/**
		* @brief 网络质量探测结果的回调
		* @param networkQuality 网络探测结果 {@link AliEngineNetworkProbeResult}
		* @note 当调用 {@link AliEngine::StartLastmileDetect} 30s后会触发该回调
		*/
		virtual void OnLastmileDetectResultWithBandWidth(int code, AliRTCSdk::AliEngineNetworkProbeResult networkQuality) {}

		/**
		* @brief 音频采集设备测试回调
		* @param level 音频采集设备音量值
		*/
		virtual void OnAudioDeviceRecordLevel(int level) {};

		/**
		* @brief 音频播放设备测试回调
		* @param level 音频采集设备音量值
		*/
		virtual void OnAudioDevicePlayoutLevel(int level) {};

		/**
		* @brief 音频播放设备测试结束(音频文件播放完毕)
		*/
		virtual void OnAudioDevicePlayoutEnd() {};

		/**
		* @brief 文件录制回调事件
		* @param event 录制事件，0：录制开始，1：录制结束，2：打开文件失败，3：写文件失败
		* @param filePath 录制文件路径
		* @note 该接口用于文件录制时的事件回调
		*/
		virtual void OnMediaRecordEvent(int event, const char* filePath) {}

		/**
		* @brief 当前会话统计信息回调
		* @param stats 会话统计信息
		* @note SDK每两秒触发一次此统计信息回调
		*/
		virtual void OnStats(const AliEngineStats& stats) {}

		/**
		* @brief 本地视频统计信息
		* @param localVideoStats 本地视频统计信息
		* @note SDK每两秒触发一次此统计信息回调
		*/
		virtual void OnLocalVideoStats(const AliEngineLocalVideoStats& localVideoStats) {}

		/**
		* @brief 远端视频统计信息
		* @param remoteVideoStats 远端视频统计信息
		* @note SDK每两秒触发一次此统计信息回调
		*/
		virtual void OnRemoteVideoStats(const AliEngineRemoteVideoStats& remoteVideoStats) {}

		/**
		* @brief 本地音频统计信息
		* @param localAudioStats 本地视频统计信息
		* @note SDK每两秒触发一次此统计信息回调
		*/
		virtual void OnLocalAudioStats(const AliEngineLocalAudioStats& localAudioStats) {}

		/**
		* @brief 远端音频统计信息
		* @param remoteAudioStats 远端视频统计信息
		* @note SDK每两秒触发一次此统计信息回调
		*/
		virtual void OnRemoteAudioStats(const AliEngineRemoteAudioStats& remoteAudioStats) {}

		/**
		* @brief 低延时互动直播模式start回调
		* @param result 是否start成功
		* @note 该回调仅在低延时互动模式且角色为观众时，调用 {@link AliEngine::StartLiveStreaming} 才会回调
		* @deprecated
		*/
		virtual void OnStartLiveStreamingResult(int result) {}

		/**
		* @brief 收到媒体扩展信息回调
		* @param uid 发送用户userId
		* @param message 扩展信息内容
		* @param size 扩展信息长度
		* @note 当一端通过 {@link AliEngine::SendMediaExtensionMsg} 发送信息后，其他端通过该回调接收数据
		*/
		virtual void OnMediaExtensionMsgReceived(const char* uid, const uint8_t payloadType, const int8_t * message, uint32_t size) {};

		/**
		* @brief 音频设备状态变更
		* @param deviceInfo  外接设备信息
		* @param deviceType  外接设备类型
		* @param deviceState 外接设备状态
		*/
		virtual void OnAudioDeviceStateChanged(const AliEngineDeviceInfo& deviceInfo, AliEngineExternalDeviceType deviceType, AliEngineExternalDeviceState deviceState) {};

		/**
		* @brief 音频焦点状态变更
		* @param audioFocus  音频焦点类型
		*/
		virtual void OnAudioFocusChanged(AliEngineAudioFocusType audioFocus) {};

		/**
		* @brief 视频设备状态变更
		* @param deviceInfo  外接设备信息
		* @param deviceType  外接设备类型
		* @param deviceState 外接设备状态
		*/
		virtual void OnVideoDeviceStateChanged(const AliEngineDeviceInfo& deviceInfo, AliEngineExternalDeviceType deviceType, AliEngineExternalDeviceState deviceState) {};

		/**
		* @brief 下行消息通道(接收消息)
		* @param messageInfo 消息内容
		* @note 该接口接收到下行消息后，使用 {@link AliEngine::SendDownlinkMessageResponse} 发送反馈消息
		* @note 已废弃使用
		* @deprecated
		*/
		virtual void OnDownlinkMessageNotify(const AliEngineMessage &messageInfo) {};

		/**
		* @brief 上行消息返回结果(接收消息)
		* @param resultInfo 发送结果
		* @note 使用 {@link AliEngine::SendUplinkMessage} 发送消息后，会触发该接口接收上行消息反馈
		* @note 已废弃使用
		* @deprecated
		*/
		virtual void OnUplinkMessageResponse(const AliEngineMessageResponse &resultInfo) {};


		/**
		* @brief 分辨率变化回调
		* @param uid 用户id
		* @param track 变化视频track
		* @param width 当前视频宽
		* @param height 当前视频高
		* @note 已废弃使用
		*/
		virtual void OnVideoResolutionChanged(const char* uid,
			AliEngineVideoTrack track,
			int width,
			int height) {};

		/**
		* @brief 截图回调
		* @param userId 用户id
		* @param videoTrack 截图视频track，参考 {@link AliEngineVideoTrack}
		* @param buffer 成功返回截图数据，失败为NULL，buffer数据格式RGBA
		* @param width 截图宽度
		* @param height 截图高度
		* @param success 截图是否成功
		* @note 该接口用于截图回调
		*/
		virtual void OnSnapshotComplete(const char* userId, AliEngineVideoTrack videoTrack, void* buffer, int width, int height, bool success) {}

		/**
		* @brief 旁路推流状态改变回调
		* @param streamUrl 流地址
		* @param state 推流状态, 参考 {@link AliEngineLiveTranscodingState}
		* @param errCode 错误码, 参考 {@link AliEngineLiveTranscodingErrorCode}
		* @note 该接口用于旁路推流状态改变的回调
		*/
		virtual void OnPublishLiveStreamStateChanged(const char* streamUrl, AliEngineLiveTranscodingState state, AliEngineLiveTranscodingErrorCode errCode) {};

		/**
		* @brief 旁路推流状态改变回调
		* @param taskId 任务id
		* @param state 推流状态, 参考 {@link AliEngineLiveTranscodingState}
		* @param errCode 错误码, 参考 {@link AliEngineLiveTranscodingErrorCode}
		* @note 该接口用于旁路推流状态改变的回调，只有用户未设置streamUrl时才会回调该接口
		*/
		virtual void OnPublishLiveStreamStateChangedWithTaskId(const char* taskId, AliEngineLiveTranscodingState state, AliEngineLiveTranscodingErrorCode errCode) {};

		/**
		* @brief 旁路任务状态改变回调
		* @param streamUrl  流地址
		* @param state 任务状态, 参考 {@link AliEngineTrascodingPublishTaskStatus}
		* @note 该接口用于旁路任务状态改变的回调
		*/
		virtual void OnPublishTaskStateChanged(const char* streamUrl, AliEngineTrascodingPublishTaskStatus state) {};

		/**
		* @brief 旁路任务状态改变回调
		* @param taskId 任务id
		* @param state 任务状态, 参考 {@link AliEngineTrascodingPublishTaskStatus}
		* @note 该接口用于旁路任务状态改变的回调，只有用户未设置streamUrl时才会回调该接口
		*/
		virtual void OnPublishTaskStateChangedWithTaskId(const char* taskId, AliEngineTrascodingPublishTaskStatus state) {};

		/**
		* @brief 跨频道转推状态变化通知
		* @param state 当前连麦状态，参考 {@link AliEngineChannelRelayState}
		* @param code 当前错误码，参考 {@link AliEngineChannelRelayErrorCode}
		* @param msg 状态描述信息
		*/
		virtual void OnChannelRelayStateChanged(int state, int code, const char* msg) {};

		/**
		* @brief 跨频道转推事件通知
		* @param state 状态码，参考 {@link AliEngineChannelRelayEvent}
		*/
		virtual void OnChannelRelayEvent(int state) {};

		/**
		* @brief 用户remote video change通知
		* @param uid 需要被通知的用户
		* @param track 变化视频track
		* @param state 视频状态的类型
		* @param reason 触发状态变化的原因
		*/
		virtual void OnRemoteVideoChanged(const char* uid, AliEngineVideoTrack trackType, const AliEngineVideoState state, const AliEngineVideoReason reason) {};

		/**
		* @brief 用户AliEngineAuthInfo authInfo即将过期通知,30秒后过期
		*/
		virtual void OnAuthInfoWillExpire() {};

		/**
		* @brief 用户调用需要鉴权的接口，服务端返回信息过期
		*/
		virtual void OnAuthInfoExpired() {};

		/**
		* @brief Qos参数发生变化通知
		* @param trackType 变化视频track
		* @param paramter qos参数结构体
		*/
		virtual void OnRequestVideoExternalEncoderParameter(AliEngineVideoTrack trackType, const AliEngineVideoExternalEncoderParameter& paramter) {};
		/**
		* @brief Qos请求帧类型发生变化通知
		* @param trackType 变化视频track
		* @param frame_type 请求参考帧类型
		*/
		virtual void OnRequestVideoExternalEncoderFrame(AliEngineVideoTrack trackType, AliEngineVideoEncodedFrameType frame_type) {};
		/**
		* @brief API 方法已执行回调。
		* @param error 当该方法调用失败时 SDK 返回的错误码。如果该方法调用成功，SDK 将返回 0。失败，非0.
		* @param api SDK 执行的 API.
		* @param result SDK 调用 API 的调用结果.
		*/
		virtual void OnCalledApiExecuted(int error, const char *api, const char *result) {};

		/**
		* @brief 推流使用的编码器信息回调
		* @param localAudioStats 本地视频统计信息
		* @note 推流开始后通知用户
		*/
		virtual void OnVideoEncoderNotify(const AliEngineEncoderNotifyInfo& encoderNotifyInfo) {};

		/**
		* @brief 使用的解码器信息回调
		* @param decoderNotifyInfo 解码器变更信息
		* @note 推流开始后通知用户
		*/
		virtual void OnVideoDecoderNotify(const AliEngineDecoderNotifyInfo& decoderNotifyInfo) {};

		/**
		* @brief 本地设备异常回调
		* @param deviceType 设备类型, 参考{@link AliEngineLocalDeviceType}
		* @param exceptionType 设备异常类型, 参考{@link AliEngineLocalDeviceExceptionType}
		* @param msg 异常时携带的信息
		* @note 此回调标识了内部无法恢复了设备异常，收到此回调时用户需要检查设备是否可用
		*/
		virtual void OnLocalDeviceException(AliEngineLocalDeviceType deviceType, AliEngineLocalDeviceExceptionType exceptionType, const char* msg) {};

		/**
		* @brief 本地音频设备状态回调
		* @param state  当前状态，AliEngineLocalAudioStateType类型
		*/
		virtual void OnLocalAudioStateChange(AliEngineLocalAudioStateType state, const char* msg) {};

		/**
		* @brief 本地视频设备状态回调
		* @param state  当前状态，AliRtcLocalVideoStateType类型
		*/
		virtual void onLocalVideoStateChanged(AliEngineLocalVideoStateType state, const char* msg) {};

		/**
		* @brief 伴奏控制消息
		* @param uid 用户
		* @param msg 消息
		* @param
		*/
		virtual void OnDataChannelMessage(const char* uid, const AliEngineDataChannelMsg& msg) {}

		/**
		* @brief 音频延迟信息
		* @param id 语句id
		* @param questionEndTime 提问结束时刻
		* @param answerStartTime 回答开始时刻
		* @param
		*/
		virtual void OnAudioDelayInfo(int scentenceId, int64_t questionEndTime, int64_t answerStartTime) {}

		void SetLogHandle(HWND logListHwnd, CARTCExampleDlg * dlg);

		protected:
			HWND	mLogHandle;
			CARTCExampleDlg * mDlg;
	};


