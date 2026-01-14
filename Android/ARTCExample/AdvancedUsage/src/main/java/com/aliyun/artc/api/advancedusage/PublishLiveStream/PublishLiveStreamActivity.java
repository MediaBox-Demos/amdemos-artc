package com.aliyun.artc.api.advancedusage.PublishLiveStream;

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
import android.util.Log;
import android.view.Gravity;
import android.view.MenuItem;
import android.view.SurfaceView;
import android.view.ViewGroup;
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
import com.alivc.rtc.AliRtcLiveTranscodingParam;
import com.aliyun.artc.api.advancedusage.R;
import com.aliyun.artc.api.keycenter.ARTCTokenHelper;
import com.aliyun.artc.api.keycenter.GlobalConfig;
import com.aliyun.artc.api.keycenter.utils.ToastHelper;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 旁路转推示例
 * 步骤：
 * 1. 输入频道号，点击「Join Channel」入会
 * 2. 在输入框里填入 CDN 推流 URL（streamUrl）
 * 3. 点击「Start Publish」开始旁路，再次点击可停止旁路
 * startPublishLiveStream / stopPublishLiveStream / onPublishLiveStreamStateChanged / onPublishTaskStateChanged
 */
public class PublishLiveStreamActivity extends AppCompatActivity {

    private static final String TAG = "PublishLiveStream";

    private Handler handler;
    private EditText mChannelEditText;
    private TextView mJoinChannelTextView;

    private EditText mStreamUrlEditText;
    private TextView mPublishButton;
    private TextView mUpdateButton;
    private TextView mStopButton;

    private boolean hasJoined = false;

    private AliRtcEngine mAliRtcEngine = null;
    private AliRtcEngine.AliRtcVideoCanvas mLocalVideoCanvas = null;
    private GridLayout gridVideoContainer;
    private final Map<String, FrameLayout> remoteViews = new ConcurrentHashMap<>();

    private boolean isPublishingLive = false;
    private String mCurrentLiveStreamUrl = null;

