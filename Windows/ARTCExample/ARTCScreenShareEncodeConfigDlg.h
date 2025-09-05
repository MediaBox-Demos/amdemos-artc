#pragma once
#include "afxwin.h"


// ARTCScreenShareEncodeConfigDlg dialog

class ARTCScreenShareEncodeConfigDlg : public CDialogEx
{
	DECLARE_DYNAMIC(ARTCScreenShareEncodeConfigDlg)

public:
	ARTCScreenShareEncodeConfigDlg(CWnd* pParent = NULL);   // standard constructor
	virtual ~ARTCScreenShareEncodeConfigDlg();
	virtual BOOL OnInitDialog();
// Dialog Data
#ifdef AFX_DESIGN_TIME
	enum { IDD = IDD_DIALOG_SCREEN_SHARE_ENCODER };
#endif

protected:
	virtual void DoDataExchange(CDataExchange* pDX);    // DDX/DDV support

	DECLARE_MESSAGE_MAP()
public:
	

	CEdit mScreenShareWidth;
	CEdit mScreenShareHeight;
	CEdit mScreenShareFps;
	CEdit mScreenShareBitRate;

	int mWidth;
	int mHeight;
	int mFps;
	int mBitRate;
	afx_msg void OnBnClickedOk();
};
