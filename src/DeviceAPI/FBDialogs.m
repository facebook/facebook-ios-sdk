/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "FBDialogs+Internal.h"
#import "FBDialogsData+Internal.h"
#import "FBDialogsParams+Internal.h"

#import <Social/Social.h>

#import "FBAccessTokenData+Internal.h"
#import "FBAccessTokenData.h"
#import "FBAppBridge.h"
#import "FBAppBridgeScheme.h"
#import "FBAppCall+Internal.h"
#import "FBAppEvents+Internal.h"
#import "FBAppLinkData+Internal.h"
#import "FBDynamicFrameworkLoader.h"
#import "FBError.h"
#import "FBLoginDialogParams.h"
#import "FBOpenGraphActionShareDialogParams+Internal.h"
#import "FBSession.h"
#import "FBSettings+Internal.h"
#import "FBShareDialogParams.h"
#import "FBShareDialogPhotoParams.h"
#import "FBUtility.h"

@interface FBDialogs ()

+ (NSError *)createError:(NSString *)reason
                 session:(FBSession *)session;

@end

@implementation FBDialogs

+ (BOOL)presentOSIntegratedShareDialogModallyFrom:(UIViewController *)viewController
                                      initialText:(NSString *)initialText
                                            image:(UIImage *)image
                                              url:(NSURL *)url
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

+ (BOOL)presentOSIntegratedShareDialogModallyFrom:(UIViewController *)viewController
                                      initialText:(NSString *)initialText
                                           images:(NSArray *)images
                                             urls:(NSArray *)urls
                                          handler:(FBOSIntegratedShareDialogHandler)handler {
    return [self presentOSIntegratedShareDialogModallyFrom:viewController
                                                   session:nil
                                               initialText:initialText
                                                    images:images
                                                      urls:urls
                                                   handler:handler];
}

+ (BOOL)presentOSIntegratedShareDialogModallyFrom:(UIViewController *)viewController
                                          session:(FBSession *)session
                                      initialText:(NSString *)initialText
                                           images:(NSArray *)images
                                             urls:(NSArray *)urls
                                          handler:(FBOSIntegratedShareDialogHandler)handler {
    if ([FBSettings restrictedTreatment] == FBRestrictedTreatmentYES) {
        if (handler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(FBOSIntegratedShareDialogResultCancelled, [NSError errorWithDomain:FacebookSDKDomain
                                                                                      code:FBErrorOperationDisallowedForRestrictedTreament
                                                                                  userInfo:nil]);
            });
        }
        return NO;
    }
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

        [FBAppEvents logImplicitEvent:FBAppEventNameShareSheetDismiss
                           valueToSum:nil
                           parameters:@{ @"render_type" : @"Native",
                                         FBAppEventParameterDialogOutcome : (cancelled
                                                                             ? FBAppEventsDialogOutcomeValue_Cancelled
                                                                             : FBAppEventsDialogOutcomeValue_Completed) }
                              session:session];

        if (handler) {
            handler(cancelled ?  FBOSIntegratedShareDialogResultCancelled :  FBOSIntegratedShareDialogResultSucceeded, nil);
        }
    }];

    [FBAppEvents logImplicitEvent:FBAppEventNameShareSheetLaunch
                       valueToSum:nil
                       parameters:@{ @"render_type" : @"Native" }
                          session:session];
    [viewController presentViewController:composeViewController animated:YES completion:nil];

    return YES;
}

+ (BOOL)canPresentOSIntegratedShareDialogWithSession:(FBSession *)session {
    return [FBSettings restrictedTreatment] == FBRestrictedTreatmentNO && [FBDialogs composeViewControllerWithSession:session
                                                                                                              handler:nil] != nil;
}

