//
//  BLECentral.h
//  KRBle
//  V1.1
//
//  Created by Kalvar on 2013/12/9.
//  Copyright (c) 2013 - 2014年 Kalvar. All rights reserved.
//

#import "BLECentral.h"
#import "TimeoutTimer.h"

static CGFloat _kScanNeverStopTimeout = 0.0f;

@interface BLECentral ()
{
    
}

@property (nonatomic, strong) TimeoutTimer *_timeoutTimer;
@property (nonatomic, strong) TimeoutTimer *_intervalTimer;

@end

@implementation BLECentral (fixInitials)

-(void)_initWithVars
{
    /*
     * @ 另外為 Central 開一條 Thread
     *   - 用於避免 Warning :
     *     CoreBluetooth[WARNING] <CBCentralManager: 0x16d94770> is disabling duplicate filtering, but is using the default queue (main thread) for delegate events
     *   
     *   - 參考文獻 : 
     *     http://stackoverflow.com/questions/18970247/cbcentralmanager-changes-for-ios-7
     *
     */
    dispatch_queue_t _centralQueue = dispatch_queue_create("com.central.KRBle", DISPATCH_QUEUE_SERIAL);// or however you want to create your dispatch_queue_t
    
    self.updateStateHandler              = nil;
    self.writeCompletion                 = nil;
    self.receiveCompletion               = nil;
    self.notifyChangedCompletion         = nil;
    self.errorCompletion                 = nil;
    self.foundPeripheralHandler          = nil;
    self.enumerateServiceHandler         = nil;
    self.enumerateCharacteristicsHandler = nil;
    self.disconnectCompletion            = nil;
    self.connectionCompletion            = nil;
    self.failConnectCompletion           = nil;
    self.connectionRssi                  = nil;
    self.scanIntervalHandler             = nil;
    
    self.delegate              = nil;
    //self.centralManager      = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    self.centralManager        = [[CBCentralManager alloc] initWithDelegate:self queue:_centralQueue];
    self.discoveredPeripheral  = nil;
    self.combinedData          = [[NSMutableData alloc] init];
    
    self.discoveredServices    = [[NSMutableDictionary alloc] initWithCapacity:0];
    self.rssi                  = 0;
    self.advertisementInfo     = nil;
    self.peripheralName        = @"";
    
    self.isDisconnect          = YES;
    self.isConnecting          = NO;
    self.isConnected           = NO;
    self.isSupportBLE          = NO;
    self.autoScan              = NO;
    
    //不要外部控制參數型的 Timeout，會不好管控流程，另開一支 Timeout Class 來做會最棒，也便於擴充
    self._timeoutTimer         = [TimeoutTimer sharedInstance];
    //控制 Scan 頻率的 Timer
    self._intervalTimer        = [[TimeoutTimer alloc] init];
}

@end

@implementation BLECentral (fixTimers)

/*
 * @ 作 Timeout 用的 Timer
 *   - Scan 多久就停止
 */
-(void)_startTimeoutTimerWithTimeout:(CGFloat)_timeout
{
    [self _stopTimeoutTimer];
    if( _timeout > _kScanNeverStopTimeout )
    {
        [self._timeoutTimer startTimeout:_timeout eventHandler:^
        {
            [self stopScan];
        }];
    }
}

-(void)_stopTimeoutTimer
{
    [self._timeoutTimer stop];
}

/*
 * @ 作 Scan 頻率用的 Timer
 *   - 每隔多久 Scan 一次，每次 Scan 持續多久
 */
-(void)_stopIntervalTimer
{
    [self._intervalTimer stop];
}

@end

@implementation BLECentral

@synthesize updateStateHandler              = _updateStateHandler;
@synthesize writeCompletion                 = _writeCompletion;
@synthesize receiveCompletion               = _receiveCompletion;
@synthesize notifyChangedCompletion         = _notifyChangedCompletion;
@synthesize errorCompletion                 = _errorCompletion;
@synthesize foundPeripheralHandler          = _foundPeripheralHandler;
@synthesize enumerateServiceHandler         = _enumerateServiceHandler;
@synthesize enumerateCharacteristicsHandler = _enumerateCharacteristicsHandler;
@synthesize disconnectCompletion            = _disconnectCompletion;
@synthesize connectionCompletion            = _connectionCompletion;
@synthesize failConnectCompletion           = _failConnectCompletion;
@synthesize connectionRssi                  = _connectionRssi;
@synthesize scanIntervalHandler                  = _scanIntervalHandler;

