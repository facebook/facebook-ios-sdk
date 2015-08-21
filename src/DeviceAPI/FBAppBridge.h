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

#import <Foundation/Foundation.h>

#import "FBAppCall.h"

@class FBAppBridgeScheme;

@interface FBAppBridge : NSObject

+ (instancetype)sharedInstance;

- (void)dispatchDialogAppCall:(FBAppCall *)appCall
                 bridgeScheme:(FBAppBridgeScheme *)bridgeScheme
                      session:(FBSession *)session
      useSafariViewController:(BOOL)useSafariViewController
            completionHandler:(FBAppCallHandler)handler;

- (BOOL)handleOpenURL:(NSURL *)url
    sourceApplication:(NSString *)sourceApplication
              session:(FBSession *)session
      fallbackHandler:(FBAppCallHandler)fallbackHandler;

- (void)handleDidBecomeActive;

- (void)trackAppCall:(FBAppCall *)call withCompletionHandler:(FBAppCallHandler)handler;

@end
