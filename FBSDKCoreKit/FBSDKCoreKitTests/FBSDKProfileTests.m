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

@import TestTools;

#import <XCTest/XCTest.h>

#import "FBSDKCoreKit.h"
#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKProfile.h"
#import "FBSDKProfile+Internal.h"

@interface FBSDKSettings (Testing)
+ (void)resetFacebookClientTokenCache;
@end

@interface FBSDKProfile (Testing)
+ (void)resetCurrentProfileCache;
+ (void)loadProfileWithToken:(FBSDKAccessToken *)token
                  completion:(FBSDKProfileBlock)completion
                graphRequest:(id<FBSDKGraphRequest>)request;
+ (NSString *)graphPathForToken:(FBSDKAccessToken *)token;
@end

@interface FBSDKProfileTests : XCTestCase
@property (nonatomic) FBSDKProfile *profile;
@property (nonatomic, copy) NSString *sdkVersion;
@property (nonatomic, assign) CGSize validNonSquareSize;
@property (nonatomic, assign) CGSize validSquareSize;
@property (nonatomic, copy) NSString *validClientToken;
@property (nonatomic) TestGraphRequest *testGraphRequest;
@end

@implementation FBSDKProfileTests

NSString *const accessTokenKey = @"access_token";
NSString *const pictureModeKey = @"type";
NSString *const widthKey = @"width";
NSString *const heightKey = @"height";

- (void)setUp
{
  [super setUp];

  [self resetCaches];

  [FBSDKSettings configureWithStore:[UserDefaultsSpy new]
     appEventsConfigurationProvider:TestAppEventsConfigurationProvider.class
             infoDictionaryProvider:[TestBundle new]
                        eventLogger:[TestAppEvents new]];

  _sdkVersion = @"100";
  _profile = SampleUserProfiles.valid;
  _validClientToken = @"Foo";
  _validSquareSize = CGSizeMake(100, 100);
  _validNonSquareSize = CGSizeMake(10, 20);
  _testGraphRequest = [TestGraphRequest new];

  FBSDKSettings.graphAPIVersion = _sdkVersion;
  FBSDKProfile.accessTokenProvider = TestAccessTokenWallet.class;
}

- (void)tearDown
{
  [self resetCaches];
  _profile = nil;

  [super tearDown];
}

- (void)resetCaches
{
  [FBSDKProfile resetCurrentProfileCache];
  [FBSDKSettings reset];
  [FBSDKProfile reset];
  [TestAccessTokenWallet reset];
}

// MARK: - Creating Image URL

- (void)testCreatingImageURL
{
  NSURL *url = [_profile imageURLForPictureMode:FBSDKProfilePictureModeNormal size:_validSquareSize];

  NSString *expectedPath = [NSString stringWithFormat:@"/%@/%@/picture", _sdkVersion, _profile.userID];
  XCTAssertEqualObjects(
    url.path,
    expectedPath,
    "Should add the graph api version and the identifier of the current user when creating a url for for fetching a profile image"
  );
}

- (void)testCreatingImageURLWithNoAccessTokenNoClientToken
{
  NSURL *url = [_profile imageURLForPictureMode:FBSDKProfilePictureModeNormal size:_validSquareSize];
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:true];

  NSSet *expectedQueryItems = [NSSet setWithArray:@[
    [[NSURLQueryItem alloc] initWithName:pictureModeKey value:@"normal"],
    [[NSURLQueryItem alloc] initWithName:widthKey value:@"100"],
    [[NSURLQueryItem alloc] initWithName:heightKey value:@"100"],
                               ]];

  XCTAssertEqualObjects(
    [NSSet setWithArray:components.queryItems],
    expectedQueryItems,
    "Should add the expected query items to a url when creating a url for fetching a profile image"
  );
}

- (void)testCreatingImageURLWithClientTokenNoAccessToken
{
  FBSDKSettings.clientToken = _validClientToken;

  NSURL *url = [_profile imageURLForPictureMode:FBSDKProfilePictureModeNormal size:_validSquareSize];
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:true];

  NSSet *expectedQueryItems = [NSSet setWithArray:@[
    [[NSURLQueryItem alloc] initWithName:pictureModeKey value:@"normal"],
    [[NSURLQueryItem alloc] initWithName:widthKey value:@"100"],
    [[NSURLQueryItem alloc] initWithName:heightKey value:@"100"],
    [[NSURLQueryItem alloc] initWithName:accessTokenKey value:_validClientToken],
                               ]];

  XCTAssertEqualObjects(
    [NSSet setWithArray:components.queryItems],
    expectedQueryItems,
    "Should use the current client token as the 'access token' when there is no true access token available"
  );
}

