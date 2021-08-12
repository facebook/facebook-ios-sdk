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

#import <XCTest/XCTest.h>

#import "FBSDKAppEventsUtility.h"
#import "FBSDKCoreKit.h"
#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKSettings.h"
#import "FBSDKSettings+Internal.h"
#import "FBSDKSettingsProtocol.h"
#import "NSUserDefaults+FBSDKDataPersisting.h"

@interface FBSDKSettings ()
+ (void)reset;
+ (NSString *)userAgentSuffix;
+ (void)setUserAgentSuffix:(NSString *)suffix;
@end

@interface FBSDKSettingsTests : XCTestCase
@property (nonatomic) UserDefaultsSpy *userDefaultsSpy;
@property (nonatomic) TestBundle *bundle;
@property (nonatomic) TestEventLogger *logger;
@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@implementation FBSDKSettingsTests

static NSString *const emptyString = @"";
static NSString *const whiteSpaceToken = @"   ";

+ (void)setUp
{
  [super setUp];

  [FBSDKSettings reset];
}

- (void)setUp
{
  [super setUp];

  self.userDefaultsSpy = [UserDefaultsSpy new];
  self.bundle = [TestBundle new];
  self.logger = [TestEventLogger new];

  [FBSDKSettings configureWithStore:self.userDefaultsSpy
     appEventsConfigurationProvider:TestAppEventsConfigurationProvider.class
             infoDictionaryProvider:self.bundle
                        eventLogger:self.logger
  ];
}

- (void)tearDown
{
  [super tearDown];

  [FBSDKSettings reset];
}

- (void)testDefaultGraphAPIVersion
{
  XCTAssertEqualObjects(
    FBSDKSettings.graphAPIVersion,
    FBSDK_DEFAULT_GRAPH_API_VERSION,
    "Settings should provide a default graph api version"
  );
}

// MARK: Logging Behaviors

- (void)testSettingsBehaviorsFromMissingPlistEntry
{
  NSSet<FBSDKLoggingBehavior> *expected = [NSSet setWithArray:@[FBSDKLoggingBehaviorDeveloperErrors]];
  XCTAssertEqualObjects(
    FBSDKSettings.loggingBehaviors,
    expected,
    "Logging behaviors should default to developer errors when there is no plist entry"
  );
}

- (void)testSettingBehaviorsFromEmptyPlistEntry
{
  NSSet<FBSDKLoggingBehavior> *expected = [NSSet setWithArray:@[FBSDKLoggingBehaviorDeveloperErrors]];

  XCTAssertEqualObjects(
    FBSDKSettings.loggingBehaviors,
    expected,
    "Logging behaviors should default to developer errors when settings are created with an empty plist entry"
  );
}

- (void)testSettingBehaviorsFromPlistWithInvalidEntry
{
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"FacebookLoggingBehavior" : @[@"Foo"]}];
  FBSDKSettings.infoDictionaryProvider = self.bundle;

  NSSet<FBSDKLoggingBehavior> *expected = [NSSet setWithArray:@[@"Foo"]];
  XCTAssertEqualObjects(
    FBSDKSettings.loggingBehaviors,
    expected,
    "Logging behaviors should default to developer errors when settings are created with a plist that only has invalid entries but it does not"
  );
}

- (void)testSettingBehaviorsFromPlistWithValidEntry
{
  NSBundle *realBundle = [NSBundle bundleForClass:self.class];
  FBSDKSettings.infoDictionaryProvider = realBundle;

  NSSet<FBSDKLoggingBehavior> *expected = [NSSet setWithArray:@[FBSDKLoggingBehaviorInformational]];
  XCTAssertEqualObjects(
    FBSDKSettings.loggingBehaviors,
    expected,
    "Settings should pull information from the bundle"
  );
}

- (void)testLoggingBehaviorsInternalStorage
{
  self.bundle = (TestBundle *) FBSDKSettings.infoDictionaryProvider;
  FBSDKSettings.loggingBehaviors = [NSSet setWithArray:@[FBSDKLoggingBehaviorInformational]];

  XCTAssertNotNil(FBSDKSettings.loggingBehaviors, "sanity check");
  XCTAssertNil(
    self.userDefaultsSpy.capturedObjectRetrievalKey,
    "Should not attempt to access the cache to retrieve objects that have a current value"
  );
  XCTAssertNil(
    self.bundle.capturedKeys.lastObject,
    "Should not attempt to access the plist to retrieve objects that have a current value"
  );
}

// MARK: Domain Prefix

- (void)testSettingDomainPrefixFromMissingPlistEntry
{
  XCTAssertNil(
    FBSDKSettings.facebookDomainPart,
    "There should be no default value for a facebook domain prefix"
  );
}

- (void)testSettingDomainPrefixFromEmptyPlistEntry
{
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"FacebookDomainPart" : emptyString}];
  FBSDKSettings.infoDictionaryProvider = self.bundle;

  XCTAssertEqualObjects(
    FBSDKSettings.facebookDomainPart,
    emptyString,
    "Should not use an empty string as a facebook domain prefix but it does"
  );
}

- (void)testSettingFacebookDomainPrefixFromPlist
{
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"FacebookDomainPart" : @"beta"}];
  FBSDKSettings.infoDictionaryProvider = self.bundle;

  XCTAssertEqualObjects(
    FBSDKSettings.facebookDomainPart,
    @"beta",
    "A developer should be able to set any string as the facebook domain prefix to use in building urls"
  );
}

- (void)testSettingDomainPrefixWithPlistEntry
{
  NSString *domainPrefix = @"abc123";
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"FacebookDomainPart" : domainPrefix}];
  FBSDKSettings.infoDictionaryProvider = self.bundle;

  [FBSDKSettings setFacebookDomainPart:@"foo"];

  XCTAssertNil(
    self.userDefaultsSpy.capturedValues[@"FacebookDomainPart"],
    "Should not persist the value of a non-cachable property when setting it"
  );

  XCTAssertEqualObjects(
    FBSDKSettings.facebookDomainPart,
    @"foo",
    "Settings should return the explicitly set domain prefix over one gleaned from a plist entry"
  );
}

- (void)testSettingDomainPrefixWithoutPlistEntry
{
  [FBSDKSettings setFacebookDomainPart:@"foo"];

  XCTAssertNil(
    self.userDefaultsSpy.capturedValues[@"FacebookDomainPart"],
    "Should not persist the value of a non-cachable property when setting it"
  );
  XCTAssertEqualObjects(
    FBSDKSettings.facebookDomainPart,
    @"foo",
    "Settings should return the explicitly set domain prefix"
  );
}

- (void)testSettingEmptyDomainPrefix
{
  [FBSDKSettings setFacebookDomainPart:emptyString];

  XCTAssertNil(
    self.userDefaultsSpy.capturedValues[@"FacebookDomainPart"],
    "Should not persist the value of a non-cachable property when setting it"
  );
  XCTAssertEqualObjects(
    FBSDKSettings.facebookDomainPart,
    emptyString,
    "Should not store an invalid domain prefix but it does"
  );
}

