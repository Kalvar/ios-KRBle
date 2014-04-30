//
//  ViewController.h
//  BleTester
//
//  Created by Kalvar on 2014/4/24.
//  Copyright (c) 2014年 Kalvar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLECentral.h"
#import "BLEPorts.h"

@interface ViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>
{
    
}

@property (nonatomic, weak) IBOutlet UIBarButtonItem *scanBarItem;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *peripherals;
@property (nonatomic, strong) CBPeripheral *discoveredPeripheral;
@property (nonatomic, strong) BLECentral *bleCentral;

-(IBAction)scan:(id)sender;

@end
