/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "FBSDKCoreKit.h"
#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKInternalUtility+Internal.h"

@interface FBSDKInternalUtilityTests : XCTestCase

@property (nonatomic) TestBundle *bundle;
@property (nonatomic) TestAppEventsConfigurationProvider *appEventsConfigurationProvider;
@property (nonatomic) TestLoggerFactory *loggerFactory;
@property (nonatomic) TestLogger *logger;

@end

@implementation FBSDKInternalUtilityTests

- (void)setUp
{
  [super setUp];

  self.bundle = [TestBundle new];
  self.appEventsConfigurationProvider = [TestAppEventsConfigurationProvider new];
  self.loggerFactory = [TestLoggerFactory new];
  self.logger = [[TestLogger alloc] initWithLoggingBehavior:FBSDKLoggingBehaviorDeveloperErrors];
  self.loggerFactory.logger = self.logger;

  [FBSDKSettings.sharedSettings reset];
  [FBSDKSettings configureWithStore:[UserDefaultsSpy new]
     appEventsConfigurationProvider:self.appEventsConfigurationProvider
             infoDictionaryProvider:self.bundle
                        eventLogger:[TestAppEvents new]];

  [FBSDKInternalUtility.sharedUtility deleteFacebookCookies];
  [FBSDKInternalUtility reset];
  [FBSDKInternalUtility.sharedUtility configureWithInfoDictionaryProvider:self.bundle
                                                            loggerFactory:self.loggerFactory];
}

- (void)tearDown
{
  [FBSDKSettings.sharedSettings reset];
  [FBSDKInternalUtility reset];

  [super tearDown];
}

// MARK: - Facebook URL

- (void)testFacebookURL
{
  FBSDKSettings.sharedSettings.facebookDomainPart = @"";
  NSString *URLString;
  NSString *tier = FBSDKSettings.sharedSettings.facebookDomainPart;

  URLString = [FBSDKInternalUtility.sharedUtility
               facebookURLWithHostPrefix:@""
               path:@""
               queryParameters:@{}
               error:NULL].absoluteString;
  XCTAssertEqualObjects(URLString, @"https://facebook.com/" FBSDK_DEFAULT_GRAPH_API_VERSION);

  URLString = [FBSDKInternalUtility.sharedUtility
               facebookURLWithHostPrefix:@"m."
               path:@""
               queryParameters:@{}
               error:NULL].absoluteString;
  XCTAssertEqualObjects(URLString, @"https://m.facebook.com/" FBSDK_DEFAULT_GRAPH_API_VERSION);

  URLString = [FBSDKInternalUtility.sharedUtility
               facebookURLWithHostPrefix:@"m"
               path:@""
               queryParameters:@{}
               error:NULL].absoluteString;
  XCTAssertEqualObjects(URLString, @"https://m.facebook.com/" FBSDK_DEFAULT_GRAPH_API_VERSION);

  URLString = [FBSDKInternalUtility.sharedUtility facebookURLWithHostPrefix:@"m"
                                                                       path:@"/dialog/share"
                                                            queryParameters:@{}
                                                                      error:NULL].absoluteString;
  XCTAssertEqualObjects(URLString, @"https://m.facebook.com/" FBSDK_DEFAULT_GRAPH_API_VERSION @"/dialog/share");

  URLString = [FBSDKInternalUtility.sharedUtility facebookURLWithHostPrefix:@"m"
                                                                       path:@"dialog/share"
                                                            queryParameters:@{}
                                                                      error:NULL].absoluteString;
  XCTAssertEqualObjects(URLString, @"https://m.facebook.com/" FBSDK_DEFAULT_GRAPH_API_VERSION @"/dialog/share");

  URLString = [FBSDKInternalUtility.sharedUtility facebookURLWithHostPrefix:@"m"
                                                                       path:@"dialog/share"
                                                            queryParameters:@{ @"key" : @"value" }
                                                                      error:NULL].absoluteString;
  XCTAssertEqualObjects(
    URLString,
    @"https://m.facebook.com/" FBSDK_DEFAULT_GRAPH_API_VERSION @"/dialog/share?key=value"
  );

  URLString = [FBSDKInternalUtility.sharedUtility facebookURLWithHostPrefix:@"m"
                                                                       path:@"/v1.0/dialog/share"
                                                            queryParameters:@{}
                                                                      error:NULL].absoluteString;
  XCTAssertEqualObjects(URLString, @"https://m.facebook.com/v1.0/dialog/share");

  URLString = [FBSDKInternalUtility.sharedUtility facebookURLWithHostPrefix:@"m"
                                                                       path:@"/dialog/share"
                                                            queryParameters:@{}
                                                             defaultVersion:@"v2.0"
                                                                      error:NULL].absoluteString;
  XCTAssertEqualObjects(URLString, @"https://m.facebook.com/v2.0/dialog/share");

  URLString = [FBSDKInternalUtility.sharedUtility facebookURLWithHostPrefix:@"m"
                                                                       path:@"/v1.0/dialog/share"
                                                            queryParameters:@{}
                                                             defaultVersion:@"v2.0"
                                                                      error:NULL].absoluteString;
  XCTAssertEqualObjects(URLString, @"https://m.facebook.com/v1.0/dialog/share");

  URLString = [FBSDKInternalUtility.sharedUtility facebookURLWithHostPrefix:@"m"
                                                                       path:@"/v987654321.2/dialog/share"
                                                            queryParameters:@{}
                                                                      error:NULL].absoluteString;
  XCTAssertEqualObjects(URLString, @"https://m.facebook.com/v987654321.2/dialog/share");

  URLString = [FBSDKInternalUtility.sharedUtility facebookURLWithHostPrefix:@"m"
                                                                       path:@"/v.1/dialog/share"
                                                            queryParameters:@{}
                                                             defaultVersion:@"v2.0"
                                                                      error:NULL].absoluteString;
  XCTAssertEqualObjects(URLString, @"https://m.facebook.com/v2.0/v.1/dialog/share");

  URLString = [FBSDKInternalUtility.sharedUtility facebookURLWithHostPrefix:@"m"
                                                                       path:@"/v1/dialog/share"
                                                            queryParameters:@{}
                                                             defaultVersion:@"v2.0"
                                                                      error:NULL].absoluteString;
  XCTAssertEqualObjects(URLString, @"https://m.facebook.com/v2.0/v1/dialog/share");
  FBSDKSettings.sharedSettings.facebookDomainPart = tier;
  FBSDKSettings.sharedSettings.graphAPIVersion = @"v3.3";
  URLString = [FBSDKInternalUtility.sharedUtility facebookURLWithHostPrefix:@"m"
                                                                       path:@"/v1/dialog/share"
                                                            queryParameters:@{}
                                                             defaultVersion:@""
                                                                      error:NULL].absoluteString;
  XCTAssertEqualObjects(URLString, @"https://m.facebook.com/v3.3/v1/dialog/share");
  FBSDKSettings.sharedSettings.graphAPIVersion = FBSDK_DEFAULT_GRAPH_API_VERSION;
  URLString = [FBSDKInternalUtility.sharedUtility facebookURLWithHostPrefix:@"m"
                                                                       path:@"/dialog/share"
                                                            queryParameters:@{}
                                                             defaultVersion:@""
                                                                      error:NULL].absoluteString;
  XCTAssertEqualObjects(URLString, @"https://m.facebook.com/" FBSDK_DEFAULT_GRAPH_API_VERSION @"/dialog/share");
}

