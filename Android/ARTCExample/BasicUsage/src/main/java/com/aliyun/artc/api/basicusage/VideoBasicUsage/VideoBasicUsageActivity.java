package com.aliyun.artc.api.basicusage.VideoBasicUsage;

import static com.alivc.rtc.AliRtcEngine.AliRtcVideoTrack.AliRtcVideoTrackCamera;
import static com.alivc.rtc.AliRtcEngine.AliRtcVideoTrack.AliRtcVideoTrackNo;

import android.app.Activity;
import android.content.Intent;
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

import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 视频常用操作和配置
 */
public class VideoBasicUsageActivity extends AppCompatActivity implements VideoConfigurationDialogFragment.VideoConfigurationAppliedListener{
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
    private FrameLayout fl_local, fl_remote, fl_remote_2, fl_remote_3;

    private AliRtcEngine mAliRtcEngine = null;
    private AliRtcEngine.AliRtcVideoCanvas mLocalVideoCanvas = null;
    private Map<String, ViewGroup> remoteViews = new ConcurrentHashMap<String, ViewGroup>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        handler = new Handler(Looper.getMainLooper());
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_video_basic_usage);

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.video_chat_main), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });

        setTitle(getString(R.string.video_basic_usage));
        Objects.requireNonNull(getSupportActionBar()).setDisplayHomeAsUpEnabled(true);

        mAliRtcEngine = AliRtcEngine.getInstance(this);

        // 视频显示视图
        fl_local = findViewById(R.id.fl_local);
        fl_remote = findViewById(R.id.fl_remote);
        fl_remote_2 = findViewById(R.id.fl_remote2);
        fl_remote_3 = findViewById(R.id.fl_remote3);

        mChannelEditText = findViewById(R.id.channel_id_input);
        mChannelEditText.setText(GlobalConfig.getInstance().gerRandomChannelId());

        initAndSetupRtcEngine();
        // 加入频道按钮
        mJoinChannelTextView = findViewById(R.id.join_room_btn);
        mJoinChannelTextView.setOnClickListener(v -> {
            if(hasJoined) {
                destroyRtcEngine();
                mJoinChannelTextView.setText(R.string.video_chat_join_room);
                resetUI();
            } else {
                if(mAliRtcEngine == null) {
                    initAndSetupRtcEngine();
                }
                startPreview();
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

    private FrameLayout getAvailableView() {
        if (fl_remote.getChildCount() == 0) {
            return fl_remote;
        } else if (fl_remote_2.getChildCount() == 0) {
            return fl_remote_2;
        } else if (fl_remote_3.getChildCount() == 0) {
            return fl_remote_3;
        } else {
            return null;
        }
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
            ViewGroup.LayoutParams layoutParams = new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);

            // Reuse existing canvas and surface view if available
            if (mLocalVideoCanvas == null) {
                mLocalVideoCanvas = new AliRtcEngine.AliRtcVideoCanvas();
                SurfaceView localSurfaceView = mAliRtcEngine.createRenderSurfaceView(VideoBasicUsageActivity.this);
                if (localSurfaceView != null) {
                    localSurfaceView.setZOrderOnTop(true);
                    localSurfaceView.setZOrderMediaOverlay(true);
                    fl_local.addView(localSurfaceView, layoutParams);
                    mLocalVideoCanvas.view = localSurfaceView;
                    try {
                        mAliRtcEngine.setLocalViewConfig(mLocalVideoCanvas, AliRtcVideoTrackCamera);
                    } catch (Exception e) {
                        e.printStackTrace(); // Handle potential exceptions
                    }
                }
            }
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
            });
        }

        //在onRemoteTrackAvailableNotify回调中设置远端视频流渲染控件
        @Override
        public void onRemoteTrackAvailableNotify(String uid, AliRtcEngine.AliRtcAudioTrack audioTrack, AliRtcEngine.AliRtcVideoTrack videoTrack){
            handler.post(() -> {
                if(videoTrack == AliRtcVideoTrackCamera) {
                    SurfaceView surfaceView = mAliRtcEngine.createRenderSurfaceView(VideoBasicUsageActivity.this);
                    surfaceView.setZOrderMediaOverlay(true);
                    FrameLayout view = getAvailableView();
                    if (view == null) {
                        return;
                    }
                    remoteViews.put(uid, view);
                    view.addView(surfaceView, new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
                    AliRtcEngine.AliRtcVideoCanvas remoteVideoCanvas = new AliRtcEngine.AliRtcVideoCanvas();
                    remoteVideoCanvas.view = surfaceView;
                    mAliRtcEngine.setRemoteViewConfig(remoteVideoCanvas, uid, AliRtcVideoTrackCamera);
                } else if(videoTrack == AliRtcVideoTrackNo) {
                    if(remoteViews.containsKey(uid)) {
                        ViewGroup view = remoteViews.get(uid);
                        if(view != null) {
                            view.removeAllViews();
                            remoteViews.remove(uid);
                            mAliRtcEngine.setRemoteViewConfig(null, uid, AliRtcVideoTrackCamera);
                        }
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
    }

    // 离会后UI清除
    private void resetUI() {
        for (ViewGroup value : remoteViews.values()) {
            value.removeAllViews();
        }
        remoteViews.clear();
        fl_local.removeAllViews();
        mLocalVideoCanvas = null;
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
}