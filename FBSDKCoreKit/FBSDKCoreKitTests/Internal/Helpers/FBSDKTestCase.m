// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web ser`vices and APIs provided by Facebook.
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

#import "FBSDKTestCase.h"

#import <OCMock/OCMock.h>

// For mocking ASIdentifier
#import <AdSupport/AdSupport.h>

#import "FBSDKAppEventsUtility.h"

@implementation FBSDKTestCase

- (void)setUp
{
  [super setUp];

  [self setUpAppEventsUtilityMock];
}

- (void)tearDown
{
  [super tearDown];

  [_appEventsUtilityClassMock stopMocking];
  _appEventsUtilityClassMock = nil;
}

- (void)setUpAppEventsUtilityMock
{
  _appEventsUtilityClassMock = OCMStrictClassMock(FBSDKAppEventsUtility.class);
}

#pragma mark - Public Methods

- (void)stubAppEventsUtilityAdvertiserIDWith:(nullable NSString *)identifier
{
  OCMStub(ClassMethod([_appEventsUtilityClassMock shared])).andReturn(_appEventsUtilityClassMock);
  OCMStub([_appEventsUtilityClassMock advertiserID]).andReturn(identifier);
}

@end
