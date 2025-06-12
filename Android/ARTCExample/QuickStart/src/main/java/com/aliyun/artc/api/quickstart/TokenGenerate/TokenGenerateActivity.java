package com.aliyun.artc.api.quickstart.TokenGenerate;

import static android.view.View.VISIBLE;

import static com.alivc.rtc.AliRtcEngine.AliRtcVideoEncoderOrientationMode.AliRtcVideoEncoderOrientationModeAdaptive;
import static com.alivc.rtc.AliRtcEngine.AliRtcVideoTrack.AliRtcVideoTrackCamera;

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
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import com.alivc.rtc.AliRtcAuthInfo;
import com.alivc.rtc.AliRtcEngine;
import com.alivc.rtc.AliRtcEngineEventListener;
import com.alivc.rtc.AliRtcEngineNotify;
import com.aliyun.artc.api.keycenter.ARTCTokenHelper;
import com.aliyun.artc.api.keycenter.GlobalConfig;
import com.aliyun.artc.api.keycenter.utils.ToastHelper;
import com.aliyun.artc.api.quickstart.R;

/**
 * Token生成API调用示例
 */
public class TokenGenerateActivity extends AppCompatActivity {
    private Handler handler;
    private EditText mAppIdEditText;
    private EditText mAppKeyEditText;
    private EditText mChannelIdEditText;
    private EditText mUserIdEditText;
    private EditText mTimestampEditText;
    private EditText mNonceEditText;
    private TextView mTokenEditText;
    private LinearLayout mTokenLayout;
    private TextView mJoinResultTextView;
    private LinearLayout mJoinResultLayout;

    private AliRtcEngine mAliRtcEngine = null;
    private AliRtcEngine.AliRtcVideoCanvas mLocalVideoCanvas = null;

