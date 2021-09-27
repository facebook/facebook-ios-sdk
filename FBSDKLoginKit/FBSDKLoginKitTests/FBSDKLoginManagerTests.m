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

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#ifdef BUCK
 #import <FBSDKLoginKit+Internal/FBSDKLoginManager+Internal.h>
 #import <FBSDKLoginKit+Internal/FBSDKLoginManagerLogger.h>
 #import <FBSDKLoginKit+Internal/FBSDKPermission.h>
 #import <FBSDKLoginKit/FBSDKLoginConstants.h>
 #import <FBSDKLoginKit/FBSDKLoginManager.h>
 #import <FBSDKLoginKit/FBSDKLoginManagerLoginResult.h>
#else
 #import "FBSDKLoginConstants.h"
 #import "FBSDKLoginManager.h"
 #import "FBSDKLoginManager+Internal.h"
 #import "FBSDKLoginManagerLogger.h"
 #import "FBSDKLoginManagerLoginResult.h"
 #import "FBSDKPermission.h"
#endif

#import "FBSDKLoginKitTests-Swift.h"
#import "FBSDKLoginManager+Testing.h"

static NSString *const kFakeAppID = @"7391628439";
static NSString *const kFakeChallenge = @"a =bcdef";
static NSString *const kFakeNonce = @"fedcb =a";
static NSString *const kFakeJTI = @"a jti is just any string";

@interface FBSDKInternalUtility (Testing)

+ (void)configureWithInfoDictionaryProvider:(id<FBSDKInfoDictionaryProviding>)infoDictionaryProvider;
+ (void)reset;

@end

@interface FBSDKAuthenticationTokenFactory (Testing)

+ (void)setSkipSignatureVerification:(BOOL)value;

@end

@interface TestFBSDKBridgeAPI : FBSDKBridgeAPI

@property (nonatomic) int openURLWithSFVCCount;
@property (nonatomic) int openURLCount;

@end

@implementation TestFBSDKBridgeAPI

- (void)openURLWithSafariViewController:(NSURL *)url
                                 sender:(id<FBSDKURLOpening>)sender
                     fromViewController:(UIViewController *)fromViewController
                                handler:(FBSDKSuccessBlock)handler
{
  _openURLWithSFVCCount += 1;
  handler(YES, nil);
}

- (void)openURL:(NSURL *)url sender:(id<FBSDKURLOpening>)sender handler:(FBSDKSuccessBlock)handler
{
  _openURLCount += 1;
  handler(YES, nil);
}

@end

@interface FBSDKLoginManagerTests : XCTestCase

@property (nonatomic) NSDictionary<NSString *, id> *claims;
@property (nonatomic) NSDictionary<NSString *, id> *header;
@property (nonatomic) TestInternalUtility *internalUtility;
@property (nonatomic) FBSDKLoginManager *loginManager;
@property (nonatomic) TestKeychainStoreFactory *keychainStoreFactory;
@property (nonatomic) TestKeychainStore *keychainStore;
@property (nonatomic) TestGraphRequestConnectionFactory *graphRequestConnectionFactory;
@property (nonatomic) TestGraphRequestConnection *connection;
@property (nonatomic) TestURLOpener *urlOpener;

@end

@implementation FBSDKLoginManagerTests

- (void)setUp
{
  [super setUp];
  // @lint-ignore FBOBJCDISCOURAGEDFUNCTION
  NSDateFormatter *formatter = [NSDateFormatter new];
  formatter.dateFormat = @"MM/dd/yyyy";
  [FBSDKApplicationDelegate.sharedInstance application:UIApplication.sharedApplication
                         didFinishLaunchingWithOptions:@{}];

  self.internalUtility = [TestInternalUtility new];
  self.keychainStore = [TestKeychainStore new];
  self.keychainStoreFactory = [TestKeychainStoreFactory new];
  self.keychainStoreFactory.stubbedKeychainStore = self.keychainStore;
  self.connection = [TestGraphRequestConnection new];
  self.graphRequestConnectionFactory = [[TestGraphRequestConnectionFactory alloc] initWithStubbedConnection:self.connection];
  self.urlOpener = [TestURLOpener new];

  self.loginManager = [[FBSDKLoginManager alloc] initWithInternalUtility:self.internalUtility
                                                    keychainStoreFactory:self.keychainStoreFactory
                                                             tokenWallet:TestAccessTokenWallet.class
                                           graphRequestConnectionFactory:self.graphRequestConnectionFactory
                                                     authenticationToken:TestAuthenticationTokenWallet.class
                                                                 profile:TestProfileProvider.class
                                                               urlOpener:self.urlOpener
  ];

  FBSDKSettings.sharedSettings.appID = kFakeAppID;
  FBSDKProfile *testUser = [[FBSDKProfile alloc] initWithUserID:@"1234"
                                                      firstName:@"Test"
                                                     middleName:@"Middle"
                                                       lastName:@"User"
                                                           name:@"Test User"
                                                        linkURL:[NSURL URLWithString:@"https://www.facebook.com"]
                                                    refreshDate:nil
                                                       imageURL:[NSURL URLWithString:@"https://www.facebook.com/some_picture"]
                                                          email:@"email@email.com"
                                                      friendIDs:@[@"123", @"456"]
                                                       birthday:[formatter dateFromString:@"01/01/1990"]
                                                       ageRange:[FBSDKUserAgeRange ageRangeFromDictionary:@{@"min" : @((long)21)}]
                                                       hometown:[FBSDKLocation locationFromDictionary:@{@"id" : @"112724962075996",
                                                                                                        @"name" : @"Martinez, California"}]
                                                       location:[FBSDKLocation locationFromDictionary:@{@"id" : @"110843418940484",
                                                                                                        @"name" : @"Seattle, Washington"}]
                                                         gender:@"male"
                                                      isLimited:NO
  ];
  TestProfileProvider.currentProfile = testUser;

  FBSDKAuthenticationToken.currentAuthenticationToken = nil;
  TestAccessTokenWallet.currentAccessToken = nil;
  [self mockURLScheme];
  [self.internalUtility validateURLSchemes];

  long currentTime = [[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]] longValue];
  _claims = @{
    @"iss" : @"https://facebook.com/dialog/oauth",
    @"aud" : kFakeAppID,
    @"nonce" : kFakeNonce,
    @"exp" : @(currentTime + 60 * 60 * 48), // 2 days later
    @"iat" : @(currentTime - 60), // 1 min ago
    @"jti" : kFakeJTI,
    @"sub" : @"1234",
    @"name" : @"Test User",
    @"given_name" : @"Test",
    @"middle_name" : @"Middle",
    @"family_name" : @"User",
    @"email" : @"email@email.com",
    @"picture" : @"https://www.facebook.com/some_picture",
    @"user_friends" : @[@"123", @"456"],
    @"user_birthday" : @"01/01/1990",
    @"user_age_range" : @{@"min" : @((long)21)},
    @"user_hometown" : @{@"id" : @"112724962075996", @"name" : @"Martinez, California"},
    @"user_location" : @{@"id" : @"110843418940484", @"name" : @"Seattle, Washington"},
    @"user_gender" : @"male",
    @"user_link" : @"https://www.facebook.com",
  };

  _header = @{
    @"alg" : @"RS256",
    @"typ" : @"JWT",
    @"kid" : @"abcd1234",
  };
}

