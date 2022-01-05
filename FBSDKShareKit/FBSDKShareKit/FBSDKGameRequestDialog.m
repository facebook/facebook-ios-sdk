/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKGameRequestDialog.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKGameRequestDialogDelegate.h"
#import "FBSDKGameRequestFrictionlessRecipientCache.h"
#import "FBSDKShareConstants.h"
#import "FBSDKShareUtility.h"

#define FBSDK_APP_REQUEST_METHOD_NAME @"apprequests"
#define FBSDK_GAME_REQUEST_URL_HOST @"game_requests"

@interface FBSDKGameRequestDialog () <FBSDKWebDialogDelegate, FBSDKURLOpening>
@end

@interface FBSDKGameRequestDialog ()
@property (nonatomic) BOOL dialogIsFrictionless;
@property (nonatomic) BOOL isAwaitingResult;
@property (nonatomic) FBSDKWebDialog *webDialog;
@end

@implementation FBSDKGameRequestDialog

#pragma mark - Class Methods

static FBSDKGameRequestFrictionlessRecipientCache * _recipientCache = nil;

+ (void)initialize
{
  if (self == FBSDKGameRequestDialog.class) {
    _recipientCache = [FBSDKGameRequestFrictionlessRecipientCache new];
  }
}

+ (instancetype)dialogWithContent:(FBSDKGameRequestContent *)content
                         delegate:(nullable id<FBSDKGameRequestDialogDelegate>)delegate
{
  FBSDKGameRequestDialog *dialog = [self new];
  dialog.content = content;
  dialog.delegate = delegate;
  return dialog;
}

+ (instancetype)showWithContent:(FBSDKGameRequestContent *)content
                       delegate:(nullable id<FBSDKGameRequestDialogDelegate>)delegate
{
  FBSDKGameRequestDialog *dialog = [self dialogWithContent:content delegate:delegate];
  NSString *graphDomain = [FBSDKUtility getGraphDomainFromToken];
  if ([graphDomain isEqualToString:@"gaming"] && [FBSDKInternalUtility.sharedUtility isFacebookAppInstalled]) {
    [dialog launchGameRequestDialogWithGameRequestContent:content delegate:delegate];
  } else {
    [dialog show];
  }
  return dialog;
}

- (void)launchGameRequestDialogWithGameRequestContent:(FBSDKGameRequestContent *)requestContent delegate:(id<FBSDKGameRequestDialogDelegate>)delegate
{
  NSError *error;
  __weak typeof(self) weakSelf = self;
  NSDictionary<NSString *, id> *contentDictionary = [self _convertGameRequestContentToDictionaryV2:_content];

  [self validateWithError:&error];
  if (error) {
    [self handleDialogError:error];
    return;
  }

  _isAwaitingResult = YES;
  [FBSDKBridgeAPI.sharedInstance
   openURL:[FBSDKGameRequestURLProvider createDeepLinkURLWithQueryDictionary:contentDictionary]
   sender:weakSelf
   handler:^(BOOL success, NSError *_Nullable bridgeError) {
     if (!success && bridgeError) {
       [weakSelf handleBridgeAPIFailureWithError:bridgeError];
     }
   }];
}

- (void)facebookAppReturnedURL:(NSURL *_Nullable)url
{
  [self _cleanUp];
  if (!url) {
    id<FBSDKErrorCreating> errorFactory = [FBSDKErrorFactory new];
    NSError *error = [errorFactory errorWithDomain:FBSDKShareErrorDomain
                                              code:FBSDKShareErrorUnknown
                                          userInfo:nil
                                           message:@"Facebook app did not return a url"
                                   underlyingError:nil];
    [self handleDialogError:error];
  } else {
    NSDictionary<NSString *, id> *parsedResults = [self parsedPayloadFromURL:url];
    if (parsedResults) {
      [_delegate gameRequestDialog:self didCompleteWithResults:parsedResults];
    }
  }
}

- (void)handleDialogError:(NSError *_Nullable)error
{
  if (error) {
    [_delegate gameRequestDialog:self didFailWithError:error];
  } else {
    [self _didCancel];
  }
  [self _cleanUp];
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

  if (isGamingUrl && _isAwaitingResult) {
    [self facebookAppReturnedURL:url];
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
   isValidCallbackURL:url];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  if (_isAwaitingResult) {
    [self _didCancel];
  }
}

