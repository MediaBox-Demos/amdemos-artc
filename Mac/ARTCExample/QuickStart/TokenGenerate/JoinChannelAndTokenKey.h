//
//  JoinChannelAndTokenKey.h
//  ARTCExample
//
//  Created by sunhui on 2025/11/19.
//

#import <Cocoa/Cocoa.h>
#import <AliRTCSdk/AliRTCSdk.h>

@interface JoinChannelAndTokenKeyController : NSViewController;

@property (nonatomic, strong, nullable) AliRtcEngine *engine;

- (void)setLoginInfo:(NSString *_Nonnull)channelId userid:(NSString *_Nonnull)userId userName:(NSString * _Nullable)userName ;

@end
