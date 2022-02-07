/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKShareCameraEffectContent+Internal.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>
#import <FBSDKShareKit/_FBSDKShareUtility.h>

#import "FBSDKCameraEffectArguments+Internal.h"
#import "FBSDKCameraEffectTextures+Internal.h"
#import "FBSDKHashtag.h"

static NSString *const kFBSDKShareCameraEffectContentEffectIDKey = @"effectID";
static NSString *const kFBSDKShareCameraEffectContentEffectArgumentsKey = @"effectArguments";
static NSString *const kFBSDKShareCameraEffectContentEffectTexturesKey = @"effectTextures";
static NSString *const kFBSDKShareCameraEffectContentContentURLKey = @"contentURL";
static NSString *const kFBSDKShareCameraEffectContentHashtagKey = @"hashtag";
static NSString *const kFBSDKShareCameraEffectContentPeopleIDsKey = @"peopleIDs";
static NSString *const kFBSDKShareCameraEffectContentPlaceIDKey = @"placeID";
static NSString *const kFBSDKShareCameraEffectContentRefKey = @"ref";
static NSString *const kFBSDKShareCameraEffectContentPageIDKey = @"pageID";
static NSString *const kFBSDKShareCameraEffectContentUUIDKey = @"uuid";

@interface FBSDKShareCameraEffectContent ()

@property (class, nonatomic) BOOL hasBeenConfigured;

@end

@implementation FBSDKShareCameraEffectContent

#pragma mark - Instance Properties

@synthesize effectID = _effectID;
@synthesize effectArguments = _effectArguments;
@synthesize effectTextures = _effectTextures;
@synthesize contentURL = _contentURL;
@synthesize hashtag = _hashtag;
@synthesize peopleIDs = _peopleIDs;
@synthesize placeID = _placeID;
@synthesize ref = _ref;
@synthesize pageID = _pageID;
@synthesize shareUUID = _shareUUID;

#pragma mark - Class Properties

static BOOL _hasBeenConfigured = NO;

+ (BOOL)hasBeenConfigured
{
  return _hasBeenConfigured;
}

+ (void)setHasBeenConfigured:(BOOL)hasBeenConfigured
{
  _hasBeenConfigured = hasBeenConfigured;
}

static _Nullable id<FBSDKInternalUtility> _internalUtility;

+ (nullable id<FBSDKInternalUtility>)internalUtility
{
  return _internalUtility;
}

+ (void)setInternalUtility:(nullable id<FBSDKInternalUtility>)internalUtility
{
  _internalUtility = internalUtility;
}

#pragma mark - Class Configuration

+ (void)configureWithInternalUtility:(nonnull id<FBSDKInternalUtility>)internalUtility
{
  self.internalUtility = internalUtility;
  self.hasBeenConfigured = YES;
}

+ (void)configureClassDependencies
{
  if (self.hasBeenConfigured) {
    return;
  }

  [self configureWithInternalUtility:FBSDKInternalUtility.sharedUtility];
}

#if FBTEST

+ (void)resetClassDependencies
{
  self.internalUtility = nil;
  self.hasBeenConfigured = NO;
}

#endif

#pragma mark - Initializer

- (instancetype)init
{
  [self.class configureClassDependencies];

  self = [super init];
  if (self) {
    _shareUUID = [NSUUID UUID].UUIDString;
  }
  return self;
}

#pragma mark - FBSDKSharingContent

- (NSDictionary<NSString *, id> *)addParameters:(NSDictionary<NSString *, id> *)existingParameters
                                  bridgeOptions:(FBSDKShareBridgeOptions)bridgeOptions
{
  NSMutableDictionary<NSString *, id> *updatedParameters = [NSMutableDictionary dictionaryWithDictionary:existingParameters];
  [FBSDKTypeUtility dictionary:updatedParameters
                     setObject:_effectID
                        forKey:@"effect_id"];

  NSString *effectArgumentsJSON;
  if (_effectArguments) {
    effectArgumentsJSON = [FBSDKBasicUtility JSONStringForObject:[_effectArguments allArguments]
                                                           error:NULL
                                            invalidObjectHandler:NULL];
  }
  [FBSDKTypeUtility dictionary:updatedParameters
                     setObject:effectArgumentsJSON
                        forKey:@"effect_arguments"];

  NSData *effectTexturesData;
  if (_effectTextures) {
    // Convert the entire textures dictionary into one NSData, because
    // the existing API protocol only allows one value to be put into the pasteboard.
    NSDictionary<NSString *, UIImage *> *texturesDict = [_effectTextures allTextures];
    NSMutableDictionary<NSString *, NSData *> *texturesDataDict = [NSMutableDictionary dictionaryWithCapacity:texturesDict.count];
    [FBSDKTypeUtility dictionary:texturesDict enumerateKeysAndObjectsUsingBlock:^(NSString *key, UIImage *img, BOOL *stop) {
      // Convert UIImages to NSData, because UIImage is not archivable.
      NSData *imageData = UIImagePNGRepresentation(img);
      if (imageData) {
        texturesDataDict[key] = imageData;
      }
    }];
    effectTexturesData = [NSKeyedArchiver archivedDataWithRootObject:texturesDataDict requiringSecureCoding:YES error:NULL];
  }
  [FBSDKTypeUtility dictionary:updatedParameters
                     setObject:effectTexturesData
                        forKey:@"effect_textures"];

  return updatedParameters;
}

