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

@import LegacyGamingServices;
@import XCTest;

#import "LegacyGamingServicesTests-Swift.h"

@interface FBSDKFriendFinderDialogTests : XCTestCase

@property (nonatomic) TestGamingServiceControllerFactory *factory;
@property (nonatomic) FBSDKFriendFinderDialog *dialog;
@property (nonatomic) NSError *bridgeAPIError;

@end

@implementation FBSDKFriendFinderDialogTests

- (void)setUp
{
  [super setUp];
  [[FBSDKApplicationDelegate sharedInstance] application:[UIApplication sharedApplication] didFinishLaunchingWithOptions:[NSMutableDictionary dictionary]];
  self.bridgeAPIError = [[NSError alloc]
                         initWithDomain:FBSDKErrorDomain
                         code:FBSDKErrorBridgeAPIInterruption
                         userInfo:nil];
  self.factory = [TestGamingServiceControllerFactory new];
  self.dialog = [[FBSDKFriendFinderDialog alloc] initWithGamingServiceControllerFactory:self.factory];
  FBSDKAccessToken.currentAccessToken = [self createAccessToken];
}

- (void)tearDown
{
  FBSDKAccessToken.currentAccessToken = nil;

  [super tearDown];
}

// MARK: - Dependencies

- (void)testDefaultDependencies
{
  XCTAssertEqualObjects(
    [(NSObject *)FBSDKFriendFinderDialog.shared.factory class],
    FBSDKGamingServiceControllerFactory.class,
    "Should use the expected default gaming service controller factory type by default"
  );
}

// MARK: - Launching Dialogs

- (void)testFailureWhenNoValidAccessTokenPresentAndAppIDIsNull
{
  [FBSDKAccessToken setCurrentAccessToken:nil];
  [FBSDKSettings setAppID:nil];

  __block BOOL actioned = false;
  [self.dialog
   launchFriendFinderDialogWithCompletionHandler:^(BOOL success, NSError *_Nullable error) {
     XCTAssert(error.code == FBSDKErrorAccessTokenRequired, "Expected error requiring a valid access token");
     actioned = true;
   }];

  XCTAssertTrue(actioned);
}

- (void)testPresentationWhenTokenIsNilAndAppIDIsSet
{
  [FBSDKAccessToken setCurrentAccessToken:nil];
  [FBSDKSettings setAppID:@"appID"];

  __block BOOL didInvokeCompletion = false;
  [self.dialog
   launchFriendFinderDialogWithCompletionHandler:^(BOOL success, NSError *_Nullable error) {
     XCTAssertTrue(success);
     didInvokeCompletion = YES;
   }];
  XCTAssertEqualObjects(
    self.factory.controller.capturedArgument,
    [FBSDKSettings appID],
    "Should invoke the new controller with the app id in the sdk setting"
  );
  self.factory.capturedCompletion(YES, nil, nil);
  XCTAssertTrue(didInvokeCompletion);
}

- (void)testPresentationWhenTokenIsSetAndAppIDIsNil
{
  [FBSDKSettings setAppID:nil];

  __block BOOL didInvokeCompletion = NO;
  [self.dialog
   launchFriendFinderDialogWithCompletionHandler:^(BOOL success, NSError *_Nullable error) {
     didInvokeCompletion = YES;
   }];

  XCTAssertEqual(
    self.factory.capturedServiceType,
    FBSDKGamingServiceTypeFriendFinder,
    "Should create a controller with the expected service type"
  );
  XCTAssertNil(
    self.factory.capturedPendingResult,
    "Should not create a controller with a pending result"
  );
  XCTAssertEqualObjects(
    self.factory.controller.capturedArgument,
    FBSDKAccessToken.currentAccessToken.appID,
    "Should invoke the new controller with the app id of the current access token"
  );
  self.factory.capturedCompletion(YES, nil, nil);

  XCTAssertTrue(didInvokeCompletion);
}

- (void)testFailuresReturnAnError
{
  __block BOOL didInvokeCompletion = NO;
  [self.dialog
   launchFriendFinderDialogWithCompletionHandler:^(BOOL success, NSError *_Nullable error) {
     XCTAssertFalse(success);
     XCTAssert(error.code == FBSDKErrorBridgeAPIInterruption);
     didInvokeCompletion = YES;
   }];

  XCTAssertEqual(
    self.factory.capturedServiceType,
    FBSDKGamingServiceTypeFriendFinder,
    "Should create a controller with the expected service type"
  );
  XCTAssertNil(
    self.factory.capturedPendingResult,
    "Should not create a controller with a pending result"
  );
  XCTAssertEqualObjects(
    self.factory.controller.capturedArgument,
    FBSDKAccessToken.currentAccessToken.appID,
    "Should invoke the new controller with the app id of the current access token"
  );

  self.factory.capturedCompletion(NO, nil, self.bridgeAPIError);

  XCTAssertTrue(didInvokeCompletion);
}

- (void)testHandlingOfCallbackURL
{
  __block BOOL actioned = false;
  [self.dialog
   launchFriendFinderDialogWithCompletionHandler:^(BOOL success, NSError *_Nullable error) {
     XCTAssertTrue(success);
     actioned = true;
   }];

  self.factory.capturedCompletion(YES, nil, nil);

  XCTAssertTrue(actioned);
}

// MARK: - Helpers

- (FBSDKAccessToken *)createAccessToken
{
  return [[FBSDKAccessToken alloc]
          initWithTokenString:@"abc"
          permissions:@[]
          declinedPermissions:@[]
          expiredPermissions:@[]
          appID:@"123"
          userID:@""
          expirationDate:nil
          refreshDate:nil
          dataAccessExpirationDate:nil];
}

@end
