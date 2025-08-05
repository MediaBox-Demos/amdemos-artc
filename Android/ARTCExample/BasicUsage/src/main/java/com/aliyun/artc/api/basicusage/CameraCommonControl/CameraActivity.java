package com.aliyun.artc.api.basicusage.CameraCommonControl;

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
import android.util.Pair;
import android.view.GestureDetector;
import android.view.MenuItem;
import android.view.MotionEvent;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.SeekBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.EdgeToEdge;
import androidx.annotation.NonNull;
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

import java.util.Map;
import java.util.Objects;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 音视频通话场景API调用示例
 */
public class CameraActivity extends AppCompatActivity {

    private Handler handler;
    private EditText mChannelEditText;
    private TextView mJoinChannelTextView;
    private boolean hasJoined = false;
    private FrameLayout fl_local, fl_remote;
    private static final int DOUBLE_TAP_TIMEOUT = 300; // 设置双击超时
    private long lastTapTime = 0;

    private AliRtcEngine mAliRtcEngine = null;
    private AliRtcEngine.AliRtcVideoCanvas mLocalVideoCanvas = null;
    private Map<String, ViewGroup> remoteViews = new ConcurrentHashMap<String, ViewGroup>();

    private SeekBar zoomSeekBar;
    private TextView zoomTextView;

    private SeekBar exposureSeekBar;
    private TextView exposureTextView;
    private Button mCameraBtn;