- (void)testCreatingImageURLWithAccessTokenNoClientToken
{
  [TestAccessTokenWallet setCurrentAccessToken:SampleAccessTokens.validToken];
  NSURL *url = [_profile imageURLForPictureMode:FBSDKProfilePictureModeNormal size:_validSquareSize];
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:true];

  NSSet *expectedQueryItems = [NSSet setWithArray:@[
    [[NSURLQueryItem alloc] initWithName:pictureModeKey value:@"normal"],
    [[NSURLQueryItem alloc] initWithName:widthKey value:@"100"],
    [[NSURLQueryItem alloc] initWithName:heightKey value:@"100"],
    [[NSURLQueryItem alloc] initWithName:accessTokenKey value:SampleAccessTokens.validToken.tokenString],
                               ]];

  XCTAssertEqualObjects(
    [NSSet setWithArray:components.queryItems],
    expectedQueryItems,
    "Should use the current 'access token' when creating a url query"
  );
}

- (void)testCreatingImageURLWithAccessTokenAndClientToken
{
  [TestAccessTokenWallet setCurrentAccessToken:SampleAccessTokens.validToken];
  FBSDKSettings.clientToken = _validClientToken;

  NSURL *url = [_profile imageURLForPictureMode:FBSDKProfilePictureModeNormal size:_validSquareSize];
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:true];

  NSSet *expectedQueryItems = [NSSet setWithArray:@[
    [[NSURLQueryItem alloc] initWithName:pictureModeKey value:@"normal"],
    [[NSURLQueryItem alloc] initWithName:widthKey value:@"100"],
    [[NSURLQueryItem alloc] initWithName:heightKey value:@"100"],
    [[NSURLQueryItem alloc] initWithName:accessTokenKey value:SampleAccessTokens.validToken.tokenString],
                               ]];

  XCTAssertEqualObjects(
    [NSSet setWithArray:components.queryItems],
    expectedQueryItems,
    "Should use the current access token as the 'access_token' parameter when available"
  );
}

- (void)testCreatingEnumWithSmallMode
{
  NSURL *url = [_profile imageURLForPictureMode:FBSDKProfilePictureModeSmall size:_validNonSquareSize];
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:true];

  NSSet *expectedQueryItems = [NSSet setWithArray:@[
    [[NSURLQueryItem alloc] initWithName:pictureModeKey value:@"small"],
    [[NSURLQueryItem alloc] initWithName:widthKey value:@"10"],
    [[NSURLQueryItem alloc] initWithName:heightKey value:@"20"],
                               ]];

  XCTAssertEqualObjects(
    [NSSet setWithArray:components.queryItems],
    expectedQueryItems,
    "Should add the expected query items to a url when creating a url for fetching a profile image"
  );
}

- (void)testCreatingEnumWithAlbumMode
{
  NSURL *url = [_profile imageURLForPictureMode:FBSDKProfilePictureModeAlbum size:_validNonSquareSize];
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:true];

  NSSet *expectedQueryItems = [NSSet setWithArray:@[
    [[NSURLQueryItem alloc] initWithName:pictureModeKey value:@"album"],
    [[NSURLQueryItem alloc] initWithName:widthKey value:@"10"],
    [[NSURLQueryItem alloc] initWithName:heightKey value:@"20"],
                               ]];

  XCTAssertEqualObjects(
    [NSSet setWithArray:components.queryItems],
    expectedQueryItems,
    "Should add the expected query items to a url when creating a url for fetching a profile image"
  );
}

- (void)testCreatingEnumWithLargeMode
{
  NSURL *url = [_profile imageURLForPictureMode:FBSDKProfilePictureModeLarge size:_validNonSquareSize];
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:true];

  NSSet *expectedQueryItems = [NSSet setWithArray:@[
    [[NSURLQueryItem alloc] initWithName:pictureModeKey value:@"large"],
    [[NSURLQueryItem alloc] initWithName:widthKey value:@"10"],
    [[NSURLQueryItem alloc] initWithName:heightKey value:@"20"],
                               ]];

  XCTAssertEqualObjects(
    [NSSet setWithArray:components.queryItems],
    expectedQueryItems,
    "Should add the expected query items to a url when creating a url for fetching a profile image"
  );
}

- (void)testCreatingEnumWithSquareMode
{
  NSURL *url = [_profile imageURLForPictureMode:FBSDKProfilePictureModeSquare size:_validNonSquareSize];
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:true];

  NSSet *expectedQueryItems = [NSSet setWithArray:@[
    [[NSURLQueryItem alloc] initWithName:pictureModeKey value:@"square"],
    [[NSURLQueryItem alloc] initWithName:widthKey value:@"10"],
    [[NSURLQueryItem alloc] initWithName:heightKey value:@"20"],
                               ]];

  XCTAssertEqualObjects(
    [NSSet setWithArray:components.queryItems],
    expectedQueryItems,
    "Should add the expected query items to a url when creating a url for fetching a profile image"
  );
}

- (void)testCreatingImageURLWithUnknownMode
{
  NSURL *url = [_profile imageURLForPictureMode:400 size:_validSquareSize];
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:true];

  NSSet *expectedQueryItems = [NSSet setWithArray:@[
    [[NSURLQueryItem alloc] initWithName:pictureModeKey value:@"normal"],
    [[NSURLQueryItem alloc] initWithName:widthKey value:@"100"],
    [[NSURLQueryItem alloc] initWithName:heightKey value:@"100"],
                               ]];

  XCTAssertEqualObjects(
    [NSSet setWithArray:components.queryItems],
    expectedQueryItems,
    "The picture mode for an invalid enum value should default to 'normal'"
  );
}

