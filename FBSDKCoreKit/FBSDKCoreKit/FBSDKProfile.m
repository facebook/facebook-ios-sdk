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

#import "FBSDKNotificationProtocols.h"
#import "TargetConditionals.h"

#if !TARGET_OS_TV

 #import "FBSDKProfile+Internal.h"

 #import "FBSDKUserAgeRange.h"

 #if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0

NSNotificationName const FBSDKProfileDidChangeNotification = @"com.facebook.sdk.FBSDKProfile.FBSDKProfileDidChangeNotification";;

 #else

NSString *const FBSDKProfileDidChangeNotification = @"com.facebook.sdk.FBSDKProfile.FBSDKProfileDidChangeNotification";;

 #endif

NSString *const FBSDKProfileChangeOldKey = @"FBSDKProfileOld";
NSString *const FBSDKProfileChangeNewKey = @"FBSDKProfileNew";
static NSString *const FBSDKProfileUserDefaultsKey = @"com.facebook.sdk.FBSDKProfile.currentProfile";
static FBSDKProfile *g_currentProfile;
static NSDateFormatter *_dateFormatter;

 #define FBSDKPROFILE_USERID_KEY @"userID"
 #define FBSDKPROFILE_FIRSTNAME_KEY @"firstName"
 #define FBSDKPROFILE_MIDDLENAME_KEY @"middleName"
 #define FBSDKPROFILE_LASTNAME_KEY @"lastName"
 #define FBSDKPROFILE_NAME_KEY @"name"
 #define FBSDKPROFILE_LINKURL_KEY @"linkURL"
 #define FBSDKPROFILE_REFRESHDATE_KEY @"refreshDate"
 #define FBSDKPROFILE_IMAGEURL_KEY @"imageURL"
 #define FBSDKPROFILE_EMAIL_KEY @"email"
 #define FBSDKPROFILE_FRIENDIDS_KEY @"friendIDs"
 #define FBSDKPROFILE_IS_LIMITED_KEY @"isLimited"
 #define FBSDKPROFILE_BIRTHDAY_KEY @"birthday"
 #define FBSDKPROFILE_AGERANGE_KEY @"ageRange"

// Once a day
 #define FBSDKPROFILE_STALE_IN_SECONDS (60 * 60 * 24)

@interface FBSDKProfile ()

@property (nonatomic, assign) BOOL isLimited;

@end

@implementation FBSDKProfile

static Class<FBSDKAccessTokenProviding> _accessTokenProvider = nil;
static id<FBSDKNotificationPosting, FBSDKNotificationObserving> _notificationCenter = nil;

+ (Class<FBSDKAccessTokenProviding>)accessTokenProvider
{
  return _accessTokenProvider;
}

+ (id<FBSDKNotificationPosting, FBSDKNotificationObserving>)notificationCenter
{
  return _notificationCenter;
}

- (instancetype)initWithUserID:(FBSDKUserIdentifier *)userID
                     firstName:(NSString *)firstName
                    middleName:(NSString *)middleName
                      lastName:(NSString *)lastName
                          name:(NSString *)name
                       linkURL:(NSURL *)linkURL
                   refreshDate:(NSDate *)refreshDate
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
                     ageRange:nil];
}

- (instancetype)initWithUserID:(FBSDKUserIdentifier *)userID
                     firstName:(NSString *)firstName
                    middleName:(NSString *)middleName
                      lastName:(NSString *)lastName
                          name:(NSString *)name
                       linkURL:(NSURL *)linkURL
                   refreshDate:(NSDate *)refreshDate
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
                     ageRange:nil];
}

- (instancetype)initWithUserID:(FBSDKUserIdentifier *)userID
                     firstName:(NSString *)firstName
                    middleName:(NSString *)middleName
                      lastName:(NSString *)lastName
                          name:(NSString *)name
                       linkURL:(NSURL *)linkURL
                   refreshDate:(NSDate *)refreshDate
                      imageURL:(NSURL *)imageURL
                         email:(NSString *)email
                     friendIDs:(NSArray<FBSDKUserIdentifier *> *)friendIDs
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
                     birthday:nil ageRange:nil];
}

- (instancetype)initWithUserID:(FBSDKUserIdentifier *)userID
                     firstName:(NSString *)firstName
                    middleName:(NSString *)middleName
                      lastName:(NSString *)lastName
                          name:(NSString *)name
                       linkURL:(NSURL *)linkURL
                   refreshDate:(NSDate *)refreshDate
                      imageURL:(NSURL *)imageURL
                         email:(NSString *)email
                     friendIDs:(NSArray<FBSDKUserIdentifier *> *)friendIDs
                      birthday:(NSDate *)birthday
                      ageRange:(FBSDKUserAgeRange *)ageRange
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
                     ageRange:ageRange];
  self.isLimited = isLimited;

  return self;
}

