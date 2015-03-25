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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import <FBSDKShareKit/FBSDKShareKit.h>

#import <XCTest/XCTest.h>

#import "FBSDKIntegrationTestCase.h"
#import "FBSDKTestBlocker.h"
#import "FBSDKTestUsersManager.h"

@interface FBSDKShareAPIIntegrationTests : FBSDKIntegrationTestCase <FBSDKSharingDelegate>

@property (nonatomic, copy) void (^shareCallback)(NSDictionary *results, NSError *error, BOOL isCancel);

@end

@implementation FBSDKShareAPIIntegrationTests

#pragma mark - FBSDKSharingDelegate

- (void)sharer:(id<FBSDKSharing>)sharer didCompleteWithResults:(NSDictionary *)results
{
  if (self.shareCallback) {
    self.shareCallback(results, nil, NO);
    self.shareCallback = nil;
  }
}

- (void)sharer:(id<FBSDKSharing>)sharer didFailWithError:(NSError *)error
{
  if (self.shareCallback) {
    self.shareCallback(nil, error, NO);
    self.shareCallback = nil;
  }
}
- (void)sharerDidCancel:(id<FBSDKSharing>)sharer
{
  if (self.shareCallback) {
    self.shareCallback(nil, nil, YES);
    self.shareCallback = nil;
  }
}

- (void)testOpenGraph {
  FBSDKTestBlocker *blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  __block FBSDKAccessToken *one = nil, *two = nil;
  FBSDKTestUsersManager *userManager = [self testUsersManager];
  // get two users.
  [userManager requestTestAccountTokensWithArraysOfPermissions:@[
                                                                 [NSSet setWithObjects:@"user_friends", @"publish_actions", nil],
                                                                 [NSSet setWithObject:@"user_friends"]]
                                              createIfNotFound:YES
                                             completionHandler:^(NSArray *tokens, NSError *error) {
                                               XCTAssertNil(error);
                                               one = tokens[0];
                                               two = tokens[1];
                                               [blocker signal];
                                             }];
  XCTAssertTrue([blocker waitWithTimeout:5], @"couldn't get 2 test users");

  // make them friends
  blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  [userManager makeFriendsWithFirst:one second:two callback:^(NSError *error) {
    XCTAssertNil(error);
    [blocker signal];
  }];
  XCTAssertTrue([blocker waitWithTimeout:5], @"couldn't make friends between:\n%@\n%@", one.tokenString, two.tokenString);

  // now set one as active, and get taggable friend.
  [FBSDKAccessToken setCurrentAccessToken:one];
  __block NSString *tag = nil;
  __block NSString *taggedName = nil;
  blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me/taggable_friends?limit=1" parameters:nil]
   startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
     XCTAssertNil(error);
     tag = result[@"data"][0][@"id"];
     // grab the name for later verification. unfortunately we can't just compare to
     // two.userID since there may already be (other) friends for this test users.
     taggedName = result[@"data"][0][@"name"];
     [blocker signal];
   }];
  XCTAssertTrue([blocker waitWithTimeout:5], @"couldn't fetch taggable friends");
  XCTAssertNotNil(tag);
  XCTAssertNotNil(taggedName);

  // now do the share
  FBSDKShareOpenGraphContent *content = [[FBSDKShareOpenGraphContent alloc] init];
  content.action = [FBSDKShareOpenGraphAction actionWithType:@"facebooksdktests:run"
                                                   objectURL:[NSURL URLWithString:@"http://samples.ogp.me/414221795280789"]
                                                         key:@"test"];
  content.peopleIDs = @[tag];
  content.previewPropertyName = @"test";
  static NSString *const placeID = @"88603851976";
  content.placeID = placeID;

  blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  __block NSString *postID = nil;
  self.shareCallback = ^(NSDictionary *results, NSError *error, BOOL isCancel) {
    NSCAssert(error == nil, @"share failed :%@", error);
    NSCAssert(!isCancel, @"share cancelled");
    postID = results[@"postId"];
    [blocker signal];
  };
  [FBSDKShareAPI shareWithContent:content delegate:self];
  XCTAssertTrue([blocker waitWithTimeout:5], @"share didn't complete");
  XCTAssertNotNil(postID);

  //now fetch and verify the share.
  blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  [[[FBSDKGraphRequest alloc] initWithGraphPath:postID parameters:nil] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
    XCTAssertNil(error);
    XCTAssertEqualObjects(postID, result[@"id"]);
    XCTAssertEqualObjects(taggedName, result[@"tags"][0][@"name"]);
    XCTAssertEqualObjects(placeID, result[@"place"][@"id"]);
    [blocker signal];
  }];
  XCTAssertTrue([blocker waitWithTimeout:200], @"couldn't fetch verify post.");
}

@end
