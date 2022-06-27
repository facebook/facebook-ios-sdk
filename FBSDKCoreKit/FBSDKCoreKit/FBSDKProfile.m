/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKProfile+Internal.h"

#import <FBSDKCoreKit/FBSDKSettingsProtocol.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKAccessToken.h"
#import "FBSDKGraphRequestConnecting.h"
#import "FBSDKLocation.h"
#import "FBSDKMath.h"
#import "FBSDKNotificationDelivering.h"
#import "FBSDKNotificationPosting.h"
#import "FBSDKProfileCodingKey.h"
#import "FBSDKURLHosting.h"
#import "FBSDKUnarchiverProvider.h"
#import "FBSDKUserAgeRange.h"

NSNotificationName const FBSDKProfileDidChangeNotification = @"com.facebook.sdk.FBSDKProfile.FBSDKProfileDidChangeNotification";;

NSString *const FBSDKProfileChangeOldKey = @"FBSDKProfileOld";
NSString *const FBSDKProfileChangeNewKey = @"FBSDKProfileNew";
static NSString *const FBSDKProfileUserDefaultsKey = @"com.facebook.sdk.FBSDKProfile.currentProfile";
static FBSDKProfile *g_currentProfile;
static NSDateFormatter *_dateFormatter;

// Once a day
#define FBSDKPROFILE_STALE_IN_SECONDS (60 * 60 * 24)

@interface FBSDKProfile ()

@property (nonatomic, assign) BOOL isLimited;
@property (class, nullable, nonatomic) id<FBSDKSettings> settings;
@property (class, nullable, nonatomic) id<FBSDKURLHosting> urlHoster;
@end

@implementation FBSDKProfile

static Class<FBSDKAccessTokenProviding> _accessTokenProvider = nil;
static id<FBSDKNotificationPosting, FBSDKNotificationDelivering> _notificationCenter = nil;
static id<FBSDKDataPersisting> _dataStore;
static id<FBSDKSettings> _settings;
static id<FBSDKURLHosting> _urlHoster;

+ (nullable id<FBSDKDataPersisting>)dataStore
{
  return _dataStore;
}

+ (void)setDataStore:(nullable id<FBSDKDataPersisting>)dataStore
{
  _dataStore = dataStore;
}

+ (nullable Class<FBSDKAccessTokenProviding>)accessTokenProvider
{
  return _accessTokenProvider;
}

+ (void)setAccessTokenProvider:(nullable Class<FBSDKAccessTokenProviding>)accessTokenProvider
{
  _accessTokenProvider = accessTokenProvider;
}

+ (nullable id<FBSDKSettings>)settings
{
  return _settings;
}

+ (void)setSettings:(nullable id<FBSDKSettings>)settings
{
  _settings = settings;
}

+ (nullable id<FBSDKNotificationPosting, FBSDKNotificationDelivering>)notificationCenter
{
  return _notificationCenter;
}

+ (void)setNotificationCenter:(nullable id<FBSDKNotificationPosting, FBSDKNotificationDelivering>)notificationCenter
{
  _notificationCenter = notificationCenter;
}

+ (nullable id<FBSDKURLHosting>)urlHoster
{
  return _urlHoster;
}

+ (void)setUrlHoster:(nullable id<FBSDKURLHosting>)urlHoster
{
  _urlHoster = urlHoster;
}

- (instancetype)initWithUserID:(FBSDKUserIdentifier)userID
                     firstName:(nullable NSString *)firstName
                    middleName:(nullable NSString *)middleName
                      lastName:(nullable NSString *)lastName
                          name:(nullable NSString *)name
                       linkURL:(nullable NSURL *)linkURL
                   refreshDate:(nullable NSDate *)refreshDate
{
  return [self initWithUserID:userID
                    firstName:firstName
                   middleName:middleName
                     lastName:lastName
                         name:name
                      linkURL:linkURL
                  refreshDate:refreshDate
                     imageURL:nil
                        email:nil
                    friendIDs:nil
                     birthday:nil
                     ageRange:nil
                     hometown:nil
                     location:nil
                       gender:nil];
}

