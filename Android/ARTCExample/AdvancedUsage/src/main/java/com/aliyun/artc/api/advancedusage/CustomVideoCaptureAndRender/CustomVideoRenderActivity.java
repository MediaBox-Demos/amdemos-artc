package com.aliyun.artc.api.advancedusage.CustomVideoCaptureAndRender;

import static android.view.View.VISIBLE;
import static com.alivc.rtc.AliRtcEngine.AliRtcVideoEncoderOrientationMode.AliRtcVideoEncoderOrientationModeAdaptive;
import static com.alivc.rtc.AliRtcEngine.AliRtcVideoFormat.AliRtcVideoFormatI420;
import static com.alivc.rtc.AliRtcEngine.AliRtcVideoFormat.AliRtcVideoFormatTextureOES;
import static com.alivc.rtc.AliRtcEngine.AliRtcVideoTrack.AliRtcVideoTrackCamera;
import static com.alivc.rtc.AliRtcEngine.AliRtcVideoTrack.AliRtcVideoTrackNo;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Intent;
import android.opengl.GLSurfaceView;
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
import com.aliyun.artc.api.advancedusage.CustomVideoCaptureAndRender.utils.TextureRenderer;
import com.aliyun.artc.api.advancedusage.CustomVideoCaptureAndRender.utils.VideoRenderer;
import com.aliyun.artc.api.advancedusage.R;
import com.aliyun.artc.api.keycenter.ARTCTokenHelper;
import com.aliyun.artc.api.keycenter.GlobalConfig;
import com.aliyun.artc.api.keycenter.utils.ToastHelper;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import javax.microedition.khronos.opengles.GL;

public class CustomVideoRenderActivity extends AppCompatActivity {
    private static final String TAG = CustomVideoRenderActivity.class.getSimpleName();
    private Handler handler;
    private EditText mChannelEditText;
    private TextView mJoinChannelTextView;

    private boolean hasJoined = false;
    private FrameLayout fl_local, fl_remote;

    private AliRtcEngine mAliRtcEngine = null;
    private AliRtcEngine.AliRtcVideoCanvas mLocalVideoCanvas = null;

    private SwitchCompat mCustomVideoRenderSwitch;
    private boolean isCustomVideoRender = true;

    // 添加RadioGroup用于选择视频源类型
    private RadioGroup mVideoSourceRadioGroup;
    private static final int VIDEO_SOURCE_YUV = 0;
    private static final int VIDEO_SOURCE_TEXTURE = 1;
    private int mCurrentVideoSource = VIDEO_SOURCE_YUV;

    private final Map<String, ViewGroup> remoteViews = new ConcurrentHashMap<String, ViewGroup>();

    private static final int VIDEO_WIDTH = 720;
    private static final int VIDEO_HEIGHT = 1280;
    private final Map<String, VideoRenderer> remoteRenderers = new ConcurrentHashMap<>();
    // 本地渲染器
    private VideoRenderer localRenderer = null;
    // 本地纹理渲染器
    private TextureRenderer localTextureRenderer = null;
    // 本地纹理渲染视图
    private GLSurfaceView localGLSurfaceView = null;
    private SurfaceView mLocalSurfaceView = null;

