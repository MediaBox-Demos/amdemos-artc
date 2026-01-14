package com.aliyun.artc.api.common.videoview;

import android.animation.ValueAnimator;
import android.content.Context;
import android.graphics.Color;
import android.util.AttributeSet;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;

import com.alivc.rtc.AliRtcEngine;
import com.aliyun.artc.api.common.R;
import com.aliyun.artc.api.common.utils.UserSeatHelper;

/**
 * 用户麦位视图容器组件（应用层自定义组件，非 RTC SDK 组件）
 * 提供视频流的显示容器和状态展示功能
 * <p>
 * 视图层次结构：
 * - FrameLayout (VideoContainer): 用于承载 RTC SDK 创建的 SurfaceView
 * - View (BorderView): 边框视图（本地/远端/说话状态区分）
 * - LinearLayout (StatusBar): 状态栏（顶部显示用户信息和状态）
 * - View (PlaceholderView): 占位视图（无流时显示）
 * - LinearLayout (ControlBar): 控制栏（底部，长按显示）
 */
public class UserSeatView extends FrameLayout {

    // 用户信息
    private String userId;
    private AliRtcEngine.AliRtcVideoTrack trackType;
    private boolean isLocal;

    // 子视图组件
    private FrameLayout videoContainer;
    private View borderView;
    private LinearLayout statusBar;
    private TextView userIdLabel;
    private ImageView cameraStatusIcon;
    private ImageView micStatusIcon;
    private View placeholderView;
    private TextView placeholderLabel;
    private LinearLayout controlBar;

    // 控制按钮
    private TextView renderModeBtn;
    private TextView mirrorBtn;
    private TextView rotateBtn;

    // 状态
    private boolean isControlBarVisible = false;
    private boolean isSpeaking = false;
    private ValueAnimator speakingAnimator;

    // 回调监听器
    private OnUserSeatActionListener actionListener;

    // 配置开关
    private boolean enableClickToSwitch = true;
    private boolean showControlBar = true;

    public UserSeatView(@NonNull Context context) {
        super(context);
        init(context);
    }

    public UserSeatView(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        init(context);
    }

    public UserSeatView(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init(context);
    }

    /**
     * 初始化视图
     */
    private void init(Context context) {
        // 设置视图基础属性
        setLayoutParams(new LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                (int) getResources().getDimension(R.dimen.user_seat_height)
        ));

        // 创建子视图
        createVideoContainer(context);
        createBorderView(context);
        createStatusBar(context);
        createPlaceholderView(context);
        createControlBar(context);

