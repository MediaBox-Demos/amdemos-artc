//
//  SampleHandler.m
//  ScreenShareExtension
//
//  Created by wy on 2025/7/24.
//


#import "SampleHandler.h"
#import <AliScreenShare/AliScreenShareExt.h>

static NSString * _Nonnull kAppGroup = @"group.com.aliyun.video"; // 屏幕共享主app和插件的AppGroup

@interface SampleHandler() <AliScreenShareExtDelegate>

@property (nonatomic, assign) int32_t frameNum;

@end

@implementation SampleHandler

- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo {
    // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
    NSLog(@"SampleHandler SEND broadcastStartedWithSetupInfo");
    [[AliScreenShareExt sharedInstance] setupWithAppGroup:kAppGroup delegate:self];
}

- (void)broadcastPaused {
    // User has requested to pause the broadcast. Samples will stop being delivered.
    NSLog(@"SampleHandler SEND broadcastPaused");
}

- (void)broadcastResumed {
    // User has requested to resume the broadcast. Samples delivery will resume.
    NSLog(@"SampleHandler SEND broadcastResumed");
}

- (void)broadcastFinished {
    // User has requested to finish the broadcast.
    NSLog(@"SampleHandler SEND broadcastFinished");
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
    @autoreleasepool {
        [[AliScreenShareExt sharedInstance] sendSampleBuffer:sampleBuffer type:sampleBufferType];
    }
}

#pragma mark - AliScreenShareExtDelegate
- (void)finishBroadcastWithError:(AliScreenShareExt *)broadcast error:(NSError *)error
{
  [self finishBroadcastWithError:error];
}


@end
