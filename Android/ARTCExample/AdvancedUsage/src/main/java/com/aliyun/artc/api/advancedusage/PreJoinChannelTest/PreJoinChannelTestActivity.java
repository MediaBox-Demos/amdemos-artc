package com.aliyun.artc.api.advancedusage.PreJoinChannelTest;

import static com.alivc.rtc.AliRtcEngine.AliRtcVideoEncoderOrientationMode.AliRtcVideoEncoderOrientationModeAdaptive;
import static com.alivc.rtc.AliRtcEngine.AliRtcVideoTrack.AliRtcVideoTrackBoth;
import static com.alivc.rtc.AliRtcEngine.AliRtcVideoTrack.AliRtcVideoTrackCamera;
import static com.alivc.rtc.AliRtcEngine.AliRtcVideoTrack.AliRtcVideoTrackNo;
import static com.alivc.rtc.AliRtcEngine.AliRtcVideoTrack.AliRtcVideoTrackScreen;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Color;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;
import android.text.method.ScrollingMovementMethod;
import android.util.Log;
import android.view.Gravity;
import android.view.MenuItem;
import android.view.SurfaceView;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.GridLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import com.alivc.rtc.AliRtcEngine;
import com.alivc.rtc.AliRtcEngineEventListener;
import com.alivc.rtc.AliRtcEngineNotify;
import com.aliyun.artc.api.advancedusage.R;
import com.aliyun.artc.api.keycenter.ARTCTokenHelper;
import com.aliyun.artc.api.keycenter.GlobalConfig;
import com.aliyun.artc.api.keycenter.utils.ToastHelper;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 通话前质量测试
 *     1. 设备检测
 *     2. 网络监测
 */
public class PreJoinChannelTestActivity extends AppCompatActivity {
    private Handler handler;
    private EditText mChannelEditText;
    private TextView mJoinChannelTextView;
    private boolean hasJoined = false;

    private AliRtcEngine mAliRtcEngine = null;
    private AliRtcEngine.AliRtcVideoCanvas mLocalVideoCanvas = null;
    private GridLayout gridVideoContainer;
    private final Map<String, FrameLayout> remoteViews = new ConcurrentHashMap<>();

    // 通话前测试
    private TextView mTestDeviceTextView;
    private Button mTestMicrophoneBtn;
    private boolean hasTestMicrophone = false;
    private boolean hasAppended = false;
    private Button mTestSpeakerBtn;
    private String testSpeakerFilePath = "/assets/music.wav";
    private boolean hasTestSpeaker = false;
    private Button mTestCameraBtn;
    private boolean hasTestCamera = false;

