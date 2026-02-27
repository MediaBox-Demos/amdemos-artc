//
//  PrivacyAuthorizer.h
//  Tutorial
//
//  Created by 高宇 on 2020/2/24.
//  Copyright © 2020 tiantian. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PrivacyAuthorizer : NSObject

+ (void)authorCamera:(void (^ __nullable)(BOOL granted))completion;

+ (void)authorMicphone:(void (^ __nullable)(BOOL granted))completion;

@end

NS_ASSUME_NONNULL_END
