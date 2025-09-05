package com.aliyun.artc.api.basicusage.AudioBasicUsage;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Color;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;
import android.util.Log;
import android.view.Gravity;
import android.view.MenuItem;
import android.view.View;
import android.widget.AdapterView;
import android.widget.Button;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.GridLayout;
import android.widget.LinearLayout;
import android.widget.SeekBar;
import android.widget.Spinner;
import android.widget.Switch;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.SwitchCompat;
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

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class AudioBasicUsageActivity extends AppCompatActivity {
    private Handler handler;
    private AliRtcEngine mAliRtcEngine = null;
    private boolean hasJoined = false;
    private boolean isMute = false;
    private boolean isMicrophoneClosed = false;

    private Spinner mAudioRouteSpinner;
    private Spinner mAudioScenarioSpinner;
    private Spinner mAudioProfileSpinner;
    private Button mAudioMuteButton, mAudioStopCaptureButton;
    private EditText mChannelEditText;
    private TextView mJoinChannelButton;

    private Switch mAudioInEarSwitch;
    private SeekBar mAudioInEarVolumeSeekBar;

    private GridLayout mUserGridLayout; // 显示用户麦位
    private final Map<String, FrameLayout> remoteUsersMap = new ConcurrentHashMap<>(); // 绑定远端用户id和麦位
    private Map<String, Boolean> userMuteStatusMap = new HashMap<>(); // 维护远端用户的静音状态，键为用户ID，值为是否已静音

    private SeekBar mAudioPlayVolumeSeekBar;
    private SwitchCompat mMuteAllRemoteUserSwitch;

    // 耳返音量控制
    private SeekBar.OnSeekBarChangeListener mSeekBarChangeListener = new SeekBar.OnSeekBarChangeListener() {
        @Override
        public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
            if(mAliRtcEngine != null) {
                mAliRtcEngine.setEarBackVolume(progress);
            }
        }

        @Override
        public void onStartTrackingTouch(SeekBar seekBar) {
        }

        @Override
        public void onStopTrackingTouch(SeekBar seekBar) {
        }
    };

    private SeekBar.OnSeekBarChangeListener mAudioPlaySeekBarChangeListener = new SeekBar.OnSeekBarChangeListener() {
        @Override
        public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
            if(mAliRtcEngine != null) {
                mAliRtcEngine.setPlayoutVolume(progress);
            }
        }

        @Override
        public void onStartTrackingTouch(SeekBar seekBar) {
        }

        @Override
        public void onStopTrackingTouch(SeekBar seekBar) {
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        handler = new Handler(Looper.getMainLooper());
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_audio_basic_usage);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.audio_basic_usage_main), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });
        setTitle(getString(R.string.audio_basic_usage));
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);

        createRtcEngine();

        // UI 麦位
        mUserGridLayout = findViewById(R.id.grid_user_container);
        // 音频配置
        mAudioRouteSpinner = findViewById(R.id.audio_route_spinner);
        mAudioScenarioSpinner = findViewById(R.id.audio_scenario_spinner);
        mAudioProfileSpinner = findViewById(R.id.audio_profile_spinner);
        mAudioInEarSwitch = findViewById(R.id.audio_inear_monitor);
        mAudioInEarVolumeSeekBar = findViewById(R.id.audio_inear_monitor_volume);
        mAudioInEarVolumeSeekBar.setOnSeekBarChangeListener(mSeekBarChangeListener);
        mAudioInEarVolumeSeekBar.setMax(100);
        mAudioInEarVolumeSeekBar.setProgress(100);

        mAudioMuteButton = findViewById(R.id.mute_microphone);
        mAudioStopCaptureButton = findViewById(R.id.close_microphone);
        mChannelEditText = findViewById(R.id.channel_id_input);
        mJoinChannelButton = findViewById(R.id.join_room_btn);
        mChannelEditText.setText(GlobalConfig.getInstance().gerRandomChannelId());

        // 播放音量
        mAudioPlayVolumeSeekBar = findViewById(R.id.audio_player_volume_seekbar);
        mAudioPlayVolumeSeekBar.setEnabled(false);
        mAudioPlayVolumeSeekBar.setMax(400);
        mAudioPlayVolumeSeekBar.setProgress(100);
        mAudioPlayVolumeSeekBar.setOnSeekBarChangeListener(mAudioPlaySeekBarChangeListener);
        // 静音所有远端用户
        mMuteAllRemoteUserSwitch = findViewById(R.id.mute_all_remote_user_switch);
        // 音频路由选项
        mAudioRouteSpinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> adapterView, View view, int i, long l) {
                if (!hasJoined) {
                    return;
                }

                boolean isSpeaker = true;
                if(getString(R.string.audio_route_earpiece).equals(adapterView.getSelectedItem())) {
                    isSpeaker = false;
                }

                if(mAliRtcEngine != null) {
                    mAliRtcEngine.enableSpeakerphone(isSpeaker);
                }
            }

            @Override
            public void onNothingSelected(AdapterView<?> adapterView) {

            }
        });

        mAudioScenarioSpinner.setSelection(1);
        mAudioProfileSpinner.setSelection(2);

        mAudioInEarSwitch.setOnCheckedChangeListener((compoundButton, b) -> {
            if(mAliRtcEngine != null) {
                mAliRtcEngine.enableEarBack(b);
            }
        });

        mJoinChannelButton.setOnClickListener(v -> {
            if(hasJoined) {
                destroyRtcEngine();
                resetUIToDefault();
            } else {
                startRTCCall();
            }
        });

        mAudioMuteButton.setOnClickListener(v -> {
            if(mAliRtcEngine != null) {
                isMute = !isMute;
                mAliRtcEngine.muteLocalMic(isMute, AliRtcEngine.AliRtcMuteLocalAudioMode.AliRtcMuteAllAudioMode);
                mAudioMuteButton.setText(isMute ? R.string.unmute_microphone : R.string.mute_microphone);
            }
        });

        mAudioStopCaptureButton.setOnClickListener(v -> {
            isMicrophoneClosed = !isMicrophoneClosed;
            mAudioStopCaptureButton.setText(isMicrophoneClosed ? R.string.open_microphone: R.string.close_microphone);
            if(mAliRtcEngine != null) {
                if(isMicrophoneClosed) {
                    mAliRtcEngine.stopAudioCapture();
                } else {
                    mAliRtcEngine.startAudioCapture();
                }
            }
        });

        // 静音所有远端用户
        mMuteAllRemoteUserSwitch.setOnCheckedChangeListener((compoundButton, b) -> {
            if(mAliRtcEngine != null) {
                mAliRtcEngine.muteAllRemoteAudioPlaying(b);
            }
        });
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        destroyRtcEngine();
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

    public static void startActionActivity(Activity activity) {
        Intent intent = new Intent(activity, AudioBasicUsageActivity.class);
        activity.startActivity(intent);
    }

    // 退出会议后重新设置UI
    private void resetUIToDefault() {
        mJoinChannelButton.setText(R.string.video_chat_join_room);
        mAudioMuteButton.setText(R.string.mute_microphone);
        mAudioStopCaptureButton.setText(R.string.close_microphone);
        mAudioStopCaptureButton.setEnabled(false);
        isMute = false;
        isMicrophoneClosed = false;
        mAudioScenarioSpinner.setEnabled(true);
        mAudioProfileSpinner.setEnabled(true);

        mChannelEditText.setEnabled(true);

        mAudioInEarVolumeSeekBar.setProgress(100);
        mAudioInEarSwitch.setChecked(false);

        mAudioPlayVolumeSeekBar.setProgress(100);
        mAudioPlayVolumeSeekBar.setEnabled(false);
        mMuteAllRemoteUserSwitch.setChecked(false);

        // 清空远端用户列表
        mUserGridLayout.removeAllViews();

        remoteUsersMap.clear();
        userMuteStatusMap.clear();
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
            if(result == 0 ) {
                mJoinChannelButton.setText(R.string.leave_channel);
                //joinChannel后不可再调整AudioProfile和AudioScenario
                mAudioScenarioSpinner.setEnabled(false);
                mAudioProfileSpinner.setEnabled(false);
                mAudioStopCaptureButton.setEnabled(true);
                mChannelEditText.setEnabled(false);
                mAudioPlayVolumeSeekBar.setEnabled(true);
                // 设置本端麦位
                FrameLayout localFrameLayout = createFrameLayout("local_" + userId);
                mUserGridLayout.addView(localFrameLayout);
                remoteUsersMap.put(userId, localFrameLayout); // 将本地用户也加入到remoteUsersMap中统一管理

                // 在对应麦位显示用户ID
                TextView userIdText = new TextView(this);
                userIdText.setText("Local: " + userId);
                userIdText.setTextColor(Color.WHITE);
                userIdText.setBackgroundColor(Color.parseColor("#80000000"));
                userIdText.setPadding(10, 10, 10, 10);

                FrameLayout.LayoutParams layoutParams = new FrameLayout.LayoutParams(
                        FrameLayout.LayoutParams.MATCH_PARENT,
                        FrameLayout.LayoutParams.WRAP_CONTENT
                );
                layoutParams.gravity = Gravity.TOP | Gravity.START;
                userIdText.setLayoutParams(layoutParams);
                localFrameLayout.addView(userIdText);
            }
        });
    }

    // 创建一个FrameLayout用于添加麦位
    private FrameLayout createFrameLayout(String tag) {
        FrameLayout view = new FrameLayout(this);
        int sizeInDp = 180;
        int sizeInPx = (int) (getResources().getDisplayMetrics().density * sizeInDp);

        GridLayout.LayoutParams params = new GridLayout.LayoutParams();
        params.width = 0;
        params.height = sizeInPx;
        params.columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f);
        params.rowSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f);
        params.setMargins(8, 8, 8, 8);

        view.setLayoutParams(params);
        view.setTag(tag);
        view.setBackgroundColor(Color.GRAY);
        return view;
    }

    // 使用滑动条来设置音量
    private void showVolumeSeekBarDialog(String uid) {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle(getString(R.string.set_playout_volume));
        // 创建一个布局，包含滑动条
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setPadding(50, 40, 50, 10);

        final SeekBar seekBar = new SeekBar(this);
        seekBar.setMax(100); // 设置滑动条最大值
        seekBar.setProgress(100); // 默认值为 100
        layout.addView(seekBar);

        final TextView volumeLabel = new TextView(this);
        volumeLabel.setText("Playout Volume: 100"); // 初始值
        layout.addView(volumeLabel);

        // 监听滑动条的变化，动态显示当前值
        seekBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                volumeLabel.setText("Playout Volume: " + progress);
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {}

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {}
        });
        // 将布局加入对话框
        builder.setView(layout);
        // 确认按钮
        builder.setPositiveButton(getString(R.string.confirm), (dialog, which) -> {
            int volume = seekBar.getProgress();
            if(mAliRtcEngine != null) {
                mAliRtcEngine.setRemoteAudioVolume(uid, volume);
            }
        });
        builder.setNegativeButton(getString(R.string.cancel), (dialog, which) -> dialog.dismiss());
        // 显示对话框
        builder.show();
    }

    private void handleRemoteUserOnline(String uid) {
        // 创建新的麦位视图
        FrameLayout targetFrameLayout = createFrameLayout(uid);
        remoteUsersMap.put(uid, targetFrameLayout);
        mUserGridLayout.addView(targetFrameLayout);

        // 在对应麦位显示用户ID
        TextView userIdText = new TextView(this);
        userIdText.setText("Remote: " + uid);
        userIdText.setTextColor(Color.WHITE);
        userIdText.setBackgroundColor(Color.parseColor("#80000000"));
        userIdText.setPadding(10, 10, 10, 10);

        FrameLayout.LayoutParams layoutParams = new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.WRAP_CONTENT
        );
        layoutParams.gravity = Gravity.TOP | Gravity.START;
        userIdText.setLayoutParams(layoutParams);
        targetFrameLayout.addView(userIdText);

        // 为麦位添加点击事件
        targetFrameLayout.setOnClickListener(v -> {
            // 检查用户当前的静音状态，默认为未静音（false）
            boolean isMuted = userMuteStatusMap.containsKey(uid) && Boolean.TRUE.equals(userMuteStatusMap.get(uid));

            // 创建 AlertDialog
            AlertDialog.Builder builder = new AlertDialog.Builder(this);
            builder.setTitle(R.string.playout_volume_user_prompt_message + uid); // 设置对话框标题

            // 动态菜单项，根据静音状态调整内容
            String muteOption = isMuted ? getString(R.string.unmute_user) : getString(R.string.mute_user);
            String userPlayVolume = getString(R.string.set_playout_volume);
            builder.setItems(new String[]{muteOption,userPlayVolume, getString(R.string.cancel)}, (dialog, which) -> {
                switch (which) {
                    case 0: // 静音 / 取消静音
                        if(mAliRtcEngine != null) {
                            mAliRtcEngine.muteRemoteAudioPlaying(uid, !isMuted);
                        }
                        // 切换静音状态
                        userMuteStatusMap.put(uid, !isMuted);
                        break;
                    case 1:
                        dialog.dismiss();
                        showVolumeSeekBarDialog(uid);
                        break;
                    case 2: // 取消
                        dialog.dismiss();
                        break;
                }
            });

            // 显示对话框
            builder.show();
        });
    }

    /**
     * 处理远端用户离开
     * @param uid
     */
    private void handleRemoteUserOffline(String uid) {
        if (remoteUsersMap.containsKey(uid)) {
            // 找到对应的麦位清空
            FrameLayout targetFrameLayout = remoteUsersMap.get(uid);
            if (targetFrameLayout != null) {
                targetFrameLayout.removeAllViews(); // 移除显示的用户信息
                mUserGridLayout.removeView(targetFrameLayout); // 从GridLayout中移除整个麦位视图
            }
            remoteUsersMap.remove(uid); // 从管理列表删除
            userMuteStatusMap.remove(uid);
        }
    }

    private AliRtcEngineEventListener mRtcEngineEventListener = new AliRtcEngineEventListener() {
        @Override
        public void onJoinChannelResult(int result, String channel, String userId, int elapsed) {
            super.onJoinChannelResult(result, channel, userId, elapsed);
            handleJoinResult(result, channel, userId);
        }

        @Override
        public void onOccurWarning(int warn, String message){
            super.onOccurWarning(warn, message);
            handler.post(new Runnable() {
                @Override
                public void run() {
                    String str = "onOccurWarning warn: " + warn + " message: " + message;
                    ToastHelper.showToast(AudioBasicUsageActivity.this, str, Toast.LENGTH_SHORT);
                }
            });
        }

        @Override
        public void onLeaveChannelResult(int result, AliRtcEngine.AliRtcStats stats) {
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
                        ToastHelper.showToast(AudioBasicUsageActivity.this, R.string.connection_failed, Toast.LENGTH_SHORT);
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
                    ToastHelper.showToast(AudioBasicUsageActivity.this, str, Toast.LENGTH_SHORT);
                }
            });
        }

    };

    private AliRtcEngineNotify mRtcEngineNotify = new AliRtcEngineNotify() {
        @Override
        public void onAudioRouteChanged(AliRtcEngine.AliRtcAudioRouteType routing) {
            super.onAudioRouteChanged(routing);
            handler.post(new Runnable() {
                @Override
                public void run() {
                    String str = "Audio Route Changed, curr routing: " + routing;
                    ToastHelper.showToast(AudioBasicUsageActivity.this, str, Toast.LENGTH_SHORT);
                }
            });
        }

        @Override
        public void onAuthInfoWillExpire() {
            super.onAuthInfoWillExpire();
            /* TODO: 务必处理；Token即将过期，需要业务触发重新获取当前channel，user的鉴权信息，然后设置refreshAuthInfo即可 */
        }

        @Override
        public void onRemoteUserOnLineNotify(String uid, int elapsed){
            super.onRemoteUserOnLineNotify(uid, elapsed);
            handler.post(() -> handleRemoteUserOnline(uid));
        }

        //在onRemoteUserOffLineNotify回调中解除远端视频流渲染控件的设置
        @Override
        public void onRemoteUserOffLineNotify(String uid, AliRtcEngine.AliRtcUserOfflineReason reason){
            super.onRemoteUserOffLineNotify(uid, reason);
            handler.post(() -> handleRemoteUserOffline(uid));
        }

        @Override
        public void onBye(int code){
            super.onBye(code);
            handler.post(new Runnable() {
                @Override
                public void run() {
                    String msg = "onBye code:" + code;
                    ToastHelper.showToast(AudioBasicUsageActivity.this, msg, Toast.LENGTH_SHORT);
                }
            });
        }

        @Override
        public void onUserAudioMuted(String uid, boolean isMute){
            super.onUserAudioMuted(uid, isMute);
            handler.post(new Runnable() {
                @Override
                public void run() {
                    String mag = "onUserAudioMuted uid:" + uid + " isMute:" + isMute;
                    ToastHelper.showToast(AudioBasicUsageActivity.this, mag, Toast.LENGTH_SHORT);
                }
            });
        }
    };

    private final AliRtcEngine.AliRtcAudioVolumeObserver mAliRtcAudioVolumeObserver = new AliRtcEngine.AliRtcAudioVolumeObserver() {
        @Override
        public void onAudioVolume(List<AliRtcEngine.AliRtcAudioVolume> speakers, int totalVolume){
            handler.post(() -> {
                if(!speakers.isEmpty()) {
                    for(AliRtcEngine.AliRtcAudioVolume volume : speakers) {
                        if("0".equals(volume.mUserId)) {
                            // 本地当前用户音量

                        } else if ("1".equals(volume.mUserId)) {
                            // 远端用户整体音量

                        } else {
                            // 远端用户音量

                        }
                    }
                }
            });
        }

        @Override
        public void onActiveSpeaker(String uid){
            // 说话人
            handler.post(() -> {
                String mag = "onActiveSpeaker uid:" + uid;
                ToastHelper.showToast(AudioBasicUsageActivity.this, mag, Toast.LENGTH_SHORT);
            });
        }
    };

    private void startRTCCall() {
        if(hasJoined) {
            return;
        }
        initAndSetupRtcEngine();
        joinChannel();
    }

    private void createRtcEngine() {
        if(mAliRtcEngine == null) {
            mAliRtcEngine = AliRtcEngine.getInstance(this);
        }
    }

    private void initAndSetupRtcEngine() {
        if(mAliRtcEngine == null) {
            mAliRtcEngine = AliRtcEngine.getInstance(this);
        }
        // 设置频道模式为互动模式,RTC下都使用AliRTCSdkInteractiveLive
        mAliRtcEngine.setChannelProfile(AliRtcEngine.AliRTCSdkChannelProfile.AliRTCSdkInteractiveLive);
        // 设置用户角色，既需要推流也需要拉流使用AliRTCSdkInteractiv
        mAliRtcEngine.setClientRole(AliRtcEngine.AliRTCSdkClientRole.AliRTCSdkInteractive);

        //设置音频Profile，默认使用高音质模式AliRtcEngineHighQualityMode及音乐模式AliRtcSceneMusicMode
        mAliRtcEngine.setAudioProfile(getAudioProfile(), getAudioScenario());

        //SDK默认会publish音频，publishLocalAudioStream可以不调用
        mAliRtcEngine.publishLocalAudioStream(true);
        mAliRtcEngine.publishLocalVideoStream(false);

        //设置默认订阅远端的音频
        mAliRtcEngine.setDefaultSubscribeAllRemoteAudioStreams(true);
        mAliRtcEngine.subscribeAllRemoteAudioStreams(true);

        // 注册回调
        mAliRtcEngine.setRtcEngineEventListener(mRtcEngineEventListener);
        mAliRtcEngine.setRtcEngineNotify(mRtcEngineNotify);

        // 开启音量监测功能并注册音量数据回调
        mAliRtcEngine.enableAudioVolumeIndication(1000, 3,1);
        mAliRtcEngine.registerAudioVolumeObserver(mAliRtcAudioVolumeObserver);
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
            Log.e("AudioBasicUsageActivity", "channelId is empty");
        }
    }

    private void destroyRtcEngine() {
        if(mAliRtcEngine != null) {
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

    private AliRtcEngine.AliRtcAudioScenario getAudioScenario() {
        switch (mAudioScenarioSpinner.getSelectedItem().toString()) {
            case "DEFAULT":
                return AliRtcEngine.AliRtcAudioScenario.AliRtcSceneDefaultMode;
            case "MUSIC":
                return AliRtcEngine.AliRtcAudioScenario.AliRtcSceneMusicMode;
        }
        return AliRtcEngine.AliRtcAudioScenario.AliRtcSceneMusicMode;
    }

    private AliRtcEngine.AliRtcAudioProfile getAudioProfile() {
        switch (mAudioProfileSpinner.getSelectedItem().toString()) {
            case "LowQualityMode":
                return AliRtcEngine.AliRtcAudioProfile.AliRtcEngineLowQualityMode;
            case "BasicQualityMode":
                return AliRtcEngine.AliRtcAudioProfile.AliRtcEngineBasicQualityMode;
            case "HighQualityMode":
                return AliRtcEngine.AliRtcAudioProfile.AliRtcEngineHighQualityMode;
            case "StereoHighQualityMode":
                return AliRtcEngine.AliRtcAudioProfile.AliRtcEngineStereoHighQualityMode;
            case "SuperHighQualityMode":
                return AliRtcEngine.AliRtcAudioProfile.AliRtcEngineSuperHighQualityMode;
            case "StereoSuperHighQualityMode":
                return AliRtcEngine.AliRtcAudioProfile.AliRtcEngineStereoSuperHighQualityMode;
        }
        return AliRtcEngine.AliRtcAudioProfile.AliRtcEngineHighQualityMode;
    }
}
