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

#import "FBSDKShareUtility.h"

#import "FBSDKHashtag.h"

#ifdef FBSDKCOCOAPODS
 #import <FBSDKCoreKit/FBSDKCoreKit+Internal.h>
#else
 #import "FBSDKCoreKit+Internal.h"
#endif
#import "FBSDKShareConstants.h"
#import "FBSDKShareLinkContent.h"

@implementation FBSDKShareUtility

#pragma mark - Class Methods

+ (void)assertCollection:(id<NSFastEnumeration>)collection ofClassStrings:(NSArray *)classStrings name:(NSString *)name
{
  for (id item in collection) {
    BOOL validClass = NO;
    for (NSString *classString in classStrings) {
      if ([item isKindOfClass:NSClassFromString(classString)]) {
        validClass = YES;
        break;
      }
    }
    if (!validClass) {
      NSString *reason = [[NSString alloc] initWithFormat:
                          @"Invalid value found in %@: %@ - %@",
                          name,
                          item,
                          collection];
      @throw [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
    }
  }
}

+ (void)assertCollection:(id<NSFastEnumeration>)collection ofClass:itemClass name:(NSString *)name
{
  for (id item in collection) {
    if (![item isKindOfClass:itemClass]) {
      NSString *reason = [[NSString alloc] initWithFormat:
                          @"Invalid value found in %@: %@ - %@",
                          name,
                          item,
                          collection];
      @throw [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
    }
  }
}

+ (BOOL)buildWebShareContent:(id<FBSDKSharingContent>)content
                  methodName:(NSString *__autoreleasing *)methodNameRef
                  parameters:(NSDictionary *__autoreleasing *)parametersRef
                       error:(NSError *__autoreleasing *)errorRef
{
  NSString *methodName = @"share";
  NSMutableDictionary<NSString *, id> *parameters = nil;
  if ([content isKindOfClass:[FBSDKShareLinkContent class]]) {
    FBSDKShareLinkContent *const linkContent = (FBSDKShareLinkContent *)content;
    if (linkContent.contentURL != nil) {
      parameters = [NSMutableDictionary new];
      [FBSDKTypeUtility dictionary:parameters setObject:linkContent.contentURL.absoluteString forKey:@"href"];
      [FBSDKTypeUtility dictionary:parameters setObject:linkContent.quote forKey:@"quote"];
    }
  }

  if (parameters) {
    [FBSDKTypeUtility dictionary:parameters setObject:[self hashtagStringFromHashtag:content.hashtag] forKey:@"hashtag"];
    [FBSDKTypeUtility dictionary:parameters setObject:content.placeID forKey:@"place"];
    [FBSDKTypeUtility dictionary:parameters setObject:[FBSDKShareUtility buildWebShareTags:content.peopleIDs] forKey:@"tags"];
  }
  if (methodNameRef != NULL) {
    *methodNameRef = methodName;
  }
  if (parametersRef != NULL) {
    *parametersRef = parameters;
  }
  if (errorRef != NULL) {
    *errorRef = nil;
  }
  return YES;
}

+ (NSString *)buildWebShareTags:(NSArray<NSString *> *)peopleIDs
{
  if (peopleIDs.count > 0) {
    NSMutableString *tags = [NSMutableString new];
    for (NSString *tag in peopleIDs) {
      if (tag.length > 0) {
        [tags appendFormat:@"%@%@", (tags.length > 0 ? @"," : @""), tag];
      }
    }
    return tags;
  } else {
    return nil;
  }
}

+ (void)buildAsyncWebPhotoContent:(FBSDKSharePhotoContent *)content
                completionHandler:(FBSDKWebPhotoContentBlock)completion
{
  void (^stageImageCompletion)(NSArray<NSString *> *) = ^(NSArray<NSString *> *stagedURIs) {
    NSString *const methodName = @"share";
    NSMutableDictionary<NSString *, id> *const parameters =
    [[FBSDKShareUtility parametersForShareContent:content
                                    bridgeOptions:FBSDKShareBridgeOptionsWebHashtag
                            shouldFailOnDataError:NO] mutableCopy];
    [parameters removeObjectForKey:@"photos"];
    NSString *const stagedURIJSONString = [FBSDKBasicUtility JSONStringForObject:stagedURIs
                                                                           error:nil
                                                            invalidObjectHandler:NULL];
    [FBSDKTypeUtility dictionary:parameters
                       setObject:stagedURIJSONString
                          forKey:@"media"];
    [FBSDKTypeUtility dictionary:parameters setObject:[FBSDKShareUtility buildWebShareTags:content.peopleIDs] forKey:@"tags"];
    if (completion != NULL) {
      completion(YES, methodName, [parameters copy]);
    }
  };

  [self _stageImagesForPhotoContent:(FBSDKSharePhotoContent *)content
              withCompletionHandler:stageImageCompletion];
}

+ (NSDictionary<NSString *, id> *)feedShareDictionaryForContent:(id<FBSDKSharingContent>)content
{
  NSMutableDictionary<NSString *, id> *parameters = nil;
  if ([content isKindOfClass:[FBSDKShareLinkContent class]]) {
    FBSDKShareLinkContent *linkContent = (FBSDKShareLinkContent *)content;
    parameters = [[NSMutableDictionary alloc] init];
    [FBSDKTypeUtility dictionary:parameters setObject:linkContent.contentURL forKey:@"link"];
    [FBSDKTypeUtility dictionary:parameters setObject:linkContent.quote forKey:@"quote"];
    [FBSDKTypeUtility dictionary:parameters setObject:[self hashtagStringFromHashtag:linkContent.hashtag] forKey:@"hashtag"];
    [FBSDKTypeUtility dictionary:parameters setObject:content.placeID forKey:@"place"];
    [FBSDKTypeUtility dictionary:parameters setObject:[FBSDKShareUtility buildWebShareTags:content.peopleIDs] forKey:@"tags"];
    [FBSDKTypeUtility dictionary:parameters setObject:linkContent.ref forKey:@"ref"];
  }
  return [parameters copy];
}

+ (NSString *)hashtagStringFromHashtag:(FBSDKHashtag *)hashtag
{
  if (!hashtag) {
    return nil;
  }
  if (hashtag.isValid) {
    return hashtag.stringRepresentation;
  } else {
    [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                       formatString:@"Invalid hashtag: '%@'", hashtag.stringRepresentation];
    return nil;
  }
}

+ (UIImage *)imageWithCircleColor:(UIColor *)color
                       canvasSize:(CGSize)canvasSize
                       circleSize:(CGSize)circleSize
{
  CGRect circleFrame = CGRectMake(
    (canvasSize.width - circleSize.width) / 2.0,
    (canvasSize.height - circleSize.height) / 2.0,
    circleSize.width,
    circleSize.height
  );
  UIGraphicsBeginImageContextWithOptions(canvasSize, NO, 0);
  CGContextRef context = UIGraphicsGetCurrentContext();
  [color setFill];
  CGContextFillEllipseInRect(context, circleFrame);
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}

+ (NSDictionary<NSString *, id> *)parametersForShareContent:(id<FBSDKSharingContent>)shareContent
                                              bridgeOptions:(FBSDKShareBridgeOptions)bridgeOptions
                                      shouldFailOnDataError:(BOOL)shouldFailOnDataError
{
  NSMutableDictionary<NSString *, id> *parameters = [[NSMutableDictionary alloc] init];

  // FBSDKSharingContent parameters
  NSString *const hashtagString = [self hashtagStringFromHashtag:shareContent.hashtag];
  if (hashtagString.length > 0) {
    // When hashtag support was originally added, the Facebook app supported an array of hashtags.
    // This was changed to support a single hashtag; however, the mobile app still expects to receive an array.
    // When hashtag support was added to web dialogs, a single hashtag was passed as a string.
    if (bridgeOptions & FBSDKShareBridgeOptionsWebHashtag) {
      [FBSDKTypeUtility dictionary:parameters setObject:hashtagString forKey:@"hashtag"];
    } else {
      [FBSDKTypeUtility dictionary:parameters setObject:@[hashtagString] forKey:@"hashtags"];
    }
  }
  [FBSDKTypeUtility dictionary:parameters setObject:shareContent.shareUUID forKey:@"shareUUID"];
  [FBSDKTypeUtility dictionary:parameters setObject:shareContent.peopleIDs forKey:@"tags"];
  [FBSDKTypeUtility dictionary:parameters setObject:shareContent.placeID forKey:@"place"];
  [FBSDKTypeUtility dictionary:parameters setObject:shareContent.ref forKey:@"ref"];

  [FBSDKTypeUtility dictionary:parameters setObject:@(shouldFailOnDataError) forKey:@"dataFailuresFatal"];

  // media/destination-specific content parameters
  if ([shareContent respondsToSelector:@selector(addParameters:bridgeOptions:)]) {
    [parameters
     addEntriesFromDictionary:[shareContent addParameters:parameters bridgeOptions:bridgeOptions]];
  }

  return [parameters copy];
}

+ (void)testShareContent:(id<FBSDKSharingContent>)shareContent
           containsMedia:(BOOL *)containsMediaRef
          containsPhotos:(BOOL *)containsPhotosRef
          containsVideos:(BOOL *)containsVideosRef
{
  BOOL containsMedia = NO;
  BOOL containsPhotos = NO;
  BOOL containsVideos = NO;
  if ([shareContent isKindOfClass:[FBSDKShareLinkContent class]]) {
    containsMedia = NO;
    containsPhotos = NO;
    containsVideos = NO;
  } else if ([shareContent isKindOfClass:[FBSDKShareVideoContent class]]) {
    containsMedia = YES;
    containsVideos = YES;
    containsPhotos = NO;
  } else if ([shareContent isKindOfClass:[FBSDKSharePhotoContent class]]) {
    [self _testObject:((FBSDKSharePhotoContent *)shareContent).photos
        containsMedia:&containsMedia
       containsPhotos:&containsPhotos
       containsVideos:&containsVideos];
  } else if ([shareContent isKindOfClass:[FBSDKShareMediaContent class]]) {
    [self _testObject:((FBSDKShareMediaContent *)shareContent).media
        containsMedia:&containsMedia
       containsPhotos:&containsPhotos
       containsVideos:&containsVideos];
  }

  if (containsMediaRef != NULL) {
    *containsMediaRef = containsMedia;
  }
  if (containsPhotosRef != NULL) {
    *containsPhotosRef = containsPhotos;
  }
  if (containsVideosRef != NULL) {
    *containsVideosRef = containsVideos;
  }
}

+ (BOOL)validateAssetLibraryURLsWithShareMediaContent:(FBSDKShareMediaContent *)mediaContent name:(NSString *)name error:(NSError *__autoreleasing *)errorRef
{
  for (id media in mediaContent.media) {
    if ([media isKindOfClass:[FBSDKShareVideo class]]) {
      FBSDKShareVideo *video = (FBSDKShareVideo *)media;
      if (![self _validateAssetLibraryVideoURL:video.videoURL name:name error:errorRef]) {
        return NO;
      }
    }
  }
  return YES;
}

+ (BOOL)validateShareContent:(id<FBSDKSharingContent>)shareContent
               bridgeOptions:(FBSDKShareBridgeOptions)bridgeOptions
                       error:(NSError *__autoreleasing *)errorRef
{
  if (![self validateRequiredValue:shareContent name:@"shareContent" error:errorRef]) {
    return NO;
  } else if ([shareContent respondsToSelector:@selector(validateWithOptions:error:)]) {
    return [shareContent validateWithOptions:bridgeOptions error:errorRef];
  } else {
    if (errorRef != NULL) {
      *errorRef = [FBSDKError invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                        name:@"shareContent"
                                                       value:shareContent
                                                     message:nil];
    }
    return NO;
  }
}

+ (BOOL)shareMediaContentContainsPhotosAndVideos:(FBSDKShareMediaContent *)shareMediaContent
{
  BOOL containsPhotos = NO;
  BOOL containsVideos = NO;
  [self testShareContent:shareMediaContent containsMedia:NULL containsPhotos:&containsPhotos containsVideos:&containsVideos];
  return containsVideos && containsPhotos;
}

#pragma mark - Helper Methods

+ (id)_convertObject:(id)object
{
  if ([object isKindOfClass:[FBSDKSharePhoto class]]) {
    object = [self convertPhoto:(FBSDKSharePhoto *)object];
  } else if ([object isKindOfClass:[NSArray class]]) {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (id item in (NSArray *)object) {
      [FBSDKTypeUtility array:array addObject:[self _convertObject:item]];
    }
    object = array;
  }
  return object;
}

+ (NSDictionary<NSString *, id> *)convertPhoto:(FBSDKSharePhoto *)photo
{
  if (!photo) {
    return nil;
  }
  NSMutableDictionary<NSString *, id> *dictionary = [[NSMutableDictionary alloc] init];
  [FBSDKTypeUtility dictionary:dictionary setObject:@(photo.userGenerated) forKey:@"user_generated"];
  [FBSDKTypeUtility dictionary:dictionary setObject:photo.caption forKey:@"caption"];

  [FBSDKTypeUtility dictionary:dictionary setObject:photo.image ?: photo.imageURL.absoluteString forKey:@"url"];
  return dictionary;
}

+ (void)_stageImagesForPhotoContent:(FBSDKSharePhotoContent *)content
              withCompletionHandler:(void (^)(NSArray<NSString *> *))completion
{
  __block NSMutableArray<NSString *> *stagedURIs = [NSMutableArray array];
  dispatch_group_t group = dispatch_group_create();
  for (FBSDKSharePhoto *photo in content.photos) {
    if (photo.image != nil) {
      dispatch_group_enter(group);
      NSDictionary *stagingParameters = @{
        @"file" : photo.image,
      };
      FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me/staging_resources"
                                                                     parameters:stagingParameters
                                                                     HTTPMethod:@"POST"];
      [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        NSString *photoStagedURI = result[@"uri"];
        if (photoStagedURI != nil) {
          [FBSDKTypeUtility array:stagedURIs addObject:photoStagedURI];
          dispatch_group_leave(group);
        }
      }];
    }
  }

  dispatch_group_notify(group,
    dispatch_get_main_queue(), ^{
      if (completion != NULL) {
        completion([stagedURIs copy]);
      }
    });
}

