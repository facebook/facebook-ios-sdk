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

#import <Social/Social.h>
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <OCMock/OCMock.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import <FBSDKShareKit/FBSDKHashtag.h>
#import <FBSDKShareKit/FBSDKShareDialog.h>

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKShareKitTestUtility.h"
#import "FBSDKShareModelTestUtility.h"

@interface FBSDKShareDialogTests : XCTestCase
@end

@implementation FBSDKShareDialogTests

- (void)_mockApplicationForURL:(NSURL *)URL canOpen:(BOOL)canOpen usingBlock:(void(^)(void))block
{
  if (block != NULL) {
    id applicationMock = [OCMockObject mockForClass:[UIApplication class]];
    [[[applicationMock stub] andReturnValue:@(canOpen)] canOpenURL:URL];
    [[[applicationMock stub] andReturn:nil] keyWindow];
    id applicationClassMock = [OCMockObject mockForClass:[UIApplication class]];
    [[[[applicationClassMock stub] classMethod] andReturn:applicationMock] sharedApplication];
    block();
    [applicationClassMock stopMocking];
    [applicationMock stopMocking];
  }
}

- (void)_mockUseNativeDialogUsingBlock:(void(^)(void))block
{
  if (block != NULL) {
    id configurationMock = [OCMockObject mockForClass:[FBSDKServerConfiguration class]];
    [[[configurationMock stub] andReturnValue:@YES] useNativeDialogForDialogName:FBSDKDialogConfigurationNameShare];
    id configurationManagerClassMock = [OCMockObject mockForClass:[FBSDKServerConfigurationManager class]];
    [[[[configurationManagerClassMock stub] classMethod] andReturn:configurationMock] cachedServerConfiguration];
    block();
    [configurationManagerClassMock stopMocking];
    [configurationMock stopMocking];
  }
}

- (void)setUp
{
  [super setUp];
  [FBSDKShareKitTestUtility mainBundleMock];
}

- (void)testCanShowNative
{
  FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] init];
  dialog.mode = FBSDKShareDialogModeNative;
  [self _mockApplicationForURL:OCMOCK_ANY canOpen:YES usingBlock:^{
    [self _mockUseNativeDialogUsingBlock:^{
      XCTAssertTrue([dialog canShow]);
      dialog.shareContent = [FBSDKShareModelTestUtility linkContent];
      XCTAssertTrue([dialog canShow]);
      dialog.shareContent = [FBSDKShareModelTestUtility photoContent];
      XCTAssertTrue([dialog canShow]);
      dialog.shareContent = [FBSDKShareModelTestUtility openGraphContent];
      XCTAssertTrue([dialog canShow]);
      dialog.shareContent = [FBSDKShareModelTestUtility videoContentWithoutPreviewPhoto];
      XCTAssertTrue([dialog canShow]);
    }];
  }];
  dialog.shareContent = nil;
  [self _mockApplicationForURL:OCMOCK_ANY canOpen:NO usingBlock:^{
    XCTAssertFalse([dialog canShow]);
    dialog.shareContent = [FBSDKShareModelTestUtility linkContent];
    XCTAssertFalse([dialog canShow]);
    dialog.shareContent = [FBSDKShareModelTestUtility photoContent];
    XCTAssertFalse([dialog canShow]);
    dialog.shareContent = [FBSDKShareModelTestUtility openGraphContent];
    XCTAssertFalse([dialog canShow]);
    dialog.shareContent = [FBSDKShareModelTestUtility videoContentWithoutPreviewPhoto];
    XCTAssertFalse([dialog canShow]);
  }];
}

- (void)testShowNativeDoesValidate
{
  FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] init];
  dialog.mode = FBSDKShareDialogModeNative;
  FBSDKSharePhotoContent *content = [[FBSDKSharePhotoContent alloc] init];
  content.photos = @[ [FBSDKSharePhoto photoWithImageURL:[FBSDKShareModelTestUtility photoImageURL] userGenerated:NO] ];
  dialog.shareContent = content;
  [self _mockApplicationForURL:OCMOCK_ANY canOpen:YES usingBlock:^{
    XCTAssertFalse([dialog show]);
  }];
}

