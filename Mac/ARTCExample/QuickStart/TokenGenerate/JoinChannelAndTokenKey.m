//
//  JoinChannelAndTokenKey.m
//  ARTCExample
//
//  Created by sunhui on 2025/11/19.
//

#import <Foundation/Foundation.h>
#import "JoinChannelAndTokenKey.h"
#import "AppDefine.h"


@interface JoinChannelAndTokenKeyController () <AliRtcEngineDelegate>{
    NSString * userId;
    NSString * channelId ;
    NSString * userName ;
}

@property (nonatomic, strong)IBOutlet NSButton *    leaveChannelButton ;
@property (nonatomic, strong)IBOutlet NSView *      localView ;
@property (nonatomic, strong)IBOutlet NSTextView *  statusListBox ;

@end

@implementation JoinChannelAndTokenKeyController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    _engine = [AliRtcEngine sharedInstance:self extras:nil] ;
    [_statusListBox setEditable:FALSE];
}

- (void)dealloc {
    [AliRtcEngine destroy];
}

-(void)viewWillDisappear {
    [[NSApplication sharedApplication] terminate:nil];
}

- (IBAction)leaveChannelClickEvent:(id)sender  {
    [_engine leaveChannel];
    [[[self view] window] close];
}

- (void)setLoginInfo:(NSString *_Nonnull)channelId
              userid:(NSString *_Nonnull)userId
            userName:(NSString * _Nullable)userName {
    
    self->userId = userId ;
    self->channelId = channelId;
    uint64_t timestamp = time(NULL) + 24 * 60 * 60;
    
    
    AliRtcAuthInfo *info = [[AliRtcAuthInfo alloc]init];
    info.channelId = self->channelId;
    info.userId    = self->userId;
    info.appId     = @ARTC_APP_ID;
    info.nonce     = @"";
    info.timestamp = timestamp;
    
    NSString *token_str = [NSString stringWithFormat:@"%@%@%@%@%@%lld",
                           info.appId,
                           @ARTC_APP_KEY,
                           info.channelId,
                           info.userId,
                           @"",
                           info.timestamp];
    
    info.token = [AppDefine generateJoinToken:token_str];
    
    AliVideoCanvas * canvas = [[AliVideoCanvas alloc] init];
    canvas.view = _localView ;
    [self->_engine setLocalViewConfig:canvas forTrack:AliRtcVideoTrackCamera];
    
    [self->_engine joinChannel:info name:userName onResult:^(NSInteger errCode, NSString * _Nonnull channel, NSInteger elapsed) {
        
        if( errCode != 0 && ![self->_engine isInCall] ){
            
        } else {
            
        }
        
    }];
    
}

- (void)statusListBoxAddString:(NSString *)lineString withColor:(NSColor *)color {
    NSDictionary *attributes = @{
        NSFontAttributeName: [NSFont systemFontOfSize:11],
        NSForegroundColorAttributeName: color //[NSColor redColor]
    };
    NSAttributedString * NSAttriString = [[NSAttributedString alloc] initWithString:lineString attributes:attributes];
    [[_statusListBox textStorage] appendAttributedString:NSAttriString];
    NSAttributedString * nextLine = [[NSAttributedString alloc] initWithString:@"\n"];
    [[_statusListBox textStorage] appendAttributedString:nextLine];
}


#pragma mark - "Delegates of engine"

- (void)onJoinChannelResult:(int)result channel:(NSString *_Nonnull)channel elapsed:(int) elapsed {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self statusListBoxAddString:[[NSString alloc]initWithFormat:@"join channel ret=%d cid:%@ elapsed:%d",
                                      result, channel, elapsed ]
                           withColor:[NSColor redColor]];
    });
}

- (void)onLeaveChannelResult:(int)result stats:(AliRtcStats)stats {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self statusListBoxAddString:[[NSString alloc]initWithFormat:@"leave channel ret=%d call duration:%lld", result, stats.call_duration ]
                           withColor:[NSColor redColor]];
    });
}


@end

