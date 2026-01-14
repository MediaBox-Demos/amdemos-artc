package com.aliyun.artc.api.basicusage.VideoBasicUsage;

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
import android.view.MenuItem;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.GridLayout;
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
import com.aliyun.artc.api.common.utils.UserSeatHelper;
import com.aliyun.artc.api.common.videoview.OnUserSeatActionListener;
import com.aliyun.artc.api.common.videoview.UserSeatState;
import com.aliyun.artc.api.common.videoview.UserSeatView;
import com.aliyun.artc.api.keycenter.ARTCTokenHelper;
import com.aliyun.artc.api.keycenter.GlobalConfig;
import com.aliyun.artc.api.keycenter.utils.ToastHelper;

import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 视频常用操作和配置
 */
public class VideoBasicUsageActivity extends AppCompatActivity implements VideoConfigurationDialogFragment.VideoConfigurationAppliedListener, OnUserSeatActionListener {
    private Handler handler;
    private EditText mChannelEditText;
    private TextView mJoinChannelTextView;
    private TextView mPreviewBtn;
    private TextView mSwitchCameraBtn;
    private TextView mSettingBtn;
    private TextView mCameraSwitchBtn;
    private Spinner mMirrorSpinner;
    private TextView mPublishVideoBtn;
    private boolean hasJoined = false; // 是否已经加入频道
    private boolean isLocalPreviewing = false; // 是否正在预览
    private boolean isEnableCamera = true;
    private boolean isMutedCamera = false;
    // 视频设置界面
    VideoConfigurationDialogFragment mVideoConfigurationDialogFragment;

    private AliRtcEngine mAliRtcEngine = null;
    private AliRtcEngine.AliRtcVideoCanvas mLocalVideoCanvas = null;
    private Map<String, FrameLayout> remoteViews = new ConcurrentHashMap<>();
    // 统一管理所有麦位的状态（key = userId_trackType）
    private final Map<String, UserSeatState> mSeatStateMap = new ConcurrentHashMap<>();
    // 记录每个远端用户当前的视频轨状态（Camera/Screen/Both/No）
    private final Map<String, AliRtcEngine.AliRtcVideoTrack> mUserVideoTrackMap = new ConcurrentHashMap<>();