- (void)testValidateShareSheet
{
  FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] init];
  dialog.mode = FBSDKShareDialogModeShareSheet;
  NSError *error;
  dialog.shareContent = [FBSDKShareModelTestUtility linkContentWithoutQuote];
  XCTAssertTrue([dialog validateWithError:&error]);
  XCTAssertNil(error);
  dialog.shareContent = [FBSDKShareModelTestUtility photoContentWithImages];
  XCTAssertTrue([dialog validateWithError:&error]);
  XCTAssertNil(error);
  dialog.shareContent = [FBSDKShareModelTestUtility photoContent];
  XCTAssertFalse([dialog validateWithError:&error]);
  XCTAssertNotNil(error);
  dialog.shareContent = [FBSDKShareModelTestUtility openGraphContent];
  XCTAssertFalse([dialog validateWithError:&error]);
  XCTAssertNotNil(error);
  dialog.shareContent = [FBSDKShareModelTestUtility openGraphContentWithURLOnly];
  XCTAssertTrue([dialog validateWithError:&error]);
  XCTAssertNil(error);
  dialog.shareContent = [FBSDKShareModelTestUtility videoContentWithoutPreviewPhoto];
  XCTAssertFalse([dialog validateWithError:&error]);
  XCTAssertNil(error);
}

- (void)testCanShowBrowser
{
  FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] init];
  dialog.mode = FBSDKShareDialogModeBrowser;
  XCTAssertTrue([dialog canShow]);
  dialog.shareContent = [FBSDKShareModelTestUtility linkContent];
  XCTAssertTrue([dialog canShow]);
  dialog.shareContent = [FBSDKShareModelTestUtility photoContent];
  XCTAssertTrue([dialog canShow]);
  dialog.shareContent = [FBSDKShareModelTestUtility openGraphContent];
  XCTAssertTrue([dialog canShow]);
  dialog.shareContent = [FBSDKShareModelTestUtility videoContentWithoutPreviewPhoto];
  XCTAssertTrue([dialog canShow]);
}

- (void)testValidateBrowser
{
  FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] init];
  dialog.mode = FBSDKShareDialogModeBrowser;
  NSError *error;
  dialog.shareContent = [FBSDKShareModelTestUtility linkContent];
  XCTAssertTrue([dialog validateWithError:&error]);
  XCTAssertNil(error);
  dialog.shareContent = [FBSDKShareModelTestUtility photoContentWithImages];
  XCTAssertFalse([dialog validateWithError:&error]);
  XCTAssertNotNil(error);
  dialog.shareContent = [FBSDKShareModelTestUtility openGraphContentWithObjectID];
  XCTAssertTrue([dialog validateWithError:&error]);
  XCTAssertNil(error);
  dialog.shareContent = [FBSDKShareModelTestUtility videoContentWithoutPreviewPhoto];
  XCTAssertFalse([dialog validateWithError:&error]);
  XCTAssertNotNil(error);
}

- (void)testCanShowWeb
{
  FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] init];
  dialog.mode = FBSDKShareDialogModeWeb;
  XCTAssertTrue([dialog canShow]);
  dialog.shareContent = [FBSDKShareModelTestUtility linkContent];
  XCTAssertTrue([dialog canShow]);
  dialog.shareContent = [FBSDKShareModelTestUtility photoContent];
  XCTAssertTrue([dialog canShow]);
  dialog.shareContent = [FBSDKShareModelTestUtility openGraphContent];
  XCTAssertTrue([dialog canShow]);
  dialog.shareContent = [FBSDKShareModelTestUtility videoContentWithoutPreviewPhoto];
  XCTAssertTrue([dialog canShow]);
}

