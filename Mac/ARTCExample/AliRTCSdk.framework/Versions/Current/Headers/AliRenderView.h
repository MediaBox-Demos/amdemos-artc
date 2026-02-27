//
//  AliRenderView.h
//  AliRTCSdk
//
//  Created by lyz on 2021/2/23.
//  Copyright © 2021 Alibaba. All rights reserved.
//

#ifndef AliRenderView_h
#define AliRenderView_h


@interface AliRenderView : NSView

@property (nonatomic, assign, readonly) NSUInteger renderId;
@property (nonatomic, assign, readonly) BOOL enableOptimization;
@property (nonatomic, strong, readonly) NSView *engineDisplayView;

@end

#endif /* AliRenderView_h */
