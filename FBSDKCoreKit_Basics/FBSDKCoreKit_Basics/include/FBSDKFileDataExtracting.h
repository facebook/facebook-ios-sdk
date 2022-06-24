/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit_Basics/FBSDKLinking.h>

NS_ASSUME_NONNULL_BEGIN

/// An internal protocol used to describe a type that can extract data from a file
NS_SWIFT_NAME(FileDataExtracting)
@protocol FBSDKFileDataExtracting

+ (nullable NSData *)fb_dataWithContentsOfFile:(NSString *)path
                                       options:(NSDataReadingOptions)readOptionsMask
                                         error:(NSError *_Nullable *)error;

@end

FB_LINK_CATEGORY_INTERFACE(NSData, FileDataExtracting)
@interface NSData (FileDataExtracting) <FBSDKFileDataExtracting>

@end

NS_ASSUME_NONNULL_END
