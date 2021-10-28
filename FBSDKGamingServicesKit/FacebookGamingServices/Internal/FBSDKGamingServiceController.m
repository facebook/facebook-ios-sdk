/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKGamingServiceController.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

static NSString *const kServiceTypeStringFriendFinder = @"friendfinder";
static NSString *const kServiceTypeStringMediaAsset = @"media_asset";
static NSString *const kServiceTypeStringCommunity = @"community";

static NSString *FBSDKGamingServiceTypeString(FBSDKGamingServiceType type)
{
  switch (type) {
    case FBSDKGamingServiceTypeFriendFinder:
      return kServiceTypeStringFriendFinder;

    case FBSDKGamingServiceTypeMediaAsset:
      return kServiceTypeStringMediaAsset;

    case FBSDKGamingServiceTypeCommunity:
      return kServiceTypeStringCommunity;
  }
}

static NSURL *FBSDKGamingServicesUrl(FBSDKGamingServiceType serviceType, NSString *argument)
{
  return
  [NSURL URLWithString:
   [NSString
    stringWithFormat:
    @"https://fb.gg/me/%@/%@",
    FBSDKGamingServiceTypeString(serviceType),
    argument]];
}

@interface FBSDKGamingServiceController ()

@property (nonatomic) FBSDKGamingServiceType serviceType;
@property (nonatomic) FBSDKGamingServiceResultCompletion completionHandler;
@property (nonatomic) id pendingResult;
@property (nonatomic) id<FBSDKURLOpener> urlOpener;
@property (nonatomic) id<FBSDKSettings> settings;

@end

@implementation FBSDKGamingServiceController

- (instancetype)initWithServiceType:(FBSDKGamingServiceType)serviceType
                  completionHandler:(FBSDKGamingServiceResultCompletion)completion
                      pendingResult:(id)pendingResult
{
  return [self initWithServiceType:serviceType
                 completionHandler:completion
                     pendingResult:pendingResult
                         urlOpener:FBSDKBridgeAPI.sharedInstance
                          settings:FBSDKSettings.sharedSettings];
}

- (instancetype)initWithServiceType:(FBSDKGamingServiceType)serviceType
                  completionHandler:(FBSDKGamingServiceResultCompletion)completion
                      pendingResult:(id)pendingResult
                          urlOpener:(id<FBSDKURLOpener>)urlOpener
                           settings:(id<FBSDKSettings>)settings
{
  if ((self = [super init])) {
    _serviceType = serviceType;
    _completionHandler = completion;
    _pendingResult = pendingResult;
    _urlOpener = urlOpener;
    _settings = settings;
  }
  return self;
}

- (void)callWithArgument:(nullable NSString *)argument
{
  __weak typeof(self) weakSelf = self;
  [self.urlOpener openURL:FBSDKGamingServicesUrl(_serviceType, argument)
                   sender:weakSelf
                  handler:^(BOOL success, NSError *_Nullable error) {
                    if (!success) {
                      [weakSelf handleBridgeAPIError:error];
                    }
                  }];
}

- (void)handleBridgeAPIError:(NSError *)error
{
  if (_completionHandler == nil) {
    return;
  }

  if (error) {
    _completionHandler(
      false,
      nil,
      [FBSDKError
       errorWithCode:FBSDKErrorBridgeAPIInterruption
       message:@"Error occured while interacting with Gaming Services"
       underlyingError:error]
    );
  } else {
    _completionHandler(
      false,
      nil,
      [FBSDKError
       errorWithCode:FBSDKErrorBridgeAPIInterruption
       message:@"An Unknown error occured while interacting with Gaming Services"]
    );
  }

  _completionHandler = nil;
}

- (void)completeSuccessfully
{
  _completionHandler(true, _pendingResult, nil);
  _completionHandler = nil;
}

#pragma mark - FBSDKURLOpening
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
  const BOOL isGamingUrl =
  [self
   canOpenURL:url
   forApplication:application
   sourceApplication:sourceApplication
   annotation:annotation];

  if (isGamingUrl && _completionHandler) {
    [self completeSuccessfully];
  }

  return isGamingUrl;
}

- (BOOL) canOpenURL:(NSURL *)url
     forApplication:(nullable UIApplication *)application
  sourceApplication:(nullable NSString *)sourceApplication
         annotation:(nullable id)annotation
{
  return
  [self
   isValidCallbackURL:url
   forService:FBSDKGamingServiceTypeString(_serviceType)];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  if (_completionHandler) {
    [self completeSuccessfully];
  }
}

- (BOOL)isAuthenticationURL:(NSURL *)url
{
  return false;
}

#pragma mark - Helpers

- (BOOL)isValidCallbackURL:(NSURL *)url forService:(NSString *)service
{
  // verify the URL is intended as a callback for the SDK's friend finder
  return
  [url.scheme hasPrefix:[NSString stringWithFormat:@"fb%@", self.settings.appID]]
  && [url.host isEqualToString:service];
}

- (id<FBSDKSettings>)settings
{
  return _settings;
}

@end