- (void)testFacebookGamingURL
{
  FBSDKSettings.sharedSettings.facebookDomainPart = @"";
  FBSDKAuthenticationToken *authToken = [[FBSDKAuthenticationToken alloc] initWithTokenString:@"token_string"
                                                                                        nonce:@"nonce"
                                                                                  graphDomain:@"gaming"];
  FBSDKAuthenticationToken.currentAuthenticationToken = authToken;
  NSString *URLString;

  URLString = [FBSDKInternalUtility.sharedUtility
               facebookURLWithHostPrefix:@"graph"
               path:@""
               queryParameters:@{}
               error:NULL].absoluteString;
  XCTAssertEqualObjects(URLString, @"https://graph.fb.gg/" FBSDK_DEFAULT_GRAPH_API_VERSION);

  URLString = [FBSDKInternalUtility.sharedUtility
               facebookURLWithHostPrefix:@"graph-video"
               path:@""
               queryParameters:@{}
               error:NULL].absoluteString;
  XCTAssertEqualObjects(URLString, @"https://graph-video.fb.gg/" FBSDK_DEFAULT_GRAPH_API_VERSION);
}

// MARK: - Extracting Permissions

- (void)testParsingPermissionsWithFuzzyValues
{
  NSMutableSet<NSString *> *grantedPermissions = [NSMutableSet set];
  NSMutableSet<NSString *> *declinedPermissions = [NSMutableSet set];
  NSMutableSet<NSString *> *expiredPermissions = [NSMutableSet set];

  // A lack of a runtime crash is considered a success here.
  for (int i = 0; i < 100; i++) {
    [FBSDKInternalUtility.sharedUtility extractPermissionsFromResponse:SampleRawRemotePermissionList.randomValues
                                                    grantedPermissions:grantedPermissions
                                                   declinedPermissions:declinedPermissions
                                                    expiredPermissions:expiredPermissions];
  }
}

- (void)testExtractingPermissionsFromResponseWithInvalidTopLevelKey
{
  NSMutableSet<NSString *> *grantedPermissions = [NSMutableSet set];
  NSMutableSet<NSString *> *declinedPermissions = [NSMutableSet set];
  NSMutableSet<NSString *> *expiredPermissions = [NSMutableSet set];

  [FBSDKInternalUtility.sharedUtility extractPermissionsFromResponse:SampleRawRemotePermissionList.missingTopLevelKey
                                                  grantedPermissions:grantedPermissions
                                                 declinedPermissions:declinedPermissions
                                                  expiredPermissions:expiredPermissions];
  XCTAssertEqual(grantedPermissions.count, 0, "Should not add granted permissions if top level key is missing");
  XCTAssertEqual(declinedPermissions.count, 0, "Should not add declined permissions if top level key is missing");
  XCTAssertEqual(expiredPermissions.count, 0, "Should not add expired permissions if top level key is missing");
}

- (void)testExtractingPermissionsFromResponseWithMissingPermissions
{
  NSMutableSet<NSString *> *grantedPermissions = [NSMutableSet set];
  NSMutableSet<NSString *> *declinedPermissions = [NSMutableSet set];
  NSMutableSet<NSString *> *expiredPermissions = [NSMutableSet set];

  [FBSDKInternalUtility.sharedUtility extractPermissionsFromResponse:SampleRawRemotePermissionList.missingPermissions
                                                  grantedPermissions:grantedPermissions
                                                 declinedPermissions:declinedPermissions
                                                  expiredPermissions:expiredPermissions];
  XCTAssertEqual(grantedPermissions.count, 0, "Should not add missing granted permissions");
  XCTAssertEqual(declinedPermissions.count, 0, "Should not add missing declined permissions");
  XCTAssertEqual(expiredPermissions.count, 0, "Should not add missing expired permissions");
}

- (void)testExtractingPermissionsFromResponseWithMissingStatus
{
  NSMutableSet<NSString *> *grantedPermissions = [NSMutableSet set];
  NSMutableSet<NSString *> *declinedPermissions = [NSMutableSet set];
  NSMutableSet<NSString *> *expiredPermissions = [NSMutableSet set];

  [FBSDKInternalUtility.sharedUtility extractPermissionsFromResponse:SampleRawRemotePermissionList.missingStatus
                                                  grantedPermissions:grantedPermissions
                                                 declinedPermissions:declinedPermissions
                                                  expiredPermissions:expiredPermissions];
  XCTAssertEqual(grantedPermissions.count, 0, "Should not add a permission with a missing status");
  XCTAssertEqual(declinedPermissions.count, 0, "Should not add a permission with a missing status");
  XCTAssertEqual(expiredPermissions.count, 0, "Should not add a permission with a missing status");
}

- (void)testExtractingPermissionsFromResponseWithValidPermissions
{
  NSMutableSet<NSString *> *grantedPermissions = [NSMutableSet set];
  NSMutableSet<NSString *> *declinedPermissions = [NSMutableSet set];
  NSMutableSet<NSString *> *expiredPermissions = [NSMutableSet set];

  [FBSDKInternalUtility.sharedUtility extractPermissionsFromResponse:SampleRawRemotePermissionList.validAllStatuses
                                                  grantedPermissions:grantedPermissions
                                                 declinedPermissions:declinedPermissions
                                                  expiredPermissions:expiredPermissions];
  XCTAssertEqual(grantedPermissions.count, 1, "Should add granted permissions when available");
  XCTAssertTrue([grantedPermissions containsObject:@"email"], "Should add the correct permission to granted permissions");

  XCTAssertEqual(declinedPermissions.count, 1, "Should add declined permissions when available");
  XCTAssertTrue([declinedPermissions containsObject:@"birthday"], "Should add the correct permission to declined permissions");

  XCTAssertEqual(expiredPermissions.count, 1, "Should add expired permissions when available");
  XCTAssertTrue([expiredPermissions containsObject:@"first_name"], "Should add the correct permission to expired permissions");
}

// MARK: - Can open URL scheme

- (void)testCanOpenUrlSchemeWithMissingScheme
{
  XCTAssertFalse(
    [FBSDKInternalUtility.sharedUtility _canOpenURLScheme:nil],
    "Should not be able to open a missing scheme"
  );

  XCTAssertNil(self.logger.capturedContents, "A developer error should not be logged for a nil scheme");
}

