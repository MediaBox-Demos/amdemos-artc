package com.aliyun.artc.api.advancedusage.CustomVideoProcess;

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
 * Custom Video Process Demo
 * Main features: Get raw video data (from local camera capture) and integrate beauty filter library for processing
 * Includes two implementation methods:
 * 1. Buffer data processing: Get via onLocalVideoSample callback
 * 2. Texture data processing: Get via onTextureUpdate callback
 */
public class CustomVideoProcessActivity extends AppCompatActivity {
    private static final String TAG = CustomVideoProcessActivity.class.getSimpleName();
    private Handler handler;
    private EditText mChannelEditText;
    private TextView mJoinChannelTextView;
    private SwitchCompat mEnableBufferProcessSwitch;
    private SwitchCompat mEnableTextureProcessSwitch;
    private SwitchCompat mEnableBeautySwitch;

    // Display callback info TextView
    private TextView mBufferInfoTv;
    private TextView mTextureInfoTv;

    private boolean hasJoined = false;
    private FrameLayout fl_local, fl_remote, fl_remote_2, fl_remote_3;

    private AliRtcEngine mAliRtcEngine = null;
    private AliRtcEngine.AliRtcVideoCanvas mLocalVideoCanvas = null;
    private Map<String, ViewGroup> remoteViews = new ConcurrentHashMap<String, ViewGroup>();

    // Whether to enable beauty processing
    private boolean isBeautyEnabled = false;
    
    // Queen beauty wrapper class
    private QueenBeautyImp mQueenBeautyImp;
    
