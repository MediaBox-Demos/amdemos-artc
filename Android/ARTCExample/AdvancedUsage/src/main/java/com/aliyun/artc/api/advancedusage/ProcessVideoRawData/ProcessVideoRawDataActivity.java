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
        
        // 视频原始数据回调开关
        mVideoSampleRawDataSwitch = findViewById(R.id.video_capture_switch);
        mVideoSampleRawDataSwitch.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if(mAliRtcEngine == null) {
                    initAndSetupRtcEngine();
                }
                if (isChecked) {
                    // 注册视频原始数据回调
                    mAliRtcEngine.registerVideoSampleObserver(mRtcVideoSampleObserver);
                } else {
                    mAliRtcEngine.unRegisterVideoSampleObserver();
                }
            }
        });

        mWriteBackToSDKSwitch = findViewById(R.id.raw_data_write_back_switch);
        mWriteBackToSDKSwitch.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                isWriteBackToSDK = isChecked;
            }
        });

        // 纹理数据回调开关
        mEnableTextureDataSwitch = findViewById(R.id.video_capture_texture_switch);
        mEnableTextureDataSwitch.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if(mAliRtcEngine == null) {
                    initAndSetupRtcEngine();
                }
                if(isChecked){
                    mAliRtcEngine.registerLocalVideoTextureObserver(mRtcTextureObserver);
                } else {
                    mAliRtcEngine.unRegisterLocalVideoTextureObserver();
                }
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

    private void startRTCCall() {
        if(hasJoined) {
            return;
        }
        startPreview();
        joinChannel();
    }

    private void initAndSetupRtcEngine() {
        //创建并初始化引擎 获取纹理相关回调需要开启纹理采集、纹理编码
        if(mAliRtcEngine == null) {
            String extras = "{\"user_specified_camera_texture_capture\":\"TRUE\",\"user_specified_texture_encode\":\"TRUE\" }";
            mAliRtcEngine = AliRtcEngine.getInstance(this, extras);
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

        if(mVideoSampleRawDataSwitch.isChecked()) {
            mAliRtcEngine.registerVideoSampleObserver(mRtcVideoSampleObserver);
        }

        if(mEnableTextureDataSwitch.isChecked()) {
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

    private final AliRtcEngine.AliRtcTextureObserver mRtcTextureObserver = new AliRtcEngine.AliRtcTextureObserver() {
        @Override
        public void onTextureCreate(long context) {
            Log.d(TAG, "onTextureCreate");
        }

        @Override
        public int onTextureUpdate(int textureId, int width, int height, AliRtcEngine.AliRtcVideoSample videoSample) {
            Log.d(TAG, "onTextureUpdate");
            return textureId;
        }

        @Override
        public void onTextureDestroy() {
            // 直接destroy销毁引擎会释放相关资源但是不会触发此回调，如有需求请在destroy前调用unRegisterLocalVideoTextureObserver
            Log.d(TAG, "onTextureDestroy");
        }
    };



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
            handler.post(new Runnable() {
                @Override
                public void run() {
                    ToastHelper.showToast(ProcessVideoRawDataActivity.this, "onLocalVideoSample", Toast.LENGTH_SHORT);
                }
            });
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
            ToastHelper.showToast(ProcessVideoRawDataActivity.this, "onRemoteVideoSample", Toast.LENGTH_SHORT);

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
            ToastHelper.showToast(ProcessVideoRawDataActivity.this, "onPreEncodeVideoSample", Toast.LENGTH_SHORT);

            return isWriteBackToSDK;
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