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

 #import "FBSDKGameRequestDialog.h"

 #ifdef FBSDKCOCOAPODS
  #import <FBSDKCoreKit/FBSDKCoreKit+Internal.h>
 #else
  #import "FBSDKCoreKit+Internal.h"
 #endif
 #import "FBSDKGameRequestFrictionlessRecipientCache.h"
 #import "FBSDKGameRequestURLProvider.h"
 #import "FBSDKShareConstants.h"
 #import "FBSDKShareUtility.h"

 #define FBSDK_APP_REQUEST_METHOD_NAME @"apprequests"

@interface FBSDKGameRequestDialog () <FBSDKWebDialogDelegate, FBSDKURLOpening>
@end

@implementation FBSDKGameRequestDialog
{
  BOOL _dialogIsFrictionless;
  FBSDKWebDialog *_webDialog;
}

 #pragma mark - Class Methods

static FBSDKGameRequestFrictionlessRecipientCache *_recipientCache = nil;

+ (void)initialize
{
  if (self == [FBSDKGameRequestDialog class]) {
    _recipientCache = [FBSDKGameRequestFrictionlessRecipientCache new];
  }
}

+ (instancetype)dialogWithContent:(FBSDKGameRequestContent *)content delegate:(id<FBSDKGameRequestDialogDelegate>)delegate
{
  FBSDKGameRequestDialog *dialog = [self new];
  dialog.content = content;
  dialog.delegate = delegate;
  return dialog;
}

+ (instancetype)showWithContent:(FBSDKGameRequestContent *)content delegate:(id<FBSDKGameRequestDialogDelegate>)delegate
{
  FBSDKGameRequestDialog *dialog = [self dialogWithContent:content delegate:delegate];
  NSString *graphDomain = [FBSDKUtility getGraphDomainFromToken];
  if ([graphDomain isEqualToString:@"gaming"] && [FBSDKInternalUtility isFacebookAppInstalled]) {
    [dialog launchGameRequestDialogWithGameRequestContent:content delegate:delegate];
  } else {
    [dialog show];
  }
  return dialog;
}

- (void)launchGameRequestDialogWithGameRequestContent:(FBSDKGameRequestContent *)requestContent delegate:(id<FBSDKGameRequestDialogDelegate>)delegate;
{
  __weak typeof(self) weakSelf = self;
  if ([FBSDKAccessToken currentAccessToken] == nil) {
    return;
  }

  NSDictionary *contentDictionary = [self _convertGameRequestContentToDictionaryV2:_content];
  [[FBSDKBridgeAPI sharedInstance]
   openURL:[FBSDKGameRequestURLProvider createDeepLinkURLWithQueryDictionary:contentDictionary]
   sender:weakSelf
   handler:^(BOOL success, NSError *_Nullable error) {
     if (!success) {}
   }];
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

  if (isGamingUrl) {
    [self completeSuccessfully];
  }

  return isGamingUrl;
}

- (BOOL) canOpenURL:(NSURL *)url
     forApplication:(UIApplication *)application
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
  return
  [self
   isValidCallbackURL:url];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  [self completeSuccessfully];
}

- (BOOL)isAuthenticationURL:(NSURL *)url
{
  return false;
}

- (void)completeSuccessfully
{
  // _completionHandler(true, nil);
}

 #pragma mark - Helpers

- (BOOL)isValidCallbackURL:(NSURL *)url
{
  return
  [url.scheme hasPrefix:[NSString stringWithFormat:@"fb%@", [FBSDKSettings appID]]];
}

 #pragma mark - Object Lifecycle

- (instancetype)init
{
  if ((self = [super init])) {
    _webDialog = [FBSDKWebDialog new];
    _webDialog.delegate = self;
    _webDialog.name = FBSDK_APP_REQUEST_METHOD_NAME;
  }
  return self;
}

