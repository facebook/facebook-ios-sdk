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
#import <OCMock/OCMock.h>

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKServerConfigurationFixtures.h"
#import "FBSDKEventBinding.h"
#import "FBSDKTestCoder.h"
#import "FBSDKMonitoringConfigurationTestHelper.h"

@interface FBSDKServerConfiguration (Testing)

- (NSDictionary *)dialogConfigurations;
- (NSDictionary *)dialogFlows;

@end

@interface FBSDKMonitoringConfiguration (Testing)

- (NSDictionary<NSString *, NSNumber *> *)sampleRates;

@end

@interface FBSDKServerConfigurationTests : XCTestCase
@end

@implementation FBSDKServerConfigurationTests {
  FBSDKServerConfiguration *config;
}

typedef FBSDKServerConfigurationFixtures Fixtures;
typedef FBSDKMonitoringConfigurationTestHelper MonitoringConfiguration;

- (void)setUp
{
  [super setUp];

  config = [Fixtures defaultConfig];
}

- (void)tearDown
{
  [super tearDown];

  config = nil;
}

- (void)testUsingDefaults
{
  XCTAssertTrue(config.defaults, "Should assume defaults are being used unless otherwise expressed");

  config = [Fixtures configWithDictionary:@{@"defaults": @NO}];
  XCTAssertFalse(config.defaults, "Should store whether or not defaults are being used");
}

- (void)testCreatingWithoutAppID
{
  XCTAssertNil(config.appID, "Should not use a default value for app identifier");
}

- (void)testCreatingWithEmptyAppID
{
  config = [Fixtures configWithDictionary:@{@"appID": @""}];
  XCTAssertEqualObjects(config.appID, @"",
                        "Should use the given app identifier regardless of value");
}

- (void)testCreatingWithDefaultAdvertisingIdEnabled
{
  XCTAssertFalse(config.isAdvertisingIDEnabled,
                 "Advertising identifier enabled should default to false");
}

- (void)testCreatingWithKnownAdvertisingIdEnabled
{
  config = [Fixtures configWithDictionary:@{@"advertisingIDEnabled": @YES}];
  XCTAssertTrue(config.isAdvertisingIDEnabled,
                "Advertising identifier enabled should be settable");
}

- (void)testCreatingWithDefaultImplicitPurchaseLoggingEnabled
{
  XCTAssertFalse(config.implicitPurchaseLoggingEnabled,
                 "Implicit purchase logging enabled should default to false");
}

- (void)testCreatingWithKnownImplicitPurchaseLoggingEnabled
{
  config = [Fixtures configWithDictionary:@{@"implicitPurchaseLoggingEnabled": @YES}];
  XCTAssertTrue(config.implicitPurchaseLoggingEnabled,
                "Implicit purchase logging enabled should be settable");
}

- (void)testCreatingWithDefaultImplicitLoggingEnabled
{
  XCTAssertFalse(config.implicitLoggingEnabled,
                 "Implicit logging enabled should default to false");
}

- (void)testCreatingWithKnownImplicitLoggingEnabled
{
  config = [Fixtures configWithDictionary:@{@"implicitLoggingEnabled": @YES}];
  XCTAssertTrue(config.implicitLoggingEnabled,
                "Implicit logging enabled should be settable");
}

- (void)testCreatingWithDefaultCodelessEventsEnabled
{
  XCTAssertFalse(config.codelessEventsEnabled,
                 "Codeless events enabled should default to false");
}

- (void)testCreatingWithKnownCodelessEventsEnabled
{
  config = [Fixtures configWithDictionary:@{@"codelessEventsEnabled": @YES}];
  XCTAssertTrue(config.codelessEventsEnabled,
                "Codeless events enabled should be settable");
}

- (void)testCreatingWithDefaultUninstallTrackingEnabled
{
  XCTAssertFalse(config.uninstallTrackingEnabled,
                 "Uninstall tracking enabled should default to false");
}

- (void)testCreatingWithKnownUninstallTrackingEnabled
{
  config = [Fixtures configWithDictionary:@{@"uninstallTrackingEnabled": @YES}];
  XCTAssertTrue(config.uninstallTrackingEnabled,
                "Uninstall tracking enabled should be settable");
}

- (void)testCreatingWithoutAppName
{
  XCTAssertNil(config.appName, "Should not use a default value for app name");
}

- (void)testCreatingWithEmptyAppName
{
  config = [Fixtures configWithDictionary:@{@"appName": @""}];
  XCTAssertEqualObjects(config.appName, @"",
                        "Should use the given app name regardless of value");
}

- (void)testCreatingWithKnownAppName
{
  config = [Fixtures configWithDictionary:@{@"appName": @"foo"}];
  XCTAssertEqual(config.appName, @"foo",
                 "App name should be settable");
}

- (void)testCreatingWithoutDefaultShareMode
{
  XCTAssertNil(config.defaultShareMode,
               "Should not provide a default for the default share mode");
}

- (void)testCreatingWithKnownDefaultShareMode
{
  config = [Fixtures configWithDictionary:@{@"defaultShareMode": @"native"}];
  XCTAssertEqual(config.defaultShareMode, @"native",
                 "Default share mode should be settable");
}

- (void)testCreatingWithEmptyDefaultShareMode
{
  config = [Fixtures configWithDictionary:@{@"defaultShareMode": @""}];
  XCTAssertEqual(config.defaultShareMode, @"",
                 "Should use the given share mode regardless of value");
}

- (void)testCreatingWithDefaultLoginTooltipEnabled
{
  XCTAssertFalse(config.loginTooltipEnabled,
                 "Login tooltip enabled should default to false");
}

- (void)testCreatingWithKnownLoginTooltipEnabled
{
  config = [Fixtures configWithDictionary:@{@"loginTooltipEnabled": @YES}];
  XCTAssertTrue(config.loginTooltipEnabled,
                "Login tooltip enabled should be settable");
}

- (void)testCreatingWithoutLoginTooltipText
{
  XCTAssertNil(config.loginTooltipText, "Should not use a default value for the login tooltip text");
}

- (void)testCreatingWithEmptyLoginTooltipText
{
  config = [Fixtures configWithDictionary:@{@"loginTooltipText": @""}];
  XCTAssertEqualObjects(config.loginTooltipText, @"",
                        "Should use the given login tooltip text regardless of value");
}

- (void)testCreatingWithKnownLoginTooltipText
{
  config = [Fixtures configWithDictionary:@{@"loginTooltipText": @"foo"}];
  XCTAssertEqual(config.loginTooltipText, @"foo",
                 "Login tooltip text should be settable");
}

- (void)testCreatingWithoutTimestamp
{
  XCTAssertNil(config.timestamp, "Should not have a timestamp by default");
}

- (void)testCreatingWithTimestamp
{
  NSDate *date = [NSDate date];
  config = [Fixtures configWithDictionary:@{@"timestamp": date}];
  XCTAssertEqualObjects(config.timestamp, date,
                        "Should use the timestamp given during creation");
}

- (void)testCreatingWithDefaultSessionTimeoutInterval
{
  XCTAssertEqual(config.sessionTimoutInterval, 60,
                 "Should set the correct default timeout interval");
}

- (void)testCreatingWithSessionTimeoutInterval
{
  config = [Fixtures configWithDictionary:@{@"sessionTimeoutInterval": @200}];
  XCTAssertEqual(config.sessionTimoutInterval, 200,
                 "Should set the session timeout interval from the remote");
}

- (void)testCreatingWithoutLoggingToken {
  XCTAssertNil(config.loggingToken,
               "Should not provide a default for the logging token");
}

- (void)testCreatingWithEmptyLoggingToken {
  config = [Fixtures configWithDictionary:@{@"loggingToken": @""}];
  XCTAssertEqualObjects(config.loggingToken, @"",
                        "Should use the logging token given during creation");
}