    private TextView mTestNetworkTextView;
    private Button mTestNetworkBtn;
    private boolean hasTestNetwork = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        handler = new Handler(Looper.getMainLooper());
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_pre_join_channel_test);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.pre_join_channel_test), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });
        setTitle(getString(R.string.pre_join_channel_test));
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);

        gridVideoContainer = findViewById(R.id.grid_video_container);

        initAndSetupRtcEngine();

        mChannelEditText = findViewById(R.id.channel_id_input);
        mChannelEditText.setText(GlobalConfig.getInstance().gerRandomChannelId());
        mJoinChannelTextView = findViewById(R.id.join_room_btn);
        mJoinChannelTextView.setOnClickListener(v -> {
            if(hasJoined) {
                destroyRtcEngine();
                mJoinChannelTextView.setText(R.string.leave_channel);
            } else {
                startRTCCall();
            }
        });

        // 麦克风测试
        mTestMicrophoneBtn = findViewById(R.id.btn_test_microphone);
        mTestMicrophoneBtn.setOnClickListener(v -> {
            if(mAliRtcEngine != null && !hasJoined) {
                if(!hasTestMicrophone) {
                    // 注册音量数据回调
                    mAliRtcEngine.registerAudioVolumeObserver(mAudioVolumeObserver);
                    int result = mAliRtcEngine.startAudioCaptureTest();
                    if(result == 0) {
                        mTestMicrophoneBtn.setText(R.string.stop_test);
                        hasTestMicrophone = true;
                        hasAppended = false;
                    }
                    mTestDeviceTextView.append("startAudioCaptureTest Result: " + result + "\n");
                } else {
                    int result = mAliRtcEngine.stopAudioCaptureTest();
                    mTestDeviceTextView.append("stopAudioCaptureTest Result: " + result + "\n");
                    mAliRtcEngine.unRegisterAudioVolumeObserver();
                    mTestMicrophoneBtn.setText(R.string.test_microphone);
                    hasTestMicrophone = false;
                }
            }
        });
        // 扬声器测试
        mTestSpeakerBtn = findViewById(R.id.btn_test_speaker);
        mTestSpeakerBtn.setOnClickListener(v -> {
            if(mAliRtcEngine != null && !hasJoined) {
                if(!hasTestSpeaker) {
                    int result = mAliRtcEngine.playAudioFileTest(testSpeakerFilePath);
                    if(result == 0) {
                        mTestSpeakerBtn.setText(R.string.stop_test);
                        hasTestSpeaker = true;
                    }
                    mTestDeviceTextView.append("playAudioFileTest Result: " + result + "\n");
                } else {
                    int result = mAliRtcEngine.stopAudioFileTest();
                    mTestSpeakerBtn.setText(R.string.test_speaker);
                    hasTestSpeaker = false;
                    mTestDeviceTextView.append("stopAudioFileTest Result: " + result + "\n");
                }
            }
        });
        // 相机测试
        mTestCameraBtn = findViewById(R.id.btn_test_camera);
        mTestCameraBtn.setOnClickListener(v -> {
            if(mAliRtcEngine != null && !hasJoined) {
                if(!hasTestCamera) {
                    startPreview();
                    mTestCameraBtn.setText(R.string.stop_test);
                    hasTestCamera = true;
                    mTestDeviceTextView.append("startPreview\n");
                } else {
                    mAliRtcEngine.setLocalViewConfig(null, AliRtcVideoTrackCamera);
                    mAliRtcEngine.stopPreview();
                    mTestCameraBtn.setText(R.string.test_camera);
                    gridVideoContainer.removeAllViews();
                    mTestCameraBtn.setText(R.string.test_camera);
                    hasTestCamera = false;
                    mTestDeviceTextView.append("stopPreview\n");
                }
            }
        });
        // 网络测试
        mTestNetworkBtn = findViewById(R.id.btn_test_network);
        mTestNetworkBtn.setOnClickListener(v -> {
            if(mAliRtcEngine != null && !hasJoined) {
                if(!hasTestNetwork) {
                    AliRtcEngine.AlirtcNetworkQualityProbeConfig config = new AliRtcEngine.AlirtcNetworkQualityProbeConfig();
                    config.probeUplink = true;
                    config.probeDownlink = true;
                    mAliRtcEngine.startNetworkQualityProbeTest(config);
                    mTestNetworkBtn.setText(R.string.stop_test);
                    hasTestNetwork = true;
                    mTestNetworkTextView.append("startNetworkQualityProbeTest\n");
                } else {
                    mAliRtcEngine.stopNetworkQualityProbeTest();
                    mTestNetworkBtn.setText(R.string.test_network);
                    hasTestNetwork = false;
                    mTestNetworkTextView.append("stopNetworkQualityProbeTest\n");
                }
            }
        });

        // 测试结果显示
        mTestDeviceTextView = findViewById(R.id.tv_device_test_result);
        mTestDeviceTextView.setMovementMethod(new ScrollingMovementMethod());
        mTestNetworkTextView = findViewById(R.id.tv_network_test_result);
        mTestNetworkTextView.setMovementMethod(new ScrollingMovementMethod());
    }

    public static void startActionActivity(Activity activity) {
        Intent intent = new Intent(activity, PreJoinChannelTestActivity.class);
        activity.startActivity(intent);
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        if (item.getItemId() == android.R.id.home) {
            // 点击返回按钮时的操作
            destroyRtcEngine();
            finish();
            return true;
        }
        return super.onOptionsItemSelected(item);
    }

    private void handleJoinResult(int result, String channel, String userId) {
        handler.post(() -> {
            String  str = null;
            if(result == 0) {
                str = "User " + userId + " Join " + channel + " Success";
            } else {
                str = "User " + userId + " Join " + channel + " Failed！， error：" + result;
            }
            ToastHelper.showToast(this, str, Toast.LENGTH_SHORT);
            ((TextView)findViewById(R.id.join_room_btn)).setText(R.string.leave_channel);
        });
    }

    private void startRTCCall() {
        if(hasJoined) {
            return;
        }
        initAndSetupRtcEngine();
        startPreview();
        joinChannel();
    }

    private void initAndSetupRtcEngine() {

        //创建并初始化引擎
        if(mAliRtcEngine == null) {
            mAliRtcEngine = AliRtcEngine.getInstance(this);
        }
        mAliRtcEngine.setRtcEngineEventListener(mRtcEngineEventListener);
        mAliRtcEngine.setRtcEngineNotify(mRtcEngineNotify);


        // 设置频道模式为互动模式,RTC下都使用AliRTCSdkInteractiveLive
        mAliRtcEngine.setChannelProfile(AliRtcEngine.AliRTCSdkChannelProfile.AliRTCSdkInteractiveLive);
        // 设置用户角色，既需要推流也需要拉流使用AliRTCSdkInteractive， 只拉流不推流使用AliRTCSdkLive
        mAliRtcEngine.setClientRole(AliRtcEngine.AliRTCSdkClientRole.AliRTCSdkInteractive);
        //设置音频Profile，默认使用高音质模式AliRtcEngineHighQualityMode及音乐模式AliRtcSceneMusicMode
        mAliRtcEngine.setAudioProfile(AliRtcEngine.AliRtcAudioProfile.AliRtcEngineHighQualityMode, AliRtcEngine.AliRtcAudioScenario.AliRtcSceneMusicMode);
        mAliRtcEngine.setCapturePipelineScaleMode(AliRtcEngine.AliRtcCapturePipelineScaleMode.AliRtcCapturePipelineScaleModePost);

        //设置视频编码参数
        AliRtcEngine.AliRtcVideoEncoderConfiguration aliRtcVideoEncoderConfiguration = new AliRtcEngine.AliRtcVideoEncoderConfiguration();
        aliRtcVideoEncoderConfiguration.dimensions = new AliRtcEngine.AliRtcVideoDimensions(720, 1280);
        aliRtcVideoEncoderConfiguration.frameRate = 20;
        aliRtcVideoEncoderConfiguration.bitrate = 1200;
        aliRtcVideoEncoderConfiguration.keyFrameInterval = 2000;
        aliRtcVideoEncoderConfiguration.orientationMode = AliRtcVideoEncoderOrientationModeAdaptive;
        mAliRtcEngine.setVideoEncoderConfiguration(aliRtcVideoEncoderConfiguration);

        //SDK默认会publish音频，publishLocalAudioStream可以不调用
        mAliRtcEngine.publishLocalAudioStream(true);
        //如果是视频通话，publishLocalVideoStream(true)可以不调用，SDK默认会publish视频
        //如果是纯语音通话 则需要设置publishLocalVideoStream(false)设置不publish视频
        mAliRtcEngine.publishLocalVideoStream(true);

        //设置默认订阅远端的音频和视频流
        mAliRtcEngine.setDefaultSubscribeAllRemoteAudioStreams(true);
        mAliRtcEngine.subscribeAllRemoteAudioStreams(true);
        mAliRtcEngine.setDefaultSubscribeAllRemoteVideoStreams(true);
        mAliRtcEngine.subscribeAllRemoteVideoStreams(true);

    }

    private void startPreview(){
        if (mAliRtcEngine != null) {
            FrameLayout localVideoFrame = createVideoView("local");
            gridVideoContainer.addView(localVideoFrame);
            SurfaceView localSurfaceView = mAliRtcEngine.createRenderSurfaceView(this);
            localSurfaceView.setZOrderOnTop(true);
            localSurfaceView.setZOrderMediaOverlay(true);

            localVideoFrame.addView(localSurfaceView, new FrameLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT));

            // 添加标签
            addUserIdLabel(localVideoFrame, "local");

            mLocalVideoCanvas = new AliRtcEngine.AliRtcVideoCanvas();
            mLocalVideoCanvas.view = localSurfaceView;
            mAliRtcEngine.setLocalViewConfig(mLocalVideoCanvas, AliRtcVideoTrackCamera);
            mAliRtcEngine.startPreview();
        }
    }

    private void joinChannel() {
        String channelId = mChannelEditText.getText().toString();
        if(!TextUtils.isEmpty(channelId)) {
            String userId = GlobalConfig.getInstance().getUserId();
            String appId = ARTCTokenHelper.AppId;
            String appKey = ARTCTokenHelper.AppKey;
            long timestamp = ARTCTokenHelper.getTimesTamp();
            String token = ARTCTokenHelper.generateSingleParameterToken(appId, appKey, channelId, userId, timestamp);
            mAliRtcEngine.joinChannel(token, null, null, null);
            hasJoined = true;
        } else {
            Log.e("VideoCallActivity", "channelId is empty");
        }
    }

    /**
     * 根据用户 ID 和流类型生成唯一标识
     * @param uid 远端用户 ID
     * @param videoTrack 视频流类型
     * @return 视频流标识符
     */
    private String getStreamKey(String uid, AliRtcEngine.AliRtcVideoTrack videoTrack) {
        return uid + "_" + videoTrack.name();
    }

    private void scrollToBottom(TextView textView) {
        int scrollAmount = textView.getLayout().getLineTop(textView.getLineCount()) - textView.getHeight();
        // 如果有滚动空间，则滚动到底部
        if (scrollAmount > 0) {
            textView.scrollTo(0, scrollAmount);
        } else {
            textView.scrollTo(0, 0);
        }
    }

    private FrameLayout createVideoView(String tag) {
        FrameLayout view = new FrameLayout(this);
        int sizeInDp = 180;
        int sizeInPx = (int) (getResources().getDisplayMetrics().density * sizeInDp);

        GridLayout.LayoutParams params = new GridLayout.LayoutParams();
        params.width = 0;
        params.height = sizeInPx;
        params.columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f); // 自动分两列
        params.setMargins(8, 8, 8, 8);

        view.setLayoutParams(params);
        view.setTag(tag);
        view.setBackgroundColor(Color.BLACK);
        return view;
    }

    /**
     * 添加用户ID标签到视频视图
     * @param layoutView 视频视图容器
     * @param userId 用户ID
     */
    private void addUserIdLabel(FrameLayout layoutView, String userId) {
        TextView userIdTextView = new TextView(this);
        userIdTextView.setText(userId);
        userIdTextView.setTextColor(Color.WHITE);
        userIdTextView.setBackgroundColor(Color.parseColor("#80000000")); // 半透明黑色背景
        userIdTextView.setPadding(10, 10, 10, 10); // 设置内边距

        FrameLayout.LayoutParams textParams = new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT);
        textParams.leftMargin = 20;
        textParams.topMargin = 20;
        textParams.gravity = Gravity.TOP | Gravity.START;

        // 通过添加顺序确保标签在最上层显示
        layoutView.addView(userIdTextView, textParams);
    }

    /**
     * 显示远端流（包括摄像头流和屏幕共享流）
     * @param uid 远端用户 ID
     * @param videoTrack 视频流类型
     */
    private void viewRemoteVideo(String uid, AliRtcEngine.AliRtcVideoTrack videoTrack) {
        String streamKey = getStreamKey(uid, videoTrack);
        FrameLayout view;
        if (remoteViews.containsKey(streamKey)) {
            view = remoteViews.get(streamKey);
            if (view != null) {
                view.removeAllViews();
            } else {
                view = createVideoView(streamKey);
                gridVideoContainer.addView(view);
                remoteViews.put(streamKey, view);
            }
        } else {
            view = createVideoView(streamKey);
            gridVideoContainer.addView(view);
            remoteViews.put(streamKey, view);
        }
        // 创建 SurfaceView 并设置渲染
        SurfaceView surfaceView = mAliRtcEngine.createRenderSurfaceView(this);
        surfaceView.setZOrderMediaOverlay(true);
        view.addView(surfaceView, new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        String trackName = videoTrack == AliRtcVideoTrackScreen ? "Screen" : "Camera";
        addUserIdLabel(view, uid + " - " + trackName);
        // 配置画布
        AliRtcEngine.AliRtcVideoCanvas videoCanvas = new AliRtcEngine.AliRtcVideoCanvas();
        videoCanvas.view = surfaceView;
        mAliRtcEngine.setRemoteViewConfig(videoCanvas, uid, videoTrack);
    }

    /**
     * 移除指定用户视频流的画面
     * @param uid 远端用户 ID
     * @param videoTrack 视频流类型
     */
    private void removeRemoteVideo(String uid, AliRtcEngine.AliRtcVideoTrack videoTrack) {
        String streamKey = getStreamKey(uid, videoTrack);

        // 找到对应的 FrameLayout 容器并移除视图
        FrameLayout frameLayout = remoteViews.remove(streamKey);
        if(frameLayout != null) {
            frameLayout.removeAllViews();
            gridVideoContainer.removeView(frameLayout);
            Log.d("RemoveRemoteVideo", "Removed video stream for: " + streamKey);
        }
    }

    /**
     * 移除指定用户的所有视频
     * @param uid 远端用户 ID
     */
    private void removeAllRemoteVideo(String uid) {
        removeRemoteVideo(uid, AliRtcVideoTrackCamera);
        removeRemoteVideo(uid, AliRtcVideoTrackScreen);
    }

    // 音量回调
    private AliRtcEngine.AliRtcAudioVolumeObserver mAudioVolumeObserver = new AliRtcEngine.AliRtcAudioVolumeObserver() {
        @Override
        public void OnTestAudioVolume(int volume) {
            handler.post(new Runnable() {
                @Override
                public void run() {
                    if(!hasAppended) {
                        hasAppended = true;
                        String msg = "OnTestAudioVolume volume: " + volume + ", the mic is valid!\n";
                        mTestDeviceTextView.append(msg);
                        scrollToBottom(mTestDeviceTextView);
                    }
                }
            });
        }
    };

    private AliRtcEngineEventListener mRtcEngineEventListener = new AliRtcEngineEventListener() {
        @Override
        public void onJoinChannelResult(int result, String channel, String userId, int elapsed) {
            super.onJoinChannelResult(result, channel, userId, elapsed);
            handleJoinResult(result, channel, userId);
        }

        @Override
        public void onLeaveChannelResult(int result, AliRtcEngine.AliRtcStats stats){
            super.onLeaveChannelResult(result, stats);
        }

        @Override
        public void onConnectionStatusChange(AliRtcEngine.AliRtcConnectionStatus status, AliRtcEngine.AliRtcConnectionStatusChangeReason reason){
            super.onConnectionStatusChange(status, reason);

            handler.post(new Runnable() {
                @Override
                public void run() {
                    if(status == AliRtcEngine.AliRtcConnectionStatus.AliRtcConnectionStatusFailed) {
                        /* TODO: 务必处理；建议业务提示客户，此时SDK内部已经尝试了各种恢复策略已经无法继续使用时才会上报 */
                        ToastHelper.showToast(PreJoinChannelTestActivity.this, R.string.video_chat_connection_failed, Toast.LENGTH_SHORT);
                    } else {
                        /* TODO: 可选处理；增加业务代码，一般用于数据统计、UI变化 */
                    }
                }
            });
        }
        @Override
        public void OnLocalDeviceException(AliRtcEngine.AliRtcEngineLocalDeviceType deviceType, AliRtcEngine.AliRtcEngineLocalDeviceExceptionType exceptionType, String msg){
            super.OnLocalDeviceException(deviceType, exceptionType, msg);
            /* TODO: 务必处理；建议业务提示设备错误，此时SDK内部已经尝试了各种恢复策略已经无法继续使用时才会上报 */
            handler.post(new Runnable() {
                @Override
                public void run() {
                    String str = "OnLocalDeviceException deviceType: " + deviceType + " exceptionType: " + exceptionType + " msg: " + msg;
                    mTestDeviceTextView.append(str + "\n");
                    ToastHelper.showToast(PreJoinChannelTestActivity.this, str, Toast.LENGTH_SHORT);
                }
            });
        }

        @Override
        public void onNetworkQualityProbeTest(AliRtcEngine.AliRtcNetworkQuality quality){
            handler.post(new Runnable() {
                @Override
                public void run() {
                    String msg = "OnNetworkQualityProbeTest quality: " + getNetworkQualityString(quality);
                    mTestNetworkTextView.append(msg + "\n");
                }
            });
        }

        @Override
        public void onNetworkQualityProbeTestResult(int code, AliRtcEngine.AlirtcNetworkQualityProbeResult result){
            handler.post(new Runnable() {
                @Override
                public void run() {
                    StringBuilder msg = new StringBuilder();
                    msg.append("网络质量测试结果:\n");
                    msg.append("  状态码: ").append(code).append("\n");
                    msg.append("  往返延迟(RTT): ").append(result.rtt).append(" ms\n");
                    msg.append("  上行丢包率: ").append(result.uplinkPacketLossRate).append("%\n");
                    msg.append("  上行抖动: ").append(result.upLinkJitter).append(" ms\n");
                    msg.append("  上行带宽: ").append(result.upLinkAvailableBandwidth).append(" kbps\n");
                    msg.append("  下行丢包率: ").append(result.downLinkPacketLossRate).append("%\n");
                    msg.append("  下行抖动: ").append(result.downLinkJitter).append(" ms\n");
                    msg.append("  下行带宽: ").append(result.downLinkAvailableBandwidth).append(" kbps\n");
                    mTestNetworkTextView.append(msg);
                    scrollToBottom(mTestNetworkTextView);
                }
            });
        }

        private String getNetworkQualityString(AliRtcEngine.AliRtcNetworkQuality quality) {
            switch (quality) {
                case AliRtcNetworkExcellent:
                    return "极好";
                case AliRtcNetworkGood:
                    return "好";
                case AliRtcNetworkPoor:
                    return "不好";
                case AliRtcNetworkBad:
                    return "差";
                case AliRtcNetworkVeryBad:
                    return "极差";
                case AliRtcNetworkDisconnected:
                    return "断开";
                case AliRtcNetworkUnknow:
                default:
                    return "未知";
            }
        }
    };

    private AliRtcEngineNotify mRtcEngineNotify = new AliRtcEngineNotify() {
        @Override
        public void onAuthInfoWillExpire() {
            super.onAuthInfoWillExpire();
            /* TODO: 务必处理；Token即将过期，需要业务触发重新获取当前channel，user的鉴权信息，然后设置refreshAuthInfo即可 */
        }

        @Override
        public void onRemoteUserOnLineNotify(String uid, int elapsed){
            super.onRemoteUserOnLineNotify(uid, elapsed);
        }

        //在onRemoteUserOffLineNotify回调中解除远端视频流渲染控件的设置
        @Override
        public void onRemoteUserOffLineNotify(String uid, AliRtcEngine.AliRtcUserOfflineReason reason){
            super.onRemoteUserOffLineNotify(uid, reason);
        }

        //在onRemoteTrackAvailableNotify回调中设置远端视频流渲染控件
        @Override
        public void onRemoteTrackAvailableNotify(String uid, AliRtcEngine.AliRtcAudioTrack audioTrack, AliRtcEngine.AliRtcVideoTrack videoTrack){
            handler.post(new Runnable() {
                @Override
                public void run() {
                    if(videoTrack == AliRtcVideoTrackCamera){
                        viewRemoteVideo(uid, AliRtcVideoTrackCamera);
                        removeRemoteVideo(uid, AliRtcVideoTrackScreen);
                    } else if(videoTrack == AliRtcVideoTrackScreen) {
                        viewRemoteVideo(uid, AliRtcVideoTrackScreen);
                        removeRemoteVideo(uid, AliRtcVideoTrackCamera);
                    } else if (videoTrack == AliRtcVideoTrackBoth) {
                        viewRemoteVideo(uid, AliRtcVideoTrackCamera);
                        viewRemoteVideo(uid, AliRtcVideoTrackScreen);
                    } else if(videoTrack == AliRtcVideoTrackNo) {
                        removeAllRemoteVideo(uid);
                    }
                }
            });
        }

        /* 业务可能会触发同一个UserID的不同设备抢占的情况，所以这个地方也需要处理 */
        @Override
        public void onBye(int code){
            handler.post(new Runnable() {
                @Override
                public void run() {
                    String msg = "onBye code:" + code;
                    ToastHelper.showToast(PreJoinChannelTestActivity.this, msg, Toast.LENGTH_SHORT);
                }
            });
        }

    };

    private void destroyRtcEngine() {
        if( mAliRtcEngine != null) {
            mAliRtcEngine.stopPreview();
            mAliRtcEngine.setLocalViewConfig(null, AliRtcVideoTrackCamera);
            mAliRtcEngine.leaveChannel();
            mAliRtcEngine.destroy();
            mAliRtcEngine = null;

            handler.post(() -> {
                ToastHelper.showToast(this, "Leave Channel", Toast.LENGTH_SHORT);
            });
        }
        hasJoined = false;
        for (ViewGroup value : remoteViews.values()) {
            value.removeAllViews();
        }
        remoteViews.clear();
        gridVideoContainer.removeAllViews();
        mLocalVideoCanvas = null;
    }
}
