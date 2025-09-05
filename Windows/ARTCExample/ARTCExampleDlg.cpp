
// ARTCExampleDlg.cpp : implementation file
//

#include "stdafx.h"
#include "ARTCExample.h"
#include "ARTCExampleDlg.h"
#include "afxdialogex.h"
#include "ARTCTools.h"
#include "ARTCScreenShareEncodeConfigDlg.h"
#include <assert.h>
#include "ARTCExampleDefine.h"


#ifdef _DEBUG
#define new DEBUG_NEW
#endif


// CAboutDlg dialog used for App About

class CAboutDlg : public CDialogEx
{
public:
	CAboutDlg();

// Dialog Data
#ifdef AFX_DESIGN_TIME
	enum { IDD = IDD_ABOUTBOX };
#endif

	protected:
	virtual void DoDataExchange(CDataExchange* pDX);    // DDX/DDV support

// Implementation
protected:
	DECLARE_MESSAGE_MAP()
};

CAboutDlg::CAboutDlg() : CDialogEx(IDD_ABOUTBOX)
{
}

void CAboutDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialogEx::DoDataExchange(pDX);
}

BEGIN_MESSAGE_MAP(CAboutDlg, CDialogEx)
END_MESSAGE_MAP()


// CARTCExampleDlg dialog



CARTCExampleDlg::CARTCExampleDlg(CWnd* pParent /*=NULL*/)
	: CDialogEx(IDD_ARTCEXAMPLE_DIALOG, pParent)
{
	m_hIcon = AfxGetApp()->LoadIcon(IDR_MAINFRAME);
}

void CARTCExampleDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialogEx::DoDataExchange(pDX);
	DDX_Control(pDX, IDC_STATIC_PREVIEW, mLocalView);
	DDX_Control(pDX, IDC_COMBO1, mDesktopListBox);
	DDX_Control(pDX, IDC_COMBO2, mWindowListBox);
	DDX_Control(pDX, IDC_CHECK_PUSH, mPushStreamCheck);
	DDX_Control(pDX, IDC_EDIT_X, mPosX);
	DDX_Control(pDX, IDC_EDIT_Y, mPosY);
	DDX_Control(pDX, IDC_EDIT_WIDTH, mPosWidth);
	DDX_Control(pDX, IDC_EDIT_HEIGHT, mPosHeight);
	DDX_Control(pDX, IDC_STATIC_REMOTE, mRemoteView);
}

BEGIN_MESSAGE_MAP(CARTCExampleDlg, CDialogEx)
	ON_WM_SYSCOMMAND()
	ON_WM_PAINT()
	ON_WM_QUERYDRAGICON()
	ON_BN_CLICKED(IDOK, &CARTCExampleDlg::OnBnClickedOk)
	ON_WM_CLOSE()
	ON_BN_CLICKED(IDC_BUTTON3, &CARTCExampleDlg::OnBnClickedButton3)
	ON_BN_CLICKED(IDC_CHECK_REGION, &CARTCExampleDlg::OnBnClickedRadioRegion)
	ON_BN_CLICKED(IDC_BUTTON_START, &CARTCExampleDlg::OnBnClickedButtonStart)
	ON_BN_CLICKED(IDC_BUTTON_STOP, &CARTCExampleDlg::OnBnClickedButtonStop)
	ON_BN_CLICKED(IDC_BUTTON1, &CARTCExampleDlg::OnBnClickedButton1)
END_MESSAGE_MAP()


// CARTCExampleDlg message handlers