- (void)testValidateWeb
{
  FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] init];
  dialog.mode = FBSDKShareDialogModeWeb;
  NSError *error;
  dialog.shareContent = [FBSDKShareModelTestUtility linkContent];
  XCTAssertTrue([dialog validateWithError:&error]);
  XCTAssertNil(error);
  dialog.shareContent = [FBSDKShareModelTestUtility photoContentWithImages];
  XCTAssertFalse([dialog validateWithError:&error]);
  XCTAssertNotNil(error);
  dialog.shareContent = [FBSDKShareModelTestUtility openGraphContentWithObjectID];
  XCTAssertTrue([dialog validateWithError:&error]);
  XCTAssertNil(error);
  dialog.shareContent = [FBSDKShareModelTestUtility videoContentWithoutPreviewPhoto];
  XCTAssertFalse([dialog validateWithError:&error]);
  XCTAssertNotNil(error);
}

- (void)testCanShowFeedBrowser
{
  FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] init];
  dialog.mode = FBSDKShareDialogModeFeedBrowser;
  XCTAssertTrue([dialog canShow]);
  dialog.shareContent = [FBSDKShareModelTestUtility linkContent];
  XCTAssertTrue([dialog canShow]);
  dialog.shareContent = [FBSDKShareModelTestUtility photoContent];
  XCTAssertTrue([dialog canShow]);
  dialog.shareContent = [FBSDKShareModelTestUtility openGraphContent];
  XCTAssertTrue([dialog canShow]);
  dialog.shareContent = [FBSDKShareModelTestUtility videoContentWithoutPreviewPhoto];
  XCTAssertTrue([dialog canShow]);
}

- (void)testValidateFeedBrowser
{
  FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] init];
  dialog.mode = FBSDKShareDialogModeFeedBrowser;
  NSError *error;
  dialog.shareContent = [FBSDKShareModelTestUtility linkContent];
  XCTAssertTrue([dialog validateWithError:&error]);
  XCTAssertNil(error);
  dialog.shareContent = [FBSDKShareModelTestUtility photoContentWithImages];
  XCTAssertFalse([dialog validateWithError:&error]);
  XCTAssertNotNil(error);
  dialog.shareContent = [FBSDKShareModelTestUtility openGraphContentWithObjectID];
  XCTAssertFalse([dialog validateWithError:&error]);
  XCTAssertNotNil(error);
  dialog.shareContent = [FBSDKShareModelTestUtility videoContentWithoutPreviewPhoto];
  XCTAssertFalse([dialog validateWithError:&error]);
  XCTAssertNotNil(error);
}

- (void)testCanShowFeedWeb
{
  FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] init];
  dialog.mode = FBSDKShareDialogModeFeedWeb;
  XCTAssertTrue([dialog canShow]);
  dialog.shareContent = [FBSDKShareModelTestUtility linkContent];
  XCTAssertTrue([dialog canShow]);
  dialog.shareContent = [FBSDKShareModelTestUtility photoContent];
  XCTAssertTrue([dialog canShow]);
  dialog.shareContent = [FBSDKShareModelTestUtility openGraphContent];
  XCTAssertTrue([dialog canShow]);
  dialog.shareContent = [FBSDKShareModelTestUtility videoContentWithoutPreviewPhoto];
  XCTAssertTrue([dialog canShow]);
}

- (void)testValidateFeedWeb
{
  FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] init];
  dialog.mode = FBSDKShareDialogModeFeedWeb;
  NSError *error;
  dialog.shareContent = [FBSDKShareModelTestUtility linkContent];
  XCTAssertTrue([dialog validateWithError:&error]);
  XCTAssertNil(error);
  dialog.shareContent = [FBSDKShareModelTestUtility photoContentWithImages];
  XCTAssertFalse([dialog validateWithError:&error]);
  XCTAssertNotNil(error);
  dialog.shareContent = [FBSDKShareModelTestUtility openGraphContentWithObjectID];
  XCTAssertFalse([dialog validateWithError:&error]);
  XCTAssertNotNil(error);
  dialog.shareContent = [FBSDKShareModelTestUtility videoContentWithoutPreviewPhoto];
  XCTAssertFalse([dialog validateWithError:&error]);
  XCTAssertNotNil(error);
}

