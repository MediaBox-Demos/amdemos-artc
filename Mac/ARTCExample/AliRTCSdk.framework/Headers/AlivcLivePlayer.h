//
//  AlivcLivePlayer.h
//  AlivcLivePusher
//
//  Created by aliyun on 2022/8/22.
//  Copyright © 2022 Alibaba. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <CoreImage/CoreImage.h>
#import "AlivcLiveCallback.h"
#import "AlivcLivePushConstants.h"


/**
 * @brief 直播连麦播放参数配置
 */
@interface AlivcLivePlayConfig : NSObject
/**
 * @brief 渲染模式
 * default：AlivcLivePlayRenderModeAuto
 */
@property (nonatomic) AlivcLivePlayRenderMode renderMode;

/**
 * @brief 播放是否镜像
 * default：false，非镜像
 */
@property (nonatomic, assign) BOOL mirror;

/**
 * @brief 旋转角度
 * default： AlivcLivePlayRotationMode_0
 */
@property (nonatomic, assign) AlivcLivePlayRotationMode rotationMode;

/**
 * @brief 直播播放模式，互动模式还是纯拉流模式
 * default: AlivcLiveBasicMode
 */
@property (nonatomic, assign) AlivcLiveMode liveMode;

@end

/**
 * @brief 互动直播模式下拉流类，暂只支持互动模式下的拉流URL
 */
@interface AlivcLivePlayer : NSObject

- (instancetype)initWithConfig:(AlivcLivePlayConfig *)config;

- (int)setPlayView:(NSView *)view;

- (int)startPlay:(NSString *)playURL;

- (int)stopPlay;

- (void)destroy;

- (int)setRemoteAudioVolume:(NSInteger)volume;

- (void)setLivePlayInfoDelegate:(id<AliLivePlayInfoDelegate>)delegate;

- (void)setLivePlayVideoFrameDelegate:(id<AlivcLiveVideoFrameDelegate>)delegate;

- (AlivcLiveMode)getMode;

- (int) setConfig:(AlivcLivePlayConfig *)config;

@property (nonatomic, assign) AlivcLiveMode liveMode;

@end

/** @} */
