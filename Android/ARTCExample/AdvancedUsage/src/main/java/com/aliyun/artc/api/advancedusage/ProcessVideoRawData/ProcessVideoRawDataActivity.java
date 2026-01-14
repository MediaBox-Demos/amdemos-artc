package com.aliyun.artc.api.advancedusage.ProcessVideoRawData;

import static android.view.View.VISIBLE;
import static com.alivc.rtc.AliRtcEngine.AliRtcVideoEncoderOrientationMode.AliRtcVideoEncoderOrientationModeAdaptive;
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
import android.widget.CompoundButton;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.TextView;
import android.widget.Toast;
import android.widget.Spinner;
import android.widget.ArrayAdapter;
import android.widget.AdapterView;
import android.widget.CheckBox;

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

import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 获取视频原始数据API调用示例
 */
public class ProcessVideoRawDataActivity extends AppCompatActivity {
    private static final String TAG = ProcessVideoRawDataActivity.class.getSimpleName();
    private Handler handler;
    private EditText mChannelEditText;
    private TextView mJoinChannelTextView;
    private SwitchCompat mVideoSampleRawDataSwitch;
    private SwitchCompat mWriteBackToSDKSwitch;
    private SwitchCompat mEnableTextureDataSwitch;

    // 视频原始数据回调信息展示（仿照音频 Demo）
    private TextView mLocalSampleInfoTv;
    private TextView mRemoteSampleInfoTv;
    private TextView mPreEncodeSampleInfoTv;
    private TextView mPostEncodeSampleInfoTv;
    private TextView mTextureInfoTv;

    // 编码/解码模式配置
    private Spinner mEncoderModeSpinner;
    private Spinner mDecoderModeSpinner;
    private int mEncoderCodecModeIndex = 2; // 默认硬件纹理
    private int mDecoderCodecModeIndex = 1; // 默认硬件解码

    // 各阶段是否启用回调处理
    private boolean enableLocalSample = true;
    private boolean enableRemoteSample = true;
    private boolean enablePreEncodeSample = true;
    private boolean enablePostEncodeSample = false;

    // 首选视频数据格式，默认 I420
    private AliRtcEngine.AliRtcVideoFormat mPreferredFormat =
            AliRtcEngine.AliRtcVideoFormat.AliRtcVideoFormatI420;

    private boolean hasJoined = false;
    private FrameLayout fl_local, fl_remote, fl_remote_2, fl_remote_3;

    private AliRtcEngine mAliRtcEngine = null;
    private AliRtcEngine.AliRtcVideoCanvas mLocalVideoCanvas = null;
    private Map<String, ViewGroup> remoteViews = new ConcurrentHashMap<String, ViewGroup>();

