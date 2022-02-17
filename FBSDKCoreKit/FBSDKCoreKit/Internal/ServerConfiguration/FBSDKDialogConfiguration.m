/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKDialogConfiguration.h"

#define FBSDK_DIALOG_CONFIGURATION_APP_VERSIONS_KEY @"appVersions"
#define FBSDK_DIALOG_CONFIGURATION_NAME_KEY @"name"
#define FBSDK_DIALOG_CONFIGURATION_URL_KEY @"url"

@implementation FBSDKDialogConfiguration

#pragma mark - Object Lifecycle

- (instancetype)initWithName:(NSString *)name URL:(NSURL *)URL appVersions:(NSArray<id> *)appVersions
{
  if ((self = [super init])) {
    _name = [name copy];
    _URL = [URL copy];
    _appVersions = [appVersions copy];
  }
  return self;
}

#pragma mark NSCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  NSString *name = [decoder decodeObjectOfClass:NSString.class forKey:FBSDK_DIALOG_CONFIGURATION_NAME_KEY];
  NSURL *URL = [decoder decodeObjectOfClass:NSURL.class forKey:FBSDK_DIALOG_CONFIGURATION_URL_KEY];
  NSSet<Class> *appVersionsClasses = [NSSet setWithObjects:NSArray.class, NSNumber.class, nil];
  NSArray<NSString *> *appVersions = [decoder decodeObjectOfClasses:appVersionsClasses
                                                             forKey:FBSDK_DIALOG_CONFIGURATION_APP_VERSIONS_KEY];
  return [self initWithName:name URL:URL appVersions:appVersions];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:_appVersions forKey:FBSDK_DIALOG_CONFIGURATION_APP_VERSIONS_KEY];
  [encoder encodeObject:_name forKey:FBSDK_DIALOG_CONFIGURATION_NAME_KEY];
  [encoder encodeObject:_URL forKey:FBSDK_DIALOG_CONFIGURATION_URL_KEY];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  return self;
}

@end
