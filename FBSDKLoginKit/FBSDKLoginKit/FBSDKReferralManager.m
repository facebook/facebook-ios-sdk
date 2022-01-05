/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
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
static NSString *const ChallengeKey = @"state";
static NSString *const SFVCCanceledLogin = @"com.apple.SafariServices.Authentication";
static NSString *const ASCanceledLogin = @"com.apple.AuthenticationServices.WebAuthenticationSession";
static int const FBClientStateChallengeLength = 20;

@interface FBSDKReferralManager ()

@property (class, nonatomic) BOOL hasBeenConfigured;
@property (nonatomic) NSString *expectedChallenge;
@property (nonatomic) UIViewController *viewController;
@property (nonatomic) FBSDKReferralManagerResultBlock handler;
@property (nonatomic) FBSDKReferralManagerLogger *logger;
@property (nonatomic) BOOL isPerformingReferral;

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
@implementation FBSDKReferralManager

static BOOL _hasBeenConfigured = NO;

+ (BOOL)hasBeenConfigured
{
  return _hasBeenConfigured;
}

+ (void)setHasBeenConfigured:(BOOL)hasBeenConfigured
{
  _hasBeenConfigured = hasBeenConfigured;
}

static _Nullable id<FBSDKBridgeAPIRequestOpening> _bridgeAPIRequestOpener;

+ (nullable id<FBSDKBridgeAPIRequestOpening>)bridgeAPIRequestOpener
{
  return _bridgeAPIRequestOpener;
}

+ (void)setBridgeAPIRequestOpener:(nullable id<FBSDKBridgeAPIRequestOpening>)bridgeAPIRequestOpener
{
  _bridgeAPIRequestOpener = bridgeAPIRequestOpener;
}

static _Nullable id<FBSDKInternalUtility> _internalUtility;

+ (nullable id<FBSDKInternalUtility>)internalUtility
{
  return _internalUtility;
}

+ (void)setInternalUtility:(nullable id<FBSDKInternalUtility>)internalUtility
{
  _internalUtility = internalUtility;
}

static _Nullable id<FBSDKSettings> _settings;

+ (nullable id<FBSDKSettings>)settings
{
  return _settings;
}

+ (void)setSettings:(nullable id<FBSDKSettings>)settings
{
  _settings = settings;
}

static _Nullable id<FBSDKErrorCreating> _errorFactory;

+ (nullable id<FBSDKErrorCreating>)errorFactory
{
  return _errorFactory;
}

+ (void)setErrorFactory:(nullable id<FBSDKErrorCreating>)errorFactory
{
  _errorFactory = errorFactory;
}

+ (void)configureWithBridgeAPIRequestOpener:(id<FBSDKBridgeAPIRequestOpening>)bridgeAPIRequestOpener
                            internalUtility:(id<FBSDKInternalUtility>)internalUtility
                                   settings:(id<FBSDKSettings>)settings
                               errorFactory:(id<FBSDKErrorCreating>)errorFactory
{
  if (self.hasBeenConfigured) {
    return;
  }

  self.bridgeAPIRequestOpener = bridgeAPIRequestOpener;
  self.internalUtility = internalUtility;
  self.settings = settings;
  self.errorFactory = errorFactory;

  self.hasBeenConfigured = YES;
}

+ (void)configureClassDependencies
{
  [self configureWithBridgeAPIRequestOpener:FBSDKBridgeAPI.sharedInstance
                            internalUtility:FBSDKInternalUtility.sharedUtility
                                   settings:FBSDKSettings.sharedSettings
                               errorFactory:[FBSDKErrorFactory new]];
}

#if FBTEST

+ (void)resetClassDependencies
{
  self.bridgeAPIRequestOpener = nil;
  self.internalUtility = nil;
  self.settings = nil;
  self.errorFactory = nil;

  self.hasBeenConfigured = NO;
}

#endif

- (instancetype)init
{
  if ((self = [super init])) {
    [self.class configureClassDependencies];
  }

  return self;
}

