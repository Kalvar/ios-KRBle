//
//  BLECentral.h
//  KRBle
//  V1.2
//
//  Created by Kalvar on 2013/12/9.
//  Copyright (c) 2013 - 2014年 Kalvar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BLEPorts.h"

//特徵碼的屬性
typedef enum CharacteristicProperties
{
    //Default Nothing
    CPDefault = 0,
    //通知的屬性
    CPNotify,
    //寫入的屬性
    CPWrite,
    //擴展的屬性
    CPExtended,
    //廣播的屬性
    CPBroadcast,
    //讀取的屬性
    CPRead,
    //提示的屬性
    CPIndicate,
    //認證簽名寫入的屬性
    CPAuthenticatedSignedWrites,
    //通知加密需求的屬性
    CPNotifyEncryptionRequired,
    //提示加密需求的屬性
    CPIndicateEncryptionRequired
}CharacteristicProperties;

//Central 已準備進行連結，狀態更新時
typedef void(^BLECentralUpdateStateHandler)(CBCentralManager *centralManager, BOOL supportBLE);

//Central 寫資料給 Peripheral 完成時
typedef void(^BLECentralWriteCompletion)(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error);

//Central 收到 Peripheral 傳來的資料時 ( Update Value )
typedef void(^BLECentralReceiveCompletion)(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error, NSMutableData *combinedData);

//Central 變更 Peripheral 通知狀態時 ( Peripheral 的 setNotify 函式被觸發時 )
typedef void(^BLECentralNotifyChangedCompletion)(CBCentralManager *centralManager, CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error);

//Central 發生 Exceptions 時
typedef void(^BLECentralError)(NSError *error);

//Central 找到 Peripheral 時 ( 在這裡指定是否連線 )
typedef void(^BLECentralFoundPeripheralHandler)(CBCentralManager *centralManager, CBPeripheral *peripheral, NSDictionary *advertisementData, NSInteger rssi);

//Central 找到指定的服務碼時
typedef void(^BLECentralEnumerateServiceHandler)(CBPeripheral *peripheral, CBService *foundSerivce);

//Central 找到 Peripheral 指定的特徵碼時，進行列舉出每一個特徵碼的動作
typedef void(^BLECentralEnumerateCharacteristicsHandler)(CBPeripheral *peripheral, CBCharacteristic *characteristic);

//Central 與 Peripheral 斷線時
typedef void(^BLECentralDisconnectCompletion)(CBPeripheral *peripheral);

//Central 與 Peripheral 建立連線時
typedef void(^BLECentralConnectCompletion)(CBPeripheral *peripheral);

//Central 與 Peripheral 連線失敗時
typedef void(^BLECentralFailConnectCompletion)(NSError *error);

//Central 依訊號強弱判斷是否連線
typedef BOOL(^BLECentralConnectionRssi)(NSNumber *RSSI);

//Central 控制 Scanning 時間的閘道
typedef CGFloat(^BLECentralScanIntervalHandler)(void);

@protocol BLECentralDelegate;

@interface BLECentral : NSObject<CBCentralManagerDelegate, CBPeripheralDelegate>
{
    id<BLECentralDelegate> delegate;
}

@property (nonatomic, copy) BLECentralUpdateStateHandler updateStateHandler;
@property (nonatomic, copy) BLECentralWriteCompletion writeCompletion;
@property (nonatomic, copy) BLECentralReceiveCompletion receiveCompletion;
@property (nonatomic, copy) BLECentralNotifyChangedCompletion notifyChangedCompletion;
@property (nonatomic, copy) BLECentralError errorCompletion;
@property (nonatomic, copy) BLECentralFoundPeripheralHandler foundPeripheralHandler;
@property (nonatomic, copy) BLECentralEnumerateServiceHandler enumerateServiceHandler;
@property (nonatomic, copy) BLECentralEnumerateCharacteristicsHandler enumerateCharacteristicsHandler;
@property (nonatomic, copy) BLECentralDisconnectCompletion disconnectCompletion;
@property (nonatomic, copy) BLECentralConnectCompletion connectionCompletion;
@property (nonatomic, copy) BLECentralFailConnectCompletion failConnectCompletion;
@property (nonatomic, copy) BLECentralConnectionRssi connectionRssi;
@property (nonatomic, copy) BLECentralScanIntervalHandler scanIntervalHandler;

//Use Strong, Not Weak, 'Coz the BT need to long connecting.
@property (nonatomic, strong) id<BLECentralDelegate> delegate;

//Central Manager
@property (strong, nonatomic) CBCentralManager *centralManager;
//目前正在作用的 Peripheral
@property (strong, nonatomic) CBPeripheral *discoveredPeripheral;
//Peripheral 傳來的資料
@property (strong, nonatomic) NSMutableData *combinedData;

//已發現的服務與特徵碼資訊
@property (nonatomic, strong) NSMutableDictionary *discoveredServices;
//目前的 RSSI 強度
@property (nonatomic, assign) NSInteger rssi;
//接收到 Peripheral 的廣播資料
@property (nonatomic, strong) NSDictionary *advertisementInfo;
//Peripheral 設備名稱
@property (nonatomic, strong) NSString *peripheralName;

