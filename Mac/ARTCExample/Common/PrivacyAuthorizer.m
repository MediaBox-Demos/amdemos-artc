//
//  PrivacyAuthorizer.m
//  Tutorial
//
//  Created by 高宇 on 2020/2/24.
//  Copyright © 2020 tiantian. All rights reserved.
//

#import "PrivacyAuthorizer.h"
#import <AVFoundation/AVFoundation.h>

@implementation PrivacyAuthorizer

+ (void)authorCamera:(void (^ __nullable)(BOOL granted))completion{
    dispatch_block_t workBlock;
    if (@available(macOS 10.14, *)) {
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if(authStatus == AVAuthorizationStatusAuthorized) {
            workBlock = ^{
                if (completion) completion(YES);
            };
            // do your logic
        } else if(authStatus == AVAuthorizationStatusDenied || authStatus == AVAuthorizationStatusRestricted){
            workBlock = ^{
                if (completion) completion(NO);
            };
            // denied
        } else if(authStatus == AVAuthorizationStatusNotDetermined){
            // not determined?!
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                [PrivacyAuthorizer authorCamera:completion];
            }];
            return;
        } else {
            // impossible, unknown authorization status
        }
    }else {
        workBlock = ^{
            if (completion) completion(YES);
        };
    }
    dispatch_async(dispatch_get_main_queue(), workBlock);
}

+ (void)authorMicphone:(void (^ __nullable)(BOOL granted))completion{
    dispatch_block_t workBlock;
    if (@available(macOS 10.14, *)) {
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
        if(authStatus == AVAuthorizationStatusAuthorized) {
            workBlock = ^{
                if (completion) completion(YES);
            };
            // do your logic
        } else if(authStatus == AVAuthorizationStatusDenied || authStatus == AVAuthorizationStatusRestricted){
            workBlock = ^{
                if (completion) completion(NO);
            };
            // denied
        } else if(authStatus == AVAuthorizationStatusNotDetermined){
            // not determined?!
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
                [PrivacyAuthorizer authorMicphone:completion];
            }];
            return;
        } else {
            // impossible, unknown authorization status
        }
    }else {
        workBlock = ^{
            if (completion) completion(YES);
        };
    }
    dispatch_async(dispatch_get_main_queue(), workBlock);
}

@end
