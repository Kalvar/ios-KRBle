//
//  ViewController.h
//  BleTester
//
//  Created by Kalvar on 2014/4/24.
//  Copyright (c) 2014年 Kalvar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLECentral.h"

@interface DeviceViewController : UIViewController<UITextFieldDelegate>
{
    
}

@property (nonatomic, weak) IBOutlet UITextField *serviceTextField;
@property (nonatomic, weak) IBOutlet UITextField *charTextField;
@property (nonatomic, weak) IBOutlet UITextField *writeTextField;
@property (nonatomic, weak) IBOutlet UILabel *readLabel;
@property (nonatomic, weak) IBOutlet UILabel *identifierLabel;
@property (nonatomic, weak) IBOutlet UILabel *statusLabel;

@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) BLECentral *bleCentral;

-(IBAction)wirteValue:(id)sender;
-(IBAction)readValue:(id)sender;
-(IBAction)notifyValue:(id)sender;
-(IBAction)stopNotify:(id)sender;
-(IBAction)connectBt:(id)sender;
-(IBAction)disconnectBt:(id)sender;

@end
