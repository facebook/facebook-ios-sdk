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

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "FBSDKCoreKit.h"
#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKProfile.h"
#import "FBSDKProfile+Internal.h"
#import "FBSDKTestCase.h"
#import "SampleAccessToken.h"

@interface FBSDKSettings (Testing)
+ (void)resetFacebookClientTokenCache;
@end

@interface FBSDKProfile (Testing)
+ (void)resetCurrentProfileCache;
+ (void)loadProfileWithToken:(FBSDKAccessToken *)token
                  completion:(FBSDKProfileBlock)completion
                graphRequest:(FBSDKGraphRequest *)request;
@end

@interface FBSDKProfileTests : FBSDKTestCase

@end

@implementation FBSDKProfileTests
{
  FBSDKProfile *_profile;
  NSString *_sdkVersion;
  CGSize _validNonSquareSize;
  CGSize _validSquareSize;
  NSString *_validClientToken;
}

NSString *const accessTokenKey = @"access_token";
NSString *const pictureModeKey = @"type";
NSString *const widthKey = @"width";
NSString *const heightKey = @"height";

- (void)setUp
{
  [super setUp];

  _sdkVersion = @"100";
  _profile = SampleUserProfile.valid;
  _validClientToken = @"Foo";
  _validSquareSize = CGSizeMake(100, 100);
  _validNonSquareSize = CGSizeMake(10, 20);

  [self stubGraphAPIVersionWith:_sdkVersion];
  [self resetCaches];
}

- (void)tearDown
{
  [super tearDown];

  [self resetCaches];
}

- (void)resetCaches
{
  [FBSDKProfile resetCurrentProfileCache];
  [FBSDKSettings resetFacebookClientTokenCache];
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
  [self stubClientTokenWith:_validClientToken];

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
  [self stubCurrentAccessTokenWith:SampleAccessToken.validToken];

  NSURL *url = [_profile imageURLForPictureMode:FBSDKProfilePictureModeNormal size:_validSquareSize];
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:true];

  NSSet *expectedQueryItems = [NSSet setWithArray:@[
    [[NSURLQueryItem alloc] initWithName:pictureModeKey value:@"normal"],
    [[NSURLQueryItem alloc] initWithName:widthKey value:@"100"],
    [[NSURLQueryItem alloc] initWithName:heightKey value:@"100"],
    [[NSURLQueryItem alloc] initWithName:accessTokenKey value:SampleAccessToken.validToken.tokenString],
                               ]];

  XCTAssertEqualObjects(
    [NSSet setWithArray:components.queryItems],
    expectedQueryItems,
    "Should use the current client token as the 'access token' when there is no true access token available"
  );
}