#pragma clang diagnostic pop

#pragma mark - FBSDKSharingValidation

- (BOOL)validateWithOptions:(FBSDKShareBridgeOptions)bridgeOptions error:(NSError *__autoreleasing *)errorRef
{
  if (_effectID.length > 0) {
    NSCharacterSet *nonDigitCharacters = NSCharacterSet.decimalDigitCharacterSet.invertedSet;
    if ([_effectID rangeOfCharacterFromSet:nonDigitCharacters].location != NSNotFound) {
      if (errorRef != NULL) {
        id<FBSDKErrorCreating> errorFactory = [FBSDKErrorFactory new];
        *errorRef = [errorFactory invalidArgumentErrorWithName:@"effectID"
                                                         value:_effectID
                                                       message:@"Invalid value for effectID, effectID can contain only numerical characters."
                                               underlyingError:nil];
      }
      return NO;
    }
  }

  return YES;
}

#pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  if ((self = [self init])) {
    _effectID = [decoder decodeObjectOfClass:NSString.class forKey:kFBSDKShareCameraEffectContentEffectIDKey];
    _effectArguments = [decoder decodeObjectOfClass:FBSDKCameraEffectArguments.class forKey:kFBSDKShareCameraEffectContentEffectArgumentsKey];
    _effectTextures = [decoder decodeObjectOfClass:FBSDKCameraEffectTextures.class forKey:kFBSDKShareCameraEffectContentEffectTexturesKey];
    _contentURL = [decoder decodeObjectOfClass:NSURL.class forKey:kFBSDKShareCameraEffectContentContentURLKey];
    _hashtag = [decoder decodeObjectOfClass:FBSDKHashtag.class forKey:kFBSDKShareCameraEffectContentHashtagKey];
    _peopleIDs = [decoder decodeObjectOfClass:NSArray.class forKey:kFBSDKShareCameraEffectContentPeopleIDsKey];
    _placeID = [decoder decodeObjectOfClass:NSString.class forKey:kFBSDKShareCameraEffectContentPlaceIDKey];
    _ref = [decoder decodeObjectOfClass:NSString.class forKey:kFBSDKShareCameraEffectContentRefKey];
    _pageID = [decoder decodeObjectOfClass:NSString.class forKey:kFBSDKShareCameraEffectContentPageIDKey];
    _shareUUID = [decoder decodeObjectOfClass:NSString.class forKey:kFBSDKShareCameraEffectContentUUIDKey];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:_effectID forKey:kFBSDKShareCameraEffectContentEffectIDKey];
  [encoder encodeObject:_effectArguments forKey:kFBSDKShareCameraEffectContentEffectArgumentsKey];
  [encoder encodeObject:_effectTextures forKey:kFBSDKShareCameraEffectContentEffectTexturesKey];
  [encoder encodeObject:_contentURL forKey:kFBSDKShareCameraEffectContentContentURLKey];
  [encoder encodeObject:_hashtag forKey:kFBSDKShareCameraEffectContentHashtagKey];
  [encoder encodeObject:_peopleIDs forKey:kFBSDKShareCameraEffectContentPeopleIDsKey];
  [encoder encodeObject:_placeID forKey:kFBSDKShareCameraEffectContentPlaceIDKey];
  [encoder encodeObject:_ref forKey:kFBSDKShareCameraEffectContentRefKey];
  [encoder encodeObject:_pageID forKey:kFBSDKShareCameraEffectContentPageIDKey];
  [encoder encodeObject:_shareUUID forKey:kFBSDKShareCameraEffectContentUUIDKey];
}

@end

#endif
