/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <TargetConditionals.h>

#if !TARGET_OS_TV

 #import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_AEMRequestBody)
@interface FBAEMRequestBody : NSObject

@property (nonatomic, readonly, retain) NSData *data;

- (void)appendWithKey:(NSString *)key
            formValue:(NSString *)value;

- (nullable NSData *)compressedData;

 #if DEBUG
@property (nonatomic, readonly, retain) NSData *multipartData;
 #endif

@end

NS_ASSUME_NONNULL_END

#endif
