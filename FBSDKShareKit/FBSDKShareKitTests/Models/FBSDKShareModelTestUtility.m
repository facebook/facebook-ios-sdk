/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKShareModelTestUtility.h"

@implementation FBSDKShareModelTestUtility

#pragma mark - Public Methods

+ (NSURL *)contentURL
{
  return [NSURL URLWithString:@"https://developers.facebook.com/"];
}

+ (FBSDKHashtag *)hashtag
{
  return [FBSDKHashtag hashtagWithString:@"#ashtag"];
}

+ (NSURL *)fileURL
{
  return [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject;
}

+ (FBSDKShareLinkContent *)linkContent
{
  FBSDKShareLinkContent *linkContent = [self linkContentWithoutQuote];
  linkContent.quote = [self quote];
  return linkContent;
}

+ (FBSDKShareLinkContent *)linkContentWithoutQuote
{
  FBSDKShareLinkContent *linkContent = [FBSDKShareLinkContent new];
  linkContent.contentURL = [self contentURL];
  linkContent.hashtag = [self hashtag];
  linkContent.peopleIDs = [self peopleIDs];
  linkContent.placeID = [self placeID];
  linkContent.ref = [self ref];
  return linkContent;
}

+ (NSString *)linkContentDescription
{
  return @"this is my status";
}

+ (NSString *)linkContentTitle
{
  return @"my status";
}

+ (NSURL *)linkImageURL
{
  return [NSURL URLWithString:@"https://fbcdn-dragon-a.akamaihd.net/hphotos-ak-xpa1/t39.2178-6/851594_549760571770473_1178259000_n.png"];
}

+ (NSArray *)peopleIDs
{
  return @[];
}

+ (FBSDKSharePhotoContent *)photoContent
{
  FBSDKSharePhotoContent *content = [FBSDKSharePhotoContent new];
  content.contentURL = [self contentURL];
  content.hashtag = [self hashtag];
  content.peopleIDs = [self peopleIDs];
  content.photos = [self photos];
  content.placeID = [self placeID];
  content.ref = [self ref];
  return content;
}

+ (FBSDKSharePhotoContent *)photoContentWithFileURLs
{
  FBSDKSharePhotoContent *const content = [FBSDKSharePhotoContent new];
  content.contentURL = [self contentURL];
  content.hashtag = [self hashtag];
  content.peopleIDs = [self peopleIDs];
  content.photos = [self photosWithFileUrls];
  content.placeID = [self placeID];
  content.ref = [self ref];
  return content;
}

+ (FBSDKSharePhotoContent *)photoContentWithImages
{
  FBSDKSharePhotoContent *content = [FBSDKSharePhotoContent new];
  content.contentURL = [self contentURL];
  content.hashtag = [self hashtag];
  content.peopleIDs = [self peopleIDs];
  content.photos = [self photosWithImages];
  content.placeID = [self placeID];
  content.ref = [self ref];
  return content;
}

+ (UIImage *)photoImage
{
  // equality checks are pointer equality for UIImage, so just return the same instance each time
  static UIImage *_photoImage = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _photoImage = [self _generateImage];
  });
  return _photoImage;
}

+ (NSURL *)photoImageURL
{
  return [NSURL URLWithString:@"https://fbstatic-a.akamaihd.net/rsrc.php/v2/yC/r/YRwxe7CPWSs.png"];
}

+ (BOOL)photoUserGenerated
{
  return YES;
}

+ (FBSDKSharePhoto *)photoWithImage
{
  return [FBSDKSharePhoto photoWithImage:[self photoImage] userGenerated:[self photoUserGenerated]];
}

+ (FBSDKSharePhoto *)photoWithFileURL
{
  return [FBSDKSharePhoto photoWithImageURL:[self fileURL] userGenerated:[self photoUserGenerated]];
}

+ (FBSDKSharePhoto *)photoWithImageURL
{
  return [FBSDKSharePhoto photoWithImageURL:[self photoImageURL] userGenerated:[self photoUserGenerated]];
}

+ (NSArray<FBSDKSharePhoto *> *)photos
{
  return @[
    [FBSDKSharePhoto photoWithImageURL:[NSURL URLWithString:@"https://fbstatic-a.akamaihd.net/rsrc.php/v2/yC/r/YRwxe7CPWSs.png"]
                         userGenerated:NO],
    [FBSDKSharePhoto photoWithImageURL:[NSURL URLWithString:@"https://fbstatic-a.akamaihd.net/rsrc.php/v2/yS/r/9f82O0jy9RH.png"]
                         userGenerated:NO],
    [FBSDKSharePhoto photoWithImageURL:[NSURL URLWithString:@"https://fbcdn-dragon-a.akamaihd.net/hphotos-ak-xaf1/t39.2178-6/10173500_1398474223767412_616498772_n.png"]
                         userGenerated:YES],
  ];
}

