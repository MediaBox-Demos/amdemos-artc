//
//  AudioChatController.m
//  ARTCExample
//
//  Created by sunhui on 2025/11/20.
//

#import "AudioChatController.h"
#import "AppDefine.h"
#import <UniformTypeIdentifiers/UTType.h>

@interface AudioChatController ()<AliRtcEngineDelegate>{
    NSString * userId;
    NSString * channelId ;
    NSString * userName ;
    AliRtcClientRole localClientRole ;
    bool       joinSucc;
    bool       inAccompanyPlaying; //
    int64_t    audioDuraionMs ;     // file durationMs
    NSString * accompanyURLString ;
    NSString * pushURLString ;
    NSTimer *  accompanyTimer ;
    
    //
    int        externStreamId ;
    int        externSampleRate ;
    int        externChannels ;
    NSThread * pcmInputThread ;
}

@property (nonatomic, strong)IBOutlet NSButton *    leaveChannelButton ;
@property (nonatomic, strong)IBOutlet NSTextView *  statusListBox ;
@property (nonatomic, strong)IBOutlet NSButton *    micModeButton;
@property (nonatomic, strong)IBOutlet NSButton *    openAccompanyFileButton;
@property (nonatomic, strong)IBOutlet NSButton *    startAccompanyFileButton;
@property (nonatomic, strong)IBOutlet NSButton *    stopAccompanyFileButton;
@property (nonatomic, strong)IBOutlet NSProgressIndicator *  localVolumeProgress;
@property (nonatomic, strong)IBOutlet NSProgressIndicator *  remoteVolumeProgress;
@property (nonatomic, strong)IBOutlet NSSlider            *  accompanyPositionSlider;
@property (nonatomic, strong)IBOutlet NSButton            *  enableLocalPlay;
@property (nonatomic, strong)IBOutlet NSButton            *  enableReplaceMic;
@property (nonatomic, strong)IBOutlet NSSlider            *  publishVolumeSlider;
@property (nonatomic, strong)IBOutlet NSTextField         *  publishVolumeLabel;

@property (nonatomic, strong)IBOutlet NSSlider            *  playVolumelider;
@property (nonatomic, strong)IBOutlet NSSlider            *  publishVolumelider;
@property (nonatomic, strong)IBOutlet NSTextField         *  accompanyDurationMsLabel;


@property (nonatomic, strong)IBOutlet NSTextField         *  pushAudioSampleRateEdit;
@property (nonatomic, strong)IBOutlet NSTextField         *  pushAudioChannelsEdit;
@property (nonatomic, strong)IBOutlet NSSlider            *  playExternVolumelider;
@property (nonatomic, strong)IBOutlet NSTextField         *  playExternVolumeLabel;
@property (nonatomic, strong)IBOutlet NSSlider            *  publishExternVolumelider;
@property (nonatomic, strong)IBOutlet NSTextField         *  publishExternVolumeLabel;

@end

@implementation AudioChatController


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

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    _engine = [AliRtcEngine sharedInstance:self extras:nil] ;

    // Do view setup here.
    [_statusListBox setEditable:FALSE];
    [_openAccompanyFileButton setEnabled:TRUE];
    [_startAccompanyFileButton setEnabled:FALSE];
    [_stopAccompanyFileButton setEnabled:FALSE];
    
    externStreamId = 0 ;

}

-(void)viewWillDisappear {
    [[NSApplication sharedApplication] terminate:nil];
}


- (void)dealloc {
    [accompanyTimer invalidate];
    accompanyTimer = nil ;
    [AliRtcEngine destroy];
}

-(IBAction)StartStopCapture:(id)sender {
    [_engine startAudioCapture] ;
}

-(IBAction)updateMicModeAction:(id)sender {
    
    AliRtcClientRole oldRole = localClientRole ;
    
    if ( localClientRole  == AliRtcClientRolelive ) {
        localClientRole = AliRtcClientRoleInteractive ;
    } else {
        localClientRole = AliRtcClientRolelive ;
    }
    /*
     wait for onUpdateRoleNotifyWithOldRole
     */
    [_micModeButton setEnabled:FALSE] ;

    int ret = [_engine setClientRole:localClientRole] ;
    if ( ret != 0 ) {
        localClientRole = oldRole ;
        [AppDefine showInfoAlertTitle:@"ERROR" message:@"Failed to change Role!" mainWindow:[self.view window]];
    }
    
    
}

