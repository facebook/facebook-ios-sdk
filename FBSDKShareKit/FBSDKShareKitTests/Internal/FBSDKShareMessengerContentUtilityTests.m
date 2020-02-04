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

@end
