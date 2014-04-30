//
//  KRProgress.m
//  V1.2
//
//  Created by Kuo-Ming Lin on 13/6/22.
//  Copyright (c) 2013 - 2014年 Kuo-Ming Lin. All rights reserved.
//

#import "KRProgress.h"
#import <QuartzCore/QuartzCore.h>

static NSInteger _krProgressTipLabelTag               = 8881;
static NSInteger _krProgressUniformTitleLabelTag      = 8882;
static NSInteger _krProgressActivityBackgroundViewTag = 8883;
static NSInteger _krProgressLockBackgroundViewTag     = 8884;

@interface KRProgress ()
{
    
}

@property (nonatomic, strong) UIView *_activityView;
@property (nonatomic, strong) UIActivityIndicatorView *_activityIndicator;
@property (nonatomic, strong) UIAlertView *_activityAlertView;

@end

@interface KRProgress (fixPrivate)

-(void)_initWithVars;
-(void)_removeActivityFromView:(UIView *)_theView;
-(void)_removeTextLabelsFromView:(UIView *)_theView;
-(void)_setupTipText:(NSString *)_tipText onTargetView:(UIView *)_theView;
-(void)_setupCornerBorderWithView:(UIView *)_theView;


@end

@implementation KRProgress (fixPrivate)

-(void)_initWithVars
{
    self.view                = nil;
    self.activityStyle       = UIActivityIndicatorViewStyleWhite;
    self.tipText             = @"Updating Data";
    self.uniformReminderText = @"Loading";
    self.borderColor         = [UIColor colorWithRed:1.0f/255.0f green:1.0f/255.0f blue:1.0f/255.0f alpha:0.85f];
}

#pragma --mark Removes
-(void)_removeActivityFromView:(UIView *)_theView
{
    if( _theView )
    {
        for(UIView *_subview in [_theView subviews])
        {
            if([_subview isKindOfClass:[UIActivityIndicatorView class]])
            {
                [(UIActivityIndicatorView *)_subview stopAnimating];
                [_subview removeFromSuperview];
                break;
            }
        }
    }
}

-(void)_removeTextLabelsFromView:(UIView *)_theView
{
    if( _theView )
    {
        for(UIView *_subview in [_theView subviews])
        {
            if([_subview isKindOfClass:[UILabel class]])
            {
                [_subview removeFromSuperview];
            }
        }
    }
}

#pragma --mark 
-(void)_setupTipText:(NSString *)_tipText onTargetView:(UIView *)_theView
{
    if( !_tipText )
    {
        _tipText = @"";
    }
    UIColor *_textColor = nil;
    if( self.tipColor )
    {
        _textColor = self.tipColor;
    }
    else
    {
        _textColor = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
    }
    [self startTranslucentWithView:_theView];
    //Large 的 Loading Icon 是 37 x 37
    CGRect _frame      = _theView.frame;
    CGFloat _height    = 26.0f;
    CGFloat _offset    = 14.0f;
    UILabel *_tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(( _frame.size.width / 2.0f ) - ( _frame.size.width / 2.0f ),
                                                                   ( _frame.size.height / 2.0f ) - ( _height / 2.0f ) + 20.0f + _offset,
                                                                     _frame.size.width,
                                                                     _height)];
    [_tipLabel setTag:_krProgressTipLabelTag];
    [_tipLabel setBackgroundColor:[UIColor clearColor]];
    [_tipLabel setText:_tipText];
    [_tipLabel setTextColor:_textColor];
    [_tipLabel setTextAlignment:NSTextAlignmentCenter];
    [_tipLabel setFont:[UIFont systemFontOfSize:15.0f]];
    [_theView addSubview:_tipLabel];
}

-(void)_setupCornerBorderWithView:(UIView *)_theView
{
    CALayer *_viewLayer      = [_theView layer];
    _viewLayer.borderColor   = [self.borderColor CGColor];
    _viewLayer.borderWidth   = 2.0f;
    _viewLayer.shadowColor   = [[UIColor blackColor] CGColor];
    _viewLayer.shadowOffset  = CGSizeMake(0, 0);
    _viewLayer.shadowOpacity = 0.5;
    _viewLayer.shadowRadius  = 5.0;
    _viewLayer.cornerRadius  = 8.0;
    _viewLayer.masksToBounds = NO;
}

