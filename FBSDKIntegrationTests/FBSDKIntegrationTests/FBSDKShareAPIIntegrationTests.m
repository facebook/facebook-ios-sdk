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
#import <FBSDKCoreKit/FBSDKTestUsersManager.h>

#import <FBSDKShareKit/FBSDKShareKit.h>

#import <XCTest/XCTest.h>

#import "FBSDKIntegrationTestCase.h"
#import "FBSDKShareKit+Internal.h"
#import "FBSDKTestBlocker.h"

@interface FBSDKShareAPIIntegrationTests : FBSDKIntegrationTestCase <FBSDKSharingDelegate, FBSDKVideoUploaderDelegate>

@property (nonatomic, copy) void (^shareCallback)(NSDictionary *results, NSError *error, BOOL isCancel);
@property (nonatomic, copy) void (^uploadCallback)(NSDictionary *results, NSError *error);
@end

static NSString *const kTaggedPlaceID = @"910055289103294";

@implementation FBSDKShareAPIIntegrationTests
{
  NSFileHandle *_fileHandle;
}

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

#pragma mark - FBSDKVideoUploaderDelegate

- (NSData *)videoChunkDataForVideoUploader:(FBSDKVideoUploader *)videoUploader startOffset:(NSUInteger)startOffset endOffset:(NSUInteger)endOffset
{
  NSUInteger chunkSize = endOffset - startOffset;
  [_fileHandle seekToFileOffset:startOffset];
  NSData *videoChunkData = [_fileHandle readDataOfLength:chunkSize];
  if (videoChunkData == nil || videoChunkData.length != chunkSize) {
    NSCAssert(videoChunkData == nil || videoChunkData.length != chunkSize, @"fail to get video chunk");
    return nil;
  }
  return videoChunkData;
}

- (void)videoUploader:(FBSDKVideoUploader *)videoUploader didCompleteWithResults:(NSMutableDictionary *)results
{
  if (self.uploadCallback) {
    self.uploadCallback(results, nil);
    self.uploadCallback = nil;
  }
}

- (void)videoUploader:(FBSDKVideoUploader *)videoUploader didFailWithError:(NSError *)error
{
  if (self.uploadCallback) {
    self.uploadCallback(nil, error);
    self.uploadCallback = nil;
  }
}

#pragma mark - Test OpenGraph

- (void)testOpenGraph
{
  NSArray *testUsers = [self createTwoFriendedTestUsers];
  FBSDKAccessToken *one = testUsers[0];
  NSDictionary *tagParameters = [self taggableFriendsOfTestUser:one];
  NSString *tag = tagParameters[@"tag"];
  NSString *taggedName = tagParameters[@"taggedName"];
  // now do the share
  FBSDKShareOpenGraphContent *content = [[FBSDKShareOpenGraphContent alloc] init];
  content.action = [FBSDKShareOpenGraphAction actionWithType:@"facebooksdktests:run"
                                                   objectURL:[NSURL URLWithString:@"http://samples.ogp.me/414221795280789"]
                                                         key:@"test"];
  content.peopleIDs = @[tag];
  content.previewPropertyName = @"test";

  FBSDKTestBlocker *blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
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
  [[[FBSDKGraphRequest alloc] initWithGraphPath:postID
                                     parameters:@{ @"fields" : @"id,tags.limit(1){name},place.limit(1){id}" } ]
   startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
    XCTAssertNil(error);
    XCTAssertEqualObjects(postID, result[@"id"]);
    XCTAssertEqualObjects(taggedName, result[@"tags"][0][@"name"]);
    [blocker signal];
  }];
  XCTAssertTrue([blocker waitWithTimeout:20], @"couldn't fetch verify post.");
}

#pragma mark - Test Share Link

- (void)testShareLink
{
  NSArray *testUsers = [self createTwoFriendedTestUsers];
  FBSDKAccessToken *one = testUsers[0];
  NSDictionary *tagParameters = [self taggableFriendsOfTestUser:one];
  NSString *tag = tagParameters[@"tag"];
  NSString *taggedName = tagParameters[@"taggedName"];
  // now do the share
  FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
  content.contentURL = [NSURL URLWithString:@"http://liveshows.disney.com/"];
  content.peopleIDs = @[tag];
  content.placeID = kTaggedPlaceID;

  FBSDKTestBlocker *blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
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
  [[[FBSDKGraphRequest alloc] initWithGraphPath:postID
                                     parameters:@{ @"fields" : @"id,with_tags.limit(1){name}, place.limit(1){id}" } ]
   startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
     XCTAssertNil(error);
     XCTAssertEqualObjects(postID, result[@"id"]);
     XCTAssertEqualObjects(taggedName, result[@"with_tags"][@"data"][0][@"name"]);
     XCTAssertEqualObjects(kTaggedPlaceID, result[@"place"][@"id"]);
     [blocker signal];
   }];
  XCTAssertTrue([blocker waitWithTimeout:200], @"couldn't fetch verify post.");
}

