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

typedef void (^FBSDKCodelessSettingLoadBlock)(BOOL isCodelessSetupEnabled, NSError *_Nullable error);

NS_SWIFT_NAME(CodelessIndexer)
@interface FBSDKCodelessIndexer : NSObject

@property (class, nonatomic, readonly, copy) NSString *extInfo;

+ (void)enable;

@end

NS_ASSUME_NONNULL_END

#endif
