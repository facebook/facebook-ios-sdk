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
#import "FBSDKShareMessengerGenericTemplateContent.h"
#import "FBSDKShareMessengerGenericTemplateElement.h"
#import "FBSDKShareMessengerMediaTemplateContent.h"
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

- (void)testGenericTemplateWithButtonAndDefaultActionSerialization {
  FBSDKShareMessengerURLActionButton *urlButton = [FBSDKShareMessengerURLActionButton new];
  urlButton.title = kButtonTitle;
  urlButton.url = [NSURL URLWithString:kButtonURL];
  urlButton.shouldHideWebviewShareButton = YES;
  urlButton.isMessengerExtensionURL = YES;
  urlButton.fallbackURL = [NSURL URLWithString:@"https://plus.google.com/something"];
  urlButton.webviewHeightRatio = FBSDKShareMessengerURLActionButtonWebviewHeightRatioCompact;

  FBSDKShareMessengerURLActionButton *defaultActionButton = [FBSDKShareMessengerURLActionButton new];
  defaultActionButton.title = kDefaultActionTitle;
  defaultActionButton.url = [NSURL URLWithString:kDefaultActionURL];
  defaultActionButton.shouldHideWebviewShareButton = NO;
  defaultActionButton.webviewHeightRatio = FBSDKShareMessengerURLActionButtonWebviewHeightRatioTall;

  FBSDKShareMessengerGenericTemplateElement *element = [FBSDKShareMessengerGenericTemplateElement new];
  element.title = kTitle;
  element.subtitle = kSubtitle;
  element.imageURL = [NSURL URLWithString:kImageURL];
  element.defaultAction = defaultActionButton;
  element.button = urlButton;

  FBSDKShareMessengerGenericTemplateContent *content = [FBSDKShareMessengerGenericTemplateContent new];
  content.isSharable = NO;
  content.imageAspectRatio = FBSDKShareMessengerGenericTemplateImageAspectRatioSquare;
  content.element = element;

  [_parameters addEntriesFromDictionary:[content addParameters:_parameters bridgeOptions:FBSDKShareBridgeOptionsDefault]];

  NSDictionary *messengerShareContent = _parameters[kMessengerShareContentKey];

  NSDictionary *contentForPreview = messengerShareContent[kContentForPreviewKey];
  XCTAssertEqualObjects(@"DEFAULT", contentForPreview[kPreviewTypeKey], @"%@ key has incorrect value.", kPreviewTypeKey);
  XCTAssertEqualObjects(kTitle, contentForPreview[kTitleKey], @"%@ key has incorrect value.", kTitleKey);
  XCTAssertEqualObjects(kSubtitle, contentForPreview[kSubtitleKey], @"%@ key has incorrect value.", kSubtitleKey);
  XCTAssertEqualObjects(@"Visit Facebook - http://www.facebook.com", contentForPreview[kTargetDisplayKey], @"%@ key has incorrect value.", kTargetDisplayKey);

  NSString *contentForShare = messengerShareContent[kContentForShareKey];
  NSString *contentForShareExpectedValue = @"{\"attachment\":{\"type\":\"template\",\"payload\":{\"template_type\":\"generic\",\"sharable\":false,\"image_aspect_ratio\":\"square\",\"elements\":[{\"default_action\":{\"webview_height_ratio\":\"tall\",\"messenger_extensions\":false,\"type\":\"web_url\",\"url\":\"http:\\/\\/www.messenger.com\\/something\"},\"title\":\"Test title\",\"image_url\":\"http:\\/\\/www.facebook.com\\/someImageURL.jpg\",\"subtitle\":\"Test subtitle\",\"buttons\":[{\"webview_share_button\":\"hide\",\"messenger_extensions\":true,\"title\":\"Visit Facebook\",\"fallback_url\":\"https:\\/\\/plus.google.com\\/something\",\"type\":\"web_url\",\"webview_height_ratio\":\"compact\",\"url\":\"http:\\/\\/www.facebook.com\\/someAdditionalURL\"}]}]}}}";
  XCTAssertEqualObjects(contentForShare, contentForShareExpectedValue, @"%@ key has incorrect value.", kContentForShareKey);
}