- (instancetype)initWithUserID:(FBSDKUserIdentifier)userID
                     firstName:(nullable NSString *)firstName
                    middleName:(nullable NSString *)middleName
                      lastName:(nullable NSString *)lastName
                          name:(nullable NSString *)name
                       linkURL:(nullable NSURL *)linkURL
                   refreshDate:(nullable NSDate *)refreshDate
                      imageURL:(NSURL *)imageURL
                         email:(NSString *)email
{
  return [self initWithUserID:userID
                    firstName:firstName
                   middleName:middleName
                     lastName:lastName
                         name:name
                      linkURL:linkURL
                  refreshDate:refreshDate
                     imageURL:imageURL
                        email:email
                    friendIDs:nil
                     birthday:nil
                     ageRange:nil
                     hometown:nil
                     location:nil
                       gender:nil];
}

- (instancetype)initWithUserID:(FBSDKUserIdentifier)userID
                     firstName:(nullable NSString *)firstName
                    middleName:(nullable NSString *)middleName
                      lastName:(nullable NSString *)lastName
                          name:(nullable NSString *)name
                       linkURL:(nullable NSURL *)linkURL
                   refreshDate:(nullable NSDate *)refreshDate
                      imageURL:(NSURL *)imageURL
                         email:(NSString *)email
                     friendIDs:(NSArray<FBSDKUserIdentifier> *)friendIDs
{
  return [self initWithUserID:userID
                    firstName:firstName
                   middleName:middleName
                     lastName:lastName
                         name:name
                      linkURL:linkURL
                  refreshDate:refreshDate
                     imageURL:imageURL
                        email:email
                    friendIDs:friendIDs
                     birthday:nil
                     ageRange:nil
                     hometown:nil
                     location:nil
                       gender:nil];
}

- (instancetype)initWithUserID:(FBSDKUserIdentifier)userID
                     firstName:(nullable NSString *)firstName
                    middleName:(nullable NSString *)middleName
                      lastName:(nullable NSString *)lastName
                          name:(nullable NSString *)name
                       linkURL:(nullable NSURL *)linkURL
                   refreshDate:(nullable NSDate *)refreshDate
                      imageURL:(NSURL *)imageURL
                         email:(NSString *)email
                     friendIDs:(NSArray<FBSDKUserIdentifier> *)friendIDs
                      birthday:(NSDate *)birthday
                      ageRange:(FBSDKUserAgeRange *)ageRange
{
  return [self initWithUserID:userID
                    firstName:firstName
                   middleName:middleName
                     lastName:lastName
                         name:name
                      linkURL:linkURL
                  refreshDate:refreshDate
                     imageURL:imageURL
                        email:email
                    friendIDs:friendIDs
                     birthday:birthday
                     ageRange:ageRange
                     hometown:nil
                     location:nil
                       gender:nil];
}

- (instancetype)initWithUserID:(FBSDKUserIdentifier)userID
                     firstName:(nullable NSString *)firstName
                    middleName:(nullable NSString *)middleName
                      lastName:(nullable NSString *)lastName
                          name:(nullable NSString *)name
                       linkURL:(nullable NSURL *)linkURL
                   refreshDate:(nullable NSDate *)refreshDate
                      imageURL:(NSURL *)imageURL
                         email:(NSString *)email
                     friendIDs:(NSArray<FBSDKUserIdentifier> *)friendIDs
                      birthday:(NSDate *)birthday
                      ageRange:(FBSDKUserAgeRange *)ageRange
                     isLimited:(BOOL)isLimited
{
  return [self initWithUserID:userID
                    firstName:firstName
                   middleName:middleName
                     lastName:lastName
                         name:name
                      linkURL:linkURL
                  refreshDate:refreshDate
                     imageURL:imageURL
                        email:email
                    friendIDs:friendIDs
                     birthday:birthday
                     ageRange:ageRange
                     hometown:nil
                     location:nil
                       gender:nil
                    isLimited:isLimited];
}

- (instancetype)initWithUserID:(FBSDKUserIdentifier)userID
                     firstName:(nullable NSString *)firstName
                    middleName:(nullable NSString *)middleName
                      lastName:(nullable NSString *)lastName
                          name:(nullable NSString *)name
                       linkURL:(nullable NSURL *)linkURL
                   refreshDate:(nullable NSDate *)refreshDate
                      imageURL:(nullable NSURL *)imageURL
                         email:(nullable NSString *)email
                     friendIDs:(nullable NSArray<FBSDKUserIdentifier> *)friendIDs
                      birthday:(nullable NSDate *)birthday
                      ageRange:(nullable FBSDKUserAgeRange *)ageRange
                      hometown:(nullable FBSDKLocation *)hometown
                      location:(nullable FBSDKLocation *)location
                        gender:(nullable NSString *)gender
                     isLimited:(BOOL)isLimited
{
  self = [self initWithUserID:userID
                    firstName:firstName
                   middleName:middleName
                     lastName:lastName
                         name:name
                      linkURL:linkURL
                  refreshDate:refreshDate
                     imageURL:imageURL
                        email:email
                    friendIDs:friendIDs
                     birthday:birthday
                     ageRange:ageRange
                     hometown:hometown
                     location:location
                       gender:gender];
  self.isLimited = isLimited;

  return self;
}

