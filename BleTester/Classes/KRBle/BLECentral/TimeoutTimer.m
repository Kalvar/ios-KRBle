//
//  TimeoutTimer.m
//  KRBle
//  V1.2
//
//  Created by Kalvar on 2014/4/27.
//  Copyright (c) 2014年 Kalvar. All rights reserved.
//

#import "TimeoutTimer.h"

static NSString *_kTimeoutTimerDifferDateKey = @"_kTimeoutTimerDifferDateKey";

@interface TimeoutTimer ()

@property (nonatomic, strong) NSTimer *_timer;

@end

@implementation TimeoutTimer (fixNSDefaults)

#pragma --mark Gets NSDefault Values
/*
 * @ 取出萬用型態
 */
-(id)_defaultValueForKey:(NSString *)_key
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:_key];
}

/*
 * @ 取出 String
 */
-(NSString *)_defaultStringValueForKey:(NSString *)_key
{
    return [NSString stringWithFormat:@"%@", [self _defaultValueForKey:_key]];
}

/*
 * @ 取出 BOOL
 */
-(BOOL)_defaultBoolValueForKey:(NSString *)_key
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:_key];
}

#pragma --mark Saves NSDefault Values
/*
 * @ 儲存萬用型態
 */
-(void)_saveDefaultValue:(id)_value forKey:(NSString *)_forKey
{
    [[NSUserDefaults standardUserDefaults] setObject:_value forKey:_forKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/*
 * @ 儲存 String
 */
-(void)_saveDefaultValueForString:(NSString *)_value forKey:(NSString *)_forKey
{
    [self _saveDefaultValue:_value forKey:_forKey];
}

/*
 * @ 儲存 BOOL
 */
-(void)_saveDefaultValueForBool:(BOOL)_value forKey:(NSString *)_forKey
{
    [self _saveDefaultValue:[NSNumber numberWithBool:_value] forKey:_forKey];
}

#pragma --mark Removes NSDefault Values
-(void)_removeDefaultValueForKey:(NSString *)_key
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:_key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end

@implementation TimeoutTimer (fixTimers)

-(void)_timeoutEvent
{
    if( self.firedEventCompletion )
    {
        self.firedEventCompletion();
    }
}

-(void)_startTimerWithTimeout:(CGFloat)_timeout
{
    [self _stopTimer];
    if( !self._timer )
    {
        self._timer = [NSTimer scheduledTimerWithTimeInterval:_timeout
                                                       target:self
                                                     selector:@selector(_timeoutEvent)
                                                     userInfo:nil
                                                      repeats:NO];
    }
}

-(void)_stopTimer
{
    if( self._timer )
    {
        if( self._timer.isValid )
        {
            [self._timer invalidate];
        }
        self._timer = nil;
    }
}

@end

@implementation TimeoutTimer

@synthesize firedEventCompletion = _firedEventCompletion;
@synthesize isValid              = _isValid;

@synthesize _timer;

+(instancetype)sharedInstance
{
    static dispatch_once_t pred;
    static TimeoutTimer *_sharedInstance = nil;
    dispatch_once(&pred, ^{
        _sharedInstance = [[TimeoutTimer alloc] init];
    });
    return _sharedInstance;
}

-(instancetype)init
{
    self = [super init];
    if( self )
    {
        _firedEventCompletion = nil;
        _timer                = nil;
    }
    return self;
}

#pragma --mark Public Methods
-(void)startTimeout:(CGFloat)_timeout eventHandler:(FiredEventCompletion)_eventHandler
{
    self.firedEventCompletion = _eventHandler;
    [self _startTimerWithTimeout:_timeout];
}

-(void)startTimeout:(CGFloat)_timeout
{
    [self startTimeout:_timeout eventHandler:nil];
}

-(void)stop
{
    [self _stopTimer];
}

#pragma --mark Time Calculate Methods
/*
 * @ 是否跟上次儲存的時間相差 _seconds 秒，且可通過
 *   - 用於方便做時間控管的閘道口
 *   - 每一次比較都會更新時間
 *   - 如果 _seconds = 0.0f 就不比較時間
 *   - return YES 代表時間確實相差 _seconds 秒，可通過
 *     return NO  代表時間不在可通過的時間裡
 */
-(BOOL)differPassSeconds:(CGFloat)_seconds
{
    BOOL _isDiffer = NO;
    if( _seconds <= 0.0f )
    {
        _isDiffer = YES;
    }
    else
    {
        NSDate *_lastDate = [self _defaultValueForKey:_kTimeoutTimerDifferDateKey];
        if( _lastDate )
        {
            NSTimeInterval _secondsBetweenTwoDates = [_lastDate timeIntervalSinceNow];
            CGFloat _diffSeconds                   = ABS(_secondsBetweenTwoDates);
            if( _diffSeconds >= _seconds )
            {
                [self _saveDefaultValue:[NSDate date] forKey:_kTimeoutTimerDifferDateKey];
                _isDiffer = YES;
            }
        }
        else
        {
            [self _saveDefaultValue:[NSDate date] forKey:_kTimeoutTimerDifferDateKey];
            _isDiffer = YES;
        }
    }
    return _isDiffer;
}

/*
 * @ 清除上次儲存的比較時間資料
 *   - 只要有執行過 differSeconds 函式就須在所有流程結束時，考慮執行這裡，以求狀態歸零。
 */
-(void)removeDifferPass
{
    [self _removeDefaultValueForKey:_kTimeoutTimerDifferDateKey];
}

#pragma --mark Blocks
-(void)setFiredEventCompletion:(FiredEventCompletion)_theFiredEventCompletion
{
    _firedEventCompletion = _theFiredEventCompletion;
}

#pragma --mark Getters
-(BOOL)isValid
{
    if( _timer )
    {
        return _timer.isValid;
    }
    return NO;
}

@end