@end

@implementation KRProgress

@synthesize view                = _view;
@synthesize activityStyle       = _activityStyle;
@synthesize tipText             = _theTipText;
@synthesize uniformReminderText = _uniformReminderText;
@synthesize tipColor            = _tipColor;
@synthesize borderColor         = _borderColor;
@synthesize _activityView, _activityIndicator, _activityAlertView;


+(KRProgress *)sharedManager
{
    static dispatch_once_t pred;
    static KRProgress *_singleton = nil;
    dispatch_once(&pred, ^{
        _singleton = [[KRProgress alloc] init];
    });
    return _singleton;
    //return [[self alloc] init];
}

-(id)init
{
    self = [super init];
    if( self )
    {
        [self _initWithVars];
        _activityAlertView  = [[UIAlertView alloc] initWithTitle:self.tipText
                                                         message:nil
                                                        delegate:self
                                               cancelButtonTitle:nil
                                               otherButtonTitles:nil];
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:self.activityStyle];
    }
    return self;
}

#pragma --mark Methods
-(BOOL)isActivityWithView:(UIView *)_theView
{
    for( UIView *_subview in _theView.subviews )
    {
        if( [_subview isKindOfClass:[UIActivityIndicatorView class]] )
        {
            return YES;
            break;
        }
    }
    return NO;
}

#pragma --mark AlertView
/*
 * @ 啟動 AlertView 的 Loading 載入畫面
 *   - 如果在使用上出現 Error : 10004003 的問題，可使用 [self performSelectorInBackground::] 解決。
 */
-(void)startAlertViewActivityWithTitle:(NSString *)_title
{
    if( !self._activityAlertView.isVisible )
    {
        self.tipText = _title;
        dispatch_queue_t queue = dispatch_queue_create("_startAlertViewWithTitleQueue", NULL);
        dispatch_async(queue, ^(void){
            if( self._activityIndicator.superview == self._activityAlertView )
            {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    [self._activityIndicator removeFromSuperview];
                });
            }
            if( _title )
            {
                self._activityAlertView.title = _title;
            }
            [self._activityAlertView show];
            self._activityIndicator.center = CGPointMake(self._activityAlertView.bounds.size.width / 2.0f,
                                                         self._activityAlertView.bounds.size.height - 40.0f);
            [self._activityIndicator startAnimating];
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self._activityAlertView addSubview:self._activityIndicator];
            });
        });
    }
}

/*
 * @ 停止 AlertView 的 Loading 載入畫面
 */
-(void)stopAlertViewActivity
{
    if( self._activityAlertView.isVisible )
    {
        [self._activityIndicator removeFromSuperview];
        [self._activityAlertView dismissWithClickedButtonIndex:0 animated:NO];
    }
}

/*
 * @ 即時改變正在畫面上作用的 AlertView 的 Title
 */
-(void)directChangeActivitingAlertViewTitle:(NSString *)_title
{
    if( self._activityAlertView.isVisible )
    {
        self._activityAlertView.title = self.tipText = _title;
    }
}

#pragma --mark UIView with Starting
-(void)startWithView:(UIView *)_theView activityColor:(UIColor *)_activityColor
{
    if( !_activityColor )
    {
        _activityColor = [UIColor whiteColor];
    }
    if( !self.activityStyle )
    {
        self.activityStyle = UIActivityIndicatorViewStyleWhiteLarge;
    }
    UIActivityIndicatorView *_activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:self.activityStyle];
    _activityIndicatorView.center = CGPointMake(_theView.bounds.size.width / 2.0f,
                                                _theView.bounds.size.height / 2.0f);
    [_activityIndicatorView setColor:_activityColor];
    [_activityIndicatorView startAnimating];
    [_theView addSubview:_activityIndicatorView];
}

-(void)startWithView:(UIView *)_theView
{
    if( _theView )
    {
        [self startWithView:_theView activityColor:[UIColor whiteColor]];
    }
}

/*
 * @ 可自訂 ActivityIndicator 的顏色與顯示位置
 */