- (BOOL)isAuthenticationURL:(NSURL *)url
{
  return false;
}

- (void)handleBridgeAPIFailureWithError:(NSError *)error
{
  if (error) {
    id<FBSDKErrorCreating> errorFactory = [FBSDKErrorFactory new];
    NSError *sdkError = [errorFactory errorWithCode:FBSDKErrorBridgeAPIInterruption
                                           userInfo:nil
                                            message:@"Error occured while interacting with Gaming Services, Failed to open bridge."
                                    underlyingError:error];
    [self handleDialogError:sdkError];
  }
}

- (BOOL)isValidCallbackURL:(NSURL *)url
{
  return
  [url.scheme hasPrefix:[NSString stringWithFormat:@"fb%@", FBSDKSettings.sharedSettings.appID]]
  && [url.host isEqualToString:FBSDK_GAME_REQUEST_URL_HOST];
}

- (nullable NSDictionary<NSString *, NSString *> *)parsedPayloadFromURL:(nonnull NSURL *)url
{
  NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
  if (!urlComponents.queryItems) {
    // If the url contains no query items, then the user self closed the dialog within fbios.
    [self _didCancel];
    return nil;
  }

  NSMutableDictionary<NSString *, id> *parsedURLQuery = [NSMutableDictionary new];
  for (NSURLQueryItem *query in urlComponents.queryItems) {
    if ([query.name isEqual:@"request_id"]) {
      [FBSDKTypeUtility dictionary:parsedURLQuery setObject:query.value forKey:query.name];
    }
    if ([query.name isEqual:@"recipients"]) {
      [FBSDKTypeUtility dictionary:parsedURLQuery setObject:[query.value componentsSeparatedByString:@","] forKey:query.name];
    }
  }
  return parsedURLQuery;
}

#pragma mark - Object Lifecycle

- (instancetype)init
{
  if ((self = [super init])) {
    _webDialog = [FBSDKWebDialog dialogWithName:FBSDK_APP_REQUEST_METHOD_NAME
                                       delegate:self];
  }
  return self;
}

#pragma mark - Public Methods

- (BOOL)canShow
{
  return YES;
}

- (BOOL)show
{
  NSError *error;
  if (!self.canShow) {
    id<FBSDKErrorCreating> errorFactory = [FBSDKErrorFactory new];
    error = [errorFactory errorWithDomain:FBSDKShareErrorDomain
                                     code:FBSDKShareErrorDialogNotAvailable
                                 userInfo:nil
                                  message:@"Game request dialog is not available."
                          underlyingError:nil];
    [_delegate gameRequestDialog:self didFailWithError:error];
    return NO;
  }

  if (![self validateWithError:&error]) {
    [_delegate gameRequestDialog:self didFailWithError:error];
    return NO;
  }

  FBSDKGameRequestContent *content = self.content;

  if (error) {
    return NO;
  }

  NSMutableDictionary<NSString *, id> *parameters = [self _convertGameRequestContentToDictionaryV1:content];

  // check if we are sending to a specific set of recipients.  if we are and they are all frictionless recipients, we
  // can perform this action without displaying the web dialog
  _webDialog.shouldDeferVisibility = NO;
  NSArray<NSString *> *recipients = content.recipients;
  if (_frictionlessRequestsEnabled && recipients) {
    // specify these parameters to get the frictionless recipients from the dialog when it is presented
    parameters[@"frictionless"] = @YES;
    parameters[@"get_frictionless_recipients"] = @YES;

    _dialogIsFrictionless = YES;
    if ([_recipientCache recipientsAreFrictionless:recipients]) {
      _webDialog.shouldDeferVisibility = YES;
    }
  }

  [self _launchDialogViaBridgeAPIWithParameters:parameters];

  [FBSDKInternalUtility.sharedUtility registerTransientObject:self];
  return YES;
}