    @SuppressLint("MissingInflatedId")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        handler = new Handler(Looper.getMainLooper());
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_custom_video_render);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.custom_video_render), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });
        setTitle(getString(R.string.custom_video_render));
        ActionBar actionBar = getSupportActionBar();
        if (actionBar != null) {
            actionBar.setDisplayHomeAsUpEnabled(true);
        }

        // 创建RTC Engine对象
        initAndSetupRtcEngine();

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
                    initAndSetupRtcEngine();
                }
                startRTCCall();
            }
        });

        mCustomVideoRenderSwitch = findViewById(R.id.custom_video_render_switch);
        mCustomVideoRenderSwitch.setOnCheckedChangeListener((buttonView, isChecked) -> {
            isCustomVideoRender = isChecked;
        });

        // 获取视频源选择RadioGroup
        mVideoSourceRadioGroup = findViewById(R.id.audioSourceRadioGroup);
        mVideoSourceRadioGroup.setOnCheckedChangeListener((group, checkedId) -> {
            if (checkedId == R.id.localMediaButton) {
                mCurrentVideoSource = VIDEO_SOURCE_YUV;
            } else if (checkedId == R.id.microphoneButton) {
                mCurrentVideoSource = VIDEO_SOURCE_TEXTURE;
            }
        });
    }

    public static void startActionActivity(Activity activity) {
        Intent intent = new Intent(activity, CustomVideoRenderActivity.class);
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
        initAndSetupRtcEngine();
        startPreview();
        joinChannel();
    }

    // 在onCreate中调用的引擎初始化方法
    private void initAndSetupRtcEngine() {
        //创建并初始化引擎
        if(mAliRtcEngine == null) {
            String extras = null;
            if(isCustomVideoRender) {
                // 根据选择的视频源类型设置不同的参数
                if (mCurrentVideoSource == VIDEO_SOURCE_YUV) {
                    // 如果只需要回调buffer格式数据
                    extras = "{\"user_specified_use_external_video_render\":\"TRUE\"}";
                } else if (mCurrentVideoSource == VIDEO_SOURCE_TEXTURE) {
                    // 如果需要回调纹理格式数据，需要开启纹理采集，建议同时开启纹理编码
                    extras = "{\"user_specified_use_external_video_render\":\"TRUE\",\"user_specified_camera_texture_capture\":\"TRUE\",\"user_specified_texture_encode\":\"TRUE\" }";
                }
            } else {
                extras = "{\"user_specified_use_external_video_render\":\"FALSE\"}";
            }
            mAliRtcEngine = AliRtcEngine.getInstance(this, extras);
        }
        mAliRtcEngine.setRtcEngineEventListener(mRtcEngineEventListener);
        mAliRtcEngine.setRtcEngineNotify(mRtcEngineNotify);

        // buffer格式数据回调
        mAliRtcEngine.registerVideoSampleObserver(mAliRtcVideoSampleObserver);
        // 纹理数据回调
        mAliRtcEngine.registerLocalVideoTextureObserver(mAliRtcTextureObserver);

        // 设置频道模式为互动模式,RTC下都使用AliRTCSdkInteractiveLive
        mAliRtcEngine.setChannelProfile(AliRtcEngine.AliRTCSdkChannelProfile.AliRTCSdkInteractiveLive);
        // 设置用户角色，既需要推流也需要拉流使用AliRTCSdkInteractive， 只拉流不推流使用AliRTCSdkLive
        mAliRtcEngine.setClientRole(AliRtcEngine.AliRTCSdkClientRole.AliRTCSdkInteractive);
        //设置音频Profile，默认使用高音质模式AliRtcEngineHighQualityMode及音乐模式AliRtcSceneMusicMode
        mAliRtcEngine.setAudioProfile(AliRtcEngine.AliRtcAudioProfile.AliRtcEngineHighQualityMode, AliRtcEngine.AliRtcAudioScenario.AliRtcSceneMusicMode);
        mAliRtcEngine.setCapturePipelineScaleMode(AliRtcEngine.AliRtcCapturePipelineScaleMode.AliRtcCapturePipelineScaleModePost);

        //设置视频编码参数
        AliRtcEngine.AliRtcVideoEncoderConfiguration aliRtcVideoEncoderConfiguration = new AliRtcEngine.AliRtcVideoEncoderConfiguration();
        aliRtcVideoEncoderConfiguration.dimensions = new AliRtcEngine.AliRtcVideoDimensions(VIDEO_WIDTH, VIDEO_HEIGHT);
        aliRtcVideoEncoderConfiguration.frameRate = 20;
        aliRtcVideoEncoderConfiguration.bitrate = 1200;
        aliRtcVideoEncoderConfiguration.keyFrameInterval = 2000;
        aliRtcVideoEncoderConfiguration.orientationMode = AliRtcVideoEncoderOrientationModeAdaptive;
        mAliRtcEngine.setVideoEncoderConfiguration(aliRtcVideoEncoderConfiguration);

        AliRtcEngine.AliRtcVideoDecoderConfiguration aliRtcVideoDecoderConfiguration = new AliRtcEngine.AliRtcVideoDecoderConfiguration();
        aliRtcVideoDecoderConfiguration.codecType = AliRtcEngine.AliRtcVideoCodecType.AliRtcVideoCodecTypeHardware;
        mAliRtcEngine.setVideoDecoderConfiguration(aliRtcVideoDecoderConfiguration);

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
            findViewById(R.id.ll_video_layout).setVisibility(VISIBLE);
            ViewGroup.LayoutParams layoutParams = new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);

            if (fl_local.getChildCount() > 0) {
                fl_local.removeAllViews();
            }

            // 根据选择的视频源类型决定使用哪种渲染方式
            if (isCustomVideoRender) {
                if (mCurrentVideoSource == VIDEO_SOURCE_YUV) {
                    // YUV格式使用自定义渲染器
                    localGLSurfaceView = new GLSurfaceView(this);
                    localGLSurfaceView.setEGLContextClientVersion(2);
                    localRenderer = new VideoRenderer();
                    localGLSurfaceView.setRenderer(localRenderer);
                    localGLSurfaceView.setRenderMode(GLSurfaceView.RENDERMODE_CONTINUOUSLY);
                    fl_local.addView(localGLSurfaceView, layoutParams);
                } else if (mCurrentVideoSource == VIDEO_SOURCE_TEXTURE) {
                    // 纹理格式使用SDK默认渲染
                    localGLSurfaceView = new GLSurfaceView(this);
                    localGLSurfaceView.setEGLContextClientVersion(2);
                    localTextureRenderer = new TextureRenderer();
                    localGLSurfaceView.setRenderer(localTextureRenderer);
                    localGLSurfaceView.setRenderMode(GLSurfaceView.RENDERMODE_CONTINUOUSLY);
                    fl_local.addView(localGLSurfaceView, layoutParams);

                }
            } else {
                // 非自定义渲染使用SDK默认渲染
                mLocalVideoCanvas = new AliRtcEngine.AliRtcVideoCanvas();
                SurfaceView localSurfaceView = mAliRtcEngine.createRenderSurfaceView(CustomVideoRenderActivity.this);
                localSurfaceView.setZOrderOnTop(true);
                localSurfaceView.setZOrderMediaOverlay(true);
                fl_local.addView(localSurfaceView, layoutParams);
                mLocalVideoCanvas.view = localSurfaceView;
                mAliRtcEngine.setLocalViewConfig(mLocalVideoCanvas, AliRtcVideoTrackCamera);
            }

            mAliRtcEngine.startPreview();
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
        public void onAudioPublishStateChanged(AliRtcEngine.AliRtcPublishState oldState , AliRtcEngine.AliRtcPublishState newState, int elapseSinceLastState, String channel){
            super.onAudioPublishStateChanged(oldState, newState, elapseSinceLastState, channel);
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
                    ToastHelper.showToast(CustomVideoRenderActivity.this, str, Toast.LENGTH_SHORT);
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
                        FrameLayout view = getAvailableView();
                        if (view == null) {
                            return;
                        }
                        // 创建VideoRender实现自定义渲染
                        view.removeAllViews();
                        GLSurfaceView glSurfaceView = new GLSurfaceView(CustomVideoRenderActivity.this);
                        glSurfaceView.setEGLContextClientVersion(2);
                        VideoRenderer renderer = new VideoRenderer();
                        glSurfaceView.setRenderer(renderer);
                        glSurfaceView.setRenderMode(GLSurfaceView.RENDERMODE_CONTINUOUSLY);
                        remoteRenderers.put(uid, renderer);
                        remoteViews.put(uid, view);
                        view.addView(glSurfaceView, new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));

                        // SDK内部渲染逻辑