-(IBAction)leaveChannelButtonAction:(id)sender {
    [_engine leaveChannel] ;
    [[[self view] window]close];
}

-(IBAction)stopAccompanyFileButtonAction:(id)sender {
    if ( !inAccompanyPlaying ) {
        return ;
    }
    
    [_engine stopAudioAccompany] ;
}

- (IBAction)getDurationAction:(NSButton *)sender {
    
    if ( inAccompanyPlaying ) {
        
        NSInteger durationMs = [self.engine getAudioAccompanyDuration];
        if (durationMs > 0) {
            audioDuraionMs = durationMs;
        }
 
    } else {
        
        
        [_accompanyDurationMsLabel setStringValue:@"00:00"] ;
        
        NSOpenPanel *openPanel = [NSOpenPanel openPanel];

        [openPanel setCanChooseFiles:YES];
        [openPanel setCanChooseDirectories:NO];
        [openPanel setAllowsMultipleSelection:NO];
                
        NSArray * contentTypes = @[[UTType typeWithFilenameExtension:@"wav"],
                                   [UTType typeWithFilenameExtension:@"mp3"]];
        
        [openPanel setAllowedContentTypes:contentTypes];
        
        [openPanel setTitle:@"Please select AudioFile wav/mp3!"];
        [openPanel beginWithCompletionHandler:^(NSModalResponse result) {
            
            if (result == NSModalResponseOK) {
                
                NSArray<NSURL *> *fileArray = [openPanel URLs];
                
                for (NSURL *filePath in fileArray) {
                    
                    NSLog(@"Use cancel selec: %@", filePath.path);
                    int ret = [self.engine getAudioFileInfo:filePath.path];

                    NSString * status_string ;
                    if (ret) {
                        status_string = [NSString stringWithFormat:@"Failed to GetFile Info:%d", ret];
                    } else {
                        status_string = [NSString stringWithFormat:@"GetFile Info ..."];
                    }
                    
                    self->accompanyURLString = filePath.path;
                    [self statusListBoxAddString:status_string withColor:[NSColor blueColor]];
                    
                    break ;
                }
                
                
            } else {
                NSLog(@"Use cancel select file!");
            }
        }];
    
    
    }
}

-(IBAction)startAccompanyFileButtonAction:(id)sender {
    
    AliRtcAudioAccompanyConfig * accConfig = [[AliRtcAudioAccompanyConfig alloc] init];
    
    accConfig.replaceMic = [[self enableReplaceMic] state] == YES ;
    accConfig.onlyLocalPlay = [[self enableLocalPlay] state] == YES ;
    accConfig.startPosMs = (double)audioDuraionMs * ( [_accompanyPositionSlider doubleValue] / 100.0 );
    accConfig.loopCycles = 1;
    accConfig.playoutVolume = [[self playVolumelider] intValue];
    accConfig.publishVolume = [[self publishVolumelider] intValue];
    
    [self->_engine startAudioAccompanyWithFile:accompanyURLString config:accConfig] ;
    
    // reset open button status
    [_openAccompanyFileButton setEnabled:FALSE] ;
    accompanyURLString = nil ;
    inAccompanyPlaying = true ;
    
    if ( accompanyTimer == nil ) {
        accompanyTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
    }
    
}

- (IBAction)publishPlayoutVolumeSliderAction:(NSSlider *)sender {
    
    int vol = [sender intValue] ;
    if (vol >400 || vol < 0 ) {
        vol = 100 ;
    }
    
    [ _publishVolumeLabel setIntValue:vol];
    [ _engine setRecordingVolume:vol];
    
}

