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

    // 控制YUV和纹理输入的选项
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

        initVideoInputTypeControl();

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

    private void initVideoInputTypeControl() {
        mVideoInputTypeGroup = findViewById(R.id.videoSourceRadioGroup);
        mYuvInputRadio = findViewById(R.id.yuv_radio_button);
        mTextureInputRadio = findViewById(R.id.texture_radio_button);

        mVideoInputTypeGroup.setOnCheckedChangeListener((group, checkedId) -> {
            if (checkedId == R.id.yuv_radio_button) {
                mCurrentInputType = INPUT_TYPE_YUV;
            } else if (checkedId == R.id.texture_radio_button) {
                mCurrentInputType = INPUT_TYPE_TEXTURE;
            }
        });
    }

    private void initRtcEngine() {
        if (mAliRtcEngine == null) {
            mAliRtcEngine = AliRtcEngine.getInstance(this);
        }
        mAliRtcEngine.setRtcEngineEventListener(mRtcEngineEventListener);
        mAliRtcEngine.setRtcEngineNotify(mRtcEngineNotify);

        if (isCustomVideoCapture) {
            mAliRtcEngine.setExternalVideoSource(true,
                    mCurrentInputType == INPUT_TYPE_TEXTURE,
                    AliRtcVideoTrackCamera,
                    AliRtcRenderModeAuto);
        }
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
        startPreview();
        if (isCustomVideoCapture) {
            mAliRtcEngine.enableLocalVideo(false);
        }

        startCustomCapture();  // 原 startYuvCapture → 改名
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

    // 改名：startYuvCapture → startCustomCapture
    private void startCustomCapture() {
        isPushingVideoData = true;
        initCamera();
        openCamera();
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

        // 5. ✅ 绑定上下文到当前线程
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

    // ✅ 在 GL 线程中处理帧
    private void processNewFrameFromTexture() {
        if (mSurfaceTexture == null || mOESTextureId == -1 || !isPushingVideoData) return;

        // ✅ 确保当前上下文绑定
        if (EGL14.eglGetCurrentContext() != mEGLContext) {
            if (!EGL14.eglMakeCurrent(mEGLDisplay, mEGLSurface, mEGLSurface, mEGLContext)) {
                Log.e("GLThread", "eglMakeCurrent failed in processNewFrame: " + EGL14.eglGetError());
                return;
            }
        }

        mSurfaceTexture.updateTexImage();
        float[] transformMatrix = new float[16];
        mSurfaceTexture.getTransformMatrix(transformMatrix);

        pushTextureFrameToSDK(mOESTextureId, transformMatrix);
    }

    private void pushTextureFrameToSDK(int textureId, float[] transformMatrix) {
        if (mAliRtcEngine == null) return;

        AliRtcEngine.AliRtcRawDataFrame frame = new AliRtcEngine.AliRtcRawDataFrame(
                textureId,
                AliRtcEngine.AliRtcVideoFormat.AliRtcVideoFormatTextureOES,
                VIDEO_WIDTH, VIDEO_HEIGHT,
                transformMatrix,
                0, 0, VIDEO_WIDTH, VIDEO_HEIGHT,
                mEGLContext  // ✅ 安全传入共享上下文
        );

        int ret = mAliRtcEngine.pushExternalVideoFrame(frame, AliRtcVideoTrackCamera);
        if (ret != 0) {
            Log.e("Texture", "push frame failed: " + ret);
        } else {
            Log.d("Texture", "Pushed texture frame with context: " + textureId);
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

            AliRtcEngine.AliRtcRawDataFrame frame = new AliRtcEngine.AliRtcRawDataFrame(
                    yuvData, format, width, height, lineSize, 0, yuvData.length);

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

        if (mCurrentInputType == INPUT_TYPE_TEXTURE) {
            stopGlThread();
        }
    }
}
