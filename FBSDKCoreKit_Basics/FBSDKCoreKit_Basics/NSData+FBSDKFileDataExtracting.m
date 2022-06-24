/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit_Basics/FBSDKFileDataExtracting.h>
#import <FBSDKCoreKit_Basics/FBSDKLinking.h>

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FB_LINK_CATEGORY_IMPLEMENTATION(NSData, FileDataExtracting)
@implementation NSData (FileDataExtracting)

+ (nullable NSData *)fb_dataWithContentsOfFile:(NSString *)path
                              options:(NSDataReadingOptions)readOptionsMask
                                error:(NSError * _Nullable __autoreleasing *)error
{
  return [self dataWithContentsOfFile:path
                              options:readOptionsMask
                                error:error];
}

@end

NS_ASSUME_NONNULL_END