- (void)testCanOpenUrlSchemeWithInvalidSchemes
{
  NSArray *invalidSchemes = @[
    @"http:",
    @"",
    @"   ",
    @"#@%(*&#$(^#@!$",
    @"////foo",
    @"foo:",
    @"foo:/"
  ];

  for (NSString *scheme in invalidSchemes) {
    [FBSDKInternalUtility.sharedUtility _canOpenURLScheme:scheme];

    [self verifyTestLoggerLoggingBehavior:FBSDKLoggingBehaviorDeveloperErrors
                                 logEntry:[NSString stringWithFormat:@"Invalid URL scheme provided: %@", scheme]];
  }
}

- (void)testCanOpenUrlSchemeWithValidSchemes
{
  NSArray *validSchemes = @[
    @"foo",
    @"FOO",
    @"foo+bar",
    @"foo-bar",
    @"foo.bar"
  ];

  for (NSString *scheme in validSchemes) {
    [FBSDKInternalUtility.sharedUtility _canOpenURLScheme:scheme];

    XCTAssertNil(self.logger.capturedContents, "A developer error should not be logged for valid schemes");
  }
}

// MARK: - App URL Scheme

- (void)testAppURLSchemeWithMissingAppIdMissingSuffix
{
  FBSDKSettings.sharedSettings.appID = nil;
  FBSDKSettings.sharedSettings.appURLSchemeSuffix = nil;
  // This is not desired behavior but accurately reflects what is currently written.
  XCTAssertEqualObjects(
    [FBSDKInternalUtility.sharedUtility appURLScheme],
    @"fb",
    "Should return an app url scheme derived from the app id and app url scheme suffix"
  );
}

- (void)testAppURLSchemeWithMissingAppIdInvalidSuffix
{
  FBSDKSettings.sharedSettings.appID = nil;
  FBSDKSettings.sharedSettings.appURLSchemeSuffix = @"   ";
  // This is not desired behavior but accurately reflects what is currently written.
  XCTAssertEqualObjects(
    [FBSDKInternalUtility.sharedUtility appURLScheme],
    @"fb   ",
    "Should return an app url scheme derived from the app id and app url scheme suffix"
  );
}

- (void)testAppURLSchemeWithMissingAppIdValidSuffix
{
  FBSDKSettings.sharedSettings.appID = nil;
  FBSDKSettings.sharedSettings.appURLSchemeSuffix = @"foo";
  // This is not desired behavior but accurately reflects what is currently written.
  XCTAssertEqualObjects(
    [FBSDKInternalUtility.sharedUtility appURLScheme],
    @"fbfoo",
    "Should return an app url scheme derived from the app id and app url scheme suffix"
  );
}

- (void)testAppURLSchemeWithInvalidAppIdMissingSuffix
{
  FBSDKSettings.sharedSettings.appID = @" ";
  FBSDKSettings.sharedSettings.appURLSchemeSuffix = nil;
  NSString *expected = [NSString stringWithFormat:@"fb%@", FBSDKSettings.sharedSettings.appID];

  // This is not desired behavior but accurately reflects what is currently written.
  XCTAssertEqualObjects(
    [FBSDKInternalUtility.sharedUtility appURLScheme],
    expected,
    "Should return an app url scheme derived app id and app url scheme suffix defined in settings"
  );
}

- (void)testAppURLSchemeWithInvalidAppIdInvalidSuffix
{
  FBSDKSettings.sharedSettings.appID = @" ";
  FBSDKSettings.sharedSettings.appURLSchemeSuffix = @" ";
  NSString *expected = [NSString stringWithFormat:@"fb%@%@", FBSDKSettings.sharedSettings.appID, FBSDKSettings.sharedSettings.appURLSchemeSuffix];

  // This is not desired behavior but accurately reflects what is currently written.
  XCTAssertEqualObjects(
    [FBSDKInternalUtility.sharedUtility appURLScheme],
    expected,
    "Should return an app url scheme derived app id and app url scheme suffix defined in settings"
  );
}

- (void)testAppURLSchemeWithInvalidAppIdValidSuffix
{
  FBSDKSettings.sharedSettings.appID = @" ";
  FBSDKSettings.sharedSettings.appURLSchemeSuffix = @"foo";
  NSString *expected = [NSString stringWithFormat:@"fb %@", FBSDKSettings.sharedSettings.appURLSchemeSuffix];

  // This is not desired behavior but accurately reflects what is currently written.
  XCTAssertEqualObjects(
    [FBSDKInternalUtility.sharedUtility appURLScheme],
    expected,
    "Should return an app url scheme derived app id and app url scheme suffix defined in settings"
  );
}

- (void)testAppURLSchemeWithValidAppIdMissingSuffix
{
  FBSDKSettings.sharedSettings.appID = @"appid";
  FBSDKSettings.sharedSettings.appURLSchemeSuffix = nil;
  NSString *expected = [NSString stringWithFormat:@"fb%@", FBSDKSettings.sharedSettings.appID];

  XCTAssertEqualObjects(
    [FBSDKInternalUtility.sharedUtility appURLScheme],
    expected,
    "Should return an app url scheme derived app id and app url scheme suffix defined in settings"
  );
}

- (void)testAppURLSchemeWithValidAppIdInvalidSuffix
{
  FBSDKSettings.sharedSettings.appID = @"appid";
  FBSDKSettings.sharedSettings.appURLSchemeSuffix = @"   ";
  NSString *expected = [NSString stringWithFormat:@"fb%@%@", FBSDKSettings.sharedSettings.appID, FBSDKSettings.sharedSettings.appURLSchemeSuffix];

  // This is not desired behavior but accurately reflects what is currently written.
  XCTAssertEqualObjects(
    [FBSDKInternalUtility.sharedUtility appURLScheme],
    expected,
    "Should return an app url scheme derived app id and app url scheme suffix defined in settings"
  );
}

- (void)testAppURLSchemeWithValidAppIdValidSuffix
{
  FBSDKSettings.sharedSettings.appID = @"appid";
  FBSDKSettings.sharedSettings.appURLSchemeSuffix = @"foo";
  NSString *expected = [NSString stringWithFormat:@"fb%@%@", FBSDKSettings.sharedSettings.appID, FBSDKSettings.sharedSettings.appURLSchemeSuffix];

  XCTAssertEqualObjects(
    [FBSDKInternalUtility.sharedUtility appURLScheme],
    expected,
    "Should return an app url scheme derived app id and app url scheme suffix defined in settings"
  );
}

// MARK: - App URL with host

- (void)testAppUrlWithEmptyHost
{
  FBSDKSettings.sharedSettings.appID = @"appid";
  FBSDKSettings.sharedSettings.appURLSchemeSuffix = @"foo";

  NSURL *url = [FBSDKInternalUtility.sharedUtility appURLWithHost:@"" path:validPath queryParameters:self.validParameters error:nil];

  XCTAssertNil(url.host, "Should not set an empty host.");
}

