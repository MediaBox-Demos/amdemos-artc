package com.aliyun.artc.api.keycenter;

import android.text.TextUtils;

import com.aliyun.artc.api.keycenter.utils.SettingStorage;

import java.util.Random;

public class GlobalConfig {

    private static class LAZY_HOLDER {
        private static GlobalConfig sInstance = new GlobalConfig();
    }
    public static GlobalConfig getInstance() {
        return LAZY_HOLDER.sInstance;
    }

    private String mUserId = null;

    private String mSdkRegion = null;
    public String getUserId() {
        if(TextUtils.isEmpty(mUserId)) {
            if(!TextUtils.isEmpty(SettingStorage.getInstance().get(SettingStorage.KEY_USER_ID))) {
                mUserId = SettingStorage.getInstance().get(SettingStorage.KEY_USER_ID);
            } else {
                Random random = new Random();
                mUserId = ("Android") + "_" + random.nextInt(1000000);
                SettingStorage.getInstance().set(SettingStorage.KEY_USER_ID, mUserId);
            }
        }
        return mUserId;
    }

    public String getSdkRegion() {

        if(TextUtils.isEmpty(mSdkRegion)) {
            if(!TextUtils.isEmpty(SettingStorage.getInstance().get(SettingStorage.KEY_SDK_ENV_ID))) {
                mSdkRegion = SettingStorage.getInstance().get(SettingStorage.KEY_SDK_ENV_ID);
            } else {
                mSdkRegion = "cn";
                SettingStorage.getInstance().set(SettingStorage.KEY_SDK_ENV_ID, mSdkRegion);
            }
        }
        return mSdkRegion;
    }

    public void setSdkRegion(String sdkRegion) {
        if(!TextUtils.isEmpty(sdkRegion)) {
            mSdkRegion = sdkRegion;
            SettingStorage.getInstance().set(SettingStorage.KEY_SDK_ENV_ID, mSdkRegion);
        }
    }

    public void setUserId(String userId) {
        if(!TextUtils.isEmpty(userId)) {
            mUserId = userId;
            SettingStorage.getInstance().set(SettingStorage.KEY_USER_ID, mUserId);
        }
    }

    public String gerRandomChannelId() {
        Random random = new Random();
        return String.valueOf(random.nextInt(1000000));
    }
}
