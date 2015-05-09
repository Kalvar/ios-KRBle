## Screen Shot

<img src="https://dl.dropbox.com/u/83663874/GitHubs/KRBle-Home.png" alt="ScanHome" title="ScanHome" style="margin: 20px;" class="center" /> &nbsp;
<img src="https://dl.dropbox.com/u/83663874/GitHubs/KRBle-Central.png" alt="Central" title="Central" style="margin: 20px;" class="center" /> &nbsp;
<img src="https://dl.dropbox.com/u/83663874/GitHubs/KRBle-Peripheral.png" alt="Peripheral" title="Peripheral" style="margin: 20px;" class="center" /> 

#### Podfile

```ruby
platform :ios, '7.0'
pod "KRBeaconFinder", "~> 1.2"
```

## How To Get Started

KRBle implements the Bluetooth Low Engery (BLE) and simulate SPP transfer big data ( ex : image / 2,000 words ), central and peripheral can exchange the big data to each other, summarized, you could easy use this project to build your BLE applications.

``` objective-c
#import "BLECentral.h"

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    __weak typeof(self) _weakSelf = self;
    
    _bleCentral = [BLECentral sharedInstance];
    
    //Scanning interval gap holder.
    [_bleCentral setScanIntervalHandler:^CGFloat
    {
        /*
         * @ 設定每 x 秒為 Scanning 的區間範圍
         *   - 每 x 秒進一次 centralManager:didDisconnectPeripheral:error: 的 Delegate
         *   - 每 x 秒才進 foundPeripheralHandler
         *   - <= 0.0f 秒為不限制 ( Default )
         */
        return 0.0f;
    }];
    
    //Find out peripheral will enter this block
    [_bleCentral setFoundPeripheralHandler:^(CBCentralManager *centralManager, CBPeripheral *peripheral, NSDictionary *advertisementData, NSInteger rssi)
    {
        if( ![_weakSelf.peripherals containsObject:peripheral] )
        {
            [_weakSelf.peripherals addObject:peripheral];
            dispatch_async(dispatch_get_main_queue(), ^{
                [_weakSelf.tableView reloadData];
            });
        }
    }];
}

-(void)scanMethods
{
	/*
	 * @ Scan Methods
	 */
	//Unlimit scanning, iPhone will be scanning 8 times per 1 sec.
	[_bleCentral startScan];

	//Limits scanning interval, may it can save some power waste.
	[_bleCentral startScanInterval:5.0f continueInterval:10.0f];

	//Scanning before timeout
	[_bleCentral startScanTimeout:2.0f];

	//Scan for limit-services.
	[_bleCentral startScanForServices:@[[CBUUID UUIDWithString:@"FFA0"]]];
}

-(void)stopScan
{
	[_bleCentral stopScan];
}

// More information please see the source code, by the way, I'm living in Taiwan, 
// so the source code remarks almost Chinese language.
// If you have any questions or never know the remarks talking about, 
// just ask me or create an issue to exchange the conversation, I'll so glad to give you a hand.

```

## Version

V1.2

## License

MIT.

## Remarks

Sharing is the best importance in the whole world.
