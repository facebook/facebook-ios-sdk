// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "FBSDKPlatformSharingToStories.h"

#import <UIKit/UIKit.h>

NSString *const FBSDKPlatformSharingToStoriesScheme = @"facebook-stories://share";
NSString *const FBSDKPlatformSharingToReelsScheme = @"facebook-reels://share";

NSString *const FBSDKPlatformSharingToStoriesParamAppID = @"com.facebook.sharedSticker.appID";
NSString *const FBSDKPlatformSharingToStoriesParamBackgroundImage = @"com.facebook.sharedSticker.backgroundImage";
NSString *const FBSDKPlatformSharingToStoriesParamBackgroundVideo = @"com.facebook.sharedSticker.backgroundVideo";
NSString *const FBSDKPlatformSharingToStoriesParamStickerImage = @"com.facebook.sharedSticker.stickerImage";
NSString *const FBSDKPlatformSharingToStoriesParamBackgroundTopColor = @"com.facebook.sharedSticker.backgroundTopColor";
NSString *const FBSDKPlatformSharingToStoriesParamBackgroundBottomColor = @"com.facebook.sharedSticker.backgroundBottomColor";
NSString *const FBSDKPlatformSharingToStoriesParamContentURL = @"com.facebook.sharedSticker.contentURL";

NSString *const FBSDKPlatformSharingToStoriesParamProxiedAppID = @"com.facebook.sharedSticker.proxiedAppID";
NSString *const FBSDKPlatformSharingToStoriesParamBackgroundVideoURL = @"com.facebook.sharedSticker.backgroundVideoURL";
NSString *const FBSDKPlatformSharingToStoriesParamMethod = @"com.facebook.sharedSticker.method";

NSString *const FBSDKPlatformSharingToStoriesParamSource = @"com.facebook.sharedSticker.source";
NSString *const FBSDKPlatformSharingToStoriesParamWhatsAppMediaList = @"com.facebook.sharedSticker.mediaList";
NSString *const FBSDKPlatformSharingToStoriesParamWhatsAppStoryImage = @"image";
NSString *const FBSDKPlatformSharingToStoriesParamWhatsAppStoryVideo = @"video";
NSString *const FBSDKPlatformSharingToStoriesParamWhatsAppStoryCaption = @"caption";

BOOL FBSDKPlatformSharingToStoriesCanOpen(void)
{
  return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:FBSDKPlatformSharingToStoriesScheme]];
}

BOOL FBSDKPlatformSharingToReels(NSString *_Nullable appID,
                                 NSData *_Nullable backgroundVideo,
                                 NSString *_Nullable contentURL,
                                 NSData *_Nullable stickerImage)
{
  NSMutableArray<NSDictionary<NSString *, id> *> *const pasteboardItems = [NSMutableArray new];
  if (appID.length > 0) {
    [pasteboardItems addObject:@{FBSDKPlatformSharingToStoriesParamAppID : appID}];
  }
  if (backgroundVideo) {
    [pasteboardItems addObject:@{FBSDKPlatformSharingToStoriesParamBackgroundVideo : backgroundVideo}];
  }
  if (contentURL.length > 0) {
    [pasteboardItems addObject:@{FBSDKPlatformSharingToStoriesParamContentURL : contentURL}];
  }
  if (stickerImage) {
    [pasteboardItems addObject:@{FBSDKPlatformSharingToStoriesParamStickerImage : stickerImage}];
  }
  return FBSDKPlatformSharingPasteboard(pasteboardItems, FBSDKPlatformSharingToReelsScheme);
}