-(void)startWithView:(UIView *)_theView activityColor:(UIColor *)_activityColor showAtCenterPoints:(CGPoint)_centerPoints
{
    if( !_activityColor )
    {
        _activityColor = [UIColor whiteColor];
    }
    if( !self.activityStyle )
    {
        self.activityStyle = UIActivityIndicatorViewStyleWhiteLarge;
    }
    UIActivityIndicatorView *_loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:self.activityStyle];
    [_loadingIndicator setCenter:_centerPoints];
    [_loadingIndicator setColor:_activityColor];
    [_loadingIndicator startAnimating];
    [_theView addSubview:_loadingIndicator];
}

/*
 * @ 在 ActivityIndicator 的底下設置一個全螢幕式的半透明背景
 */
-(void)startTranslucentWithView:(UIView *)_theView
{
    UIView *_backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0.0f,
                                                                       0.0f,
                                                                       _theView.frame.size.width,
                                                                       _theView.frame.size.height)];
    [_backgroundView setTag:_krProgressActivityBackgroundViewTag];
    [_backgroundView setBackgroundColor:[UIColor blackColor]];
    [_backgroundView setAlpha:0.5f];
    [_theView addSubview:_backgroundView];
    [self startWithView:_theView];
}

-(void)startCornerTranslucentWithView:(UIView *)_theView
{
    CGFloat _width  = self._activityIndicator.frame.size.width + 30.0f;
    CGFloat _height = self._activityIndicator.frame.size.height + 30.0f;
    UIView *_backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0.0f,
                                                                       0.0f,
                                                                       _width,
                                                                       _height)];
    [_backgroundView setTag:_krProgressActivityBackgroundViewTag];
    [_backgroundView setCenter:CGPointMake(_theView.bounds.size.width / 2, _theView.bounds.size.height / 2.0f)];
    [_backgroundView setBackgroundColor:[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.7f]];
    [self _setupCornerBorderWithView:_backgroundView];
    [_theView addSubview:_backgroundView];
    [self startWithView:_theView];
}

-(void)startCornerTranslucentWithView:(UIView *)_theView tipText:(NSString *)_tipText lockWindow:(BOOL)_isLockWindow
{
    if( _isLockWindow )
    {
        UIView *_backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0.0f,
                                                                           0.0f,
                                                                           _theView.frame.size.width,
                                                                           _theView.frame.size.height)];
        [_backgroundView setTag:_krProgressLockBackgroundViewTag];
        [_backgroundView setBackgroundColor:[UIColor clearColor]];
        [_theView addSubview:_backgroundView];
    }
        
    CGFloat _width  = self._activityIndicator.frame.size.width + 100.0f;
    CGFloat _height = self._activityIndicator.frame.size.height + 100.0f;
    UIView *_backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0.0f,
                                                                       0.0f,
                                                                       _width,
                                                                       _height)];
    [_backgroundView setTag:_krProgressActivityBackgroundViewTag];
    [_backgroundView setCenter:CGPointMake(_theView.bounds.size.width / 2, _theView.bounds.size.height / 2.0f)];
    [_backgroundView setBackgroundColor:[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.7f]];
    [self _setupCornerBorderWithView:_backgroundView];
    [_theView addSubview:_backgroundView];
    if( !self.activityStyle )
    {
        self.activityStyle = UIActivityIndicatorViewStyleWhiteLarge;
    }
    UIActivityIndicatorView *_activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:self.activityStyle];
    _activityIndicatorView.center = CGPointMake(_theView.bounds.size.width / 2.0f,
                                                _theView.bounds.size.height / 2.0f - 15.0f);
    [_activityIndicatorView setColor:[UIColor whiteColor]];
    [_activityIndicatorView startAnimating];
    [_theView addSubview:_activityIndicatorView];
    if( !_tipText )
    {
        _tipText = self.uniformReminderText;
    }
    UIColor *_textColor = nil;
    if( self.tipColor )
    {
        _textColor = self.tipColor;
    }
    else
    {
        _textColor = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
    }
    //Large 的 Loading Icon 是 37 x 37
    CGRect _viewframe    = _theView.frame;
    CGFloat _titleHeight = _activityIndicatorView.frame.size.height; //26.0f;
    CGFloat _titleOffset = 15.0f;
    //讀取的制式文字
    UILabel *_uniformTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(( _viewframe.size.width / 2.0f ) - ( _viewframe.size.width / 2.0f ),
                                                                            ( _viewframe.size.height / 2.0f ) - ( _titleHeight / 2.0f ) + _titleOffset,
                                                                            _viewframe.size.width,
                                                                            _titleHeight)];
    [_uniformTitleLabel setTag:_krProgressUniformTitleLabelTag];
    [_uniformTitleLabel setBackgroundColor:[UIColor clearColor]];
    [_uniformTitleLabel setText:_tipText];
    [_uniformTitleLabel setTextColor:_textColor];
    [_uniformTitleLabel setTextAlignment:NSTextAlignmentCenter];
    [_uniformTitleLabel setFont:[UIFont boldSystemFontOfSize:18.0f]];
    [_theView addSubview:_uniformTitleLabel];
    
    /*
    //動態提示小文字
    CGFloat _labelHeight = _activityIndicatorView.frame.size.height; //26.0f;
    CGFloat _offset      = 20.0f + _titleOffset;
    UILabel *_tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(( _viewframe.size.width / 2.0f ) - ( _viewframe.size.width / 2.0f ),
                                                                   ( _viewframe.size.height / 2.0f ) - ( _labelHeight / 2.0f ) + _offset,
                                                                   _viewframe.size.width,
                                                                   _labelHeight)];
    [_tipLabel setTag:_krProgressTipLabelTag];
    [_tipLabel setBackgroundColor:[UIColor clearColor]];
    [_tipLabel setText:_tipText];
    [_tipLabel setTextColor:_textColor];
    [_tipLabel setTextAlignment:NSTextAlignmentCenter];
    [_tipLabel setFont:[UIFont boldSystemFontOfSize:14.0f]];
    [_theView addSubview:_tipLabel];
     */
}