- (IBAction)publishExternVolumeSliderAction:(NSSlider *)sender {
    
    int vol = [sender intValue] ;
    if (vol >100 || vol < 0 ) {
        vol = 100 ;
    }
    
    [ _publishExternVolumelider setIntValue:vol];
    [ _engine setExternalAudioVolume:vol];
    
}

- (IBAction)playoutExternVolumeSliderAction:(NSSlider *)sender {
    
    int vol = [sender intValue] ;
    if (vol >100 || vol < 0 ) {
        vol = 100 ;
    }
    
    [ _playExternVolumeLabel setIntValue:vol];
    [ _engine setExternalAudioRenderVolume:vol];
    
}

- (IBAction)playoutVolumeSliderAction:(NSSlider *)sender {
    if ( inAccompanyPlaying ) {
        [_engine setAudioAccompanyPlayoutVolume:[sender intValue]] ;
    }
}

- (IBAction)publishVolumeSliderAction:(NSSlider *)sender {
    if ( inAccompanyPlaying ) {
        [_engine setAudioAccompanyPublishVolume:[sender intValue]] ;
    }
}


- (IBAction)pushExternAudioFileStartAction:(id)sender {
    
    if ( pcmInputThread != nil ) {
        [pcmInputThread cancel] ;
        pcmInputThread = nil ;
    }
    
    int sampleRate = [_pushAudioSampleRateEdit intValue] ;
    int channels = [_pushAudioChannelsEdit intValue];
    if ( channels != 1 && channels != 2 ) {
        [AppDefine showInfoAlertTitle:@"ERROR" message:@"Channels is error!" mainWindow:[self.view window]];
        return ;
    }
    
    if ( sampleRate != 44100 && sampleRate != 48000 &&
        sampleRate != 32000 && sampleRate != 12000 &&
        sampleRate != 16000 && sampleRate != 8000 &&
        sampleRate != 24000 ) {
        [AppDefine showInfoAlertTitle:@"ERROR" message:@"SampleRate is error!" mainWindow:[self.view window]];
        return ;
    }
    
    externSampleRate = sampleRate ;
    externChannels = channels ;
    
    // - (int)addExternalAudioStream:(AliRtcExternalAudioStreamConfig *_Nonnull)config;

    AliRtcExternalAudioStreamConfig * streamConfig = [[AliRtcExternalAudioStreamConfig alloc] init];
    
    streamConfig.sampleRate = sampleRate ;
    streamConfig.channels = channels ;
    streamConfig.playoutVolume = [_playExternVolumelider intValue];
    streamConfig.publishStream = [_publishExternVolumelider intValue];

    externStreamId = [_engine addExternalAudioStream:streamConfig] ;
    if ( externStreamId < 0 ) {
        [AppDefine showInfoAlertTitle:@"ERROR" message:@"Failed to create Exernal Stream!" mainWindow:[self.view window]];
        return ;
    }
        
    
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];

    [openPanel setCanChooseFiles:YES];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setAllowsMultipleSelection:NO];
    NSArray * contentTypes = @[[UTType typeWithFilenameExtension:@"pcm"]];
    
    [openPanel setAllowedContentTypes:contentTypes];
    [openPanel setTitle:@"Please select pcm file"];
    [openPanel beginWithCompletionHandler:^(NSModalResponse result) {
        
        if (result == NSModalResponseOK) {
            
            NSArray<NSURL *> *urls = [openPanel URLs];
            
            for (NSURL *url in urls) {
                
                
                
                NSLog(@"Use cancel selec: %@", url.path);
                self->pushURLString = url.path;
                
                self->pcmInputThread  = [[NSThread alloc] initWithTarget:self selector:@selector(externPCMThreadProc) object:nil];
                [self->pcmInputThread start];
                
                
                break ;
            }
            
            
        } else {
            NSLog(@"Use cancel select file!");
        }
    }];

    
}

#pragma mark PCM/YUV输入代码

