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

#import "FBSDKShareDialog.h"

#import <Social/Social.h>

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKShareConstants.h"
#import "FBSDKShareDefines.h"
#import "FBSDKShareError.h"
#import "FBSDKShareLinkContent.h"
#import "FBSDKShareOpenGraphAction.h"
#import "FBSDKShareOpenGraphContent.h"
#import "FBSDKShareOpenGraphObject.h"
#import "FBSDKSharePhoto.h"
#import "FBSDKSharePhotoContent.h"
#import "FBSDKShareUtility.h"
#import "FBSDKShareVideo.h"
#import "FBSDKShareVideoContent.h"

#define FBSDK_SHARE_DIALOG_APP_SCHEME @"fbapi"
#define FBSDK_SHARE_FEED_METHOD_NAME @"feed"
#define FBSDK_SHARE_METHOD_MIN_VERSION @"20130410"
#define FBSDK_SHARE_METHOD_OG_MIN_VERSION @"20130214"
#define FBSDK_SHARE_METHOD_OG_IMAGE_MIN_VERSION @"20130410"
#define FBSDK_SHARE_METHOD_PHOTOS_MIN_VERSION @"20140116"
#define FBSDK_SHARE_METHOD_VIDEO_MIN_VERSION @"20150313"
#define FBSDK_SHARE_METHOD_ATTRIBUTED_SHARE_SHEET_MIN_VERSION @"20150629"

@interface FBSDKShareDialog () <FBSDKWebDialogDelegate>
@end

@implementation FBSDKShareDialog
{
  FBSDKWebDialog *_webDialog;
}

#pragma mark - Class Methods

+ (instancetype)showFromViewController:(UIViewController *)viewController
                           withContent:(id<FBSDKSharingContent>)content
                              delegate:(id<FBSDKSharingDelegate>)delegate
{
  FBSDKShareDialog *dialog = [[self alloc] init];
  dialog.fromViewController = viewController;
  dialog.shareContent = content;
  dialog.delegate = delegate;
  [dialog show];
  return dialog;
}

#pragma mark - Object Lifecycle

- (void)dealloc
{
  _webDialog.delegate = nil;
}

#pragma mark - Properties

@synthesize delegate = _delegate;
@synthesize shareContent = _shareContent;
@synthesize shouldFailOnDataError = _shouldFailOnDataError;

#pragma mark - Public Methods

- (BOOL)canShow
{
  switch (self.mode) {
    case FBSDKShareDialogModeAutomatic:
    case FBSDKShareDialogModeBrowser:
    case FBSDKShareDialogModeFeedBrowser:
    case FBSDKShareDialogModeFeedWeb:
    case FBSDKShareDialogModeWeb:{
      return YES;
    }
    case FBSDKShareDialogModeNative:{
      return [self _canShowNativeWithMethodName:NULL methodVersion:NULL];
    }
    case FBSDKShareDialogModeShareSheet:{
      return [self _canShowShareSheet];
    }
  }
}

- (BOOL)show
{
  BOOL didShow = NO;
  NSError *error = nil;
  switch (self.mode) {
    case FBSDKShareDialogModeAutomatic:{
      // use the first validation error that fails, ignore canShow errors
      didShow = ([self _showNativeWithCanShowError:NULL validationError:&error] ||
                 [self _showShareSheetWithCanShowError:NULL validationError:&error] ||
                 [self _showFeedBrowser:&error] ||
                 [self _showFeedWeb:&error] ||
                 [self _showBrowser:&error] ||
                 [self _showWeb:&error]);
      break;
    }
    case FBSDKShareDialogModeBrowser:{
      didShow = [self _showBrowser:&error];
      break;
    }
    case FBSDKShareDialogModeFeedBrowser:{
      didShow = [self _showFeedBrowser:&error];
      break;
    }
    case FBSDKShareDialogModeFeedWeb:{
      didShow = [self _showFeedWeb:&error];
      break;
    }
    case FBSDKShareDialogModeNative:{
      didShow = [self _showNativeWithCanShowError:&error validationError:&error];
      break;
    }
    case FBSDKShareDialogModeShareSheet:{
      didShow = [self _showShareSheetWithCanShowError:&error validationError:&error];
      break;
    }
    case FBSDKShareDialogModeWeb:{
      didShow = [self _showWeb:&error];
      break;
    }
  }
  if (!didShow) {
    [self _invokeDelegateDidFailWithError:error];
  } else {
    [self _logDialogShow];
    [FBSDKInternalUtility registerTransientObject:self];
  }
  return didShow;
}

