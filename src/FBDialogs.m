/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Social/Social.h>

#import "FBDialogs+Internal.h"
#import "FBSession.h"
#import "FBError.h"
#import "FBUtility.h"
#import "FBAppCall+Internal.h"
#import "FBAppBridge.h"
#import "FBAccessTokenData.h"
#import "FBInsights+Internal.h"
#import "FBDialogsParams+Internal.h"
#import "FBLoginDialogParams.h"
#import "FBShareDialogParams.h"
#import "FBOpenGraphActionShareDialogParams.h"
#import "FBDialogsData+Internal.h"
#import "FBAppLinkData+Internal.h"
#import "FBAccessTokenData+Internal.h"
#import "FBSettings.h"

static NSString *const kFBNativeLoginMinVersion = @"20130214";

@interface FBDialogs ()

+ (NSError*)createError:(NSString*)reason
                session:(FBSession *)session;

@end

@implementation FBDialogs

+ (BOOL)presentOSIntegratedShareDialogModallyFrom:(UIViewController*)viewController
                                      initialText:(NSString*)initialText
                                            image:(UIImage*)image
                                              url:(NSURL*)url
                                          handler:(FBOSIntegratedShareDialogHandler)handler {
    NSArray *images = image ? [NSArray arrayWithObject:image] : nil;
    NSArray *urls = url ? [NSArray arrayWithObject:url] : nil;
    
    return [self presentOSIntegratedShareDialogModallyFrom:viewController
                                                   session:nil
                                               initialText:initialText
                                                    images:images
                                                      urls:urls
                                                   handler:handler];
}

+ (BOOL)presentOSIntegratedShareDialogModallyFrom:(UIViewController*)viewController
                                      initialText:(NSString*)initialText
                                           images:(NSArray*)images
                                             urls:(NSArray*)urls
                                          handler:(FBOSIntegratedShareDialogHandler)handler {
    return [self presentOSIntegratedShareDialogModallyFrom:viewController
                                                   session:nil
                                               initialText:initialText
                                                    images:images
                                                      urls:urls
                                                   handler:handler];
}

+ (BOOL)presentOSIntegratedShareDialogModallyFrom:(UIViewController*)viewController
                                          session:(FBSession*)session
                                      initialText:(NSString*)initialText
                                           images:(NSArray*)images
                                             urls:(NSArray*)urls
                                          handler:(FBOSIntegratedShareDialogHandler)handler {
    SLComposeViewController *composeViewController = [FBDialogs composeViewControllerWithSession:session
                                                                                         handler:handler];
    if (!composeViewController) {
        return NO;
    }
    
    if (initialText) {
        [composeViewController setInitialText:initialText];
    }
    if (images && images.count > 0) {
        for (UIImage *image in images) {
            [composeViewController addImage:image];
        }
    }
    if (urls && urls.count > 0) {
        for (NSURL *url in urls) {
            [composeViewController addURL:url];
        }
    }
    
    [composeViewController setCompletionHandler:^(SLComposeViewControllerResult result) {
        BOOL cancelled = (result == SLComposeViewControllerResultCancelled);
        
        [FBInsights logImplicitEvent:FBInsightsEventNameShareSheetDismiss
                          valueToSum:1.0
                          parameters:@{ @"render_type" : @"Native",
FBInsightsEventParameterDialogOutcome : (cancelled
                                         ? FBInsightsDialogOutcomeValue_Cancelled
                                         : FBInsightsDialogOutcomeValue_Completed) }
                             session:session];
        
        if (handler) {
            handler(cancelled ?  FBOSIntegratedShareDialogResultCancelled :  FBOSIntegratedShareDialogResultSucceeded, nil);
        }
    }];
    
    [FBInsights logImplicitEvent:FBInsightsEventNameShareSheetLaunch
                      valueToSum:1.0
                      parameters:@{ @"render_type" : @"Native" }
                         session:session];
    [viewController presentModalViewController:composeViewController animated:YES];
    
    return YES;
}

+ (BOOL)canPresentOSIntegratedShareDialogWithSession:(FBSession*)session {
    return [FBDialogs composeViewControllerWithSession:session
                                               handler:nil] != nil;
}

// Private method to abstract away url polling for the present* and canPresent* methods for
// the FB Login Dialog
+ (NSString *)versionForLoginDialogWithParams:(FBLoginDialogParams *)params {
    // Select the right minimum version for the passed in combination of params.
    // NOTE: For now, there is only one.
    NSString *minVersion = kFBNativeLoginMinVersion;
    
    return [FBAppBridge installedFBNativeAppVersionForMethod:@"auth3" minVersion:minVersion];
}

