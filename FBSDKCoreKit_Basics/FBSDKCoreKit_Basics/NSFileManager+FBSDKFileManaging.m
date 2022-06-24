/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit_Basics/FBSDKFileManaging.h>
#import <FBSDKCoreKit_Basics/FBSDKLinking.h>

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FB_LINK_CATEGORY_IMPLEMENTATION(NSFileManager, FileManaging)
@implementation NSFileManager (FileManaging)

- (BOOL)fb_createDirectoryAtPath:(NSString *)path
     withIntermediateDirectories:(BOOL)createIntermediates
                      attributes:(nullable NSDictionary<NSFileAttributeKey,id> *)attributes
                           error:(NSError * _Nullable __autoreleasing *)error
{
  return [self createDirectoryAtPath:path
         withIntermediateDirectories:createIntermediates
                          attributes:attributes
                               error:error];
}

- (BOOL)fb_fileExistsAtPath:(NSString *)path
{
  return [self fileExistsAtPath:path];
}

- (BOOL)fb_removeItemAtPath:(NSString *)path
                      error:(NSError * _Nullable __autoreleasing *)error
{
  return [self removeItemAtPath:path error:error];
}

- (NSArray<NSString *> *)fb_contentsOfDirectoryAtPath:(NSString *)path
                                                error:(NSError * _Nullable __autoreleasing *)error
{
  return [self contentsOfDirectoryAtPath:path error:error];
}

@end

NS_ASSUME_NONNULL_END
