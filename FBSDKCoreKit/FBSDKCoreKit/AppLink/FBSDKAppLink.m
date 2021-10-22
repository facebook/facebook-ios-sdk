/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKAppLink+Internal.h"

NSString *const FBSDKAppLinkDataParameterName = @"al_applink_data";
NSString *const FBSDKAppLinkTargetKeyName = @"target_url";
NSString *const FBSDKAppLinkUserAgentKeyName = @"user_agent";
NSString *const FBSDKAppLinkExtrasKeyName = @"extras";
NSString *const FBSDKAppLinkRefererAppLink = @"referer_app_link";
NSString *const FBSDKAppLinkRefererAppName = @"app_name";
NSString *const FBSDKAppLinkRefererUrl = @"url";
NSString *const FBSDKAppLinkVersionKeyName = @"version";
NSString *const FBSDKAppLinkVersion = @"1.0";

@interface FBSDKAppLink ()

@property (nullable, nonatomic, readwrite, strong) NSURL *sourceURL;
@property (nonatomic, copy) NSArray<id<FBSDKAppLinkTarget>> *targets;
@property (nullable, nonatomic, readwrite, strong) NSURL *webURL;

@property (nonatomic, getter = isBackToReferrer, assign) BOOL backToReferrer;

@end

@implementation FBSDKAppLink

+ (instancetype)appLinkWithSourceURL:(nullable NSURL *)sourceURL
                             targets:(NSArray<id<FBSDKAppLinkTarget>> *)targets
                              webURL:(nullable NSURL *)webURL
                    isBackToReferrer:(BOOL)isBackToReferrer
{
  FBSDKAppLink *link = [self new];
  link.backToReferrer = isBackToReferrer;
  link.sourceURL = sourceURL;
  link.targets = [targets copy];
  link.webURL = webURL;
  return link;
}

+ (instancetype)appLinkWithSourceURL:(nullable NSURL *)sourceURL
                             targets:(NSArray<id<FBSDKAppLinkTarget>> *)targets
                              webURL:(nullable NSURL *)webURL
{
  return [self appLinkWithSourceURL:sourceURL
                            targets:targets
                             webURL:webURL
                   isBackToReferrer:NO];
}

@end

#endif