- (void)testSettingWhitespaceOnlyDomainPrefix
{
  [FBSDKSettings setFacebookDomainPart:whiteSpaceToken];

  XCTAssertNil(
    self.userDefaultsSpy.capturedValues[@"FacebookDomainPart"],
    "Should not persist the value of a non-cachable property when setting it"
  );
  XCTAssertEqualObjects(
    FBSDKSettings.facebookDomainPart,
    whiteSpaceToken,
    "Should not store a whitespace only domain prefix but it does"
  );
}

- (void)testDomainPartInternalStorage
{
  FBSDKSettings.facebookDomainPart = @"foo";

  [self resetLoggingSideEffects];

  XCTAssertNotNil(FBSDKSettings.facebookDomainPart, "sanity check");
  XCTAssertNil(
    self.userDefaultsSpy.capturedObjectRetrievalKey,
    "Should not attempt to access the cache to retrieve objects that have a current value"
  );
  XCTAssertNil(
    self.bundle.capturedKeys.lastObject,
    "Should not attempt to access the plist to retrieve objects that have a current value"
  );
}

// MARK: Client Token

- (void)testClientTokenFromPlist
{
  NSString *clientToken = @"abc123";
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"FacebookClientToken" : clientToken}];
  FBSDKSettings.infoDictionaryProvider = self.bundle;

  XCTAssertEqualObjects(
    FBSDKSettings.clientToken,
    clientToken,
    "A developer should be able to set any string as the client token"
  );
}

- (void)testClientTokenFromMissingPlistEntry
{
  XCTAssertNil(
    FBSDKSettings.clientToken,
    "A client token should not have a default value if it is not available in the plist"
  );
}

- (void)testSettingClientTokenFromEmptyPlistEntry
{
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"FacebookClientToken" : emptyString}];
  FBSDKSettings.infoDictionaryProvider = self.bundle;

  XCTAssertEqualObjects(
    FBSDKSettings.clientToken,
    emptyString,
    "Should not use an empty string as a facebook client token but it will"
  );
}

- (void)testSettingClientTokenWithPlistEntry
{
  NSString *clientToken = @"abc123";
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"FacebookClientToken" : clientToken}];
  FBSDKSettings.infoDictionaryProvider = self.bundle;

  FBSDKSettings.clientToken = @"foo";

  XCTAssertNil(
    self.userDefaultsSpy.capturedValues[@"FacebookClientToken"],
    "Should not persist the value of a non-cachable property when setting it"
  );

  XCTAssertNil(
    self.userDefaultsSpy.capturedValues[@"FacebookClientToken"],
    "Should not persist the value of a non-cachable property when setting it"
  );
  XCTAssertEqual(
    FBSDKSettings.clientToken,
    @"foo",
    "Settings should return the explicitly set client token over one gleaned from a plist entry"
  );
}

- (void)testSettingClientTokenWithoutPlistEntry
{
  FBSDKSettings.clientToken = @"foo";

  XCTAssertNil(
    self.userDefaultsSpy.capturedValues[@"FacebookClientToken"],
    "Should not persist the value of a non-cachable property when setting it"
  );
  XCTAssertEqual(
    FBSDKSettings.clientToken,
    @"foo",
    "Settings should return the explicitly set client token"
  );
}

- (void)testSettingEmptyClientToken
{
  FBSDKSettings.clientToken = emptyString;

  XCTAssertNil(
    self.userDefaultsSpy.capturedValues[@"FacebookClientToken"],
    "Should not persist the value of a non-cachable property when setting it"
  );
  XCTAssertEqualObjects(
    FBSDKSettings.clientToken,
    emptyString,
    "Should not store an invalid token but it will"
  );
}

- (void)testSettingWhitespaceOnlyClientToken
{
  FBSDKSettings.clientToken = whiteSpaceToken;

  XCTAssertNil(
    self.userDefaultsSpy.capturedValues[@"FacebookClientToken"],
    "Should not persist the value of a non-cachable property when setting it"
  );
  XCTAssertEqualObjects(
    FBSDKSettings.clientToken,
    whiteSpaceToken,
    "Should not store a whitespace only client token but it will"
  );
}

- (void)testClientTokenInternalStorage
{
  FBSDKSettings.clientToken = @"foo";

  [self resetLoggingSideEffects];

  XCTAssertNotNil(FBSDKSettings.clientToken, "sanity check");
  XCTAssertNil(
    self.userDefaultsSpy.capturedObjectRetrievalKey,
    "Should not attempt to access the cache to retrieve objects that have a current value"
  );
  XCTAssertNil(
    self.bundle.capturedKeys.lastObject,
    "Should not attempt to access the plist to retrieve objects that have a current value"
  );
}

// MARK: App Identifier

- (void)testAppIdentifierFromPlist
{
  NSString *appIdentifier = @"abc1234";
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"FacebookAppID" : appIdentifier}];
  FBSDKSettings.infoDictionaryProvider = self.bundle;

  XCTAssertEqualObjects(
    FBSDKSettings.appID,
    appIdentifier,
    "A developer should be able to set any string as the app identifier"
  );
}

- (void)testAppIdentifierFromMissingPlistEntry
{
  XCTAssertNil(
    FBSDKSettings.appID,
    "An app identifier should not have a default value if it is not available in the plist"
  );
}

- (void)testSettingAppIdentifierFromEmptyPlistEntry
{
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"FacebookAppID" : emptyString}];
  FBSDKSettings.infoDictionaryProvider = self.bundle;

  XCTAssertEqualObjects(
    FBSDKSettings.appID,
    emptyString,
    "Should not use an empty string as an app identifier but it will"
  );
}

- (void)testSettingAppIdentifierWithPlistEntry
{
  NSString *appIdentifier = @"abc123";
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"FacebookAppID" : appIdentifier}];
  FBSDKSettings.infoDictionaryProvider = self.bundle;

  FBSDKSettings.appID = @"foo";

  XCTAssertNil(
    self.userDefaultsSpy.capturedValues[@"FacebookAppID"],
    "Should not persist the value of a non-cachable property when setting it"
  );
  XCTAssertEqualObjects(
    FBSDKSettings.appID,
    @"foo",
    "Settings should return the explicitly set app identifier over one gleaned from a plist entry"
  );
}

- (void)testSettingAppIdentifierWithoutPlistEntry
{
  FBSDKSettings.appID = @"foo";

  XCTAssertNil(
    self.userDefaultsSpy.capturedValues[@"FacebookAppID"],
    "Should not persist the value of a non-cachable property when setting it"
  );
  XCTAssertEqualObjects(
    FBSDKSettings.appID,
    @"foo",
    "Settings should return the explicitly set app identifier"
  );
}

- (void)testSettingEmptyAppIdentifier
{
  FBSDKSettings.appID = emptyString;

  XCTAssertNil(
    self.userDefaultsSpy.capturedValues[@"FacebookAppID"],
    "Should not persist the value of a non-cachable property when setting it"
  );
  XCTAssertEqualObjects(
    FBSDKSettings.appID,
    emptyString,
    "Should not store an empty app identifier but it will"
  );
}