// MARK: - Size Validations

- (void)testCreatingImageURLWithNoSize
{
  NSURL *url = [_profile imageURLForPictureMode:FBSDKProfilePictureModeNormal size:CGSizeZero];
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:true];

  NSSet *expectedQueryItems = [NSSet setWithArray:@[
    [[NSURLQueryItem alloc] initWithName:pictureModeKey value:@"normal"],
    [[NSURLQueryItem alloc] initWithName:widthKey value:@"0"],
    [[NSURLQueryItem alloc] initWithName:heightKey value:@"0"],
                               ]];

  XCTAssertNotNil(url, "Should not create a url for fetching a profile picture with zero size but it will");
  XCTAssertEqualObjects(
    [NSSet setWithArray:components.queryItems],
    expectedQueryItems,
    "Should add the expected query items to a url when creating a url for fetching a profile image"
  );
}

- (void)testCreatingSquareImageURLWithNonSquareSize
{
  NSURL *url = [_profile imageURLForPictureMode:FBSDKProfilePictureModeSquare size:_validNonSquareSize];
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:true];

  NSSet *expectedQueryItems = [NSSet setWithArray:@[
    [[NSURLQueryItem alloc] initWithName:pictureModeKey value:@"square"],
    [[NSURLQueryItem alloc] initWithName:widthKey value:@"10"],
    [[NSURLQueryItem alloc] initWithName:heightKey value:@"20"],
                               ]];

  XCTAssertNotNil(url, "Should not create a url for a square image with non-square size but it will");
  XCTAssertEqualObjects(
    [NSSet setWithArray:components.queryItems],
    expectedQueryItems,
    "Should add the expected query items to a url when creating a url for fetching a profile image"
  );
}

- (void)testCreatingSquareImageURLWithNegativeSize
{
  NSURL *url = [_profile imageURLForPictureMode:FBSDKProfilePictureModeSquare size:CGSizeMake(-10, -10)];
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:true];

  NSSet *expectedQueryItems = [NSSet setWithArray:@[
    [[NSURLQueryItem alloc] initWithName:pictureModeKey value:@"square"],
    [[NSURLQueryItem alloc] initWithName:widthKey value:@"-10"],
    [[NSURLQueryItem alloc] initWithName:heightKey value:@"-10"],
                               ]];

  XCTAssertNotNil(url, "Should not create a url for a square image with a negative size but it will");
  XCTAssertEqualObjects(
    [NSSet setWithArray:components.queryItems],
    expectedQueryItems,
    "Should add the expected query items to a url when creating a url for fetching a profile image"
  );
}

// MARK: - Profile Loading

- (void)testGraphPathForProfileLoadWithLinkPermission
{
  [self verifyGraphPath:@"me?fields=id,first_name,middle_name,last_name,name,link" forPermissions:@[@"user_link"]];
}

- (void)testGraphPathForProfileLoadWithNoPermission
{
  [self verifyGraphPath:@"me?fields=id,first_name,middle_name,last_name,name" forPermissions:@[]];
}

- (void)testGraphPathForProfileLoadWithEmailPermission
{
  [self verifyGraphPath:@"me?fields=id,first_name,middle_name,last_name,name,email" forPermissions:@[@"email"]];
}

- (void)testGraphPathForProfileLoadWithFriendsPermission
{
  [self verifyGraphPath:@"me?fields=id,first_name,middle_name,last_name,name,friends" forPermissions:@[@"user_friends"]];
}

- (void)testGraphPathForProfileLoadWithBirthdayPermission
{
  [self verifyGraphPath:@"me?fields=id,first_name,middle_name,last_name,name,birthday" forPermissions:@[@"user_birthday"]];
}

- (void)testGraphPathForProfileLoadWithAgeRangePermission
{
  [self verifyGraphPath:@"me?fields=id,first_name,middle_name,last_name,name,age_range" forPermissions:@[@"user_age_range"]];
}

- (void)testGraphPathForProfileLoadWithHometownPermission
{
  [self verifyGraphPath:@"me?fields=id,first_name,middle_name,last_name,name,hometown" forPermissions:@[@"user_hometown"]];
}

- (void)testGraphPathForProfileLoadWithLocationPermission
{
  [self verifyGraphPath:@"me?fields=id,first_name,middle_name,last_name,name,location" forPermissions:@[@"user_location"]];
}

- (void)testGraphPathForProfileLoadWithGenderPermission
{
  [self verifyGraphPath:@"me?fields=id,first_name,middle_name,last_name,name,gender" forPermissions:@[@"user_gender"]];
}

