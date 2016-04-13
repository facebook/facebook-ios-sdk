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

#import <FBSDKLoginKit/FBSDKLoginKit.h>

#import <XCTest/XCTest.h>

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKIntegrationTestCase.h"
#import "FBSDKTestBlocker.h"

@interface FBSDKProfileIntegrationTests : FBSDKIntegrationTestCase

@end

@implementation FBSDKProfileIntegrationTests

- (void)setUp {
  [super setUp];
  [FBSDKProfile enableUpdatesOnAccessTokenChange:YES];
}

// basic test of setting currentAccessToken, verifying currentProfile, then clearing currentAccessToken
- (void)testCurrentProfile {
  NSString *const userDefaultsKey = @"com.facebook.sdk.FBSDKProfile.currentProfile";

  FBSDKTestBlocker *blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  __block int notificationCount = 0;
  [self expectationForNotification:FBSDKProfileDidChangeNotification object:nil handler:^BOOL(NSNotification *notification) {
    if (++notificationCount == 1) {
      XCTAssertNil(notification.userInfo[FBSDKProfileChangeOldKey]);
      XCTAssertNotNil(notification.userInfo[FBSDKProfileChangeNewKey]);
    }
    XCTAssertLessThanOrEqual(1, notificationCount);
    return YES;
  }];

  FBSDKAccessToken *token = [self getTokenWithPermissions:nil];
  [FBSDKAccessToken setCurrentAccessToken:token];
  [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
    XCTAssertNil(error);
  }];
  XCTAssertNotNil([FBSDKProfile currentProfile]);
  FBSDKProfile *cachedProfile = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:userDefaultsKey]];
  XCTAssertEqualObjects(cachedProfile, [FBSDKProfile currentProfile]);

  [FBSDKAccessToken setCurrentAccessToken:nil];

  // wait 5 seconds to make sure clearing current access token didn't trigger profile notification.
  [blocker waitWithTimeout:5];
  XCTAssertNotNil([FBSDKProfile currentProfile]);
  // clear profile for next tests
  [[[FBSDKLoginManager alloc] init] logOut];
  cachedProfile = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:userDefaultsKey]];
  XCTAssertNil(cachedProfile);
  XCTAssertNil([FBSDKProfile currentProfile]);
}

// test setting currentAccessToken, then immediately assigning currentProfile
- (void)testCurrentProfileManuallyAssigned {
  FBSDKTestBlocker *blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  __block int notificationCount = 0;
  [self expectationForNotification:FBSDKProfileDidChangeNotification object:nil handler:^BOOL(NSNotification *notification) {
    if (++notificationCount == 1) {
      XCTAssertNil(notification.userInfo[FBSDKProfileChangeOldKey]);
      XCTAssertNotNil(notification.userInfo[FBSDKProfileChangeNewKey]);
    }
    return YES;
  }];

  FBSDKAccessToken *token = [self getTokenWithPermissions:nil];
  FBSDKProfile *manualProfile = [[FBSDKProfile alloc] initWithUserID:@"123" firstName:@"not" middleName:nil lastName:@"sure" name:@"not sure" linkURL:nil refreshDate:nil];
  [FBSDKAccessToken setCurrentAccessToken:token];
  [FBSDKProfile setCurrentProfile:manualProfile];
  [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
    XCTAssertNil(error);
  }];
  XCTAssertNotNil([FBSDKProfile currentProfile]);

  [FBSDKAccessToken setCurrentAccessToken:nil];

  // wait 5 seconds to see if we get another notification
  [blocker waitWithTimeout:5];
  XCTAssertNotNil([FBSDKProfile currentProfile]);

  XCTAssertLessThanOrEqual(1, notificationCount);
  // clear profile for next tests
  [FBSDKProfile setCurrentProfile:nil];
}

