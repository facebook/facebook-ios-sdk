// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Shameless fork of internal ShareKit function FBSDKShareExtensionInitialText
NSString *_Nullable HackbookShareExtensionInitialText(NSString *_Nullable appID,
                                                      NSString *_Nullable hashtag,
                                                      NSString *_Nullable jsonString);

NSString *_Nullable FBSDKPlatformShareExtensionInitialText(NSString *_Nullable appID,
                                                           NSString *_Nullable hashtag,
                                                           NSString *_Nullable quote);

NS_ASSUME_NONNULL_END