- (void)testLoadingProfile
{
  NSDateFormatter *formatter = NSDateFormatter.new;
  [formatter setDateFormat:@"MM/dd/yyyy"];

  __block BOOL didInvokeCompletion = NO;
  [FBSDKProfile loadProfileWithToken:SampleAccessTokens.validToken
                          completion:^(FBSDKProfile *profile, NSError *error) {
                            didInvokeCompletion = YES;
                            XCTAssertEqualObjects(profile.firstName, SampleUserProfiles.valid.firstName);
                            XCTAssertEqualObjects(profile.middleName, SampleUserProfiles.valid.middleName);
                            XCTAssertEqualObjects(profile.lastName, SampleUserProfiles.valid.lastName);
                            XCTAssertEqualObjects(profile.name, SampleUserProfiles.valid.name);
                            XCTAssertEqualObjects(profile.userID, SampleUserProfiles.valid.userID);
                            XCTAssertEqualObjects(profile.linkURL, SampleUserProfiles.valid.linkURL);
                            XCTAssertEqualObjects(profile.email, SampleUserProfiles.valid.email);
                            XCTAssertEqualObjects(profile.friendIDs, SampleUserProfiles.valid.friendIDs);
                            XCTAssertEqualObjects([formatter stringFromDate:profile.birthday], self.sampleGraphResult[@"birthday"]);
                            XCTAssertEqualObjects(profile.ageRange, SampleUserProfiles.valid.ageRange);
                            XCTAssertEqualObjects(profile.hometown, SampleUserProfiles.valid.hometown);
                            XCTAssertEqualObjects(profile.location, SampleUserProfiles.valid.location);
                            XCTAssertEqualObjects(profile.gender, SampleUserProfiles.valid.gender);
                          } graphRequest:_testGraphRequest];

  _testGraphRequest.capturedCompletionHandler(nil, self.sampleGraphResult, nil);
  XCTAssertTrue(didInvokeCompletion);
}

- (void)testLoadingProfileWithInvalidLink
{
  id result = @{
    @"id" : SampleUserProfiles.valid.userID,
    @"first_name" : SampleUserProfiles.valid.firstName,
    @"middle_name" : SampleUserProfiles.valid.middleName,
    @"last_name" : SampleUserProfiles.valid.lastName,
    @"name" : SampleUserProfiles.valid.name,
    @"link" : @"   ",
    @"email" : SampleUserProfiles.valid.email
  };

  __block BOOL didInvokeCompletion = NO;
  [FBSDKProfile loadProfileWithToken:SampleAccessTokens.validToken
                          completion:^(FBSDKProfile *profile, NSError *error) {
                            didInvokeCompletion = YES;
                            XCTAssertNil(profile.linkURL);
                          } graphRequest:_testGraphRequest];

  _testGraphRequest.capturedCompletionHandler(nil, result, nil);
  XCTAssertTrue(didInvokeCompletion);
}

- (void)testProfileNilWithNilAccessToken
{
  __block BOOL didInvokeCompletion = NO;
  [FBSDKProfile loadProfileWithToken:nil completion:^(FBSDKProfile *profile, NSError *error) {
                                           didInvokeCompletion = YES;
                                           XCTAssertNil(profile);
                                         } graphRequest:_testGraphRequest];
  XCTAssertTrue(didInvokeCompletion);
  XCTAssertEqual(
    _testGraphRequest.startCallCount,
    0,
    "Should not fetch a profile if there is no access token"
  );
}

- (void)testLoadingProfileWithNoFriends
{
  id result = @{
    @"id" : SampleUserProfiles.valid.userID,
    @"first_name" : SampleUserProfiles.valid.firstName,
    @"middle_name" : SampleUserProfiles.valid.middleName,
    @"last_name" : SampleUserProfiles.valid.lastName,
    @"name" : SampleUserProfiles.valid.name,
    @"link" : SampleUserProfiles.valid.linkURL,
    @"email" : SampleUserProfiles.valid.email,
    @"friends" : @{@"data" : @[]}
  };

  __block BOOL didInvokeCompletion = NO;
  [FBSDKProfile loadProfileWithToken:SampleAccessTokens.validToken
                          completion:^(FBSDKProfile *profile, NSError *error) {
                            didInvokeCompletion = YES;
                            XCTAssertNotNil(profile);
                            XCTAssertNil(profile.friendIDs);
                          } graphRequest:_testGraphRequest];

  _testGraphRequest.capturedCompletionHandler(nil, result, nil);
  XCTAssertTrue(didInvokeCompletion);
}

- (void)testLoadingProfileWithInvalidFriends
{
  id result = @{
    @"id" : SampleUserProfiles.valid.userID,
    @"first_name" : SampleUserProfiles.valid.firstName,
    @"middle_name" : SampleUserProfiles.valid.middleName,
    @"last_name" : SampleUserProfiles.valid.lastName,
    @"name" : SampleUserProfiles.valid.name,
    @"link" : SampleUserProfiles.valid.linkURL,
    @"email" : SampleUserProfiles.valid.email,
    @"friends" : @"   "
  };

  __block BOOL didInvokeCompletion = NO;
  [FBSDKProfile loadProfileWithToken:SampleAccessTokens.validToken
                          completion:^(FBSDKProfile *profile, NSError *error) {
                            didInvokeCompletion = YES;
                            XCTAssertNotNil(profile);
                            XCTAssertNil(profile.friendIDs);
                          } graphRequest:_testGraphRequest];

  _testGraphRequest.capturedCompletionHandler(nil, result, nil);
  XCTAssertTrue(didInvokeCompletion);
}

