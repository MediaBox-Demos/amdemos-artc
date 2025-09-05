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
		* @brief ����Ƶ�����
		* @param result ����Ƶ��������ɹ�����0��ʧ�ܷ��ش�����
		* @param channel Ƶ��id.
		* @param userId  �û�ID
		* @note �ѷ���
		*/
		virtual void OnJoinChannelResult(int result, const char *channel, int elapsed) {
		}

		/**
		* @brief ����Ƶ�����
		* @details ��Ӧ�õ��� {@link AliEngine::JoinChannel} ����ʱ���ûص���ʾ�ɹ�/ʧ�ܼ���Ƶ�������ҷ���Ƶ������������Ϣ�Լ�����Ƶ����ʱ
		* @param result ����Ƶ��������ɹ�����0��ʧ�ܷ��ش�����
		* @param channel Ƶ��id.
		* @param userId  �û�ID
		* @param elapsed ����Ƶ����ʱ
		*/
		virtual void OnJoinChannelResult(int result, const char *channel, const char *userId, int elapsed) {
			char logBuffer[MAX_LOG_STRING_SIZE];
			snprintf(logBuffer, USE_LOG_STRING_SIZE, "Login code:%d channel:%s userid:%s elapsed:%d", result, channel, userId, elapsed);

			SendMessageA(this->mLogHandle, LB_ADDSTRING, WPARAM(), (LPARAM)logBuffer);
		}

		/**
		* @brief �뿪Ƶ�����
		* @details Ӧ�õ��� {@link AliEngine::LeaveChannel} ����ʱ���ûص���ʾ�ɹ�/ʧ���뿪Ƶ�����ص����᷵������result�͸�Ƶ���Ļ�����Ϣ,��� {@link AliEngine::LeaveChannel} ��ֱ�� {@link AliEngine::Destory} SDK���������յ��˻ص�
		* @param result �뿪Ƶ��������ɹ�����0��ʧ�ܷ��ش�����
		* @param stats ����Ƶ���ڻỰ������ͳ�ƻ��ܡ�
		*/
		virtual void OnLeaveChannelResult(int result, AliEngineStats stats) {
			char logBuffer[MAX_LOG_STRING_SIZE];
			snprintf(logBuffer, USE_LOG_STRING_SIZE, "leave channel result:%d", result);
			SendMessageA(this->mLogHandle, LB_ADDSTRING, WPARAM(), (LPARAM)logBuffer);
		}

		/**
		* @brief Զ���û���ͨ��ģʽ��/������ģʽ��������ɫ������Ƶ���ص�
		* @details �ûص������³����ᱻ����
		* - ͨ��ģʽ��Զ���û�����Ƶ���ᴥ���ûص��������ǰ�û��ڼ���Ƶ��ǰ���������û���Ƶ���У���ǰ�û�����Ƶ����Ҳ���յ��Ѽ���Ƶ���û��Ļص�
		* - ����ģʽ��
		*   - Զ��������ɫ�û�����Ƶ���ᴥ���ûص��������ǰ�û��ڼ���Ƶ��ǰ��������������Ƶ���У���ǰ�û�����Ƶ����Ҳ���յ��Ѽ���Ƶ�������Ļص�
		*   - Զ�˹��ڽ�ɫ���� {@link AliEngine::SetClientRole} �л�Ϊ������ɫ {@link AliEngineClientRoleInteractive}���ᴥ���ûص�
		*
		* @param uid �û�ID ��App server�����Ψһ��ʾ��
		* @param elapsed �û�����Ƶ��ʱ�ĺ�ʱ
		* @note ����ģʽ�»ص���Ϊ
		* - ��������Ի����յ�����Ƶ���ص�
		* - ���ڿ����յ���������Ƶ���ص�
		* - �����޷��յ����ڼ���Ƶ���ص�
		*/
		virtual void OnRemoteUserOnLineNotify(const char *uid, int elapsed) {
			char logBuffer[MAX_LOG_STRING_SIZE];
			snprintf(logBuffer, USE_LOG_STRING_SIZE, "user %s enter!", uid);
			SendMessageA(this->mLogHandle, LB_ADDSTRING, WPARAM(), (LPARAM)logBuffer);
		}

		/**
		* @brief Զ���û���ͨ��ģʽ��/������ģʽ��������ɫ���뿪Ƶ���ص�
		* @details �ûص������³����ᱻ����
		* - ͨ��ģʽ��Զ���û��뿪Ƶ���ᴥ���ûص�
		* - ����ģʽ��
		*   - Զ��������ɫ{@link AliEngineClientRoleInteractive}�뿪Ƶ��
		*   - Զ�������л����� {@link AliEngine::SetClientRole} �л�Ϊ���ڽ�ɫ{@link AliEngineClientRoleLive}���ᴥ���ûص�
		* - ͨ��ģʽ�ͻ���ģʽ������ɫ����£�����ʱ���ղ���Զ���û����ݣ���ʱ����ʱ���ᴥ���ûص�
		*
		* @param uid �û�ID ��App server�����Ψһ��ʾ��
		* @param reason �û����ߵ�ԭ����� {@link AliEngineUserOfflineReason}
		*/
		virtual void OnRemoteUserOffLineNotify(const char *uid, AliEngineUserOfflineReason reason) {
			char logBuffer[MAX_LOG_STRING_SIZE];
			snprintf(logBuffer, USE_LOG_STRING_SIZE, "user %s leave! reason:%d ", uid, (int)reason);
			SendMessageA(this->mLogHandle, LB_ADDSTRING, WPARAM(), (LPARAM)logBuffer);
		}

		/**
		* @brief ��Ƶ��������ص�
		* @param oldState ֮ǰ������״̬
		* @param newState ��ǰ������״̬
		* @param elapseSinceLastState ״̬���ʱ����
		* @param channel ��ǰƵ��id
		*/
		virtual void OnAudioPublishStateChanged(AliEnginePublishState oldState, AliEnginePublishState newState, int elapseSinceLastState, const char *channel) {};


		virtual void OnAudioPublishStateChanged(AliEngineAudioTrack audioTrack, AliEnginePublishState oldState, AliEnginePublishState newState, int elapseSinceLastState, const char *channel) {};

		/**
		* @brief ��Ƶ��������ص�
		* @param oldState ֮ǰ������״̬
		* @param newState ��ǰ������״̬
		* @param elapseSinceLastState ״̬���ʱ����
		* @param channel ��ǰƵ��id
		*/
		virtual void OnVideoPublishStateChanged(AliEnginePublishState oldState, AliEnginePublishState newState, int elapseSinceLastState, const char *channel) {};

		/**
		* @brief ��Ҫ����������ص�
		* @param oldState ֮ǰ������״̬
		* @param newState ��ǰ������״̬
		* @param elapseSinceLastState ״̬���ʱ����
		* @param channel ��ǰƵ��id
		*/
		virtual void OnDualStreamPublishStateChanged(AliEnginePublishState oldState, AliEnginePublishState newState, int elapseSinceLastState, const char *channel) {};

		/**
		* @brief ��Ļ������������ص�
		* @param oldState ֮ǰ������״̬
		* @param newState ��ǰ������״̬
		* @param elapseSinceLastState ״̬���ʱ����
		* @param channel ��ǰƵ��id
		*/
		virtual void OnScreenSharePublishStateChanged(AliEnginePublishState oldState, AliEnginePublishState newState, int elapseSinceLastState, const char *channel) {};


		virtual void OnScreenSharePublishStateChangedWithInfo(AliEnginePublishState oldState, AliEnginePublishState newState, int elapseSinceLastState, const char *channel, AliEngineScreenShareInfo& screenShareInfo) {};


		/**
		* @brief ʹ��RTS URL�������
		* @details Ӧ�õ��� {@link AliEngine::PublishStreamByRtsUrl} ����ʱ���ûص���ʾ�����ɹ�/ʧ��
		* @param result ����������ɹ�����0��ʧ�ܷ��ش�����
		*/
		virtual void OnPublishStreamByRtsUrlResult(const char* rts_url, int result) {};

		/**
		* @brief ʹ��RTS URL�����������
		* @details Ӧ�õ��� {@link AliEngine::PublishStreamByRtsUrl} ����ʱ���ûص���ʾ���������ɹ�/ʧ��
		* @param result ����������ɹ�����0��ʧ�ܷ��ش�����
		*/
		virtual void OnStopPublishStreamByRtsUrlResult(const char* rts_url, int result) {};

		/**
		* @brief ʹ��RTS URL���Ľ���ص�
		* @details Ӧ�õ��� {@link AliEngine::SubscribeStreamByRtsUrl} ����ʱ���ûص���ʾ���ĳɹ�/ʧ��
		* @param uid ���ĵ��û�ID
		* @param result ���Ľ�����ɹ�����0��ʧ�ܷ��ش�����
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
		* @brief ʹ��RTS URLȡ�����Ľ���ص�
		* @details Ӧ�õ��� {@link AliEngine::StopSubscribeStreamByRtsUrl} ����ʱ���ûص���ʾȡ�����ĳɹ�/ʧ��
		* @param uid ȡ�����ĵ��û�ID
		* @param result ȡ�����Ľ�����ɹ�����0��ʧ�ܷ��ش�����
		*/
		virtual void OnStopSubscribeStreamByRtsUrlResult(const char* uid, int result) {};

		/**
		* @brief Ԥ������Ŀ���޻ص�
		* @details Ӧ�õ��� {@link AliEngine::SubscribeStreamByRtsUrl} ����ʱ�������Ԥ�����������ޣ����ֹͣ���Ĳ����������RTS����ֹͣ���ĵĽ������{@link AliEngineEventListener::OnStopSubscribeStreamByRtsUrlResult}�лص���
		* @param uid ���ٶ���RTS�����û�ID
		* @param url ���ٶ���RTS����URL
		*/
		virtual void OnSubscribedRtsStreamBeyondLimit(const char* uid, const char* url) {};

		/**
		* @brief ʹ��RTS UID ��ͣ���Ľ���ص�
		* @details Ӧ�õ��� {@link AliEngine::PauseRtsStreamByRtsUserId} ����ʱ���ûص���ʾ��ͣ���ĳɹ�/ʧ��
		* @param uid ��ͣ���ĵ��û�ID
		* @param result ��ͣ���Ľ�����ɹ�����0��ʧ�ܷ��ش�����
		*/
		virtual void OnPauseRtsStreamResult(const char* uid, int result) {};

		/**
		* @brief ʹ��RTS UID �ָ����Ľ���ص�
		* @details Ӧ�õ��� {@link AliEngine::ResumeRtsStreamByRtsUserId} ����ʱ���ûص���ʾ�ָ����ĳɹ�/ʧ��
		* @param uid �ָ����ĵ��û�ID
		* @param result �ָ����Ľ�����ɹ�����0��ʧ�ܷ��ش�����
		*/
		virtual void OnResumeRtsStreamResult(const char* uid, int result) {};

		/**
		* @brief Զ���û�������Ƶ�������仯�ص�
		* @details �ûص������³����ᱻ����
		* - ��Զ���û���δ�������Ϊ������������Ƶ����Ƶ��
		* - ��Զ���û������������Ϊδ������������Ƶ����Ƶ��
		* - ����ģʽ�£����� {@link AliEngine::SetClientRole} �л�Ϊ������ɫ {@link AliEngineClientRoleInteractive}��ͬʱ����������ʱ���ᴥ���ûص�
		* @param uid userId����App server�����Ψһ��ʾ��
		* @param audioTrack ��Ƶ�����ͣ���� {@link AliEngineAudioTrack}
		* @param videoTrack ��Ƶ�����ͣ���� {@link AliEngineVideoTrack}
		* @note �ûص�����ͨ��ģʽ�û��ͻ���ģʽ�µ�������ɫ�Żᴥ��
		*/
		virtual void OnRemoteTrackAvailableNotify(const char *uid,
			AliEngineAudioTrack audioTrack,
			AliEngineVideoTrack videoTrack);
		/**
		* @brief Զ���û��豸id�ص�
		* @details һ���������ƽ��룬�ûص��ػᴥ��
		* - ��Զ���û�sdk�汾�ϵͣ���͸���豸idʱ����ص�ħ��
		*/
		virtual void OnRemoteDeviceIdNotify(const char *uid, const char *deviceId) {}

		/**
		* @brief ��Ƶ�����������ص�
		* @param uid userId����App server�����Ψһ��ʾ��
		* @param oldState ֮ǰ�Ķ���״̬����� {@link AliRTCSdk::AliEngineSubscribeState}
		* @param newState ��ǰ�Ķ���״̬����� {@link AliRTCSdk::AliEngineSubscribeState}
		* @param elapseSinceLastState ����״̬���ʱ����(����)
		* @param channel ��ǰƵ��id
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
		* @brief ����������������ص�
		* @param uid userId����App server�����Ψһ��ʾ��
		* @param oldState ֮ǰ�Ķ���״̬����� {@link AliRTCSdk::AliEngineSubscribeState}
		* @param newState ��ǰ�Ķ���״̬����� {@link AliRTCSdk::AliEngineSubscribeState}
		* @param elapseSinceLastState ����״̬���ʱ����(����)
		* @param channel ��ǰƵ��id
		*/
		virtual void OnVideoSubscribeStateChanged(const char *uid,
			AliEngineSubscribeState oldState,
			AliEngineSubscribeState newState,
			int elapseSinceLastState,
			const char *channel) {};

		/**
		* @brief ��Ļ�����������������ص�
		* @param uid userId����App server�����Ψһ��ʾ��
		* @param oldState ֮ǰ�Ķ���״̬����� {@link AliRTCSdk::AliEngineSubscribeState}
		* @param newState ��ǰ�Ķ���״̬����� {@link AliRTCSdk::AliEngineSubscribeState}
		* @param elapseSinceLastState ����״̬���ʱ����(����)
		* @param channel ��ǰƵ��id
		*/
		virtual void OnScreenShareSubscribeStateChanged(const char *uid,
			AliEngineSubscribeState oldState,
			AliEngineSubscribeState newState,
			int elapseSinceLastState,
			const char *channel) {};

		/**
		* @brief ��С�����������ص�
		* @param uid userId����App server�����Ψһ��ʾ��
		* @param oldStreamType ֮ǰ�Ķ��ĵĴ�С�����ͣ���� {@link AliRTCSdk::AliEngineVideoStreamType}
		* @param newStreamType ��ǰ�Ķ��ĵĴ�С�����ͣ���� {@link AliRTCSdk::AliEngineVideoStreamType}
		* @param elapseSinceLastState ��С�����ͱ��ʱ����(����)
		* @param channel ��ǰƵ��id
		*/
		virtual void OnSubscribeStreamTypeChanged(const char *uid,
			AliEngineVideoStreamType oldStreamType,
			AliEngineVideoStreamType newStreamType,
			int elapseSinceLastState,
			const char *channel) {};

		/**
		* @brief ���������仯ʱ��������Ϣ
		* @param uid  �������������仯���û�uid
		* @param upQuality ����������������� {@link AliRTCSdk::AliEngineNetworkQuality}
		* @param downQuality ����������������� {@link AliRTCSdk::AliEngineNetworkQuality}
		* @note ���������������仯ʱ������uidΪ��ʱ�����û��Լ����������������仯
		*/
		virtual void OnNetworkQualityChanged(const char *uid,
			AliEngineNetworkQuality upQuality,
			AliEngineNetworkQuality downQuality) {}

		/**
		* @brief �Ƿ��ƾ�̬ͼƬ����ͨ�� {@link AliEngine::SetPublishImage}���������ͼƬ����������״̬�������»ص���
		* @param trackType ��Ƶ������
		* @param isStaticFrame
		* - true: ����������ʼ�ƾ�̬ͼƬ
		* - false: ��������ָ����������ɼ�����
		*/
		virtual void OnPublishStaticVideoFrame(AliEngineVideoTrack trackType, bool isStaticFrame) {}

		/**
		* @brief ���������߳�Ƶ������Ϣ
		* @param code onBye���ͣ���� {@link AliEngineOnByeType}
		*/
		virtual void OnBye(int code) {}

		/**
		* @brief ���engine����warning��ͨ�������Ϣ֪ͨapp
		* @param warn ��������
		* @param msg ������Ϣ
		*/
		virtual void OnOccurWarning(int warn, const char *msg) {}

		/**
		* @brief ���engine����error��ͨ������ص�֪ͨapp
		* @param error  �������ͣ��ο� {@link AliEngineErrorCode}
		* @param msg ��������
		*/
		virtual void OnOccurError(int error, const char *msg) {}

		/**
		* @brief ��ǰ�豸���ܲ���
		*/
		virtual void OnPerformanceLow() {}

		/**
		* @brief ��ǰ�豸���ָܻ�
		*/
		virtual void OnPerformanceRecovery() {}

		/**
		* @brief Զ���û��ĵ�һ֡��Ƶ֡��ʾʱ���������Ϣ
		* @param uid User ID����App server�����Ψһ��ʾ��
		* @param videoTrack ��Ļ��������������ο� {@link AliEngineVideoTrack}
		* @param width ��Ƶ���
		* @param height ��Ƶ�߶�
		* @param elapsed �����û�����Ƶ��ֱ���ûص��������ӳ��ܺ�ʱ�����룩
		* @note �ýӿ�����Զ���û��ĵ�һ֡��Ƶ֡��ʾʱ�Ļص�
		*/
		virtual void OnFirstRemoteVideoFrameDrawn(const char *uid,
			AliEngineVideoTrack videoTrack,
			int width,
			int height,
			int elapsed) {}

		/**
		* @brief Ԥ����ʼ��ʾ��һ֡��Ƶ֡ʱ���������Ϣ
		* @param width ����Ԥ����Ƶ���
		* @param height ����Ԥ����Ƶ�߶�
		* @param elapsed �ӱ����û�����Ƶ��ֱ���ûص��������ӳ��ܺ�ʱ�����룩
		* @note �ýӿ�����Ԥ����ʼ��ʾ��һ֡��Ƶ֡ʱ�Ļص�
		*/
		virtual void OnFirstLocalVideoFrameDrawn(int width, int height, int elapsed) {}

		/**
		* @brief ��Ƶ�װ����ͻص�
		* @details ���׸���Ƶ���ݰ����ͳ�ȥʱ�����˻ص�
		* @param timeCost ���ͺ�ʱ������Ὺʼ����Ƶ�װ����ͳ�ȥ�ĺ�ʱ
		*/
		virtual void OnFirstAudioPacketSend(int timeCost) {};


		virtual void OnFirstAudioPacketSend(AliEngineAudioTrack audioTrack, int timeCost) {};

		/**
		* @brief ��Ƶ�װ����ջص�
		* @details �ڽ��յ�Զ���׸���Ƶ���ݰ�ʱ�����˻ص�
		* @param uid Զ���û�ID����App server�����Ψһ��ʶ��
		* @param timeCost ���պ�ʱ������Ὺʼ����Ƶ�װ����յ��ĺ�ʱ
		*/
		virtual void OnFirstAudioPacketReceived(const char* uid, int timeCost) {}


		virtual void OnFirstAudioPacketReceived(const char* uid, AliEngineAudioTrack audioTrack, int timeCost) {}

		/**
		* @brief �ѽ���Զ����Ƶ��֡�ص�
		* @param uid Զ���û�ID����App server�����Ψһ��ʶ��
		* @param elapsed �ӱ����û�����Ƶ��ֱ���ûص��������ӳ�, ��λΪ����
		*/
		virtual void OnFirstRemoteAudioDecoded(const char* uid, int elapsed) {}


		virtual void OnFirstRemoteAudioDecoded(const char* uid, AliEngineAudioTrack audioTrack, int elapsed) {}

		/**
		* @brief ��Ƶ�װ����ͻص�
		* @param videoTrack ������Ƶtrack���ο� {@link AliEngineVideoTrack}
		* @param timeCost ��ʱ�����룩
		* @note �ýӿ�������Ƶ�װ����͵Ļص�
		*/
		virtual void OnFirstVideoPacketSend(AliEngineVideoTrack videoTrack, int timeCost) {};

		/**
		* @brief ��Ƶ�װ����ջص�
		* @param uid User ID����App server�����Ψһ��ʾ��
		* @param videoTrack ������Ƶtrack���ο� {@link AliEngineVideoTrack}
		* @param timeCost ��ʱ�����룩
		* @note �ýӿ�������Ƶ�װ����յĻص�
		*/
		virtual void OnFirstVideoPacketReceived(const char* uid,
			AliEngineVideoTrack videoTrack,
			int timeCost) {}

		/**
		* @brief �յ�Զ���û���Ƶ��֡�Ļص�
		* @param uid User ID����App server�����Ψһ��ʾ��
		* @param videoTrack ������Ƶtrack���ο� {@link AliEngineVideoTrack}
		* @param timeCost ��ʱ�����룩
		* @note �ýӿ������յ�Զ���û���Ƶ��֡�Ļص�
		*/
		virtual void OnFirstVideoFrameReceived(const char* uid,
			AliEngineVideoTrack videoTrack,
			int timeCost) {};

		/**
		* @brief ����Ͽ�
		*/
		virtual void OnConnectionLost() {}

		/**
		* @brief ��ʼ����
		*/
		virtual void OnTryToReconnect() {}

		/**
		* @brief �����ɹ�
		*/
		virtual void OnConnectionRecovery() {}

		/**
		* @brief ��������״̬�ı�Ļص�
		* @param status ��ǰ��������״̬���ο� {@link AliRTCSdk::AliEngineConnectionStatus}
		* @param reason ��������״̬�ı�ԭ�򣬲ο� {@link AliRTCSdk::AliEngineConnectionStatusChangeReason}
		*/
		virtual void OnConnectionStatusChange(int status, int reason) {};

		/**
		* @brief Զ���û�����/ȡ�������ص�
		* @param uid Զ���û�ID
		* @param isMute ���û��Ƿ���
		* - true: ����
		* - false: ȡ������
		*/
		virtual void OnUserAudioMuted(const char* uid, bool isMute) {}

		/**
		* @brief �Զ��û�������Ƶ��֡���ݷ���֪ͨ
		* @param uid ִ��muteVideo���û�
		* @param isMute
		* - true: ������֡
		* - false: ��������
		* @note �ýӿ����ڶԶ��û�������Ƶ��֡����ʱ�Ļص�
		*/
		virtual void OnUserVideoMuted(const char* uid, bool isMute) {}

		/**
		* @brief �Զ��û��ر�������ɼ�����֪ͨ
		* @param uid ִ��EnableLocalVideo���û�
		* @param isEnable
		* - true: ��������ɼ�
		* - false: �ر�������ɼ�
		* @note �ýӿ����ڶԶ��û��ر�������ɼ�ʱ�Ļص�
		*/
		virtual void OnUserVideoEnabled(const char* uid, bool isEnable) {}

		/**
		* @brief �û���Ƶ���ж�֪ͨ��һ���û���绰����Ƶ����ռ������
		* @param uid ��Ƶ���жϵ��û�ID
		*/
		virtual void OnUserAudioInterruptedBegin(const char* uid) {}

		/**
		* @brief �û���Ƶ�жϽ���֪ͨ����Ӧ {@link OnUserAudioInterruptedBegin}��
		* @param uid ��Ƶ�жϽ������û�ID
		*/
		virtual void OnUserAudioInterruptedEnded(const char* uid) {}

		/**
		* @brief Զ���û����ಥ�ſ�ʼ�ص�
		* @param uid Զ���û�ID����App server�����Ψһ��ʶ��
		*/
		virtual void OnRemoteAudioAccompanyStarted(const char* uid) {}

		/**
		* @brief Զ���û����ಥ�Ž����ص�
		* @param uid Զ���û�ID����App server�����Ψһ��ʶ��
		*/
		virtual void OnRemoteAudioAccompanyFinished(const char* uid) {}

		/**
		* @brief Զ���û�Ӧ���˵���̨
		* @param uid �û�
		*/
		virtual void OnUserWillResignActive(const char* uid) {}

		/**
		* @brief Զ���û�Ӧ�÷���ǰ̨
		* @param uid �û�
		*/
		virtual void OnUserWillBecomeActive(const char* uid) {}

		/**
		* @brief ���û���ɫ�����仯ʱ֪ͨ
		* @param oldRole �仯ǰ��ɫ���ͣ��ο�{@link AliEngineClientRole}
		* @param newRole �仯���ɫ���ͣ��ο�{@link AliEngineClientRole}
		* @note ����{@link setClientRole}�����л���ɫ�ɹ�ʱ�����˻ص�
		*/
		virtual void OnUpdateRoleNotify(const AliEngineClientRole oldRole,
			const AliEngineClientRole newRole) {}

		/**
		* @brief ���ĵ���Ƶ�����ص�������callidΪ"0"��ʾ��������������"1"��ʾԶ�˻���������������ʾԶ���û�����
		* @param volumeInfo ˵����������Ϣ
		* @param volumeInfoCount �ص���˵���˵ĸ���
		* @param totalVolume �����������������Χ[0,255]���ڱ����û��Ļص��У�totalVolume;Ϊ�����û����������������Զ���û��Ļص��У�totalVolume; Ϊ����˵���߻������������
		*/
		virtual void OnAudioVolumeCallback(const AliEngineUserVolumeInfo* volumeInfo, int volumeInfoCount, int totalVolume) {}

		/**
		* @brief ���ĵĵ�ǰ˵���ˣ���ǰʱ���˵�������������û�uid��������ص�uidΪ0����Ĭ��Ϊ�����û�
		* @param uid ˵���˵��û�ID
		*/
		virtual void OnActiveSpeaker(const char *uid) {}

		/**
		* @brief ���ذ��ಥ��״̬�ص�
		* @details �ûص��ڰ��ಥ��״̬�����ı�ʱ��������֪ͨ��ǰ�Ĳ���״̬�ʹ�����
		* @param type ��ǰ����״̬������ο�{@link AliEngineAudioPlayingType}
		* @param errorCode ���Ŵ����룬����ο�{@link AliEngineAudioPlayingErrorCode}
		*/
		virtual void OnAudioAccompanyStateChanged(AliEngineAudioAccompanyStateCode playState,
			AliEngineAudioAccompanyErrorCode errorCode) {}
		/**
		* @brief ��Ƶ�ļ���Ϣ�ص�
		* @details �ûص��ڵ���{@link AliEngine::GetAudioFileInfo}�󴥷������ص�ǰ��Ƶ�ļ���Ϣ�ʹ�����
		* @param info ��Ƶ�ļ���Ϣ������ο� {@link AliRtcAudioFileInfo}
		* @param errorCode �����룬����ο� {@link AliRtcAudioAccompanyErrorCode}
		*/
		virtual void OnAudioFileInfo(AliEngineAudioFileInfo info,
			AliEngineAudioAccompanyErrorCode errorCode) {}

		/**
		* @brief ������Ч���Ž����ص�
		* @param soundId �û�������Ч�ļ������ΨһID
		*/
		virtual void OnAudioEffectFinished(int soundId) {}

		/**
		* @brief ��������̽��ص�
		* @param networkQuality �������� {@link AliEngineNetworkQuality}
		* @note ������ {@link AliEngine::StartLastmileDetect} 3s��ᴥ���ûص�
		*/
		virtual void OnLastmileDetectResultWithQuality(AliEngineNetworkQuality networkQuality) {}

		/**
		* @brief ��������̽�����Ļص�
		* @param networkQuality ����̽���� {@link AliEngineNetworkProbeResult}
		* @note ������ {@link AliEngine::StartLastmileDetect} 30s��ᴥ���ûص�
		*/
		virtual void OnLastmileDetectResultWithBandWidth(int code, AliRTCSdk::AliEngineNetworkProbeResult networkQuality) {}

		/**
		* @brief ��Ƶ�ɼ��豸���Իص�
		* @param level ��Ƶ�ɼ��豸����ֵ
		*/
		virtual void OnAudioDeviceRecordLevel(int level) {};

		/**
		* @brief ��Ƶ�����豸���Իص�
		* @param level ��Ƶ�ɼ��豸����ֵ
		*/
		virtual void OnAudioDevicePlayoutLevel(int level) {};

		/**
		* @brief ��Ƶ�����豸���Խ���(��Ƶ�ļ��������)
		*/
		virtual void OnAudioDevicePlayoutEnd() {};

		/**
		* @brief �ļ�¼�ƻص��¼�
		* @param event ¼���¼���0��¼�ƿ�ʼ��1��¼�ƽ�����2�����ļ�ʧ�ܣ�3��д�ļ�ʧ��
		* @param filePath ¼���ļ�·��
		* @note �ýӿ������ļ�¼��ʱ���¼��ص�
		*/
		virtual void OnMediaRecordEvent(int event, const char* filePath) {}

		/**
		* @brief ��ǰ�Ựͳ����Ϣ�ص�
		* @param stats �Ựͳ����Ϣ
		* @note SDKÿ���봥��һ�δ�ͳ����Ϣ�ص�
		*/
		virtual void OnStats(const AliEngineStats& stats) {}

		/**
		* @brief ������Ƶͳ����Ϣ
		* @param localVideoStats ������Ƶͳ����Ϣ
		* @note SDKÿ���봥��һ�δ�ͳ����Ϣ�ص�
		*/
		virtual void OnLocalVideoStats(const AliEngineLocalVideoStats& localVideoStats) {}

		/**
		* @brief Զ����Ƶͳ����Ϣ
		* @param remoteVideoStats Զ����Ƶͳ����Ϣ
		* @note SDKÿ���봥��һ�δ�ͳ����Ϣ�ص�
		*/
		virtual void OnRemoteVideoStats(const AliEngineRemoteVideoStats& remoteVideoStats) {}

		/**
		* @brief ������Ƶͳ����Ϣ
		* @param localAudioStats ������Ƶͳ����Ϣ
		* @note SDKÿ���봥��һ�δ�ͳ����Ϣ�ص�
		*/
		virtual void OnLocalAudioStats(const AliEngineLocalAudioStats& localAudioStats) {}

		/**
		* @brief Զ����Ƶͳ����Ϣ
		* @param remoteAudioStats Զ����Ƶͳ����Ϣ
		* @note SDKÿ���봥��һ�δ�ͳ����Ϣ�ص�
		*/
		virtual void OnRemoteAudioStats(const AliEngineRemoteAudioStats& remoteAudioStats) {}

		/**
		* @brief ����ʱ����ֱ��ģʽstart�ص�
		* @param result �Ƿ�start�ɹ�
		* @note �ûص����ڵ���ʱ����ģʽ�ҽ�ɫΪ����ʱ������ {@link AliEngine::StartLiveStreaming} �Ż�ص�
		* @deprecated
		*/
		virtual void OnStartLiveStreamingResult(int result) {}

		/**
		* @brief �յ�ý����չ��Ϣ�ص�
		* @param uid �����û�userId
		* @param message ��չ��Ϣ����
		* @param size ��չ��Ϣ����
		* @note ��һ��ͨ�� {@link AliEngine::SendMediaExtensionMsg} ������Ϣ��������ͨ���ûص���������
		*/
		virtual void OnMediaExtensionMsgReceived(const char* uid, const uint8_t payloadType, const int8_t * message, uint32_t size) {};

		/**
		* @brief ��Ƶ�豸״̬���
		* @param deviceInfo  ����豸��Ϣ
		* @param deviceType  ����豸����
		* @param deviceState ����豸״̬
		*/
		virtual void OnAudioDeviceStateChanged(const AliEngineDeviceInfo& deviceInfo, AliEngineExternalDeviceType deviceType, AliEngineExternalDeviceState deviceState) {};

		/**
		* @brief ��Ƶ����״̬���
		* @param audioFocus  ��Ƶ��������
		*/
		virtual void OnAudioFocusChanged(AliEngineAudioFocusType audioFocus) {};

		/**
		* @brief ��Ƶ�豸״̬���
		* @param deviceInfo  ����豸��Ϣ
		* @param deviceType  ����豸����
		* @param deviceState ����豸״̬
		*/
		virtual void OnVideoDeviceStateChanged(const AliEngineDeviceInfo& deviceInfo, AliEngineExternalDeviceType deviceType, AliEngineExternalDeviceState deviceState) {};

		/**
		* @brief ������Ϣͨ��(������Ϣ)
		* @param messageInfo ��Ϣ����
		* @note �ýӿڽ��յ�������Ϣ��ʹ�� {@link AliEngine::SendDownlinkMessageResponse} ���ͷ�����Ϣ
		* @note �ѷ���ʹ��
		* @deprecated
		*/
		virtual void OnDownlinkMessageNotify(const AliEngineMessage &messageInfo) {};

		/**
		* @brief ������Ϣ���ؽ��(������Ϣ)
		* @param resultInfo ���ͽ��
		* @note ʹ�� {@link AliEngine::SendUplinkMessage} ������Ϣ�󣬻ᴥ���ýӿڽ���������Ϣ����
		* @note �ѷ���ʹ��
		* @deprecated
		*/
		virtual void OnUplinkMessageResponse(const AliEngineMessageResponse &resultInfo) {};


		/**
		* @brief �ֱ��ʱ仯�ص�
		* @param uid �û�id
		* @param track �仯��Ƶtrack
		* @param width ��ǰ��Ƶ��
		* @param height ��ǰ��Ƶ��
		* @note �ѷ���ʹ��
		*/
		virtual void OnVideoResolutionChanged(const char* uid,
			AliEngineVideoTrack track,
			int width,
			int height) {};

		/**
		* @brief ��ͼ�ص�
		* @param userId �û�id
		* @param videoTrack ��ͼ��Ƶtrack���ο� {@link AliEngineVideoTrack}
		* @param buffer �ɹ����ؽ�ͼ���ݣ�ʧ��ΪNULL��buffer���ݸ�ʽRGBA
		* @param width ��ͼ���
		* @param height ��ͼ�߶�
		* @param success ��ͼ�Ƿ�ɹ�
		* @note �ýӿ����ڽ�ͼ�ص�
		*/
		virtual void OnSnapshotComplete(const char* userId, AliEngineVideoTrack videoTrack, void* buffer, int width, int height, bool success) {}

		/**
		* @brief ��·����״̬�ı�ص�
		* @param streamUrl ����ַ
		* @param state ����״̬, �ο� {@link AliEngineLiveTranscodingState}
		* @param errCode ������, �ο� {@link AliEngineLiveTranscodingErrorCode}
		* @note �ýӿ�������·����״̬�ı�Ļص�
		*/
		virtual void OnPublishLiveStreamStateChanged(const char* streamUrl, AliEngineLiveTranscodingState state, AliEngineLiveTranscodingErrorCode errCode) {};

		/**
		* @brief ��·����״̬�ı�ص�
		* @param taskId ����id
		* @param state ����״̬, �ο� {@link AliEngineLiveTranscodingState}
		* @param errCode ������, �ο� {@link AliEngineLiveTranscodingErrorCode}
		* @note �ýӿ�������·����״̬�ı�Ļص���ֻ���û�δ����streamUrlʱ�Ż�ص��ýӿ�
		*/
		virtual void OnPublishLiveStreamStateChangedWithTaskId(const char* taskId, AliEngineLiveTranscodingState state, AliEngineLiveTranscodingErrorCode errCode) {};

		/**
		* @brief ��·����״̬�ı�ص�
		* @param streamUrl  ����ַ
		* @param state ����״̬, �ο� {@link AliEngineTrascodingPublishTaskStatus}
		* @note �ýӿ�������·����״̬�ı�Ļص�
		*/
		virtual void OnPublishTaskStateChanged(const char* streamUrl, AliEngineTrascodingPublishTaskStatus state) {};

		/**
		* @brief ��·����״̬�ı�ص�
		* @param taskId ����id
		* @param state ����״̬, �ο� {@link AliEngineTrascodingPublishTaskStatus}
		* @note �ýӿ�������·����״̬�ı�Ļص���ֻ���û�δ����streamUrlʱ�Ż�ص��ýӿ�
		*/
		virtual void OnPublishTaskStateChangedWithTaskId(const char* taskId, AliEngineTrascodingPublishTaskStatus state) {};

		/**
		* @brief ��Ƶ��ת��״̬�仯֪ͨ
		* @param state ��ǰ����״̬���ο� {@link AliEngineChannelRelayState}
		* @param code ��ǰ�����룬�ο� {@link AliEngineChannelRelayErrorCode}
		* @param msg ״̬������Ϣ
		*/
		virtual void OnChannelRelayStateChanged(int state, int code, const char* msg) {};

		/**
		* @brief ��Ƶ��ת���¼�֪ͨ
		* @param state ״̬�룬�ο� {@link AliEngineChannelRelayEvent}
		*/
		virtual void OnChannelRelayEvent(int state) {};

		/**
		* @brief �û�remote video change֪ͨ
		* @param uid ��Ҫ��֪ͨ���û�
		* @param track �仯��Ƶtrack
		* @param state ��Ƶ״̬������
		* @param reason ����״̬�仯��ԭ��
		*/
		virtual void OnRemoteVideoChanged(const char* uid, AliEngineVideoTrack trackType, const AliEngineVideoState state, const AliEngineVideoReason reason) {};

		/**
		* @brief �û�AliEngineAuthInfo authInfo��������֪ͨ,30������
		*/
		virtual void OnAuthInfoWillExpire() {};

		/**
		* @brief �û�������Ҫ��Ȩ�Ľӿڣ�����˷�����Ϣ����
		*/
		virtual void OnAuthInfoExpired() {};

		/**
		* @brief Qos���������仯֪ͨ
		* @param trackType �仯��Ƶtrack
		* @param paramter qos�����ṹ��
		*/
		virtual void OnRequestVideoExternalEncoderParameter(AliEngineVideoTrack trackType, const AliEngineVideoExternalEncoderParameter& paramter) {};
		/**
		* @brief Qos����֡���ͷ����仯֪ͨ
		* @param trackType �仯��Ƶtrack
		* @param frame_type ����ο�֡����
		*/
		virtual void OnRequestVideoExternalEncoderFrame(AliEngineVideoTrack trackType, AliEngineVideoEncodedFrameType frame_type) {};
		/**
		* @brief API ������ִ�лص���
		* @param error ���÷�������ʧ��ʱ SDK ���صĴ����롣����÷������óɹ���SDK ������ 0��ʧ�ܣ���0.
		* @param api SDK ִ�е� API.
		* @param result SDK ���� API �ĵ��ý��.
		*/
		virtual void OnCalledApiExecuted(int error, const char *api, const char *result) {};

		/**
		* @brief ����ʹ�õı�������Ϣ�ص�
		* @param localAudioStats ������Ƶͳ����Ϣ
		* @note ������ʼ��֪ͨ�û�
		*/
		virtual void OnVideoEncoderNotify(const AliEngineEncoderNotifyInfo& encoderNotifyInfo) {};

		/**
		* @brief ʹ�õĽ�������Ϣ�ص�
		* @param decoderNotifyInfo �����������Ϣ
		* @note ������ʼ��֪ͨ�û�
		*/
		virtual void OnVideoDecoderNotify(const AliEngineDecoderNotifyInfo& decoderNotifyInfo) {};

		/**
		* @brief �����豸�쳣�ص�
		* @param deviceType �豸����, �ο�{@link AliEngineLocalDeviceType}
		* @param exceptionType �豸�쳣����, �ο�{@link AliEngineLocalDeviceExceptionType}
		* @param msg �쳣ʱЯ������Ϣ
		* @note �˻ص���ʶ���ڲ��޷��ָ����豸�쳣���յ��˻ص�ʱ�û���Ҫ����豸�Ƿ����
		*/
		virtual void OnLocalDeviceException(AliEngineLocalDeviceType deviceType, AliEngineLocalDeviceExceptionType exceptionType, const char* msg) {};

		/**
		* @brief ������Ƶ�豸״̬�ص�
		* @param state  ��ǰ״̬��AliEngineLocalAudioStateType����
		*/
		virtual void OnLocalAudioStateChange(AliEngineLocalAudioStateType state, const char* msg) {};

		/**
		* @brief ������Ƶ�豸״̬�ص�
		* @param state  ��ǰ״̬��AliRtcLocalVideoStateType����
		*/
		virtual void onLocalVideoStateChanged(AliEngineLocalVideoStateType state, const char* msg) {};

		/**
		* @brief ���������Ϣ
		* @param uid �û�
		* @param msg ��Ϣ
		* @param
		*/
		virtual void OnDataChannelMessage(const char* uid, const AliEngineDataChannelMsg& msg) {}

		/**
		* @brief ��Ƶ�ӳ���Ϣ
		* @param id ���id
		* @param questionEndTime ���ʽ���ʱ��
		* @param answerStartTime �ش�ʼʱ��
		* @param
		*/
		virtual void OnAudioDelayInfo(int scentenceId, int64_t questionEndTime, int64_t answerStartTime) {}

		void SetLogHandle(HWND logListHwnd, CARTCExampleDlg * dlg);

		protected:
			HWND	mLogHandle;
			CARTCExampleDlg * mDlg;
	};