- (void)externPCMThreadProc {
    
    FILE * pcmFile = fopen( [pushURLString UTF8String], "rb") ;
    if ( pcmFile == nil ) {
        [AppDefine showInfoAlertTitle:@"ERROR" message:@"Failed to open pcm File!" mainWindow:[self.view window]];
        return ;
    }
    
    // read 10ms
    size_t blockSize = externSampleRate*externChannels*sizeof(int16_t) /100;
    int16_t * pcmBuffer = (int16_t *)malloc(blockSize) ;
    
    int retryCount = 0 ;
    
    while ( [pcmInputThread isCancelled] == false ) {
        
        ssize_t readSize = fread( pcmBuffer, 1, blockSize, pcmFile ) ;
        if ( readSize == 0 ) {
            fseek(pcmFile, 0, SEEK_SET ) ;
            continue;
        }else {
            
            if ( read < 0 ) {
                // error!
                break ;
            }
            
            if ( readSize < blockSize ) {
                memset( pcmBuffer+readSize, 0 , blockSize-readSize ) ;
            }
        }
        
        AliRtcAudioFrame * audioFrame = [[AliRtcAudioFrame alloc] init];
        audioFrame.dataPtr = pcmBuffer;
        audioFrame.numOfSamples = (int)(readSize / sizeof(int16_t));
        audioFrame.samplesPerSec = externSampleRate ;
        audioFrame.numOfChannels = externChannels ;
        audioFrame.bytesPerSample = sizeof(int16_t);
        
       int ret = [_engine pushExternalAudioStream:externStreamId rawData:audioFrame] ;
                
        if ( ret == AliRtcErrAudioBufferFull ) {
            [NSThread sleepForTimeInterval:0.020 ];
            
            ++retryCount ;
            
            if ( retryCount > 100 ) {
                break ;
            }
            
        } else {
            
            retryCount = 0;
            
            if ( ret < 0 ) {
                break ;
            }
            
        }
        
        
    }
    
    fclose(pcmFile);
    free(pcmBuffer);
    
}


- (IBAction)pushExternAudioFileSopAction:(id)sender {
    
    if ( pcmInputThread == nil ) {
        return ;
    }
    
    [pcmInputThread cancel] ;
    pcmInputThread = nil ;
    
    [_engine removeExternalAudioStream:externStreamId] ;
    externStreamId = -1 ;
    
}

- (void)timerAction {
    
    if ( inAccompanyPlaying ) {
        NSInteger pos = [self.engine getAudioAccompanyCurrentPosition];
        NSInteger all_duration = [self.engine getAudioAccompanyDuration] ;
        [_accompanyPositionSlider setDoubleValue: (double)pos*100.0/(double)all_duration ];
    }
    
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
    
    /*
     disable local video
    */
    [self->_engine enableLocalVideo:FALSE];
    [self->_engine setDefaultSubscribeAllRemoteAudioStreams:TRUE] ;
    [self->_engine setDefaultSubscribeAllRemoteVideoStreams:FALSE] ;
  
    /*
     config audio profile and Scene
     */
    [self->_engine setAudioProfile:AliRtcEngineHighQualityMode audio_scene:AliRtcSceneMusicMode];
    

    /*
     config channel Profile and client Role
     */
    [self->_engine setChannelProfile:AliRtcInteractivelive];
    [self->_engine setClientRole:AliRtcClientRolelive];
    localClientRole = AliRtcClientRolelive;
    
    /*
     enable audio volume monitor
     */
    [self->_engine enableAudioVolumeIndication:200 smooth:3 reportVad:0];
    
    [self->_stopAccompanyFileButton setEnabled:FALSE] ;
    
    [self->_engine joinChannel:info name:userName onResult:^(NSInteger errCode, NSString * _Nonnull channel, NSInteger elapsed) {
        
        if( errCode != 0 && ![self->_engine isInCall] ){
            
        } else {
            
        }
        
    }];
    
}



#pragma mark - "Delegates of engine"

- (void)onJoinChannelResult:(int)result channel:(NSString *_Nonnull)channel elapsed:(int) elapsed {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self statusListBoxAddString:[[NSString alloc]initWithFormat:@"join channel ret=%d cid:%@ elapsed:%d",
                                      result, channel, elapsed ]
                           withColor:[NSColor redColor]];
        
        if ( result == 0 ) {
            self->joinSucc = true ;
        }
    });
}