- (void)testCreatingWithKnownLoggingToken {
  config = [Fixtures configWithDictionary:@{@"loggingToken": @"foo"}];
  XCTAssertEqualObjects(config.loggingToken, @"foo",
                        "Should use the logging token given during creation");
}

- (void)testCreatingWithoutSmartLoginBookmarkUrl
{
  XCTAssertNil(config.smartLoginBookmarkIconURL,
               "Should not provide a default url for the smart login bookmark icon");
}

- (void)testCreatingWithInvalidSmartLoginBookmarkUrl
{
  config = [Fixtures configWithDictionary:@{@"smartLoginBookmarkIconURL": [NSURL URLWithString:@""]}];
  XCTAssertEqualObjects(config.smartLoginBookmarkIconURL, [NSURL URLWithString:@""],
                        "Should use the url given during creation");
}

- (void)testCreatingWithValidSmartBookmarkUrl
{
  config = [Fixtures configWithDictionary:@{@"smartLoginBookmarkIconURL": [NSURL URLWithString:@"http://www.example.com"]}];
  XCTAssertEqualObjects(config.smartLoginBookmarkIconURL, [NSURL URLWithString:@"http://www.example.com"],
                        "Should use the url given during creation");
}


- (void)testCreatingWithSmartLoginOptionsDefault
{
  XCTAssertEqual(config.smartLoginOptions, FBSDKServerConfigurationSmartLoginOptionsUnknown,
                 "Should default smart login options to unknown");
}

- (void)testCreatingWithSmartLoginOptionsEnabled
{
  config = [Fixtures configWithDictionary:@{@"smartLoginOptions": [NSNumber numberWithInt:FBSDKServerConfigurationSmartLoginOptionsEnabled]}];
  XCTAssertEqual(config.smartLoginOptions, FBSDKServerConfigurationSmartLoginOptionsEnabled,
                 "Should use the smartLoginOptions given during creation");
}

- (void)testCreatingWithoutErrorConfiguration
{
  XCTAssertNil(config.errorConfiguration, "Should not have an error configuration by default");
}

- (void)testCreatingWithErrorConfiguration
{
  FBSDKErrorConfiguration *errorConfig = [[FBSDKErrorConfiguration alloc] initWithDictionary:nil];
  config = [Fixtures configWithDictionary:@{@"errorConfiguration": errorConfig}];

  XCTAssertEqualObjects(config.errorConfiguration, errorConfig,
                        @"Error configuration should be settable");
}

- (void)testCreatingWithoutSmartLoginMenuUrl
{
  XCTAssertNil(config.smartLoginMenuIconURL,
               "Should not provide a default url for the smart login menu icon");
}

- (void)testCreatingWithInvalidSmartLoginMenuUrl
{
  config = [Fixtures configWithDictionary:@{@"smartLoginMenuIconURL": [NSURL URLWithString:@""]}];
  XCTAssertEqualObjects(config.smartLoginMenuIconURL, [NSURL URLWithString:@""],
                        "Should use the url given during creation");
}

- (void)testCreatingWithValidSmartLoginMenuUrl
{
  config = [Fixtures configWithDictionary:@{@"smartLoginMenuIconURL": [NSURL URLWithString:@"http://www.example.com"]}];
  XCTAssertEqualObjects(config.smartLoginMenuIconURL, [NSURL URLWithString:@"http://www.example.com"],
                        "Should use the url given during creation");
}

- (void)testCreatingWithoutUpdateMessage
{
  XCTAssertNil(config.updateMessage,
               "Should not provide a default for the update message");
}

- (void)testCreatingWithEmptyUpdateMessage
{
  config = [Fixtures configWithDictionary:@{@"updateMessage": @""}];
  XCTAssertEqualObjects(config.updateMessage, @"",
                        "Should use the update message given during creation");
}

- (void)testCreatingWithKnownUpdateMessage
{
  config = [Fixtures configWithDictionary:@{@"updateMessage": @"foo"}];
  XCTAssertEqualObjects(config.updateMessage, @"foo",
                        "Should use the update message given during creation");
}

- (void)testCreatingWithoutEventBindings
{
  XCTAssertNil(config.eventBindings,
               "Should not provide default event bindings");
}

- (void)testCreatingWithEmptyEventBindings
{
  config = [Fixtures configWithDictionary:@{@"eventBindings": @[]}];
  XCTAssertNotNil(config.eventBindings, "Should use the empty list of event bindings it was created with");
  XCTAssertEqual(config.eventBindings.count, 0,
                 "Should use the empty list of event bindings it was created with");
}

- (void)testCreatingWithEventBindings
{
  NSArray *bindings = @[[FBSDKEventBinding new]];
  config = [Fixtures configWithDictionary:@{@"eventBindings": bindings}];

  XCTAssertEqualObjects(config.eventBindings, bindings,
                        @"Event binding should be settable");
}

- (void)testCreatingWithoutDialogConfigurations
{
  XCTAssertNil(config.dialogConfigurations,
               @"Should not have dialog configurations by default");
}

- (void)testCreatingWithDialogConfigurations
{
  NSDictionary *dialogConfigurations = @{
    @"dialog": @"Hello",
    @"dialog2": @"World"
  };

  config = [Fixtures configWithDictionary:@{@"dialogConfigurations": dialogConfigurations}];
  XCTAssertEqualObjects(config.dialogConfigurations, dialogConfigurations,
                        "Should set the exact dialog configurations it was created with");
}

- (void)testCreatingWithoutDialogFlowsBelowIosVersion9
{
  NSOperatingSystemVersion iOS9Version = { .majorVersion = 9, .minorVersion = 0, .patchVersion = 0 };

  id internalUtilityMock = OCMClassMock([FBSDKInternalUtility class]);
  OCMStub([internalUtilityMock isOSRunTimeVersionAtLeast:iOS9Version]).andReturn(YES);

  // Need to recreate with a new appID to invalidate cache of default configuration
  config = [FBSDKServerConfiguration defaultServerConfigurationForAppID:self.name];

  NSDictionary *expectedDefaultDialogFlows = @{
    FBSDKDialogConfigurationNameDefault: @{
        FBSDKDialogConfigurationFeatureUseNativeFlow: @NO,
        FBSDKDialogConfigurationFeatureUseSafariViewController: @YES,
    },
    FBSDKDialogConfigurationNameMessage: @{
        FBSDKDialogConfigurationFeatureUseNativeFlow: @YES,
    },
  };

  XCTAssertEqualObjects(config.dialogFlows, expectedDefaultDialogFlows);
}

- (void)testCreatingWithoutDialogFlowsAboveIosVersion9
{
  NSOperatingSystemVersion iOS9Version = { .majorVersion = 9, .minorVersion = 0, .patchVersion = 0 };

  id internalUtilityMock = OCMClassMock([FBSDKInternalUtility class]);
  OCMStub([internalUtilityMock isOSRunTimeVersionAtLeast:iOS9Version]).andReturn(NO);

  // Need to recreate with a new appID to invalidate cache of default configuration
  config = [FBSDKServerConfiguration defaultServerConfigurationForAppID:self.name];

  NSDictionary *expectedDefaultDialogFlows = @{
    FBSDKDialogConfigurationNameDefault: @{
        FBSDKDialogConfigurationFeatureUseNativeFlow: @YES,
        FBSDKDialogConfigurationFeatureUseSafariViewController: @YES,
    },
    FBSDKDialogConfigurationNameMessage: @{
        FBSDKDialogConfigurationFeatureUseNativeFlow: @YES,
    },
  };

  XCTAssertEqualObjects(config.dialogFlows, expectedDefaultDialogFlows);
}


