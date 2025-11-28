package com.aliyun.artc.api.advancedusage.CustomAudioCaptureAndRender;

import static android.view.View.VISIBLE;
import static com.alivc.rtc.AliRtcEngine.AliRtcVideoEncoderOrientationMode.AliRtcVideoEncoderOrientationModeAdaptive;
import static com.alivc.rtc.AliRtcEngine.AliRtcVideoTrack.AliRtcVideoTrackCamera;
import static com.alivc.rtc.AliRtcEngine.AliRtcVideoTrack.AliRtcVideoTrackNo;

import android.annotation.SuppressLint;
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
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.RadioGroup;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.ActionBar;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.SwitchCompat;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import com.alivc.rtc.AliRtcEngine;
import com.alivc.rtc.AliRtcEngineEventListener;
import com.alivc.rtc.AliRtcEngineNotify;
import com.aliyun.artc.api.advancedusage.CustomAudioCaptureAndRender.utils.AudioCaptureCallback;
import com.aliyun.artc.api.advancedusage.CustomAudioCaptureAndRender.utils.FileAudioCaptureThread;
import com.aliyun.artc.api.advancedusage.CustomAudioCaptureAndRender.utils.MicrophoneCaptureThread;
import com.aliyun.artc.api.keycenter.ARTCTokenHelper;
import com.aliyun.artc.api.keycenter.GlobalConfig;
import com.aliyun.artc.api.keycenter.utils.ToastHelper;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import com.aliyun.artc.api.advancedusage.R;

import org.webrtc.alirtcInterface.ErrorCodeEnum;

/**
 * 外部音频采集API调用示例
 */
public class CustomAudioCaptureActivity extends AppCompatActivity implements AudioCaptureCallback {

    private Handler handler;
    private EditText mChannelEditText;
    private TextView mJoinChannelTextView;

    private boolean hasJoined = false;
    private FrameLayout fl_local, fl_remote, fl_remote_2, fl_remote_3;

    private AliRtcEngine mAliRtcEngine = null;
    private AliRtcEngine.AliRtcVideoCanvas mLocalVideoCanvas = null;
    private Map<String, ViewGroup> remoteViews = new ConcurrentHashMap<String, ViewGroup>();

    private int mExternalAudioStreamId; // 音频流ID,addExternalAudioStream的返回值


    // 麦克风采集参数，用于初始化AudioRecord，请根据您的业务场景配置，并自行实现音屏采集逻辑
    private final int mAudioMicrophoneSampleRate = 48000;
    private final int mAudioMicrophoneChannel = 1;
    private final int mAudioMicrophoneBitsPerSample = 16;  // 对应AudioFormat.ENCODING_PCM_16BIT,大部分场景采用16bit位深就足够了

    // 文件音频采集参数，在此演示assets/music.wav文件的参数
    String mFileName = "music.wav";
    private final int mAudioFileSampleRate = 16000;
    private final int mAudioFileChannel = 1;
    private final int mAudioFileBitsPerSample = 16; // 位深

    // 默认10ms送一次数据
    public static final int BUFFER_DURATION = 10; // 10ms

    // 麦克风采集输入 or 外部文件输入
    RadioGroup audioSourceRadioGroup;
    private boolean isMicrophoneCapture = false;
    private MicrophoneCaptureThread microphoneCaptureThread; // 模拟从麦克风采集数据
    private FileAudioCaptureThread fileAudioCaptureThread;   // 模拟从文件中读取数据

    // 是否需要本地播放
    private boolean isLocalPlayout = false;
    private SwitchCompat isLocalPlayoutSwitch;

    // 是否允许录制麦克风采集的数据到文件,主要用于检查传入SDK前采集的数据是否正常
    private SwitchCompat mEnableDumpAudioSwitch;
    private boolean mEnableDumpAudio = false;
    private EditText mDumpAudioFileNameEditText;
    private String dumpAudioFileName = "test.wav";


