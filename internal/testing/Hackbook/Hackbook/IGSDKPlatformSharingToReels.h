// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Add instagram-reels to the LSApplicationQueriesSchemes array of the app's Info.plist file.

extern NSString *const IGSDKPlatformSharingToReelsScheme; // Instagram's custom URL scheme
extern NSString *const IGSDKPlatformSharingToReelsParamBackgroundVideo; // background video data
extern NSString *const IGSDKPlatformSharingToReelsParamStickerImage; // sticker image data


BOOL IGSDKPlatformSharingToReels(NSData *_Nullable backgroundVideo,
                                   NSData *_Nullable stickerImage)
NS_SWIFT_NAME(shareToReels(backgroundVideo:stickerImage:));

BOOL IGSDKPlatformSharingToReelsCanOpen(void);

BOOL IGSDKPlatformSharingToReelsPasteboard(NSArray<NSDictionary<NSString *, id> *> *pasteboardItems);

NS_ASSUME_NONNULL_END