@synthesize delegate                        = _delegate;
@synthesize centralManager                  = _centralManager;
@synthesize discoveredPeripheral            = _discoveredPeripheral;
@synthesize combinedData                    = _combinedData;

@synthesize discoveredServices              = _discoveredServices;
@synthesize rssi                            = _rssi;
@synthesize advertisementInfo               = _advertisementInfo;
@synthesize peripheralName                  = _peripheralName;
@synthesize isDisconnect                    = _isDisconnect;
@synthesize isConnecting                    = _isConnecting;
@synthesize isConnected                     = _isConnected;
@synthesize autoScan                        = _autoScan;
@synthesize isSupportBLE                    = _isSupportBLE;
@synthesize bleState                        = _bleState;
@synthesize bleStateString                  = _bleStateString;

@synthesize _timeoutTimer;

+(instancetype)sharedInstance
{
    static dispatch_once_t pred;
    static BLECentral *_sharedInstance = nil;
    dispatch_once(&pred, ^{
        _sharedInstance = [[BLECentral alloc] init];
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

-(instancetype)initWithDelegate:(id<BLECentralDelegate>)_bleDelegate
{
    self = [super init];
    if( self )
    {
        [self _initWithVars];
        _delegate = _bleDelegate;
    }
    return self;
}

#pragma --mark Scanning Methods
/*
 * @ Central 開始掃描 Peripherals
 */
-(void)startScanForServices:(NSArray *)_services timeout:(CGFloat)_timeout
{
    //先停止 Scan
    [self stopScan];
    
    //self.scanTimeout = _timeout;
    if( self.centralManager )
    {
        if( _services && [_services count] > 0 )
        {
            //NSLog(@"搜尋指定的服務碼 : %@", _services);
            /*
             * @ 搜尋特定服務 UUID
             *   - @[[CBUUID UUIDWithString:@"FFA0"]]
             *   - CBCentralManagerScanOptionAllowDuplicatesKey 為 YES ( 為何不是 NO ? )
             */
            [self.centralManager scanForPeripheralsWithServices:_services
                                                        options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES}];
        }
        else
        {
            //NSLog(@"搜尋全部的服務碼");
            /*
             * @ 搜尋全部服務 UUID
             */
            [self.centralManager scanForPeripheralsWithServices:nil
                                                        options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES}];
        }
        
        [self _startTimeoutTimerWithTimeout:_timeout];
    }
}

-(void)startScanForServices:(NSArray *)_services
{
    [self startScanForServices:_services timeout:_kScanNeverStopTimeout];
}

/*
 * @ 進行掃描並決定多久後停止動作
 */
-(void)startScanTimeout:(CGFloat)_timeout
{
    [self startScanForServices:nil timeout:_timeout];
}

/*
 * @ 進行掃描並設定動作頻率
 *   - _scanInterval     每 5 秒掃一次
 *   - _continueInterval 每次持續 10 秒鐘
 *   - 頻率 : 
 *     - 第 1 次，第 0 秒發起 Scan 10 秒
 *     - 第 2 次，10 秒後，等 5 秒後再發起 Scan 10 秒，此時時間已過 10 + 5 + 10 = 25 秒
 *     - 第 3 次，25 秒後，等 5 秒後再發起 Scan 10 秒，此時時間已過 25 + 5 + 10 = 40 秒
 *     - ... 以此為推
 */
-(void)startScanInterval:(CGFloat)_scanInterval continueInterval:(CGFloat)_continueInterval
{
    [self startScan];
    //把 Code 寫在這裡比較好維護，只有這一支 Function 會用到這一個 IntervalTimer
    [self _stopIntervalTimer];
    [self._intervalTimer startTimeout:_continueInterval eventHandler:^
    {
        [self stopScan];
        //停止後等 _scanInterval 秒後再啟動 Timer 掃 _continueInterval 秒
        [self._intervalTimer startTimeout:_scanInterval eventHandler:^
        {
            [self startScanInterval:_scanInterval continueInterval:_continueInterval];
        }];
    }];
}

-(void)startScan
{
    [self startScanTimeout:_kScanNeverStopTimeout];
}

/*
 * @ Central 停止掃描 Peripherals
 */
-(void)stopScan
{
    [self _stopTimeoutTimer];
    [self _stopIntervalTimer];
    if( self.centralManager )
    {
        [self.centralManager stopScan];
    }
    [self._timeoutTimer removeDifferPass];
}

#pragma --mark Disconnect Methods
-(void)disconnectWithCompletion:(BLECentralDisconnectCompletion)_completion
{
    self.disconnectCompletion = _completion;
    
    if ( !self.isConnected )
    {
        return;
    }
    
    //取出目前連線的 Peripheral 進行清除與斷線
    if (self.discoveredPeripheral.services != nil)
    {
        for (CBService *service in self.discoveredPeripheral.services)
        {
            if (service.characteristics != nil)
            {
                for (CBCharacteristic *characteristic in service.characteristics)
                {
                    if( characteristic.properties == CBCharacteristicPropertyNotify )
                    {
                        if (characteristic.isNotifying)
                        {
                            [self.discoveredPeripheral setNotifyValue:NO forCharacteristic:characteristic];
                            //return;
                        }
                    }
                }
            }
        }
    }
    
    if( self.centralManager && self.discoveredPeripheral )
    {
        dispatch_async(dispatch_get_main_queue(), ^
        {
            [self.centralManager cancelPeripheralConnection:self.discoveredPeripheral];
            [self._timeoutTimer removeDifferPass];
        });
    }
}

-(void)disconnect
{
    [self disconnectWithCompletion:nil];
}

#pragma --mark Notify Methods
/*
 * @ 開始接取通知
 *   - 設定特徵碼為可接收通知的狀態
 *   - 只有特徵碼屬性為 CBCharacteristicPropertyNotify 和 CBAttributePermissionsReadable 才行
 *   - 完成後會觸發這裡實作的 Peripheral 委派
 *     peripheral:didUpdateNotificationStateForCharacteristic:error:
 */
-(void)startNotifyWithCharacteristic:(CBCharacteristic *)_characteristic completion:(BLECentralNotifyChangedCompletion)_completion
{
    if( self.discoveredPeripheral && _characteristic )
    {
        self.notifyChangedCompletion = _completion;
        [self.discoveredPeripheral setNotifyValue:YES forCharacteristic:_characteristic];
    }
}

/*
 * @ 取消該特徵碼的通知傳輸
 */
-(void)stopNotifyWithCharacteristic:(CBCharacteristic *)_characteristic completion:(BLECentralNotifyChangedCompletion)_completion
{
    if( self.discoveredPeripheral && _characteristic )
    {
        self.notifyChangedCompletion = _completion;
        [self.discoveredPeripheral setNotifyValue:NO forCharacteristic:_characteristic];
    }
}

#pragma --mark Discover Methods
/*
 * @ 搜尋服務
 */
-(void)discoverServices:(NSArray *)_services foundServiceCompletion:(BLECentralEnumerateServiceHandler)_serviceCompletion enumerateCharacteristicHandler:(BLECentralEnumerateCharacteristicsHandler)_characteristicHandler
{
    if( self.discoveredPeripheral )
    {
        if( _serviceCompletion )
        {
            _enumerateServiceHandler = _serviceCompletion;
        }
        
        if( _characteristicHandler )
        {
            _enumerateCharacteristicsHandler = _characteristicHandler;
        }
        
        [self.discoveredPeripheral discoverServices:_services];
    }
}

#pragma --mark Read / Write with Peripheral
-(void)writeValueForPeripheralWithCharacteristic:(CBCharacteristic *)_characteristic data:(NSData *)_data completion:(BLECentralWriteCompletion)_completion
{
    if( self.discoveredPeripheral && _data )
    {
        [self.combinedData setLength:0];
        self.writeCompletion = _completion;
        [_discoveredPeripheral writeValue:_data forCharacteristic:_characteristic type:CBCharacteristicWriteWithResponse];
    }
}

-(void)readValueFromPeripheralWithCharacteristic:(CBCharacteristic *)_characteristic completion:(BLECentralReceiveCompletion)_completion
{
    if( self.discoveredPeripheral )
    {
        [self.combinedData setLength:0];
        self.receiveCompletion = _completion;
        [_discoveredPeripheral readValueForCharacteristic:_characteristic];
    }
}

#pragma --mark Connection Methods
-(void)connectPeripheral:(CBPeripheral *)_peripheral completion:(BLECentralConnectCompletion)_completion
{
    self.connectionCompletion = _completion;
    if( self.discoveredPeripheral != _peripheral )
    {
        self.discoveredPeripheral = _peripheral;
    }
    [self.centralManager connectPeripheral:self.discoveredPeripheral options:nil];
}

-(void)connectPeripheral:(CBPeripheral *)_peripheral
{
    [self connectPeripheral:_peripheral completion:nil];
}

#pragma --mark CBUUID Methods
-(CBUUID *)buildUUIDWithString:(NSString *)_uuidString
{
    return [CBUUID UUIDWithString:_uuidString];
}

#pragma --mark Characteristic methods
/*
 * @ 取得特徵碼屬性
 */
-(CharacteristicProperties)propertyForCharacteristic:(CBCharacteristic *)_characteristic
{
    CharacteristicProperties _property = CPDefault;
    switch (_characteristic.properties)
    {
        case CBCharacteristicPropertyNotify:
            //NSLog(@"通知的屬性 : %x", CBCharacteristicPropertyNotify);
            _property = CPNotify;
            break;
        case CBCharacteristicPropertyWrite:
            //NSLog(@"寫入的屬性 : %x", CBCharacteristicPropertyWrite);
            _property = CPWrite;
            break;
        case CBCharacteristicPropertyExtendedProperties:
            //NSLog(@"擴展的屬性 : %x", CBCharacteristicPropertyExtendedProperties);
            _property = CPExtended;
            break;
        case CBCharacteristicPropertyBroadcast:
            //NSLog(@"廣播的屬性 : %x", CBCharacteristicPropertyBroadcast);
            _property = CPBroadcast;
            break;
        case CBCharacteristicPropertyRead:
            //NSLog(@"讀取的屬性 : %x", CBCharacteristicPropertyRead);
            _property = CPRead;
            break;
        case CBCharacteristicPropertyIndicate:
            //NSLog(@"提示的屬性 : %x", CBCharacteristicPropertyIndicate);
            _property = CPIndicate;
            break;
        case CBCharacteristicPropertyAuthenticatedSignedWrites:
            //NSLog(@"認證簽名寫入的屬性 : %x", CBCharacteristicPropertyAuthenticatedSignedWrites);
            _property = CPAuthenticatedSignedWrites;
            break;
        case CBCharacteristicPropertyNotifyEncryptionRequired:
            //NSLog(@"通知加密需求的屬性 : %x", CBCharacteristicPropertyNotifyEncryptionRequired);
            _property = CPNotifyEncryptionRequired;
            break;
        case CBCharacteristicPropertyIndicateEncryptionRequired:
            //NSLog(@"提示加密需求的屬性 : %x", CBCharacteristicPropertyIndicateEncryptionRequired);
            _property = CPIndicateEncryptionRequired;
            break;
        default:
            break;
    }
    return _property;
}

#pragma --mark Getters
-(NSInteger)rssi
{
    return [[_discoveredPeripheral RSSI] integerValue];
}

-(BOOL)isDisconnect
{
    return ( [_discoveredPeripheral state] == CBPeripheralStateDisconnected );
}

-(BOOL)isConnecting
{
    return ( [_discoveredPeripheral state] == CBPeripheralStateConnecting );
}

-(BOOL)isConnected
{
    return ( [_discoveredPeripheral state] == CBPeripheralStateConnected );
}

/*
 * @ 是否支援 BLE
 */
-(BOOL)isSupportBLE
{
    return ( [_centralManager state] == CBCentralManagerStatePoweredOn );
}

-(CBCentralManagerState)bleState
{
    return [_centralManager state];
}

-(NSString *)bleStateString
{
    NSString * state = @"";
    switch ([_centralManager state])
    {
        case CBCentralManagerStateUnsupported:
            state = @"The platform/hardware doesn't support Bluetooth Low Energy.";
            break;
        case CBCentralManagerStateUnauthorized:
            state = @"The app is not authorized to use Bluetooth Low Energy.";
            break;
        case CBCentralManagerStatePoweredOff:
            state = @"Bluetooth is currently powered off.";
            break;
        case CBCentralManagerStatePoweredOn:
            state = @"The device supports BLE.";
            break;
        case CBCentralManagerStateUnknown:
            state = @"The device has unknown problem.";
        default: break;
    }
    return state;
}

#pragma --mark Setter Blocks
-(void)setUpdateStateHandler:(BLECentralUpdateStateHandler)_theBlock
{
    _updateStateHandler = _theBlock;
}

-(void)setWriteCompletion:(BLECentralWriteCompletion)_theBlock
{
    _writeCompletion    = _theBlock;
}

-(void)setReceiveCompletion:(BLECentralReceiveCompletion)_theBlock
{
    _receiveCompletion  = _theBlock;
}

-(void)setNotifyChangedCompletion:(BLECentralNotifyChangedCompletion)_theBlock
{
    _notifyChangedCompletion = _theBlock;
}

-(void)setErrorCompletion:(BLECentralError)_theBlock
{
    _errorCompletion         = _theBlock;
}

-(void)setFoundPeripheralHandler:(BLECentralFoundPeripheralHandler)_theBlock
{
    _foundPeripheralHandler  = _theBlock;
}

-(void)setEnumerateServiceHandler:(BLECentralEnumerateServiceHandler)_theBlock
{
    _enumerateServiceHandler = _theBlock;
}

-(void)setEnumerateCharacteristicsHandler:(BLECentralEnumerateCharacteristicsHandler)_theBlock
{
    _enumerateCharacteristicsHandler = _theBlock;
}

-(void)setDisconnectCompletion:(BLECentralDisconnectCompletion)_theBlock
{
    _disconnectCompletion  = _theBlock;
}

-(void)setConnectionCompletion:(BLECentralConnectCompletion)_theBlock
{
    _connectionCompletion  = _theBlock;
}

-(void)setFailConnectCompletion:(BLECentralFailConnectCompletion)_theBlock
{
    _failConnectCompletion = _theBlock;
}

-(void)setConnectionRssi:(BLECentralConnectionRssi)_theBlock
{
    _connectionRssi        = _theBlock;
}

-(void)setScanIntervalHandler:(BLECentralScanIntervalHandler)_theBlock
{
    _scanIntervalHandler   = _theBlock;
}

#pragma --mark CentralManagerDelegate
/*
 * @ Once the disconnection happens, we need to clean up our local copy of the peripheral
 *   與外設斷線時觸發。
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    self.discoveredPeripheral = nil;
    
    if( self.delegate )
    {
        if( [_delegate respondsToSelector:@selector(bleCentralDidDisconnectPeripheral:error:)] )
        {
            [_delegate bleCentralDidDisconnectPeripheral:peripheral error:error];
        }
    }
    
    if( self.disconnectCompletion )
    {
        _disconnectCompletion(peripheral);
    }
    
    if( self.autoScan )
    {
        [self startScan];
    }
}

/*
 * @ Invoked whenever a connection is succesfully created with the peripheral.
 *   Discover available services on the peripheral
 *   開始尋找外設支援的服務
 *
 * @ Central Device 的目前支援狀態
 *   - 第 1 次連結時，都會自動被系統帶入觸發這裡。
 */
-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if( self.updateStateHandler )
    {
        _updateStateHandler(central, self.isSupportBLE);
    }
}