//與 Peripheral 斷線
@property (nonatomic, assign) BOOL isDisconnect;
//與 Peripheral 正在嚐試連線
@property (nonatomic, assign) BOOL isConnecting;
//與 Peripheral 已連線
@property (nonatomic, assign) BOOL isConnected;
//是否在斷線時自動掃描
@property (nonatomic, assign) BOOL autoScan;
//是否支援 BLE
@property (nonatomic, assign) BOOL isSupportBLE;
//BLE 的支援狀態
@property (nonatomic, assign) CBCentralManagerState bleState;
@property (nonatomic, strong) NSString *bleStateString;
//傳送 Spp 資料給 Peripheral
@property (nonatomic, strong) NSData *sendData;
@property (nonatomic, assign) NSInteger dataLength;
@property (nonatomic, assign) NSInteger sendDataIndex;
@property (nonatomic, assign) CGFloat progress;

+(instancetype)sharedInstance;
-(id)init;
-(instancetype)initWithDelegate:(id<BLECentralDelegate>)_bleDelegate;

#pragma --mark Scanning Methods
-(void)startScanForServices:(NSArray *)_services timeout:(CGFloat)_timeout;
-(void)startScanForServices:(NSArray *)_services;
-(void)startScanTimeout:(CGFloat)_timeout;
-(void)startScanInterval:(CGFloat)_scanInterval continueInterval:(CGFloat)_continueInterval;
-(void)startScan;
-(void)stopScan;

#pragma --mark Disconnect Methods
-(void)disconnectWithCompletion:(BLECentralDisconnectCompletion)_completion;
-(void)disconnect;

#pragma --mark Notify Methods
-(void)startNotifyWithCharacteristic:(CBCharacteristic *)_characteristic completion:(BLECentralNotifyChangedCompletion)_completion;
-(void)stopNotifyWithCharacteristic:(CBCharacteristic *)_characteristic completion:(BLECentralNotifyChangedCompletion)_completion;

#pragma --mark Discover Methods
-(void)discoverServices:(NSArray *)_services foundServiceCompletion:(BLECentralEnumerateServiceHandler)_serviceCompletion enumerateCharacteristicHandler:(BLECentralEnumerateCharacteristicsHandler)_characteristicHandler;

#pragma --mark Read / Write with Peripheral
-(void)writeValueForPeripheralWithCharacteristic:(CBCharacteristic *)_characteristic data:(NSData *)_data completion:(BLECentralWriteCompletion)_completion;
-(void)writeSppDataForCharacteristic:(CBCharacteristic *)_characteristic completion:(BLECentralWriteCompletion)_completion;
-(void)readValueFromPeripheralWithCharacteristic:(CBCharacteristic *)_characteristic completion:(BLECentralReceiveCompletion)_completion;

#pragma --mark Connection Methods
-(void)connectPeripheral:(CBPeripheral *)_peripheral completion:(BLECentralConnectCompletion)_completion;
-(void)connectPeripheral:(CBPeripheral *)_peripheral;

#pragma --mark CBUUID Methods
-(CBUUID *)buildUUIDWithString:(NSString *)_uuidString;

#pragma --mark Characteristic methods
-(CharacteristicProperties)propertyForCharacteristic:(CBCharacteristic *)_characteristic;

#pragma --mark Setting Blocks
-(void)setUpdateStateHandler:(BLECentralUpdateStateHandler)_theBlock;
-(void)setWriteCompletion:(BLECentralWriteCompletion)_theBlock;
-(void)setReceiveCompletion:(BLECentralReceiveCompletion)_theBlock;
-(void)setNotifyChangedCompletion:(BLECentralNotifyChangedCompletion)_theBlock;
-(void)setErrorCompletion:(BLECentralError)_theBlock;
-(void)setFoundPeripheralHandler:(BLECentralFoundPeripheralHandler)_theBlock;
-(void)setEnumerateServiceHandler:(BLECentralEnumerateServiceHandler)_theBlock;
-(void)setEnumerateCharacteristicsHandler:(BLECentralEnumerateCharacteristicsHandler)_theBlock;
-(void)setDisconnectCompletion:(BLECentralDisconnectCompletion)_theBlock;
-(void)setConnectionCompletion:(BLECentralConnectCompletion)_theBlock;
-(void)setFailConnectCompletion:(BLECentralFailConnectCompletion)_theBlock;
-(void)setConnectionRssi:(BLECentralConnectionRssi)_theBlock;
-(void)setScanIntervalHandler:(BLECentralScanIntervalHandler)_theBlock;

@end

@protocol BLECentralDelegate <NSObject>

@required

//...

@optional

//Central 成功找到 Peripheral
-(void)bleCentralDidDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI;

//Central 成功找到指定的服務碼
-(void)bleCentralDidDiscoverServices:(CBPeripheral *)peripheral error:(NSError *)error;

//Central 成功找到指定服務碼裡的特徵碼
-(void)bleCentralDidDiscoverCharacteristicsForService:(CBService *)service withPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;

//Central 成功寫資料給 Peripheral 時
-(void)bleCentralDidWriteValueForPeripheral:(CBPeripheral *)peripheral withCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;

//Central 讀取到 Peripheral 回應的資料時
-(void)bleCentralDidReadValueFromPeripheral:(CBPeripheral *)peripheral withCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;

//Central 成功接收到 Peripheral Notify 通知的資料時
-(void)bleCentralManager:(CBCentralManager *)centralManager didUpdateNotificationForPeripheral:(CBPeripheral *)peripheral withCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;

//Central 與 Peripheral 斷線時
-(void)bleCentralDidDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;

@end