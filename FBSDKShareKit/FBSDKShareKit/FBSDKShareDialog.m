/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKShareDialog+Internal.h"

#import <Social/Social.h>
#import <UIKit/UIApplication.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>
#import <objc/runtime.h>

#import "FBSDKShareAppEventName.h"
#import "FBSDKShareAppEventParameters.h"
#import "FBSDKShareBridgeAPIRequestFactory.h"
#import "FBSDKShareCameraEffectContent.h"
#import "FBSDKShareConstants.h"
#import "FBSDKShareDefines.h"
#import "FBSDKShareExtension.h"
#import "FBSDKShareInternalURLOpening.h"
#import "FBSDKShareLinkContent.h"
#import "FBSDKShareMediaContent.h"
#import "FBSDKSharePhoto.h"
#import "FBSDKSharePhotoContent.h"
#import "FBSDKShareUtility.h"
#import "FBSDKShareUtilityProtocol.h"
#import "FBSDKShareVideo.h"
#import "FBSDKShareVideoContent.h"
#import "FBSDKSocialComposeViewController.h"
#import "FBSDKSocialComposeViewControllerFactory.h"
#import "UIApplication+ShareInternalURLOpening.h"

/*
 NOTE: version checking with custom URL schemes is not scalable for Facebook, Inc (Meta, Inc) apps.
 Internal apps will need to use a different solution going forward (Nov 1, 2021).
 Third party apps can continue to use these URL schemes as a version check.
 */
#define FBSDK_SHARE_FEED_METHOD_NAME @"feed"

@interface FBSDKShareDialog () <FBSDKWebDialogDelegate>

@property (class, nonatomic) BOOL hasBeenConfigured;

@property (nonatomic) FBSDKWebDialog *webDialog;
@property (nonatomic) NSMutableArray<NSURL *> *temporaryFiles;

@end

@interface FBSDKInternalUtility (ShareWindowFinding) <FBSDKWindowFinding>
@end

@implementation FBSDKShareDialog

#pragma mark - Class Properties

static BOOL _hasBeenConfigured;

+ (BOOL)hasBeenConfigured
{
  return _hasBeenConfigured;
}

+ (void)setHasBeenConfigured:(BOOL)hasBeenConfigured
{
  _hasBeenConfigured = hasBeenConfigured;
}

static _Nullable id<FBSDKShareInternalURLOpening> _internalURLOpener;

+ (nullable id<FBSDKShareInternalURLOpening>)internalURLOpener
{
  return _internalURLOpener;
}

+ (void)setInternalURLOpener:(nullable id<FBSDKShareInternalURLOpening>)internalURLOpener
{
  _internalURLOpener = internalURLOpener;
}

static _Nullable id<FBSDKInternalUtility> _internalUtility;

+ (nullable id<FBSDKInternalUtility>)internalUtility
{
  return _internalUtility;
}

