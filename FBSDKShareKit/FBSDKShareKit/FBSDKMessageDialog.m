/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKMessageDialog.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKShareAppEventName.h"
#import "FBSDKShareAppEventParameters.h"
#import "FBSDKShareDefines.h"
#import "FBSDKShareDialogConfiguration+Internal.h"
#import "FBSDKShareDialogConfigurationProtocol.h"
#import "FBSDKShareUtility.h"
#import "FBSDKShareVideoContent.h"

#define FBSDK_MESSAGE_DIALOG_APP_SCHEME @"fb-messenger-share-api"

@interface FBSDKMessageDialog ()

@property (nonatomic) id<FBSDKAppAvailabilityChecker> appAvailabilityChecker;
@property (nonatomic) id<FBSDKShareDialogConfiguration> shareDialogConfiguration;

@end

@implementation FBSDKMessageDialog

NSString *const FBSDKAppEventParameterDialogShareContentPageID = @"fb_dialog_share_content_page_id";
NSString *const FBSDKAppEventParameterDialogShareContentUUID = @"fb_dialog_share_content_uuid";

#pragma mark - Class Methods

+ (void)initialize
{
  if (FBSDKMessageDialog.class == self) {
    [FBSDKInternalUtility.sharedUtility checkRegisteredCanOpenURLScheme:FBSDKURLSchemeMessengerApp];
  }
}

- (instancetype)init
{
  return [self initWithContent:nil delegate:nil];
}

- (instancetype)initWithContent:(nullable id<FBSDKSharingContent>)content
                       delegate:(nullable id<FBSDKSharingDelegate>)delegate
{
  return [self initWithContent:content
                          delegate:delegate
            appAvailabilityChecker:FBSDKInternalUtility.sharedUtility
          shareDialogConfiguration:[FBSDKShareDialogConfiguration new]];
}

- (instancetype)initWithContent:(nullable id<FBSDKSharingContent>)content
                       delegate:(nullable id<FBSDKSharingDelegate>)delegate
         appAvailabilityChecker:(nonnull id<FBSDKAppAvailabilityChecker>)appAvailabilityChecker
       shareDialogConfiguration:(nonnull id<FBSDKShareDialogConfiguration>)shareDialogConfiguration
{
  if ((self = [super init])) {
    _shareContent = content;
    _delegate = delegate;
    _appAvailabilityChecker = appAvailabilityChecker;
    _shareDialogConfiguration = shareDialogConfiguration;
  }

  return self;
}

+ (instancetype)dialogWithContent:(nullable id<FBSDKSharingContent>)content
                         delegate:(nullable id<FBSDKSharingDelegate>)delegate
{
  return [[self alloc] initWithContent:content delegate:delegate];
}

+ (instancetype)showWithContent:(nullable id<FBSDKSharingContent>)content
                       delegate:(nullable id<FBSDKSharingDelegate>)delegate
{
  FBSDKMessageDialog *dialog = [[self alloc] initWithContent:content delegate:delegate];
  [dialog show];
  return dialog;
}

#pragma mark - Properties

@synthesize delegate = _delegate;
@synthesize shareContent = _shareContent;
@synthesize shouldFailOnDataError = _shouldFailOnDataError;

#pragma mark - Public Methods

- (BOOL)canShow
{
  return [self _canShowNative];
}

- (BOOL)show
{
  NSError *error;
  if (!self.canShow) {
    error = [FBSDKError errorWithDomain:FBSDKShareErrorDomain
                                   code:FBSDKShareErrorDialogNotAvailable
                                message:@"Message dialog is not available."];
    [self _invokeDelegateDidFailWithError:error];
    return NO;
  }
  if (![self validateWithError:&error]) {
    [self _invokeDelegateDidFailWithError:error];
    return NO;
  }

  id<FBSDKSharingContent> shareContent = self.shareContent;
  NSDictionary<NSString *, id> *parameters = [FBSDKShareUtility parametersForShareContent:shareContent
                                                                            bridgeOptions:FBSDKShareBridgeOptionsDefault
                                                                    shouldFailOnDataError:self.shouldFailOnDataError];
  NSString *methodName = ([shareContent isKindOfClass:NSClassFromString(@"FBSDKShareOpenGraphContent")]
    ? FBSDK_SHARE_OPEN_GRAPH_METHOD_NAME
    : FBSDK_SHARE_METHOD_NAME);
  FBSDKBridgeAPIRequest *request;
  request = [FBSDKBridgeAPIRequest bridgeAPIRequestWithProtocolType:FBSDKBridgeAPIProtocolTypeNative
                                                             scheme:FBSDK_MESSAGE_DIALOG_APP_SCHEME
                                                         methodName:methodName
                                                         parameters:parameters
                                                           userInfo:nil];
  BOOL useSafariViewController = [[FBSDKShareDialogConfiguration new]
                                  shouldUseSafariViewControllerForDialogName:FBSDKDialogConfigurationNameMessage];
  FBSDKBridgeAPIResponseBlock completionBlock = ^(FBSDKBridgeAPIResponse *response) {
    [self _handleCompletionWithDialogResults:response.responseParameters response:response];
    [FBSDKInternalUtility.sharedUtility unregisterTransientObject:self];
  };
  [FBSDKBridgeAPI.sharedInstance openBridgeAPIRequest:request
                              useSafariViewController:useSafariViewController
                                   fromViewController:nil
                                      completionBlock:completionBlock];

  [self _logDialogShow];
  [FBSDKInternalUtility.sharedUtility registerTransientObject:self];
  return YES;
}

