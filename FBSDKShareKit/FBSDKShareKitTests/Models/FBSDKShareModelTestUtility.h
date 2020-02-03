// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <UIKit/UIKit.h>

#import "FBSDKCameraEffectArguments.h"
#import "FBSDKHashtag.h"
#import "FBSDKShareCameraEffectContent.h"
#import "FBSDKShareLinkContent.h"
#import "FBSDKShareMediaContent.h"
#import "FBSDKSharePhoto.h"
#import "FBSDKSharePhotoContent.h"
#import "FBSDKShareVideo.h"
#import "FBSDKShareVideoContent.h"

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