+ (void)setInternalUtility:(nullable id<FBSDKInternalUtility>)internalUtility
{
  _internalUtility = internalUtility;
  [_internalUtility checkRegisteredCanOpenURLScheme:FBSDKURLSchemeFacebookAPI];
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

static _Nullable Class<FBSDKShareUtility> _shareUtility;

+ (nullable Class<FBSDKShareUtility>)shareUtility
{
  return _shareUtility;
}

+ (void)setShareUtility:(nullable Class<FBSDKShareUtility>)shareUtility
{
  _shareUtility = shareUtility;
}

static _Nullable id<FBSDKBridgeAPIRequestCreating> _bridgeAPIRequestFactory;

+ (nullable id<FBSDKBridgeAPIRequestCreating>)bridgeAPIRequestFactory
{
  return _bridgeAPIRequestFactory;
}

+ (void)setBridgeAPIRequestFactory:(nullable id<FBSDKBridgeAPIRequestCreating>)bridgeAPIRequestFactory
{
  _bridgeAPIRequestFactory = bridgeAPIRequestFactory;
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

static _Nullable id<FBSDKSocialComposeViewControllerFactory> _socialComposeViewControllerFactory;

+ (nullable id<FBSDKSocialComposeViewControllerFactory>)socialComposeViewControllerFactory
{
  return _socialComposeViewControllerFactory;
}

+ (void)setSocialComposeViewControllerFactory:(nullable id<FBSDKSocialComposeViewControllerFactory>)socialComposeViewControllerFactory
{
  _socialComposeViewControllerFactory = socialComposeViewControllerFactory;
}

static _Nullable id<FBSDKWindowFinding> _windowFinder;

+ (nullable id<FBSDKWindowFinding>)windowFinder
{
  return _windowFinder;
}

+ (void)setWindowFinder:(nullable id<FBSDKWindowFinding>)windowFinder
{
  _windowFinder = windowFinder;
}

#pragma mark - Class Configuration

+ (void)configureWithInternalURLOpener:(nonnull id<FBSDKShareInternalURLOpening>)internalURLOpener
                       internalUtility:(nonnull id<FBSDKInternalUtility>)internalUtility
                              settings:(nonnull id<FBSDKSettings>)settings
                          shareUtility:(nonnull Class<FBSDKShareUtility>)shareUtility
               bridgeAPIRequestFactory:(nonnull id<FBSDKBridgeAPIRequestCreating>)bridgeAPIRequestFactory
                bridgeAPIRequestOpener:(nonnull id<FBSDKBridgeAPIRequestOpening>)bridgeAPIRequestOpener
    socialComposeViewControllerFactory:(nonnull id<FBSDKSocialComposeViewControllerFactory>)socialComposeViewControllerFactory
                          windowFinder:(nonnull id<FBSDKWindowFinding>)windowFinder
{
  self.internalURLOpener = internalURLOpener;
  self.internalUtility = internalUtility;
  self.settings = settings;
  self.shareUtility = shareUtility;
  self.bridgeAPIRequestFactory = bridgeAPIRequestFactory;
  self.bridgeAPIRequestOpener = bridgeAPIRequestOpener;
  self.socialComposeViewControllerFactory = socialComposeViewControllerFactory;
  self.windowFinder = windowFinder;

  self.hasBeenConfigured = YES;
}

+ (void)configureClassDependencies
{
  if (self.hasBeenConfigured) {
    return;
  }

  [self configureWithInternalURLOpener:UIApplication.sharedApplication
                       internalUtility:FBSDKInternalUtility.sharedUtility
                              settings:FBSDKSettings.sharedSettings
                          shareUtility:FBSDKShareUtility.self
               bridgeAPIRequestFactory:[FBSDKShareBridgeAPIRequestFactory new]
                bridgeAPIRequestOpener:FBSDKBridgeAPI.sharedInstance
    socialComposeViewControllerFactory:[FBSDKSocialComposeViewControllerFactory new]
                          windowFinder:FBSDKInternalUtility.sharedUtility];
}

static dispatch_once_t validateAPIURLSchemeRegisteredToken;

+ (void)validateAPIURLSchemeRegistered
{
  dispatch_once(&validateAPIURLSchemeRegisteredToken, ^{
    [self.class.internalUtility checkRegisteredCanOpenURLScheme:FBSDKURLSchemeFacebookAPI];
  });
}

#if FBTEST && DEBUG

+ (void)resetClassDependencies
{
  self.internalURLOpener = nil;
  self.internalUtility = nil;
  self.settings = nil;
  self.shareUtility = nil;
  self.bridgeAPIRequestFactory = nil;
  self.bridgeAPIRequestOpener = nil;
  self.socialComposeViewControllerFactory = nil;

  validateAPIURLSchemeRegisteredToken = 0;

  self.hasBeenConfigured = NO;
}

#endif

#pragma mark - Properties

@synthesize delegate = _delegate;
@synthesize shareContent = _shareContent;
@synthesize shouldFailOnDataError = _shouldFailOnDataError;

#pragma mark - Object Lifecycle

- (instancetype)init
{
  [self.class configureClassDependencies];

  self = [super init];
  return self;
}

- (void)dealloc
{
  if (_temporaryFiles) {
    NSFileManager *const fileManager = NSFileManager.defaultManager;
    for (NSURL *temporaryFile in _temporaryFiles) {
      [fileManager removeItemAtURL:temporaryFile error:nil];
    }
    _temporaryFiles = nil;
  }
}

- (instancetype)initWithViewController:(nullable UIViewController *)viewController
                               content:(nullable id<FBSDKSharingContent>)content
                              delegate:(nullable id<FBSDKSharingDelegate>)delegate
{
  if ((self = [self init])) {
    _fromViewController = viewController;
    _shareContent = content;
    _delegate = delegate;
  }

  return self;
}

#pragma mark - Factory Methods

+ (instancetype)dialogWithViewController:(nullable UIViewController *)viewController
                             withContent:(nullable id<FBSDKSharingContent>)content
                                delegate:(nullable id<FBSDKSharingDelegate>)delegate
{
  return [[FBSDKShareDialog alloc] initWithViewController:viewController
                                                  content:content
                                                 delegate:delegate];
}

+ (instancetype)showFromViewController:(nullable UIViewController *)viewController
                           withContent:(nullable id<FBSDKSharingContent>)content
                              delegate:(nullable id<FBSDKSharingDelegate>)delegate
{
  FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] initWithViewController:viewController
                                                                      content:content
                                                                     delegate:delegate];
  [dialog show];
  return dialog;
}

#pragma mark - Public Methods

- (BOOL)canShow
{
  if (self.shareContent) {
    // Validate this content
    NSError *error = nil;
    return [self validateWithError:&error];
  } else {
    // Launch an empty dialog for sharing a status message.
    switch (self.mode) {
      case FBSDKShareDialogModeAutomatic:
      case FBSDKShareDialogModeBrowser:
      case FBSDKShareDialogModeFeedBrowser:
      case FBSDKShareDialogModeFeedWeb:
      case FBSDKShareDialogModeWeb: {
        return YES;
      }
      case FBSDKShareDialogModeNative: {
        return [self _canShowNative];
      }
      case FBSDKShareDialogModeShareSheet: {
        return [self _canShowShareSheet];
      }
    }
  }
}

- (BOOL)show
{
  BOOL didShow = NO;
  NSError *error;
  NSError *validationError;

  if ([self validateWithError:&error]) {
    switch (self.mode) {
      case FBSDKShareDialogModeAutomatic: {
        didShow = [self _showAutomatic:&error];
        break;
      }
      case FBSDKShareDialogModeBrowser: {
        didShow = [self _showBrowser:&error];
        break;
      }
      case FBSDKShareDialogModeFeedBrowser: {
        didShow = [self _showFeedBrowser:&error];
        break;
      }
      case FBSDKShareDialogModeFeedWeb: {
        didShow = [self _showFeedWeb:&error];
        break;
      }
      case FBSDKShareDialogModeNative: {
        didShow = [self _showNativeWithCanShowError:&error validationError:&validationError];
        break;
      }
      case FBSDKShareDialogModeShareSheet: {
        didShow = [self _showShareSheetWithCanShowError:&error validationError:&validationError];
        break;
      }
      case FBSDKShareDialogModeWeb: {
        didShow = [self _showWeb:&error];
        break;
      }
    }
  }
  if (!didShow) {
    if (error || validationError) {
      [self _invokeDelegateDidFailWithError:error ?: validationError];
    }
  } else {
    [self _logDialogShow];
    [self.class.internalUtility registerTransientObject:self];
  }
  return didShow;
}

#pragma mark - FBSDKWebDialogDelegate

