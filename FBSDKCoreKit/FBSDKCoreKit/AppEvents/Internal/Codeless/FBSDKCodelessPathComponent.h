/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(int, FBSDKCodelessMatchBitmaskField)
{
  FBSDKCodelessMatchBitmaskFieldID = 1,
  FBSDKCodelessMatchBitmaskFieldText = 1 << 1,
  FBSDKCodelessMatchBitmaskFieldTag = 1 << 2,
  FBSDKCodelessMatchBitmaskFieldDescription = 1 << 3,
  FBSDKCodelessMatchBitmaskFieldHint = 1 << 4
};

NS_SWIFT_NAME(CodelessPathComponent)
@interface FBSDKCodelessPathComponent : NSObject

@property (nonatomic, copy, readonly) NSString *className;
@property (nonatomic, copy, readonly) NSString *text;
@property (nonatomic, copy, readonly) NSString *hint;
@property (nonatomic, copy, readonly) NSString *desc; // description
@property (nonatomic, readonly) int index;
@property (nonatomic, readonly) int tag;
@property (nonatomic, readonly) int section;
@property (nonatomic, readonly) int row;
@property (nonatomic, readonly) int matchBitmask;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithJSON:(NSDictionary<NSString *, id> *)dict;
- (BOOL)isEqualToPath:(FBSDKCodelessPathComponent *)path;

@end

NS_ASSUME_NONNULL_END

#endif
