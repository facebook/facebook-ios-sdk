/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKChooseContextDialog.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import <FacebookGamingServices/FacebookGamingServices-Swift.h>
// Deeplink url constants
#define FBSDK_CONTEXT_DIALOG_URL_HOST @"fb.gg"
#define FBSDK_CONTEXT_DIALOG_DEEPLINK_PATH @"/dialog/choosecontext/%@/"
#define FBSDK_CONTEXT_DIALOG_MSITE_URL_PATH @"/dialog/choosecontext/"

#define FBSDK_CONTEXT_DIALOG_QUERY_PARAMETER_FILTER_KEY @"filter"
#define FBSDK_CONTEXT_DIALOG_QUERY_PARAMETER_MIN_SIZE_KEY @"min_size"
#define FBSDK_CONTEXT_DIALOG_QUERY_PARAMETER_MAX_SIZE_KEY @"max_size"
#define FBSDK_CONTEXT_DIALOG_DEEPLINK_QUERY_CONTEXT_KEY @"context_id"
#define FBSDK_CONTEXT_DIALOG_DEEPLINK_QUERY_CONTEXT_SIZE_KEY @"context_size"
#define FBSDK_CONTEXT_DIALOG_DEEPLINK_QUERY_ERROR_MESSAGE_KEY @"error_message"

@interface FBSDKChooseContextDialog () <FBSDKURLOpening>
@property (nonatomic) id<FBSDKInternalUtility> internalUtility;
@end

@implementation FBSDKChooseContextDialog

+ (instancetype)dialogWithContent:(FBSDKChooseContextContent *)content
                         delegate:(nullable id<FBSDKContextDialogDelegate>)delegate
{
  FBSDKChooseContextDialog *dialog = [FBSDKChooseContextDialog dialogWithContent:content
                                                                        delegate:delegate
                                                                 internalUtility:FBSDKInternalUtility.sharedUtility];
  return dialog;
}

+ (instancetype)dialogWithContent:(FBSDKChooseContextContent *)content
                         delegate:(id<FBSDKContextDialogDelegate>)delegate
                  internalUtility:(id<FBSDKInternalUtility>)internalUtility
{
  FBSDKChooseContextDialog *dialog = [self new];
  dialog.dialogContent = content;
  dialog.delegate = delegate;
  dialog->_internalUtility = internalUtility;
  return dialog;
}

- (BOOL)show
{
  NSError *error;
  __weak typeof(self) weakSelf = self;
  if (![self validateWithError:&error] && !error) {
    return NO;
  }
  if (error) {
    [self _handleDialogError:error];
    return NO;
  }
  NSURL *dialogURL = [self _generateURL];

  [FBSDKBridgeAPI.sharedInstance
   openURL:dialogURL
   sender:weakSelf
   handler:^(BOOL success, NSError *_Nullable bridgeError) {
     if (!success && bridgeError) {
       id<FBSDKErrorCreating> errorFactory = [FBSDKErrorFactory new];
       NSError *sdkError = [errorFactory errorWithCode:FBSDKErrorBridgeAPIInterruption
                                              userInfo:nil
                                               message:@"Error occured while interacting with Gaming Services, Failed to open bridge."
                                       underlyingError:bridgeError];
       [weakSelf _handleDialogError:sdkError];
     }
   }];
  return YES;
}

- (BOOL)validateWithError:(NSError *__autoreleasing *)errorRef
{
  id<FBSDKErrorCreating> errorFactory = [FBSDKErrorFactory new];

  if (!FBSDKSettings.sharedSettings.appID) {
    if (errorRef != NULL) {
      *errorRef = [errorFactory errorWithCode:FBSDKErrorUnknown
                                     userInfo:nil
                                      message:@"App ID is not set in settings"
                              underlyingError:nil];
    }
    return NO;
  }
  if (![self.dialogContent respondsToSelector:@selector(validateWithError:)]) {
    if (errorRef != NULL) {
      *errorRef = [errorFactory invalidArgumentErrorWithDomain:FBSDKErrorDomain
                                                          name:@"content"
                                                         value:self.dialogContent
                                                       message:nil
                                               underlyingError:nil];
    }

    return NO;
  }
  return [self.dialogContent validateWithError:errorRef];
}

