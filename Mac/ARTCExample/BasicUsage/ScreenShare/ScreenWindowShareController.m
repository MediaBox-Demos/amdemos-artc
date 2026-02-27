//
//  ViewController.m
//  ARTCExample
//
//  Created by sunhui on 2025/11/13.
//

#import "ScreenWindowShareController.h"
#import "LoginViewController.h"
#import "AppDefine.h"


@interface ScreenWindowShareController () <AliRtcEngineDelegate, NSComboBoxDelegate>{
    NSString * userId;
    NSString * channelId ;
    NSString * userName ;
    bool       inCaptureScreen;
}

@property (nonatomic, strong)IBOutlet NSButton *    startScreenShareButton ;
@property (nonatomic, strong)IBOutlet NSTextField * screenShareRegionX ;
@property (nonatomic, strong)IBOutlet NSTextField * screenShareRegionY ;
@property (nonatomic, strong)IBOutlet NSTextField * screenShareRegionWidth ;
@property (nonatomic, strong)IBOutlet NSTextField * screenShareRegionHeight ;
@property (nonatomic, strong)IBOutlet NSView *      localView ;
@property (nonatomic, strong)IBOutlet NSView *      remoteView ;
@property (nonatomic, strong)IBOutlet NSButton *    screenShareUseRegionButton;
@property (nonatomic, strong)IBOutlet NSComboBox *  screenShareTypeBox;
@property (nonatomic, strong)IBOutlet NSComboBox *  screenShareSourceBox;

@property (nonatomic, strong)IBOutlet NSTextView *  statusListBox ;

@end

@implementation ScreenWindowShareController

- (void)setLoginInfo:(NSString *_Nonnull)channelId userid:(NSString *_Nonnull)userId userName:(NSString * _Nullable)userName {
    
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

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    _engine = [AliRtcEngine sharedInstance:self extras:nil] ;
    
    [_screenShareRegionX setFocusRingType:NSFocusRingTypeNone];
    [_screenShareRegionY setFocusRingType:NSFocusRingTypeNone];
    [_screenShareRegionWidth setFocusRingType:NSFocusRingTypeNone];
    [_screenShareRegionHeight setFocusRingType:NSFocusRingTypeNone];
    _screenShareTypeBox.delegate = self ;
    [_screenShareTypeBox selectItemAtIndex:0];
    [_screenShareUseRegionButton setState:NO];
    [self setupScreenSourceList:AliRtcScreenShareDesktop];
    [_statusListBox setEditable:FALSE];
    // Do any additional setup after loading the view.
}

- (void)dealloc {
    [AliRtcEngine destroy];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    // Update the view, if already loaded.
}


- (AliRtcScreenSourceInfo *)infoWithSelectString:(NSString *)selectString inArray:(NSArray <AliRtcScreenSourceInfo *>*)array{
    
    for (AliRtcScreenSourceInfo *info in array) {
        // find id
        NSArray *stringArray = [selectString componentsSeparatedByString:@"+"];
        if (stringArray.count > 1) {
            NSString *souceIDString = stringArray[1];
            if ([info.sourceId isEqualToString:souceIDString]) {
                return info;
            }
        }
    }
    
    return nil;
}