- (void)testAppUrlWithValidHost
{
  FBSDKSettings.sharedSettings.appID = @"appid";
  FBSDKSettings.sharedSettings.appURLSchemeSuffix = @"foo";

  NSURL *url = [FBSDKInternalUtility.sharedUtility appURLWithHost:@"facebook" path:validPath queryParameters:self.validParameters error:nil];

  XCTAssertEqualObjects(url.host, @"facebook", "Should set the expected host.");
}

// MARK: - Check registered can open url scheme

- (void)testCheckRegisteredCanOpenURLScheme
{
  NSString *scheme = @"foo";

  [FBSDKInternalUtility.sharedUtility checkRegisteredCanOpenURLScheme:scheme];

  [self verifyTestLoggerLoggingBehavior:FBSDKLoggingBehaviorDeveloperErrors
                               logEntry:@"foo is missing from your Info.plist under LSApplicationQueriesSchemes and is required."];
}

- (void)testCheckRegisteredCanOpenURLSchemeMultipleTimes
{
  NSString *scheme = @"foo";

  XCTAssertEqual(self.logger.logEntryCallCount, 0, @"There should not be developer errors logged initially");

  [FBSDKInternalUtility.sharedUtility checkRegisteredCanOpenURLScheme:scheme];

  XCTAssertEqual(self.logger.logEntryCallCount, 1, @"One developer error should be logged");
  [self verifyTestLoggerLoggingBehavior:FBSDKLoggingBehaviorDeveloperErrors
                               logEntry:@"foo is missing from your Info.plist under LSApplicationQueriesSchemes and is required."];

  [FBSDKInternalUtility.sharedUtility checkRegisteredCanOpenURLScheme:scheme];
  XCTAssertEqual(self.logger.logEntryCallCount, 1, @"Additional errors should not be logged for the same error");
}

// MARK: - Dictionary from FBURL

- (void)testWithAuthorizeHostNoParameters
{
  NSURL *url = [[NSURL alloc] initWithString:@"foo://authorize"];
  NSDictionary<NSString *, id> *parameters = [FBSDKInternalUtility.sharedUtility parametersFromFBURL:url];

  XCTAssertEqualObjects(
    parameters,
    @{},
    "Should not extract parameters from a url if there are none"
  );
}

- (void)testWithAuthorizeHostNoFragment
{
  NSURL *url = [[NSURL alloc] initWithString:@"foo://authorize?foo=bar"];
  NSDictionary<NSString *, id> *parameters = [FBSDKInternalUtility.sharedUtility parametersFromFBURL:url];

  XCTAssertEqualObjects(
    parameters,
    @{@"foo" : @"bar"},
    "Should extract parameters from a url"
  );
}

- (void)testWithAuthorizeHostAndFragment
{
  NSURL *url = [[NSURL alloc] initWithString:@"foo://authorize?foo=bar#param1=value1&param2=value2"];
  NSDictionary<NSString *, id> *parameters = [FBSDKInternalUtility.sharedUtility parametersFromFBURL:url];
  NSDictionary<NSString *, id> *expectedParameters = @{
    @"foo" : @"bar",
    @"param1" : @"value1",
    @"param2" : @"value2"
  };

  XCTAssertEqualObjects(
    parameters,
    expectedParameters,
    "Extracted parameters from an auth url should include fragment parameters"
  );
}

- (void)testWithoutAuthorizeHostNoParameters
{
  NSURL *url = [[NSURL alloc] initWithString:@"foo://example"];
  NSDictionary<NSString *, id> *parameters = [FBSDKInternalUtility.sharedUtility parametersFromFBURL:url];

  XCTAssertEqualObjects(
    parameters,
    @{},
    "Should not extract parameters from a url if there are none"
  );
}

- (void)testWithoutAuthorizeHostNoFragment
{
  NSURL *url = [[NSURL alloc] initWithString:@"foo://example?foo=bar"];
  NSDictionary<NSString *, id> *parameters = [FBSDKInternalUtility.sharedUtility parametersFromFBURL:url];

  XCTAssertEqualObjects(
    parameters,
    @{@"foo" : @"bar"},
    "Should extract parameters from a url"
  );
}

- (void)testWithoutAuthorizeHostWithFragment
{
  NSURL *url = [[NSURL alloc] initWithString:@"foo://example?foo=bar#param1=value1&param2=value2"];
  NSDictionary<NSString *, id> *parameters = [FBSDKInternalUtility.sharedUtility parametersFromFBURL:url];
  NSDictionary<NSString *, id> *expectedParameters = @{ @"foo" : @"bar" };

  XCTAssertEqualObjects(
    parameters,
    expectedParameters,
    "Extracted parameters from a non auth url should not include fragment parameters"
  );
}

// MARK: - Cookies

- (void)testDeletingDialogCookies
{
  NSHTTPCookie *cookie1 = [self cookieForUrl:self.dialogUrl];
  NSHTTPCookie *cookie2 = [self cookieForUrl:self.dialogUrl name:@"cookie 2"];

  [NSHTTPCookieStorage.sharedHTTPCookieStorage setCookie:cookie1];
  [NSHTTPCookieStorage.sharedHTTPCookieStorage setCookie:cookie2];

  NSArray *cookies = [NSHTTPCookieStorage.sharedHTTPCookieStorage cookiesForURL:self.dialogUrl];
  NSArray *expectedCookies = @[cookie1, cookie2];

  XCTAssertEqualObjects(cookies, expectedCookies, "Sanity check that there are cookies to delete");

  [FBSDKInternalUtility.sharedUtility deleteFacebookCookies];
  XCTAssertEqual(
    [NSHTTPCookieStorage.sharedHTTPCookieStorage cookiesForURL:self.dialogUrl],
    @[],
    "All cookies for the facebook dialog url should be deleted"
  );
}

- (void)testDeletingNonDialogCookies
{
  NSHTTPCookie *cookie = [self cookieForUrl:self.nonDialogUrl];
  [NSHTTPCookieStorage.sharedHTTPCookieStorage setCookie:cookie];

  NSArray *cookies = [NSHTTPCookieStorage.sharedHTTPCookieStorage cookiesForURL:self.nonDialogUrl];
  XCTAssertEqualObjects(cookies, @[cookie], "Sanity check that there are cookies to delete");

  [FBSDKInternalUtility.sharedUtility deleteFacebookCookies];
  XCTAssertEqualObjects(
    [NSHTTPCookieStorage.sharedHTTPCookieStorage cookiesForURL:self.nonDialogUrl],
    @[cookie],
    "Should only delete cookies for the dialog url"
  );
}

