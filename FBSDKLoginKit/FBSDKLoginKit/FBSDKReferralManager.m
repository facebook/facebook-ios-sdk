/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKReferralManager+Internal.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKLoginConstants.h"
#import "FBSDKReferralManagerLogger.h"
#import "FBSDKReferralManagerResult.h"

static NSString *const FBSDKReferralPath = @"/dialog/share_referral";
static NSString *const ReferralCodesKey = @"fb_referral_codes";
static NSString *const ChalllengeKey = @"state";
static NSString *const SFVCCanceledLogin = @"com.apple.SafariServices.Authentication";
static NSString *const ASCanceledLogin = @"com.apple.AuthenticationServices.WebAuthenticationSession";
static int const FBClientStateChallengeLength = 20;

@interface FBSDKReferralManager ()
@property (nonatomic) NSString *expectedChallenge;
@property (nonatomic) UIViewController *viewController;
@property (nonatomic) FBSDKReferralManagerResultBlock handler;
@property (nonatomic) FBSDKReferralManagerLogger *logger;
@property (nonatomic) BOOL isPerformingReferral;
@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
@implementation FBSDKReferralManager

static _Nullable id<FBSDKBridgeAPIRequestOpening> _bridgeAPIRequestOpener;

- (id<FBSDKBridgeAPIRequestOpening>)bridgeAPIRequestOpener
{
  if (!_bridgeAPIRequestOpener) {
    _bridgeAPIRequestOpener = FBSDKBridgeAPI.sharedInstance;
  }
  return _bridgeAPIRequestOpener;
}

+ (void)setBridgeAPIRequestOpener:(nullable id<FBSDKBridgeAPIRequestOpening>)bridgeAPIRequestOpener
{
  _bridgeAPIRequestOpener = bridgeAPIRequestOpener;
}

- (instancetype)initWithViewController:(nullable UIViewController *)viewController
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
    [FBSDKInternalUtility.sharedUtility validateURLSchemes];
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

    [self.bridgeAPIRequestOpener openURLWithSafariViewController:referralURL
                                                          sender:self
                                              fromViewController:_viewController
                                                         handler:completionHandler];
  }
}

- (nullable NSURL *)referralURL
{
  NSError *error;
  NSURL *url;
  NSMutableDictionary<NSString *, id> *params = [NSMutableDictionary dictionary];

  [FBSDKTypeUtility dictionary:params setObject:FBSDKSettings.sharedSettings.appID forKey:@"app_id"];

  _expectedChallenge = [self stringForChallenge];
  [FBSDKTypeUtility dictionary:params setObject:_expectedChallenge forKey:@"state"];

  NSURL *redirectURL = [FBSDKInternalUtility.sharedUtility appURLWithHost:@"authorize" path:@"" queryParameters:@{} error:&error];
  if (!error) {
    [FBSDKTypeUtility dictionary:params setObject:redirectURL forKey:@"redirect_uri"];

    url = [FBSDKInternalUtility.sharedUtility facebookURLWithHostPrefix:@"m."
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

- (void)invokeHandler:(nullable FBSDKReferralManagerResult *)result error:(NSError *)error
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
    NSDictionary<NSString *, id> *params = [FBSDKInternalUtility.sharedUtility parametersFromFBURL:url];

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
     forApplication:(nullable UIApplication *)application
  sourceApplication:(nullable NSString *)sourceApplication
         annotation:(nullable id)annotation
{
  // verify the URL is intended as a callback for the SDK's referral request
  return [url.scheme hasPrefix:[NSString stringWithFormat:@"fb%@", FBSDKSettings.sharedSettings.appID]]
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
#pragma clang diagnostic pop

#endif
