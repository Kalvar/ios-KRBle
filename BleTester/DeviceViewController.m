//
//  ViewController.m
//  BleTester
//
//  Created by Kalvar on 2014/4/24.
//  Copyright (c) 2014年 Kalvar. All rights reserved.
//

#import "DeviceViewController.h"
#import "KRProgress.h"

@interface DeviceViewController ()

@property (nonatomic, strong) KRProgress *_krProgress;
@property (nonatomic, strong) CBCharacteristic *_activityNotifyChar;

@end

@implementation DeviceViewController (fixDiscovers)

-(void)_discoverServices
{
    [self.peripheral discoverServices:@[[CBUUID UUIDWithString:self.serviceTextField.text]]];
}

@end

@implementation DeviceViewController (fixTouchs)

-(void)_resignFirstResponder:(UITextField *)_textField
{
    if( _textField.resignFirstResponder )
    {
        [_textField resignFirstResponder];
    }
}

-(void)_dismissAllTextFields
{
    [self _resignFirstResponder:self.serviceTextField];
    [self _resignFirstResponder:self.charTextField];
    [self _resignFirstResponder:self.writeTextField];
}

@end

@implementation DeviceViewController

@synthesize serviceTextField     = _serviceTextField;
@synthesize charTextField        = _charTextField;
@synthesize writeTextField       = _writeTextField;
@synthesize readLabel            = _readLabel;
@synthesize identifierLabel      = _identifierLabel;
@synthesize statusLabel          = _statusLabel;

@synthesize peripheral           = _peripheral;
@synthesize bleCentral           = _bleCentral;

@synthesize _krProgress;
@synthesize _activityNotifyChar;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _krProgress = [KRProgress sharedManager];
    _krProgress.uniformReminderText = @"";
    
    __weak typeof(self) _weakSelf = self;
	_bleCentral                   = [BLECentral sharedInstance];
    
    //找到服務碼時
    [_bleCentral setEnumerateServiceHandler:^(CBPeripheral *peripheral, CBService *foundSerivce)
    {
        //NSLog(@"找到服務碼 : %@", foundSerivce);
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:_weakSelf.charTextField.text]]
                                 forService:foundSerivce];
    }];
    
    [self handleConnectionStatus];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.title            = _peripheral.name;
    _identifierLabel.text = [_peripheral.identifier UUIDString];
    _bleCentral.discoveredPeripheral = _peripheral;
    if( _bleCentral.isConnected )
    {
        _statusLabel.text = @"Connected";
    }
    else
    {
        _statusLabel.text = @"Disconnect";
    }
    [self connectButtonStatus:!_bleCentral.isConnected];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [_bleCentral disconnect];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}

#pragma --mark private

-(void) handleConnectionStatus
{
    __weak typeof(self) _weakSelf = self;
    
    [_bleCentral setConnectionCompletion:^(CBPeripheral *peripheral)
    {
        dispatch_sync(dispatch_get_main_queue(), ^{
            _weakSelf.statusLabel.text = @"Connected";
            [_weakSelf connectButtonStatus:!_weakSelf.bleCentral.isConnected];
            [_weakSelf._krProgress stopCornerTranslucentFromActivitingView:_weakSelf.view];
        });
    }];
    
    [_bleCentral setDisconnectCompletion:^(CBPeripheral *peripheral)
    {
         dispatch_sync(dispatch_get_main_queue(), ^{
             _weakSelf.statusLabel.text = @"Disconnect";
             [_weakSelf connectButtonStatus:!_weakSelf.bleCentral.isConnected];
             [_weakSelf._krProgress stopCornerTranslucentFromActivitingView:_weakSelf.view];
         });
    }];
    
}

-(void) connectButtonStatus : (BOOL) isEnable
{

    _connectButton.enabled = isEnable;
    _disconnectButton.enabled = !isEnable;
    
}