+ (BOOL)canPresentLoginDialogWithParams:(FBLoginDialogParams *)params {
    FBAppBridgeScheme *bridgeScheme = [FBAppBridgeScheme bridgeSchemeForFBAppForLoginParams:params];

    // Ensure version support and that FBAppCall can be constructed correctly (i.e., in case of urlSchemeSuffix overrides).
    return ([FBSettings restrictedTreatment] == FBRestrictedTreatmentNO
            && bridgeScheme != nil
            && [[[FBAppCall alloc] initWithID:nil
                                enforceScheme:YES
                                        appID:params.session.appID
                              urlSchemeSuffix:params.session.urlSchemeSuffix] autorelease]);
}

// A helper method to wrap common logic for any FBAppCalls. If `FBSettings restrictedTreatment` is
// set, this method will return YES and dispatch a call to the handler with an NSError.
+ (BOOL)cancelAppCallBecauseOfRestrictedTreatment:(FBDialogAppCallCompletionHandler)handler {
    if ([FBSettings restrictedTreatment] == FBRestrictedTreatmentYES) {
        if (handler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(nil, nil, [NSError errorWithDomain:FacebookSDKDomain
                                                      code:FBErrorOperationDisallowedForRestrictedTreament
                                                  userInfo:nil]);
            });
        }
        return YES;
    }
    return NO;
}

+ (FBAppCall *)presentLoginDialogWithParams:(FBLoginDialogParams *)params
                                clientState:(NSDictionary *)clientState
                                    handler:(FBDialogAppCallCompletionHandler)handler {
    if ([FBDialogs cancelAppCallBecauseOfRestrictedTreatment:handler]) {
        return nil;
    }
    FBAppCall *call = [[[FBAppCall alloc] initWithID:nil enforceScheme:YES appID:params.session.appID urlSchemeSuffix:params.session.urlSchemeSuffix] autorelease];
    FBAppBridgeScheme *bridgeScheme = [FBAppBridgeScheme bridgeSchemeForFBAppForLoginParams:params];
    if (bridgeScheme && call) {
        FBDialogsData *dialogData = [[[FBDialogsData alloc] initWithMethod:@"auth3"
                                                                 arguments:[params dictionaryMethodArgs]]
                                     autorelease];
        dialogData.clientState = clientState;

        call.dialogData = dialogData;

        // log the timestamp for starting the switch to the Facebook application
        [FBAppEvents logImplicitEvent:FBAppEventNameFBDialogsNativeLoginDialogStart
                           valueToSum:nil
                           parameters:@{
                                        FBAppEventsNativeLoginDialogStartTime : [NSNumber numberWithDouble:round(1000 * [[NSDate date] timeIntervalSince1970])],
                                        @"action_id" : [call ID],
                                        @"app_id" : [FBSettings defaultAppID]
                                        }
                              session:nil];
        [[FBAppBridge sharedInstance] dispatchDialogAppCall:call
                                               bridgeScheme:bridgeScheme
                                                    session:params.session
                                          completionHandler:^(FBAppCall *call) {
                                              if (handler) {
                                                  handler(call, call.dialogData.results, call.error);
                                              }
                                          }];
        return call;
    }

    return nil;
}

+ (BOOL)canPresentShareDialogWithParams:(FBShareDialogParams *)params {
    FBAppBridgeScheme *bridgeScheme = [FBAppBridgeScheme bridgeSchemeForFBAppForShareDialogParams:params];
    return ([FBSettings restrictedTreatment] == FBRestrictedTreatmentNO
            && bridgeScheme != nil);
}

+ (BOOL)canPresentShareDialogWithPhotos {
    FBAppBridgeScheme *bridgeScheme = [FBAppBridgeScheme bridgeSchemeForFBAppForShareDialogPhotos];
    return ([FBSettings restrictedTreatment] == FBRestrictedTreatmentNO
            && bridgeScheme != nil);
}

+ (FBAppCall *)presentShareDialogWithParams:(FBShareDialogParams *)params
                                clientState:(NSDictionary *)clientState
                                    handler:(FBDialogAppCallCompletionHandler)handler {
    if ([FBDialogs cancelAppCallBecauseOfRestrictedTreatment:handler]) {
        return nil;
    }
    FBAppBridgeScheme *bridgeScheme = [FBAppBridgeScheme bridgeSchemeForFBAppForShareDialogParams:params];
    return [FBDialogs presentShareDialogWithParams:params
                                      bridgeScheme:bridgeScheme
                                       clientState:clientState
                                           handler:handler];
}