- (instancetype)initWithUserID:(FBSDKUserIdentifier)userID
                     firstName:(nullable NSString *)firstName
                    middleName:(nullable NSString *)middleName
                      lastName:(nullable NSString *)lastName
                          name:(nullable NSString *)name
                       linkURL:(nullable NSURL *)linkURL
                   refreshDate:(nullable NSDate *)refreshDate
                      imageURL:(NSURL *)imageURL
                         email:(NSString *)email
                     friendIDs:(NSArray<FBSDKUserIdentifier> *)friendIDs
                      birthday:(NSDate *)birthday
                      ageRange:(FBSDKUserAgeRange *)ageRange
                      hometown:(FBSDKLocation *)hometown
                      location:(FBSDKLocation *)location
                        gender:(NSString *)gender
{
  if ((self = [super init])) {
    _userID = [userID copy];
    _firstName = [firstName copy];
    _middleName = [middleName copy];
    _lastName = [lastName copy];
    _name = [name copy];
    _linkURL = [linkURL copy];
    _refreshDate = [refreshDate copy] ?: [NSDate date];
    _imageURL = [imageURL copy];
    _email = [email copy];
    _friendIDs = [friendIDs copy];
    _isLimited = NO;
    _birthday = [birthday copy];
    _ageRange = [ageRange copy];
    _hometown = [hometown copy];
    _location = [location copy];
    _gender = [gender copy];
  }
  return self;
}

+ (nullable FBSDKProfile *)currentProfile
{
  return g_currentProfile;
}

+ (void)setCurrentProfile:(nullable FBSDKProfile *)profile
{
  [self setCurrentProfile:profile shouldPostNotification:YES];
}

+ (void)setCurrentProfile:(nullable FBSDKProfile *)profile
   shouldPostNotification:(BOOL)shouldPostNotification
{
  if (!profile && !self.currentProfile) {
    return;
  }

  if (![profile isEqual:self.currentProfile]) {
    [self.class cacheProfile:profile];
    NSMutableDictionary<NSString *, id> *userInfo = [NSMutableDictionary dictionary];

    [FBSDKTypeUtility dictionary:userInfo setObject:profile forKey:FBSDKProfileChangeNewKey];
    [FBSDKTypeUtility dictionary:userInfo setObject:self.currentProfile forKey:FBSDKProfileChangeOldKey];
    g_currentProfile = profile;

    if (shouldPostNotification) {
      [self.notificationCenter fb_postNotificationName:FBSDKProfileDidChangeNotification
                                                object:self.class
                                              userInfo:userInfo];
    }
  }
}

- (nullable NSURL *)imageURLForPictureMode:(FBSDKProfilePictureMode)mode size:(CGSize)size
{
  return [FBSDKProfile imageURLForProfileID:self.userID pictureMode:mode size:size];
}

+ (void)enableUpdatesOnAccessTokenChange:(BOOL)enable
{
  if (enable) {
    [self.notificationCenter fb_addObserver:self
                                   selector:@selector(observeChangeAccessTokenChange:)
                                       name:FBSDKAccessTokenDidChangeNotification
                                     object:nil];
  } else {
    [self.notificationCenter fb_removeObserver:self];
  }
}

+ (void)loadCurrentProfileWithCompletion:(nullable FBSDKProfileBlock)completion
{
  [self loadProfileWithToken:[self.accessTokenProvider currentAccessToken] completion:completion];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
  // immutable
  return self;
}

#pragma mark - Equality

- (NSUInteger)hash
{
  NSUInteger subhashes[] = {
    self.userID.hash,
    self.firstName.hash,
    self.middleName.hash,
    self.lastName.hash,
    self.name.hash,
    self.linkURL.hash,
    self.refreshDate.hash,
    self.imageURL.hash,
    self.email.hash,
    self.friendIDs.hash,
    self.birthday.hash,
    self.ageRange.hash,
    self.hometown.hash,
    self.location.hash,
    self.gender.hash,
    self.isLimited
  };
  return [FBSDKMath hashWithIntegerArray:subhashes count:sizeof(subhashes) / sizeof(subhashes[0])];
}