- (void)testInitializingLoginManager
{
  FBSDKLoginManager *loginManager = [FBSDKLoginManager new];
  NSObject *internalUtility = (NSObject *)loginManager.internalUtility;
  NSObject *keychainStore = (NSObject *)loginManager.keychainStore;
  NSObject *tokenWallet = (NSObject *)loginManager.tokenWallet;
  NSObject *graphRequestConnectionFactory = (NSObject *)loginManager.graphRequestConnectionFactory;
  NSObject *authenticationToken = (NSObject *)loginManager.authenticationToken;
  NSObject *profile = (NSObject *)loginManager.profile;
  NSObject *urlOpener = (NSObject *)loginManager.urlOpener;

  XCTAssertEqualObjects(internalUtility.class, FBSDKInternalUtility.class);
  XCTAssertEqualObjects(keychainStore.class, FBSDKKeychainStore.class);
  XCTAssertEqualObjects(tokenWallet.class, FBSDKAccessToken.class);
  XCTAssertEqualObjects(graphRequestConnectionFactory.class, FBSDKGraphRequestConnectionFactory.class);
  XCTAssertEqualObjects(authenticationToken.class, FBSDKAuthenticationToken.class);
  XCTAssertEqualObjects(profile.class, FBSDKProfile.class);
  XCTAssertEqualObjects(urlOpener.class, FBSDKBridgeAPI.class);
}

// MARK: openURL Auth

// verify basic case of first login and getting granted and declined permissions (is not classified as cancelled)
- (void)testOpenURLAuth
{
  __block BOOL handlerCalled;
  NSURL *url = [self authorizeURLWithFragment:@"granted_scopes=public_profile&denied_scopes=email%2Cuser_friends&signed_request=ggarbage.eyJhbGdvcml0aG0iOiJITUFDSEEyNTYiLCJjb2RlIjoid2h5bm90IiwiaXNzdWVkX2F0IjoxNDIyNTAyMDkyLCJ1c2VyX2lkIjoiMTIzIn0&access_token=sometoken&expires_in=5183949"];
  __weak FBSDKLoginManager *target = self.loginManager;

  [target setRequestedPermissions:[NSSet setWithObjects:@"email", @"user_friends", nil]];
  __block FBSDKAccessToken *tokenAfterAuth;
  [target setHandler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
    handlerCalled = YES;
    XCTAssertFalse(result.isCancelled);

    XCTAssertEqualObjects(@"sometoken", result.token.tokenString);
    tokenAfterAuth = TestAccessTokenWallet.currentAccessToken;
    XCTAssertEqualObjects(tokenAfterAuth, result.token);
    XCTAssertTrue([tokenAfterAuth.userID isEqualToString:@"123"], @"failed to parse userID");
    XCTAssertTrue([tokenAfterAuth.permissions isEqualToSet:[NSSet setWithObject:@"public_profile"]], @"unexpected permissions");
    XCTAssertTrue([result.grantedPermissions isEqualToSet:[NSSet setWithObject:@"public_profile"]], @"unexpected permissions");
    NSSet *expectedDeclined = [NSSet setWithObjects:@"email", @"user_friends", nil];
    XCTAssertEqualObjects(tokenAfterAuth.declinedPermissions, expectedDeclined, @"unexpected permissions");
    XCTAssertEqualObjects(result.declinedPermissions, expectedDeclined, @"unexpected permissions");

    TestKeychainStore *keychainStore = (TestKeychainStore *)target.keychainStore;
    XCTAssertNil(keychainStore.keychainDictionary[@"expected_login_challenge"]);
    XCTAssertTrue(keychainStore.wasStringForKeyCalled);
    XCTAssertNil(result.authenticationToken);
  }];
  XCTAssertTrue([self.keychainStore setString:kFakeChallenge forKey:@"expected_login_challenge" accessibility:[FBSDKDynamicFrameworkLoaderProxy loadkSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]]);

  XCTAssertTrue([target application:nil openURL:url sourceApplication:@"com.apple.mobilesafari" annotation:nil]);
  XCTAssert(handlerCalled, "Completion handler should be invoked synchronously");

  // now test a cancel and make sure the current token is not touched.
  url = [self authorizeURLWithParameters:@"error=access_denied&error_code=200&error_description=Permissions+error&error_reason=user_denied#_=_" joinedBy:@"?"];
  XCTAssertTrue([target application:nil openURL:url sourceApplication:@"com.apple.mobilesafari" annotation:nil]);
  FBSDKAccessToken *actualTokenAfterCancel = TestAccessTokenWallet.currentAccessToken;
  XCTAssertEqualObjects(tokenAfterAuth, actualTokenAfterCancel);
}

// verify basic case of first login and no declined permissions.
- (void)testOpenURLAuthNoDeclines
{
  NSURL *url = [self authorizeURLWithFragment:@"granted_scopes=public_profile&denied_scopes=&signed_request=ggarbage.eyJhbGdvcml0aG0iOiJITUFDSEEyNTYiLCJjb2RlIjoid2h5bm90IiwiaXNzdWVkX2F0IjoxNDIyNTAyMDkyLCJ1c2VyX2lkIjoiMTIzIn0&access_token=sometoken&expires_in=5183949"];
  TestAccessTokenWallet.currentAccessToken = SampleAccessTokens.validToken;
  XCTAssertTrue([self.loginManager application:nil openURL:url sourceApplication:@"com.apple.mobilesafari" annotation:nil]);
  FBSDKAccessToken *actualToken = TestAccessTokenWallet.currentAccessToken;
  XCTAssertTrue([actualToken.userID isEqualToString:@"user123"], @"failed to parse userID");
  NSSet *expectedDeclined = [NSSet set];
  XCTAssertEqualObjects(actualToken.declinedPermissions, expectedDeclined, @"unexpected permissions");
}

// verify that recentlyDeclined is a subset of requestedPermissions (i.e., other declined permissions are not in recentlyDeclined)
- (void)testOpenURLRecentlyDeclined
{
  __block BOOL handlerCalled;
  // receive url with denied_scopes more than what was requested.
  NSURL *url = [self authorizeURLWithFragment:@"granted_scopes=public_profile&denied_scopes=user_friends,user_likes&signed_request=ggarbage.eyJhbGdvcml0aG0iOiJITUFDSEEyNTYiLCJjb2RlIjoid2h5bm90IiwiaXNzdWVkX2F0IjoxNDIyNTAyMDkyLCJ1c2VyX2lkIjoiMTIzIn0&access_token=sometoken&expires_in=5183949"];

  FBSDKLoginManagerLoginResultBlock handler = ^(FBSDKLoginManagerLoginResult *result, NSError *error) {
    handlerCalled = YES;
    XCTAssertFalse(result.isCancelled);
    XCTAssertEqualObjects(result.declinedPermissions, [NSSet setWithObject:@"user_friends"]);
    XCTAssertEqualObjects(result.grantedPermissions, [NSSet setWithObject:@"public_profile"]);

    TestKeychainStore *keychainStore = (TestKeychainStore *)self.loginManager.keychainStore;
    XCTAssertNil(keychainStore.keychainDictionary[@"expected_login_challenge"]);
    XCTAssertTrue(keychainStore.wasStringForKeyCalled);
  };

  XCTAssertTrue([self.keychainStore setString:kFakeChallenge forKey:@"expected_login_challenge" accessibility:[FBSDKDynamicFrameworkLoaderProxy loadkSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]]);

  [self.loginManager setRequestedPermissions:[NSSet setWithObject:@"user_friends"]];
  [self.loginManager setHandler:handler];
  XCTAssertTrue([self.loginManager application:nil openURL:url sourceApplication:@"com.apple.mobilesafari" annotation:nil]);

  XCTAssert(handlerCalled, "Completion handler should be invoked synchronously");
}

