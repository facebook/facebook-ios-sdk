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

#import "FBSDKShareMessengerContentUtility.h"
#import "FBSDKShareMessengerOpenGraphMusicTemplateContent.h"
#import "FBSDKShareMessengerURLActionButton.h"
#import "FBSDKShareModelTestUtility.h"

// High level keys
static NSString *const kMessengerShareContentKey = @"messenger_share_content";
static NSString *const kContentForPreviewKey = @"content_for_preview";
static NSString *const kContentForShareKey = @"content_for_share";

// Preview content keys
static NSString *const kImageURLKey = @"image_url";
static NSString *const kPreviewTypeKey = @"preview_type";
static NSString *const kOpenGraphURLKey = @"open_graph_url";
static NSString *const kButtonTitleKey = @"button_title";
static NSString *const kButtonURLKey = @"button_url";
static NSString *const kItemURLKey = @"item_url";
static NSString *const kMediaTypeKey = @"media_type";
static NSString *const kFacebookMediaURLKey = @"facebook_media_url";
static NSString *const kNonFacebookMediaURLKey = @"image_url";
static NSString *const kTargetDisplayKey = @"target_display";
static NSString *const kButtonTitle = @"Visit Facebook";
static NSString *const kButtonURL = @"http://www.facebook.com/someAdditionalURL";
static NSString *const kImageURL = @"http://www.facebook.com/someImageURL.jpg";
static NSString *const kDefaultActionTitle = @"Default Action";
static NSString *const kDefaultActionURL = @"http://www.messenger.com/something";
static NSString *const kTitleKey = @"title";
static NSString *const kSubtitleKey = @"subtitle";
static NSString *const kTitle = @"Test title";
static NSString *const kSubtitle = @"Test subtitle";

@interface FBSDKShareMessengerContentUtilityTests : XCTestCase
@end

@implementation FBSDKShareMessengerContentUtilityTests
{
  NSMutableDictionary *_parameters;
}

- (void)setUp {
  [super setUp];

  _parameters = [NSMutableDictionary dictionary];
}

- (void)tearDown {
  [super tearDown];

  _parameters = nil;
}

#pragma mark - Open Graph Music Tests

- (void)testOpenGraphMusicNoButtonSerialization {
  FBSDKShareMessengerOpenGraphMusicTemplateContent *content = [FBSDKShareMessengerOpenGraphMusicTemplateContent new];
  content.url = [FBSDKShareModelTestUtility contentURL];

  [_parameters addEntriesFromDictionary:[content addParameters:_parameters bridgeOptions:FBSDKShareBridgeOptionsDefault]];

  NSDictionary *messengerShareContent = _parameters[kMessengerShareContentKey];

  NSDictionary *contentForPreview = messengerShareContent[kContentForPreviewKey];
  XCTAssertEqualObjects([FBSDKShareModelTestUtility contentURL].absoluteString, contentForPreview[kOpenGraphURLKey], @"%@ key has incorrect value.", kOpenGraphURLKey);
  XCTAssertEqualObjects(@"OPEN_GRAPH", contentForPreview[kPreviewTypeKey], @"%@ key has incorrect value.", kPreviewTypeKey);

  NSString *contentForShare = messengerShareContent[kContentForShareKey];
  NSString *contentForShareExpectedValue = @"{\"attachment\":{\"type\":\"template\",\"payload\":{\"template_type\":\"open_graph\",\"elements\":[{\"url\":\"https:\\/\\/developers.facebook.com\\/\",\"buttons\":[]}]}}}";
  XCTAssertEqualObjects(contentForShare, contentForShareExpectedValue, @"%@ key has incorrect value.", kContentForShareKey);
}

- (void)testOpenGraphMusicWithButtonSerialization {
  FBSDKShareMessengerURLActionButton *urlButton = [[FBSDKShareMessengerURLActionButton alloc] init];
  urlButton.title = kButtonTitle;
  urlButton.url = [NSURL URLWithString:kButtonURL];
  urlButton.webviewHeightRatio = FBSDKShareMessengerURLActionButtonWebviewHeightRatioTall;

  FBSDKShareMessengerOpenGraphMusicTemplateContent *content = [FBSDKShareMessengerOpenGraphMusicTemplateContent new];
  content.url = [FBSDKShareModelTestUtility contentURL];
  content.button = urlButton;

  [_parameters addEntriesFromDictionary:[content addParameters:_parameters bridgeOptions:FBSDKShareBridgeOptionsDefault]];

  NSDictionary *messengerShareContent = _parameters[kMessengerShareContentKey];

  NSDictionary *contentForPreview = messengerShareContent[kContentForPreviewKey];
  XCTAssertEqualObjects(@"OPEN_GRAPH", contentForPreview[kPreviewTypeKey], @"%@ key has incorrect value.", kPreviewTypeKey);
  XCTAssertEqualObjects([FBSDKShareModelTestUtility contentURL].absoluteString, contentForPreview[kOpenGraphURLKey], @"%@ key has incorrect value.", kOpenGraphURLKey);
  XCTAssertEqualObjects(kButtonURL, contentForPreview[kItemURLKey], @"%@ key has incorrect value.", kItemURLKey);
  XCTAssertEqualObjects(@"Visit Facebook - http://www.facebook.com", contentForPreview[kTargetDisplayKey], @"%@ key has incorrect value.", kTargetDisplayKey);

  NSString *contentForShare = messengerShareContent[kContentForShareKey];
  NSString *contentForShareExpectedValue = @"{\"attachment\":{\"type\":\"template\",\"payload\":{\"template_type\":\"open_graph\",\"elements\":[{\"url\":\"https:\\/\\/developers.facebook.com\\/\",\"buttons\":[{\"webview_height_ratio\":\"tall\",\"messenger_extensions\":false,\"title\":\"Visit Facebook\",\"type\":\"web_url\",\"url\":\"http:\\/\\/www.facebook.com\\/someAdditionalURL\"}]}]}}}";
  XCTAssertEqualObjects(contentForShare, contentForShareExpectedValue, @"%@ key has incorrect value.", kContentForShareKey);
}

@end