- (void)testSettingWhitespaceOnlyAppIdentifier
{
  FBSDKSettings.appID = whiteSpaceToken;

  XCTAssertNil(
    self.userDefaultsSpy.capturedValues[@"FacebookAppID"],
    "Should not persist the value of a non-cachable property when setting it"
  );
  XCTAssertEqualObjects(
    FBSDKSettings.appID,
    whiteSpaceToken,
    "Should not store a whitespace only app identifier but it will"
  );
}

- (void)testAppIdentifierInternalStorage
{
  FBSDKSettings.appID = @"foo";

  [self resetLoggingSideEffects];

  XCTAssertNotNil(FBSDKSettings.appID, "sanity check");
  XCTAssertNil(
    self.userDefaultsSpy.capturedObjectRetrievalKey,
    "Should not attempt to access the cache to retrieve objects that have a current value"
  );
  XCTAssertNil(
    self.bundle.capturedKeys.lastObject,
    "Should not attempt to access the plist to retrieve objects that have a current value"
  );
}

// MARK: Display Name

- (void)testDisplayNameFromPlist
{
  NSString *displayName = @"abc123";
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"FacebookDisplayName" : displayName}];
  FBSDKSettings.infoDictionaryProvider = self.bundle;

  XCTAssertEqualObjects(
    FBSDKSettings.displayName,
    displayName,
    "A developer should be able to set any string as the display name"
  );
}

- (void)testDisplayNameFromMissingPlistEntry
{
  XCTAssertNil(
    FBSDKSettings.displayName,
    "A display name should not have a default value if it is not available in the plist"
  );
}

- (void)testSettingDisplayNameFromEmptyPlistEntry
{
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"FacebookDisplayName" : emptyString}];
  FBSDKSettings.infoDictionaryProvider = self.bundle;

  XCTAssertEqualObjects(
    FBSDKSettings.displayName,
    emptyString,
    "Should not use an empty string as a display name but it will"
  );
}

- (void)testSettingDisplayNameWithPlistEntry
{
  NSString *displayName = @"abc123";
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"FacebookDisplayName" : displayName}];
  FBSDKSettings.infoDictionaryProvider = self.bundle;

  FBSDKSettings.displayName = @"foo";

  XCTAssertNil(
    self.userDefaultsSpy.capturedValues[@"FacebookDisplayName"],
    "Should not persist the value of a non-cachable property when setting it"
  );
  XCTAssertEqual(
    FBSDKSettings.displayName,
    @"foo",
    "Settings should return the explicitly set display name over one gleaned from a plist entry"
  );
}

- (void)testSettingDisplayNameWithoutPlistEntry
{
  FBSDKSettings.displayName = @"foo";

  XCTAssertNil(
    self.userDefaultsSpy.capturedValues[@"FacebookDisplayName"],
    "Should not persist the value of a non-cachable property when setting it"
  );
  XCTAssertEqual(
    FBSDKSettings.displayName,
    @"foo",
    "Settings should return the explicitly set display name"
  );
}

- (void)testSettingEmptyDisplayName
{
  FBSDKSettings.displayName = emptyString;

  XCTAssertNil(
    self.userDefaultsSpy.capturedValues[@"FacebookDisplayName"],
    "Should not persist the value of a non-cachable property when setting it"
  );
  XCTAssertEqualObjects(
    FBSDKSettings.displayName,
    emptyString,
    "Should not store an empty display name but it will"
  );
}

- (void)testSettingWhitespaceOnlyDisplayName
{
  FBSDKSettings.displayName = whiteSpaceToken;

  XCTAssertNil(
    self.userDefaultsSpy.capturedValues[@"FacebookDisplayName"],
    "Should not persist the value of a non-cachable property when setting it"
  );
  XCTAssertEqualObjects(
    FBSDKSettings.displayName,
    whiteSpaceToken,
    "Should not store a whitespace only display name but it will"
  );
}

- (void)testDisplayNameInternalStorage
{
  FBSDKSettings.displayName = @"foo";

  [self resetLoggingSideEffects];

  XCTAssertNotNil(FBSDKSettings.displayName, "sanity check");
  XCTAssertNil(
    self.userDefaultsSpy.capturedObjectRetrievalKey,
    "Should not attempt to access the cache to retrieve objects that have a current value"
  );
  XCTAssertNil(
    self.bundle.capturedKeys.lastObject,
    "Should not attempt to access the plist to retrieve objects that have a current value"
  );
}

// MARK: JPEG Compression Quality

- (void)testJPEGCompressionQualityFromPlist
{
  NSNumber *jpegCompressionQuality = @0.1;
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"FacebookJpegCompressionQuality" : jpegCompressionQuality}];
  FBSDKSettings.infoDictionaryProvider = self.bundle;

  XCTAssertEqualWithAccuracy(
    FBSDKSettings.JPEGCompressionQuality,
    jpegCompressionQuality.doubleValue,
    0.01,
    "A developer should be able to set a jpeg compression quality via the plist"
  );
}

- (void)testJPEGCompressionQualityFromMissingPlistEntry
{
  XCTAssertEqualWithAccuracy(
    FBSDKSettings.JPEGCompressionQuality,
    0.9,
    0.01,
    "There should be a known default value for jpeg compression quality"
  );
}

- (void)testSettingJPEGCompressionQualityFromInvalidPlistEntry
{
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"FacebookJpegCompressionQuality" : @-2.0}];
  FBSDKSettings.infoDictionaryProvider = self.bundle;

  XCTAssertNotEqual(
    FBSDKSettings.JPEGCompressionQuality,
    -0.2,
    "Should not use a negative value as a jpeg compression quality"
  );
}

- (void)testSettingJPEGCompressionQualityWithPlistEntry
{
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"FacebookJpegCompressionQuality" : @0.2}];
  FBSDKSettings.infoDictionaryProvider = self.bundle;

  FBSDKSettings.JPEGCompressionQuality = 0.3;

  XCTAssertNil(
    self.userDefaultsSpy.capturedValues[@"FacebookJpegCompressionQuality"],
    "Should not persist the value of a non-cachable property when setting it"
  );
  XCTAssertEqualWithAccuracy(
    FBSDKSettings.JPEGCompressionQuality,
    @(0.3).doubleValue,
    0.01,
    "Settings should return the explicitly set jpeg compression quality over one gleaned from a plist entry"
  );
}

- (void)testSettingJPEGCompressionQualityWithoutPlistEntry
{
  FBSDKSettings.JPEGCompressionQuality = 1.0;

  XCTAssertNil(
    self.userDefaultsSpy.capturedValues[@"FacebookJpegCompressionQuality"],
    "Should not persist the value of a non-cachable property when setting it"
  );
  XCTAssertEqual(
    FBSDKSettings.JPEGCompressionQuality,
    1.0,
    "Settings should return the explicitly set jpeg compression quality"
  );
}