+ (void)_testObject:(id)object containsMedia:(BOOL *)containsMediaRef containsPhotos:(BOOL *)containsPhotosRef containsVideos:(BOOL *)containsVideosRef
{
  BOOL containsMedia = NO;
  BOOL containsPhotos = NO;
  BOOL containsVideos = NO;
  if ([object isKindOfClass:[FBSDKSharePhoto class]]) {
    containsMedia = (((FBSDKSharePhoto *)object).image != nil);
    containsPhotos = YES;
  } else if ([object isKindOfClass:[FBSDKShareVideo class]]) {
    containsMedia = YES;
    containsVideos = YES;
  } else if ([object isKindOfClass:[NSArray class]]) {
    for (id item in (NSArray *)object) {
      BOOL itemContainsMedia = NO;
      BOOL itemContainsPhotos = NO;
      BOOL itemContainsVideos = NO;
      [self _testObject:item containsMedia:&itemContainsMedia containsPhotos:&itemContainsPhotos containsVideos:&itemContainsVideos];
      containsMedia |= itemContainsMedia;
      containsPhotos |= itemContainsPhotos;
      containsVideos |= itemContainsVideos;
      if (containsMedia && containsPhotos && containsVideos) {
        break;
      }
    }
  }
  if (containsMediaRef != NULL) {
    *containsMediaRef = containsMedia;
  }
  if (containsPhotosRef != NULL) {
    *containsPhotosRef = containsPhotos;
  }
  if (containsVideosRef != NULL) {
    *containsVideosRef = containsVideos;
  }
}