- (void)testOpenURLNoGrantedPermission
{
  __block BOOL handlerCalled;
  // receive url with denied_scopes more than what was requested.
  NSURL *url = [self authorizeURLWithFragment:@"denied_scopes=user_friends,user_likes&signed_request=ggarbage.eyJhbGdvcml0aG0iOiJITUFDSEEyNTYiLCJjb2RlIjoid2h5bm90IiwiaXNzdWVkX2F0IjoxNDIyNTAyMDkyLCJ1c2VyX2lkIjoiMTIzIn0&access_token=sometoken&expires_in=5183949"];
  FBSDKLoginManagerLoginResultBlock handler = ^(FBSDKLoginManagerLoginResult *result, NSError *error) {
    handlerCalled = YES;
    XCTAssertNil(result.token);

    TestKeychainStore *keychainStore = (TestKeychainStore *)self.loginManager.keychainStore;
    XCTAssertNil(keychainStore.keychainDictionary[@"expected_login_challenge"]);
    XCTAssertTrue(keychainStore.wasStringForKeyCalled);
  };
  FBSDKLoginManager *target = self.loginManager;
  [target setRequestedPermissions:[NSSet setWithObject:@"user_friends"]];
  target.handler = handler;
  XCTAssertTrue([target application:nil openURL:url sourceApplication:@"com.apple.mobilesafari" annotation:nil]);

  XCTAssert(handlerCalled, "Completion handler should be invoked synchronously");
}

// verify that a reauth for already granted permissions is not treated as a cancellation.
- (void)testOpenURLReauthSamePermissionsIsNotCancelled
{
  // XCTestExpectation *expectation = [self expectationWithDescription:@"completed reauth"];
  // set up a current token with public_profile
  FBSDKAccessToken *existingToken = [[FBSDKAccessToken alloc] initWithTokenString:@"token"
                                                                      permissions:@[@"public_profile", @"read_stream"]
                                                              declinedPermissions:@[]
                                                               expiredPermissions:@[]
                                                                            appID:@""
                                                                           userID:@""
                                                                   expirationDate:nil
                                                                      refreshDate:nil
                                                         dataAccessExpirationDate:nil];
  FBSDKAccessToken.currentAccessToken = existingToken;
  NSURL *url = [self authorizeURLWithFragment:@"granted_scopes=public_profile,read_stream&denied_scopes=email%2Cuser_friends&signed_request=ggarbage.eyJhbGdvcml0aG0iOiJITUFDSEEyNTYiLCJjb2RlIjoid2h5bm90IiwiaXNzdWVkX2F0IjoxNDIyNTAyMDkyLCJ1c2VyX2lkIjoiMTIzIn0&access_token=sometoken&expires_in=5183949"];

  FBSDKLoginManager *target = self.loginManager;
  [target validateReauthentication:[TestAccessTokenWallet currentAccessToken] withResult:nil];

  FBSDKGraphRequest *capturedRequest = (FBSDKGraphRequest *)self.connection.capturedRequest;
  XCTAssertEqualObjects(
    capturedRequest.graphPath,
    @"me",
    "Should create a graph request with the expected graph path"
  );

  [target setRequestedPermissions:[NSSet setWithObjects:@"public_profile", @"read_stream", nil]];

  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Wnonnull"

  XCTAssertTrue([target application:nil openURL:url sourceApplication:@"com.apple.mobilesafari" annotation:nil]);
}

// verify that a reauth for already granted permissions is not treated as a cancellation.
- (void)testOpenURLReauthNoPermissionsIsNotCancelled
{
  // XCTestExpectation *expectation = [self expectationWithDescription:@"completed reauth"];
  // set up a current token with public_profile
  FBSDKAccessToken *existingToken = [[FBSDKAccessToken alloc] initWithTokenString:@"token"
                                                                      permissions:@[@"public_profile", @"read_stream"]
                                                              declinedPermissions:@[]
                                                               expiredPermissions:@[]
                                                                            appID:@""
                                                                           userID:@""
                                                                   expirationDate:nil
                                                                      refreshDate:nil
                                                         dataAccessExpirationDate:nil];
  FBSDKAccessToken.currentAccessToken = existingToken;
  NSURL *url = [self authorizeURLWithFragment:@"granted_scopes=public_profile,read_stream&denied_scopes=email%2Cuser_friends&signed_request=ggarbage.eyJhbGdvcml0aG0iOiJITUFDSEEyNTYiLCJjb2RlIjoid2h5bm90IiwiaXNzdWVkX2F0IjoxNDIyNTAyMDkyLCJ1c2VyX2lkIjoiMTIzIn0&access_token=sometoken&expires_in=5183949"];

  FBSDKLoginManager *target = self.loginManager;
  [target validateReauthentication:[TestAccessTokenWallet currentAccessToken] withResult:nil];

  XCTAssertEqualObjects(
    self.connection.capturedRequest.graphPath,
    @"me",
    "Should create a graph request with the expected graph path"
  );

  target.requestedPermissions = nil;

  XCTAssertTrue([target application:nil openURL:url sourceApplication:@"com.apple.mobilesafari" annotation:nil]);
}

- (void)testOpenURLWithBadChallenge
{
  __block BOOL handlerCalled;
  NSURL *url = [self authorizeURLWithFragment:@"granted_scopes=public_profile&denied_scopes=email%2Cuser_friends&signed_request=ggarbage.eyJhbGdvcml0aG0iOiJITUFDSEEyNTYiLCJjb2RlIjoid2h5bm90IiwiaXNzdWVkX2F0IjoxNDIyNTAyMDkyLCJ1c2VyX2lkIjoiMTIzIn0&access_token=sometoken&expires_in=5183949"
                                    challenge:@"someotherchallenge"];
  FBSDKLoginManager *target = self.loginManager;
  [target setRequestedPermissions:[NSSet setWithObjects:@"email", @"user_friends", nil]];
  [target setHandler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
    XCTAssertNotNil(error);
    XCTAssertNil(result.token);
    handlerCalled = YES;
  }];

  XCTAssertTrue([target application:nil openURL:url sourceApplication:@"com.apple.mobilesafari" annotation:nil]);

  XCTAssert(handlerCalled, "Completion handler should be invoked synchronously");
}

- (void)testOpenURLWithNoChallengeAndError
{
  __block BOOL handlerCalled;
  NSURL *url = [self authorizeURLWithParameters:@"error=some_error&error_code=999&error_message=Errorerror_reason=foo#_=_" joinedBy:@"?"];

  FBSDKLoginManager *target = self.loginManager;
  [target setRequestedPermissions:[NSSet setWithObjects:@"email", @"user_friends", nil]];
  [target setHandler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
    handlerCalled = YES;
    XCTAssertNotNil(error);
  }];

  XCTAssertTrue([target application:nil openURL:url sourceApplication:@"com.apple.mobilesafari" annotation:nil]);

  XCTAssert(handlerCalled, "Completion handler should be invoked synchronously");
}

