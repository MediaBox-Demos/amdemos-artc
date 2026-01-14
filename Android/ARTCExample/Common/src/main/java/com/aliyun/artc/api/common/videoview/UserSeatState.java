package com.aliyun.artc.api.common.videoview;

import com.alivc.rtc.AliRtcEngine;

/**
 * 用户麦位状态数据类（应用层自定义类，非 RTC SDK 组件）
 * 用于管理单个用户麦位的所有状态信息
 */
public class UserSeatState {
    /**
     * 用户ID
     */
    public String userId;

    /**
     * 视频流类型（Camera/Screen/Both/No）
     */
    public AliRtcEngine.AliRtcVideoTrack trackType;

    /**
     * 是否为本地流
     */
    public boolean isLocal;

    /**
     * 渲染模式（Auto/Stretch/Fill/Clip）
     */
    public AliRtcEngine.AliRtcRenderMode renderMode;

    /**
     * 镜像模式（用于渲染画布）
     */
    public AliRtcEngine.AliRtcRenderMirrorMode mirrorMode;

    /**
     * 旋转角度（用于渲染画布）
     */
    public AliRtcEngine.AliRtcRotationMode rotationMode;

    /**
     * 是否有视频流
     */
    public boolean hasVideoStream;

    /**
     * 摄像头是否开启
     */
    public boolean isCameraOn;

    /**
     * 麦克风是否静音
     */
    public boolean isMicMuted;

    /**
     * 是否正在说话
     */
    public boolean isSpeaking;

    /**
     * 构造函数 - 创建默认状态
     */
    public UserSeatState() {
        this.renderMode = AliRtcEngine.AliRtcRenderMode.AliRtcRenderModeAuto;
        this.mirrorMode = AliRtcEngine.AliRtcRenderMirrorMode.AliRtcRenderMirrorModeAllDisable;
        this.rotationMode = AliRtcEngine.AliRtcRotationMode.AliRtcRotationMode_0;
        this.hasVideoStream = false;
        this.isCameraOn = true;
        this.isMicMuted = false;
        this.isSpeaking = false;
        this.isLocal = false;
    }

    /**
     * 构造函数 - 使用用户ID和流类型初始化
     *
     * @param userId    用户ID
     * @param trackType 流类型
     * @param isLocal   是否为本地流
     */
    public UserSeatState(String userId, AliRtcEngine.AliRtcVideoTrack trackType, boolean isLocal) {
        this();
        this.userId = userId;
        this.trackType = trackType;
        this.isLocal = isLocal;
        // 本地流默认仅前置镜像
        if (isLocal) {
            this.mirrorMode = AliRtcEngine.AliRtcRenderMirrorMode.AliRtcRenderMirrorModeOnlyFront;
        }
    }

    /**
     * 获取流的唯一标识
     *
     * @return 格式: userId_trackType
     */
    public String getStreamKey() {
        return userId + "_" + trackType.name();
    }

    /**
     * 复制状态对象
     *
     * @return 新的状态对象副本
     */
    public UserSeatState copy() {
        UserSeatState copy = new UserSeatState();
        copy.userId = this.userId;
        copy.trackType = this.trackType;
        copy.isLocal = this.isLocal;
        copy.renderMode = this.renderMode;
        copy.mirrorMode = this.mirrorMode;
        copy.rotationMode = this.rotationMode;
        copy.hasVideoStream = this.hasVideoStream;
        copy.isCameraOn = this.isCameraOn;
        copy.isMicMuted = this.isMicMuted;
        copy.isSpeaking = this.isSpeaking;
        return copy;
    }

    @Override
    public String toString() {
        return "UserSeatState{" +
                "userId='" + userId + '\'' +
                ", trackType=" + trackType +
                ", isLocal=" + isLocal +
                ", renderMode=" + renderMode +
                ", mirrorMode=" + mirrorMode +
                ", rotationMode=" + rotationMode +
                ", hasVideoStream=" + hasVideoStream +
                ", isCameraOn=" + isCameraOn +
                ", isMicMuted=" + isMicMuted +
                ", isSpeaking=" + isSpeaking +
                '}';
    }
}
