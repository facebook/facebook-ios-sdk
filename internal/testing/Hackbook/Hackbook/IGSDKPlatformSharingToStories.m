// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "IGSDKPlatformSharingToStories.h"

#import <UIKit/UIKit.h>

NSString *const IGSDKPlatformSharingToStoriesScheme = @"instagram-stories://share";

NSString *const IGSDKPlatformSharingToStoriesParamBackgroundImage = @"com.instagram.sharedSticker.backgroundImage";
NSString *const IGSDKPlatformSharingToStoriesParamBackgroundVideo = @"com.instagram.sharedSticker.backgroundVideo";
NSString *const IGSDKPlatformSharingToStoriesParamStickerImage = @"com.instagram.sharedSticker.stickerImage";
NSString *const IGSDKPlatformSharingToStoriesParamBackgroundTopColor = @"com.instagram.sharedSticker.backgroundTopColor";
NSString *const IGSDKPlatformSharingToStoriesParamBackgroundBottomColor = @"com.instagram.sharedSticker.backgroundBottomColor";
NSString *const IGSDKPlatformSharingToStoriesParamContentURL = @"com.instagram.sharedSticker.contentURL";

BOOL IGSDKPlatformSharingToStories(NSData *_Nullable backgroundImage,
                                   NSData *_Nullable backgroundVideo,
                                   NSData *_Nullable stickerImage,
                                   NSString *_Nullable backgroundTopColor,
                                   NSString *_Nullable backgroundBottomColor,
                                   NSString *_Nullable contentURL)
{
  NSMutableArray<NSDictionary<NSString *, id> *> *const pasteboardItems = [NSMutableArray new];
  if (backgroundImage) {
    [pasteboardItems addObject:@{IGSDKPlatformSharingToStoriesParamBackgroundImage : backgroundImage}];
  }
  if (backgroundVideo) {
    [pasteboardItems addObject:@{IGSDKPlatformSharingToStoriesParamBackgroundVideo : backgroundVideo}];
  }
  if (stickerImage) {
    [pasteboardItems addObject:@{IGSDKPlatformSharingToStoriesParamStickerImage : stickerImage}];
  }
  if (backgroundTopColor.length > 0) {
    [pasteboardItems addObject:@{IGSDKPlatformSharingToStoriesParamBackgroundTopColor : backgroundTopColor}];
  }
  if (backgroundBottomColor.length > 0) {
    [pasteboardItems addObject:@{IGSDKPlatformSharingToStoriesParamBackgroundBottomColor : backgroundBottomColor}];
  }
  if (contentURL.length > 0) {
    [pasteboardItems addObject:@{IGSDKPlatformSharingToStoriesParamContentURL : contentURL}];
  }
  return IGSDKPlatformSharingToStoriesPasteboard(pasteboardItems);
}

BOOL IGSDKPlatformSharingToStoriesCanOpen(void)
{
  return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:IGSDKPlatformSharingToStoriesScheme]];
}

BOOL IGSDKPlatformSharingToStoriesPasteboard(NSArray<NSDictionary<NSString *, id> *> *pasteboardItems)
{
  if (pasteboardItems.count == 0) {
    return NO;
  }

  NSURL *const URL = [NSURL URLWithString:IGSDKPlatformSharingToStoriesScheme];
  if (![[UIApplication sharedApplication] canOpenURL:URL]) {
    return NO;
  }

  [[UIPasteboard generalPasteboard] addItems:pasteboardItems]; // iOS 10+ setItems:options:
  return [[UIApplication sharedApplication] openURL:URL]; // iOS 10+ openURL:options:completionHandler:
}