+ (BOOL)canPresentLoginDialogWithParams:(FBLoginDialogParams *)params {
    NSString *version = [FBDialogs versionForLoginDialogWithParams:params];
    return (version != nil);
}

+ (FBAppCall *)presentLoginDialogWithParams:(FBLoginDialogParams *)params
                                  clientState:(NSDictionary *)clientState
                                      handler:(FBDialogAppCallCompletionHandler)handler {
    FBAppCall *call = nil;
    NSString *version = [FBDialogs versionForLoginDialogWithParams:params];
    if (version) {
        FBDialogsData *dialogData = [[[FBDialogsData alloc] initWithMethod:@"auth3"
                                                                 arguments:[params dictionaryMethodArgs]]
                                     autorelease];
        dialogData.clientState = clientState;
        
        call = [[[FBAppCall alloc] init] autorelease];
        call.dialogData = dialogData;
        
        
        // log the timestamp for starting the switch to the Facebook application
        [FBInsights logImplicitEvent:FBInsightsEventNameFBDialogsNativeLoginDialogStart
                          valueToSum:1.0
                          parameters:@{
                            FBInsightsNativeLoginDialogStartTime : [NSNumber numberWithDouble:round(1000 * [[NSDate date] timeIntervalSince1970])],
                            @"action_id" : [call ID],
                            @"app_id" : [FBSettings defaultAppID]
                          }
                          session:nil];
        [[FBAppBridge sharedInstance] dispatchDialogAppCall:call
                                                   version:version
                                         completionHandler:handler];
    }
    
    return call;
}

+ (BOOL)canPresentShareDialogWithParams:(FBShareDialogParams *)params {
    BOOL canPresent = [params appBridgeVersion] != nil;
    [FBInsights logImplicitEvent:FBInsightsEventNameFBDialogsCanPresentShareDialog
                      valueToSum:1.0
                      parameters:@{ FBInsightsEventParameterDialogOutcome :
                                         canPresent ?
                                            FBInsightsDialogOutcomeValue_Completed :
                                            FBInsightsDialogOutcomeValue_Failed }
                         session:nil];
    return canPresent;
}

+ (FBAppCall *)presentShareDialogWithParams:(FBShareDialogParams *)params
                                clientState:(NSDictionary *)clientState
                                    handler:(FBDialogAppCallCompletionHandler)handler {
    FBAppCall *call = nil;
    NSString *version = [params appBridgeVersion];
    if (version) {
        FBDialogsData *dialogData = [[[FBDialogsData alloc] initWithMethod:@"share"
                                                                 arguments:[params dictionaryMethodArgs]]
                                     autorelease];
        dialogData.clientState = clientState;
        
        call = [[[FBAppCall alloc] init] autorelease];
        call.dialogData = dialogData;
        
        [[FBAppBridge sharedInstance] dispatchDialogAppCall:call
                                                   version:version
                                         completionHandler:handler];
    }
    
    return call;
}

+ (FBAppCall *)presentShareDialogWithLink:(NSURL *)link
                                  handler:(FBDialogAppCallCompletionHandler)handler {
    return [FBDialogs presentShareDialogWithLink:link
                                            name:nil
                                         caption:nil
                                     description:nil
                                         picture:nil
                                     clientState:nil
                                         handler:handler];
}

+ (FBAppCall *)presentShareDialogWithLink:(NSURL *)link
                                     name:(NSString *)name
                                  handler:(FBDialogAppCallCompletionHandler)handler {
    return [FBDialogs presentShareDialogWithLink:link
                                            name:name
                                         caption:nil
                                     description:nil
                                         picture:nil
                                     clientState:nil
                                         handler:handler];
}


+ (FBAppCall *)presentShareDialogWithLink:(NSURL *)link
                                     name:(NSString *)name
                                  caption:(NSString *)caption
                              description:(NSString *)description
                                  picture:(NSURL *)picture
                              clientState:(NSDictionary *)clientState
                                  handler:(FBDialogAppCallCompletionHandler)handler {
    FBShareDialogParams *params = [[[FBShareDialogParams alloc] init] autorelease];
    params.link = link;
    params.name = name;
    params.caption = caption;
    params.description = description;
    params.picture = picture;
    
    return [self presentShareDialogWithParams:params
                                  clientState:clientState
                                      handler:handler];
}

+ (BOOL)canPresentShareDialogWithOpenGraphActionParams:(FBOpenGraphActionShareDialogParams *)params {
    BOOL canPresent = [params appBridgeVersion] != nil;
    [FBInsights logImplicitEvent:FBInsightsEventNameFBDialogsCanPresentShareDialogOG
                      valueToSum:1.0
                      parameters:@{ FBInsightsEventParameterDialogOutcome :
                                         canPresent ?
                                            FBInsightsDialogOutcomeValue_Completed :
                                            FBInsightsDialogOutcomeValue_Failed }
                         session:nil];
    return canPresent;
}

