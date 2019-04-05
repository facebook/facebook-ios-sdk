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

#import "FBSDKPlacesManager.h"

#import <SystemConfiguration/CaptiveNetwork.h>

#import "FBSDKPlacesBluetoothScanner.h"

static NSString *const ParameterKeyFields = @"fields";

typedef void (^FBSDKLocationRequestCompletion)(CLLocation *_Nullable location, NSError *_Nullable error);

@interface FBSDKPlacesManager() <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (atomic, strong) NSMutableArray<FBSDKLocationRequestCompletion> *locationCompletionBlocks;

@property (nonatomic, strong) FBSDKPlacesBluetoothScanner *bluetoothScanner;

@end

@implementation FBSDKPlacesManager

- (instancetype)init
{
  self = [super init];
  if (self) {
    _locationManager = [CLLocationManager new];
    _locationManager.delegate = self;
    _locationCompletionBlocks = [NSMutableArray new];
    _bluetoothScanner = [FBSDKPlacesBluetoothScanner new];
  }
  return self;
}

#pragma mark - Place Search

- (void)generatePlaceSearchRequestForSearchTerm:(NSString *)searchTerm
                                     categories:(NSArray<FBSDKPlacesCategoryKey> *)categories
                                         fields:(NSArray<FBSDKPlacesFieldKey> *)fields
                                       distance:(CLLocationDistance)distance
                                         cursor:(NSString *)cursor
                                     completion:(FBSDKPlaceGraphRequestBlock)completion
{
  __weak FBSDKPlacesManager *weakSelf = self;
  [self.locationCompletionBlocks addObject:^void (CLLocation *location, NSError *error) {
    if (!error) {
      FBSDKGraphRequest *request = [weakSelf placeSearchRequestForLocation:location searchTerm:searchTerm categories:categories fields:fields distance:distance cursor:cursor];
      completion(request, location, nil);
    }
    else {
      completion(nil, nil, error);
    }
  }];

  if (@available(iOS 9.0, *)) {
    [self.locationManager requestLocation];
  } else {
    [self.locationManager startUpdatingLocation];
  }
}

- (FBSDKGraphRequest *)placeSearchRequestForLocation:(CLLocation *)location
                                          searchTerm:(NSString *)searchTerm
                                          categories:(NSArray<FBSDKPlacesCategoryKey> *)categories
                                              fields:(NSArray<FBSDKPlacesFieldKey> *)fields
                                            distance:(CLLocationDistance)distance
                                              cursor:(NSString *)cursor
{
  if (!location && !searchTerm) {
    return nil;
  }

  NSMutableDictionary *parameters = [@{@"type" : @"place"} mutableCopy];

  if (searchTerm) {
    parameters[@"q"] = searchTerm;
  }
  if (categories && categories.count > 0) {
    parameters[@"categories"] = [self _jsonStringForObject:categories];
  }
  if (location) {
    parameters[@"center"] = [NSString stringWithFormat:@"%f,%f", location.coordinate.latitude, location.coordinate.longitude];
  }
  if (distance > 0) {
    parameters[@"distance"] = @(distance);
  }
  if (fields && fields.count > 0) {
    parameters[ParameterKeyFields] = [fields componentsJoinedByString:@","];
  }

  return [[FBSDKGraphRequest alloc]
          initWithGraphPath:@"search"
          parameters:parameters
          tokenString:self._tokenString
          version:nil
          HTTPMethod:@""];
}

- (void)generateCurrentPlaceRequestWithMinimumConfidenceLevel:(FBSDKPlaceLocationConfidence)minimumConfidence
                                                       fields:(NSArray<FBSDKPlacesFieldKey> *)fields
                                                   completion:(FBSDKCurrentPlaceGraphRequestBlock)completion
{

  dispatch_group_t locationAndBeaconsGroup = dispatch_group_create();

  __block CLLocation *currentLocation = nil;
  __block NSError *locationError = nil;

  __block NSArray<FBSDKBluetoothBeacon *> *currentBeacons = nil;

  dispatch_group_enter(locationAndBeaconsGroup);
  [self.locationCompletionBlocks addObject:^void (CLLocation *location, NSError *error) {
    currentLocation = location;
    locationError = error;
    dispatch_group_leave(locationAndBeaconsGroup);
  }];

  if (@available(iOS 9.0, *)) {
    [self.locationManager requestLocation];
  } else {
    [self.locationManager startUpdatingLocation];
  }

  dispatch_group_enter(locationAndBeaconsGroup);
  [self.bluetoothScanner scanForBeaconsWithCompletion:^(NSArray<FBSDKBluetoothBeacon *> *beacons) {
    currentBeacons = beacons;
    dispatch_group_leave(locationAndBeaconsGroup);
  }];

  dispatch_group_notify(locationAndBeaconsGroup, dispatch_get_main_queue(),^{
    if (!currentLocation) {
      completion(nil, locationError);
    }
    else {
      completion([self _currentPlaceGraphRequestForLocation:currentLocation bluetoothBeacons:currentBeacons minimumConfidenceLevel:minimumConfidence fields:fields], nil);
    }
  });
}

- (void)generateCurrentPlaceRequestForCurrentLocation:(CLLocation *)currentLocation
                           withMinimumConfidenceLevel:(FBSDKPlaceLocationConfidence)minimumConfidence
                                               fields:(NSArray<FBSDKPlacesFieldKey> *)fields
                                           completion:(nonnull FBSDKCurrentPlaceGraphRequestBlock)completion
{
  [self.bluetoothScanner scanForBeaconsWithCompletion:^(NSArray<FBSDKBluetoothBeacon *> *beacons) {
    completion([self _currentPlaceGraphRequestForLocation:currentLocation bluetoothBeacons:beacons minimumConfidenceLevel:minimumConfidence fields:fields], nil);
  }];
}