- (void)testCreatingWithDialogFlows
{
  NSDictionary *dialogFlows =  @{
    @"foo": @{
        FBSDKDialogConfigurationFeatureUseNativeFlow: @YES,
        FBSDKDialogConfigurationFeatureUseSafariViewController: @YES,
    },
    @"bar": @{
        FBSDKDialogConfigurationFeatureUseNativeFlow: @NO,
    }
  };

  config = [Fixtures configWithDictionary:@{@"dialogFlows": dialogFlows}];

  XCTAssertEqualObjects(config.dialogFlows, dialogFlows,
                        "Should set the exact dialog flows it was created with");
}

- (void)testCreatingWithoutAAMRules
{
  XCTAssertNil(config.AAMRules,
               @"Should not have aam rules by default");
}

- (void)testCreatingWithAAMRules
{
  NSDictionary *rules = @{ @"foo": @"bar" };

  config = [Fixtures configWithDictionary:@{@"aamRules": rules}];

  XCTAssertEqualObjects(config.AAMRules, rules,
                        "Should set the exact aam rules it was created with");
}

- (void)testCreatingWithoutRestrictiveParams
{
  XCTAssertNil(config.restrictiveParams,
               @"Should not have restrictive params by default");
}

- (void)testCreatingWithRestrictiveParams
{
  NSDictionary *params = @{ @"foo": @"bar" };

  config = [Fixtures configWithDictionary:@{@"restrictiveParams": params}];

  XCTAssertEqualObjects(config.restrictiveParams, params,
                        "Should set the exact restrictive params it was created with");
}

- (void)testCreatingWithoutSuggestedEventSetting
{
  XCTAssertNil(config.suggestedEventsSetting,
               @"Should not have a suggested events setting by default");
}

- (void)testCreatingWithSuggestedEventSetting
{
  NSDictionary *setting = @{ @"foo": @"bar" };

  config = [Fixtures configWithDictionary:@{@"suggestedEventsSetting": setting}];

  XCTAssertEqualObjects(config.suggestedEventsSetting, setting,
                        "Should set the exact suggested events setting it was created with");
}

- (void)testCreatingWithoutMonitoringConfiguration
{
  XCTAssertEqualObjects(config.monitoringConfiguration.sampleRates,
                        FBSDKMonitoringConfiguration.defaultConfiguration.sampleRates,
                        @"Should use the default monitoring configuration if none is provided");
}

- (void)testCreatingWithMonitoringConfiguration
{
  NSDictionary *sampleRates = [MonitoringConfiguration sampleRatesWithEntryPairs: @{ @"foo": @1 }];
  FBSDKMonitoringConfiguration *monitoringConfiguration = [FBSDKMonitoringConfiguration fromDictionary:sampleRates];

  config = [Fixtures configWithDictionary:@{@"monitoringConfiguration": monitoringConfiguration}];

  XCTAssertEqualObjects(config.monitoringConfiguration, monitoringConfiguration,
                        "Should set the exact monitoring configuration it was created with");
}

- (void)testEncoding
{
  FBSDKTestCoder *coder = [FBSDKTestCoder new];
  FBSDKErrorConfiguration *errorConfig = [[FBSDKErrorConfiguration alloc] initWithDictionary:nil];
  NSDictionary *sampleRates = [MonitoringConfiguration sampleRatesWithEntryPairs: @{ @"foo": @1 }];
  FBSDKMonitoringConfiguration *monitoringConfiguration = [FBSDKMonitoringConfiguration fromDictionary:sampleRates];

  config = [Fixtures configWithDictionary:@{
    @"appID": @"appID",
    @"appName": @"appName",
    @"loginTooltipEnabled": @YES,
    @"loginTooltipText": @"loginTooltipText",
    @"defaultShareMode": @"defaultShareMode",
    @"advertisingIDEnabled": @YES,
    @"implicitLoggingEnabled": @YES,
    @"implicitPurchaseLoggingEnabled": @YES,
    @"codelessEventsEnabled" : @YES,
    @"uninstallTrackingEnabled" : @YES,
    @"dialogFlows": @{@"Foo": @"Bar"},
    @"timestamp": [NSDate date],
    @"errorConfiguration": errorConfig,
    @"sessionTimeoutInterval": @100,
    @"defaults": @NO,
    @"loggingToken": @"loggingToken",
    @"smartLoginOptions": [NSNumber numberWithInt: FBSDKServerConfigurationSmartLoginOptionsEnabled],
    @"smartLoginBookmarkIconURL": [NSURL URLWithString:@"https://example.com"],
    @"smartLoginMenuIconURL": [NSURL URLWithString:@"https://example.com"],
    @"updateMessage": @"updateMessage",
    @"eventBindings": @{ @"foo": @"bar" },
    @"restrictiveParams": @{ @"restrictiveParams": @"foo" },
    @"AAMRules": @{ @"AAMRules": @"foo" },
    @"suggestedEventsSetting": @{ @"suggestedEventsSetting": @"foo" },
    @"monitoringConfiguration": monitoringConfiguration
  }];

  [config encodeWithCoder:coder];

  XCTAssertEqualObjects(coder.encodedObject[@"appID"], config.appID);
  XCTAssertEqualObjects(coder.encodedObject[@"appName"], config.appName);
  XCTAssertEqual([coder.encodedObject[@"loginTooltipEnabled"] boolValue], config.loginTooltipEnabled);
  XCTAssertEqualObjects(coder.encodedObject[@"loginTooltipText"], config.loginTooltipText);
  XCTAssertEqualObjects(coder.encodedObject[@"defaultShareMode"], config.defaultShareMode);
  XCTAssertEqual([coder.encodedObject[@"advertisingIDEnabled"] boolValue], config.advertisingIDEnabled);
  XCTAssertEqual([coder.encodedObject[@"implicitLoggingEnabled"] boolValue], config.implicitLoggingEnabled);
  XCTAssertEqual([coder.encodedObject[@"implicitPurchaseLoggingEnabled"] boolValue], config.implicitPurchaseLoggingEnabled);
  XCTAssertEqual([coder.encodedObject[@"codelessEventsEnabled"] boolValue], config.codelessEventsEnabled);
  XCTAssertEqual([coder.encodedObject[@"trackAppUninstallEnabled"] boolValue], config.uninstallTrackingEnabled);
  XCTAssertEqualObjects(coder.encodedObject[@"dialogFlows"], config.dialogFlows);
  XCTAssertEqualObjects(coder.encodedObject[@"timestamp"], config.timestamp);
  XCTAssertEqualObjects(coder.encodedObject[@"errorConfigs"], config.errorConfiguration);
  XCTAssertEqual([coder.encodedObject[@"sessionTimeoutInterval"] intValue], config.sessionTimoutInterval);
  XCTAssertNil(coder.encodedObject[@"defaults"],
               @"Should not encode whether default values were used to create server configuration");
  XCTAssertEqualObjects(coder.encodedObject[@"loggingToken"], config.loggingToken);
  XCTAssertEqual([coder.encodedObject[@"smartLoginEnabled"] intValue], config.smartLoginOptions);
  XCTAssertEqualObjects(coder.encodedObject[@"smarstLoginBookmarkIconURL"], config.smartLoginBookmarkIconURL);
  XCTAssertEqualObjects(coder.encodedObject[@"smarstLoginBookmarkMenuURL"], config.smartLoginMenuIconURL);
  XCTAssertEqualObjects(coder.encodedObject[@"SDKUpdateMessage"], config.updateMessage);
  XCTAssertEqualObjects(coder.encodedObject[@"eventBindings"], config.eventBindings);
  XCTAssertEqualObjects(coder.encodedObject[@"restrictiveParams"], config.restrictiveParams);
  XCTAssertEqualObjects(coder.encodedObject[@"AAMRules"], config.AAMRules);
  XCTAssertEqualObjects(coder.encodedObject[@"suggestedEventsSetting"], config.suggestedEventsSetting);
  XCTAssertEqualObjects(coder.encodedObject[@"monitoringConfiguration"], config.monitoringConfiguration);
}

