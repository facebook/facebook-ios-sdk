/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <UIKit/UIKit.h>

#import <FBSDKCoreKit/FBSDKAppLinkResolverRequestBuilder.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKGraphRequest+Internal.h"

static NSString *const kIOSKey = @"ios";
static NSString *const kIPhoneKey = @"iphone";
static NSString *const kIPadKey = @"ipad";
static NSString *const kAppLinksKey = @"app_links";

@interface FBSDKAppLinkResolverRequestBuilder ()
@property (nonatomic, assign) UIUserInterfaceIdiom userInterfaceIdiom;
@end

// `FBSDKAppLinkResolverRequestBuilder` is marked as deprecated for the next
// major release; we should make it internal when moving to Swift and retire the
// prefixed name.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
@implementation FBSDKAppLinkResolverRequestBuilder
#pragma clang diagnostic pop

- (instancetype)initWithUserInterfaceIdiom:(UIUserInterfaceIdiom)userInterfaceIdiom
{
  if ((self = [super init])) {
    self.userInterfaceIdiom = userInterfaceIdiom;
  }
  return self;
}

- (instancetype)init
{
  if ((self = [super init])) {
    _userInterfaceIdiom = UIDevice.currentDevice.userInterfaceIdiom;
  }

  return self;
}

- (FBSDKGraphRequest *)requestForURLs:(NSArray<NSURL *> *)urls
{
  NSArray<NSString *> *fields = [self getUISpecificFields];
  NSArray<NSString *> *encodedURLs = [self getEncodedURLs:urls];

  NSString *path =
  [NSString stringWithFormat:@"?fields=%@.fields(%@)&ids=%@",
   kAppLinksKey,
   [fields componentsJoinedByString:@","],
   [encodedURLs componentsJoinedByString:@","]];
  return [[FBSDKGraphRequest alloc]
          initWithGraphPath:path
          parameters:nil
          flags:FBSDKGraphRequestFlagDoNotInvalidateTokenOnError
          | FBSDKGraphRequestFlagDisableErrorRecovery];
}

- (NSString *_Nullable)getIdiomSpecificField
{
  NSString *idiomSpecificField = nil;

  switch (self.userInterfaceIdiom) {
    case UIUserInterfaceIdiomPad:
      idiomSpecificField = kIPadKey;
      break;
    case UIUserInterfaceIdiomPhone:
      idiomSpecificField = kIPhoneKey;
      break;
    default:
      break;
  }

  return idiomSpecificField;
}

- (NSArray<NSString *> *)getUISpecificFields
{
  NSMutableArray<NSString *> *fields = [@[kIOSKey] mutableCopy];
  NSString *idiomSpecificField = [self getIdiomSpecificField];

  if (idiomSpecificField) {
    [FBSDKTypeUtility array:fields addObject:idiomSpecificField];
  }

  return fields;
}

- (NSArray<NSString *> *)getEncodedURLs:(NSArray<NSURL *> *)urls
{
  NSMutableArray<NSString *> *encodedURLs = [NSMutableArray array];

  for (NSURL *url in urls) {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSString *encodedURL = [url.absoluteString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    #pragma clang diagnostic pop
    if (encodedURL) {
      [FBSDKTypeUtility array:encodedURLs addObject:encodedURL];
    }
  }

  return encodedURLs;
}

@end

#endif