- (void)testDeletingMixOfCookies
{
  NSHTTPCookie *dialogCookie = [self cookieForUrl:self.dialogUrl];
  NSHTTPCookie *nonDialogCookie = [self cookieForUrl:self.nonDialogUrl];

  [NSHTTPCookieStorage.sharedHTTPCookieStorage setCookie:dialogCookie];
  [NSHTTPCookieStorage.sharedHTTPCookieStorage setCookie:nonDialogCookie];

  [FBSDKInternalUtility.sharedUtility deleteFacebookCookies];

  XCTAssertEqualObjects(
    [NSHTTPCookieStorage.sharedHTTPCookieStorage cookiesForURL:self.dialogUrl],
    @[],
    "Should delete cookies for the dialog url"
  );
  XCTAssertEqualObjects(
    [NSHTTPCookieStorage.sharedHTTPCookieStorage cookiesForURL:self.nonDialogUrl],
    @[nonDialogCookie],
    "Should only delete cookies for the dialog url"
  );
}

// MARK: - App Installation

- (void)testIsRegisteredCanOpenURLSchemeWithMissingScheme
{
  NSArray *querySchemes = @[];
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"LSApplicationQueriesSchemes" : querySchemes}];
  [FBSDKInternalUtility.sharedUtility configureWithInfoDictionaryProvider:self.bundle
                                                            loggerFactory:self.loggerFactory];

  XCTAssertFalse(
    [FBSDKInternalUtility.sharedUtility isRegisteredCanOpenURLScheme:self.name],
    "Should not be consider a scheme to be registered if it's missing from the application query schemes"
  );
}

- (void)testIsRegisteredCanOpenURLSchemeWithScheme
{
  NSArray *querySchemes = @[self.name];
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"LSApplicationQueriesSchemes" : querySchemes}];
  [FBSDKInternalUtility.sharedUtility configureWithInfoDictionaryProvider:self.bundle
                                                            loggerFactory:self.loggerFactory];

  XCTAssertTrue(
    [FBSDKInternalUtility.sharedUtility isRegisteredCanOpenURLScheme:self.name],
    "Should consider a scheme to be registered if it exists in the application query schemes"
  );
}

- (void)testIsRegisteredCanOpenURLSchemeCache
{
  NSArray *querySchemes = @[self.name];
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"LSApplicationQueriesSchemes" : querySchemes}];
  [FBSDKInternalUtility.sharedUtility configureWithInfoDictionaryProvider:self.bundle
                                                            loggerFactory:self.loggerFactory];

  XCTAssertTrue([FBSDKInternalUtility.sharedUtility isRegisteredCanOpenURLScheme:self.name], "Sanity check");

  [self.bundle setInfoDictionary:@{}];

  XCTAssertTrue([FBSDKInternalUtility.sharedUtility isRegisteredCanOpenURLScheme:self.name], "Should return the cached value of the main bundle and not the updated values");
}

- (void)testFacebookAppInstalledMissingQuerySchemes
{
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{}];
  [FBSDKInternalUtility.sharedUtility configureWithInfoDictionaryProvider:self.bundle
                                                            loggerFactory:self.loggerFactory];

  [FBSDKInternalUtility.sharedUtility isFacebookAppInstalled];

  [self verifyTestLoggerLoggingBehavior:FBSDKLoggingBehaviorDeveloperErrors
                               logEntry:facebookUrlSchemeMissingMessage];
}

- (void)testFacebookAppInstalledEmptyQuerySchemes
{
  NSArray *querySchemes = @[];
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"LSApplicationQueriesSchemes" : querySchemes}];
  [FBSDKInternalUtility.sharedUtility configureWithInfoDictionaryProvider:self.bundle
                                                            loggerFactory:self.loggerFactory];

  [FBSDKInternalUtility.sharedUtility isFacebookAppInstalled];

  [self verifyTestLoggerLoggingBehavior:FBSDKLoggingBehaviorDeveloperErrors
                               logEntry:facebookUrlSchemeMissingMessage];
}

- (void)testFacebookAppInstalledMissingQueryScheme
{
  NSArray *querySchemes = @[@"Foo"];
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"LSApplicationQueriesSchemes" : querySchemes}];
  [FBSDKInternalUtility.sharedUtility configureWithInfoDictionaryProvider:self.bundle
                                                            loggerFactory:self.loggerFactory];

  [FBSDKInternalUtility.sharedUtility isFacebookAppInstalled];

  [self verifyTestLoggerLoggingBehavior:FBSDKLoggingBehaviorDeveloperErrors
                               logEntry:facebookUrlSchemeMissingMessage];
}

- (void)testFacebookAppInstalledValidQueryScheme
{
  NSArray *querySchemes = @[@"fbauth2"];
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"LSApplicationQueriesSchemes" : querySchemes}];
  [FBSDKInternalUtility.sharedUtility configureWithInfoDictionaryProvider:self.bundle
                                                            loggerFactory:self.loggerFactory];

  [FBSDKInternalUtility.sharedUtility isFacebookAppInstalled];

  XCTAssertNil(TestLogger.capturedLoggingBehavior);
}

- (void)testFacebookAppInstalledCache
{
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{}];
  [FBSDKInternalUtility.sharedUtility configureWithInfoDictionaryProvider:self.bundle
                                                            loggerFactory:self.loggerFactory];

  XCTAssertEqual(self.logger.logEntryCallCount, 0, @"There should not be developer errors logged initially");

  [FBSDKInternalUtility.sharedUtility isFacebookAppInstalled];

  XCTAssertEqual(self.logger.logEntryCallCount, 1, @"One developer error should be logged");
  [self verifyTestLoggerLoggingBehavior:FBSDKLoggingBehaviorDeveloperErrors
                               logEntry:facebookUrlSchemeMissingMessage];

  // Calling it again should not result in an additional call to the singleShotLogEntry method
  [FBSDKInternalUtility.sharedUtility isFacebookAppInstalled];
  XCTAssertEqual(self.logger.logEntryCallCount, 1, @"Additional errors should not be logged for the same error");
}

- (void)testMessengerAppInstalledMissingQuerySchemes
{
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{}];
  [FBSDKInternalUtility.sharedUtility configureWithInfoDictionaryProvider:self.bundle
                                                            loggerFactory:self.loggerFactory];

  [FBSDKInternalUtility.sharedUtility isMessengerAppInstalled];

  [self verifyTestLoggerLoggingBehavior:FBSDKLoggingBehaviorDeveloperErrors
                               logEntry:messengerUrlSchemeMissingMessage];
}

- (void)testMessengerAppInstalledEmptyQuerySchemes
{
  NSArray *querySchemes = @[];
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"LSApplicationQueriesSchemes" : querySchemes}];
  [FBSDKInternalUtility.sharedUtility configureWithInfoDictionaryProvider:self.bundle
                                                            loggerFactory:self.loggerFactory];

  [FBSDKInternalUtility.sharedUtility isMessengerAppInstalled];

  [self verifyTestLoggerLoggingBehavior:FBSDKLoggingBehaviorDeveloperErrors
                               logEntry:messengerUrlSchemeMissingMessage];
}

