package com.aliyun.artc.api.advancedusage.CustomAudioCaptureAndRender;

import static android.view.View.VISIBLE;
import static com.alivc.rtc.AliRtcEngine.AliRtcAudioSampleRate.AliRtcAudioSampleRate_48000;
import static com.alivc.rtc.AliRtcEngine.AliRtcAudioSource.AliRtcAudioSourcePlayback;
import static com.alivc.rtc.AliRtcEngine.AliRtcVideoEncoderOrientationMode.AliRtcVideoEncoderOrientationModeAdaptive;
import static com.alivc.rtc.AliRtcEngine.AliRtcVideoTrack.AliRtcVideoTrackCamera;
import static com.alivc.rtc.AliRtcEngine.AliRtcVideoTrack.AliRtcVideoTrackNo;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Intent;
import android.media.AudioFormat;
import android.media.AudioManager;
import android.media.AudioTrack;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;
import android.util.Log;
import android.view.MenuItem;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.CompoundButton;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.SwitchCompat;
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
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * 外部音频渲染API调用示例
 */
public class CustomAudioRenderActivity extends AppCompatActivity {
    private static final String TAG = CustomAudioRenderActivity.class.getSimpleName();
    private Handler handler;
    private EditText mChannelEditText;
    private TextView mJoinChannelTextView;
    private SwitchCompat mCustomAudioRenderSwitch;

    private boolean hasJoined = false;
    private FrameLayout fl_local, fl_remote, fl_remote_2, fl_remote_3;

    private AliRtcEngine mAliRtcEngine = null;
    private AliRtcEngine.AliRtcVideoCanvas mLocalVideoCanvas = null;
    private Map<String, ViewGroup> remoteViews = new ConcurrentHashMap<String, ViewGroup>();

    // 音频播放相关变量
    private AudioTrack mAudioTrack= null;
    private boolean isAudioTrackInitialized = false;
    private int currentSampleRate = -1;
    private int currentChannelCount = -1;

    private BlockingQueue<AliRtcEngine.AliRtcAudioFrame> audioFrameQueue;
    private AudioPlayerThread audioPlayerThread;
    private AtomicBoolean isAudioPlayerThreadRunning;

