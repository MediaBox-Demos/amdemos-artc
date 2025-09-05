package com.aliyun.artc.api.advancedusage.PictureInPicture;

import static com.alivc.rtc.AliRtcEngine.AliRtcVideoEncoderOrientationMode.AliRtcVideoEncoderOrientationModeAdaptive;
import static com.alivc.rtc.AliRtcEngine.AliRtcVideoTrack.AliRtcVideoTrackBoth;
import static com.alivc.rtc.AliRtcEngine.AliRtcVideoTrack.AliRtcVideoTrackCamera;
import static com.alivc.rtc.AliRtcEngine.AliRtcVideoTrack.AliRtcVideoTrackNo;
import static com.alivc.rtc.AliRtcEngine.AliRtcVideoTrack.AliRtcVideoTrackScreen;

import android.app.Activity;
import android.app.PictureInPictureParams;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.res.Configuration;
import android.graphics.Color;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;
import android.util.Log;
import android.util.Rational;
import android.view.Gravity;
import android.view.MenuItem;
import android.view.SurfaceView;
import android.view.View;
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
import com.aliyun.artc.api.advancedusage.R;
import com.aliyun.artc.api.keycenter.ARTCTokenHelper;
import com.aliyun.artc.api.keycenter.GlobalConfig;
import com.aliyun.artc.api.keycenter.utils.ToastHelper;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 画中画功能
 */
public class PictureInPictureAcitivity extends AppCompatActivity {
    private static final String TAG = PictureInPictureAcitivity.class.getSimpleName();
    private Handler handler;
    private EditText mChannelEditText;
    private TextView mJoinChannelTextView;
    private TextView mPipButton;
    private boolean hasJoined = false;

    private AliRtcEngine mAliRtcEngine = null;
    private AliRtcEngine.AliRtcVideoCanvas mLocalVideoCanvas = null;
    private GridLayout gridVideoContainer;
    private final Map<String, FrameLayout> remoteViews = new ConcurrentHashMap<>();

    // PIP模式下用于显示主视频的容器
    private FrameLayout mPipVideoContainer;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        handler = new Handler(Looper.getMainLooper());
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_picture_in_picture);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.video_pip), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });
        setTitle(getString(R.string.picture_in_picture));
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);

        gridVideoContainer = findViewById(R.id.grid_video_container);

        mChannelEditText = findViewById(R.id.channel_id_input);
        mChannelEditText.setText(GlobalConfig.getInstance().gerRandomChannelId());
        mJoinChannelTextView = findViewById(R.id.join_room_btn);
        mJoinChannelTextView.setOnClickListener(v -> {
            if(hasJoined) {
                destroyRtcEngine();
                mJoinChannelTextView.setText(R.string.video_chat_join_channel);
            } else {
                startRTCCall();
            }
        });

        mPipButton = findViewById(R.id.tv_pip);
        mPipButton.setOnClickListener(v -> {enterPIPMode();});
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (mAliRtcEngine != null) {
            destroyRtcEngine();
        }
    }
    // 可选: 点击Home键自动进入画中画
    @Override
    protected void onUserLeaveHint() {
        super.onUserLeaveHint();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            if(hasJoined && !isInPictureInPictureMode()) {
                enterPIPMode();
            }
        }
    }

    /**
     * 进入画中画模式
     */
    private void enterPIPMode(){
        if(!hasJoined) {
            ToastHelper.showToast(this, "请先加入频道", Toast.LENGTH_SHORT);
            return;
        }
        if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if(getPackageManager().hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)) {
                Rational aspectRatio = new Rational(9, 16); // 推荐视频比例
                PictureInPictureParams params = new PictureInPictureParams.Builder()
                        .setAspectRatio(aspectRatio)
                        .build();
                enterPictureInPictureMode(params);
            } else {
                ToastHelper.showToast(this, "设备不支持画中画", Toast.LENGTH_SHORT);
            }
        } else {
            ToastHelper.showToast(this, "Android 8.0 以上才支持画中画", Toast.LENGTH_SHORT);
        }
    }

    public static void startActionActivity(Activity activity) {
        Intent intent = new Intent(activity, PictureInPictureAcitivity.class);
        activity.startActivity(intent);
    }

    /**
     * 响应画中画状态变化
     */
    @Override
    public void onPictureInPictureModeChanged(boolean isInPictureInPictureMode, Configuration newConfig) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig);
        if (isInPictureInPictureMode) {
            // 进入 PIP：隐藏 全屏UI，只保留视频
            findViewById(R.id.ll_channel_layout).setVisibility(View.GONE);
            findViewById(R.id.scroll_remote_container).setVisibility(View.GONE);

            // 可选：隐藏状态栏
            getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_LOW_PROFILE);

            // 可选：创建专用 PIP 视频容器
            showPipVideoContainer();
        } else {
            // 退出 PIP：恢复 全屏UI
            findViewById(R.id.ll_channel_layout).setVisibility(View.VISIBLE);
            findViewById(R.id.scroll_remote_container).setVisibility(View.VISIBLE);
            getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_VISIBLE);

            // 重新绑定本地预览视图
            if (mAliRtcEngine != null && mLocalVideoCanvas != null) {
                mAliRtcEngine.setLocalViewConfig(mLocalVideoCanvas, AliRtcVideoTrackCamera);
            }

            // 移除 PIP 容器
            removePipVideoContainer();
        }
    }

    /**
     * 显示 PIP 模式下的主视频容器（例如本地预览）
     */
    private void showPipVideoContainer() {
        if (mPipVideoContainer == null) {
            mPipVideoContainer = new FrameLayout(this);
            mPipVideoContainer.setBackgroundColor(Color.BLACK);
            addContentView(mPipVideoContainer, new ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT));

            // 重新创建本地预览视图（不能移动 SurfaceView，只能重建）
            SurfaceView surfaceView = mAliRtcEngine.createRenderSurfaceView(this);
            surfaceView.setZOrderOnTop(true);
            surfaceView.setZOrderMediaOverlay(true);

            mPipVideoContainer.addView(surfaceView, new FrameLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT));

            if(mAliRtcEngine != null) {
                AliRtcEngine.AliRtcVideoCanvas canvas = new AliRtcEngine.AliRtcVideoCanvas();
                canvas.view = surfaceView;
                mAliRtcEngine.setLocalViewConfig(canvas, AliRtcVideoTrackCamera);
            }
        }
    }

    /**
     * 移除 PIP 视频容器
     */
    private void removePipVideoContainer() {
        if (mPipVideoContainer != null && mPipVideoContainer.getParent() != null) {
            ((ViewGroup) mPipVideoContainer.getParent()).removeView(mPipVideoContainer);
            mPipVideoContainer = null;
        }
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
        aliRtcVideoEncoderConfiguration.dimensions = new AliRtcEngine.AliRtcVideoDimensions(
                720, 1280);
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
            Log.e(TAG, "channelId is empty");
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
                        ToastHelper.showToast(PictureInPictureAcitivity.this, R.string.video_chat_connection_failed, Toast.LENGTH_SHORT);
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
                    ToastHelper.showToast(PictureInPictureAcitivity.this, str, Toast.LENGTH_SHORT);
                }
            });
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
                    ToastHelper.showToast(PictureInPictureAcitivity.this, msg, Toast.LENGTH_SHORT);
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