- (void)testMessengerAppInstalledMissingQueryScheme
{
  NSArray *querySchemes = @[@"Foo"];
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"LSApplicationQueriesSchemes" : querySchemes}];
  [FBSDKInternalUtility.sharedUtility configureWithInfoDictionaryProvider:self.bundle
                                                            loggerFactory:self.loggerFactory];

  [FBSDKInternalUtility.sharedUtility isMessengerAppInstalled];

  [self verifyTestLoggerLoggingBehavior:FBSDKLoggingBehaviorDeveloperErrors
                               logEntry:messengerUrlSchemeMissingMessage];
}

- (void)testMessengerAppInstalledValidQueryScheme
{
  NSArray *querySchemes = @[@"fb-messenger-share-api"];
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"LSApplicationQueriesSchemes" : querySchemes}];
  [FBSDKInternalUtility.sharedUtility configureWithInfoDictionaryProvider:self.bundle
                                                            loggerFactory:self.loggerFactory];

  [FBSDKInternalUtility.sharedUtility isMessengerAppInstalled];

  XCTAssertNil(TestLogger.capturedLoggingBehavior);
}

- (void)testMessengerAppInstalledCache
{
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{}];
  [FBSDKInternalUtility.sharedUtility configureWithInfoDictionaryProvider:self.bundle
                                                            loggerFactory:self.loggerFactory];

  XCTAssertEqual(TestLogger.capturedLogEntries.count, 0, @"There should not be developer errors logged initially");

  [FBSDKInternalUtility.sharedUtility isMessengerAppInstalled];

  XCTAssertEqual(self.logger.logEntryCallCount, 1, @"One developer error should be logged");
  [self verifyTestLoggerLoggingBehavior:FBSDKLoggingBehaviorDeveloperErrors
                               logEntry:messengerUrlSchemeMissingMessage];

  // Calling it again should not result in an additional call to the singleShotLogEntry method
  [FBSDKInternalUtility.sharedUtility isMessengerAppInstalled];
  XCTAssertEqual(self.logger.logEntryCallCount, 1, @"Additional errors should not be logged for the same error");
}

// MARK: - Random Utility Methods

- (void)verifyTestLoggerLoggingBehavior:(FBSDKLoggingBehavior)loggingBehavior logEntry:(NSString *)logEntry
{
  XCTAssertEqual(self.loggerFactory.capturedLoggingBehavior, loggingBehavior);
  XCTAssertEqualObjects(self.logger.capturedContents, logEntry);
}

- (void)testIsBrowserURLWithNonBrowserURL
{
  NSArray *urls = @[
    [NSURL URLWithString:@"file://foo"],
    [NSURL URLWithString:@"example://bar"]
  ];

  for (NSURL *url in urls) {
    XCTAssertFalse([FBSDKInternalUtility.sharedUtility isBrowserURL:url], "%@ should not be considered a browser url", url.absoluteString);
  }
}

- (void)testIsBrowserURLWithBrowserURL
{
  NSArray *urls = @[
    [NSURL URLWithString:@"HTTPS://example.com"],
    [NSURL URLWithString:@"HTTP://example.com"],
    [NSURL URLWithString:@"https://example.com"],
    [NSURL URLWithString:@"http://example.com"],
  ];

  for (NSURL *url in urls) {
    XCTAssertTrue([FBSDKInternalUtility.sharedUtility isBrowserURL:url], "%@ should be considered a browser url", url.absoluteString);
  }
}

- (void)testIsFacebookBundleIdentifierWithInvalidIdentifiers
{
  NSArray *identifiers = @[
    @"",
    @"foo",
    @"com.foo.bar",
    @"com.facebook"
  ];

  for (NSString *identifier in identifiers) {
    XCTAssertFalse([FBSDKInternalUtility.sharedUtility isFacebookBundleIdentifier:identifier], "%@ should not be considered a facebook bundle indentifier", identifier);
  }
}

- (void)testIsFacebookBundleIdentifierWithValidIdentifiers
{
  NSArray *identifiers = @[
    @"com.facebook.",
    @"com.facebook.foo",
    @".com.facebook.",
    @".com.facebook.foo"
  ];

  for (NSString *identifier in identifiers) {
    XCTAssertTrue([FBSDKInternalUtility.sharedUtility isFacebookBundleIdentifier:identifier], "%@ should be considered a facebook bundle indentifier", identifier);
  }
}

- (void)testNonSafariBundleIdentifiers
{
  NSArray *identifiers = @[
    @"",
    @" ",
    @"com.foo"
  ];

  for (NSString *identifier in identifiers) {
    XCTAssertFalse(
      [FBSDKInternalUtility.sharedUtility isSafariBundleIdentifier:identifier],
      "%@ should not be considered a safari bundle identifier",
      identifier
    );
  }
}

- (void)testSafariBundleIdentifiers
{
  NSArray *identifiers = @[
    @"com.apple.mobilesafari",
    @"com.apple.SafariViewService",
  ];

  for (NSString *identifier in identifiers) {
    XCTAssertTrue(
      [FBSDKInternalUtility.sharedUtility isSafariBundleIdentifier:identifier],
      "%@ should be considered a safari bundle identifier",
      identifier
    );
  }
}

- (void)testValidatingAppIDWhenUninitialized
{
  [FBSDKInternalUtility reset];
  FBSDKSettings.sharedSettings.appID = @"abc";

  XCTAssertThrows([FBSDKInternalUtility.sharedUtility validateAppID]);
}

- (void)testValidatingAppID
{
  [FBSDKInternalUtility.sharedUtility configureWithInfoDictionaryProvider:self.bundle
                                                            loggerFactory:self.loggerFactory];
  FBSDKSettings.sharedSettings.appID = nil;

  XCTAssertThrows([FBSDKInternalUtility.sharedUtility validateAppID]);
}

- (void)testValidateClientAccessTokenWhenUninitialized
{
  [FBSDKInternalUtility reset];
  FBSDKSettings.sharedSettings.appID = @"abc";
  FBSDKSettings.sharedSettings.clientToken = @"123";

  XCTAssertThrows([FBSDKInternalUtility.sharedUtility validateRequiredClientAccessToken]);
}

- (void)testValidateClientAccessTokenWithoutClientTokenWithoutAppID
{
  [FBSDKInternalUtility.sharedUtility configureWithInfoDictionaryProvider:self.bundle
                                                            loggerFactory:self.loggerFactory];
  FBSDKSettings.sharedSettings.appID = nil;
  FBSDKSettings.sharedSettings.clientToken = nil;

  XCTAssertThrows([FBSDKInternalUtility.sharedUtility validateRequiredClientAccessToken]);
}

- (void)testValidateClientAccessTokenWithClientTokenWithoutAppID
{
  [FBSDKInternalUtility.sharedUtility configureWithInfoDictionaryProvider:self.bundle
                                                            loggerFactory:self.loggerFactory];
  FBSDKSettings.sharedSettings.appID = nil;
  FBSDKSettings.sharedSettings.clientToken = @"client123";

  XCTAssertEqualObjects(
    [FBSDKInternalUtility.sharedUtility validateRequiredClientAccessToken],
    @"(null)|client123",
    "A valid client-access token should include the app identifier and the client token"
  );
}

