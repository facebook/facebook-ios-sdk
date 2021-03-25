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

#import "FBSDKAppEventsConfigurationManager.h"

#import "FBSDKCoreKit+Internal.h"

static NSString *const FBSDKAppEventsConfigurationKey = @"com.facebook.sdk:FBSDKAppEventsConfiguration";
static NSString *const FBSDKAppEventsConfigurationTimestampKey = @"com.facebook.sdk:FBSDKAppEventsConfigurationTimestamp";
static const NSTimeInterval kTimeout = 4.0;

@interface FBSDKAppEventsConfigurationManager ()

@property (nullable, nonatomic) id<FBSDKDataPersisting> store;
@property (nonnull, nonatomic) FBSDKAppEventsConfiguration *configuration;
@property (nonatomic) BOOL isLoadingConfiguration;
@property (nonatomic) BOOL hasRequeryFinishedForAppStart;
@property (nullable, nonatomic) NSDate *timestamp;
@property (nullable, nonatomic) NSMutableArray *completionBlocks;

@end

@implementation FBSDKAppEventsConfigurationManager

static dispatch_once_t sharedConfigurationManagerNonce;

// Transitional singleton introduced as a way to change the usage semantics
// from a type-based interface to an instance-based interface.
// The goal of the refactor is to move callsites from:
// ClassWithoutUnderlyingInstance -> ClassRelyingOnUnderlyingInstance -> Instance
+ (FBSDKAppEventsConfigurationManager *)shared
{
  static id instance;
  dispatch_once(&sharedConfigurationManagerNonce, ^{
    instance = [[self alloc] init];
  });
  return instance;
}

+ (void)configureWithStore:(id<FBSDKDataPersisting>)store
{
  [self.shared configureWithStore:store];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)configureWithStore:(id<FBSDKDataPersisting>)store
{
  self.store = store;
  id data = [self.store objectForKey:FBSDKAppEventsConfigurationKey];
  if ([data isKindOfClass:NSData.class]) {
    self.configuration = [NSKeyedUnarchiver unarchiveObjectWithData:data];
  }
  if (!self.configuration) {
    self.configuration = [FBSDKAppEventsConfiguration defaultConfiguration];
  }
  self.completionBlocks = [NSMutableArray new];
  self.timestamp = [self.store objectForKey:FBSDKAppEventsConfigurationTimestampKey];
}

#pragma clang diagnostic pop

+ (FBSDKAppEventsConfiguration *)cachedAppEventsConfiguration
{
  return self.shared.configuration;
}

- (FBSDKAppEventsConfiguration *)cachedAppEventsConfiguration
{
  return self.configuration;
}

+ (void)loadAppEventsConfigurationWithBlock:(FBSDKAppEventsConfigurationManagerBlock)block
{
  [self.shared loadAppEventsConfigurationWithBlock:block];
}

- (void)loadAppEventsConfigurationWithBlock:(FBSDKAppEventsConfigurationManagerBlock)block
{
  NSString *appID = [FBSDKSettings appID];
  @synchronized(self) {
    [FBSDKTypeUtility array:self.completionBlocks addObject:block];
    if (!appID || (self.hasRequeryFinishedForAppStart && [self _isTimestampValid])) {
      for (FBSDKAppEventsConfigurationManagerBlock completionBlock in self.completionBlocks) {
        completionBlock();
      }
      [self.completionBlocks removeAllObjects];
      return;
    }
    if (self.isLoadingConfiguration) {
      return;
    }
    self.isLoadingConfiguration = true;
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                  initWithGraphPath:appID
                                  parameters:@{
                                    @"fields" : [NSString stringWithFormat:@"app_events_config.os_version(%@)", [UIDevice currentDevice].systemVersion]
                                  }];
    FBSDKGraphRequestConnection *requestConnection = [FBSDKGraphRequestConnection new];
    requestConnection.timeout = kTimeout;
    [requestConnection addRequest:request completionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
      [self _processResponse:result error:error];
    }];
    [requestConnection start];
  }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
+ (void)_processResponse:(id)response
                   error:(NSError *)error
{
  [self.shared _processResponse:response error:error];
}

- (void)_processResponse:(id)response
                   error:(NSError *)error
{
  NSDate *date = [NSDate date];
  @synchronized(self) {
    self.isLoadingConfiguration = NO;
    self.hasRequeryFinishedForAppStart = YES;
    if (error) {
      return;
    }
    self.configuration = [[FBSDKAppEventsConfiguration alloc] initWithJSON:response];
    self.timestamp = date;
    for (FBSDKAppEventsConfigurationManagerBlock completionBlock in self.completionBlocks) {
      completionBlock();
    }
    [self.completionBlocks removeAllObjects];
  }
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.configuration];
  [self.store setObject:data forKey:FBSDKAppEventsConfigurationKey];
  [self.store setObject:date forKey:FBSDKAppEventsConfigurationTimestampKey];
}

#pragma clang diagnostic pop

+ (BOOL)_isTimestampValid
{
  return [self.shared _isTimestampValid];
}

- (BOOL)_isTimestampValid
{
  return self.timestamp && [[NSDate date] timeIntervalSinceDate:self.timestamp] < 3600;
}

#if DEBUG
 #if FBSDKTEST

+ (void)reset
{
  [self.shared reset];
}

- (void)reset
{
  // Reset the nonce so that a new instance will be created.
  if (sharedConfigurationManagerNonce) {
    sharedConfigurationManagerNonce = 0;
  }
}

 #endif
#endif

@end