    @SuppressLint("MissingInflatedId")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        handler = new Handler(Looper.getMainLooper());
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_custom_audio_capture);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.custom_audio_capture), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });
        setTitle(getString(R.string.custom_audio_capture));
        ActionBar actionBar = getSupportActionBar();
        if (actionBar != null) {
            actionBar.setDisplayHomeAsUpEnabled(true);
        }

        // 创建RTC Engine对象
        initRtcEngine();

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
                    initRtcEngine();
                }
                startRTCCall();
            }
        });

        audioSourceRadioGroup = findViewById(R.id.audioSourceRadioGroup);
        audioSourceRadioGroup.setOnCheckedChangeListener(new RadioGroup.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(RadioGroup group, int checkedId) {
                isMicrophoneCapture = checkedId != R.id.localMediaButton;
            }
        });

        isLocalPlayoutSwitch = findViewById(R.id.audio_capture_local_playout_switch);
        isLocalPlayoutSwitch.setOnCheckedChangeListener((buttonView, isChecked) -> {
            isLocalPlayout = isChecked;
        });

        // 音频Dump
        mEnableDumpAudioSwitch = findViewById(R.id.audio_dump_switch);
        mEnableDumpAudioSwitch.setOnCheckedChangeListener((buttonView, isChecked) -> {
            mEnableDumpAudio = isChecked;
        });

        // Dump音频保存路径
        mDumpAudioFileNameEditText = findViewById(R.id.audio_dump_file_name);
        dumpAudioFileName = mDumpAudioFileNameEditText.getText().toString().trim();
        if(dumpAudioFileName.isEmpty()) {
            dumpAudioFileName = mDumpAudioFileNameEditText.getHint().toString().trim();
        }
    }

    public static void startActionActivity(Activity activity) {
        Intent intent = new Intent(activity, CustomAudioCaptureActivity.class);
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
            String  str;
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
        setupRtcEngineForCall();
        startPreview();
        joinChannel();
    }

    // 在onCreate中调用的引擎初始化方法
    private void initRtcEngine() {
        //创建并初始化引擎
        if(mAliRtcEngine == null) {
            // 通过extras参数设置是否关闭内部音频采集
            String extras = "{\"user_specified_use_external_audio_record\":\"TRUE\"}";
            mAliRtcEngine = AliRtcEngine.getInstance(this, extras);
        }
        mAliRtcEngine.setRtcEngineEventListener(mRtcEngineEventListener);
        mAliRtcEngine.setRtcEngineNotify(mRtcEngineNotify);
    }

    // 在加入频道前调用的引擎配置方法
    private void setupRtcEngineForCall() {
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

            if (fl_local.getChildCount() > 0) {
                fl_local.removeAllViews();
            }

            findViewById(R.id.ll_video_layout).setVisibility(VISIBLE);
            ViewGroup.LayoutParams layoutParams = new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
            if(mLocalVideoCanvas == null) {
                mLocalVideoCanvas = new AliRtcEngine.AliRtcVideoCanvas();
                SurfaceView localSurfaceView = mAliRtcEngine.createRenderSurfaceView(CustomAudioCaptureActivity.this);
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

    // 开启外部音频采集
    private void startAudioCapture() {
        // 根据获取到的音频数据格式配置添加音频流
        AliRtcEngine.AliRtcExternalAudioStreamConfig config = new AliRtcEngine.AliRtcExternalAudioStreamConfig();
        if(isMicrophoneCapture) {
            config.sampleRate = mAudioMicrophoneSampleRate;
            config.channels = mAudioMicrophoneChannel;
        } else {
            config.sampleRate = mAudioFileSampleRate;
            config.channels = mAudioFileChannel;
        }
        // 推流音量，如果为0表示不推流
        config.publishVolume = 100;
        // 本地播放音量，如果为0表示本地不播放
        config.playoutVolume = isLocalPlayout ? 100 : 0;
        config.enable3A = true; // 外采传入音频数据是否经过3A算法，即AEC、ANS、AGC,请根据您的场景来选择

        // 添加音频流，返回值为音频流ID，用于后续的音频数据推送
        int result = mAliRtcEngine.addExternalAudioStream(config);
        if (result <= 0) {
            Log.e("VideoCallActivity", "addExternalAudioStream failed, result = " + result);
            return;
        }
        mExternalAudioStreamId = result;

        if (isMicrophoneCapture) {
            // 启动麦克风采集输入
            startMicrophoneCapture();
        } else {
            // 启动音频文件输入
            startFileAudioCapture();
        }
    }

    private void startMicrophoneCapture() {
        if(microphoneCaptureThread == null) {
            microphoneCaptureThread = new MicrophoneCaptureThread(
                    this, // Context
                    this,
                    mAudioMicrophoneSampleRate,
                    mAudioMicrophoneChannel,
                    mAudioMicrophoneBitsPerSample,
                    mEnableDumpAudio,
                    dumpAudioFileName
            );
            microphoneCaptureThread.start();
        }
    }

    private void startFileAudioCapture() {
        if (fileAudioCaptureThread == null) {
            // 从文件中读取，在此演示读取app/assets/music.wav文件，其参数为16k单声道,比特深度为16bit
            fileAudioCaptureThread = new FileAudioCaptureThread(
                    mFileName,
                    this,
                    this,
                    mAudioFileSampleRate,
                    mAudioFileChannel,
                    mAudioFileBitsPerSample,
                    BUFFER_DURATION
            );
            fileAudioCaptureThread.start();
        }
    }

    private void stopAudioCapture() {

        // 停止麦克风采集线程
        if (microphoneCaptureThread != null) {
            microphoneCaptureThread.stopCapture();
            try {
                microphoneCaptureThread.join(1000); // 1秒超时
            } catch (InterruptedException e) {
                Log.e("CustomAudioCapture", "等待麦克风采集线程结束时被中断", e);
            } finally {
                microphoneCaptureThread = null;
            }
        }

        // 停止文件音频采集线程
        if (fileAudioCaptureThread != null) {
            fileAudioCaptureThread.stopCapture();
            try {
                fileAudioCaptureThread.join(1000); // 1秒超时
            } catch (InterruptedException e) {
                Log.e("CustomAudioCapture", "等待文件音频采集线程结束时被中断", e);
            } finally {
                fileAudioCaptureThread = null;
            }
        }

        if(mAliRtcEngine != null) {
            mAliRtcEngine.removeExternalAudioStream(mExternalAudioStreamId);
        }
        mExternalAudioStreamId = 0;
    }

    @Override
    public void onAudioFrameCaptured(byte[] audioData, int bytesRead, int sampleRate, int channels, int bitsPerSample) {
        if (mAliRtcEngine != null && bytesRead > 0) {
            // 构造AliRtcAudioFrame对象
            AliRtcEngine.AliRtcAudioFrame sample = new AliRtcEngine.AliRtcAudioFrame();
            sample.data = audioData;
            sample.bytesPerSample = bitsPerSample / 8;
            sample.numSamples = bytesRead / (channels * sample.bytesPerSample); // 根据实际读取的字节数计算样本数
            sample.numChannels = channels;
            sample.samplesPerSec = sampleRate;


            // 将获取的数据送入SDK
            int ret = 0;
            // 当缓冲区满导致push失败的时候需要进行重试
            int retryCount = 0;
            final int MAX_RETRY_COUNT = 20;
            final int BUFFER_WAIT_MS = 10;
            do {
                ret = mAliRtcEngine.pushExternalAudioStreamRawData(mExternalAudioStreamId, sample);
                if(ret == ErrorCodeEnum.ERR_SDK_AUDIO_INPUT_BUFFER_FULL) {
                    // 处理缓冲区满的情况，等待一段时间重试，最多重试几百ms
                    retryCount++;
                    if(mExternalAudioStreamId <= 0 || retryCount >= MAX_RETRY_COUNT) {
                        // 已经停止推流或者重试次数过多，退出循环
                        break;
                    }

                    try {
                        // 暂停一段时间
                        Thread.sleep(BUFFER_WAIT_MS);
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                        break;
                    }
                } else {
                    // 推送成功或者其他错误直接退出循环
                    break;
                }
            } while (retryCount < MAX_RETRY_COUNT);

            // 推送失败记录日志
            if(ret != 0) {
                if(ret == ErrorCodeEnum.ERR_SDK_AUDIO_INPUT_BUFFER_FULL) {
                    // 如果重试后仍然失败，记录日志
                    Log.w("CustomAudioCapture", "推送音频数据失败，错误码: " + ret + "，重试次数: " + retryCount);
                } else {
                    Log.e("CustomAudioCapture", "推送音频数据失败，错误码：" + ret);
                }
            }
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
        }

        @Override
        public void onAudioPublishStateChanged(AliRtcEngine.AliRtcPublishState oldState , AliRtcEngine.AliRtcPublishState newState, int elapseSinceLastState, String channel){
            super.onAudioPublishStateChanged(oldState, newState, elapseSinceLastState, channel);
            // 推荐在推流成功后再调用addExternalAudioSource接口
            if(newState == AliRtcEngine.AliRtcPublishState.AliRtcStatsPublished) {
                startAudioCapture();
            }
        }

        @Override
        public void onConnectionStatusChange(AliRtcEngine.AliRtcConnectionStatus status, AliRtcEngine.AliRtcConnectionStatusChangeReason reason){
            super.onConnectionStatusChange(status, reason);
        }

        @Override
        public void OnLocalDeviceException(AliRtcEngine.AliRtcEngineLocalDeviceType deviceType, AliRtcEngine.AliRtcEngineLocalDeviceExceptionType exceptionType, String msg){
            super.OnLocalDeviceException(deviceType, exceptionType, msg);
            /* TODO: 务必处理；建议业务提示设备错误，此时SDK内部已经尝试了各种恢复策略已经无法继续使用时才会上报 */
            handler.post(new Runnable() {
                @Override
                public void run() {
                    String str = "OnLocalDeviceException deviceType: " + deviceType + " exceptionType: " + exceptionType + " msg: " + msg;
                    ToastHelper.showToast(CustomAudioCaptureActivity.this, str, Toast.LENGTH_SHORT);
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
                    if(videoTrack == AliRtcVideoTrackCamera) {
                        SurfaceView surfaceView = mAliRtcEngine.createRenderSurfaceView(CustomAudioCaptureActivity.this);
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
                    ToastHelper.showToast(CustomAudioCaptureActivity.this, msg, Toast.LENGTH_SHORT);
                }
            });
        }
    };

    private void destroyRtcEngine() {

        // 停止外部音频采集
        stopAudioCapture();

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