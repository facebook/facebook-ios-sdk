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

#import "FBSDKMonitoringConfiguration.h"

#import "FBSDKTestCoder.h"
#import "TestMonitorEntry.h"
#import "FBSDKMonitoringConfigurationTestHelper.h"

@interface FBSDKMonitoringConfiguration (Testing)

- (NSDictionary<NSString *, NSNumber *> *)sampleRates;

@end

@interface FBSDKMonitoringConfigurationTests : XCTestCase

@property (nonatomic) FBSDKMonitoringConfiguration *config;

@end

@implementation FBSDKMonitoringConfigurationTests

typedef FBSDKMonitoringConfigurationTestHelper MonitoringConfiguration;

- (void)testDefaultMonitoringConfiguration
{
  self.config = FBSDKMonitoringConfiguration.defaultConfiguration;

  XCTAssertEqual(self.config.defaultSamplingRate, 0,
                 @"Default sampling rate should be zero if unspecified");
  XCTAssertEqual(self.config.sampleRates.count, 0,
                 @"A config should not have any sample rates by default");
}

- (void)testCreatingWithMissingSamplingRates
{
  self.config = [FBSDKMonitoringConfiguration fromDictionary:@{}];

  XCTAssertEqual(self.config.defaultSamplingRate, 0,
                 @"Default sampling rate should be zero if unspecified");
  XCTAssertEqual(self.config.sampleRates.count, 0,
                 @"A config should not have any sample rates by default");
}

- (void)testCreatingWithEmptySamplingRates
{
  NSDictionary *dict = [MonitoringConfiguration sampleRatesWithEntryPairs:@{}];

  self.config = [FBSDKMonitoringConfiguration fromDictionary:dict];

  XCTAssertEqual(self.config.defaultSamplingRate, 0,
                 @"Default sampling rate should be zero if missing from the sampling rates");
  XCTAssertEqual(self.config.sampleRates.count, 0,
                 @"A config should not have any sample rates by default");
}


- (void)testCreatingWithMissingDefaultSamplingRate
{
  NSDictionary *expectedSampleRates = @{
    @"foo": @1
  };

  NSDictionary *dict = [MonitoringConfiguration sampleRatesWithEntryPairs:@{ @"foo": @1 }];

  self.config = [FBSDKMonitoringConfiguration fromDictionary:dict];

  XCTAssertEqual(self.config.defaultSamplingRate, 0,
                 @"Default sampling rate should be zero if missing from the sampling rates");
  XCTAssertTrue([self.config.sampleRates isEqualToDictionary:expectedSampleRates],
                @"A config should set sample rates correctly based on the input rates");
}

- (void)testCreatingWithValidDefaultSamplingRate
{
  NSDictionary *dict = [MonitoringConfiguration sampleRatesWithEntryPairs:@{ @"default": @100 }];

  self.config = [FBSDKMonitoringConfiguration fromDictionary:dict];

  XCTAssertEqual(self.config.defaultSamplingRate, 100,
                 @"Default sampling rate should be gleaned from the initializing dictionary");
}

- (void)testCreatingWithOnlyInvalidSamplingRates
{
  NSDictionary *dict = [MonitoringConfiguration sampleRatesWithEntryPairs:@{
    @"default": @-1,
    @"foo": @"bar"
  }];

  self.config = [FBSDKMonitoringConfiguration fromDictionary:dict];

  XCTAssertEqual(self.config.defaultSamplingRate, 0,
                 @"Default sampling rate should be zero if no valid default is given");
  XCTAssertTrue([self.config.sampleRates isEqualToDictionary:@{}],
                @"Should not store invalid sample rates");
}

- (void)testCreatingWihSomeInvalidSampleRates
{
  NSDictionary *dict = [MonitoringConfiguration sampleRatesWithEntryPairs:@{
    @"default": @-1,
    @"foo": @50
  }];

  self.config = [FBSDKMonitoringConfiguration fromDictionary:dict];

  XCTAssertEqual(self.config.defaultSamplingRate, 0,
                 @"Default sampling rate should be gleaned from the initializing dictionary");

}

- (void)testGettingSampleRate
{
  NSDictionary *dict = [MonitoringConfiguration sampleRatesWithEntryPairs:@{ @"foo": @50 }];

  self.config = [FBSDKMonitoringConfiguration fromDictionary:dict];

  XCTAssertEqual([self.config sampleRateForEntry: [TestMonitorEntry testEntryWithName:@"foo"]], 50,
                 @"Should retrieve the sample rate for the entry with the matching name");
}

- (void)testEncoding
{
  FBSDKTestCoder *coder = [FBSDKTestCoder new];
  NSDictionary *expectedSampleRates = @{@"foo": @50};
  NSDictionary *dict = [MonitoringConfiguration sampleRatesWithEntryPairs:@{ @"foo": @50 }];

  self.config = [FBSDKMonitoringConfiguration fromDictionary:dict];

  [self.config encodeWithCoder:coder];

  XCTAssertEqualObjects(coder.encodedObject[@"sample_rates"], expectedSampleRates,
                        @"Should encode the sample rates");
}

- (void)testDecoding
{
  FBSDKTestCoder *decoder = [FBSDKTestCoder new];

  NSDictionary *dict = [MonitoringConfiguration sampleRatesWithEntryPairs:@{ @"foo": @50 }];

  self.config = [FBSDKMonitoringConfiguration fromDictionary:dict];

  self.config = [self.config initWithCoder:decoder];

  XCTAssertEqualObjects(decoder.decodedObject[@"sample_rates"], [NSDictionary class],
                        @"Should attempt to decode a dictionary of sample rates when initializing from a decoder");
}

#pragma mark Helpers

@end
