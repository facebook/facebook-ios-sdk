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

#import "FBSDKAppEventsConfiguration.h"

@class FBSDKAppEventsConfiguration;
@class FBSDKServerConfiguration;

NS_ASSUME_NONNULL_BEGIN

/**
 This shared test case class is intended to provide commonly mocked objects and methods for stubbing out common side effects such as
 fetching from the network when objects are missing from a given cache. Additionally this class will handle stopping mocking and invalidating
 mock objects to avoid potential shared global state between tests.

 In general there are three broad use cases for mocks. These include:

 1) stubbing out a method in order to avoid calling it or to provide a known return value.

 2) stubbing out a method (usually an initializer or a singleton) to replace an object with a test object.

 3) stubbing out a method on the object you're testing. ie. use the real implementation for method a but stub out the implementation for method b.

 4) verifying behavior - something was called or something was not called etc...

Before you write a new class mock. Check to see if there's already an implementation in this class.
Also, to get a better understanding of mocking, please read the documentation at https://ocmock.org/
*/
@interface FBSDKTestCase : XCTestCase

/// Used for sharing a common app identifier between tests. This is not a valid FB App ID
@property (nullable, assign) NSString *appID;

/// Used during `-setUp` to determine the type of mock for `appEventsMock` (partial or nice), default is `NO`
@property (assign) BOOL shouldAppEventsMockBePartial;

/// Used for sharing an `FBSDKAppEvents` mock between tests
@property (nullable, assign) id appEventsMock;

/// Used for sharing a `FBSDKAppEventsUtility` class  mock between tests
@property (nullable, nonatomic, assign) id appEventsUtilityClassMock;

/// Used for sharing an `FBSDKSettings` class mock between tests
@property (nullable, assign) id settingsClassMock;

/// Used for sharing a `FBSDKInternalUtility` class mock between tests
@property (nullable, nonatomic, assign) id internalUtilityClassMock;

/// Used for sharing a `FBSDKGraphRequestConnection` class mock between tests
@property (nullable, nonatomic, assign) id graphRequestConnectionClassMock;

/// Used for sharing a `UIApplication.sharedApplication` mock between tests
@property (nullable, nonatomic, assign) id sharedApplicationMock;

/// Used for stubbing any instance that conforms to the `UIViewControllerTransitionCoordinator` protocol
@property (nullable, nonatomic, assign) id transitionCoordinatorMock;

/// Used for sharing a `FBSDKBridgeAPIResponse` class mock between tests
@property (nullable, nonatomic, assign) id bridgeApiResponseClassMock;

/// Used for sharing a `FBSDKUtility` class mock between tests
@property (nullable, nonatomic, assign) id utilityClassMock;

/// Used for sharing a `ASIdentifier` class mock between tests
@property (nullable, nonatomic, assign) id asIdentifierManagerClassMock;

/// Stubs `FBSDKAppEventsUtility.shared.advertiserID` with the provided value
- (void)stubAppEventsUtilityAdvertiserIDWith:(nullable NSString *)identifier;

/// Disables creation of graph request connections so that they cannot be started.
/// This is the nuclear option. It should be removed as soon as possible so that we can test important things
/// like whether or not a given method actually started a graph request.
/// This should be used only as needed as a stopgap to keep tests
/// from hitting the network while proper mocks are being written.
- (void)stubAllocatingGraphRequestConnection;

/// Stubs `UIApplication.sharedApplication`'s `openURL:` method and returns the provided value
- (void)stubOpenURLWith:(BOOL)openURL;

/// Stubs `UIApplication.sharedApplication`'s `openURL:options:completionHandler:` method
///
/// - Parameters:
/// - performCompletion: Whether to invoke the completion handler
/// - completionSuccess: The value to pass for the success parameter of the completion handler
- (void)stubOpenUrlOptionsCompletionHandlerWithPerformCompletion:(BOOL)performCompletion
                                               completionSuccess:(BOOL)completionSuccess;

/// Stubs `FBSDKInternalUtility`'s `appURLScheme` property to return the provided scheme
- (void)stubAppUrlSchemeWith:(nullable NSString *)scheme;

/// Stubs `ASIdentifierManager.sharedManager` and returns the provided identifier manager
- (void)stubSharedAsIdentifierManagerWithAsIdentifierManager:(id)identifierManager;

/// Stubs `ASIdentifierManager.advertisingIdentifier` and returns the provided value
- (void)stubAdvertisingIdentifierWithIdentifier:(NSUUID *)uuid;

@end

NS_ASSUME_NONNULL_END