    private boolean hasJoined = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        handler = new Handler(Looper.getMainLooper());
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_token_verfiy);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });
        setTitle(getString(R.string.token_verify));
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        setDefaultData();

        findViewById(R.id.multi_param_join_btn).setOnClickListener(v -> {
            if(hasJoined) {
                destroyRtcEngine();
                ((TextView)findViewById(R.id.multi_param_join_btn)).setText(R.string.multiple_parameters_join);
            } else {
                startRTCCall(true);
            }
        });
        findViewById(R.id.sigle_param_join_btn).setOnClickListener(v -> {
            if(hasJoined) {
                destroyRtcEngine();
                ((TextView)findViewById(R.id.sigle_param_join_btn)).setText(R.string.signle_parameters_join);
            } else {
                startRTCCall(false);
            }
        });

    }

    private void setDefaultData() {
        mAppIdEditText = findViewById(R.id.app_id_input);
        mAppIdEditText.setText(ARTCTokenHelper.AppId);
        mAppKeyEditText = findViewById(R.id.app_key_input);
        mAppKeyEditText.setText(ARTCTokenHelper.AppKey);
        mChannelIdEditText = findViewById(R.id.ll_channel_input);
        mChannelIdEditText.setText(GlobalConfig.getInstance().gerRandomChannelId());
        mUserIdEditText = findViewById(R.id.user_id_input);
        mUserIdEditText.setText(GlobalConfig.getInstance().getUserId());
        mNonceEditText = findViewById(R.id.ll_nonce_input);
        mTimestampEditText = findViewById(R.id.ll_timestamp_input);
        mTimestampEditText.setText(ARTCTokenHelper.getTimesTamp() + "");
        mTokenEditText = findViewById(R.id.ll_token_input);
        mTokenLayout = findViewById(R.id.ll_token);
        mJoinResultTextView = findViewById(R.id.ll_join_result_input);
        mJoinResultLayout = findViewById(R.id.ll_join_result);
    }

    private void handleJoinResult(int result, String channel, String userId) {
        new Handler(Looper.getMainLooper()).post(() -> {
            String  str = null;
            if(result == 0) {
                str = "User " + userId + " Join " + channel + " Success";
            } else {
                str = "User " + userId + " Join " + channel + " Failed！， error：" + result;
            }
            mJoinResultLayout.setVisibility(VISIBLE);
            mJoinResultTextView.setText(str);
        });
    }

    private void startRTCCall(boolean isMultiParamJoin) {
        String appId = mAppIdEditText.getText().toString();
        String appKey = mAppKeyEditText.getText().toString();
        String channelId = mChannelIdEditText.getText().toString();
        String userId = mUserIdEditText.getText().toString();
        String timestamp = mTimestampEditText.getText().toString();
        String nonce = mNonceEditText.getText().toString();

        if(TextUtils.isEmpty(appId) || TextUtils.isEmpty(appKey) || TextUtils.isEmpty(channelId) || TextUtils.isEmpty(userId) || TextUtils.isEmpty(timestamp)) {
            Log.e("TokenGenerateActivity", "appId or appKey or channelId or userId or timestamp is empty");
        }

        String token = "";
        if(isMultiParamJoin) {
            token = ARTCTokenHelper.generateMulitParameterToken(appId, appKey, channelId, userId, Long.parseLong(timestamp));
        } else {
            token = ARTCTokenHelper.generateSingleParameterToken(appId, appKey, channelId, userId, Long.parseLong(timestamp));
        }
        if(!TextUtils.isEmpty(token)) {
            mTokenLayout.setVisibility(VISIBLE);
            mTokenEditText.setText(token);

            initAndSetupRtcEngine();
            startPreview();

            if(isMultiParamJoin) {
                joinChannelWithMultiParameterToken(appId, channelId, userId, Long.parseLong(timestamp), nonce, token);
                ((TextView)findViewById(R.id.multi_param_join_btn)).setText(R.string.leave_channel);
            } else {
                joinChannelWithSingleParameterToken(token);
                ((TextView)findViewById(R.id.sigle_param_join_btn)).setText(R.string.leave_channel);
            }

            hasJoined = true;
        }
    }

    private void destroyRtcEngine() {
        if(mAliRtcEngine != null) {
            mAliRtcEngine.stopPreview();
            mAliRtcEngine.leaveChannel();
            mAliRtcEngine.destroy();
            mAliRtcEngine = null;
            handler.post(() -> {
                ToastHelper.showToast(this, "Leave Channel", Toast.LENGTH_SHORT);
            });
        }
        mLocalVideoCanvas = null;
        findViewById(R.id.preview_layer).setVisibility(View.GONE);
        hasJoined = false;
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
                        ToastHelper.showToast(TokenGenerateActivity.this, R.string.video_chat_connection_failed, Toast.LENGTH_SHORT);
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
                    ToastHelper.showToast(TokenGenerateActivity.this, str, Toast.LENGTH_SHORT);
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
            super.onRemoteTrackAvailableNotify(uid, audioTrack, videoTrack);
        }

        /* 业务可能会触发同一个UserID的不同设备抢占的情况，所以这个地方也需要处理 */
        @Override
        public void onBye(int code){
            handler.post(new Runnable() {
                @Override
                public void run() {
                    String msg = "onBye code:" + code;
                    ToastHelper.showToast(TokenGenerateActivity.this, msg, Toast.LENGTH_SHORT);
                }
            });
        }
    };


    private void initAndSetupRtcEngine() {
        if(mAliRtcEngine == null) {
            mAliRtcEngine = AliRtcEngine.getInstance(this);
        }
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

        //设置默认订阅远端的音频和视频流
        mAliRtcEngine.setDefaultSubscribeAllRemoteAudioStreams(true);
        mAliRtcEngine.subscribeAllRemoteAudioStreams(true);
        mAliRtcEngine.setDefaultSubscribeAllRemoteVideoStreams(true);
        mAliRtcEngine.subscribeAllRemoteVideoStreams(true);

        mAliRtcEngine.setRtcEngineEventListener(mRtcEngineEventListener);
        mAliRtcEngine.setRtcEngineNotify(mRtcEngineNotify);
    }

    private void startPreview(){
        if (mAliRtcEngine != null) {
            ViewGroup localView = findViewById(R.id.preview_layer);
            localView.setVisibility(VISIBLE);
            ViewGroup.LayoutParams layoutParams = new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
            if(mLocalVideoCanvas == null) {
                mLocalVideoCanvas = new AliRtcEngine.AliRtcVideoCanvas();
                SurfaceView localSurfaceView = mAliRtcEngine.createRenderSurfaceView(TokenGenerateActivity.this);
                localSurfaceView.setZOrderOnTop(true);
                localSurfaceView.setZOrderMediaOverlay(true);
                localView.addView(localSurfaceView, layoutParams);
                mLocalVideoCanvas.view = localSurfaceView;
                mAliRtcEngine.setLocalViewConfig(mLocalVideoCanvas, AliRtcVideoTrackCamera);
                mAliRtcEngine.startPreview();
            }
        }
    }

    private void joinChannelWithSingleParameterToken(String token) {
        mAliRtcEngine.joinChannel(token, null, null, null);
    }

    private void joinChannelWithMultiParameterToken(String appId, String channelId, String userId, long timestamp,  String nonce, String token) {
        AliRtcAuthInfo authInfo = new AliRtcAuthInfo();
        authInfo.appId = appId;
        authInfo.channelId = channelId;
        authInfo.userId = userId;
        authInfo.timestamp = timestamp;
        authInfo.nonce = nonce;
        authInfo.token = token;
        mAliRtcEngine.joinChannel(authInfo, "");
    }


    public static void startActionActivity(Activity activity) {
        Intent intent = new Intent(activity, TokenGenerateActivity.class);
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
}