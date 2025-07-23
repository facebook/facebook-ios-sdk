// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Add facebook-stories to the LSApplicationQueriesSchemes array of the app's Info.plist file.

extern NSString *const FBSDKPlatformSharingToStoriesScheme; // Facebook's custom URL scheme
extern NSString *const FBSDKPlatformSharingToReelsScheme; // Facebook's custom URL scheme for Sharing to Reels

extern NSString *const FBSDKPlatformSharingToStoriesParamAppID; // application identifier string
extern NSString *const FBSDKPlatformSharingToStoriesParamBackgroundImage; // background image data
extern NSString *const FBSDKPlatformSharingToStoriesParamBackgroundVideo; // background video data
extern NSString *const FBSDKPlatformSharingToStoriesParamStickerImage; // sticker image data
extern NSString *const FBSDKPlatformSharingToStoriesParamBackgroundTopColor; // background color hex string
extern NSString *const FBSDKPlatformSharingToStoriesParamBackgroundBottomColor; // background color hex string
extern NSString *const FBSDKPlatformSharingToStoriesParamContentURL; // attribution URL string

extern NSString *const FBSDKPlatformSharingToStoriesParamProxiedAppID; // proxied application identifier string
extern NSString *const FBSDKPlatformSharingToStoriesParamBackgroundVideoURL; // background video file URL string
extern NSString *const FBSDKPlatformSharingToStoriesParamMethod; // values: camera, share

extern NSString *const FBSDKPlatformSharingToStoriesParamSource;
extern NSString *const FBSDKPlatformSharingToStoriesParamWhatsAppMedia;
extern NSString *const FBSDKPlatformSharingToStoriesParamWhatsAppStoryImage;
extern NSString *const FBSDKPlatformSharingToStoriesParamWhatsAppStoryVideo;
extern NSString *const FBSDKPlatformSharingToStoriesParamWhatsAppStoryCaption;

BOOL FBSDKPlatformSharingToStoriesCanOpen(void);

BOOL FBSDKPlatformSharingToReels(NSString *_Nullable appID,
                                 NSData *_Nullable backgroundVideo,
                                 NSString *_Nullable contentURL,
                                 NSData *_Nullable stickerImage);

BOOL FBSDKPlatformSharingToStoriesCamera(NSString *_Nullable appID,
                                         NSString *_Nullable proxiedAppID,
                                         NSData *_Nullable backgroundImage,
                                         NSData *_Nullable backgroundVideo,
                                         NSData *_Nullable stickerImage,
                                         NSString *_Nullable backgroundTopColor,
                                         NSString *_Nullable backgroundBottomColor,
                                         NSString *_Nullable contentURL,
                                         NSString *_Nullable entityURI);

BOOL FBSDKPlatformSharingToStoriesComposer(NSString *_Nullable appID,
                                           NSString *_Nullable proxiedAppID,
                                           NSData *_Nullable backgroundImage,
                                           NSData *_Nullable backgroundVideo,
                                           NSString *_Nullable backgroundVideoURL); // file must be in shared app group folder

BOOL FBSDKPlatformSharingToStoriesWhatsAppShare(NSString *_Nullable appID,
                                                NSArray<NSDictionary<NSString *, id> *> *_Nullable mediaList);

BOOL FBSDKPlatformSharingPasteboard(NSArray<NSDictionary<NSString *, id> *> *pasteboardItems, NSString *urlScheme);

NS_ASSUME_NONNULL_END
