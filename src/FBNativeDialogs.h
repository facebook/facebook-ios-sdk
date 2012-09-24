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

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@class FBSession;

typedef enum {
    FBNativeDialogResultSucceeded,
    FBNativeDialogResultCancelled,
    FBNativeDialogResultError
} FBNativeDialogResult;

typedef void (^FBShareDialogHandler)(FBNativeDialogResult result, NSError *error);

@interface FBNativeDialogs : NSObject

+ (BOOL)presentShareDialogModallyFrom:(UIViewController*)viewController
                          initialText:(NSString*)initialText
                                image:(UIImage*)image
                                  url:(NSURL*)url
                              handler:(FBShareDialogHandler)handler;

+ (BOOL)presentShareDialogModallyFrom:(UIViewController*)viewController
                          initialText:(NSString*)initialText
                               images:(NSArray*)images
                                 urls:(NSArray*)urls
                              handler:(FBShareDialogHandler)handler;

+ (BOOL)presentShareDialogModallyFrom:(UIViewController*)viewController
                              session:(FBSession*)session
                          initialText:(NSString*)initialText
                               images:(NSArray*)images
                                 urls:(NSArray*)urls
                              handler:(FBShareDialogHandler)handler;

@end
