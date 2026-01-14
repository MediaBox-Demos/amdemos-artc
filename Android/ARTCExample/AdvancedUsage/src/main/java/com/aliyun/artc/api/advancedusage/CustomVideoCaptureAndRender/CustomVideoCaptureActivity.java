package com.aliyun.artc.api.advancedusage.CustomVideoCaptureAndRender;

import static android.view.View.VISIBLE;
import static com.alivc.rtc.AliRtcEngine.AliRtcRenderMode.AliRtcRenderModeAuto;
import static com.alivc.rtc.AliRtcEngine.AliRtcVideoEncoderOrientationMode.AliRtcVideoEncoderOrientationModeAdaptive;
import static com.alivc.rtc.AliRtcEngine.AliRtcVideoTrack.AliRtcVideoTrackCamera;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.SurfaceTexture;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCaptureSession;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraDevice;
import android.hardware.camera2.CameraManager;
import android.hardware.camera2.CaptureRequest;
import android.media.Image;
import android.media.ImageReader;
import android.opengl.EGL14;
import android.opengl.EGLConfig;
import android.opengl.EGLContext;
import android.opengl.EGLDisplay;
import android.opengl.EGLSurface;
import android.opengl.GLES11Ext;
import android.opengl.GLES20;
import android.opengl.Matrix;
import android.os.Bundle;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.Looper;
import android.os.Process;
import android.text.TextUtils;
import android.util.Log;
import android.view.MenuItem;
import android.view.Surface;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.*;

