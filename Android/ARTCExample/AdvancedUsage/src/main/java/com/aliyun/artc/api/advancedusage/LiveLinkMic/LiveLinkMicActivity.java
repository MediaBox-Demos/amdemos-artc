package com.aliyun.artc.api.advancedusage.LiveLinkMic;

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
import android.util.Log;
import android.view.Gravity;
import android.view.MenuItem;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.GridLayout;
import android.widget.LinearLayout;
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
import com.alivc.rtc.AliRtcLiveTranscodingParam;
import com.aliyun.artc.api.advancedusage.R;
import com.aliyun.artc.api.keycenter.ARTCTokenHelper;
import com.aliyun.artc.api.keycenter.GlobalConfig;
import com.aliyun.artc.api.keycenter.utils.ToastHelper;

import java.util.Map;
import java.util.Objects;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 直播连麦示例：
 * - 主播 / 连麦观众加入同一频道，实现实时互动
 * - 展示本地 + 多路远端视频
 * - 支持跨频道订阅（模拟主播PK场景）
 */
public class LiveLinkMicActivity extends AppCompatActivity {

    private static final String TAG = "LiveLinkMic";

    private Handler handler;
    private EditText mChannelEditText;
    private TextView mJoinChannelTextView;

    // 角色选择：主播 / 连麦观众
    private TextView mAnchorRoleTextView;
    private TextView mGuestRoleTextView;
    private boolean isAnchorRole = true;

    // 跨频道订阅相关
    private LinearLayout mCrossChannelLayout;
    private EditText mPeerChannelEditText;
    private EditText mPeerUidEditText;
    private TextView mPkSubscribeBtn;
    private boolean isSubscribingPeer = false;

    // CDN旁路转推相关
    private LinearLayout mPublishLiveStreamLayout;
    private EditText mStreamUrlEditText;
    private TextView mStartPublishBtn;
    private TextView mStopPublishBtn;
    private boolean isPublishingLive = false;
    private String mCurrentLiveStreamUrl = null;

    private AliRtcEngine mAliRtcEngine = null;
    private AliRtcEngine.AliRtcVideoCanvas mLocalVideoCanvas = null;
    private GridLayout mGridVideoContainer;
    private final Map<String, FrameLayout> remoteViews = new ConcurrentHashMap<>();

    private final String mPushUrl = "";

    private boolean hasJoined = false;