- (void)testValidateClientAccessTokenWithClientTokenWithAppID
{
  [FBSDKInternalUtility.sharedUtility configureWithInfoDictionaryProvider:self.bundle
                                                            loggerFactory:self.loggerFactory];
  FBSDKSettings.sharedSettings.appID = @"appid";
  FBSDKSettings.sharedSettings.clientToken = @"client123";

  XCTAssertEqualObjects(
    [FBSDKInternalUtility.sharedUtility validateRequiredClientAccessToken],
    @"appid|client123",
    "A valid client-access token should include the app identifier and the client token"
  );
}

- (void)testValidateClientAccessTokenWithoutClientTokenWithAppID
{
  FBSDKSettings.sharedSettings.appID = @"appid";
  FBSDKSettings.sharedSettings.clientToken = nil;

  XCTAssertThrows([FBSDKInternalUtility.sharedUtility validateRequiredClientAccessToken]);
}

- (void)testIsRegisteredUrlSchemeWithRegisteredScheme
{
  self.bundle = [self bundleWithRegisteredUrlSchemes:@[@"com.foo.bar"]];
  [FBSDKInternalUtility.sharedUtility configureWithInfoDictionaryProvider:self.bundle
                                                            loggerFactory:self.loggerFactory];

  XCTAssertTrue([FBSDKInternalUtility.sharedUtility isRegisteredURLScheme:@"com.foo.bar"], "Schemes in the bundle should be considered registered");
}

- (void)testIsRegisteredUrlSchemeWithoutRegisteredScheme
{
  self.bundle = [self bundleWithRegisteredUrlSchemes:@[@"com.foo.bar"]];
  [FBSDKInternalUtility.sharedUtility configureWithInfoDictionaryProvider:self.bundle
                                                            loggerFactory:self.loggerFactory];

  XCTAssertFalse([FBSDKInternalUtility.sharedUtility isRegisteredURLScheme:@"com.facebook"], "Schemes absent from the bundle should not be considered registered");
}

- (void)testIsRegisteredUrlSchemeCaching
{
  self.bundle = [TestBundle new];
  [FBSDKInternalUtility.sharedUtility configureWithInfoDictionaryProvider:self.bundle
                                                            loggerFactory:self.loggerFactory];

  [FBSDKInternalUtility.sharedUtility isRegisteredURLScheme:@"com.facebook"];

  XCTAssertTrue(
    self.bundle.didAccessInfoDictionary,
    "Should query the bundle for URL types"
  );
  [self.bundle reset];

  [FBSDKInternalUtility.sharedUtility isRegisteredURLScheme:@"com.facebook"];

  XCTAssertFalse(
    self.bundle.didAccessInfoDictionary,
    "Should not query the bundle more than once"
  );
}

- (void)testValidatingUrlSchemesWithoutAppID
{
  [FBSDKInternalUtility.sharedUtility configureWithInfoDictionaryProvider:self.bundle
                                                            loggerFactory:self.loggerFactory];
  FBSDKSettings.sharedSettings.appID = nil;

  XCTAssertThrows(
    [FBSDKInternalUtility.sharedUtility validateURLSchemes],
    "Cannot validate url schemes without an app identifier"
  );
}

- (void)testValidatingUrlSchemesWhenNotConfigured
{
  XCTAssertThrows(
    [FBSDKInternalUtility.sharedUtility validateURLSchemes],
    "Cannot validate url schemes before configuring"
  );
}

- (void)testValidatingUrlSchemesWithAppIdMatchingBundleEntry
{
  [FBSDKInternalUtility.sharedUtility configureWithInfoDictionaryProvider:self.bundle
                                                            loggerFactory:self.loggerFactory];
  FBSDKSettings.sharedSettings.appID = @"appid";
  FBSDKSettings.sharedSettings.appURLSchemeSuffix = nil;

  self.bundle = [self bundleWithRegisteredUrlSchemes:@[@"fbappid"]];
  [FBSDKInternalUtility.sharedUtility configureWithInfoDictionaryProvider:self.bundle
                                                            loggerFactory:self.loggerFactory];

  XCTAssertNoThrow(
    [FBSDKInternalUtility.sharedUtility validateURLSchemes],
    "The registered app url scheme must match the app id and url scheme suffix prepended with 'fb'"
  );
}

- (void)testValidatingUrlSchemesWithNonAppIdMatchingBundleEntry
{
  FBSDKSettings.sharedSettings.appID = @"appid";
  FBSDKSettings.sharedSettings.appURLSchemeSuffix = nil;

  self.bundle = [self bundleWithRegisteredUrlSchemes:@[@"fb123"]];
  [FBSDKInternalUtility.sharedUtility configureWithInfoDictionaryProvider:self.bundle
                                                            loggerFactory:self.loggerFactory];

  XCTAssertThrows(
    [FBSDKInternalUtility.sharedUtility validateURLSchemes],
    "The registered app url scheme must match the app id and url scheme suffix prepended with 'fb'"
  );
}

// We can't loop through these because of how stubbing works.
- (void)testValidatingFacebookUrlSchemes_api
{
  self.bundle = [self bundleWithRegisteredUrlSchemes:@[@"fbapi"]];
  [FBSDKInternalUtility.sharedUtility configureWithInfoDictionaryProvider:self.bundle
                                                            loggerFactory:self.loggerFactory];
  XCTAssertThrows([FBSDKInternalUtility.sharedUtility validateFacebookReservedURLSchemes], "Should throw an error if fbapi is present in the bundle url schemes");
}

// We can't loop through these because of how stubbing works.
- (void)testValidatingFacebookUrlSchemes_messenger
{
  self.bundle = [self bundleWithRegisteredUrlSchemes:@[@"fb-messenger-share-api"]];
  [FBSDKInternalUtility.sharedUtility configureWithInfoDictionaryProvider:self.bundle
                                                            loggerFactory:self.loggerFactory];
  XCTAssertThrows([FBSDKInternalUtility.sharedUtility validateFacebookReservedURLSchemes], "Should throw an error if fb-messenger-share-api is present in the bundle url schemes");
}

- (void)testExtendDictionaryWithDefaultDataProcessingOptions
{
  NSMutableDictionary<NSString *, id> *parameters = [NSMutableDictionary new];
  [FBSDKInternalUtility.sharedUtility extendDictionaryWithDataProcessingOptions:parameters];

  XCTAssertEqualObjects(parameters, @{}, "Parameters should not change with default data processing options");
}

