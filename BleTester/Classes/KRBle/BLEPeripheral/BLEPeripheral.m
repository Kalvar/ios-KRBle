//
//  BLEPeripheral.m
//  KRBle
//  V1.2
//
//  Created by Kalvar on 2013/12/9.
//  Copyright (c) 2013 - 2014年 Kalvar. All rights reserved.
//

#import "BLEPeripheral.h"

#define NOTIFY_MTU 20

@interface BLEPeripheral ()

@property (nonatomic, assign) BOOL _finishedTransfer;
@property (nonatomic, assign) BOOL _stopNotify;

@end

@implementation BLEPeripheral (fixPrivate)

-(void)_initWithVars
{
    self.readRequestHandler               = nil;
    self.writeRequestHandler              = nil;
    
    self.updateStateHandler               = nil;
    self.subscribedCompletion             = nil;
    self.sppNotifyCompletion              = nil;
    self.sppNotifyHandler                 = nil;
    self.updateSubscribersHandler         = nil;
    
    self.errorCompletion                  = nil;
    self.startAdvertisingCompletion       = nil;
    
    self.unsubscribedCompletion           = nil;
    
    self.delegate          = nil;
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    self.receivedData      = [NSMutableData new];
    self.progress          = 0.0f;
    self.dataLength        = 0;
    
    self.eomEndHeader      = nil; //@"BOM";
    self.services          = [NSMutableArray new];
    self.name              = @"BleTester";
    self.advertiseData     = nil;
    self.advertiseInfo     = [NSMutableDictionary new];
    
    self._finishedTransfer = NO;
    self._stopNotify       = NO;
}

@end

@implementation BLEPeripheral (fixNotifies)

-(void)_resetProgress
{
    self.progress = [[NSString stringWithFormat:@"%.2f",
                      ( (float)(self.sendDataIndex) / self.dataLength ) * 100.0f] floatValue];
}

#warning 待優化
/*
 * @ 模擬 SPP 傳輸檔案
 *   - 傳送大量資料，非一個 20 Bytes 封包能解決的情況時
 */
