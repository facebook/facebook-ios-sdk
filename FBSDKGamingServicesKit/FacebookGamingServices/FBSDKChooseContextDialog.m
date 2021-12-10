/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKChooseContextDialog.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import <FacebookGamingServices/FacebookGamingServices-Swift.h>

#import "FBSDKChooseContextContent.h"

// Deeplink url constants
#define FBSDK_CONTEXT_DIALOG_URL_HOST @"fb.gg"
#define FBSDK_CONTEXT_DIALOG_DEEPLINK_PATH @"/dialog/choosecontext/%@/"
#define FBSDK_CONTEXT_DIALOG_MSITE_URL_PATH @"/dialog/choosecontext/"

#define FBSDK_CONTEXT_DIALOG_QUERY_PARAMETER_FILTER_KEY @"filter"
#define FBSDK_CONTEXT_DIALOG_QUERY_PARAMETER_MIN_SIZE_KEY @"min_size"
#define FBSDK_CONTEXT_DIALOG_QUERY_PARAMETER_MAX_SIZE_KEY @"max_size"
#define FBSDK_CONTEXT_DIALOG_DEEPLINK_QUERY_CONTEXT_KEY @"context_id"
#define FBSDK_CONTEXT_DIALOG_DEEPLINK_QUERY_CONTEXT_SIZE_KEY @"context_size"

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
       NSError *sdkError = [FBSDKError
                            errorWithCode:FBSDKErrorBridgeAPIInterruption
                            message:@"Error occured while interacting with Gaming Services, Failed to open bridge."
                            underlyingError:bridgeError];
       [weakSelf _handleDialogError:sdkError];
     }
   }];
  return YES;
}

- (BOOL)validateWithError:(NSError *__autoreleasing *)errorRef
{
  if (!FBSDKSettings.sharedSettings.appID) {
    if (errorRef != NULL) {
      *errorRef = [FBSDKError errorWithCode:FBSDKErrorUnknown message:@"App ID is not set in settings"];
    }
    return NO;
  }
  if (![self.dialogContent respondsToSelector:@selector(validateWithError:)]) {
    if (errorRef != NULL) {
      *errorRef = [FBSDKError invalidArgumentErrorWithDomain:FBSDKErrorDomain
                                                        name:@"content"
                                                       value:self.dialogContent
                                                     message:nil];
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
  NSMutableDictionary<NSString *, id> *parametersDictionary = [self queryParameters];
  NSError *error;
  return [_internalUtility URLWithScheme:FBSDKURLSchemeHTTPS
                                    host:FBSDK_CONTEXT_DIALOG_URL_HOST
                                    path:[NSString stringWithFormat:FBSDK_CONTEXT_DIALOG_DEEPLINK_PATH, FBSDKSettings.sharedSettings.appID]
                         queryParameters:parametersDictionary
                                   error:&error];
}

- (NSMutableDictionary<NSString *, id> *)queryParameters
{
  NSMutableDictionary<NSString *, id> *appSwitchParameters = [NSMutableDictionary new];
  if (self.dialogContent && [self.dialogContent isKindOfClass:FBSDKChooseContextContent.class]) {
    FBSDKChooseContextContent *content = (FBSDKChooseContextContent *)self.dialogContent;

    NSString *filtersName = [FBSDKChooseContextContent filtersNameForFilters:content.filter];
    if (filtersName) {
      appSwitchParameters[FBSDK_CONTEXT_DIALOG_QUERY_PARAMETER_FILTER_KEY] = filtersName;
    }

    NSNumber *minParticipants = @(content.minParticipants);
    if (minParticipants != nil) {
      appSwitchParameters[FBSDK_CONTEXT_DIALOG_QUERY_PARAMETER_MIN_SIZE_KEY] = minParticipants;
    }

    NSNumber *maxParticipants = @(content.maxParticipants);
    if (maxParticipants != nil) {
      appSwitchParameters[FBSDK_CONTEXT_DIALOG_QUERY_PARAMETER_MAX_SIZE_KEY] = maxParticipants;
    }
  }
  return appSwitchParameters;
}

- (FBSDKGamingContext *_Nullable)_gamingContextFromURL:(NSURL *)url
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

  FBSDKGamingContext *context = [self _gamingContextFromURL:url];
  if (context) {
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
