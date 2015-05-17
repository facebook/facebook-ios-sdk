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

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKShareConstants.h"
#import "FBSDKShareError.h"
#import "FBSDKShareLinkContent.h"
#import "FBSDKShareOpenGraphContent.h"
#import "FBSDKShareOpenGraphObject.h"
#import "FBSDKSharePhoto.h"
#import "FBSDKSharePhotoContent.h"
#import "FBSDKShareVideo.h"
#import "FBSDKShareVideoContent.h"
#import "FBSDKSharingContent.h"

@implementation FBSDKShareUtility

#pragma mark - Class Methods

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

+ (void)assertOpenGraphKey:(id)key requireNamespace:(BOOL)requireNamespace
{
  if (![key isKindOfClass:[NSString class]]) {
    NSString *reason = [[NSString alloc] initWithFormat:@"Invalid key found in Open Graph dictionary: %@", key];
    @throw [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
  }
  if (!requireNamespace) {
    return;
  }
  NSArray *components = [key componentsSeparatedByString:@":"];
  if ([components count] < 2) {
    NSString *reason = [[NSString alloc] initWithFormat:@"Open Graph keys must be namespaced: %@", key];
    @throw [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
  }
  for (NSString *component in components) {
    if (![component length]) {
      NSString *reason = [[NSString alloc] initWithFormat:@"Invalid key found in Open Graph dictionary: %@", key];
      @throw [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
    }
  }
}

+ (void)assertOpenGraphValue:(id)value
{
  if ([self _isOpenGraphValue:value]) {
    return;
  }
  if ([value isKindOfClass:[NSDictionary class]]) {
    [self assertOpenGraphValues:(NSDictionary *)value requireKeyNamespace:YES];
    return;
  }
  if ([value isKindOfClass:[NSArray class]]) {
    for (id subValue in (NSArray *)value) {
      [self assertOpenGraphValue:subValue];
    }
    return;
  }
  NSString *reason = [[NSString alloc] initWithFormat:@"Invalid Open Graph value found: %@", value];
  @throw [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
}

+ (void)assertOpenGraphValues:(NSDictionary *)dictionary requireKeyNamespace:(BOOL)requireKeyNamespace
{
  [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
    [self assertOpenGraphKey:key requireNamespace:requireKeyNamespace];
    [self assertOpenGraphValue:value];
  }];
}

+ (BOOL)buildWebShareContent:(id<FBSDKSharingContent>)content
                  methodName:(NSString *__autoreleasing *)methodNameRef
                  parameters:(NSDictionary *__autoreleasing *)parametersRef
                       error:(NSError *__autoreleasing *)errorRef
{
  NSString *methodName = nil;
  NSDictionary *parameters = nil;
  if ([content isKindOfClass:[FBSDKShareOpenGraphContent class]]) {
    methodName = @"share_open_graph";
    FBSDKShareOpenGraphContent *openGraphContent = (FBSDKShareOpenGraphContent *)content;
    FBSDKShareOpenGraphAction *action = openGraphContent.action;
    NSDictionary *properties = [self _convertOpenGraphValueContainer:action requireNamespace:NO];
    NSString *propertiesJSON = [FBSDKInternalUtility JSONStringForObject:properties
                                                                   error:errorRef
                                                    invalidObjectHandler:NULL];
    parameters = @{
                   @"action_type": action.actionType,
                   @"action_properties": propertiesJSON,
                   };
  } else if ([content isKindOfClass:[FBSDKShareLinkContent class]]) {
    FBSDKShareLinkContent *linkContent = (FBSDKShareLinkContent *)content;
    methodName = @"share";
    if (linkContent.contentURL != nil) {
      parameters = @{ @"href": linkContent.contentURL.absoluteString };
    }
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

+ (id)convertOpenGraphValue:(id)value
{
  if ([self _isOpenGraphValue:value]) {
    return value;
  } else if ([value isKindOfClass:[NSDictionary class]]) {
    NSDictionary *properties = (NSDictionary *)value;
    if ([FBSDKTypeUtility stringValue:properties[@"type"]]) {
      return [FBSDKShareOpenGraphObject objectWithProperties:properties];
    } else {
      NSURL *imageURL = [FBSDKTypeUtility URLValue:properties[@"url"]];
      if (imageURL) {
        FBSDKSharePhoto *sharePhoto = [FBSDKSharePhoto photoWithImageURL:imageURL
                                                           userGenerated:[FBSDKTypeUtility boolValue:properties[@"user_generated"]]];
        sharePhoto.caption = [FBSDKTypeUtility stringValue:properties[@"caption"]];
        return sharePhoto;
      } else {
        return nil;
      }
    }
  } else if ([value isKindOfClass:[NSArray class]]) {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (id subValue in (NSArray *)value) {
      [FBSDKInternalUtility array:array addObject:[self convertOpenGraphValue:subValue]];
    }
    return [array copy];
  } else {
    return nil;
  }
}

+ (NSDictionary *)convertOpenGraphValues:(NSDictionary *)dictionary
{
  NSMutableDictionary *convertedDictionary = [[NSMutableDictionary alloc] init];
  [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    [FBSDKInternalUtility dictionary:convertedDictionary setObject:[self convertOpenGraphValue:obj] forKey:key];
  }];
  return [convertedDictionary copy];
}

+ (NSDictionary *)feedShareDictionaryForContent:(id<FBSDKSharingContent>)content
{
  NSMutableDictionary *parameters = nil;
  if ([content isKindOfClass:[FBSDKShareLinkContent class]]) {
    FBSDKShareLinkContent *linkContent = (FBSDKShareLinkContent *)content;
    parameters = [[NSMutableDictionary alloc] init];
    [FBSDKInternalUtility dictionary:parameters setObject:linkContent.contentDescription forKey:@"description"];
    [FBSDKInternalUtility dictionary:parameters setObject:linkContent.contentURL forKey:@"link"];
    [FBSDKInternalUtility dictionary:parameters setObject:linkContent.contentTitle forKey:@"name"];
    [FBSDKInternalUtility dictionary:parameters setObject:linkContent.imageURL forKey:@"picture"];
    [FBSDKInternalUtility dictionary:parameters setObject:linkContent.ref forKey:@"ref"];
  }
  return [parameters copy];
}

+ (NSDictionary *)parametersForShareContent:(id<FBSDKSharingContent>)shareContent
                      shouldFailOnDataError:(BOOL)shouldFailOnDataError
{
  NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
  [self _addToParameters:parameters forShareContent:shareContent];
  parameters[@"dataFailuresFatal"] = @(shouldFailOnDataError);
  if ([shareContent isKindOfClass:[FBSDKShareLinkContent class]]) {
    [self _addToParameters:parameters forShareLinkContent:(FBSDKShareLinkContent *)shareContent];
  } else if ([shareContent isKindOfClass:[FBSDKSharePhotoContent class]]) {
    [self _addToParameters:parameters forSharePhotoContent:(FBSDKSharePhotoContent *)shareContent];
  } else if ([shareContent isKindOfClass:[FBSDKShareVideoContent class]]) {
    [self _addToParameters:parameters forShareVideoContent:(FBSDKShareVideoContent *)shareContent];
  } else if ([shareContent isKindOfClass:[FBSDKShareOpenGraphContent class]]) {
    [self _addToParameters:parameters forShareOpenGraphContent:(FBSDKShareOpenGraphContent *)shareContent];
  }
  return [parameters copy];
}

+ (void)testShareContent:(id<FBSDKSharingContent>)shareContent
           containsMedia:(BOOL *)containsMediaRef
          containsPhotos:(BOOL *)containsPhotosRef
{
  BOOL containsMedia = NO;
  BOOL containsPhotos = NO;
  if ([shareContent isKindOfClass:[FBSDKShareLinkContent class]]) {
    containsMedia = NO;
    containsPhotos = NO;
  } else if ([shareContent isKindOfClass:[FBSDKShareVideoContent class]]) {
    containsMedia = YES;
    containsPhotos = NO;
  } else if ([shareContent isKindOfClass:[FBSDKSharePhotoContent class]]) {
    [self _testObject:((FBSDKSharePhotoContent *)shareContent).photos
        containsMedia:&containsMedia
       containsPhotos:&containsPhotos];
  } else if ([shareContent isKindOfClass:[FBSDKShareOpenGraphContent class]]) {
    [self _testOpenGraphValueContainer:((FBSDKShareOpenGraphContent *)shareContent).action
                         containsMedia:&containsMedia
                        containsPhotos:&containsPhotos];
  }
  if (containsMediaRef != NULL) {
    *containsMediaRef = containsMedia;
  }
  if (containsPhotosRef != NULL) {
    *containsPhotosRef = containsPhotos;
  }
}

+ (BOOL)validateAppInviteContent:(FBSDKAppInviteContent *)appInviteContent error:(NSError *__autoreleasing *)errorRef
{
  return ([self _validateRequiredValue:appInviteContent name:@"content" error:errorRef] &&
          [self _validateRequiredValue:appInviteContent.appLinkURL name:@"appLinkURL" error:errorRef] &&
          [self _validateNetworkURL:appInviteContent.appLinkURL name:@"appLinkURL" error:errorRef] &&
          [self _validateNetworkURL:appInviteContent.previewImageURL name:@"previewImageURL" error:errorRef]);
}

+ (BOOL)validateGameRequestContent:(FBSDKGameRequestContent *)gameRequestContent error:(NSError *__autoreleasing *)errorRef
{
  if (![self _validateRequiredValue:gameRequestContent name:@"content" error:errorRef]
      || ![self _validateRequiredValue:gameRequestContent.message name:@"message" error:errorRef]) {
    return NO;
  }
  BOOL mustHaveobjectID = gameRequestContent.actionType == FBSDKGameRequestActionTypeSend
  || gameRequestContent.actionType == FBSDKGameRequestActionTypeAskFor;
  BOOL hasobjectID = [gameRequestContent.objectID length] > 0;
  if (mustHaveobjectID ^ hasobjectID) {
    if (errorRef != NULL) {
      NSString *message = @"The objectID is required when the actionType is either send or askfor.";
      *errorRef = [FBSDKShareError requiredArgumentErrorWithName:@"objectID" message:message];
    }
    return NO;
  }
  BOOL hasTo = [gameRequestContent.to count] > 0;
  BOOL hasFilters = gameRequestContent.filters != FBSDKGameRequestFilterNone;
  BOOL hasSuggestions = [gameRequestContent.suggestions count] > 0;
  if (hasTo && hasFilters) {
    if (errorRef != NULL) {
      NSString *message = @"Cannot specify to and filters at the same time.";
      *errorRef = [FBSDKShareError invalidArgumentErrorWithName:@"to" value:gameRequestContent.to message:message];
    }
    return NO;
  }
  if (hasTo && hasSuggestions) {
    if (errorRef != NULL) {
      NSString *message = @"Cannot specify to and suggestions at the same time.";
      *errorRef = [FBSDKShareError invalidArgumentErrorWithName:@"to" value:gameRequestContent.to message:message];
    }
    return NO;
  }

  if (hasFilters && hasSuggestions) {
    if (errorRef != NULL) {
      NSString *message = @"Cannot specify filters and suggestions at the same time.";
      *errorRef = [FBSDKShareError invalidArgumentErrorWithName:@"suggestions" value:gameRequestContent.suggestions message:message];
    }
    return NO;
  }

  if ([gameRequestContent.data length] > 255) {
    if (errorRef != NULL) {
      NSString *message = @"The data cannot be longer than 255 characters";
      *errorRef = [FBSDKShareError invalidArgumentErrorWithName:@"data" value:gameRequestContent.data message:message];
    }
    return NO;
  }

  if (errorRef != NULL) {
    *errorRef = nil;
  }

  return [self _validateArgumentWithName:@"actionType"
                                   value:gameRequestContent.actionType
                                    isIn:@[@(FBSDKGameRequestActionTypeNone),
                                           @(FBSDKGameRequestActionTypeSend),
                                           @(FBSDKGameRequestActionTypeAskFor),
                                           @(FBSDKGameRequestActionTypeTurn)]
                                   error:errorRef]
  && [self _validateArgumentWithName:@"filters"
                               value:gameRequestContent.filters
                                isIn:@[@(FBSDKGameRequestFilterNone),
                                       @(FBSDKGameRequestFilterAppUsers),
                                       @(FBSDKGameRequestFilterAppNonUsers)]
                               error:errorRef];
}

+ (BOOL)validateShareContent:(id<FBSDKSharingContent>)shareContent error:(NSError *__autoreleasing *)errorRef
{
  if (![self _validateRequiredValue:shareContent name:@"shareContent" error:errorRef]) {
    return NO;
  } else if ([shareContent isKindOfClass:[FBSDKShareLinkContent class]]) {
    return [self validateShareLinkContent:(FBSDKShareLinkContent *)shareContent error:errorRef];
  } else if ([shareContent isKindOfClass:[FBSDKSharePhotoContent class]]) {
    return [self validateSharePhotoContent:(FBSDKSharePhotoContent *)shareContent error:errorRef];
  } else if ([shareContent isKindOfClass:[FBSDKShareVideoContent class]]) {
    return [self validateShareVideoContent:(FBSDKShareVideoContent *)shareContent error:errorRef];
  } else if ([shareContent isKindOfClass:[FBSDKShareOpenGraphContent class]]) {
    return [self validateShareOpenGraphContent:(FBSDKShareOpenGraphContent *)shareContent error:errorRef];
  } else {
    if (errorRef != NULL) {
      *errorRef = [FBSDKShareError invalidArgumentErrorWithName:@"shareContent" value:shareContent message:nil];
    }
    return NO;
  }
}

+ (BOOL)validateShareOpenGraphContent:(FBSDKShareOpenGraphContent *)openGraphContent
                                error:(NSError *__autoreleasing *)errorRef
{
  FBSDKShareOpenGraphAction *action = openGraphContent.action;
  NSString *previewPropertyName = openGraphContent.previewPropertyName;
  id object = action[previewPropertyName];
  return ([self _validateRequiredValue:openGraphContent name:@"shareContent" error:errorRef] &&
          [self _validateRequiredValue:action name:@"action" error:errorRef] &&
          [self _validateRequiredValue:previewPropertyName name:@"previewPropertyName" error:errorRef] &&
          [self _validateRequiredValue:object name:previewPropertyName error:errorRef]);
}

+ (BOOL)validateSharePhotoContent:(FBSDKSharePhotoContent *)photoContent error:(NSError *__autoreleasing *)errorRef
{
  NSArray *photos = photoContent.photos;
  if (![self _validateRequiredValue:photoContent name:@"shareContent" error:errorRef] ||
      ![self _validateArray:photos minCount:1 maxCount:6 name:@"photos" error:errorRef]) {
    return NO;
  }
  for (FBSDKSharePhoto *photo in photos) {
    if (!photo.image) {
      if (errorRef != NULL) {
        *errorRef = [FBSDKShareError invalidArgumentErrorWithName:@"photos"
                                                            value:photos
                                                          message:@"photos must have UIImages"];
      }
      return NO;
    }
  }
  return YES;
}

+ (BOOL)validateShareLinkContent:(FBSDKShareLinkContent *)linkContent error:(NSError *__autoreleasing *)errorRef
{
  return ([self _validateRequiredValue:linkContent name:@"shareContent" error:errorRef] &&
          [self _validateNetworkURL:linkContent.contentURL name:@"contentURL" error:errorRef] &&
          [self _validateNetworkURL:linkContent.imageURL name:@"imageURL" error:errorRef]);
}

+ (BOOL)validateShareVideoContent:(FBSDKShareVideoContent *)videoContent error:(NSError *__autoreleasing *)errorRef
{
  FBSDKShareVideo *video = videoContent.video;
  NSURL *videoURL = video.videoURL;
  return ([self _validateRequiredValue:videoContent name:@"videoContent" error:errorRef] &&
          [self _validateRequiredValue:video name:@"video" error:errorRef] &&
          [self _validateRequiredValue:videoURL name:@"videoURL" error:errorRef] &&
          [self _validateAssetLibraryURL:videoURL name:@"videoURL" error:errorRef]);
}

#pragma mark - Object Lifecycle

- (instancetype)init
{
  FBSDK_NO_DESIGNATED_INITIALIZER();
  return nil;
}

#pragma mark - Helper Methods

+ (void)_addToParameters:(NSMutableDictionary *)parameters forShareContent:(id<FBSDKSharingContent>)shareContent
{
  [FBSDKInternalUtility dictionary:parameters setObject:shareContent.peopleIDs forKey:@"tags"];
  [FBSDKInternalUtility dictionary:parameters setObject:shareContent.placeID forKey:@"place"];
  [FBSDKInternalUtility dictionary:parameters setObject:shareContent.ref forKey:@"ref"];
}

+ (void)_addToParameters:(NSMutableDictionary *)parameters
forShareOpenGraphContent:(FBSDKShareOpenGraphContent *)openGraphContent
{
  NSString *previewPropertyName = [self getOpenGraphNameAndNamespaceFromFullName:openGraphContent.previewPropertyName namespace:nil];
  [FBSDKInternalUtility dictionary:parameters
                         setObject:previewPropertyName
                            forKey:@"previewPropertyName"];
  [FBSDKInternalUtility dictionary:parameters setObject:openGraphContent.action.actionType forKey:@"actionType"];
  [FBSDKInternalUtility dictionary:parameters
                         setObject:[self _convertOpenGraphValueContainer:openGraphContent.action requireNamespace:NO]
                            forKey:@"action"];
}

+ (void)_addToParameters:(NSMutableDictionary *)parameters
    forSharePhotoContent:(FBSDKSharePhotoContent *)photoContent
{
  [FBSDKInternalUtility dictionary:parameters
                         setObject:[photoContent.photos valueForKeyPath:@"image"]
                            forKey:@"photos"];
}

+ (void)_addToParameters:(NSMutableDictionary *)parameters
     forShareLinkContent:(FBSDKShareLinkContent *)linkContent
{
  [FBSDKInternalUtility dictionary:parameters setObject:linkContent.contentURL forKey:@"link"];
  [FBSDKInternalUtility dictionary:parameters setObject:linkContent.contentTitle forKey:@"name"];
  [FBSDKInternalUtility dictionary:parameters setObject:linkContent.contentDescription forKey:@"description"];
  [FBSDKInternalUtility dictionary:parameters setObject:linkContent.imageURL forKey:@"picture"];
}

+ (void)_addToParameters:(NSMutableDictionary *)parameters
    forShareVideoContent:(FBSDKShareVideoContent *)videoContent
{
  NSMutableDictionary *videoParameters = [[NSMutableDictionary alloc] init];
  FBSDKShareVideo *video = videoContent.video;
  NSURL *videoURL = video.videoURL;
  if (videoURL) {
    videoParameters[@"assetURL"] = videoURL;
  }
  [FBSDKInternalUtility dictionary:videoParameters
                         setObject:[self _convertPhoto:videoContent.previewPhoto]
                            forKey:@"previewPhoto"];
  parameters[@"video"] = videoParameters;
}

+ (id)_convertObject:(id)object
{
  if ([object isKindOfClass:[FBSDKShareOpenGraphValueContainer class]]) {
    object = [self _convertOpenGraphValueContainer:(FBSDKShareOpenGraphValueContainer *)object requireNamespace:YES];
  } else if ([object isKindOfClass:[FBSDKSharePhoto class]]) {
    object = [self _convertPhoto:(FBSDKSharePhoto *)object];
  } else if ([object isKindOfClass:[NSArray class]]) {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (id item in (NSArray *)object) {
      [FBSDKInternalUtility array:array addObject:[self _convertObject:item]];
    }
    object = array;
  }
  return object;
}

+ (NSDictionary *)_convertOpenGraphValueContainer:(FBSDKShareOpenGraphValueContainer *)container
                                 requireNamespace:(BOOL)requireNamespace
{
  NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
  NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
  [container enumerateKeysAndObjectsUsingBlock:^(NSString *key, id object, BOOL *stop) {
    // if we have an FBSDKShareOpenGraphObject and a type, then we are creating a new object instance; set the flag
    if ([key isEqualToString:@"og:type"] && [container isKindOfClass:[FBSDKShareOpenGraphObject class]]) {
      dictionary[@"fbsdk:create_object"] = @YES;
    }
    id value = [self _convertObject:object];
    if (value) {
      NSString *namespace;
      key = [self getOpenGraphNameAndNamespaceFromFullName:key namespace:&namespace];

      if (requireNamespace) {
        if ([namespace isEqualToString:@"og"]) {
          dictionary[key] = value;
        } else {
          data[key] = value;
        }
      } else {
        dictionary[key] = value;
      }
    }
  }];
  if ([data count]) {
    dictionary[@"data"] = data;
  }
  return dictionary;
}

+ (NSString *)getOpenGraphNameAndNamespaceFromFullName:(NSString *)fullName namespace:(NSString **)namespace {
  if (namespace) {
    *namespace = nil;
  }

  if ([fullName isEqualToString:@"fb:explicitly_shared"]) {
    return fullName;
  }

  NSUInteger index = [fullName rangeOfString:@":"].location;
  if ((index != NSNotFound) && (fullName.length > index + 1)) {
    if (namespace) {
      *namespace = [fullName substringToIndex:index];
    }

    return [fullName substringFromIndex:index + 1];
  }

  return fullName;
}

+ (NSDictionary *)_convertPhoto:(FBSDKSharePhoto *)photo
{
  if (!photo) {
    return nil;
  }
  NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
  dictionary[@"user_generated"] = @(photo.userGenerated);
  [FBSDKInternalUtility dictionary:dictionary setObject:photo.caption forKey:@"caption"];

  [FBSDKInternalUtility dictionary:dictionary setObject:photo.image ?: photo.imageURL.absoluteString forKey:@"url"];
  return dictionary;
}

+ (BOOL)_isOpenGraphValue:(id)value
{
  return ((value == nil) ||
          [value isKindOfClass:[NSNull class]] ||
          [value isKindOfClass:[NSNumber class]] ||
          [value isKindOfClass:[NSString class]] ||
          [value isKindOfClass:[NSURL class]] ||
          [value isKindOfClass:[FBSDKSharePhoto class]] ||
          [value isKindOfClass:[FBSDKShareOpenGraphObject class]]);
}

+ (void)_testObject:(id)object containsMedia:(BOOL *)containsMediaRef containsPhotos:(BOOL *)containsPhotosRef
{
  BOOL containsMedia = NO;
  BOOL containsPhotos = NO;
  if ([object isKindOfClass:[FBSDKSharePhoto class]]) {
    containsMedia = (((FBSDKSharePhoto *)object).image != nil);
    containsPhotos = YES;
  } else if ([object isKindOfClass:[FBSDKShareOpenGraphValueContainer class]]) {
    [self _testOpenGraphValueContainer:(FBSDKShareOpenGraphValueContainer *)object
                         containsMedia:&containsMedia
                        containsPhotos:&containsPhotos];
  } else if ([object isKindOfClass:[NSArray class]]) {
    for (id item in (NSArray *)object) {
      BOOL itemContainsMedia = NO;
      BOOL itemContainsPhotos = NO;
      [self _testObject:item containsMedia:&itemContainsMedia containsPhotos:&itemContainsPhotos];
      containsMedia |= itemContainsMedia;
      containsPhotos |= itemContainsPhotos;
      if (containsMedia && containsPhotos) {
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
}

+ (void)_testOpenGraphValueContainer:(FBSDKShareOpenGraphValueContainer *)container
                       containsMedia:(BOOL *)containsMediaRef
                      containsPhotos:(BOOL *)containsPhotosRef
{
  __block BOOL containsMedia = NO;
  __block BOOL containsPhotos = NO;
  [container enumerateKeysAndObjectsUsingBlock:^(NSString *key, id object, BOOL *stop) {
    BOOL itemContainsMedia = NO;
    BOOL itemContainsPhotos = NO;
    [self _testObject:object containsMedia:&itemContainsMedia containsPhotos:&itemContainsPhotos];
    containsMedia |= itemContainsMedia;
    containsPhotos |= itemContainsPhotos;
    if (containsMedia && containsPhotos) {
      *stop = YES;
    }
  }];
  if (containsMediaRef != NULL) {
    *containsMediaRef = containsMedia;
  }
  if (containsPhotosRef != NULL) {
    *containsPhotosRef = containsPhotos;
  }
}

+ (BOOL)_validateArray:(NSArray *)array
              minCount:(NSUInteger)minCount
              maxCount:(NSUInteger)maxCount
                  name:(NSString *)name
                 error:(NSError *__autoreleasing *)errorRef
{
  NSUInteger count = [array count];
  if ((count < minCount) || (count > maxCount)) {
    if (errorRef != NULL) {
      NSString *message = [[NSString alloc] initWithFormat:@"%@ must have %lu to %lu values",
                           name,
                           (unsigned long)minCount,
                           (unsigned long)maxCount];
      *errorRef = [FBSDKShareError invalidArgumentErrorWithName:name value:array message:message];
    }
    return NO;
  } else {
    if (errorRef != NULL) {
      *errorRef = nil;
    }
    return YES;
  }
}

+ (BOOL)_validateAssetLibraryURL:(NSURL *)URL name:(NSString *)name error:(NSError *__autoreleasing *)errorRef
{
  if (!URL || [[URL.scheme lowercaseString] isEqualToString:@"assets-library"]) {
    if (errorRef != NULL) {
      *errorRef = nil;
    }
    return YES;
  } else {
    if (errorRef != NULL) {
      *errorRef = [FBSDKShareError invalidArgumentErrorWithName:name value:URL message:nil];
    }
    return NO;
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
      *errorRef = [FBSDKShareError invalidArgumentErrorWithName:name value:URL message:nil];
    }
    return NO;
  }
  // ensure that the file exists.  per the latest spec for NSFileManager, we should not be checking for file existance,
  // so they have removed that option for URLs and discourage it for paths, so we just construct a mapped NSData.
  NSError *fileError;
  if (![[NSData alloc] initWithContentsOfURL:URL
                                     options:NSDataReadingMapped
                                       error:&fileError]) {
    if (errorRef != NULL) {
      *errorRef = [FBSDKShareError invalidArgumentErrorWithName:name
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

+ (BOOL)_validateNetworkURL:(NSURL *)URL name:(NSString *)name error:(NSError *__autoreleasing *)errorRef
{
  if (!URL || [FBSDKInternalUtility isBrowserURL:URL]) {
    if (errorRef != NULL) {
      *errorRef = nil;
    }
    return YES;
  } else {
    if (errorRef != NULL) {
      *errorRef = [FBSDKShareError invalidArgumentErrorWithName:name value:URL message:nil];
    }
    return NO;
  }
}

+ (BOOL)_validateRequiredValue:(id)value name:(NSString *)name error:(NSError *__autoreleasing *)errorRef
{
  if (!value ||
      ([value isKindOfClass:[NSString class]] && ![(NSString *)value length]) ||
      ([value isKindOfClass:[NSArray class]] && ![(NSArray *)value count]) ||
      ([value isKindOfClass:[NSDictionary class]] && ![(NSDictionary *)value count])) {
    if (errorRef != NULL) {
      *errorRef = [FBSDKShareError requiredArgumentErrorWithName:name message:nil];
    }
    return NO;
  }
  if (errorRef != NULL) {
    *errorRef = nil;
  }
  return YES;
}

+ (BOOL)_validateArgumentWithName:(NSString *)argumentName
                            value:(NSUInteger)value
                             isIn:(NSArray *)possibleValues
                            error:(NSError *__autoreleasing *)errorRef
{
  for (NSNumber *possibleValue in possibleValues) {
    if (value == [possibleValue unsignedIntegerValue]) {
      if (errorRef != NULL) {
        *errorRef = nil;
      }
      return YES;
    }
  }
  if (errorRef != NULL) {
    *errorRef = [FBSDKShareError invalidArgumentErrorWithName:argumentName value:@(value) message:nil];
  }
  return NO;
}

@end