- (void)testShareLinkTokenOverride
{
  FBSDKTestBlocker *blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  __block FBSDKAccessToken *tokenWithPublish;
  __block FBSDKAccessToken *tokenWithEmail;
  [[self testUsersManager] requestTestAccountTokensWithArraysOfPermissions:@[
                                                                             [NSSet setWithObject:@"publish_actions"],
                                                                             [NSSet setWithObject:@"email"]                                                                            ]
                                                          createIfNotFound:YES
                                                         completionHandler:^(NSArray *tokens, NSError *error) {
                                                           tokenWithPublish = tokens[0];
                                                           tokenWithEmail = tokens[1];
                                                           [blocker signal];
                                                         }];
  XCTAssertTrue([blocker waitWithTimeout:8], @"failed to fetch two test users for testing");
  XCTAssertFalse([tokenWithPublish.userID isEqualToString:tokenWithEmail.userID], @"failed to fetch two distinct users for testing");

  // set current token to email token.
  [FBSDKAccessToken setCurrentAccessToken:tokenWithEmail];

  FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
  content.contentURL = [NSURL URLWithString:@"http://www.yahoo.com/"];

  blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  __block NSString *postID = nil;
  self.shareCallback = ^(NSDictionary *results, NSError *error, BOOL isCancel) {
    NSCAssert(error == nil, @"share failed :%@", error);
    NSCAssert(!isCancel, @"share cancelled");
    postID = results[@"postId"];
    [blocker signal];
  };
  // but send as the other token
  FBSDKShareAPI *sharer = [[FBSDKShareAPI alloc] init];
  sharer.shareContent = content;
  sharer.delegate = self;
  sharer.accessToken = tokenWithPublish;
  [sharer share];

  XCTAssertTrue([blocker waitWithTimeout:5], @"share didn't complete");
  XCTAssertNotNil(postID);

  //now fetch and verify the share.
  blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  [[[FBSDKGraphRequest alloc] initWithGraphPath:postID
                                     parameters:@{ @"fields" : @"id,from" }
                                    tokenString:tokenWithPublish.tokenString
                                        version:nil
                                     HTTPMethod:@"GET"
    ]
   startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
     XCTAssertNil(error);
     XCTAssertEqualObjects(postID, result[@"id"]);
     XCTAssertEqualObjects(tokenWithPublish.userID, result[@"from"][@"id"]);
     [blocker signal];
   }];
  XCTAssertTrue([blocker waitWithTimeout:10], @"couldn't fetch verify post.");
}

#pragma mark - Test Share Photo

- (void)testSharePhoto
{
  NSArray *testUsers = [self createTwoFriendedTestUsers];
  FBSDKAccessToken *one = testUsers[0];
  NSDictionary *tagParameters = [self taggableFriendsOfTestUser:one];
  NSString *tag = tagParameters[@"tag"];
  NSString *taggedName = tagParameters[@"taggedName"];
  // now do the share
  [FBSDKAccessToken setCurrentAccessToken:one];
  FBSDKSharePhotoContent *content = [[FBSDKSharePhotoContent alloc] init];
  content.photos = @[[FBSDKSharePhoto photoWithImage:[UIImage imageNamed:@"hack.png"] userGenerated:YES]];
  content.peopleIDs = @[tag];
  content.placeID = kTaggedPlaceID;

  FBSDKTestBlocker *blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  __block NSString *postID = nil;
  self.shareCallback = ^(NSDictionary *results, NSError *error, BOOL isCancel) {
    NSCAssert(error == nil, @"share failed :%@", error);
    NSCAssert(!isCancel, @"share cancelled");
    postID = results[@"postId"];
    [blocker signal];
  };
  [FBSDKShareAPI shareWithContent:content delegate:self];
  XCTAssertTrue([blocker waitWithTimeout:10], @"share didn't complete");
  XCTAssertNotNil(postID);

  //now fetch and verify the share.
  blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];

  // Note in order to verify tags on a photo, we have to get the photo
  // object id from the post id, rather than simply checking the with_tags
  // of the post. This is because the photo can go in an album which
  // doesn't have the same tags.
  // So we build a batch request to get object_id and then et the tags and place off that.
  FBSDKGraphRequestConnection *batch = [[FBSDKGraphRequestConnection alloc] init];
  FBSDKGraphRequest *getPhotoIDRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:postID
                                                                           parameters:@{ @"fields" : @"object_id"}];
  [batch addRequest:getPhotoIDRequest completionHandler:NULL batchEntryName:@"get-id"];
  FBSDKGraphRequest *getTagsToVerifyRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:@"{result=get-id:$.object_id}" parameters:@{ @"fields" : @"id,tags.limit(1){name}, place.limit(1){id}"}];
  [batch addRequest:getTagsToVerifyRequest completionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
     XCTAssertNil(error);
     XCTAssertEqualObjects(taggedName, result[@"tags"][@"data"][0][@"name"]);
     XCTAssertEqualObjects(kTaggedPlaceID, result[@"place"][@"id"],
                           @"Failed to fetch place tag for post %@ for %@",
                           postID,
                           one.tokenString);
     [blocker signal];
   }];
  [batch start];
  XCTAssertTrue([blocker waitWithTimeout:30], @"couldn't fetch verify post.");
}