- (instancetype)initWithUserID:(FBSDKUserIdentifier *)userID
                     firstName:(NSString *)firstName
                    middleName:(NSString *)middleName
                      lastName:(NSString *)lastName
                          name:(NSString *)name
                       linkURL:(NSURL *)linkURL
                   refreshDate:(NSDate *)refreshDate
                      imageURL:(NSURL *)imageURL
                         email:(NSString *)email
                     friendIDs:(NSArray<FBSDKUserIdentifier *> *)friendIDs
                      birthday:(NSDate *)birthday
                      ageRange:(FBSDKUserAgeRange *)ageRange
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
    self.isLimited = NO;
    _birthday = [birthday copy];
    _ageRange = [ageRange copy];
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
  if (profile != g_currentProfile && ![profile isEqualToProfile:g_currentProfile]) {
    [[self class] cacheProfile:profile];
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];

    [FBSDKTypeUtility dictionary:userInfo setObject:profile forKey:FBSDKProfileChangeNewKey];
    [FBSDKTypeUtility dictionary:userInfo setObject:g_currentProfile forKey:FBSDKProfileChangeOldKey];
    g_currentProfile = profile;

    if (shouldPostNotification) {
      [_notificationCenter postNotificationName:FBSDKProfileDidChangeNotification
                                         object:[self class]
                                       userInfo:userInfo];
    }
  }
}

- (NSURL *)imageURLForPictureMode:(FBSDKProfilePictureMode)mode size:(CGSize)size
{
  return [FBSDKProfile imageURLForProfileID:_userID PictureMode:mode size:size];
}

+ (void)enableUpdatesOnAccessTokenChange:(BOOL)enable
{
  if (enable) {
    [_notificationCenter addObserver:self
                            selector:@selector(observeChangeAccessTokenChange:)
                                name:FBSDKAccessTokenDidChangeNotification
                              object:nil];
  } else {
    [_notificationCenter removeObserver:self];
  }
}

+ (void)loadCurrentProfileWithCompletion:(FBSDKProfileBlock)completion
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
    self.isLimited
  };
  return [FBSDKMath hashWithIntegerArray:subhashes count:sizeof(subhashes) / sizeof(subhashes[0])];
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:[FBSDKProfile class]]) {
    return NO;
  }
  return [self isEqualToProfile:object];
}

- (BOOL)isEqualToProfile:(FBSDKProfile *)profile
{
  return ([_userID isEqualToString:profile.userID]
    && [_firstName isEqualToString:profile.firstName]
    && [_middleName isEqualToString:profile.middleName]
    && [_lastName isEqualToString:profile.lastName]
    && [_name isEqualToString:profile.name]
    && [_linkURL isEqual:profile.linkURL]
    && [_refreshDate isEqualToDate:profile.refreshDate]
    && [_imageURL isEqual:profile.imageURL]
    && [_email isEqualToString:profile.email]
    && [_friendIDs isEqualToArray:profile.friendIDs]
    && _isLimited == profile.isLimited
    && [_birthday isEqualToDate:profile.birthday]
    && [_ageRange isEqual:profile.ageRange]);
}

 #pragma mark NSCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  FBSDKUserIdentifier *userID = [decoder decodeObjectOfClass:[FBSDKUserIdentifier class] forKey:FBSDKPROFILE_USERID_KEY];
  NSString *firstName = [decoder decodeObjectOfClass:[NSString class] forKey:FBSDKPROFILE_FIRSTNAME_KEY];
  NSString *middleName = [decoder decodeObjectOfClass:[NSString class] forKey:FBSDKPROFILE_MIDDLENAME_KEY];
  NSString *lastName = [decoder decodeObjectOfClass:[NSString class] forKey:FBSDKPROFILE_LASTNAME_KEY];
  NSString *name = [decoder decodeObjectOfClass:[NSString class] forKey:FBSDKPROFILE_NAME_KEY];
  NSURL *linkURL = [decoder decodeObjectOfClass:[NSURL class] forKey:FBSDKPROFILE_LINKURL_KEY];
  NSDate *refreshDate = [decoder decodeObjectOfClass:[NSDate class] forKey:FBSDKPROFILE_REFRESHDATE_KEY];
  NSURL *imageURL = [decoder decodeObjectOfClass:[NSURL class] forKey:FBSDKPROFILE_IMAGEURL_KEY];
  NSString *email = [decoder decodeObjectOfClass:[NSString class] forKey:FBSDKPROFILE_EMAIL_KEY];
  NSArray<FBSDKUserIdentifier *> *friendIDs = [decoder decodeObjectOfClass:[NSArray class] forKey:FBSDKPROFILE_FRIENDIDS_KEY];
  BOOL isLimited = [decoder decodeBoolForKey:FBSDKPROFILE_IS_LIMITED_KEY];
  NSDate *birthday = [decoder decodeObjectOfClass:[NSDate class] forKey:FBSDKPROFILE_BIRTHDAY_KEY];
  FBSDKUserAgeRange *ageRange = [decoder decodeObjectOfClass:[FBSDKUserAgeRange class] forKey:FBSDKPROFILE_AGERANGE_KEY];
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
                    isLimited:isLimited];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:self.userID forKey:FBSDKPROFILE_USERID_KEY];
  [encoder encodeObject:self.firstName forKey:FBSDKPROFILE_FIRSTNAME_KEY];
  [encoder encodeObject:self.middleName forKey:FBSDKPROFILE_MIDDLENAME_KEY];
  [encoder encodeObject:self.lastName forKey:FBSDKPROFILE_LASTNAME_KEY];
  [encoder encodeObject:self.name forKey:FBSDKPROFILE_NAME_KEY];
  [encoder encodeObject:self.linkURL forKey:FBSDKPROFILE_LINKURL_KEY];
  [encoder encodeObject:self.refreshDate forKey:FBSDKPROFILE_REFRESHDATE_KEY];
  [encoder encodeObject:self.imageURL forKey:FBSDKPROFILE_IMAGEURL_KEY];
  [encoder encodeObject:self.email forKey:FBSDKPROFILE_EMAIL_KEY];
  [encoder encodeObject:self.friendIDs forKey:FBSDKPROFILE_FRIENDIDS_KEY];
  [encoder encodeBool:self.isLimited forKey:FBSDKPROFILE_IS_LIMITED_KEY];
  [encoder encodeObject:self.birthday forKey:FBSDKPROFILE_BIRTHDAY_KEY];
  [encoder encodeObject:self.ageRange forKey:FBSDKPROFILE_AGERANGE_KEY];
}

