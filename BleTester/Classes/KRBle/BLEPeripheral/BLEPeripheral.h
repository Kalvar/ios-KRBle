//
//  BLEPeripheral.h
//  KRBle
//  V1.1
//
//  Created by Kalvar on 2013/12/9.
//  Copyright (c) 2013 - 2014年 Kalvar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BLEPorts.h"

//Peripheral 收到 Central 的讀取請求時 ( Read )
typedef void(^BLEPeripheralReceivedReadRequestHandler)(CBPeripheralManager *peripheralManager, CBATTRequest *cbATTRequest);

//Peripheral 收到 Central 送來的資料時 ( Write )
typedef void(^BLEPeripheralReceivedWriteRequestHandler)(CBPeripheralManager *peripheralManager, NSArray *cbAttRequests, NSMutableData *receivedData);

//Peripheral 準備好要連結時 ( 狀態更新時 )
typedef void(^BLEPeripheralUpdateStateHandler)(CBPeripheralManager *peripheralManager, CBPeripheralManagerState peripheralState, BOOL supportBLE);

//Peripheral 收到 Central 將 setNotify 設為 YES 時
typedef void(^BLEPeripheralSubscribedCompletion)(CBPeripheralManager *peripheral, CBCentral *central, CBCharacteristic *characteristic);

//Peripheral 持續送出資料給 Central 時
typedef void(^BLEPeripheralSppNotifyHandler)(BOOL sendOk, NSInteger chunkIndex, NSData *chunk, CGFloat progress);

//Peripheral 送出資料給 Central 完成時
//-(BOOL)updateValue:(NSData *)value forCharacteristic:(CBMutableCharacteristic *)characteristic onSubscribedCentrals:(NSArray *)centrals;
typedef void(^BLEPeripheralSppNotifyCompletion)(CBPeripheralManager *peripheralManager, CGFloat progress);

//Peripheral 每送出一個封包後，準備再送出下一個封包時觸發
typedef void(^BLEPeripheralUpdateSubscribersHandler)(CBPeripheralManager *peripheralManager, CGFloat progress);

//Peripheral 發生 Exceptions 時
typedef void(^BLEPeripheralError)(NSError *error);

//Peripheral 開始廣播時
typedef void(^BLEPeripheralStartAdvertisingCompletion)(CBPeripheralManager *peripheralManager, NSError *error);

//Central 取消訂閱時觸發
typedef void(^BLEPeripheralUnsubscribedCompletion)(CBPeripheralManager *peripheralManager, CBCentral *central, CBCharacteristic *characteristic);

@protocol BLEPeripheralDelegate;


@interface BLEPeripheral : NSObject<CBPeripheralManagerDelegate>
{
    
}

@property (nonatomic, copy) BLEPeripheralReceivedReadRequestHandler readRequestHandler;
@property (nonatomic, copy) BLEPeripheralReceivedWriteRequestHandler writeRequestHandler;
@property (nonatomic, copy) BLEPeripheralUpdateStateHandler updateStateHandler;
@property (nonatomic, copy) BLEPeripheralSubscribedCompletion subscribedCompletion;
@property (nonatomic, copy) BLEPeripheralSppNotifyHandler sppNotifyHandler;
@property (nonatomic, copy) BLEPeripheralSppNotifyCompletion sppNotifyCompletion;
@property (nonatomic, copy) BLEPeripheralUpdateSubscribersHandler updateSubscribersHandler;
@property (nonatomic, copy) BLEPeripheralError errorCompletion;
@property (nonatomic, copy) BLEPeripheralStartAdvertisingCompletion startAdvertisingCompletion;
@property (nonatomic, copy) BLEPeripheralUnsubscribedCompletion unsubscribedCompletion;

@property (nonatomic, strong) id<BLEPeripheralDelegate> delegate;
@property (nonatomic, strong) CBPeripheralManager       *peripheralManager;
@property (nonatomic, strong) NSMutableData *receivedData;

//通知用的特徵碼 ( 待修 ; 應該用 NSArray 來存 Notify 特徵碼 ? )
@property (nonatomic, strong) CBMutableCharacteristic   *notifyCharacteristic;
@property (nonatomic, strong) NSData                    *sendData;
//傳送出去的每包資料長度
@property (nonatomic, readwrite) NSInteger              sendDataIndex;
@property (nonatomic, assign) NSInteger                 dataLength;
@property (nonatomic, assign) CGFloat                   progress;
//SPP 傳輸資料結束時的最後一筆 BOM 結尾 ( 通知結束 )
@property (nonatomic, strong) NSString                  *eomEndHeader;

