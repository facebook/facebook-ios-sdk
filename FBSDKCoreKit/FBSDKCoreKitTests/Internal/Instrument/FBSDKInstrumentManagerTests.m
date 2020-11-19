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

#import "FBSDKCoreKitTestUtility.h"
#import "FBSDKFeatureManager.h"
#import "FBSDKInstrumentManager.h"
#import "FBSDKTestCase.h"

@interface FBSDKInstrumentManagerTests : FBSDKTestCase
@end

@implementation FBSDKInstrumentManagerTests

- (void)testEnablingWithAutoLogEventsEnabledFeaturesEnabled
{
  [self stubIsAutoLogAppEventsEnabled:YES];
  [self stubFeatureChecksCompleteWith:YES];

  OCMStub(ClassMethod([self.crashObserverClassMock enable]));
  OCMStub(ClassMethod([self.errorReportClassMock enable]));

  [FBSDKInstrumentManager enable];

  OCMVerify([self.crashObserverClassMock enable]);
  OCMVerify([self.errorReportClassMock enable]);
}

- (void)testEnablingWithAutoLogEventsEnabledFeaturesDisabled
{
  [self stubIsAutoLogAppEventsEnabled:YES];
  [self stubFeatureChecksCompleteWith:NO];
  [self rejectFeatureEnabling];

  [FBSDKInstrumentManager enable];
}

- (void)testEnablingWithAutoLogEventsDisabledFeaturesEnabled
{
  [self stubIsAutoLogAppEventsEnabled:NO];
  [self stubFeatureChecksCompleteWith:YES];
  [self rejectFeatureEnabling];

  [FBSDKInstrumentManager enable];
}

- (void)testEnablingWithAutoLogEventsDisabledFeaturesDisabled
{
  [self stubIsAutoLogAppEventsEnabled:YES];
  [self stubFeatureChecksCompleteWith:NO];
  [self rejectFeatureEnabling];

  [FBSDKInstrumentManager enable];
}

// MARK: - Helpers

- (void)stubFeatureChecksCompleteWith:(BOOL)value
{
  OCMStub(
    ClassMethod(
      [self.featureManagerClassMock checkFeature:FBSDKFeatureCrashReport
                                 completionBlock:([OCMArg invokeBlockWithArgs:@(value), nil])]
    )
  );
  OCMStub(
    ClassMethod(
      [self.featureManagerClassMock checkFeature:FBSDKFeatureErrorReport
                                 completionBlock:([OCMArg invokeBlockWithArgs:@(value), nil])]
    )
  );
}

- (void)rejectFeatureEnabling
{
  OCMReject([self.crashObserverClassMock enable]);
  OCMReject([self.errorReportClassMock enable]);
}

@end
