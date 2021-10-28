/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@protocol FBSDKObjectDecoding <NSObject>

- (nullable id)decodeObjectOfClass:(Class)aClass
                            forKey:(NSString *)key;
- (nullable id)decodeObjectOfClasses:(NSSet<Class> *)classes
                              forKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