- (BOOL)validateWithError:(NSError *__autoreleasing *)errorRef
{
  if (errorRef != NULL) {
    *errorRef = nil;
  }
  id<FBSDKSharingContent> shareContent = self.shareContent;
  if (!shareContent) {
    if (errorRef != NULL) {
      *errorRef = [FBSDKShareError requiredArgumentErrorWithName:@"shareContent" message:nil];
    }
    return NO;
  }
  if (![FBSDKShareUtility validateShareContent:shareContent error:errorRef]) {
    return NO;
  }
  switch (self.mode) {
    case FBSDKShareDialogModeAutomatic:{
      return (
              ([self _canShowNativeWithMethodName:NULL methodVersion:NULL] && [self _validateShareContentForNative:errorRef]) ||
              ([self _canShowShareSheet] && [self _validateShareContentForShareSheet:errorRef]) ||
              [self _validateShareContentForFeed:errorRef] ||
              [self _validateShareContentForBrowser:errorRef]);
    }
    case FBSDKShareDialogModeNative:{
      return [self _validateShareContentForNative:errorRef];
    }
    case FBSDKShareDialogModeShareSheet:{
      return [self _validateShareContentForShareSheet:errorRef];
    }
    case FBSDKShareDialogModeBrowser:
    case FBSDKShareDialogModeWeb:{
      return [self _validateShareContentForBrowser:errorRef];
    }
    case FBSDKShareDialogModeFeedBrowser:
    case FBSDKShareDialogModeFeedWeb:{
      return [self _validateShareContentForFeed:errorRef];
    }
  }
}

#pragma mark - FBSDKWebDialogDelegate

- (void)webDialog:(FBSDKWebDialog *)webDialog didCompleteWithResults:(NSDictionary *)results
{
  if (_webDialog != webDialog) {
    return;
  }
  [self _cleanUpWebDialog];
  NSInteger errorCode = [results[@"error_code"] integerValue];
  if (errorCode == 4201) {
    [self _invokeDelegateDidCancel];
  } else {
    // not all web dialogs report cancellation, so assume that the share has completed with no additional information
    [self _handleWebResponseParameters:results error:nil];
  }
  [FBSDKInternalUtility unregisterTransientObject:self];
}

- (void)webDialog:(FBSDKWebDialog *)webDialog didFailWithError:(NSError *)error
{
  if (_webDialog != webDialog) {
    return;
  }
  [self _cleanUpWebDialog];
  [self _invokeDelegateDidFailWithError:error];
  [FBSDKInternalUtility unregisterTransientObject:self];
}

- (void)webDialogDidCancel:(FBSDKWebDialog *)webDialog
{
  if (_webDialog != webDialog) {
    return;
  }
  [self _cleanUpWebDialog];
  [self _invokeDelegateDidCancel];
  [FBSDKInternalUtility unregisterTransientObject:self];
}

#pragma mark - Helper Methods

