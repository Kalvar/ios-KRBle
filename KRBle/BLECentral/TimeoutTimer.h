//
//  TimeoutTimer.h
//  KRBle
//  V1.2
//
//  Created by Kalvar Lin on 2014/4/27.
//  Copyright (c) 2014年 Kalvar Lin. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^FiredEventCompletion)(void);

@interface TimeoutTimer : NSObject

@property (nonatomic, copy) FiredEventCompletion firedEventCompletion;
@property (nonatomic, assign) BOOL isValid;


#pragma --mark Public Methods
+(instancetype)sharedInstance;
-(instancetype)init;
-(void)startTimeout:(CGFloat)_timeout eventHandler:(FiredEventCompletion)_eventHandler;
-(void)startTimeout:(CGFloat)_timeout;
-(void)stop;

#pragma --mark Time Calculate Methods
-(BOOL)differPassSeconds:(CGFloat)_seconds;
-(void)removeDifferPass;

#pragma --mark Blocks
-(void)setFiredEventCompletion:(FiredEventCompletion)_theFiredEventCompletion;

@end