    private GridLayout mGridVideoContainer;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        handler = new Handler(Looper.getMainLooper());
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_video_basic_usage);

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.video_basic_usage), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });

        setTitle(getString(R.string.video_basic_usage));
        Objects.requireNonNull(getSupportActionBar()).setDisplayHomeAsUpEnabled(true);

        mAliRtcEngine = AliRtcEngine.getInstance(this);

        // 视频显示视图
        mGridVideoContainer = findViewById(R.id.grid_video_container);

        mChannelEditText = findViewById(R.id.channel_id_input);
        mChannelEditText.setText(GlobalConfig.getInstance().gerRandomChannelId());

        initAndSetupRtcEngine();
        // 加入频道按钮
        mJoinChannelTextView = findViewById(R.id.join_room_btn);
        mJoinChannelTextView.setOnClickListener(v -> {
            if(hasJoined) {
                destroyRtcEngine();
                mJoinChannelTextView.setText(R.string.video_chat_join_room);
            } else {
                if(mAliRtcEngine == null) {
                    initAndSetupRtcEngine();
                }
                // 如果已经在预览，就不要再创建本地预览视图
                if (!isLocalPreviewing) {
                    startPreview();
                }
                joinChannel();
            }
        });
        // 停止/开启预览按钮
        mPreviewBtn = findViewById(R.id.preview_btn);
        mPreviewBtn.setOnClickListener(v -> {
            if(hasJoined) {
                if(isLocalPreviewing) {
                    mAliRtcEngine.stopPreview();
                    isLocalPreviewing = false;
                    mPreviewBtn.setText(R.string.start_preview);
                } else {
                    mAliRtcEngine.startPreview();
                    isLocalPreviewing = true;
                    mPreviewBtn.setText(R.string.stop_preview);
                }
            } else {
                // 入会前开启预览
                if (mAliRtcEngine == null) {
                    initAndSetupRtcEngine();
                }
                if(isLocalPreviewing) {
                    mAliRtcEngine.stopPreview();
                    mPreviewBtn.setText(R.string.start_preview);
                    isLocalPreviewing = false;
                } else {
                    startPreview();
                    mPreviewBtn.setText(R.string.stop_preview);
                    isLocalPreviewing = true;
                    isEnableCamera = true;
                }
            }
        });

        // 切换摄像头按钮
        mSwitchCameraBtn = findViewById(R.id.switch_camera_btn);
        mSwitchCameraBtn.setOnClickListener(v -> {
            if(mAliRtcEngine != null) {
                mAliRtcEngine.switchCamera();
            }
        });

        // 设置按钮
        mSettingBtn = findViewById(R.id.setting_btn);
        mSettingBtn.setOnClickListener(v -> {
            if(mAliRtcEngine == null) {
                initAndSetupRtcEngine();
            }
            if(mVideoConfigurationDialogFragment == null) {
                mVideoConfigurationDialogFragment = new VideoConfigurationDialogFragment();
            }
            mVideoConfigurationDialogFragment.setOnItemCommitListener(this);
            if(!mVideoConfigurationDialogFragment.isAdded()) {
                mVideoConfigurationDialogFragment.show(getSupportFragmentManager(), "VideoConfigurationDialogFragment");
            } else {
                if(mVideoConfigurationDialogFragment.getDialog() != null) {
                    mVideoConfigurationDialogFragment.getDialog().show();
                } else {
                    mVideoConfigurationDialogFragment.dismiss();
                    mVideoConfigurationDialogFragment = new VideoConfigurationDialogFragment();
                    mVideoConfigurationDialogFragment.show(getSupportFragmentManager(), "VideoConfigurationDialogFragment");
                }
            }
        });
        // 相机开关
        mCameraSwitchBtn = findViewById(R.id.camera_control_btn);
        mCameraSwitchBtn.setOnClickListener(v -> {
            if(mAliRtcEngine != null) {
                if(isEnableCamera) {
                    mAliRtcEngine.enableLocalVideo(false);
                    isEnableCamera = false;
                    mCameraSwitchBtn.setText(R.string.camera_on);
                } else {
                    mAliRtcEngine.enableLocalVideo(true);
                    isEnableCamera = true;
                    mCameraSwitchBtn.setText(R.string.camera_off);
                }
            }
        });
        // 推流控制
        mPublishVideoBtn = findViewById(R.id.publish_video_control_btn);
        mPublishVideoBtn.setOnClickListener(v -> {
            if(mAliRtcEngine != null) {
                if(!isMutedCamera) {
                    mAliRtcEngine.muteLocalCamera(true, AliRtcEngine.AliRtcVideoTrack.AliRtcVideoTrackCamera);
                    mPublishVideoBtn.setText(R.string.resume_pub_video);
                    isMutedCamera = true;
                } else {
                    mAliRtcEngine.muteLocalCamera(false, AliRtcEngine.AliRtcVideoTrack.AliRtcVideoTrackCamera);
                    mPublishVideoBtn.setText(R.string.stop_pub_video);
                    isMutedCamera = false;
                }
            }
        });
        // 镜像
        List<String> mirrorOptions = Arrays.asList(getString(R.string.mirror_mode_both_off), getString(R.string.mirror_mode_both_on),
                getString(R.string.mirror_mode_only_preview), getString(R.string.mirror_mode_only_encode));
        mMirrorSpinner = findViewById(R.id.mirror_control_btn);
        ArrayAdapter<String> adapter = new ArrayAdapter<>(this, android.R.layout.simple_spinner_item, mirrorOptions);
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        mMirrorSpinner.setAdapter(adapter);
        mMirrorSpinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> adapterView, View view, int position, long id) {
                if(mAliRtcEngine != null) {
                    AliRtcEngine.AliRtcVideoPipelineMirrorMode mirrorMode = AliRtcEngine.AliRtcVideoPipelineMirrorMode.values()[position];
                    mAliRtcEngine.setVideoMirrorMode(mirrorMode);
                }
            }

            @Override
            public void onNothingSelected(AdapterView<?> adapterView) {

            }
        });
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        destroyRtcEngine();
    }

    public static void startActionActivity(Activity activity) {
        Intent intent = new Intent(activity, VideoBasicUsageActivity.class);
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
                ((TextView)findViewById(R.id.join_room_btn)).setText(R.string.leave_channel);
            } else {
                str = "User " + userId + " Join " + channel + " Failed！， error：" + result;
                ((TextView)findViewById(R.id.join_room_btn)).setText(R.string.video_chat_join_room);
            }
            ToastHelper.showToast(this, str, Toast.LENGTH_SHORT);

        });
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

    private void startPreview() {
        if (mAliRtcEngine != null) {
            FrameLayout localVideoFrame = createVideoView("local");
            String localUserId = GlobalConfig.getInstance().getUserId();
            String localStreamKey = getStreamKey(localUserId, AliRtcVideoTrackCamera);
            
            // 创建本地流的状态对象
            UserSeatState localState = new UserSeatState(localUserId, AliRtcVideoTrackCamera, true);
            localState.hasVideoStream = true;
            localState.isCameraOn = true;
            // 本地流默认镜像：仅前置
            localState.mirrorMode = AliRtcEngine.AliRtcRenderMirrorMode.AliRtcRenderMirrorModeOnlyFront;
            mSeatStateMap.put(localStreamKey, localState);
            
            if (localVideoFrame instanceof UserSeatView) {
                ((UserSeatView) localVideoFrame).applyState(localState);
            }
            mGridVideoContainer.addView(localVideoFrame);
            SurfaceView localSurfaceView = mAliRtcEngine.createRenderSurfaceView(this);
            // 注释掉 ZOrderOnTop 和 ZOrderMediaOverlay，避免与远端屏幕共享流冲突
            // localSurfaceView.setZOrderOnTop(true);
            // localSurfaceView.setZOrderMediaOverlay(true);

            if (localVideoFrame instanceof UserSeatView) {
                ((UserSeatView) localVideoFrame).getVideoContainer().addView(localSurfaceView,
                        new FrameLayout.LayoutParams(
                                ViewGroup.LayoutParams.MATCH_PARENT,
                                ViewGroup.LayoutParams.MATCH_PARENT));
            } else {
                localVideoFrame.addView(localSurfaceView, new FrameLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.MATCH_PARENT));
            }

            mLocalVideoCanvas = new AliRtcEngine.AliRtcVideoCanvas();
            mLocalVideoCanvas.view = localSurfaceView;
            mLocalVideoCanvas.renderMode = localState.renderMode;
            mLocalVideoCanvas.mirrorMode = localState.mirrorMode;
            mLocalVideoCanvas.rotationMode = localState.rotationMode;
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
            if(!isLocalPreviewing) {
                isLocalPreviewing = true;
                mPreviewBtn.setText(R.string.stop_preview);
            }
        } else {
            Log.e("VideoCallActivity", "channelId is empty");
        }
    }

    private FrameLayout createVideoView(String tag) {
        UserSeatView view = new UserSeatView(this);
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
        
        // 设置操作回调监听器
        view.setOnActionListener(this);
        
        return view;
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
                mGridVideoContainer.addView(view);
                remoteViews.put(streamKey, view);
            }
        } else {
            view = createVideoView(streamKey);
            mGridVideoContainer.addView(view);
            remoteViews.put(streamKey, view);
        }
        
        // 创建或获取该流的状态对象
        UserSeatState state = mSeatStateMap.get(streamKey);
        if (state == null) {
            state = new UserSeatState(uid, videoTrack, false);
            state.hasVideoStream = true;
            mSeatStateMap.put(streamKey, state);
        } else {
            state.hasVideoStream = true;
        }
        
        if (view instanceof UserSeatView) {
            ((UserSeatView) view).applyState(state);
        }
        
        // 创建 SurfaceView 并设置渲染
        SurfaceView surfaceView = mAliRtcEngine.createRenderSurfaceView(this);
        surfaceView.setZOrderMediaOverlay(true);
        if (view instanceof UserSeatView) {
            ((UserSeatView) view).getVideoContainer().addView(surfaceView, new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        } else {
            view.addView(surfaceView, new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        }
        // 配置画布
        AliRtcEngine.AliRtcVideoCanvas videoCanvas = new AliRtcEngine.AliRtcVideoCanvas();
        videoCanvas.view = surfaceView;
        videoCanvas.renderMode = state.renderMode;
        videoCanvas.mirrorMode = state.mirrorMode;
        videoCanvas.rotationMode = state.rotationMode;
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
            mGridVideoContainer.removeView(frameLayout);
            Log.d("RemoveRemoteVideo", "Removed video stream for: " + streamKey);
        }
        
        // 移除该流的状态对象
        mSeatStateMap.remove(streamKey);
    }

    /**
     * 移除指定用户的所有视频
     * @param uid 远端用户 ID
     */
    private void removeAllRemoteVideo(String uid) {
        removeRemoteVideo(uid, AliRtcVideoTrackCamera);
        removeRemoteVideo(uid, AliRtcVideoTrackScreen);
        // 移除音频占位视图
        removeRemoteVideo(uid, AliRtcVideoTrackNo);
    }

    /**
     * 根据当前远端用户的视频轨状态，统一更新相机流 / 屏幕流视图
     * 采用增量更新策略：只处理发生变化的流，避免重复创建导致黑屏
     *
     * @param uid        远端用户 ID
     * @param videoTrack 当前视频轨状态（Camera/Screen/Both/No）
     */
    private void updateRemoteUserViews(String uid, AliRtcEngine.AliRtcVideoTrack videoTrack) {
        // 获取上一次该用户的视频轨状态
        AliRtcEngine.AliRtcVideoTrack prevTrack = mUserVideoTrackMap.get(uid);
        
        // 上一次的流状态
        boolean hadCameraBefore = (prevTrack == AliRtcVideoTrackCamera || prevTrack == AliRtcVideoTrackBoth);
        boolean hadScreenBefore = (prevTrack == AliRtcVideoTrackScreen || prevTrack == AliRtcVideoTrackBoth);
        
        // 本次需要的流状态
        boolean needCamera = (videoTrack == AliRtcVideoTrackCamera || videoTrack == AliRtcVideoTrackBoth);
        boolean needScreen = (videoTrack == AliRtcVideoTrackScreen || videoTrack == AliRtcVideoTrackBoth);
        
        // 相机流：按"增删 diff"处理
        if (!hadCameraBefore && needCamera) {
            // 之前没有相机流，现在需要 -> 创建相机画面
            viewRemoteVideo(uid, AliRtcVideoTrackCamera);
            Log.d("VideoBasicUsage", "Create camera view for " + uid);
        } else if (hadCameraBefore && !needCamera) {
            // 之前有相机流，现在不需要 -> 移除相机画面
            removeRemoteVideo(uid, AliRtcVideoTrackCamera);
            Log.d("VideoBasicUsage", "Remove camera view for " + uid);
        }
        // hadCameraBefore && needCamera 的情况：相机流保持不变，不做任何操作，避免重建导致黑屏
        
        // 屏幕流：按"增删 diff"处理
        if (!hadScreenBefore && needScreen) {
            // 之前没有屏幕流，现在需要 -> 创建屏幕画面
            viewRemoteVideo(uid, AliRtcVideoTrackScreen);
            Log.d("VideoBasicUsage", "Create screen view for " + uid);
        } else if (hadScreenBefore && !needScreen) {
            // 之前有屏幕流，现在不需要 -> 移除屏幕画面
            removeRemoteVideo(uid, AliRtcVideoTrackScreen);
            Log.d("VideoBasicUsage", "Remove screen view for " + uid);
        }
        // hadScreenBefore && needScreen 的情况：屏幕流保持不变，不做任何操作
        
        // 记录最新状态
        if (videoTrack == AliRtcVideoTrackNo) {
            mUserVideoTrackMap.remove(uid);
        } else {
            mUserVideoTrackMap.put(uid, videoTrack);
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

    /**
     * 获取用户的静音状态（从该用户的任意一个 Seat 查找）
     * @param userId 用户 ID
     * @return 静音状态
     */
    private boolean getUserMutedState(String userId) {
        for (Map.Entry<String, UserSeatState> entry : mSeatStateMap.entrySet()) {
            UserSeatState state = entry.getValue();
            if (state != null && userId.equals(state.userId)) {
                return state.isMicMuted;
            }
        }
        return false; // 默认不静音
    }


    private final AliRtcEngineEventListener mRtcEngineEventListener = new AliRtcEngineEventListener() {
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
                        ToastHelper.showToast(VideoBasicUsageActivity.this, R.string.connection_failed, Toast.LENGTH_SHORT);
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
                    ToastHelper.showToast(VideoBasicUsageActivity.this, str, Toast.LENGTH_SHORT);
                }
            });
        }

    };

    private final AliRtcEngineNotify mRtcEngineNotify = new AliRtcEngineNotify() {
        @Override
        public void onAuthInfoWillExpire() {
            super.onAuthInfoWillExpire();
            /* TODO: 务必处理；Token即将过期，需要业务触发重新获取当前channel，user的鉴权信息，然后设置refreshAuthInfo即可 */
        }

        @Override
        public void onRemoteUserOnLineNotify(String uid, int elapsed){
            super.onRemoteUserOnLineNotify(uid, elapsed);
            handler.post(() -> {
                String msg = "User "+ uid + " online";
                ToastHelper.showToast(VideoBasicUsageActivity.this, msg, Toast.LENGTH_SHORT);
            });
        }

        //在onRemoteUserOffLineNotify回调中解除远端视频流渲染控件的设置
        @Override
        public void onRemoteUserOffLineNotify(String uid, AliRtcEngine.AliRtcUserOfflineReason reason){
            super.onRemoteUserOffLineNotify(uid, reason);
            handler.post(() -> {
                String msg = "User "+ uid + " offline";
                ToastHelper.showToast(VideoBasicUsageActivity.this, msg, Toast.LENGTH_SHORT);
                // 用户下线时，移除该用户所有视频画面
                removeAllRemoteVideo(uid);
                // 同步清理该用户的轨状态
                mUserVideoTrackMap.remove(uid);
            });
        }

        //在onRemoteTrackAvailableNotify回调中设置远端视频流渲染控件
        @Override
        public void onRemoteTrackAvailableNotify(String uid, AliRtcEngine.AliRtcAudioTrack audioTrack, AliRtcEngine.AliRtcVideoTrack videoTrack){
            handler.post(() -> {
                Log.d("VideoBasicUsage", "onRemoteTrackAvailableNotify uid=" + uid + " audioTrack=" + audioTrack + " videoTrack=" + videoTrack);
                
                // 先按视频轨状态增删相机/屏幕画面
                updateRemoteUserViews(uid, videoTrack);
                
                // 如果没有视频但有音频，创建一个占位视图
                if (videoTrack == AliRtcVideoTrackNo && 
                    audioTrack != AliRtcEngine.AliRtcAudioTrack.AliRtcAudioTrackNo) {
                    
                    String streamKey = getStreamKey(uid, AliRtcVideoTrackNo);
                    FrameLayout view = remoteViews.get(streamKey);
                    if (view == null) {
                        view = createVideoView(streamKey);
                        mGridVideoContainer.addView(view);
                        remoteViews.put(streamKey, view);
                    }
                    
                    // 创建音频占位状态
                    UserSeatState audioState = mSeatStateMap.get(streamKey);
                    if (audioState == null) {
                        audioState = new UserSeatState(uid, AliRtcVideoTrackNo, false);
                        audioState.hasVideoStream = false;
                        audioState.isCameraOn = false;
                        mSeatStateMap.put(streamKey, audioState);
                    }
                    // 同步静音状态（从该用户其他 Seat 查找）
                    audioState.isMicMuted = getUserMutedState(uid);
                    
                    if (view instanceof UserSeatView) {
                        ((UserSeatView) view).applyState(audioState);
                        Log.d("VideoBasicUsage", "Create audio-only placeholder for " + uid);
                    }
                } else if (videoTrack != AliRtcVideoTrackNo) {
                    // 如果有视频了，移除音频占位视图
                    String audioOnlyKey = getStreamKey(uid, AliRtcVideoTrackNo);
                    if (remoteViews.containsKey(audioOnlyKey)) {
                        removeRemoteVideo(uid, AliRtcVideoTrackNo);
                        Log.d("VideoBasicUsage", "Remove audio-only placeholder for " + uid);
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
                    ToastHelper.showToast(VideoBasicUsageActivity.this, msg, Toast.LENGTH_SHORT);
                }
            });
        }

        @Override
        public void onUserVideoEnabled(String uid, boolean isEnable) {
            handler.post(new Runnable() {
                @Override
                public void run() {
                    ToastHelper.showToast(VideoBasicUsageActivity.this, "remote user uid:" + uid + " camera enable:" + isEnable, Toast.LENGTH_SHORT);
                }
            });
        }
    };

    private void destroyRtcEngine() {
        if( mAliRtcEngine != null) {
            if(hasJoined) {
                mAliRtcEngine.leaveChannel();
                hasJoined = false;
                handler.post(() -> {
                    ToastHelper.showToast(this, "Leave Channel", Toast.LENGTH_SHORT);
                });
            }
            mAliRtcEngine.destroy();
            mAliRtcEngine = null;
        }

        for (ViewGroup value : remoteViews.values()) {
            value.removeAllViews();
        }
        remoteViews.clear();
        mGridVideoContainer.removeAllViews();
        mLocalVideoCanvas = null;
        
        // 清理所有麦位状态
        mSeatStateMap.clear();
        // 清理每个用户的视频轨状态
        mUserVideoTrackMap.clear();
        
        // 重置本地预览相关状态
        isLocalPreviewing = false;
        isEnableCamera = true;
        isMutedCamera = false;
        handler.post(() -> {
            if (mPreviewBtn != null) {
                mPreviewBtn.setText(R.string.start_preview);
            }
            if (mCameraSwitchBtn != null) {
                mCameraSwitchBtn.setText(R.string.camera_off);
            }
            if (mPublishVideoBtn != null) {
                mPublishVideoBtn.setText(R.string.stop_pub_video);
            }
        });
    }

    @Override
    public void onCameraCaptureConfiguration(AliRtcEngine.AliEngineCameraCapturerConfiguration config) {
        if (mAliRtcEngine != null && !mAliRtcEngine.isCameraOn()) {
            // 摄像头开启前设置
            mAliRtcEngine.setCameraCapturerConfiguration(config);
        }
    }

    @Override
    public void onVideoEncoderConfiguraion(AliRtcEngine.AliRtcVideoEncoderConfiguration config) {
        if(mAliRtcEngine != null) {
            mAliRtcEngine.setVideoEncoderConfiguration(config);
        }
    }

    @Override
    public void onVideoDecoderConfiguration(AliRtcEngine.AliRtcVideoDecoderConfiguration config) {
        if(mAliRtcEngine != null) {
            mAliRtcEngine.setVideoDecoderConfiguration(config);
        }
    }

    // ==================== UserSeatView.OnUserSeatActionListener 接口实现 ====================

    /**
     * 切换渲染模式
     */
    @Override
    public void onRenderModeChange(String userId, AliRtcEngine.AliRtcVideoTrack trackType) {
        handler.post(() -> {
            if (mAliRtcEngine != null) {
                // 获取当前流的 streamKey
                String streamKey = getStreamKey(userId, trackType);
                UserSeatState state = mSeatStateMap.get(streamKey);
                if (state == null) return;
                
                FrameLayout view = remoteViews.get(streamKey);
                if (view == null && userId.equals(GlobalConfig.getInstance().getUserId())) {
                    // 本地预览，查找第一个视图
                    if (mGridVideoContainer.getChildCount() > 0) {
                        View firstChild = mGridVideoContainer.getChildAt(0);
                        if (firstChild instanceof UserSeatView) {
                            view = (FrameLayout) firstChild;
                        }
                    }
                }
                
                if (view instanceof UserSeatView) {
                    UserSeatView userSeatView = (UserSeatView) view;
                    
                    // 计算下一个渲染模式（基于当前状态循环）
                    AliRtcEngine.AliRtcRenderMode nextMode = UserSeatHelper.getNextRenderMode(state.renderMode);
                    state.renderMode = nextMode;
                    
                    // 更新 SDK 配置
                    if (userId.equals(GlobalConfig.getInstance().getUserId()) && mLocalVideoCanvas != null) {
                        // 本地预览
                        mLocalVideoCanvas.renderMode = nextMode;
                        mLocalVideoCanvas.mirrorMode = state.mirrorMode;
                        mLocalVideoCanvas.rotationMode = state.rotationMode;
                        mAliRtcEngine.setLocalViewConfig(mLocalVideoCanvas, trackType);
                    } else {
                        // 远端画面
                        AliRtcEngine.AliRtcVideoCanvas videoCanvas = new AliRtcEngine.AliRtcVideoCanvas();
                        videoCanvas.renderMode = nextMode;
                        videoCanvas.mirrorMode = state.mirrorMode;
                        videoCanvas.rotationMode = state.rotationMode;
                        // 保持原有的 view
                        ViewGroup container = userSeatView.getVideoContainer();
                        if (container.getChildCount() > 0 && container.getChildAt(0) instanceof SurfaceView) {
                            videoCanvas.view = (SurfaceView) container.getChildAt(0);
                        }
                        mAliRtcEngine.setRemoteViewConfig(videoCanvas, userId, trackType);
                    }
                    
                    // 更新 UI 显示（使用统一的 applyState 刷新汇总文本）
                    userSeatView.applyState(state);
                    
                    ToastHelper.showToast(this, "渲染模式: " + UserSeatHelper.getRenderModeName(nextMode), Toast.LENGTH_SHORT);
                }
            }
        });
    }

    /**
     * 切换镜像状态
     */
    @Override
    public void onMirrorToggle(String userId, AliRtcEngine.AliRtcVideoTrack trackType) {
        handler.post(() -> {
            if (mAliRtcEngine != null) {
                String streamKey = getStreamKey(userId, trackType);
                UserSeatState state = mSeatStateMap.get(streamKey);
                if (state == null) return;
                
                // 获取当前镜像模式并切换
                AliRtcEngine.AliRtcRenderMirrorMode nextMode = UserSeatHelper.toggleMirrorMode(state.mirrorMode);
                state.mirrorMode = nextMode;
                
                // 更新 UI 显示
                FrameLayout view = remoteViews.get(streamKey);
                if (view == null && userId.equals(GlobalConfig.getInstance().getUserId())) {
                    // 本地预览，查找第一个视图
                    if (mGridVideoContainer.getChildCount() > 0) {
                        View firstChild = mGridVideoContainer.getChildAt(0);
                        if (firstChild instanceof UserSeatView) {
                            view = (FrameLayout) firstChild;
                        }
                    }
                }
                
                if (view instanceof UserSeatView) {
                    UserSeatView userSeatView = (UserSeatView) view;
                    
                    // 通过 canvas 设置镜像模式
                    if (userId.equals(GlobalConfig.getInstance().getUserId()) && mLocalVideoCanvas != null) {
                        // 本地预览
                        mLocalVideoCanvas.mirrorMode = nextMode;
                        mLocalVideoCanvas.renderMode = state.renderMode;
                        mLocalVideoCanvas.rotationMode = state.rotationMode;
                        mAliRtcEngine.setLocalViewConfig(mLocalVideoCanvas, trackType);
                    } else {
                        // 远端画面
                        AliRtcEngine.AliRtcVideoCanvas videoCanvas = new AliRtcEngine.AliRtcVideoCanvas();
                        videoCanvas.mirrorMode = nextMode;
                        videoCanvas.renderMode = state.renderMode;
                        videoCanvas.rotationMode = state.rotationMode;
                        
                        ViewGroup container = userSeatView.getVideoContainer();
                        if (container.getChildCount() > 0 && container.getChildAt(0) instanceof SurfaceView) {
                            videoCanvas.view = (SurfaceView) container.getChildAt(0);
                        }
                        mAliRtcEngine.setRemoteViewConfig(videoCanvas, userId, trackType);
                    }
                    
                    // 更新 UI 显示（使用统一的 applyState 刷新汇总文本和图标）
                    userSeatView.applyState(state);
                }
                
                String modeName = UserSeatHelper.getMirrorModeName(nextMode);
                ToastHelper.showToast(this, "镜像: " + modeName, Toast.LENGTH_SHORT);
            }
        });
    }

    /**
     * 切换旋转角度
     */
    @Override
    public void onRotationChange(String userId, AliRtcEngine.AliRtcVideoTrack trackType) {
        handler.post(() -> {
            if (mAliRtcEngine != null) {
                String streamKey = getStreamKey(userId, trackType);
                UserSeatState state = mSeatStateMap.get(streamKey);
                if (state == null) return;
                
                FrameLayout view = remoteViews.get(streamKey);
                
                if (view == null && userId.equals(GlobalConfig.getInstance().getUserId())) {
                    // 本地预览，查找第一个视图
                    if (mGridVideoContainer.getChildCount() > 0) {
                        View firstChild = mGridVideoContainer.getChildAt(0);
                        if (firstChild instanceof UserSeatView) {
                            view = (FrameLayout) firstChild;
                        }
                    }
                }
                
                if (view instanceof UserSeatView) {
                    UserSeatView userSeatView = (UserSeatView) view;
                    
                    // 获取下一个旋转模式（0° -> 90° -> 180° -> 270° -> 0°）
                    AliRtcEngine.AliRtcRotationMode nextMode = UserSeatHelper.getNextRotationMode(state.rotationMode);
                    state.rotationMode = nextMode;
                    
                    // 通过 canvas 设置旋转模式
                    if (userId.equals(GlobalConfig.getInstance().getUserId()) && mLocalVideoCanvas != null) {
                        // 本地预览
                        mLocalVideoCanvas.rotationMode = nextMode;
                        mLocalVideoCanvas.renderMode = state.renderMode;
                        mLocalVideoCanvas.mirrorMode = state.mirrorMode;
                        mAliRtcEngine.setLocalViewConfig(mLocalVideoCanvas, trackType);
                    } else {
                        // 远端画面
                        AliRtcEngine.AliRtcVideoCanvas videoCanvas = new AliRtcEngine.AliRtcVideoCanvas();
                        videoCanvas.rotationMode = nextMode;
                        videoCanvas.renderMode = state.renderMode;
                        videoCanvas.mirrorMode = state.mirrorMode;
                        
                        ViewGroup container = userSeatView.getVideoContainer();
                        if (container.getChildCount() > 0 && container.getChildAt(0) instanceof SurfaceView) {
                            videoCanvas.view = (SurfaceView) container.getChildAt(0);
                        }
                        mAliRtcEngine.setRemoteViewConfig(videoCanvas, userId, trackType);
                    }
                    
                    // 更新 UI 显示（使用统一的 applyState 刷新汇总文本和图标）
                    int angle = UserSeatHelper.rotationModeToAngle(nextMode);
                    userSeatView.applyState(state);
                    
                    ToastHelper.showToast(this, "旋转角度: " + angle + "°", Toast.LENGTH_SHORT);
                }
            }
        });
    }
}