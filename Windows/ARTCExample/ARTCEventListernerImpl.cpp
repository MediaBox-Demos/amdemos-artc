#include "stdafx.h"
#include "ARTCEventListernerImpl.h"
#include "ARTCExampleDlg.h"

ARTCEventListernerImpl::ARTCEventListernerImpl()
{
}


ARTCEventListernerImpl::~ARTCEventListernerImpl()
{
}


void ARTCEventListernerImpl::SetLogHandle(HWND logListHwnd, CARTCExampleDlg * dlg) {
	mLogHandle = logListHwnd;
	mDlg = dlg;
}

void ARTCEventListernerImpl::OnRemoteTrackAvailableNotify(const char *uid,
	AliEngineAudioTrack audioTrack,
	AliEngineVideoTrack videoTrack) {

	char logBuffer[MAX_LOG_STRING_SIZE];
	snprintf(logBuffer, USE_LOG_STRING_SIZE, "user %s push video=%d audio=%d", uid, videoTrack, audioTrack);
	SendMessageA(this->mLogHandle, LB_ADDSTRING, WPARAM(), (LPARAM)logBuffer);

	mDlg->HandleTrackChangeEvent(uid, audioTrack, videoTrack);

}