//                        SurfaceView surfaceView = mAliRtcEngine.createRenderSurfaceView(CustomVideoRenderActivity.this);
//                        surfaceView.setZOrderMediaOverlay(true);
//                        view.addView(surfaceView, new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
//                        AliRtcEngine.AliRtcVideoCanvas remoteVideoCanvas = new AliRtcEngine.AliRtcVideoCanvas();
//                        remoteVideoCanvas.view = surfaceView;
//                        mAliRtcEngine.setRemoteViewConfig(remoteVideoCanvas, uid, AliRtcVideoTrackCamera);
                    } else if(videoTrack == AliRtcVideoTrackNo) {
                        if(remoteViews.containsKey(uid)) {
                            ViewGroup view = remoteViews.get(uid);
                            if(view != null) {
                                view.removeAllViews();
                                remoteViews.remove(uid);
                            }
                            VideoRenderer renderer = remoteRenderers.get(uid);
                            if (renderer != null) {
                                remoteRenderers.remove(uid);
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
                    ToastHelper.showToast(CustomVideoRenderActivity.this, msg, Toast.LENGTH_SHORT);
                }
            });
        }
    };

    // buffer格式数据回调
    private final AliRtcEngine.AliRtcVideoObserver mAliRtcVideoSampleObserver = new AliRtcEngine.AliRtcVideoObserver() {
        @Override
        public AliRtcEngine.AliRtcVideoFormat onGetVideoFormatPreference() {
            // 期望数据输出格式
            return AliRtcVideoFormatI420;
        }

        @Override
        public boolean onLocalVideoSample(AliRtcEngine.AliRtcVideoSourceType sourceType, AliRtcEngine.AliRtcVideoSample videoSample){
            Log.i(TAG, "onLocalVideoSample");
            // 处理本地采集的视频数据(YUV格式)
            if(videoSample.format == AliRtcVideoFormatI420) {
                if (isCustomVideoRender && mCurrentVideoSource == VIDEO_SOURCE_YUV && localRenderer != null) {
                    localRenderer.drawYUV(videoSample);
                }
            }
            return true;
        }

        @Override
        public boolean onRemoteVideoSample(String callId, AliRtcEngine.AliRtcVideoSourceType sourceType, AliRtcEngine.AliRtcVideoSample videoSample){
            if(videoSample.format == AliRtcVideoFormatI420) {
                // 处理远端视频数据
                VideoRenderer remoteRenderer = remoteRenderers.get(callId);
                if (remoteRenderer == null) {
                    remoteRenderer = new VideoRenderer();
                    remoteRenderers.put(callId, remoteRenderer);
                }

                remoteRenderer.drawYUV(videoSample);
            } else {
                // TODO 其他格式数据处理
            }
            return false;
        }
    };

    // 纹理数据回调
    private final AliRtcEngine.AliRtcTextureObserver mAliRtcTextureObserver = new AliRtcEngine.AliRtcTextureObserver() {

        private long context_ = 0 ;
        private int  log_ref = 0 ;
        @Override
        public void onTextureCreate(long context) {
            context_ = context ;
            Log.d(TAG, "texture context: "+context_+" create!") ;
        }

        @Override
        public int onTextureUpdate(int textureId, int width, int height, AliRtcEngine.AliRtcVideoSample videoSample) {
            if ( log_ref % 30 == 0 ) {
                Log.d(TAG, "texture update w: "+width +" h: "+height+" text_id: "+textureId+" rotate:"+videoSample.rotate ) ;
            }

            if (isCustomVideoRender && mCurrentVideoSource == VIDEO_SOURCE_TEXTURE && localTextureRenderer != null) {
                Log.d(TAG, "Updating 2D texture with ID: " + textureId + ", size: " + width + "x" + height + ", context: " + context_ + ", format: " + videoSample.format);
                localTextureRenderer.updateTexture(textureId, width, height);
                if(localGLSurfaceView != null) {
                    localGLSurfaceView.requestRender();
                }
            }

            ++log_ref ;
            return textureId;
        }
        @Override
        public void onTextureDestroy() {

            Log.d(TAG, "texture context: "+context_+" destory!") ;
        }
    };

    private void destroyRtcEngine() {
        if( mAliRtcEngine != null) {
            // 取消视频数据回调
            mAliRtcEngine.unRegisterVideoSampleObserver();
            mAliRtcEngine.unRegisterLocalVideoTextureObserver();

            mAliRtcEngine.stopPreview();

            mAliRtcEngine.leaveChannel();
            mAliRtcEngine.destroy();
            mAliRtcEngine = null;

            handler.post(() -> {
                ToastHelper.showToast(this, "Leave Channel", Toast.LENGTH_SHORT);
            });
        }

        // 清理远端渲染器
        remoteRenderers.clear();

        hasJoined = false;
        for (ViewGroup value : remoteViews.values()) {
            value.removeAllViews();
        }
        remoteViews.clear();
        findViewById(R.id.ll_video_layout).setVisibility(View.GONE);
        fl_local.removeAllViews();
        mLocalVideoCanvas = null;
        localRenderer = null;
        localTextureRenderer = null;
        localGLSurfaceView = null;
    }
}