import androidx.activity.EdgeToEdge;
import androidx.annotation.NonNull;
import androidx.appcompat.app.ActionBar;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.SwitchCompat;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
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

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;
import java.util.Arrays;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class CustomVideoCaptureActivity extends AppCompatActivity {

    private static final int REQUEST_CAMERA_PERMISSION = 1001;

    private Handler mainHandler;
    private EditText mChannelEditText;
    private TextView mJoinChannelTextView;

    private boolean hasJoined = false;
    private FrameLayout fl_local, fl_remote;

    private AliRtcEngine mAliRtcEngine = null;
    private AliRtcEngine.AliRtcVideoCanvas mLocalVideoCanvas = null;

    private SwitchCompat mCustomVideoCaptureSwitch;
    private boolean isCustomVideoCapture = true;

    // 数据源选择：相机 / 文件
    private RadioGroup mVideoSourceTypeGroup;
    private RadioButton mCameraSourceRadio;
    private RadioButton mFileSourceRadio;
    private static final int SOURCE_CAMERA = 0;
    private static final int SOURCE_FILE = 1;
    private int mCurrentSourceType = SOURCE_CAMERA;

    // 输入格式选择：YUV / 纹理
    private RadioGroup mVideoInputTypeGroup;
    private RadioButton mYuvInputRadio;
    private RadioButton mTextureInputRadio;
    private static final int INPUT_TYPE_YUV = 0;
    private static final int INPUT_TYPE_TEXTURE = 1;
    private int mCurrentInputType = INPUT_TYPE_YUV;

    private final Map<String, ViewGroup> remoteViews = new ConcurrentHashMap<>();

    // 自定义视频采集配置
    private static final int VIDEO_WIDTH = 720;
    private static final int VIDEO_HEIGHT = 1280;
    private static final int VIDEO_FPS = 20;
    private volatile boolean isPushingVideoData = false;

    // 相机相关
    private CameraDevice mCameraDevice;
    private CameraCaptureSession mCaptureSession;
    private ImageReader mImageReader;
    private Handler mBackgroundHandler;
    private HandlerThread mBackgroundThread;

    // 新增：GL 独立线程（负责纹理创建、updateTexImage、推流）
    private HandlerThread mGlThread;
    private Handler mGlHandler;
    private EGLDisplay mEGLDisplay = EGL14.EGL_NO_DISPLAY;
    private EGLContext mEGLContext = EGL14.EGL_NO_CONTEXT;
    private EGLSurface mEGLSurface = EGL14.EGL_NO_SURFACE;
    private int mOESTextureId = -1;
    private SurfaceTexture mSurfaceTexture;
    private Surface mPreviewSurface;
    private String mCameraId;

    private EGLConfig mEGLConfig;

    // 相机 OES → Texture2D 转换相关
    private int mCameraShaderProgram = -1;
    private int mCameraAPositionHandle;
    private int mCameraATexCoordHandle;
    private int mCameraUTexMatrixHandle;
    private int mCameraUTextureHandle;
    private int mCameraFboId = -1;
    private int mCameraTexture2DId = -1;

    // 全屏四边形顶点坐标
    private static final float[] CAMERA_VERTEX_COORDS = {
            -1.0f, -1.0f,
             1.0f, -1.0f,
            -1.0f,  1.0f,
             1.0f,  1.0f,
    };

    // 纹理坐标
    private static final float[] CAMERA_TEXTURE_COORDS = {
            0.0f, 0.0f,
            1.0f, 0.0f,
            0.0f, 1.0f,
            1.0f, 1.0f,
    };

    // OES 顶点着色器
    private static final String CAMERA_VERTEX_SHADER =
            "attribute vec4 aPosition;\n" +
            "attribute vec4 aTexCoord;\n" +
            "uniform mat4 uTexMatrix;\n" +
            "varying vec2 vTexCoord;\n" +
            "void main() {\n" +
            "    gl_Position = aPosition;\n" +
            "    vTexCoord = (uTexMatrix * aTexCoord).xy;\n" +
            "}\n";

    // OES 片段着色器
    private static final String CAMERA_FRAGMENT_SHADER =
            "#extension GL_OES_EGL_image_external : require\n" +
            "precision mediump float;\n" +
            "varying vec2 vTexCoord;\n" +
            "uniform samplerExternalOES uTexture;\n" +
            "void main() {\n" +
            "    gl_FragColor = texture2D(uTexture, vTexCoord);\n" +
            "}\n";

    // Mp4 播放器（YUV 和 Texture2D 两种模式）
    private Mp4TexturePlayer mp4YuvPlayer;           // YUV 模式
    private Mp4Texture2DPlayer mp4Texture2DPlayer;   // Texture2D 模式

    @SuppressLint("MissingInflatedId")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        mainHandler = new Handler(Looper.getMainLooper());
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_custom_video_capture);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.custom_video_capture), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });
        setTitle(getString(R.string.custom_video_capture));
        ActionBar actionBar = getSupportActionBar();
        if (actionBar != null) {
            actionBar.setDisplayHomeAsUpEnabled(true);
        }

        fl_local = findViewById(R.id.fl_local);
        fl_remote = findViewById(R.id.fl_remote);

        mChannelEditText = findViewById(R.id.channel_id_input);
        mChannelEditText.setText(GlobalConfig.getInstance().gerRandomChannelId());
        mJoinChannelTextView = findViewById(R.id.join_room_btn);
        mJoinChannelTextView.setOnClickListener(v -> {
            if (hasJoined) {
                destroyRtcEngine();
                mJoinChannelTextView.setText(R.string.video_chat_join_channel);
            } else {
                if (mAliRtcEngine == null) {
                    initRtcEngine();
                }
                startRTCCall();
            }
        });

        mCustomVideoCaptureSwitch = findViewById(R.id.custom_video_capture_switch);
        mCustomVideoCaptureSwitch.setOnCheckedChangeListener((buttonView, isChecked) -> {
            isCustomVideoCapture = isChecked;
        });

        initVideoSourceControl();    // 数据源选择：相机/文件
        initVideoInputTypeControl(); // 输入格式：YUV/纹理

        // 请求相机权限
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.CAMERA}, REQUEST_CAMERA_PERMISSION);
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == REQUEST_CAMERA_PERMISSION) {
            if (grantResults.length == 0 || grantResults[0] != PackageManager.PERMISSION_GRANTED) {
                Toast.makeText(this, "需要相机权限才能使用自定义采集", Toast.LENGTH_LONG).show();
            }
        }
    }

    public static void startActionActivity(Activity activity) {
        Intent intent = new Intent(activity, CustomVideoCaptureActivity.class);
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

    /**
     * 初始化数据源选择控件（相机 / 文件）
     */
    private void initVideoSourceControl() {
        mVideoSourceTypeGroup = findViewById(R.id.video_source_type_group);
        mCameraSourceRadio = findViewById(R.id.camera_source_radio_button);
        mFileSourceRadio = findViewById(R.id.file_source_radio_button);

        mVideoSourceTypeGroup.setOnCheckedChangeListener((group, checkedId) -> {
            if (checkedId == R.id.camera_source_radio_button) {
                mCurrentSourceType = SOURCE_CAMERA;
                Log.d("CustomVideoCapture", "Source switched to: CAMERA");
            } else if (checkedId == R.id.file_source_radio_button) {
                mCurrentSourceType = SOURCE_FILE;
                Log.d("CustomVideoCapture", "Source switched to: FILE(mp4)");
            }
        });
    }

    /**
     * 初始化输入格式选择控件（YUV / 纹理）
     */
    private void initVideoInputTypeControl() {
        mVideoInputTypeGroup = findViewById(R.id.video_input_type_group);
        mYuvInputRadio = findViewById(R.id.yuv_input_radio_button);
        mTextureInputRadio = findViewById(R.id.texture_input_radio_button);

        mVideoInputTypeGroup.setOnCheckedChangeListener((group, checkedId) -> {
            if (checkedId == R.id.yuv_input_radio_button) {
                mCurrentInputType = INPUT_TYPE_YUV;
                Log.d("CustomVideoCapture", "Input type switched to: YUV");
            } else if (checkedId == R.id.texture_input_radio_button) {
                mCurrentInputType = INPUT_TYPE_TEXTURE;
                Log.d("CustomVideoCapture", "Input type switched to: TEXTURE");
            }
        });
    }

    private void initRtcEngine() {
        if (mAliRtcEngine == null) {
            mAliRtcEngine = AliRtcEngine.getInstance(this);
        }
        mAliRtcEngine.setRtcEngineEventListener(mRtcEngineEventListener);
        mAliRtcEngine.setRtcEngineNotify(mRtcEngineNotify);
        // 外部视频采集相关配置放在真正开始通话前（startRTCCall），
        // 以便根据当前的 YUV/Texture 选择进行准确设置。
    }

    private void setupExternalVideoSourceIfNeeded() {
        if (mAliRtcEngine == null) {
            return;
        }

        if (!isCustomVideoCapture) {
            mAliRtcEngine.setExternalVideoSource(false,
                    false,
                    AliRtcVideoTrackCamera,
                    AliRtcRenderModeAuto);
            Log.d("CustomVideoCapture", "setExternalVideoSource disabled");
            mAliRtcEngine.enableLocalVideo(true);
            return;
        }

        mAliRtcEngine.enableLocalVideo(false);

        boolean useTexture = (mCurrentInputType == INPUT_TYPE_TEXTURE);

        // 【外部视频采集关键 API 1】声明使用外部视频源：
        // 参数说明：
        //  - enable           : true 表示开启外部视频源模式，由应用侧负责采集并推送视频
        //  - useTexture       : true=纹理输入(Texture2D)，false=YUV/I420数据
        //  - videoTrack       : 选择替换的轨道，这里替换相机流 AliRtcVideoTrackCamera
        //  - renderMode       : 本地预览渲染模式，这里使用 AliRtcRenderModeAuto
        mAliRtcEngine.setExternalVideoSource(true,
                useTexture,
                AliRtcVideoTrackCamera,
                AliRtcRenderModeAuto);
        Log.d("CustomVideoCapture", "setExternalVideoSource enable=true, useTexture=" + useTexture);
    }

    private void setupRtcEngineForCall() {
        mAliRtcEngine.setChannelProfile(AliRtcEngine.AliRTCSdkChannelProfile.AliRTCSdkInteractiveLive);
        mAliRtcEngine.setClientRole(AliRtcEngine.AliRTCSdkClientRole.AliRTCSdkInteractive);
        mAliRtcEngine.setAudioProfile(AliRtcEngine.AliRtcAudioProfile.AliRtcEngineHighQualityMode, AliRtcEngine.AliRtcAudioScenario.AliRtcSceneMusicMode);
        mAliRtcEngine.setCapturePipelineScaleMode(AliRtcEngine.AliRtcCapturePipelineScaleMode.AliRtcCapturePipelineScaleModePost);

        AliRtcEngine.AliRtcVideoEncoderConfiguration config = new AliRtcEngine.AliRtcVideoEncoderConfiguration();
        config.dimensions = new AliRtcEngine.AliRtcVideoDimensions(VIDEO_WIDTH, VIDEO_HEIGHT);
        config.frameRate = VIDEO_FPS;
        config.bitrate = 1200;
        config.keyFrameInterval = 2000;
        config.orientationMode = AliRtcVideoEncoderOrientationModeAdaptive;
        mAliRtcEngine.setVideoEncoderConfiguration(config);

        mAliRtcEngine.publishLocalAudioStream(true);
        mAliRtcEngine.publishLocalVideoStream(true);
        mAliRtcEngine.setDefaultSubscribeAllRemoteAudioStreams(true);
        mAliRtcEngine.subscribeAllRemoteAudioStreams(true);
        mAliRtcEngine.setDefaultSubscribeAllRemoteVideoStreams(true);
        mAliRtcEngine.subscribeAllRemoteVideoStreams(true);
    }

    private void startRTCCall() {
        if (hasJoined) return;

        setupRtcEngineForCall();

        // 根据当前是否开启自定义采集以及 YUV/纹理选择，配置外部视频源。
        setupExternalVideoSourceIfNeeded();

        // 此时 SDK 已处于外部采集模式，startPreview 会绑定本地渲染视图。
        startPreview();

        // 启动自定义采集（Camera + ImageReader / SurfaceTexture）
        startCustomCapture();

        // 加入频道
        joinChannel();
    }

    private void startPreview() {
        if (mAliRtcEngine != null) {
            if (fl_local.getChildCount() > 0) {
                fl_local.removeAllViews();
            }

            findViewById(R.id.ll_video_layout).setVisibility(VISIBLE);
            ViewGroup.LayoutParams layoutParams = new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
            if (mLocalVideoCanvas == null) {
                mLocalVideoCanvas = new AliRtcEngine.AliRtcVideoCanvas();
                SurfaceView localSurfaceView = mAliRtcEngine.createRenderSurfaceView(this);
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
        if (!TextUtils.isEmpty(channelId)) {
            String userId = GlobalConfig.getInstance().getUserId();
            String appId = ARTCTokenHelper.AppId;
            String appKey = ARTCTokenHelper.AppKey;
            long timestamp = ARTCTokenHelper.getTimesTamp();
            String token = ARTCTokenHelper.generateSingleParameterToken(appId, appKey, channelId, userId, timestamp);
            mAliRtcEngine.joinChannel(token, null, null, null);
            hasJoined = true;
        } else {
            Log.e("CustomVideoCapture", "channelId is empty");
        }
    }

    /**
     * 启动自定义采集
     * 
     * 根据“数据源 + 输入格式”两个维度决定路径：
     * 
     * 数据源：
     *  - SOURCE_CAMERA：从相机采集
     *  - SOURCE_FILE：从 mp4 文件采集
     * 
     * 输入格式：
     *  - INPUT_TYPE_YUV：YUV Buffer (I420)
     *  - INPUT_TYPE_TEXTURE：纹理（Texture2D 或 OES）
     * 
     * 4 种组合：
     *  1. 相机 + YUV    → ImageReader + pushYuvDataToSDK
     *  2. 相机 + 纹理   → GLThread + OES 纹理 + pushTextureFrameToSDK
     *  3. 文件 + YUV    → Mp4TexturePlayer (YUV 回调)
     *  4. 文件 + 纹理   → Mp4Texture2DPlayer (Texture2D 回调)
     */
    private void startCustomCapture() {
        isPushingVideoData = true;

        if (mCurrentSourceType == SOURCE_FILE) {
            // ===== 数据源 = 文件(mp4) =====
            // 根据输入类型选择 YUV 播放器 / Texture2D 播放器
            startMp4TextureCapture();
            Log.d("CustomVideoCapture", "Started FILE capture, inputType=" + 
                (mCurrentInputType == INPUT_TYPE_TEXTURE ? "TEXTURE" : "YUV"));
        } else {
            // ===== 数据源 = 相机 =====
            // 根据输入类型选择 YUV 相机路径 / 纹理相机路径
            initCamera();
            openCamera();
            Log.d("CustomVideoCapture", "Started CAMERA capture, inputType=" + 
                (mCurrentInputType == INPUT_TYPE_TEXTURE ? "TEXTURE(OES)" : "YUV"));
        }
    }

    /**
     * 启动 Mp4 视频采集
     * 
     * 根据当前选择的输入类型（YUV/Texture），启动对应的播放器：
     *  - YUV 模式：使用 Mp4TexturePlayer，在回调中推送 YUV 数据
     *  - Texture 模式：使用 Mp4Texture2DPlayer，在回调中推送 Texture2D
     * 
     * 关键 API 集中在此方法的回调中：
     *  【外部视频采集关键 API】mAliRtcEngine.pushExternalVideoFrame(...)
     */
    private void startMp4TextureCapture() {
        // 停止旧的播放器
        if (mp4YuvPlayer != null) {
            mp4YuvPlayer.stop();
            mp4YuvPlayer = null;
        }
        if (mp4Texture2DPlayer != null) {
            mp4Texture2DPlayer.stop();
            mp4Texture2DPlayer = null;
        }

        // 根据当前配置决定使用哪种播放器
        boolean useTexture = (mCurrentInputType == INPUT_TYPE_TEXTURE);
        if (useTexture) {
            // ===== 纹理模式：使用 Texture2D 播放器 =====
            mp4Texture2DPlayer = new Mp4Texture2DPlayer(
                    getAssets(),
                    "video.mp4",
                    (textureId, width, height, texMatrix, eglContext) -> {
                        if (!isPushingVideoData || mAliRtcEngine == null) {
                            return;
                        }

                        // 【外部视频采集关键 API】构造 Texture2D 格式的帧数据
                        AliRtcEngine.AliRtcRawDataFrame frame = new AliRtcEngine.AliRtcRawDataFrame(
                                textureId,
                                AliRtcEngine.AliRtcVideoFormat.AliRtcVideoFormatTexture2D,
                                width, height,
                                texMatrix,
                                0, 0, width, height,
                                eglContext
                        );

                        // 【外部视频采集关键 API】推送纹理帧给 SDK
                        int ret = mAliRtcEngine.pushExternalVideoFrame(frame, AliRtcVideoTrackCamera);
                        if (ret != 0) {
                            Log.e("CustomVideoCapture", "pushExternalVideoFrame (Texture2D) failed: " + ret);
                        }
                    }
            );
            mp4Texture2DPlayer.start();
            Log.d("CustomVideoCapture", "Started Mp4Texture2DPlayer (Texture2D mode)");
        } else {
            // ===== YUV 模式：使用 YUV 播放器 =====
            mp4YuvPlayer = new Mp4TexturePlayer(
                    getAssets(),
                    "video.mp4",
                    (data, width, height, lineSize) -> {
                        if (!isPushingVideoData || mAliRtcEngine == null) {
                            return;
                        }

                        // 【外部视频采集关键 API】构造 I420 格式的帧数据
                        AliRtcEngine.AliRtcVideoFormat format =
                                AliRtcEngine.AliRtcVideoFormat.AliRtcVideoFormatI420;

                        AliRtcEngine.AliRtcRawDataFrame frame = new AliRtcEngine.AliRtcRawDataFrame(
                                data, format, width, height, lineSize, 0, data.length
                        );

                        // 【外部视频采集关键 API】推送 YUV 帧给 SDK
                        int ret = mAliRtcEngine.pushExternalVideoFrame(frame, AliRtcVideoTrackCamera);
                        if (ret != 0) {
                            Log.e("CustomVideoCapture", "pushExternalVideoFrame (YUV) failed: " + ret);
                        }
                    }
            );
            mp4YuvPlayer.start();
            Log.d("CustomVideoCapture", "Started Mp4TexturePlayer (YUV mode)");
        }
    }

    private void initCamera() {
        if (mBackgroundThread != null) {
            mBackgroundThread.quitSafely();
            try {
                mBackgroundThread.join();
            } catch (InterruptedException e) {
                Log.e("CustomVideoCapture", "Background thread join failed", e);
            }
        }

        mBackgroundThread = new HandlerThread("CameraBackground", Process.THREAD_PRIORITY_DEFAULT);
        mBackgroundThread.start();
        mBackgroundHandler = new Handler(mBackgroundThread.getLooper());

        if (mCurrentInputType == INPUT_TYPE_YUV) {
            mImageReader = ImageReader.newInstance(VIDEO_WIDTH, VIDEO_HEIGHT, android.graphics.ImageFormat.YUV_420_888, 3);
            mImageReader.setOnImageAvailableListener(mOnImageAvailableListener, mBackgroundHandler);
        }
    }

    private void openCamera() {
        CameraManager manager = (CameraManager) getSystemService(Context.CAMERA_SERVICE);
        try {
            for (String cameraId : manager.getCameraIdList()) {
                CameraCharacteristics characteristics = manager.getCameraCharacteristics(cameraId);
                Integer facing = characteristics.get(CameraCharacteristics.LENS_FACING);
                if (facing != null && facing == CameraCharacteristics.LENS_FACING_BACK) {
                    mCameraId = cameraId;
                    break;
                }
            }
            if (mCameraId == null) mCameraId = manager.getCameraIdList()[0];
            manager.openCamera(mCameraId, mStateCallback, mBackgroundHandler);
        } catch (CameraAccessException e) {
            e.printStackTrace();
            Log.e("Camera", "openCamera failed: " + e.getMessage());
        }
    }

    private void createCameraPreviewSession() {
        try {
            CaptureRequest.Builder builder = mCameraDevice.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW);

            if (mCurrentInputType == INPUT_TYPE_TEXTURE) {
                if (mSurfaceTexture == null) {
                    Log.e("Camera", "mSurfaceTexture is null, cannot create session");
                    return;
                }
                mPreviewSurface = new Surface(mSurfaceTexture);
                builder.addTarget(mPreviewSurface);
                mCameraDevice.createCaptureSession(Arrays.asList(mPreviewSurface), mSessionCallback, mBackgroundHandler);
            } else {
                builder.addTarget(mImageReader.getSurface());
                mCameraDevice.createCaptureSession(Arrays.asList(mImageReader.getSurface()), mSessionCallback, mBackgroundHandler);
            }
        } catch (Exception e) {
            Log.e("Camera", "Create preview session failed", e);
        }
    }

    private final CameraCaptureSession.StateCallback mSessionCallback = new CameraCaptureSession.StateCallback() {
        @Override
        public void onConfigured(@NonNull CameraCaptureSession session) {
            mCaptureSession = session;
            Log.d("Camera", "CameraCaptureSession onConfigured");
            try {
                CaptureRequest.Builder builder = mCameraDevice.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW);
                if (mCurrentInputType == INPUT_TYPE_TEXTURE) {
                    builder.addTarget(mPreviewSurface);
                } else {
                    builder.addTarget(mImageReader.getSurface());
                }
                builder.set(CaptureRequest.CONTROL_MODE, CaptureRequest.CONTROL_MODE_AUTO);
                session.setRepeatingRequest(builder.build(), null, mBackgroundHandler);
            } catch (Exception e) {
                Log.e("Camera", "Start repeating failed", e);
            }
        }

        @Override
        public void onConfigureFailed(@NonNull CameraCaptureSession session) {
            Log.e("Camera", "Camera session configure failed");
        }
    };

    private void startGlThread(Runnable onGlReady) {
        mGlThread = new HandlerThread("GLThread", Process.THREAD_PRIORITY_URGENT_DISPLAY);
        mGlThread.start();
        mGlHandler = new Handler(mGlThread.getLooper());
        mGlHandler.post(() -> {
            initGlEnvironment();
            if (onGlReady != null) {
                mGlHandler.post(onGlReady);
            }
        });
    }

    private void initGlEnvironment() {
        // 1. 初始化 EGL Display
        mEGLDisplay = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY);
        if (mEGLDisplay == EGL14.EGL_NO_DISPLAY) {
            Log.e("GLThread", "eglGetDisplay failed");
            return;
        }
        int[] version = new int[2];
        if (!EGL14.eglInitialize(mEGLDisplay, version, 0, version, 1)) {
            Log.e("GLThread", "eglInitialize failed");
            return;
        }

        // 2. 选择配置
        int[] configAttribs = {
                EGL14.EGL_RED_SIZE, 8,
                EGL14.EGL_GREEN_SIZE, 8,
                EGL14.EGL_BLUE_SIZE, 8,
                EGL14.EGL_ALPHA_SIZE, 8,
                EGL14.EGL_RENDERABLE_TYPE, EGL14.EGL_OPENGL_ES2_BIT,
                EGL14.EGL_SURFACE_TYPE, EGL14.EGL_PBUFFER_BIT,
                EGL14.EGL_NONE
        };
        EGLConfig[] configs = new EGLConfig[1];
        int[] numConfigs = new int[1];
        EGL14.eglChooseConfig(mEGLDisplay, configAttribs, 0, configs, 0, 1, numConfigs, 0);
        if (numConfigs[0] == 0) {
            Log.e("GLThread", "No EGLConfig found");
            return;
        }
        mEGLConfig = configs[0];

        // 3. 创建上下文
        int[] contextAttribs = {
                EGL14.EGL_CONTEXT_CLIENT_VERSION, 2,
                EGL14.EGL_NONE
        };
        mEGLContext = EGL14.eglCreateContext(mEGLDisplay, mEGLConfig, EGL14.EGL_NO_CONTEXT, contextAttribs, 0);
        if (mEGLContext == null || mEGLContext == EGL14.EGL_NO_CONTEXT) {
            Log.e("GLThread", "Failed to create EGLContext");
            return;
        }

        // 4. 创建 Pbuffer Surface
        int[] surfaceAttribs = {EGL14.EGL_WIDTH, 1, EGL14.EGL_HEIGHT, 1, EGL14.EGL_NONE};
        mEGLSurface = EGL14.eglCreatePbufferSurface(mEGLDisplay, mEGLConfig, surfaceAttribs, 0);
        if (mEGLSurface == null || mEGLSurface == EGL14.EGL_NO_SURFACE) {
            Log.e("GLThread", "Failed to create EGLSurface");
            return;
        }

        // 5. 绑定上下文到当前线程
        if (!EGL14.eglMakeCurrent(mEGLDisplay, mEGLSurface, mEGLSurface, mEGLContext)) {
            Log.e("GLThread", "eglMakeCurrent failed: " + EGL14.eglGetError());
            return;
        }

        // 6. 创建 OES 纹理
        mOESTextureId = createOESTexture();
        if (mOESTextureId == -1) {
            Log.e("GLThread", "Failed to create OES texture");
            return;
        }

        // 7. 创建 SurfaceTexture
        mSurfaceTexture = new SurfaceTexture(mOESTextureId);
        mSurfaceTexture.setDefaultBufferSize(VIDEO_WIDTH, VIDEO_HEIGHT);

        // 8. 设置帧回调（post 到 GL 线程处理）
        mSurfaceTexture.setOnFrameAvailableListener(tex -> {
            mGlHandler.post(this::processNewFrameFromTexture);
        });

        // 9. 创建相机用的 Texture2D + FBO + shader（用于 OES → Texture2D 转换）
        initCameraTexture2DAndFBO();

        Log.d("GLThread", "GL environment initialized with Texture2D conversion support");
    }

    /**
     * 初始化相机 OES → Texture2D 转换所需的 shader、FBO 和 Texture2D
     */
    private void initCameraTexture2DAndFBO() {
        // 1. 编译 shader 程序
        int vertexShader = loadCameraShader(GLES20.GL_VERTEX_SHADER, CAMERA_VERTEX_SHADER);
        int fragmentShader = loadCameraShader(GLES20.GL_FRAGMENT_SHADER, CAMERA_FRAGMENT_SHADER);
        if (vertexShader == 0 || fragmentShader == 0) {
            Log.e("GLThread", "Failed to compile camera shaders");
            return;
        }

        mCameraShaderProgram = GLES20.glCreateProgram();
        GLES20.glAttachShader(mCameraShaderProgram, vertexShader);
        GLES20.glAttachShader(mCameraShaderProgram, fragmentShader);
        GLES20.glLinkProgram(mCameraShaderProgram);

        int[] linkStatus = new int[1];
        GLES20.glGetProgramiv(mCameraShaderProgram, GLES20.GL_LINK_STATUS, linkStatus, 0);
        if (linkStatus[0] != GLES20.GL_TRUE) {
            Log.e("GLThread", "Could not link camera program: "
                    + GLES20.glGetProgramInfoLog(mCameraShaderProgram));
            GLES20.glDeleteProgram(mCameraShaderProgram);
            mCameraShaderProgram = -1;
            return;
        }

        // 获取 shader 变量句柄
        mCameraAPositionHandle  = GLES20.glGetAttribLocation(mCameraShaderProgram, "aPosition");
        mCameraATexCoordHandle  = GLES20.glGetAttribLocation(mCameraShaderProgram, "aTexCoord");
        mCameraUTexMatrixHandle = GLES20.glGetUniformLocation(mCameraShaderProgram, "uTexMatrix");
        mCameraUTextureHandle   = GLES20.glGetUniformLocation(mCameraShaderProgram, "uTexture");

        // 2. 创建 Texture2D
        int[] textures = new int[1];
        GLES20.glGenTextures(1, textures, 0);
        mCameraTexture2DId = textures[0];

        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, mCameraTexture2DId);
        GLES20.glTexParameterf(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR);
        GLES20.glTexParameterf(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR);
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE);
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE);
        GLES20.glTexImage2D(GLES20.GL_TEXTURE_2D, 0, GLES20.GL_RGBA,
                VIDEO_WIDTH, VIDEO_HEIGHT,
                0, GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, null);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0);

        // 3. 创建 FBO 并把 Texture2D 挂上去作为颜色附件
        int[] fbos = new int[1];
        GLES20.glGenFramebuffers(1, fbos, 0);
        mCameraFboId = fbos[0];

        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, mCameraFboId);
        GLES20.glFramebufferTexture2D(GLES20.GL_FRAMEBUFFER,
                GLES20.GL_COLOR_ATTACHMENT0,
                GLES20.GL_TEXTURE_2D,
                mCameraTexture2DId,
                0);

        int status = GLES20.glCheckFramebufferStatus(GLES20.GL_FRAMEBUFFER);
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0);

        if (status != GLES20.GL_FRAMEBUFFER_COMPLETE) {
            Log.e("GLThread", "Camera FBO not complete: " + status);
        } else {
            Log.d("GLThread", "Camera Texture2D(" + mCameraTexture2DId + ") and FBO(" + mCameraFboId + ") created");
        }
    }

    /**
     * 加载并编译 shader
     */
    private int loadCameraShader(int type, String shaderCode) {
        int shader = GLES20.glCreateShader(type);
        GLES20.glShaderSource(shader, shaderCode);
        GLES20.glCompileShader(shader);

        int[] compiled = new int[1];
        GLES20.glGetShaderiv(shader, GLES20.GL_COMPILE_STATUS, compiled, 0);
        if (compiled[0] == 0) {
            Log.e("GLThread", "Camera shader compile error: " + GLES20.glGetShaderInfoLog(shader));
            GLES20.glDeleteShader(shader);
            return 0;
        }
        return shader;
    }

    private int createOESTexture() {
        int[] tex = new int[1];
        GLES20.glGenTextures(1, tex, 0);
        int textureId = tex[0];

        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, textureId);
        GLES20.glTexParameterf(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR);
        GLES20.glTexParameterf(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR);
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE);
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE);
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, 0);

        return textureId;
    }

    //  在 GL 线程中处理帧
    /**
     * 相机纹理数据回调：从 SurfaceTexture 获取新帧，并推送到 SDK
     * 将 OES 纹理转换为 Texture2D 后再推送
     */
    private void processNewFrameFromTexture() {
        if (mSurfaceTexture == null || mOESTextureId == -1 || !isPushingVideoData) return;

        if (EGL14.eglGetCurrentContext() != mEGLContext) {
            if (!EGL14.eglMakeCurrent(mEGLDisplay, mEGLSurface, mEGLSurface, mEGLContext)) {
                Log.e("GLThread", "eglMakeCurrent failed in processNewFrame: " + EGL14.eglGetError());
                return;
            }
        }

        // 更新 SurfaceTexture，从相机拉取最新帧到 OES 纹理
        mSurfaceTexture.updateTexImage();
        float[] transformMatrix = new float[16];
        mSurfaceTexture.getTransformMatrix(transformMatrix);

        // 将 OES 纹理转换为 Texture2D 并推送到 SDK
        convertOesToTexture2DAndPush(transformMatrix);
    }

    /**
     * 将相机 OES 纹理转换为 Texture2D 并推送到 SDK
     * 
     * @param oesTransformMatrix OES 纹理的变换矩阵（包含相机旋转、镜像等信息）
     */
    private void convertOesToTexture2DAndPush(float[] oesTransformMatrix) {
        if (mCameraFboId == -1 || mCameraTexture2DId == -1 || mCameraShaderProgram == -1) {
            Log.e("GLThread", "Camera Texture2D conversion resources not ready");
            return;
        }

        // 1. 绑定 FBO，渲染目标设为 mCameraTexture2DId
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, mCameraFboId);
        GLES20.glViewport(0, 0, VIDEO_WIDTH, VIDEO_HEIGHT);

        // 2. 使用 shader 程序
        GLES20.glUseProgram(mCameraShaderProgram);

        // 3. 绑定 OES 纹理作为输入
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, mOESTextureId);
        GLES20.glUniform1i(mCameraUTextureHandle, 0);

        // 4. 传递变换矩阵
        GLES20.glUniformMatrix4fv(mCameraUTexMatrixHandle, 1, false, oesTransformMatrix, 0);

        // 5. 设置顶点坐标
        FloatBuffer vertexBuffer = ByteBuffer.allocateDirect(CAMERA_VERTEX_COORDS.length * 4)
                .order(ByteOrder.nativeOrder())
                .asFloatBuffer()
                .put(CAMERA_VERTEX_COORDS);
        vertexBuffer.position(0);
        GLES20.glEnableVertexAttribArray(mCameraAPositionHandle);
        GLES20.glVertexAttribPointer(mCameraAPositionHandle, 2, GLES20.GL_FLOAT, false, 0, vertexBuffer);

        // 6. 设置纹理坐标
        FloatBuffer texCoordBuffer = ByteBuffer.allocateDirect(CAMERA_TEXTURE_COORDS.length * 4)
                .order(ByteOrder.nativeOrder())
                .asFloatBuffer()
                .put(CAMERA_TEXTURE_COORDS);
        texCoordBuffer.position(0);
        GLES20.glEnableVertexAttribArray(mCameraATexCoordHandle);
        GLES20.glVertexAttribPointer(mCameraATexCoordHandle, 2, GLES20.GL_FLOAT, false, 0, texCoordBuffer);

        // 7. 绘制四边形（将 OES 纹理渲染到 Texture2D）
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);

        // 8. 清理状态
        GLES20.glDisableVertexAttribArray(mCameraAPositionHandle);
        GLES20.glDisableVertexAttribArray(mCameraATexCoordHandle);
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0);
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, 0);

        // 9. 推送 Texture2D 到 SDK
        // 注意：Texture2D 不需要变换矩阵，传递单位矩阵
        float[] identityMatrix = new float[16];
        Matrix.setIdentityM(identityMatrix, 0);
        pushTexture2DFrameToSDK(mCameraTexture2DId, identityMatrix);
    }

    /**
     * 推送 Texture2D 帧到 SDK（相机采集的纹理路径）
     * 
     * @param textureId      Texture2D ID
     * @param transformMatrix 变换矩阵（Texture2D 通常使用单位矩阵）
     */
    private void pushTexture2DFrameToSDK(int textureId, float[] transformMatrix) {
        if (mAliRtcEngine == null) return;

        AliRtcEngine.AliRtcRawDataFrame frame = new AliRtcEngine.AliRtcRawDataFrame(
                textureId,
                AliRtcEngine.AliRtcVideoFormat.AliRtcVideoFormatTexture2D,  // 使用 Texture2D 格式
                VIDEO_WIDTH, VIDEO_HEIGHT,
                transformMatrix,
                0, 0, VIDEO_WIDTH, VIDEO_HEIGHT,
                mEGLContext
        );

        // 【外部视频采集关键 API 3（纹理模式）】
        // 使用 Texture2D 方式将自定义采集的视频帧推送给 SDK：
        //  - textureId 为 Texture2D ID（从 OES 转换而来）
        //  - format 为 AliRtcVideoFormatTexture2D，标识 2D 纹理输入
        //  - eglContext 用于让 SDK 在共享 GL 上下文中访问该纹理
        int ret = mAliRtcEngine.pushExternalVideoFrame(frame, AliRtcVideoTrackCamera);
        if (ret != 0) {
            Log.e("Texture", "push Texture2D frame failed: " + ret);
        } else {
            Log.d("Texture", "Pushed Texture2D frame: " + textureId);
        }
    }

    private void stopGlThread() {
        if (mGlHandler != null) {
            mGlHandler.post(() -> {
                if (mSurfaceTexture != null) {
                    mSurfaceTexture.release();
                    mSurfaceTexture = null;
                }

                if (mEGLDisplay != EGL14.EGL_NO_DISPLAY) {
                    EGL14.eglMakeCurrent(mEGLDisplay, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_CONTEXT);
                    EGL14.eglDestroySurface(mEGLDisplay, mEGLSurface);
                    EGL14.eglDestroyContext(mEGLDisplay, mEGLContext);
                    EGL14.eglTerminate(mEGLDisplay);
                    EGL14.eglReleaseThread();

                    mEGLDisplay = EGL14.EGL_NO_DISPLAY;
                    mEGLContext = EGL14.EGL_NO_CONTEXT;
                    mEGLSurface = EGL14.EGL_NO_SURFACE;
                }
            });
            try {
                mGlThread.quitSafely();
                mGlThread.join();
            } catch (InterruptedException e) {
                Log.e("GLThread", "join failed", e);
            }
            mGlThread = null;
            mGlHandler = null;
        }
    }

    private final CameraDevice.StateCallback mStateCallback = new CameraDevice.StateCallback() {
        @Override
        public void onOpened(@NonNull CameraDevice camera) {
            mCameraDevice = camera;
            Log.d("Camera", "CameraDevice opened: " + camera.getId());

            if (mCurrentInputType == INPUT_TYPE_TEXTURE) {
                startGlThread(() -> {
                    mBackgroundHandler.post(CustomVideoCaptureActivity.this::createCameraPreviewSession);
                });
            } else {
                createCameraPreviewSession();
            }
        }

        @Override
        public void onDisconnected(@NonNull CameraDevice camera) {
            camera.close();
            mCameraDevice = null;
        }

        @Override
        public void onError(@NonNull CameraDevice camera, int error) {
            camera.close();
            mCameraDevice = null;
        }
    };

    private final ImageReader.OnImageAvailableListener mOnImageAvailableListener = reader -> {
        Image image = reader.acquireLatestImage();
        if (image != null) {
            if (isPushingVideoData && mAliRtcEngine != null) {
                pushYuvDataToSDK(image);
            }
            image.close();
        }
    };

    /**
     * 从 Camera2 ImageReader 中提取 YUV 数据并推送给 SDK
     * 
     * 【外部视频采集关键 API 2】mAliRtcEngine.pushExternalVideoFrame(...)
     * 
     * 流程：
     *  1. 从 Image.Plane 中分别提取 Y/U/V 三个平面的数据
     *  2. 根据 stride 和 pixelStride 将数据拷贝为连续的 I420 格式
     *  3. 构造 AliRtcRawDataFrame（I420格式）
     *  4. 调用 pushExternalVideoFrame 推送给 SDK
     */
    private void pushYuvDataToSDK(Image image) {
        if (image == null || !isPushingVideoData || mAliRtcEngine == null) return;

        try {
            Image.Plane[] planes = image.getPlanes();
            ByteBuffer bufferY = planes[0].getBuffer();
            ByteBuffer bufferU = planes[1].getBuffer();
            ByteBuffer bufferV = planes[2].getBuffer();

            int width = image.getWidth();
            int height = image.getHeight();

            int yRowStride = planes[0].getRowStride();
            int uRowStride = planes[1].getRowStride();
            int vRowStride = planes[2].getRowStride();
            int yPixelStride = planes[0].getPixelStride();
            int uPixelStride = planes[1].getPixelStride();
            int vPixelStride = planes[2].getPixelStride();

            int ySize = width * height;
            int uSize = width * height / 4;
            int vSize = width * height / 4;
            byte[] yuvData = new byte[ySize + uSize + vSize];

            // Y
            for (int i = 0; i < height; i++) {
                int srcPos = i * yRowStride;
                int dstPos = i * width;
                if (yPixelStride == 1) {
                    bufferY.position(srcPos);
                    bufferY.get(yuvData, dstPos, width);
                } else {
                    for (int j = 0; j < width; j++) {
                        yuvData[dstPos + j] = bufferY.get(srcPos + j * yPixelStride);
                    }
                }
            }

            // U
            int uOffset = ySize;
            for (int i = 0; i < height / 2; i++) {
                int srcPos = i * uRowStride;
                int dstPos = uOffset + i * (width / 2);
                if (uPixelStride == 1) {
                    bufferU.position(srcPos);
                    bufferU.get(yuvData, dstPos, width / 2);
                } else {
                    for (int j = 0; j < width / 2; j++) {
                        yuvData[dstPos + j] = bufferU.get(srcPos + j * uPixelStride);
                    }
                }
            }

            // V
            int vOffset = ySize + uSize;
            for (int i = 0; i < height / 2; i++) {
                int srcPos = i * vRowStride;
                int dstPos = vOffset + i * (width / 2);
                if (vPixelStride == 1) {
                    bufferV.position(srcPos);
                    bufferV.get(yuvData, dstPos, width / 2);
                } else {
                    for (int j = 0; j < width / 2; j++) {
                        yuvData[dstPos + j] = bufferV.get(srcPos + j * vPixelStride);
                    }
                }
            }

            AliRtcEngine.AliRtcVideoFormat format = AliRtcEngine.AliRtcVideoFormat.AliRtcVideoFormatI420;
            int[] lineSize = {width, width / 2, width / 2};

            // 【外部视频采集关键 API 2】构造 I420 格式的帧数据
            AliRtcEngine.AliRtcRawDataFrame frame = new AliRtcEngine.AliRtcRawDataFrame(
                    yuvData, format, width, height, lineSize, 90, yuvData.length);

            // 【外部视频采集关键 API 2】推送 YUV 帧给 SDK
            int ret = mAliRtcEngine.pushExternalVideoFrame(frame, AliRtcVideoTrackCamera);
            if (ret != 0) {
                Log.e("YUV", "pushExternalVideoFrame failed: " + ret);
            }
        } catch (Exception e) {
            Log.e("YUV", "Error processing YUV frame", e);
        }
    }

    private final AliRtcEngineEventListener mRtcEngineEventListener = new AliRtcEngineEventListener() {
        @Override
        public void onJoinChannelResult(int result, String channel, String userId, int elapsed) {
            mainHandler.post(() -> {
                String str = result == 0 ? "Join Success" : "Join Failed: " + result;
                ToastHelper.showToast(CustomVideoCaptureActivity.this, str, Toast.LENGTH_SHORT);
                mJoinChannelTextView.setText(R.string.leave_channel);
            });
        }
    };

    private final AliRtcEngineNotify mRtcEngineNotify = new AliRtcEngineNotify() {
        @Override
        public void onRemoteTrackAvailableNotify(String uid, AliRtcEngine.AliRtcAudioTrack audioTrack, AliRtcEngine.AliRtcVideoTrack videoTrack) {
            mainHandler.post(() -> {
                if (videoTrack == AliRtcVideoTrackCamera) {
                    SurfaceView sv = mAliRtcEngine.createRenderSurfaceView(CustomVideoCaptureActivity.this);
                    sv.setZOrderMediaOverlay(true);
                    FrameLayout container = getAvailableView();
                    if (container != null) {
                        container.addView(sv, new FrameLayout.LayoutParams(-1, -1));
                        AliRtcEngine.AliRtcVideoCanvas canvas = new AliRtcEngine.AliRtcVideoCanvas();
                        canvas.view = sv;
                        mAliRtcEngine.setRemoteViewConfig(canvas, uid, AliRtcVideoTrackCamera);
                    }
                }
            });
        }
    };

    private FrameLayout getAvailableView() {
        return fl_remote.getChildCount() == 0 ? fl_remote : null;
    }

    private void destroyRtcEngine() {
        stopCustomCapture();  // 改名

        if (mAliRtcEngine != null) {
            mAliRtcEngine.stopPreview();
            mAliRtcEngine.setLocalViewConfig(null, AliRtcVideoTrackCamera);
            mAliRtcEngine.leaveChannel();
            mAliRtcEngine.destroy();
            mAliRtcEngine = null;
        }
        hasJoined = false;
        findViewById(R.id.ll_video_layout).setVisibility(View.GONE);
        fl_local.removeAllViews();
        mLocalVideoCanvas = null;
        mainHandler.post(() -> ToastHelper.showToast(this, "Leave Channel", Toast.LENGTH_SHORT));
    }

    // 改名：stopYuvCapture → stopCustomCapture
    private void stopCustomCapture() {
        isPushingVideoData = false;

        // 停止 Mp4 播放器
        if (mp4YuvPlayer != null) {
            mp4YuvPlayer.stop();
            mp4YuvPlayer = null;
        }
        if (mp4Texture2DPlayer != null) {
            mp4Texture2DPlayer.stop();
            mp4Texture2DPlayer = null;
        }

        // 停止相机采集
        if (mCaptureSession != null) {
            mCaptureSession.close();
            mCaptureSession = null;
        }
        if (mCameraDevice != null) {
            mCameraDevice.close();
            mCameraDevice = null;
        }
        if (mImageReader != null) {
            mImageReader.close();
            mImageReader = null;
        }
        if (mBackgroundThread != null) {
            mBackgroundThread.quitSafely();
            try {
                mBackgroundThread.join();
            } catch (InterruptedException e) {
                Log.e("CustomVideoCapture", "Background thread join failed", e);
            }
            mBackgroundThread = null;
            mBackgroundHandler = null;
        }

        // 停止旧的 GL 线程（如果之前用相机纹理模式）
        if (mCurrentInputType == INPUT_TYPE_TEXTURE && mGlThread != null) {
            stopGlThread();
        }
    }
}
