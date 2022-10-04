/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@protocol FBSDKObjectDecoding <NSObject>

- (nullable id)decodeObjectOfClass:(Class)aClass
                            forKey:(NSString *)key;
- (nullable id)decodeObjectOfClasses:(NSSet<Class> *)classes
                              forKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
