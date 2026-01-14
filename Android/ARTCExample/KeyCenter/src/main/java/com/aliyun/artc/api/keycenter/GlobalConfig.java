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
    private String mAppId = null;
    private String mAppKey = null;
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

    public String getAppId() {
        if (TextUtils.isEmpty(mAppId)) {
            String saved = SettingStorage.getInstance().get(SettingStorage.KEY_APP_ID);
            if (!TextUtils.isEmpty(saved)) {
                mAppId = saved;
            } else {
                // 使用 ARTCTokenHelper 中的 AppId 作为默认值
                mAppId = ARTCTokenHelper.AppId;
            }
        }
        return mAppId;
    }

    public void setAppId(String appId) {
        if (!TextUtils.isEmpty(appId)) {
            mAppId = appId;
            SettingStorage.getInstance().set(SettingStorage.KEY_APP_ID, mAppId);
            // 同步更新到 ARTCTokenHelper，兼容旧用法
            ARTCTokenHelper.AppId = mAppId;
        }
    }

    public String getAppKey() {
        if (TextUtils.isEmpty(mAppKey)) {
            String saved = SettingStorage.getInstance().get(SettingStorage.KEY_APP_KEY);
            if (!TextUtils.isEmpty(saved)) {
                mAppKey = saved;
            } else {
                // 使用 ARTCTokenHelper 中的 AppKey 作为默认值
                mAppKey = ARTCTokenHelper.AppKey;
            }
        }
        return mAppKey;
    }

    public void setAppKey(String appKey) {
        if (!TextUtils.isEmpty(appKey)) {
            mAppKey = appKey;
            SettingStorage.getInstance().set(SettingStorage.KEY_APP_KEY, mAppKey);
            // 同步更新到 ARTCTokenHelper，兼容旧用法
            ARTCTokenHelper.AppKey = mAppKey;
        }
    }

    /**
     * 检查 AppId 和 AppKey 是否已配置
     * @return true 表示已配置，false 表示未配置
     */
    public boolean isAppConfigured() {
        String appId = getAppId();
        String appKey = getAppKey();
        return !TextUtils.isEmpty(appId) && !TextUtils.isEmpty(appKey);
    }
}
