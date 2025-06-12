#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import hashlib
import datetime
import time
import base64
import json

def create_base64_token(app_id, app_key, channel_id, user_id):
    expire = datetime.datetime.now() + datetime.timedelta(days=1)
    timestamp = int(time.mktime(expire.timetuple()))
    h = hashlib.sha256()
    h.update(str(app_id).encode('utf-8'))
    h.update(str(app_key).encode('utf-8'))
    h.update(str(channel_id).encode('utf-8'))
    h.update(str(user_id).encode('utf-8'))
    h.update(str(timestamp).encode('utf-8'))
    token = h.hexdigest()

    jsonToken = {'appid':str(app_id),
                 'channelid':str(channel_id),
                 'userid':str(user_id),
                 'nonce':'',
                 'timestamp':timestamp,
                 'token':str(token)
                }
    base64Token = base64.b64encode(json.dumps(jsonToken).encode())

    return base64Token

def main():
    app_id = 'your_appid'
    app_key = 'your_appkey'
    channel_id = 'your_channel_id'
    user_id = 'your_user_id'

    base64Token = create_base64_token(app_id, app_key, channel_id, user_id)
    
    print(base64Token)

if __name__ == '__main__':
    main()