- (void)testGenericTemplateWithButtonOnlySerialization {
  FBSDKShareMessengerURLActionButton *urlButton = [FBSDKShareMessengerURLActionButton new];
  urlButton.title = kButtonTitle;
  urlButton.url = [NSURL URLWithString:kButtonURL];
  urlButton.shouldHideWebviewShareButton = YES;
  urlButton.isMessengerExtensionURL = YES;
  urlButton.fallbackURL = [NSURL URLWithString:@"https://plus.google.com/something"];
  urlButton.webviewHeightRatio = FBSDKShareMessengerURLActionButtonWebviewHeightRatioCompact;

  FBSDKShareMessengerGenericTemplateElement *element = [FBSDKShareMessengerGenericTemplateElement new];
  element.title = kTitle;
  element.subtitle = kSubtitle;
  element.imageURL = [NSURL URLWithString:kImageURL];
  element.button = urlButton;

  FBSDKShareMessengerGenericTemplateContent *content = [FBSDKShareMessengerGenericTemplateContent new];
  content.isSharable = YES;
  content.imageAspectRatio = FBSDKShareMessengerGenericTemplateImageAspectRatioHorizontal;
  content.element = element;

  [_parameters addEntriesFromDictionary:[content addParameters:_parameters bridgeOptions:FBSDKShareBridgeOptionsDefault]];

  NSDictionary *messengerShareContent = _parameters[kMessengerShareContentKey];

  NSDictionary *contentForPreview = messengerShareContent[kContentForPreviewKey];
  XCTAssertEqualObjects(@"DEFAULT", contentForPreview[kPreviewTypeKey], @"%@ key has incorrect value.", kPreviewTypeKey);
  XCTAssertEqualObjects(kTitle, contentForPreview[kTitleKey], @"%@ key has incorrect value.", kTitleKey);
  XCTAssertEqualObjects(kSubtitle, contentForPreview[kSubtitleKey], @"%@ key has incorrect value.", kSubtitleKey);
  XCTAssertEqualObjects(@"Visit Facebook - http://www.facebook.com", contentForPreview[kTargetDisplayKey], @"%@ key has incorrect value.", kTargetDisplayKey);
  XCTAssertEqualObjects(kImageURL, contentForPreview[kImageURLKey], @"%@ key has incorrect value.", kImageURLKey);

  NSString *contentForShare = messengerShareContent[kContentForShareKey];
  NSString *contentForShareExpectedValue = @"{\"attachment\":{\"type\":\"template\",\"payload\":{\"template_type\":\"generic\",\"sharable\":true,\"image_aspect_ratio\":\"horizontal\",\"elements\":[{\"title\":\"Test title\",\"image_url\":\"http:\\/\\/www.facebook.com\\/someImageURL.jpg\",\"subtitle\":\"Test subtitle\",\"buttons\":[{\"webview_share_button\":\"hide\",\"messenger_extensions\":true,\"title\":\"Visit Facebook\",\"fallback_url\":\"https:\\/\\/plus.google.com\\/something\",\"type\":\"web_url\",\"webview_height_ratio\":\"compact\",\"url\":\"http:\\/\\/www.facebook.com\\/someAdditionalURL\"}]}]}}}";
  XCTAssertEqualObjects(contentForShare, contentForShareExpectedValue, @"%@ key has incorrect value.", kContentForShareKey);
}

- (void)testMediaTemplateAttachmentIDNoButtonSerialization
{
  FBSDKShareMessengerMediaTemplateContent *content = [[FBSDKShareMessengerMediaTemplateContent alloc] initWithAttachmentID:@"123"];
  content.mediaType = FBSDKShareMessengerMediaTemplateMediaTypeImage;

  [_parameters addEntriesFromDictionary:[content addParameters:_parameters bridgeOptions:FBSDKShareBridgeOptionsDefault]];

  NSDictionary *messengerShareContent = _parameters[kMessengerShareContentKey];

  NSDictionary *contentForPreview = messengerShareContent[kContentForPreviewKey];
  XCTAssertEqualObjects(@"123", contentForPreview[@"attachment_id"], @"attachment_id key has incorrect value.");
  XCTAssertEqualObjects(@"image", contentForPreview[kMediaTypeKey], @"%@ key has incorrect value.", kMediaTypeKey);
  XCTAssertEqualObjects(@"DEFAULT", contentForPreview[kPreviewTypeKey], @"%@ key has incorrect value.", kPreviewTypeKey);

  NSString *contentForShare = messengerShareContent[kContentForShareKey];
  NSString *contentForShareExpectedValue = @"{\"attachment\":{\"type\":\"template\",\"payload\":{\"template_type\":\"media\",\"elements\":[{\"buttons\":[],\"attachment_id\":\"123\",\"media_type\":\"image\"}]}}}";
  XCTAssertEqualObjects(contentForShare, contentForShareExpectedValue, @"%@ key has incorrect value.", kContentForShareKey);
}

