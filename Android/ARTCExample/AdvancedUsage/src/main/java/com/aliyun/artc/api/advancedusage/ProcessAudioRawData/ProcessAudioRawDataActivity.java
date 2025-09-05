package com.aliyun.artc.api.advancedusage.ProcessAudioRawData;

import static android.view.View.VISIBLE;

import static com.alivc.rtc.AliRtcEngine.AliRtcVideoTrack.AliRtcVideoTrackCamera;
import static com.alivc.rtc.AliRtcEngine.AliRtcVideoTrack.AliRtcVideoTrackNo;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.SwitchCompat;
import android.widget.CompoundButton;

import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import com.alivc.rtc.AliRtcEngine;
import com.alivc.rtc.AliRtcEngineEventListener;
import com.alivc.rtc.AliRtcEngineNotify;
import com.aliyun.artc.api.keycenter.ARTCTokenHelper;
import com.aliyun.artc.api.keycenter.GlobalConfig;
import com.aliyun.artc.api.keycenter.utils.ToastHelper;
import com.aliyun.artc.api.advancedusage.R;

import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;
import android.util.Log;
import android.view.MenuItem;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.TextView;
import android.widget.Toast;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 获取音频原始数据API调用示例
 */
public class ProcessAudioRawDataActivity extends AppCompatActivity {
    private static final String TAG = ProcessAudioRawDataActivity.class.getSimpleName();

    private Handler handler;
    private EditText mChannelEditText;
    private TextView mJoinChannelTextView;
    // Audio Raw Frame Switch
    private SwitchCompat mCapturedAudioFrame;
    private SwitchCompat mProcessCapturedAudioSwitch;
    private SwitchCompat mPublishAudioSwitch;
    private SwitchCompat mPlaybackAudioFrame;
    private SwitchCompat mRemoteUserAudioFrame;

    private boolean hasJoined = false;
    private FrameLayout fl_local, fl_remote;

