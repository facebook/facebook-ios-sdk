/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(LibAnalyzer)
@interface FBSDKLibAnalyzer : NSObject

+ (NSDictionary<NSString *, NSString *> *)getMethodsTable:(NSArray<NSString *> *)prefixes
                                               frameworks:(NSArray<NSString *> *_Nullable)frameworks;
+ (nullable NSArray<NSString *> *)symbolicateCallstack:(NSArray<NSString *> *)callstack
                                         methodMapping:(NSDictionary<NSString *, id> *)methodMapping;

@end

NS_ASSUME_NONNULL_END
