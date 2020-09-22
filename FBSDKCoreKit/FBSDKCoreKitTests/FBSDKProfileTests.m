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
#import "FBSDKProfile.h"
#import "FBSDKProfile+Internal.h"
#import "FBSDKTestCase.h"
#import "SampleAccessToken.h"
#import "SampleUserProfile.h"

@interface FBSDKSettings ()
+ (NSString *)userAgentSuffix;
+ (void)setUserAgentSuffix:(NSString *)suffix;
+ (void)resetLoggingBehaviorsCache;
+ (void)resetFacebookAppIDCache;
+ (void)resetFacebookUrlSchemeSuffixCache;
+ (void)resetFacebookClientTokenCache;
+ (void)resetFacebookDisplayNameCache;
+ (void)resetFacebookDomainPartCache;
+ (void)resetFacebookJpegCompressionQualityCache;
+ (void)resetFacebookAutoInitEnabledCache;
+ (void)resetFacebookInstrumentEnabledCache;
+ (void)resetFacebookAutoLogAppEventsEnabledCache;
+ (void)resetFacebookAdvertiserIDCollectionEnabledCache;
+ (void)resetUserAgentSuffixCache;
+ (void)resetFacebookCodelessDebugLogEnabledCache;
+ (void)resetDataProcessingOptionsCache;
@end

@interface FBSDKProfile (Testing)
+ (void)resetCurrentProfileCache;
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

@end