- (void)webDialog:(FBSDKWebDialog *)webDialog didCompleteWithResults:(NSDictionary<NSString *, id> *)results
{
  if (_webDialog != webDialog) {
    return;
  }
  [self _cleanUpWebDialog];
  NSInteger errorCode = [results[@"error_code"] integerValue];
  if (errorCode == 4201) {
    [self _invokeDelegateDidCancel];
  } else if (errorCode != 0) {
    NSError *error = [FBSDKError errorWithDomain:FBSDKShareErrorDomain
                                            code:FBSDKShareErrorUnknown
                                        userInfo:@{
                        FBSDKGraphRequestErrorGraphErrorCodeKey : @(errorCode)
                      }
                                         message:results[@"error_message"]
                                 underlyingError:nil];
    [self _handleWebResponseParameters:nil error:error cancelled:NO];
  } else {
    // not all web dialogs report cancellation, so assume that the share has completed with no additional information
    [self _handleWebResponseParameters:results error:nil cancelled:NO];
  }
  [self.class.internalUtility unregisterTransientObject:self];
}

- (void)webDialog:(FBSDKWebDialog *)webDialog didFailWithError:(NSError *)error
{
  if (_webDialog != webDialog) {
    return;
  }
  [self _cleanUpWebDialog];
  [self _invokeDelegateDidFailWithError:error];
  [self.class.internalUtility unregisterTransientObject:self];
}

- (void)webDialogDidCancel:(FBSDKWebDialog *)webDialog
{
  if (_webDialog != webDialog) {
    return;
  }
  [self _cleanUpWebDialog];
  [self _invokeDelegateDidCancel];
  [self.class.internalUtility unregisterTransientObject:self];
}

- (BOOL)_isDefaultToShareSheet
{
  if ([self.shareContent isKindOfClass:FBSDKShareCameraEffectContent.class]) {
    return NO;
  }
  return [[[FBSDKShareDialogConfiguration new] defaultShareMode] isEqualToString:@"share_sheet"];
}

- (BOOL)_showAutomatic:(NSError **)errorRef
{
  BOOL isDefaultToShareSheet = [self _isDefaultToShareSheet];
  BOOL useNativeDialog = [self _useNativeDialog];
  return ((isDefaultToShareSheet && [self _showShareSheetWithCanShowError:NULL validationError:errorRef])
    || (useNativeDialog && [self _showNativeWithCanShowError:NULL validationError:errorRef])
    || (!isDefaultToShareSheet && [self _showShareSheetWithCanShowError:NULL validationError:errorRef])
    || [self _showFeedBrowser:errorRef]
    || [self _showFeedWeb:errorRef]
    || [self _showBrowser:errorRef]
    || [self _showWeb:errorRef]
    || (!useNativeDialog && [self _showNativeWithCanShowError:NULL validationError:errorRef]));
}

- (BOOL)_canShowNative
{
  return [self.class.internalUtility isFacebookAppInstalled];
}

- (BOOL)_canShowShareSheet
{
  if (![self.class.internalUtility isFacebookAppInstalled]) {
    return NO;
  }

  return [self.class.socialComposeViewControllerFactory canMakeSocialComposeViewController];
}

- (BOOL)_canAttributeThroughShareSheet
{
  [self.class validateAPIURLSchemeRegistered];
  NSString *scheme = FBSDKURLSchemeFacebookAPI;
  NSURLComponents *components = [NSURLComponents new];
  components.scheme = scheme;
  components.path = @"/";
  return ([self.class.internalURLOpener canOpenURL:components.URL]
    || [self _canUseFBShareSheet]);
}

- (BOOL)_canUseFBShareSheet
{
  [self _canShowNative];
  NSURLComponents *components = [NSURLComponents new];
  components.scheme = FBSDKURLSchemeFacebookAPI;
  components.path = @"/";
  return [self.class.internalURLOpener canOpenURL:components.URL];
}

- (void)_cleanUpWebDialog
{
  _webDialog = nil;
}

- (NSArray *)_contentImages
{
  NSMutableArray *ret = [NSMutableArray new];
  id<FBSDKSharingContent> shareContent = self.shareContent;
  if ([shareContent isKindOfClass:FBSDKSharePhotoContent.class]) {
    [ret addObjectsFromArray:[((FBSDKSharePhotoContent *)shareContent).photos valueForKeyPath:@"@distinctUnionOfObjects.image"]];
  } else if ([shareContent isKindOfClass:FBSDKShareMediaContent.class]) {
    for (id media in ((FBSDKShareMediaContent *)shareContent).media) {
      if ([media isKindOfClass:FBSDKSharePhoto.class]) {
        UIImage *image = ((FBSDKSharePhoto *)media).image;
        if (image != nil) {
          [FBSDKTypeUtility array:ret addObject:image];
        }
      }
    }
  }
  return [ret copy];
}