- (void)testOpenURLWithNonFacebookURL
{
  NSURL *url = [NSURL URLWithString:@"test://test?granted_scopes=public_profile&access_token=sometoken&expires_in=5183949"];
  FBSDKLoginManager *target = self.loginManager;
  target.state = FBSDKLoginManagerStatePerformingLogin;

  XCTAssertFalse([target application:nil openURL:url sourceApplication:@"com.apple.mobilesafari" annotation:nil]);
  XCTAssertEqual(
    target.state,
    FBSDKLoginManagerStateIdle,
    "For verifying if handleImplicitCancelOfLogIn is being called we check if the state is in idle"
  );
}

- (void)testOpenURLAuthWithAuthenticationToken
{
  __block BOOL handlerCalled;
  FBSDKAuthenticationTokenFactory.skipSignatureVerification = YES;

  NSData *claimsData = [FBSDKTypeUtility dataWithJSONObject:_claims options:0 error:nil];
  NSString *encodedClaims = [FBSDKBase64 encodeData:claimsData];
  NSData *headerData = [FBSDKTypeUtility dataWithJSONObject:_header options:0 error:nil];
  NSString *encodedHeader = [FBSDKBase64 encodeData:headerData];

  NSString *tokenString = [NSString stringWithFormat:@"%@.%@.%@", encodedHeader, encodedClaims, @"signature"];
  NSArray *permissions = @[
    @"public_profile",
    @"email",
    @"user_friends",
    @"user_birthday",
    @"user_age_range",
    @"user_hometown",
    @"user_location",
    @"user_gender",
    @"user_link"
  ];
  NSURL *url = [self authorizeURLWithFragment:[NSString stringWithFormat:@"granted_scopes=%@&id_token=%@", [permissions componentsJoinedByString:@","], tokenString] challenge:kFakeChallenge];

  __weak FBSDKLoginManager *target = self.loginManager;
  FBSDKAccessToken.currentAccessToken = nil;
  [target setHandler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
    handlerCalled = YES;
    XCTAssertFalse(result.isCancelled);

    FBSDKAuthenticationToken *authToken = result.authenticationToken;
    XCTAssertNotNil(authToken);
    [self validateAuthenticationToken:authToken expectedTokenString:tokenString];

    TestKeychainStore *keychainStore = (TestKeychainStore *)target.keychainStore;
    XCTAssertNil(keychainStore.keychainDictionary[@"expected_login_challenge"]);
    XCTAssertTrue(keychainStore.wasStringForKeyCalled);

    [self validateProfile:TestProfileProvider.currentProfile];

    XCTAssertNil(result.token);
  }];

  XCTAssertTrue([self.keychainStore setString:kFakeNonce forKey:@"expected_login_nonce" accessibility:[FBSDKDynamicFrameworkLoaderProxy loadkSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]]);

  XCTAssertTrue([self.keychainStore setString:kFakeChallenge forKey:@"expected_login_challenge" accessibility:[FBSDKDynamicFrameworkLoaderProxy loadkSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]]);

  XCTAssertTrue([target application:nil openURL:url sourceApplication:@"com.apple.mobilesafari" annotation:nil]);

  XCTAssertTrue(handlerCalled, "Should invoke completion synchronously");

  FBSDKAuthenticationTokenFactory.skipSignatureVerification = NO;
}

- (void)testOpenURLAuthWithInvalidAuthenticationToken
{
  __block BOOL resultBlockInvoked = NO;
  NSURL *url = [self authorizeURLWithFragment:@"id_token=invalid_token" challenge:kFakeChallenge];
  __weak FBSDKLoginManager *target = self.loginManager;

  [target setHandler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
    XCTAssertNotNil(error);
    TestAuthenticationTokenWallet.currentAuthenticationToken = nil;
    resultBlockInvoked = YES;
  }];

  XCTAssertTrue([target application:nil openURL:url sourceApplication:@"com.apple.mobilesafari" annotation:nil]);
  XCTAssertTrue(resultBlockInvoked, "Should invoke completion synchronously");
}

- (void)testOpenURLAuthWithAuthenticationTokenWithAccessToken
{
  __block BOOL handlerCalled;
  __weak FBSDKLoginManager *target = self.loginManager;
  FBSDKAuthenticationTokenFactory.skipSignatureVerification = YES;

  NSData *claimsData = [FBSDKTypeUtility dataWithJSONObject:_claims options:0 error:nil];
  NSString *encodedClaims = [FBSDKBase64 encodeData:claimsData];
  NSData *headerData = [FBSDKTypeUtility dataWithJSONObject:_header options:0 error:nil];
  NSString *encodedHeader = [FBSDKBase64 encodeData:headerData];

  NSString *tokenString = [NSString stringWithFormat:@"%@.%@.%@", encodedHeader, encodedClaims, @"signature"];
  NSString *fragment = [@"granted_scopes=public_profile%2Cemail%2Cuser_friends&signed_request=ggarbage.eyJhbGdvcml0aG0iOiJITUFDSEEyNTYiLCJjb2RlIjoid2h5bm90IiwiaXNzdWVkX2F0IjoxNDIyNTAyMDkyLCJ1c2VyX2lkIjoiMTIzIn0&access_token=sometoken&expires_in=5183949&id_token=" stringByAppendingString:tokenString];
  NSURL *url = [self authorizeURLWithFragment:fragment challenge:kFakeChallenge];

  [target setHandler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
    XCTAssertFalse(result.isCancelled);

    FBSDKAuthenticationToken *authToken = result.authenticationToken;

    XCTAssertNotNil(authToken);
    [self validateAuthenticationToken:authToken expectedTokenString:tokenString];

    TestKeychainStore *keychainStore = (TestKeychainStore *)self.loginManager.keychainStore;
    XCTAssertNil(keychainStore.keychainDictionary[@"expected_login_challenge"]);
    XCTAssertTrue(keychainStore.wasStringForKeyCalled);

    [self validateProfile:TestProfileProvider.currentProfile];

    handlerCalled = YES;
  }];

  XCTAssertTrue([self.keychainStore setString:kFakeNonce forKey:@"expected_login_nonce" accessibility:[FBSDKDynamicFrameworkLoaderProxy loadkSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]]);

  XCTAssertTrue([self.keychainStore setString:kFakeChallenge forKey:@"expected_login_challenge" accessibility:[FBSDKDynamicFrameworkLoaderProxy loadkSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]]);

  XCTAssertTrue([target application:nil openURL:url sourceApplication:@"com.apple.mobilesafari" annotation:nil]);

  XCTAssertTrue(handlerCalled, "Should invoke completion synchronously");

  FBSDKAuthenticationTokenFactory.skipSignatureVerification = NO;
}

// MARK: FBSDKURLOpening

- (void)testApplicationDidBecomeActiveWhileLogin
{
  FBSDKLoginManager *manager = self.loginManager;
  manager.state = FBSDKLoginManagerStatePerformingLogin;

  [manager applicationDidBecomeActive:nil];

  XCTAssertEqual(manager.state, FBSDKLoginManagerStateIdle);
}

- (void)testIsAuthenticationURL
{
  FBSDKLoginManager *manager = self.loginManager;

  XCTAssertFalse([manager isAuthenticationURL:[NSURL URLWithString:@"https://www.facebook.com/some/test/url"]]);
  XCTAssertTrue([manager isAuthenticationURL:[NSURL URLWithString:@"https://www.facebook.com/v9.0/dialog/oauth/?test=test"]]);
  XCTAssertFalse([manager isAuthenticationURL:nil]);
  XCTAssertFalse([manager isAuthenticationURL:NSURL.new]);
  XCTAssertFalse([manager isAuthenticationURL:[NSURL URLWithString:@"123"]]);
}