    // Whether to write back to SDK
    private boolean isWriteBackToSDK = true;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        handler = new Handler(Looper.getMainLooper());
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_custom_video_process);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.custom_video_process), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });
        setTitle(getString(R.string.custom_video_process));
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);

        initViews();
        initListeners();
    }

    private void initViews() {
        fl_local = findViewById(R.id.fl_local);
        fl_remote = findViewById(R.id.fl_remote);
        fl_remote_2 = findViewById(R.id.fl_remote2);
        fl_remote_3 = findViewById(R.id.fl_remote3);

        mBufferInfoTv = findViewById(R.id.tv_buffer_info);
        mTextureInfoTv = findViewById(R.id.tv_texture_info);

        mChannelEditText = findViewById(R.id.channel_id_input);
        mChannelEditText.setText(GlobalConfig.getInstance().gerRandomChannelId());
        
        mJoinChannelTextView = findViewById(R.id.join_room_btn);
        mEnableBufferProcessSwitch = findViewById(R.id.enable_buffer_process_switch);
        mEnableTextureProcessSwitch = findViewById(R.id.enable_texture_process_switch);
        mEnableBeautySwitch = findViewById(R.id.enable_beauty_switch);

        // Default enable buffer processing
        mEnableBufferProcessSwitch.setChecked(true);
        // Default enable texture processing
        mEnableTextureProcessSwitch.setChecked(true);
    }

    private void initListeners() {
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

        // Buffer data processing switch
        mEnableBufferProcessSwitch.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (mAliRtcEngine == null) {
                initAndSetupRtcEngine();
            }
            if (isChecked) {
                // Register raw video data callback
                mAliRtcEngine.registerVideoSampleObserver(mRtcVideoSampleObserver);
                Log.d(TAG, "Register Buffer data callback");
            } else {
                mAliRtcEngine.unRegisterVideoSampleObserver();
                Log.d(TAG, "Unregister Buffer data callback");
                updateVideoInfo(mBufferInfoTv, "Buffer callback: Disabled");
            }
        });

        // Texture data processing switch
        mEnableTextureProcessSwitch.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (mAliRtcEngine == null) {
                initAndSetupRtcEngine();
            }
            if (isChecked) {
                // Register texture data callback
                mAliRtcEngine.registerLocalVideoTextureObserver(mRtcTextureObserver);
                Log.d(TAG, "Register texture data callback");
            } else {
                mAliRtcEngine.unRegisterLocalVideoTextureObserver();
                Log.d(TAG, "Unregister texture data callback");
                updateVideoInfo(mTextureInfoTv, "Texture callback: Disabled");
            }
        });

        // Beauty switch
        mEnableBeautySwitch.setOnCheckedChangeListener((buttonView, isChecked) -> {
            isBeautyEnabled = isChecked;
            String status = isChecked ? "Enabled" : "Disabled";
            ToastHelper.showToast(this, "Beauty processing " + status, Toast.LENGTH_SHORT);
            Log.d(TAG, "Beauty processing: " + status);
        });
    }

    public static void startActionActivity(Activity activity) {
        Intent intent = new Intent(activity, CustomVideoProcessActivity.class);
        activity.startActivity(intent);
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        if (item.getItemId() == android.R.id.home) {
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
            String str = null;
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
     * Update video info TextView on main thread
     */
    private void updateVideoInfo(TextView textView, String message) {
        if (textView == null) {
            return;
        }
        handler.post(() -> textView.setText(message));
    }

    /**
     * Unified beauty processing entry:
     * - Judge texture mode or buffer mode based on videoSample.glContex / textureid
     * - Complete specific processing internally by QueenBeautyImp
     *
     * @return true means processed and needs to write back to SDK
     */
    private boolean handleBeautyProcess(AliRtcEngine.AliRtcVideoSample videoSample) {
        if (!isBeautyEnabled) {
            // Beauty not enabled: no processing, keep original data
            return false;
        }
        if (videoSample == null) {
            return false;
        }
        // According to the document: use glContex as shared context; buffer mode glContex is 0 is also fine
        if (mQueenBeautyImp == null) {
            mQueenBeautyImp = new QueenBeautyImp(this, videoSample.glContex);
        }
        return mQueenBeautyImp.onBeautyProcess(videoSample);
    }

    private void startRTCCall() {
        if(hasJoined) {
            return;
        }
        startPreview();
        joinChannel();
    }

    /**
     * Create and initialize AliRtcEngine
     * [Core API] Custom video processing main flow:
     *   1. registerVideoSampleObserver(observer) - Register buffer data observer
     *   2. registerLocalVideoTextureObserver(observer) - Register texture data observer
     *   3. Get video data in callback and process (such as beauty filter)
     *   4. Return processed data to SDK
     */
    private void initAndSetupRtcEngine() {
        if(mAliRtcEngine == null) {
            // Create engine, enable texture capture and encoding
            String extras = "{\"user_specified_camera_texture_capture\":\"TRUE\",\"user_specified_texture_encode\":\"TRUE\"}";
            mAliRtcEngine = AliRtcEngine.getInstance(this, extras);
        }

        mAliRtcEngine.setRtcEngineEventListener(mRtcEngineEventListener);
        mAliRtcEngine.setRtcEngineNotify(mRtcEngineNotify);

        // Set channel profile to interactive live
        mAliRtcEngine.setChannelProfile(AliRtcEngine.AliRTCSdkChannelProfile.AliRTCSdkInteractiveLive);
        // Set client role to interactive
        mAliRtcEngine.setClientRole(AliRtcEngine.AliRTCSdkClientRole.AliRTCSdkInteractive);
        // Set audio profile
        mAliRtcEngine.setAudioProfile(AliRtcEngine.AliRtcAudioProfile.AliRtcEngineHighQualityMode, 
                                     AliRtcEngine.AliRtcAudioScenario.AliRtcSceneMusicMode);
        mAliRtcEngine.setCapturePipelineScaleMode(AliRtcEngine.AliRtcCapturePipelineScaleMode.AliRtcCapturePipelineScaleModePost);

        // Set video encoder configuration - use hardware texture encoding to support texture callback
        AliRtcEngine.AliRtcVideoEncoderConfiguration aliRtcVideoEncoderConfiguration = 
            new AliRtcEngine.AliRtcVideoEncoderConfiguration();
        aliRtcVideoEncoderConfiguration.dimensions = new AliRtcEngine.AliRtcVideoDimensions(720, 1280);
        aliRtcVideoEncoderConfiguration.frameRate = 20;
        aliRtcVideoEncoderConfiguration.bitrate = 1200;
        aliRtcVideoEncoderConfiguration.keyFrameInterval = 2000;
        aliRtcVideoEncoderConfiguration.orientationMode = AliRtcVideoEncoderOrientationModeAdaptive;
        aliRtcVideoEncoderConfiguration.codecType = 
            AliRtcEngine.AliRtcVideoCodecType.AliRtcVideoCodecTypeHardwareTexture;
        mAliRtcEngine.setVideoEncoderConfiguration(aliRtcVideoEncoderConfiguration);

        // SDK will publish audio and video by default
        mAliRtcEngine.publishLocalAudioStream(true);
        mAliRtcEngine.publishLocalVideoStream(true);

        // Set default subscribe all remote audio and video streams
        mAliRtcEngine.setDefaultSubscribeAllRemoteAudioStreams(true);
        mAliRtcEngine.subscribeAllRemoteAudioStreams(true);
        mAliRtcEngine.setDefaultSubscribeAllRemoteVideoStreams(true);
        mAliRtcEngine.subscribeAllRemoteVideoStreams(true);

        // Register callback according to switch status
        if (mEnableBufferProcessSwitch.isChecked()) {
            mAliRtcEngine.registerVideoSampleObserver(mRtcVideoSampleObserver);
        }
        if (mEnableTextureProcessSwitch.isChecked()) {
            mAliRtcEngine.registerLocalVideoTextureObserver(mRtcTextureObserver);
        }
    }

    private void startPreview(){
        if (mAliRtcEngine != null) {
            if (fl_local.getChildCount() > 0) {
                fl_local.removeAllViews();
            }

            findViewById(R.id.ll_video_layout).setVisibility(VISIBLE);
            ViewGroup.LayoutParams layoutParams = new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
            
            if(mLocalVideoCanvas == null) {
                mLocalVideoCanvas = new AliRtcEngine.AliRtcVideoCanvas();
                SurfaceView localSurfaceView = mAliRtcEngine.createRenderSurfaceView(CustomVideoProcessActivity.this);
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
            Log.e(TAG, "channelId is empty");
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
        public void onConnectionStatusChange(AliRtcEngine.AliRtcConnectionStatus status, 
                                            AliRtcEngine.AliRtcConnectionStatusChangeReason reason){
            super.onConnectionStatusChange(status, reason);
            handler.post(new Runnable() {
                @Override
                public void run() {
                    if(status == AliRtcEngine.AliRtcConnectionStatus.AliRtcConnectionStatusFailed) {
                        ToastHelper.showToast(CustomVideoProcessActivity.this, 
                            R.string.video_chat_connection_failed, Toast.LENGTH_SHORT);
                    }
                }
            });
        }

        @Override
        public void OnLocalDeviceException(AliRtcEngine.AliRtcEngineLocalDeviceType deviceType, 
                                          AliRtcEngine.AliRtcEngineLocalDeviceExceptionType exceptionType, 
                                          String msg){
            super.OnLocalDeviceException(deviceType, exceptionType, msg);
            handler.post(new Runnable() {
                @Override
                public void run() {
                    String str = "OnLocalDeviceException deviceType: " + deviceType + 
                               " exceptionType: " + exceptionType + " msg: " + msg;
                    ToastHelper.showToast(CustomVideoProcessActivity.this, str, Toast.LENGTH_SHORT);
                }
            });
        }
    };

    private AliRtcEngineNotify mRtcEngineNotify = new AliRtcEngineNotify() {
        @Override
        public void onAuthInfoWillExpire() {
            super.onAuthInfoWillExpire();
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
        public void onRemoteTrackAvailableNotify(String uid, AliRtcEngine.AliRtcAudioTrack audioTrack, 
                                                 AliRtcEngine.AliRtcVideoTrack videoTrack){
            handler.post(new Runnable() {
                @Override
                public void run() {
                    if(videoTrack == AliRtcVideoTrackCamera) {
                        SurfaceView surfaceView = mAliRtcEngine.createRenderSurfaceView(CustomVideoProcessActivity.this);
                        surfaceView.setZOrderMediaOverlay(true);
                        FrameLayout view = getAvailableView();
                        if (view == null) {
                            return;
                        }
                        remoteViews.put(uid, view);
                        view.addView(surfaceView, new FrameLayout.LayoutParams(
                            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
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

        @Override
        public void onBye(int code){
            handler.post(new Runnable() {
                @Override
                public void run() {
                    String msg = "onBye code:" + code;
                    ToastHelper.showToast(CustomVideoProcessActivity.this, msg, Toast.LENGTH_SHORT);
                }
            });
        }
    };

    /**
     * [Key Callback 1] Texture data observer
     * Used to get OpenGL texture ID, can perform texture-level beauty processing here
     */
    private final AliRtcEngine.AliRtcTextureObserver mRtcTextureObserver = new AliRtcEngine.AliRtcTextureObserver() {
        @Override
        public void onTextureCreate(long context) {
            Log.d(TAG, "onTextureCreate - Texture created");
            updateVideoInfo(mTextureInfoTv, "Texture: Created");
        }

        @Override
        public int onTextureUpdate(int textureId, int width, int height, AliRtcEngine.AliRtcVideoSample videoSample) {
            int outputTextureId = textureId;

            boolean processed = false;
            if (isBeautyEnabled) {
                // Call unified beauty entry, QueenBeautyImp internally distinguishes texture / buffer
                processed = handleBeautyProcess(videoSample);
                if (processed && videoSample != null && videoSample.textureid > 0) {
                    // Queen may return a new texture ID (and modify format)
                    outputTextureId = (int) videoSample.textureid;
                }
            }

            String message = String.format("Texture: %dx%d, ID=%d, Beauty=%s, Processed=%s",
                    width, height, outputTextureId,
                    isBeautyEnabled ? "ON" : "OFF",
                    processed ? "YES" : "NO");
            Log.d(TAG, message);
            updateVideoInfo(mTextureInfoTv, message);

            // Return processed texture ID
            return outputTextureId;
        }

        @Override
        public void onTextureDestroy() {
            Log.d(TAG, "onTextureDestroy - Texture destroyed");
            updateVideoInfo(mTextureInfoTv, "Texture: Destroyed");
        }
    };

    /**
     * [Key Callback 2] Video Buffer data observer
     * Used to get YUV/RGB format video data, can perform buffer-level beauty processing here
     */
    private AliRtcEngine.AliRtcVideoObserver mRtcVideoSampleObserver = new AliRtcEngine.AliRtcVideoObserver() {

        @Override
        public boolean onLocalVideoSample(AliRtcEngine.AliRtcVideoSourceType sourceType,
                                         AliRtcEngine.AliRtcVideoSample videoSample){

            String message = String.format("Buffer: %dx%d, Format=%s, Source=%s, Beauty=%s",
                    videoSample.width, videoSample.height,
                    videoSample.format, sourceType,
                    isBeautyEnabled ? "ON" : "OFF");
            Log.d(TAG, message);
            updateVideoInfo(mBufferInfoTv, message);

            // Call unified beauty entry; internally determine texture or buffer based on glContex / textureid
            boolean processed = handleBeautyProcess(videoSample);

            // If beauty processing succeeds, must return true to write back to SDK;
            // If not processed, keep original logic determined by isWriteBackToSDK
            return processed || isWriteBackToSDK;
        }

        @Override
        public AliRtcEngine.AliRtcVideoFormat onGetVideoFormatPreference() {
            // Return preferred video format (I420 is commonly used format)
            return AliRtcEngine.AliRtcVideoFormat.AliRtcVideoFormatI420;
        }

        @Override
        public int onGetObservedFramePosition(){
            // Only focus on data after local capture (for beauty processing)
            return AliRtcEngine.AliRtcVideoObserPosition.AliRtcPositionPostCapture.getValue();
        }
    };

    private void destroyRtcEngine() {
        if(mAliRtcEngine != null) {
            mAliRtcEngine.stopPreview();
            mAliRtcEngine.setLocalViewConfig(null, AliRtcVideoTrackCamera);
            mAliRtcEngine.leaveChannel();
            mAliRtcEngine.unRegisterVideoSampleObserver();
            mAliRtcEngine.unRegisterLocalVideoTextureObserver();
            mAliRtcEngine.destroy();
            mAliRtcEngine = null;
        }

        // Release Queen beauty engine
        if (mQueenBeautyImp != null) {
            mQueenBeautyImp.release();
            mQueenBeautyImp = null;
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
