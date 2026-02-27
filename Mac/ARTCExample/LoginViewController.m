//
//  LoginViewController.m
//  ARTCExample
//
//  Created by sunhui on 2025/11/13.
//

#import <Foundation/Foundation.h>
#import "AppDefine.h"
#import "LoginViewController.h"
#import "ScreenWindowShareController.h"
#import "JoinChannelAndTokenKey.h"
#import "VideoChatController.h"
#import "AudioChatController.h"


@interface LoginViewController (){
}

@property (nonatomic, strong)IBOutlet NSButton *    joinChannelButton ;
@property (nonatomic, strong)IBOutlet NSTextField * channelIDEdit ;
@property (nonatomic, strong)IBOutlet NSTextField * userIDEdit ;
@property (nonatomic, strong)IBOutlet NSTextField * userNameEdit ;
@property (nonatomic, strong)IBOutlet NSComboBox  * exampleTypeBox ;


@end

@implementation LoginViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view
    [_channelIDEdit setFocusRingType:NSFocusRingTypeNone];
    [_userIDEdit setFocusRingType:NSFocusRingTypeNone];
    
    [_exampleTypeBox addItemWithObjectValue:@"TokenAndJoinChannel"];
    [_exampleTypeBox addItemWithObjectValue:@"VideoChat"];
    [_exampleTypeBox addItemWithObjectValue:@"AudioChat"];
    [_exampleTypeBox addItemWithObjectValue:@"Screen/Window Share"];

    [_exampleTypeBox selectItemAtIndex:1];
}

- (void)dealloc {
    
}

- (IBAction)JoinChannelClickEvent:(id)sender {
    
    _LoginChannelID  = [_channelIDEdit stringValue];
    _LoginUserID = [_userIDEdit stringValue];
    _LoginUserName = [_userNameEdit stringValue];
    
    /*
     userid and channelid max size = 64
     */
    if ( _LoginChannelID == nil || [_LoginChannelID length] == 0 || [_LoginChannelID length] > 64 ||
        _LoginUserID == nil || [_LoginUserID length] == 0 || [_LoginUserID length] > 64 ||
        [_LoginUserName length] > 64  ) {
        
        [AppDefine showInfoAlertTitle:@"ERROR"
                                   message:@"ChannelID or UserID length is Invalid!"
                                mainWindow:[self.view window]];
        return ;
    }
        
    NSStoryboard *storyboard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
    NSInteger selectIndex = [_exampleTypeBox indexOfSelectedItem] ;
    switch ( selectIndex ) {
        case 0: {
            NSWindowController * wc = [storyboard instantiateControllerWithIdentifier:@"JoinchannelAndToken"];
            JoinChannelAndTokenKeyController * vc = (JoinChannelAndTokenKeyController *)[wc contentViewController];
            [vc setLoginInfo:_LoginChannelID userid:_LoginUserID userName:_LoginUserName];
            [wc showWindow:nil];
        }
            break ;
        case 1: {
            NSWindowController * wc = [storyboard instantiateControllerWithIdentifier:@"VideoChat"];
            VideoChatController * vc = (VideoChatController *)[wc contentViewController];
            [vc setLoginInfo:_LoginChannelID userid:_LoginUserID userName:_LoginUserName];
            [wc showWindow:nil];
        }
            break ;
        case 2: {
            NSWindowController * wc = [storyboard instantiateControllerWithIdentifier:@"AudioChat"];
            AudioChatController * vc = (AudioChatController *)[wc contentViewController];
            [vc setLoginInfo:_LoginChannelID userid:_LoginUserID userName:_LoginUserName];
            [wc showWindow:nil];
        }
            break ;
        case 3: {
            NSWindowController * wc = [storyboard instantiateControllerWithIdentifier:@"MainWindow"];
            ScreenWindowShareController * vc = (ScreenWindowShareController *)[wc contentViewController];
            [vc setLoginInfo:_LoginChannelID userid:_LoginUserID userName:_LoginUserName];
            [wc showWindow:nil];
        }
            break;
            
        case 4: {
            
        }
            break ;
            
            
        default:
            break;
    }
    
    [[[self view] window] close];
}

@end