- (BOOL)validateWithError:(NSError *__autoreleasing *)errorRef
{
  if (![FBSDKShareUtility validateRequiredValue:self.content name:@"content" error:errorRef]) {
    return NO;
  }
  if ([self.content respondsToSelector:@selector(validateWithOptions:error:)]) {
    return [self.content validateWithOptions:FBSDKShareBridgeOptionsDefault error:errorRef];
  }
  if (errorRef != NULL) {
    id<FBSDKErrorCreating> errorFactory = [FBSDKErrorFactory new];
    *errorRef = [errorFactory invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                        name:@"content"
                                                       value:self.content
                                                     message:nil
                                             underlyingError:nil];
  }
  return NO;
}

- (NSMutableDictionary<NSString *, id> *)_convertGameRequestContentToDictionaryV1:(FBSDKGameRequestContent *)content
{
  NSMutableDictionary<NSString *, id> *parameters = [NSMutableDictionary new];
  [FBSDKTypeUtility dictionary:parameters setObject:[content.recipients componentsJoinedByString:@","] forKey:@"to"];
  [FBSDKTypeUtility dictionary:parameters setObject:content.message forKey:@"message"];
  [FBSDKTypeUtility dictionary:parameters setObject:[FBSDKGameRequestURLProvider actionTypeNameForActionType:content.actionType] forKey:@"action_type"];
  [FBSDKTypeUtility dictionary:parameters setObject:content.objectID forKey:@"object_id"];
  [FBSDKTypeUtility dictionary:parameters setObject:content.data forKey:@"data"];
  [FBSDKTypeUtility dictionary:parameters setObject:content.title forKey:@"title"];

  [FBSDKTypeUtility dictionary:parameters setObject:[FBSDKGameRequestURLProvider filtersNameForFilters:content.filters] forKey:@"filters"];
  [FBSDKTypeUtility dictionary:parameters setObject:[content.recipientSuggestions componentsJoinedByString:@","] forKey:@"suggestions"];
  return parameters;
}

- (NSMutableDictionary<NSString *, id> *)_convertGameRequestContentToDictionaryV2:(FBSDKGameRequestContent *)content
{
  NSMutableDictionary<NSString *, id> *parameters = [NSMutableDictionary new];
  [FBSDKTypeUtility dictionary:parameters setObject:[content.recipientSuggestions componentsJoinedByString:@","] forKey:@"to"];
  [FBSDKTypeUtility dictionary:parameters setObject:content.message forKey:@"message"];
  [FBSDKTypeUtility dictionary:parameters setObject:[FBSDKGameRequestURLProvider actionTypeNameForActionType:content.actionType] forKey:@"action_type"];
  [FBSDKTypeUtility dictionary:parameters setObject:content.objectID forKey:@"object_id"];
  [FBSDKTypeUtility dictionary:parameters setObject:content.data forKey:@"data"];
  [FBSDKTypeUtility dictionary:parameters setObject:content.title forKey:@"title"];

  [FBSDKTypeUtility dictionary:parameters setObject:[FBSDKGameRequestURLProvider filtersNameForFilters:content.filters] forKey:@"options"];
  [FBSDKTypeUtility dictionary:parameters setObject:content.cta forKey:@"cta"];
  return parameters;
}

#pragma mark - FBSDKWebDialogDelegate

- (void)webDialog:(FBSDKWebDialog *)webDialog didCompleteWithResults:(NSDictionary<NSString *, id> *)results
{
  if (_webDialog != webDialog) {
    return;
  }

  [self _didCompleteWithResults:results];
}

- (void)webDialog:(FBSDKWebDialog *)webDialog didFailWithError:(NSError *)error
{
  if (_webDialog != webDialog) {
    return;
  }

  [self _didFailWithError:error];
}

- (void)webDialogDidCancel:(FBSDKWebDialog *)webDialog
{
  if (_webDialog != webDialog) {
    return;
  }

  [self _didCancel];
}

#pragma mark - FBSDKBridgeAPI

