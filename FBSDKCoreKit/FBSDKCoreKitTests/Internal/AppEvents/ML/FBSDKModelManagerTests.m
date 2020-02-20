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

#import "FBSDKFeatureManager.h"
#import "FBSDKGraphRequest.h"
#import "FBSDKGraphRequestConnection.h"
#import "FBSDKModelManager.h"

@interface FBSDKModelManagerTests : XCTestCase
@end

@implementation FBSDKModelManagerTests {
  id _mockFeatureManager;
}

- (void)setUp {
  id mockLocale = OCMClassMock([NSLocale class]);
  OCMStub([mockLocale currentLocale]).andReturn(mockLocale);
  OCMStub([mockLocale objectForKey:NSLocaleLanguageCode]).andReturn(@"en");

  id mockRequest = OCMClassMock([FBSDKGraphRequest class]);
  OCMStub([mockRequest alloc]).andReturn(mockRequest);
  OCMStub([mockRequest initWithGraphPath:OCMOCK_ANY]).andReturn(mockRequest);
  OCMStub([mockRequest startWithCompletionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation){
    FBSDKGraphRequestBlock handler;
    [invocation getArgument:&handler atIndex:2];
    if (handler) {
      handler(nil, [self _mockResult], nil);
    }
  });

  _mockFeatureManager = OCMClassMock([FBSDKFeatureManager class]);
}

- (void)testFeatureMTMLEnabled {
  OCMStub([_mockFeatureManager checkFeature:FBSDKFeatureMTML completionBlock:OCMOCK_ANY]).andDo(^(NSInvocation *invocation){
    FBSDKFeatureManagerBlock block;
    [invocation getArgument:&block atIndex:3];
    if (block) {
      block(true);
    }
  });

  [FBSDKModelManager enable];

  OCMVerify([_mockFeatureManager checkFeature:FBSDKFeatureSuggestedEvents completionBlock:OCMOCK_ANY]);
  OCMVerify([_mockFeatureManager checkFeature:FBSDKFeaturePIIFiltering completionBlock:OCMOCK_ANY]);
}

- (void)testFeatureMTMLDisabled {
  OCMStub([_mockFeatureManager checkFeature:FBSDKFeatureMTML completionBlock:OCMOCK_ANY]).andDo(^(NSInvocation *invocation){
    FBSDKFeatureManagerBlock block;
    [invocation getArgument:&block atIndex:3];
    if (block) {
      block(false);
    }
  });

  [FBSDKModelManager enable];

  OCMVerify([_mockFeatureManager checkFeature:FBSDKFeatureSuggestedEvents completionBlock:OCMOCK_ANY]);
  OCMVerify([_mockFeatureManager checkFeature:FBSDKFeaturePIIFiltering completionBlock:OCMOCK_ANY]);
}

- (NSDictionary<NSString *, NSArray *> *)_mockResult
{
  return @{@"data": @[@{@"use_case": @"DATA_DETECTION_ADDRESS", @"version_id": @1}]};
}

@end