- (void)testSettingJPEGCompressionQualityTooLow
{
  FBSDKSettings.JPEGCompressionQuality = -0.1;

  XCTAssertNil(
    self.userDefaultsSpy.capturedValues[@"FacebookJpegCompressionQuality"],
    "Should not persist the value of a non-cachable property when setting it"
  );
  XCTAssertNotEqual(
    FBSDKSettings.JPEGCompressionQuality,
    -0.1,
    "Should not store a negative jpeg compression quality"
  );
}

- (void)testSettingJPEGCompressionQualityTooHigh
{
  FBSDKSettings.JPEGCompressionQuality = 1.1;

  XCTAssertNil(
    self.userDefaultsSpy.capturedValues[@"FacebookJpegCompressionQuality"],
    "Should not persist the value of a non-cachable property when setting it"
  );
  XCTAssertNotEqual(
    FBSDKSettings.JPEGCompressionQuality,
    1.1,
    "Should not store a jpeg compression quality that is larger than 1.0"
  );
}

- (void)testJPEGCompressionQualityInternalStorage
{
  FBSDKSettings.JPEGCompressionQuality = 1;

  [self resetLoggingSideEffects];

  XCTAssertEqual(FBSDKSettings.JPEGCompressionQuality, 1, "Sanity check");
  XCTAssertNil(
    self.userDefaultsSpy.capturedObjectRetrievalKey,
    "Should not attempt to access the cache to retrieve objects that have a current value"
  );
  XCTAssertNil(
    self.bundle.capturedKeys.lastObject,
    "Should not attempt to access the plist to retrieve objects that have a current value"
  );
}

// MARK: URL Scheme Suffix

- (void)testURLSchemeSuffixFromPlist
{
  NSString *urlSchemeSuffix = @"abc123";
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"FacebookUrlSchemeSuffix" : urlSchemeSuffix}];
  FBSDKSettings.infoDictionaryProvider = self.bundle;

  XCTAssertEqual(
    FBSDKSettings.appURLSchemeSuffix,
    urlSchemeSuffix,
    "A developer should be able to set any string as the url scheme suffix"
  );
}

- (void)testURLSchemeSuffixFromMissingPlistEntry
{
  XCTAssertNil(
    FBSDKSettings.appURLSchemeSuffix,
    "A url scheme suffix should not have a default value if it is not available in the plist"
  );
}

- (void)testSettingURLSchemeSuffixFromEmptyPlistEntry
{
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"FacebookUrlSchemeSuffix" : emptyString}];
  FBSDKSettings.infoDictionaryProvider = self.bundle;

  XCTAssertEqualObjects(
    FBSDKSettings.appURLSchemeSuffix,
    emptyString,
    "Should not use an empty string as a url scheme suffix but it will"
  );
}

- (void)testSettingURLSchemeSuffixWithPlistEntry
{
  NSString *urlSchemeSuffix = @"abc123";
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"FacebookUrlSchemeSuffix" : urlSchemeSuffix}];
  FBSDKSettings.infoDictionaryProvider = self.bundle;

  FBSDKSettings.appURLSchemeSuffix = @"foo";

  XCTAssertNil(
    self.userDefaultsSpy.capturedValues[@"FacebookUrlSchemeSuffix"],
    "Should not persist the value of a non-cachable property when setting it"
  );
  XCTAssertEqual(
    FBSDKSettings.appURLSchemeSuffix,
    @"foo",
    "Settings should return the explicitly set url scheme suffix over one gleaned from a plist entry"
  );
}

- (void)testSettingURLSchemeSuffixWithoutPlistEntry
{
  FBSDKSettings.appURLSchemeSuffix = @"foo";

  XCTAssertNil(
    self.userDefaultsSpy.capturedValues[@"FacebookUrlSchemeSuffix"],
    "Should not persist the value of a non-cachable property when setting it"
  );
  XCTAssertEqual(
    FBSDKSettings.appURLSchemeSuffix,
    @"foo",
    "Settings should return the explicitly set url scheme suffix"
  );
}

- (void)testSettingEmptyURLSchemeSuffix
{
  FBSDKSettings.appURLSchemeSuffix = emptyString;

  XCTAssertNil(
    self.userDefaultsSpy.capturedValues[@"FacebookUrlSchemeSuffix"],
    "Should not persist the value of a non-cachable property when setting it"
  );
  XCTAssertEqualObjects(
    FBSDKSettings.appURLSchemeSuffix,
    emptyString,
    "Should not store an empty url scheme suffix but it will"
  );
}

- (void)testSettingWhitespaceOnlyURLSchemeSuffix
{
  FBSDKSettings.appURLSchemeSuffix = whiteSpaceToken;

  XCTAssertNil(
    self.userDefaultsSpy.capturedValues[@"FacebookUrlSchemeSuffix"],
    "Should not persist the value of a non-cachable property when setting it"
  );
  XCTAssertEqualObjects(
    FBSDKSettings.appURLSchemeSuffix,
    whiteSpaceToken,
    "Should not store a whitespace only url scheme suffix but it will"
  );
}

- (void)testURLSchemeSuffixInternalStorage
{
  FBSDKSettings.appURLSchemeSuffix = @"foo";

  [self resetLoggingSideEffects];

  XCTAssertNotNil(FBSDKSettings.appURLSchemeSuffix, "sanity check");
  XCTAssertNil(
    self.userDefaultsSpy.capturedObjectRetrievalKey,
    "Should not attempt to access the cache to retrieve objects that have a current value"
  );
  XCTAssertNil(
    self.bundle.capturedKeys.lastObject,
    "Should not attempt to access the plist to retrieve objects that have a current value"
  );
}

// MARK: Auto Log App Events Enabled

- (void)testAutoLogAppEventsEnabledFromPlist
{
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"FacebookAutoLogAppEventsEnabled" : @NO}];
  FBSDKSettings.infoDictionaryProvider = self.bundle;

  XCTAssertFalse(
    FBSDKSettings.isAutoLogAppEventsEnabled,
    "A developer should be able to set the value of auto log app events from the plist"
  );
}

- (void)testAutoLogAppEventsEnabledDefaultValue
{
  XCTAssertTrue(
    FBSDKSettings.isAutoLogAppEventsEnabled,
    "Auto logging of app events should default to true when there is no plist value given"
  );
}

- (void)testAutoLogAppEventsEnabledInvalidPlistEntry
{
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"FacebookAutoLogAppEventsEnabled" : emptyString}];
  FBSDKSettings.infoDictionaryProvider = self.bundle;

  XCTAssertFalse(
    FBSDKSettings.isAutoLogAppEventsEnabled,
    "Auto logging of app events should default to true when there is an invalid plist value given but it does not"
  );
}

- (void)testSettingAutoLogAppEventsEnabled
{
  FBSDKSettings.autoLogAppEventsEnabled = false;

  XCTAssertNotNil(
    self.userDefaultsSpy.capturedValues[@"FacebookAutoLogAppEventsEnabled"],
    "Should persist the value of a cachable property when setting it"
  );
  XCTAssertFalse(
    FBSDKSettings.autoLogAppEventsEnabled,
    "Should use the explicitly set property"
  );
}

