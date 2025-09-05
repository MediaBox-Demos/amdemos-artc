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

	m_ListFastStart.AddString(L"Token���ɺ����");
	m_ListFastStart.AddString(L"ʵ������Ƶͨ��");
	m_ListFastStart.AddString(L"ʵ�����ķ�");
	m_ListFastStart.AddString(L"��Ļ����[����]");

	m_ListBasic.AddString(L"��Ƶ���ò���������");
	m_ListBasic.AddString(L"��Ƶ���ò���������");
	m_ListBasic.AddString(L"����ͷ�������");
	m_ListBasic.AddString(L"SEI���ͺͽ���");

	m_ListAdvanced.AddString(L"�Զ�����Ƶ�ɼ�");
	m_ListAdvanced.AddString(L"�Զ�����Ƶ�ɼ�");


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
		m_ListAdvanced.AddString(L"�Զ�����Ƶ�ɼ�");
		m_ListAdvanced.AddString(L"�Զ�����Ƶ�ɼ�");

	}
	
	selectIndex = m_ListBasic.GetCurSel();
	if (selectIndex >= 0) {
		m_ListBasic.ResetContent();
		m_ListBasic.AddString(L"��Ƶ���ò���������");
		m_ListBasic.AddString(L"��Ƶ���ò���������");
		m_ListBasic.AddString(L"����ͷ�������");
		m_ListBasic.AddString(L"SEI���ͺͽ���");
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
		m_ListAdvanced.AddString(L"�Զ�����Ƶ�ɼ�");
		m_ListAdvanced.AddString(L"�Զ�����Ƶ�ɼ�");

	}

	selectIndex = m_ListFastStart.GetCurSel();
	if (selectIndex >= 0) {
		m_ListFastStart.ResetContent();
		m_ListFastStart.AddString(L"Token���ɺ����");
		m_ListFastStart.AddString(L"ʵ������Ƶͨ��");
		m_ListFastStart.AddString(L"ʵ�����ķ�");
		m_ListFastStart.AddString(L"��Ļ����[����]");
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
		m_ListBasic.AddString(L"��Ƶ���ò���������");
		m_ListBasic.AddString(L"��Ƶ���ò���������");
		m_ListBasic.AddString(L"����ͷ�������");
		m_ListBasic.AddString(L"SEI���ͺͽ���");
	}

	selectIndex = m_ListFastStart.GetCurSel();
	if (selectIndex >= 0) {
		m_ListFastStart.ResetContent();
		m_ListFastStart.AddString(L"Token���ɺ����");
		m_ListFastStart.AddString(L"ʵ������Ƶͨ��");
		m_ListFastStart.AddString(L"ʵ�����ķ�");
		m_ListFastStart.AddString(L"��Ļ����[����]");
	}

	m_SelectItemIndex = m_ListAdvanced.GetCurSel() + 8;
}