    private AliRtcEngine mAliRtcEngine = null;
    private AliRtcEngine.AliRtcVideoCanvas mLocalVideoCanvas = null;
    private final Map<String, ViewGroup> remoteViews = new ConcurrentHashMap<String, ViewGroup>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        handler = new Handler(Looper.getMainLooper());
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_process_audio_raw_date);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.process_audio_raw_data), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });
        setTitle(getString(R.string.process_audio_raw_data));
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);

        // 视频显示视图
        fl_local = findViewById(R.id.fl_local);
        fl_remote = findViewById(R.id.fl_remote);

        mChannelEditText = findViewById(R.id.channel_id_input);
        mChannelEditText.setText(GlobalConfig.getInstance().gerRandomChannelId());
        mJoinChannelTextView = findViewById(R.id.join_room_btn);
        mJoinChannelTextView.setOnClickListener(v -> {
            if(hasJoined) {
                destroyRtcEngine();
                mJoinChannelTextView.setText(R.string.video_chat_join_channel);
            } else {
                // 重复入会时需要重新初始化引擎
                if(mAliRtcEngine == null) {
                    initAndSetupRtcEngine();
                }
                startRTCCall();
            }
        });

        // Create Rtc Engine
        initAndSetupRtcEngine();

        // Enable or Disable Audio Frame Callback
        // Capture Audio Frame
        mCapturedAudioFrame = findViewById(R.id.CapturedAudioFrame_Switch);
        mCapturedAudioFrame.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if(mAliRtcEngine == null) {
                    ToastHelper.showToast(ProcessAudioRawDataActivity.this, getString(R.string.rtc_engine_init_required), Toast.LENGTH_SHORT);
                    mCapturedAudioFrame.setChecked(false);
                    return;
                }

                AliRtcEngine.AliRtcAudioFrameObserverConfig config = new AliRtcEngine.AliRtcAudioFrameObserverConfig();
                config.sampleRate = AliRtcEngine.AliRtcAudioSampleRate.AliRtcAudioSampleRate_48000;
                config.mode = AliRtcEngine.AliRtcAudioFrameObserverOperationMode.AliRtcAudioDataObserverOperationModeReadWrite;
                config.channels = AliRtcEngine.AliRtcAudioNumChannel.AliRtcMonoAudio;

                mAliRtcEngine.enableAudioFrameObserver(isChecked, AliRtcEngine.AliRtcAudioSource.AliRtcAudioSourceCaptured, config);
            }
        });

        // 3A Audio Raw Data
        mProcessCapturedAudioSwitch = findViewById(R.id.process_captured_audio_switch);
        mProcessCapturedAudioSwitch.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if(mAliRtcEngine == null) {
                    ToastHelper.showToast(ProcessAudioRawDataActivity.this, getString(R.string.rtc_engine_init_required), Toast.LENGTH_SHORT);
                    mProcessCapturedAudioSwitch.setChecked(false);
                    return;
                }

                AliRtcEngine.AliRtcAudioFrameObserverConfig config = new AliRtcEngine.AliRtcAudioFrameObserverConfig();
                config.sampleRate = AliRtcEngine.AliRtcAudioSampleRate.AliRtcAudioSampleRate_48000;
                config.mode = AliRtcEngine.AliRtcAudioFrameObserverOperationMode.AliRtcAudioDataObserverOperationModeReadWrite;
                config.channels = AliRtcEngine.AliRtcAudioNumChannel.AliRtcMonoAudio;

                mAliRtcEngine.enableAudioFrameObserver(isChecked, AliRtcEngine.AliRtcAudioSource.AliRtcAudioSourceProcessCaptured, config);
            }
        });

        // Publish Audio Frame
        mPublishAudioSwitch = findViewById(R.id.PublishAudioFrame_switch);
        mPublishAudioSwitch.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if(mAliRtcEngine == null) {
                    ToastHelper.showToast(ProcessAudioRawDataActivity.this, getString(R.string.rtc_engine_init_required), Toast.LENGTH_SHORT);
                    mPublishAudioSwitch.setChecked(false);
                    return;
                }
                AliRtcEngine.AliRtcAudioFrameObserverConfig config = new AliRtcEngine.AliRtcAudioFrameObserverConfig();
                config.sampleRate = AliRtcEngine.AliRtcAudioSampleRate.AliRtcAudioSampleRate_48000;
                config.mode = AliRtcEngine.AliRtcAudioFrameObserverOperationMode.AliRtcAudioDataObserverOperationModeReadOnly; // 只能设置为ReadOnly
                config.channels = AliRtcEngine.AliRtcAudioNumChannel.AliRtcMonoAudio;

                mAliRtcEngine.enableAudioFrameObserver(isChecked, AliRtcEngine.AliRtcAudioSource.AliRtcAudioSourcePub, config);
            }
        });

        // Playback Audio Frame (After Mix)
        mPlaybackAudioFrame=findViewById(R.id.audio_playback_switch);
        mPlaybackAudioFrame.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if(mAliRtcEngine == null) {
                    ToastHelper.showToast(ProcessAudioRawDataActivity.this, getString(R.string.rtc_engine_init_required), Toast.LENGTH_SHORT);
                    mPlaybackAudioFrame.setChecked(false);
                    return;
                }
                AliRtcEngine.AliRtcAudioFrameObserverConfig config = new AliRtcEngine.AliRtcAudioFrameObserverConfig();
                config.sampleRate = AliRtcEngine.AliRtcAudioSampleRate.AliRtcAudioSampleRate_48000;
                config.mode = AliRtcEngine.AliRtcAudioFrameObserverOperationMode.AliRtcAudioDataObserverOperationModeReadOnly;
                config.channels = AliRtcEngine.AliRtcAudioNumChannel.AliRtcMonoAudio;

                mAliRtcEngine.enableAudioFrameObserver(isChecked, AliRtcEngine.AliRtcAudioSource.AliRtcAudioSourcePlayback, config);
            }
        });

        // Remote User Audio Frame
        mRemoteUserAudioFrame = findViewById(R.id.RemoteUserAudioFrame);
        mRemoteUserAudioFrame.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if(mAliRtcEngine == null) {
                    ToastHelper.showToast(ProcessAudioRawDataActivity.this, getString(R.string.rtc_engine_init_required), Toast.LENGTH_SHORT);
                    mRemoteUserAudioFrame.setChecked(false);
                    return;
                }
                // 可以设置读写模式，但是无法设置采样率、声道数
                AliRtcEngine.AliRtcAudioFrameObserverConfig config = new AliRtcEngine.AliRtcAudioFrameObserverConfig();
                config.mode = AliRtcEngine.AliRtcAudioFrameObserverOperationMode.AliRtcAudioDataObserverOperationModeReadOnly;

                mAliRtcEngine.enableAudioFrameObserver(isChecked, AliRtcEngine.AliRtcAudioSource.AliRtcAudioSourceRemoteUser, config);
            }
        });
    }

    public static void startActionActivity(Activity activity) {
        Intent intent = new Intent(activity, ProcessAudioRawDataActivity.class);
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
        } else {
            return null;
        }
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

        //添加音频帧原始数据回调监听器
        mAliRtcEngine.registerAudioFrameObserver(rtcAudioFrameObserver);

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
        aliRtcVideoEncoderConfiguration.orientationMode = AliRtcEngine.AliRtcVideoEncoderOrientationMode.AliRtcVideoEncoderOrientationModeAdaptive;
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

            if (fl_local.getChildCount() > 0) {
                fl_local.removeAllViews();
            }

            findViewById(R.id.ll_video_layout).setVisibility(VISIBLE);
            ViewGroup.LayoutParams layoutParams = new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
            if(mLocalVideoCanvas == null) {
                mLocalVideoCanvas = new AliRtcEngine.AliRtcVideoCanvas();
                SurfaceView localSurfaceView = mAliRtcEngine.createRenderSurfaceView(ProcessAudioRawDataActivity.this);
                localSurfaceView.setZOrderOnTop(true);
                localSurfaceView.setZOrderMediaOverlay(true);
                fl_local.addView(localSurfaceView, layoutParams);
                mLocalVideoCanvas.view = localSurfaceView;
                mAliRtcEngine.setLocalViewConfig(mLocalVideoCanvas, AliRtcVideoTrackCamera);
                mAliRtcEngine.startPreview();
            }
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


    private AliRtcEngineEventListener mRtcEngineEventListener = new AliRtcEngineEventListener() {
        @Override
        public void onJoinChannelResult(int result, String channel, String userId, int elapsed) {
            super.onJoinChannelResult(result, channel, userId, elapsed);
            handleJoinResult(result, channel, userId);
        }

        @Override
        public void onLeaveChannelResult(int result, AliRtcEngine.AliRtcStats stats){
            super.onLeaveChannelResult(result, stats);

            //离开频道后，需要移除音频帧原始数据回调监听器
            if(rtcAudioFrameObserver != null) {
                mAliRtcEngine.registerAudioFrameObserver(null);
            }
        }

        @Override
        public void onConnectionStatusChange(AliRtcEngine.AliRtcConnectionStatus status, AliRtcEngine.AliRtcConnectionStatusChangeReason reason){
            super.onConnectionStatusChange(status, reason);

            handler.post(new Runnable() {
                @Override
                public void run() {
                    if(status == AliRtcEngine.AliRtcConnectionStatus.AliRtcConnectionStatusFailed) {
                        /* TODO: 务必处理；建议业务提示客户，此时SDK内部已经尝试了各种恢复策略已经无法继续使用时才会上报 */
                        ToastHelper.showToast(ProcessAudioRawDataActivity.this, R.string.video_chat_connection_failed, Toast.LENGTH_SHORT);
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
                    ToastHelper.showToast(ProcessAudioRawDataActivity.this, str, Toast.LENGTH_SHORT);
                }
            });
        }

    };

    private final AliRtcEngine.AliRtcAudioFrameObserver rtcAudioFrameObserver = new AliRtcEngine.AliRtcAudioFrameObserver() {
        @Override
        public boolean onCapturedAudioFrame(AliRtcEngine.AliRtcAudioFrame frame) {
            // 本地采集音频数据回调，根据业务场景进行处理
            Log.i(TAG, "onCaptureAudioFrame");
            return true;
        }

        @Override
        public boolean onProcessCapturedAudioFrame(AliRtcEngine.AliRtcAudioFrame frame) {
            // 3A后数据回调，根据业务场景进行处理
            Log.i(TAG, "onProcessCaptureAudioFrame");
            return true;
        }

        @Override
        public boolean onPublishAudioFrame(AliRtcEngine.AliRtcAudioFrame frame) {
            // 推流音频数据回调，根据业务场景进行处理
            Log.i(TAG, "onPublishAudioFrame");
            return true;
        }

        @Override
        public boolean onPlaybackAudioFrame(AliRtcEngine.AliRtcAudioFrame frame) {
            // 播放数据（混音后），根据业务场景进行处理
            Log.i(TAG, "onPlaybackAudioFrame");
            return true;
        }

        @Override
        @Deprecated
        public boolean onMixedAllAudioFrame(AliRtcEngine.AliRtcAudioFrame frame) {
            // 该方法已弃用
            return true;
        }

        @Override
        public boolean onRemoteUserAudioFrame(String uid, AliRtcEngine.AliRtcAudioFrame frame) {
            // 远端用户拉流音频数据，根据业务场景进行处理
            Log.i(TAG, "onRemoteUserAudioFrame");
            return true;
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
                    if(videoTrack == AliRtcVideoTrackCamera) {
                        SurfaceView surfaceView = mAliRtcEngine.createRenderSurfaceView(ProcessAudioRawDataActivity.this);
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
                    ToastHelper.showToast(ProcessAudioRawDataActivity.this, msg, Toast.LENGTH_SHORT);
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
        findViewById(R.id.ll_video_layout).setVisibility(View.GONE);
        fl_local.removeAllViews();
        mLocalVideoCanvas = null;
    }
}