- (BOOL)isEqual:(id)object
{
  if (object == nil) {
    return NO;
  }

  if (self == object) {
    return YES;
  }

  if (![object isKindOfClass:FBSDKProfile.class]) {
    return NO;
  }

  return [self isEqualToProfile:object];
}

- (BOOL)isEqualToProfile:(FBSDKProfile *)profile
{
  return ([self.userID isEqualToString:profile.userID]
    && [self.firstName isEqualToString:profile.firstName]
    && [self.middleName isEqualToString:profile.middleName]
    && [self.lastName isEqualToString:profile.lastName]
    && [self.name isEqualToString:profile.name]
    && [self.linkURL isEqual:profile.linkURL]
    && [self.refreshDate isEqualToDate:profile.refreshDate]
    && [self.imageURL isEqual:profile.imageURL]
    && [self.email isEqualToString:profile.email]
    && [self.friendIDs isEqualToArray:profile.friendIDs]
    && (self.isLimited == profile.isLimited)
    && [self.birthday isEqualToDate:profile.birthday]
    && [self.ageRange isEqual:profile.ageRange]
    && [self.hometown isEqual:profile.hometown]
    && [self.location isEqual:profile.location]
    && [self.gender isEqual:profile.gender]);
}

#pragma mark NSCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  FBSDKUserIdentifier userID = [decoder decodeObjectOfClass:[NSString class] forKey:FBSDKProfileCodingKeyUserID];
  NSString *firstName = [decoder decodeObjectOfClass:NSString.class forKey:FBSDKProfileCodingKeyFirstName];
  NSString *middleName = [decoder decodeObjectOfClass:NSString.class forKey:FBSDKProfileCodingKeyMiddleName];
  NSString *lastName = [decoder decodeObjectOfClass:NSString.class forKey:FBSDKProfileCodingKeyLastName];
  NSString *name = [decoder decodeObjectOfClass:NSString.class forKey:FBSDKProfileCodingKeyName];
  NSURL *linkURL = [decoder decodeObjectOfClass:NSURL.class forKey:FBSDKProfileCodingKeyLinkURL];
  NSDate *refreshDate = [decoder decodeObjectOfClass:NSDate.class forKey:FBSDKProfileCodingKeyRefreshDate];
  NSURL *imageURL = [decoder decodeObjectOfClass:NSURL.class forKey:FBSDKProfileCodingKeyImageURL];
  NSString *email = [decoder decodeObjectOfClass:NSString.class forKey:FBSDKProfileCodingKeyEmail];
  NSArray<FBSDKUserIdentifier> *friendIDs = [decoder decodeObjectOfClass:NSArray.class forKey:FBSDKProfileCodingKeyFriendIDs];
  BOOL isLimited = [decoder decodeBoolForKey:FBSDKProfileCodingKeyIsLimited];
  NSDate *birthday = [decoder decodeObjectOfClass:NSDate.class forKey:FBSDKProfileCodingKeyBirthday];
  FBSDKUserAgeRange *ageRange = [decoder decodeObjectOfClass:FBSDKUserAgeRange.class forKey:FBSDKProfileCodingKeyAgeRange];
  FBSDKLocation *hometown = [decoder decodeObjectOfClass:FBSDKLocation.class forKey:FBSDKProfileCodingKeyHometown];
  FBSDKLocation *location = [decoder decodeObjectOfClass:FBSDKLocation.class forKey:FBSDKProfileCodingKeyLocation];
  NSString *gender = [decoder decodeObjectOfClass:NSString.class forKey:FBSDKProfileCodingKeyGender];
  return [self initWithUserID:userID
                    firstName:firstName
                   middleName:middleName
                     lastName:lastName
                         name:name
                      linkURL:linkURL
                  refreshDate:refreshDate
                     imageURL:imageURL
                        email:email
                    friendIDs:friendIDs
                     birthday:birthday
                     ageRange:ageRange
                     hometown:hometown
                     location:location
                       gender:gender
                    isLimited:isLimited];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:self.userID forKey:FBSDKProfileCodingKeyUserID];
  [encoder encodeObject:self.firstName forKey:FBSDKProfileCodingKeyFirstName];
  [encoder encodeObject:self.middleName forKey:FBSDKProfileCodingKeyMiddleName];
  [encoder encodeObject:self.lastName forKey:FBSDKProfileCodingKeyLastName];
  [encoder encodeObject:self.name forKey:FBSDKProfileCodingKeyName];
  [encoder encodeObject:self.linkURL forKey:FBSDKProfileCodingKeyLinkURL];
  [encoder encodeObject:self.refreshDate forKey:FBSDKProfileCodingKeyRefreshDate];
  [encoder encodeObject:self.imageURL forKey:FBSDKProfileCodingKeyImageURL];
  [encoder encodeObject:self.email forKey:FBSDKProfileCodingKeyEmail];
  [encoder encodeObject:self.friendIDs forKey:FBSDKProfileCodingKeyFriendIDs];
  [encoder encodeBool:self.isLimited forKey:FBSDKProfileCodingKeyIsLimited];
  [encoder encodeObject:self.birthday forKey:FBSDKProfileCodingKeyBirthday];
  [encoder encodeObject:self.ageRange forKey:FBSDKProfileCodingKeyAgeRange];
  [encoder encodeObject:self.hometown forKey:FBSDKProfileCodingKeyHometown];
  [encoder encodeObject:self.location forKey:FBSDKProfileCodingKeyLocation];
  [encoder encodeObject:self.gender forKey:FBSDKProfileCodingKeyGender];
}