- (nullable NSURL *)_contentVideoURL:(FBSDKShareVideo *)video
{
  if (video.videoAsset != nil) {
    return video.videoAsset.videoURL;
  } else if (video.data != nil) {
    NSURL *const temporaryDirectory = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    if (temporaryDirectory) {
      NSURL *const temporaryFile = [temporaryDirectory URLByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
      if (temporaryFile) {
        if (!_temporaryFiles) {
          _temporaryFiles = [NSMutableArray new];
        }
        [FBSDKTypeUtility array:_temporaryFiles addObject:temporaryFile];
        if ([video.data writeToURL:temporaryFile atomically:YES]) {
          return temporaryFile;
        }
      }
    }
  } else if (video.videoURL != nil) {
    return video.videoURL;
  }
  return nil;
}

- (NSArray *)_contentVideoURLs
{
  NSMutableArray<NSURL *> *const ret = [NSMutableArray new];
  const id<FBSDKSharingContent> shareContent = self.shareContent;
  if ([shareContent isKindOfClass:FBSDKShareVideoContent.class]) {
    NSURL *const videoURL = [self _contentVideoURL:[(FBSDKShareVideoContent *)shareContent video]];
    if (videoURL != nil) {
      [FBSDKTypeUtility array:ret addObject:videoURL];
    }
  } else if ([shareContent isKindOfClass:FBSDKShareMediaContent.class]) {
    for (const id media in ((FBSDKShareMediaContent *)shareContent).media) {
      if ([media isKindOfClass:FBSDKShareVideo.class]) {
        NSURL *const videoURL = [self _contentVideoURL:(FBSDKShareVideo *)media];
        if (videoURL != nil) {
          [FBSDKTypeUtility array:ret addObject:videoURL];
        }
      }
    }
  }
  return [ret copy];
}

- (NSArray *)_contentURLs
{
  NSArray *URLs = nil;
  id<FBSDKSharingContent> shareContent = self.shareContent;
  if ([shareContent isKindOfClass:FBSDKShareLinkContent.class]) {
    FBSDKShareLinkContent *linkContent = (FBSDKShareLinkContent *)shareContent;
    URLs = (linkContent.contentURL ? @[linkContent.contentURL] : nil);
  } else if ([shareContent isKindOfClass:FBSDKSharePhotoContent.class]) {
    FBSDKSharePhotoContent *photoContent = (FBSDKSharePhotoContent *)shareContent;
    URLs = (photoContent.contentURL ? @[photoContent.contentURL] : nil);
  }
  return URLs;
}

- (void)_handleWebResponseParameters:(NSDictionary<NSString *, id> *)webResponseParameters
                               error:(NSError *)error
                           cancelled:(BOOL)isCancelled
{
  if (error) {
    [self _invokeDelegateDidFailWithError:error];
    return;
  } else {
    NSString *completionGesture = webResponseParameters[FBSDK_SHARE_RESULT_COMPLETION_GESTURE_KEY];
    if ([completionGesture isEqualToString:FBSDK_SHARE_RESULT_COMPLETION_GESTURE_VALUE_CANCEL] || isCancelled) {
      [self _invokeDelegateDidCancel];
    } else {
      // not all web dialogs report cancellation, so assume that the share has completed with no additional information
      NSMutableDictionary<NSString *, id> *results = [NSMutableDictionary new];
      // the web response comes back with a different payload, so we need to translate it
      [FBSDKTypeUtility dictionary:results
                         setObject:webResponseParameters[FBSDK_SHARE_WEB_PARAM_POST_ID_KEY]
                            forKey:FBSDK_SHARE_RESULT_POST_ID_KEY];
      [self _invokeDelegateDidCompleteWithResults:results];
    }
  }
}

- (BOOL)_photoContentHasAtLeastOneImage:(FBSDKSharePhotoContent *)photoContent
{
  for (FBSDKSharePhoto *photo in photoContent.photos) {
    if (photo.image != nil) {
      return YES;
    }
  }
  return NO;
}

- (BOOL)_showBrowser:(NSError **)errorRef
{
  if (![self _validateShareContentForBrowserWithOptions:FBSDKShareBridgeOptionsDefault error:errorRef]) {
    return NO;
  }
  id<FBSDKSharingContent> shareContent = self.shareContent;
  if ([shareContent isKindOfClass:FBSDKSharePhotoContent.class] && [self _photoContentHasAtLeastOneImage:(FBSDKSharePhotoContent *)shareContent]) {
    void (^completion)(BOOL, NSString *, NSDictionary<NSString *, id> *) = ^(BOOL successfullyBuilt, NSString *cMethodName, NSDictionary<NSString *, id> *cParameters) {
      if (successfullyBuilt) {
        FBSDKBridgeAPIResponseBlock completionBlock = ^(FBSDKBridgeAPIResponse *response) {
          [self _handleWebResponseParameters:response.responseParameters error:response.error cancelled:response.isCancelled];
          [self.class.internalUtility unregisterTransientObject:self];
        };
        id<FBSDKBridgeAPIRequest> request;
        request = [self.class.bridgeAPIRequestFactory bridgeAPIRequestWithProtocolType:FBSDKBridgeAPIProtocolTypeWeb
                                                                                scheme:FBSDKURLSchemeHTTPS
                                                                            methodName:cMethodName
                                                                            parameters:cParameters
                                                                              userInfo:nil];
        [self.class.bridgeAPIRequestOpener openBridgeAPIRequest:request
                                        useSafariViewController:[self _useSafariViewController]
                                             fromViewController:self.fromViewController
                                                completionBlock:completionBlock];
      }
    };

    [self.class.shareUtility buildAsyncWebPhotoContent:shareContent
                                     completionHandler:completion];
  } else {
    NSString *methodName;
    NSDictionary<NSString *, id> *parameters;
    if (![self.class.shareUtility buildWebShareContent:shareContent
                                            methodName:&methodName
                                            parameters:&parameters
                                                 error:errorRef]) {
      return NO;
    }
    FBSDKBridgeAPIResponseBlock completionBlock = ^(FBSDKBridgeAPIResponse *response) {
      [self _handleWebResponseParameters:response.responseParameters error:response.error cancelled:response.isCancelled];
      [self.class.internalUtility unregisterTransientObject:self];
    };
    id<FBSDKBridgeAPIRequest> request;
    request = [self.class.bridgeAPIRequestFactory bridgeAPIRequestWithProtocolType:FBSDKBridgeAPIProtocolTypeWeb
                                                                            scheme:FBSDKURLSchemeHTTPS
                                                                        methodName:methodName
                                                                        parameters:parameters
                                                                          userInfo:nil];
    [self.class.bridgeAPIRequestOpener openBridgeAPIRequest:request
                                    useSafariViewController:[self _useSafariViewController]
                                         fromViewController:self.fromViewController
                                            completionBlock:completionBlock];
  }
  return YES;
}

- (BOOL)_showFeedBrowser:(NSError **)errorRef
{
  if (![self _validateShareContentForFeed:errorRef]) {
    return NO;
  }
  id<FBSDKSharingContent> shareContent = self.shareContent;
  NSDictionary<NSString *, id> *parameters = [self.class.shareUtility feedShareDictionaryForContent:shareContent];
  FBSDKBridgeAPIResponseBlock completionBlock = ^(FBSDKBridgeAPIResponse *response) {
    [self _handleWebResponseParameters:response.responseParameters error:response.error cancelled:response.isCancelled];
    [self.class.internalUtility unregisterTransientObject:self];
  };
  id<FBSDKBridgeAPIRequest> request;
  request = [self.class.bridgeAPIRequestFactory bridgeAPIRequestWithProtocolType:FBSDKBridgeAPIProtocolTypeWeb
                                                                          scheme:FBSDKURLSchemeHTTPS
                                                                      methodName:FBSDK_SHARE_FEED_METHOD_NAME
                                                                      parameters:parameters
                                                                        userInfo:nil];
  [self.class.bridgeAPIRequestOpener openBridgeAPIRequest:request
                                  useSafariViewController:[self _useSafariViewController]
                                       fromViewController:self.fromViewController
                                          completionBlock:completionBlock];
  return YES;
}

- (BOOL)_showFeedWeb:(NSError **)errorRef
{
  if (![self _validateShareContentForFeed:errorRef]) {
    return NO;
  }
  id<FBSDKSharingContent> shareContent = self.shareContent;
  NSDictionary<NSString *, id> *parameters = [self.class.shareUtility feedShareDictionaryForContent:shareContent];
  _webDialog = [FBSDKWebDialog createAndShowWithName:FBSDK_SHARE_FEED_METHOD_NAME
                                          parameters:parameters
                                               frame:CGRectZero
                                            delegate:self
                                        windowFinder:self.class.windowFinder];
  return YES;
}

- (BOOL)_showNativeWithCanShowError:(NSError **)canShowErrorRef validationError:(NSError **)validationErrorRef
{
  if (![self _canShowNative]) {
    if (canShowErrorRef != NULL) {
      *canShowErrorRef = [FBSDKError errorWithDomain:FBSDKShareErrorDomain
                                                code:FBSDKShareErrorDialogNotAvailable
                                             message:@"Native share dialog is not available."];
    }
    return NO;
  }
  if (![self _validateShareContentForNative:validationErrorRef]) {
    return NO;
  }
  NSString *scheme = nil;
  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Wdeprecated-declarations"
  if ([self.shareContent respondsToSelector:@selector(schemeForMode:)]) {
    scheme = [(id<FBSDKSharingScheme>)self.shareContent schemeForMode:FBSDKShareDialogModeNative];
  }
  #pragma clang diagnostic pop
  if (!(scheme.length > 0)) {
    scheme = FBSDKURLSchemeFacebookAPI;
  }
  NSString *methodName;
  if ([self.shareContent isKindOfClass:FBSDKShareCameraEffectContent.class]) {
    methodName = FBSDK_SHARE_CAMERA_METHOD_NAME;
  } else {
    methodName = FBSDK_SHARE_METHOD_NAME;
  }

  NSDictionary<NSString *, id> *parameters = [self.class.shareUtility parametersForShareContent:self.shareContent
                                                                                  bridgeOptions:FBSDKShareBridgeOptionsDefault
                                                                          shouldFailOnDataError:self.shouldFailOnDataError];
  id<FBSDKBridgeAPIRequest> request;
  request = [self.class.bridgeAPIRequestFactory bridgeAPIRequestWithProtocolType:FBSDKBridgeAPIProtocolTypeNative
                                                                          scheme:scheme
                                                                      methodName:methodName
                                                                      parameters:parameters
                                                                        userInfo:nil];
  FBSDKBridgeAPIResponseBlock completionBlock = ^(FBSDKBridgeAPIResponse *response) {
    if (response.error.code == FBSDKErrorAppVersionUnsupported) {
      NSError *fallbackError;
      if ([self _showShareSheetWithCanShowError:NULL validationError:&fallbackError]
          || [self _showFeedBrowser:&fallbackError]) {
        return;
      }
    }
    NSDictionary<NSString *, id> *responseParameters = response.responseParameters;
    NSString *completionGesture = responseParameters[FBSDK_SHARE_RESULT_COMPLETION_GESTURE_KEY];
    if ([completionGesture isEqualToString:FBSDK_SHARE_RESULT_COMPLETION_GESTURE_VALUE_CANCEL]
        || response.isCancelled) {
      [self _invokeDelegateDidCancel];
    } else if (response.error) {
      [self _invokeDelegateDidFailWithError:response.error];
    } else {
      NSMutableDictionary<NSString *, id> *results = [NSMutableDictionary new];
      [FBSDKTypeUtility dictionary:results
                         setObject:responseParameters[FBSDK_SHARE_RESULT_POST_ID_KEY]
                            forKey:FBSDK_SHARE_RESULT_POST_ID_KEY];
      [self _invokeDelegateDidCompleteWithResults:results];
    }
    [self.class.internalUtility unregisterTransientObject:self];
  };
  [self.class.bridgeAPIRequestOpener openBridgeAPIRequest:request
                                  useSafariViewController:[self _useSafariViewController]
                                       fromViewController:self.fromViewController
                                          completionBlock:completionBlock];
  return YES;
}

- (BOOL)_showShareSheetWithCanShowError:(NSError **)canShowErrorRef validationError:(NSError **)validationErrorRef
{
  if (![self _canShowShareSheet]) {
    if (canShowErrorRef != NULL) {
      *canShowErrorRef = [FBSDKError errorWithDomain:FBSDKShareErrorDomain
                                                code:FBSDKShareErrorDialogNotAvailable
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
      *validationErrorRef = [FBSDKError requiredArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                                   name:@"fromViewController"
                                                                message:nil];
    }
    return NO;
  }
  NSArray *images = [self _contentImages];
  NSArray *URLs = [self _contentURLs];
  NSArray *videoURLs = [self _contentVideoURLs];

  id<FBSDKSocialComposeViewController> composeViewController = [self.class.socialComposeViewControllerFactory makeSocialComposeViewController];

  if (!composeViewController || ![composeViewController isKindOfClass:UIViewController.class]) {
    if (canShowErrorRef != NULL) {
      *canShowErrorRef = [FBSDKError errorWithDomain:FBSDKShareErrorDomain
                                                code:FBSDKShareErrorDialogNotAvailable
                                             message:@"Error creating social compose view controller."];
    }
    return NO;
  }

  NSString *initialText = [self _calculateInitialText];
  if (initialText.length > 0) {
    [composeViewController setInitialText:initialText];
  }

  for (UIImage *image in images) {
    [composeViewController addImage:image];
  }
  for (NSURL *URL in URLs) {
    [composeViewController addURL:URL];
  }
  for (NSURL *videoURL in videoURLs) {
    [composeViewController addURL:videoURL];
  }
  composeViewController.completionHandler = ^(FBSDKSocialComposeViewControllerResult result) {
    switch (result) {
      case FBSDKSocialComposeViewControllerResultCancelled: {
        [self _invokeDelegateDidCancel];
        break;
      }
      case FBSDKSocialComposeViewControllerResultDone: {
        [self _invokeDelegateDidCompleteWithResults:@{}];
        break;
      }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.class.internalUtility unregisterTransientObject:self];
    });
  };

  [fromViewController presentViewController:(UIViewController *)composeViewController
                                   animated:YES
                                 completion:nil];
  return YES;
}