// testing thrashing between setting and clearing currentAccessToken
- (void)testCurrentProfileThrash {
  FBSDKTestBlocker *blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  __block int notificationCount = 0;
  [self expectationForNotification:FBSDKProfileDidChangeNotification object:nil handler:^BOOL(NSNotification *notification) {
    if (++notificationCount == 1) {
      XCTAssertNil(notification.userInfo[FBSDKProfileChangeOldKey]);
      XCTAssertNotNil(notification.userInfo[FBSDKProfileChangeNewKey]);
    }
    return YES;
  }];

  FBSDKAccessToken *token = [self getTokenWithPermissions:nil];
  [FBSDKAccessToken setCurrentAccessToken:token];
  [FBSDKAccessToken setCurrentAccessToken:nil];
  [FBSDKAccessToken setCurrentAccessToken:token];
  [FBSDKAccessToken setCurrentAccessToken:nil];
  [FBSDKAccessToken setCurrentAccessToken:token];
  [FBSDKAccessToken setCurrentAccessToken:nil];
  [FBSDKAccessToken setCurrentAccessToken:token];

  [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
    XCTAssertNil(error);
  }];
  XCTAssertNotNil([FBSDKProfile currentProfile]);

  [FBSDKAccessToken setCurrentAccessToken:nil];

  // wait 5 seconds to see if we get another notification
  [blocker waitWithTimeout:5];
  XCTAssertNotNil([FBSDKProfile currentProfile]);

  XCTAssertLessThanOrEqual(1, notificationCount);
  // clear profile for next tests
  [FBSDKProfile setCurrentProfile:nil];
}

- (void)testProfileStale
{
  FBSDKAccessToken *token = [self getTokenWithPermissions:nil];
  // set a profile with a matching user id and today's date.
  // this posts the nofication but we're not observing yet.
  [FBSDKProfile setCurrentProfile:[[FBSDKProfile alloc] initWithUserID:token.userID
                                                            firstName:nil
                                                           middleName:nil
                                                             lastName:nil
                                                                 name:nil
                                                              linkURL:nil
                                                          refreshDate:[NSDate date]]];
  __block BOOL expectNotification = NO;
  FBSDKTestBlocker *blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  NSMutableArray *blockers = [NSMutableArray arrayWithArray:@[blocker]];
  [[NSNotificationCenter defaultCenter] addObserverForName:FBSDKProfileDidChangeNotification
                                                    object:nil
                                                     queue:[NSOperationQueue mainQueue]
                                                usingBlock:^(NSNotification *note) {
                                                  if (!expectNotification) {
                                                    XCTFail(@"unexpected profile change notification");
                                                  }
                                                  [blockers[0] signal];
                                                }];
  // set the token which should not trigger profile change since the refresh date is already today.
  [FBSDKAccessToken setCurrentAccessToken:token];
  XCTAssertFalse([blocker waitWithTimeout:5], @"Blocker was prematurely signalled by unexpected profile change notification");

  // now set the profile with older date.
  expectNotification = YES;
  [FBSDKProfile setCurrentProfile:[[FBSDKProfile alloc] initWithUserID:token.userID
                                                             firstName:nil
                                                            middleName:nil
                                                              lastName:nil
                                                                  name:nil
                                                               linkURL:nil
                                                           refreshDate:[NSDate dateWithTimeInterval:(-60*60*25) sinceDate:[NSDate date]]]];
  XCTAssertTrue([blockers[0] waitWithTimeout:2], @"expected notification for profile change");
  blockers[0] = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  // now update the token again
  [FBSDKAccessToken setCurrentAccessToken:[[FBSDKAccessToken alloc] initWithTokenString:@"tokenstring"
                                                                            permissions:nil
                                                                    declinedPermissions:nil
                                                                                  appID:token.appID
                                                                                 userID:token.userID
                                                                         expirationDate:nil
                                                                            refreshDate:nil]];
  XCTAssertTrue([blockers[0] waitWithTimeout:5], @"expected notification for profile change after token change");
  expectNotification = NO;
  [FBSDKProfile setCurrentProfile:nil];
  [FBSDKAccessToken setCurrentAccessToken:nil];
}

- (void)testImageURLForPictureMode
{
  CGSize size = CGSizeMake(10, 10);
  FBSDKAccessToken *token = [self getTokenWithPermissions:nil];
  [FBSDKAccessToken setCurrentAccessToken:token];
  [FBSDKProfile setCurrentProfile:[[FBSDKProfile alloc] initWithUserID:token.userID
                                                             firstName:nil
                                                            middleName:nil
                                                              lastName:nil
                                                                  name:nil
                                                               linkURL:nil
                                                           refreshDate:[NSDate date]]];
  NSString *imageURL = [[[FBSDKProfile currentProfile] imageURLForPictureMode:FBSDKProfilePictureModeNormal size:size] absoluteString];
  NSString *expectedImageURLSuffix = [NSString stringWithFormat:@".facebook.com/%@/%@/picture?type=%@&width=%d&height=%d",
                                FBSDK_TARGET_PLATFORM_VERSION,
                                token.userID,
                                @"normal",
                                (int) roundf(size.width),
                                (int) roundf(size.height)
                                ];
  XCTAssertTrue([imageURL hasSuffix:expectedImageURLSuffix]);
}
@end