- (void)testThatInitialTextIsSetCorrectlyWhenShareExtensionIsAvailable
{
  FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] init];
  FBSDKShareLinkContent *content = [FBSDKShareModelTestUtility linkContent];
  content.hashtag = [FBSDKHashtag hashtagWithString:@"#hashtag"];
  content.quote = @"a quote";
  dialog.shareContent = content;

  NSDictionary *expectedJSON = @{@"app_id":@"appID", @"hashtags":@[@"#hashtag"], @"quotes":@[@"a quote"]};
  [self _showDialog:dialog
              appID:@"appID"
shareSheetAvailable:YES
expectedPreJSONtext:@"fb-app-id:appID #hashtag"
       expectedJSON:expectedJSON];
}

#pragma mark - FullyCompatible Validation

- (void)testThatInitialTextIsSetCorrectlyWhenShareExtensionIsNOTAvailable
{
  FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] init];
  FBSDKShareLinkContent *content = [FBSDKShareModelTestUtility linkContentWithoutQuote];
  content.hashtag = [FBSDKHashtag hashtagWithString:@"#hashtag"];
  dialog.shareContent = content;
  [self _showDialog:dialog
              appID:@"appID"
shareSheetAvailable:NO
expectedPreJSONtext:@"#hashtag" expectedJSON:nil];
}

- (void)testThatValidateWithErrorReturnsNOForLinkQuoteIfAValidShareExtensionVersionIsNotAvailable
{
  [self _testValidateShareContent:[FBSDKShareModelTestUtility linkContent]
                      expectValid:NO
                             mode:FBSDKShareDialogModeShareSheet
               nonSupportedScheme:@"fbapi20160328:/"];
}

- (void)testThatValidateWithErrorReturnsYESForLinkQuoteIfAValidShareExtensionVersionIsAvailable
{
  [self _testValidateShareContent:[FBSDKShareModelTestUtility linkContent]
                      expectValid:YES
                             mode:FBSDKShareDialogModeShareSheet
               nonSupportedScheme:nil];

}

- (void)testThatValidateWithErrorReturnsNOForMMPIfAValidShareExtensionVersionIsNotAvailable
{
  [self _testValidateShareContent:[FBSDKShareModelTestUtility mediaContent]
                      expectValid:NO
                             mode:FBSDKShareDialogModeShareSheet
               nonSupportedScheme:@"fbapi20160328:/"];
}

- (void)testThatValidateWithErrorReturnsYESForMMPIfAValidShareExtensionVersionIsAvailable
{
  [self _testValidateShareContent:[FBSDKShareModelTestUtility mediaContent]
                      expectValid:YES
                             mode:FBSDKShareDialogModeShareSheet
               nonSupportedScheme:nil];
}

#pragma mark - Helpers