+ (BOOL)validateArray:(NSArray<id> *)array
             minCount:(NSUInteger)minCount
             maxCount:(NSUInteger)maxCount
                 name:(NSString *)name
                error:(NSError *__autoreleasing *)errorRef
{
  NSUInteger count = array.count;
  if ((count < minCount) || (count > maxCount)) {
    if (errorRef != NULL) {
      NSString *message = [[NSString alloc] initWithFormat:@"%@ must have %lu to %lu values",
                           name,
                           (unsigned long)minCount,
                           (unsigned long)maxCount];
      *errorRef = [FBSDKError invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                        name:name
                                                       value:array
                                                     message:message];
    }
    return NO;
  } else {
    if (errorRef != NULL) {
      *errorRef = nil;
    }
    return YES;
  }
}

+ (BOOL)_validateFileURL:(NSURL *)URL name:(NSString *)name error:(NSError *__autoreleasing *)errorRef
{
  if (!URL) {
    if (errorRef != NULL) {
      *errorRef = nil;
    }
    return YES;
  }
  if (!URL.isFileURL) {
    if (errorRef != NULL) {
      *errorRef = [FBSDKError invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                        name:name
                                                       value:URL
                                                     message:nil];
    }
    return NO;
  }
  // ensure that the file exists.  per the latest spec for NSFileManager, we should not be checking for file existence,
  // so they have removed that option for URLs and discourage it for paths, so we just construct a mapped NSData.
  NSError *fileError;
  if (![[NSData alloc] initWithContentsOfURL:URL
                                     options:NSDataReadingMapped
                                       error:&fileError]) {
    if (errorRef != NULL) {
      *errorRef = [FBSDKError invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                        name:name
                                                       value:URL
                                                     message:@"Error reading file"
                                             underlyingError:fileError];
    }
    return NO;
  }
  if (errorRef != NULL) {
    *errorRef = nil;
  }
  return YES;
}