- (BOOL)_canShowNativeWithMethodName:(NSString **)methodNameRef methodVersion:(NSString **)methodVersionRef
{
  if (methodNameRef != NULL) {
    *methodNameRef = nil;
  }
  if (methodVersionRef != NULL) {
    *methodVersionRef = nil;
  }
  NSString *scheme = FBSDK_SHARE_DIALOG_APP_SCHEME;
  if (![FBSDKBridgeAPIRequest checkProtocolForType:FBSDKBridgeAPIProtocolTypeNative scheme:scheme]) {
    return NO;
  }

  id<FBSDKSharingContent> shareContent = self.shareContent;
  if (!shareContent) {
    return YES;
  }

  // if there is shareContent on the receiver already, we can check the minimum app version, otherwise we can only check
  // for an app that can handle the native share dialog
  NSString *methodName = nil;
  NSString *methodVersion = nil;
  if ([shareContent isKindOfClass:[FBSDKShareOpenGraphContent class]]) {
    methodName = FBSDK_SHARE_OPEN_GRAPH_METHOD_NAME;
    BOOL containsMedia = NO;
    [FBSDKShareUtility testShareContent:shareContent containsMedia:&containsMedia containsPhotos:NULL];
    if (containsMedia) {
      methodVersion = FBSDK_SHARE_METHOD_OG_IMAGE_MIN_VERSION;
    } else {
      methodVersion = FBSDK_SHARE_METHOD_OG_MIN_VERSION;
    }
  } else {
    methodName = FBSDK_SHARE_METHOD_NAME;
    if ([shareContent isKindOfClass:[FBSDKSharePhotoContent class]]) {
      methodVersion = FBSDK_SHARE_METHOD_PHOTOS_MIN_VERSION;
    } else if ([shareContent isKindOfClass:[FBSDKShareVideoContent class]]) {
      methodVersion = FBSDK_SHARE_METHOD_VIDEO_MIN_VERSION;
    } else {
      methodVersion = FBSDK_SHARE_METHOD_MIN_VERSION;
    }
  }
  NSURL *URL = [[NSURL alloc] initWithScheme:[scheme stringByAppendingString:methodVersion]
                                        host:nil
                                        path:@"/"];
  if (![[UIApplication sharedApplication] canOpenURL:URL]) {
    return NO;
  }
  if (methodNameRef != NULL) {
    *methodNameRef = methodName;
  }
  if (methodVersionRef != NULL) {
    *methodVersionRef = methodVersion;
  }
  return YES;
}

- (BOOL)_canShowShareSheet
{
  Class composeViewControllerClass = [fbsdkdfl_SLComposeViewControllerClass() class];
  if (!composeViewControllerClass) {
    return NO;
  }
  NSString *facebookServiceType = fbsdkdfl_SLServiceTypeFacebook();
  if (![composeViewControllerClass isAvailableForServiceType:facebookServiceType]) {
    return NO;
  }
  return YES;
}

- (BOOL)_canAttributeThroughShareSheet
{
  NSOperatingSystemVersion iOS8Version = { .majorVersion = 8, .minorVersion = 0, .patchVersion = 0 };
  if (![FBSDKInternalUtility isOSRunTimeVersionAtLeast:iOS8Version]) {
    return NO;
  }
  NSString *scheme = FBSDK_SHARE_DIALOG_APP_SCHEME;
  NSString *minimumVersion = FBSDK_SHARE_METHOD_ATTRIBUTED_SHARE_SHEET_MIN_VERSION;
  NSURL *URL = [[NSURL alloc] initWithScheme:[scheme stringByAppendingString:minimumVersion] host:nil path:@"/"];
  return [[UIApplication sharedApplication] canOpenURL:URL];
}

- (void)_cleanUpWebDialog
{
  _webDialog.delegate = nil;
  _webDialog = nil;
}

- (NSArray *)_contentImages
{
  id<FBSDKSharingContent> shareContent = self.shareContent;
  return ([shareContent isKindOfClass:[FBSDKSharePhotoContent class]] ?
          [((FBSDKSharePhotoContent *)shareContent).photos valueForKeyPath:@"@distinctUnionOfObjects.image"] :
          nil);
}

- (NSArray *)_contentURLs
{
  NSArray *URLs = nil;
  id<FBSDKSharingContent> shareContent = self.shareContent;
  if ([shareContent isKindOfClass:[FBSDKShareLinkContent class]]) {
    FBSDKShareLinkContent *linkContent = (FBSDKShareLinkContent *)shareContent;
    URLs = (linkContent.contentURL ? @[linkContent.contentURL] : nil);
  } else if ([shareContent isKindOfClass:[FBSDKSharePhotoContent class]]) {
    FBSDKSharePhotoContent *photoContent = (FBSDKSharePhotoContent *)shareContent;
    URLs = (photoContent.contentURL ? @[photoContent.contentURL] : nil);
  }
  return URLs;
}

