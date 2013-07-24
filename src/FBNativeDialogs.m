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
#import "FBAppEvents+Internal.h"
#import "FBDialogsParams+Internal.h"
#import "FBLoginDialogParams.h"
#import "FBShareDialogParams.h"
#import "FBOpenGraphActionShareDialogParams.h"
#import "FBDialogsData+Internal.h"
#import "FBAppLinkData+Internal.h"
#import "FBAccessTokenData+Internal.h"
#import "FBNativeDialogs.h"

@implementation FBNativeDialogs

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
+ (FBOSIntegratedShareDialogHandler)handlerFromHandler:(FBShareDialogHandler)handler {
    if (handler) {
        FBOSIntegratedShareDialogHandler fancy = ^(FBOSIntegratedShareDialogResult result, NSError *error) {
            handler(result, error);
        };
        return [[fancy copy] autorelease];
    }
    return nil;
}
#pragma GCC diagnostic pop

+ (BOOL)presentShareDialogModallyFrom:(UIViewController*)viewController
                          initialText:(NSString*)initialText
                                image:(UIImage*)image
                                  url:(NSURL*)url
                              handler:(FBShareDialogHandler)handler {
    return [FBDialogs presentOSIntegratedShareDialogModallyFrom:viewController
                                                    initialText:initialText
                                                          image:image
                                                            url:url
                                                        handler:[FBNativeDialogs handlerFromHandler:handler]];
}

+ (BOOL)presentShareDialogModallyFrom:(UIViewController*)viewController
                          initialText:(NSString*)initialText
                               images:(NSArray*)images
                                 urls:(NSArray*)urls
                              handler:(FBShareDialogHandler)handler {
    return [FBDialogs presentOSIntegratedShareDialogModallyFrom:viewController
                                                    initialText:initialText
                                                         images:images
                                                           urls:urls
                                                        handler:[FBNativeDialogs handlerFromHandler:handler]];
}

+ (BOOL)presentShareDialogModallyFrom:(UIViewController*)viewController
                              session:(FBSession*)session
                          initialText:(NSString*)initialText
                               images:(NSArray*)images
                                 urls:(NSArray*)urls
                              handler:(FBShareDialogHandler)handler {
    return [FBDialogs presentOSIntegratedShareDialogModallyFrom:viewController
                                                        session:session
                                                    initialText:initialText
                                                         images:images
                                                           urls:urls
                                                        handler:[FBNativeDialogs handlerFromHandler:handler]];
}

+ (BOOL)canPresentShareDialogWithSession:(FBSession*)session {
    return [FBDialogs canPresentOSIntegratedShareDialogWithSession:session];
}

@end