/*
 * @ Central 發現 Peripheral
 *   - central           : 中央設備
 *   - advertisementData : 取得 Peripheral 所發出的廣播資訊，包含 " Device Name ", " Device Identifier ",  " Device Characteristic " 等
 *   - RSSI              : 訊號強度
 */
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    /*
     * @ 這裡是所有的 Peripheral 所廣播帶來的 Device Infomation include in : 
     *   - " Device Name "
     *   - " Device Identifier "
     *   - " Device Characteristic " 等。
     */
    //NSLog(@"Discovered %@ at %@, %@, %@", peripheral.name, RSSI, [advertisementData description], peripheral.identifier);
    //NSLog(@"peripheral.services : %@", peripheral.services);
    
    if( self.connectionRssi )
    {
        //-15 ~ -35
        if( !_connectionRssi(RSSI) )
        {
            return;
        }
    }
    
    /*
     * @ 控制 x 秒才能通過繼續跑 Scanning 的後續動作
     *   - BLE Scanning 還會繼續跑，但設一個閘道去控管進入 Block 和 Delegate 的區隔時間。
     */
    if( self.scanIntervalHandler )
    {
        CGFloat _seconds = _scanIntervalHandler();
        //要大於 0 秒才算數
        if( _seconds > 0.0f )
        {
            //上一次跟這一次相差 x 秒才能通過
            if( ![self._timeoutTimer differPassSeconds:_seconds] )
            {
                return;
            }
        }
    }
    
    self.advertisementInfo = advertisementData;
    self.rssi              = [RSSI integerValue];
    self.peripheralName    = peripheral.name;
    
    if (self.discoveredPeripheral != peripheral)
    {
        // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
        self.discoveredPeripheral = peripheral;
    }
    
    if( self.delegate )
    {
        if( [_delegate respondsToSelector:@selector(bleCentralDidDiscoverPeripheral:advertisementData:RSSI:)] )
        {
            [_delegate bleCentralDidDiscoverPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
        }
    }
    
    if( self.foundPeripheralHandler )
    {
        _foundPeripheralHandler(self.centralManager, peripheral, advertisementData, [RSSI integerValue]);
    }
}