- (void)testOverridingCachedAutoLogAppEventsEnabled
{
  XCTAssertTrue(FBSDKSettings.isAutoLogAppEventsEnabled);

  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"FacebookAutoLogAppEventsEnabled" : @NO}];
  FBSDKSettings.infoDictionaryProvider = self.bundle;

  XCTAssertTrue(
    FBSDKSettings.isAutoLogAppEventsEnabled,
    "Should favor cached properties over those set in the plist"
  );
}

- (void)testAutoLogAppEventsEnabledInternalStorage
{
  FBSDKSettings.autoLogAppEventsEnabled = @YES;

  [self resetLoggingSideEffects];

  XCTAssertTrue(FBSDKSettings.autoLogAppEventsEnabled, "sanity check");
  XCTAssertNil(
    self.userDefaultsSpy.capturedObjectRetrievalKey,
    "Should not attempt to access the cache to retrieve objects that have a current value"
  );
  XCTAssertNil(
    self.bundle.capturedKeys.lastObject,
    "Should not attempt to access the plist to retrieve objects that have a current value"
  );
}

// MARK: Advertiser Identifier Collection Enabled

- (void)testFacebookAdvertiserIDCollectionEnabled
{
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"FacebookAdvertiserIDCollectionEnabled" : @NO}];
  FBSDKSettings.infoDictionaryProvider = self.bundle;

  XCTAssertFalse(
    FBSDKSettings.isAdvertiserIDCollectionEnabled,
    "A developer should be able to set whether advertiser ID collection is enabled from the plist"
  );
}

- (void)testFacebookAdvertiserIDCollectionEnabledDefaultValue
{
  XCTAssertTrue(
    FBSDKSettings.isAdvertiserIDCollectionEnabled,
    "Auto collection of advertiser id should default to true when there is no plist value given"
  );
}

- (void)testFacebookAdvertiserIDCollectionEnabledInvalidPlistEntry
{
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"FacebookAdvertiserIDCollectionEnabled" : emptyString}];
  FBSDKSettings.infoDictionaryProvider = self.bundle;

  XCTAssertFalse(
    FBSDKSettings.isAdvertiserIDCollectionEnabled,
    "Auto collection of advertiser id should default to true when there is an invalid plist value given but it does not"
  );
}

- (void)testSettingFacebookAdvertiserIDCollectionEnabled
{
  FBSDKSettings.advertiserIDCollectionEnabled = false;

  XCTAssertNotNil(
    self.userDefaultsSpy.capturedValues[@"FacebookAdvertiserIDCollectionEnabled"],
    "Should persist the value of a cachable property when setting it"
  );
  XCTAssertFalse(
    FBSDKSettings.advertiserIDCollectionEnabled,
    "Should use the explicitly set property"
  );
}

- (void)testOverridingCachedFacebookAdvertiserIDCollectionEnabled
{
  FBSDKSettings.advertiserIDCollectionEnabled = true;
  XCTAssertTrue(FBSDKSettings.isAdvertiserIDCollectionEnabled);

  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"FacebookAdvertiserIDCollectionEnabled" : @NO}];
  FBSDKSettings.infoDictionaryProvider = self.bundle;

  XCTAssertTrue(
    FBSDKSettings.isAdvertiserIDCollectionEnabled,
    "Should favor cached properties over those set in the plist"
  );
}

- (void)testAdvertiserIDCollectionEnabledInternalStorage
{
  FBSDKSettings.advertiserIDCollectionEnabled = @YES;

  [self resetLoggingSideEffects];

  XCTAssertTrue(FBSDKSettings.advertiserIDCollectionEnabled, "sanity check");
  XCTAssertNil(
    self.userDefaultsSpy.capturedObjectRetrievalKey,
    "Should not attempt to access the cache to retrieve objects that have a current value"
  );
  XCTAssertNil(
    self.bundle.capturedKeys.lastObject,
    "Should not attempt to access the plist to retrieve objects that have a current value"
  );
}

// MARK: SKAdNetwork Report Enabled

- (void)testFacebookSKAdNetworkReportEnabledFromPlist
{
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"FacebookSKAdNetworkReportEnabled" : @NO}];
  FBSDKSettings.infoDictionaryProvider = self.bundle;

  XCTAssertFalse(
    FBSDKSettings.SKAdNetworkReportEnabled,
    "A developer should be able to set the value of SKAdNetwork Report from the plist"
  );
}

- (void)testFacebookSKAdNetworkReportEnabledDefaultValue
{
  XCTAssertTrue(
    FBSDKSettings.SKAdNetworkReportEnabled,
    "SKAdNetwork Report should default to true when there is no plist value given"
  );
}

- (void)testFacebookSKAdNetworkReportEnabledInvalidPlistEntry
{
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"FacebookSKAdNetworkReportEnabled" : emptyString}];
  FBSDKSettings.infoDictionaryProvider = self.bundle;

  XCTAssertFalse(
    FBSDKSettings.SKAdNetworkReportEnabled,
    "SKAdNetwork Report should default to true when there is an invalid plist value given but it does not"
  );
}

- (void)testSettingFacebookSKAdNetworkReportEnabled
{
  FBSDKSettings.SKAdNetworkReportEnabled = NO;

  XCTAssertNotNil(
    self.userDefaultsSpy.capturedValues[@"FacebookSKAdNetworkReportEnabled"],
    "Should persist the value of a cachable property when setting it"
  );
  XCTAssertFalse(
    FBSDKSettings.SKAdNetworkReportEnabled,
    "Should use the explicitly set property"
  );
}

- (void)testOverridingCachedFacebookSKAdNetworkReportEnabled
{
  XCTAssertTrue(FBSDKSettings.SKAdNetworkReportEnabled);

  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"FacebookSKAdNetworkReportEnabled" : @NO}];
  FBSDKSettings.infoDictionaryProvider = self.bundle;

  XCTAssertTrue(
    FBSDKSettings.SKAdNetworkReportEnabled,
    "Should favor cached properties over those set in the plist"
  );
}

- (void)testFacebookSKAdNetworkReportEnabledInternalStorage
{
  FBSDKSettings.SKAdNetworkReportEnabled = YES;

  [self resetLoggingSideEffects];

  XCTAssertTrue(FBSDKSettings.SKAdNetworkReportEnabled, "sanity check");
  XCTAssertNil(
    self.userDefaultsSpy.capturedObjectRetrievalKey,
    "Should not attempt to access the cache to retrieve objects that have a current value"
  );
  XCTAssertNil(
    self.bundle.capturedKeys.lastObject,
    "Should not attempt to access the plist to retrieve objects that have a current value"
  );
}

// MARK: Codeless Debug Log Enabled

- (void)testFacebookCodelessDebugLogEnabled
{
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"FacebookCodelessDebugLogEnabled" : @NO}];
  FBSDKSettings.infoDictionaryProvider = self.bundle;

  XCTAssertFalse(
    FBSDKSettings.isCodelessDebugLogEnabled,
    "A developer should be able to set whether codeless debug logging is enabled from the plist"
  );
}