- (void)testMediaTemplateAttachmentIDButtonSerialization
{
  FBSDKShareMessengerURLActionButton *urlButton = [FBSDKShareMessengerURLActionButton new];
  urlButton.title = kButtonTitle;
  urlButton.url = [NSURL URLWithString:kButtonURL];
  urlButton.shouldHideWebviewShareButton = YES;
  urlButton.isMessengerExtensionURL = YES;
  urlButton.fallbackURL = [NSURL URLWithString:@"https://plus.google.com/something"];
  urlButton.webviewHeightRatio = FBSDKShareMessengerURLActionButtonWebviewHeightRatioCompact;

  FBSDKShareMessengerMediaTemplateContent *content = [[FBSDKShareMessengerMediaTemplateContent alloc] initWithAttachmentID:@"123"];
  content.mediaType = FBSDKShareMessengerMediaTemplateMediaTypeVideo;
  content.button = urlButton;

  [_parameters addEntriesFromDictionary:[content addParameters:_parameters bridgeOptions:FBSDKShareBridgeOptionsDefault]];

  NSDictionary *messengerShareContent = _parameters[kMessengerShareContentKey];

  NSDictionary *contentForPreview = messengerShareContent[kContentForPreviewKey];
  XCTAssertEqualObjects(@"123", contentForPreview[@"attachment_id"], @"attachment_id key has incorrect value.");
  XCTAssertEqualObjects(@"video", contentForPreview[kMediaTypeKey], @"%@ key has incorrect value.", kMediaTypeKey);
  XCTAssertEqualObjects(@"DEFAULT", contentForPreview[kPreviewTypeKey], @"%@ key has incorrect value.", kPreviewTypeKey);
  XCTAssertEqualObjects(@"Visit Facebook - http://www.facebook.com", contentForPreview[kTargetDisplayKey], @"%@ key has incorrect value.", kTargetDisplayKey);

  NSString *contentForShare = messengerShareContent[kContentForShareKey];
  NSString *contentForShareExpectedValue = @"{\"attachment\":{\"type\":\"template\",\"payload\":{\"template_type\":\"media\",\"elements\":[{\"buttons\":[{\"webview_share_button\":\"hide\",\"messenger_extensions\":true,\"title\":\"Visit Facebook\",\"fallback_url\":\"https:\\/\\/plus.google.com\\/something\",\"type\":\"web_url\",\"webview_height_ratio\":\"compact\",\"url\":\"http:\\/\\/www.facebook.com\\/someAdditionalURL\"}],\"attachment_id\":\"123\",\"media_type\":\"video\"}]}}}";
  XCTAssertEqualObjects(contentForShare, contentForShareExpectedValue, @"%@ key has incorrect value.", kContentForShareKey);
}

- (void)testMediaTemplateMediaURLButtonSerialization
{
  FBSDKShareMessengerURLActionButton *urlButton = [FBSDKShareMessengerURLActionButton new];
  urlButton.title = kButtonTitle;
  urlButton.url = [NSURL URLWithString:kButtonURL];
  urlButton.shouldHideWebviewShareButton = YES;
  urlButton.isMessengerExtensionURL = YES;
  urlButton.fallbackURL = [NSURL URLWithString:@"https://plus.google.com/something"];
  urlButton.webviewHeightRatio = FBSDKShareMessengerURLActionButtonWebviewHeightRatioCompact;

  FBSDKShareMessengerMediaTemplateContent *content = [[FBSDKShareMessengerMediaTemplateContent alloc] initWithMediaURL:[NSURL URLWithString:kDefaultActionURL]];
  content.mediaType = FBSDKShareMessengerMediaTemplateMediaTypeVideo;
  content.button = urlButton;

  [_parameters addEntriesFromDictionary:[content addParameters:_parameters bridgeOptions:FBSDKShareBridgeOptionsDefault]];

  NSDictionary *messengerShareContent = _parameters[kMessengerShareContentKey];

  NSDictionary *contentForPreview = messengerShareContent[kContentForPreviewKey];
  XCTAssertEqualObjects(kDefaultActionURL, contentForPreview[kNonFacebookMediaURLKey], @"facebook_media_url key has incorrect value.");
  XCTAssertEqualObjects(@"video", contentForPreview[kMediaTypeKey], @"%@ key has incorrect value.", kMediaTypeKey);
  XCTAssertEqualObjects(@"DEFAULT", contentForPreview[kPreviewTypeKey], @"%@ key has incorrect value.", kPreviewTypeKey);
  XCTAssertEqualObjects(@"Visit Facebook - http://www.facebook.com", contentForPreview[kTargetDisplayKey], @"%@ key has incorrect value.", kTargetDisplayKey);

  NSString *contentForShare = messengerShareContent[kContentForShareKey];
  NSString *contentForShareExpectedValue = @"{\"attachment\":{\"type\":\"template\",\"payload\":{\"template_type\":\"media\",\"elements\":[{\"url\":\"http:\\/\\/www.messenger.com\\/something\",\"buttons\":[{\"webview_share_button\":\"hide\",\"messenger_extensions\":true,\"title\":\"Visit Facebook\",\"fallback_url\":\"https:\\/\\/plus.google.com\\/something\",\"type\":\"web_url\",\"webview_height_ratio\":\"compact\",\"url\":\"http:\\/\\/www.facebook.com\\/someAdditionalURL\"}],\"media_type\":\"video\"}]}}}";
  XCTAssertEqualObjects(contentForShare, contentForShareExpectedValue, @"%@ key has incorrect value.", kContentForShareKey);
}