- (void)testShouldStopPropagationOfURL
{
  FBSDKLoginManager *manager = self.loginManager;

  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"fb%@://no-op/test/", kFakeAppID]];
  XCTAssertTrue([manager shouldStopPropagationOfURL:url]);

  url = [NSURL URLWithString:[NSString stringWithFormat:@"fb%@://", kFakeAppID]];
  XCTAssertFalse([manager shouldStopPropagationOfURL:url]);

  url = [NSURL URLWithString:@"https://no-op/"];
  XCTAssertFalse([manager shouldStopPropagationOfURL:url]);
}

// MARK: Login

- (void)testLoginWithSFVC
{
  [self.loginManager logInWithPermissions:@[@"public_profile"] fromViewController:[UIViewController new] handler:nil];

  XCTAssertTrue(
    self.urlOpener.wasOpenURLWithSVCCalled,
    "openURLWithSafariViewController should be called"
  );

  XCTAssertFalse(
    self.urlOpener.wasOpenURLWithoutSVCCalled,
    "openURL should not be called"
  );

  XCTAssertNotNil(self.urlOpener.viewController);
}

- (void)testLoginWithBrowser
{
  [self.loginManager logInWithPermissions:@[@"public_profile"] fromViewController:nil handler:nil];

  XCTAssertTrue(
    self.loginManager.usedSFAuthSession,
    "If useSafariViewController is YES, _usedSFAuthSession should be YES and openURLWithSafariViewController should be invoked"
  );
}

- (void)testCallingLoginWithNilConfigurationShouldFail
{
  __block BOOL resultBlockInvoked = NO;
  FBSDKLoginManagerLoginResultBlock completion = ^(FBSDKLoginManagerLoginResult *result, NSError *error) {
    XCTAssertNil(result);
    XCTAssertNotNil(error);
    resultBlockInvoked = YES;
  };

  FBSDKLoginConfiguration *invalidConfig = [[FBSDKLoginConfiguration alloc] initWithPermissions:@[]
                                                                                       tracking:FBSDKLoginTrackingLimited
                                                                                          nonce:@" "];
  XCTAssertNil(invalidConfig);

  [self.loginManager logInFromViewController:nil configuration:invalidConfig completion:completion];
  XCTAssertTrue(resultBlockInvoked, "Should invoke completion synchronously");
}

- (void)testCallingLoginWithStateChange
{
  self.internalUtility.isFacebookAppInstalled = NO;
  self.loginManager.usedSFAuthSession = NO;
  self.loginManager.state = FBSDKLoginManagerStateStart;
  FBSDKLoginManager *manager = self.loginManager;
  [manager logInWithPermissions:@[@"public_profile"] fromViewController:nil handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
    XCTFail(@"Should not be called");
  }];
}

// MARK: Login Parameters

- (void)testLoginTrackingEnabledLoginParams
{
  FBSDKLoginConfiguration *config = [[FBSDKLoginConfiguration alloc]
                                     initWithPermissions:@[@"public_profile", @"email"]
                                     tracking:FBSDKLoginTrackingEnabled];
  FBSDKLoginManagerLogger *logger = [[FBSDKLoginManagerLogger alloc] initWithLoggingToken:@"123"
                                                                                 tracking:FBSDKLoginTrackingEnabled];

  NSDictionary<NSString *, id> *params = [self.loginManager logInParametersWithConfiguration:config loggingToken:nil logger:logger authMethod:@"sfvc_auth"];

  [self validateCommonLoginParameters:params];
  XCTAssertEqualObjects(params[@"response_type"], @"id_token,token_or_nonce,signed_request,graph_domain");
  XCTAssertEqualObjects(params[@"scope"], @"public_profile,email,openid");
  XCTAssertNotNil(params[@"nonce"]);
  XCTAssertNil(params[@"tp"], "Regular login should not send a tracking parameter");
  NSDictionary<NSString *, id> *state = [FBSDKBasicUtility objectForJSONString:params[@"state"] error:nil];
  XCTAssertEqualObjects(state[@"3_method"], @"sfvc_auth");
  XCTAssertEqual(params[@"auth_type"], FBSDKLoginAuthTypeRerequest);
}

- (void)testLoginTrackingLimitedLoginParams
{
  FBSDKLoginConfiguration *config = [[FBSDKLoginConfiguration alloc]
                                     initWithPermissions:@[@"public_profile", @"email"]
                                     tracking:FBSDKLoginTrackingLimited
                                     nonce:@"some_nonce"];
  FBSDKLoginManagerLogger *logger = [[FBSDKLoginManagerLogger alloc] initWithLoggingToken:@"123"
                                                                                 tracking:FBSDKLoginTrackingLimited];

  NSDictionary<NSString *, id> *params = [self.loginManager logInParametersWithConfiguration:config loggingToken:nil logger:logger authMethod:@"browser_auth"];

  [self validateCommonLoginParameters:params];
  XCTAssertEqualObjects(params[@"response_type"], @"id_token,graph_domain");
  XCTAssertEqualObjects(params[@"scope"], @"public_profile,email,openid");
  XCTAssertEqualObjects(params[@"nonce"], @"some_nonce");
  XCTAssertEqualObjects(params[@"tp"], @"ios_14_do_not_track");
  NSDictionary<NSString *, id> *state = [FBSDKBasicUtility objectForJSONString:params[@"state"] error:nil];
  XCTAssertEqualObjects(state[@"3_method"], @"browser_auth");
  XCTAssertEqual(params[@"auth_type"], FBSDKLoginAuthTypeRerequest);
}

- (void)testLoginParamsWithNilConfiguration
{
  __block BOOL wasCalled = NO;
  FBSDKLoginManagerLoginResultBlock handler = ^(FBSDKLoginManagerLoginResult *result, NSError *error) {
    XCTAssertNil(result);
    XCTAssertNotNil(error);
    wasCalled = YES;
  };
  [self.loginManager setHandler:handler];

  NSDictionary<NSString *, id> *params = [self.loginManager logInParametersWithConfiguration:nil loggingToken:nil logger:nil authMethod:@"sfvc_auth"];

  XCTAssertNil(params);
  XCTAssert(wasCalled);
}

- (void)testLoginParamsWithNilAuthType
{
  FBSDKLoginConfiguration *config = [[FBSDKLoginConfiguration alloc]
                                     initWithPermissions:@[@"public_profile", @"email"]
                                     tracking:FBSDKLoginTrackingEnabled
                                     messengerPageId:nil
                                     authType:nil];
  FBSDKLoginManagerLogger *logger = [[FBSDKLoginManagerLogger alloc] initWithLoggingToken:@"123"
                                                                                 tracking:FBSDKLoginTrackingEnabled];

  NSDictionary<NSString *, id> *params = [self.loginManager logInParametersWithConfiguration:config loggingToken:nil logger:logger authMethod:@"sfvc_auth"];

  [self validateCommonLoginParameters:params];
  XCTAssertEqualObjects(params[@"response_type"], @"id_token,token_or_nonce,signed_request,graph_domain");
  XCTAssertEqualObjects(params[@"scope"], @"public_profile,email,openid");
  XCTAssertNotNil(params[@"nonce"]);
  XCTAssertNil(params[@"tp"], "Regular login should not send a tracking parameter");
  NSDictionary<NSString *, id> *state = [FBSDKBasicUtility objectForJSONString:params[@"state"] error:nil];
  XCTAssertEqualObjects(state[@"3_method"], @"sfvc_auth");
  XCTAssertEqual(params[@"auth_type"], nil);
}

