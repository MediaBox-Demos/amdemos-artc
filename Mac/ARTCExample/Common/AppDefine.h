//
//  Appdefine.h
//  ARTCExample
//
//  Created by sunhui on 2025/11/14.
//


#define ARTC_APP_ID "<RTC AppId>"
#define ARTC_APP_KEY "<RTC AppKey>"

#import <Cocoa/Cocoa.h>

@interface AppDefine : NSObject;


+ (NSString*_Nonnull)generateJoinToken:(NSString *_Nonnull)oc_str ;


+ (void)showInfoAlertTitle:(NSString *_Nonnull)title message:(NSString *_Nullable)message
                mainWindow:(NSWindow *_Nullable)window;


@end
