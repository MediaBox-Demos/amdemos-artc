package com.aliyun.artc.api.keycenter.utils;

import static android.content.Context.MODE_PRIVATE;

import android.content.Context;
import android.content.SharedPreferences;
import android.util.Log;

public class SettingStorage {
    private static final String FILE_NAME = "API_EXAMPLE_SETTING_STORAGE";
    public static final String KEY_USER_ID = "KEY_USER_ID";
    public static final String KEY_SDK_ENV_ID = "KEY_SDK_ENV_ID";

    private static class LAZY_HOLDER {
        private static SettingStorage sInstance = new SettingStorage();
    }
    public static SettingStorage getInstance() {
        return LAZY_HOLDER.sInstance;
    }

    private SharedPreferences mSP = null;

    public void init(Context context) {
        if (mSP == null) {
            Context applicationContext = context.getApplicationContext();
            mSP = applicationContext.getSharedPreferences(FILE_NAME, MODE_PRIVATE);
        }
    }

    public void set(String key, String value) {
        SharedPreferences.Editor editor = mSP.edit();
        editor.putString(key, value);
        editor.apply();
        Log.i("SettingStorage", "set " + key + ": " + value);
    }

    public String get(String key) {
        String value = mSP.getString(key, "");
        Log.i("SettingStorage", "get " + key + ": " + value);
        return value;
    }


}