        // 设置点击事件
        setupClickListeners();
    }

    /**
     * 创建视频容器
     */
    private void createVideoContainer(Context context) {
        videoContainer = new FrameLayout(context);
        videoContainer.setLayoutParams(new LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
        ));
        videoContainer.setBackgroundColor(Color.BLACK);
        addView(videoContainer);
    }

    /**
     * 创建边框视图
     */
    private void createBorderView(Context context) {
        borderView = new View(context);
        LayoutParams params = new LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
        );
        borderView.setLayoutParams(params);
        addView(borderView);
        
        // 默认远端样式
        applyRemoteStyle();
    }

    /**
     * 创建状态栏
     */
    private void createStatusBar(Context context) {
        statusBar = new LinearLayout(context);
        statusBar.setOrientation(LinearLayout.HORIZONTAL);
        statusBar.setGravity(Gravity.CENTER_VERTICAL);
        
        int padding = (int) getResources().getDimension(R.dimen.user_seat_status_bar_padding);
        statusBar.setPadding(padding, padding, padding, padding);
        
        LayoutParams params = new LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                (int) getResources().getDimension(R.dimen.user_seat_status_bar_height)
        );
        params.gravity = Gravity.TOP;
        statusBar.setLayoutParams(params);
        statusBar.setBackgroundColor(ContextCompat.getColor(context, R.color.user_seat_remote_label_bg));

        // 用户ID标签
        userIdLabel = new TextView(context);
        userIdLabel.setTextColor(Color.WHITE);
        userIdLabel.setTextSize(TypedValue.COMPLEX_UNIT_PX, 
                getResources().getDimension(R.dimen.user_seat_label_text_size));
        LinearLayout.LayoutParams labelParams = new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.WRAP_CONTENT, 1.0f
        );
        userIdLabel.setLayoutParams(labelParams);
        statusBar.addView(userIdLabel);

        // 摄像头状态图标
        cameraStatusIcon = createStatusIcon(context);
        cameraStatusIcon.setContentDescription("Camera");
        statusBar.addView(cameraStatusIcon);

        // 麦克风状态图标
        micStatusIcon = createStatusIcon(context);
        micStatusIcon.setContentDescription("Microphone");
        statusBar.addView(micStatusIcon);

        addView(statusBar);
    }

    /**
     * 创建状态图标
     */
    private ImageView createStatusIcon(Context context) {
        ImageView icon = new ImageView(context);
        int size = (int) getResources().getDimension(R.dimen.user_seat_icon_size);
        int margin = (int) getResources().getDimension(R.dimen.user_seat_icon_margin);
        
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(size, size);
        params.setMargins(margin, 0, margin, 0);
        icon.setLayoutParams(params);
        icon.setColorFilter(ContextCompat.getColor(context, R.color.user_seat_icon_normal));
        
        return icon;
    }

    /**
     * 创建占位视图
     */
    private void createPlaceholderView(Context context) {
        placeholderView = new FrameLayout(context);
        placeholderView.setLayoutParams(new LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
        ));
        placeholderView.setBackgroundColor(ContextCompat.getColor(context, R.color.user_seat_placeholder_bg));
        placeholderView.setVisibility(GONE);

        // 占位标签
        placeholderLabel = new TextView(context);
        placeholderLabel.setTextColor(Color.WHITE);
        placeholderLabel.setTextSize(24);
        placeholderLabel.setGravity(Gravity.CENTER);
        LayoutParams labelParams = new LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
        );
        labelParams.gravity = Gravity.CENTER;
        placeholderLabel.setLayoutParams(labelParams);
        placeholderLabel.setText("👤");

        ((FrameLayout) placeholderView).addView(placeholderLabel);
        addView(placeholderView);
    }

    /**
     * 创建控制栏
     */
    private void createControlBar(Context context) {
        controlBar = new LinearLayout(context);
        controlBar.setOrientation(LinearLayout.HORIZONTAL);
        controlBar.setGravity(Gravity.CENTER);
        
        // 高度改为 WRAP_CONTENT，根据按钮内容自适应
        LayoutParams params = new LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
        );
        params.gravity = Gravity.BOTTOM;
        controlBar.setLayoutParams(params);
        controlBar.setBackgroundColor(ContextCompat.getColor(context, R.color.user_seat_control_bar_bg));
        // 默认显示控制栏，方便用户直接操作
        controlBar.setVisibility(VISIBLE);
        
        // 给控制栏添加小量内边距，让按钮不贴边
        int padding = (int) getResources().getDimension(R.dimen.user_seat_control_button_margin);
        controlBar.setPadding(0, padding / 2, 0, padding / 2);

        // 渲染模式按钮
        renderModeBtn = createControlButton(context, "Mode");
        controlBar.addView(renderModeBtn);

        // 镜像按钮（文字按钮）
        mirrorBtn = createControlButton(context, "Mirror");
        controlBar.addView(mirrorBtn);

        // 旋转按钮（文字按钮）
        rotateBtn = createControlButton(context, "Rotate");
        controlBar.addView(rotateBtn);

        addView(controlBar);
    }

    /**
     * 创建控制按钮（文本）
     */
    private TextView createControlButton(Context context, String text) {
        TextView button = new TextView(context);
        button.setText(text);
        button.setTextColor(Color.WHITE);
        button.setTextSize(10); // 字体稍微缩小一点
        button.setGravity(Gravity.CENTER);
        button.setBackgroundColor(Color.parseColor("#44FFFFFF"));
        
        int margin = (int) getResources().getDimension(R.dimen.user_seat_control_button_margin);
        int size = (int) getResources().getDimension(R.dimen.user_seat_control_button_size);
        
        // 宽度使用权重平分，高度用 WRAP_CONTENT，整体更扁一些
        LinearLayout.LayoutParams params = 
                new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f);
        // 缩小按钮之间的距离：将 margin 减半
        params.setMargins(margin / 2, 0, margin / 2, 0);
        button.setLayoutParams(params);
        
        // 给一个较小的最小高度，避免太扁不好点
        button.setMinHeight(size);
        
        // 允许多行显示
        button.setSingleLine(false);
        button.setMaxLines(2);
        
        return button;
    }

    /**
     * 设置点击事件监听器
     */
    private void setupClickListeners() {
        // 单击：切换渲染模式
        if (enableClickToSwitch) {
            setOnClickListener(v -> {
                if (actionListener != null && !isControlBarVisible) {
                    actionListener.onRenderModeChange(userId, trackType);
                }
            });
        }

        // 长按：显示/隐藏控制栏
        if (showControlBar) {
            setOnLongClickListener(v -> {
                toggleControlBar();
                return true;
            });
        }

        // 控制按钮点击事件
        renderModeBtn.setOnClickListener(v -> {
            if (actionListener != null) {
                actionListener.onRenderModeChange(userId, trackType);
            }
        });

        mirrorBtn.setOnClickListener(v -> {
            if (actionListener != null) {
                actionListener.onMirrorToggle(userId, trackType);
            }
        });

        rotateBtn.setOnClickListener(v -> {
            if (actionListener != null) {
                actionListener.onRotationChange(userId, trackType);
            }
        });
    }

    // ==================== 公共方法 ====================

    /**
     * 设置用户信息、流类型和本地/远端标识
     *
     * @param userId    用户ID
     * @param trackType 流类型
     * @param isLocal   是否为本地流
     */
    public void setUserInfo(String userId, AliRtcEngine.AliRtcVideoTrack trackType, boolean isLocal) {
        this.userId = userId;
        this.trackType = trackType;
        this.isLocal = isLocal;

        // 更新用户标签
        String label = UserSeatHelper.formatUserLabel(userId, trackType, isLocal);
        userIdLabel.setText(label);

        // 更新状态栏背景色
        if (isLocal) {
            statusBar.setBackgroundColor(ContextCompat.getColor(getContext(), R.color.user_seat_local_label_bg));
        } else {
            statusBar.setBackgroundColor(ContextCompat.getColor(getContext(), R.color.user_seat_remote_label_bg));
        }

        // 应用本地/远端样式
        if (isLocal) {
            applyLocalStyle();
        } else {
            applyRemoteStyle();
        }
    }

    /**
     * 获取视频容器，用于添加 SurfaceView
     *
     * @return 视频容器
     */
    public FrameLayout getVideoContainer() {
        return videoContainer;
    }

    /**
     * 更新摄像头状态图标
     *
     * @param enabled 是否开启
     */
    public void updateCameraStatus(boolean enabled) {
        if (enabled) {
            cameraStatusIcon.setColorFilter(ContextCompat.getColor(getContext(), R.color.user_seat_icon_normal));
            cameraStatusIcon.setAlpha(1.0f);
        } else {
            cameraStatusIcon.setColorFilter(ContextCompat.getColor(getContext(), R.color.user_seat_icon_disabled));
            cameraStatusIcon.setAlpha(0.5f);
        }
    }

    /**
     * 更新麦克风状态图标
     *
     * @param muted 是否静音
     */
    public void updateMicStatus(boolean muted) {
        if (muted) {
            micStatusIcon.setColorFilter(ContextCompat.getColor(getContext(), R.color.user_seat_icon_muted));
            micStatusIcon.setAlpha(1.0f);
        } else {
            micStatusIcon.setColorFilter(ContextCompat.getColor(getContext(), R.color.user_seat_icon_normal));
            micStatusIcon.setAlpha(1.0f);
        }
    }

    /**
     * 设置说话状态（边框动画）
     *
     * @param speaking 是否正在说话
     */
    public void setSpeaking(boolean speaking) {
        this.isSpeaking = speaking;
        
        if (speaking) {
            startSpeakingAnimation();
        } else {
            stopSpeakingAnimation();
            // 恢复正常边框
            if (isLocal) {
                applyLocalStyle();
            } else {
                applyRemoteStyle();
            }
        }
    }

    /**
     * 显示/隐藏占位视图
     *
     * @param show 是否显示
     */
    public void showPlaceholder(boolean show) {
        placeholderView.setVisibility(show ? VISIBLE : GONE);
    }

    /**
     * 更新显示模式提示
     *
     * @param mode 渲染模式
     */
    public void updateRenderModeDisplay(AliRtcEngine.AliRtcRenderMode mode) {
        String modeName = UserSeatHelper.getRenderModeName(mode);
        renderModeBtn.setText(modeName);
    }

    /**
     * 更新镜像状态显示
     *
     * @param enabled 是否启用镜像
     */
    public void updateMirrorDisplay(boolean enabled) {
        if (enabled) {
            mirrorBtn.setAlpha(1.0f);
        } else {
            mirrorBtn.setAlpha(0.5f);
        }
    }

    /**
     * 更新旋转角度显示
     *
     * @param angle 旋转角度
     */
    public void updateRotationDisplay(int angle) {
        rotateBtn.setText(angle + "°");
    }

    /**
     * 设置操作回调监听器
     *
     * @param listener 回调监听器
     */
    public void setOnActionListener(OnUserSeatActionListener listener) {
        this.actionListener = listener;
    }

    /**
     * 从 UserSeatState 刷新整个视图状态
     *
     * @param state 用户麦位状态
     */
    public void applyState(UserSeatState state) {
        if (state == null) return;
        
        setUserInfo(state.userId, state.trackType, state.isLocal);
        updateCameraStatus(state.isCameraOn);
        updateMicStatus(state.isMicMuted);
        
        // 渲染模式按钮：显示渲染模式
        updateRenderModeDisplay(state.renderMode);
        
        // 镜像按钮：显示镜像模式文本 + 高亮与否
        boolean isMirrorEnabled = 
                (state.mirrorMode == AliRtcEngine.AliRtcRenderMirrorMode.AliRtcRenderMirrorModeAllEnabled);
        updateMirrorDisplay(isMirrorEnabled);
        String mirrorName = UserSeatHelper.getMirrorModeName(state.mirrorMode);
        mirrorBtn.setText(mirrorName);
        
        // 旋转按钮：显示角度文本
        int angle = UserSeatHelper.rotationModeToAngle(state.rotationMode);
        updateRotationDisplay(angle);
        
        showPlaceholder(!state.hasVideoStream);
        setSpeaking(state.isSpeaking);
    }

    /**
     * 应用本地预览样式（蓝色边框）
     */
    public void applyLocalStyle() {
        int borderWidth = (int) getResources().getDimension(R.dimen.user_seat_border_width_local);
        int borderColor = ContextCompat.getColor(getContext(), R.color.user_seat_local_border);
        setBorder(borderWidth, borderColor);
    }

    /**
     * 应用远端画面样式（默认边框）
     */
    public void applyRemoteStyle() {
        int borderWidth = (int) getResources().getDimension(R.dimen.user_seat_border_width_normal);
        int borderColor = ContextCompat.getColor(getContext(), R.color.user_seat_remote_border);
        setBorder(borderWidth, borderColor);
    }

    /**
     * 设置点击切换开关
     */
    public void setEnableClickToSwitch(boolean enable) {
        this.enableClickToSwitch = enable;
    }

    /**
     * 设置控制栏显示开关
     */
    public void setShowControlBar(boolean show) {
        this.showControlBar = show;
    }

    // ==================== 私有辅助方法 ====================

    /**
     * 设置边框
     */
    private void setBorder(int width, int color) {
        borderView.setBackgroundColor(Color.TRANSPARENT);
        borderView.setPadding(width, width, width, width);
        // 使用简单的边框实现
        videoContainer.setBackgroundColor(color);
        LayoutParams params = (LayoutParams) videoContainer.getLayoutParams();
        params.setMargins(width, width, width, width);
        videoContainer.setLayoutParams(params);
    }

    /**
     * 切换控制栏显示/隐藏
     */
    private void toggleControlBar() {
        isControlBarVisible = !isControlBarVisible;
        controlBar.setVisibility(isControlBarVisible ? VISIBLE : GONE);
    }

    /**
     * 开始说话动画
     */
    private void startSpeakingAnimation() {
        if (speakingAnimator != null && speakingAnimator.isRunning()) {
            return;
        }

        int normalWidth = isLocal ? 
                (int) getResources().getDimension(R.dimen.user_seat_border_width_local) :
                (int) getResources().getDimension(R.dimen.user_seat_border_width_normal);
        int speakingWidth = (int) getResources().getDimension(R.dimen.user_seat_border_width_speaking);
        int speakingColor = ContextCompat.getColor(getContext(), R.color.user_seat_speaking_border);

        speakingAnimator = ValueAnimator.ofFloat(0f, 1f);
        speakingAnimator.setDuration(500);
        speakingAnimator.setRepeatMode(ValueAnimator.REVERSE);
        speakingAnimator.setRepeatCount(ValueAnimator.INFINITE);
        speakingAnimator.addUpdateListener(animation -> {
            float fraction = (float) animation.getAnimatedValue();
            int width = (int) (normalWidth + (speakingWidth - normalWidth) * fraction);
            setBorder(width, speakingColor);
        });
        speakingAnimator.start();
    }

    /**
     * 停止说话动画
     */
    private void stopSpeakingAnimation() {
        if (speakingAnimator != null) {
            speakingAnimator.cancel();
            speakingAnimator = null;
        }
    }

    @Override
    protected void onDetachedFromWindow() {
        super.onDetachedFromWindow();
        stopSpeakingAnimation();
    }
}