- (void)testLoginParamsWithExplicitlySetAuthType
{
  FBSDKLoginConfiguration *config = [[FBSDKLoginConfiguration alloc]
                                     initWithPermissions:@[@"public_profile", @"email"]
                                     tracking:FBSDKLoginTrackingEnabled
                                     messengerPageId:nil
                                     authType:FBSDKLoginAuthTypeReauthorize];
  FBSDKLoginManagerLogger *logger = [[FBSDKLoginManagerLogger alloc] initWithLoggingToken:@"123"
                                                                                 tracking:FBSDKLoginTrackingEnabled];

  NSDictionary<NSString *, id> *params = [self.loginManager logInParametersWithConfiguration:config loggingToken:nil logger:logger authMethod:@"sfvc_auth"];

  [self validateCommonLoginParameters:params];
  XCTAssertEqualObjects(params[@"response_type"], @"id_token,token_or_nonce,signed_request,graph_domain");
  XCTAssertEqualObjects(params[@"scope"], @"public_profile,email,openid");
  XCTAssertNotNil(params[@"nonce"]);
  XCTAssertNil(params[@"tp"], "Regular login should not send a tracking parameter");
  NSDictionary<NSString *, id> *state = [FBSDKBasicUtility objectForJSONString:params[@"state"] error:nil];
  XCTAssertEqualObjects(state[@"3_method"], @"sfvc_auth");
  XCTAssertEqual(params[@"auth_type"], FBSDKLoginAuthTypeReauthorize);
}

- (void)testLogInParametersFromURL
{
  NSURL *url = [NSURL URLWithString:@"myapp://somelink/?al_applink_data=%7B%22target_url%22%3Anull%2C%22extras%22%3A%7B%22fb_login%22%3A%22%7B%5C%22granted_scopes%5C%22%3A%5C%22public_profile%5C%22%2C%5C%22denied_scopes%5C%22%3A%5C%22%5C%22%2C%5C%22signed_request%5C%22%3A%5C%22ggarbage.eyJhbGdvcml0aG0iOiJITUFDSEEyNTYiLCJjb2RlIjoid2h5bm90IiwiaXNzdWVkX2F0IjoxNDIyNTAyMDkyLCJ1c2VyX2lkIjoiMTIzIn0%5C%22%2C%5C%22nonce%5C%22%3A%5C%22someNonce%5C%22%2C%5C%22data_access_expiration_time%5C%22%3A%5C%221607374566%5C%22%2C%5C%22expires_in%5C%22%3A%5C%225183401%5C%22%7D%22%7D%2C%22referer_app_link%22%3A%7B%22url%22%3A%22fb%3A%5C%2F%5C%2F%5C%2F%22%2C%22app_name%22%3A%22Facebook%22%7D%7D"];

  NSDictionary<NSString *, id> *params = [self.loginManager logInParametersFromURL:url];

  XCTAssertNotNil(params);
  XCTAssertEqualObjects(params[@"nonce"], @"someNonce");
  XCTAssertEqualObjects(params[@"granted_scopes"], @"public_profile");
  XCTAssertEqualObjects(params[@"denied_scopes"], @"");
}

// MARK: logInWithURL

- (void)testLogInWithURLFailWithInvalidLoginData
{
  __block BOOL handlerCalled;
  NSURL *urlWithInvalidLoginData = [NSURL URLWithString:@"myapp://somelink/?al_applink_data=%7B%22target_url%22%3Anull%2C%22extras%22%3A%7B%22fb_login%22%3A%22invalid%22%7D%2C%22referer_app_link%22%3A%7B%22url%22%3A%22fb%3A%5C%2F%5C%2F%5C%2F%22%2C%22app_name%22%3A%22Facebook%22%7D%7D"];
  FBSDKLoginManagerLoginResultBlock handler = ^(FBSDKLoginManagerLoginResult *result, NSError *error) {
    handlerCalled = YES;
    if (error) {
      XCTAssertNil(result);
    } else {
      XCTFail(@"Should have error");
    }
  };

  [self.loginManager logInWithURL:urlWithInvalidLoginData handler:handler];

  XCTAssert(handlerCalled, @"Completion handler should be invoked synchronously");
}

- (void)testLogInWithURLFailWithNoLoginData
{
  __block BOOL handlerCalled;
  NSURL *urlWithNoLoginData = [NSURL URLWithString:@"myapp://somelink/?al_applink_data=%7B%22target_url%22%3Anull%2C%22extras%22%3A%7B%22some_param%22%3A%22some_value%22%7D%2C%22referer_app_link%22%3A%7B%22url%22%3A%22fb%3A%5C%2F%5C%2F%5C%2F%22%2C%22app_name%22%3A%22Facebook%22%7D%7D"];
  FBSDKLoginManagerLoginResultBlock handler = ^(FBSDKLoginManagerLoginResult *result, NSError *error) {
    handlerCalled = YES;
    if (error) {
      XCTAssertNil(result);
    } else {
      XCTFail(@"Should have error");
    }
  };

  [self.loginManager logInWithURL:urlWithNoLoginData handler:handler];

  XCTAssert(handlerCalled, @"Completion handler should be invoked synchronously");
}

// MARK: Logout

- (void)testLogout
{
  [self.loginManager logOut];
  XCTAssertNil(TestAccessTokenWallet.currentAccessToken);
  XCTAssertNil(TestAuthenticationTokenWallet.currentAuthenticationToken);
  XCTAssertNil(TestProfileProvider.currentProfile);
}

// MARK: Keychain Store

- (void)testStoreExpectedNonce
{
  [self.loginManager storeExpectedNonce:@"some_nonce"];
  XCTAssertEqualObjects([self.loginManager.keychainStore stringForKey:@"expected_login_nonce"], @"some_nonce");

  [self.loginManager storeExpectedNonce:nil];
  XCTAssertNil([self.loginManager.keychainStore stringForKey:@"expected_login_nonce"]);
}

// MARK: Reauthorization

- (void)testReauthorizingWithoutAccessToken
{
  __block BOOL handlerCalled;
  [self.loginManager reauthorizeDataAccess:[UIViewController new]
                                   handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
                                     handlerCalled = true;
                                     XCTAssertNil(result, "Should not have a result when reauthorizing without a current access token");
                                     XCTAssertEqual(error.domain, FBSDKLoginErrorDomain);
                                     XCTAssertEqual(error.code, FBSDKLoginErrorMissingAccessToken);
                                   }];
  XCTAssert(handlerCalled, @"Completion handler should be invoked synchronously");
}

- (void)testReauthorizingWithAccessToken
{
  TestAccessTokenWallet.currentAccessToken = self.sampleAccessToken;
  FBSDKLoginManager *manager = self.loginManager;

  [self.loginManager reauthorizeDataAccess:[UIViewController new]
                                   handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {}];

  XCTAssertEqual(manager.configuration.tracking, FBSDKLoginTrackingEnabled);
  XCTAssertEqualObjects(manager.configuration.requestedPermissions, NSSet.new);
  XCTAssertNotNil(manager.configuration.nonce);
}

- (void)testReauthorizingWithInvalidStartState
{
  FBSDKLoginManager *manager = self.loginManager;
  manager.state = FBSDKLoginManagerStateStart;

  [manager reauthorizeDataAccess:[UIViewController new]
                         handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
                           XCTFail("Should not actually reauthorize and call the handler in this test");
                         }];
  TestGraphRequestConnection *connection = (TestGraphRequestConnection *)self.graphRequestConnectionFactory.stubbedConnection;
  XCTAssertEqualObjects(connection.capturedRequests, @[]);
  XCTAssertFalse(self.loginManager.state == FBSDKLoginManagerStateIdle);
}

