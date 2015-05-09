//
//  KRProgress.h
//  V1.2
//
//  Created by Kuo-Ming Lin on 13/6/22.
//  Copyright (c) 2013 - 2015年 Kuo-Ming Lin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KRProgress : NSObject
{
    UIView *view;
    UIActivityIndicatorViewStyle activityStyle;
    NSString *tipText;
    UIColor *tipColor;
    NSString *uniformReminderText;
    UIColor *borderColor;
}

@property (nonatomic, strong) UIView *view;
@property (nonatomic, assign) UIActivityIndicatorViewStyle activityStyle;
@property (nonatomic, strong) NSString *tipText;
@property (nonatomic, strong) UIColor *tipColor;
@property (nonatomic, strong) NSString *uniformReminderText;
@property (nonatomic, strong) UIColor *borderColor;


+(KRProgress *)sharedManager;
-(BOOL)isActivityWithView:(UIView *)_theView;
/*
 * @ AlertView
 */
-(void)startAlertViewActivityWithTitle:(NSString *)_title;
-(void)stopAlertViewActivity;
-(void)directChangeActivitingAlertViewTitle:(NSString *)_title;
/*
 * @ UIView with Starting
 */
-(void)startWithView:(UIView *)_theView activityColor:(UIColor *)_activityColor;
-(void)startWithView:(UIView *)_theView;
-(void)startWithView:(UIView *)_theView activityColor:(UIColor *)_activityColor showAtCenterPoints:(CGPoint)_centerPoints;
-(void)startTranslucentWithView:(UIView *)_theView;
-(void)startCornerTranslucentWithView:(UIView *)_theView;
-(void)startCornerTranslucentWithView:(UIView *)_theView tipText:(NSString *)_tipText lockWindow:(BOOL)_isLockWindow;
-(void)startTranslucentWithView:(UIView *)_theView setTipText:(NSString *)_tipText;
-(void)startTranslucentInBackgroundWithView:(UIView *)_theView;
-(void)startWithView:(UIView *)_theView executionHandler:( void (^)(void) )_ececutionHandler;
-(void)startTranslucentWithView:(UIView *)_theView executionHandler:( void (^)(void) )_ececutionHandler;
-(void)startTranslucentWithView:(UIView *)_theView setTipText:(NSString *)_tipText executionHandler:( void (^)(void) )_ececutionHandler;
-(void)startCornerTranslucentWithView:(UIView *)_theView executionHandler:( void (^)(void) )_ececutionHandler;
/*
 * @ UIView with Stopped
 */
-(void)stopActivitingView:(UIView *)_theView;
-(void)stopTranslucentFromActivitingView:(UIView *)_theView;
-(void)stopCornerTranslucentFromActivitingView:(UIView *)_theView;
-(void)stopTranslucentInBackgroundFromView:(UIView *)_theView;
-(void)stopTranslucentAndRemoveTipTextFromView:(UIView *)_theView;
-(void)directChangeTipText:(NSString *)_tipText withActivitingView:(UIView *)_theView;
/*
 * @ UIView with Banner Mode
 */
-(void)startTopBannerModeWithView:(UIView *)_theView;
-(void)startTopBannerModetWithView:(UIView *)_theView executionHandler:( void (^)(void) )_ececutionHandler;
-(void)stopTopBannerModeFromView:(UIView *)_theView;


@end