-(void)_startNotifySppData
{
    if( self._stopNotify )
    {
        return;
    }
    
    if( !self.sendData )
    {
        return;
    }
    
    if( self.dataLength <= 0 )
    {
        self.dataLength = [self.sendData length];
    }
    
    [self _resetProgress];
    
    /*
    //以下判斷式可以考慮刪除，經實驗證明，似乎不會再進到這裡
    //所有封包都已傳送完成
    if (self._finishedTransfer)
    {
        //如有設定資料結尾的話，就多送資料結尾通知 Central 資料傳完了
        if( self.eomEndHeader && [self.eomEndHeader isKindOfClass:[NSString class]] )
        {
            if( [self.eomEndHeader length] > 0 )
            {
                BOOL didSend = [self.peripheralManager updateValue:[self.eomEndHeader dataUsingEncoding:NSUTF8StringEncoding]
                                                 forCharacteristic:self.notifyCharacteristic
                                              onSubscribedCentrals:nil];
                
                if (didSend)
                {
                    NSLog(@"Sent 1: EOM");
                }
            }
        }
        //NSLog(@"here 2");
        self._finishedTransfer = NO;
        [self.peripheralManager stopAdvertising];
        if( self.sppNotifyCompletion )
        {
            self.sppNotifyCompletion(self.peripheralManager, self.progress);
        }
        return;
    }
    */
    
    if (self.sendDataIndex >= self.dataLength)
    {
        return;
    }
    
    BOOL didSend = YES;
    
    while (didSend)
    {
        NSInteger amountToSend = self.dataLength - self.sendDataIndex;
        
        //NSLog(@"%i = %i - %i", amountToSend, self.sendData.length, self.sendDataIndex);
        
        if (amountToSend > NOTIFY_MTU)
        {
            amountToSend = NOTIFY_MTU;
        }
        
        NSData *chunk = [NSData dataWithBytes:self.sendData.bytes+self.sendDataIndex length:amountToSend];
        
        //NSLog(@"chunk : %@", chunk);
        
        /*
         * @ 送封包給 Central
         *   - 會觸發 - (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral 送下一個封包，
         *     如果發送失敗，就會再進到這裡再跑一次遞迴重傳封包，直到本次封包傳輸成功為止。
         *   
         *   - 而因為會有 Peripheral 發送速度快，Central 來不及接收的延遲情形，所以每一個包會因為重複發送而失敗
         */
        didSend = [self.peripheralManager updateValue:chunk forCharacteristic:self.notifyCharacteristic onSubscribedCentrals:nil];
        
        // If it didn't work, drop out and wait for the callback
        if (!didSend)
        {
            if( self.sppNotifyHandler )
            {
                self.sppNotifyHandler(NO, self.sendDataIndex, chunk, self.progress);
            }
            return;
        }
        
        // It did send, so update our index
        self.sendDataIndex += amountToSend;
        
        //NSLog(@"Sent chunk: %@", chunk);
        //NSLog(@"sendDataIndex : %i", self.sendDataIndex);
        
        if( self.sppNotifyHandler )
        {
            self.sppNotifyHandler(YES, self.sendDataIndex, chunk, self.progress);
        }
        
        //是最後一筆封包
        if (self.sendDataIndex >= self.dataLength)
        {
            self._finishedTransfer = YES;
            //停止廣播，同時停止其使用 Notify 屬性的特徵碼繼續傳送資料給 Central
            //[self.peripheralManager stopAdvertising];
            
            /*
             * @ 有設定數據結尾的話，會多執行這裡，告知 Central 資料傳送結束了
             *
             * @ 2013.12.11 PM 13:45
             * @ 一個奇怪的問題，待解，但目前運作正常 XD
             *   - 這裡在使用 updateValue 送封包時，第 1 次都會送不出去，第 2 次才會送成功，這跟使用 updateValue 方法的原意不對，
             *     所以這裡送資料的流程才會實際上結尾的封包是在上面的 " Sent 1: EOM " 裡發送成功。
             *
             *     猜測，會否是 Central 還來不及解析完成，就送出了第 2 包，所以被 Central 拒收，直到線程可以收資料時，才接收 Peripheral 傳輸的封包 ?
             *     2014.04.28 PM 17:30, 應是 Peripheral 有 Slave Lantency ( 延遲 ; 容錯 ) 的關係。
             */
            if( self.eomEndHeader && [self.eomEndHeader isKindOfClass:[NSString class]] )
            {
                if( [self.eomEndHeader length] > 0 )
                {
                    BOOL eomSent = [self.peripheralManager updateValue:[self.eomEndHeader dataUsingEncoding:NSUTF8StringEncoding]
                                                     forCharacteristic:self.notifyCharacteristic
                                                  onSubscribedCentrals:nil];
                    if (eomSent)
                    {
                        NSLog(@"Sent 2 : EOM");
                    }
                }
            }
            //NSLog(@"here 1");
            [self _resetProgress];
            //這裡設 NO 是為了歸零
            self._finishedTransfer = NO;
            [self.peripheralManager stopAdvertising];
            if( self.sppNotifyCompletion )
            {
                self.sppNotifyCompletion(self.peripheralManager, self.progress);
            }
            return;
        }
    }
}

@end

@implementation BLEPeripheral

@synthesize readRequestHandler               = _readRequestHandler;
@synthesize writeRequestHandler              = _writeRequestHandler;
@synthesize updateStateHandler               = _updateStateHandler;
@synthesize subscribedCompletion             = _subscribedCompletion;
@synthesize sppNotifyHandler                 = _sppNotifyHandler;
@synthesize sppNotifyCompletion              = _sppNotifyCompletion;
@synthesize updateSubscribersHandler         = _updateSubscribersHandler;
@synthesize errorCompletion                  = _errorCompletion;
@synthesize startAdvertisingCompletion       = _startAdvertisingCompletion;
@synthesize unsubscribedCompletion           = _unsubscribedCompletion;