- (BOOL)_showWeb:(NSError **)errorRef
{
  if (![self _validateShareContentForBrowserWithOptions:FBSDKShareBridgeOptionsPhotoImageURL error:errorRef]) {
    return NO;
  }
  id<FBSDKSharingContent> shareContent = self.shareContent;
  NSString *methodName;
  NSDictionary<NSString *, id> *parameters;
  if (![self.class.shareUtility buildWebShareContent:shareContent
                                          methodName:&methodName
                                          parameters:&parameters
                                               error:errorRef]) {
    return NO;
  }
  _webDialog = [FBSDKWebDialog createAndShowWithName:methodName
                                          parameters:parameters
                                               frame:CGRectZero
                                            delegate:self
                                        windowFinder:self.class.windowFinder];
  return YES;
}

- (BOOL)_useNativeDialog
{
  if ([self.shareContent isKindOfClass:FBSDKShareCameraEffectContent.class]) {
    return YES;
  }
  return [[FBSDKShareDialogConfiguration new] shouldUseNativeDialogForDialogName:FBSDKDialogConfigurationNameShare];
}

- (BOOL)_useSafariViewController
{
  if ([self.shareContent isKindOfClass:FBSDKShareCameraEffectContent.class]) {
    return NO;
  }
  return [[FBSDKShareDialogConfiguration new] shouldUseSafariViewControllerForDialogName:FBSDKDialogConfigurationNameShare];
}

