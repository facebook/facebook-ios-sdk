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

 #import "FBSDKChooseContextDialog.h"

 #import "FBSDKChooseContextContent.h"
 #import "FBSDKGamingContext.h"
 #import "FBSDKGamingServicesCoreKitBasicsImport.h"

// Deeplink url constants
 #define FBSDK_CONTEXT_DIALOG_URL_SCHEME @"https"
 #define FBSDK_CONTEXT_DIALOG_URL_HOST @"fb.gg"
 #define FBSDK_CONTEXT_DIALOG_URL_PATH @"/dialog/choosecontext/"

 #define FBSDK_CONTEXT_DIALOG_QUERY_PARAMETER_FILTER_KEY @"filter"
 #define FBSDK_CONTEXT_DIALOG_QUERY_PARAMETER_MIN_SIZE_KEY @"min_size"
 #define FBSDK_CONTEXT_DIALOG_QUERY_PARAMETER_MAX_SIZE_KEY @"max_size"
 #define FBSDK_CONTEXT_DIALOG_DEEPLINK_QUERY_CONTEXT_KEY @"context_id"

@interface FBSDKChooseContextDialog () <FBSDKURLOpening>
@end

@implementation FBSDKChooseContextDialog

@synthesize dialogContent = _dialogContent;
@synthesize delegate = _delegate;

+ (instancetype)dialogWithContent:(FBSDKChooseContextContent *)content delegate:(id<FBSDKContextDialogDelegate>)delegate
{
  FBSDKChooseContextDialog *dialog = [self new];
  dialog.dialogContent = content;
  dialog.delegate = delegate;
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
  NSURL *appSwitchDeeplink = [FBSDKInternalUtility.sharedUtility URLWithScheme:FBSDK_CONTEXT_DIALOG_URL_SCHEME
                                                                          host:FBSDK_CONTEXT_DIALOG_URL_HOST
                                                                          path:[NSString stringWithFormat:@"/dialog/choosecontext/%@/", FBSDKSettings.appID]
                                                               queryParameters:[self queryParameters]
                                                                         error:&error];

  [[FBSDKBridgeAPI sharedInstance]
   openURL:appSwitchDeeplink
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
  if (!errorRef) {
    return NO;
  }

  if (!FBSDKSettings.appID) {
    *errorRef = [FBSDKError errorWithCode:FBSDKErrorInvalidArgument message:@"App ID is not set in settings"];
    return NO;
  }
  if (![self.dialogContent respondsToSelector:@selector(validateWithError:)]) {
    *errorRef = [FBSDKError invalidArgumentErrorWithDomain:FBSDKErrorDomain
                                                      name:@"content"
                                                     value:self.dialogContent
                                                   message:nil];

    return NO;
  }
  return [self.dialogContent validateWithError:errorRef];
}

 #pragma mark - Helpers
- (void)_handleDialogError:(NSError *)dialogError
{
  [self.delegate contextDialog:self didFailWithError:dialogError];
}

- (NSMutableDictionary *)queryParameters
{
  NSMutableDictionary *parameters = [NSMutableDictionary new];
  if (self.dialogContent && [self.dialogContent isKindOfClass:[FBSDKChooseContextContent class]]) {
    FBSDKChooseContextContent *content = (FBSDKChooseContextContent *)self.dialogContent;

    NSString *filtersName = [FBSDKChooseContextContent filtersNameForFilters:content.filter];
    if (filtersName) {
      parameters[FBSDK_CONTEXT_DIALOG_QUERY_PARAMETER_FILTER_KEY] = filtersName;
    }

    NSNumber *minParticipants = [NSNumber numberWithInteger:content.minParticipants];
    if (minParticipants != nil) {
      parameters[FBSDK_CONTEXT_DIALOG_QUERY_PARAMETER_MIN_SIZE_KEY] = minParticipants;
    }

    NSNumber *maxParticipants = [NSNumber numberWithInteger:content.maxParticipants];
    if (maxParticipants != nil) {
      parameters[FBSDK_CONTEXT_DIALOG_QUERY_PARAMETER_MAX_SIZE_KEY] = maxParticipants;
    }
  }
  return parameters;
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

  FBSDKGamingContext *context = [self _parseURLForGamingContext:url];
  if (context) {
    [self.delegate contextDialogDidComplete:self];
  }
  return isGamingUrl;
}

- (BOOL) canOpenURL:(NSURL *)url
     forApplication:(UIApplication *)application
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
  return
  [url.scheme hasPrefix:[NSString stringWithFormat:@"fb%@", [FBSDKSettings appID]]];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  [self.delegate contextDialogDidCancel:self];
}

- (BOOL)isAuthenticationURL:(NSURL *)url
{
  return false;
}

- (FBSDKGamingContext *_Nullable)_parseURLForGamingContext:(NSURL *)url
{
  NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];

  if (!urlComponents.queryItems || !urlComponents.queryItems.count) {
    return nil;
  }
  NSURLQueryItem *contextIDQueryItem = urlComponents.queryItems.firstObject;
  if (![contextIDQueryItem.name isEqual:FBSDK_CONTEXT_DIALOG_DEEPLINK_QUERY_CONTEXT_KEY]) {
    return nil;
  }
  NSString *contextID = contextIDQueryItem.value;
  [[FBSDKGamingContext currentContext] setIdentifier:contextID];

  return [FBSDKGamingContext currentContext];
}

@end
#endif