+ (BOOL)validateNetworkURL:(NSURL *)URL name:(NSString *)name error:(NSError *__autoreleasing *)errorRef
{
  if (!URL || [FBSDKInternalUtility isBrowserURL:URL]) {
    if (errorRef != NULL) {
      *errorRef = nil;
    }
    return YES;
  } else {
    if (errorRef != NULL) {
      *errorRef = [FBSDKError invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                        name:name
                                                       value:URL
                                                     message:nil];
    }
    return NO;
  }
}

+ (BOOL)validateRequiredValue:(id)value name:(NSString *)name error:(NSError *__autoreleasing *)errorRef
{
  if (!value
      || ([value isKindOfClass:[NSString class]] && !((NSString *)value).length)
      || ([value isKindOfClass:[NSArray class]] && !((NSArray *)value).count)
      || ([value isKindOfClass:[NSDictionary class]] && !((NSDictionary *)value).count)) {
    if (errorRef != NULL) {
      *errorRef = [FBSDKError requiredArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                         name:name
                                                      message:nil];
    }
    return NO;
  }
  if (errorRef != NULL) {
    *errorRef = nil;
  }
  return YES;
}

+ (BOOL)validateArgumentWithName:(NSString *)argumentName
                           value:(NSUInteger)value
                            isIn:(NSArray<NSNumber *> *)possibleValues
                           error:(NSError *__autoreleasing *)errorRef
{
  for (NSNumber *possibleValue in possibleValues) {
    if (value == possibleValue.unsignedIntegerValue) {
      if (errorRef != NULL) {
        *errorRef = nil;
      }
      return YES;
    }
  }
  if (errorRef != NULL) {
    *errorRef = [FBSDKError invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                      name:argumentName
                                                     value:@(value)
                                                   message:nil];
  }
  return NO;
}

+ (BOOL)_validateAssetLibraryVideoURL:(NSURL *)videoURL name:(NSString *)name error:(NSError *__autoreleasing *)errorRef
{
  if (!videoURL || [videoURL.scheme.lowercaseString isEqualToString:@"assets-library"]) {
    if (errorRef != NULL) {
      *errorRef = nil;
    }
    return YES;
  } else {
    if (errorRef != NULL) {
      *errorRef = [FBSDKError invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                        name:name
                                                       value:videoURL
                                                     message:nil];
    }
    return NO;
  }
}

@end
