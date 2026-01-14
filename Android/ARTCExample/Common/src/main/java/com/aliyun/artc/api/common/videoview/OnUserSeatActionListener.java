package com.aliyun.artc.api.common.videoview;

import com.alivc.rtc.AliRtcEngine;

/**
 * 用户麦位视图操作回调接口
 * Activity实现此接口以处理用户交互事件，并调用RTC SDK接口
 */
public interface OnUserSeatActionListener {
    /**
     * 渲染模式切换回调
     *
     * @param userId    用户ID
     * @param trackType 流类型
     */
    void onRenderModeChange(String userId, AliRtcEngine.AliRtcVideoTrack trackType);

    /**
     * 镜像切换回调
     *
     * @param userId    用户ID
     * @param trackType 流类型
     */
    void onMirrorToggle(String userId, AliRtcEngine.AliRtcVideoTrack trackType);

    /**
     * 旋转切换回调
     *
     * @param userId    用户ID
     * @param trackType 流类型
     */
    void onRotationChange(String userId, AliRtcEngine.AliRtcVideoTrack trackType);
}
