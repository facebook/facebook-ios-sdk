/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>
@import FBSDKShareKit;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ShareModelTestUtility)
@interface FBSDKShareModelTestUtility : NSObject

+ (NSURL *)contentURL;
+ (NSURL *)fileURL;
+ (FBSDKHashtag *)hashtag;
+ (FBSDKShareLinkContent *)linkContent;
+ (FBSDKShareLinkContent *)linkContentWithoutQuote;
+ (NSString *)linkContentDescription;
+ (NSString *)linkContentTitle;
+ (NSURL *)linkImageURL;
+ (NSArray *)peopleIDs;
+ (FBSDKSharePhotoContent *)photoContent;
+ (FBSDKSharePhotoContent *)photoContentWithFileURLs;
+ (FBSDKSharePhotoContent *)photoContentWithImages;
+ (UIImage *)photoImage;
+ (NSURL *)photoImageURL;
+ (FBSDKSharePhoto *)photoWithImage;
+ (FBSDKSharePhoto *)photoWithImageURL;
+ (BOOL)photoUserGenerated;
+ (NSArray *)photos;
+ (NSArray *)photosWithImages;
+ (NSString *)placeID;
+ (NSString *)previewPropertyName;
+ (NSString *)ref;
+ (NSString *)quote;
+ (FBSDKShareVideo *)video;
+ (FBSDKShareVideo *)videoWithPreviewPhoto;
+ (FBSDKShareVideoContent *)videoContentWithoutPreviewPhoto;
+ (FBSDKShareVideoContent *)videoContentWithPreviewPhoto;
+ (NSURL *)videoURL;
+ (NSArray *)media;
+ (FBSDKShareMediaContent *)mediaContent;
+ (FBSDKShareMediaContent *)multiVideoMediaContent;
+ (NSString *)cameraEffectID;
+ (FBSDKCameraEffectArguments *)cameraEffectArguments;
+ (FBSDKShareCameraEffectContent *)cameraEffectContent;

@end

NS_ASSUME_NONNULL_END