- (void)_handleWebResponseParameters:(NSDictionary *)webResponseParameters error:(NSError *)error
{
  if (error) {
    [self _invokeDelegateDidFailWithError:error];
    return;
  } else {
    NSString *completionGesture = webResponseParameters[FBSDK_SHARE_RESULT_COMPLETION_GESTURE_KEY];
    if ([completionGesture isEqualToString:FBSDK_SHARE_RESULT_COMPLETION_GESTURE_VALUE_CANCEL]) {
      [self _invokeDelegateDidCancel];
    } else {
      // not all web dialogs report cancellation, so assume that the share has completed with no additional information
      NSMutableDictionary *results = [[NSMutableDictionary alloc] init];
      // the web response comes back with a different payload, so we need to translate it
      [FBSDKInternalUtility dictionary:results
                             setObject:webResponseParameters[FBSDK_SHARE_WEB_PARAM_POST_ID_KEY]
                                forKey:FBSDK_SHARE_RESULT_POST_ID_KEY];
      [self _invokeDelegateDidCompleteWithResults:results];
    }
  }
}

- (BOOL)_showBrowser:(NSError **)errorRef
{
  if (![self _validateShareContentForBrowser:errorRef]) {
    return NO;
  }
  id<FBSDKSharingContent> shareContent = self.shareContent;
  NSString *methodName;
  NSDictionary *parameters;
  if (![FBSDKShareUtility buildWebShareContent:shareContent
                                    methodName:&methodName
                                    parameters:&parameters
                                         error:errorRef]) {
    return NO;
  }
  FBSDKBridgeAPICallbackBlock completionBlock = ^(FBSDKBridgeAPIResponse *response) {
    [self _handleWebResponseParameters:response.responseParameters error:response.error];
    [FBSDKInternalUtility unregisterTransientObject:self];
  };
  FBSDKBridgeAPIRequest *request;
  request = [FBSDKBridgeAPIRequest bridgeAPIRequestWithProtocolType:FBSDKBridgeAPIProtocolTypeWeb
                                                             scheme:FBSDK_SHARE_WEB_SCHEME
                                                         methodName:methodName
                                                      methodVersion:nil
                                                         parameters:parameters
                                                           userInfo:nil];
  [[FBSDKApplicationDelegate sharedInstance] openBridgeAPIRequest:request completionBlock:completionBlock];
  return YES;
}

- (BOOL)_showFeedBrowser:(NSError **)errorRef
{
  if (![self _validateShareContentForFeed:errorRef]) {
    return NO;
  }
  id<FBSDKSharingContent> shareContent = self.shareContent;
  NSDictionary *parameters = [FBSDKShareUtility feedShareDictionaryForContent:shareContent];
  FBSDKBridgeAPICallbackBlock completionBlock = ^(FBSDKBridgeAPIResponse *response) {
    [self _handleWebResponseParameters:response.responseParameters error:response.error];
    [FBSDKInternalUtility unregisterTransientObject:self];
  };
  FBSDKBridgeAPIRequest *request;
  request = [FBSDKBridgeAPIRequest bridgeAPIRequestWithProtocolType:FBSDKBridgeAPIProtocolTypeWeb
                                                             scheme:FBSDK_SHARE_WEB_SCHEME
                                                         methodName:FBSDK_SHARE_FEED_METHOD_NAME
                                                      methodVersion:nil
                                                         parameters:parameters
                                                           userInfo:nil];
  [[FBSDKApplicationDelegate sharedInstance] openBridgeAPIRequest:request completionBlock:completionBlock];
  return YES;
}

- (BOOL)_showFeedWeb:(NSError **)errorRef
{
  if (![self _validateShareContentForFeed:errorRef]) {
    return NO;
  }
  id<FBSDKSharingContent> shareContent = self.shareContent;
  NSDictionary *parameters = [FBSDKShareUtility feedShareDictionaryForContent:shareContent];
  _webDialog = [FBSDKWebDialog showWithName:FBSDK_SHARE_FEED_METHOD_NAME
                                 parameters:parameters
                                   delegate:self];
  return YES;
}

