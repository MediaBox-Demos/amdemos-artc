// ARTCSelectDlg.cpp : implementation file
//

#include "stdafx.h"
#include "ARTCExample.h"
#include "ARTCSelectDlg.h"
#include "afxdialogex.h"
#include "include/rtc/engine_interface.h"


// ARTCSelectDlg dialog

IMPLEMENT_DYNAMIC(ARTCSelectDlg, CDialogEx)

ARTCSelectDlg::ARTCSelectDlg(CWnd* pParent /*=NULL*/)
	: CDialogEx(IDD_DIALOG_SELECT, pParent)
{

}

ARTCSelectDlg::~ARTCSelectDlg()
{
}

void ARTCSelectDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialogEx::DoDataExchange(pDX);
	DDX_Control(pDX, IDC_LIST_FAST_START, m_ListFastStart);
	DDX_Control(pDX, IDC_LIST_BASIC, m_ListBasic);
	DDX_Control(pDX, IDC_LIST_ADVANCED, m_ListAdvanced);
}


BEGIN_MESSAGE_MAP(ARTCSelectDlg, CDialogEx)
	ON_BN_CLICKED(IDOK, &ARTCSelectDlg::OnBnClickedOk)
	ON_LBN_SELCHANGE(IDC_LIST_FAST_START, &ARTCSelectDlg::OnLbnSelchangeListFastStart)
	ON_LBN_SELCHANGE(IDC_LIST_BASIC, &ARTCSelectDlg::OnLbnSelchangeListBasic)
	ON_LBN_SELCHANGE(IDC_LIST_ADVANCED, &ARTCSelectDlg::OnLbnSelchangeListAdvanced)
END_MESSAGE_MAP()


// ARTCSelectDlg message handlers

BOOL ARTCSelectDlg::OnInitDialog() {
	CDialogEx::OnInitDialog();

	m_ListFastStart.AddString(L"Token生成和入会");
	m_ListFastStart.AddString(L"实现音视频通话");
	m_ListFastStart.AddString(L"实现语聊房");
	m_ListFastStart.AddString(L"屏幕共享[可用]");

	m_ListBasic.AddString(L"音频常用操作和配置");
	m_ListBasic.AddString(L"视频常用操作和配置");
	m_ListBasic.AddString(L"摄像头常规控制");
	m_ListBasic.AddString(L"SEI发送和接收");

	m_ListAdvanced.AddString(L"自定义音频采集");
	m_ListAdvanced.AddString(L"自定义视频采集");


	return TRUE;

}

void ARTCSelectDlg::OnBnClickedOk()
{
	// TODO: Add your control notification handler code here
	CDialogEx::OnOK();
}


void ARTCSelectDlg::OnLbnSelchangeListFastStart()
{
	// TODO: Add your control notification handler code here
	int selectIndex = m_ListAdvanced.GetCurSel();
	if (selectIndex >= 0) {
		m_ListAdvanced.ResetContent();
		m_ListAdvanced.AddString(L"自定义音频采集");
		m_ListAdvanced.AddString(L"自定义视频采集");

	}
	
	selectIndex = m_ListBasic.GetCurSel();
	if (selectIndex >= 0) {
		m_ListBasic.ResetContent();
		m_ListBasic.AddString(L"音频常用操作和配置");
		m_ListBasic.AddString(L"视频常用操作和配置");
		m_ListBasic.AddString(L"摄像头常规控制");
		m_ListBasic.AddString(L"SEI发送和接收");
	}

	m_SelectItemIndex = m_ListFastStart.GetCurSel();

	this->UpdateData();

	if (m_SelectItemIndex == 3) {
		CDialogEx::OnOK();
	}
}


void ARTCSelectDlg::OnLbnSelchangeListBasic()
{
	// TODO: Add your control notification handler code here

	int selectIndex = m_ListAdvanced.GetCurSel();
	if (selectIndex >= 0) {
		m_ListAdvanced.ResetContent();
		m_ListAdvanced.AddString(L"自定义音频采集");
		m_ListAdvanced.AddString(L"自定义视频采集");

	}

	selectIndex = m_ListFastStart.GetCurSel();
	if (selectIndex >= 0) {
		m_ListFastStart.ResetContent();
		m_ListFastStart.AddString(L"Token生成和入会");
		m_ListFastStart.AddString(L"实现音视频通话");
		m_ListFastStart.AddString(L"实现语聊房");
		m_ListFastStart.AddString(L"屏幕共享[可用]");
	}

	this->UpdateData();

	m_SelectItemIndex = m_ListBasic.GetCurSel() + 4;
}


void ARTCSelectDlg::OnLbnSelchangeListAdvanced()
{
	// TODO: Add your control notification handler code here
	int selectIndex = m_ListBasic.GetCurSel();
	if (selectIndex >= 0) {
		m_ListBasic.ResetContent();
		m_ListBasic.AddString(L"音频常用操作和配置");
		m_ListBasic.AddString(L"视频常用操作和配置");
		m_ListBasic.AddString(L"摄像头常规控制");
		m_ListBasic.AddString(L"SEI发送和接收");
	}

	selectIndex = m_ListFastStart.GetCurSel();
	if (selectIndex >= 0) {
		m_ListFastStart.ResetContent();
		m_ListFastStart.AddString(L"Token生成和入会");
		m_ListFastStart.AddString(L"实现音视频通话");
		m_ListFastStart.AddString(L"实现语聊房");
		m_ListFastStart.AddString(L"屏幕共享[可用]");
	}

	m_SelectItemIndex = m_ListAdvanced.GetCurSel() + 8;
}
