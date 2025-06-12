'use strict'
const crypto = require('crypto')
function create_base64_token(appid, appkey, channelid, userid) {
    let timestamp = Math.floor(Date.now() / 1000 + 24 * 60 * 60)

    let string_builder = appid + appkey + channelid + userid + timestamp.toString()
    let token = crypto.createHash('sha256').update(string_builder).digest('hex')
    let base64tokenJson = {
        appid:appid,
        channelid:channelid,
        userid:userid,
        nonce:'',
        timestamp:timestamp,
        token:token
    }
    let base64token = Buffer.from(JSON.stringify(base64tokenJson), 'utf-8').toString('base64')
    return base64token
}

let appid = "your_appid";
let appkey = "your_appkey";
let channel_id = "your_channel_id";
let user_id = "your_user_id";

let base64token = create_base64_token(appid, appkey, channel_id, user_id)
console.log(base64token)
