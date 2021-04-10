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

#import "FBSDKViewImpressionTracker.h"

#import "FBSDKAccessToken.h"
#import "FBSDKAccessTokenProtocols.h"
#import "FBSDKAppEvents+Internal.h"
#import "FBSDKCoreKitBasicsImport.h"
#import "FBSDKEventLogging.h"
#import "FBSDKGraphRequestProviding.h"
#import "FBSDKInternalUtility.h"
#import "FBSDKNotificationProtocols.h"

@interface FBSDKViewImpressionTracker ()

@property (nonatomic, strong) id<FBSDKGraphRequestProviding> graphRequestProvider;
@property (nonatomic, strong) id<FBSDKEventLogging> eventLogger;
@property (nonatomic, strong) id<FBSDKNotificationObserving> notificationObserver;
@property (nonatomic, strong) Class<FBSDKAccessTokenProviding> tokenWallet;

@end

@implementation FBSDKViewImpressionTracker
{
  NSMutableSet *_trackedImpressions;
}

static dispatch_once_t token;

#pragma mark - Class Methods

+ (instancetype)impressionTrackerWithEventName:(NSString *)eventName
                          graphRequestProvider:(id<FBSDKGraphRequestProviding>)graphRequestProvider
                                   eventLogger:(id<FBSDKEventLogging>)eventLogger
                          notificationObserver:(id<FBSDKNotificationObserving>)notificationObserver
                                   tokenWallet:(Class<FBSDKAccessTokenProviding>)tokenWallet
{
  static NSMutableDictionary *_impressionTrackers = nil;

  dispatch_once(&token, ^{
    _impressionTrackers = [NSMutableDictionary new];
  });
  // Maintains a single instance of an impression tracker for each event name
  FBSDKViewImpressionTracker *impressionTracker = _impressionTrackers[eventName];
  if (!impressionTracker) {
    impressionTracker = [[self alloc] initWithEventName:eventName
                                   graphRequestProvider:graphRequestProvider
                                            eventLogger:eventLogger
                                   notificationObserver:notificationObserver
                                            tokenWallet:tokenWallet];
    [FBSDKTypeUtility dictionary:_impressionTrackers setObject:impressionTracker forKey:eventName];
  }
  return impressionTracker;
}

#pragma mark - Object Lifecycle

- (instancetype)initWithEventName:(NSString *)eventName
             graphRequestProvider:(id<FBSDKGraphRequestProviding>)graphRequestProvider
                      eventLogger:(id<FBSDKEventLogging>)eventLogger
             notificationObserver:(id<FBSDKNotificationObserving>)notificationObserver
                      tokenWallet:(Class<FBSDKAccessTokenProviding>)tokenWallet
{
  if ((self = [super init])) {
    _eventName = [eventName copy];
    _trackedImpressions = [NSMutableSet new];
    _graphRequestProvider = graphRequestProvider;
    _eventLogger = eventLogger;
    _notificationObserver = notificationObserver;
    _tokenWallet = tokenWallet;

    [self.notificationObserver addObserver:self
                                  selector:@selector(_applicationDidEnterBackgroundNotification:)
                                      name:UIApplicationDidEnterBackgroundNotification
                                    object:UIApplication.sharedApplication];
  }
  return self;
}

- (void)dealloc
{
  [self.notificationObserver removeObserver:self];
}

#pragma mark - Public API

- (void)logImpressionWithIdentifier:(NSString *)identifier parameters:(NSDictionary *)parameters
{
  NSMutableDictionary *keys = [NSMutableDictionary dictionary];
  [FBSDKTypeUtility dictionary:keys setObject:identifier forKey:@"__view_impression_identifier__"];
  [keys addEntriesFromDictionary:parameters];
  NSDictionary *impressionKey = [keys copy];
  // Ensure that each impression is only tracked once
  if ([_trackedImpressions containsObject:impressionKey]) {
    return;
  }
  [_trackedImpressions addObject:impressionKey];

  [self.eventLogger logInternalEvent:self.eventName
                          parameters:parameters
                  isImplicitlyLogged:YES
                         accessToken:[self.tokenWallet currentAccessToken]];
}

#pragma mark - Helper Methods

- (void)_applicationDidEnterBackgroundNotification:(NSNotification *)notification
{
  // reset all tracked impressions when the app backgrounds so we will start tracking them again the next time they
  // are triggered.
  [_trackedImpressions removeAllObjects];
}

#if DEBUG
 #if FBSDKTEST

+ (void)reset
{
  if (token) {
    token = 0;
  }
}

- (NSMutableSet *)trackedImpressions
{
  return _trackedImpressions;
}

 #endif
#endif

@end
