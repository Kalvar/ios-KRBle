//
//  PeripheralViewController.m
//  BleTester
//
//  Created by Kalvar on 2014/4/28.
//  Copyright (c) 2014年 Kalvar. All rights reserved.
//

#import "PeripheralViewController.h"
#import "BLEPeripheral.h"

@interface PeripheralViewController ()


@end

@implementation PeripheralViewController (fixIos7)

-(void)_fixIos7Issues
{
    if ( [self respondsToSelector:@selector(edgesForExtendedLayout)] )
    {
        [self setEdgesForExtendedLayout:UIRectEdgeNone];
    }
}

@end

@implementation PeripheralViewController (fixTouchs)

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
    
    [self _resignFirstResponder:self.notifyCharTextField];
    [self _resignFirstResponder:self.notifyValueTextField];
    
    [self _resignFirstResponder:self.writeCharTextField];
    [self _resignFirstResponder:self.writeValueTextField];
    
    [self _resignFirstResponder:self.readCharTextField];
    [self _resignFirstResponder:self.readValueTextField];
    
}

@end

@implementation PeripheralViewController

@synthesize serviceTextField     = _serviceTextField;

@synthesize notifyCharTextField  = _notifyCharTextField;
@synthesize notifyValueTextField = _notifyValueTextField;

@synthesize writeCharTextField   = _writeCharTextField;
@synthesize writeValueTextField  = _writeValueTextField;

@synthesize readCharTextField    = _readCharTextField;
@synthesize readValueTextField   = _readValueTextField;

@synthesize advertisingSwitch    = _advertisingSwitch;

@synthesize readwriteLabel       = _readwriteLabel;

@synthesize blePeripheral        = _blePeripheral;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        //...
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self _fixIos7Issues];
    
    _blePeripheral = [BLEPeripheral sharedInstance];
    
    __weak typeof(self) _weakSelf                      = self;
    __block typeof(_blePeripheral) _blockBlePeripheral = _blePeripheral;
    
    //收到 Central 發 Read 請求時
    [_blePeripheral setReadRequestHandler:^(CBPeripheralManager *peripheralManager, CBATTRequest *cbATTRequest)
    {
        NSLog(@"Peripheral 收到 Central 發的 Read 請求 : %@", cbATTRequest);
        
        //先通知 Central 已完成 Read Request
        [_blockBlePeripheral respondSuccessToCentralRequest:cbATTRequest];
        if( [cbATTRequest.characteristic.UUID isEqual:[CBUUID UUIDWithString:_weakSelf.readCharTextField.text]] )
        {
            //一樣走 Notify 回應資料給 Central
            //可以在這裡走 Notify 回應給 Central 特定的訊息
            CBMutableCharacteristic *_notifyCharacteristic = (CBMutableCharacteristic *)[BLEPorts findCharacteristicFromUUID:[CBUUID UUIDWithString:_weakSelf.notifyCharTextField.text] service:cbATTRequest.characteristic.service];
            
            //回應 Central 20 Bytes 的數據
            [_blockBlePeripheral notifyData:[_weakSelf.readValueTextField.text dataUsingEncoding:NSUTF8StringEncoding]
                          forCharacteristic:_notifyCharacteristic];
            
            
            //要回應更多就用此方法
            //[_blockBlePeripheral notifySppData:];
            
        }
        
    }];
    
    //收到 Central Write 過來的資料時
    [_blePeripheral setWriteRequestHandler:^(CBPeripheralManager *peripheralManager, NSArray *cbAttRequests, NSMutableData *receivedData)
    {
        NSLog(@"Peripheral 收到 Central 發的 Write 請求 : %@", cbAttRequests);
        
        for( CBATTRequest *_cbRequest in cbAttRequests )
        {
            //NSLog(@"特徵碼 Value ( NSData ) 1 : %@, Parsed : %@", _cbRequest.characteristic.value, [[NSString alloc] initWithData:_cbRequest.characteristic.value encoding:NSUTF8StringEncoding]);
            
            //NSLog(@"_cbRequest.characteristic.UUID : %@", _cbRequest.characteristic.UUID);
            
            if( [_cbRequest.characteristic.UUID isEqual:[CBUUID UUIDWithString:_weakSelf.writeCharTextField.text]] )
            {
                //Central 送來的值，值在 CBATTRequest 裡，不在特徵碼裡
                NSString *_parsedString = [[NSString alloc] initWithData:_cbRequest.value encoding:NSUTF8StringEncoding];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    //NSLog(@"Parsed : %@", _parsedString);
                    _weakSelf.readwriteLabel.text = _parsedString;
                });
                
                //_blockBlePeripheral.readwriteCharacteristic.value = _cbRequest.value;
                [receivedData appendData:_cbRequest.value];
                
                //先通知 Central 已完成 Write Request
                [_blockBlePeripheral respondSuccessToCentralRequest:_cbRequest];
                
                //可以在這裡走 Notify 回應給 Central 特定的訊息
                CBMutableCharacteristic *_notifyCharacteristic = (CBMutableCharacteristic *)[BLEPorts findCharacteristicFromUUID:[CBUUID UUIDWithString:_weakSelf.notifyCharTextField.text] service:_cbRequest.characteristic.service];
                
                //回應 Central 20 Bytes 的數據
                [_blockBlePeripheral notifyData:[_weakSelf.writeValueTextField.text dataUsingEncoding:NSUTF8StringEncoding]
                              forCharacteristic:_notifyCharacteristic];
                
                break;
            }
            
        }

    }];
    
    //收到 Central 的訂閱通知時( setNotify = YES )
    [_blePeripheral setSubscribedCompletion:^(CBPeripheralManager *peripheral, CBCentral *central, CBCharacteristic *characteristic)
    {
        NSLog(@"收到 Central 的訂閱通知 : %@", characteristic);
        NSLog(@"傳送 %@", _weakSelf.notifyValueTextField.text);
        
        [_blockBlePeripheral notifySppData:[_weakSelf.notifyValueTextField.text dataUsingEncoding:NSUTF8StringEncoding] sendingHandler:^(BOOL sendOk, NSInteger chunkIndex, NSData *chunk, CGFloat progress)
        {
            NSLog(@"進度 %f %%, 第 %i 資料長度傳送%@ ", progress, chunkIndex, (sendOk ? @"成功" : @"失敗"));
        } completion:^(CBPeripheralManager *peripheralManager, CGFloat progress)
        {
            NSLog(@"傳送完成 %f %%", progress);
        }];
    }];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}

