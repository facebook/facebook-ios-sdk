// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "IGSDKPlatformSharingToReels.h"

#import <UIKit/UIKit.h>

NSString *const IGSDKPlatformSharingToReelsScheme = @"instagram-reels://share";

NSString *const IGSDKPlatformSharingToReelsParamAppID = @"com.instagram.sharedSticker.appID";
NSString *const IGSDKPlatformSharingToReelsParamBackgroundVideo = @"com.instagram.sharedSticker.backgroundVideo";
NSString *const IGSDKPlatformSharingToReelsParamStickerImage = @"com.instagram.sharedSticker.stickerImage";
NSString *const IGSDKPlatformSharingToReelsParamContentURL = @"com.instagram.sharedSticker.contentURL";

BOOL IGSDKPlatformSharingToReels(NSString *_Nullable appID,
                                 NSData *_Nullable backgroundVideo,
                                 NSData *_Nullable stickerImage,
                                 NSString *_Nullable contentURL)
{
  NSMutableArray<NSDictionary<NSString *, id> *> *const pasteboardItems = [NSMutableArray new];
  if (appID) {
    [pasteboardItems addObject:@{IGSDKPlatformSharingToReelsParamAppID : appID}];
  }
  if (backgroundVideo) {
    [pasteboardItems addObject:@{IGSDKPlatformSharingToReelsParamBackgroundVideo : backgroundVideo}];
  }
  if (stickerImage) {
    [pasteboardItems addObject:@{IGSDKPlatformSharingToReelsParamStickerImage : stickerImage}];
  }
  if (contentURL) {
    [pasteboardItems addObject:@{IGSDKPlatformSharingToReelsParamContentURL : contentURL}];
  }
  return IGSDKPlatformSharingToReelsPasteboard(pasteboardItems);
}

BOOL IGSDKPlatformSharingToReelsCanOpen(void)
{
  return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:IGSDKPlatformSharingToReelsScheme]];
}

BOOL IGSDKPlatformSharingToReelsPasteboard(NSArray<NSDictionary<NSString *, id> *> *pasteboardItems)
{
  if (pasteboardItems.count == 0) {
    return NO;
  }

  NSURL *const URL = [NSURL URLWithString:IGSDKPlatformSharingToReelsScheme];
  if (![[UIApplication sharedApplication] canOpenURL:URL]) {
    return NO;
  }

  [[UIPasteboard generalPasteboard] setItems:pasteboardItems];
  [[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:nil];
  return YES;
}