- (BOOL)_launchDialogViaBridgeAPIWithParameters:(NSDictionary<NSString *, id> *)parameters
{
  UIViewController *topMostViewController = [FBSDKInternalUtility.sharedUtility topMostViewController];
  if (!topMostViewController) {
    [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                           logEntry:@"There are no valid ViewController to present FBSDKWebDialog"];
    [self _handleCompletionWithDialogResults:nil error:nil];
    return NO;
  }

  FBSDKBridgeAPIRequest *request =
  [FBSDKBridgeAPIRequest
   bridgeAPIRequestWithProtocolType:FBSDKBridgeAPIProtocolTypeWeb
   scheme:FBSDKURLSchemeHTTPS
   methodName:FBSDK_APP_REQUEST_METHOD_NAME
   parameters:parameters
   userInfo:nil];

  [FBSDKInternalUtility.sharedUtility registerTransientObject:self];

  __weak typeof(self) weakSelf = self;
  [FBSDKBridgeAPI.sharedInstance
   openBridgeAPIRequest:request
   useSafariViewController:false
   fromViewController:topMostViewController
   completionBlock:^(FBSDKBridgeAPIResponse *response) {
     [weakSelf _handleBridgeAPIResponse:response];
   }];

  return YES;
}

- (void)_handleBridgeAPIResponse:(FBSDKBridgeAPIResponse *)response
{
  if (response.cancelled) {
    [self _didCancel];
    return;
  }

  if (response.error) {
    [self _didFailWithError:response.error];
    return;
  }

  [self _didCompleteWithResults:response.responseParameters];
}

#pragma mark - Response Handling

- (void)_didCompleteWithResults:(NSDictionary<NSString *, id> *)results
{
  if (!results) {
    NSError *error = [NSError errorWithDomain:FBSDKShareErrorDomain
                                         code:FBSDKShareErrorUnknown
                                     userInfo:nil];
    return [self _handleCompletionWithDialogResults:nil error:error];
  }

  if (_dialogIsFrictionless) {
    [_recipientCache updateWithResults:results];
  }
  [self _cleanUp];

  id<FBSDKErrorCreating> errorFactory = [FBSDKErrorFactory new];
  NSError *error = [errorFactory errorWithCode:[FBSDKTypeUtility unsignedIntegerValue:results[@"error_code"]]
                                      userInfo:nil
                                       message:[FBSDKTypeUtility coercedToStringValue:results[@"error_message"]]
                               underlyingError:nil];
  if (!error.code) {
    // reformat "to[x]" keys into an array.
    int counter = 0;
    NSMutableArray *toArray = [NSMutableArray array];
    while (true) {
      NSString *key = [NSString stringWithFormat:@"to[%d]", counter++];
      if (results[key]) {
        [FBSDKTypeUtility array:toArray addObject:results[key]];
      } else {
        break;
      }
    }
    if (toArray.count) {
      NSMutableDictionary<NSString *, id> *mutableResults = [results mutableCopy];
      [FBSDKTypeUtility dictionary:mutableResults setObject:toArray forKey:@"to"];
      results = mutableResults;
    }
  }
  [self _handleCompletionWithDialogResults:results error:error];
  [FBSDKInternalUtility.sharedUtility unregisterTransientObject:self];
}

- (void)_didFailWithError:(NSError *)error
{
  [self _cleanUp];
  [self _handleCompletionWithDialogResults:nil error:error];
  [FBSDKInternalUtility.sharedUtility unregisterTransientObject:self];
}

- (void)_didCancel
{
  [self _cleanUp];
  [_delegate gameRequestDialogDidCancel:self];
  [FBSDKInternalUtility.sharedUtility unregisterTransientObject:self];
}

- (void)_cleanUp
{
  _dialogIsFrictionless = NO;
  _isAwaitingResult = NO;
}

- (void)_handleCompletionWithDialogResults:(nullable NSDictionary<NSString *, id> *)results error:(NSError *)error
{
  if (!_delegate) {
    return;
  }
  switch (error.code) {
    case 0: {
      if (results) {
        [_delegate gameRequestDialog:self didCompleteWithResults:results];
      }
      break;
    }
    case 4201: {
      [_delegate gameRequestDialogDidCancel:self];
      break;
    }
    default: {
      [_delegate gameRequestDialog:self didFailWithError:error];
      break;
    }
  }
  if (error) {
    return;
  } else {}
}

@end

#endif
