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

#import "FBSDKShareModelTestUtility.h"

NSString *kFBSDKShareModelTestUtilityOpenGraphBoolValueKey = @"TEST:OPEN_GRAPH_BOOL_VALUE";
NSString *kFBSDKShareModelTestUtilityOpenGraphDoubleValueKey = @"TEST:OPEN_GRAPH_DOUBLE_VALUE";
NSString *kFBSDKShareModelTestUtilityOpenGraphFloatValueKey = @"TEST:OPEN_GRAPH_FLOAT_VALUE";
NSString *kFBSDKShareModelTestUtilityOpenGraphIntegerValueKey = @"TEST:OPEN_GRAPH_INTEGER_VALUE";
NSString *kFBSDKShareModelTestUtilityOpenGraphNumberArrayKey = @"TEST:OPEN_GRAPH_NUMBER_ARRAY";
NSString *kFBSDKShareModelTestUtilityOpenGraphPhotoArrayKey = @"TEST:OPEN_GRAPH_PHOTO_ARRAY";
NSString *kFBSDKShareModelTestUtilityOpenGraphStringArrayKey = @"TEST:OPEN_GRAPH_STRING_ARRAY";
NSString *kFBSDKShareModelTestUtilityOpenGraphStringKey = @"TEST:OPEN_GRAPH_STRING";

@implementation FBSDKShareModelTestUtility

#pragma mark - Public Methods

+ (NSArray *)allOpenGraphActionKeys
{
  NSMutableArray *allKeys = [[self allOpenGraphObjectKeys] mutableCopy];
  [allKeys addObject:[self previewPropertyName]];
  return [allKeys copy];
}

+ (NSArray *)allOpenGraphObjectKeys
{
  return [[self _openGraphProperties:YES] allKeys];
}

+ (NSURL *)contentURL
{
  return [[NSURL alloc] initWithString:@"https://developers.facebook.com/"];
}

+ (FBSDKHashtag *)hashtag
{
  return [FBSDKHashtag hashtagWithString:@"#ashtag"];
}