@synthesize delegate          = _delegate;
@synthesize peripheralManager = _peripheralManager;
@synthesize receivedData      = _receivedData;
@synthesize progress          = _progress;
@synthesize dataLength        = _dataLength;
@synthesize eomEndHeader      = _eomEndHeader;

@synthesize services          = _services;
@synthesize name              = _name;
@synthesize advertiseData     = _advertiseData;
@synthesize advertiseInfo     = _advertiseInfo;

@synthesize _finishedTransfer;
@synthesize _stopNotify;


+(instancetype)sharedInstance
{
    static dispatch_once_t pred;
    static BLEPeripheral *_sharedInstance = nil;
    dispatch_once(&pred, ^{
        _sharedInstance = [[BLEPeripheral alloc] init];
    });
    return _sharedInstance;
}

-(id)init
{
    self = [super init];
    if( self )
    {
        [self _initWithVars];
    }
    return self;
}

-(BLEPeripheral *)initWithDelegate:(id<BLEPeripheralDelegate>)_bleDelegate
{
    self = [super init];
    if( self )
    {
        [self _initWithVars];
        _delegate = _bleDelegate;
    }
    return self;
}

#pragma --mark Services & Characteristic
-(CBMutableCharacteristic *)createNotifyWithUuidString:(NSString *)_charUuid value:(NSData *)_charValue
{
    if( !_charValue )
    {
        _charValue = nil;
    }
    CBMutableCharacteristic *_characteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:_charUuid]
                                                                                  properties:CBCharacteristicPropertyNotify
                                                                                       value:_charValue
                                                                                 permissions:CBAttributePermissionsReadable];
    return _characteristic;
}

-(CBMutableCharacteristic *)createReadWithUuidString:(NSString *)_charUuid value:(NSData *)_charValue
{
    if( !_charValue )
    {
        _charValue = nil;
    }
    CBMutableCharacteristic *_characteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:_charUuid]
                                                                                  properties:CBCharacteristicPropertyRead
                                                                                       value:_charValue
                                                                                 permissions:CBAttributePermissionsReadable];
    return _characteristic;
}

-(CBMutableCharacteristic *)createWriteWithUuidString:(NSString *)_charUuid value:(NSData *)_charValue
{
    if( !_charValue )
    {
        _charValue = nil;
    }
    CBMutableCharacteristic *_characteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:_charUuid]
                                                                                  properties:CBCharacteristicPropertyWrite
                                                                                       value:_charValue
                                                                                 permissions:CBAttributePermissionsWriteable];
    return _characteristic;
}

-(CBMutableCharacteristic *)createReadwriteWithUuidString:(NSString *)_charUuid value:(NSData *)_charValue
{
    if( !_charValue )
    {
        _charValue = nil;
    }
    CBMutableCharacteristic *_characteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:_charUuid]
                                                                                  properties:CBCharacteristicPropertyWrite | CBCharacteristicPropertyRead
                                                                                       value:_charValue
                                                                                 permissions:CBAttributePermissionsWriteable | CBAttributePermissionsReadable];
    return _characteristic;
}

-(CBMutableService *)createServiceWithUuidString:(NSString *)_serviceUuid characteristics:(NSArray *)_characteristics isPrimary:(BOOL)_isPrimary
{
    CBMutableService *_service = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:_serviceUuid] primary:_isPrimary];
    _service.characteristics   = _characteristics;
    return _service;
}

-(CBMutableService *)createServiceWithUuidString:(NSString *)_serviceUuid characteristics:(NSArray *)_characteristics
{
    return [self createServiceWithUuidString:_serviceUuid characteristics:_characteristics isPrimary:YES];
}

-(void)addService:(CBMutableService *)_service
{
    if( self.peripheralManager )
    {
        [_peripheralManager addService:_service];
        [_services addObject:_service];
    }
}