- (void)testExtendDictionaryWithDataProcessingOptions
{
  [FBSDKSettings.sharedSettings setDataProcessingOptions:@[@"LDU"] country:10 state:100];
  NSMutableDictionary<NSString *, id> *parameters = [NSMutableDictionary new];
  [FBSDKInternalUtility.sharedUtility extendDictionaryWithDataProcessingOptions:parameters];

  NSDictionary *expectedParameters = @{
    @"data_processing_options" : @"[\"LDU\"]",
    @"data_processing_options_country" : @(10),
    @"data_processing_options_state" : @(100)
  };

  XCTAssertEqualObjects(parameters, expectedParameters, "Parameters is not extended with expected data processing options");
}

- (void)testIsPublishPermission
{
  NSArray *publishPermissions = @[
    @"publish",
    @"publishSomething",
    @"manage",
    @"manageSomething",
    @"ads_management",
    @"create_event",
    @"rsvp_event"
  ];
  for (NSString *permission in publishPermissions) {
    XCTAssertTrue([FBSDKInternalUtility.sharedUtility isPublishPermission:permission]);
  }

  NSArray *nonPublishPermissions = @[
    @"",
    @"email",
    @"_publish"
  ];
  for (NSString *permission in nonPublishPermissions) {
    XCTAssertFalse([FBSDKInternalUtility.sharedUtility isPublishPermission:permission]);
  }
}

- (void)testIsUnityWithMissingSuffix
{
  FBSDKSettings.sharedSettings.userAgentSuffix = nil;
  XCTAssertFalse([FBSDKInternalUtility.sharedUtility isUnity], "User agent should determine whether an app is Unity");
}

- (void)testIsUnityWithNonUnitySuffix
{
  FBSDKSettings.sharedSettings.userAgentSuffix = @"Foo";
  XCTAssertFalse([FBSDKInternalUtility.sharedUtility isUnity], "User agent should determine whether an app is Unity");
}

- (void)testIsUnityWithUnitySuffix
{
  FBSDKSettings.sharedSettings.userAgentSuffix = @"__Unity__";
  XCTAssertTrue([FBSDKInternalUtility.sharedUtility isUnity], "User agent should determine whether an app is Unity");
}

- (void)testHexadecimalStringFromData
{
  XCTAssertNil([FBSDKInternalUtility.sharedUtility hexadecimalStringFromData:NSData.data]);

  NSString *foo = @"foo";
  NSData *stringData = [foo dataUsingEncoding:NSUTF8StringEncoding];
  NSString *expected = @"666f6f";

  XCTAssertEqualObjects([FBSDKInternalUtility.sharedUtility hexadecimalStringFromData:stringData], expected);
}

- (void)testObjectIsEqualToObject
{
  id obj1 = @"foo";
  id obj2 = @"foo";
  id obj3 = @"bar";

  XCTAssertTrue([FBSDKInternalUtility.sharedUtility object:obj1 isEqualToObject:obj1]);
  XCTAssertTrue([FBSDKInternalUtility.sharedUtility object:obj1 isEqualToObject:obj2]);
  XCTAssertFalse([FBSDKInternalUtility.sharedUtility object:obj1 isEqualToObject:obj3]);

  obj1 = nil;
  XCTAssertFalse([FBSDKInternalUtility.sharedUtility object:obj1 isEqualToObject:obj2]);
  XCTAssertFalse([FBSDKInternalUtility.sharedUtility object:obj2 isEqualToObject:obj1]);
}

- (void)testCreatingUrlWithUnknownError // InvalidQueryString
{
  NSError *error = [NSError errorWithDomain:@"test" code:1 userInfo:nil];

  [FBSDKInternalUtility.sharedUtility URLWithScheme:FBSDKURLSchemeHTTPS host:@"example" path:@"/foo" queryParameters:@{@"a date" : NSDate.date} error:&error];

  XCTAssertEqualObjects(
    error.domain,
    @"com.facebook.sdk.core",
    "Creating a url with an error reference should repopulate the error domain correctly"
  );
  XCTAssertEqual(
    error.code,
    3,
    "Creating a url with an error reference should repopulate the error code correctly"
  );
  XCTAssertEqualObjects(
    [error.userInfo objectForKey:FBSDKErrorDeveloperMessageKey],
    @"Unknown error building URL.",
    "Creating a url with an error reference should repopulate the error message correctly"
  );
}

- (void)testCreatingUrlWithInvalidQueryString
{
  NSError *error = [NSError errorWithDomain:@"test" code:1 userInfo:nil];

  [FBSDKInternalUtility.sharedUtility URLWithScheme:FBSDKURLSchemeHTTPS host:@"example" path:@"/foo" queryParameters:(id) @{@[] : @"foo"} error:&error];

  XCTAssertEqualObjects(
    error.domain,
    @"com.facebook.sdk.core",
    "Creating a url with invalid parameters should repopulate the error domain correctly"
  );
  XCTAssertEqual(
    error.code,
    2,
    "Creating a url with invalid parameters should repopulate the error code correctly"
  );

  XCTAssertTrue(
    [[error.userInfo objectForKey:FBSDKErrorDeveloperMessageKey] hasPrefix:@"Invalid value for queryParameters:"],
    "Creating a url with invalid parameters should repopulate the error message correctly"
  );
}

// MARK: - Helpers

- (NSURL *)dialogUrl
{
  return [FBSDKInternalUtility.sharedUtility facebookURLWithHostPrefix:@"m."
                                                                  path:@"/dialog/"
                                                       queryParameters:@{}
                                                                 error:NULL];
}

- (NSURL *)nonDialogUrl
{
  return [FBSDKInternalUtility.sharedUtility facebookURLWithHostPrefix:@"m."
                                                                  path:@"/foo/"
                                                       queryParameters:@{}
                                                                 error:NULL];
}

- (NSHTTPCookie *)cookieForUrl:(NSURL *)url name:(NSString *)name
{
  return [NSHTTPCookie cookieWithProperties:@{
            NSHTTPCookieOriginURL : url,
            NSHTTPCookiePath : url.path,
            NSHTTPCookieName : name,
            NSHTTPCookieValue : @"Is good"
          }];
}

- (NSHTTPCookie *)cookieForUrl:(NSURL *)url
{
  return [self cookieForUrl:url name:@"MyCookie"];
}

- (NSDictionary<NSString *, id> *)validParameters
{
  return @{@"foo" : @"bar"};
}

NSString *const validPath = @"example";
NSString *const facebookUrlSchemeMissingMessage = @"fbapi is missing from your Info.plist under LSApplicationQueriesSchemes and is required.";
NSString *const messengerUrlSchemeMissingMessage = @"fb-messenger-share-api is missing from your Info.plist under LSApplicationQueriesSchemes and is required.";

- (TestBundle *)bundleWithRegisteredUrlSchemes:(NSArray<NSString *> *)schemes
{
  return [[TestBundle alloc] initWithInfoDictionary:@{
            @"CFBundleURLTypes" : @[
              @{ @"CFBundleURLSchemes" : schemes }
            ]
          }];
}

@end
