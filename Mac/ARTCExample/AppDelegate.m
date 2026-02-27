//
//  AppDelegate.m
//  ARTCExample
//
//  Created by sunhui on 2025/11/13.
//

#import "AppDelegate.h"
#import "LoginViewController.h"
#import "PrivacyAuthorizer.h"

@interface AppDelegate () {
    LoginViewController * loginViewController ;
}


@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    //检测权限
    [PrivacyAuthorizer authorCamera:^(BOOL granted) {
        
        if (!granted) {
            NSLog(@"Camera_granted == %hhd",granted);
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setMessageText:@"未开启摄像头权限,请在<安全与隐私>里开启"];
                [alert setAlertStyle:NSAlertStyleInformational];
                [alert beginSheetModalForWindow:[self->loginViewController.view window] completionHandler:^(NSModalResponse returnCode) {
                }];
            });
        }
        
    }];
    
    [PrivacyAuthorizer authorMicphone:^(BOOL granted) {
        
        if (!granted) {
            
            NSLog(@"Camera_granted == %hhd",granted);
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setMessageText:@"未开启麦克风权限,请在<安全与隐私>里开启"];
                [alert setAlertStyle:NSAlertStyleInformational];
                [alert beginSheetModalForWindow:[self->loginViewController.view window] completionHandler:^(NSModalResponse returnCode) {
                    
                }];
            });
        }
    }];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}


@end
