//
//  BLEPorts.h
//  KRBle
//
//  Created by Kalvar on 2013/12/5.
//  Copyright (c) 2013 - 2014年 Kalvar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface BLEPorts : NSObject

+(const char *) centralManagerStateToString: (int)state;
+(void) printPeripheralInfo:(CBPeripheral*)peripheral;
+(void) getAllCharacteristicsFromPeripheral:(CBPeripheral *)p;
+(const char *) CBUUIDToString:(CBUUID *) UUID;
+(NSString *) CBUUIDToNSString:(CBUUID *) UUID;
+(const char *) UUIDToString:(NSUUID *) UUID;
+(int) compareCBUUID:(CBUUID *) UUID1 UUID2:(CBUUID *)UUID2;
+(int) compareCBUUIDToInt:(CBUUID *)UUID1 UUID2:(UInt16)UUID2;
+(UInt16) swap:(UInt16)s;
+(UInt16) CBUUIDToInt:(CBUUID *) UUID;
+(CBUUID *) IntToCBUUID:(UInt16)UUID;
+(CBService *) findServiceFromUUID:(CBUUID *)UUID p:(CBPeripheral *)p;
+(CBCharacteristic *) findCharacteristicFromUUID:(CBUUID *)UUID service:(CBService*)service;

@end
