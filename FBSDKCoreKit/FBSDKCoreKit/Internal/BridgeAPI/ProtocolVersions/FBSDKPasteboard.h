/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Pasteboard)
@protocol FBSDKPasteboard

@property (nonatomic, readonly) NSString *name;

@property (nonatomic, readonly) BOOL _isGeneralPasteboard;

- (nullable NSData *)dataForPasteboardType:(NSString *)pasteboardType;
- (void)setData:(NSData *)data forPasteboardType:(NSString *)pasteboardType;

@end

NS_ASSUME_NONNULL_END

#endif