- (IBAction)StartScreenShareClickEvent:(id)sender {
    
    if ( inCaptureScreen ) {
        
        [_engine stopScreenShare] ;
        [_startScreenShareButton setTitle:@"Start ScreenShare"] ;
        
        [self->_engine setLocalViewConfig:nil forTrack:AliRtcVideoTrackScreen];

        AliVideoCanvas * canvas = [[AliVideoCanvas alloc] init];
        canvas.view = _localView ;
        [self->_engine setLocalViewConfig:canvas forTrack:AliRtcVideoTrackCamera];
        
        inCaptureScreen = false;
        return ;
    }
    
    AliRtcScreenShareConfig * shareConfig = [[AliRtcScreenShareConfig alloc]init];
    
    //
    // desktop share !
    //
    if ( [_screenShareTypeBox indexOfSelectedItem] == 0 ) {
        
        NSArray<AliRtcScreenSourceInfo *> *  sourceList = [self->_engine getScreenShareSourceInfoWithType:AliRtcScreenShareDesktop];

        AliRtcScreenSourceInfo * info = [self infoWithSelectString:[_screenShareSourceBox stringValue] inArray:sourceList];
        if ( info == nil ) {
            [AppDefine showInfoAlertTitle:@"ScreenShare" message:@"select desktop invalid!" mainWindow:[[self view] window]] ;
            return ;
        }
        
        if ([_screenShareUseRegionButton state] == YES ) {
            
            shareConfig.isShareByRegion = true;
            
            AliRtcScreenShareRegion * region = [[AliRtcScreenShareRegion alloc]init];
            region.width = [_screenShareRegionWidth intValue];
            region.height = [_screenShareRegionHeight intValue];
            region.originX = [_screenShareRegionX intValue];
            region.originY = [_screenShareRegionY intValue];
            
            [shareConfig setShareRegion:region];
            
        } else {
            shareConfig.isShareByRegion = false ;
        }
        
        int idValue = [info.sourceId intValue];
        
        [_engine setLocalViewConfig:nil forTrack:AliRtcVideoTrackCamera] ;

        AliVideoCanvas * localCanvas = [[AliVideoCanvas alloc] init];
        localCanvas.view = self->_localView ;
        [_engine setLocalViewConfig:localCanvas forTrack:AliRtcVideoTrackScreen] ;
        
        int ret = [_engine startScreenShareWithDesktopId:idValue config:shareConfig] ;
        if ( ret != 0 ) {
            [AppDefine showInfoAlertTitle:@"ScreenShare" message:@"Failed to start screenshare!" mainWindow:[[self view] window]] ;
        }
        else {
            inCaptureScreen = true ;
        }
        
    } else {
        
        NSArray<AliRtcScreenSourceInfo *> *  sourceList = [self->_engine getScreenShareSourceInfoWithType:AliRtcScreenShareWindow];

        AliRtcScreenSourceInfo * info = [self infoWithSelectString:[_screenShareSourceBox stringValue] inArray:sourceList];
        if ( info == nil ) {
            [AppDefine showInfoAlertTitle:@"ScreenShare" message:@"select desktop invalid!" mainWindow:[[self view] window]] ;
            return ;
        }
        
        if ([_screenShareUseRegionButton state] == YES ) {
            
            shareConfig.isShareByRegion = true;
            
            AliRtcScreenShareRegion * region = [[AliRtcScreenShareRegion alloc]init];
            region.width = [_screenShareRegionWidth intValue];
            region.height = [_screenShareRegionHeight intValue];
            region.originX = [_screenShareRegionX intValue];
            region.originY = [_screenShareRegionY intValue];
            
            [shareConfig setShareRegion:region];
            
        } else {
            shareConfig.isShareByRegion = false ;
        }
        
        int idValue = [info.sourceId intValue];
        
        [_engine setLocalViewConfig:nil forTrack:AliRtcVideoTrackCamera] ;

        AliVideoCanvas * localCanvas = [[AliVideoCanvas alloc] init];
        localCanvas.view = self->_localView ;
        [_engine setLocalViewConfig:localCanvas forTrack:AliRtcVideoTrackScreen] ;
        
        int ret = [_engine startScreenShareWithWindowId:idValue config:shareConfig] ;
        if ( ret != 0 ) {
            [AppDefine showInfoAlertTitle:@"ScreenShare" message:@"Failed to start screenshare!" mainWindow:[[self view] window]] ;
        }
        else {
            inCaptureScreen = true ;
        }
    }
    
    if ( inCaptureScreen ) {
        [_startScreenShareButton setTitle:@"Stop ScreenScreen"];
    }
   
}

-(void)viewWillDisappear {
    [[NSApplication sharedApplication] terminate:nil];
}



-(void)setupScreenSourceList:(AliRtcScreenShareType)shareType {
    
    [_screenShareSourceBox removeAllItems];
    
    NSArray<AliRtcScreenSourceInfo *> *  sourceList = [self->_engine getScreenShareSourceInfoWithType:shareType];
    if ( sourceList != nil ) {
                
        for(AliRtcScreenSourceInfo * info in sourceList ) {
            NSString *showString = [NSString stringWithFormat:@"%@+%@",info.sourceName,info.sourceId];
            [_screenShareSourceBox addItemWithObjectValue:showString];
        }
        
        if ([sourceList count] > 0  ) {
            [_screenShareSourceBox selectItemAtIndex:0];
        }
    }
    
   
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


#pragma mark - "NSComboBoxDelegate"

- (void)comboBoxSelectionDidChange:(NSNotification *)notification {
    AliRtcScreenShareType shareType = (AliRtcScreenShareType)[_screenShareTypeBox indexOfSelectedItem];
    [self setupScreenSourceList:shareType];
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
        [self statusListBoxAddString:[[NSString alloc]initWithFormat:@"screen share stream state change:%ld->%ld",
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

- (void)onRemoteTrackAvailableNotify:(NSString *)uid
                          audioTrack:(AliRtcAudioTrack)audioTrack
                          videoTrack:(AliRtcVideoTrack)videoTrack {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if ( videoTrack == AliRtcVideoTrackCamera ) {
            
            [self->_engine setRemoteViewConfig:nil uid:uid forTrack:AliRtcVideoTrackScreen];
            AliVideoCanvas * remoteCanvas = [[AliVideoCanvas alloc] init];
            remoteCanvas.view = self->_remoteView ;
            [self->_engine setRemoteViewConfig:remoteCanvas uid:uid forTrack:AliRtcVideoTrackCamera];
        }
        
        if ( videoTrack == AliRtcVideoTrackScreen ) {

            [self->_engine setRemoteViewConfig:nil uid:uid forTrack:AliRtcVideoTrackCamera];
            AliVideoCanvas * remoteCanvas = [[AliVideoCanvas alloc] init];
            remoteCanvas.view = self->_remoteView ;
            [self->_engine setRemoteViewConfig:remoteCanvas uid:uid forTrack:AliRtcVideoTrackScreen];
        }
        
    });
    
}

@end
