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

    // 最近一次生成 Token 的中间过程（用于 Demo 展示）
    private static String sLastContent = "";
    private static String sLastSha256Token = "";
    private static String sLastJsonString = "";
    private static String sLastBase64Token = "";

    /**
     * 获取最近一次生成的拼接内容
     */
    public static String getLastContent() {
        return sLastContent;
    }

    /**
     * 获取最近一次生成的 SHA256 Token
     */
    public static String getLastSha256Token() {
        return sLastSha256Token;
    }

    /**
     * 获取最近一次生成的 JSON 字符串（仅单参入会有效）
     */
    public static String getLastJsonString() {
        return sLastJsonString;
    }

    /**
     * 获取最近一次生成的 Base64 Token（仅单参入会有效）
     */
    public static String getLastBase64Token() {
        return sLastBase64Token;
    }

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
        String content = stringBuilder.toString();
        String sha256 = getSHA256(content);
        try{
            JSONObject tokenJson = new JSONObject();
            tokenJson.put("appid", appId);
            tokenJson.put("channelid", channelId);
            tokenJson.put("userid", userId);
            tokenJson.put("nonce", nonce);
            tokenJson.put("timestamp", timestamp);
            tokenJson.put("token", sha256);
            String jsonStr = tokenJson.toString();
            String base64Token = Base64.encodeToString(jsonStr.getBytes(StandardCharsets.UTF_8), Base64.NO_WRAP);

            // 记录中间过程（单参入会）
            sLastContent = content;
            sLastSha256Token = sha256;
            sLastJsonString = jsonStr;
            sLastBase64Token = base64Token;

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
        String content = stringBuilder.toString();
        String sha256 = getSHA256(content);

        // 记录中间过程（多参入会）：没有 JSON / Base64
        sLastContent = content;
        sLastSha256Token = sha256;
        sLastJsonString = "";
        sLastBase64Token = "";

        return sha256;
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