- (void)testLoadingProfileWithInvalidBithday
{
  id result = @{
    @"id" : SampleUserProfiles.valid.userID,
    @"first_name" : SampleUserProfiles.valid.firstName,
    @"middle_name" : SampleUserProfiles.valid.middleName,
    @"last_name" : SampleUserProfiles.valid.lastName,
    @"name" : SampleUserProfiles.valid.name,
    @"link" : SampleUserProfiles.valid.linkURL,
    @"email" : SampleUserProfiles.valid.email,
    @"birthday" : @123
  };

  __block BOOL didInvokeCompletion = NO;
  [FBSDKProfile loadProfileWithToken:SampleAccessTokens.validToken
                          completion:^(FBSDKProfile *profile, NSError *error) {
                            didInvokeCompletion = YES;
                            XCTAssertNotNil(profile);
                            XCTAssertNil(profile.birthday);
                          } graphRequest:_testGraphRequest];

  _testGraphRequest.capturedCompletionHandler(nil, result, nil);
  XCTAssertTrue(didInvokeCompletion);
}

- (void)testLoadingProfileWithInvalidAgeRange
{
  id result = @{
    @"id" : SampleUserProfiles.valid.userID,
    @"first_name" : SampleUserProfiles.valid.firstName,
    @"middle_name" : SampleUserProfiles.valid.middleName,
    @"last_name" : SampleUserProfiles.valid.lastName,
    @"name" : SampleUserProfiles.valid.name,
    @"link" : SampleUserProfiles.valid.linkURL,
    @"email" : SampleUserProfiles.valid.email,
    @"age_range" : @"ageRange"
  };

  __block BOOL didInvokeCompletion = NO;
  [FBSDKProfile loadProfileWithToken:SampleAccessTokens.validToken
                          completion:^(FBSDKProfile *profile, NSError *error) {
                            didInvokeCompletion = YES;
                            XCTAssertNotNil(profile);
                            XCTAssertNil(profile.ageRange);
                          } graphRequest:_testGraphRequest];

  _testGraphRequest.capturedCompletionHandler(nil, result, nil);
  XCTAssertTrue(didInvokeCompletion);
}

- (void)testLoadingProfileWithInvalidHometown
{
  id result = @{
    @"id" : SampleUserProfiles.valid.userID,
    @"first_name" : SampleUserProfiles.valid.firstName,
    @"middle_name" : SampleUserProfiles.valid.middleName,
    @"last_name" : SampleUserProfiles.valid.lastName,
    @"name" : SampleUserProfiles.valid.name,
    @"link" : SampleUserProfiles.valid.linkURL,
    @"email" : SampleUserProfiles.valid.email,
    @"hometown" : @"hometown"
  };

  __block BOOL didInvokeCompletion = NO;
  [FBSDKProfile loadProfileWithToken:SampleAccessTokens.validToken
                          completion:^(FBSDKProfile *profile, NSError *error) {
                            didInvokeCompletion = YES;
                            XCTAssertNotNil(profile);
                            XCTAssertNil(profile.hometown);
                          } graphRequest:_testGraphRequest];

  _testGraphRequest.capturedCompletionHandler(nil, result, nil);
  XCTAssertTrue(didInvokeCompletion);
}

- (void)testLoadingProfileWithInvalidLocation
{
  id result = @{
    @"id" : SampleUserProfiles.valid.userID,
    @"first_name" : SampleUserProfiles.valid.firstName,
    @"middle_name" : SampleUserProfiles.valid.middleName,
    @"last_name" : SampleUserProfiles.valid.lastName,
    @"name" : SampleUserProfiles.valid.name,
    @"link" : SampleUserProfiles.valid.linkURL,
    @"email" : SampleUserProfiles.valid.email,
    @"location" : @"location"
  };

  __block BOOL didInvokeCompletion = NO;
  [FBSDKProfile loadProfileWithToken:SampleAccessTokens.validToken
                          completion:^(FBSDKProfile *profile, NSError *error) {
                            didInvokeCompletion = YES;
                            XCTAssertNotNil(profile);
                            XCTAssertNil(profile.location);
                          } graphRequest:_testGraphRequest];

  _testGraphRequest.capturedCompletionHandler(nil, result, nil);
  XCTAssertTrue(didInvokeCompletion);
}

- (void)testLoadingProfileWithInvalidGender
{
  id result = @{
    @"id" : SampleUserProfiles.valid.userID,
    @"first_name" : SampleUserProfiles.valid.firstName,
    @"middle_name" : SampleUserProfiles.valid.middleName,
    @"last_name" : SampleUserProfiles.valid.lastName,
    @"name" : SampleUserProfiles.valid.name,
    @"link" : SampleUserProfiles.valid.linkURL,
    @"email" : SampleUserProfiles.valid.email,
    @"gender" : @{}
  };

  __block BOOL didInvokeCompletion = NO;
  [FBSDKProfile loadProfileWithToken:SampleAccessTokens.validToken
                          completion:^(FBSDKProfile *profile, NSError *error) {
                            didInvokeCompletion = YES;
                            XCTAssertNotNil(profile);
                            XCTAssertNil(profile.gender);
                          } graphRequest:_testGraphRequest];

  _testGraphRequest.capturedCompletionHandler(nil, result, nil);
  XCTAssertTrue(didInvokeCompletion);
}

