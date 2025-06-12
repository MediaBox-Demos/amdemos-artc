package com.example;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Base64;
import java.util.Calendar;
import org.json.JSONObject;

public class App {

    public static String createBase64Token(String appid, String appkey, String channelid, String userid) {
        // Calculate the expiration timestamp (24 hours from now)
        Calendar calendar = Calendar.getInstance();
        calendar.add(Calendar.HOUR_OF_DAY, 24);
        long timestamp = calendar.getTimeInMillis() / 1000;

        // Concatenate the strings
        String stringBuilder = appid + appkey + channelid + userid + timestamp;

        // Calculate the SHA-256 hash
        String token = sha256(stringBuilder);

        // Create the JSON object
        JSONObject base64tokenJson = new JSONObject();
        base64tokenJson.put("appid", appid);
        base64tokenJson.put("channelid", channelid);
        base64tokenJson.put("userid", userid);
        base64tokenJson.put("nonce", "");
        base64tokenJson.put("timestamp", timestamp);
        base64tokenJson.put("token", token);

        // Convert the JSON object to a string and encode it in Base64
        String jsonStr = base64tokenJson.toString();
        String base64token = Base64.getEncoder().encodeToString(jsonStr.getBytes(StandardCharsets.UTF_8));
        return base64token;
    }

    private static String sha256(String input) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(input.getBytes(StandardCharsets.UTF_8));
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1)
                    hexString.append('0');
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        }
    }

    public static void main(String[] args) {
        String appid = "your_appid";
        String appkey = "your_appkey";
        String channel_id = "your_channel_id";
        String user_id = "your_user_id";

        String base64token = createBase64Token(appid, appkey, channel_id, user_id);
        System.out.println("Base64 Token: " + base64token);
    }
}
