#pragma once
#include "afxwin.h"


// ARTCSelectDlg dialog

class ARTCSelectDlg : public CDialogEx
{
	DECLARE_DYNAMIC(ARTCSelectDlg)

public:
	ARTCSelectDlg(CWnd* pParent = NULL);   // standard constructor
	virtual ~ARTCSelectDlg();

// Dialog Data
#ifdef AFX_DESIGN_TIME
	enum { IDD = IDD_DIALOG_SELECT };
#endif

protected:
	virtual void DoDataExchange(CDataExchange* pDX);    // DDX/DDV support
	BOOL  OnInitDialog();
	DECLARE_MESSAGE_MAP()
public:
	CListBox m_ListFastStart;
	CListBox m_ListBasic;
	CListBox m_ListAdvanced;
	int		 m_SelectItemIndex{-1};
	afx_msg void OnBnClickedOk();
	afx_msg void OnLbnSelchangeListFastStart();
	afx_msg void OnLbnSelchangeListBasic();
	afx_msg void OnLbnSelchangeListAdvanced();
};