/*
 * @ Invoked whenever the central manager fails to create a connection with the peripheral.
 *   無法建立與外設的連線時觸發。
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    //NSLog(@"Failed to connect to %@. (%@)", peripheral, [error localizedDescription]);
    if( self.failConnectCompletion )
    {
        _failConnectCompletion(error);
    }
}

/*
 * @ Invoked whenever a connection is succesfully created with the peripheral.
 *   Discover available services on the peripheral
 *   已連接外設，並開始尋找外設的服務
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [self stopScan];
    if( !self.combinedData )
    {
        _combinedData = [[NSMutableData alloc] init];
    }
    [self.combinedData setLength:0];
    peripheral.delegate = self;
    
    //連線後，這 discoverServices 的方法可以在外部觸發，去手動連結自己想要連結的 Service，之後只要配合外部的 _foundServiceHandler Block 就能作動流程
    // Search only for services that match our UUID
    
    /*
     * @ 如果一開始 Scan 時就有指定 Service UUIDs，那在這裡也不用指定 discoverServices 要找哪些服務碼，
     *   如果一開始 Scan 就不指定 Service UUIDs，那這裡再限定也沒有意義。
     *
     * @ 在外部操作流程唄
     *
     */
    //在外部操作 [peripheral discoverServices:@[[CBUUID UUIDWithString:BLE_CUSTOM_SERVICE_UUID]]];
    if( self.connectionCompletion )
    {
        _connectionCompletion(peripheral);
    }
    else
    {
        [peripheral discoverServices:nil];
    }
}