- (BOOL)validateWithError:(NSError **)errorRef
{
  if (errorRef != NULL) {
    *errorRef = nil;
  }

  /* UNCRUSTIFY_FORMAT_OFF */
  if (self.shareContent) {
    if ([self.shareContent isKindOfClass:FBSDKShareCameraEffectContent.class]
        || [self.shareContent isKindOfClass:FBSDKShareLinkContent.class]
        || [self.shareContent isKindOfClass:FBSDKShareMediaContent.class]
        || [self.shareContent isKindOfClass:FBSDKSharePhotoContent.class]
        || [self.shareContent isKindOfClass:FBSDKShareVideoContent.class]) {
    } else {
      if (errorRef != NULL) {
        NSString *message = [NSString stringWithFormat:@"Share dialog does not support %@.",
                             NSStringFromClass(self.shareContent.class)];
        *errorRef = [FBSDKError requiredArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                           name:@"shareContent"
                                                        message:message];
      }
      return NO;
    }
  }
  /* UNCRUSTIFY_FORMAT_ON */

  if (![self.class.shareUtility validateShareContent:self.shareContent
                                       bridgeOptions:FBSDKShareBridgeOptionsDefault
                                               error:errorRef]) {
    return NO;
  }

  switch (self.mode) {
    case FBSDKShareDialogModeAutomatic: {
      return (
        ([self _canShowNative] && [self _validateShareContentForNative:errorRef])
        || ([self _canShowShareSheet] && [self _validateShareContentForShareSheet:errorRef])
        || [self _validateShareContentForFeed:errorRef]
        || [self _validateShareContentForBrowserWithOptions:FBSDKShareBridgeOptionsDefault error:errorRef]);
    }
    case FBSDKShareDialogModeNative: {
      return [self _validateShareContentForNative:errorRef];
    }
    case FBSDKShareDialogModeShareSheet: {
      return [self _validateShareContentForShareSheet:errorRef];
    }
    case FBSDKShareDialogModeBrowser: {
      return [self _validateShareContentForBrowserWithOptions:FBSDKShareBridgeOptionsDefault error:errorRef];
    }
    case FBSDKShareDialogModeWeb: {
      return [self _validateShareContentForBrowserWithOptions:FBSDKShareBridgeOptionsPhotoImageURL error:errorRef];
    }
    case FBSDKShareDialogModeFeedBrowser:
    case FBSDKShareDialogModeFeedWeb: {
      return [self _validateShareContentForFeed:errorRef];
    }
  }
  if (errorRef != NULL) {
    *errorRef = [FBSDKError invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                      name:@"FBSDKShareDialogMode"
                                                     value:@(self.mode)
                                                   message:nil];
  }
  return NO;
}