@property (nonatomic, assign) BOOL isSupportBLE;

//取得支援的 Services
@property (nonatomic, strong) NSMutableArray *services;

//要廣播的 Device Name
@property (nonatomic, strong) NSString *name;

+(instancetype)sharedInstance;
-(BLEPeripheral *)initWithDelegate:(id<BLEPeripheralDelegate>)_bleDelegate;

#pragma --mark Services & Characteristic
-(CBMutableCharacteristic *)createNotifyWithUuidString:(NSString *)_charUuid value:(NSData *)_charValue;
-(CBMutableCharacteristic *)createReadWithUuidString:(NSString *)_charUuid value:(NSData *)_charValue;
-(CBMutableCharacteristic *)createWriteWithUuidString:(NSString *)_charUuid value:(NSData *)_charValue;
-(CBMutableCharacteristic *)createReadwriteWithUuidString:(NSString *)_charUuid value:(NSData *)_charValue;
-(CBMutableService *)createServiceWithUuidString:(NSString *)_serviceUuid characteristics:(NSArray *)_characteristics isPrimary:(BOOL)_isPrimary;
-(CBMutableService *)createServiceWithUuidString:(NSString *)_serviceUuid characteristics:(NSArray *)_characteristics;
-(void)addService:(CBMutableService *)_service;
-(void)removeService:(CBMutableService *)_service;
-(void)removeAllServices;

#pragma --mark Advertising Methods
-(void)startAdvertisingForServiceUUID:(NSString *)_serviceUUID;
-(void)stopAdvertising;

#pragma --mark Clear Data Methods
-(void)clearReceivedData;
-(void)clearSendData;

#pragma --mark Notify Methods
-(BOOL)notifyData:(NSData *)_data forCharacteristic:(CBMutableCharacteristic *)_forCharacteristic;
-(void)notifySppData:(NSData *)_data forCharacteristic:(CBMutableCharacteristic *)_forCharacteristic;
-(void)notifySppData:(NSData *)_data sendingHandler:(BLEPeripheralSppNotifyHandler)_sendingHandler completion:(BLEPeripheralSppNotifyCompletion)_completion;
-(void)notifySppData:(NSData *)_data;
-(void)stopSppNotify;
-(void)pauseSppNotify;
-(void)restartSppNotify;

#pragma --mark Response to Central Methods
-(void)respondSuccessToCentralRequest:(CBATTRequest *)_centralRequest;

#pragma --mark Setting Blocks
-(void)setReadRequestHandler:(BLEPeripheralReceivedReadRequestHandler)_theBlock;
-(void)setWriteRequestHandler:(BLEPeripheralReceivedWriteRequestHandler)_theBlock;
-(void)setUpdateStateHandler:(BLEPeripheralUpdateStateHandler)_theBlock;
-(void)setSubscribedCompletion:(BLEPeripheralSubscribedCompletion)_theBlock;
-(void)setSppNotifyHandler:(BLEPeripheralSppNotifyHandler)_theBlock;
-(void)setSppNotifyCompletion:(BLEPeripheralSppNotifyCompletion)_theBlock;
-(void)setUpdateSubscribersHandler:(BLEPeripheralUpdateSubscribersHandler)_theBlock;
-(void)setErrorCompletion:(BLEPeripheralError)_theBlock;
-(void)setStartAdvertisingCompletion:(BLEPeripheralStartAdvertisingCompletion)_theBlock;
-(void)setUnsubscribedCompletion:(BLEPeripheralUnsubscribedCompletion)_theBlock;

@end

@protocol BLEPeripheralDelegate <NSObject>

@required

//...

@optional

//Peripheral 收到 Central 的讀取請求時
-(void)blePeripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)cbATTRequest;

//Peripheral 收到 Central 送來的資料時
-(void)blePeripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)cbAttRequests;

//Peripheral 送出資料給 Central 完成時
-(void)blePeripheralManagerDidFinishedTransferForCentral:(CBPeripheralManager *)peripheral;

//Peripheral 狀態更新時
-(void)blePeripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral supportBLE:(BOOL)_supportBLE;

//Peripheral 取得 Central 訂閱特徵碼時觸發 ( 同時在這裡開始傳送資料給 Central )
-(BOOL)blePeripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic;

//Central 取消訂閱時觸發 ( setNotify 為 NO 時 )
- (void)blePeripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didCancelSubscribeFromCharacteristic:(CBCharacteristic *)characteristic;

//當 Peripheral 使用 updateValue 方法後，就會觸發這裡再傳送下一個封包。
-(void)blePeripheralManagerIsReadyToSendNextChunk:(CBPeripheralManager *)peripheral;


@end