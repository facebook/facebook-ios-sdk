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

#import "TargetConditionals.h"

#if !TARGET_OS_TV

 #import "FBSDKReferralManager+Internal.h"

 #ifdef FBSDKCOCOAPODS
  #import <FBSDKCoreKit/FBSDKCoreKit+Internal.h>
 #else
  #import "FBSDKCoreKit+Internal.h"
 #endif

 #import "FBSDKCoreKitBasicsImportForLoginKit.h"
 #import "FBSDKLoginConstants.h"
 #import "FBSDKReferralManagerLogger.h"
 #import "FBSDKReferralManagerResult.h"

static NSString *const FBSDKReferralPath = @"/dialog/share_referral";
static NSString *const ReferralCodesKey = @"fb_referral_codes";
static NSString *const ChalllengeKey = @"state";
static NSString *const SFVCCanceledLogin = @"com.apple.SafariServices.Authentication";
static NSString *const ASCanceledLogin = @"com.apple.AuthenticationServices.WebAuthenticationSession";
static int const FBClientStateChallengeLength = 20;

@implementation FBSDKReferralManager
{
  UIViewController *_viewController;
  FBSDKReferralManagerResultBlock _handler;
  FBSDKReferralManagerLogger *_logger;
  BOOL _isPerformingReferral;
  NSString *_expectedChallenge;
}

- (instancetype)initWithViewController:(UIViewController *)viewController
{
  self = [super init];
  if (self) {
    _viewController = viewController;
  }

  return self;
}

- (void)startReferralWithCompletionHandler:(FBSDKReferralManagerResultBlock)handler
{
  _handler = [handler copy];
  _logger = [FBSDKReferralManagerLogger new];

  [_logger logReferralStart];

  @try {
    [FBSDKInternalUtility validateURLSchemes];
  } @catch (NSException *exception) {
    NSError *error = [FBSDKError errorWithCode:FBSDKLoginErrorUnknown
                                       message:[NSString stringWithFormat:@"%@: %@", exception.name, exception.reason]];
    [self handleReferralError:error];
    return;
  }

  NSURL *referralURL = [self referralURL];
  if (referralURL) {
    void (^completionHandler)(BOOL, NSError *) = ^(BOOL didOpen, NSError *error) {
      [self handleOpenURLComplete:didOpen error:error];
    };

    [[FBSDKBridgeAPI sharedInstance] openURLWithSafariViewController:referralURL
                                                              sender:self
                                                  fromViewController:_viewController
                                                             handler:completionHandler];
  }
}

- (NSURL *)referralURL
{
  NSError *error;
  NSURL *url;
  NSMutableDictionary *params = [NSMutableDictionary dictionary];

  [FBSDKTypeUtility dictionary:params setObject:FBSDKSettings.appID forKey:@"app_id"];

  _expectedChallenge = [self stringForChallenge];
  [FBSDKTypeUtility dictionary:params setObject:_expectedChallenge forKey:@"state"];

  NSURL *redirectURL = [FBSDKInternalUtility appURLWithHost:@"authorize" path:@"" queryParameters:@{} error:&error];
  if (!error) {
    [FBSDKTypeUtility dictionary:params setObject:redirectURL forKey:@"redirect_uri"];

    url = [FBSDKInternalUtility facebookURLWithHostPrefix:@"m."
                                                     path:FBSDKReferralPath
                                          queryParameters:params
                                                    error:&error];
  }

  if (error || !url) {
    error = error ?: [FBSDKError errorWithCode:FBSDKLoginErrorUnknown message:@"Failed to construct referral browser url"];
    [self handleReferralError:error];
    return nil;
  }

  return url;
}

- (NSString *)stringForChallenge
{
  NSString *challenge = fb_randomString(FBClientStateChallengeLength);

  return [challenge stringByReplacingOccurrencesOfString:@"+" withString:@"="];
}

- (void)invokeHandler:(FBSDKReferralManagerResult *)result error:(NSError *)error
{
  _isPerformingReferral = NO;
  [_logger logReferralEnd:result error:error];
  _logger = nil;

  if (_handler) {
    _handler(result, error);
    _handler = nil;
  }
}

- (void)handleReferralCancel
{
  FBSDKReferralManagerResult *result = [[FBSDKReferralManagerResult alloc] initWithReferralCodes:nil isCancelled:YES];
  [self invokeHandler:result error:(NSError *)nil];
}

- (void)handleReferralError:(NSError *)error
{
  [self invokeHandler:nil error:error];
}

- (void)handleOpenURLComplete:(BOOL)didOpen error:(NSError *)error
{
  if (didOpen) {
    self->_isPerformingReferral = YES;
  } else if ([error.domain isEqualToString:SFVCCanceledLogin]
             || [error.domain isEqualToString:ASCanceledLogin]) {
    [self handleReferralCancel];
  } else {
    if (!error) {
      error = [FBSDKError errorWithCode:FBSDKLoginErrorUnknown message:@"Failed to open referral dialog"];
    }
    [self handleReferralError:error];
  }
}

- (BOOL)validateChallenge:(NSString *)challenge
{
  BOOL challengeValid = YES;
  if (_expectedChallenge && ![_expectedChallenge isEqualToString:challenge]) {
    challengeValid = NO;
  }

  _expectedChallenge = nil;
  return challengeValid;
}

 #pragma mark - FBSDKURLOpening

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
  BOOL isFacebookURL = [self canOpenURL:url
                           forApplication:application
                        sourceApplication:sourceApplication
                               annotation:annotation];

  if (isFacebookURL) {
    NSError *error;
    NSDictionary *params = [FBSDKInternalUtility parametersFromFBURL:url];

    if (![self validateChallenge:params[ChalllengeKey]]) {
      error = [FBSDKError errorWithCode:FBSDKLoginErrorBadChallengeString
                                message:@"The referral response was missing a valid challenge string"];
      [self handleReferralError:error];
      return YES;
    }

    NSString *rawReferralCodes = params[ReferralCodesKey];
    NSArray<FBSDKJSONField *> *referralCodesJSON = [FBSDKCreateJSONFromString(rawReferralCodes, &error) matchArrayOrNil];
    if (!error) {
      NSMutableArray<FBSDKReferralCode *> *referralCodes = [NSMutableArray array];
      for (FBSDKJSONField *object in referralCodesJSON) {
        FBSDKReferralCode *referralCode = [FBSDKReferralCode initWithString:[FBSDKTypeUtility coercedToStringValue:[object rawObject]]];
        if (referralCode) {
          [FBSDKTypeUtility array:referralCodes addObject:referralCode];
        }
      }

      FBSDKReferralManagerResult *result = [[FBSDKReferralManagerResult alloc]initWithReferralCodes:referralCodes isCancelled:NO];
      [self invokeHandler:result error:nil];
    } else {
      [self handleReferralError:error];
    }
  } else if (_isPerformingReferral) {
    [self handleReferralCancel];
  }

  return isFacebookURL;
}

- (BOOL) canOpenURL:(NSURL *)url
     forApplication:(UIApplication *)application
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
  // verify the URL is intended as a callback for the SDK's referral request
  return [url.scheme hasPrefix:[NSString stringWithFormat:@"fb%@", FBSDKSettings.appID]]
  && [url.host isEqualToString:@"authorize"];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  // Do nothing since currently we don't switch to external app
}

- (BOOL)isAuthenticationURL:(NSURL *)url
{
  return [url.path hasSuffix:FBSDKReferralPath];
}

@end

#endif
