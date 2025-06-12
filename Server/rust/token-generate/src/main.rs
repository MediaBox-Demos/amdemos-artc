use chrono::{Duration, Utc};
use sha2::{Sha256, Digest};
use serde_json::json;
use base64::encode;

fn create_base64_token(appid: &str, appkey: &str, channel_id: &str, user_id: &str) -> String {
    // Calculate the expiration timestamp (24 hours from now)
    let timestamp = (Utc::now() + Duration::hours(24)).timestamp();

    // Concatenate the strings
    let string_builder = format!("{}{}{}{}{}", appid, appkey, channel_id, user_id, timestamp);

    // Calculate the SHA-256 hash
    let mut hasher = Sha256::new();
    hasher.update(string_builder);
    let token = hasher.finalize();
    let token_hex = format!("{:x}", token);

    // Create the JSON object
    let token_json = json!({
        "appid": appid,
        "channelid": channel_id,
        "userid": user_id,
        "nonce": "",
        "timestamp": timestamp,
        "token": token_hex
    });

    // Convert the JSON object to a string and encode it in Base64
    let base64_token = encode(token_json.to_string());

    base64_token
}

fn main() {
    let appid = "your_appid";
    let appkey = "your_appkey";
    let channel_id = "your_channel_id";
    let user_id = "your_user_id";

    let token = create_base64_token(appid, appkey, channel_id, user_id);
    println!("Base64 Token: {}", token);
}