#pragma --mark PeripheralDelegate
/*
 * @ Invoked upon completion of a -[discoverServices:] request.
 *   當 -[discoverServices:] 請求完成後調用。
 *   即發現服務時，會調用這裡。
 *
 * @ 可在這裡限定當下要連結的「指定特徵碼」為何，以便於在 didDiscoverCharacteristicsForService 的函式裡，可以單純的連接要作動的特徵碼。
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    //這一個 Delegate 只是寫來備用，原則上是用不到的
    //有實作本 Delegate 的話，一切的主控權就會改至該 Delegate 方法裡執行，而不再向下運作
    //這裡推薦使用 Blocks 來作流程控制
    if( self.delegate )
    {
        if( [_delegate respondsToSelector:@selector(bleCentralDidDiscoverServices:error:)] )
        {
            [_delegate bleCentralDidDiscoverServices:peripheral error:error];
            return;
        }
    }
    
    if ( error )
    {
        //NSLog(@"Error discovering services: %@", [error localizedDescription]);
        if( self.errorCompletion )
        {
            _errorCompletion(error);
        }
        return;
    }
    
    //列舉出所有的服務碼
    for (CBService *service in peripheral.services)
    {
        [self.discoveredServices setObject:service forKey:(NSString *)[service.UUID description]];
        if( self.enumerateServiceHandler )
        {
            _enumerateServiceHandler(peripheral, service);
        }
    }
}

/*
 * @ Invoked upon completion of a -[discoverCharacteristics:forService:] request.
 *   當 - [discoverCharacteristics:forService:] 請求完成後調用。
 *   即找到服務裡的特徵碼 ( 例如，心跳帶裡的「人身部位偵測服務」底下的「腰部位置」 )
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if( self.delegate )
    {
        if( [_delegate respondsToSelector:@selector(bleCentralDidDiscoverCharacteristicsForService:withPeripheral:error:)] )
        {
            [_delegate bleCentralDidDiscoverCharacteristicsForService:service withPeripheral:peripheral error:error];
        }
    }
    
    if (error)
    {
        //NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        //[self disconnect];
        if( self.errorCompletion )
        {
            _errorCompletion(error);
        }
        return;
    }
    
    //列舉並找出該服務裡所有的特徵碼
    for (CBCharacteristic *characteristic in service.characteristics)
    {
        if( self.enumerateCharacteristicsHandler )
        {
            _enumerateCharacteristicsHandler(peripheral, characteristic);
        }
    }
}

/*
 * @ Central 寫資料給 Peripheral 後，會觸發這裡
 *   - Function : [(CBPeripheral *)peripheral writeValue:forCharacteristic:type:];
 *   - See also : CBCharacteristicWriteWithResponse
 */