- (void)testCreatingImageURLWithAccessTokenAndClientToken
{
  [self stubCurrentAccessTokenWith:SampleAccessToken.validToken];
  [self stubClientTokenWith:_validClientToken];

  NSURL *url = [_profile imageURLForPictureMode:FBSDKProfilePictureModeNormal size:_validSquareSize];
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:true];

  NSSet *expectedQueryItems = [NSSet setWithArray:@[
    [[NSURLQueryItem alloc] initWithName:pictureModeKey value:@"normal"],
    [[NSURLQueryItem alloc] initWithName:widthKey value:@"100"],
    [[NSURLQueryItem alloc] initWithName:heightKey value:@"100"],
    [[NSURLQueryItem alloc] initWithName:accessTokenKey value:SampleAccessToken.validToken.tokenString],
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

- (void)testCorrectGraphPathForFBProfileLoad
{
  id profileMock = OCMClassMock([FBSDKProfile class]);
  NSString *graphPath = @"me?fields=id,first_name,middle_name,last_name,name,link";
  __block BOOL graphRequestMethodInvoked = false;
  OCMStub([profileMock loadProfileWithToken:OCMOCK_ANY completion:OCMOCK_ANY graphRequest:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __unsafe_unretained FBSDKGraphRequest *req;
    [invocation getArgument:&req atIndex:4];
    graphRequestMethodInvoked = true;
    XCTAssertTrue([[req graphPath] isEqualToString:graphPath]);
  });
  OCMStub([profileMock loadProfileWithToken:OCMOCK_ANY completion:OCMOCK_ANY]).andForwardToRealObject();
  [FBSDKProfile loadProfileWithToken:SampleAccessToken.validToken completion:nil];
  XCTAssertTrue(graphRequestMethodInvoked);
}

- (void)testActualProfileLoaded
{
  id result = @{ @"id" : SampleUserProfile.valid.userID,
                 @"first_name" : SampleUserProfile.valid.firstName,
                 @"middle_name" : SampleUserProfile.valid.middleName,
                 @"last_name" : SampleUserProfile.valid.lastName,
                 @"name" : SampleUserProfile.valid.name};
  [self stubGraphRequestWithResult:result error:nil connection:nil];

  [FBSDKProfile loadProfileWithToken:SampleAccessToken.validToken completion:^(FBSDKProfile *_Nullable profile, NSError *_Nullable error) {
                                                                    XCTAssertTrue([profile.firstName isEqualToString:SampleUserProfile.valid.firstName]);
                                                                    XCTAssertTrue([profile.middleName isEqualToString:SampleUserProfile.valid.middleName]);
                                                                    XCTAssertTrue([profile.lastName isEqualToString:SampleUserProfile.valid.lastName]);
                                                                    XCTAssertTrue([profile.name isEqualToString:SampleUserProfile.valid.name]);
                                                                    XCTAssertTrue([profile.userID isEqualToString:SampleUserProfile.valid.userID]);
                                                                  } graphRequest:self.graphRequestMock];
}

- (void)testProfileNilWithNilAccessToken
{
  id result = @{ @"id" : SampleUserProfile.valid.userID,
                 @"first_name" : SampleUserProfile.valid.firstName,
                 @"middle_name" : SampleUserProfile.valid.middleName,
                 @"last_name" : SampleUserProfile.valid.lastName,
                 @"name" : SampleUserProfile.valid.name};
  [self stubGraphRequestWithResult:result error:nil connection:nil];

  [FBSDKProfile loadProfileWithToken:nil completion:^(FBSDKProfile *_Nullable profile, NSError *_Nullable error) {
                                           XCTAssertNil(profile);
                                         } graphRequest:self.graphRequestMock];
}

- (void)testProfileNotRefreshedIfNotStale
{
  [FBSDKProfile setCurrentProfile:SampleUserProfile.valid];
  id result = @{ @"id" : SampleUserProfile.valid.userID,
                 @"first_name" : @"firstname",
                 @"middle_name" : @"middlename",
                 @"last_name" : @"lastname",
                 @"name" : @"name"};
  [self stubGraphRequestWithResult:result error:nil connection:nil];

  [FBSDKProfile loadProfileWithToken:nil completion:^(FBSDKProfile *_Nullable profile, NSError *_Nullable error) {
                                           XCTAssertTrue([profile.firstName isEqualToString:SampleUserProfile.valid.firstName]);
                                           XCTAssertTrue([profile.middleName isEqualToString:SampleUserProfile.valid.middleName]);
                                           XCTAssertTrue([profile.lastName isEqualToString:SampleUserProfile.valid.lastName]);
                                           XCTAssertTrue([profile.name isEqualToString:SampleUserProfile.valid.name]);
                                           XCTAssertTrue([profile.userID isEqualToString:SampleUserProfile.valid.userID]);
                                         } graphRequest:self.graphRequestMock];
}

- (void)testProfileParseBlockInvokedOnSuccessfulGraphRequest
{
  id result = @{};
  [self stubGraphRequestWithResult:result error:nil connection:nil];

  __block BOOL parseBlockInvoked = false;

  [FBSDKProfile loadProfileWithToken:SampleAccessToken.validToken
                          completion:^void (FBSDKProfile *profile, NSError *error) {}
                        graphRequest:self.graphRequestMock
                          parseBlock:^void (id parseResult, FBSDKProfile **profileRef) {
                            parseBlockInvoked = true;
                          }];
  XCTAssertTrue(parseBlockInvoked);
}

- (void)testProfileParseBlockShouldHaveNonNullPointer
{
  id result = @{};
  [self stubGraphRequestWithResult:result error:nil connection:nil];

  [FBSDKProfile loadProfileWithToken:SampleAccessToken.validToken
                          completion:^void (FBSDKProfile *profile, NSError *error) {}
                        graphRequest:self.graphRequestMock
                          parseBlock:^void (id parseResult, FBSDKProfile **profileRef) {
                            XCTAssertTrue(profileRef != NULL);
                          }];
}

- (void)testProfileParseBlockReturnsNilIfResultIsEmpty
{
  id result = @{};
  [self stubGraphRequestWithResult:result error:nil connection:nil];

  [FBSDKProfile loadProfileWithToken:SampleAccessToken.validToken completion:nil graphRequest:self.graphRequestMock];
  XCTAssertNil(FBSDKProfile.currentProfile);
}

- (void)testProfileParseBlockReturnsNilIfResultHasNoId
{
  id result = @{ @"first_name" : @"firstname",
                 @"middle_name" : @"middlename",
                 @"last_name" : @"lastname",
                 @"name" : @"name"};
  [self stubGraphRequestWithResult:result error:nil connection:nil];

  [FBSDKProfile loadProfileWithToken:SampleAccessToken.validToken completion:nil graphRequest:self.graphRequestMock];
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
  [self stubGraphRequestWithResult:result error:nil connection:nil];

  [FBSDKProfile loadProfileWithToken:SampleAccessToken.validToken completion:nil graphRequest:self.graphRequestMock];
  XCTAssertNil(FBSDKProfile.currentProfile);
}

@end
