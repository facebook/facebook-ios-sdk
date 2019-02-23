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
#import <XCTest/XCTest.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKShareKitTestUtility.h"
#import "FBSDKShareModelTestUtility.h"
#import "FBSDKShareUtility.h"

@interface FBSDKShareUtilityTests : XCTestCase
@end

@implementation FBSDKShareUtilityTests

- (void)testShareLinkContentValidationWithNilValues
{
  FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
  XCTAssertNotNil(content.shareUUID);
  NSError *error;
  XCTAssertTrue([content validateWithOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNil(error);
}

- (void)testShareLinkContentValidationWithValidValues
{
  FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
  content.contentURL = [FBSDKShareModelTestUtility contentURL];
  content.peopleIDs = [FBSDKShareModelTestUtility peopleIDs];
  content.placeID = [FBSDKShareModelTestUtility placeID];
  content.ref = [FBSDKShareModelTestUtility ref];
  XCTAssertNotNil(content.shareUUID);
  NSError *error;
  XCTAssertTrue([content validateWithOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNil(error);
}

- (void)testShareLinkContentParameters
{
  FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
  content.contentURL = [FBSDKShareModelTestUtility contentURL];
  XCTAssertNotNil(content.shareUUID);
  NSDictionary<NSString *, id> *parameters = [FBSDKShareUtility parametersForShareContent:content bridgeOptions:FBSDKShareBridgeOptionsDefault shouldFailOnDataError:YES];
  XCTAssertEqualObjects(content.contentURL, parameters[@"messenger_link"], @"Incorrect messenger_link param.");
}

- (void)testOpenGraphMusicWithoutURL
{
  FBSDKShareMessengerOpenGraphMusicTemplateContent *content = [FBSDKShareMessengerOpenGraphMusicTemplateContent new];
  content.pageID = @"123";
  XCTAssertNotNil(content.shareUUID);
  NSError *error;
  XCTAssertFalse([FBSDKShareUtility validateShareContent:content bridgeOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNotNil(error);
}

- (void)testOpenGraphMusicWithURL
{
  FBSDKShareMessengerOpenGraphMusicTemplateContent *content = [FBSDKShareMessengerOpenGraphMusicTemplateContent new];
  content.pageID = @"123";
  content.url = [NSURL URLWithString:@"www.facebook.com"];
  XCTAssertNotNil(content.shareUUID);
  NSError *error;
  XCTAssertTrue([FBSDKShareUtility validateShareContent:content bridgeOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNil(error);
}

- (void)testOpenGraphMusicWithoutPageID
{
  FBSDKShareMessengerOpenGraphMusicTemplateContent *content = [FBSDKShareMessengerOpenGraphMusicTemplateContent new];
  content.url = [NSURL URLWithString:@"www.facebook.com"];
  XCTAssertNotNil(content.shareUUID);
  NSError *error;
  XCTAssertFalse([FBSDKShareUtility validateShareContent:content bridgeOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNotNil(error);
}

- (void)testMediaTemplateWithAttachmentID
{
  FBSDKShareMessengerMediaTemplateContent *content = [[FBSDKShareMessengerMediaTemplateContent alloc] initWithAttachmentID:@"1"];
  XCTAssertNotNil(content.shareUUID);
  NSError *error;
  XCTAssertTrue([FBSDKShareUtility validateShareContent:content bridgeOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNil(error);
}

- (void)testMediaTemplateWithMediaURL
{
  FBSDKShareMessengerMediaTemplateContent *content = [[FBSDKShareMessengerMediaTemplateContent alloc] initWithMediaURL:[NSURL URLWithString:@"www.facebook.com"]];
  XCTAssertNotNil(content.shareUUID);
  NSError *error;
  XCTAssertTrue([FBSDKShareUtility validateShareContent:content bridgeOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNil(error);
}

- (void)testGenericTemplateWithoutTitle
{
  FBSDKShareMessengerGenericTemplateContent *content = [FBSDKShareMessengerGenericTemplateContent new];
  content.element = [FBSDKShareMessengerGenericTemplateElement new];
  XCTAssertNotNil(content.shareUUID);
  NSError *error;
  XCTAssertFalse([FBSDKShareUtility validateShareContent:content bridgeOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNotNil(error);
}

- (void)testGenericTemplateWithTitle
{
  FBSDKShareMessengerGenericTemplateContent *content = [FBSDKShareMessengerGenericTemplateContent new];
  content.element = [FBSDKShareMessengerGenericTemplateElement new];
  content.element.title = @"Some Title";
  XCTAssertNotNil(content.shareUUID);
  NSError *error;
  XCTAssertTrue([FBSDKShareUtility validateShareContent:content bridgeOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNil(error);
}

- (void)testGenericTemplateWithButtonAndDefaultAction
{
  FBSDKShareMessengerURLActionButton *button = [FBSDKShareMessengerURLActionButton new];
  button.url = [NSURL URLWithString:@"www.facebook.com"];
  button.title = @"test button";

  FBSDKShareMessengerURLActionButton *defaultAction = [FBSDKShareMessengerURLActionButton new];
  defaultAction.url = [NSURL URLWithString:@"www.facebook.com"];

  FBSDKShareMessengerGenericTemplateContent *content = [FBSDKShareMessengerGenericTemplateContent new];
  content.element = [FBSDKShareMessengerGenericTemplateElement new];
  content.element.title = @"Some Title";
  content.element.button = button;
  content.element.defaultAction = defaultAction;
  XCTAssertNotNil(content.shareUUID);
  NSError *error;
  XCTAssertTrue([FBSDKShareUtility validateShareContent:content bridgeOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNil(error);
}

- (void)testButtonWithoutTitle
{
  FBSDKShareMessengerURLActionButton *button = [FBSDKShareMessengerURLActionButton new];
  button.url = [NSURL URLWithString:@"www.facebook.com"];

  FBSDKShareMessengerMediaTemplateContent *content = [[FBSDKShareMessengerMediaTemplateContent alloc] initWithMediaURL:[NSURL URLWithString:@"www.facebook.com"]];
  content.button = button;
  XCTAssertNotNil(content.shareUUID);
  XCTAssertNotNil(content.button);
  NSError *error;
  XCTAssertFalse([FBSDKShareUtility validateShareContent:content bridgeOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNotNil(error);
}

- (void)testButtonWithoutURL
{
  FBSDKShareMessengerURLActionButton *button = [FBSDKShareMessengerURLActionButton new];
  button.title = @"Test";

  FBSDKShareMessengerMediaTemplateContent *content = [[FBSDKShareMessengerMediaTemplateContent alloc] initWithMediaURL:[NSURL URLWithString:@"www.facebook.com"]];
  content.button = button;
  XCTAssertNotNil(content.shareUUID);
  XCTAssertNotNil(content.button);
  NSError *error;
  XCTAssertFalse([FBSDKShareUtility validateShareContent:content bridgeOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNotNil(error);
}

- (void)testButtonWithURLAndTitle
{
  FBSDKShareMessengerURLActionButton *button = [FBSDKShareMessengerURLActionButton new];
  button.url = [NSURL URLWithString:@"www.facebook.com"];
  button.title = @"Title";

  FBSDKShareMessengerMediaTemplateContent *content = [[FBSDKShareMessengerMediaTemplateContent alloc] initWithMediaURL:[NSURL URLWithString:@"www.facebook.com"]];
  content.button = button;
  XCTAssertNotNil(content.shareUUID);
  XCTAssertNotNil(content.button);
  NSError *error;
  XCTAssertTrue([FBSDKShareUtility validateShareContent:content bridgeOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNil(error);
}

- (void)testMessengerExtensionButtonWithoutPageID
{
  FBSDKShareMessengerURLActionButton *button = [FBSDKShareMessengerURLActionButton new];
  button.url = [NSURL URLWithString:@"www.facebook.com"];
  button.isMessengerExtensionURL = YES;

  FBSDKShareMessengerMediaTemplateContent *content = [[FBSDKShareMessengerMediaTemplateContent alloc] initWithMediaURL:[NSURL URLWithString:@"www.facebook.com"]];
  content.button = button;
  XCTAssertNotNil(content.shareUUID);
  XCTAssertNotNil(content.button);
  NSError *error;
  XCTAssertFalse([FBSDKShareUtility validateShareContent:content bridgeOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNotNil(error);
}

- (void)testMessengerExtensionButtonWithPageID
{
  FBSDKShareMessengerURLActionButton *button = [FBSDKShareMessengerURLActionButton new];
  button.url = [NSURL URLWithString:@"www.facebook.com"];
  button.title = @"Title";
  button.isMessengerExtensionURL = YES;

  FBSDKShareMessengerMediaTemplateContent *content = [[FBSDKShareMessengerMediaTemplateContent alloc] initWithMediaURL:[NSURL URLWithString:@"www.facebook.com"]];
  content.pageID = @"123";
  content.button = button;
  XCTAssertNotNil(content.shareUUID);
  XCTAssertNotNil(content.button);
  NSError *error;
  XCTAssertTrue([FBSDKShareUtility validateShareContent:content bridgeOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNil(error);
}

@end
