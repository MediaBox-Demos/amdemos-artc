package main

import (
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"time"
)

func createBase64Token(appid, appkey, channelID, userID string) (string, error) {
	// Calculate the expiration timestamp (24 hours from now)
	timestamp := time.Now().Add(24 * time.Hour).Unix()

	// Concatenate the strings
	stringBuilder := appid + appkey + channelID + userID + fmt.Sprintf("%d", timestamp)

	// Calculate the SHA-256 hash
	hasher := sha256.New()
	hasher.Write([]byte(stringBuilder))
	token := hasher.Sum(nil)

	// Convert the hash to a hexadecimal string using encoding/hex
	tokenHex := hex.EncodeToString(token)

	// Create the JSON object
	tokenJSON := map[string]interface{}{
		"appid":     appid,
		"channelid": channelID,
		"userid":    userID,
		"nonce":     "",
		"timestamp": timestamp,
		"token":     tokenHex,
	}

	// Convert the JSON object to a string and encode it in Base64
	jsonBytes, err := json.Marshal(tokenJSON)
	if err != nil {
		return "", err
	}
	base64Token := base64.StdEncoding.EncodeToString(jsonBytes)

	return base64Token, nil
}

func main() {
	appid := "your_appid"
	appkey := "your_appkey"
	channelID := "your_channel_id"
	userID := "your_user_id"

	token, err := createBase64Token(appid, appkey, channelID, userID)
	if err != nil {
		fmt.Println("Error creating token:", err)
		return
	}
	fmt.Println("Base64 Token:", token)
}