+ (void)configureWithDataStore:(id<FBSDKDataPersisting>)dataStore
           accessTokenProvider:(Class<FBSDKAccessTokenProviding>)accessTokenProvider
            notificationCenter:(id<FBSDKNotificationPosting, FBSDKNotificationDelivering>)notificationCenter
                      settings:(id<FBSDKSettings>)settings
                     urlHoster:(id<FBSDKURLHosting>)urlHoster
{
  if (self == FBSDKProfile.class) {
    self.dataStore = dataStore;
    self.accessTokenProvider = accessTokenProvider;
    self.notificationCenter = notificationCenter;
    self.urlHoster = urlHoster;
    self.settings = settings;
  }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
+ (void)cacheProfile:(FBSDKProfile *)profile
{
  if (profile) {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:profile];
    [self.dataStore fb_setObject:data forKey:FBSDKProfileUserDefaultsKey];
  } else {
    [self.dataStore fb_removeObjectForKey:FBSDKProfileUserDefaultsKey];
  }
}

+ (nullable FBSDKProfile *)fetchCachedProfile
{
  NSData *data = [self.dataStore fb_objectForKey:FBSDKProfileUserDefaultsKey];
  if (data != nil) {
    id<FBSDKObjectDecoding> unarchiver = [FBSDKUnarchiverProvider createSecureUnarchiverFor:data];

    @try {
      return [unarchiver decodeObjectOfClass:FBSDKProfile.class forKey:NSKeyedArchiveRootObjectKey];
    } @catch (NSException *exception) {
      // Ignore decode error
    }
  }
  return nil;
}

+ (NSURL *)imageURLForProfileID:(FBSDKUserIdentifier)profileId
                    pictureMode:(FBSDKProfilePictureMode)mode
                           size:(CGSize)size
{
  NSString *const accessTokenKey = @"access_token";
  NSString *const pictureModeKey = @"type";
  NSString *const widthKey = @"width";
  NSString *const heightKey = @"height";

  NSString *type;
  switch (mode) {
    case FBSDKProfilePictureModeNormal: type = @"normal"; break;
    case FBSDKProfilePictureModeSquare: type = @"square"; break;
    case FBSDKProfilePictureModeSmall: type = @"small"; break;
    case FBSDKProfilePictureModeAlbum: type = @"album"; break;
    case FBSDKProfilePictureModeLarge: type = @"large"; break;
    default: type = @"normal";
  }

  NSMutableDictionary<NSString *, id> *queryParameters = [NSMutableDictionary dictionary];
  [FBSDKTypeUtility dictionary:queryParameters setObject:type forKey:pictureModeKey];
  [FBSDKTypeUtility dictionary:queryParameters setObject:@(roundf(size.width)).stringValue forKey:widthKey];
  [FBSDKTypeUtility dictionary:queryParameters setObject:@(roundf(size.height)).stringValue forKey:heightKey];

  if ([self.accessTokenProvider currentAccessToken]) {
    [FBSDKTypeUtility dictionary:queryParameters setObject:[[self.accessTokenProvider currentAccessToken] tokenString]
                          forKey:accessTokenKey];
  } else if (self.settings.clientToken) {
    [FBSDKTypeUtility dictionary:queryParameters setObject:self.settings.clientToken forKey:accessTokenKey];
  } else {
    NSLog(@"As of Graph API v8.0, profile images may not be retrieved without an access token. This can be the current access token from logging in with Facebook or it can be set via the plist or in code. Providing neither will cause this call to return a silhouette image.");
  }

  NSString *path = [NSString stringWithFormat:@"%@/picture", profileId];

  return [self.urlHoster facebookURLWithHostPrefix:@"graph"
                                              path:path
                                   queryParameters:queryParameters
                                             error:NULL];
}

