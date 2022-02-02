/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// An internal protocol used to describe a file manager
NS_SWIFT_NAME(FileManaging)
@protocol FBSDKFileManaging

- (nullable NSURL *)URLForDirectory:(NSSearchPathDirectory)directory
                           inDomain:(NSSearchPathDomainMask)domain
                  appropriateForURL:(NSURL *)url
                             create:(BOOL)shouldCreate
                              error:(NSError *_Nullable *)error;

- (BOOL)createDirectoryAtPath:(NSString *)path
  withIntermediateDirectories:(BOOL)createIntermediates
                   attributes:(NSDictionary<NSFileAttributeKey, id> *_Nullable)attributes
                        error:(NSError *_Nullable *)error;

- (BOOL)fileExistsAtPath:(NSString *)path;

- (BOOL)removeItemAtPath:(NSString *)path
                   error:(NSError *_Nullable *)error;

- (NSArray<NSString *> *)contentsOfDirectoryAtPath:(NSString *)path
                                             error:(NSError *_Nullable *)error;

@end

@interface NSFileManager (FBSDKFileManaging) <FBSDKFileManaging>
@end

NS_ASSUME_NONNULL_END