+ (FBAppCall *)presentShareDialogWithOpenGraphActionParams:(FBOpenGraphActionShareDialogParams *)params
                                               clientState:(NSDictionary *)clientState
                                                   handler:(FBDialogAppCallCompletionHandler)handler {
    FBAppCall *call = nil;
    NSString *version = [params appBridgeVersion];
    if (version) {
        call = [[[FBAppCall alloc] init] autorelease];

        NSError *validationError = [params validate];
        if (validationError) {
            if (handler) {
                handler(call, nil, validationError);
            }
        } else {
            FBDialogsData *dialogData = [[[FBDialogsData alloc] initWithMethod:@"ogshare"
                                                                      arguments:[params dictionaryMethodArgs]]
                                         autorelease];
            dialogData.clientState = clientState;

            call.dialogData = dialogData;
        
            [[FBAppBridge sharedInstance] dispatchDialogAppCall:call
                                                        version:version
                                              completionHandler:handler];
        }
    }
    
    return call;
}

+ (FBAppCall *)presentShareDialogWithOpenGraphAction:(id<FBOpenGraphAction>)action
                                          actionType:(NSString *)actionType
                                 previewPropertyName:(NSString *)previewPropertyName
                                             handler:(FBDialogAppCallCompletionHandler) handler {
    return [FBDialogs presentShareDialogWithOpenGraphAction:action
                                                 actionType:actionType
                                        previewPropertyName:previewPropertyName
                                                clientState:nil
                                                    handler:handler];
}

+ (FBAppCall *)presentShareDialogWithOpenGraphAction:(id<FBOpenGraphAction>)action
                                          actionType:(NSString *)actionType
                                 previewPropertyName:(NSString*)previewPropertyName
                                         clientState:(NSDictionary *)clientState
                                             handler:(FBDialogAppCallCompletionHandler) handler {
    FBOpenGraphActionShareDialogParams *params = [[[FBOpenGraphActionShareDialogParams alloc] init] autorelease];
    
    // If we have OG objects, we want to pass just their URL or id to the share dialog.
    params.action = action;
    params.actionType = actionType;
    params.previewPropertyName = previewPropertyName;
    
    return [self presentShareDialogWithOpenGraphActionParams:params
                                                 clientState:clientState
                                                     handler:handler];
}

+ (SLComposeViewController*)composeViewControllerWithSession:(FBSession*)session
                                                     handler:(FBOSIntegratedShareDialogHandler)handler {
    // Can we even call the iOS API?
    Class composeViewControllerClass = [SLComposeViewController class];
    if (composeViewControllerClass == nil ||
        [composeViewControllerClass isAvailableForServiceType:SLServiceTypeFacebook] == NO) {
        if (handler) {
            handler( FBOSIntegratedShareDialogResultError, [self createError:FBErrorDialogNotSupported
                                                                     session:session]);
        }
        return nil;
    }
    
    if (session == nil) {
        // No session provided -- do we have an activeSession? We must either have a session that
        // was authenticated with native auth, or no session at all (in which case the app is
        // running unTOSed and we will rely on the OS to authenticate/TOS the user).
        session = [FBSession activeSession];
    }
    if (session != nil) {
        // If we have an open session and it's not native auth, fail. If the session is
        // not open, attempting to put up the dialog will prompt the user to configure
        // their account.
        if (session.isOpen && session.accessTokenData.loginType != FBSessionLoginTypeSystemAccount) {
            if (handler) {
                handler( FBOSIntegratedShareDialogResultError, [self createError:FBErrorDialogInvalidForSession
                                                                         session:session]);
            }
            return nil;
        }
    }
    
    SLComposeViewController *composeViewController = [composeViewControllerClass composeViewControllerForServiceType:SLServiceTypeFacebook];
    if (composeViewController == nil) {
        if (handler) {
            handler( FBOSIntegratedShareDialogResultError, [self createError:FBErrorDialogCantBeDisplayed
                                                                     session:session]);
        }
        return nil;
    }
    return composeViewController;
}

+ (NSError *)createError:(NSString *)reason
                 session:(FBSession *)session {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[FBErrorDialogReasonKey] = reason;
    if (session) {
        userInfo[FBErrorSessionKey] = session;
    }
    NSError *error = [NSError errorWithDomain:FacebookSDKDomain
                                         code:FBErrorDialog
                                     userInfo:userInfo];
    return error;
}

@end