- (instancetype)initWithViewController:(nullable UIViewController *)viewController
{
  if ((self = [self init])) {
    _viewController = viewController;
  }

  return self;
}

- (void)startReferralWithCompletionHandler:(nullable FBSDKReferralManagerResultBlock)handler
{
  self.handler = [handler copy];
  self.logger = [FBSDKReferralManagerLogger new];

  [self.logger logReferralStart];

  @try {
    [self.class.internalUtility validateURLSchemes];
  } @catch (NSException *exception) {
    NSError *error = [self.class.errorFactory errorWithCode:FBSDKLoginErrorUnknown
                                                   userInfo:nil
                                                    message:[NSString stringWithFormat:@"%@: %@", exception.name, exception.reason]
                                            underlyingError:nil];
    [self handleReferralError:error];
    return;
  }

  NSURL *referralURL = [self referralURL];
  if (referralURL) {
    void (^completionHandler)(BOOL, NSError *) = ^(BOOL didOpen, NSError *error) {
      [self handleOpenURLComplete:didOpen error:error];
    };

    [self.class.bridgeAPIRequestOpener openURLWithSafariViewController:referralURL
                                                                sender:self
                                                    fromViewController:self.viewController
                                                               handler:completionHandler];
  }
}

- (nullable NSURL *)referralURL
{
  NSError *error;
  NSURL *url;
  NSMutableDictionary<NSString *, NSString *> *params = [NSMutableDictionary dictionary];

  [FBSDKTypeUtility dictionary:params setObject:self.class.settings.appID forKey:@"app_id"];

  self.expectedChallenge = [self stringForChallenge];
  [FBSDKTypeUtility dictionary:params setObject:self.expectedChallenge forKey:@"state"];

  NSURL *redirectURL = [self.class.internalUtility appURLWithHost:@"authorize" path:@"" queryParameters:@{} error:&error];
  if (!error) {
    [FBSDKTypeUtility dictionary:params setObject:redirectURL.absoluteString forKey:@"redirect_uri"];

    url = [self.class.internalUtility facebookURLWithHostPrefix:@"m."
                                                           path:FBSDKReferralPath
                                                queryParameters:params
                                                          error:&error];
  }

  if (error || !url) {
    if (!error) {
      error = [self.class.errorFactory errorWithCode:FBSDKLoginErrorUnknown
                                            userInfo:nil
                                             message:@"Failed to construct referral browser url"
                                     underlyingError:nil];
    }
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
  self.isPerformingReferral = NO;
  [self.logger logReferralEnd:result error:error];
  self.logger = nil;

  if (self.handler) {
    self.handler(result, error);
    self.handler = nil;
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
    self.isPerformingReferral = YES;
  } else if ([error.domain isEqualToString:SFVCCanceledLogin]
             || [error.domain isEqualToString:ASCanceledLogin]) {
    [self handleReferralCancel];
  } else {
    if (!error) {
      error = [self.class.errorFactory errorWithCode:FBSDKLoginErrorUnknown
                                            userInfo:nil
                                             message:@"Failed to open referral dialog"
                                     underlyingError:nil];
    }
    [self handleReferralError:error];
  }
}

- (BOOL)validateChallenge:(NSString *)challenge
{
  BOOL challengeValid = YES;
  if (self.expectedChallenge && ![self.expectedChallenge isEqualToString:challenge]) {
    challengeValid = NO;
  }

  self.expectedChallenge = nil;
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
    NSDictionary<NSString *, id> *params = [self.class.internalUtility parametersFromFBURL:url];

    if (![self validateChallenge:params[ChallengeKey]]) {
      error = [self.class.errorFactory errorWithCode:FBSDKLoginErrorBadChallengeString
                                            userInfo:nil
                                             message:@"The referral response was missing a valid challenge string"
                                     underlyingError:nil];
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
  } else if (self.isPerformingReferral) {
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
  return [url.scheme hasPrefix:[NSString stringWithFormat:@"fb%@", self.class.settings.appID]]
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
