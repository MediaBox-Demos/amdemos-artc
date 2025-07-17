package com.aliyun.artc.api.keycenter.utils;

import android.content.Context;
import android.graphics.Color;
import android.view.Gravity;

import io.github.muddz.styleabletoast.StyleableToast;

public class ToastHelper {
    private static StyleableToast.Builder currentToast;  // 全局单例 Toast

    public static void showToast(Context context, String text, int duration) {
        // 如果已有 Toast，先取消
        if (currentToast != null) {
            currentToast.cancel();
        }

        // 创建新的 Toast 实例并赋值给全局变量
        currentToast = new StyleableToast.Builder(context)
                .text(text)
                .textColor(Color.parseColor("#FCFCFD"))
                .textSize(14)
                .cornerRadius(8)
                .backgroundColor(Color.parseColor("#141416"))
                .length(duration)
                .gravity(Gravity.CENTER)
                .build();

        // 显示 Toast
        currentToast.show();
    }

    public static void showToast(Context context, int resId, int duration) {
        showToast(context, context.getString(resId), duration);
    }
}
