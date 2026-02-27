//
//  AlivcLivePusher+Private.h
//  AlivcLivePusher
//
//  Created by siheng on 2021/5/28.
//  Copyright © 2021 Alivc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AlivcLivePusher.h"
#include "pusher/alivc_live_pusher.h"

NS_ASSUME_NONNULL_BEGIN

@interface AlivcLivePusher ()

- (NSString *)getTraceId;

- (AlivcLivePushConfig *)getLivePusherConfig;

- (int) setConfig:(AlivcLivePushConfig *)config;

@property (nonatomic, strong) NSUserDefaults *userDefaults;

@property (nonatomic, strong) NSURL *groupFileUrl;

@property (nonatomic, strong) NSURL *groupVideoFileUrl;

@property (nonatomic) AliVCSDK_ARTC::AlivcLivePusher* alivcLivePusher_;

@property (nonatomic,assign) AliVCSDK_ARTC::AlivcLivePushConfig config_;

@property (nonatomic, strong) NSMutableDictionary *renderViews;

@end

NS_ASSUME_NONNULL_END

