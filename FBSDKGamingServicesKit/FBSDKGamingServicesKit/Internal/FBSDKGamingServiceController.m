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

#import "FBSDKGamingServiceController.h"

#import "FBSDKCoreKitInternalImport.h"

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

@implementation FBSDKGamingServiceController
{
  FBSDKGamingServiceType _serviceType;
  FBSDKGamingServiceResultCompletionHandler _completionHandler;
  id _pendingResult;
}

- (instancetype)initWithServiceType:(FBSDKGamingServiceType)serviceType
                  completionHandler:(FBSDKGamingServiceResultCompletionHandler)completionHandler
                      pendingResult:(id)pendingResult
{
  if (self = [super init]) {
    _serviceType = serviceType;
    _completionHandler = completionHandler;
    _pendingResult = pendingResult;
  }
  return self;
}

- (void)callWithArgument:(NSString *)argument
{
  __weak typeof(self) weakSelf = self;
  [[FBSDKBridgeAPI sharedInstance]
   openURL:FBSDKGamingServicesUrl(_serviceType, argument)
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
- (BOOL)  openURL:(NSURL *)url
sourceApplication:(NSString *)sourceApplication
       annotation:(id)annotation
{
  const BOOL isGamingUrl =
  [self
   canOpenURL:url
   sourceApplication:sourceApplication
   annotation:annotation];

  if (isGamingUrl && _completionHandler) {
    [self completeSuccessfully];
  }

  return isGamingUrl;
}

- (BOOL)canOpenURL:(NSURL *)url
 sourceApplication:(NSString *)sourceApplication
        annotation:(id)annotation
{
  return
  [self
   isValidCallbackURL:url
   forService:FBSDKGamingServiceTypeString(_serviceType)];
}

- (void)applicationDidBecomeActive
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
  [url.scheme hasPrefix:[NSString stringWithFormat:@"fb%@", [FBSDKSettings appID]]]
  && [url.host isEqualToString:service];
}

@end