@end

@implementation FBSDKProfile (Internal)

static id <FBSDKDataPersisting> _store;

+ (void)configureWithStore:(id<FBSDKDataPersisting>)store
       accessTokenProvider:(Class<FBSDKAccessTokenProviding>)accessTokenProvider
        notificationCenter:(id<FBSDKNotificationPosting, FBSDKNotificationObserving>)notificationCenter
{
  if (self == [FBSDKProfile class]) {
    _store = store;
    _accessTokenProvider = accessTokenProvider;
    _notificationCenter = notificationCenter;
  }
}

 #pragma clang diagnostic push
 #pragma clang diagnostic ignored "-Wdeprecated-declarations"
+ (void)cacheProfile:(FBSDKProfile *)profile
{
  if (profile) {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:profile];
    [_store setObject:data forKey:FBSDKProfileUserDefaultsKey];
  } else {
    [_store removeObjectForKey:FBSDKProfileUserDefaultsKey];
  }
}

+ (FBSDKProfile *)fetchCachedProfile
{
  NSData *data = [_store objectForKey:FBSDKProfileUserDefaultsKey];
  if (data != nil) {
    id<FBSDKObjectDecoding> unarchiver = [FBSDKUnarchiverProvider createSecureUnarchiverFor:data];

    @try {
      return [unarchiver decodeObjectOfClass:[FBSDKProfile class] forKey:NSKeyedArchiveRootObjectKey];
    } @catch (NSException *exception) {
      // Ignore decode error
    }
  }
  return nil;
}

+ (NSURL *)imageURLForProfileID:(FBSDKUserIdentifier *)profileId
                    PictureMode:(FBSDKProfilePictureMode)mode
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

  NSMutableDictionary *queryParameters = [NSMutableDictionary dictionary];
  [FBSDKTypeUtility dictionary:queryParameters setObject:type forKey:pictureModeKey];
  [FBSDKTypeUtility dictionary:queryParameters setObject:@(roundf(size.width)) forKey:widthKey];
  [FBSDKTypeUtility dictionary:queryParameters setObject:@(roundf(size.height)) forKey:heightKey];

  if ([self.accessTokenProvider currentAccessToken]) {
    [FBSDKTypeUtility dictionary:queryParameters setObject:[[self.accessTokenProvider currentAccessToken] tokenString]
                          forKey:accessTokenKey];
  } else if (FBSDKSettings.clientToken) {
    [FBSDKTypeUtility dictionary:queryParameters setObject:FBSDKSettings.clientToken forKey:accessTokenKey];
  } else {
    NSLog(@"As of Graph API v8.0, profile images may not be retrieved without an access token. This can be the current access token from logging in with Facebook or it can be set via the plist or in code. Providing neither will cause this call to return a silhouette image.");
  }

  NSString *path = [NSString stringWithFormat:@"%@/picture", profileId];

  return [FBSDKInternalUtility facebookURLWithHostPrefix:@"graph"
                                                    path:path
                                         queryParameters:queryParameters
                                                   error:NULL];
}