- (void)testProfileNotRefreshedIfNotStale
{
  [FBSDKProfile setCurrentProfile:SampleUserProfiles.valid];

  __block BOOL didInvokeCompletion = NO;
  [FBSDKProfile loadProfileWithToken:nil
                          completion:^(FBSDKProfile *_Nullable profile, NSError *_Nullable error) {
                            didInvokeCompletion = YES;
                            XCTAssertEqualObjects(profile.firstName, SampleUserProfiles.valid.firstName);
                            XCTAssertEqualObjects(profile.middleName, SampleUserProfiles.valid.middleName);
                            XCTAssertEqualObjects(profile.lastName, SampleUserProfiles.valid.lastName);
                            XCTAssertEqualObjects(profile.name, SampleUserProfiles.valid.name);
                            XCTAssertEqualObjects(profile.userID, SampleUserProfiles.valid.userID);
                            XCTAssertEqualObjects(profile.linkURL, SampleUserProfiles.valid.linkURL);
                            XCTAssertEqualObjects(profile.email, SampleUserProfiles.valid.email);
                          } graphRequest:_testGraphRequest];

  XCTAssertTrue(didInvokeCompletion);

  XCTAssertEqual(
    _testGraphRequest.startCallCount,
    0,
    "Should not fetch a profile if it is not stale"
  );
}

- (void)testLoadingProfileWithLimitedProfileWithoutToken
{
  FBSDKProfile *expected = SampleUserProfiles.validLimited;
  [FBSDKProfile setCurrentProfile:expected];
  TestGraphRequest *request = [TestGraphRequest new];
  [FBSDKProfile loadProfileWithToken:nil
                          completion:^(FBSDKProfile *profile, NSError *error) {
                            XCTAssertEqualObjects(
                              profile,
                              expected,
                              "Should return the current profile synchronously"
                            );
                          }
                        graphRequest:request];
  XCTAssertEqual(
    request.startCallCount,
    0,
    "Should not fetch a profile if there is no access token"
  );
}

- (void)testLoadingProfileWithLimitedProfileWithToken
{
  [FBSDKProfile setCurrentProfile:SampleUserProfiles.validLimited];
  TestGraphRequest *request = [TestGraphRequest new];
  [FBSDKProfile loadProfileWithToken:SampleAccessTokens.validToken
                          completion:^(FBSDKProfile *profile, NSError *error) {
                            XCTFail("Should not invoke the completion");
                          }
                        graphRequest:request];
  XCTAssertEqual(
    request.startCallCount,
    1,
    "Should fetch a profile if it is limited and there is an access token"
  );
}

- (void)testLoadingProfileWithExpiredNonLimitedProfileWithToken
{
  FBSDKProfile *expected = [SampleUserProfiles createValidWithIsExpired:YES];
  [FBSDKProfile setCurrentProfile:expected];
  TestGraphRequest *request = [TestGraphRequest new];
  [FBSDKProfile loadProfileWithToken:SampleAccessTokens.validToken
                          completion:^(FBSDKProfile *profile, NSError *error) {
                            XCTFail("Should not invoke the completion");
                          }
                        graphRequest:request];
  XCTAssertEqual(
    request.startCallCount,
    1,
    "Should fetch a profile if it is expired and there is an access token"
  );
}

- (void)testLoadingProfileWithCurrentlyLoadingProfile
{
  FBSDKProfile *expected = [SampleUserProfiles createValidWithIsExpired:YES];
  [FBSDKProfile setCurrentProfile:expected];
  TestGraphRequest *request = [TestGraphRequest new];
  TestGraphRequestConnection *connection = [TestGraphRequestConnection new];
  request.stubbedConnection = connection;
  [FBSDKProfile loadProfileWithToken:SampleAccessTokens.validToken
                          completion:^(FBSDKProfile *profile, NSError *error) { XCTFail("Should not invoke the completion"); }
                        graphRequest:request];
  [FBSDKProfile loadProfileWithToken:SampleAccessTokens.validToken
                          completion:^(FBSDKProfile *profile, NSError *error) { XCTFail("Should not invoke the completion"); }
                        graphRequest:request];
  XCTAssertEqual(
    connection.cancelCallCount,
    1,
    "Should cancel an existing connection if a new connection is started before it completes"
  );
}

- (void)testProfileParseBlockInvokedOnSuccessfulGraphRequest
{
  id result = @{};
  __block BOOL parseBlockInvoked = false;

  [FBSDKProfile loadProfileWithToken:SampleAccessTokens.validToken
                          completion:^void (FBSDKProfile *profile, NSError *error) {}
                        graphRequest:_testGraphRequest
                          parseBlock:^void (id parseResult, FBSDKProfile **profileRef) {
                            parseBlockInvoked = true;
                          }];

  _testGraphRequest.capturedCompletionHandler(nil, result, nil);

  XCTAssertTrue(parseBlockInvoked);
}

