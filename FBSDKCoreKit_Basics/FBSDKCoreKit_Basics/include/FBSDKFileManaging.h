/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit_Basics/FBSDKLinking.h>

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_FileManaging)
@protocol FBSDKFileManaging

- (BOOL)fb_createDirectoryAtPath:(NSString *)path
     withIntermediateDirectories:(BOOL)createIntermediates
                      attributes:(NSDictionary<NSFileAttributeKey, id> *_Nullable)attributes
                           error:(NSError *_Nullable *)error;

- (BOOL)fb_fileExistsAtPath:(NSString *)path;

- (BOOL)fb_removeItemAtPath:(NSString *)path
                      error:(NSError *_Nullable *)error;

- (NSArray<NSString *> *)fb_contentsOfDirectoryAtPath:(NSString *)path
                                                error:(NSError *_Nullable *)error
__attribute__((swift_error(nonnull_error)));

@end

FB_LINK_CATEGORY_INTERFACE(NSFileManager, FileManaging)
@interface NSFileManager (FileManaging) <FBSDKFileManaging>

@end

NS_ASSUME_NONNULL_END