+ (NSString *)graphPathForToken:(FBSDKAccessToken *)token
{
  NSString *graphPath = @"me?fields=id,first_name,middle_name,last_name,name";
  if ([token.permissions containsObject:@"user_link"]) {
    graphPath = [graphPath stringByAppendingString:@",link"];
  }

  if ([token.permissions containsObject:@"email"]) {
    graphPath = [graphPath stringByAppendingString:@",email"];
  }

  if ([token.permissions containsObject:@"user_friends"]) {
    graphPath = [graphPath stringByAppendingString:@",friends"];
  }

  if ([token.permissions containsObject:@"user_birthday"]) {
    graphPath = [graphPath stringByAppendingString:@",birthday"];
  }

  if ([token.permissions containsObject:@"user_age_range"]) {
    graphPath = [graphPath stringByAppendingString:@",age_range"];
  }

  if ([token.permissions containsObject:@"user_hometown"]) {
    graphPath = [graphPath stringByAppendingString:@",hometown"];
  }

  if ([token.permissions containsObject:@"user_location"]) {
    graphPath = [graphPath stringByAppendingString:@",location"];
  }

  if ([token.permissions containsObject:@"user_gender"]) {
    graphPath = [graphPath stringByAppendingString:@",gender"];
  }

  return graphPath;
}

+ (void)loadProfileWithToken:(FBSDKAccessToken *)token completion:(FBSDKProfileBlock)completion
{
  NSString *graphPath = [self.class graphPathForToken:token];
  id<FBSDKGraphRequest> request = [[FBSDKGraphRequest alloc] initWithGraphPath:graphPath
                                                                    parameters:nil
                                                                         flags:FBSDKGraphRequestFlagDoNotInvalidateTokenOnError | FBSDKGraphRequestFlagDisableErrorRecovery];
  [self.class loadProfileWithToken:token graphRequest:request completion:completion];
}

+ (void)loadProfileWithToken:(FBSDKAccessToken *)token
                graphRequest:(id<FBSDKGraphRequest>)request
                  completion:(FBSDKProfileBlock)completion
{
  FBSDKParseProfileBlock parseBlock = ^void (id result, FBSDKProfile **profileRef) {
    if (profileRef == NULL
        || result == nil
        || [FBSDKTypeUtility dictionaryValue:result] == nil) {
      return;
    }

    NSString *profileID = [FBSDKTypeUtility coercedToStringValue:result[@"id"]];
    if (profileID == nil || profileID.length == 0) {
      return;
    }

    NSString *urlString = [FBSDKTypeUtility coercedToStringValue:result[@"link"]];

    NSURL *linkUrl;
    if (urlString) {
      linkUrl = [FBSDKTypeUtility coercedToURLValue:[NSURL URLWithString:urlString]];
    }
    NSArray<FBSDKUserIdentifier> *friendIDs = [self friendIDsFromGraphResult:[FBSDKTypeUtility dictionaryValue:result[@"friends"]]];
    FBSDKUserAgeRange *ageRange = [FBSDKUserAgeRange ageRangeFromDictionary:[FBSDKTypeUtility dictionaryValue:result[@"age_range"]]];

    [FBSDKProfile.dateFormatter setDateFormat:@"MM/dd/yyyy"];
    NSDate *birthday = [FBSDKProfile.dateFormatter dateFromString:[FBSDKTypeUtility coercedToStringValue:result[@"birthday"]]];
    FBSDKLocation *hometown = [FBSDKLocation locationFromDictionary:[FBSDKTypeUtility dictionaryValue:result[@"hometown"]]];
    FBSDKLocation *location = [FBSDKLocation locationFromDictionary:[FBSDKTypeUtility dictionaryValue:result[@"location"]]];
    NSString *gender = [FBSDKTypeUtility coercedToStringValue:result[@"gender"]];

    FBSDKProfile *profile = [[FBSDKProfile alloc] initWithUserID:profileID
                                                       firstName:[FBSDKTypeUtility coercedToStringValue:result[@"first_name"]]
                                                      middleName:[FBSDKTypeUtility coercedToStringValue:result[@"middle_name"]]
                                                        lastName:[FBSDKTypeUtility coercedToStringValue:result[@"last_name"]]
                                                            name:[FBSDKTypeUtility coercedToStringValue:result[@"name"]]
                                                         linkURL:linkUrl
                                                     refreshDate:[NSDate date]
                                                        imageURL:nil
                                                           email:[FBSDKTypeUtility coercedToStringValue:result[@"email"]]
                                                       friendIDs:friendIDs
                                                        birthday:birthday
                                                        ageRange:ageRange
                                                        hometown:hometown
                                                        location:location
                                                          gender:gender];
    *profileRef = [profile copy];
  };
  [self.class loadProfileWithToken:token
                      graphRequest:request
                        completion:completion
                        parseBlock:parseBlock];
}