+ (FBAppCall *)presentShareDialogWithPhotoParams:(FBShareDialogPhotoParams *)params
                                     clientState:(NSDictionary *)clientState
                                         handler:(FBDialogAppCallCompletionHandler)handler
{
    if ([FBDialogs cancelAppCallBecauseOfRestrictedTreatment:handler]) {
        return nil;
    }
    FBAppBridgeScheme *bridgeScheme = [FBAppBridgeScheme bridgeSchemeForFBAppForShareDialogPhotos];
    return [FBDialogs presentShareDialogWithParams:params
                                      bridgeScheme:bridgeScheme
                                       clientState:clientState
                                           handler:handler];
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

+ (FBAppCall *)presentShareDialogWithPhotos:(NSArray *)photos
                                    handler:(FBDialogAppCallCompletionHandler)handler {
    return [self presentShareDialogWithPhotos:photos
                                  clientState:nil
                                      handler:handler];
}

+ (FBAppCall *)presentShareDialogWithPhotos:(NSArray *)photos
                                clientState:(NSDictionary *)clientState
                                    handler:(FBDialogAppCallCompletionHandler)handler {
    FBShareDialogPhotoParams *params = [[[FBShareDialogPhotoParams alloc] init] autorelease];
    params.photos = photos;

    return [self presentShareDialogWithPhotoParams:params
                                       clientState:clientState
                                           handler:handler];

}

+ (BOOL)canPresentShareDialogWithOpenGraphActionParams:(FBOpenGraphActionShareDialogParams *)params {
    FBAppBridgeScheme *bridgeScheme = [FBAppBridgeScheme bridgeSchemeForFBAppForOpenGraphActionShareDialogParams:params];
    return ([FBSettings restrictedTreatment] == FBRestrictedTreatmentNO
            && bridgeScheme != nil);
}

+ (FBAppCall *)presentShareDialogWithOpenGraphActionParams:(FBOpenGraphActionShareDialogParams *)params
                                               clientState:(NSDictionary *)clientState
                                                   handler:(FBDialogAppCallCompletionHandler)handler {
    if ([FBDialogs cancelAppCallBecauseOfRestrictedTreatment:handler]) {
        return nil;
    }
    FBAppBridgeScheme *bridgeScheme = [FBAppBridgeScheme bridgeSchemeForFBAppForOpenGraphActionShareDialogParams:params];
    return [FBDialogs presentShareDialogWithOpenGraphActionParams:params
                                                     bridgeScheme:bridgeScheme
                                                      clientState:clientState
                                                          handler:handler];
}

+ (FBAppCall *)presentShareDialogWithOpenGraphAction:(id<FBOpenGraphAction>)action
                                          actionType:(NSString *)actionType
                                 previewPropertyName:(NSString *)previewPropertyName
                                             handler:(FBDialogAppCallCompletionHandler)handler {
    return [FBDialogs presentShareDialogWithOpenGraphAction:action
                                                 actionType:actionType
                                        previewPropertyName:previewPropertyName
                                                clientState:nil
                                                    handler:handler];
}

+ (FBAppCall *)presentShareDialogWithOpenGraphAction:(id<FBOpenGraphAction>)action
                                          actionType:(NSString *)actionType
                                 previewPropertyName:(NSString *)previewPropertyName
                                         clientState:(NSDictionary *)clientState
                                             handler:(FBDialogAppCallCompletionHandler)handler {
    FBOpenGraphActionShareDialogParams *params = [[[FBOpenGraphActionShareDialogParams alloc] init] autorelease];

    // If we have OG objects, we want to pass just their URL or id to the share dialog.
    params.action = action;
    params.actionType = actionType;
    params.previewPropertyName = previewPropertyName;

    return [self presentShareDialogWithOpenGraphActionParams:params
                                                 clientState:clientState
                                                     handler:handler];
}

+ (FBAppCall *)presentShareDialogWithParams:(FBDialogsParams *)params
                               bridgeScheme:(FBAppBridgeScheme *)bridgeScheme
                                clientState:(NSDictionary *)clientState
                                    handler:(FBDialogAppCallCompletionHandler)handler {
    FBAppCall *call = nil;
    if (bridgeScheme) {
        NSError *validationError = [params validate];
        if (validationError) {
            if (handler) {
                handler(nil, nil, validationError);
            }
        } else {
            FBDialogsData *dialogData = [[[FBDialogsData alloc] initWithMethod:@"share"
                                                                     arguments:[params dictionaryMethodArgs]]
                                         autorelease];
            dialogData.clientState = clientState;

            call = [[[FBAppCall alloc] init] autorelease];
            call.dialogData = dialogData;

            [[FBAppBridge sharedInstance] dispatchDialogAppCall:call
                                                   bridgeScheme:bridgeScheme
                                                        session:nil
                                              completionHandler:^(FBAppCall *call) {
                                                  if (handler) {
                                                      handler(call, call.dialogData.results, call.error);
                                                  }
                                              }];
        }
    }
    [FBAppEvents logImplicitEvent:FBAppEventNameFBDialogsPresentShareDialog
                       valueToSum:nil
                       parameters:@{ FBAppEventParameterDialogOutcome : call ?
                                     FBAppEventsDialogOutcomeValue_Completed :
                                         FBAppEventsDialogOutcomeValue_Failed }
                          session:nil];

    return call;
}

+ (FBAppCall *)presentShareDialogWithOpenGraphActionParams:(FBOpenGraphActionShareDialogParams *)params
                                              bridgeScheme:(FBAppBridgeScheme *)bridgeScheme
                                               clientState:(NSDictionary *)clientState
                                                   handler:(FBDialogAppCallCompletionHandler)handler {
    FBAppCall *call = nil;

    if (bridgeScheme) {
        params.bridgeScheme = bridgeScheme;
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
                                                   bridgeScheme:bridgeScheme
                                                        session:nil
                                              completionHandler:^(FBAppCall *call) {
                                                  if (handler) {
                                                      handler(call, call.dialogData.results, call.error);
                                                  }
                                              }];
        }
    }
    [FBAppEvents logImplicitEvent:FBAppEventNameFBDialogsPresentShareDialogOG
                       valueToSum:nil
                       parameters:@{ FBAppEventParameterDialogOutcome : call ?
                                     FBAppEventsDialogOutcomeValue_Completed :
                                         FBAppEventsDialogOutcomeValue_Failed }
                          session:nil];

    return call;
}

+ (SLComposeViewController *)composeViewControllerWithSession:(FBSession *)session
                                                      handler:(FBOSIntegratedShareDialogHandler)handler {
    // Can we even call the iOS API?
    Class composeViewControllerClass = [[FBDynamicFrameworkLoader loadClass:@"SLComposeViewController" withFramework:@"Social"] class];
    if (composeViewControllerClass == nil ||
        [composeViewControllerClass isAvailableForServiceType:[FBDynamicFrameworkLoader loadStringConstant:@"SLServiceTypeFacebook" withFramework:@"Social"]] == NO) {
        if (handler) {
            handler(FBOSIntegratedShareDialogResultError, [self createError:FBErrorDialogNotSupported
                                                                    session:session]);
        }
        return nil;
    }

    SLComposeViewController *composeViewController = [composeViewControllerClass composeViewControllerForServiceType:[FBDynamicFrameworkLoader loadStringConstant:@"SLServiceTypeFacebook" withFramework:@"Social"]];
    if (composeViewController == nil) {
        if (handler) {
            handler(FBOSIntegratedShareDialogResultError, [self createError:FBErrorDialogCantBeDisplayed
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
