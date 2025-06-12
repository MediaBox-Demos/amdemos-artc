package com.aliyun.artc.api.keycenter.utils;

import android.content.Context;
import android.graphics.Color;
import android.view.Gravity;

import io.github.muddz.styleabletoast.StyleableToast;

public class ToastHelper {

    public static void showToast(Context context, String text, int duration) {
        new StyleableToast.Builder(context)
                .text(text)
                .textColor(Color.parseColor("#FCFCFD"))
                .textSize(14)
                .cornerRadius(8)
                .backgroundColor(Color.parseColor("#141416"))
                .length(duration)
                .gravity(Gravity.CENTER)
                .build().show();
    }

    public static void showToast(Context context, int resId, int duration) {
        showToast(context, context.getString(resId), duration);
    }
}