    @SuppressLint("MissingInflatedId")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        handler = new Handler(Looper.getMainLooper());
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_custom_audio_render);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.custom_audio_render), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });
        setTitle(getString(R.string.custom_playback));
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);

        initAndSetupRtcEngine();

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

        mCustomAudioRenderSwitch =findViewById(R.id.audio_playback_switch);
        //负责获取远程音频，混音处理后，播放前的数据
        mCustomAudioRenderSwitch.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if(mAliRtcEngine == null) {
                    ToastHelper.showToast(CustomAudioRenderActivity.this, getString(R.string.rtc_engine_init_required), Toast.LENGTH_SHORT);
                    mCustomAudioRenderSwitch.setChecked(false);
                    return;
                }
                AliRtcEngine.AliRtcAudioFrameObserverConfig config = new AliRtcEngine.AliRtcAudioFrameObserverConfig();
                config.sampleRate = AliRtcAudioSampleRate_48000;
                config.channels = AliRtcEngine.AliRtcAudioNumChannel.AliRtcMonoAudio;

                if (isChecked) {//打开了外部播放，所以要关闭内部播放
                    if(mAliRtcEngine.enableAudioFrameObserver(true, AliRtcAudioSourcePlayback, config) == 0){
                        String parameter = "{\"audio\":{\"enable_system_audio_device_play\":\"FALSE\"}}";
                        mAliRtcEngine.setParameter(parameter);
                        ToastHelper.showToast(CustomAudioRenderActivity.this, getString(R.string.start_raw_data_callback), Toast.LENGTH_SHORT);

                    } else {
                        ToastHelper.showToast(CustomAudioRenderActivity.this, getString(R.string.get_raw_data_failed), Toast.LENGTH_SHORT);
                        mCustomAudioRenderSwitch.setChecked(false);
                    }
                } else {//关闭外部播放，打开内部播放/* 动态打开阿里内部采集 */
                    if(mAliRtcEngine.enableAudioFrameObserver(false, AliRtcAudioSourcePlayback, config) == 0){
                        ToastHelper.showToast(CustomAudioRenderActivity.this, getString(R.string.stop_External_playback), Toast.LENGTH_SHORT);
                        String parameter = "{\"audio\":{\"enable_system_audio_device_play\":\"TRUE\"}}";
                        mAliRtcEngine.setParameter(parameter);
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
                        ToastHelper.showToast(CustomAudioRenderActivity.this, getString(R.string.stop_raw_data_failed), Toast.LENGTH_SHORT);
                        mCustomAudioRenderSwitch.setChecked(true);
                    }
                }
            }
        });
    }

    public static void startActionActivity(Activity activity) {
        Intent intent = new Intent(activity, CustomAudioRenderActivity.class);
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
        // 初始化音频播放线程
        startAudioPlayerThread();
        joinChannel();
    }

    private void initAndSetupRtcEngine() {

        //创建并初始化引擎
        if(mAliRtcEngine == null) {
            String extras = "{\"user_specified_use_external_audio_player\":\"TRUE\"}";
            mAliRtcEngine = AliRtcEngine.getInstance(this, extras);
        }
        mAliRtcEngine.setRtcEngineEventListener(mRtcEngineEventListener);
        mAliRtcEngine.setRtcEngineNotify(mRtcEngineNotify);

        //添加音频帧原始数据回调监听器
        mAliRtcEngine.registerAudioFrameObserver(aliRtcAudioFrameObserver);

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
                SurfaceView localSurfaceView = mAliRtcEngine.createRenderSurfaceView(CustomAudioRenderActivity.this);
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


    private final AliRtcEngineEventListener mRtcEngineEventListener = new AliRtcEngineEventListener() {
        @Override
        public void onJoinChannelResult(int result, String channel, String userId, int elapsed) {
            super.onJoinChannelResult(result, channel, userId, elapsed);
            handleJoinResult(result, channel, userId);
        }

        @Override
        public void onLeaveChannelResult(int result, AliRtcEngine.AliRtcStats stats){
            super.onLeaveChannelResult(result, stats);

            //离开频道后，需要移除音频帧原始数据回调监听器
            mAliRtcEngine.registerAudioFrameObserver(null);
        }

        @Override
        public void onConnectionStatusChange(AliRtcEngine.AliRtcConnectionStatus status, AliRtcEngine.AliRtcConnectionStatusChangeReason reason){
            super.onConnectionStatusChange(status, reason);

            handler.post(new Runnable() {
                @Override
                public void run() {
                    if(status == AliRtcEngine.AliRtcConnectionStatus.AliRtcConnectionStatusFailed) {
                        /* TODO: 务必处理；建议业务提示客户，此时SDK内部已经尝试了各种恢复策略已经无法继续使用时才会上报 */
                        ToastHelper.showToast(CustomAudioRenderActivity.this, R.string.video_chat_connection_failed, Toast.LENGTH_SHORT);
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
                    ToastHelper.showToast(CustomAudioRenderActivity.this, str, Toast.LENGTH_SHORT);
                }
            });
        }

    };

    private final AliRtcEngine.AliRtcAudioFrameObserver aliRtcAudioFrameObserver = new AliRtcEngine.AliRtcAudioFrameObserver() {
        @Override
        public boolean onCapturedAudioFrame(AliRtcEngine.AliRtcAudioFrame frame) {
            Log.d("AudioCapture", "onCapturedAudioFrame");
            //该方法负责获取本地采集的裸数据
            return true;
        }

        @Override
        public boolean onProcessCapturedAudioFrame(AliRtcEngine.AliRtcAudioFrame frame) {
            Log.d("AudioCapture", "onProcessCapturedAudioFrame");
            return true;
        }

        @Override
        public boolean onPublishAudioFrame(AliRtcEngine.AliRtcAudioFrame frame) {
            Log.d("AudioCapture", "onPublishAudioFrame");
            return true;
        }

        @Override
        public boolean onPlaybackAudioFrame(AliRtcEngine.AliRtcAudioFrame frame) {
            // 数据有效性检查
            if(frame == null || frame.data == null || frame.samplesPerSec <= 0 || frame.numChannels <= 0 || frame.bytesPerSample <= 0){
                Log.e(TAG, "Invalid Audio Frame!");
                return true;
            }

            if (audioFrameQueue != null) {
                try {
                    // 创建音频帧的副本以避免数据竞争
                    AliRtcEngine.AliRtcAudioFrame frameCopy = new AliRtcEngine.AliRtcAudioFrame();
                    frameCopy.data = frame.data.clone();
                    frameCopy.numSamples = frame.numSamples;
                    frameCopy.samplesPerSec = frame.samplesPerSec;
                    frameCopy.numChannels = frame.numChannels;
                    frameCopy.bytesPerSample = frame.bytesPerSample;

                    // 添加到队列，如果队列满了就丢弃旧数据
                    if (!audioFrameQueue.offer(frameCopy)) {
                        audioFrameQueue.poll(); // 移除最旧的帧
                        audioFrameQueue.offer(frameCopy); // 添加新帧
                    }
                } catch (Exception e) {
                    Log.e("AudioCapture", "添加音频帧到队列失败: " + e.getMessage());
                }
            }
            return true;
        }

        @Override
        public boolean onMixedAllAudioFrame(AliRtcEngine.AliRtcAudioFrame frame) {
            return false;
        }

        @Override
        public boolean onRemoteUserAudioFrame(String uid, AliRtcEngine.AliRtcAudioFrame frame) { //该方法负责获取当前单个用户的音频数据
            Log.d("AudioCapture", "onRemoteUserAudioFrame: ");
            return true;
        }

    };

    private class AudioPlayerThread extends Thread {
        @Override
        public void run() {
            android.os.Process.setThreadPriority(android.os.Process.THREAD_PRIORITY_URGENT_AUDIO);

            while (isAudioPlayerThreadRunning.get()) {
                try {
                    AliRtcEngine.AliRtcAudioFrame frame = audioFrameQueue.take();

                    // 检查音频参数是否变化
                    if (!isAudioTrackInitialized || currentSampleRate != frame.samplesPerSec || currentChannelCount != frame.numChannels) {
                        // 在音频播放线程中初始化AudioTrack
                        initAudioTrackInPlayerThread(frame.samplesPerSec, frame.numChannels, frame.bytesPerSample);
                    }

                    // 播放音频数据（包括全0数据，以保证AEC正常工作）
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
                } catch (InterruptedException e) {
                    // 线程被中断，正常退出
                    break;
                } catch (Exception e) {
                    Log.e("AudioCapture", "音频播放线程异常: " + e.getMessage());
                }
            }
        }
    }

    private void initAudioTrackInPlayerThread(int sampleRate, int channelCount, int bytesPerSample) {
        try {
            // 如果已有AudioTrack实例，先释放它
            releaseAudioTrack();

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
                Log.d("AudioCapture", "AudioTrack初始化成功，采样率: " + sampleRate + "，声道数: " + channelCount);
            } else {
                Log.e("AudioCapture", "AudioTrack初始化失败");
                isAudioTrackInitialized = false;
            }
        } catch (Exception e) {
            Log.e("AudioCapture", "初始化AudioTrack失败: " + e.getMessage());
            isAudioTrackInitialized = false;
        }
    }

    // 启动音频播放线程
    private void startAudioPlayerThread() {
        stopAudioPlayerThread(); // 确保之前的线程已停止

        audioFrameQueue = new LinkedBlockingQueue<>(5); // 限制队列大小以避免内存问题
        isAudioPlayerThreadRunning = new AtomicBoolean(true);
        audioPlayerThread = new AudioPlayerThread();
        audioPlayerThread.start();
        Log.d("AudioCapture", "音频播放线程已启动");
    }

    // 停止音频播放线程
    private void stopAudioPlayerThread() {
        if (isAudioPlayerThreadRunning != null) {
            isAudioPlayerThreadRunning.set(false);
        }

        if (audioPlayerThread != null) {
            try {
                audioPlayerThread.interrupt();
                audioPlayerThread.join(1000); // 等待最多1秒
            } catch (InterruptedException e) {
                Log.e("AudioCapture", "等待音频播放线程结束时被中断: " + e.getMessage());
            }
            audioPlayerThread = null;
        }

        if (audioFrameQueue != null) {
            audioFrameQueue.clear();
            audioFrameQueue = null;
        }

        // 释放AudioTrack资源
        releaseAudioTrack();
    }

    // 释放AudioTrack资源的专用方法
    private void releaseAudioTrack() {
        if (mAudioTrack != null) {
            try {
                if (mAudioTrack.getPlayState() == AudioTrack.PLAYSTATE_PLAYING) {
                    mAudioTrack.stop();
                }
                mAudioTrack.release();
            } catch (Exception e) {
                Log.e(TAG, "释放AudioTrack失败: " + e.getMessage());
            } finally {
                mAudioTrack = null;
                isAudioTrackInitialized = false;
                currentSampleRate = -1;
                currentChannelCount = -1;
            }
        }
    }

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

        @Override
        public void onRemoteUserOffLineNotify(String uid, AliRtcEngine.AliRtcUserOfflineReason reason){
            super.onRemoteUserOffLineNotify(uid, reason);
        }

        @Override
        public void onRemoteTrackAvailableNotify(String uid, AliRtcEngine.AliRtcAudioTrack audioTrack, AliRtcEngine.AliRtcVideoTrack videoTrack){
            handler.post(new Runnable() {
                @Override
                public void run() {
                    if(videoTrack == AliRtcVideoTrackCamera) {
                        SurfaceView surfaceView = mAliRtcEngine.createRenderSurfaceView(CustomAudioRenderActivity.this);
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
                    ToastHelper.showToast(CustomAudioRenderActivity.this, msg, Toast.LENGTH_SHORT);
                }
            });
        }
    };

    private void destroyRtcEngine() {
        stopAudioPlayerThread();
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

    @Override
    protected void onDestroy() {
        super.onDestroy();
        stopAudioPlayerThread();
        if (mAliRtcEngine != null) {
            destroyRtcEngine();
        }
    }
}