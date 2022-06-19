// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Add instagram-stories to the LSApplicationQueriesSchemes array of the app's Info.plist file.

extern NSString *const IGSDKPlatformSharingToStoriesScheme; // Instagram's custom URL scheme

extern NSString *const IGSDKPlatformSharingToStoriesParamBackgroundImage; // background image data
extern NSString *const IGSDKPlatformSharingToStoriesParamBackgroundVideo; // background video data
extern NSString *const IGSDKPlatformSharingToStoriesParamStickerImage; // sticker image data
extern NSString *const IGSDKPlatformSharingToStoriesParamBackgroundTopColor; // background color hex string
extern NSString *const IGSDKPlatformSharingToStoriesParamBackgroundBottomColor; // background color hex string
extern NSString *const IGSDKPlatformSharingToStoriesParamContentURL; // attribution URL string

BOOL IGSDKPlatformSharingToStories(NSData *_Nullable backgroundImage,
                                   NSData *_Nullable backgroundVideo,
                                   NSData *_Nullable stickerImage,
                                   NSString *_Nullable backgroundTopColor,
                                   NSString *_Nullable backgroundBottomColor,
                                   NSString *_Nullable contentURL);

BOOL IGSDKPlatformSharingToStoriesCanOpen(void);

BOOL IGSDKPlatformSharingToStoriesPasteboard(NSArray<NSDictionary<NSString *, id> *> *pasteboardItems);

NS_ASSUME_NONNULL_END
