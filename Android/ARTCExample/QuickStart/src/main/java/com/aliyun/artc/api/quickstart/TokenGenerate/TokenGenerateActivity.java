package com.aliyun.artc.api.quickstart.TokenGenerate;

import static android.view.View.VISIBLE;
import static com.alivc.rtc.AliRtcEngine.AliRtcVideoEncoderOrientationMode.AliRtcVideoEncoderOrientationModeAdaptive;
import static com.alivc.rtc.AliRtcEngine.AliRtcVideoTrack.AliRtcVideoTrackCamera;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Color;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;
import android.view.MenuItem;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AlertDialog;
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
    private Spinner mExpireSpinner;
    private TextView mTimestampTextView;
    private EditText mNonceEditText;

    private long mCurrentTimestamp = 0;

    private LinearLayout mContentLayout;
    private TextView mContentTextView;
    private LinearLayout mSha256Layout;
    private TextView mSha256TextView;
    private TextView mSha256LabelTextView;
    private LinearLayout mJsonLayout;
    private TextView mJsonTextView;
    private LinearLayout mTokenLayout;
    private TextView mTokenTextView;
    private TextView mTokenLabelTextView;
    private LinearLayout mJoinResultLayout;
    private TextView mJoinResultTextView;

    private AliRtcEngine mAliRtcEngine = null;
    private AliRtcEngine.AliRtcVideoCanvas mLocalVideoCanvas = null;

    private boolean hasJoined = false;
    private boolean isMultiParamMode = false; // 记录当前使用的入会模式

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
        setupExpireSpinner();

        findViewById(R.id.multi_param_join_btn).setOnClickListener(v -> {
            if (hasJoined) {
                // 如果已入会，先挂断
                destroyRtcEngine();
                ((TextView) findViewById(R.id.multi_param_join_btn)).setText(R.string.multiple_parameters_join);
                if (isMultiParamMode) {
                    // 如果是同一个按钮，不再执行入会
                    return;
                }
            }
            // 执行多参入会
            startRTCCall(true);
        });
        findViewById(R.id.sigle_param_join_btn).setOnClickListener(v -> {
            if (hasJoined) {
                // 如果已入会，先挂断
                destroyRtcEngine();
                ((TextView) findViewById(R.id.sigle_param_join_btn)).setText(R.string.signle_parameters_join);
                if (!isMultiParamMode) {
                    // 如果是同一个按钮，不再执行入会
                    return;
                }
            }
            // 执行单参入会
            startRTCCall(false);
        });

    }

    private void setDefaultData() {
        mAppIdEditText = findViewById(R.id.app_id_input);
        mAppIdEditText.setText(GlobalConfig.getInstance().getAppId());
        mAppKeyEditText = findViewById(R.id.app_key_input);
        mAppKeyEditText.setText(GlobalConfig.getInstance().getAppKey());
        mChannelIdEditText = findViewById(R.id.ll_channel_input);
        mChannelIdEditText.setText(GlobalConfig.getInstance().gerRandomChannelId());
        mUserIdEditText = findViewById(R.id.user_id_input);
        mUserIdEditText.setText(GlobalConfig.getInstance().getUserId());
        mNonceEditText = findViewById(R.id.ll_nonce_input);
        mExpireSpinner = findViewById(R.id.ll_expire_spinner);
        mTimestampTextView = findViewById(R.id.ll_timestamp_value);

        mContentLayout = findViewById(R.id.ll_content_raw);
        mContentTextView = findViewById(R.id.ll_content_raw_input);
        mSha256Layout = findViewById(R.id.ll_sha256);
        mSha256TextView = findViewById(R.id.ll_sha256_input);
        mSha256LabelTextView = findViewById(R.id.ll_sha256_label);
        mJsonLayout = findViewById(R.id.ll_json);
        mJsonTextView = findViewById(R.id.ll_json_input);
        mTokenLayout = findViewById(R.id.ll_token);
        mTokenTextView = findViewById(R.id.ll_token_input);
        mTokenLabelTextView = findViewById(R.id.ll_token_label);
        mJoinResultLayout = findViewById(R.id.ll_join_result);
        mJoinResultTextView = findViewById(R.id.ll_join_result_input);
    }

    /**
     * 根据 Spinner 选择的位置获取过期时长（秒）
     */
    private long getExpireSecondsFromSpinnerPosition(int position) {
        switch (position) {
            case 0: // 1 Minute
                return 60;
            case 1: // 1 Hour
                return 60 * 60;
            case 2: // 6 Hours
                return 60 * 60 * 6;
            case 3: // 12 Hours
                return 60 * 60 * 12;
            case 4: // 1 Day
                return 60 * 60 * 24;
            case 5: // 2 Days
                return 60 * 60 * 24 * 2;
            case 6: // 7 Days
                return 60 * 60 * 24 * 7;
            case 7: // 30 Days
                return 60 * 60 * 24 * 30;
            default:
                return 60 * 60 * 24; // 默认 1 天
        }
    }

    /**
     * 根据当前选择的过期时长更新时间戳
     */
    private void updateTimestamp() {
        int position = mExpireSpinner.getSelectedItemPosition();
        long expireSeconds = getExpireSecondsFromSpinnerPosition(position);
        long currentTime = System.currentTimeMillis() / 1000;
        mCurrentTimestamp = currentTime + expireSeconds;
        mTimestampTextView.setText(String.valueOf(mCurrentTimestamp));
    }

    private void setupExpireSpinner() {
        String[] expireOptions = {
                "1 Minute",
                "1 Hour",
                "6 Hours",
                "12 Hours",
                "1 Day (Default)",
                "2 Days",
                "7 Days",
                "30 Days"
        };

        ArrayAdapter<String> adapter = new ArrayAdapter<>(this,
                android.R.layout.simple_spinner_item, expireOptions);
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        mExpireSpinner.setAdapter(adapter);
        mExpireSpinner.setSelection(4); // 默认1天

        mExpireSpinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                // 根据选择的过期时间更新时间戳
                updateTimestamp();
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {
            }
        });

        // 初始化默认时间戳
        updateTimestamp();
    }

    private void handleJoinResult(int result, String channel, String userId) {
        handler.post(() -> {
            String str;
            if (result == 0) {
                str = "User " + userId + " Join " + channel + " Success";
                mJoinResultTextView.setTextColor(Color.GREEN);
            } else {
                str = "User " + userId + " Join " + channel + " Failed，error：" + result;
                mJoinResultTextView.setTextColor(Color.RED);
            }
            mJoinResultLayout.setVisibility(VISIBLE);
            mJoinResultTextView.setText(str);
        });
    }

    private void startRTCCall(boolean isMultiParamJoin) {
        String appId = mAppIdEditText.getText().toString().trim();
        String appKey = mAppKeyEditText.getText().toString().trim();
        String channelId = mChannelIdEditText.getText().toString().trim();
        String userId = mUserIdEditText.getText().toString().trim();
        String nonce = mNonceEditText.getText().toString().trim();

        if (TextUtils.isEmpty(appId) || TextUtils.isEmpty(appKey) || TextUtils.isEmpty(channelId)
                || TextUtils.isEmpty(userId)) {
            ToastHelper.showToast(this, "AppId/AppKey/ChannelId/UserId cannot be empty", Toast.LENGTH_SHORT);
            return;
        }

        // 重新计算过期时间戳（基于当前时间 + 选择的过期时长）
        updateTimestamp();
        long timestamp = mCurrentTimestamp;

        // 使用 ARTCTokenHelper 生成 Token
        String token = "";
        if (isMultiParamJoin) {
            // 多参入会：调用 Helper 生成 Token
            token = ARTCTokenHelper.generateMulitParameterToken(
                    appId, appKey, channelId, userId, timestamp, nonce
            );

            // 从 Helper 获取中间过程展示
            mContentLayout.setVisibility(VISIBLE);
            mContentTextView.setText(ARTCTokenHelper.getLastContent());

            mSha256Layout.setVisibility(VISIBLE);
            mSha256LabelTextView.setText("SHA256 (Token):");
            mSha256TextView.setText(ARTCTokenHelper.getLastSha256Token());

            mJsonLayout.setVisibility(View.GONE);
            mTokenLayout.setVisibility(View.GONE);
        } else {
            // 单参入会：调用 Helper 生成 Token
            token = ARTCTokenHelper.generateSingleParameterToken(
                    appId, appKey, channelId, userId, timestamp, nonce
            );

            // 从 Helper 获取中间过程展示
            mContentLayout.setVisibility(VISIBLE);
            mContentTextView.setText(ARTCTokenHelper.getLastContent());

            mSha256Layout.setVisibility(VISIBLE);
            mSha256LabelTextView.setText("SHA256:");
            mSha256TextView.setText(ARTCTokenHelper.getLastSha256Token());

            mJsonLayout.setVisibility(VISIBLE);
            mJsonTextView.setText(ARTCTokenHelper.getLastJsonString());

            mTokenLayout.setVisibility(VISIBLE);
            mTokenLabelTextView.setText("Base64 (Token):");
            mTokenTextView.setText(ARTCTokenHelper.getLastBase64Token());
        }

        if (TextUtils.isEmpty(token)) {
            ToastHelper.showToast(this, "生成 Token 失败", Toast.LENGTH_SHORT);
            return;
        }

        initAndSetupRtcEngine();
        startPreview();

        if (isMultiParamJoin) {
            joinChannelWithMultiParameterToken(appId, channelId, userId, timestamp, nonce, token);
            ((TextView) findViewById(R.id.multi_param_join_btn)).setText(R.string.leave_channel);
            ((TextView) findViewById(R.id.sigle_param_join_btn)).setText(R.string.signle_parameters_join);
            isMultiParamMode = true;
        } else {
            joinChannelWithSingleParameterToken(token);
            ((TextView) findViewById(R.id.sigle_param_join_btn)).setText(R.string.leave_channel);
            ((TextView) findViewById(R.id.multi_param_join_btn)).setText(R.string.multiple_parameters_join);
            isMultiParamMode = false;
        }

        hasJoined = true;
    }

    private void destroyRtcEngine() {
        if (mAliRtcEngine != null) {
            mAliRtcEngine.stopPreview();
            mAliRtcEngine.leaveChannel();
            mAliRtcEngine.destroy();
            mAliRtcEngine = null;
            handler.post(() -> ToastHelper.showToast(this, "Leave Channel", Toast.LENGTH_SHORT));
        }
        mLocalVideoCanvas = null;
        findViewById(R.id.preview_layer).setVisibility(View.GONE);
        hasJoined = false;

        // 重置按钮状态
        ((TextView) findViewById(R.id.multi_param_join_btn)).setText(R.string.multiple_parameters_join);
        ((TextView) findViewById(R.id.sigle_param_join_btn)).setText(R.string.signle_parameters_join);
    }

    /**
     * 刷新 Token（用于 Token 即将过期时调用）
     */
    private void refreshToken() {
        if (mAliRtcEngine == null || !hasJoined) {
            ToastHelper.showToast(this, "当前不在频道中，无法刷新 Token", Toast.LENGTH_SHORT);
            return;
        }

        // 重新生成一个Token
        String appId = mAppIdEditText.getText().toString().trim();
        String appKey = mAppKeyEditText.getText().toString().trim();
        String channelId = mChannelIdEditText.getText().toString().trim();
        String userId = mUserIdEditText.getText().toString().trim();
        String nonce = mNonceEditText.getText().toString().trim();

        if (TextUtils.isEmpty(appId) || TextUtils.isEmpty(appKey)
                || TextUtils.isEmpty(channelId) || TextUtils.isEmpty(userId)) {
            ToastHelper.showToast(this, "AppId/AppKey/ChannelId/UserId 不能为空", Toast.LENGTH_SHORT);
            return;
        }

        // 重新计算过期时间戳（基于当前时间 + 选择的过期时长）
        updateTimestamp();

        // 使用 ARTCTokenHelper 生成新的 Token
        String newToken = "";
        int ret;

        if (isMultiParamMode) {
            // 多参数入会：调用 Helper 生成 Token
            newToken = ARTCTokenHelper.generateMulitParameterToken(
                    appId, appKey, channelId, userId, mCurrentTimestamp, nonce
            );

            // 更新 UI 展示
            mContentLayout.setVisibility(VISIBLE);
            mContentTextView.setText(ARTCTokenHelper.getLastContent());
            mSha256Layout.setVisibility(VISIBLE);
            mSha256LabelTextView.setText("SHA256 (Token):");
            mSha256TextView.setText(ARTCTokenHelper.getLastSha256Token());
            mJsonLayout.setVisibility(View.GONE);
            mTokenLayout.setVisibility(View.GONE);

            // 刷新多参 Token
            AliRtcAuthInfo authInfo = new AliRtcAuthInfo();
            authInfo.appId = appId;
            authInfo.channelId = channelId;
            authInfo.userId = userId;
            authInfo.timestamp = mCurrentTimestamp;
            authInfo.nonce = nonce;
            authInfo.token = newToken;
            ret = mAliRtcEngine.refreshAuthInfo(authInfo);
        } else {
            // 单参数入会：调用 Helper 生成 Token
            newToken = ARTCTokenHelper.generateSingleParameterToken(
                    appId, appKey, channelId, userId, mCurrentTimestamp, nonce
            );

            // 更新 UI 展示
            mContentLayout.setVisibility(VISIBLE);
            mContentTextView.setText(ARTCTokenHelper.getLastContent());
            mSha256Layout.setVisibility(VISIBLE);
            mSha256LabelTextView.setText("SHA256:");
            mSha256TextView.setText(ARTCTokenHelper.getLastSha256Token());
            mJsonLayout.setVisibility(VISIBLE);
            mJsonTextView.setText(ARTCTokenHelper.getLastJsonString());
            mTokenLayout.setVisibility(VISIBLE);
            mTokenLabelTextView.setText("Base64 (Token):");
            mTokenTextView.setText(ARTCTokenHelper.getLastBase64Token());

            // 刷新单参 Token
            ret = mAliRtcEngine.refreshAuthInfo(newToken);
        }

        if (ret == 0) {
            ToastHelper.showToast(this, "Token 刷新成功", Toast.LENGTH_SHORT);
        } else {
            ToastHelper.showToast(this, "Token 刷新失败，错误码：" + ret, Toast.LENGTH_SHORT);
        }
    }

    private AliRtcEngineEventListener mRtcEngineEventListener = new AliRtcEngineEventListener() {
        @Override
        public void onJoinChannelResult(int result, String channel, String userId, int elapsed) {
            super.onJoinChannelResult(result, channel, userId, elapsed);
            handleJoinResult(result, channel, userId);
        }

        @Override
        public void onLeaveChannelResult(int result, AliRtcEngine.AliRtcStats stats) {
            super.onLeaveChannelResult(result, stats);
        }

        @Override
        public void onConnectionStatusChange(AliRtcEngine.AliRtcConnectionStatus status,
                                            AliRtcEngine.AliRtcConnectionStatusChangeReason reason) {
            super.onConnectionStatusChange(status, reason);
            handler.post(() -> {
                if (status == AliRtcEngine.AliRtcConnectionStatus.AliRtcConnectionStatusFailed) {
                    ToastHelper.showToast(TokenGenerateActivity.this,
                            R.string.video_chat_connection_failed, Toast.LENGTH_SHORT);
                }
            });
        }

        @Override
        public void OnLocalDeviceException(AliRtcEngine.AliRtcEngineLocalDeviceType deviceType,
                                          AliRtcEngine.AliRtcEngineLocalDeviceExceptionType exceptionType,
                                          String msg) {
            super.OnLocalDeviceException(deviceType, exceptionType, msg);
            handler.post(() -> {
                String str = "OnLocalDeviceException deviceType: " + deviceType
                        + " exceptionType: " + exceptionType + " msg: " + msg;
                ToastHelper.showToast(TokenGenerateActivity.this, str, Toast.LENGTH_SHORT);
            });
        }
    };

    private AliRtcEngineNotify mRtcEngineNotify = new AliRtcEngineNotify() {
        @Override
        public void onAuthInfoWillExpire() {
            super.onAuthInfoWillExpire();
            // Token 即将过期（提前 30 秒），弹窗提示并提供刷新按钮
            handler.post(() -> {
                new AlertDialog.Builder(TokenGenerateActivity.this)
                        .setTitle("Token 即将过期")
                        .setMessage("当前 Token 即将在 30 秒后过期，是否刷新 Token 继续通话？")
                        .setPositiveButton("刷新 Token", (dialog, which) -> {
                            refreshToken();
                        })
                        .setNegativeButton("稍后", null)
                        .show();
            });
        }

        @Override
        public void onAuthInfoExpired(){
            // Token 已过期，弹窗提示用户重新入会
            handler.post(() -> {
                new AlertDialog.Builder(TokenGenerateActivity.this)
                        .setTitle("Token 已过期")
                        .setMessage("当前 Token 已经过期，请重新加入会议。")
                        .setPositiveButton("确定", (dialog, which) -> {
                            // 挂断当前会话，用户可以重新点击入会按钮
                            destroyRtcEngine();
                        })
                        .setCancelable(false)
                        .show();
            });
        };

        @Override
        public void onRemoteUserOnLineNotify(String uid, int elapsed) {
            super.onRemoteUserOnLineNotify(uid, elapsed);
        }

        @Override
        public void onRemoteUserOffLineNotify(String uid, AliRtcEngine.AliRtcUserOfflineReason reason) {
            super.onRemoteUserOffLineNotify(uid, reason);
        }

        @Override
        public void onRemoteTrackAvailableNotify(String uid, AliRtcEngine.AliRtcAudioTrack audioTrack,
                                                 AliRtcEngine.AliRtcVideoTrack videoTrack) {
            super.onRemoteTrackAvailableNotify(uid, audioTrack, videoTrack);
        }

        @Override
        public void onBye(int code) {
            handler.post(() -> {
                String msg = "onBye code:" + code;
                ToastHelper.showToast(TokenGenerateActivity.this, msg, Toast.LENGTH_SHORT);
            });
        }
    };


    private void initAndSetupRtcEngine() {
        if (mAliRtcEngine == null) {
            mAliRtcEngine = AliRtcEngine.getInstance(this);
        }
        // 设置频道模式为互动模式
        mAliRtcEngine.setChannelProfile(AliRtcEngine.AliRTCSdkChannelProfile.AliRTCSdkInteractiveLive);
        // 设置用户角色为互动角色
        mAliRtcEngine.setClientRole(AliRtcEngine.AliRTCSdkClientRole.AliRTCSdkInteractive);
        // 设置音频Profile
        mAliRtcEngine.setAudioProfile(AliRtcEngine.AliRtcAudioProfile.AliRtcEngineHighQualityMode,
                AliRtcEngine.AliRtcAudioScenario.AliRtcSceneMusicMode);
        mAliRtcEngine.setCapturePipelineScaleMode(
                AliRtcEngine.AliRtcCapturePipelineScaleMode.AliRtcCapturePipelineScaleModePost);

        // 设置视频编码参数
        AliRtcEngine.AliRtcVideoEncoderConfiguration aliRtcVideoEncoderConfiguration =
                new AliRtcEngine.AliRtcVideoEncoderConfiguration();
        aliRtcVideoEncoderConfiguration.dimensions = new AliRtcEngine.AliRtcVideoDimensions(720, 1280);
        aliRtcVideoEncoderConfiguration.frameRate = 20;
        aliRtcVideoEncoderConfiguration.bitrate = 1200;
        aliRtcVideoEncoderConfiguration.keyFrameInterval = 2000;
        aliRtcVideoEncoderConfiguration.orientationMode = AliRtcVideoEncoderOrientationModeAdaptive;
        mAliRtcEngine.setVideoEncoderConfiguration(aliRtcVideoEncoderConfiguration);

        // 设置默认订阅远端的音频和视频流
        mAliRtcEngine.setDefaultSubscribeAllRemoteAudioStreams(true);
        mAliRtcEngine.subscribeAllRemoteAudioStreams(true);
        mAliRtcEngine.setDefaultSubscribeAllRemoteVideoStreams(true);
        mAliRtcEngine.subscribeAllRemoteVideoStreams(true);

        mAliRtcEngine.setRtcEngineEventListener(mRtcEngineEventListener);
        mAliRtcEngine.setRtcEngineNotify(mRtcEngineNotify);
    }

    private void startPreview() {
        if (mAliRtcEngine != null) {
            ViewGroup localView = findViewById(R.id.preview_layer);
            localView.setVisibility(VISIBLE);
            ViewGroup.LayoutParams layoutParams = new FrameLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
            if (mLocalVideoCanvas == null) {
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

    private void joinChannelWithMultiParameterToken(String appId, String channelId, String userId,
                                                   long timestamp, String nonce, String token) {
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

    @Override
    protected void onDestroy() {
        super.onDestroy();
        // 确保退出时挂断
        destroyRtcEngine();
    }
}