- (void)testFacebookCodelessDebugLogEnabledDefaultValue
{
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{}];
  FBSDKSettings.infoDictionaryProvider = self.bundle;

  XCTAssertFalse(
    FBSDKSettings.isCodelessDebugLogEnabled,
    "Codeless debug logging enabled should default to false when there is no plist value given"
  );
}

- (void)testFacebookCodelessDebugLogEnabledInvalidPlistEntry
{
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"FacebookCodelessDebugLogEnabled" : emptyString}];
  FBSDKSettings.infoDictionaryProvider = self.bundle;

  XCTAssertFalse(
    FBSDKSettings.isCodelessDebugLogEnabled,
    "Codeless debug logging enabled should default to true when there is an invalid plist value given but it does not"
  );
}

- (void)testSettingFacebookCodelessDebugLogEnabled
{
  FBSDKSettings.codelessDebugLogEnabled = false;

  XCTAssertNotNil(
    self.userDefaultsSpy.capturedValues[@"FacebookCodelessDebugLogEnabled"],
    "Should persist the value of a cachable property when setting it"
  );
  XCTAssertFalse(
    FBSDKSettings.codelessDebugLogEnabled,
    "Should use the explicitly set property"
  );
}

- (void)testOverridingCachedFacebookCodelessDebugLogEnabled
{
  FBSDKSettings.codelessDebugLogEnabled = true;
  XCTAssertTrue(FBSDKSettings.isCodelessDebugLogEnabled);

  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"FacebookCodelessDebugLogEnabled" : @NO}];
  FBSDKSettings.infoDictionaryProvider = self.bundle;

  XCTAssertTrue(
    FBSDKSettings.isCodelessDebugLogEnabled,
    "Should favor cached properties over those set in the plist"
  );
}

- (void)testCachedFacebookCodelessDebugLogEnabledInternalStorage
{
  FBSDKSettings.codelessDebugLogEnabled = @YES;

  [self resetLoggingSideEffects];

  XCTAssertTrue(FBSDKSettings.codelessDebugLogEnabled, "sanity check");
  XCTAssertNil(
    self.userDefaultsSpy.capturedObjectRetrievalKey,
    "Should not attempt to access the cache to retrieve objects that have a current value"
  );
  XCTAssertNil(
    self.bundle.capturedKeys.lastObject,
    "Should not attempt to access the plist to retrieve objects that have a current value"
  );
}

// MARK: Caching Properties

- (void)testInitialAccessForCachablePropertyWithNonEmptyCache
{
  // Using false because it is not the default value for `isAutoInitializationEnabled`
  self.userDefaultsSpy.capturedValues = @{ @"FacebookAutoLogAppEventsEnabled" : @NO };

  XCTAssertFalse(
    FBSDKSettings.isAutoLogAppEventsEnabled,
    "Should retrieve an initial value for a cachable property when there is a non-empty cache"
  );

  XCTAssertEqualObjects(
    self.userDefaultsSpy.capturedObjectRetrievalKey,
    @"FacebookAutoLogAppEventsEnabled",
    "Should attempt to access the cache to retrieve the initial value for a cachable property"
  );
  XCTAssertFalse(
    [self.bundle.capturedKeys containsObject:@"FacebookAutoLogAppEventsEnabled"],
    "Should not attempt to access the plist for cachable properties that have a value in the cache"
  );
}

- (void)testInitialAccessForCachablePropertyWithEmptyCacheNonEmptyPlist
{
  // Using false because it is not the default value for `isAutoInitializationEnabled`
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"FacebookAutoLogAppEventsEnabled" : @NO}];
  FBSDKSettings.infoDictionaryProvider = self.bundle;

  XCTAssertFalse(
    FBSDKSettings.isAutoLogAppEventsEnabled,
    "Should retrieve an initial value from the property list"
  );

  XCTAssertEqualObjects(
    self.userDefaultsSpy.capturedObjectRetrievalKey,
    @"FacebookAutoLogAppEventsEnabled",
    "Should attempt to access the cache to retrieve the initial value for a cachable property"
  );
  XCTAssertEqualObjects(
    self.bundle.capturedKeys.lastObject,
    @"FacebookAutoLogAppEventsEnabled",
    "Should attempt to access the plist for cachable properties that have no value in the cache"
  );
}

- (void)testInitialAccessForCachablePropertyWithEmptyCacheEmptyPlistAndDefaultValue
{
  XCTAssertTrue(
    FBSDKSettings.isAutoLogAppEventsEnabled,
    "Should use the default value for a property when there are no values in the cache or plist"
  );

  XCTAssertEqualObjects(
    self.userDefaultsSpy.capturedObjectRetrievalKey,
    @"FacebookAutoLogAppEventsEnabled",
    "Should attempt to access the cache to retrieve the initial value for a cachable property"
  );
  XCTAssertEqualObjects(
    self.bundle.capturedKeys.lastObject,
    @"FacebookAutoLogAppEventsEnabled",
    "Should attempt to access the plist for cachable properties that have no value in the cache"
  );
}

- (void)testInitialAccessForNonCachablePropertyWithEmptyPlist
{
  XCTAssertNil(
    FBSDKSettings.clientToken,
    "A non-cachable property with no default value and no plist entry should not have a value"
  );

  XCTAssertNil(
    self.userDefaultsSpy.capturedObjectRetrievalKey,
    "Should not attempt to access the cache for a non-cachable property"
  );
  XCTAssertEqualObjects(
    self.bundle.capturedKeys.lastObject,
    @"FacebookClientToken",
    "Should attempt to access the plist for non-cachable properties"
  );
}

- (void)testInitialAccessForNonCachablePropertyWithNonEmptyPlist
{
  self.bundle = [[TestBundle alloc] initWithInfoDictionary:@{@"FacebookClientToken" : @"abc123"}];
  FBSDKSettings.infoDictionaryProvider = self.bundle;

  XCTAssertEqualObjects(
    FBSDKSettings.clientToken,
    @"abc123",
    "Should retrieve the initial value from the property list"
  );

  XCTAssertNil(
    self.userDefaultsSpy.capturedObjectRetrievalKey,
    "Should not attempt to access the cache for a non-cachable property"
  );
  XCTAssertEqualObjects(
    self.bundle.capturedKeys.lastObject,
    @"FacebookClientToken",
    "Should attempt to access the plist for non-cachable properties"
  );
}

// MARK: Graph Error Recovery Enabled

- (void)testSetGraphErrorRecoveryEnabled
{
  [FBSDKSettings setGraphErrorRecoveryEnabled:YES];
  XCTAssertTrue([FBSDKSettings isGraphErrorRecoveryEnabled]);

  [FBSDKSettings setGraphErrorRecoveryEnabled:NO];
  XCTAssertFalse([FBSDKSettings isGraphErrorRecoveryEnabled]);
}

// MARK: Limit Event and Data Usage

- (void)testSetLimitEventAndDataUsageDefault
{
  XCTAssertFalse(
    FBSDKSettings.shouldLimitEventAndDataUsage,
    "Should limit event data usage by default"
  );
}