void CARTCExampleDlg::ListAllDesktopAndWindow() {

	if (mDeskTopList) {
		mDeskTopList->Release();
	}

	mDeskTopList = mEngine->GetScreenShareSourceInfo(AliEngineScreenShareDesktop);
	if (mDeskTopList) {

		mDesktopListBox.ResetContent();

		AliEngineScreenSourcInfo sourceInfo;
		for (int i = 0; i < mDeskTopList->GetCount(); ++i) {

			sourceInfo = mDeskTopList->GetSourceInfo(i);

			CString sourceName = ARTCTools::AliStringToCString(sourceInfo.sourceName);
			mDesktopListBox.AddString(sourceName);

		}

		if (mDeskTopList->GetCount() > 0) {
			mDesktopListBox.SetCurSel(0);
		}
		
	}

	if (mWindowList) {
		mWindowList->Release();
	}

	mWindowList = mEngine->GetScreenShareSourceInfo(AliEngineScreenShareWindow);
	if (mWindowList) {

		mWindowListBox.ResetContent();

		AliEngineScreenSourcInfo sourceInfo;
		for (int i = 0; i < mWindowList->GetCount(); ++i) {

			sourceInfo = mWindowList->GetSourceInfo(i);

			CString sourceName = ARTCTools::AliStringToCString(sourceInfo.sourceName);
			mWindowListBox.AddString(sourceName);

		}

		if (mWindowList->GetCount() > 0) {
			mWindowListBox.SetCurSel(0);
		}

	}


}

BOOL CARTCExampleDlg::OnInitDialog()
{
	CDialogEx::OnInitDialog();

	// Add "About..." menu item to system menu.

	// IDM_ABOUTBOX must be in the system command range.
	ASSERT((IDM_ABOUTBOX & 0xFFF0) == IDM_ABOUTBOX);
	ASSERT(IDM_ABOUTBOX < 0xF000);

	CMenu* pSysMenu = GetSystemMenu(FALSE);
	if (pSysMenu != NULL)
	{
		BOOL bNameValid;
		CString strAboutMenu;
		bNameValid = strAboutMenu.LoadString(IDS_ABOUTBOX);
		ASSERT(bNameValid);
		if (!strAboutMenu.IsEmpty())
		{
			pSysMenu->AppendMenu(MF_SEPARATOR);
			pSysMenu->AppendMenu(MF_STRING, IDM_ABOUTBOX, strAboutMenu);
		}
	}

	// Set the icon for this dialog.  The framework does this automatically
	//  when the application's main window is not a dialog
	SetIcon(m_hIcon, TRUE);			// Set big icon
	SetIcon(m_hIcon, FALSE);		// Set small icon

	

	int ret = mLoginDlg.DoModal();
	if (ret != IDOK) {
		return FALSE;
	}

	this->SetWindowText(L"ARTC屏幕共享Example");

	/*
	获取用户ID和频道ID
	*/
	
	mUserId = ARTCTools::CStringtoStdString(mLoginDlg.mUserID);
	mChannelId = ARTCTools::CStringtoStdString(mLoginDlg.mChannelID);

	mUserName = "APIExample";

	
	InitAliEngine();

	mEngineEvent.SetLogHandle(GetDlgItem(IDC_LIST_LOG)->GetSafeHwnd(), this);

	AliEngineVideoCanvas canvas;
	canvas.displayView = mLocalView.GetSafeHwnd();
	
	mEngine->SetLocalViewConfig( canvas, AliRTCSdk::AliEngineVideoTrackCamera );

	mEngine->StartPreview();

	mCheckButtoDesktop = (CButton *)GetDlgItem(IDC_RADIO_DESKTOP);
	mCheckButtoWin = (CButton *)GetDlgItem(IDC_RADIO_WIN);
	mCheckButtonRegion = (CButton *)GetDlgItem(IDC_CHECK_REGION);

	ListAllDesktopAndWindow();

	mCheckButtoDesktop->SetCheck(1);
	mPushStreamCheck.SetCheck(1);

	// TODO: Add extra initialization here

	return TRUE;  // return TRUE  unless you set the focus to a control
}


void CARTCExampleDlg::OnSysCommand(UINT nID, LPARAM lParam)
{
	if ((nID & 0xFFF0) == IDM_ABOUTBOX)
	{
		CAboutDlg dlgAbout;
		dlgAbout.DoModal();
	}
	else
	{
		CDialogEx::OnSysCommand(nID, lParam);
	}
}