-(void)removeService:(CBMutableService *)_service
{
    if( self.peripheralManager )
    {
        //先清除該 Service 裡有記錄連動的 Characteristic
        for( CBMutableCharacteristic *_characteristic in _service.characteristics )
        {
            if( self.notifyCharacteristic )
            {
                if( [_notifyCharacteristic isEqual:_characteristic] )
                {
                    _notifyCharacteristic = nil;
                    break;
                }
            }
        }
        [_services removeObject:_service];
        [_peripheralManager removeService:_service];
    }
}

-(void)removeAllServices
{
    if( self.peripheralManager )
    {
        [_peripheralManager removeAllServices];
        [_services removeAllObjects];
        self.notifyCharacteristic = nil;
    }
}

#pragma --mark Advertising Methods
-(void)startAdvertisingForServiceUUID:(NSString *)_serviceUUID
{
    if( self.peripheralManager )
    {
        if( _serviceUUID )
        {
            [_advertiseInfo setObject:@[[CBUUID UUIDWithString:_serviceUUID]] forKey:CBAdvertisementDataServiceUUIDsKey];
        }
        
        if( _name.length > 0 )
        {
            [_advertiseInfo setObject:_name forKey:CBAdvertisementDataLocalNameKey];
        }

        if( _advertiseData )
        {
            [_advertiseInfo setObject:_advertiseData forKey:CBAdvertisementDataManufacturerDataKey];
        }
        
        [self.peripheralManager startAdvertising:(NSDictionary *)_advertiseInfo];
    }
}

-(void)stopAdvertising
{
    if( self.peripheralManager )
    {
        [self.peripheralManager stopAdvertising];
    }
}

#pragma --mark Clear Data Methods
/*
 * @ 清除 Peripheral 從 Central 接收到的資料
 */
-(void)clearReceivedData
{
    if( self.receivedData )
    {
        [_receivedData setLength:0];
        _receivedData = nil;
        _receivedData = [NSMutableData new];
        [_receivedData setLength:0];
    }
}

/*
 * @ 清除要傳輸的資料
 */
-(void)clearSendData
{
    if( self.sendData )
    {
        self.sendData = nil;
    }
    
    if( self.sendDataIndex != 0 )
    {
        self.sendDataIndex = 0;
    }
    
    if( self.dataLength != 0 )
    {
        self.dataLength = 0;
    }
    
    self._stopNotify = NO;
}

#pragma --mark Notify Methods
/*
 * @ 只送 1 包 Notify 資料
 *   - 覆蓋舊資料
 *   - 送完後會清掉資料，以免重複送資料
 */
-(BOOL)notifyData:(NSData *)_data forCharacteristic:(CBMutableCharacteristic *)_forCharacteristic
{
    _stopNotify    = NO;
    if( !_data || !_forCharacteristic )
    {
        return NO;
    }
    _sendData      = _data;
    _dataLength    = [_sendData length];
    _sendDataIndex = 0;
    BOOL _notifySuccess = [_peripheralManager updateValue:_data
                                        forCharacteristic:_forCharacteristic
                                     onSubscribedCentrals:nil];
    [self clearSendData];
    return _notifySuccess;
}

/*
 * @ 模擬 SPP 傳送大量封包
 */
-(void)notifySppData:(NSData *)_data forCharacteristic:(CBMutableCharacteristic *)_forCharacteristic
{
    _stopNotify           = NO;
    if( !_data || !_forCharacteristic )
    {
        return;
    }
    _sendData             = _data;
    _sendDataIndex        = 0;
    _dataLength           = [_data length];
    _notifyCharacteristic = _forCharacteristic;
    [self _startNotifySppData];
}

-(void)notifySppData:(NSData *)_data sendingHandler:(BLEPeripheralSppNotifyHandler)_sendingHandler completion:(BLEPeripheralSppNotifyCompletion)_completion
{
    _sppNotifyHandler    = _sendingHandler;
    _sppNotifyCompletion = _completion;
    [self notifySppData:_data forCharacteristic:_notifyCharacteristic];
}

-(void)notifySppData:(NSData *)_data
{
    [self notifySppData:_data forCharacteristic:_notifyCharacteristic];
}

