/*
 * Copyright 2012 Facebook
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

#import "FBNativeDialogs.h"
#import "FBSession.h"
#import "FBError.h"
#import "FBUtility.h"
#import "FBAccessTokenData.h"
#import "FBInsights+Internal.h"

@interface FBNativeDialogs ()

+ (NSError*)createError:(NSString*)reason
                session:(FBSession *)session;

@end

@implementation FBNativeDialogs

+ (BOOL)presentShareDialogModallyFrom:(UIViewController*)viewController
                          initialText:(NSString*)initialText
                                image:(UIImage*)image
                                  url:(NSURL*)url
                              handler:(FBShareDialogHandler)handler {
    NSArray *images = image ? [NSArray arrayWithObject:image] : nil;
    NSArray *urls = url ? [NSArray arrayWithObject:url] : nil;
    
    return [self presentShareDialogModallyFrom:viewController
                                       session:nil
                                   initialText:initialText
                                        images:images
                                          urls:urls
                                       handler:handler];
}

+ (BOOL)presentShareDialogModallyFrom:(UIViewController*)viewController
                          initialText:(NSString*)initialText
                               images:(NSArray*)images
                                 urls:(NSArray*)urls
                              handler:(FBShareDialogHandler)handler {
    
    return [self presentShareDialogModallyFrom:viewController
                                       session:nil
                                   initialText:initialText
                                        images:images
                                          urls:urls
                                       handler:handler];
}

+ (BOOL)presentShareDialogModallyFrom:(UIViewController*)viewController
                              session:(FBSession*)session
                          initialText:(NSString*)initialText
                               images:(NSArray*)images
                                 urls:(NSArray*)urls
                              handler:(FBShareDialogHandler)handler {
    
    SLComposeViewController *composeViewController = [FBNativeDialogs composeViewControllerWithSession:session
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
            handler(cancelled ? FBNativeDialogResultCancelled : FBNativeDialogResultSucceeded, nil);
        }
    }];
    
    [FBInsights logImplicitEvent:FBInsightsEventNameShareSheetLaunch
                      valueToSum:1.0
                      parameters:@{ @"render_type" : @"Native" }
                         session:session];
    [viewController presentModalViewController:composeViewController animated:YES];
        
    return YES;
}

+ (BOOL)canPresentShareDialogWithSession:(FBSession*)session {
    return [FBNativeDialogs composeViewControllerWithSession:session
                                                     handler:nil] != nil;
}

+ (SLComposeViewController*)composeViewControllerWithSession:(FBSession*)session
                                                     handler:(FBShareDialogHandler)handler  {
    // Can we even call the iOS API?
    Class composeViewControllerClass = [SLComposeViewController class];
    if (composeViewControllerClass == nil ||
        [composeViewControllerClass isAvailableForServiceType:SLServiceTypeFacebook] == NO) {
        if (handler) {
            handler(FBNativeDialogResultError, [self createError:FBErrorNativeDialogNotSupported
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
                handler(FBNativeDialogResultError, [self createError:FBErrorNativeDialogInvalidForSession
                                                             session:session]);
            }
            return nil;
        }
    }
    
    SLComposeViewController *composeViewController = [composeViewControllerClass composeViewControllerForServiceType:SLServiceTypeFacebook];
    if (composeViewController == nil) {
        if (handler) {
            handler(FBNativeDialogResultError, [self createError:FBErrorNativeDialogCantBeDisplayed
                                                         session:session]);
        }
        return nil;
    }
    return composeViewController;
}

+ (NSError *)createError:(NSString *)reason
                 session:(FBSession *)session {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[FBErrorNativeDialogReasonKey] = reason;
    if (session) {
        userInfo[FBErrorSessionKey] = session;
    }
    NSError *error = [NSError errorWithDomain:FacebookSDKDomain
                                         code:FBErrorNativeDialog
                                     userInfo:userInfo];
    return error;
}

@end
