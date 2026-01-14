package com.aliyun.artc.api.common.utils;

import com.alivc.rtc.AliRtcEngine;

/**
 * 用户麦位辅助工具类（应用层自定义工具类）
 * 提供麦位相关的辅助方法
 */
public class UserSeatHelper {

    /**
     * 生成流的唯一标识
     *
     * @param userId    用户ID
     * @param trackType 流类型
     * @return 格式: userId_trackType
     */
    public static String getStreamKey(String userId, AliRtcEngine.AliRtcVideoTrack trackType) {
        return userId + "_" + trackType.name();
    }

    /**
     * 获取下一个渲染模式（循环切换）
     * 顺序: Auto -> Stretch -> Fill -> Clip -> Auto
     *
     * @param currentMode 当前渲染模式
     * @return 下一个渲染模式
     */
    public static AliRtcEngine.AliRtcRenderMode getNextRenderMode(AliRtcEngine.AliRtcRenderMode currentMode) {
        if (currentMode == null) {
            return AliRtcEngine.AliRtcRenderMode.AliRtcRenderModeAuto;
        }

        switch (currentMode) {
            case AliRtcRenderModeAuto:
                return AliRtcEngine.AliRtcRenderMode.AliRtcRenderModeStretch;
            case AliRtcRenderModeStretch:
                return AliRtcEngine.AliRtcRenderMode.AliRtcRenderModeFill;
            default:
                return AliRtcEngine.AliRtcRenderMode.AliRtcRenderModeAuto;
        }
    }

    /**
     * 获取渲染模式的显示名称
     *
     * @param mode 渲染模式
     * @return 显示名称
     */
    public static String getRenderModeName(AliRtcEngine.AliRtcRenderMode mode) {
        if (mode == null) {
            return "Unknown";
        }

        switch (mode) {
            case AliRtcRenderModeAuto:
                return "Auto";
            case AliRtcRenderModeStretch:
                return "Stretch";
            case AliRtcRenderModeFill:
                return "Fill";
            default:
                return "Unknown";
        }
    }

    /**
     * 获取下一个旋转角度（循环切换）
     * 顺序: 0 -> 90 -> 180 -> 270 -> 0
     *
     * @param currentAngle 当前旋转角度
     * @return 下一个旋转角度
     */
    public static int getNextRotationAngle(int currentAngle) {
        switch (currentAngle) {
            case 0:
                return 90;
            case 90:
                return 180;
            case 180:
                return 270;
            case 270:
            default:
                return 0;
        }
    }

    /**
     * 获取下一个旋转模式（循环切换）
     * 顺序: 0° -> 90° -> 180° -> 270° -> 0°
     *
     * @param currentMode 当前旋转模式
     * @return 下一个旋转模式
     */
    public static AliRtcEngine.AliRtcRotationMode getNextRotationMode(AliRtcEngine.AliRtcRotationMode currentMode) {
        if (currentMode == null) {
            return AliRtcEngine.AliRtcRotationMode.AliRtcRotationMode_0;
        }

        switch (currentMode) {
            case AliRtcRotationMode_0:
                return AliRtcEngine.AliRtcRotationMode.AliRtcRotationMode_90;
            case AliRtcRotationMode_90:
                return AliRtcEngine.AliRtcRotationMode.AliRtcRotationMode_180;
            case AliRtcRotationMode_180:
                return AliRtcEngine.AliRtcRotationMode.AliRtcRotationMode_270;
            case AliRtcRotationMode_270:
            default:
                return AliRtcEngine.AliRtcRotationMode.AliRtcRotationMode_0;
        }
    }

    /**
     * 将 RotationMode 转为角度值
     *
     * @param mode 旋转模式
     * @return 角度值（0/90/180/270）
     */
    public static int rotationModeToAngle(AliRtcEngine.AliRtcRotationMode mode) {
        if (mode == null) {
            return 0;
        }
        switch (mode) {
            case AliRtcRotationMode_0:
            default:
                return 0;
            case AliRtcRotationMode_90:
                return 90;
            case AliRtcRotationMode_180:
                return 180;
            case AliRtcRotationMode_270:
                return 270;
        }
    }