+ (void)loadProfileWithToken:(FBSDKAccessToken *)token
                graphRequest:(id<FBSDKGraphRequest>)request
                  completion:(FBSDKProfileBlock)completion
                  parseBlock:(FBSDKParseProfileBlock)parseBlock;
{
  static id<FBSDKGraphRequestConnecting> executingRequestConnection = nil;

  BOOL isStale = [[NSDate date] timeIntervalSinceDate:self.currentProfile.refreshDate] > FBSDKPROFILE_STALE_IN_SECONDS;
  if (token
      && (isStale || ![self.currentProfile.userID isEqualToString:token.userID] || self.currentProfile.isLimited)) {
    FBSDKProfile *expectedCurrentProfile = self.currentProfile;

    [executingRequestConnection cancel];
    executingRequestConnection = [request startWithCompletion:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {
      if (expectedCurrentProfile != self.currentProfile) {
        // current profile has already changed since request was started. Let's not overwrite.
        if (completion != NULL) {
          completion(nil, nil);
        }
        return;
      }
      FBSDKProfile *profile = nil;
      if (!error) {
        parseBlock(result, &profile);
      }
      [self.class setCurrentProfile:profile];
      if (completion != NULL) {
        completion(profile, error);
      }
    }];
  } else if (completion != NULL) {
    completion(self.currentProfile, nil);
  }
}

+ (void)observeChangeAccessTokenChange:(NSNotification *)notification
{
  FBSDKAccessToken *token = notification.userInfo[FBSDKAccessTokenChangeNewKey];
  [self loadProfileWithToken:token completion:NULL];
}

+ (nullable NSArray<FBSDKUserIdentifier> *)friendIDsFromGraphResult:(NSDictionary<NSString *, id> *)result
{
  NSArray<NSDictionary<NSString *, id> *> *rawFriends = [FBSDKTypeUtility arrayValue:result[@"data"]];
  NSMutableArray<FBSDKUserIdentifier> *friendIDs = [NSMutableArray new];

  for (NSDictionary<NSString *, id> *rawFriend in rawFriends) {
    if ([FBSDKTypeUtility dictionaryValue:rawFriend]) {
      FBSDKUserIdentifier friendID = [FBSDKTypeUtility coercedToStringValue:rawFriend[@"id"]];
      [FBSDKTypeUtility array:friendIDs addObject:friendID];
    }
  }

  if (friendIDs.count <= 0) {
    return nil;
  }
  return friendIDs;
}

+ (NSDateFormatter *)dateFormatter
{
  if (!_dateFormatter) {
    // @lint-ignore FBOBJCDISCOURAGEDFUNCTION
    _dateFormatter = [NSDateFormatter new];
  }
  return _dateFormatter;
}

#pragma clang diagnostic pop

#if DEBUG

+ (void)resetCurrentProfileCache
{
  self.currentProfile = nil;
}

+ (void)reset
{
  self.dataStore = nil;
  self.accessTokenProvider = nil;
  self.notificationCenter = nil;
  self.urlHoster = nil;
  self.settings = nil;
}

#endif

@end

#endif