    private String mPushUrl = "";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        handler = new Handler(Looper.getMainLooper());
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_publish_live_stream);

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.publish_live_stream_root), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });

        setTitle(getString(R.string.publish_live_stream));
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);

        gridVideoContainer = findViewById(R.id.grid_video_container);

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

        mStreamUrlEditText = findViewById(R.id.stream_url_input);
        mStreamUrlEditText.setText(mPushUrl);
        mPublishButton = findViewById(R.id.btn_start_publish);
        mUpdateButton = findViewById(R.id.btn_update_publish);
        mStopButton = findViewById(R.id.btn_stop_publish);

        mPublishButton.setOnClickListener(v -> {
            if (!hasJoined) {
                ToastHelper.showToast(PublishLiveStreamActivity.this,
                        "Please join channel first", Toast.LENGTH_SHORT);
                return;
            }
            startLiveStreaming();
        });

        mUpdateButton.setOnClickListener(v -> {
            if (!hasJoined) {
                ToastHelper.showToast(PublishLiveStreamActivity.this,
                        "Please join channel first", Toast.LENGTH_SHORT);
                return;
            }
            if (!isPublishingLive) {
                ToastHelper.showToast(PublishLiveStreamActivity.this,
                        "Please start publish first", Toast.LENGTH_SHORT);
                return;
            }
            updateLiveStreaming();
        });

        mStopButton.setOnClickListener(v -> {
            if (!isPublishingLive) {
                ToastHelper.showToast(PublishLiveStreamActivity.this,
                        "No active live stream to stop", Toast.LENGTH_SHORT);
                return;
            }
            stopLiveStreaming();
        });
    }

    public static void startActionActivity(Activity activity) {
        Intent intent = new Intent(activity, PublishLiveStreamActivity.class);
        activity.startActivity(intent);
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

    private void handleJoinResult(int result, String channel, String userId) {
        handler.post(() -> {
            String str;
            if (result == 0) {
                str = "User " + userId + " Join " + channel + " Success";
            } else {
                str = "User " + userId + " Join " + channel + " Failed! error: " + result;
            }
            ToastHelper.showToast(this, str, Toast.LENGTH_SHORT);
            ((TextView) findViewById(R.id.join_room_btn)).setText(R.string.leave_channel);
        });
    }

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

        // 频道模式/角色/音频Profile 与其它示例保持一致
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
        config.orientationMode = AliRtcVideoEncoderOrientationModeAdaptive;
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
        if (mAliRtcEngine != null) {
            FrameLayout localVideoFrame = createVideoView("local");
            gridVideoContainer.addView(localVideoFrame);
            SurfaceView localSurfaceView = mAliRtcEngine.createRenderSurfaceView(this);
            localSurfaceView.setZOrderOnTop(true);
            localSurfaceView.setZOrderMediaOverlay(true);

            localVideoFrame.addView(localSurfaceView, new FrameLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT));

            addUserIdLabel(localVideoFrame, "local");

            mLocalVideoCanvas = new AliRtcEngine.AliRtcVideoCanvas();
            mLocalVideoCanvas.view = localSurfaceView;
            mAliRtcEngine.setLocalViewConfig(mLocalVideoCanvas, AliRtcVideoTrackCamera);
            mAliRtcEngine.startPreview();
        }
    }

    private void joinChannel() {
        String channelId = mChannelEditText.getText().toString();
        if (!TextUtils.isEmpty(channelId)) {
            String userId = GlobalConfig.getInstance().getUserId();
            String appId = ARTCTokenHelper.AppId;
            String appKey = ARTCTokenHelper.AppKey;
            long timestamp = ARTCTokenHelper.getTimesTamp();
            String token = ARTCTokenHelper.generateSingleParameterToken(
                    appId, appKey, channelId, userId, timestamp);
            mAliRtcEngine.joinChannel(token, null, null, null);
            hasJoined = true;
        } else {
            Log.e(TAG, "channelId is empty");
        }
    }

    /**
     * 启动旁路直播
     */
    private void startLiveStreaming() {
        if (mAliRtcEngine == null) {
            ToastHelper.showToast(this, getString(R.string.rtc_engine_init_required), Toast.LENGTH_SHORT);
            return;
        }

        String streamUrl = mStreamUrlEditText.getText().toString().trim();
        if (TextUtils.isEmpty(streamUrl)) {
            ToastHelper.showToast(this, "Stream URL is empty", Toast.LENGTH_SHORT);
            return;
        }

        AliRtcLiveTranscodingParam transcodingParam =
                new AliRtcLiveTranscodingParam();

        int ret = mAliRtcEngine.startPublishLiveStream(streamUrl, transcodingParam);
        if (ret == 0) {
            isPublishingLive = true;
            mCurrentLiveStreamUrl = streamUrl;
            updateButtonStates();
            ToastHelper.showToast(this, "Start live stream: " + streamUrl, Toast.LENGTH_SHORT);
        } else {
            ToastHelper.showToast(this, "Start live stream failed, ret=" + ret, Toast.LENGTH_SHORT);
        }
    }

    /**
     * 更新旁路直播参数
     */
    private void updateLiveStreaming() {
        if (mAliRtcEngine == null) {
            return;
        }
        if (!isPublishingLive || TextUtils.isEmpty(mCurrentLiveStreamUrl)) {
            return;
        }

        String streamUrl = mCurrentLiveStreamUrl;
        
        // 创建新的转码参数，这里可以修改参数来演示更新功能
        AliRtcLiveTranscodingParam transcodingParam = new AliRtcLiveTranscodingParam();
        // 可以在这里修改 mixParam/singleParam 来更新旁路参数
        
        int ret = mAliRtcEngine.updatePublishLiveStream(streamUrl, transcodingParam);
        if (ret == 0) {
            ToastHelper.showToast(this, "Update live stream parameters success", Toast.LENGTH_SHORT);
        } else {
            ToastHelper.showToast(this, "Update live stream failed, ret=" + ret, Toast.LENGTH_SHORT);
        }
    }

    /**
     * 停止旁路直播
     */
    private void stopLiveStreaming() {
        if (mAliRtcEngine == null) {
            return;
        }
        if (!isPublishingLive || TextUtils.isEmpty(mCurrentLiveStreamUrl)) {
            return;
        }
        String streamUrl = mCurrentLiveStreamUrl;
        int ret = mAliRtcEngine.stopPublishLiveStream(streamUrl);
        Log.d(TAG, "stopPublishLiveStream url=" + streamUrl + ", ret=" + ret);
        isPublishingLive = false;
        mCurrentLiveStreamUrl = null;
        updateButtonStates();
        ToastHelper.showToast(this, "Stop live stream", Toast.LENGTH_SHORT);
    }

    /**
     * 更新按钮状态
     */
    private void updateButtonStates() {
        handler.post(() -> {
            if (isPublishingLive) {
                mPublishButton.setEnabled(false);
                mPublishButton.setAlpha(0.5f);
                mUpdateButton.setEnabled(true);
                mUpdateButton.setAlpha(1.0f);
                mStopButton.setEnabled(true);
                mStopButton.setAlpha(1.0f);
            } else {
                mPublishButton.setEnabled(true);
                mPublishButton.setAlpha(1.0f);
                mUpdateButton.setEnabled(false);
                mUpdateButton.setAlpha(0.5f);
                mStopButton.setEnabled(false);
                mStopButton.setAlpha(0.5f);
            }
        });
    }

    //=================== 远端视频视图管理 ===================

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
                gridVideoContainer.addView(view);
                remoteViews.put(streamKey, view);
            }
        } else {
            view = createVideoView(streamKey);
            gridVideoContainer.addView(view);
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
            gridVideoContainer.removeView(frameLayout);
            Log.d(TAG, "Removed video stream for: " + streamKey);
        }
    }

    private void removeAllRemoteVideo(String uid) {
        removeRemoteVideo(uid, AliRtcVideoTrackCamera);
        removeRemoteVideo(uid, AliRtcVideoTrackScreen);
    }

    //=================== 回调：包含旁路状态回调（以 streamUrl 为 key） ===================

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
                    ToastHelper.showToast(PublishLiveStreamActivity.this,
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
                ToastHelper.showToast(PublishLiveStreamActivity.this, str, Toast.LENGTH_SHORT);
            });
        }

        @Override
        public void onPublishLiveStreamStateChanged(String streamUrl,
                                                    AliRtcEngine.AliRtcLiveTranscodingState state,
                                                    AliRtcEngine.AliEngineLiveTranscodingErrorCode errCode) {
            super.onPublishLiveStreamStateChanged(streamUrl, state, errCode);
            handler.post(() -> {
                String msg = "LiveStream state: " + streamUrl
                        + " state=" + state
                        + " err=" + errCode;
                ToastHelper.showToast(PublishLiveStreamActivity.this, msg, Toast.LENGTH_SHORT);
            });
        }

        @Override
        public void onPublishTaskStateChanged(String streamUrl,
                                              AliRtcEngine.AliRtcTrascodingPublishTaskStatus state) {
            super.onPublishTaskStateChanged(streamUrl, state);
            handler.post(() -> {
                String msg = "LiveStream task: " + streamUrl + " state=" + state;
                ToastHelper.showToast(PublishLiveStreamActivity.this, msg, Toast.LENGTH_SHORT);
            });
        }
    };

    private final AliRtcEngineNotify mRtcEngineNotify = new AliRtcEngineNotify() {
        @Override
        public void onAuthInfoWillExpire() {
            super.onAuthInfoWillExpire();
            // 这里可以触发刷新 Token
        }

        @Override
        public void onRemoteUserOnLineNotify(String uid, int elapsed) {
            super.onRemoteUserOnLineNotify(uid, elapsed);
        }

        @Override
        public void onRemoteUserOffLineNotify(String uid,
                                              AliRtcEngine.AliRtcUserOfflineReason reason) {
            super.onRemoteUserOffLineNotify(uid, reason);
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
                ToastHelper.showToast(PublishLiveStreamActivity.this, msg, Toast.LENGTH_SHORT);
            });
        }
    };

    private void destroyRtcEngine() {
        if (mAliRtcEngine != null) {
            // 离开频道前先停止旁路
            stopLiveStreaming();

            mAliRtcEngine.stopPreview();
            mAliRtcEngine.setLocalViewConfig(null, AliRtcVideoTrackCamera);
            mAliRtcEngine.leaveChannel();
            mAliRtcEngine.destroy();
            mAliRtcEngine = null;

            handler.post(() -> ToastHelper.showToast(this,
                    "Leave Channel", Toast.LENGTH_SHORT));
        }
        hasJoined = false;
        for (ViewGroup value : remoteViews.values()) {
            value.removeAllViews();
        }
        remoteViews.clear();
        gridVideoContainer.removeAllViews();
        mLocalVideoCanvas = null;
        isPublishingLive = false;
        mCurrentLiveStreamUrl = null;
        updateButtonStates();
    }
}
