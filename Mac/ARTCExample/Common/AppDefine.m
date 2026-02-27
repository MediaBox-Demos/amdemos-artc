//
//  AppDefine.m
//  ARTCExample
//
//  Created by sunhui on 2025/11/14.
//
#import "AppDefine.h"
#include <stdint.h>

#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>

@implementation AppDefine

+ (NSString *)stringFromBytes:(uint8_t *)bytes length:(int)length {
    
    NSMutableString *strArray = [NSMutableString string];

    for (int i = 0; i < length; i++) {
        [strArray appendFormat:@"%02x", bytes[i]];
    }

    return [strArray copy];
}

+(NSString*)generateJoinToken:(NSString *)oc_str {

    const char * cstring = [oc_str UTF8String];
    size_t length = [oc_str length] ;
    uint8_t sha256_buffer[CC_SHA256_DIGEST_LENGTH];
    
    CC_SHA256(cstring, (CC_LONG)length, sha256_buffer);
    
    return [AppDefine stringFromBytes:sha256_buffer length:CC_SHA256_DIGEST_LENGTH];
}

+ (void)showInfoAlertTitle:(NSString *_Nonnull)title
                   message:(NSString *_Nullable)message
                mainWindow:(NSWindow *)window {

    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSAlert *alert = [[NSAlert alloc] init];
        
        [alert setMessageText:title];
        [alert setInformativeText:message];
        [alert setAlertStyle:NSAlertStyleInformational];
  
        if ( window != nil ) {
            
            [alert beginSheetModalForWindow:window
                          completionHandler:^(NSModalResponse returnCode) {
            }];
            
        } else {
            [alert runModal];
        }
    });
    
}


@end