- (void)dealloc
{
  _webDialog.delegate = nil;
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
    error = [FBSDKError errorWithDomain:FBSDKShareErrorDomain
                                   code:FBSDKShareErrorDialogNotAvailable
                                message:@"Game request dialog is not available."];
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

  NSMutableDictionary *parameters = [self _convertGameRequestContentToDictionaryV1:content];

  // check if we are sending to a specific set of recipients.  if we are and they are all frictionless recipients, we
  // can perform this action without displaying the web dialog
  _webDialog.deferVisibility = NO;
  NSArray *recipients = content.recipients;
  if (_frictionlessRequestsEnabled && recipients) {
    // specify these parameters to get the frictionless recipients from the dialog when it is presented
    parameters[@"frictionless"] = @YES;
    parameters[@"get_frictionless_recipients"] = @YES;

    _dialogIsFrictionless = YES;
    if ([_recipientCache recipientsAreFrictionless:recipients]) {
      _webDialog.deferVisibility = YES;
    }
  }

  [self _launchDialogViaBridgeAPIWithParameters:parameters];

  [FBSDKInternalUtility registerTransientObject:self];
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
    *errorRef = [FBSDKError invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                      name:@"content"
                                                     value:self.content
                                                   message:nil];
  }
  return NO;
}

- (NSMutableDictionary *)_convertGameRequestContentToDictionaryV1:(FBSDKGameRequestContent *)content
{
  NSMutableDictionary *parameters = [NSMutableDictionary new];
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

- (NSMutableDictionary *)_convertGameRequestContentToDictionaryV2:(FBSDKGameRequestContent *)content
{
  NSMutableDictionary *parameters = [NSMutableDictionary new];
  [FBSDKTypeUtility dictionary:parameters setObject:[content.recipients componentsJoinedByString:@","] forKey:@"to"];
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

- (void)webDialog:(FBSDKWebDialog *)webDialog didCompleteWithResults:(NSDictionary *)results
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

- (BOOL)_launchDialogViaBridgeAPIWithParameters:(NSDictionary *)parameters
{
  UIViewController *topMostViewController = [FBSDKInternalUtility topMostViewController];
  if (!topMostViewController) {
    [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                       formatString:@"There are no valid ViewController to present FBSDKWebDialog", nil];
    [self _handleCompletionWithDialogResults:nil error:nil];
    return NO;
  }

  FBSDKBridgeAPIRequest *request =
  [FBSDKBridgeAPIRequest
   bridgeAPIRequestWithProtocolType:FBSDKBridgeAPIProtocolTypeWeb
   scheme:@"https"
   methodName:FBSDK_APP_REQUEST_METHOD_NAME
   methodVersion:nil
   parameters:parameters
   userInfo:nil];

  [FBSDKInternalUtility registerTransientObject:self];

  __weak typeof(self) weakSelf = self;
  [[FBSDKBridgeAPI sharedInstance]
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

- (void)_didCompleteWithResults:(NSDictionary *)results
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

  NSError *error = [FBSDKError errorWithCode:[FBSDKTypeUtility unsignedIntegerValue:results[@"error_code"]]
                                     message:[FBSDKTypeUtility coercedToStringValue:results[@"error_message"]]];
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
      NSMutableDictionary *mutableResults = [results mutableCopy];
      [FBSDKTypeUtility dictionary:mutableResults setObject:toArray forKey:@"to"];
      results = mutableResults;
    }
  }
  [self _handleCompletionWithDialogResults:results error:error];
  [FBSDKInternalUtility unregisterTransientObject:self];
}

- (void)_didFailWithError:(NSError *)error
{
  [self _cleanUp];
  [self _handleCompletionWithDialogResults:nil error:error];
  [FBSDKInternalUtility unregisterTransientObject:self];
}

- (void)_didCancel
{
  [self _cleanUp];
  [_delegate gameRequestDialogDidCancel:self];
  [FBSDKInternalUtility unregisterTransientObject:self];
}

 #pragma mark - Helper Methods

- (void)_cleanUp
{
  _dialogIsFrictionless = NO;
}

- (void)_handleCompletionWithDialogResults:(NSDictionary *)results error:(NSError *)error
{
  if (!_delegate) {
    return;
  }
  switch (error.code) {
    case 0: {
      [_delegate gameRequestDialog:self didCompleteWithResults:results];
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