    private GestureDetector mLocalViewGestureDetector;
    private TextView mCameraExposurePointX;
    private TextView mCameraExposurePointY;
    private TextView mCameraFocusPointX;
    private TextView mCameraFocusPointY;
    private SwitchCompat mCameraFlashSwitch;
    private SwitchCompat mCameraAutoFaceFocusSwitch;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        handler = new Handler(Looper.getMainLooper());
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_camera);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.camera_test), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });
        setTitle(getString(R.string.camera_common_control));
        Objects.requireNonNull(getSupportActionBar()).setDisplayHomeAsUpEnabled(true);

        // UI
        initUI();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        destroyRtcEngine();
    }

    private void initUI() {
        // 视频显示区域
        fl_local = findViewById(R.id.fl_local);
        fl_remote = findViewById(R.id.fl_remote);

        mChannelEditText = findViewById(R.id.channel_id_input);
        mChannelEditText.setText(GlobalConfig.getInstance().gerRandomChannelId());
        mJoinChannelTextView = findViewById(R.id.join_room_btn);
        mJoinChannelTextView.setOnClickListener(v -> {
            if(hasJoined) {
                destroyRtcEngine();
                mJoinChannelTextView.setText(R.string.video_chat_join_room);
                resetUI();
            } else {
                startRTCCall();
                mCameraBtn.setEnabled(true);
                zoomSeekBar.setEnabled(true);
                exposureSeekBar.setEnabled(true);
                mCameraFlashSwitch.setEnabled(true);
                mCameraAutoFaceFocusSwitch.setEnabled(true);
            }
        });

        //相机反转摄像头相关事件
        mCameraBtn = findViewById(R.id.switchCameraButton);
        mCameraBtn.setEnabled(false);
        mCameraBtn.setOnClickListener(v -> {
            if(mAliRtcEngine == null) {
                return;
            }
            if(mAliRtcEngine.getCurrentCameraDirection() == AliRtcEngine.AliRtcCameraDirection.CAMERA_FRONT) {
                mCameraBtn.setText(getString(R.string.current_rear_camera));
            }else{
                mCameraBtn.setText(getString(R.string.current_front_camera));
            }
            mAliRtcEngine.switchCamera();
            new Handler(Looper.getMainLooper()).postDelayed(() -> {
                initExposureSeekBar();
                initZoomSeekBar();
                if(!mAliRtcEngine.isCameraAutoFocusFaceModeSupported()) {
                    mCameraAutoFaceFocusSwitch.setChecked(false);
                    mCameraAutoFaceFocusSwitch.setEnabled(false);
                } else {
                    mCameraAutoFaceFocusSwitch.setEnabled(true);
                }
            }, 300);
        });

        mLocalViewGestureDetector = new GestureDetector(this, new GestureDetector.SimpleOnGestureListener() {
            @Override
            public boolean onDoubleTap(@NonNull MotionEvent e) {
                // 处理双击
                if(mAliRtcEngine != null && mAliRtcEngine.isCameraFocusPointSupported()) {
                    float[] normalizedCoords = getNormalizedCoordinates(e.getX(), e.getY());
                    if (normalizedCoords[0] != -1 && normalizedCoords[1] != -1) {
                        mAliRtcEngine.setCameraFocusPoint(normalizedCoords[0], normalizedCoords[1]);
                        mCameraFocusPointX.setText(String.format("%.2f", normalizedCoords[0]));
                        mCameraFocusPointY.setText(String.format("%.2f", normalizedCoords[1]));
                    }
                }
                return true;
            }
            @Override
            public boolean onSingleTapConfirmed(@NonNull MotionEvent e) {
                // 处理单击
                if(mAliRtcEngine != null && mAliRtcEngine.isCameraExposurePointSupported()) {
                    float[] normalizedCoords = getNormalizedCoordinates(e.getX(), e.getY());
                    if (normalizedCoords[0] != -1 && normalizedCoords[1] != -1) {
                        mAliRtcEngine.setCameraExposurePoint(normalizedCoords[0], normalizedCoords[1]);
                        mCameraExposurePointX.setText(String.format("%.2f", normalizedCoords[0]));
                        mCameraExposurePointY.setText(String.format("%.2f", normalizedCoords[1]));
                    }
                }
                return true;
            }
        });

        mCameraExposurePointX = findViewById(R.id.exposure_point_x);
        mCameraExposurePointY = findViewById(R.id.exposure_point_y);
        mCameraFocusPointX = findViewById(R.id.focus_point_x);
        mCameraFocusPointY = findViewById(R.id.focus_point_y);

        //缩放相关事件
        zoomSeekBar = findViewById(R.id.zoomSeekBar);
        zoomSeekBar.setEnabled(false);
        zoomTextView = findViewById(R.id.zoomFactorValue);

        zoomSeekBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int i, boolean b) {
                if(mAliRtcEngine != null) {
                    float newZoom = (float)((i+10) / 10.0);
                    mAliRtcEngine.setCameraZoom(newZoom);
                    zoomTextView.setText(String.format("%.1f", newZoom));
                }
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {
            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {
            }
        });

        exposureSeekBar = findViewById(R.id.exposureSeekBar);
        exposureSeekBar.setEnabled(false);
        exposureTextView = findViewById(R.id.exposureValue);
        exposureSeekBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int i, boolean b) {
                if(mAliRtcEngine != null) {
                    float minExposure = mAliRtcEngine.GetMinExposure();
                    float newExposure = minExposure + (float)(i / 10.0);

                    mAliRtcEngine.SetExposure(newExposure);
                    exposureTextView.setText(String.format("% .1f", newExposure));
                }
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {
            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {
            }
        });

        // 摄像头自动人脸聚焦
        mCameraAutoFaceFocusSwitch = findViewById(R.id.camera_auto_face_focus_switch);
        mCameraAutoFaceFocusSwitch.setEnabled(false);
        mCameraAutoFaceFocusSwitch.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (mAliRtcEngine != null) {
                if (mAliRtcEngine.isCameraAutoFocusFaceModeSupported()) {
                    mAliRtcEngine.setCameraAutoFocusFaceModeEnabled(isChecked);
                } else {
                    ToastHelper.showToast(CameraActivity.this, "Not support camera auto focus mode!", Toast.LENGTH_SHORT);
                    mCameraAutoFaceFocusSwitch.setEnabled(false);
                    mCameraAutoFaceFocusSwitch.setChecked(false);
                }
            }
        });
        // 闪光灯相关事件
        mCameraFlashSwitch = findViewById(R.id.camera_flash_switch);
        mCameraFlashSwitch.setEnabled(false);
        mCameraFlashSwitch.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (mAliRtcEngine != null) {
                mAliRtcEngine.setCameraFlash(isChecked);
            }
        });
    }

    private void resetUI() {
        mCameraBtn.setEnabled(false);
        mCameraBtn.setText(R.string.Switch_camera);
        zoomSeekBar.setProgress(0);
        exposureSeekBar.setProgress(0);
        zoomSeekBar.setEnabled(false);
        exposureSeekBar.setEnabled(false);
        mCameraExposurePointX.setText("");
        mCameraExposurePointY.setText("");
        mCameraFocusPointX.setText("");
        mCameraFocusPointY.setText("");
        mCameraAutoFaceFocusSwitch.setChecked(false);
        mCameraAutoFaceFocusSwitch.setEnabled(false);
        mCameraFlashSwitch.setChecked(false);
        mCameraFlashSwitch.setEnabled(false);

        for (ViewGroup value : remoteViews.values()) {
            value.removeAllViews();
        }
        remoteViews.clear();
        findViewById(R.id.ll_video_layout).setVisibility(View.GONE);
        fl_local.removeAllViews();
        mLocalVideoCanvas = null;
    }
    private void initZoomSeekBar() {
        if (mAliRtcEngine != null) {
            zoomSeekBar.setEnabled(true);
            // 获取最大zoom值
            float maxZoom = mAliRtcEngine.GetCameraMaxZoomFactor();
            float currZoom = mAliRtcEngine.GetCurrentZoom();
            // 设置SeekBar范围（1.0到maxZoom，0.1步进）
            if(maxZoom >= 1.0) {
                int maxProgress = (int)((maxZoom - 1) * 10);
                zoomSeekBar.setMax(maxProgress);
                int currProgress = (int)((currZoom - 1) * 10);
                zoomSeekBar.setProgress(currProgress);
            } else{
                zoomSeekBar.setEnabled(false);
            }
        }
    }

    private void initExposureSeekBar() {
        if (mAliRtcEngine != null) {
            exposureSeekBar.setEnabled(true);
            // 获取最大zoom值
            float maxExposure = mAliRtcEngine.GetMaxExposure();
            // 获取最小zoom值
            float minExposure = mAliRtcEngine.GetMinExposure();
            float currExposure = mAliRtcEngine.GetCurrentExposure();
            if(maxExposure > minExposure) {
                // 重新设置SeekBar范围
                int maxProgress = (int)(maxExposure - minExposure) * 10;
                exposureSeekBar.setMax(maxProgress);
                int currProgress = (int)((currExposure - minExposure) * 10);
                exposureSeekBar.setProgress(currProgress);
            } else {
                exposureSeekBar.setEnabled(false);
            }
        }
    }

    public static void startActionActivity(Activity activity) {
        Intent intent = new Intent(activity, CameraActivity.class);
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
        }  else {
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
        initAndSetupRtcEngine();
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
                SurfaceView localSurfaceView = mAliRtcEngine.createRenderSurfaceView(CameraActivity.this);
                localSurfaceView.setZOrderOnTop(true);
                localSurfaceView.setZOrderMediaOverlay(true);
                localSurfaceView.setOnTouchListener((v, event) -> {
                    mLocalViewGestureDetector.onTouchEvent(event);
                    return true;
                });
                fl_local.addView(localSurfaceView, layoutParams);
                mLocalVideoCanvas.view = localSurfaceView;
                mAliRtcEngine.setLocalViewConfig(mLocalVideoCanvas, AliRtcVideoTrackCamera);
                mAliRtcEngine.startPreview();
            }
        }
    }

    // 获取归一化坐标
    private float[] getNormalizedCoordinates(float touchX, float touchY) {
        if (fl_local.getChildCount() > 0) {
            View childView = fl_local.getChildAt(0);
            if (childView instanceof SurfaceView) {
                SurfaceView surfaceView = (SurfaceView) childView;

                int componentWidth = surfaceView.getWidth();
                int componentHeight = surfaceView.getHeight();

                // 计算归一化坐标
                float cameraX = touchX / componentWidth;  // 单位为0到1之间
                float cameraY = touchY / componentHeight; // 单位为0到1之间

                return new float[]{cameraX, cameraY};
            }
        }
        return new float[]{-1.0f, -1.0f};
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
            Log.e("cameraActivity", "channelId is empty");
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
                        ToastHelper.showToast(CameraActivity.this, R.string.basic_usage, Toast.LENGTH_SHORT);
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
                    String str = "recv msg: " + msg;
                    ToastHelper.showToast(CameraActivity.this, str, Toast.LENGTH_SHORT);
                }
            });
        }

    };

    private AliRtcEngineNotify mRtcEngineNotify = new AliRtcEngineNotify() {

        @Override
        public void onFirstLocalVideoFrameDrawn(int width, int height, int elapsed){
            super.onFirstLocalVideoFrameDrawn(width, height, elapsed);
            initZoomSeekBar();
            initExposureSeekBar();
        }
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
                        SurfaceView surfaceView = mAliRtcEngine.createRenderSurfaceView(CameraActivity.this);
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
                    ToastHelper.showToast(CameraActivity.this, msg, Toast.LENGTH_SHORT);
                }
            });
        }


    };

    private void destroyRtcEngine() {
        if( mAliRtcEngine != null) {
            if(hasJoined) {
                mAliRtcEngine.leaveChannel();
                hasJoined = false;
                handler.post(() -> {
                    ToastHelper.showToast(this, getString(R.string.leave_channel_msg), Toast.LENGTH_SHORT);
                });
            }
            mAliRtcEngine.destroy();
            mAliRtcEngine = null;
        }
    }
}