- (void)testSetUseCachedValuesForExpensiveMetadata
{
  FBSDKSettings.shouldUseCachedValuesForExpensiveMetadata = YES;

  XCTAssertEqualObjects(
    self.userDefaultsSpy.capturedValues[@"com.facebook.sdk:FBSDKSettingsUseCachedValuesForExpensiveMetadata"],
    @YES,
    "Should store whether or not to limit event and data usage in the user defaults"
  );
  XCTAssertTrue(
    FBSDKSettings.shouldUseCachedValuesForExpensiveMetadata,
    "should use cached values for expensive metadata"
  );
}

- (void)testSetUseTokenOptimizations
{
  FBSDKSettings.sharedSettings.shouldUseTokenOptimizations = NO;

  XCTAssertEqualObjects(
    self.userDefaultsSpy.capturedValues[@"com.facebook.sdk.FBSDKSettingsUseTokenOptimizations"],
    @NO,
    "Should store whether or not to use token optimizations"
  );
  XCTAssertFalse(
    FBSDKSettings.sharedSettings.shouldUseTokenOptimizations,
    "Should use token optimizations"
  );
}

- (void)testSetLimitEventAndDataUsageWithEmptyCache
{
  FBSDKSettings.limitEventAndDataUsage = YES;

  XCTAssertEqualObjects(
    self.userDefaultsSpy.capturedValues[@"com.facebook.sdk:FBSDKSettingsLimitEventAndDataUsage"],
    @YES,
    "Should store whether or not to limit event and data usage in the user defaults"
  );
  XCTAssertTrue(
    FBSDKSettings.shouldLimitEventAndDataUsage,
    "Should be able to set whether event data usage is limited"
  );
}

- (void)testSetLimitEventAndDataUsageWithNonEmptyCache
{
  FBSDKSettings.limitEventAndDataUsage = YES;
  XCTAssertTrue(FBSDKSettings.shouldLimitEventAndDataUsage, "sanity check");

  FBSDKSettings.limitEventAndDataUsage = NO;
  XCTAssertFalse(
    FBSDKSettings.shouldLimitEventAndDataUsage,
    "Should be able to override the existing value of should limit event data usage"
  );
  XCTAssertEqualObjects(
    self.userDefaultsSpy.capturedValues[@"com.facebook.sdk:FBSDKSettingsLimitEventAndDataUsage"],
    @NO,
    "Should store the overridden preference for limiting event data usage in the user defaults"
  );
}

// MARK: Data Processing Options

- (void)testDataProcessingOptionDefaults
{
  FBSDKSettings.dataProcessingOptions = @[];

  XCTAssertEqualObjects(
    FBSDKSettings.dataProcessingOptions[DATA_PROCESSING_OPTIONS_COUNTRY],
    @0,
    "Country should default to zero when not provided"
  );
  XCTAssertEqualObjects(
    FBSDKSettings.dataProcessingOptions[DATA_PROCESSING_OPTIONS_STATE],
    @0,
    "State should default to zero when not provided"
  );
}

- (void)testSettingEmptyDataProcessingOptions
{
  FBSDKSettings.dataProcessingOptions = @[];

  XCTAssertNotNil(
    FBSDKSettings.dataProcessingOptions,
    "Should not be able to set data processing options to an empty list of options but you can"
  );
}

- (void)testSettingInvalidDataProcessOptions
{
  FBSDKSettings.dataProcessingOptions = @[@"Foo", @"Bar"];

  XCTAssertNotNil(
    FBSDKSettings.dataProcessingOptions,
    "Should not be able to set data processing options to invalid list of options but you can"
  );

  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:FBSDKSettings.dataProcessingOptions];

  XCTAssertEqualObjects(
    self.userDefaultsSpy.capturedValues[@"com.facebook.sdk:FBSDKSettingsDataProcessingOptions"],
    data,
    "Should store the data processing options in the user defaults as data"
  );
}

- (void)testSettingDataProcessingOptionsWithCountryAndState
{
  int countryCode = -1000000000;
  int stateCode = 100000000;
  [FBSDKSettings setDataProcessingOptions:@[] country:countryCode state:stateCode];

  XCTAssertEqualObjects(
    FBSDKSettings.dataProcessingOptions[DATA_PROCESSING_OPTIONS],
    @[],
    "Should use the provided array of processing options"
  );
  XCTAssertEqualObjects(
    FBSDKSettings.dataProcessingOptions[DATA_PROCESSING_OPTIONS_COUNTRY],
    @(countryCode),
    "Should use the provided country code"
  );
  XCTAssertEqualObjects(
    FBSDKSettings.dataProcessingOptions[DATA_PROCESSING_OPTIONS_STATE],
    @(stateCode),
    "Should use the provided state code"
  );
}

- (void)testDataProcessingOptionsWithEmptyCache
{
  XCTAssertNil(
    FBSDKSettings.dataProcessingOptions,
    "Should not be able to get data processing options if there is none cached"
  );
  XCTAssertEqualObjects(
    self.userDefaultsSpy.capturedObjectRetrievalKey,
    @"com.facebook.sdk:FBSDKSettingsDataProcessingOptions",
    "Should attempt to access the cache to retrieve the initial value for a cachable property"
  );
  XCTAssertNil(
    self.bundle.capturedKeys.lastObject,
    "Should not attempt to access the plist for data processing options"
  );
}

- (void)testDataProcessingOptionsWithNonEmptyCache
{
  FBSDKSettings.dataProcessingOptions = @[];

  // Reset internal storage
  [FBSDKSettings reset];
  [FBSDKSettings configureWithStore:self.userDefaultsSpy
     appEventsConfigurationProvider:TestAppEventsConfigurationProvider.class
             infoDictionaryProvider:[TestBundle new]
                        eventLogger:[TestEventLogger new]];

  XCTAssertNotNil(
    FBSDKSettings.dataProcessingOptions,
    "Should be able to retrieve data processing options from the cache"
  );
  XCTAssertEqualObjects(
    self.userDefaultsSpy.capturedObjectRetrievalKey,
    @"com.facebook.sdk:FBSDKSettingsDataProcessingOptions",
    "Should attempt to access the cache to retrieve the initial value for a cachable property"
  );
  XCTAssertNil(
    self.bundle.capturedKeys.lastObject,
    "Should not attempt to access the plist for data processing options"
  );
}

- (void)testDataProcessingOptionsInternalStorage
{
  FBSDKSettings.dataProcessingOptions = @[];

  XCTAssertNotNil(FBSDKSettings.dataProcessingOptions, "sanity check");
  XCTAssertNil(
    self.userDefaultsSpy.capturedObjectRetrievalKey,
    "Should not attempt to access the cache to retrieve objects that have a current value"
  );
  XCTAssertNil(
    self.bundle.capturedKeys.lastObject,
    "Should not attempt to access the plist to retrieve objects that have a current value"
  );
}