- (FBSDKGraphRequest *)currentPlaceFeedbackRequestForPlaceID:(NSString *)placeID
                                                    tracking:(NSString *)tracking
                                                     wasHere:(BOOL)wasHere
{
  return [[FBSDKGraphRequest alloc]
          initWithGraphPath:@"current_place/feedback"
          parameters:@{@"tracking" : tracking,
                       @"place_id" : placeID,
                       @"was_here" : @(wasHere)}
          tokenString:self._tokenString
          version:nil
          HTTPMethod:@"POST"];
}

- (FBSDKGraphRequest *)placeInfoRequestForPlaceID:(NSString *)placeID
                                           fields:(NSArray<FBSDKPlacesFieldKey> *)fields
{
  NSDictionary *parameters = @{};
  if (fields && fields.count) {
    parameters = @{ParameterKeyFields : [fields componentsJoinedByString:@","]};
  }

  return [[FBSDKGraphRequest alloc]
          initWithGraphPath:placeID
          parameters:parameters
          tokenString:self._tokenString
          version:nil
          HTTPMethod:@""];
}

#pragma mark - Helper Methods

- (FBSDKGraphRequest *)_currentPlaceGraphRequestForLocation:(CLLocation *)location
                                           bluetoothBeacons:(NSArray<FBSDKBluetoothBeacon *> *)beacons
                                     minimumConfidenceLevel:(FBSDKPlaceLocationConfidence)minimumConfidence
                                                     fields:(NSArray<FBSDKPlacesFieldKey> *)fields
{
  NSMutableDictionary *parameters = [NSMutableDictionary new];

  parameters[@"coordinates"] = [self _jsonStringForObject:@{@"latitude" : @(location.coordinate.latitude),
                                                            @"longitude" : @(location.coordinate.longitude)}];

  parameters[@"summary"] = @"tracking";

  NSArray *beaconParams = [self _bluetoothParametersForBeacons:beacons];
  if (beaconParams) {
      parameters[@"bluetooth"] = [self _jsonStringForObject:@{@"enabled" : @YES,
                                                              @"scans" : beaconParams}];
  }

  NSDictionary *networkInfo = [self _networkInfo];
  if (networkInfo) {
    NSString *ssid = networkInfo[@"SSID"];
    NSString *bssid = networkInfo[@"BSSID"];
    if ((ssid && bssid) &&
        !([ssid containsString:@"_nomap"] || [ssid containsString:@"_optout"])) {
      parameters[@"wifi"] = [self _jsonStringForObject:@{@"enabled" : @YES,
                                                         @"current_connection" : @{@"ssid" : ssid,
                                                                                   @"mac_address" : bssid}}];
      }
  }

  if (minimumConfidence != FBSDKPlaceLocationConfidenceNotApplicable) {
    parameters[@"min_confidence_level"] = [self _confidenceWebKeyForConfidence:minimumConfidence];
  }

  if (fields && fields.count > 0) {
    parameters[ParameterKeyFields] = [fields componentsJoinedByString:@","];
  }

  return [[FBSDKGraphRequest alloc]
          initWithGraphPath:@"current_place/results"
          parameters:parameters
          tokenString:self._tokenString
          version:nil
          HTTPMethod:@""];

}

- (NSDictionary *)_networkInfo
{
  NSArray *interfaceNames = CFBridgingRelease(CNCopySupportedInterfaces());

  for (NSString *interfaceName in interfaceNames) {
    NSDictionary *networkInfo = CFBridgingRelease(CNCopyCurrentNetworkInfo((__bridge CFStringRef)interfaceName));
    if (networkInfo.count > 0) {
      return networkInfo;
    }
  }
  return nil;
}

- (NSArray *)_bluetoothParametersForBeacons:(NSArray<FBSDKBluetoothBeacon *> *)beacons
{
  if (!beacons) {
    return nil;
  }

  NSMutableArray *beaconDicts = [NSMutableArray new];
  for (FBSDKBluetoothBeacon *beacon in beacons) {

    [beaconDicts addObject:@{@"payload" : beacon.payload,
                             @"rssi" : beacon.RSSI}];
  }

  return beaconDicts;
}

- (NSString *)_confidenceWebKeyForConfidence:(FBSDKPlaceLocationConfidence)confidence
{
  switch (confidence) {
    case FBSDKPlaceLocationConfidenceNotApplicable:
      return @"";
      break;
    case FBSDKPlaceLocationConfidenceLow:
      return @"low";
      break;
    case FBSDKPlaceLocationConfidenceMedium:
      return @"medium";
      break;
    case FBSDKPlaceLocationConfidenceHigh:
      return @"high";
      break;
  }
}

- (NSString *)_jsonStringForObject:(id)object
{
  if (![NSJSONSerialization isValidJSONObject:object]) {
    return @"";
  }

  NSError *error;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object options:0 error:&error];
  if (!error && jsonData) {
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
  }
  else {
    return @"";
  }
}

- (NSString *)_tokenString
{
  return [FBSDKAccessToken currentAccessToken].tokenString ?: [NSString stringWithFormat:@"%@|%@", [FBSDKSettings appID], [FBSDKSettings clientToken]];
}

#pragma mark - CLLocationManager Delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
  CLLocation *mostRecentLocation = locations.lastObject;
  [self _callCompletionBlocksWithLocation:mostRecentLocation error:nil];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
  [self _callCompletionBlocksWithLocation:nil error:error];
}

- (void)_callCompletionBlocksWithLocation:(CLLocation *)location error:(NSError *)error
{
  for (FBSDKLocationRequestCompletion completionBlock in self.locationCompletionBlocks) {
    completionBlock(location, error);
  }
  [self.locationCompletionBlocks removeAllObjects];
}

@end