- (void)_testValidateShareContent:(id<FBSDKSharingContent>)shareContent
                      expectValid:(BOOL)expectValid
                             mode:(FBSDKShareDialogMode)mode
               nonSupportedScheme:(NSString *)nonSupportedScheme
{
  id mockApplication = [OCMockObject niceMockForClass:[UIApplication class]];
  [[[mockApplication stub] andReturn:mockApplication] sharedApplication];
  [[[mockApplication stub] andReturnValue:@YES] canOpenURL:[OCMArg checkWithBlock:^BOOL(NSURL *url) {
    return ![url.absoluteString isEqualToString:nonSupportedScheme];
  }]];
  NSOperatingSystemVersion iOS8Version = { .majorVersion = 8, .minorVersion = 0, .patchVersion = 0 };
  id mockInternalUtility = [OCMockObject niceMockForClass:[FBSDKInternalUtility class]];
  [[[mockInternalUtility stub] andReturnValue:@YES] isOSRunTimeVersionAtLeast:iOS8Version];
  id mockSLController = [OCMockObject niceMockForClass:[fbsdkdfl_SLComposeViewControllerClass() class]];
  [[[mockSLController stub] andReturn:mockSLController] composeViewControllerForServiceType:OCMOCK_ANY];
  [[[mockSLController stub] andReturnValue:@YES] isAvailableForServiceType:OCMOCK_ANY];

  UIViewController *vc = [UIViewController new];
  FBSDKShareDialog *dialog = [FBSDKShareDialog new];
  dialog.shareContent = shareContent;
  dialog.mode = mode;
  dialog.fromViewController = vc;
  NSError *error;
  if (expectValid) {
    XCTAssertTrue([dialog validateWithError:&error]);
    XCTAssertNil(error);
  } else {
    XCTAssertFalse([dialog validateWithError:&error]);
    XCTAssertNotNil(error);
  }
  XCTAssert([dialog show]);

  [mockApplication stopMocking];
  [mockInternalUtility stopMocking];
  [mockSLController stopMocking];
}

- (void)_showDialog:(FBSDKShareDialog *)dialog
              appID:(NSString *)appID
shareSheetAvailable:(BOOL)shareSheetAvailable
expectedPreJSONtext:(NSString *)expectedPreJSONText
       expectedJSON:(NSDictionary *)expectedJSON
{
  id mockApplication = [OCMockObject niceMockForClass:[UIApplication class]];
  [[[mockApplication stub] andReturn:mockApplication] sharedApplication];
  [[[mockApplication stub] andReturnValue:@YES] canOpenURL:OCMOCK_ANY];
  NSOperatingSystemVersion iOS8Version = { .majorVersion = 8, .minorVersion = 0, .patchVersion = 0 };
  id mockInternalUtility = [OCMockObject niceMockForClass:[FBSDKInternalUtility class]];
  [[[mockInternalUtility stub] andReturnValue:@(shareSheetAvailable)] isOSRunTimeVersionAtLeast:iOS8Version];
  id settingsClassMock = [OCMockObject niceMockForClass:[FBSDKSettings class]];
  [[[settingsClassMock stub] andReturn:appID] appID];
  id mockSLController = [OCMockObject niceMockForClass:[fbsdkdfl_SLComposeViewControllerClass() class]];
  [[[mockSLController stub] andReturn:mockSLController] composeViewControllerForServiceType:OCMOCK_ANY];
  [[[mockSLController stub] andReturnValue:@YES] isAvailableForServiceType:OCMOCK_ANY];
  [[mockSLController expect] setInitialText:[OCMArg checkWithBlock:^BOOL(NSString *text) {
    NSRange JSONDelimiterRange = [text rangeOfString:@"|"];
    NSString *preJSONText;
    NSDictionary *json;
    if (JSONDelimiterRange.location == NSNotFound) {
      preJSONText = text;
    } else {
      preJSONText = [text substringToIndex:JSONDelimiterRange.location];
      NSString *jsonText = [text substringFromIndex:JSONDelimiterRange.location+1];
      json = [NSJSONSerialization JSONObjectWithData:[jsonText dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    }
    return ((expectedPreJSONText == nil && preJSONText == nil) || [expectedPreJSONText isEqualToString:preJSONText]) &&
           ((expectedJSON == nil && json == nil) || [expectedJSON isEqual:json]);
  }]];

  UIViewController *vc = [UIViewController new];
  dialog.fromViewController = vc;
  dialog.mode = FBSDKShareDialogModeShareSheet;
  XCTAssert([dialog show]);
  [mockSLController verify];

  [mockSLController stopMocking];
  [settingsClassMock stopMocking];
  [mockApplication stopMocking];
  [mockInternalUtility stopMocking];
}

@end