- (BOOL)_validateShareContentForBrowserWithOptions:(FBSDKShareBridgeOptions)bridgeOptions error:(NSError **)errorRef
{
  id<FBSDKSharingContent> shareContent = self.shareContent;
  if ([shareContent isKindOfClass:FBSDKShareLinkContent.class]) {
    // The parameter 'href' or 'media' is required
    FBSDKShareLinkContent *const linkContent = shareContent;
    if (!linkContent.contentURL) {
      if ((errorRef != NULL) && !*errorRef) {
        *errorRef = [FBSDKError invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                          name:@"shareContent"
                                                         value:shareContent
                                                       message:@"FBSDKShareLinkContent contentURL is required."];
      }
      return NO;
    }
  }
  if ([shareContent isKindOfClass:FBSDKShareCameraEffectContent.class]) {
    if ((errorRef != NULL) && !*errorRef) {
      *errorRef = [FBSDKError invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                        name:@"shareContent"
                                                       value:shareContent
                                                     message:@"Camera Content must be shared in `Native` mode."];
    }
    return NO;
  }
  BOOL containsMedia;
  BOOL containsPhotos;
  BOOL containsVideos;
  [self.class.shareUtility testShareContent:shareContent
                              containsMedia:&containsMedia
                             containsPhotos:&containsPhotos
                             containsVideos:&containsVideos];
  if (containsPhotos) {
    if (FBSDKAccessToken.currentAccessToken == nil) {
      if ((errorRef != NULL) && !*errorRef) {
        *errorRef = [FBSDKError invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                          name:@"shareContent"
                                                         value:shareContent
                                                       message:@"The web share dialog needs a valid access token to stage photos."];
      }
      return NO;
    }
    if ([shareContent isKindOfClass:FBSDKSharePhotoContent.class]) {
      if (![shareContent validateWithOptions:bridgeOptions error:errorRef]) {
        return NO;
      }
    } else {
      if ((errorRef != NULL) && !*errorRef) {
        *errorRef = [FBSDKError invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                          name:@"shareContent"
                                                         value:shareContent
                                                       message:@"Web share dialogs cannot include photos."];
      }
      return NO;
    }
  }
  if (containsVideos) {
    if (FBSDKAccessToken.currentAccessToken == nil) {
      if ((errorRef != NULL) && !*errorRef) {
        *errorRef = [FBSDKError invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                          name:@"shareContent"
                                                         value:shareContent
                                                       message:@"The web share dialog needs a valid access token to stage videos."];
      }
      return NO;
    }
    if ([shareContent isKindOfClass:FBSDKShareVideoContent.class]) {
      if (![shareContent validateWithOptions:bridgeOptions error:errorRef]) {
        return NO;
      }
    }
  }
  if (containsMedia) {
    if (bridgeOptions & FBSDKShareBridgeOptionsPhotoImageURL) { // a web-based URL is required
      if ((errorRef != NULL) && !*errorRef) {
        *errorRef = [FBSDKError invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                          name:@"shareContent"
                                                         value:shareContent
                                                       message:@"Web share dialogs cannot include local media."];
      }
      return NO;
    }
  }
  return YES;
}

