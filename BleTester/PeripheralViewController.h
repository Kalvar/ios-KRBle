//
//  PeripheralViewController.h
//  BleTester
//
//  Created by Kalvar on 2014/4/28.
//  Copyright (c) 2014年 Kalvar. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BLEPeripheral;

@interface PeripheralViewController : UIViewController<UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITextField *serviceTextField;

@property (nonatomic, weak) IBOutlet UITextField *notifyCharTextField;
@property (nonatomic, weak) IBOutlet UITextField *notifyValueTextField;

@property (nonatomic, weak) IBOutlet UITextField *writeCharTextField;
@property (nonatomic, weak) IBOutlet UITextField *writeValueTextField;

@property (nonatomic, weak) IBOutlet UITextField *readCharTextField;
@property (nonatomic, weak) IBOutlet UITextField *readValueTextField;

@property (nonatomic, weak) IBOutlet UISwitch *advertisingSwitch;

@property (nonatomic, weak) IBOutlet UILabel *readwriteLabel;

@property (nonatomic, strong) BLEPeripheral *blePeripheral;

-(void)addService;

-(IBAction)saveInfo:(id)sender;
-(IBAction)switchChanged:(id)sender;
-(IBAction)sendNotify:(id)sender;

@end