#pragma mark - Test Share Video

- (void)testShareVideo
{
  NSArray *testUsers = [self createTwoFriendedTestUsers];
  FBSDKAccessToken *one = testUsers[0];
  NSDictionary *tagParameters = [self taggableFriendsOfTestUser:one];
  NSString *tag = tagParameters[@"tag"];
  // now do the share
  [FBSDKAccessToken setCurrentAccessToken:one];
  FBSDKShareVideoContent *content = [[FBSDKShareVideoContent alloc] init];
  NSURL *bundleURL = [[NSBundle mainBundle] URLForResource:@"videoviewdemo" withExtension:@"mp4"];
  content.video = [FBSDKShareVideo videoWithVideoURL:bundleURL];
  content.peopleIDs = @[tag];

  FBSDKTestBlocker *blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  self.shareCallback = ^(NSDictionary *results, NSError *error, BOOL isCancel) {
    NSCAssert(results == nil, @"VideoContent should not allow peopleIDs");
    NSCAssert(error != nil, @"VideoContent should not allow peopleIDs.");
    [blocker signal];
  };
  [FBSDKShareAPI shareWithContent:content delegate:self];
  XCTAssertTrue([blocker waitWithTimeout:10], @"share didn't complete");
}

- (void)testVideoUploader
{
  FBSDKAccessToken *token = [self getTokenWithPermissions:[NSSet setWithObject:@"publish_actions"]];
  [FBSDKAccessToken setCurrentAccessToken:token];
  NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
  NSURL *bundleURL = [[NSBundle mainBundle] URLForResource:@"videoviewdemo" withExtension:@"mp4"];
  //test on file URL
  __block FBSDKTestBlocker *blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  _fileHandle = [NSFileHandle fileHandleForReadingFromURL:bundleURL error:nil];
  NSCAssert(_fileHandle,  @"Fail to get file handler");
  FBSDKVideoUploader *videoUploader = [[FBSDKVideoUploader alloc] initWithVideoName:[bundleURL lastPathComponent] videoSize:(unsigned long)[_fileHandle seekToEndOfFile] parameters:dictionary delegate:self];
  self.uploadCallback = ^(NSDictionary *results, NSError *error) {
    NSCAssert(error == nil, @"upload failed :%@", error);
    NSCAssert(results[@"success"], @"upload fail");
    [blocker signal];
  };
  [videoUploader start];
  XCTAssertTrue([blocker waitWithTimeout:20], @"upload didn't complete");
}

#pragma mark - Help Method

- (NSArray *)createTwoFriendedTestUsers
{
  FBSDKTestBlocker *blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  __block FBSDKAccessToken *one = nil, *two = nil;
  FBSDKTestUsersManager *userManager = [self testUsersManager];
  // get two users.
  [userManager requestTestAccountTokensWithArraysOfPermissions:@[
                                                                 [NSSet setWithObjects:@"user_friends", @"publish_actions", @"user_posts", nil],
                                                                 [NSSet setWithObject:@"user_friends"]]
                                              createIfNotFound:YES
                                             completionHandler:^(NSArray *tokens, NSError *error) {
                                               XCTAssertNil(error);
                                               one = tokens[0];
                                               two = tokens[1];
                                               [blocker signal];
                                             }];
  XCTAssertTrue([blocker waitWithTimeout:15], @"couldn't get 2 test users");

  // make them friends
  blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  [userManager makeFriendsWithFirst:one second:two callback:^(NSError *error) {
    XCTAssertNil(error);
    [blocker signal];
  }];
  XCTAssertTrue([blocker waitWithTimeout:5], @"couldn't make friends between:\n%@\n%@", one.tokenString, two.tokenString);
  return @[one, two];
}

- (NSDictionary *)taggableFriendsOfTestUser:(FBSDKAccessToken *)testUser
{
  [FBSDKAccessToken setCurrentAccessToken:testUser];
  __block NSString *tag = nil;
  __block NSString *taggedName = nil;
  __block FBSDKTestBlocker *blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me/taggable_friends?limit=1" parameters:@{ @"fields": @"id,name" }]
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
  return @{ @"tag" : tag,
            @"taggedName" : taggedName };
}

@end