- (BOOL)_validateShareContentForFeed:(NSError **)errorRef
{
  id<FBSDKSharingContent> shareContent = self.shareContent;
  if ([shareContent isKindOfClass:FBSDKShareLinkContent.class]) {
    // The parameter 'href' or 'media' is required
    FBSDKShareLinkContent *const linkContent = shareContent;
    if (!linkContent.contentURL) {
      if ((errorRef != NULL) && !*errorRef) {
        *errorRef = [FBSDKError invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                          name:@"shareContent"
                                                         value:shareContent
                                                       message:@"FBSDKShareLinkContent contentURL is required."];
      }
      return NO;
    }
  } else {
    if ((errorRef != NULL) && !*errorRef) {
      *errorRef = [FBSDKError invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                        name:@"shareContent"
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
  if ([shareContent isKindOfClass:FBSDKShareMediaContent.class]) {
    if ([self.class.shareUtility shareMediaContentContainsPhotosAndVideos:(FBSDKShareMediaContent *)shareContent]) {
      if ((errorRef != NULL) && !*errorRef) {
        *errorRef = [FBSDKError invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                          name:@"shareContent"
                                                         value:shareContent
                                                       message:@"Multimedia Content is only available for mode `ShareSheet`"];
      }
      return NO;
    }
  }
  if (![shareContent isKindOfClass:FBSDKShareVideoContent.class]) {
    return YES;
  }
  return [(FBSDKShareVideoContent *)shareContent validateWithOptions:FBSDKShareBridgeOptionsDefault
                                                               error:errorRef];
}

- (BOOL)_validateShareContentForShareSheet:(NSError **)errorRef
{
  id<FBSDKSharingContent> shareContent = self.shareContent;
  if (shareContent) {
    if ([shareContent isKindOfClass:FBSDKSharePhotoContent.class]) {
      if ([self _contentImages].count != 0) {
        return YES;
      } else {
        if ((errorRef != NULL) && !*errorRef) {
          NSString *message = @"Share photo content must have UIImage photos in order to share with the share sheet";
          *errorRef = [FBSDKError invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                            name:@"shareContent"
                                                           value:shareContent
                                                         message:message];
        }
        return NO;
      }
    } else if ([shareContent isKindOfClass:FBSDKShareVideoContent.class]) {
      return ([self _canUseFBShareSheet]
        && [(FBSDKShareVideoContent *)shareContent validateWithOptions:FBSDKShareBridgeOptionsDefault error:errorRef]);
    } else if ([shareContent isKindOfClass:FBSDKShareMediaContent.class]) {
      return ([self _canUseFBShareSheet]
        && [self _validateShareMediaContentAvailability:shareContent error:errorRef]
        && [(FBSDKShareMediaContent *)shareContent validateWithOptions:FBSDKShareBridgeOptionsDefault error:errorRef]);
    } else if ([shareContent isKindOfClass:FBSDKShareLinkContent.class]) {
      return YES;
    } else {
      if ((errorRef != NULL) && !*errorRef) {
        NSString *message = [NSString stringWithFormat:@"Share sheet does not support %@.",
                             NSStringFromClass(shareContent.class)];
        *errorRef = [FBSDKError invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                          name:@"shareContent"
                                                         value:shareContent
                                                       message:message];
      }
      return NO;
    }
  }
  return YES;
}

- (BOOL)_validateShareMediaContentAvailability:(FBSDKShareMediaContent *)shareContent error:(NSError **)errorRef
{
  if ([self.class.shareUtility shareMediaContentContainsPhotosAndVideos:shareContent]
      && self.mode == FBSDKShareDialogModeShareSheet
      && ![self _canUseFBShareSheet]) {
    if ((errorRef != NULL) && !*errorRef) {
      *errorRef = [FBSDKError invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                        name:@"shareContent"
                                                       value:shareContent
                                                     message:@"Cannot use the share sheet if the share sheet is unavailable. Make sure the FB app is installed."];
    }
    return NO;
  }
  return YES;
}

- (void)_invokeDelegateDidCancel
{
  NSDictionary<NSString *, id> *parameters = @{
    FBSDKAppEventParameterDialogOutcome : FBSDKAppEventsDialogOutcomeValue_Cancelled,
  };

  [FBSDKAppEvents.shared logInternalEvent:FBSDKAppEventNameShareDialogResult
                               parameters:parameters
                       isImplicitlyLogged:YES
                              accessToken:FBSDKAccessToken.currentAccessToken];

  [_delegate sharerDidCancel:self];
}

- (void)_invokeDelegateDidCompleteWithResults:(NSDictionary<NSString *, id> *)results
{
  NSDictionary<NSString *, id> *parameters = @{
    FBSDKAppEventParameterDialogOutcome : FBSDKAppEventsDialogOutcomeValue_Completed
  };

  [FBSDKAppEvents.shared logInternalEvent:FBSDKAppEventNameShareDialogResult
                               parameters:parameters
                       isImplicitlyLogged:YES
                              accessToken:FBSDKAccessToken.currentAccessToken];

  [_delegate sharer:self didCompleteWithResults:[results copy]];
}

- (void)_invokeDelegateDidFailWithError:(nonnull NSError *)error
{
  NSDictionary<NSString *, id> *parameters = @{
    FBSDKAppEventParameterDialogOutcome : FBSDKAppEventsDialogOutcomeValue_Failed,
    FBSDKAppEventParameterDialogErrorMessage : [NSString stringWithFormat:@"%@", error]
  };

  [FBSDKAppEvents.shared logInternalEvent:FBSDKAppEventNameShareDialogResult
                               parameters:parameters
                       isImplicitlyLogged:YES
                              accessToken:FBSDKAccessToken.currentAccessToken];

  [_delegate sharer:self didFailWithError:error];
}

- (void)_logDialogShow
{
  NSString *shareMode = NSStringFromFBSDKShareDialogMode(self.mode);

  NSString *contentType;
  if ([self.shareContent isKindOfClass:FBSDKShareLinkContent.class]) {
    contentType = FBSDKAppEventsDialogShareContentTypeStatus;
  } else if ([self.shareContent isKindOfClass:FBSDKSharePhotoContent.class]) {
    contentType = FBSDKAppEventsDialogShareContentTypePhoto;
  } else if ([self.shareContent isKindOfClass:FBSDKShareVideoContent.class]) {
    contentType = FBSDKAppEventsDialogShareContentTypeVideo;
  } else if ([self.shareContent isKindOfClass:FBSDKShareCameraEffectContent.class]) {
    contentType = FBSDKAppEventsDialogShareContentTypeCamera;
  } else {
    contentType = FBSDKAppEventsDialogShareContentTypeUnknown;
  }

  NSDictionary<NSString *, id> *parameters = @{
    FBSDKAppEventParameterDialogMode : shareMode,
    FBSDKAppEventParameterDialogShareContentType : contentType,
  };

  [FBSDKAppEvents.shared logInternalEvent:FBSDKAppEventNameShareDialogShow
                               parameters:parameters
                       isImplicitlyLogged:YES
                              accessToken:FBSDKAccessToken.currentAccessToken];
}

- (nullable NSString *)_calculateInitialText
{
  NSString *initialText;
  NSString *const hashtag = [self.class.shareUtility hashtagStringFromHashtag:self.shareContent.hashtag];
  if ([self _canAttributeThroughShareSheet]) {
    NSMutableDictionary<NSString *, id> *const parameters = [NSMutableDictionary new];
    NSString *const appID = self.class.settings.appID;
    if (appID.length > 0) {
      [FBSDKTypeUtility dictionary:parameters setObject:appID forKey:FBSDKShareExtensionParamAppID];
    }
    if (hashtag.length > 0) {
      [FBSDKTypeUtility dictionary:parameters setObject:@[hashtag] forKey:FBSDKShareExtensionParamHashtags];
    }
    if ([self.shareContent isKindOfClass:FBSDKShareLinkContent.class]) {
      NSString *const quote = ((FBSDKShareLinkContent *)self.shareContent).quote;
      if (quote.length > 0) {
        [FBSDKTypeUtility dictionary:parameters setObject:@[quote] forKey:FBSDKShareExtensionParamQuotes];
      }
    }

    NSError *error = nil;
    NSString *const jsonString = [FBSDKBasicUtility JSONStringForObject:parameters error:&error invalidObjectHandler:NULL];
    if (error != nil) {
      return nil;
    }

    initialText = FBSDKShareExtensionInitialText(appID, hashtag, jsonString);
  } else {
    if (hashtag.length > 0) {
      initialText = hashtag;
    }
  }
  return initialText;
}

@end

#endif
