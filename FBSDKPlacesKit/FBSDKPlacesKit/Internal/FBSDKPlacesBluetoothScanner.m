// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "FBSDKPlacesBluetoothScanner.h"

#import <CoreBluetooth/CoreBluetooth.h>

static NSString *const FBBeaconUUIDString = @"FEB8";
static NSString *const EddystoneBeaconUUIDString = @"FEAA";

static NSInteger const FBBeaconPrefix = 0xff;
static NSInteger const EddystoneBeaconPrefix = 0xfeaa16;

static NSTimeInterval const scanLength = 0.5;

@interface FBSDKPlacesBluetoothScanner () <CBCentralManagerDelegate>

@property (nonatomic, strong) CBCentralManager *manager;
@property (nonatomic, strong) NSTimer *updateTimeoutTimer;
@property (nonatomic, strong) NSMutableArray<FBSDKBluetoothBeacon *> *discoveredBeacons;
@property (atomic, strong) NSMutableArray<BluetoothBeaconScanCompletion> *scanCompletionBlocks;
@property (nonatomic) BOOL didPerformScan;

@property (nonatomic, copy, readonly) NSArray<CBUUID *> *bluetoothServices;
@property (nonatomic, strong, readonly) CBUUID *eddystoneBeaconUUID;

@end

@implementation FBSDKPlacesBluetoothScanner

- (instancetype)init
{
  self = [super init];
  if (self) {
    _manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:@{CBCentralManagerOptionShowPowerAlertKey: @NO}];
    _discoveredBeacons = [NSMutableArray new];
    _eddystoneBeaconUUID = [CBUUID UUIDWithString:EddystoneBeaconUUIDString];
    _bluetoothServices = @[[CBUUID UUIDWithString:FBBeaconUUIDString], _eddystoneBeaconUUID];
    _scanCompletionBlocks = [NSMutableArray new];
  }
  return self;
}

- (void)scanForBeaconsWithCompletion:(BluetoothBeaconScanCompletion)completion
{
  if (self.manager.state == CBCentralManagerStatePoweredOff ||
      self.manager.state == CBCentralManagerStateUnsupported ||
      self.manager.state == CBCentralManagerStateUnauthorized) {

    completion(nil);
    return;
  }

  [self.scanCompletionBlocks addObject:completion];

  if (self.manager.state == CBCentralManagerStatePoweredOn) {
    [self _startScan];
  }
}

- (void)_startScan
{
  if (self.manager.isScanning) {
    return;
  }
  
  [self.discoveredBeacons removeAllObjects];
  
  [self.manager scanForPeripheralsWithServices:self.bluetoothServices options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
  self.updateTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:scanLength target:self selector:@selector(_finalizeBluetoothScan) userInfo:nil repeats:NO];
  self.didPerformScan = YES;
}

- (void)_finalizeBluetoothScan
{
  [self.manager stopScan];

  for (BluetoothBeaconScanCompletion completion in self.scanCompletionBlocks) {
    if (self.didPerformScan) {
      completion(self.discoveredBeacons);
    }
    else {
      completion(nil);
    }
  }
  [self.scanCompletionBlocks removeAllObjects];
  self.didPerformScan = NO;
}

#pragma mark - Central Manager Delegate
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
  FBSDKBluetoothBeacon *beacon = [FBSDKBluetoothBeacon new];
  beacon.RSSI = RSSI;

  if (advertisementData[CBAdvertisementDataManufacturerDataKey]) {
    beacon.payload = [self _dataStringForFBGravityBeaconData:advertisementData[CBAdvertisementDataManufacturerDataKey]];
  }
  else if (advertisementData[CBAdvertisementDataServiceDataKey][self.eddystoneBeaconUUID]){
    beacon.payload = [self _dataStringForEddystoneBeaconData:advertisementData[CBAdvertisementDataServiceDataKey][self.eddystoneBeaconUUID]];
  }
  else {
    return;
  }

  [self.discoveredBeacons addObject:beacon];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
  if (self.scanCompletionBlocks.count > 0) {
    if (central.state == CBCentralManagerStatePoweredOn) {
      [self _startScan];
    }
    else {
      [self _finalizeBluetoothScan];
    }
  }
}

#pragma mark - Beacon Data Helper Methods

- (NSString *)_dataStringForFBGravityBeaconData:(NSData *)data
{
  NSMutableData *manufacturerPrefix = [[NSMutableData alloc] initWithBytes:&FBBeaconPrefix length:1];
  [manufacturerPrefix appendData:data];

  NSInteger length = manufacturerPrefix.length;
  NSMutableData *finalBeaconData = [[NSMutableData alloc] initWithBytes:&length length:1];
  [finalBeaconData appendData:manufacturerPrefix];

  return [self _hexStringForData:finalBeaconData];
}

- (NSString *)_dataStringForEddystoneBeaconData:(NSData *)data
{
  NSMutableData *manufacturerPrefix = [[NSMutableData alloc] initWithBytes:&EddystoneBeaconPrefix length:3];
  [manufacturerPrefix appendData:data];

  NSInteger length = manufacturerPrefix.length;
  NSMutableData *finalBeaconData = [[NSMutableData alloc] initWithBytes:&length length:1];
  [finalBeaconData appendData:manufacturerPrefix];

  return [self _hexStringForData:finalBeaconData];
}

- (NSString *)_hexStringForData:(NSData *)data
{
  NSMutableString *hexString = [NSMutableString stringWithCapacity:data.length * 2];
  const unsigned char *rawBytes = [data bytes];
  for (NSInteger i = 0; i < data.length; i++) {
    [hexString appendFormat:@"%02x", rawBytes[i]];
  }

  return [hexString copy];
}

@end

@implementation FBSDKBluetoothBeacon

@end