- (void)onLeaveChannelResult:(int)result stats:(AliRtcStats)stats {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self statusListBoxAddString:[[NSString alloc]initWithFormat:@"leave channel ret=%d call duration:%lld", result, stats.call_duration ]
                           withColor:[NSColor redColor]];
    });
}

- (void)onUpdateRoleNotifyWithOldRole:(AliRtcClientRole)oldRole newRole:(AliRtcClientRole)newRole {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self statusListBoxAddString:[[NSString alloc]initWithFormat:@"role state change:%ld->%ld",
                                      oldRole, newRole ]
                           withColor:[NSColor redColor]];
        
        self->localClientRole = newRole ;

        if ( newRole == AliRtcClientRolelive ) {
            [self->_micModeButton setTitle:@"Enable Mic"] ;
        } else {
            [self->_micModeButton setTitle:@"Disable Mic"] ;
        }
        
        [self->_micModeButton setEnabled:TRUE];
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



- (void)onDualStreamPublishStateChanged:(AliRtcPublishState)oldState
                               newState:(AliRtcPublishState)newState
                   elapseSinceLastState:(NSInteger)elapseSinceLastState
                                channel:(NSString *_Nonnull)channel{
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
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self statusListBoxAddString:[[NSString alloc]initWithFormat:@"uid:%@ offline reason:%ld",
                                      userID, reason]
                           withColor:[NSColor blueColor]];
    });

}

- (void)onAudioFileInfo:(AliRtcAudioFileInfo* _Nonnull)info
              errorCode:(AliRtcAudioAccompanyErrorCode)errorCode {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self statusListBoxAddString:[[NSString alloc]initWithFormat:
                                      @"Accompany File Info:%ld ms",info.durationMs]
                           withColor:[NSColor blueColor]];
        
        NSString * durationString = [[NSString alloc] initWithFormat:@"%.2ld:%.2ld",
                                     info.durationMs/(1000*60), (info.durationMs % (1000*60))/1000 ];
        
        [self->_accompanyDurationMsLabel setStringValue:durationString] ;

        self->audioDuraionMs = info.durationMs ;
        [self->_startAccompanyFileButton setEnabled:TRUE] ;
        
    });
    
}

- (void)onAudioAccompanyStateChanged:(AliRtcAudioAccompanyStateCode)playState errorCode:(AliRtcAudioAccompanyErrorCode)errorCode {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self statusListBoxAddString:[[NSString alloc]initWithFormat:@"Accompany state:%ld  errCode:%ld",
                                      playState, errorCode]
                           withColor:[NSColor blueColor]];
        
        if ( errorCode != 0 || playState == AliRtcAudioAccompanyEnded ||
            playState == AliRtcAudioAccompanyFailed || playState ==  AliRtcAudioAccompanyStopped ) {
            [self->_startAccompanyFileButton setEnabled:TRUE] ;
            self->inAccompanyPlaying = false ;
            [self->_openAccompanyFileButton setEnabled:TRUE] ;
        }
        
        if ( playState == AliRtcAudioAccompanyStarted ) {
            [self->_stopAccompanyFileButton setEnabled:TRUE] ;
            [self->_startAccompanyFileButton setEnabled:FALSE] ;
        } else
        {
            [self->_stopAccompanyFileButton setEnabled:TRUE] ;
        }
        
    });
}


- (void)onAudioVolumeCallback:(NSArray <AliRtcUserVolumeInfo *> *_Nullable)array
                  totalVolume:(int)totalVolume {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if ( array == nil ) return;
        
        for (AliRtcUserVolumeInfo * volumeInfo in array) {
            
            /*
             "0" is local "1" is mix remote vol
            */
            
            if ( [volumeInfo.uid  isEqual: @"0"] ) {
                [self->_localVolumeProgress setDoubleValue:volumeInfo.volume];
            } else {
                if ( [volumeInfo.uid  isEqual: @"1"] ) {
                    [self->_remoteVolumeProgress setDoubleValue:volumeInfo.volume];
                }
            }
            
        }
        
    });
}




@end
