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

extern NSString *const FBSDKShareExtensionParamAppID; // application identifier string
extern NSString *const FBSDKShareExtensionParamHashtags; // array of hashtag strings (max 1)
extern NSString *const FBSDKShareExtensionParamQuotes; // array of quote strings (max 1)
extern NSString *const FBSDKShareExtensionParamOGData; // dictionary of Open Graph data

NSString *_Nullable FBSDKShareExtensionInitialText(NSString *_Nullable appID,
                                                   NSString *_Nullable hashtag,
                                                   NSString *_Nullable jsonString);

NS_ASSUME_NONNULL_END

#endif