    // 获取的原始视频数据是否写回SDK更新
    private boolean isWriteBackToSDK = true;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        handler = new Handler(Looper.getMainLooper());
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_process_video_raw_data);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.process_video_raw_data), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });
        setTitle(getString(R.string.process_video_raw_data));
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);

        fl_local = findViewById(R.id.fl_local);
        fl_remote = findViewById(R.id.fl_remote);
        fl_remote_2 = findViewById(R.id.fl_remote2);
        fl_remote_3 = findViewById(R.id.fl_remote3);

        // 视频原始数据信息展示 TextView
        mLocalSampleInfoTv = findViewById(R.id.tv_local_sample_info);
        mRemoteSampleInfoTv = findViewById(R.id.tv_remote_sample_info);
        mPreEncodeSampleInfoTv = findViewById(R.id.tv_preencode_sample_info);
        mPostEncodeSampleInfoTv = findViewById(R.id.tv_postencode_sample_info);
        mTextureInfoTv = findViewById(R.id.tv_texture_info);

        mChannelEditText = findViewById(R.id.channel_id_input);
        mChannelEditText.setText(GlobalConfig.getInstance().gerRandomChannelId());
        mJoinChannelTextView = findViewById(R.id.join_room_btn);
        mJoinChannelTextView.setOnClickListener(v -> {
            if(hasJoined) {
                destroyRtcEngine();
                mJoinChannelTextView.setText(R.string.video_chat_join_channel);
            } else {
                if(mAliRtcEngine == null) {
                    initAndSetupRtcEngine();
                }
                startRTCCall();
            }
        });
        
        // 视频原始数据回调开关：直接调用 SDK 的 register/unRegister API
        mVideoSampleRawDataSwitch = findViewById(R.id.video_capture_switch);
        mVideoSampleRawDataSwitch.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (mAliRtcEngine == null) {
                initAndSetupRtcEngine();
            }
            if (isChecked) {
                // 【关键 API】注册原始视频数据回调
                mAliRtcEngine.registerVideoSampleObserver(mRtcVideoSampleObserver);
            } else {
                mAliRtcEngine.unRegisterVideoSampleObserver();
            }
        });

        mWriteBackToSDKSwitch = findViewById(R.id.raw_data_write_back_switch);
        mWriteBackToSDKSwitch.setOnCheckedChangeListener((buttonView, isChecked) -> {
            isWriteBackToSDK = isChecked;
        });

        // 纹理数据回调开关：直接调用 SDK 的 register/unRegister API
        mEnableTextureDataSwitch = findViewById(R.id.video_capture_texture_switch);
        mEnableTextureDataSwitch.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (mAliRtcEngine == null) {
                initAndSetupRtcEngine();
            }
            if (isChecked) {
                // 【关键 API】注册纹理数据回调
                mAliRtcEngine.registerLocalVideoTextureObserver(mRtcTextureObserver);
            } else {
                mAliRtcEngine.unRegisterLocalVideoTextureObserver();
            }
        });

        // 【演示功能】Position 控制开关：控制 SDK 是否回调各个 Position 的数据
        // 每次开关变化时，会重新注册 VideoSampleObserver，让 onGetObservedFramePosition() 生效
        CheckBox mStageLocalSwitch = findViewById(R.id.switch_stage_local);
        CheckBox mStageRemoteSwitch = findViewById(R.id.switch_stage_remote);
        CheckBox mStagePreEncodeSwitch = findViewById(R.id.switch_stage_preencode);
        CheckBox mStagePostEncodeSwitch = findViewById(R.id.switch_stage_postencode);

        CompoundButton.OnCheckedChangeListener stageChangeListener = (buttonView, isChecked) -> {
            // 更新对应阶段的开关状态
            int viewId = buttonView.getId();
            if (viewId == R.id.switch_stage_local) {
                enableLocalSample = isChecked;
            } else if (viewId == R.id.switch_stage_remote) {
                enableRemoteSample = isChecked;
            } else if (viewId == R.id.switch_stage_preencode) {
                enablePreEncodeSample = isChecked;
            } else if (viewId == R.id.switch_stage_postencode) {
                enablePostEncodeSample = isChecked;
            }

            // 重新注册回调，让新的 position 配置生效
            if (mVideoSampleRawDataSwitch.isChecked()) {
                reRegisterVideoSampleObserver();
            }
        };

        mStageLocalSwitch.setOnCheckedChangeListener(stageChangeListener);
        mStageRemoteSwitch.setOnCheckedChangeListener(stageChangeListener);
        mStagePreEncodeSwitch.setOnCheckedChangeListener(stageChangeListener);
        mStagePostEncodeSwitch.setOnCheckedChangeListener(stageChangeListener);

        // 格式选择：控制返回数据的格式
        Spinner formatSpinner = findViewById(R.id.sp_video_format);

        // 可选格式列表：只挑几种典型的，避免太长
        final List<AliRtcEngine.AliRtcVideoFormat> formatList = Arrays.asList(
                AliRtcEngine.AliRtcVideoFormat.AliRtcVideoFormatI420,
                AliRtcEngine.AliRtcVideoFormat.AliRtcVideoFormatNV21,
                AliRtcEngine.AliRtcVideoFormat.AliRtcVideoFormatNV12,
                AliRtcEngine.AliRtcVideoFormat.AliRtcVideoFormatBGRA,
                AliRtcEngine.AliRtcVideoFormat.AliRtcVideoFormatRGBA
        );

        final List<String> formatLabels = Arrays.asList(
                "I420",
                "NV21",
                "NV12",
                "BGRA",
                "RGBA"
        );

        // 适配器
        ArrayAdapter<String> adapter = new ArrayAdapter<>(
                this,
                android.R.layout.simple_spinner_item,
                formatLabels
        );
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        formatSpinner.setAdapter(adapter);

        // 默认选中 I420
        formatSpinner.setSelection(0);
        mPreferredFormat = formatList.get(0);

        formatSpinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                mPreferredFormat = formatList.get(position);
                String hint = "PreferredFormat: " + formatLabels.get(position);
                Log.d(TAG, hint);
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {
                // 保持上一次选择
            }
        });

        // 编码/解码模式 Spinner 配置
        setupCodecModeSpinners();
    }

    /**
     * 设置编码/解码模式 Spinner
     * 说明：
     * - 软件/硬件编码：主要返回 buffer 数据，通过 AliRtcVideoObserver 回调
     * - 硬件纹理编码：主要返回纹理数据，通过 AliRtcTextureObserver 回调
     */
    private void setupCodecModeSpinners() {
        // 编码模式 Spinner
        mEncoderModeSpinner = findViewById(R.id.sp_encoder_codec_mode);
        List<String> encoderOptions = Arrays.asList(
                getString(R.string.video_encoder_software_encode),
                getString(R.string.video_encoder_hardware_encode),
                getString(R.string.video_encoder_hardware_texture_encode)
        );
        ArrayAdapter<String> encoderAdapter = new ArrayAdapter<>(
                this, android.R.layout.simple_spinner_item, encoderOptions);
        encoderAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        mEncoderModeSpinner.setAdapter(encoderAdapter);
        mEncoderModeSpinner.setSelection(2); // 默认硬件纹理编码

        mEncoderModeSpinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                mEncoderCodecModeIndex = position;
                Log.d(TAG, "Encoder mode changed to: " + encoderOptions.get(position));
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {
            }
        });

        // 解码模式 Spinner
        mDecoderModeSpinner = findViewById(R.id.sp_decoder_codec_mode);
        List<String> decoderOptions = Arrays.asList(
                getString(R.string.video_decoder_software_decode),
                getString(R.string.video_decoder_hardware_decode),
                getString(R.string.video_decoder_hardware_texture_decode)
        );
        ArrayAdapter<String> decoderAdapter = new ArrayAdapter<>(
                this, android.R.layout.simple_spinner_item, decoderOptions);
        decoderAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        mDecoderModeSpinner.setAdapter(decoderAdapter);
        mDecoderModeSpinner.setSelection(1); // 默认硬件解码

        mDecoderModeSpinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                mDecoderCodecModeIndex = position;
                Log.d(TAG, "Decoder mode changed to: " + decoderOptions.get(position));
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {
            }
        });
    }

    public static void startActionActivity(Activity activity) {
        Intent intent = new Intent(activity, ProcessVideoRawDataActivity.class);
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

    /**
     * 在主线程更新视频原始数据信息 TextView
     */
    private void updateVideoInfo(TextView textView, String message) {
        if (textView == null) {
            return;
        }
        handler.post(() -> textView.setText(message));
    }

    /**
     * 【演示功能】重新注册视频原始数据回调
     * 用于阶段开关变化时，让 onGetObservedFramePosition() 的新配置生效
     */
    private void reRegisterVideoSampleObserver() {
        if (mAliRtcEngine == null) {
            return;
        }
        // 先取消注册
        mAliRtcEngine.unRegisterVideoSampleObserver();
        // 重新注册，SDK 会重新调用 onGetObservedFramePosition() 获取新的 position 配置
        mAliRtcEngine.registerVideoSampleObserver(mRtcVideoSampleObserver);
        Log.d(TAG, "reRegisterVideoSampleObserver: updated position mask");
    }

    private void startRTCCall() {
        if(hasJoined) {
            return;
        }
        startPreview();
        joinChannel();
    }

    /**
     * 创建并初始化 AliRtcEngine，并注册视频原始数据回调监听器。
     * 【核心 API】获取原始视频数据的主流程入口：
     *   1. registerVideoSampleObserver(observer) - 注册视频裸数据观察者
     *   2. registerLocalVideoTextureObserver(observer) - 注册纹理数据观察者
     *   3. 在 observer 回调中获取 AliRtcVideoSample 数据
     *   4. 根据业务处理视频数据，返回 true/false 决定是否写回 SDK
     */
    private void initAndSetupRtcEngine() {
        //创建并初始化引擎 获取纹理相关回调需要开启纹理采集、纹理编码
        if(mAliRtcEngine == null) {
//            String extras = "{\"user_specified_camera_texture_capture\":\"TRUE\",\"user_specified_texture_encode\":\"TRUE\" }";
            mAliRtcEngine = AliRtcEngine.getInstance(this, null);
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
        
        // 根据配置设置编码方式
        switch (mEncoderCodecModeIndex) {
            case 0:
                aliRtcVideoEncoderConfiguration.codecType =
                        AliRtcEngine.AliRtcVideoCodecType.AliRtcVideoCodecTypeSoftware;
                break;
            case 1:
                aliRtcVideoEncoderConfiguration.codecType =
                        AliRtcEngine.AliRtcVideoCodecType.AliRtcVideoCodecTypeHardware;
                break;
            case 2:
            default:
                aliRtcVideoEncoderConfiguration.codecType =
                        AliRtcEngine.AliRtcVideoCodecType.AliRtcVideoCodecTypeHardwareTexture;
                break;
        }
        mAliRtcEngine.setVideoEncoderConfiguration(aliRtcVideoEncoderConfiguration);

        // 设置视频解码参数
        AliRtcEngine.AliRtcVideoDecoderConfiguration decoderConfig =
                new AliRtcEngine.AliRtcVideoDecoderConfiguration();
        
        switch (mDecoderCodecModeIndex) {
            case 0:
                decoderConfig.codecType =
                        AliRtcEngine.AliRtcVideoCodecType.AliRtcVideoCodecTypeSoftware;
                break;
            case 1:
                decoderConfig.codecType =
                        AliRtcEngine.AliRtcVideoCodecType.AliRtcVideoCodecTypeHardware;
                break;
            case 2:
            default:
                decoderConfig.codecType =
                        AliRtcEngine.AliRtcVideoCodecType.AliRtcVideoCodecTypeHardwareTexture;
                break;
        }
        mAliRtcEngine.setVideoDecoderConfiguration(decoderConfig);

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

        // 根据开关状态注册回调
        if (mVideoSampleRawDataSwitch.isChecked()) {
            mAliRtcEngine.registerVideoSampleObserver(mRtcVideoSampleObserver);
        }
        if (mEnableTextureDataSwitch.isChecked()) {
            mAliRtcEngine.registerLocalVideoTextureObserver(mRtcTextureObserver);
        }
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
                SurfaceView localSurfaceView = mAliRtcEngine.createRenderSurfaceView(ProcessVideoRawDataActivity.this);
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
        }

        @Override
        public void onConnectionStatusChange(AliRtcEngine.AliRtcConnectionStatus status, AliRtcEngine.AliRtcConnectionStatusChangeReason reason){
            super.onConnectionStatusChange(status, reason);

            handler.post(new Runnable() {
                @Override
                public void run() {
                    if(status == AliRtcEngine.AliRtcConnectionStatus.AliRtcConnectionStatusFailed) {
                        /* TODO: 务必处理；建议业务提示客户，此时SDK内部已经尝试了各种恢复策略已经无法继续使用时才会上报 */
                        ToastHelper.showToast(ProcessVideoRawDataActivity.this, R.string.video_chat_connection_failed, Toast.LENGTH_SHORT);
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
                    ToastHelper.showToast(ProcessVideoRawDataActivity.this, str, Toast.LENGTH_SHORT);
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
                        SurfaceView surfaceView = mAliRtcEngine.createRenderSurfaceView(ProcessVideoRawDataActivity.this);
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
                    ToastHelper.showToast(ProcessVideoRawDataActivity.this, msg, Toast.LENGTH_SHORT);
                }
            });
        }

    };

    /**
     * 【关键回调】纹理数据观察者：SDK 通过该回调返回 OpenGL 纹理 ID
     */
    private final AliRtcEngine.AliRtcTextureObserver mRtcTextureObserver = new AliRtcEngine.AliRtcTextureObserver() {
        @Override
        public void onTextureCreate(long context) {
            Log.d(TAG, "onTextureCreate");
            updateVideoInfo(mTextureInfoTv, "Texture: onTextureCreate");
        }

        @Override
        public int onTextureUpdate(int textureId, int width, int height, AliRtcEngine.AliRtcVideoSample videoSample) {
            String message = "Texture: " + width + "x" + height + ", texId=" + textureId;
            Log.d(TAG, message);
            updateVideoInfo(mTextureInfoTv, message);
            return textureId;
        }

        @Override
        public void onTextureDestroy() {
            // 直接destroy销毁引擎会释放相关资源但是不会触发此回调，如有需求请在destroy前调用unRegisterLocalVideoTextureObserver
            Log.d(TAG, "onTextureDestroy");
            updateVideoInfo(mTextureInfoTv, "Texture: onTextureDestroy");
        }
    };

    /**
     * 【关键回调】视频数据回调监听器：SDK 通过该回调返回各类视频源的原始数据
     * videoSample 中包含：width/height（宽高）、format（格式）、data（视频数据）等
     * 返回值：true - 写回 SDK（默认）；false - 不写回 SDK
     */
    //视频数据回调监听器，回调函数处理逻辑在此处实现
    private AliRtcEngine.AliRtcVideoObserver mRtcVideoSampleObserver = new AliRtcEngine.AliRtcVideoObserver() {

        @Override
        public boolean onLocalVideoSample(AliRtcEngine.AliRtcVideoSourceType sourceType, AliRtcEngine.AliRtcVideoSample videoSample){

            /**
             * @brief 订阅的本地采集视频数据回调
             * @param sourceType 视频流类型
             * @param videoSample 视频裸数据
             * @return
             * - true: 需要写回SDK（默认写回，需要操作AliRtcVideoSample.data时必须要写回）
             * - false: 不需要写回SDK(需要直接操作AliRtcVideoSample.dataFrameY、AliRtcVideoSample.dataFrameU、AliRtcVideoSample.dataFrameV时使用)
             */
            String message = "LocalSample: " + videoSample.width + "x" + videoSample.height
                    + ", format=" + videoSample.format
                    + ", source=" + sourceType
                    + ", writeBack=" + isWriteBackToSDK;
            Log.d(TAG, message);
            updateVideoInfo(mLocalSampleInfoTv, message);
            return isWriteBackToSDK;
        }

        @Override
        public boolean onRemoteVideoSample(String callId, AliRtcEngine.AliRtcVideoSourceType sourceType, AliRtcEngine.AliRtcVideoSample videoSample){

            /**
             * @brief 订阅的远端视频数据回调
             * @param callId 用户ID
             * @param sourceType 视频流类型
             * @param videoSample 视频裸数据
             * @return
             * - true: 需要写回SDK（默认写回，需要操作AliRtcVideoSample.data时必须要写回）
             * - false: 不需要写回SDK(需要直接操作AliRtcVideoSample.dataFrameY、AliRtcVideoSample.dataFrameU、AliRtcVideoSample.dataFrameV时使用)
             */
            String message = "RemoteSample: uid=" + callId
                    + ", " + videoSample.width + "x" + videoSample.height
                    + ", format=" + videoSample.format
                    + ", source=" + sourceType
                    + ", writeBack=" + isWriteBackToSDK;
            Log.d(TAG, message);
            updateVideoInfo(mRemoteSampleInfoTv, message);
            return isWriteBackToSDK;
        }

        @Override
        public boolean onPreEncodeVideoSample(AliRtcEngine.AliRtcVideoSourceType sourceType, AliRtcEngine.AliRtcVideoSample videoRawData){
            /**
             * @brief 订阅的本地编码前视频数据回调
             * @param sourceType 视频流类型
             * @param videoRawData 视频裸数据
             * @return
             * - true: 需要写回SDK（默认写回，需要操作AliRtcVideoSample.data时必须要写回）
             * - false: 不需要写回SDK(需要直接操作AliRtcVideoSample.dataFrameY、AliRtcVideoSample.dataFrameU、AliRtcVideoSample.dataFrameV时使用)
             */
            String message = "PreEncodeSample: " + videoRawData.width + "x" + videoRawData.height
                    + ", format=" + videoRawData.format
                    + ", source=" + sourceType
                    + ", writeBack=" + isWriteBackToSDK;
            Log.d(TAG, message);
            updateVideoInfo(mPreEncodeSampleInfoTv, message);
            return isWriteBackToSDK;
        }

        /**
         * @brief 订阅的本地编码后视频数据回调（新增阶段）
         * @param sourceType 视频流类型
         * @param videoEncodedData 编码后视频数据
         * @return
         * - true: 需要写回SDK
         * - false: 不需要写回SDK
         */
        // 注意：这个回调需要 SDK 支持，如果 SDK 中没有此接口，请注释掉
        @Override
        public boolean onPostEncodeVideoSample(AliRtcEngine.AliRtcVideoSourceType sourceType,
                                               AliRtcEngine.AliRtcVideoEncodedData videoEncodedData) {
            // 根据 SDK 实际定义获取字段
            String message = "PostEncodeSample: source=" + sourceType
                    + ", writeBack=" + isWriteBackToSDK;
            Log.d(TAG, message);
            updateVideoInfo(mPostEncodeSampleInfoTv, message);
            return isWriteBackToSDK;
        }

        /**
         * @brief 控制返回的视频数据格式
         * @return 首选的视频格式
         */
        @Override
        public AliRtcEngine.AliRtcVideoFormat onGetVideoFormatPreference() {
            // Demo：返回当前用户通过 UI 选择的格式
            return mPreferredFormat;
        }

        /**
         * @brief 【演示核心功能】控制 SDK 回调哪些阶段的视频数据
         * @return 期望接收的视频数据阶段（位掩码）
         * 
         * 通过位或（|）组合多个阶段：
         * - AliRtcPositionPostCapture (1)  → onLocalVideoSample
         * - AliRtcPositionPreRender (2)    → onRemoteVideoSample
         * - AliRtcPositionPreEncoder (4)   → onPreEncodeVideoSample
         * - AliRtcPositionPostEncoder (8)  → onPostEncodeVideoSample
         */
        @Override
        public int onGetObservedFramePosition(){
            int position = 0;

            if (enableLocalSample) {
                position |= AliRtcEngine.AliRtcVideoObserPosition.AliRtcPositionPostCapture.getValue();
            }

            if (enableRemoteSample) {
                position |= AliRtcEngine.AliRtcVideoObserPosition.AliRtcPositionPreRender.getValue();
            }

            if (enablePreEncodeSample) {
                position |= AliRtcEngine.AliRtcVideoObserPosition.AliRtcPositionPreEncoder.getValue();
            }

            if (enablePostEncodeSample) {
                position |= AliRtcEngine.AliRtcVideoObserPosition.AliRtcPositionPostEncoder.getValue();
            }

            Log.d(TAG, "onGetObservedFramePosition: position=" + position
                    + " (Local=" + enableLocalSample
                    + ", Remote=" + enableRemoteSample
                    + ", PreEncode=" + enablePreEncodeSample
                    + ", PostEncode=" + enablePostEncodeSample + ")");

            return position;
        }

    };

    private void destroyRtcEngine() {
        if( mAliRtcEngine != null) {
            mAliRtcEngine.stopPreview();
            mAliRtcEngine.setLocalViewConfig(null, AliRtcVideoTrackCamera);
            mAliRtcEngine.leaveChannel();
            mAliRtcEngine.unRegisterLocalVideoTextureObserver();
            mAliRtcEngine.destroy();
            mAliRtcEngine = null;
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