- (BOOL)_showNativeWithCanShowError:(NSError **)canShowErrorRef validationError:(NSError **)validationErrorRef
{
  NSString *methodName;
  NSString *methodVersion;
  if (![self _canShowNativeWithMethodName:&methodName methodVersion:&methodVersion]) {
    if (canShowErrorRef != NULL) {
      *canShowErrorRef = [FBSDKShareError errorWithCode:FBSDKShareDialogNotAvailableErrorCode
                                                message:@"Native share dialog is not available."];
    }
    return NO;
  }
  if (![self _validateShareContentForNative:validationErrorRef]) {
    return NO;
  }

  NSDictionary *parameters = [FBSDKShareUtility parametersForShareContent:self.shareContent
                                                    shouldFailOnDataError:self.shouldFailOnDataError];
  FBSDKBridgeAPIRequest *request;
  request = [FBSDKBridgeAPIRequest bridgeAPIRequestWithProtocolType:FBSDKBridgeAPIProtocolTypeNative
                                                             scheme:FBSDK_SHARE_DIALOG_APP_SCHEME
                                                         methodName:methodName
                                                      methodVersion:methodVersion
                                                         parameters:parameters
                                                           userInfo:nil];
  FBSDKBridgeAPICallbackBlock completionBlock = ^(FBSDKBridgeAPIResponse *response) {
    NSDictionary *responseParameters = response.responseParameters;
    NSString *completionGesture = responseParameters[FBSDK_SHARE_RESULT_COMPLETION_GESTURE_KEY];
    if ([completionGesture isEqualToString:FBSDK_SHARE_RESULT_COMPLETION_GESTURE_VALUE_CANCEL] ||
        response.isCancelled) {
      [self _invokeDelegateDidCancel];
    } else if (response.error) {
      [self _invokeDelegateDidFailWithError:response.error];
    } else {
      NSMutableDictionary *results = [[NSMutableDictionary alloc] init];
      [FBSDKInternalUtility dictionary:results
                             setObject:responseParameters[FBSDK_SHARE_RESULT_POST_ID_KEY]
                                forKey:FBSDK_SHARE_RESULT_POST_ID_KEY];
      [self _invokeDelegateDidCompleteWithResults:results];
    }
    [FBSDKInternalUtility unregisterTransientObject:self];
  };
  [[FBSDKApplicationDelegate sharedInstance] openBridgeAPIRequest:request completionBlock:completionBlock];
  return YES;
}

- (BOOL)_showShareSheetWithCanShowError:(NSError **)canShowErrorRef validationError:(NSError **)validationErrorRef
{
  if (![self _canShowShareSheet]) {
    if (canShowErrorRef != NULL) {
      *canShowErrorRef = [FBSDKShareError errorWithCode:FBSDKShareDialogNotAvailableErrorCode
                                                message:@"Share sheet is not available."];
    }
    return NO;
  }
  if (![self _validateShareContentForShareSheet:validationErrorRef]) {
    return NO;
  }
  UIViewController *fromViewController = self.fromViewController;
  if (!fromViewController) {
    if (validationErrorRef != NULL) {
      *validationErrorRef = [FBSDKShareError requiredArgumentErrorWithName:@"fromViewController" message:nil];
    }
    return NO;
  }
  NSArray *images = [self _contentImages];
  NSArray *URLs = [self _contentURLs];

  Class composeViewControllerClass = [fbsdkdfl_SLComposeViewControllerClass() class];
  NSString *facebookServiceType = fbsdkdfl_SLServiceTypeFacebook();
  SLComposeViewController *composeViewController;
  composeViewController = [composeViewControllerClass composeViewControllerForServiceType:facebookServiceType];

  if (!composeViewController) {
    if (canShowErrorRef != NULL) {
      *canShowErrorRef = [FBSDKShareError errorWithCode:FBSDKShareDialogNotAvailableErrorCode
                                                message:@"Error creating SLComposeViewController."];
    }
    return NO;
  }
  if ([self _canAttributeThroughShareSheet]) {
    NSString *attributionToken = [NSString stringWithFormat:@"fb-app-id:%@", [FBSDKSettings appID]];
    [composeViewController setInitialText:attributionToken];
  }
  for (UIImage *image in images) {
    [composeViewController addImage:image];
  }
  for (NSURL *URL in URLs) {
    [composeViewController addURL:URL];
  }
  composeViewController.completionHandler = ^(SLComposeViewControllerResult result) {
    switch (result) {
      case SLComposeViewControllerResultCancelled:{
        [self _invokeDelegateDidCancel];
        break;
      }
      case SLComposeViewControllerResultDone:{
        [self _invokeDelegateDidCompleteWithResults:@{}];
        break;
      }
    }
    [FBSDKInternalUtility unregisterTransientObject:self];
  };
  [fromViewController presentViewController:composeViewController animated:YES completion:nil];
  return YES;
}

