/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKAppLinkNavigation+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKAppLinkNavigation (Testing)

@property (nonnull, nonatomic) id<FBSDKSettings> settings;

+ (void)reset;

- (nullable NSURL *)appLinkURLWithTargetURL:(NSURL *)targetUrl error:(NSError **)error;
- (void)postAppLinkNavigateEventNotificationWithTargetURL:(nullable NSURL *)outputURL
                                                    error:(nullable NSError *)error
                                                     type:(FBSDKAppLinkNavigationType)type
                                              eventPoster:(id<FBSDKAppLinkEventPosting>)eventPoster;
- (FBSDKAppLinkNavigationType)navigationTypeForTargets:(NSArray<FBSDKAppLinkTarget *> *)targets
                                             urlOpener:(id<FBSDKInternalURLOpener>)urlOpener;

// UNCRUSTIFY_FORMAT_OFF
- (FBSDKAppLinkNavigationType)navigateWithUrlOpener:(id<FBSDKInternalURLOpener>)urlOpener
                                        eventPoster:(id<FBSDKAppLinkEventPosting>)eventPoster
                                              error:(NSError **)error
NS_SWIFT_NAME(navigate(urlOpener:eventPoster:error:));
// UNCRUSTIFY_FORMAT_ON

@end

NS_ASSUME_NONNULL_END
