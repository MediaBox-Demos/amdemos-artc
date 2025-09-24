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

    // 自定义音频采集相关参数，根据业务场景自行配置
    public static final int SAMPLE_RATE = 48000;
    public static final int CHANNEL = 2;
    public static final int BITS_PER_SAMPLE = 16;
    public static final float BYTE_PER_SAMPLE = 1.0f * BITS_PER_SAMPLE / 8 * CHANNEL;
    public static final double SAMPLE_COUNT_PER_MS = SAMPLE_RATE * 1.0f / 1000.0;
    public static final int BUFFER_DURATION = 10; // 10ms
    public static final int BUFFER_FULL_DURATION = 30; // BUFFER FULL, wait for 30ms
    private static final int BUFFER_SAMPLE_COUNT = (int) (SAMPLE_COUNT_PER_MS * BUFFER_DURATION); // 10ms sample count
    private static final int BUFFER_BYTE_SIZE = (int) (BUFFER_SAMPLE_COUNT * BYTE_PER_SAMPLE); // byte size

    // 自定义音频采集相关变量
    private int mExternalAudioStreamId;

    private boolean isPushingAudio = false;
    // 为麦克风采集和文件读取分别创建线程
    private MicrophoneCaptureThread microphoneCaptureThread;
    private FileAudioCaptureThread fileAudioCaptureThread;

    RadioGroup audioSourceRadioGroup;
    // 麦克风采集输入 or 外部文件输入
    private boolean isMicrophoneCapture = false;

    // 本地播放
    private boolean isLocalPlayout = false;
    private SwitchCompat isLocalPlayoutSwitch;

    // 是否允许录制麦克风采集的数据到文件
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
            mAliRtcEngine = AliRtcEngine.getInstance(this);
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

        //音频自定义采集，需要关闭ARTC SDK内部采集，默认是开启的
        String parameter = "{\"audio\":{\"enable_system_audio_device_record\":\"FALSE\"}}";
        mAliRtcEngine.setParameter(parameter);
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
        AliRtcEngine.AliRtcExternalAudioStreamConfig config = new AliRtcEngine.AliRtcExternalAudioStreamConfig();
        if(isMicrophoneCapture) {
            config.sampleRate = SAMPLE_RATE;
        } else {
            // 示例音频wav文件的采样率为16000
            config.sampleRate = 16000;
        }
        config.channels = CHANNEL;
        config.publishVolume = 100;
        // 本地播放音量
        config.playoutVolume = isLocalPlayout ? 100 : 0;
        config.enable3A = true;

        int result = mAliRtcEngine.addExternalAudioStream(config);
        if (result <= 0) {
            return;
        }

        mExternalAudioStreamId = result;

        isPushingAudio = true;
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
                    SAMPLE_RATE,
                    CHANNEL,
                    BITS_PER_SAMPLE,
                    mEnableDumpAudio,
                    dumpAudioFileName
            );
            microphoneCaptureThread.start();
        }
    }

    private void startFileAudioCapture() {
        if (fileAudioCaptureThread == null) {
            fileAudioCaptureThread = new FileAudioCaptureThread(
                    this,
                    this
            );
            fileAudioCaptureThread.start();
        }
    }

    private void stopAudioCapture() {

        isPushingAudio = false;
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
            sample.numSamples = bytesRead / (channels * (bitsPerSample / 8)); // 根据实际读取的字节数计算样本数
            sample.numChannels = channels;
            sample.sampleRate = sampleRate;
            sample.bytesPerSample = bitsPerSample / 8;

            int ret = mAliRtcEngine.pushExternalAudioStreamRawData(mExternalAudioStreamId, sample);

            if (ret != 0) {
                if (ret == ErrorCodeEnum.ERR_SDK_AUDIO_INPUT_BUFFER_FULL) {
                    // 处理缓冲区满的情况, 等待一段时间再重试,一般最多重试几百ms
                    int retryCount = 0;
                    final int MAX_RETRY_COUNT = 20;
                    final int BUFFER_FULL_WAIT_MS = 30;
                    while (ret == ErrorCodeEnum.ERR_SDK_AUDIO_INPUT_BUFFER_FULL && retryCount < MAX_RETRY_COUNT) {
                        if(!isPushingAudio) {
                            break;
                        }
                        try {
                            Thread.sleep(BUFFER_FULL_WAIT_MS);
                            ret = mAliRtcEngine.pushExternalAudioStreamRawData(mExternalAudioStreamId, sample);
                            retryCount++;
                        } catch (InterruptedException e) {
                            Thread.currentThread().interrupt();
                            break;
                        }
                    }

                    // 如果重试后仍然失败，记录日志
                    if (ret != 0) {
                        Log.w("CustomAudioCapture", "推送音频数据失败，错误码: " + ret + "，重试次数: " + retryCount);
                    }
                } else {
                    // 处理其他错误情况
                    Log.e("CustomAudioCapture", "推送音频数据失败，错误码: " + ret);
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