// If you add a minimize button to your dialog, you will need the code below
//  to draw the icon.  For MFC applications using the document/view model,
//  this is automatically done for you by the framework.

void CARTCExampleDlg::OnPaint()
{
	if (IsIconic())
	{
		CPaintDC dc(this); // device context for painting

		SendMessage(WM_ICONERASEBKGND, reinterpret_cast<WPARAM>(dc.GetSafeHdc()), 0);

		// Center icon in client rectangle
		int cxIcon = GetSystemMetrics(SM_CXICON);
		int cyIcon = GetSystemMetrics(SM_CYICON);
		CRect rect;
		GetClientRect(&rect);
		int x = (rect.Width() - cxIcon + 1) / 2;
		int y = (rect.Height() - cyIcon + 1) / 2;

		// Draw the icon
		dc.DrawIcon(x, y, m_hIcon);
	}
	else
	{
		CDialogEx::OnPaint();
	}
}

// The system calls this function to obtain the cursor to display while the user drags
//  the minimized window.
HCURSOR CARTCExampleDlg::OnQueryDragIcon()
{
	return static_cast<HCURSOR>(m_hIcon);
}



void CARTCExampleDlg::OnBnClickedOk()
{
	// TODO: Add your control notification handler code here
	CDialogEx::OnOK();
}


int CARTCExampleDlg::InitAliEngine() {
	if (mEngine != nullptr) {
		return 0;
	}

	mEngine = AliRTCSdk::AliEngine::Create("");

	mEngine->SetEngineEventListener(&mEngineEvent);

	/*
	这里用ARTCExampleDefine.h中的宏
	*/
	std::string appid = ARTC_APP_ID;
	std::string appkey = ARTC_APP_KEY;
	std::string nonce  = "";

	char cTokenBuffer[512];

	AliEngineAuthInfo auth;

	auth.appId = (char *)appid.c_str();
	auth.channelId = (char *)mChannelId.c_str();
	auth.userId = (char*)mUserId.c_str();
	auth.timestamp = time(NULL) + 24 * 60 * 60;
	auth.nonce = (char *)nonce.c_str();

	/*
	mUserId/mChannelId 长度最大都是64 用500长度够了
	*/
	snprintf(cTokenBuffer, 500, "%s%s%s%s%s%I64u",
		auth.appId,
		appkey.c_str(),
		auth.channelId,
		auth.userId,
		auth.nonce,
		auth.timestamp);

	char SHA256_Buffer[512];

	ARTCTools::encoder_SHA256(cTokenBuffer, SHA256_Buffer);

	auth.token = SHA256_Buffer;

	mChannelProfile = AliEngineInteractiveLive;
	mClientRole = AliEngineClientRoleInteractive;
	
	mEngine->SetChannelProfile(mChannelProfile);
	mEngine->SetClientRole(mClientRole);

	mEngine->SetClientRole(mClientRole);

	mEngine->JoinChannel(auth, mUserName.c_str());
	mEngine->SetDefaultSubscribeAllRemoteVideoStreams(true);
	mEngine->SetDefaultSubscribeAllRemoteAudioStreams(false);

	return 0;
}

void CARTCExampleDlg::CleanupAliEngine() {
	if (mEngine == nullptr) {
		return;
	}

	mEngine->Destroy(nullptr);
	mEngine = nullptr;
}


void CARTCExampleDlg::OnClose()
{
	// TODO: Add your message handler code here and/or call default
	if (mWindowList) {
		mWindowList->Release();
		mWindowList = nullptr;
	}

	if (mDeskTopList) {
		mDeskTopList->Release();
		mDeskTopList = nullptr;
	}

	CleanupAliEngine();
	CDialogEx::OnClose();
}


void CARTCExampleDlg::OnBnClickedButton3()
{
	// TODO: Add your control notification handler code here
	ListAllDesktopAndWindow();
}