    public static void startActionActivity(Activity activity) {
        Intent intent = new Intent(activity, LiveLinkMicActivity.class);
        activity.startActivity(intent);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        handler = new Handler(Looper.getMainLooper());
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_live_link_mic);

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.live_link_mic_root), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });

        setTitle(getString(R.string.live_link_mic));
        Objects.requireNonNull(getSupportActionBar()).setDisplayHomeAsUpEnabled(true);

        mGridVideoContainer = findViewById(R.id.grid_video_container);

        mChannelEditText = findViewById(R.id.channel_id_input);
        mChannelEditText.setText(GlobalConfig.getInstance().gerRandomChannelId());

        mJoinChannelTextView = findViewById(R.id.join_room_btn);
        mJoinChannelTextView.setOnClickListener(v -> {
            if (hasJoined) {
                destroyRtcEngine();
                mJoinChannelTextView.setText(R.string.video_chat_join_channel);
            } else {
                startRTCCall();
            }
        });

        // 角色选择
        mAnchorRoleTextView = findViewById(R.id.role_anchor_btn);
        mGuestRoleTextView = findViewById(R.id.role_guest_btn);

        // 跨频道订阅控件（先初始化，再设置点击事件）
        mCrossChannelLayout = findViewById(R.id.ll_cross_channel_subscribe);
        mPeerChannelEditText = findViewById(R.id.peer_channel_input);
        mPeerUidEditText = findViewById(R.id.peer_uid_input);
        mPkSubscribeBtn = findViewById(R.id.btn_start_pk_subscribe);

        // CDN旁路转推控件
        mPublishLiveStreamLayout = findViewById(R.id.ll_publish_live_stream);
        mStreamUrlEditText = findViewById(R.id.stream_url_input);
        mStartPublishBtn = findViewById(R.id.btn_start_publish);
        mStopPublishBtn = findViewById(R.id.btn_stop_publish);
        
        // 设置默认推流URL
        mStreamUrlEditText.setText(mPushUrl);

        mAnchorRoleTextView.setOnClickListener(v -> {
            if (!hasJoined) {
                isAnchorRole = true;
                updateRoleUI();
            }
        });
        mGuestRoleTextView.setOnClickListener(v -> {
            if (!hasJoined) {
                isAnchorRole = false;
                updateRoleUI();
            }
        });
        
        mPkSubscribeBtn.setOnClickListener(v -> {
            if (isSubscribingPeer) {
                stopCrossChannelSubscribe();
            } else {
                startCrossChannelSubscribe();
            }
        });

        mStartPublishBtn.setOnClickListener(v -> startLiveStreaming());
        mStopPublishBtn.setOnClickListener(v -> stopLiveStreaming());

        // 初始化角色 UI
        updateRoleUI();
    }

    private void updateRoleUI() {
        if (isAnchorRole) {
            mAnchorRoleTextView.setBackgroundResource(R.drawable.bg_role_selected);
            mAnchorRoleTextView.setTextColor(Color.WHITE);
            mGuestRoleTextView.setBackgroundResource(R.drawable.bg_role_unselected);
            mGuestRoleTextView.setTextColor(getResources().getColor(R.color.text_gray));
        } else {
            mAnchorRoleTextView.setBackgroundResource(R.drawable.bg_role_unselected);
            mAnchorRoleTextView.setTextColor(getResources().getColor(R.color.text_gray));
            mGuestRoleTextView.setBackgroundResource(R.drawable.bg_role_selected);
            mGuestRoleTextView.setTextColor(Color.WHITE);
        }
        updateCrossChannelVisibility();
    }

    private void updateCrossChannelVisibility() {
        // 只有主播角色才显示跨频道订阅功能和CDN旁路转推功能
        mCrossChannelLayout.setVisibility(isAnchorRole ? View.VISIBLE : View.GONE);
        mPublishLiveStreamLayout.setVisibility(isAnchorRole ? View.VISIBLE : View.GONE);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        destroyRtcEngine();
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        if (item.getItemId() == android.R.id.home) {
            destroyRtcEngine();
            finish();
            return true;
        }
        return super.onOptionsItemSelected(item);
    }

    // ==================== 入会流程 ====================

    private void startRTCCall() {
        if (hasJoined) {
            return;
        }
        initAndSetupRtcEngine();
        startPreview();
        joinChannel();
    }

    private void initAndSetupRtcEngine() {
        if (mAliRtcEngine == null) {
            mAliRtcEngine = AliRtcEngine.getInstance(this);
        }
        mAliRtcEngine.setRtcEngineEventListener(mRtcEngineEventListener);
        mAliRtcEngine.setRtcEngineNotify(mRtcEngineNotify);

        // 互动直播 + 互动角色
        mAliRtcEngine.setChannelProfile(AliRtcEngine.AliRTCSdkChannelProfile.AliRTCSdkInteractiveLive);
        mAliRtcEngine.setClientRole(AliRtcEngine.AliRTCSdkClientRole.AliRTCSdkInteractive);

        mAliRtcEngine.setAudioProfile(
                AliRtcEngine.AliRtcAudioProfile.AliRtcEngineHighQualityMode,
                AliRtcEngine.AliRtcAudioScenario.AliRtcSceneMusicMode);
        mAliRtcEngine.setCapturePipelineScaleMode(
                AliRtcEngine.AliRtcCapturePipelineScaleMode.AliRtcCapturePipelineScaleModePost);

        // 视频编码参数
        AliRtcEngine.AliRtcVideoEncoderConfiguration config =
                new AliRtcEngine.AliRtcVideoEncoderConfiguration();
        config.dimensions = new AliRtcEngine.AliRtcVideoDimensions(720, 1280);
        config.frameRate = 20;
        config.bitrate = 1200;
        config.keyFrameInterval = 2000;
        config.orientationMode =
                AliRtcEngine.AliRtcVideoEncoderOrientationMode.AliRtcVideoEncoderOrientationModeAdaptive;
        mAliRtcEngine.setVideoEncoderConfiguration(config);

        // 发布本地流
        mAliRtcEngine.publishLocalAudioStream(true);
        mAliRtcEngine.publishLocalVideoStream(true);

        // 默认订阅远端音视频
        mAliRtcEngine.setDefaultSubscribeAllRemoteAudioStreams(true);
        mAliRtcEngine.subscribeAllRemoteAudioStreams(true);
        mAliRtcEngine.setDefaultSubscribeAllRemoteVideoStreams(true);
        mAliRtcEngine.subscribeAllRemoteVideoStreams(true);
    }

    private void startPreview() {
        if (mAliRtcEngine == null) {
            return;
        }
        FrameLayout localVideoFrame = createVideoView("local");
        mGridVideoContainer.addView(localVideoFrame);

        SurfaceView localSurfaceView = mAliRtcEngine.createRenderSurfaceView(this);
        localSurfaceView.setZOrderOnTop(true);
        localSurfaceView.setZOrderMediaOverlay(true);

        localVideoFrame.addView(localSurfaceView, new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT));

        String roleLabel = isAnchorRole ? "Anchor(local)" : "Guest(local)";
        addUserIdLabel(localVideoFrame, roleLabel);

        mLocalVideoCanvas = new AliRtcEngine.AliRtcVideoCanvas();
        mLocalVideoCanvas.view = localSurfaceView;
        mAliRtcEngine.setLocalViewConfig(mLocalVideoCanvas, AliRtcVideoTrackCamera);
        mAliRtcEngine.startPreview();
    }

    private void joinChannel() {
        String channelId = mChannelEditText.getText().toString();
        if (TextUtils.isEmpty(channelId)) {
            ToastHelper.showToast(this, "ChannelID is empty", Toast.LENGTH_SHORT);
            return;
        }
        String userId = GlobalConfig.getInstance().getUserId();
        String appId = ARTCTokenHelper.AppId;
        String appKey = ARTCTokenHelper.AppKey;
        long timestamp = ARTCTokenHelper.getTimesTamp();
        String token = ARTCTokenHelper.generateSingleParameterToken(
                appId, appKey, channelId, userId, timestamp);
        mAliRtcEngine.joinChannel(token, null, null, null);
        hasJoined = true;

        // 入会后启用跨频道订阅和旁路转推按钮
        handler.post(() -> {
            mPkSubscribeBtn.setEnabled(true);
            mPkSubscribeBtn.setAlpha(1.0f);
            mStartPublishBtn.setEnabled(true);
            mStartPublishBtn.setAlpha(1.0f);
        });
    }

    private void handleJoinResult(int result, String channel, String userId) {
        handler.post(() -> {
            String roleText = isAnchorRole ? "Anchor" : "Guest";
            String str;
            if (result == 0) {
                str = roleText + " " + userId + " Join " + channel + " Success";
            } else {
                str = roleText + " " + userId + " Join " + channel + " Failed! error: " + result;
            }
            ToastHelper.showToast(this, str, Toast.LENGTH_SHORT);
            mJoinChannelTextView.setText(R.string.leave_channel);
        });
    }

    // ==================== 跨频道订阅功能（主播PK演示） ====================

    /**
     * 开始跨频道订阅
     * 模拟主播PK场景：订阅另一个频道中指定用户的音视频流
     */
    private void startCrossChannelSubscribe() {
        if (mAliRtcEngine == null) {
            ToastHelper.showToast(this, "RTC引擎未初始化", Toast.LENGTH_SHORT);
            return;
        }

        String peerChannelId = mPeerChannelEditText.getText().toString().trim();
        String peerUid = mPeerUidEditText.getText().toString().trim();

        if (TextUtils.isEmpty(peerChannelId)) {
            ToastHelper.showToast(this, "请输入目标频道ID", Toast.LENGTH_SHORT);
            return;
        }

        if (TextUtils.isEmpty(peerUid)) {
            ToastHelper.showToast(this, "请输入目标用户ID", Toast.LENGTH_SHORT);
            return;
        }

        try {
            Log.i(TAG, "开始跨频道订阅: channelId=" + peerChannelId + ", uid=" + peerUid);

            // 调用跨频道订阅接口
            // Android SDK: subscribeRemoteDestChannelStream(channelId, uid, videoTrack, audioTrack, sub)
            int ret = mAliRtcEngine.subscribeRemoteDestChannelStream(
                    peerChannelId,                                    // 目标频道
                    peerUid,                                          // 目标用户
                    AliRtcVideoTrackCamera,                           // 订阅相机流
                    AliRtcEngine.AliRtcAudioTrack.AliRtcAudioTrackMic,    // 订阅麦克风流
                    true                                              // 开始订阅
            );

            if (ret == 0) {
                isSubscribingPeer = true;
                handler.post(() -> {
                    mPkSubscribeBtn.setText(R.string.stop_pk_subscribe);
                    mPeerChannelEditText.setEnabled(false);
                    mPeerUidEditText.setEnabled(false);
                    ToastHelper.showToast(this, 
                            "开始PK订阅: " + peerChannelId + "/" + peerUid, 
                            Toast.LENGTH_SHORT);
                });
                Log.i(TAG, "跨频道订阅请求成功");
            } else {
                String errorMsg = "跨频道订阅失败, ret=" + ret;
                handler.post(() -> ToastHelper.showToast(this, errorMsg, Toast.LENGTH_SHORT));
                Log.e(TAG, errorMsg);
            }

        } catch (Exception e) {
            Log.e(TAG, "跨频道订阅异常", e);
            handler.post(() -> ToastHelper.showToast(this, "跨频道订阅异常", Toast.LENGTH_SHORT));
        }
    }

    /**
     * 停止跨频道订阅
     */
    private void stopCrossChannelSubscribe() {
        if (mAliRtcEngine == null) {
            return;
        }

        String peerChannelId = mPeerChannelEditText.getText().toString().trim();
        String peerUid = mPeerUidEditText.getText().toString().trim();

        if (TextUtils.isEmpty(peerChannelId) || TextUtils.isEmpty(peerUid)) {
            return;
        }

        try {
            Log.i(TAG, "停止跨频道订阅: channelId=" + peerChannelId + ", uid=" + peerUid);

            // 取消订阅
            // Android SDK: subscribeRemoteDestChannelStream(channelId, uid, videoTrack, audioTrack, sub)
            int ret = mAliRtcEngine.subscribeRemoteDestChannelStream(
                    peerChannelId,
                    peerUid,
                    AliRtcVideoTrackNo,                                   // 不订阅视频
                    AliRtcEngine.AliRtcAudioTrack.AliRtcAudioTrackNo,    // 不订阅音频
                    false                                                 // 停止订阅
            );

            Log.i(TAG, "停止跨频道订阅结果: ret=" + ret);

            // 移除远端画面
            removeAllRemoteVideo(peerUid);

            isSubscribingPeer = false;
            handler.post(() -> {
                mPkSubscribeBtn.setText(R.string.start_pk_subscribe);
                mPeerChannelEditText.setEnabled(true);
                mPeerUidEditText.setEnabled(true);
                ToastHelper.showToast(this, "已停止PK订阅", Toast.LENGTH_SHORT);
            });

        } catch (Exception e) {
            Log.e(TAG, "停止跨频道订阅异常", e);
            handler.post(() -> ToastHelper.showToast(this, "停止订阅异常", Toast.LENGTH_SHORT));
        }
    }

    // ==================== CDN旁路转推功能（主播专用）====================

    /**
     * 开始旁路转推
     */
    private void startLiveStreaming() {
        if (mAliRtcEngine == null) {
            ToastHelper.showToast(this, "RTC引擎未初始化", Toast.LENGTH_SHORT);
            return;
        }

        String streamUrl = mStreamUrlEditText.getText().toString().trim();
        if (TextUtils.isEmpty(streamUrl)) {
            ToastHelper.showToast(this, "请输入推流地址", Toast.LENGTH_SHORT);
            return;
        }

        try {
            Log.i(TAG, "开始旁路转推: url=" + streamUrl);

            AliRtcLiveTranscodingParam transcodingParam = new AliRtcLiveTranscodingParam();
            int ret = mAliRtcEngine.startPublishLiveStream(streamUrl, transcodingParam);

            if (ret == 0) {
                isPublishingLive = true;
                mCurrentLiveStreamUrl = streamUrl;
                handler.post(() -> {
                    mStartPublishBtn.setEnabled(false);
                    mStartPublishBtn.setAlpha(0.5f);
                    mStopPublishBtn.setEnabled(true);
                    mStopPublishBtn.setAlpha(1.0f);
                    ToastHelper.showToast(this, "开始旁路: " + streamUrl, Toast.LENGTH_SHORT);
                });
                Log.i(TAG, "旁路转推启动成功");
            } else {
                handler.post(() -> 
                    ToastHelper.showToast(this, "旁路转推失败, ret=" + ret, Toast.LENGTH_SHORT)
                );
                Log.e(TAG, "旁路转推失败, ret=" + ret);
            }

        } catch (Exception e) {
            Log.e(TAG, "旁路转推异常", e);
            handler.post(() -> ToastHelper.showToast(this, "旁路转推异常", Toast.LENGTH_SHORT));
        }
    }

    /**
     * 停止旁路转推
     */
    private void stopLiveStreaming() {
        if (mAliRtcEngine == null) {
            return;
        }

        if (!isPublishingLive || TextUtils.isEmpty(mCurrentLiveStreamUrl)) {
            return;
        }

        try {
            Log.i(TAG, "停止旁路转推: url=" + mCurrentLiveStreamUrl);

            String streamUrl = mCurrentLiveStreamUrl;
            int ret = mAliRtcEngine.stopPublishLiveStream(streamUrl);

            Log.i(TAG, "停止旁路转推结果: ret=" + ret);

            isPublishingLive = false;
            mCurrentLiveStreamUrl = null;
            handler.post(() -> {
                mStartPublishBtn.setEnabled(true);
                mStartPublishBtn.setAlpha(1.0f);
                mStopPublishBtn.setEnabled(false);
                mStopPublishBtn.setAlpha(0.5f);
                ToastHelper.showToast(this, "已停止旁路", Toast.LENGTH_SHORT);
            });

        } catch (Exception e) {
            Log.e(TAG, "停止旁路转推异常", e);
            handler.post(() -> ToastHelper.showToast(this, "停止旁路异常", Toast.LENGTH_SHORT));
        }
    }

    // ==================== 远端视频视图管理 ====================

    private String getStreamKey(String uid, AliRtcEngine.AliRtcVideoTrack videoTrack) {
        return uid + "_" + videoTrack.name();
    }

    private FrameLayout createVideoView(String tag) {
        FrameLayout view = new FrameLayout(this);
        int sizeInDp = 180;
        int sizeInPx = (int) (getResources().getDisplayMetrics().density * sizeInDp);

        GridLayout.LayoutParams params = new GridLayout.LayoutParams();
        params.width = 0;
        params.height = sizeInPx;
        params.columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f);
        params.setMargins(8, 8, 8, 8);

        view.setLayoutParams(params);
        view.setTag(tag);
        view.setBackgroundColor(Color.BLACK);
        return view;
    }

    private void addUserIdLabel(FrameLayout layoutView, String userId) {
        TextView userIdTextView = new TextView(this);
        userIdTextView.setText(userId);
        userIdTextView.setTextColor(Color.WHITE);
        userIdTextView.setBackgroundColor(Color.parseColor("#80000000"));
        userIdTextView.setPadding(10, 10, 10, 10);

        FrameLayout.LayoutParams textParams = new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT);
        textParams.leftMargin = 20;
        textParams.topMargin = 20;
        textParams.gravity = Gravity.TOP | Gravity.START;

        layoutView.addView(userIdTextView, textParams);
    }

    private void viewRemoteVideo(String uid, AliRtcEngine.AliRtcVideoTrack videoTrack) {
        String streamKey = getStreamKey(uid, videoTrack);
        FrameLayout view;
        if (remoteViews.containsKey(streamKey)) {
            view = remoteViews.get(streamKey);
            if (view != null) {
                view.removeAllViews();
            } else {
                view = createVideoView(streamKey);
                mGridVideoContainer.addView(view);
                remoteViews.put(streamKey, view);
            }
        } else {
            view = createVideoView(streamKey);
            mGridVideoContainer.addView(view);
            remoteViews.put(streamKey, view);
        }

        SurfaceView surfaceView = mAliRtcEngine.createRenderSurfaceView(this);
        surfaceView.setZOrderMediaOverlay(true);
        view.addView(surfaceView, new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT));

        String trackName = (videoTrack == AliRtcVideoTrackScreen) ? "Screen" : "Camera";
        addUserIdLabel(view, uid + " - " + trackName);

        AliRtcEngine.AliRtcVideoCanvas videoCanvas = new AliRtcEngine.AliRtcVideoCanvas();
        videoCanvas.view = surfaceView;
        mAliRtcEngine.setRemoteViewConfig(videoCanvas, uid, videoTrack);
    }

    private void removeRemoteVideo(String uid, AliRtcEngine.AliRtcVideoTrack videoTrack) {
        String streamKey = getStreamKey(uid, videoTrack);
        FrameLayout frameLayout = remoteViews.remove(streamKey);
        if (frameLayout != null) {
            frameLayout.removeAllViews();
            mGridVideoContainer.removeView(frameLayout);
            Log.d(TAG, "Removed video stream for: " + streamKey);
        }
    }

    private void removeAllRemoteVideo(String uid) {
        removeRemoteVideo(uid, AliRtcVideoTrackCamera);
        removeRemoteVideo(uid, AliRtcVideoTrackScreen);
    }

    // ==================== 回调 ====================

    private final AliRtcEngineEventListener mRtcEngineEventListener = new AliRtcEngineEventListener() {
        @Override
        public void onJoinChannelResult(int result, String channel, String userId, int elapsed) {
            super.onJoinChannelResult(result, channel, userId, elapsed);
            handleJoinResult(result, channel, userId);
        }

        @Override
        public void onLeaveChannelResult(int result, AliRtcEngine.AliRtcStats stats) {
            super.onLeaveChannelResult(result, stats);
        }

        @Override
        public void onConnectionStatusChange(AliRtcEngine.AliRtcConnectionStatus status,
                                             AliRtcEngine.AliRtcConnectionStatusChangeReason reason) {
            super.onConnectionStatusChange(status, reason);
            handler.post(() -> {
                if (status == AliRtcEngine.AliRtcConnectionStatus.AliRtcConnectionStatusFailed) {
                    ToastHelper.showToast(LiveLinkMicActivity.this,
                            R.string.video_chat_connection_failed, Toast.LENGTH_SHORT);
                }
            });
        }

        @Override
        public void OnLocalDeviceException(AliRtcEngine.AliRtcEngineLocalDeviceType deviceType,
                                           AliRtcEngine.AliRtcEngineLocalDeviceExceptionType exceptionType,
                                           String msg) {
            super.OnLocalDeviceException(deviceType, exceptionType, msg);
            handler.post(() -> {
                String str = "OnLocalDeviceException deviceType: " + deviceType
                        + " exceptionType: " + exceptionType + " msg: " + msg;
                ToastHelper.showToast(LiveLinkMicActivity.this, str, Toast.LENGTH_SHORT);
            });
        }
    };

    private final AliRtcEngineNotify mRtcEngineNotify = new AliRtcEngineNotify() {
        @Override
        public void onRemoteUserOnLineNotify(String uid, int elapsed) {
            super.onRemoteUserOnLineNotify(uid, elapsed);
            handler.post(() -> {
                String roleText = isAnchorRole ? "观众" : "主播/观众";
                ToastHelper.showToast(LiveLinkMicActivity.this, 
                        roleText + " " + uid + " 加入了", 
                        Toast.LENGTH_SHORT);
            });
        }

        @Override
        public void onRemoteUserOffLineNotify(String uid,
                                              AliRtcEngine.AliRtcUserOfflineReason reason) {
            super.onRemoteUserOffLineNotify(uid, reason);
            handler.post(() -> removeAllRemoteVideo(uid));
        }

        @Override
        public void onRemoteTrackAvailableNotify(String uid,
                                                 AliRtcEngine.AliRtcAudioTrack audioTrack,
                                                 AliRtcEngine.AliRtcVideoTrack videoTrack) {
            handler.post(() -> {
                if (videoTrack == AliRtcVideoTrackCamera) {
                    viewRemoteVideo(uid, AliRtcVideoTrackCamera);
                    removeRemoteVideo(uid, AliRtcVideoTrackScreen);
                } else if (videoTrack == AliRtcVideoTrackScreen) {
                    viewRemoteVideo(uid, AliRtcVideoTrackScreen);
                    removeRemoteVideo(uid, AliRtcVideoTrackCamera);
                } else if (videoTrack == AliRtcVideoTrackBoth) {
                    viewRemoteVideo(uid, AliRtcVideoTrackCamera);
                    viewRemoteVideo(uid, AliRtcVideoTrackScreen);
                } else if (videoTrack == AliRtcVideoTrackNo) {
                    removeAllRemoteVideo(uid);
                }
            });
        }

        @Override
        public void onBye(int code) {
            handler.post(() -> {
                String msg = "onBye code:" + code;
                ToastHelper.showToast(LiveLinkMicActivity.this, msg, Toast.LENGTH_SHORT);
            });
        }
    };

    // ==================== 销毁 ====================

    private void destroyRtcEngine() {
        if (mAliRtcEngine != null) {
            // 离开频道前先停止跨频道订阅
            if (isSubscribingPeer) {
                stopCrossChannelSubscribe();
            }

            // 离开频道前先停止旁路转推
            if (isPublishingLive) {
                stopLiveStreaming();
            }

            mAliRtcEngine.stopPreview();
            mAliRtcEngine.setLocalViewConfig(null, AliRtcVideoTrackCamera);
            mAliRtcEngine.leaveChannel();
            mAliRtcEngine.destroy();
            mAliRtcEngine = null;

            handler.post(() -> ToastHelper.showToast(this,
                    "Leave Channel", Toast.LENGTH_SHORT));
        }
        hasJoined = false;
        isSubscribingPeer = false;
        isPublishingLive = false;
        mCurrentLiveStreamUrl = null;
        
        for (ViewGroup value : remoteViews.values()) {
            value.removeAllViews();
        }
        remoteViews.clear();
        mGridVideoContainer.removeAllViews();
        mLocalVideoCanvas = null;

        // 重置UI状态
        handler.post(() -> {
            mPkSubscribeBtn.setEnabled(false);
            mPkSubscribeBtn.setAlpha(0.5f);
            mPkSubscribeBtn.setText(R.string.start_pk_subscribe);
            mPeerChannelEditText.setEnabled(true);
            mPeerUidEditText.setEnabled(true);
            
            mStartPublishBtn.setEnabled(false);
            mStartPublishBtn.setAlpha(0.5f);
            mStopPublishBtn.setEnabled(false);
            mStopPublishBtn.setAlpha(0.5f);
        });
    }
}