-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if( self.delegate )
    {
        if( [_delegate respondsToSelector:@selector(bleCentralDidWriteValueForPeripheral:withCharacteristic:error:)] )
        {
            [_delegate bleCentralDidWriteValueForPeripheral:peripheral withCharacteristic:characteristic error:error];
        }
    }
    
    if( self.writeCompletion )
    {
        _writeCompletion(peripheral, characteristic, error);
    }
}

/*
 * @ 觸發時機
 *   - 1. 當 Peripheral Notify 資料給 Central 時觸發。
 *   - 2. 當 [(CBPeripheral *)peripheral readValueForCharacteristic:] 執行完成後觸發。
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        //NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        return;
    }
    
    //還原資料
    //NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    //NSLog(@"Received: %@", stringFromData);
    //[self.combinedData appendData:characteristic.value];
    
    if( self.delegate )
    {
        if( [_delegate respondsToSelector:@selector(bleCentralDidReadValueFromPeripheral:withCharacteristic:error:)] )
        {
            [_delegate bleCentralDidReadValueFromPeripheral:peripheral withCharacteristic:characteristic error:error];
        }
    }
    
    if( self.receiveCompletion )
    {
        _receiveCompletion(peripheral, characteristic, error, self.combinedData);
    }
}

/*
 * @ Central 已更新 Peripheral 的 Notify 狀態 : 
 *   - Invoked upon completion of a -[setNotifyValue:forCharacteristic:] request.
 *     當 Central 執行 [setNotifyValue:forCharacteristic:] 的請求完成後調用。
 *
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    //非通知屬性，一律不執行
    if( characteristic.properties != CBCharacteristicPropertyNotify )
    {
        return;
    }
    
    if( self.delegate )
    {
        if( [_delegate respondsToSelector:@selector(bleCentralManager:didUpdateNotificationForPeripheral:withCharacteristic:error:)] )
        {
            [_delegate bleCentralManager:self.centralManager didUpdateNotificationForPeripheral:peripheral withCharacteristic:characteristic error:error];
        }
    }
    
    if( self.notifyChangedCompletion )
    {
        _notifyChangedCompletion(self.centralManager, peripheral, characteristic, error);
    }
}

@end