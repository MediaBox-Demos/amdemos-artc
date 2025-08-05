package com.aliyun.artc.api.advancedusage.ProcessAudioRawData;

import static android.view.View.VISIBLE;
import static com.alivc.rtc.AliRtcEngine.AliRtcAudioSampleRate.AliRtcAudioSampleRate_48000;
import static com.alivc.rtc.AliRtcEngine.AliRtcAudioSource.AliRtcAudioSourcePlayback;
import static com.alivc.rtc.AliRtcEngine.AliRtcAudioSource.AliRtcAudioSourceProcessCaptured;
import static com.alivc.rtc.AliRtcEngine.AliRtcAudioSource.AliRtcAudioSourceRemoteUser;
import static com.alivc.rtc.AliRtcEngine.AliRtcVideoEncoderOrientationMode.AliRtcVideoEncoderOrientationModeAdaptive;
import static com.alivc.rtc.AliRtcEngine.AliRtcVideoTrack.AliRtcVideoTrackCamera;
import static com.alivc.rtc.AliRtcEngine.AliRtcVideoTrack.AliRtcVideoTrackNo;

import android.annotation.SuppressLint;
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


import android.media.AudioFormat;
import android.media.AudioManager;
import android.media.AudioTrack;

/**
 * 获取音频原始数据API调用示例
 */
public class ProcessAudioRawDataActivity extends AppCompatActivity {

    private Handler handler;
    private EditText mChannelEditText;
    private TextView mJoinChannelTextView;
    private SwitchCompat mPlaybackAudioFrame;
    private SwitchCompat mRemoteUserAudioFrame;
    private SwitchCompat mProcessCapturedAudioSwitch;
    private SwitchCompat mPublishAudioSwitch;
    private SwitchCompat mCapturedAudioFrame;

    private boolean hasJoined = false;
    private FrameLayout fl_local, fl_remote, fl_remote_2, fl_remote_3;

    private AliRtcEngine mAliRtcEngine = null;
    private AliRtcEngine.AliRtcVideoCanvas mLocalVideoCanvas = null;
    private Map<String, ViewGroup> remoteViews = new ConcurrentHashMap<String, ViewGroup>();