#pragma mark - Switch Methods
-(void)addService
{
    //先清除並重設所有的服務碼 & 特徵碼
    [_blePeripheral removeAllServices];
    CBMutableCharacteristic *_notifyCharacteristic    = [_blePeripheral createNotifyWithUuidString:self.notifyCharTextField.text
                                                                                             value:nil];
    CBMutableCharacteristic *_readwriteCharacteristic = [_blePeripheral createReadwriteWithUuidString:self.readCharTextField.text
                                                                                                value:nil];
    CBMutableCharacteristic *_writeCharacteristic     = [_blePeripheral createWriteWithUuidString:self.writeCharTextField.text
                                                                                            value:nil];
    
    NSArray *_characteristics  = @[_notifyCharacteristic, _readwriteCharacteristic, _writeCharacteristic];
    
    CBMutableService *_service = [_blePeripheral createServiceWithUuidString:self.serviceTextField.text
                                                             characteristics:_characteristics];
    
    _blePeripheral.notifyCharacteristic = _notifyCharacteristic;
    _blePeripheral.sendData             = [self.notifyValueTextField.text dataUsingEncoding:NSUTF8StringEncoding];
    [_blePeripheral addService:_service];
}

/*
 * @ 儲存 Peripheral 要廣播的參數和要傳送的值
 */
-(IBAction)saveInfo:(id)sender
{
    [_blePeripheral stopAdvertising];
    [_advertisingSwitch setOn:NO animated:YES];
    [self addService];
    [self _dismissAllTextFields];
}

/*
 * @ Start advertising ( 是否進行廣播 )
 */
- (IBAction)switchChanged:(id)sender
{
    //如果沒按下 Save 鈕存過資訊，就主動更新資訊
    if( [_blePeripheral.services count] < 1 )
    {
        [self addService];
    }
    
    if (self.advertisingSwitch.on)
    {
        [_blePeripheral startAdvertisingForServiceUUID:_serviceTextField.text];
    }
    else
    {
        [_blePeripheral stopAdvertising];
    }
}

-(IBAction)sendNotify:(id)sender
{
    [_blePeripheral notifySppData:[self.notifyValueTextField.text dataUsingEncoding:NSUTF8StringEncoding]];
}

#pragma --mark UITextFieldDelegate

#pragma --mark UIViewDelegate
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self _dismissAllTextFields];
    [super touchesBegan:touches withEvent:event];
}

@end
