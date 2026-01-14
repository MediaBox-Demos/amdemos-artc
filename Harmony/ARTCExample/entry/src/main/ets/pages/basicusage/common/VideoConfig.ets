import { AliRtcCaptureOutputPreference } from "@aliyun_video_cloud/alivcsdk_artc";

export class VideoConfig {
  // 摄像头采集配置
  cameraPreference: AliRtcCaptureOutputPreference = AliRtcCaptureOutputPreference.AliRtcCaptureOutputPreferenceAuto; // 0: SDK Auto, 1: Performance Priority, 2: Preview Priority
  cameraDirection: number = 1; // 0: 后置, 1: 前置
  fps: number = 15; // 帧率
  cameraCaptureProfile: number = 0; // 0: default, 1: 1080P
  textureEncode: boolean = false; // 是否使用纹理编码
  cameraTextureCapture: boolean = false; // 是否开启纹理采集

  // 视频编码配置
  width: number = 640;
  height: number = 480;
  frameRate: number = 15; // 编码帧率
  bitrate: number = 512; // 码率(kbps)
  keyFrameInterval: number = 0; // 关键帧间隔
  forceStrictKeyFrameInterval: boolean = false; // 是否强制严格关键帧间隔
  orientationMode: number = 1; // 0: 跟随采集, 1: 固定横屏, 2: 固定竖屏
  rotationMode: number = 0; // 0, 90, 180, 270
  encodeCodecType: number = 0; // 0: H264, 1: H265
  codecType: number = 0; // 0: 软件编码, 1: 硬件编码, 2: 硬件纹理编码
}