    /**
     * 切换镜像模式（循环切换）
     * 顺序: AllDisable -> OnlyFront -> AllEnable -> AllDisable
     *
     * @param currentMode 当前镜像模式
     * @return 新的镜像模式
     */
    public static AliRtcEngine.AliRtcRenderMirrorMode toggleMirrorMode(AliRtcEngine.AliRtcRenderMirrorMode currentMode) {
        if (currentMode == null) {
            return AliRtcEngine.AliRtcRenderMirrorMode.AliRtcRenderMirrorModeOnlyFront;
        }
    
        switch (currentMode) {
            case AliRtcRenderMirrorModeAllDisable:
                return AliRtcEngine.AliRtcRenderMirrorMode.AliRtcRenderMirrorModeOnlyFront;
            case AliRtcRenderMirrorModeOnlyFront:
                return AliRtcEngine.AliRtcRenderMirrorMode.AliRtcRenderMirrorModeAllEnabled;
            case AliRtcRenderMirrorModeAllEnabled:
            default:
                return AliRtcEngine.AliRtcRenderMirrorMode.AliRtcRenderMirrorModeAllDisable;
        }
    }
    
    /**
     * 获取镜像模式的显示名称
     *
     * @param mode 镜像模式
     * @return 显示名称
     */
    public static String getMirrorModeName(AliRtcEngine.AliRtcRenderMirrorMode mode) {
        if (mode == null) {
            return "Unknown";
        }
    
        switch (mode) {
            case AliRtcRenderMirrorModeAllDisable:
                return "全关";
            case AliRtcRenderMirrorModeOnlyFront:
                return "仅前置";
            case AliRtcRenderMirrorModeAllEnabled:
                return "全开";
            default:
                return "Unknown";
        }
    }

    /**
     * 格式化用户标签文本
     *
     * @param userId    用户ID
     * @param trackType 流类型
     * @param isLocal   是否为本地流
     * @return 格式化后的标签文本
     */
    public static String formatUserLabel(String userId, AliRtcEngine.AliRtcVideoTrack trackType, boolean isLocal) {
        StringBuilder label = new StringBuilder();

        // 本地/远端标识
        if (isLocal) {
            label.append("[Local] ");
        } else {
            label.append(userId).append(" ");
        }

        // 流类型
        if (trackType != null) {
            switch (trackType) {
                case AliRtcVideoTrackCamera:
                    label.append("(Camera)");
                    break;
                case AliRtcVideoTrackScreen:
                    label.append("(Screen)");
                    break;
                case AliRtcVideoTrackBoth:
                    label.append("(Both)");
                    break;
                case AliRtcVideoTrackNo:
                    label.append("(No Video)");
                    break;
            }
        }

        return label.toString();
    }

    /**
     * 判断是否为相机流
     *
     * @param trackType 流类型
     * @return true表示是相机流
     */
    public static boolean isCameraTrack(AliRtcEngine.AliRtcVideoTrack trackType) {
        return trackType == AliRtcEngine.AliRtcVideoTrack.AliRtcVideoTrackCamera ||
                trackType == AliRtcEngine.AliRtcVideoTrack.AliRtcVideoTrackBoth;
    }

    /**
     * 判断是否为屏幕流
     *
     * @param trackType 流类型
     * @return true表示是屏幕流
     */
    public static boolean isScreenTrack(AliRtcEngine.AliRtcVideoTrack trackType) {
        return trackType == AliRtcEngine.AliRtcVideoTrack.AliRtcVideoTrackScreen ||
                trackType == AliRtcEngine.AliRtcVideoTrack.AliRtcVideoTrackBoth;
    }

    /**
     * 判断是否有视频流
     *
     * @param trackType 流类型
     * @return true表示有视频流
     */
    public static boolean hasVideoTrack(AliRtcEngine.AliRtcVideoTrack trackType) {
        return trackType != null && trackType != AliRtcEngine.AliRtcVideoTrack.AliRtcVideoTrackNo;
    }
}
