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
#import "FBSDKShareMessengerGenericTemplateContent.h"
#import "FBSDKShareMessengerGenericTemplateElement.h"
#import "FBSDKShareMessengerMediaTemplateContent.h"
#import "FBSDKShareMessengerOpenGraphMusicTemplateContent.h"
#import "FBSDKShareMessengerURLActionButton.h"
#import "FBSDKShareOpenGraphAction.h"
#import "FBSDKShareOpenGraphObject.h"
#import "FBSDKSharePhoto.h"
#import "FBSDKSharePhotoContent.h"
#import "FBSDKShareVideo.h"
#import "FBSDKShareVideoContent.h"

FOUNDATION_EXPORT NSString *kFBSDKShareModelTestUtilityOpenGraphBoolValueKey;
FOUNDATION_EXPORT NSString *kFBSDKShareModelTestUtilityOpenGraphDoubleValueKey;
FOUNDATION_EXPORT NSString *kFBSDKShareModelTestUtilityOpenGraphFloatValueKey;
FOUNDATION_EXPORT NSString *kFBSDKShareModelTestUtilityOpenGraphIntegerValueKey;
FOUNDATION_EXPORT NSString *kFBSDKShareModelTestUtilityOpenGraphNumberArrayKey;
FOUNDATION_EXPORT NSString *kFBSDKShareModelTestUtilityOpenGraphPhotoArrayKey;
FOUNDATION_EXPORT NSString *kFBSDKShareModelTestUtilityOpenGraphStringArrayKey;
FOUNDATION_EXPORT NSString *kFBSDKShareModelTestUtilityOpenGraphStringKey;

@interface FBSDKShareModelTestUtility : NSObject

+ (NSArray *)allOpenGraphActionKeys;
+ (NSArray *)allOpenGraphObjectKeys;
+ (NSURL *)contentURL;
+ (NSURL *)fileURL;
+ (FBSDKHashtag *)hashtag;
+ (FBSDKShareLinkContent *)linkContent;
+ (FBSDKShareLinkContent *)linkContentWithoutQuote;
+ (NSString *)linkContentDescription;
+ (NSString *)linkContentTitle;
+ (NSURL *)linkImageURL;
+ (FBSDKShareOpenGraphAction *)openGraphAction;
+ (NSString *)openGraphActionType;
+ (FBSDKShareOpenGraphAction *)openGraphActionWithObjectID;
+ (BOOL)openGraphBoolValue;
+ (double)openGraphDoubleValue;
+ (float)openGraphFloatValue;
+ (NSInteger)openGraphIntegerValue;
+ (NSArray *)openGraphNumberArray;
+ (FBSDKShareOpenGraphObject *)openGraphObject;
+ (NSString *)openGraphObjectID;
+ (NSArray *)openGraphStringArray;
+ (NSString *)openGraphString;
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
