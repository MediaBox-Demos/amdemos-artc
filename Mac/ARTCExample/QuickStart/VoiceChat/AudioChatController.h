//
//  AudioChatController.h
//  ARTCExample
//
//  Created by sunhui on 2025/11/20.
//

#import <Cocoa/Cocoa.h>
#import <AliRTCSdk/AliRTCSdk.h>

NS_ASSUME_NONNULL_BEGIN

@interface AudioChatController : NSViewController

@property (nonatomic, strong, nullable) AliRtcEngine *engine;

- (void)setLoginInfo:(NSString *_Nonnull)channelId
              userid:(NSString *_Nonnull)userId
            userName:(NSString * _Nullable)userName ;


@end

NS_ASSUME_NONNULL_END