+ (void)loadProfileWithToken:(FBSDKAccessToken *)token completion:(FBSDKProfileBlock)completion
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

  id<FBSDKGraphRequest> request = [[FBSDKGraphRequest alloc] initWithGraphPath:graphPath
                                                                    parameters:nil
                                                                         flags:FBSDKGraphRequestFlagDoNotInvalidateTokenOnError | FBSDKGraphRequestFlagDisableErrorRecovery];
  [[self class] loadProfileWithToken:token completion:completion graphRequest:request];
}

+ (void)loadProfileWithToken:(FBSDKAccessToken *)token
                  completion:(FBSDKProfileBlock)completion
                graphRequest:(id<FBSDKGraphRequest>)request
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
    NSURL *linkUrl = [FBSDKTypeUtility URLValue:[NSURL URLWithString:urlString]];
    NSArray<FBSDKUserIdentifier *> *friendIDs = [self friendIDsFromGraphResult:[FBSDKTypeUtility dictionaryValue:result[@"friends"]]];
    FBSDKUserAgeRange *ageRange = [FBSDKUserAgeRange ageRangeFromDictionary:[FBSDKTypeUtility dictionaryValue:result[@"age_range"]]];

    [FBSDKProfile.dateFormatter setDateFormat:@"MM/dd/yyyy"];
    NSDate *birthday = [FBSDKProfile.dateFormatter dateFromString:[FBSDKTypeUtility coercedToStringValue:result[@"birthday"]]];

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
                                                        ageRange:ageRange];
    *profileRef = [profile copy];
  };
  [[self class] loadProfileWithToken:token
                          completion:completion
                        graphRequest:request
                          parseBlock:parseBlock];
}

+ (void)loadProfileWithToken:(FBSDKAccessToken *)token
                  completion:(FBSDKProfileBlock)completion
                graphRequest:(id<FBSDKGraphRequest>)request
                  parseBlock:(FBSDKParseProfileBlock)parseBlock;
{
  static id<FBSDKGraphRequestConnecting> executingRequestConnection = nil;

  BOOL isStale = [[NSDate date] timeIntervalSinceDate:g_currentProfile.refreshDate] > FBSDKPROFILE_STALE_IN_SECONDS;
  if (token
      && (isStale || ![g_currentProfile.userID isEqualToString:token.userID] || g_currentProfile.isLimited)) {
    FBSDKProfile *expectedCurrentProfile = g_currentProfile;

    [executingRequestConnection cancel];
    executingRequestConnection = [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
      if (expectedCurrentProfile != g_currentProfile) {
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
      [[self class] setCurrentProfile:profile];
      if (completion != NULL) {
        completion(profile, error);
      }
    }];
  } else if (completion != NULL) {
    completion(g_currentProfile, nil);
  }
}

+ (void)observeChangeAccessTokenChange:(NSNotification *)notification
{
  FBSDKAccessToken *token = notification.userInfo[FBSDKAccessTokenChangeNewKey];
  [self loadProfileWithToken:token completion:NULL];
}

+ (NSArray<FBSDKUserIdentifier *> *)friendIDsFromGraphResult:(NSDictionary<NSString *, id> *)result
{
  NSArray *rawFriends = [FBSDKTypeUtility arrayValue:result[@"data"]];
  NSMutableArray *friendIDs = NSMutableArray.new;

  for (NSDictionary *rawFriend in rawFriends) {
    if ([FBSDKTypeUtility dictionaryValue:rawFriend]) {
      FBSDKUserIdentifier *friendID = [FBSDKTypeUtility coercedToStringValue:rawFriend[@"id"]];
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
    _dateFormatter = NSDateFormatter.new;
  }
  return _dateFormatter;
}

 #pragma clang diagnostic pop

 #if DEBUG
  #if FBSDKTEST

+ (void)resetCurrentProfileCache
{
  g_currentProfile = nil;
}

+ (id<FBSDKDataPersisting>)store
{
  return _store;
}

+ (void)setAccessTokenProvider:(Class<FBSDKAccessTokenProviding>)accessTokenProvider
{
  _accessTokenProvider = accessTokenProvider;
}

+ (void)reset
{
  _store = nil;
  _accessTokenProvider = nil;
  _notificationCenter = nil;
}

  #endif
 #endif

@end

#endif
