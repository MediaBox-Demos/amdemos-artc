// ARTCScreenShareEncodeConfigDlg.cpp : implementation file
//

#include "stdafx.h"
#include "ARTCExample.h"
#include "ARTCScreenShareEncodeConfigDlg.h"
#include "afxdialogex.h"


// ARTCScreenShareEncodeConfigDlg dialog

IMPLEMENT_DYNAMIC(ARTCScreenShareEncodeConfigDlg, CDialogEx)

ARTCScreenShareEncodeConfigDlg::ARTCScreenShareEncodeConfigDlg(CWnd* pParent /*=NULL*/)
	: CDialogEx(IDD_DIALOG_SCREEN_SHARE_ENCODER, pParent)
{

}

ARTCScreenShareEncodeConfigDlg::~ARTCScreenShareEncodeConfigDlg()
{
}

BOOL ARTCScreenShareEncodeConfigDlg::OnInitDialog()
{
	CDialogEx::OnInitDialog();

	mScreenShareWidth.SetWindowText(L"1280");
	mScreenShareHeight.SetWindowText(L"720");
	mScreenShareFps.SetWindowText(L"5");
	mScreenShareBitRate.SetWindowText(L"800");


	return TRUE;
}

void ARTCScreenShareEncodeConfigDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialogEx::DoDataExchange(pDX);
	DDX_Control(pDX, IDC_EDIT1, mScreenShareWidth);
	DDX_Control(pDX, IDC_EDIT2, mScreenShareHeight);
	DDX_Control(pDX, IDC_EDIT3, mScreenShareFps);
	DDX_Control(pDX, IDC_EDIT4, mScreenShareBitRate);
}


BEGIN_MESSAGE_MAP(ARTCScreenShareEncodeConfigDlg, CDialogEx)
	ON_BN_CLICKED(IDOK, &ARTCScreenShareEncodeConfigDlg::OnBnClickedOk)
END_MESSAGE_MAP()


// ARTCScreenShareEncodeConfigDlg message handlers


void ARTCScreenShareEncodeConfigDlg::OnBnClickedOk()
{
	// TODO: Add your control notification handler code here
	if (mScreenShareBitRate.GetWindowTextLength() == 0 ||
		mScreenShareFps.GetWindowTextLength() == 0 ||
		mScreenShareWidth.GetWindowTextLength() == 0 ||
		mScreenShareHeight.GetWindowTextLength() == 0 ) {
		this->MessageBox(L"编码参数未配置！", L"提示", MB_ICONERROR);
		return;
	}

	CString strWidth;
	CString strHeight;
	CString strFps;
	CString strBitRate;
	
	mScreenShareWidth.GetWindowText(strWidth);
	mScreenShareHeight.GetWindowText(strHeight);
	mScreenShareFps.GetWindowText(strFps);
	mScreenShareBitRate.GetWindowText(strBitRate);

	mWidth = _ttoi(strWidth.GetBuffer());
	mHeight = _ttoi(strHeight.GetBuffer());
	mFps = _ttoi(strFps.GetBuffer());
	mBitRate = _ttoi(strBitRate.GetBuffer());

	if (mWidth <= 0 || mHeight <= 0 || mFps <= 0 || mBitRate <= 0) {
		this->MessageBox(L"编码参数配置不对，请重新设置！", L"提示", MB_ICONERROR);
		return;
	}

	CDialogEx::OnOK();
}