BOOL FBSDKPlatformSharingToStoriesCamera(NSString *_Nullable appID,
                                         NSString *_Nullable proxiedAppID,
                                         NSData *_Nullable backgroundImage,
                                         NSData *_Nullable backgroundVideo,
                                         NSData *_Nullable stickerImage,
                                         NSString *_Nullable backgroundTopColor,
                                         NSString *_Nullable backgroundBottomColor,
                                         NSString *_Nullable contentURL)
{
  NSMutableArray<NSDictionary<NSString *, id> *> *const pasteboardItems = [NSMutableArray new];
  if (appID.length > 0) {
    [pasteboardItems addObject:@{FBSDKPlatformSharingToStoriesParamAppID : appID}];
  }
  if (proxiedAppID.length > 0) {
    [pasteboardItems addObject:@{FBSDKPlatformSharingToStoriesParamProxiedAppID : proxiedAppID}];
  }
  if (backgroundImage) {
    [pasteboardItems addObject:@{FBSDKPlatformSharingToStoriesParamBackgroundImage : backgroundImage}];
  }
  if (backgroundVideo) {
    [pasteboardItems addObject:@{FBSDKPlatformSharingToStoriesParamBackgroundVideo : backgroundVideo}];
  }
  if (stickerImage) {
    [pasteboardItems addObject:@{FBSDKPlatformSharingToStoriesParamStickerImage : stickerImage}];
  }
  if (backgroundTopColor.length > 0) {
    [pasteboardItems addObject:@{FBSDKPlatformSharingToStoriesParamBackgroundTopColor : backgroundTopColor}];
  }
  if (backgroundBottomColor.length > 0) {
    [pasteboardItems addObject:@{FBSDKPlatformSharingToStoriesParamBackgroundBottomColor : backgroundBottomColor}];
  }
  if (contentURL.length > 0) {
    [pasteboardItems addObject:@{FBSDKPlatformSharingToStoriesParamContentURL : contentURL}];
  }
  return FBSDKPlatformSharingPasteboard(pasteboardItems, FBSDKPlatformSharingToStoriesScheme);
}

BOOL FBSDKPlatformSharingToStoriesComposer(NSString *_Nullable appID,
                                           NSString *_Nullable proxiedAppID,
                                           NSData *_Nullable backgroundImage,
                                           NSData *_Nullable backgroundVideo,
                                           NSString *_Nullable backgroundVideoURL)
{
  NSMutableArray<NSDictionary<NSString *, id> *> *const pasteboardItems = [NSMutableArray new];
  if (appID.length > 0) {
    [pasteboardItems addObject:@{FBSDKPlatformSharingToStoriesParamAppID : appID}];
  }
  if (proxiedAppID.length > 0) {
    [pasteboardItems addObject:@{FBSDKPlatformSharingToStoriesParamProxiedAppID : proxiedAppID}];
  }
  if (backgroundImage) {
    [pasteboardItems addObject:@{FBSDKPlatformSharingToStoriesParamBackgroundImage : backgroundImage}];
  }
  if (backgroundVideo) {
    [pasteboardItems addObject:@{FBSDKPlatformSharingToStoriesParamBackgroundVideo : backgroundVideo}];
  }
  if (backgroundVideoURL.length > 0) {
    [pasteboardItems addObject:@{FBSDKPlatformSharingToStoriesParamBackgroundVideoURL : backgroundVideoURL}];
  }
  if (pasteboardItems.count > 0) {
    [pasteboardItems addObject:@{FBSDKPlatformSharingToStoriesParamMethod : @"share"}]; // default behavior would open camera
  }
  return FBSDKPlatformSharingPasteboard(pasteboardItems, FBSDKPlatformSharingToStoriesScheme);
}

BOOL FBSDKPlatformSharingToStoriesWhatsAppShare(NSString *_Nullable appID,
                                                NSArray<NSDictionary<NSString *, id> *> *_Nullable mediaList)
{
  NSMutableArray<NSDictionary<NSString *, id> *> *const pasteboardItems = [NSMutableArray new];
  if (appID.length > 0) {
    [pasteboardItems addObject:@{FBSDKPlatformSharingToStoriesParamAppID : appID}];
  }
  if (mediaList.count > 0) {
    [pasteboardItems addObject:@{FBSDKPlatformSharingToStoriesParamWhatsAppMediaList : [NSKeyedArchiver archivedDataWithRootObject:mediaList]}];
  }
  return FBSDKPlatformSharingPasteboard(pasteboardItems, FBSDKPlatformSharingToStoriesScheme);
}

BOOL FBSDKPlatformSharingPasteboard(NSArray<NSDictionary<NSString *, id> *> *pasteboardItems, NSString *urlScheme)
{
  if (pasteboardItems.count > 0) {
    NSURL *const URL = [NSURL URLWithString:urlScheme];
    if ([[UIApplication sharedApplication] canOpenURL:URL]) {
      [[UIPasteboard generalPasteboard] addItems:pasteboardItems]; // iOS 10+ setItems:options:
      return [[UIApplication sharedApplication] openURL:URL]; // iOS 10+ openURL:options:completionHandler:
    }
  }
  return NO;
}