void CARTCExampleDlg::OnBnClickedRadioRegion()
{
	// TODO: Add your control notification handler code here
	if (mCheckButtonRegion->GetCheck() == 1) {
		mPosX.EnableWindow(TRUE);
		mPosY.EnableWindow(TRUE);
		mPosWidth.EnableWindow(TRUE);
		mPosHeight.EnableWindow(TRUE);
	}
	else {
		mPosX.EnableWindow(FALSE);
		mPosY.EnableWindow(FALSE);
		mPosWidth.EnableWindow(FALSE);
		mPosHeight.EnableWindow(FALSE);
	}
}



void CARTCExampleDlg::OnBnClickedButtonStart()
{
	// TODO: Add your control notification handler code here


	AliEngineScreenShareConfig shareConfig;

	/*
	进行共享类型判断，包括是否是窗口、桌面共享、是否是局部共享
	*/
	bool bPushStream = false;
	if (mPushStreamCheck.GetCheck() == 1) {
		bPushStream = true;
	}

	bool bShareRegion = false;
	int PosX = 0;
	int PosY = 0;
	int PosWidth = 0;
	int PosHeight = 0;

	if (mCheckButtonRegion->GetCheck() == 1) {

		bShareRegion = true;

		if (mPosX.GetWindowTextLength() == 0 || mPosY.GetWindowTextLength() == 0 ||
			mPosWidth.GetWindowTextLength() == 0 || mPosHeight.GetWindowTextLength() == 0 ) {
			this->MessageBox(L"未设置屏幕共享区域坐标或者宽高，请重新设置！", L"提示", MB_ICONERROR);
			return;
		}

		CString strPosX;
		CString strPosY;
		CString strPosWidth;
		CString strPosHeight;

		mPosX.GetWindowText(strPosX);
		mPosY.GetWindowText(strPosY);
		mPosWidth.GetWindowText(strPosWidth);
		mPosHeight.GetWindowText(strPosHeight);

		PosX = _ttoi(strPosX.GetBuffer());
		PosY = _ttoi(strPosY.GetBuffer());
		PosWidth = _ttoi(strPosWidth.GetBuffer());
		PosHeight = _ttoi(strPosHeight.GetBuffer());

		if (PosWidth <= 0 || PosHeight <= 0 || PosX < 0 || PosY < 0 ) {
			this->MessageBox(L"共享屏幕分享区域坐标或者长宽不对，请重新设置！", L"提示", MB_ICONERROR);
			return;
		}

	}

	/*
	配置共享区域
	*/
	shareConfig.isPushStream = bPushStream;
	shareConfig.isShareByRegion = bShareRegion;

	if (bShareRegion) {
		shareConfig.shareRegion.originX = PosX;
		shareConfig.shareRegion.originY = PosY;
		shareConfig.shareRegion.width = PosWidth;
		shareConfig.shareRegion.height = PosHeight;
	}

	if (mStartScreenShare) {
		mEngine->UpdateScreenShareConfig(shareConfig);
		return;
	}

	/*
	开始启动屏幕共享
	*/

	/*
	先移除摄像头的渲染
	*/
	AliEngineVideoCanvas canvas;
	canvas.displayView = nullptr;
	mEngine->SetLocalViewConfig(canvas, AliEngineVideoTrackCamera);

	/*
	停止推本地摄像头流
	*/
	mEngine->EnableLocalVideo(FALSE);

	/*
	再加上屏幕共享的预览窗口
	*/
	canvas.displayView = mLocalView.GetSafeHwnd();
	canvas.renderMode = AliRTCSdk::AliEngineRenderModeAuto;
	mEngine->SetLocalViewConfig(canvas, AliEngineVideoTrackScreen);

	if (mCheckButtoDesktop->GetCheck() == 1) {

		int selectIndex = mDesktopListBox.GetCurSel();
		if (selectIndex < 0) {
			return;
		}

		int sourceId = atoi(mDeskTopList->GetSourceInfo(selectIndex).sourceId.c_str());
		int ret = mEngine->StartScreenShareByDesktopId(sourceId, shareConfig);

		assert(ret == 0);

		mStartScreenShare = true;
	}
	else {

		int selectIndex = mWindowListBox.GetCurSel();
		if (selectIndex < 0) {
			return;
		}

		int sourceId = atoi(mWindowList->GetSourceInfo(selectIndex).sourceId.c_str());
		int ret = mEngine->StartScreenShareByWindowId(sourceId, shareConfig);

		assert(ret == 0);
		mStartScreenShare = true;
	}

	// TODO: Add your control notification handler code here
	/*
	开启屏幕共享后，禁止修改屏幕共享类型，只能修改区域共享坐标和是否推流
	*/
	mWindowListBox.EnableWindow(FALSE);
	mDesktopListBox.EnableWindow(FALSE);
	mCheckButtoDesktop->EnableWindow(FALSE);
	mCheckButtoWin->EnableWindow(FALSE);

	CWnd * button = GetDlgItem(IDC_BUTTON_START);
	button->SetWindowText(L"更新共享");



}