- (void)testProfileParseBlockShouldHaveNonNullPointer
{
  id result = @{};
  __block BOOL didInvokeParseBlock = NO;
  [FBSDKProfile loadProfileWithToken:SampleAccessTokens.validToken
                          completion:^void (FBSDKProfile *profile, NSError *error) {}
                        graphRequest:_testGraphRequest
                          parseBlock:^void (id parseResult, FBSDKProfile **profileRef) {
                            didInvokeParseBlock = YES;
                            XCTAssertTrue(profileRef != NULL);
                          }];

  _testGraphRequest.capturedCompletionHandler(nil, result, nil);
  XCTAssertTrue(didInvokeParseBlock);
}

- (void)testProfileParseBlockReturnsNilIfResultIsEmpty
{
  id result = @{};

  [FBSDKProfile loadProfileWithToken:SampleAccessTokens.validToken completion:nil graphRequest:_testGraphRequest];

  _testGraphRequest.capturedCompletionHandler(nil, result, nil);

  XCTAssertNil(FBSDKProfile.currentProfile);
}

- (void)testProfileParseBlockReturnsNilIfResultHasNoId
{
  id result = @{
    @"first_name" : @"firstname",
    @"middle_name" : @"middlename",
    @"last_name" : @"lastname",
    @"name" : @"name"
  };
  [FBSDKProfile loadProfileWithToken:SampleAccessTokens.validToken completion:nil graphRequest:_testGraphRequest];
  _testGraphRequest.capturedCompletionHandler(nil, result, nil);
  XCTAssertNil(FBSDKProfile.currentProfile);
}

- (void)testProfileParseBlockReturnsNilIfResultHasEmptyId
{
  id result = @{
    @"id" : @"",
    @"first_name" : @"firstname",
    @"middle_name" : @"middlename",
    @"last_name" : @"lastname",
    @"name" : @"name"
  };
  [FBSDKProfile loadProfileWithToken:SampleAccessTokens.validToken completion:nil graphRequest:_testGraphRequest];
  _testGraphRequest.capturedCompletionHandler(nil, result, nil);
  XCTAssertNil(FBSDKProfile.currentProfile);
}

- (void)testLoadProfileWithRandomData
{
  for (int i = 0; i < 100; i++) {
    NSDictionary *randomizedResult = [Fuzzer randomizeWithJson:self.sampleGraphResult];
    __block BOOL completed = NO;
    [FBSDKProfile loadProfileWithToken:SampleAccessTokens.validToken
                            completion:^(FBSDKProfile *_Nullable profile, NSError *_Nullable error) {
                              completed = YES;
                            } graphRequest:_testGraphRequest];

    _testGraphRequest.capturedCompletionHandler(nil, randomizedResult, nil);
    XCTAssert(completed, @"Completion handler should be invoked synchronously");
  }
}

// MARK: Storage

- (void)testEncoding
{
  FBSDKTestCoder *coder = [FBSDKTestCoder new];
  _profile = SampleUserProfiles.validLimited;

  [_profile encodeWithCoder:coder];

  XCTAssertEqualObjects(
    coder.encodedObject[@"userID"],
    _profile.userID,
    "Should encode the expected user identifier"
  );
  XCTAssertEqualObjects(
    coder.encodedObject[@"firstName"],
    _profile.firstName,
    "Should encode the expected first name"
  );
  XCTAssertEqualObjects(
    coder.encodedObject[@"middleName"],
    _profile.middleName,
    "Should encode the expected middle name"
  );
  XCTAssertEqualObjects(
    coder.encodedObject[@"lastName"],
    _profile.lastName,
    "Should encode the expected last name"
  );
  XCTAssertEqualObjects(
    coder.encodedObject[@"name"],
    _profile.name,
    "Should encode the expected name"
  );
  XCTAssertEqualObjects(
    coder.encodedObject[@"linkURL"],
    _profile.linkURL,
    "Should encode the expected link URL"
  );
  XCTAssertEqualObjects(
    coder.encodedObject[@"refreshDate"],
    _profile.refreshDate,
    "Should encode the expected refresh date"
  );
  XCTAssertEqualObjects(
    coder.encodedObject[@"imageURL"],
    _profile.imageURL,
    "Should encode the expected image URL"
  );
  XCTAssertEqualObjects(
    coder.encodedObject[@"email"],
    _profile.email,
    "Should encode the expected email address"
  );
  XCTAssertEqualObjects(
    coder.encodedObject[@"friendIDs"],
    _profile.friendIDs,
    "Should encode the expected list of friend identifiers"
  );
  XCTAssertEqualObjects(
    coder.encodedObject[@"birthday"],
    _profile.birthday,
    "Should encode the expected user birthday"
  );
  XCTAssertEqualObjects(
    coder.encodedObject[@"ageRange"],
    _profile.ageRange,
    "Should encode the expected user age range"
  );
  XCTAssertEqualObjects(
    coder.encodedObject[@"hometown"],
    _profile.hometown,
    "Should encode the expected user hometown"
  );
  XCTAssertEqualObjects(
    coder.encodedObject[@"location"],
    _profile.location,
    "Should encode the expected user location"
  );
  XCTAssertEqualObjects(
    coder.encodedObject[@"gender"],
    _profile.gender,
    "Should encode the expected user gender"
  );
  XCTAssertEqualObjects(
    coder.encodedObject[@"isLimited"],
    @YES,
    "Should encode the expected 'isLimited' value as an object"
  );
}

