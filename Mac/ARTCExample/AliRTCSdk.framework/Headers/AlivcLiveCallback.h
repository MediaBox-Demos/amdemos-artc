//
//  AlivcLiveCallback.h
//  AliRTCSdk
//
//  Created by chengrenjun on 2023/4/6.
//  Copyright © 2023 Alibaba. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <CoreImage/CoreImage.h>
#import "AlivcLivePushConstants.h"



@interface AlivcLivePlayerStatsInfo : NSObject

#pragma mark - system
/**
 用户ID
 */
@property (nonatomic, copy) NSString * _Nonnull userId;
/**
 用户ID
 */
@property (nonatomic, copy) NSString * _Nonnull channelId;
/**
 视频宽度
 */
@property(nonatomic, assign) int videoWidth;

/**
 视频高度
 */
@property(nonatomic, assign) int videoHeight;

/**
 视频解码FPS
 * 单位 : Frames per Second
 */
@property (nonatomic, assign) int decodeFps;

/**
 视频渲染FPS
 * 单位 : Frames per Second
 */
@property (nonatomic, assign) int renderFps;

/**
 视频码率（当前视频码率是所有接收的总码率）
 * Kbps
 */
@property (nonatomic, assign) int videoBitrate;


/**
 音频码率
 * Kbps
 */
@property (nonatomic, assign) int audioBitrate;


/**
 音频丢包率
 * %
 */
@property (nonatomic, assign) int audioLossRate;;

/**
 丢包率 (网络丢包率)
 * %
 */
@property (nonatomic, assign) int lossRate;


@end


@interface AlivcLiveVideoDataSample : NSObject

@property (nonatomic, assign) AlivcLiveVideoFormat format;
@property (nonatomic, assign) AlivcLiveBufferType type;
@property (nonatomic, assign) CVPixelBufferRef _Nullable pixelBuffer;
@property (nonatomic, assign) long dataPtr;
@property (nonatomic, assign) long dataLength;
@property (nonatomic, assign) int strideY;
@property (nonatomic, assign) int strideU;
@property (nonatomic, assign) int strideV;
@property (nonatomic, assign) int height;
@property (nonatomic, assign) int width;
@property (nonatomic, assign) int rotation;
@property (nonatomic, assign) long long timeStamp;

@end


@class AlivcLivePusher;
@class AlivcLivePlayer;


#pragma mark - PlayerInfo回调
/**
 * @defgroup AliLivePlayerDelegate 直播连麦播放回调
 *  直播连麦播放回调
 *  @{
 */
@protocol AliLivePlayInfoDelegate <NSObject>

@optional

/**
 * @brief 播放错误回调
 * @param player 连麦播放引擎对象
 * @param code 错误码 {@link AlivcLivePlayerError }
 * @param msg 错误信息
 */
- (void)onError:(AlivcLivePlayer *_Nonnull)player code:(AlivcLivePlayerError)code message:(NSString *_Nonnull)msg;

/**
 * @brief 开始播放回调
 * @param player 连麦播放引擎对象
 */
- (void)onPlayStarted:(AlivcLivePlayer *_Nonnull)player;

/**
 * @brief 结束播放回调
 * @param player 连麦播放引擎对象
 */
- (void)onPlayStoped:(AlivcLivePlayer *_Nonnull)player;

/**
 * @brief 视频首帧渲染回调
 * @param player 连麦播放引擎对象
 */
- (void)onFirstVideoFrameDrawn:(AlivcLivePlayer*_Nonnull)player;
/**
 * @brief 网络质量变化时发出的消息
 * @param player 连麦播放引擎对象
 * @param quality  网络质量
 * @note 当对端网络质量发生变化时触发
 */
- (void)onNetworkQualityChanged:(AlivcLivePlayer*_Nonnull)player quality: (AlivcLiveNetworkQuality)quality;

/**
 * @brief 播放统计数据回调
 * @param player 连麦播放引擎对象
 * @param statistics 统计数据
 * @note statistics中的videoBitrate是总的视频接收码率
 */
- (void)onPlayerStatistics:(AlivcLivePlayer *_Nonnull)player statsInfo:(AlivcLivePlayerStatsInfo*_Nonnull)statistics;

@end

#pragma mark - 视频帧回调

@protocol AlivcLiveVideoFrameDelegate <NSObject>

@optional

- (bool)onCaptureVideoSample:(AlivcLivePusher *_Nonnull)player videoSource:(AlivcLiveVideoSource)videoSource videoData:(AlivcLiveVideoDataSample *_Nonnull)videoData;

- (bool)onRemoteVideoSample:(AlivcLivePlayer *_Nonnull)player videoSource:(AlivcLiveVideoSource)videoSource videoData:(AlivcLiveVideoDataSample *_Nonnull)videoData;

@end
