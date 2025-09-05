// ARTCLoginDlg.cpp : implementation file
//

#include "stdafx.h"
#include "ARTCExample.h"
#include "ARTCLoginDlg.h"
#include "afxdialogex.h"


#define MAX_CHANNEL_ID_SIZE		( 128 )
#define MAX_USER_ID_SIZE		( 128 )

// ARTCLoginDlg dialog

IMPLEMENT_DYNAMIC(ARTCLoginDlg, CDialogEx)

ARTCLoginDlg::ARTCLoginDlg(CWnd* pParent /*=NULL*/)
	: CDialogEx(IDD_DIALOG_LOGIN, pParent)
{

}

ARTCLoginDlg::~ARTCLoginDlg()
{
}

void ARTCLoginDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialogEx::DoDataExchange(pDX);
	DDX_Control(pDX, IDC_EDIT1, mEditChannelID);
	DDX_Control(pDX, IDC_EDIT2, mEditUserID);
}


BEGIN_MESSAGE_MAP(ARTCLoginDlg, CDialogEx)
	ON_BN_CLICKED(IDOK, &ARTCLoginDlg::OnBnClickedOk)
END_MESSAGE_MAP()


// ARTCLoginDlg message handlers

BOOL ARTCLoginDlg::OnInitDialog() {
	CDialogEx::OnInitDialog();
	this->SetWindowText(L"ARTC��¼Example");
	return TRUE;
}

void ARTCLoginDlg::OnBnClickedOk()
{
	TCHAR channelID[MAX_CHANNEL_ID_SIZE];
	TCHAR userID[MAX_USER_ID_SIZE];
	// TODO: Add your control notification handler code here
	if (mEditChannelID.GetWindowText(channelID, MAX_CHANNEL_ID_SIZE) <= 0 || mEditUserID.GetWindowText(userID, MAX_USER_ID_SIZE) <= 0) {
		this->MessageBox(L"������Ƶ��ID���û�ID��", L"��ʾ", MB_ICONERROR);
		return;
	}

	mEditChannelID.GetWindowText(mChannelID);
	mEditUserID.GetWindowText(mUserID);

	if (mChannelID.GetLength() > 64 || mUserID.GetLength() > 64) {
		this->MessageBox(L"ID���ȳ������ƣ��û�ID��Ƶ��ID��������Ϊ���64��", L"��ʾ", MB_ICONERROR);
		return;
	}

	CDialogEx::OnOK();
}