- (void)testDecodingEntryWithMethodName
{
  FBSDKTestCoder *coder = [FBSDKTestCoder new];
  _profile = [[FBSDKProfile alloc] initWithCoder:coder];

  XCTAssertEqualObjects(
    coder.decodedObject[@"userID"],
    NSString.class,
    "Should decode a string for the userID key"
  );
  XCTAssertEqualObjects(
    coder.decodedObject[@"firstName"],
    NSString.class,
    "Should decode a string for the firstName key"
  );
  XCTAssertEqualObjects(
    coder.decodedObject[@"middleName"],
    NSString.class,
    "Should decode a string for the middleName key"
  );
  XCTAssertEqualObjects(
    coder.decodedObject[@"lastName"],
    NSString.class,
    "Should decode a string for the lastName key"
  );
  XCTAssertEqualObjects(
    coder.decodedObject[@"name"],
    NSString.class,
    "Should decode a string for the name key"
  );
  XCTAssertEqualObjects(
    coder.decodedObject[@"linkURL"],
    NSURL.class,
    "Should decode a url for the linkURL key"
  );
  XCTAssertEqualObjects(
    coder.decodedObject[@"refreshDate"],
    NSDate.class,
    "Should decode a date for the refreshDate key"
  );
  XCTAssertEqualObjects(
    coder.decodedObject[@"imageURL"],
    NSURL.class,
    "Should decode a url for the imageURL key"
  );
  XCTAssertEqualObjects(
    coder.decodedObject[@"email"],
    NSString.class,
    "Should decode a string for the email key"
  );
  XCTAssertEqualObjects(
    coder.decodedObject[@"friendIDs"],
    NSArray.class,
    "Should decode an array for the friendIDs key"
  );
  XCTAssertEqualObjects(
    coder.decodedObject[@"birthday"],
    NSDate.class,
    "Should decode a date for the birthday key"
  );
  XCTAssertEqualObjects(
    coder.decodedObject[@"ageRange"],
    FBSDKUserAgeRange.class,
    "Should decode a UserAgeRange object for the ageRange key"
  );
  XCTAssertEqualObjects(
    coder.decodedObject[@"hometown"],
    FBSDKLocation.class,
    "Should decode a Location object for the hometown key"
  );
  XCTAssertEqualObjects(
    coder.decodedObject[@"location"],
    FBSDKLocation.class,
    "Should decode a Location object for the location key"
  );
  XCTAssertEqualObjects(
    coder.decodedObject[@"gender"],
    NSString.class,
    "Should decode a string for the gender key"
  );
  XCTAssertEqualObjects(
    coder.decodedObject[@"isLimited"],
    @"decodeBoolForKey",
    "Should decode a bool for the isLimited key"
  );
}

// MARK: Helper

- (NSDictionary *)sampleGraphResult
{
  return @{
    @"id" : SampleUserProfiles.valid.userID,
    @"first_name" : SampleUserProfiles.valid.firstName,
    @"middle_name" : SampleUserProfiles.valid.middleName,
    @"last_name" : SampleUserProfiles.valid.lastName,
    @"name" : SampleUserProfiles.valid.name,
    @"link" : SampleUserProfiles.valid.linkURL,
    @"email" : SampleUserProfiles.valid.email,
    @"friends" : @{@"data" : @[
      @{
        @"name" : @"user1",
        @"id" : SampleUserProfiles.valid.friendIDs[0],
      },
      @{
        @"name" : @"user2",
        @"id" : SampleUserProfiles.valid.friendIDs[1],
      }
    ]},
    @"birthday" : @"01/01/1990",
    @"age_range" : @{
      @"min" : SampleUserProfiles.valid.ageRange.min,
    },
    @"hometown" : @{
      @"id" : SampleUserProfiles.valid.hometown.id,
      @"name" : SampleUserProfiles.valid.hometown.name,
    },
    @"location" : @{
      @"id" : SampleUserProfiles.valid.location.id,
      @"name" : SampleUserProfiles.valid.location.name,
    },
    @"gender" : SampleUserProfiles.valid.gender,
  };
}

- (void)verifyGraphPath:(NSString *)expectedPath
         forPermissions:(NSArray *)permissions
{
  FBSDKAccessToken *token = [SampleAccessTokens createWithPermissions:permissions];
  NSString *graphPath = [FBSDKProfile graphPathForToken:token];
  XCTAssertEqualObjects(graphPath, expectedPath);
}

@end