void CARTCExampleDlg::OnBnClickedButtonStop()
{
	// TODO: Add your control notification handler code here
	if (!mStartScreenShare) {
		return;
	}

	mEngine->StopScreenShare();
	mStartScreenShare = false;
	mWindowListBox.EnableWindow(TRUE);
	mDesktopListBox.EnableWindow(TRUE);
	mCheckButtoDesktop->EnableWindow(TRUE);
	mCheckButtoWin->EnableWindow(TRUE);

	CWnd * button = GetDlgItem(IDC_BUTTON_START);

	button->SetWindowText(L"开始共享");


	/*
	重新切到摄像头预览
	*/
	AliEngineVideoCanvas canvas;
	canvas.displayView = mLocalView.GetSafeHwnd();

	mEngine->SetLocalViewConfig(canvas, AliRTCSdk::AliEngineVideoTrackCamera);
	/*
	开始推本地摄像头流
	*/
	mEngine->EnableLocalVideo(TRUE);
}


void CARTCExampleDlg::HandleTrackChangeEvent(const char *uid,
	AliEngineAudioTrack audioTrack,
	AliEngineVideoTrack videoTrack) {

	/*
	如果有屏幕共享流，则先删除摄像头流的显示，然后再设置屏幕共享流的窗口
	*/
	if ((videoTrack & AliEngineVideoTrackScreen) > 0) {

		if ((videoTrack & AliEngineVideoTrackCamera) == 0) {

			AliEngineVideoCanvas canvas;
			canvas.displayView = nullptr;

			mEngine->SetRemoteViewConfig(canvas, uid, AliEngineVideoTrackCamera);
		}


		{
			AliEngineVideoCanvas canvas;
			canvas.displayView = mRemoteView.GetSafeHwnd();

			mEngine->SetRemoteViewConfig(canvas, uid, AliEngineVideoTrackScreen);
		}

		return;
	}

	/*
	再处理摄像头流的通知
	*/
	if ( (videoTrack & AliEngineVideoTrackCamera) > 0) {

		AliEngineVideoCanvas canvas;
		canvas.displayView = mRemoteView.GetSafeHwnd();

		mEngine->SetRemoteViewConfig(canvas, uid, AliEngineVideoTrackCamera );
	}
	
	
}

void CARTCExampleDlg::OnBnClickedButton1()
{
	// TODO: Add your control notification handler code here

	ARTCScreenShareEncodeConfigDlg dlg;
	if (dlg.DoModal() == IDOK) {
		AliEngineScreenShareEncoderConfiguration config;

		config.bitrate = dlg.mBitRate;
		config.dimensions.width = dlg.mWidth;
		config.dimensions.height = dlg.mHeight;
		config.frameRate = (AliEngineFrameRate)dlg.mFps;

		mEngine->SetScreenShareEncoderConfiguration(config);
	}
}