#pragma --mark IBActions
-(IBAction)wirteValue:(id)sender
{
    [self._krProgress startCornerTranslucentWithView:self.view tipText:@"Writing" lockWindow:NO];
    [self _discoverServices];
    __weak typeof(self) _weakSelf = self;
    __block typeof(_bleCentral) _blockBleCentral = _bleCentral;
    //找到指定的特徵碼時
    [_bleCentral setEnumerateCharacteristicsHandler:^(CBPeripheral *peripheral, CBCharacteristic *characteristic)
    {
        _weakSelf.readLabel.text      = @"找到指定的 write 特徵碼";
        //_weakSelf._activityNotifyChar = characteristic;
        
        //Only send 20 Byptes to Peripheral
        [_blockBleCentral writeValueForPeripheralWithCharacteristic:characteristic
                                                               data:[_weakSelf.writeTextField.text dataUsingEncoding:NSUTF8StringEncoding]
                                                         completion:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
                                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                                 _weakSelf.readLabel.text = [NSString stringWithFormat:@"Wrote : %@, %@",
                                                                                             _weakSelf.writeTextField.text, characteristic.UUID];
                                                                 [_weakSelf._krProgress stopCornerTranslucentFromActivitingView:_weakSelf.view];
                                                             });
                                                         }];
        
        /*
        //Write n Byptes to Peripheral
        [_blockBleCentral writeSppDataForCharacteristic:characteristic completion:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
            //...
        }];
        */
        
    }];
    
}

-(IBAction)readValue:(id)sender
{
    [self._krProgress startCornerTranslucentWithView:self.view tipText:@"Reading" lockWindow:NO];
    [self _discoverServices];
    __weak typeof(self) _weakSelf = self;
    __block typeof(_bleCentral) _blockBleCentral = _bleCentral;
    //找到指定的特徵碼時
    [_bleCentral setEnumerateCharacteristicsHandler:^(CBPeripheral *peripheral, CBCharacteristic *characteristic)
    {
        _weakSelf.readLabel.text      = @"找到指定的 read 特徵碼";
        //_weakSelf._activityNotifyChar = characteristic;
        [_blockBleCentral readValueFromPeripheralWithCharacteristic:characteristic
                                                         completion:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error, NSMutableData *combinedData) {
                                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                                 _weakSelf.readLabel.text = [NSString stringWithFormat:@"%@\n%@",
                                                                                             characteristic.value,
                                                                                             [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding]];
                                                                 [_weakSelf._krProgress stopCornerTranslucentFromActivitingView:_weakSelf.view];
                                                             });
                                                         }];
    }];
}

-(IBAction)notifyValue:(id)sender
{
    [self _discoverServices];
    __weak typeof(self) _weakSelf = self;
    __block typeof(_bleCentral) _blockBleCentral = _bleCentral;
    //找到指定的特徵碼時
    [_bleCentral setEnumerateCharacteristicsHandler:^(CBPeripheral *peripheral, CBCharacteristic *characteristic)
    {
        //是通知屬性的特徵碼
        if( [_blockBleCentral propertyForCharacteristic:characteristic] == CPNotify )
        {
            //才進行通知
            _weakSelf.readLabel.text      = @"找到指定的 notify 特徵碼";
            _weakSelf._activityNotifyChar = characteristic;
            if( !characteristic.isNotifying )
            {
                //NSLog(@"啟動 Notify : %@", characteristic);
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
            
            [_blockBleCentral setReceiveCompletion:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error, NSMutableData *combinedData)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *_decodeString  = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
                    _weakSelf.readLabel.text = [NSString stringWithFormat:@"%@\n%@",
                                                characteristic.value,
                                                _decodeString];
                    //[peripheral setNotifyValue:NO forCharacteristic:characteristic];
                });
            }];
        }
    }];
}

-(IBAction)stopNotify:(id)sender
{
    if( self._activityNotifyChar.isNotifying )
    {
        UIAlertView *_alertView = [[UIAlertView alloc] initWithTitle:@""
                                                             message:[NSString stringWithFormat:@"Already stop notify with %@", self._activityNotifyChar.UUID]
                                                            delegate:nil
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil];
        [_alertView show];
    }
    [_peripheral setNotifyValue:NO forCharacteristic:self._activityNotifyChar];
}

-(IBAction)connectBt:(id)senderr
{
    [self._krProgress startCornerTranslucentWithView:self.view tipText:@"Connecting" lockWindow:NO];
    [_bleCentral connectPeripheral:_peripheral];
}

-(IBAction)disconnectBt:(id)sender
{
    [self._krProgress startCornerTranslucentWithView:self.view tipText:@"Disconnecting" lockWindow:NO];
    [_bleCentral disconnect];
}

#pragma --mark UITextFieldDelegate

#pragma --mark UIViewDelegate
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self _dismissAllTextFields];
    [super touchesBegan:touches withEvent:event];
}

@end
