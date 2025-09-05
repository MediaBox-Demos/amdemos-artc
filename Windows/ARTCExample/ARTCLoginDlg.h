#pragma once
#include "afxwin.h"


// ARTCLoginDlg dialog

class ARTCLoginDlg : public CDialogEx
{
	DECLARE_DYNAMIC(ARTCLoginDlg)

public:
	ARTCLoginDlg(CWnd* pParent = NULL);   // standard constructor
	virtual ~ARTCLoginDlg();
	virtual BOOL OnInitDialog();
// Dialog Data
#ifdef AFX_DESIGN_TIME
	enum { IDD = IDD_DIALOG_LOGIN };
#endif

protected:
	virtual void DoDataExchange(CDataExchange* pDX);    // DDX/DDV support

	DECLARE_MESSAGE_MAP()
public:
	CEdit mEditChannelID;
	CEdit mEditUserID;
	CString mUserID;
	CString mChannelID;
	afx_msg void OnBnClickedOk();
};
