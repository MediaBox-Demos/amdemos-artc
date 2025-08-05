package com.aliyun.artc.api.basicusage.VideoBasicUsage;

import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.widget.Button;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.DialogFragment;
import androidx.recyclerview.widget.RecyclerView;

import com.alivc.rtc.AliRtcEngine;
import com.aliyun.artc.api.basicusage.R;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Objects;

public class VideoConfigurationDialogFragment extends DialogFragment {
    public interface VideoConfigurationAppliedListener {
        void onCameraCaptureConfiguration(AliRtcEngine.AliEngineCameraCapturerConfiguration config);

        void onVideoEncoderConfiguraion(AliRtcEngine.AliRtcVideoEncoderConfiguration config);
    }

    private List<VideoConfigurationItem> configItems;
    private VideoConfigurationItemAdapter adapter;

    private VideoConfigurationAppliedListener listener;

    private AliRtcEngine.AliEngineCameraCapturerConfiguration  videoCaptureConfiguration;
    private AliRtcEngine.AliRtcVideoEncoderConfiguration videoEncoderConfiguration;

    private boolean isCameraOn = false;

    public VideoConfigurationDialogFragment() {}

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        initVideoConfigUI();
    }

    @Override
    public void onStart() {
        super.onStart();
        if(getDialog() != null && getDialog().getWindow() != null) {
            Window window = getDialog().getWindow();
            window.setLayout(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
            window.setBackgroundDrawable(new ColorDrawable(Color.TRANSPARENT));
        }
    }

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.dialog_video_configuration, container, false);
        RecyclerView recyclerView = view.findViewById(R.id.video_configuration_recycler_view);
        recyclerView.setLayoutManager(new androidx.recyclerview.widget.LinearLayoutManager(getContext()));
        adapter = new VideoConfigurationItemAdapter(getContext(), configItems);
        recyclerView.setAdapter(adapter);

        Button btnConfirm = view.findViewById(R.id.video_configuration_button_confirm);
        btnConfirm.setOnClickListener(v -> {
            // 构建对象
            videoCaptureConfiguration = new AliRtcEngine.AliEngineCameraCapturerConfiguration();
            videoEncoderConfiguration = new AliRtcEngine.AliRtcVideoEncoderConfiguration();
            // 收集配置
            getCameraCapturerConfiguration();
            getVideoEncoderConfiguration();
            // 触发回调
            if(listener != null) {
                listener.onCameraCaptureConfiguration(videoCaptureConfiguration);
                listener.onVideoEncoderConfiguraion(videoEncoderConfiguration);
            }
            // 隐藏dialog
            if(getDialog() != null && getDialog().isShowing()) {
                getDialog().hide();
            }
        });
        return view;
    }

    private void getCameraCapturerConfiguration() {
        videoCaptureConfiguration = new AliRtcEngine.AliEngineCameraCapturerConfiguration();

        // 1. 摄像头采集偏好
        VideoConfigurationItem prefItem = configItems.get(1);
        if (prefItem.type == VideoConfigurationItem.TYPE_SPINNER) {
            int index = prefItem.spinnerIndex;
            AliRtcEngine.AliRtcCaptureOutputPreference preference;
            switch (index) {
                case 1:
                    preference = AliRtcEngine.AliRtcCaptureOutputPreference.ALIRTC_CAPTURER_OUTPUT_PREFERENCE_PERFORMANCE;
                    break;
                case 2:
                    preference = AliRtcEngine.AliRtcCaptureOutputPreference.ALIRTC_CAPTURER_OUTPUT_PREFERENCE_PREVIEW;
                    break;
                default:
                    preference = AliRtcEngine.AliRtcCaptureOutputPreference.ALIRTC_CAPTURER_OUTPUT_PREFERENCE_AUTO;
                    break;
            }
            videoCaptureConfiguration.preference = preference;
        }

        // 2. 摄像头方向
        VideoConfigurationItem dirItem = configItems.get(2);
        if (dirItem.type == VideoConfigurationItem.TYPE_SPINNER) {
            int index = dirItem.spinnerIndex;
            videoCaptureConfiguration.cameraDirection = index == 0 ?
                    AliRtcEngine.AliRtcCameraDirection.CAMERA_FRONT : AliRtcEngine.AliRtcCameraDirection.CAMERA_REAR;
        }

        // 3. 帧率
        VideoConfigurationItem frameRateItem = configItems.get(3);
        if (frameRateItem.type == VideoConfigurationItem.TYPE_EDIT_TEXT) {
            try {
                int frameRate = Integer.parseInt(frameRateItem.editTextValue);
                if(frameRate > 30) {
                    frameRate = 30;
                }
                if(frameRate < 0){
                    frameRate = -1;
                }
                videoCaptureConfiguration.fps = frameRate;
            } catch (NumberFormatException ignored) {}
        }

        // 4. 采集分辨率
        VideoConfigurationItem profileItem = configItems.get(4);
        if (profileItem.type == VideoConfigurationItem.TYPE_SPINNER) {
            int index = profileItem.spinnerIndex;
            videoCaptureConfiguration.cameraCaptureProfile = index == 0 ?
                    AliRtcEngine.AliRtcCameraCaptureProfile.ALIRTC_CAMERA_CAPTURER_PROFILE_DEFAULT : AliRtcEngine.AliRtcCameraCaptureProfile.ALIRTC_CAMERA_CAPTURER_PROFILE_1080P;
        }

        // 5. 使用纹理编码
        VideoConfigurationItem textureEncodeItem = configItems.get(5);
        if (textureEncodeItem.type == VideoConfigurationItem.TYPE_SWITCH) {
            videoCaptureConfiguration.textureEncode = textureEncodeItem.switchValue ? 1 : 0;
        }

        // 6. 开启纹理采集
        VideoConfigurationItem textureCaptureItem = configItems.get(6);
        if (textureCaptureItem.type == VideoConfigurationItem.TYPE_SWITCH) {
            videoCaptureConfiguration.cameraTextureCapture = textureCaptureItem.switchValue ? 1 : 0;
        }
    }


    private void getVideoEncoderConfiguration() {
        videoEncoderConfiguration = new AliRtcEngine.AliRtcVideoEncoderConfiguration();

        // 1. 分辨率宽高
        int width = 0, height = 0;
        try {
            width = Integer.parseInt(configItems.get(7).editTextValue);
            height = Integer.parseInt(configItems.get(8).editTextValue);
        } catch (NumberFormatException ignored) {}
        videoEncoderConfiguration.dimensions = new AliRtcEngine.AliRtcVideoDimensions(width, height);

        // 2. 帧率
        VideoConfigurationItem frameRateItem = configItems.get(9);
        if (frameRateItem.type == VideoConfigurationItem.TYPE_EDIT_TEXT) {
            try {
                int frameRate = Integer.parseInt(frameRateItem.editTextValue);
                if(frameRate > 30) {
                    frameRate = 30;
                }
                if(frameRate <= 1){
                    frameRate = 1;
                }
                videoEncoderConfiguration.frameRate = frameRate;
            } catch (NumberFormatException ignored) {}
        }

        // 3. 码率
        VideoConfigurationItem bitrateItem = configItems.get(10);
        if (bitrateItem.type == VideoConfigurationItem.TYPE_EDIT_TEXT) {
            try {
                videoEncoderConfiguration.bitrate = Integer.parseInt(bitrateItem.editTextValue);
            } catch (NumberFormatException ignored) {}
        }

        // 4. GOP
        VideoConfigurationItem gopItem = configItems.get(11);
        if (gopItem.type == VideoConfigurationItem.TYPE_EDIT_TEXT) {
            try {
                int gopSize = Integer.parseInt(gopItem.editTextValue);
                if(gopSize >1) {
                    videoEncoderConfiguration.keyFrameInterval = gopSize;
                }
            } catch (NumberFormatException ignored) {}
        }

        // 5. 强制严格关键帧间隔
        VideoConfigurationItem strictKeyframeItem = configItems.get(12);
        if (strictKeyframeItem.type == VideoConfigurationItem.TYPE_SWITCH) {
            videoEncoderConfiguration.forceStrictKeyFrameInterval = strictKeyframeItem.switchValue;
        }

        // 6. 视频输出方向
        VideoConfigurationItem orientationItem = configItems.get(13);
        if (orientationItem.type == VideoConfigurationItem.TYPE_SPINNER) {
            int index = orientationItem.spinnerIndex;
            AliRtcEngine.AliRtcVideoEncoderOrientationMode mode;
            switch (index) {
                case 1:
                    mode = AliRtcEngine.AliRtcVideoEncoderOrientationMode.AliRtcVideoEncoderOrientationModeFixedLandscape;
                    break;
                case 2:
                    mode = AliRtcEngine.AliRtcVideoEncoderOrientationMode.AliRtcVideoEncoderOrientationModeFixedPortrait;
                    break;
                default:
                    mode = AliRtcEngine.AliRtcVideoEncoderOrientationMode.AliRtcVideoEncoderOrientationModeAdaptive;
                    break;
            }
            videoEncoderConfiguration.orientationMode = mode;
        }

        // 7. 旋转模式
        VideoConfigurationItem rotationItem = configItems.get(14);
        if (rotationItem.type == VideoConfigurationItem.TYPE_SPINNER) {
            int index = rotationItem.spinnerIndex;
            AliRtcEngine.AliRtcRotationMode rotationMode;
            switch (index) {
                case 1:
                    rotationMode = AliRtcEngine.AliRtcRotationMode.AliRtcRotationMode_90;
                    break;
                case 2:
                    rotationMode = AliRtcEngine.AliRtcRotationMode.AliRtcRotationMode_180;
                    break;
                case 3:
                    rotationMode = AliRtcEngine.AliRtcRotationMode.AliRtcRotationMode_270;
                    break;
                default:
                    rotationMode = AliRtcEngine.AliRtcRotationMode.AliRtcRotationMode_0;
                    break;
            }
            videoEncoderConfiguration.rotationMode = rotationMode;
        }

        // 8. 编码类型（H264 / H265）
        VideoConfigurationItem codecTypeItem = configItems.get(15);
        if (codecTypeItem.type == VideoConfigurationItem.TYPE_SPINNER) {
            int index = codecTypeItem.spinnerIndex;
            videoEncoderConfiguration.encodeCodecType = index == 0 ?
                    AliRtcEngine.AliRtcVideoEncodeCodecType.AliRtcVideoEncodeCodecTypeH264 :
                    AliRtcEngine.AliRtcVideoEncodeCodecType.AliRtcVideoEncodeCodecTypeHevc;
        }

        // 9. 编码方式（软编 / 硬编）
        VideoConfigurationItem codecModeItem = configItems.get(16);
        if (codecModeItem.type == VideoConfigurationItem.TYPE_SPINNER) {
            int index = codecModeItem.spinnerIndex;
            switch (index) {
                case 0:
                    videoEncoderConfiguration.codecType = AliRtcEngine.AliRtcVideoCodecType.AliRtcVideoCodecTypeSoftware;
                    break;
                case 1:
                    videoEncoderConfiguration.codecType = AliRtcEngine.AliRtcVideoCodecType.AliRtcVideoCodecTypeHardware;
                    break;
                case 2:
                    videoEncoderConfiguration.codecType = AliRtcEngine.AliRtcVideoCodecType.AliRtcVideoCodecTypeHardwareTexture;
                    break;
                default:
                    videoEncoderConfiguration.codecType = AliRtcEngine.AliRtcVideoCodecType.AliRtcVideoCodecTypeDefault;
            }
        }
    }


    public void setOnItemCommitListener(VideoConfigurationAppliedListener listener) {
        this.listener = listener;
    }

    // 视频配置界面
    private void initVideoConfigUI() {
        List<VideoConfigurationItem> configItems = new ArrayList<>();
        configItems.add(VideoConfigurationItem.createHeaderItem(getString(R.string.camera_capture_config)));
        // 摄像头采集偏好
        List<String> capturePreferenceOptions = Arrays.asList("SDK Auto", "Performance Priority", "Preview Priority");
        configItems.add(VideoConfigurationItem.createSpinnerItem(getString(R.string.camera_capture_preference), 0, capturePreferenceOptions));
        //摄像头方向
        List<String> cameraDirectionOptions = Arrays.asList(getString(R.string.camera_capture_front_camera), getString(R.string.camera_capture_back_camera));
        configItems.add(VideoConfigurationItem.createSpinnerItem(getString(R.string.camera_capture_direction), 0, cameraDirectionOptions));
        // 帧率
        configItems.add(VideoConfigurationItem.createEditTextItem(getString(R.string.camera_capture_frame_rate), "15"));
        // 采集分辨率
        List<String> captureProfileOptions = Arrays.asList("default","1080p");
        configItems.add(VideoConfigurationItem.createSpinnerItem(getString(R.string.camera_capture_resolution), 0, captureProfileOptions));
        // 是否使用纹理编码
        configItems.add(VideoConfigurationItem.createSwitchItem(getString(R.string.camera_capture_texture_Encode), false));
        // 是否开启纹理采集
        configItems.add(VideoConfigurationItem.createSwitchItem(getString(R.string.camera_capture_texture_capture), false));

        configItems.add(VideoConfigurationItem.createHeaderItem(getString(R.string.video_encoder_config)));
        configItems.add(VideoConfigurationItem.createEditTextItem(getString(R.string.video_encoder_resolution_width), "640"));
        configItems.add(VideoConfigurationItem.createEditTextItem(getString(R.string.video_encoder_resolution_height), "480"));
        // 帧率
        configItems.add(VideoConfigurationItem.createEditTextItem(getString(R.string.video_encoder_frame_rate), "15"));
        //码率
        configItems.add(VideoConfigurationItem.createEditTextItem(getString(R.string.video_encoder_bitrate), "512"));
        // GOP
        configItems.add(VideoConfigurationItem.createEditTextItem(getString(R.string.video_encoder_keyframe_interval), "0"));
        configItems.add(VideoConfigurationItem.createSwitchItem(getString(R.string.video_encoder_force_strict_keyframe_interval), false));
        // 镜像模式，推荐调用setVideoMirrorMode
//        configItems.add(VideoConfigurationItem.createSwitchItem(getString(R.string.video_encoder_mirror_mode), false));
        // 视频输出方向
        List<String> orientationOptions = Arrays.asList(getString(R.string.video_encoder_orientation_adaptive), getString(R.string.video_encoder_orientation_landscape), getString(R.string.video_encoder_orientation_portrait));
        configItems.add(VideoConfigurationItem.createSpinnerItem(getString(R.string.video_encoder_orientation_mode), 0, orientationOptions));
        // 旋转
        List<String> rotationOptions = Arrays.asList("0", "90", "180", "270");
        configItems.add(VideoConfigurationItem.createSpinnerItem(getString(R.string.video_encoder_rotation_mode), 0, rotationOptions));
        // 编码类型
        List<String> encodeCodecTypeOptions = Arrays.asList("H264", "H265");
        configItems.add(VideoConfigurationItem.createSpinnerItem(getString(R.string.video_encoder_encode_codec_type), 0, encodeCodecTypeOptions));
        List<String> codecTypeOptions = Arrays.asList(getString(R.string.video_encoder_software_encode), getString(R.string.video_encoder_hardware_encode), getString(R.string.video_encoder_hardware_texture_encode));
        configItems.add(VideoConfigurationItem.createSpinnerItem(getString(R.string.video_encoder_codec_type), 0, codecTypeOptions));

        this.configItems = configItems;
    }
}