- (BOOL)validateWithError:(NSError *__autoreleasing *)errorRef
{
  if (self.shareContent) {
    if ([self.shareContent isKindOfClass:FBSDKShareLinkContent.class]
        || [self.shareContent isKindOfClass:FBSDKSharePhotoContent.class]
        || [self.shareContent isKindOfClass:FBSDKShareVideoContent.class]) {} else {
      if (errorRef != NULL) {
        NSString *message = [NSString stringWithFormat:@"Message dialog does not support %@.",
                             NSStringFromClass(self.shareContent.class)];
        *errorRef = [FBSDKError requiredArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                           name:@"shareContent"
                                                        message:message];
      }
      return NO;
    }
  }
  return [FBSDKShareUtility validateShareContent:self.shareContent
                                   bridgeOptions:FBSDKShareBridgeOptionsDefault
                                           error:errorRef];
}

- (BOOL)_canShowNative
{
  BOOL useNativeDialog = [self.shareDialogConfiguration
                          shouldUseNativeDialogForDialogName:FBSDKDialogConfigurationNameMessage];

  return (useNativeDialog && [self.appAvailabilityChecker isMessengerAppInstalled]);
}

- (void)_handleCompletionWithDialogResults:(NSDictionary<NSString *, id> *)results response:(FBSDKBridgeAPIResponse *)response
{
  NSString *completionGesture = results[FBSDK_SHARE_RESULT_COMPLETION_GESTURE_KEY];
  if ([completionGesture isEqualToString:FBSDK_SHARE_RESULT_COMPLETION_GESTURE_VALUE_CANCEL]
      || response.isCancelled) {
    [self _invokeDelegateDidCancel];
  } else if (response.error) {
    [self _invokeDelegateDidFailWithError:response.error];
  } else {
    [self _invokeDelegateDidCompleteWithResults:results];
  }
}

- (void)_invokeDelegateDidCancel
{
  NSDictionary<NSString *, id> *parameters = @{
    FBSDKAppEventParameterDialogOutcome : FBSDKAppEventsDialogOutcomeValue_Cancelled,
  };

  [FBSDKAppEvents.shared logInternalEvent:FBSDKAppEventNameMessengerShareDialogResult
                               parameters:parameters
                       isImplicitlyLogged:YES
                              accessToken:FBSDKAccessToken.currentAccessToken];

  if (!_delegate) {
    return;
  }

  [_delegate sharerDidCancel:self];
}

- (void)_invokeDelegateDidCompleteWithResults:(NSDictionary<NSString *, id> *)results
{
  NSDictionary<NSString *, id> *parameters = @{
    FBSDKAppEventParameterDialogOutcome : FBSDKAppEventsDialogOutcomeValue_Completed,
  };

  [FBSDKAppEvents.shared logInternalEvent:FBSDKAppEventNameMessengerShareDialogResult
                               parameters:parameters
                       isImplicitlyLogged:YES
                              accessToken:FBSDKAccessToken.currentAccessToken];

  if (!_delegate) {
    return;
  }

  [_delegate sharer:self didCompleteWithResults:[results copy]];
}

- (void)_invokeDelegateDidFailWithError:(NSError *)error
{
  NSMutableDictionary<NSString *, id> *parameters = [@{FBSDKAppEventParameterDialogOutcome : FBSDKAppEventsDialogOutcomeValue_Failed} mutableCopy];
  if (error) {
    [FBSDKTypeUtility dictionary:parameters setObject:[NSString stringWithFormat:@"%@", error] forKey:FBSDKAppEventParameterDialogErrorMessage];

    [FBSDKAppEvents.shared logInternalEvent:FBSDKAppEventNameMessengerShareDialogResult
                                 parameters:parameters
                         isImplicitlyLogged:YES
                                accessToken:FBSDKAccessToken.currentAccessToken];

    if (!_delegate) {
      return;
    }

    [_delegate sharer:self didFailWithError:error];
  }
}

- (void)_logDialogShow
{
  NSString *contentType;
  if ([self.shareContent isKindOfClass:FBSDKShareLinkContent.class]) {
    contentType = FBSDKAppEventsDialogShareContentTypeStatus;
  } else if ([self.shareContent isKindOfClass:FBSDKSharePhotoContent.class]) {
    contentType = FBSDKAppEventsDialogShareContentTypePhoto;
  } else if ([self.shareContent isKindOfClass:FBSDKShareVideoContent.class]) {
    contentType = FBSDKAppEventsDialogShareContentTypeVideo;
  } else {
    contentType = FBSDKAppEventsDialogShareContentTypeUnknown;
  }

  NSDictionary<NSString *, id> *parameters = @{FBSDKAppEventParameterDialogShareContentType : contentType,
                                               FBSDKAppEventParameterDialogShareContentUUID : self.shareContent.shareUUID ?: [NSNull null],
                                               FBSDKAppEventParameterDialogShareContentPageID : self.shareContent.pageID ?: [NSNull null]};

  [FBSDKAppEvents.shared logInternalEvent:FBSDKAppEventNameMessengerShareDialogShow
                               parameters:parameters
                       isImplicitlyLogged:YES
                              accessToken:FBSDKAccessToken.currentAccessToken];
}

@end

#endif
