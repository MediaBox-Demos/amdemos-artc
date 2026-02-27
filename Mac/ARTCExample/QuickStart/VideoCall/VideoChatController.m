//
//  VideoChatController.m
//  ARTCExample
//
//  Created by sunhui on 2025/11/19.
//

#import "VideoChatController.h"
#import "AppDefine.h"

@interface VideoChatController ()<AliRtcEngineDelegate> {
    NSString * userId;
    NSString * channelId ;
    NSString * userName ;
}

@property (nonatomic, strong)IBOutlet NSButton *    leaveChannelButton ;
@property (nonatomic, strong)IBOutlet NSView *      localView ;

@property (nonatomic, strong)IBOutlet NSView *      remoteView ;
@property (nonatomic, strong)IBOutlet NSTextView *  statusListBox ;

@end

@implementation VideoChatController

- (void)viewDidLoad {
    [super viewDidLoad];
    _engine = [AliRtcEngine sharedInstance:self extras:nil] ;

    // Do view setup here.
    [_statusListBox setEditable:FALSE];
}

- (void)dealloc {
    [self leaveChannelButton:nil];
}

-(void)viewWillDisappear {
    [[NSApplication sharedApplication] terminate:nil];
}


-(IBAction)leaveChannelButton:(id)sender {
    if ( _engine == nil ) {
        return ;
    }
    
    [_engine stopPreview];
    [_engine leaveChannel] ;
    [AliRtcEngine destroy] ;
    _engine = nil ;
    
    [[[self view] window]close];
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
    canvas.renderMode = AliRtcRenderModeAuto;
    canvas.rotation = AliRtcRotationMode_0 ;
    [_engine setLocalViewConfig:canvas forTrack:AliRtcVideoTrackCamera];
    int ret = [_engine startPreview];
    if ( ret != 0 ) {
        
    }
    
    [_engine setDefaultSubscribeAllRemoteAudioStreams:TRUE] ;
    [_engine setDefaultSubscribeAllRemoteVideoStreams:TRUE] ;
  
    /*
     config audio profile and Scene
     */
    [_engine setAudioProfile:AliRtcEngineHighQualityMode audio_scene:AliRtcSceneMusicMode];


    /*
     config channel Profile and client Role
     */
    [_engine setChannelProfile:AliRtcInteractivelive];
    [_engine setClientRole:AliRtcClientRoleInteractive];
    
    [_engine publishLocalAudioStream:TRUE] ;
    [_engine publishLocalVideoStream:TRUE];
    /*
     config video encoder
     */
    AliRtcVideoEncoderConfiguration * videoConfig = [[AliRtcVideoEncoderConfiguration alloc]init];
    videoConfig.dimensions = CGSizeMake(1280, 720);
    videoConfig.bitrate = 1200;         // kbps
    videoConfig.frameRate = 15;
    videoConfig.keyFrameInterval = 2000;
    
    [_engine setVideoEncoderConfiguration:videoConfig];
    [_engine joinChannel:info name:userName onResult:^(NSInteger errCode, NSString * _Nonnull channel, NSInteger elapsed) {
        
        if( errCode != 0 && ![self->_engine isInCall] ){
            
        } else {
            
        }
        
    }];
    
    [_engine publishLocalDualStream:YES] ;
    
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

- (void)onAudioPublishStateChanged:(AliRtcPublishState)oldState
                          newState:(AliRtcPublishState)newState
              elapseSinceLastState:(NSInteger)elapseSinceLastState
                           channel:(NSString *_Nonnull)channel{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self statusListBoxAddString:[[NSString alloc]initWithFormat:@"audio stream state change:%ld->%ld",
                                        oldState, newState ]
                           withColor:[NSColor blueColor]];
    });
}

- (void)onVideoPublishStateChanged:(AliRtcPublishState)oldState
                          newState:(AliRtcPublishState)newState
              elapseSinceLastState:(NSInteger)elapseSinceLastState
                           channel:(NSString *_Nonnull)channel{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self statusListBoxAddString:[[NSString alloc]initWithFormat:@"video stream state change:%ld->%ld",
                                      oldState, newState ]
                           withColor:[NSColor blueColor]];
    });
}