- (void)testDecoding
{
  FBSDKTestCoder *decoder = [FBSDKTestCoder new];
  config = [config initWithCoder:decoder];

  NSSet *dialogFlowsClasses = [[NSSet alloc] initWithObjects:
                               [NSDictionary class],
                               [NSString class],
                               [NSNumber class],
                               nil];

  XCTAssertEqualObjects(decoder.decodedObject[@"appID"], NSString.class);
  XCTAssertEqualObjects(decoder.decodedObject[@"appName"], NSString.class);
  XCTAssertEqualObjects(decoder.decodedObject[@"loginTooltipEnabled"], @"decodeBoolForKey",
                        @"Should decode loginTooltipEnabled as a BOOL");
  XCTAssertEqualObjects(decoder.decodedObject[@"loginTooltipText"], NSString.class);
  XCTAssertEqualObjects(decoder.decodedObject[@"defaultShareMode"], NSString.class);
  XCTAssertEqualObjects(decoder.decodedObject[@"advertisingIDEnabled"], @"decodeBoolForKey",
                        @"Should decode advertisingIDEnabled as a BOOL");
  XCTAssertEqualObjects(decoder.decodedObject[@"implicitLoggingEnabled"], @"decodeBoolForKey",
                        @"Should decode implicitLoggingEnabled as a BOOL");
  XCTAssertEqualObjects(decoder.decodedObject[@"implicitPurchaseLoggingEnabled"], @"decodeBoolForKey",
                        @"Should decode implicitPurchaseLoggingEnabled as a BOOL");
  XCTAssertEqualObjects(decoder.decodedObject[@"codelessEventsEnabled"], @"decodeBoolForKey",
                        @"Should decode codelessEventsEnabled as a BOOL");
  XCTAssertEqualObjects(decoder.decodedObject[@"trackAppUninstallEnabled"], @"decodeBoolForKey",
                        @"Should decode trackAppUninstallEnabled as a BOOL");
  XCTAssertEqualObjects(decoder.decodedObject[@"dialogFlows"], dialogFlowsClasses);
  XCTAssertEqualObjects(decoder.decodedObject[@"timestamp"], NSDate.class);
  XCTAssertEqualObjects(decoder.decodedObject[@"errorConfigs"], FBSDKErrorConfiguration.class);
  XCTAssertEqualObjects(decoder.decodedObject[@"sessionTimeoutInterval"], @"decodeDoubleForKey",
                        @"Should decode implicitLoggingEnabled as a double");
  XCTAssertNil(decoder.decodedObject[@"defaults"],
               @"Should not encode whether default values were used to create server configuration");
  XCTAssertEqualObjects(decoder.decodedObject[@"loggingToken"], NSString.class);
  XCTAssertEqualObjects(decoder.decodedObject[@"smartLoginEnabled"], @"decodeIntegerForKey",
                        @"Should decode smartLoginEnabled as an integer");
  XCTAssertEqualObjects(decoder.decodedObject[@"smarstLoginBookmarkIconURL"], NSURL.class);
  XCTAssertEqualObjects(decoder.decodedObject[@"smarstLoginBookmarkMenuURL"], NSURL.class);
  XCTAssertEqualObjects(decoder.decodedObject[@"SDKUpdateMessage"], NSString.class);
  XCTAssertEqualObjects(decoder.decodedObject[@"eventBindings"], NSArray.class);
  XCTAssertEqualObjects(decoder.decodedObject[@"restrictiveParams"], NSDictionary.class);
  XCTAssertEqualObjects(decoder.decodedObject[@"AAMRules"], NSDictionary.class);
  XCTAssertEqualObjects(decoder.decodedObject[@"suggestedEventsSetting"], NSDictionary.class);
  XCTAssertEqualObjects(decoder.decodedObject[@"monitoringConfiguration"], FBSDKMonitoringConfiguration.class);
}

- (void)testRetrievingInvalidDialogConfigurationForDialogName
{
  config = [Fixtures configWithDictionary:@{
    @"dialogConfigurations": @{
        @"foo": @"bar"
    }
  }];

  XCTAssertEqualObjects([config dialogConfigurationForDialogName:@"foo"], @"bar",
                        @"Should be able to retrieve an invalid dialog configuration by name");
}

- (void)testRetrievingValidDialogConfigurationForDialogName
{
  FBSDKDialogConfiguration *fooConfig = [[FBSDKDialogConfiguration alloc] initWithName:@"foo"
                                                                                   URL:nil
                                                                           appVersions:nil];

  config = [Fixtures configWithDictionary:@{
    @"dialogConfigurations": @{
        @"foo": fooConfig
    }
  }];

  XCTAssertEqualObjects([config dialogConfigurationForDialogName:@"foo"], fooConfig,
                        @"Should be able to retrieve a valid dialog configuration by name");
}

#pragma mark Native Dialog Checks

