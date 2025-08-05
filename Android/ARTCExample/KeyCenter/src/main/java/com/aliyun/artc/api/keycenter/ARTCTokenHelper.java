package com.aliyun.artc.api.keycenter;

import android.util.Base64;

import org.json.JSONObject;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

public final class ARTCTokenHelper {
    /**
     * RTC AppId
     */
    public static String AppId = "xxx";

    /**
     * RTC AppKey
     */
    public static String AppKey = "xxx";

    /**
     * 根据channelId，userId, timestamp, nonce 生成单参数入会 的token
     * Generate a single-parameter meeting token based on channelId, userId, and nonce
     */
    public static String generateSingleParameterToken(String appId, String appKey, String channelId, String userId, long timestamp,  String nonce) {

        StringBuilder stringBuilder = new StringBuilder()
                .append(appId)
                .append(appKey)
                .append(channelId)
                .append(userId)
                .append(timestamp);
        String token =  getSHA256(stringBuilder.toString());
        try{
            JSONObject tokenJson = new JSONObject();
            tokenJson.put("appid", AppId);
            tokenJson.put("channelid", channelId);
            tokenJson.put("userid", userId);
            tokenJson.put("nonce", nonce);
            tokenJson.put("timestamp", timestamp);
            tokenJson.put("token", token);
            String base64Token = Base64.encodeToString(tokenJson.toString().getBytes(StandardCharsets.UTF_8), Base64.NO_WRAP);
            return base64Token;
        }catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    /**
     * 根据channelId，userId, timestamp 生成单参数入会 的token
     * Generate a single-parameter meeting token based on channelId, userId, and timestamp
     */
    public static String generateSingleParameterToken(String appId, String appKey, String channelId, String userId, long timestamp) {
        return generateSingleParameterToken(appId, appKey, channelId, userId, timestamp, "");
    }

    /**
     * 根据channelId，userId, timestamp, nonce 生成多参数入会的 token
     * Generate a multi-parameter meeting token based on channelId, userId, and timestamp
     */
    public static String generateMulitParameterToken(String appId, String appKey, String channelId, String userId, long timestamp,  String nonce) {
        StringBuilder stringBuilder = new StringBuilder()
                .append(appId)
                .append(appKey)
                .append(channelId)
                .append(userId)
                .append(timestamp);
        String token =  getSHA256(stringBuilder.toString());
        return token;
    }

    /**
     * 根据channelId，userId, timestamp 生成多参数入会的 token
     * Generate a multi-parameter meeting token based on channelId, userId, and timestamp
     */
    public static String generateMulitParameterToken(String appId, String appKey, String channelId, String userId, long timestamp) {
        return generateMulitParameterToken(appId, appKey, channelId, userId, timestamp, "");
    }

    public static String getSHA256(String str) {
        try {
            MessageDigest messageDigest = MessageDigest.getInstance("SHA-256");
            byte[] hash = messageDigest.digest(str.getBytes(StandardCharsets.UTF_8));
            return byte2Hex(hash);
        } catch (NoSuchAlgorithmException e) {
            // Consider logging the exception and/or re-throwing as a RuntimeException
            e.printStackTrace();
        }
        return "";
    }

    private static String byte2Hex(byte[] bytes) {
        StringBuilder stringBuilder = new StringBuilder();
        for (byte b : bytes) {
            String hex = Integer.toHexString(0xff & b);
            if (hex.length() == 1) {
                // Use single quote for char
                stringBuilder.append('0');
            }
            stringBuilder.append(hex);
        }
        return stringBuilder.toString();
    }

    public static long getTimesTamp() {
        return System.currentTimeMillis() / 1000 + 60 * 60 * 24;
    }
}
