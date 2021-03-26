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

#import "FBSDKAppEventsAtePublisher.h"
#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKTestCase.h"
#import "UserDefaultsSpy.h"

@interface FBSDKAppEventsAtePublisherTests : FBSDKTestCase

@property (nonatomic, strong) UserDefaultsSpy *store;

@end

@implementation FBSDKAppEventsAtePublisherTests

static const int TWELVE_HOURS_AGO_IN_SECONDS = -12 * 60 * 60;
static const int FORTY_EIGHT_HOURS_AGO_IN_SECONDS = -48 * 60 * 60;

- (void)setUp
{
  [super setUp];

  self.store = [UserDefaultsSpy new];
}

- (void)testCreatingWithEmptyAppIdentifier
{
  XCTAssertNil(
    [[FBSDKAppEventsAtePublisher alloc] initWithAppIdentifier:@"" store:self.store],
    "Should not create an ATE publisher with an empty app identifier"
  );
}

- (void)testCreatingWithValidAppIdentifier
{
  FBSDKAppEventsAtePublisher *publisher = [[FBSDKAppEventsAtePublisher alloc] initWithAppIdentifier:self.name store:self.store];
  XCTAssertEqualObjects(
    publisher.appIdentifier,
    self.name,
    "Should be able to create a publisher with a non-empty string for the app identifier"
  );
}

- (void)testPublishingAteWithoutLastPublishDate
{
  [self stubAdvertisingTrackingStatusWith:FBSDKAdvertisingTrackingAllowed];

  id graphRequestMock = OCMClassMock([FBSDKGraphRequest class]);
  OCMStub([graphRequestMock alloc]).andReturn(graphRequestMock);
  OCMStub(
    [graphRequestMock initWithGraphPath:[OCMArg any]
                             parameters:[OCMArg any]
                            tokenString:nil
                             HTTPMethod:FBSDKHTTPMethodPOST
                                  flags:FBSDKGraphRequestFlagDoNotInvalidateTokenOnError | FBSDKGraphRequestFlagDisableErrorRecovery]
  ).andReturn(graphRequestMock);

  FBSDKAppEventsAtePublisher *publisher = [[FBSDKAppEventsAtePublisher alloc] initWithAppIdentifier:self.name store:self.store];

  [publisher publishATE];

  OCMVerify([graphRequestMock startWithCompletionHandler:[OCMArg any]]);

  [graphRequestMock stopMocking];
  graphRequestMock = nil;

  NSString *key = [NSString stringWithFormat:@"com.facebook.sdk:lastATEPing%@", publisher.appIdentifier];
  XCTAssertEqualObjects(
    self.store.capturedObjectRetrievalKey,
    key,
    "Should use the store to access the last published date"
  );
}

- (void)testPublishingWithNonExpiredLastPublishDate
{
  [self.store setObject:[NSDate dateWithTimeIntervalSinceNow:TWELVE_HOURS_AGO_IN_SECONDS]
                 forKey:[NSString stringWithFormat:@"com.facebook.sdk:lastATEPing%@", @"mockAppID"]];
  [self stubAdvertisingTrackingStatusWith:FBSDKAdvertisingTrackingAllowed];

  id graphRequestMock = OCMClassMock([FBSDKGraphRequest class]);
  OCMStub([graphRequestMock alloc]).andReturn(graphRequestMock);
  OCMStub(
    [graphRequestMock initWithGraphPath:[OCMArg any]
                             parameters:[OCMArg any]
                            tokenString:nil
                             HTTPMethod:FBSDKHTTPMethodPOST
                                  flags:FBSDKGraphRequestFlagDoNotInvalidateTokenOnError | FBSDKGraphRequestFlagDisableErrorRecovery]
  ).andReturn(graphRequestMock);

  FBSDKAppEventsAtePublisher *publisher = [[FBSDKAppEventsAtePublisher alloc] initWithAppIdentifier:@"mockAppID" store:self.store];

  OCMReject([graphRequestMock startWithCompletionHandler:[OCMArg any]]);

  [publisher publishATE];

  [graphRequestMock stopMocking];
  graphRequestMock = nil;

  NSString *key = [NSString stringWithFormat:@"com.facebook.sdk:lastATEPing%@", publisher.appIdentifier];
  XCTAssertEqualObjects(
    self.store.capturedObjectRetrievalKey,
    key,
    "Should use the store to access the last published date"
  );
}

- (void)testPublishingWithExpiredLastPublishDate
{
  [self.store setObject:[NSDate dateWithTimeIntervalSinceNow:FORTY_EIGHT_HOURS_AGO_IN_SECONDS]
                 forKey:[NSString stringWithFormat:@"com.facebook.sdk:lastATEPing%@", @"mockAppID"]];
  [self stubAdvertisingTrackingStatusWith:FBSDKAdvertisingTrackingAllowed];

  id graphRequestMock = OCMClassMock([FBSDKGraphRequest class]);
  OCMStub([graphRequestMock alloc]).andReturn(graphRequestMock);
  OCMStub(
    [graphRequestMock initWithGraphPath:[OCMArg any]
                             parameters:[OCMArg any]
                            tokenString:nil
                             HTTPMethod:FBSDKHTTPMethodPOST
                                  flags:FBSDKGraphRequestFlagDoNotInvalidateTokenOnError | FBSDKGraphRequestFlagDisableErrorRecovery]
  ).andReturn(graphRequestMock);

  FBSDKAppEventsAtePublisher *publisher = [[FBSDKAppEventsAtePublisher alloc] initWithAppIdentifier:@"mockAppID"
                                                                                              store:self.store];

  [publisher publishATE];

  OCMVerify([graphRequestMock startWithCompletionHandler:[OCMArg any]]);

  [graphRequestMock stopMocking];
  graphRequestMock = nil;

  NSString *key = [NSString stringWithFormat:@"com.facebook.sdk:lastATEPing%@", publisher.appIdentifier];
  XCTAssertEqualObjects(
    self.store.capturedObjectRetrievalKey,
    key,
    "Should use the store to access the last published date"
  );
}

@end