- (BOOL)_showWeb:(NSError **)errorRef
{
  if (![self _validateShareContentForBrowser:errorRef]) {
    return NO;
  }
  id<FBSDKSharingContent> shareContent = self.shareContent;
  NSString *methodName;
  NSDictionary *parameters;
  if (![FBSDKShareUtility buildWebShareContent:shareContent
                                    methodName:&methodName
                                    parameters:&parameters
                                         error:errorRef]) {
    return NO;
  }
  _webDialog = [FBSDKWebDialog showWithName:methodName
                                 parameters:parameters
                                   delegate:self];
  return YES;
}

- (BOOL)_validateShareContentForBrowser:(NSError **)errorRef
{
  id<FBSDKSharingContent> shareContent = self.shareContent;
  BOOL containsMedia;
  BOOL containsPhotos;
  [FBSDKShareUtility testShareContent:shareContent containsMedia:&containsMedia containsPhotos:&containsPhotos];
  if (containsPhotos) {
    if ((errorRef != NULL) && !*errorRef) {
      *errorRef = [FBSDKShareError invalidArgumentErrorWithName:@"shareContent"
                                                          value:shareContent
                                                        message:@"Web share dialogs cannot include photos."];
    }
    return NO;
  }
  if (containsMedia) {
    if ((errorRef != NULL) && !*errorRef) {
      *errorRef = [FBSDKShareError invalidArgumentErrorWithName:@"shareContent"
                                                          value:shareContent
                                                        message:@"Web share dialogs cannot include local media."];
    }
    return NO;
  }
  return YES;
}

- (BOOL)_validateShareContentForFeed:(NSError **)errorRef
{
  id<FBSDKSharingContent> shareContent = self.shareContent;
  if (![shareContent isKindOfClass:[FBSDKShareLinkContent class]]) {
    if ((errorRef != NULL) && !*errorRef) {
      *errorRef = [FBSDKShareError invalidArgumentErrorWithName:@"shareContent"
                                                          value:shareContent
                                                        message:@"Feed share dialogs support FBSDKShareLinkContent."];
    }
    return NO;
  }
  return YES;
}

- (BOOL)_validateShareContentForNative:(NSError **)errorRef
{
  id<FBSDKSharingContent> shareContent = self.shareContent;
  if (![shareContent isKindOfClass:[FBSDKShareVideoContent class]]) {
    return YES;
  }
  if (((FBSDKShareVideoContent *)shareContent).video.videoURL.isFileURL) {
    if ((errorRef != NULL) && !*errorRef) {
      NSString *message = @"Only asset file URLs are allowed for the native dialog.";
      *errorRef = [FBSDKShareError invalidArgumentErrorWithName:@"videoURL" value:shareContent message:message];
    }
    return NO;
  }
  return YES;
}

