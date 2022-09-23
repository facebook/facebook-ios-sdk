/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal protocol exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_Pasteboard)
@protocol FBSDKPasteboard

@property (nonatomic, readonly) NSString *name;

@property (nonatomic, readonly) BOOL _isGeneralPasteboard;

- (nullable NSData *)dataForPasteboardType:(NSString *)pasteboardType;
- (void)setData:(NSData *)data forPasteboardType:(NSString *)pasteboardType;

@end

NS_ASSUME_NONNULL_END

#endif