- (void)testMediaTemplateBasicFacebookURLSerialization
{
  FBSDKShareMessengerMediaTemplateContent *content = [[FBSDKShareMessengerMediaTemplateContent alloc] initWithMediaURL:[NSURL URLWithString:@"http://www.facebook.com/something"]];
  content.mediaType = FBSDKShareMessengerMediaTemplateMediaTypeImage;

  [_parameters addEntriesFromDictionary:[content addParameters:_parameters bridgeOptions:FBSDKShareBridgeOptionsDefault]];

  NSDictionary *messengerShareContent = _parameters[kMessengerShareContentKey];
  NSDictionary *contentForPreview = messengerShareContent[kContentForPreviewKey];
  XCTAssertEqualObjects(@"http://www.facebook.com/something", contentForPreview[kFacebookMediaURLKey], @"facebook_media_url key has incorrect value.");
  XCTAssertNil(contentForPreview[kNonFacebookMediaURLKey], @"non-facebook url key should be nil.");
}

- (void)testMediaTemplateWWWFacebookURLSerialization
{
  FBSDKShareMessengerMediaTemplateContent *content = [[FBSDKShareMessengerMediaTemplateContent alloc] initWithMediaURL:[NSURL URLWithString:@"www.facebook.com/something"]];
  content.mediaType = FBSDKShareMessengerMediaTemplateMediaTypeImage;

  [_parameters addEntriesFromDictionary:[content addParameters:_parameters bridgeOptions:FBSDKShareBridgeOptionsDefault]];

  NSDictionary *messengerShareContent = _parameters[kMessengerShareContentKey];
  NSDictionary *contentForPreview = messengerShareContent[kContentForPreviewKey];
  XCTAssertEqualObjects(@"www.facebook.com/something", contentForPreview[kFacebookMediaURLKey], @"facebook_media_url key has incorrect value.");
  XCTAssertNil(contentForPreview[kNonFacebookMediaURLKey], @"non-facebook url key should be nil.");
}

- (void)testMediaTemplateNoHostFacebookURLSerialization
{
  FBSDKShareMessengerMediaTemplateContent *content = [[FBSDKShareMessengerMediaTemplateContent alloc] initWithMediaURL:[NSURL URLWithString:@"facebook.com/something"]];
  content.mediaType = FBSDKShareMessengerMediaTemplateMediaTypeImage;

  [_parameters addEntriesFromDictionary:[content addParameters:_parameters bridgeOptions:FBSDKShareBridgeOptionsDefault]];

  NSDictionary *messengerShareContent = _parameters[kMessengerShareContentKey];
  NSDictionary *contentForPreview = messengerShareContent[kContentForPreviewKey];
  XCTAssertEqualObjects(@"facebook.com/something", contentForPreview[kFacebookMediaURLKey], @"facebook_media_url key has incorrect value.");
  XCTAssertNil(contentForPreview[kNonFacebookMediaURLKey], @"non-facebook url key should be nil.");
}

- (void)testMediaTemplateNonFacebookURLSerialization
{
  FBSDKShareMessengerMediaTemplateContent *content = [[FBSDKShareMessengerMediaTemplateContent alloc] initWithMediaURL:[NSURL URLWithString:@"http://www.definitelynotfacebook.com/something"]];
  content.mediaType = FBSDKShareMessengerMediaTemplateMediaTypeImage;

  [_parameters addEntriesFromDictionary:[content addParameters:_parameters bridgeOptions:FBSDKShareBridgeOptionsDefault]];

  NSDictionary *messengerShareContent = _parameters[kMessengerShareContentKey];
  NSDictionary *contentForPreview = messengerShareContent[kContentForPreviewKey];
  XCTAssertEqualObjects(@"http://www.definitelynotfacebook.com/something", contentForPreview[kNonFacebookMediaURLKey], @"non-facebook url key has incorrect value.");
  XCTAssertNil(contentForPreview[kFacebookMediaURLKey], @"facebook_media_url key should be nil.");
}

@end