+ (NSArray<FBSDKSharePhoto *> *)photosWithFileUrls
{
  return @[
    [FBSDKShareModelTestUtility photoWithFileURL],
  ];
}

+ (NSArray<FBSDKSharePhoto *> *)photosWithImages
{
  // equality checks are pointer equality for UIImage, so just return the same instance each time
  static NSArray *_photos = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _photos = @[
      [FBSDKSharePhoto photoWithImage:[self _generateImage] userGenerated:YES],
      [FBSDKSharePhoto photoWithImage:[self _generateImage] userGenerated:YES],
      [FBSDKSharePhoto photoWithImage:[self _generateImage] userGenerated:YES],
    ];
  });
  return _photos;
}

+ (NSString *)placeID
{
  return @"141887372509674";
}

+ (NSString *)previewPropertyName
{
  return @"myObject";
}

+ (NSString *)ref
{
  return @"myref";
}

+ (NSString *)quote
{
  return @"quote";
}

+ (FBSDKShareVideo *)video
{
  return [FBSDKShareVideo videoWithVideoURL:[self videoURL]];
}

+ (FBSDKShareVideo *)videoWithPreviewPhoto
{
  return [FBSDKShareVideo videoWithVideoURL:[self videoURL] previewPhoto:[self photoWithImageURL]];
}

+ (FBSDKShareVideoContent *)videoContentWithoutPreviewPhoto
{
  FBSDKShareVideoContent *content = [FBSDKShareVideoContent new];
  content.contentURL = [self contentURL];
  content.hashtag = [self hashtag];
  content.peopleIDs = [self peopleIDs];
  content.placeID = [self placeID];
  content.ref = [self ref];
  content.video = [self video];
  return content;
}

+ (FBSDKShareVideoContent *)videoContentWithPreviewPhoto
{
  FBSDKShareVideoContent *content = [FBSDKShareVideoContent new];
  content.contentURL = [self contentURL];
  content.hashtag = [self hashtag];
  content.peopleIDs = [self peopleIDs];
  content.placeID = [self placeID];
  content.ref = [self ref];
  content.video = [self videoWithPreviewPhoto];
  return content;
}

+ (NSURL *)videoURL
{
  return [NSURL URLWithString:@"assets-library://asset/asset.mp4?id=86C6970B-1266-42D0-91E8-4E68127D3864&ext=mp4"];
}

+ (NSArray *)media
{
  return @[[self video], [self photoWithImage]];
}

+ (FBSDKShareMediaContent *)mediaContent
{
  FBSDKShareMediaContent *content = [FBSDKShareMediaContent new];
  content.media = [self media];
  return content;
}

+ (FBSDKShareMediaContent *)multiVideoMediaContent
{
  FBSDKShareMediaContent *content = [FBSDKShareMediaContent new];
  content.media = @[[self video], [self video]];
  return content;
}

+ (NSString *)cameraEffectID
{
  return @"1234567";
}

+ (FBSDKCameraEffectArguments *)cameraEffectArguments
{
  FBSDKCameraEffectArguments *arguments = [FBSDKCameraEffectArguments new];
  [arguments setString:@"A string argument" forKey:@"stringArg1"];
  [arguments setString:@"Another string argument" forKey:@"stringArg2"];
  return arguments;
}

+ (FBSDKShareCameraEffectContent *)cameraEffectContent
{
  FBSDKShareCameraEffectContent *content = [FBSDKShareCameraEffectContent new];
  content.effectID = [self cameraEffectID];
  content.effectArguments = [self cameraEffectArguments];
  return content;
}

+ (UIImage *)_generateImage
{
  UIGraphicsBeginImageContext(CGSizeMake(10.0, 10.0));
  CGContextRef context = UIGraphicsGetCurrentContext();
  [UIColor.redColor setFill];
  CGContextFillRect(context, CGRectMake(0.0, 0.0, 5.0, 5.0));
  [UIColor.greenColor setFill];
  CGContextFillRect(context, CGRectMake(5.0, 0.0, 5.0, 5.0));
  [UIColor.blueColor setFill];
  CGContextFillRect(context, CGRectMake(5.0, 5.0, 5.0, 5.0));
  [UIColor.yellowColor setFill];
  CGContextFillRect(context, CGRectMake(0.0, 5.0, 5.0, 5.0));
  CGImageRef imageRef = CGBitmapContextCreateImage(context);
  UIGraphicsEndImageContext();
  UIImage *image = [[UIImage alloc] initWithCGImage:imageRef];
  CGImageRelease(imageRef);
  return image;
}

@end
