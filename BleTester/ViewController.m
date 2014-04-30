//
//  ViewController.m
//  BleTester
//
//  Created by Kalvar on 2014/4/24.
//  Copyright (c) 2014年 Kalvar. All rights reserved.
//

#import "ViewController.h"
#import "DeviceViewController.h"

@interface ViewController ()

@property (nonatomic, assign) BOOL _isScanning;
@property (nonatomic, strong) NSTimer *_timer;

@end

@implementation ViewController (fixIos7)

-(void)_fixIos7IssuesWithTableView
{
    //修復 TalbViewCell 的縮排問題
    if ( [self.tableView respondsToSelector:@selector(separatorInset)] )
    {
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
        //移除 TableViewCell 上方空白
        [self setAutomaticallyAdjustsScrollViewInsets:NO];
    }
}

@end

@implementation ViewController (fixTimers)

-(void)_removeOldRecords
{
    [self.peripherals removeAllObjects];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

-(void)_startTimer
{
    [self _stopTimer];
    if( !self._timer )
    {
        //5 秒後重 Load 所有的 Devices
        self._timer = [NSTimer scheduledTimerWithTimeInterval:5.0f
                                                       target:self
                                                     selector:@selector(_removeOldRecords)
                                                     userInfo:nil
                                                      repeats:YES];
    }
}

-(void)_stopTimer
{
    if( self._timer )
    {
        [self._timer invalidate];
        self._timer = nil;
    }
}

@end

@implementation ViewController

@synthesize tableView            = _tableView;
@synthesize scanBarItem          = _scanBarItem;
@synthesize peripherals          = _peripherals;
@synthesize bleCentral           = _bleCentral;

@synthesize _isScanning;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self _fixIos7IssuesWithTableView];
    
    _peripherals = [NSMutableArray new];
    _isScanning  = NO;
    
    __weak typeof(self) _weakSelf = self;
    
    _bleCentral  = [BLECentral sharedInstance];
    
    [_bleCentral setScanIntervalHandler:^CGFloat
    {
        /*
         * @ 設定每 x 秒為 Scanning 的區間範圍
         *   - 每 x 秒進一次 centralManager:didDisconnectPeripheral:error: 的 Delegate
         *   - 每 x 秒才進 foundPeripheralHandler
         *   - <= 0 秒為不限制
         */
        return 0.0f;
    }];
    
    //找到 Peripheral 時
    [_bleCentral setFoundPeripheralHandler:^(CBCentralManager *centralManager, CBPeripheral *peripheral, NSDictionary *advertisementData, NSInteger rssi)
    {
        if( ![_weakSelf.peripherals containsObject:peripheral] )
        {
            [_weakSelf.peripherals addObject:peripheral];
            dispatch_async(dispatch_get_main_queue(), ^{
                [_weakSelf.tableView reloadData];
            });
        }
    }];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self _stopTimer];
    [_bleCentral stopScan];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma --mark IBActions
-(IBAction)scan:(id)sender
{
    if( _isScanning )
    {
        _isScanning = NO;
        [_bleCentral stopScan];
        
        //[self _stopTimer];
    }
    else
    {
        _isScanning = YES;
        [_peripherals removeAllObjects];
        [_tableView reloadData];
        [_bleCentral startScan];
        
        //[_bleCentral startScanInterval:5.0f continueInterval:10.0f];
        //[_bleCentral startScanTimeout:2.0f];
        //[_bleCentral startScanForServices:@[[CBUUID UUIDWithString:@"FFA0"]]];
        
        //[self _startTimer];
    }
}

#pragma --mark UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.peripherals.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Scanned Devices";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CBPeripheral *peripheral = self.peripherals[indexPath.row];
    
    UITableViewCell *defaultCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                                          reuseIdentifier:@"DeviceCells"];
    defaultCell.textLabel.text            = peripheral.name;
    defaultCell.detailTextLabel.text      = [peripheral.identifier UUIDString];
    defaultCell.detailTextLabel.textColor = [UIColor grayColor];
    return defaultCell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [_bleCentral stopScan];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    CBPeripheral *peripheral = self.peripherals[indexPath.row];
    
    NSLog(@"Selected peripheral : %@", peripheral);
    
    DeviceViewController *_deviceViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil]
                                                   instantiateViewControllerWithIdentifier:@"DeviceViewController"];
    _deviceViewController.peripheral            = peripheral;
    [self.navigationController pushViewController:_deviceViewController animated:YES];
}

@end
