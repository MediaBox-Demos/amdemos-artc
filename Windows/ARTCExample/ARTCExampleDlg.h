
// ARTCExampleDlg.h : header file
//

#pragma once
#include "include/rtc/engine_interface.h"
#include "ARTCEventListernerImpl.h"
#include "afxwin.h"
#include "ARTCLoginDlg.h"


// CARTCExampleDlg dialog
class CARTCExampleDlg : public CDialogEx
{
// Construction
public:
	CARTCExampleDlg(CWnd* pParent = NULL);	// standard constructor

// Dialog Data
#ifdef AFX_DESIGN_TIME
	enum { IDD = IDD_ARTCEXAMPLE_DIALOG };
#endif

	protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV support


// Implementation
protected:
	HICON m_hIcon;

	// Generated message map functions
	virtual BOOL OnInitDialog();
	afx_msg void OnSysCommand(UINT nID, LPARAM lParam);
	afx_msg void OnPaint();
	afx_msg HCURSOR OnQueryDragIcon();
	DECLARE_MESSAGE_MAP()
public:
	afx_msg void OnBnClickedOk();

protected:
	std::string					mUserId;
	std::string					mChannelId;
	std::string					mUserName;
	AliEngineChannelProfile		mChannelProfile;
	AliEngineClientRole			mClientRole;
	ARTCEventListernerImpl		mEngineEvent;
	ARTCLoginDlg				mLoginDlg;
	AliRTCSdk::AliEngine	*	mEngine{nullptr};

	int InitAliEngine();
	void CleanupAliEngine();

public:
	afx_msg void OnClose();
	CStatic mLocalView;
	CStatic mRemoteView;
	CComboBox mDesktopListBox;
	CComboBox mWindowListBox;
	CButton mPushStreamCheck;
	CButton * mCheckButtoDesktop;
	CButton * mCheckButtoWin;
	CButton * mCheckButtonRegion;
	CEdit mPosX;
	CEdit mPosY;
	CEdit mPosWidth;
	CEdit mPosHeight;
	bool  mStartScreenShare{false};
	AliEngineScreenSourceList * mWindowList{nullptr};
	AliEngineScreenSourceList * mDeskTopList{nullptr};
	void ListAllDesktopAndWindow();

	afx_msg void OnBnClickedButton3();

	afx_msg void OnBnClickedRadioRegion();
	afx_msg void OnBnClickedButtonStart();
	afx_msg void OnBnClickedButtonStop();

	void HandleTrackChangeEvent(const char *uid,
		AliEngineAudioTrack audioTrack,
		AliEngineVideoTrack videoTrack);
	afx_msg void OnBnClickedButton1();
};