-(void)startTranslucentWithView:(UIView *)_theView setTipText:(NSString *)_tipText
{
    self.tipText = _tipText;
    [self _setupTipText:_tipText onTargetView:_theView];
}

-(void)startTranslucentInBackgroundWithView:(UIView *)_theView
{
    if( [self isActivityWithView:_theView] )
    {
        return;
    }
    [self performSelectorInBackground:@selector(startTranslucentWithView:) withObject:_theView];
}

#pragma --mark Blocks
-(void)startWithView:(UIView *)_theView executionHandler:( void (^)(void) )_ececutionHandler
{
    [self startWithView:_theView];
    dispatch_queue_t queue = dispatch_queue_create("_startWithViewQueue", NULL);
    dispatch_async(queue, ^(void){
        _ececutionHandler();
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self stopActivitingView:_theView];
        });
    });
}

-(void)startTranslucentWithView:(UIView *)_theView executionHandler:( void (^)(void) )_ececutionHandler
{
    [self startTranslucentWithView:_theView];
    dispatch_queue_t queue = dispatch_queue_create("_startTranslucentWithViewQueue", NULL);
    dispatch_async(queue, ^(void){
        _ececutionHandler();
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self stopTranslucentFromActivitingView:_theView];
        });
    });
}

-(void)startTranslucentWithView:(UIView *)_theView setTipText:(NSString *)_tipText executionHandler:( void (^)(void) )_ececutionHandler
{
    [self startTranslucentWithView:_theView setTipText:_tipText];
    dispatch_queue_t queue = dispatch_queue_create("_startTranslucentWithViewQueue", NULL);
    dispatch_async(queue, ^(void){
        _ececutionHandler();
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self stopTranslucentAndRemoveTipTextFromView:_theView];
        });
    });
}

-(void)startCornerTranslucentWithView:(UIView *)_theView executionHandler:( void (^)(void) )_ececutionHandler
{
    [self startCornerTranslucentWithView:_theView];
    dispatch_queue_t queue = dispatch_queue_create("_startTranslucentWithViewQueue", NULL);
    dispatch_async(queue, ^(void){
        _ececutionHandler();
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self stopTranslucentFromActivitingView:_theView];
        });
    });
}

#pragma --mark UIView with Stopped
-(void)stopActivitingView:(UIView *)_theView
{
    if( _theView )
    {
        [self _removeActivityFromView:_theView];
    }
}