-(void)stopSppNotify
{
    _stopNotify     = YES;
    if( !_notifyCharacteristic.isNotifying )
    {
        _stopNotify = NO;
    }
}

-(void)pauseSppNotify
{
    _stopNotify = YES;
}

-(void)restartSppNotify
{
    _stopNotify = NO;
    [self _startNotifySppData];
}

#pragma --mark Response to Central Methods
-(void)respondSuccessToCentralRequest:(CBATTRequest *)_centralRequest
{
    [_peripheralManager respondToRequest:_centralRequest withResult:CBATTErrorSuccess];
}

#pragma --mark Setting Blocks
-(void)setReadRequestHandler:(BLEPeripheralReceivedReadRequestHandler)_theBlock
{
    _readRequestHandler         = _theBlock;
}

-(void)setWriteRequestHandler:(BLEPeripheralReceivedWriteRequestHandler)_theBlock
{
    _writeRequestHandler        = _theBlock;
}

-(void)setUpdateStateHandler:(BLEPeripheralUpdateStateHandler)_theBlock
{
    _updateStateHandler         = _theBlock;
}

-(void)setSubscribedCompletion:(BLEPeripheralSubscribedCompletion)_theBlock
{
    _subscribedCompletion       = _theBlock;
}

-(void)setSppNotifyHandler:(BLEPeripheralSppNotifyHandler)_theBlock
{
    _sppNotifyHandler           = _theBlock;
}

-(void)setSppNotifyCompletion:(BLEPeripheralSppNotifyCompletion)_theBlock
{
    _sppNotifyCompletion        = _theBlock;
}

-(void)setUpdateSubscribersHandler:(BLEPeripheralUpdateSubscribersHandler)_theBlock
{
    _updateSubscribersHandler   = _theBlock;
}

-(void)setErrorCompletion:(BLEPeripheralError)_theBlock
{
    _errorCompletion            = _theBlock;
}

-(void)setStartAdvertisingCompletion:(BLEPeripheralStartAdvertisingCompletion)_theBlock
{
    _startAdvertisingCompletion = _theBlock;
}

-(void)setUnsubscribedCompletion:(BLEPeripheralUnsubscribedCompletion)_theBlock
{
    _unsubscribedCompletion     = _theBlock;
}

#pragma --mark Getters
-(BOOL)isSupportBLE
{
    NSString * state = @"";
    BOOL _isSupport  = NO;
    switch ([self.peripheralManager state])
    {
        case CBPeripheralManagerStateUnsupported:
            state = @"The platform/hardware doesn't support Bluetooth Low Energy.";
            break;
        case CBPeripheralManagerStateUnauthorized:
            state = @"The app is not authorized to use Bluetooth Low Energy.";
            break;
        case CBPeripheralManagerStatePoweredOff:
            state = @"Bluetooth is currently powered off.";
            break;
        case CBPeripheralManagerStatePoweredOn:
            state = @"The device supports BLE.";
            _isSupport = YES;
            break;
        case CBPeripheralManagerStateUnknown:
            state = @"The device has unknown problem.";
        default: break;
    }
    NSLog(@"Peripheral manager state: %@", state);
    return _isSupport;
}

#pragma --mark Central Interacts Peripheral Read / Write Response Methods
/*
 * @ Peripheral 收到 Central 的讀取特徵碼資料的指令
 *   - //該特徵碼必須擁有「讀」的屬性權限才可作用此函式
 *     [(CBPeripheral *)peripheral readValueForCharacteristic:_characteristic];
 *
 */
-(void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    if( self.delegate )
    {
        if( [_delegate respondsToSelector:@selector(blePeripheralManager:didReceiveReadRequest:)] )
        {
            [_delegate blePeripheralManager:peripheral didReceiveReadRequest:request];
        }
    }
    
    if( self.readRequestHandler )
    {
        _readRequestHandler(peripheral, request);
    }
}