    private AudioTrack mAudioTrack= null;
    private boolean isAudioTrackInitialized = false;
    private int currentSampleRate = -1;
    private int currentChannelCount = -1;
    @SuppressLint("MissingInflatedId")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        handler = new Handler(Looper.getMainLooper());
        EdgeToEdge.enable(this);
        setContentView(R.layout.audio_capture);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.audioCap), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });
        setTitle(getString(R.string.audio_raw));
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);

        fl_local = findViewById(R.id.fl_local);
        fl_remote = findViewById(R.id.fl_remote);

        mChannelEditText = findViewById(R.id.channel_id_input);
        mChannelEditText.setText(GlobalConfig.getInstance().gerRandomChannelId());
        mJoinChannelTextView = findViewById(R.id.join_room_btn);
        mJoinChannelTextView.setOnClickListener(v -> {
            if(hasJoined) {
                destroyRtcEngine();
                mJoinChannelTextView.setText(R.string.video_chat_join_room);
            } else {
                // 重复入会时需要重新初始化引擎
                if(mAliRtcEngine == null) {
                    initAndSetupRtcEngine();
                }
                startRTCCall();
            }
        });
        
        // 初始化并设置 SwitchCompat 触发事件

        mPlaybackAudioFrame=findViewById(R.id.audio_playback_switch);
        //负责获取远程音频，混音处理后，播放前的数据
        mPlaybackAudioFrame.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if(mAliRtcEngine == null) {
                    ToastHelper.showToast(ProcessAudioRawDataActivity.this, getString(R.string.rtc_engine_init_required), Toast.LENGTH_SHORT);
                    mPlaybackAudioFrame.setChecked(false);
                    return;
                }
                AliRtcEngine.AliRtcAudioFrameObserverConfig config = null;
                config = new AliRtcEngine.AliRtcAudioFrameObserverConfig();
                config.sampleRate = AliRtcAudioSampleRate_48000;

                if (isChecked) {
                    if(mAliRtcEngine.enableAudioFrameObserver(true, AliRtcAudioSourcePlayback, config) == 0){
                        ToastHelper.showToast(ProcessAudioRawDataActivity.this, getString(R.string.start_raw_data_callback), Toast.LENGTH_SHORT);

                    } else {
                        ToastHelper.showToast(ProcessAudioRawDataActivity.this, getString(R.string.get_raw_data_failed), Toast.LENGTH_SHORT);
                        mPlaybackAudioFrame.setChecked(false);
                    }
                } else {
                    if(mAliRtcEngine.enableAudioFrameObserver(false, AliRtcAudioSourcePlayback, config) == 0){
                        ToastHelper.showToast(ProcessAudioRawDataActivity.this, getString(R.string.stop_raw_data_callback), Toast.LENGTH_SHORT);
                        if (mAudioTrack != null) {
                            try {
                                mAudioTrack.stop();
                                mAudioTrack.release();
                                mAudioTrack = null;
                            } catch (Exception e) {
                                Log.e("AudioCapture", "释放AudioTrack失败: " + e.getMessage());
                            }
                        }
                    } else {
                        ToastHelper.showToast(ProcessAudioRawDataActivity.this, getString(R.string.stop_raw_data_failed), Toast.LENGTH_SHORT);
                        mPlaybackAudioFrame.setChecked(true);
                    }
                }
            }
        });

        mRemoteUserAudioFrame = findViewById(R.id.RemoteUserAudioFrame);
        mRemoteUserAudioFrame.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if(mAliRtcEngine == null) {
                    ToastHelper.showToast(ProcessAudioRawDataActivity.this, getString(R.string.rtc_engine_init_required), Toast.LENGTH_SHORT);
                    mRemoteUserAudioFrame.setChecked(false);
                    return;
                }
                if(isChecked){
                    AliRtcEngine.AliRtcAudioFrameObserverConfig config = new AliRtcEngine.AliRtcAudioFrameObserverConfig();
                    config.mode=AliRtcEngine.AliRtcAudioFrameObserverOperationMode.AliRtcAudioDataObserverOperationModeReadWrite;
                    if(mAliRtcEngine.enableAudioFrameObserver(true, AliRtcAudioSourceRemoteUser, config) == 0){
                        ToastHelper.showToast(ProcessAudioRawDataActivity.this, "start onRemoteUserAudioFrame", Toast.LENGTH_SHORT);
                    } else {
                        ToastHelper.showToast(ProcessAudioRawDataActivity.this, "start onRemoteUserAudioFrame failed", Toast.LENGTH_SHORT);
                        mRemoteUserAudioFrame.setChecked(false);
                    }
                }else {
                    AliRtcEngine.AliRtcAudioFrameObserverConfig config = new AliRtcEngine.AliRtcAudioFrameObserverConfig();
                    config.mode=AliRtcEngine.AliRtcAudioFrameObserverOperationMode.AliRtcAudioDataObserverOperationModeReadWrite;
                    if(mAliRtcEngine.enableAudioFrameObserver(false, AliRtcAudioSourceRemoteUser, config) == 0){
                        ToastHelper.showToast(ProcessAudioRawDataActivity.this, "stop onRemoteUserAudioFrame", Toast.LENGTH_SHORT);
                    } else {
                        ToastHelper.showToast(ProcessAudioRawDataActivity.this, "stop onRemoteUserAudioFrame failed", Toast.LENGTH_SHORT);
                        mRemoteUserAudioFrame.setChecked(true);
                    }
                }
            }
        });

        mProcessCapturedAudioSwitch = findViewById(R.id.process_captured_audio_switch);
        mProcessCapturedAudioSwitch.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if(mAliRtcEngine == null) {
                    ToastHelper.showToast(ProcessAudioRawDataActivity.this, getString(R.string.rtc_engine_init_required), Toast.LENGTH_SHORT);
                    mProcessCapturedAudioSwitch.setChecked(false);
                    return;
                }
                if(isChecked){
                    AliRtcEngine.AliRtcAudioFrameObserverConfig config = new AliRtcEngine.AliRtcAudioFrameObserverConfig();

                    config.mode=AliRtcEngine.AliRtcAudioFrameObserverOperationMode.AliRtcAudioDataObserverOperationModeReadWrite;
                    config.sampleRate = AliRtcAudioSampleRate_48000;
                    config.channels=AliRtcEngine.AliRtcAudioNumChannel.AliRtcMonoAudio;   //默认设置，可以修改

                    if(mAliRtcEngine.enableAudioFrameObserver(true, AliRtcAudioSourceProcessCaptured, config) == 0){
                        ToastHelper.showToast(ProcessAudioRawDataActivity.this, "start ProcessCapturedAudioSwitch", Toast.LENGTH_SHORT);
                    } else {
                        ToastHelper.showToast(ProcessAudioRawDataActivity.this, "start ProcessCapturedAudioSwitch failed", Toast.LENGTH_SHORT);
                        mRemoteUserAudioFrame.setChecked(false);
                    }
                }else {

                    AliRtcEngine.AliRtcAudioFrameObserverConfig config = new AliRtcEngine.AliRtcAudioFrameObserverConfig();
                    config.mode=AliRtcEngine.AliRtcAudioFrameObserverOperationMode.AliRtcAudioDataObserverOperationModeReadWrite;
                    config.sampleRate = AliRtcAudioSampleRate_48000;
                    config.channels=AliRtcEngine.AliRtcAudioNumChannel.AliRtcMonoAudio;   //默认设置，可以修改

                    if(mAliRtcEngine.enableAudioFrameObserver(false, AliRtcAudioSourceProcessCaptured, config) == 0){
                        ToastHelper.showToast(ProcessAudioRawDataActivity.this, "stop ProcessCapturedAudioSwitch", Toast.LENGTH_SHORT);
                    } else {
                        ToastHelper.showToast(ProcessAudioRawDataActivity.this, "stop ProcessCapturedAudioSwitch failed", Toast.LENGTH_SHORT);
                        mRemoteUserAudioFrame.setChecked(true);
                    }
                }
            }
        });

        mPublishAudioSwitch = findViewById(R.id.PublishAudioFrame_switch);
        mPublishAudioSwitch.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if(mAliRtcEngine == null) {
                    ToastHelper.showToast(ProcessAudioRawDataActivity.this, getString(R.string.rtc_engine_init_required), Toast.LENGTH_SHORT);
                    mPublishAudioSwitch.setChecked(false);
                    return;
                }
                if(isChecked){
                    AliRtcEngine.AliRtcAudioFrameObserverConfig config = new AliRtcEngine.AliRtcAudioFrameObserverConfig();

                    config.mode=AliRtcEngine.AliRtcAudioFrameObserverOperationMode.AliRtcAudioDataObserverOperationModeReadOnly;
                    config.sampleRate = AliRtcAudioSampleRate_48000;//默认设置，可以修改
                    config.channels=AliRtcEngine.AliRtcAudioNumChannel.AliRtcMonoAudio;   //默认设置，可以修改

                    if(mAliRtcEngine.enableAudioFrameObserver(true, AliRtcEngine.AliRtcAudioSource.AliRtcAudioSourcePub, config) == 0){
                        ToastHelper.showToast(ProcessAudioRawDataActivity.this, "start PublishAudioFrame", Toast.LENGTH_SHORT);
                    } else {
                        ToastHelper.showToast(ProcessAudioRawDataActivity.this, "start PublishAudioFrame failed", Toast.LENGTH_SHORT);
                        mRemoteUserAudioFrame.setChecked(false);
                    }
                }else {

                    AliRtcEngine.AliRtcAudioFrameObserverConfig config = new AliRtcEngine.AliRtcAudioFrameObserverConfig();
                    config.mode=AliRtcEngine.AliRtcAudioFrameObserverOperationMode.AliRtcAudioDataObserverOperationModeReadOnly;
                    config.sampleRate = AliRtcAudioSampleRate_48000;//默认设置，可以修改
                    config.channels=AliRtcEngine.AliRtcAudioNumChannel.AliRtcMonoAudio;   //默认设置，可以修改

                    if(mAliRtcEngine.enableAudioFrameObserver(false, AliRtcEngine.AliRtcAudioSource.AliRtcAudioSourcePub, config) == 0){
                        ToastHelper.showToast(ProcessAudioRawDataActivity.this, "stop PublishAudioFrame", Toast.LENGTH_SHORT);
                    } else {
                        ToastHelper.showToast(ProcessAudioRawDataActivity.this, "stop PublishAudioFrame failed", Toast.LENGTH_SHORT);
                        mRemoteUserAudioFrame.setChecked(true);
                    }
                }
            }
        });

        mCapturedAudioFrame = findViewById(R.id.CapturedAudioFrame_Switch);
        mCapturedAudioFrame.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if(mAliRtcEngine == null) {
                    ToastHelper.showToast(ProcessAudioRawDataActivity.this, getString(R.string.rtc_engine_init_required), Toast.LENGTH_SHORT);
                    mCapturedAudioFrame.setChecked(false);
                    return;
                }
                if(isChecked){
                    AliRtcEngine.AliRtcAudioFrameObserverConfig config = new AliRtcEngine.AliRtcAudioFrameObserverConfig();

                    config.mode=AliRtcEngine.AliRtcAudioFrameObserverOperationMode.AliRtcAudioDataObserverOperationModeReadWrite;
                    config.sampleRate = AliRtcAudioSampleRate_48000;//默认设置，可以修改
                    config.channels=AliRtcEngine.AliRtcAudioNumChannel.AliRtcMonoAudio;   //默认设置，可以修改

                    if(mAliRtcEngine.enableAudioFrameObserver(true, AliRtcEngine.AliRtcAudioSource.AliRtcAudioSourceCaptured, config) == 0){
                        ToastHelper.showToast(ProcessAudioRawDataActivity.this, "start onCapturedAudioFrame", Toast.LENGTH_SHORT);
                    } else {
                        ToastHelper.showToast(ProcessAudioRawDataActivity.this, "start onCapturedAudioFrame failed", Toast.LENGTH_SHORT);
                        mRemoteUserAudioFrame.setChecked(false);
                    }
                }else {

                    AliRtcEngine.AliRtcAudioFrameObserverConfig config = new AliRtcEngine.AliRtcAudioFrameObserverConfig();
                    config.mode=AliRtcEngine.AliRtcAudioFrameObserverOperationMode.AliRtcAudioDataObserverOperationModeReadWrite;
                    config.sampleRate = AliRtcAudioSampleRate_48000;//默认设置，可以修改
                    config.channels=AliRtcEngine.AliRtcAudioNumChannel.AliRtcMonoAudio;   //默认设置，可以修改

                    if(mAliRtcEngine.enableAudioFrameObserver(false, AliRtcEngine.AliRtcAudioSource.AliRtcAudioSourceCaptured, config) == 0){
                        ToastHelper.showToast(ProcessAudioRawDataActivity.this, "stop onCapturedAudioFrame", Toast.LENGTH_SHORT);
                    } else {
                        ToastHelper.showToast(ProcessAudioRawDataActivity.this, "stop onCapturedAudioFrame failed", Toast.LENGTH_SHORT);
                        mRemoteUserAudioFrame.setChecked(true);
                    }
                }
            }
        });

        initAndSetupRtcEngine();
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
        mAliRtcEngine.registerAudioFrameObserver(m_rtcobserver);



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
            if(m_rtcobserver != null) {
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

    private AliRtcEngine.AliRtcAudioFrameObserver m_rtcobserver = new AliRtcEngine.AliRtcAudioFrameObserver() {

        private void initAudioTrack(int sampleRate, int channelCount, int bytesPerSample) {
            try {
                if (mAudioTrack != null) {
                    mAudioTrack.stop();
                    mAudioTrack.release();
                }

                int channelConfig = channelCount == 1 ?
                        AudioFormat.CHANNEL_OUT_MONO : AudioFormat.CHANNEL_OUT_STEREO;
                int audioFormat = bytesPerSample == 2 ?
                        AudioFormat.ENCODING_PCM_16BIT : AudioFormat.ENCODING_PCM_8BIT;

                int bufferSize = AudioTrack.getMinBufferSize(sampleRate, channelConfig, audioFormat);
                bufferSize = Math.max(bufferSize, sampleRate * channelCount * bytesPerSample / 10);

                mAudioTrack = new AudioTrack(
                        AudioManager.STREAM_MUSIC,
                        sampleRate,
                        channelConfig,
                        audioFormat,
                        bufferSize,
                        AudioTrack.MODE_STREAM
                );

                if (mAudioTrack.getState() == AudioTrack.STATE_INITIALIZED) {
                    mAudioTrack.play();
                    currentSampleRate = sampleRate;
                    currentChannelCount = channelCount;
                    isAudioTrackInitialized = true;
                }
            } catch (Exception e) {
                Log.e("AudioCapture", "初始化AudioTrack失败: " + e.getMessage());
                isAudioTrackInitialized = false;
            }
        }

        /**
         * 检测字节数组是否全为0
         * @param data 要检测的字节数组
         * @return true表示数组全为0或为空，false表示数组包含非0数据
         */
        private boolean isAllZeroArray(byte[] data) {
            if (data == null || data.length == 0) {
                return true;
            }
            for (byte b : data) {
                if (b != 0) {
                    return false;
                }
            }
            return true;
        }

        @Override
        public boolean onCapturedAudioFrame(AliRtcEngine.AliRtcAudioFrame frame) {
            Log.d("AudioCapture", "onCapturedAudioFrame");
            //该方法负责获取本地采集的裸数据
            return true;
        }

        @Override
        public boolean onProcessCapturedAudioFrame(AliRtcEngine.AliRtcAudioFrame frame) {
            Log.d("AudioCapture", "onProcessCapturedAudioFrame");
//            handler.post(new Runnable() {
//                @Override
//                public void run() {
//                    ToastHelper.showToast(AudioCaptureActivity.this, "onProcessCapturedAudioFrame", Toast.LENGTH_SHORT);
//                }
//            });
            //该方法负责获取本地采集、3A处理后的数据
            return true;
        }

        @Override
        public boolean onPublishAudioFrame(AliRtcEngine.AliRtcAudioFrame frame) {
            Log.d("AudioCapture", "onPublishAudioFrame");
//            handler.post(new Runnable() {
//                @Override
//                public void run() {
//                    ToastHelper.showToast(AudioCaptureActivity.this, "onPublishAudioFrame", Toast.LENGTH_SHORT);
//                }
//            });
            //该方法负责获取本地采集、处理、编码后，准备推流的数据，只读模式
            return true;
        }

        @Override
        public boolean onPlaybackAudioFrame(AliRtcEngine.AliRtcAudioFrame frame) {
//该方法获得将所有用户的音频混音处理后得到的音频数据，供直接播放使用
            Log.d("AudioCapture", "onPlaybackAudioFrame");

            if (frame != null && frame.data != null) {

                // 数据有效性检查，包括全0数组检测
                if (frame == null || frame.data == null || frame.data.length == 0 ||
                    frame.samplesPerSec <= 0 || frame.numChannels <= 0 || frame.bytesPerSample <= 0 ||
                    isAllZeroArray(frame.data)) {
                    // 跳过无效数据，等待下次回调
                    Log.d("AudioCapture", "跳过无效音频帧 - 采样率: " +
                            (frame != null ? frame.samplesPerSec : "null") +
                            ", 数据长度: " + (frame != null && frame.data != null ? frame.data.length : "null") +
                            ", 是否全0数组: " + (frame != null && frame.data != null ? isAllZeroArray(frame.data) : "null"));
                    return true;
                }
                // 检查音频参数是否变化
                if (!isAudioTrackInitialized || currentSampleRate != frame.samplesPerSec || currentChannelCount != frame.numChannels)
                {
                    initAudioTrack(frame.samplesPerSec, frame.numChannels, frame.bytesPerSample);
                }

                // 播放音频数据
                if (isAudioTrackInitialized && mAudioTrack != null) {
                    try {
                        int dataLength = frame.numSamples * frame.numChannels * frame.bytesPerSample;
                        if (dataLength <= frame.data.length) {
                            mAudioTrack.write(frame.data, 0, dataLength);
                        }
                    } catch (Exception e) {
                        Log.e("AudioCapture", "播放音频失败: " + e.getMessage());
                    }
                }
            }

//            handler.post(new Runnable() {
//                @Override
//                public void run() {
//                    ToastHelper.showToast(AudioCaptureActivity.this, "onLocalAudioSample", Toast.LENGTH_SHORT);
//                }
//            });
            return true;
        }

        @Override
        public boolean onMixedAllAudioFrame(AliRtcEngine.AliRtcAudioFrame frame) {
            return true;
            //该方法已被弃用
        }


        @Override
        public boolean onRemoteUserAudioFrame(String uid, AliRtcEngine.AliRtcAudioFrame frame) { //该方法负责获取当前单个用户的音频数据
            Log.d("AudioCapture", "onRemoteUserAudioFrame: ");
            //            handler.post(new Runnable() {
//                @Override
//                public void run() {
//                    ToastHelper.showToast(AudioCaptureActivity.this, "onRemoteUserAudioFrame", Toast.LENGTH_SHORT);
//                }
//            });
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