// MARK: Permissions
- (void)testRecentlyGrantedPermissionsWithoutPreviouslyGrantedOrRequestedPermissions
{
  NSSet *grantedPermissions = [FBSDKPermission permissionsFromRawPermissions:[NSSet setWithArray:@[@"email", @"user_friends"]]];

  NSSet *recentlyGrantedPermissions = [self.loginManager recentlyGrantedPermissionsFromGrantedPermissions:grantedPermissions];
  XCTAssertEqualObjects(recentlyGrantedPermissions, grantedPermissions);
}

- (void)testRecentlyGrantedPermissionsWithPreviouslyGrantedPermissions
{
  NSSet *grantedPermissions = [FBSDKPermission permissionsFromRawPermissions:[NSSet setWithArray:@[@"email", @"user_friends"]]];
  TestAccessTokenWallet.currentAccessToken = self.sampleAccessToken;

  NSSet *recentlyGrantedPermissions = [self.loginManager recentlyGrantedPermissionsFromGrantedPermissions:grantedPermissions];
  XCTAssertEqualObjects(recentlyGrantedPermissions, grantedPermissions);
}

- (void)testRecentlyGrantedPermissionsWithRequestedPermissions
{
  // Permissions are set through creations of access token
  FBSDKAccessToken *testAccessToken = [[FBSDKAccessToken alloc] initWithTokenString:@"123"
                                                                        permissions:@[]
                                                                declinedPermissions:@[]
                                                                 expiredPermissions:@[]
                                                                              appID:kFakeAppID
                                                                             userID:@"123"
                                                                     expirationDate:nil
                                                                        refreshDate:nil
                                                           dataAccessExpirationDate:nil
  ];
  TestAccessTokenWallet.currentAccessToken = testAccessToken;

  NSSet *grantedPermissions = [FBSDKPermission permissionsFromRawPermissions:[NSSet setWithArray:@[@"email", @"user_friends"]]];
  [self.loginManager setRequestedPermissions:[NSSet setWithArray:@[@"user_friends"]]];

  NSSet *recentlyGrantedPermissions = [self.loginManager recentlyGrantedPermissionsFromGrantedPermissions:grantedPermissions];
  XCTAssertEqualObjects(recentlyGrantedPermissions, grantedPermissions);
}

- (void)testRecentlyGrantedPermissionsWithPreviouslyGrantedAndRequestedPermissions
{
  NSSet *grantedPermissions = [FBSDKPermission permissionsFromRawPermissions:[NSSet setWithArray:@[@"email", @"user_friends"]]];
  TestAccessTokenWallet.currentAccessToken = self.sampleAccessToken;
  [self.loginManager setRequestedPermissions:[NSSet setWithArray:@[@"user_friends"]]];

  NSSet *recentlyGrantedPermissions = [self.loginManager recentlyGrantedPermissionsFromGrantedPermissions:grantedPermissions];
  NSSet *expectedPermisssions = [FBSDKPermission permissionsFromRawPermissions:[NSSet setWithArray:@[@"user_friends"]]];
  XCTAssertEqualObjects(recentlyGrantedPermissions, expectedPermisssions);
}

- (void)testRecentlyDeclinedPermissionsWithoutRequestedPermissions
{
  NSSet *declinedPermissions = [FBSDKPermission permissionsFromRawPermissions:[NSSet setWithArray:@[@"email", @"user_friends"]]];

  NSSet *recentlyDeclinedPermissions = [self.loginManager recentlyDeclinedPermissionsFromDeclinedPermissions:declinedPermissions];
  XCTAssertEqual(recentlyDeclinedPermissions.count, 0);
}

- (void)testRecentlyDeclinedPermissionsWithRequestedPermissions
{
  NSSet *declinedPermissions = [FBSDKPermission permissionsFromRawPermissions:[NSSet setWithArray:@[@"email", @"user_friends"]]];
  [self.loginManager setRequestedPermissions:[NSSet setWithArray:@[@"user_friends"]]];

  NSSet *recentlyDeclinedPermissions = [self.loginManager recentlyDeclinedPermissionsFromDeclinedPermissions:declinedPermissions];
  NSSet *expectedPermisssions = [FBSDKPermission permissionsFromRawPermissions:[NSSet setWithArray:@[@"user_friends"]]];
  XCTAssertEqualObjects(recentlyDeclinedPermissions, expectedPermisssions);
}

// MARK: Reauthentication

- (void)testValidateReauthenticationGraphRequestCreation
{
  FBSDKLoginManager *manager = self.loginManager;
  FBSDKLoginManagerLoginResult *result = [[FBSDKLoginManagerLoginResult alloc] initWithToken:SampleAccessTokens.validToken authenticationToken:nil isCancelled:NO grantedPermissions:NSSet.new declinedPermissions:NSSet.new];

  [manager validateReauthentication:result.token withResult:result];

  id<FBSDKGraphRequest> capturedRequest = self.connection.capturedRequest;
  XCTAssertEqualObjects(
    capturedRequest.graphPath,
    @"me",
    "Should create a graph request with the expected graph path"
  );
  XCTAssertEqualObjects(
    capturedRequest.tokenString,
    SampleAccessTokens.validToken.tokenString,
    "Should create a graph request with the expected access token string"
  );
  XCTAssertEqual(
    capturedRequest.flags,
    FBSDKGraphRequestFlagDoNotInvalidateTokenOnError
    | FBSDKGraphRequestFlagDisableErrorRecovery,
    "The graph request should not invalidate the token on error or disable error recovery"
  );
}

- (void)testValidateReauthenticationCompletionWithError
{
  FBSDKLoginManager *manager = self.loginManager;

  FBSDKLoginManagerLoginResult *loginResult = [[FBSDKLoginManagerLoginResult alloc] initWithToken:SampleAccessTokens.validToken authenticationToken:nil isCancelled:NO grantedPermissions:NSSet.new declinedPermissions:NSSet.new];

  __block BOOL completionWasInvoked = NO;
  [manager setHandler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
    completionWasInvoked = YES;
    XCTAssertNotNil(error);
    XCTAssertNil(result);
  }];

  [manager validateReauthentication:SampleAccessTokens.validToken withResult:loginResult];
  self.connection.capturedCompletion(nil, nil, [FBSDKError unknownErrorWithMessage:@"test"]);

  XCTAssertTrue(completionWasInvoked);
}

- (void)testValidateReauthenticationCompletionWithMatchingUserID
{
  FBSDKLoginManager *manager = self.loginManager;

  FBSDKLoginManagerLoginResult *loginResult = [[FBSDKLoginManagerLoginResult alloc] initWithToken:SampleAccessTokens.validToken authenticationToken:nil isCancelled:NO grantedPermissions:NSSet.new declinedPermissions:NSSet.new];

  __block BOOL completionWasInvoked = NO;
  [manager setHandler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
    completionWasInvoked = YES;
    XCTAssertNil(error);
    XCTAssertEqualObjects(result, loginResult);
  }];

  [manager validateReauthentication:SampleAccessTokens.validToken withResult:loginResult];
  self.connection.capturedCompletion(nil, @{@"id" : SampleAccessTokens.validToken.userID}, nil);

  XCTAssertTrue(completionWasInvoked);
}