/*
 * @ Peripheral 收到 Central 寫過來的數據
 *   - //該特徵碼必須擁有「寫」的屬性權限才可作用此函式
 *     //從 BLECentral 裡連線的 peripheral 寫過來的
 *     NSData *_transferData   = [@"Hello World 123456789012345" dataUsingEncoding:NSUTF8StringEncoding];
 *     [(CBPeripheral *)peripheral writeValue:_transferData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
 *
 */
-(void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests
{
    if( self.delegate )
    {
        if( [_delegate respondsToSelector:@selector(blePeripheralManager:didReceiveWriteRequests:)] )
        {
            [_delegate blePeripheralManager:peripheral didReceiveWriteRequests:requests];
        }
    }
    
    if( self.writeRequestHandler )
    {
        _writeRequestHandler(peripheral, requests, self.receivedData);
    }
}

#pragma --mark PeripheralManagerDelegate
/*
 * @ 已經開始廣播
 */
-(void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    if( self.startAdvertisingCompletion )
    {
        _startAdvertisingCompletion(peripheral, error);
    }
}

/*
 * @ 當 Peripheral 準備好時，就會觸發這裡的狀態更新
 */
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    if( self.delegate )
    {
        if( [_delegate respondsToSelector:@selector(blePeripheralManagerDidUpdateState:supportBLE:)] )
        {
            [_delegate blePeripheralManagerDidUpdateState:peripheral supportBLE:self.isSupportBLE];
        }
    }
    
    if( self.updateStateHandler )
    {
        //peripheral = PeripheralManager
        _updateStateHandler(peripheral, peripheral.state, self.isSupportBLE);
    }
}

/*
 * @ Catch when someone subscribes to our characteristic, then start sending them data.
 *   取得 Central 訂閱 Peripheral 的特徵碼時觸發，之後開始傳送資料給 Central，也就是 Central 的 setNotify = YES 時觸發
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    //NSLog(@"Central subscribed to characteristic : %@", characteristic);
    
    if( self.delegate )
    {
        if( [_delegate respondsToSelector:@selector(blePeripheralManager:central:didSubscribeToCharacteristic:)] )
        {
            [_delegate blePeripheralManager:peripheral central:central didSubscribeToCharacteristic:characteristic];
        }
    }
    
    if( self.subscribedCompletion )
    {
        _subscribedCompletion(peripheral, central, characteristic);
    }
    
    //改在外部控制流程
    //原先是這裡在執行時就會觸發下面 Notify 傳資料的動作
    //self._dataLength   = [self.sendData length];
    //self.sendDataIndex = 0;
    //[self notifySppData];
}

/*
 * @ 當 Central 取消訂閱時觸發
 *   - 當 Central 執行 [(CBPeripheral *)peripheral setNotifyValue:NO forCharacteristic:characteristic] 時觸發
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    if( self.delegate )
    {
        if([_delegate respondsToSelector:@selector(blePeripheralManager:central:didCancelSubscribeFromCharacteristic:)] )
        {
            [_delegate blePeripheralManager:peripheral central:central didCancelSubscribeFromCharacteristic:characteristic];
        }
    }
    
    if( self.unsubscribedCompletion )
    {
        _unsubscribedCompletion(peripheral, central, characteristic);
    }
}

/*
 *  @ This callback comes in when the PeripheralManager is ready to send the next chunk of data.
 *    This is to ensure that packets will arrive in the order they are sent.
 *    當 Peripheral 使用 updateValue 方法後，就會觸發這裡再傳送下一個封包。
 */
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    if( self.delegate )
    {
        if( [_delegate respondsToSelector:@selector(blePeripheralManagerIsReadyToSendNextChunk:)] )
        {
            [_delegate blePeripheralManagerIsReadyToSendNextChunk:peripheral];
        }
    }
    
    if( self.updateSubscribersHandler )
    {
        _updateSubscribersHandler(peripheral, self.progress);
    }
    
    //2014.04.29, 這裡的模式不用去修改
    //執行這裡一邊檢查是否還有封包未傳送完畢
    [self _startNotifySppData];
}

@end