+ (NSURL *)fileURL
{
  return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

+ (FBSDKShareLinkContent *)linkContent
{
  FBSDKShareLinkContent *linkContent = [self linkContentWithoutQuote];
  linkContent.quote = [self quote];
  return linkContent;
}

+ (FBSDKShareLinkContent *)linkContentWithoutQuote
{
  FBSDKShareLinkContent *linkContent = [[FBSDKShareLinkContent alloc] init];
  linkContent.contentDescription = [self linkContentDescription];
  linkContent.contentTitle = [self linkContentTitle];
  linkContent.contentURL = [self contentURL];
  linkContent.hashtag = [self hashtag];
  linkContent.imageURL = [self linkImageURL];
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
  return [[NSURL alloc] initWithString:@"https://fbcdn-dragon-a.akamaihd.net/hphotos-ak-xpa1/t39.2178-6/851594_549760571770473_1178259000_n.png"];
}

+ (FBSDKShareOpenGraphAction *)openGraphAction
{
  FBSDKShareOpenGraphAction *action = [FBSDKShareOpenGraphAction actionWithType:[self openGraphActionType]
                                                                         object:[self openGraphObject]
                                                                            key:[self previewPropertyName]];
  [action parseProperties:[self _openGraphProperties:YES]];
  return action;
}

+ (FBSDKShareOpenGraphAction *)openGraphActionWithURLObject
{
  FBSDKShareOpenGraphAction *action = [FBSDKShareOpenGraphAction actionWithType:[self openGraphActionType]
                                                                      objectURL:[self contentURL]
                                                                            key:[self previewPropertyName]];
  return action;
}

+ (NSString *)openGraphActionType
{
  return @"myActionType";
}

+ (FBSDKShareOpenGraphAction *)openGraphActionWithObjectID
{
  FBSDKShareOpenGraphAction *action = [[FBSDKShareOpenGraphAction alloc] init];
  action.actionType = [self openGraphActionType];
  [action setString:[self openGraphObjectID] forKey:[self previewPropertyName]];
  [action parseProperties:[self _openGraphProperties:NO]];
  return action;
}

+ (BOOL)openGraphBoolValue
{
  return YES;
}

+ (FBSDKShareOpenGraphContent *)openGraphContent
{
  FBSDKShareOpenGraphContent *content = [[FBSDKShareOpenGraphContent alloc] init];
  content.action = [self openGraphAction];
  content.contentURL = [self contentURL];
  content.hashtag = [self hashtag];
  content.peopleIDs = [self peopleIDs];
  content.placeID = [self placeID];
  content.previewPropertyName = [self previewPropertyName];
  content.ref = [self ref];
  return content;
}

+ (FBSDKShareOpenGraphContent *)openGraphContentWithObjectID
{
  FBSDKShareOpenGraphContent *content = [[FBSDKShareOpenGraphContent alloc] init];
  content.action = [self openGraphActionWithObjectID];
  content.contentURL = [self contentURL];
  content.hashtag = [self hashtag];
  content.peopleIDs = [self peopleIDs];
  content.placeID = [self placeID];
  content.previewPropertyName = [self previewPropertyName];
  content.ref = [self ref];
  return content;
}

+ (FBSDKShareOpenGraphContent *)openGraphContentWithURLOnly
{
  FBSDKShareOpenGraphContent *content = [[FBSDKShareOpenGraphContent alloc] init];
  content.action = [self openGraphActionWithURLObject];
  content.previewPropertyName = [self previewPropertyName];
  return content;
}

+ (double)openGraphDoubleValue
{
  return DBL_MAX;
}

+ (float)openGraphFloatValue
{
  return FLT_MAX;
}

+ (NSInteger)openGraphIntegerValue
{
  return NSIntegerMax;
}

+ (NSArray *)openGraphNumberArray
{
  return @[ @NSIntegerMin, @-7, @0, @42, @NSIntegerMax ];
}

+ (FBSDKShareOpenGraphObject *)openGraphObject
{
  return [FBSDKShareOpenGraphObject objectWithProperties:[self _openGraphProperties:YES]];
}

+ (NSString *)openGraphObjectID
{
  return @"9876543210";
}

+ (NSArray *)openGraphStringArray
{
  return @[ @"string1", @"string2", @"string3" ];
}

+ (NSString *)openGraphString
{
  return @"this is a string";
}

+ (NSArray *)peopleIDs
{
  return @[];
}

+ (FBSDKSharePhotoContent *)photoContent
{
  FBSDKSharePhotoContent *content = [[FBSDKSharePhotoContent alloc] init];
  content.contentURL = [self contentURL];
  content.hashtag = [self hashtag];
  content.peopleIDs = [self peopleIDs];
  content.photos = [self photos];
  content.placeID = [self placeID];
  content.ref = [self ref];
  return content;
}

+ (FBSDKSharePhotoContent *)photoContentWithImages
{
  FBSDKSharePhotoContent *content = [[FBSDKSharePhotoContent alloc] init];
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
  return [[NSURL alloc] initWithString:@"https://fbstatic-a.akamaihd.net/rsrc.php/v2/yC/r/YRwxe7CPWSs.png"];
}

+ (BOOL)photoUserGenerated
{
  return YES;
}

+ (FBSDKSharePhoto *)photoWithImage
{
  return [FBSDKSharePhoto photoWithImage:[self photoImage] userGenerated:[self photoUserGenerated]];
}

+ (FBSDKSharePhoto *)photoWithImageURL
{
  return [FBSDKSharePhoto photoWithImageURL:[self photoImageURL] userGenerated:[self photoUserGenerated]];
}

+ (NSArray *)photos
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

+ (NSArray *)photosWithImages
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
  FBSDKShareVideoContent *content = [[FBSDKShareVideoContent alloc] init];
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
  FBSDKShareVideoContent *content = [[FBSDKShareVideoContent alloc] init];
  content.contentURL = [self contentURL];
  content.hashtag = [self hashtag];
  content.peopleIDs = [self peopleIDs];
  content.placeID = [self placeID];
  content.previewPhoto = [self photoWithImage];
  content.ref = [self ref];
  content.video = [self video];
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

#pragma mark - Helper Methods

+ (UIImage *)_generateImage
{
  UIGraphicsBeginImageContext(CGSizeMake(10.0, 10.0));
  CGContextRef context = UIGraphicsGetCurrentContext();
  [[UIColor redColor] setFill];
  CGContextFillRect(context, CGRectMake(0.0, 0.0, 5.0, 5.0));
  [[UIColor greenColor] setFill];
  CGContextFillRect(context, CGRectMake(5.0, 0.0, 5.0, 5.0));
  [[UIColor blueColor] setFill];
  CGContextFillRect(context, CGRectMake(5.0, 5.0, 5.0, 5.0));
  [[UIColor yellowColor] setFill];
  CGContextFillRect(context, CGRectMake(0.0, 5.0, 5.0, 5.0));
  CGImageRef imageRef = CGBitmapContextCreateImage(context);
  UIGraphicsEndImageContext();
  UIImage *image = [[UIImage alloc] initWithCGImage:imageRef];
  CGImageRelease(imageRef);
  return image;
}

+ (NSDictionary *)_openGraphProperties:(BOOL)includePhoto
{
  NSDictionary *properties = @{
                               kFBSDKShareModelTestUtilityOpenGraphBoolValueKey: @([self openGraphBoolValue]),
                               kFBSDKShareModelTestUtilityOpenGraphDoubleValueKey: @([self openGraphDoubleValue]),
                               kFBSDKShareModelTestUtilityOpenGraphFloatValueKey: @([self openGraphFloatValue]),
                               kFBSDKShareModelTestUtilityOpenGraphIntegerValueKey: @([self openGraphIntegerValue]),
                               kFBSDKShareModelTestUtilityOpenGraphNumberArrayKey: [self openGraphNumberArray],
                               kFBSDKShareModelTestUtilityOpenGraphStringArrayKey: [self openGraphStringArray],
                               kFBSDKShareModelTestUtilityOpenGraphStringKey: [self openGraphString],
                               };
  if (includePhoto) {
    NSMutableDictionary *mutableProperties = [properties mutableCopy];
    mutableProperties[kFBSDKShareModelTestUtilityOpenGraphPhotoArrayKey] = [self photos];
    properties = [mutableProperties copy];
  }
  return properties;
}

@end