- (void)onDualStreamPublishStateChanged:(AliRtcPublishState)oldState
                               newState:(AliRtcPublishState)newState
                   elapseSinceLastState:(NSInteger)elapseSinceLastState
                                channel:(NSString *_Nonnull)channel{
}

- (void)onScreenSharePublishStateChanged:(AliRtcPublishState)oldState
                                newState:(AliRtcPublishState)newState
                    elapseSinceLastState:(NSInteger)elapseSinceLastState
                                 channel:(NSString *_Nonnull)channel {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self statusListBoxAddString:[[NSString alloc]initWithFormat:
                                      @"screen share stream state change:%ld->%ld",
                                      oldState, newState ]
                           withColor:[NSColor blueColor]];
    });
    
}


- (void)onRemoteUserOnLineNotify:(NSString *)uid elapsed:(int)elapsed {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self statusListBoxAddString:[[NSString alloc]initWithFormat:@"uid:%@ online reason:%d",
                                      uid, elapsed]
                           withColor:[NSColor blueColor]];
    });
}

- (void)onRemoteUserOffLineNotify:(NSString *)userID
                    offlineReason:(AliRtcUserOfflineReason)reason{
    
    /* 删除对应的canvas */
    
    dispatch_async(dispatch_get_main_queue(), ^{
        /*
         This function is recommended to be called on the main thread
         */
        [self->_engine setRemoteViewConfig:nil uid:userID forTrack:AliRtcVideoTrackScreen];
        [self->_engine setRemoteViewConfig:nil uid:userID forTrack:AliRtcVideoTrackCamera];
        
        [self statusListBoxAddString:[[NSString alloc]initWithFormat:@"uid:%@ offline reason:%ld",
                                      userID, reason]
                           withColor:[NSColor blueColor]];
    });

}

- (void)onBye:(int)code {
    
}

- (void)onLocalDeviceException:(AliRtcLocalDeviceType)deviceType
                 exceptionType:(AliRtcLocalDeviceExceptionType)exceptionType
                       message:(NSString *_Nullable)msg {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        /* to main thread process */
        
    });
    
    
}


- (void)onRemoteTrackAvailableNotify:(NSString *)uid
                          audioTrack:(AliRtcAudioTrack)audioTrack
                          videoTrack:(AliRtcVideoTrack)videoTrack {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if ( videoTrack == AliRtcVideoTrackCamera ) {
            
            [self->_engine setRemoteViewConfig:nil uid:uid forTrack:AliRtcVideoTrackScreen];
            AliVideoCanvas * remoteCanvas = [[AliVideoCanvas alloc] init];
            remoteCanvas.view = self->_remoteView ;
            remoteCanvas.rotation = AliRtcRotationMode_0 ;
            remoteCanvas.renderMode = AliRtcRenderModeAuto;
            [self->_engine setRemoteViewConfig:remoteCanvas uid:uid forTrack:AliRtcVideoTrackCamera];
        }
        
        if ( videoTrack == AliRtcVideoTrackScreen ) {

            [self->_engine setRemoteViewConfig:nil uid:uid forTrack:AliRtcVideoTrackCamera];
            AliVideoCanvas * remoteCanvas = [[AliVideoCanvas alloc] init];
            
            remoteCanvas.view = self->_remoteView ;
            remoteCanvas.rotation = AliRtcRotationMode_0 ;
            
            /* 屏幕共享建议加黑边模式 */
            remoteCanvas.renderMode = AliRtcRenderModeFill ;
            
            [self->_engine setRemoteViewConfig:remoteCanvas uid:uid forTrack:AliRtcVideoTrackScreen];
        }
        
        if ( videoTrack == AliRtcVideoTrackNo ) {
            [self->_engine setRemoteViewConfig:nil uid:uid forTrack:AliRtcVideoTrackCamera];
            [self->_engine setRemoteViewConfig:nil uid:uid forTrack:AliRtcVideoTrackScreen];
        }
    });
    
}


@end