// querying / value / sharing value / default value  / expected
// 'login'  / nil   / nil           / nil            / false
- (void)testNativeDialogForMissingLoginMissingSharingMissingDefaultValue
{
  [self assertNativeDialogIs:NO
              forFeatureName:@"login"
            withFeatureValue:nil
                sharingValue:nil
                defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'login'  / nil   / nil           / true           / true
- (void)testNativeDialogForMissingLoginMissingSharingTrueDefault
{
  [self assertNativeDialogIs:YES
              forFeatureName:@"login"
            withFeatureValue:nil
                sharingValue:nil
                defaultValue:@YES];
}

// querying / value / sharing value / default value  / expected
// 'login'  / nil   / nil           / false          / false
- (void)testNativeDialogForMissingLoginMissingSharingFalseDefault
{
  [self assertNativeDialogIs:NO
              forFeatureName:@"login"
            withFeatureValue:nil
                sharingValue:nil
                defaultValue:@NO];
}

// querying / value / sharing value / default value  / expected
// 'login'  / nil   / true          / nil            / false
- (void)testNativeDialogForMissingLoginTrueSharingMissingDefault
{
  [self assertNativeDialogIs:NO
              forFeatureName:@"login"
            withFeatureValue:nil
                sharingValue:@YES
                defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'login'  / nil   / true          / true           / true
- (void)testNativeDialogForMissingLoginTrueSharingTrueDefault
{
  [self assertNativeDialogIs:YES
              forFeatureName:@"login"
            withFeatureValue:nil
                sharingValue:@YES
                defaultValue:@YES];
}

// querying / value / sharing value / default value  / expected
// 'login'  / nil   / true          / false          / false
- (void)testNativeDialogForMissingLoginTrueSharingFalseDefault
{
  [self assertNativeDialogIs:NO
              forFeatureName:@"login"
            withFeatureValue:nil
                sharingValue:@YES
                defaultValue:@NO];
}

// querying / value / sharing value / default value  / expected
// 'login'  / nil   / false         / nil            / false
- (void)testNativeDialogForMissingLoginFalseSharingMissingDefault
{
  [self assertNativeDialogIs:NO
              forFeatureName:@"login"
            withFeatureValue:nil
                sharingValue:@NO
                defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'login'  / nil   / false         / true           / true
- (void)testNativeDialogForMissingLoginFalseSharingTrueDefault
{
  [self assertNativeDialogIs:YES
              forFeatureName:@"login"
            withFeatureValue:nil
                sharingValue:@NO
                defaultValue:@YES];
}

// querying / value / sharing value / default value  / expected
// 'login'  / nil   / false         / false          / false
- (void)testNativeDialogForMissingLoginFalseSharingFalseDefault
{
  [self assertNativeDialogIs:NO
              forFeatureName:@"login"
            withFeatureValue:nil
                sharingValue:@NO
                defaultValue:@NO];
}

// querying / value / sharing value / default value  / expected
// 'login'  / true  / nil           / nil            / true
- (void)testNativeDialogForTrueLoginMissingSharingMissingDefault
{
  [self assertNativeDialogIs:YES
              forFeatureName:@"login"
            withFeatureValue:@YES
                sharingValue:nil
                defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'login'  / true  / nil           / true           / true
- (void)testNativeDialogForTrueLoginMissingSharingTrueDefault
{
  [self assertNativeDialogIs:YES
              forFeatureName:@"login"
            withFeatureValue:@YES
                sharingValue:nil
                defaultValue:@YES];
}

// querying / value / sharing value / default value  / expected
// 'login'  / true  / nil           / false          / true
- (void)testNativeDialogForTrueLoginMissingSharingFalseDefault
{
  [self assertNativeDialogIs:YES
              forFeatureName:@"login"
            withFeatureValue:@YES
                sharingValue:nil
                defaultValue:@NO];
}

// querying / value / sharing value / default value  / expected
// 'login'  / true  / true          / nil            / true
- (void)testNativeDialogForTrueLoginTrueSharingMissingDefault
{
  [self assertNativeDialogIs:YES
              forFeatureName:@"login"
            withFeatureValue:@YES
                sharingValue:@YES
                defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'login'  / true  / true          / true           / true
- (void)testNativeDialogForTrueLoginTrueSharingTrueDefault
{
  [self assertNativeDialogIs:YES
              forFeatureName:@"login"
            withFeatureValue:@YES
                sharingValue:@YES
                defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'login'  / true  / true          / false          / true
- (void)testNativeDialogForTrueLoginTrueSharingFalseDefault
{
  [self assertNativeDialogIs:YES
              forFeatureName:@"login"
            withFeatureValue:@YES
                sharingValue:@YES
                defaultValue:@NO];
}

// querying / value / sharing value / default value  / expected
// 'login'  / true  / false         / nil            / true
- (void)testNativeDialogForTrueLoginFalseSharingMissingDefault
{
  [self assertNativeDialogIs:YES
              forFeatureName:@"login"
            withFeatureValue:@YES
                sharingValue:@NO
                defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'login'  / true  / false         / true           / true
- (void)testNativeDialogForTrueLoginFalseSharingTrueDefault
{
  [self assertNativeDialogIs:YES
              forFeatureName:@"login"
            withFeatureValue:@YES
                sharingValue:@NO
                defaultValue:@YES];
}

// querying / value / sharing value / default value  / expected
// 'login'  / true  / false         / false          / true
- (void)testNativeDialogForTrueLoginFalseSharingFalseDefault
{
  [self assertNativeDialogIs:YES
              forFeatureName:@"login"
            withFeatureValue:@YES
                sharingValue:@NO
                defaultValue:@NO];
}

// querying / value / sharing value / default value  / expected
// 'login'  / false / nil           / nil            / false
- (void)testNativeDialogForFalseLoginMissingSharingMissingDefault
{
  [self assertNativeDialogIs:NO
              forFeatureName:@"login"
            withFeatureValue:@NO
                sharingValue:nil
                defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'login'  / false / nil           / true           / false
- (void)testNativeDialogForFalseLoginMissingSharingTrueDefault
{
  [self assertNativeDialogIs:NO
              forFeatureName:@"login"
            withFeatureValue:@NO
                sharingValue:nil
                defaultValue:@YES];
}

// querying / value / sharing value / default value  / expected
// 'login'  / false / nil           / false          / false
- (void)testNativeDialogForFalseLoginMissingSharingFalseDefault
{
  [self assertNativeDialogIs:NO
              forFeatureName:@"login"
            withFeatureValue:@NO
                sharingValue:nil
                defaultValue:@NO];
}

// querying / value / sharing value / default value  / expected
// 'login'  / false / true          / nil            / false
- (void)testNativeDialogForFalseLoginTrueSharingMissingDefault
{
  [self assertNativeDialogIs:NO
              forFeatureName:@"login"
            withFeatureValue:@NO
                sharingValue:@YES
                defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'login'  / false / true          / true           / false
- (void)testNativeDialogForFalseLoginTrueSharingTrueDefault
{
  [self assertNativeDialogIs:NO
              forFeatureName:@"login"
            withFeatureValue:@NO
                sharingValue:@YES
                defaultValue:@YES];
}

// querying / value / sharing value / default value  / expected
// 'login'  / false / true          / false          / false
- (void)testNativeDialogForFalseLoginTrueSharingFalseDefault
{
  [self assertNativeDialogIs:NO
              forFeatureName:@"login"
            withFeatureValue:@NO
                sharingValue:@YES
                defaultValue:@NO];
}

// querying / value / sharing value / default value  / expected
// 'login'  / false / false         / nil            / false
- (void)testNativeDialogForFalseLoginFalseSharingMissingDefault
{
  [self assertNativeDialogIs:NO
              forFeatureName:@"login"
            withFeatureValue:@NO
                sharingValue:@NO
                defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'login'  / false / false         / true           / false
- (void)testNativeDialogForFalseLoginFalseSharingTrueDefault
{
  [self assertNativeDialogIs:NO
              forFeatureName:@"login"
            withFeatureValue:@NO
                sharingValue:@NO
                defaultValue:@YES];
}

// querying / value / sharing value / default value  / expected
// 'login'  / false / false         / false          / false
- (void)testNativeDialogForFalseLoginFalseSharingFalseDefault
{
  [self assertNativeDialogIs:NO
              forFeatureName:@"login"
            withFeatureValue:@NO
                sharingValue:@NO
                defaultValue:@NO];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / nil   / nil           / nil            / false
- (void)testNativeDialogForMissingDialogMissingSharingMissingDefaultValue
{
  [self assertNativeDialogIs:NO
              forFeatureName:@"foo"
            withFeatureValue:nil
                sharingValue:nil
                defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / nil   / nil           / true           / true
- (void)testNativeDialogForMissingDialogMissingSharingTrueDefault
{
  [self assertNativeDialogIs:YES
              forFeatureName:@"foo"
            withFeatureValue:nil
                sharingValue:nil
                defaultValue:@YES];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / nil   / nil           / false          / false
- (void)testNativeDialogForMissingDialogMissingSharingFalseDefault
{
  [self assertNativeDialogIs:NO
              forFeatureName:@"foo"
            withFeatureValue:nil
                sharingValue:nil
                defaultValue:@NO];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / nil   / true          / nil            / false
- (void)testNativeDialogForMissingDialogTrueSharingMissingDefault
{
  [self assertNativeDialogIs:YES
              forFeatureName:@"foo"
            withFeatureValue:nil
                sharingValue:@YES
                defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / nil   / true          / true           / true
- (void)testNativeDialogForMissingDialogTrueSharingTrueDefault
{
  [self assertNativeDialogIs:YES
              forFeatureName:@"foo"
            withFeatureValue:nil
                sharingValue:@YES
                defaultValue:@YES];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / nil   / true          / false          / true
- (void)testNativeDialogForMissingDialogTrueSharingFalseDefault
{
  [self assertNativeDialogIs:YES
              forFeatureName:@"foo"
            withFeatureValue:nil
                sharingValue:@YES
                defaultValue:@NO];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / nil   / false         / nil            / false
- (void)testNativeDialogForMissingDialogFalseSharingMissingDefault
{
  [self assertNativeDialogIs:NO
              forFeatureName:@"foo"
            withFeatureValue:nil
                sharingValue:@NO
                defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / nil   / false         / true           / false
- (void)testNativeDialogForMissingDialogFalseSharingTrueDefault
{
  [self assertNativeDialogIs:NO
              forFeatureName:@"foo"
            withFeatureValue:nil
                sharingValue:@NO
                defaultValue:@YES];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / nil   / false         / false          / false
- (void)testNativeDialogForMissingDialogFalseSharingFalseDefault
{
  [self assertNativeDialogIs:NO
              forFeatureName:@"foo"
            withFeatureValue:nil
                sharingValue:@NO
                defaultValue:@NO];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / true  / nil           / nil            / true
- (void)testNativeDialogForTrueDialogMissingSharingMissingDefault
{
  [self assertNativeDialogIs:YES
              forFeatureName:@"foo"
            withFeatureValue:@YES
                sharingValue:nil
                defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / true  / nil           / true           / true
- (void)testNativeDialogForTrueDialogMissingSharingTrueDefault
{
  [self assertNativeDialogIs:YES
              forFeatureName:@"foo"
            withFeatureValue:@YES
                sharingValue:nil
                defaultValue:@YES];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / true  / nil           / false          / true
- (void)testNativeDialogForTrueDialogMissingSharingFalseDefault
{
  [self assertNativeDialogIs:YES
              forFeatureName:@"foo"
            withFeatureValue:@YES
                sharingValue:nil
                defaultValue:@NO];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / true  / true          / nil            / true
- (void)testNativeDialogForTrueDialogTrueSharingMissingDefault
{
  [self assertNativeDialogIs:YES
              forFeatureName:@"foo"
            withFeatureValue:@YES
                sharingValue:@YES
                defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / true  / true          / true           / true
- (void)testNativeDialogForTrueDialogTrueSharingTrueDefault
{
  [self assertNativeDialogIs:YES
              forFeatureName:@"foo"
            withFeatureValue:@YES
                sharingValue:@YES
                defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / true  / true          / false          / true
- (void)testNativeDialogForTrueDialogTrueSharingFalseDefault
{
  [self assertNativeDialogIs:YES
              forFeatureName:@"foo"
            withFeatureValue:@YES
                sharingValue:@YES
                defaultValue:@NO];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / true  / false         / nil            / true
- (void)testNativeDialogForTrueDialogFalseSharingMissingDefault
{
  [self assertNativeDialogIs:YES
              forFeatureName:@"foo"
            withFeatureValue:@YES
                sharingValue:@NO
                defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / true  / false         / true           / true
- (void)testNativeDialogForTrueDialogFalseSharingTrueDefault
{
  [self assertNativeDialogIs:YES
              forFeatureName:@"foo"
            withFeatureValue:@YES
                sharingValue:@NO
                defaultValue:@YES];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / true  / false         / false          / true
- (void)testNativeDialogForTrueDialogFalseSharingFalseDefault
{
  [self assertNativeDialogIs:YES
              forFeatureName:@"foo"
            withFeatureValue:@YES
                sharingValue:@NO
                defaultValue:@NO];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / false / nil           / nil            / false
- (void)testNativeDialogForFalseDialogMissingSharingMissingDefault
{
  [self assertNativeDialogIs:NO
              forFeatureName:@"foo"
            withFeatureValue:@NO
                sharingValue:nil
                defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / false / nil           / true           / false
- (void)testNativeDialogForFalseDialogMissingSharingTrueDefault
{
  [self assertNativeDialogIs:NO
              forFeatureName:@"foo"
            withFeatureValue:@NO
                sharingValue:nil
                defaultValue:@YES];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / false / nil           / false          / false
- (void)testNativeDialogForFalseDialogMissingSharingFalseDefault
{
  [self assertNativeDialogIs:NO
              forFeatureName:@"foo"
            withFeatureValue:@NO
                sharingValue:nil
                defaultValue:@NO];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / false / true          / nil            / false
- (void)testNativeDialogForFalseDialogTrueSharingMissingDefault
{
  [self assertNativeDialogIs:NO
              forFeatureName:@"foo"
            withFeatureValue:@NO
                sharingValue:@YES
                defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / false / true          / true           / false
- (void)testNativeDialogForFalseDialogTrueSharingTrueDefault
{
  [self assertNativeDialogIs:NO
              forFeatureName:@"foo"
            withFeatureValue:@NO
                sharingValue:@YES
                defaultValue:@YES];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / false / true          / false          / false
- (void)testNativeDialogForFalseDialogTrueSharingFalseDefault
{
  [self assertNativeDialogIs:NO
              forFeatureName:@"foo"
            withFeatureValue:@NO
                sharingValue:@YES
                defaultValue:@NO];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / false / false         / nil            / false
- (void)testNativeDialogForFalseDialogFalseSharingMissingDefault
{
  [self assertNativeDialogIs:NO
              forFeatureName:@"foo"
            withFeatureValue:@NO
                sharingValue:@NO
                defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / false / false         / true           / false
- (void)testNativeDialogForFalseDialogFalseSharingTrueDefault
{
  [self assertNativeDialogIs:NO
              forFeatureName:@"foo"
            withFeatureValue:@NO
                sharingValue:@NO
                defaultValue:@YES];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / false / false         / false          / false
- (void)testNativeDialogForFalseDialogFalseSharingFalseDefault
{
  [self assertNativeDialogIs:NO
              forFeatureName:@"foo"
            withFeatureValue:@NO
                sharingValue:@NO
                defaultValue:@NO];
}

#pragma mark SafariVC Checks

// querying / value / sharing value / default value  / expected
// 'login'  / nil   / nil           / nil            / false
- (void)testSafariVCForMissingLoginMissingSharingMissingDefaultValue
{
  [self assertSafariVcIs:NO
          forFeatureName:@"login"
        withFeatureValue:nil
            sharingValue:nil
            defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'login'  / nil   / nil           / true           / true
- (void)testSafariVCForMissingLoginMissingSharingTrueDefault
{
  [self assertSafariVcIs:YES
          forFeatureName:@"login"
        withFeatureValue:nil
            sharingValue:nil
            defaultValue:@YES];
}

// querying / value / sharing value / default value  / expected
// 'login'  / nil   / nil           / false          / false
- (void)testSafariVCForMissingLoginMissingSharingFalseDefault
{
  [self assertSafariVcIs:NO
          forFeatureName:@"login"
        withFeatureValue:nil
            sharingValue:nil
            defaultValue:@NO];
}

// querying / value / sharing value / default value  / expected
// 'login'  / nil   / true          / nil            / false
- (void)testSafariVCForMissingLoginTrueSharingMissingDefault
{
  [self assertSafariVcIs:NO
          forFeatureName:@"login"
        withFeatureValue:nil
            sharingValue:@YES
            defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'login'  / nil   / true          / true           / true
- (void)testSafariVCForMissingLoginTrueSharingTrueDefault
{
  [self assertSafariVcIs:YES
          forFeatureName:@"login"
        withFeatureValue:nil
            sharingValue:@YES
            defaultValue:@YES];
}

// querying / value / sharing value / default value  / expected
// 'login'  / nil   / true          / false          / false
- (void)testSafariVCForMissingLoginTrueSharingFalseDefault
{
  [self assertSafariVcIs:NO
          forFeatureName:@"login"
        withFeatureValue:nil
            sharingValue:@YES
            defaultValue:@NO];
}

// querying / value / sharing value / default value  / expected
// 'login'  / nil   / false         / nil            / false
- (void)testSafariVCForMissingLoginFalseSharingMissingDefault
{
  [self assertSafariVcIs:NO
          forFeatureName:@"login"
        withFeatureValue:nil
            sharingValue:@NO
            defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'login'  / nil   / false         / true           / true
- (void)testSafariVCForMissingLoginFalseSharingTrueDefault
{
  [self assertSafariVcIs:YES
          forFeatureName:@"login"
        withFeatureValue:nil
            sharingValue:@NO
            defaultValue:@YES];
}

// querying / value / sharing value / default value  / expected
// 'login'  / nil   / false         / false          / false
- (void)testSafariVCForMissingLoginFalseSharingFalseDefault
{
  [self assertSafariVcIs:NO
          forFeatureName:@"login"
        withFeatureValue:nil
            sharingValue:@NO
            defaultValue:@NO];
}

// querying / value / sharing value / default value  / expected
// 'login'  / true  / nil           / nil            / true
- (void)testSafariVCForTrueLoginMissingSharingMissingDefault
{
  [self assertSafariVcIs:YES
          forFeatureName:@"login"
        withFeatureValue:@YES
            sharingValue:nil
            defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'login'  / true  / nil           / true           / true
- (void)testSafariVCForTrueLoginMissingSharingTrueDefault
{
  [self assertSafariVcIs:YES
          forFeatureName:@"login"
        withFeatureValue:@YES
            sharingValue:nil
            defaultValue:@YES];
}

// querying / value / sharing value / default value  / expected
// 'login'  / true  / nil           / false          / true
- (void)testSafariVCForTrueLoginMissingSharingFalseDefault
{
  [self assertSafariVcIs:YES
          forFeatureName:@"login"
        withFeatureValue:@YES
            sharingValue:nil
            defaultValue:@NO];
}

// querying / value / sharing value / default value  / expected
// 'login'  / true  / true          / nil            / true
- (void)testSafariVCForTrueLoginTrueSharingMissingDefault
{
  [self assertSafariVcIs:YES
          forFeatureName:@"login"
        withFeatureValue:@YES
            sharingValue:@YES
            defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'login'  / true  / true          / true           / true
- (void)testSafariVCForTrueLoginTrueSharingTrueDefault
{
  [self assertSafariVcIs:YES
          forFeatureName:@"login"
        withFeatureValue:@YES
            sharingValue:@YES
            defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'login'  / true  / true          / false          / true
- (void)testSafariVCForTrueLoginTrueSharingFalseDefault
{
  [self assertSafariVcIs:YES
          forFeatureName:@"login"
        withFeatureValue:@YES
            sharingValue:@YES
            defaultValue:@NO];
}

// querying / value / sharing value / default value  / expected
// 'login'  / true  / false         / nil            / true
- (void)testSafariVCForTrueLoginFalseSharingMissingDefault
{
  [self assertSafariVcIs:YES
          forFeatureName:@"login"
        withFeatureValue:@YES
            sharingValue:@NO
            defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'login'  / true  / false         / true           / true
- (void)testSafariVCForTrueLoginFalseSharingTrueDefault
{
  [self assertSafariVcIs:YES
          forFeatureName:@"login"
        withFeatureValue:@YES
            sharingValue:@NO
            defaultValue:@YES];
}

// querying / value / sharing value / default value  / expected
// 'login'  / true  / false         / false          / true
- (void)testSafariVCForTrueLoginFalseSharingFalseDefault
{
  [self assertSafariVcIs:YES
          forFeatureName:@"login"
        withFeatureValue:@YES
            sharingValue:@NO
            defaultValue:@NO];
}

// querying / value / sharing value / default value  / expected
// 'login'  / false / nil           / nil            / false
- (void)testSafariVCForFalseLoginMissingSharingMissingDefault
{
  [self assertSafariVcIs:NO
          forFeatureName:@"login"
        withFeatureValue:@NO
            sharingValue:nil
            defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'login'  / false / nil           / true           / false
- (void)testSafariVCForFalseLoginMissingSharingTrueDefault
{
  [self assertSafariVcIs:NO
          forFeatureName:@"login"
        withFeatureValue:@NO
            sharingValue:nil
            defaultValue:@YES];
}

// querying / value / sharing value / default value  / expected
// 'login'  / false / nil           / false          / false
- (void)testSafariVCForFalseLoginMissingSharingFalseDefault
{
  [self assertSafariVcIs:NO
          forFeatureName:@"login"
        withFeatureValue:@NO
            sharingValue:nil
            defaultValue:@NO];
}

// querying / value / sharing value / default value  / expected
// 'login'  / false / true          / nil            / false
- (void)testSafariVCForFalseLoginTrueSharingMissingDefault
{
  [self assertSafariVcIs:NO
          forFeatureName:@"login"
        withFeatureValue:@NO
            sharingValue:@YES
            defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'login'  / false / true          / true           / false
- (void)testSafariVCForFalseLoginTrueSharingTrueDefault
{
  [self assertSafariVcIs:NO
          forFeatureName:@"login"
        withFeatureValue:@NO
            sharingValue:@YES
            defaultValue:@YES];
}

// querying / value / sharing value / default value  / expected
// 'login'  / false / true          / false          / false
- (void)testSafariVCForFalseLoginTrueSharingFalseDefault
{
  [self assertSafariVcIs:NO
          forFeatureName:@"login"
        withFeatureValue:@NO
            sharingValue:@YES
            defaultValue:@NO];
}

// querying / value / sharing value / default value  / expected
// 'login'  / false / false         / nil            / false
- (void)testSafariVCForFalseLoginFalseSharingMissingDefault
{
  [self assertSafariVcIs:NO
          forFeatureName:@"login"
        withFeatureValue:@NO
            sharingValue:@NO
            defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'login'  / false / false         / true           / false
- (void)testSafariVCForFalseLoginFalseSharingTrueDefault
{
  [self assertSafariVcIs:NO
          forFeatureName:@"login"
        withFeatureValue:@NO
            sharingValue:@NO
            defaultValue:@YES];
}

// querying / value / sharing value / default value  / expected
// 'login'  / false / false         / false          / false
- (void)testSafariVCForFalseLoginFalseSharingFalseDefault
{
  [self assertSafariVcIs:NO
          forFeatureName:@"login"
        withFeatureValue:@NO
            sharingValue:@NO
            defaultValue:@NO];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / nil   / nil           / nil            / false
- (void)testSafariVCForMissingDialogMissingSharingMissingDefaultValue
{
  [self assertSafariVcIs:NO
          forFeatureName:@"foo"
        withFeatureValue:nil
            sharingValue:nil
            defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / nil   / nil           / true           / true
- (void)testSafariVCForMissingDialogMissingSharingTrueDefault
{
  [self assertSafariVcIs:YES
          forFeatureName:@"foo"
        withFeatureValue:nil
            sharingValue:nil
            defaultValue:@YES];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / nil   / nil           / false          / false
- (void)testSafariVCForMissingDialogMissingSharingFalseDefault
{
  [self assertSafariVcIs:NO
          forFeatureName:@"foo"
        withFeatureValue:nil
            sharingValue:nil
            defaultValue:@NO];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / nil   / true          / nil            / false
- (void)testSafariVCForMissingDialogTrueSharingMissingDefault
{
  [self assertSafariVcIs:YES
          forFeatureName:@"foo"
        withFeatureValue:nil
            sharingValue:@YES
            defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / nil   / true          / true           / true
- (void)testSafariVCForMissingDialogTrueSharingTrueDefault
{
  [self assertSafariVcIs:YES
          forFeatureName:@"foo"
        withFeatureValue:nil
            sharingValue:@YES
            defaultValue:@YES];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / nil   / true          / false          / true
- (void)testSafariVCForMissingDialogTrueSharingFalseDefault
{
  [self assertSafariVcIs:YES
          forFeatureName:@"foo"
        withFeatureValue:nil
            sharingValue:@YES
            defaultValue:@NO];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / nil   / false         / nil            / false
- (void)testSafariVCForMissingDialogFalseSharingMissingDefault
{
  [self assertSafariVcIs:NO
          forFeatureName:@"foo"
        withFeatureValue:nil
            sharingValue:@NO
            defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / nil   / false         / true           / false
- (void)testSafariVCForMissingDialogFalseSharingTrueDefault
{
  [self assertSafariVcIs:NO
          forFeatureName:@"foo"
        withFeatureValue:nil
            sharingValue:@NO
            defaultValue:@YES];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / nil   / false         / false          / false
- (void)testSafariVCForMissingDialogFalseSharingFalseDefault
{
  [self assertSafariVcIs:NO
          forFeatureName:@"foo"
        withFeatureValue:nil
            sharingValue:@NO
            defaultValue:@NO];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / true  / nil           / nil            / true
- (void)testSafariVCForTrueDialogMissingSharingMissingDefault
{
  [self assertSafariVcIs:YES
          forFeatureName:@"foo"
        withFeatureValue:@YES
            sharingValue:nil
            defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / true  / nil           / true           / true
- (void)testSafariVCForTrueDialogMissingSharingTrueDefault
{
  [self assertSafariVcIs:YES
          forFeatureName:@"foo"
        withFeatureValue:@YES
            sharingValue:nil
            defaultValue:@YES];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / true  / nil           / false          / true
- (void)testSafariVCForTrueDialogMissingSharingFalseDefault
{
  [self assertSafariVcIs:YES
          forFeatureName:@"foo"
        withFeatureValue:@YES
            sharingValue:nil
            defaultValue:@NO];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / true  / true          / nil            / true
- (void)testSafariVCForTrueDialogTrueSharingMissingDefault
{
  [self assertSafariVcIs:YES
          forFeatureName:@"foo"
        withFeatureValue:@YES
            sharingValue:@YES
            defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / true  / true          / true           / true
- (void)testSafariVCForTrueDialogTrueSharingTrueDefault
{
  [self assertSafariVcIs:YES
          forFeatureName:@"foo"
        withFeatureValue:@YES
            sharingValue:@YES
            defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / true  / true          / false          / true
- (void)testSafariVCForTrueDialogTrueSharingFalseDefault
{
  [self assertSafariVcIs:YES
          forFeatureName:@"foo"
        withFeatureValue:@YES
            sharingValue:@YES
            defaultValue:@NO];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / true  / false         / nil            / true
- (void)testSafariVCForTrueDialogFalseSharingMissingDefault
{
  [self assertSafariVcIs:YES
          forFeatureName:@"foo"
        withFeatureValue:@YES
            sharingValue:@NO
            defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / true  / false         / true           / true
- (void)testSafariVCForTrueDialogFalseSharingTrueDefault
{
  [self assertSafariVcIs:YES
          forFeatureName:@"foo"
        withFeatureValue:@YES
            sharingValue:@NO
            defaultValue:@YES];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / true  / false         / false          / true
- (void)testSafariVCForTrueDialogFalseSharingFalseDefault
{
  [self assertSafariVcIs:YES
          forFeatureName:@"foo"
        withFeatureValue:@YES
            sharingValue:@NO
            defaultValue:@NO];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / false / nil           / nil            / false
- (void)testSafariVCForFalseDialogMissingSharingMissingDefault
{
  [self assertSafariVcIs:NO
          forFeatureName:@"foo"
        withFeatureValue:@NO
            sharingValue:nil
            defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / false / nil           / true           / false
- (void)testSafariVCForFalseDialogMissingSharingTrueDefault
{
  [self assertSafariVcIs:NO
          forFeatureName:@"foo"
        withFeatureValue:@NO
            sharingValue:nil
            defaultValue:@YES];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / false / nil           / false          / false
- (void)testSafariVCForFalseDialogMissingSharingFalseDefault
{
  [self assertSafariVcIs:NO
          forFeatureName:@"foo"
        withFeatureValue:@NO
            sharingValue:nil
            defaultValue:@NO];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / false / true          / nil            / false
- (void)testSafariVCForFalseDialogTrueSharingMissingDefault
{
  [self assertSafariVcIs:NO
          forFeatureName:@"foo"
        withFeatureValue:@NO
            sharingValue:@YES
            defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / false / true          / true           / false
- (void)testSafariVCForFalseDialogTrueSharingTrueDefault
{
  [self assertSafariVcIs:NO
          forFeatureName:@"foo"
        withFeatureValue:@NO
            sharingValue:@YES
            defaultValue:@YES];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / false / true          / false          / false
- (void)testSafariVCForFalseDialogTrueSharingFalseDefault
{
  [self assertSafariVcIs:NO
          forFeatureName:@"foo"
        withFeatureValue:@NO
            sharingValue:@YES
            defaultValue:@NO];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / false / false         / nil            / false
- (void)testSafariVCForFalseDialogFalseSharingMissingDefault
{
  [self assertSafariVcIs:NO
          forFeatureName:@"foo"
        withFeatureValue:@NO
            sharingValue:@NO
            defaultValue:nil];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / false / false         / true           / false
- (void)testSafariVCForFalseDialogFalseSharingTrueDefault
{
  [self assertSafariVcIs:NO
          forFeatureName:@"foo"
        withFeatureValue:@NO
            sharingValue:@NO
            defaultValue:@YES];
}

// querying / value / sharing value / default value  / expected
// 'foo'    / false / false         / false          / false
- (void)testSafariVCForFalseDialogFalseSharingFalseDefault
{
  [self assertSafariVcIs:NO
          forFeatureName:@"foo"
        withFeatureValue:@NO
            sharingValue:@NO
            defaultValue:@NO];
}

#pragma mark Helpers

- (void)setupConfigWithDialogFlowKey:(NSString *)flowKey
                      forFeatureName:(NSString *)name
                    withFeatureValue:(NSNumber *)featureValue
                        sharingValue:(NSNumber *)sharingValue
                        defaultValue:(NSNumber *)defaultValue
{
  NSMutableDictionary *dialogFlows = [NSMutableDictionary dictionary];
  if (featureValue != nil) {
    dialogFlows[name] = @{
      flowKey: featureValue
    };
  }
  if (sharingValue != nil) {
    dialogFlows[@"sharing"] = @{
      flowKey: sharingValue
    };
  }
  if (defaultValue != nil) {
    dialogFlows[@"default"] = @{
      flowKey: defaultValue
    };
  }

  config = [Fixtures configWithDictionary:@{ @"dialogFlows": dialogFlows }];
}

- (void)assertSafariVcIs:(BOOL)expected
          forFeatureName:(NSString *)name
        withFeatureValue:(NSNumber *)featureValue
            sharingValue:(NSNumber *)sharingValue
            defaultValue:(NSNumber *)defaultValue
{
  [self setupConfigWithDialogFlowKey:@"use_safari_vc"
                      forFeatureName:name
                    withFeatureValue:featureValue sharingValue:sharingValue
                        defaultValue:defaultValue];

  XCTAssertEqual([config useSafariViewControllerForDialogName:name],
                 expected,
                 "Use safari view controller for dialog name: %@, should return true when the feature value is: %@, the sharing value is: %@, and the default value is: %@",
                 name, featureValue, sharingValue, defaultValue);
}

- (void)assertNativeDialogIs:(BOOL)expected
              forFeatureName:(NSString *)name
            withFeatureValue:(NSNumber *)featureValue
                sharingValue:(NSNumber *)sharingValue
                defaultValue:(NSNumber *)defaultValue
{
  [self setupConfigWithDialogFlowKey:@"use_native_flow"
                      forFeatureName:name
                    withFeatureValue:featureValue
                        sharingValue:sharingValue
                        defaultValue:defaultValue];

  XCTAssertEqual([config useNativeDialogForDialogName:name],
                 expected,
                 "Use native dialog for dialog name: %@, should return true when the feature value is: %@, the sharing value is: %@, and the default value is: %@",
                 name, featureValue, sharingValue, defaultValue);

}

@end