- (void)testValidateReauthenticationCompletionWithMismatchedUserID
{
  FBSDKLoginManager *manager = self.loginManager;
  FBSDKLoginManagerLoginResult *loginResult = [[FBSDKLoginManagerLoginResult alloc] initWithToken:SampleAccessTokens.validToken authenticationToken:nil isCancelled:NO grantedPermissions:NSSet.new declinedPermissions:NSSet.new];

  __block BOOL completionWasInvoked = NO;
  [manager setHandler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
    completionWasInvoked = YES;
    XCTAssertNotNil(error);
    XCTAssertNil(result);
  }];

  [manager validateReauthentication:SampleAccessTokens.validToken withResult:loginResult];
  self.connection.capturedCompletion(nil, @{@"id" : @"456"}, nil);

  XCTAssertTrue(completionWasInvoked);
}

// MARK: isPerformingLogin

- (void)testIsPerformingLoginWhenIdle
{
  [self.loginManager setState:(FBSDKLoginManagerState)FBSDKLoginManagerStateIdle];
  XCTAssertFalse([self.loginManager isPerformingLogin]);
}

- (void)testIsPerformingLoginWhenStarted
{
  [self.loginManager setState:(FBSDKLoginManagerState)FBSDKLoginManagerStateStart];
  XCTAssertFalse([self.loginManager isPerformingLogin]);
}

- (void)testIsPerformingLoginWhenPerformingLogin
{
  [self.loginManager setState:(FBSDKLoginManagerState)FBSDKLoginManagerStatePerformingLogin];
  XCTAssert([self.loginManager isPerformingLogin]);
}

// MARK: Helpers

- (FBSDKAccessToken *)sampleAccessToken
{
  return [[FBSDKAccessToken alloc] initWithTokenString:self.name
                                           permissions:@[@"email"]
                                   declinedPermissions:@[]
                                    expiredPermissions:@[]
                                                 appID:@"abc123"
                                                userID:@"userID"
                                        expirationDate:nil
                                           refreshDate:nil
                              dataAccessExpirationDate:nil];
}

- (void)validateCommonLoginParameters:(NSDictionary<NSString *, id> *)params
{
  XCTAssertEqualObjects(params[@"client_id"], kFakeAppID);
  XCTAssertEqualObjects(params[@"display"], @"touch");
  XCTAssertEqualObjects(params[@"sdk"], @"ios");
  XCTAssertEqualObjects(params[@"return_scopes"], @"true");
  XCTAssertEqualObjects(params[@"fbapp_pres"], @0);
  XCTAssertEqualObjects(params[@"ies"], [FBSDKSettings isAutoLogAppEventsEnabled] ? @1 : @0);
  XCTAssertNotNil(params[@"e2e"]);

  NSDictionary<NSString *, id> *state = [FBSDKBasicUtility objectForJSONString:params[@"state"] error:nil];
  XCTAssertNotNil(state[@"challenge"]);
  XCTAssertNotNil(state[@"0_auth_logger_id"]);

  long long cbt = [params[@"cbt"] longLongValue];
  long long currentMilliseconds = round(1000 * [NSDate date].timeIntervalSince1970);
  XCTAssertEqualWithAccuracy(cbt, currentMilliseconds, 500);

  NSString *expectedRedirectUri = [NSString stringWithFormat:@"fb%@://authorize/", kFakeAppID];
  XCTAssertEqualObjects(params[@"redirect_uri"], expectedRedirectUri);
}

- (void)validateProfile:(FBSDKProfile *)profile
{
  XCTAssertNotNil(profile, @"user profile should be updated");
  XCTAssertEqualObjects(profile.name, _claims[@"name"], @"failed to parse user name");
  XCTAssertEqualObjects(profile.firstName, _claims[@"given_name"], @"failed to parse user first name");
  XCTAssertEqualObjects(profile.middleName, _claims[@"middle_name"], @"failed to parse user middle name");
  XCTAssertEqualObjects(profile.lastName, _claims[@"family_name"], @"failed to parse user last name");
  XCTAssertEqualObjects(profile.userID, _claims[@"sub"], @"failed to parse userID");
  XCTAssertEqualObjects(profile.imageURL.absoluteString, _claims[@"picture"], @"failed to parse user profile picture");
  XCTAssertEqualObjects(profile.email, _claims[@"email"], @"failed to parse user email");
  XCTAssertEqualObjects(profile.friendIDs, _claims[@"user_friends"], @"failed to parse user friends");
  NSDateFormatter *formatter = NSDateFormatter.new;
  formatter.dateFormat = @"MM/dd/yyyy";
  XCTAssertEqualObjects(
    [formatter stringFromDate:profile.birthday],
    _claims[@"user_birthday"],
    @"failed to parse user birthday"
  );
  XCTAssertEqualObjects(
    profile.ageRange,
    [FBSDKUserAgeRange ageRangeFromDictionary:_claims[@"user_age_range"]],
    @"failed to parse user age range"
  );
  XCTAssertEqualObjects(
    profile.hometown,
    [FBSDKLocation locationFromDictionary:_claims[@"user_hometown"]],
    @"failed to parse user hometown"
  );
  XCTAssertEqualObjects(
    profile.location,
    [FBSDKLocation locationFromDictionary:_claims[@"user_location"]],
    @"failed to parse user location"
  );
  XCTAssertEqualObjects(profile.gender, _claims[@"user_gender"], @"failed to parse user gender");
  XCTAssertEqualObjects(
    profile.linkURL,
    [NSURL URLWithString:_claims[@"user_link"]],
    @"failed to parse user link"
  );
}

- (NSURL *)authorizeURLWithParameters:(NSString *)parameters joinedBy:(NSString *)joinChar
{
  return [NSURL URLWithString:[NSString stringWithFormat:@"fb%@://authorize/%@%@", kFakeAppID, joinChar, parameters]];
}

- (NSURL *)authorizeURLWithFragment:(NSString *)fragment challenge:(NSString *)challenge
{
  challenge = [FBSDKUtility URLEncode:challenge];
  fragment = [NSString stringWithFormat:@"%@%@state=%@",
              fragment,
              fragment.length > 0 ? @"&" : @"",
              [FBSDKUtility URLEncode:[NSString stringWithFormat:@"{\"challenge\":\"%@\"}", challenge]]
  ];
  return [self authorizeURLWithParameters:fragment joinedBy:@"#"];
}

- (NSURL *)authorizeURLWithFragment:(NSString *)fragment
{
  return [self authorizeURLWithFragment:fragment challenge:kFakeChallenge];
}

- (void)mockURLScheme
{
  TestBundle *bundle = [[TestBundle alloc] initWithInfoDictionary:@{
                          @"CFBundleURLTypes" : @[
                            @{ @"CFBundleURLSchemes" : @[@"fb7391628439"] }
                          ]
                        }];

  [FBSDKInternalUtility reset];
  [FBSDKInternalUtility configureWithInfoDictionaryProvider:bundle];
}

- (void)validateAuthenticationToken:(FBSDKAuthenticationToken *)authToken
                expectedTokenString:(NSString *)tokenString
{
  XCTAssertNotNil(authToken, @"An Authentication token should be created after successful login");
  XCTAssertEqualObjects(authToken.tokenString, tokenString, @"A raw authentication token string should be stored");
  XCTAssertEqualObjects(authToken.nonce, kFakeNonce, @"The nonce claims in the authentication token should be stored");
}

@end