- (void)_handleDialogError:(NSError *)dialogError
{
  [self.delegate contextDialog:self didFailWithError:dialogError];
}

- (NSURL *)_generateURL
{
  NSMutableDictionary<NSString *, NSString *> *parametersDictionary = [self queryParameters];
  NSError *error;
  return [_internalUtility URLWithScheme:FBSDKURLSchemeHTTPS
                                    host:FBSDK_CONTEXT_DIALOG_URL_HOST
                                    path:[NSString stringWithFormat:FBSDK_CONTEXT_DIALOG_DEEPLINK_PATH, FBSDKSettings.sharedSettings.appID]
                         queryParameters:parametersDictionary
                                   error:&error];
}

- (NSMutableDictionary<NSString *, NSString *> *)queryParameters
{
  NSMutableDictionary<NSString *, NSString *> *appSwitchParameters = [NSMutableDictionary new];
  if (self.dialogContent && [self.dialogContent isKindOfClass:FBSDKChooseContextContent.class]) {
    FBSDKChooseContextContent *content = (FBSDKChooseContextContent *)self.dialogContent;

    [FBSDKTypeUtility dictionary:appSwitchParameters
                       setObject:[FBSDKChooseContextContent filtersNameForFilters:content.filter]
                          forKey:FBSDK_CONTEXT_DIALOG_QUERY_PARAMETER_FILTER_KEY];

    [FBSDKTypeUtility dictionary:appSwitchParameters
                       setObject:@(content.minParticipants).stringValue
                          forKey:FBSDK_CONTEXT_DIALOG_QUERY_PARAMETER_MIN_SIZE_KEY];

    [FBSDKTypeUtility dictionary:appSwitchParameters
                       setObject:@(content.maxParticipants).stringValue
                          forKey:FBSDK_CONTEXT_DIALOG_QUERY_PARAMETER_MAX_SIZE_KEY];
  }
  return appSwitchParameters;
}

- (FBSDKGamingContext *_Nullable)_gamingContextFromURL:(NSURL *)url error:(NSError *__autoreleasing *)errorRef
{
  NSString *contextID;
  NSInteger contextSize = 0;
  NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];

  if (!urlComponents.queryItems || !urlComponents.queryItems.count) {
    return nil;
  }

  for (NSURLQueryItem *queryItem in urlComponents.queryItems) {
    if ([queryItem.name isEqual:FBSDK_CONTEXT_DIALOG_DEEPLINK_QUERY_CONTEXT_KEY]) {
      contextID = queryItem.value;
    }
    if ([queryItem.name isEqual:FBSDK_CONTEXT_DIALOG_DEEPLINK_QUERY_CONTEXT_SIZE_KEY]) {
      contextSize = [queryItem.value integerValue];
    }
    if ([queryItem.name isEqual:FBSDK_CONTEXT_DIALOG_DEEPLINK_QUERY_ERROR_MESSAGE_KEY] && errorRef != nil) {
      id<FBSDKErrorCreating> errorFactory = [FBSDKErrorFactory new];
      *errorRef = [errorFactory unknownErrorWithMessage:queryItem.value userInfo:nil];
    }
  }

  if (contextID && contextID.length > 0) {
    FBSDKGamingContext.currentContext = [[FBSDKGamingContext alloc] initWithIdentifier:contextID size:contextSize];
  } else {
    FBSDKGamingContext.currentContext = nil;
  }

  return FBSDKGamingContext.currentContext;
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

  if (!isGamingUrl) {
    return isGamingUrl;
  }

  NSError *error;
  FBSDKGamingContext *context = [self _gamingContextFromURL:url error:&error];
  if (error) {
    [self _handleDialogError:error];
  } else if (context) {
    [self.delegate contextDialogDidComplete:self];
  } else {
    [self.delegate contextDialogDidCancel:self];
  }
  return isGamingUrl;
}

- (BOOL) canOpenURL:(NSURL *)url
     forApplication:(UIApplication *)application
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
  return
  [url.scheme hasPrefix:[NSString stringWithFormat:@"fb%@", FBSDKSettings.sharedSettings.appID]];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  [self.delegate contextDialogDidCancel:self];
}

- (BOOL)isAuthenticationURL:(NSURL *)url
{
  return false;
}

@end
#endif
