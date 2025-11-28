package com.aliyun.artc.api.basicusage.PlayAudioFiles;

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
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.GridLayout;
import android.widget.LinearLayout;
import android.widget.SeekBar;
import android.widget.Spinner;
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
import com.aliyun.artc.api.basicusage.R;
import com.aliyun.artc.api.keycenter.ARTCTokenHelper;
import com.aliyun.artc.api.keycenter.GlobalConfig;
import com.aliyun.artc.api.keycenter.utils.ToastHelper;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 播放或推流本地的伴奏和音效，当前示例主要演示本地文件的播放
 */
public class PlayAudioFilesActivity extends AppCompatActivity {
    private static final String TAG = "PlayAudioFilesActivity";

    private Handler handler;
    private EditText mChannelEditText;
    private Button mJoinChannelBtn;
    private boolean hasJoined = false;

    private AliRtcEngine mAliRtcEngine = null;
    private AliRtcEngine.AliRtcVideoCanvas mLocalVideoCanvas = null;
    private GridLayout gridVideoContainer;
    private final Map<String, FrameLayout> remoteViews = new ConcurrentHashMap<>();

    // 伴奏（背景音乐）—— 同一时间只允许一个
    private String mMixingMusicFilepath = "/assets/music.wav"; // app/src/main/assets/music.wav
    private TextView mMixingMusicFileTextView;
    private SeekBar mMixingVolumeSeekBar;
    private SeekBar mMixingPublishVolumeSeekBar;
    private SeekBar mMixingPlaybackVolumeSeekBar;
    private EditText mMixingLoopCountEditText;
    private Integer mMixingMusicLoopCount = -1; // 默认无限循环
    private SeekBar mMixingPlayPositionSeekBar;
    // 音效——可以同时有多个
    private String mAudioEffectFilePath1 = "/assets/thunder.wav";
    private String mAudioEffectFilePath2 = "/assets/applause.wav";

    private int mCurrSoundID = 1;
    private SeekBar mEffectVolumeSeekBar;
    private Spinner mAudioEffectSpinner;
    private SeekBar mAudioEffectVolumeSeekBar;
    private EditText mAudioEffectLoopCountEditText;
    private SeekBar mAudioEffectVolumeAllSeekBar;