-(void)stopTranslucentFromActivitingView:(UIView *)_theView
{
    [self _removeActivityFromView:_theView];
    if( [_theView viewWithTag:_krProgressActivityBackgroundViewTag] )
    {
        [[_theView viewWithTag:_krProgressActivityBackgroundViewTag] removeFromSuperview];
    }
}

-(void)stopCornerTranslucentFromActivitingView:(UIView *)_theView
{
    if( _theView )
    {
        UILabel *_tipTextLabel = (UILabel *)[_theView viewWithTag:_krProgressTipLabelTag];
        if( _tipTextLabel )
        {
            [_tipTextLabel removeFromSuperview];
        }
        UILabel *_uniformTextLabel = (UILabel *)[_theView viewWithTag:_krProgressUniformTitleLabelTag];
        if( _uniformTextLabel )
        {
            [_uniformTextLabel removeFromSuperview];
        }
        if( [_theView viewWithTag:_krProgressLockBackgroundViewTag] )
        {
            [[_theView viewWithTag:_krProgressLockBackgroundViewTag] removeFromSuperview];
        }
        [self stopTranslucentFromActivitingView:_theView];
    }
}

-(void)stopTranslucentInBackgroundFromView:(UIView *)_theView
{
    [self performSelectorInBackground:@selector(stopFromTranslucentView:) withObject:_theView];
}

-(void)stopTranslucentAndRemoveTipTextFromView:(UIView *)_theView
{
    if( _theView )
    {
        UILabel *_tipTextLabel = (UILabel *)[_theView viewWithTag:_krProgressTipLabelTag];
        if( _tipTextLabel )
        {
            [_tipTextLabel removeFromSuperview];
        }
        [self stopTranslucentFromActivitingView:_theView];
    }
}

/*
 * @ 即時改變正在 UIView 上顯示的提示文字
 */
-(void)directChangeTipText:(NSString *)_tipText withActivitingView:(UIView *)_theView
{
    if( _theView )
    {
        if( [self isActivityWithView:_theView] )
        {
            UILabel *_tipTextLabel = (UILabel *)[_theView viewWithTag:_krProgressTipLabelTag];
            if( _tipTextLabel )
            {
                self.tipText = _tipText;
                [_tipTextLabel setText:self.tipText];
            }
        }
    }
}

#pragma --mark Banner Mode
/*
 * @ 上方橫幅通知的模式
 */
-(void)startTopBannerModeWithView:(UIView *)_theView
{
    if( !self.activityStyle )
    {
        self.activityStyle = UIActivityIndicatorViewStyleWhite;
    }
    CGRect _frame = CGRectMake(0.0f, 0.0f, _theView.frame.size.width, 30.0f);
    UIView *_backgroundView = [[UIView alloc] initWithFrame:_frame];
    [_backgroundView setTag:_krProgressActivityBackgroundViewTag];
    [_backgroundView setBackgroundColor:[UIColor blackColor]];
    [_backgroundView setAlpha:0.6f];
    [_theView addSubview:_backgroundView];
    UIActivityIndicatorView *_activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:self.activityStyle];
    _activityIndicatorView.center = CGPointMake(_frame.size.width / 2.0f, _frame.size.height / 2.0f);
    [_activityIndicatorView setColor:[UIColor whiteColor]];
    [_activityIndicatorView startAnimating];
    [_theView addSubview:_activityIndicatorView];
}

-(void)startTopBannerModetWithView:(UIView *)_theView executionHandler:( void (^)(void) )_ececutionHandler
{
    [self startTopBannerModeWithView:_theView];
    dispatch_queue_t queue = dispatch_queue_create("_startTopBannerModetWithViewQueue", NULL);
    dispatch_async(queue, ^(void){
        _ececutionHandler();
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self stopTopBannerModeFromView:_theView];
        });
    });
}

-(void)stopTopBannerModeFromView:(UIView *)_theView
{
    if( _theView )
    {
        [self _removeActivityFromView:_theView];
        if( [_theView viewWithTag:_krProgressActivityBackgroundViewTag] )
        {
            [[_theView viewWithTag:_krProgressActivityBackgroundViewTag] removeFromSuperview];
        }
    }
}





@end