- (void)testRecordInstall
{
  XCTAssertNil(
    self.userDefaultsSpy.capturedValues[@"com.facebook.sdk:FBSDKSettingsInstallTimestamp"],
    "Should not persist the value of before setting it"
  );
  [FBSDKSettings.sharedSettings recordInstall];
  XCTAssertNotNil(
    self.userDefaultsSpy.capturedValues[@"com.facebook.sdk:FBSDKSettingsInstallTimestamp"],
    "Should persist the value after setting it"
  );
  NSDate *date = self.userDefaultsSpy.capturedValues[@"com.facebook.sdk:FBSDKSettingsInstallTimestamp"];
  [FBSDKSettings.sharedSettings recordInstall];
  XCTAssertEqual(date, self.userDefaultsSpy.capturedValues[@"com.facebook.sdk:FBSDKSettingsInstallTimestamp"], "Should not change the cached install timesstamp");
}

- (void)testRecordSetAdvertiserTrackingEnabled
{
  [FBSDKSettings recordSetAdvertiserTrackingEnabled];
  XCTAssertNotNil(
    self.userDefaultsSpy.capturedValues[@"com.facebook.sdk:FBSDKSettingsSetAdvertiserTrackingEnabledTimestamp"],
    "Should persist the value after setting it"
  );
  NSDate *date = self.userDefaultsSpy.capturedValues[@"com.facebook.sdk:FBSDKSettingsSetAdvertiserTrackingEnabledTimestamp"];
  [FBSDKSettings recordSetAdvertiserTrackingEnabled];
  XCTAssertNotEqual(date, self.userDefaultsSpy.capturedValues[@"com.facebook.sdk:FBSDKSettingsSetAdvertiserTrackingEnabledTimestamp"], "Should update set advertiser tracking enabled timesstamp");
}

- (void)testIsEventDelayTimerExpired
{
  [FBSDKSettings.sharedSettings recordInstall];
  XCTAssertFalse([FBSDKSettings isEventDelayTimerExpired]);

  NSDate *today = [NSDate new];
  NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
  NSDateComponents *addComponents = [NSDateComponents new];
  addComponents.month = -1;
  NSDate *expiredDate = [calendar dateByAddingComponents:addComponents toDate:today options:0];
  [self.userDefaultsSpy setObject:expiredDate forKey:@"com.facebook.sdk:FBSDKSettingsInstallTimestamp"];
  XCTAssertTrue([FBSDKSettings isEventDelayTimerExpired]);

  [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"com.facebook.sdk:FBSDKSettingsInstallTimestamp"];
}

- (void)testIsSetATETimeExceedsInstallTime
{
  [FBSDKSettings.sharedSettings recordInstall];
  [FBSDKSettings recordSetAdvertiserTrackingEnabled];
  XCTAssertFalse([FBSDKSettings isSetATETimeExceedsInstallTime]);
  [FBSDKSettings recordSetAdvertiserTrackingEnabled];
  NSDate *today = [NSDate new];
  NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
  NSDateComponents *addComponents = [NSDateComponents new];
  addComponents.month = -1;
  NSDate *expiredDate = [calendar dateByAddingComponents:addComponents toDate:today options:0];
  [self.userDefaultsSpy setObject:expiredDate forKey:@"com.facebook.sdk:FBSDKSettingsInstallTimestamp"];
  XCTAssertTrue([FBSDKSettings isSetATETimeExceedsInstallTime]);
}

- (void)testLoggingBehaviors
{
  NSSet<FBSDKLoggingBehavior> *mockLoggingBehaviors =
  [NSSet setWithObjects:FBSDKLoggingBehaviorAppEvents, FBSDKLoggingBehaviorNetworkRequests, nil];

  [FBSDKSettings setLoggingBehaviors:mockLoggingBehaviors];
  XCTAssertEqualObjects(mockLoggingBehaviors, [FBSDKSettings loggingBehaviors]);

  // test enable logging behavior
  [FBSDKSettings enableLoggingBehavior:FBSDKLoggingBehaviorInformational];
  XCTAssertTrue([[FBSDKSettings loggingBehaviors] containsObject:FBSDKLoggingBehaviorInformational]);

  // test disable logging behavior
  [FBSDKSettings disableLoggingBehavior:FBSDKLoggingBehaviorInformational];
  XCTAssertFalse([[FBSDKSettings loggingBehaviors] containsObject:FBSDKLoggingBehaviorInformational]);
}

#pragma mark - test for internal functions

// MARK: User Agent Suffix

- (void)testUserAgentSuffix
{
  XCTAssertNil(
    FBSDKSettings.userAgentSuffix,
    "User agent suffix should be nil by default"
  );
}

- (void)testSettingUserAgentSuffix
{
  FBSDKSettings.userAgentSuffix = @"foo";

  XCTAssertEqual(
    FBSDKSettings.userAgentSuffix,
    @"foo",
    "Settings should return the explicitly set user agent suffix"
  );
}

- (void)testSettingEmptyUserAgentSuffix
{
  FBSDKSettings.userAgentSuffix = emptyString;

  XCTAssertEqualObjects(
    FBSDKSettings.userAgentSuffix,
    emptyString,
    "Should not store an empty user agent suffix but it will"
  );
}

- (void)testSettingWhitespaceOnlyUserAgentSuffix
{
  FBSDKSettings.userAgentSuffix = whiteSpaceToken;

  XCTAssertEqualObjects(
    FBSDKSettings.userAgentSuffix,
    whiteSpaceToken,
    "Should not store a whitespace only user agent suffix but it will"
  );
}

- (void)testSetGraphAPIVersion
{
  NSString *mockGraphAPIVersion = @"mockGraphAPIVersion";
  [FBSDKSettings setGraphAPIVersion:mockGraphAPIVersion];
  XCTAssertEqualObjects(mockGraphAPIVersion, [FBSDKSettings graphAPIVersion]);

  [FBSDKSettings setGraphAPIVersion:nil];
  XCTAssertEqualObjects(FBSDK_DEFAULT_GRAPH_API_VERSION, [FBSDKSettings graphAPIVersion]);
}

- (void)testIsDataProcessingRestricted
{
  [FBSDKSettings setDataProcessingOptions:@[@"LDU"]];
  XCTAssertTrue([FBSDKSettings isDataProcessingRestricted]);
  [FBSDKSettings setDataProcessingOptions:@[]];
  XCTAssertFalse([FBSDKSettings isDataProcessingRestricted]);
  [FBSDKSettings setDataProcessingOptions:@[@"ldu"]];
  XCTAssertTrue([FBSDKSettings isDataProcessingRestricted]);
  [FBSDKSettings setDataProcessingOptions:nil];
  XCTAssertFalse([FBSDKSettings isDataProcessingRestricted]);
}

/**
 Setting the plist-based properties will call `logIfSDKSettingsChanged` which will
 access properties some properties, check for plist and cache values and set defaults
 for them.
 Clearing the test fixtures enables us to only observe the side effects from
 getting the property and not those from setting the property in a test or resetting
 the property as part of test lifecycle management.
 */
- (void)resetLoggingSideEffects
{
  self.bundle = [TestBundle new];
  self.userDefaultsSpy = [UserDefaultsSpy new];
}

@end

#pragma clang diagnostic pop