- (BOOL)_validateShareContentForShareSheet:(NSError **)errorRef
{
  id<FBSDKSharingContent> shareContent = self.shareContent;
  if ([shareContent isKindOfClass:[FBSDKSharePhotoContent class]]) {
    if ([self _contentImages] != 0) {
      return YES;
    } else {
      if ((errorRef != NULL) && !*errorRef) {
        NSString *message = @"Share photo content must have UIImage photos in order to share with the share sheet";
        *errorRef = [FBSDKShareError invalidArgumentErrorWithName:@"shareContent" value:shareContent message:message];
      }
      return NO;
    }
  } else if (![shareContent isKindOfClass:[FBSDKShareLinkContent class]]) {
    if ((errorRef != NULL) && !*errorRef) {
      NSString *message = @"Share content must be FBSDKShareLinkContent or FBSDKSharePhotoContent in order to share "
      @"with the share sheet.";
      *errorRef = [FBSDKShareError invalidArgumentErrorWithName:@"shareContent" value:shareContent message:message];
    }
    return NO;
  }
  return YES;
}

- (void)_invokeDelegateDidCancel
{
  NSDictionary * parameters = @{
                               FBSDKAppEventParameterDialogOutcome : FBSDKAppEventsDialogOutcomeValue_Cancelled,
                               };

  [FBSDKAppEvents logImplicitEvent:FBSDLAppEventNameFBSDKEventShareDialogResult
                        valueToSum:nil
                        parameters:parameters
                       accessToken:[FBSDKAccessToken currentAccessToken]];

  [_delegate sharerDidCancel:self];
}

- (void)_invokeDelegateDidCompleteWithResults:(NSDictionary *)results
{
  NSDictionary * parameters = @{
                               FBSDKAppEventParameterDialogOutcome : FBSDKAppEventsDialogOutcomeValue_Completed
                               };

  [FBSDKAppEvents logImplicitEvent:FBSDLAppEventNameFBSDKEventShareDialogResult
                        valueToSum:nil
                        parameters:parameters
                       accessToken:[FBSDKAccessToken currentAccessToken]];

  [_delegate sharer:self didCompleteWithResults:[results copy]];
}

- (void)_invokeDelegateDidFailWithError:(NSError *)error
{
  NSDictionary * parameters = @{
                               FBSDKAppEventParameterDialogOutcome : FBSDKAppEventsDialogOutcomeValue_Failed,
                               FBSDKAppEventParameterDialogErrorMessage : [NSString stringWithFormat:@"%@", error]
                               };

  [FBSDKAppEvents logImplicitEvent:FBSDLAppEventNameFBSDKEventShareDialogResult
                        valueToSum:nil
                        parameters:parameters
                       accessToken:[FBSDKAccessToken currentAccessToken]];

  [_delegate sharer:self didFailWithError:error];
}

- (void)_logDialogShow
{
  NSString *shareMode = NSStringFromFBSDKShareDialogMode(self.mode);

  NSString *contentType;
  if([self.shareContent isKindOfClass:[FBSDKShareOpenGraphContent class]]) {
    contentType = FBSDKAppEventsDialogShareContentTypeOpenGraph;
  } else if ([self.shareContent isKindOfClass:[FBSDKShareLinkContent class]]) {
    contentType = FBSDKAppEventsDialogShareContentTypeStatus;
  } else if ([self.shareContent isKindOfClass:[FBSDKSharePhotoContent class]]) {
    contentType = FBSDKAppEventsDialogShareContentTypePhoto;
  } else if ([self.shareContent isKindOfClass:[FBSDKShareVideoContent class]]) {
    contentType = FBSDKAppEventsDialogShareContentTypeVideo;
  } else {
    contentType = FBSDKAppEventsDialogShareContentTypeUnknown;
  }


  NSDictionary *parameters = @{
                               FBSDKAppEventParameterDialogMode : shareMode,
                               FBSDKAppEventParameterDialogShareContentType : contentType,

                               };

  [FBSDKAppEvents logImplicitEvent:FBSDKAppEventNameFBSDKEventShareDialogShow
                        valueToSum:nil
                        parameters:parameters
                       accessToken:[FBSDKAccessToken currentAccessToken]];
}

@end