    // 演示根据音频文件路径获取音频文件的时长
    private TextView mAudioFilePathTextView;
    private Button mGetAudioFileDurationBtn;


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        handler = new Handler(Looper.getMainLooper());
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_play_audio_files);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.play_audio_files), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });
        setTitle(getString(R.string.play_audio_files));
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);

        // 获取音频文件时长
        mAudioFilePathTextView = findViewById(R.id.tv_audio_file_path);
        mAudioFilePathTextView.setText(mMixingMusicFilepath);
        mGetAudioFileDurationBtn = findViewById(R.id.btn_get_audio_file_info);
        mGetAudioFileDurationBtn.setOnClickListener(v -> {
            // 获取音频文件时长,结果通过onAudioFileInfo返回
            if(mAliRtcEngine != null) {
                mAliRtcEngine.getAudioFileInfo(mMixingMusicFilepath);
            } else {
                ToastHelper.showToast(this, "请先初始化AliRtcEngine", Toast.LENGTH_SHORT);
            }
        });

        // 处理音频伴奏和音效的相关UI
        initUI();

        gridVideoContainer = findViewById(R.id.grid_video_container);

        mChannelEditText = findViewById(R.id.channel_id_input);
        mChannelEditText.setText(GlobalConfig.getInstance().gerRandomChannelId());

        mJoinChannelBtn = findViewById(R.id.join_channel_btn);
        mJoinChannelBtn.setOnClickListener(v -> {
            if(hasJoined) {
                destroyRtcEngine();
                mJoinChannelBtn.setText(R.string.video_chat_join_room);
            } else {
                startRTCCall();
            }
        });
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        destroyRtcEngine();
    }

    public static void startActionActivity(Activity activity) {
        Intent intent = new Intent(activity, PlayAudioFilesActivity.class);
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
            mJoinChannelBtn.setText(R.string.leave_channel);
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
        public void onAudioPublishStateChanged(AliRtcEngine.AliRtcPublishState oldState , AliRtcEngine.AliRtcPublishState newState, int elapseSinceLastState, String channel, AliRtcEngine.AliRtcPublishStateChangedReason reason){
            super.onAudioPublishStateChanged(oldState, newState, elapseSinceLastState, channel, reason);
            // 已经推流之后才能开始播放伴奏或者音效
            handler.post(new Runnable() {
                @Override
                public void run() {
                    if(newState == AliRtcEngine.AliRtcPublishState.AliRtcStatsPublished) {
                        ToastHelper.showToast(PlayAudioFilesActivity.this, "Audio Stream has been published!", Toast.LENGTH_SHORT);
                    }
                }
            });
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
                        ToastHelper.showToast(PlayAudioFilesActivity.this, R.string.video_chat_connection_failed, Toast.LENGTH_SHORT);
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
                    ToastHelper.showToast(PlayAudioFilesActivity.this, str, Toast.LENGTH_SHORT);
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
                    ToastHelper.showToast(PlayAudioFilesActivity.this, msg, Toast.LENGTH_SHORT);
                }
            });
        }


        public void onAudioAccompanyStateChanged(AliRtcEngine.AliRtcAudioAccompanyStateCode playState, AliRtcEngine.AliRtcAudioAccompanyErrorCode errorCode){
            // 本地播放伴奏状态变化 Started、Stopped、Paused、Resumed、Ended、Buffering、BufferingEnd、Failed
            handler.post(() -> {
                String msg = "onAudioAccompanyStateChanged playState:" + playState + " errorCode:" + errorCode;
                ToastHelper.showToast(PlayAudioFilesActivity.this, msg, Toast.LENGTH_SHORT);
            });
        }

        @Override
        public void onAudioFileInfo(AliRtcEngine.AliRtcAudioFileInfo info, AliRtcEngine.AliRtcAudioAccompanyErrorCode errorCode) {

            handler.post(() -> {
                String msg = "onAudioFileInfo.file:" + info.filePath + "duration:" + info.durationMs + "audioPlayingErrorCode=" + errorCode;
                ToastHelper.showToast(PlayAudioFilesActivity.this, msg, Toast.LENGTH_SHORT);
            });
        }

        @Override
        public void onRemoteAudioAccompanyStarted(String uid) {
            // 远端用户uid开始播放伴奏时触发
            handler.post(() -> {
                String msg = "onRemoteAudioAccompanyStarted.uid:" + uid;
                ToastHelper.showToast(PlayAudioFilesActivity.this, msg, Toast.LENGTH_SHORT);
            });
        }

        @Override
        public void onRemoteAudioAccompanyFinished(String uid) {
            // 远端用户uid停止播放伴奏时触发
            handler.post(() -> {
                String msg = "onRemoteAudioAccompanyFinished.uid:" + uid;
                ToastHelper.showToast(PlayAudioFilesActivity.this, msg, Toast.LENGTH_SHORT);
            });
        }

        @Override
        public void onAudioEffectFinished(int soundId) {
            // 本地播放的音效播放完毕时触发
            handler.post(() -> {
                String msg = "onAudioEffectFinished.soundId:" + soundId;
                ToastHelper.showToast(PlayAudioFilesActivity.this, msg, Toast.LENGTH_SHORT);
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

    private void initUI() {
        // 控制CardView的显示和隐藏
        TextView mixingMusicTitle = findViewById(R.id.tv_mixing_music_title);
        LinearLayout mixingMusicContent = findViewById(R.id.ll_mixing_music_content);
        mixingMusicTitle.setOnClickListener(v -> {
            if (mixingMusicContent.getVisibility() == android.view.View.VISIBLE) {
                mixingMusicContent.setVisibility(android.view.View.GONE);
                mixingMusicTitle.setText("伴奏 ▼");
            } else {
                mixingMusicContent.setVisibility(android.view.View.VISIBLE);
                mixingMusicTitle.setText("伴奏 ▲");
            }
        });

        // 伴奏相关UI
        mMixingMusicFileTextView = findViewById(R.id.tv_mixing_music_file);
        mMixingMusicFileTextView.setText(mMixingMusicFilepath);
        mMixingVolumeSeekBar = findViewById(R.id.seekbar_mixing_music_volume);
        mMixingVolumeSeekBar.setMax(100);
        mMixingVolumeSeekBar.setProgress(60);
        mMixingPublishVolumeSeekBar = findViewById(R.id.seekbar_mixing_music_publish_volume);
        mMixingPublishVolumeSeekBar.setMax(100);
        mMixingPublishVolumeSeekBar.setProgress(60);
        mMixingPlaybackVolumeSeekBar = findViewById(R.id.seekbar_mixing_music_play_volume);
        mMixingPlaybackVolumeSeekBar.setMax(100);
        mMixingPlaybackVolumeSeekBar.setProgress(60);
        mMixingLoopCountEditText = findViewById(R.id.et_mixing_music_loop_count);
        mMixingPlayPositionSeekBar = findViewById(R.id.seekbar_mixing_music_play_position);
        mMixingPlayPositionSeekBar.setProgress(0);

        TextView mMixingStartBtn = findViewById(R.id.mixing_start);
        TextView mMixingStopBtn = findViewById(R.id.mixing_stop);
        TextView mMixingPauseBtn = findViewById(R.id.mixing_pause);
        TextView mMixingResumeBtn = findViewById(R.id.mixing_resume);

        mMixingStartBtn.setOnClickListener(v -> startAudioAccompany());
        mMixingStopBtn.setOnClickListener(v -> stopAudioAccompany());
        mMixingPauseBtn.setOnClickListener(v -> pauseAudioAccompany());
        mMixingResumeBtn.setOnClickListener(v -> resumeAudioAccompany());

        // 添加伴奏音量控制逻辑
        // 总音量控制
        mMixingVolumeSeekBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                // 音量进度条改变
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {
                // 开始拖动
            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {
                // 拖动结束设置音量，或者onProgressChanged时设置
                if(mAliRtcEngine != null) {
                    int volume = seekBar.getProgress();
                    mAliRtcEngine.setAudioAccompanyVolume(volume); // 音量要求[0-100]
                }
            }
        });

        // 推流音量控制
        mMixingPublishVolumeSeekBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                if (fromUser && mAliRtcEngine != null) {
                    mAliRtcEngine.setAudioAccompanyPublishVolume(progress);
                }
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {}

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {}
        });

        // 播放音量控制
        mMixingPlaybackVolumeSeekBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                if (fromUser && mAliRtcEngine != null) {
                    mAliRtcEngine.setAudioAccompanyPlayoutVolume(progress);
                }
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {}

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {}
        });

        mMixingPlayPositionSeekBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener(){

            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {

            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {

            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {
                if(mAliRtcEngine != null && hasJoined) {
                    int duration = seekBar.getProgress();
                    if(duration >= 0 && duration <= mAliRtcEngine.getAudioAccompanyDuration()) {
                        mAliRtcEngine.setAudioAccompanyPosition(duration);
                        mMixingPlayPositionSeekBar.setProgress(duration);
                    }
                }
            }
        });

        // 音效相关UI
        mAudioEffectSpinner = findViewById(R.id.spinner_audio_effect);
        mAudioEffectVolumeSeekBar = findViewById(R.id.seekbar_audio_effect_volume);
        mAudioEffectVolumeSeekBar.setMax(100);
        mAudioEffectVolumeSeekBar.setProgress(60);
        mAudioEffectLoopCountEditText = findViewById(R.id.edittext_audio_effect_loop_count);
        mAudioEffectVolumeAllSeekBar = findViewById(R.id.seekbar_audio_effect_volume_all);
        mAudioEffectVolumeAllSeekBar.setMax(100);
        mAudioEffectVolumeAllSeekBar.setProgress(60);

        // 设置音效选择Spinner
        String[] audioEffects = {"音效 1 (effect1.wav)", "音效 2 (effect2.wav)"};
        ArrayAdapter<String> adapter = new ArrayAdapter<>(this, android.R.layout.simple_spinner_item, audioEffects);
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        mAudioEffectSpinner.setAdapter(adapter);
        mAudioEffectSpinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                mCurrSoundID = position + 1;
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {
                mCurrSoundID = 1;
            }
        });

        TextView effectPreloadBtn = findViewById(R.id.effect_preload);
        TextView effectUnloadBtn = findViewById(R.id.effect_unload);
        TextView effectStartBtn = findViewById(R.id.effect_start);
        TextView effectPauseBtn = findViewById(R.id.effect_pause);
        TextView effectResumeBtn = findViewById(R.id.effect_resume);
        TextView effectStopBtn = findViewById(R.id.effect_stop);
        TextView effectStopAllBtn = findViewById(R.id.effect_stop_all);
        TextView effectPauseAllBtn = findViewById(R.id.effect_pause_all);
        TextView effectResumeAllBtn = findViewById(R.id.effect_resume_all);

        effectPreloadBtn.setOnClickListener(v -> preloadAudioEffect());
        effectUnloadBtn.setOnClickListener(v -> unloadAudioEffect());
        effectStartBtn.setOnClickListener(v -> playAudioEffect());
        effectPauseBtn.setOnClickListener(v -> pauseAudioEffect(mCurrSoundID));
        effectResumeBtn.setOnClickListener(v -> resumeAudioEffect(mCurrSoundID));
        effectStopBtn.setOnClickListener(v -> stopAudioEffect(mCurrSoundID));
        effectStopAllBtn.setOnClickListener(v -> stopAllAudioEffect());
        effectPauseAllBtn.setOnClickListener(v -> pauseAllAudioEffects());
        effectResumeAllBtn.setOnClickListener(v -> resumeAllAudioEffects());

        // 音效音量控制
        mAudioEffectVolumeSeekBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                if (fromUser && mAliRtcEngine != null) {
                    mAliRtcEngine.setAudioEffectPublishVolume(mCurrSoundID, progress);
                    mAliRtcEngine.setAudioEffectPlayoutVolume(mCurrSoundID, progress);
                }
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {}

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {}
        });

        // 所有音效音量控制
        mAudioEffectVolumeAllSeekBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                if (fromUser && mAliRtcEngine != null) {
                    mAliRtcEngine.setAllAudioEffectsPlayoutVolume(progress);
                    mAliRtcEngine.setAllAudioEffectsPublishVolume(progress);
                }
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {}

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {}
        });

        TextView audioEffectTitle = findViewById(R.id.tv_audio_effect_title);
        LinearLayout audioEffectContent = findViewById(R.id.ll_audio_effect_content);
        audioEffectTitle.setOnClickListener(v -> {
            if (audioEffectContent.getVisibility() == android.view.View.VISIBLE) {
                audioEffectContent.setVisibility(android.view.View.GONE);
                audioEffectTitle.setText("音效 ▼");
            } else {
                audioEffectContent.setVisibility(android.view.View.VISIBLE);
                audioEffectTitle.setText("音效 ▲");
            }
        });
    }

    private void startAudioAccompany() {
        if (mAliRtcEngine == null) {
            ToastHelper.showToast(this, "RTC引擎未初始化", Toast.LENGTH_SHORT);
            return;
        }

        if (!hasJoined) {
            ToastHelper.showToast(this, "请先加入频道", Toast.LENGTH_SHORT);
            return;
        }

        try {
            // 获取循环次数
            String loopCountStr = mMixingLoopCountEditText.getText().toString();
            int loopCount = TextUtils.isEmpty(loopCountStr) ? -1 : Integer.parseInt(loopCountStr);
            int publishVolume = mMixingPublishVolumeSeekBar.getProgress();
            int playbackVolume = mMixingPlaybackVolumeSeekBar.getProgress();
            // 文件检查
            AliRtcEngine.AliRtcAudioAccompanyConfig config = new AliRtcEngine.AliRtcAudioAccompanyConfig();
            config.loopCycles = loopCount;
            config.publishVolume = publishVolume;
            config.playoutVolume = playbackVolume;
            config.startPosMs = 0;
            mAliRtcEngine.startAudioAccompany(mMixingMusicFilepath, config);

            // 更新进度条UI
            int audioDuration = mAliRtcEngine.getAudioAccompanyDuration(); // ms
            mMixingPlayPositionSeekBar.setMax(audioDuration);
        } catch (Exception e) {
            ToastHelper.showToast(this, "播放背景音乐异常", Toast.LENGTH_SHORT);
        }
    }

    private void stopAudioAccompany() {
        if (mAliRtcEngine == null) {
            ToastHelper.showToast(this, "RTC引擎未初始化", Toast.LENGTH_SHORT);
            return;
        }
        mAliRtcEngine.stopAudioAccompany();
    }

    private void pauseAudioAccompany() {
        if (mAliRtcEngine == null) {
            ToastHelper.showToast(this, "RTC引擎未初始化", Toast.LENGTH_SHORT);
            return;
        }
        mAliRtcEngine.pauseAudioAccompany();
    }

    private void resumeAudioAccompany() {
        if (mAliRtcEngine == null) {
            ToastHelper.showToast(this, "RTC引擎未初始化", Toast.LENGTH_SHORT);
            return;
        }
        mAliRtcEngine.resumeAudioAccompany();
    }

    // 音效
    private void preloadAudioEffect() {
        if (mAliRtcEngine == null) {
            ToastHelper.showToast(this, "RTC引擎未初始化", Toast.LENGTH_SHORT);
            return;
        }

        if (!hasJoined) {
            ToastHelper.showToast(this, "请先加入频道", Toast.LENGTH_SHORT);
            return;
        }

        String filePath = mCurrSoundID == 1 ? mAudioEffectFilePath1 : mAudioEffectFilePath2;
        mAliRtcEngine.preloadAudioEffect(mCurrSoundID, filePath);
        ToastHelper.showToast(this, "预加载音效 " + mCurrSoundID, Toast.LENGTH_SHORT);
    }

    private void unloadAudioEffect() {
        if (mAliRtcEngine == null) {
            ToastHelper.showToast(this, "RTC引擎未初始化", Toast.LENGTH_SHORT);
            return;
        }

        mAliRtcEngine.unloadAudioEffect(mCurrSoundID);
        ToastHelper.showToast(this, "取消加载音效 " + mCurrSoundID, Toast.LENGTH_SHORT);
    }

    private void playAudioEffect() {
        if (mAliRtcEngine == null) {
            ToastHelper.showToast(this, "RTC引擎未初始化", Toast.LENGTH_SHORT);
            return;
        }

        if (!hasJoined) {
            ToastHelper.showToast(this, "请先加入频道", Toast.LENGTH_SHORT);
            return;
        }

        try {
            String filePath = mCurrSoundID == 1 ? mAudioEffectFilePath1 : mAudioEffectFilePath2;

            // 获取循环次数
            String loopCountStr = mAudioEffectLoopCountEditText.getText().toString();
            int loopCount = TextUtils.isEmpty(loopCountStr) ? 1 : Integer.parseInt(loopCountStr);

            AliRtcEngine.AliRtcAudioEffectConfig config = new AliRtcEngine.AliRtcAudioEffectConfig();
            config.loopCycles = loopCount;
            config.startPosMs = 0;
            config.publishVolume = mAudioEffectVolumeSeekBar.getProgress();
            config.playoutVolume = mAudioEffectVolumeSeekBar.getProgress();

            mAliRtcEngine.playAudioEffect(mCurrSoundID, filePath, config);
            ToastHelper.showToast(this, "播放音效 " + mCurrSoundID, Toast.LENGTH_SHORT);
        } catch (Exception e) {
            ToastHelper.showToast(this, "播放音效异常: " + e.getMessage(), Toast.LENGTH_SHORT);
        }
    }

    private void stopAudioEffect(int soundId) {
        if (mAliRtcEngine == null) {
            ToastHelper.showToast(this, "RTC引擎未初始化", Toast.LENGTH_SHORT);
            return;
        }

        mAliRtcEngine.stopAudioEffect(soundId);
        ToastHelper.showToast(this, "停止音效 " + soundId, Toast.LENGTH_SHORT);
    }

    private void stopAllAudioEffect() {
        if (mAliRtcEngine == null) {
            ToastHelper.showToast(this, "RTC引擎未初始化", Toast.LENGTH_SHORT);
            return;
        }

        mAliRtcEngine.stopAllAudioEffects();
        ToastHelper.showToast(this, "停止所有音效", Toast.LENGTH_SHORT);
    }

    private void pauseAudioEffect(int soundId) {
        if (mAliRtcEngine == null) {
            ToastHelper.showToast(this, "RTC引擎未初始化", Toast.LENGTH_SHORT);
            return;
        }

        mAliRtcEngine.pauseAudioEffect(soundId);
        ToastHelper.showToast(this, "暂停音效 " + soundId, Toast.LENGTH_SHORT);
    }

    private void pauseAllAudioEffects() {
        if (mAliRtcEngine == null) {
            ToastHelper.showToast(this, "RTC引擎未初始化", Toast.LENGTH_SHORT);
            return;
        }
        mAliRtcEngine.pauseAllAudioEffects();
        ToastHelper.showToast(this, "暂停所有音效", Toast.LENGTH_SHORT);
    }

    private void resumeAudioEffect(int soundId) {
        if (mAliRtcEngine == null) {
            ToastHelper.showToast(this, "RTC引擎未初始化", Toast.LENGTH_SHORT);
            return;
        }
        mAliRtcEngine.resumeAudioEffect(soundId);
        ToastHelper.showToast(this, "恢复音效 " + soundId, Toast.LENGTH_SHORT);
    }

    private void resumeAllAudioEffects() {
        if (mAliRtcEngine == null) {
            ToastHelper.showToast(this, "RTC引擎未初始化", Toast.LENGTH_SHORT);
            return;
        }
        mAliRtcEngine.resumeAllAudioEffects();
        ToastHelper.showToast(this, "恢复所有音效", Toast.LENGTH_SHORT);
    }
}
