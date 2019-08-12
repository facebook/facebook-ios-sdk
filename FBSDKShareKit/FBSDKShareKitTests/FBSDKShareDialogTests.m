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
#import "FBSDKShareDefines.h"
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
    [[[applicationMock stub] andReturnValue:@(0)] applicationState];
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

#pragma mark - Native

- (void)testCanShowNativeDialogWithoutShareContent {
  FBSDKShareDialog *const dialog = [[FBSDKShareDialog alloc] init];
  dialog.mode = FBSDKShareDialogModeNative;
  [self _mockApplicationForURL:OCMOCK_ANY canOpen:YES usingBlock:^{
    [self _mockUseNativeDialogUsingBlock:^{
      XCTAssertTrue([dialog canShow],
                    @"A dialog without share content should be showable on a native dialog");
    }];
  }];
}

- (void)testCanShowNativeLinkContent {
  FBSDKShareDialog *const dialog = [[FBSDKShareDialog alloc] init];
  dialog.mode = FBSDKShareDialogModeNative;
  [self _mockUseNativeDialogUsingBlock:^{

    dialog.shareContent = [FBSDKShareModelTestUtility linkContent];
    XCTAssertTrue([dialog canShow],
                  @"A dialog with valid link content should be showable on a native dialog");
  }];
}

- (void)testCanShowNativePhotoContent {
  FBSDKShareDialog *const dialog = [[FBSDKShareDialog alloc] init];
  dialog.mode = FBSDKShareDialogModeNative;
  [self _mockUseNativeDialogUsingBlock:^{
    dialog.shareContent = [FBSDKShareModelTestUtility photoContent];
    XCTAssertFalse([dialog canShow],
                   @"Photo content with photos that have web urls should not be showable on a native dialog");
  }];
}

- (void)testCanShowNativePhotoContentWithFileURL {
  FBSDKShareDialog *const dialog = [[FBSDKShareDialog alloc] init];
  dialog.mode = FBSDKShareDialogModeNative;
  [self _mockUseNativeDialogUsingBlock:^{
    dialog.shareContent = [FBSDKShareModelTestUtility photoContentWithFileURLs];
    XCTAssertTrue([dialog canShow],
                  @"Photo content with photos that have file urls should be showable on a native dialog");
  }];
}

- (void)testCanShowNativeOpenGraphContent {
  FBSDKShareDialog *const dialog = [[FBSDKShareDialog alloc] init];
  dialog.mode = FBSDKShareDialogModeNative;
  [self _mockApplicationForURL:OCMOCK_ANY canOpen:YES usingBlock:^{
    [self _mockUseNativeDialogUsingBlock:^{
      dialog.shareContent = [FBSDKShareModelTestUtility openGraphContent];
      XCTAssertTrue([dialog canShow],
                    @"Open graph content should be showable on a native dialog");
    }];
  }];
}

- (void)testCanShowNativeVideoContentWithoutPreviewPhoto {
  FBSDKShareDialog *const dialog = [[FBSDKShareDialog alloc] init];
  dialog.mode = FBSDKShareDialogModeNative;
  [self _mockApplicationForURL:OCMOCK_ANY canOpen:YES usingBlock:^{
    [self _mockUseNativeDialogUsingBlock:^{
      dialog.shareContent = [FBSDKShareModelTestUtility videoContentWithoutPreviewPhoto];
      XCTAssertTrue([dialog canShow],
                    @"Video content without a preview photo should be showable on a native dialog");
    }];
  }];
}

- (void)testCanShowNative
{
  FBSDKShareDialog *const dialog = [[FBSDKShareDialog alloc] init];
  dialog.mode = FBSDKShareDialogModeNative;
  [self _mockApplicationForURL:OCMOCK_ANY canOpen:NO usingBlock:^{
    [self _mockUseNativeDialogUsingBlock:^{
      XCTAssertFalse([dialog canShow],
                     @"A native dialog should not be showable if the application is unable to open a url, this can also occur if the api scheme is not whitelisted in the third party app or if the application cannot handle the share API scheme");
    }];
  }];
}

- (void)testShowNativeDoesValidate
{
  FBSDKShareDialog *const dialog = [[FBSDKShareDialog alloc] init];
  dialog.mode = FBSDKShareDialogModeNative;
  dialog.shareContent = [FBSDKShareModelTestUtility photoContent];
  [self _mockApplicationForURL:OCMOCK_ANY canOpen:YES usingBlock:^{
    XCTAssertFalse([dialog show]);
  }];
}

#pragma mark - Share sheet

- (void)testValidateShareSheet
{
  FBSDKShareDialog *const dialog = [[FBSDKShareDialog alloc] init];
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

#pragma mark - Browser

- (void)testCanShowBrowser
{
  FBSDKShareDialog *const dialog = [[FBSDKShareDialog alloc] init];
  dialog.mode = FBSDKShareDialogModeBrowser;
  XCTAssertTrue([dialog canShow],
                @"A dialog without share content should be showable in a browser");
  dialog.shareContent = [FBSDKShareModelTestUtility linkContent];
  XCTAssertTrue([dialog canShow],
                @"A dialog with link content should be showable in a browser");
  [self _performBlockWithAccessToken:^{
    dialog.shareContent = [FBSDKShareModelTestUtility photoContentWithFileURLs];
    XCTAssertTrue([dialog canShow],
                  @"A dialog with photo content with file urls should be showable in a browser when there is a current access token");
    dialog.shareContent = [FBSDKShareModelTestUtility openGraphContent];
    XCTAssertFalse([dialog canShow],
                   @"A dialog with open graph content should not be showable since browser dialogs cannot include photos");
    dialog.shareContent = [FBSDKShareModelTestUtility videoContentWithoutPreviewPhoto];
    XCTAssertTrue([dialog canShow],
                  @"A dialog with video content without a preview photo should be showable in a browser when there is a current access token");
  }];
}

- (void)testValidateBrowser
{
  FBSDKShareDialog *const dialog = [[FBSDKShareDialog alloc] init];
  dialog.mode = FBSDKShareDialogModeBrowser;
  __block NSError *error;
  dialog.shareContent = [FBSDKShareModelTestUtility linkContent];
  XCTAssertTrue([dialog validateWithError:&error]);
  XCTAssertNil(error);
  dialog.shareContent = [FBSDKShareModelTestUtility photoContentWithImages];
  [self _performBlockWithAccessToken:^{
    XCTAssertTrue([dialog validateWithError:&error]);
    XCTAssertNil(error);
  }];
  [self _performBlockWithNilAccessToken:^{
    XCTAssertFalse([dialog validateWithError:&error]);
    XCTAssertNotNil(error);
  }];
  dialog.shareContent = [FBSDKShareModelTestUtility openGraphContentWithObjectID];
  XCTAssertTrue([dialog validateWithError:&error]);
  XCTAssertNil(error);
  dialog.shareContent = [FBSDKShareModelTestUtility videoContentWithoutPreviewPhoto];
  XCTAssertFalse([dialog validateWithError:&error]);
  XCTAssertNotNil(error);
}

#pragma mark - Web

- (void)testCanShowWeb
{
  FBSDKShareDialog *const dialog = [[FBSDKShareDialog alloc] init];
  dialog.mode = FBSDKShareDialogModeWeb;
  XCTAssertTrue([dialog canShow],
                @"A dialog without share content should be showable on web");
  dialog.shareContent = [FBSDKShareModelTestUtility linkContent];
  XCTAssertTrue([dialog canShow],
                @"A dialog with link content should be showable on web");
  [self _performBlockWithAccessToken:^{
    dialog.shareContent = [FBSDKShareModelTestUtility photoContent];
    XCTAssertFalse([dialog canShow],
                   @"A dialog with photos should not be showable on web");
    dialog.shareContent = [FBSDKShareModelTestUtility openGraphContent];
    XCTAssertFalse([dialog canShow],
                   @"A dialog with content that contains photos should not be showable on web");
    dialog.shareContent = [FBSDKShareModelTestUtility videoContentWithoutPreviewPhoto];
    XCTAssertFalse([dialog canShow],
                   @"A dialog with content that contains local media should not be showable on web");
  }];
}

- (void)testValidateWeb
{
  FBSDKShareDialog *const dialog = [[FBSDKShareDialog alloc] init];
  dialog.mode = FBSDKShareDialogModeWeb;
  __block NSError *error;
  dialog.shareContent = [FBSDKShareModelTestUtility linkContent];
  XCTAssertTrue([dialog validateWithError:&error]);
  XCTAssertNil(error);

  [self _performBlockWithAccessToken:^{
    dialog.shareContent = [FBSDKShareModelTestUtility photoContent];
    XCTAssertFalse([dialog validateWithError:&error],
                   @"A dialog with photo content that points to remote urls should not be considered valid on web");
    XCTAssertNotNil(error,
                    @"Validating a dialog with photo content on web should provide a meaningful error");

    dialog.shareContent = [FBSDKShareModelTestUtility photoContentWithImages];
    XCTAssertFalse([dialog validateWithError:&error],
                   @"A dialog with photo content that is already loaded should not be considered valid on web");
    XCTAssertNotNil(error,
                    @"Validating a dialog with photo content that is already loaded on web should provide a meaningful error");

    dialog.shareContent = [FBSDKShareModelTestUtility photoContentWithFileURLs];
    XCTAssertFalse([dialog validateWithError:&error],
                   @"A dialog with photo content that points to file urls should not be considered valid on web");
    XCTAssertNotNil(error,
                    @"Validating a dialog with photo content that points to file urls on web should provide a meaningful error");

    dialog.shareContent = [FBSDKShareModelTestUtility openGraphContentWithObjectID];
    XCTAssertTrue([dialog validateWithError:&error],
                  @"A dialog with open graph content that has an object id should be considered valid on web");
    XCTAssertNil(error,
                 @"Validating a dialog with open graph content that has an object id should not provide an error");

    dialog.shareContent = [FBSDKShareModelTestUtility videoContentWithoutPreviewPhoto];
    XCTAssertFalse([dialog validateWithError:&error],
                   @"A dialog that includes local media should not be considered valid on web");
    XCTAssertNotNil(error,
                 @"Validating a dialog that includes local media should provide a meaningful error");
  }];
  [self _performBlockWithNilAccessToken:^{
    XCTAssertFalse([dialog validateWithError:&error],
                   @"A dialog with content but no access token should not be considered valid on web");
    XCTAssertNotNil(error,
                    @"Validating a dialog with content but no access token should provide a meaningful error");
  }];
}

#pragma mark - Feed browser

- (void)testCanShowFeedBrowser
{
  FBSDKShareDialog *const dialog = [[FBSDKShareDialog alloc] init];
  dialog.mode = FBSDKShareDialogModeFeedBrowser;
  XCTAssertTrue([dialog canShow],
                @"A dialog without content should be showable in a browser feed");
  dialog.shareContent = [FBSDKShareModelTestUtility linkContent];
  XCTAssertTrue([dialog canShow],
                @"A dialog with link content should be showable in a browser feed");
  dialog.shareContent = [FBSDKShareModelTestUtility photoContent];
  XCTAssertFalse([dialog canShow],
                 @"A dialog with photo content should not be showable in a browser feed");
  dialog.shareContent = [FBSDKShareModelTestUtility openGraphContent];
  XCTAssertFalse([dialog canShow],
                 @"A dialog with open graph content should not be showable in a browser feed");
  dialog.shareContent = [FBSDKShareModelTestUtility videoContentWithoutPreviewPhoto];
  XCTAssertFalse([dialog canShow],
                 @"A dialog with video content that has no preview photo should not be showable in a browser feed");
}

- (void)testValidateFeedBrowser
{
  FBSDKShareDialog *const dialog = [[FBSDKShareDialog alloc] init];
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

#pragma mark - Feed web

- (void)testCanShowFeedWeb
{
  FBSDKShareDialog *const dialog = [[FBSDKShareDialog alloc] init];
  dialog.mode = FBSDKShareDialogModeFeedWeb;
  XCTAssertTrue([dialog canShow],
                @"A dialog without content should be showable in a web feed");
  dialog.shareContent = [FBSDKShareModelTestUtility linkContent];
  XCTAssertTrue([dialog canShow],
                @"A dialog with link content should be showable in a web feed");
  dialog.shareContent = [FBSDKShareModelTestUtility photoContent];
  XCTAssertFalse([dialog canShow],
                 @"A dialog with photo content should not be showable in a web feed");
  dialog.shareContent = [FBSDKShareModelTestUtility openGraphContent];
  XCTAssertFalse([dialog canShow],
                 @"A dialog with open graph content should not be showable in a web feed");
  dialog.shareContent = [FBSDKShareModelTestUtility videoContentWithoutPreviewPhoto];
  XCTAssertFalse([dialog canShow],
                 @"A dialog with video content and no preview photo should not be showable in a web feed");
}

- (void)testValidateFeedWeb
{
  FBSDKShareDialog *const dialog = [[FBSDKShareDialog alloc] init];
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
  FBSDKShareDialog *const dialog = [[FBSDKShareDialog alloc] init];
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

#pragma mark - Camera Share

- (void)testCameraShareModes
{
  FBSDKShareDialog *const dialog = [[FBSDKShareDialog alloc] init];
  dialog.shareContent = [FBSDKShareModelTestUtility cameraEffectContent];

  // When native is available.
  [self _mockApplicationForURL:OCMOCK_ANY canOpen:YES usingBlock:^{
    [self _mockUseNativeDialogUsingBlock:^{
      // Check supported modes
      NSError *error;
      dialog.mode = FBSDKShareDialogModeAutomatic;
      XCTAssertTrue([dialog validateWithError:&error]);
      XCTAssertNil(error);
      dialog.mode = FBSDKShareDialogModeNative;
      XCTAssertTrue([dialog validateWithError:&error]);
      XCTAssertNil(error);

      // Check unsupported modes
      dialog.mode = FBSDKShareDialogModeWeb;
      error = nil;
      XCTAssertFalse([dialog validateWithError:&error]);
      XCTAssertNotNil(error);
      dialog.mode = FBSDKShareDialogModeBrowser;
      error = nil;
      XCTAssertFalse([dialog validateWithError:&error]);
      XCTAssertNotNil(error);
      error = nil;
      dialog.mode = FBSDKShareDialogModeShareSheet;
      error = nil;
      XCTAssertFalse([dialog validateWithError:&error]);
      XCTAssertNotNil(error);
      dialog.mode = FBSDKShareDialogModeFeedWeb;
      error = nil;
      XCTAssertFalse([dialog validateWithError:&error]);
      XCTAssertNotNil(error);
      dialog.mode = FBSDKShareDialogModeFeedBrowser;
      error = nil;
      XCTAssertFalse([dialog validateWithError:&error]);
      XCTAssertNotNil(error);
    }];
  }];

  // When native isn't available.
  [self _mockApplicationForURL:OCMOCK_ANY canOpen:NO usingBlock:^{
    [self _mockUseNativeDialogUsingBlock:^{
      NSError *error;
      dialog.mode = FBSDKShareDialogModeAutomatic;
      XCTAssertFalse([dialog validateWithError:&error]);
      XCTAssertNotNil(error);
    }];
  }];
}

- (void)testShowCameraShareToPlayerWhenPlayerInstalled
{
  FBSDKShareDialog *const dialog = [[FBSDKShareDialog alloc] init];
  dialog.shareContent = [FBSDKShareModelTestUtility cameraEffectContent];
  [self _showNativeDialog:dialog
       nonSupportedScheme:nil
      expectRequestScheme:FBSDK_CANOPENURL_MSQRD_PLAYER
               methodName:FBSDK_SHARE_CAMERA_METHOD_NAME];
}

- (void)testShowCameraShareToFBWhenPlayerNotInstalled
{
  FBSDKShareDialog *const dialog = [[FBSDKShareDialog alloc] init];
  dialog.shareContent = [FBSDKShareModelTestUtility cameraEffectContent];
  [self _showNativeDialog:dialog
       nonSupportedScheme:[NSString stringWithFormat:@"%@:/", FBSDK_CANOPENURL_MSQRD_PLAYER]
      expectRequestScheme:FBSDK_CANOPENURL_FACEBOOK
               methodName:FBSDK_SHARE_CAMERA_METHOD_NAME];
}

#pragma mark - FullyCompatible Validation

- (void)testThatInitialTextIsSetCorrectlyWhenShareExtensionIsNOTAvailable
{
  FBSDKShareDialog *const dialog = [[FBSDKShareDialog alloc] init];
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
                       expectShow:YES
                             mode:FBSDKShareDialogModeShareSheet
               nonSupportedScheme:@"fbapi20160328:/"];
}

- (void)testThatValidateWithErrorReturnsYESForLinkQuoteIfAValidShareExtensionVersionIsAvailable
{
  [self _testValidateShareContent:[FBSDKShareModelTestUtility linkContent]
                      expectValid:YES
                       expectShow:YES
                             mode:FBSDKShareDialogModeShareSheet
               nonSupportedScheme:nil];

}

- (void)testThatValidateWithErrorReturnsNOForMMPIfAValidShareExtensionVersionIsNotAvailable
{
  [self _testValidateShareContent:[FBSDKShareModelTestUtility mediaContent]
                      expectValid:NO
                       expectShow:NO
                             mode:FBSDKShareDialogModeShareSheet
               nonSupportedScheme:@"fbapi20160328:/"];
}

- (void)testThatValidateWithErrorReturnsYESForMMPIfAValidShareExtensionVersionIsAvailable
{
  [self _testValidateShareContent:[FBSDKShareModelTestUtility mediaContent]
                      expectValid:YES
                       expectShow:YES
                             mode:FBSDKShareDialogModeShareSheet
               nonSupportedScheme:nil];
}

- (void)testThatValidateWithErrorReturnsNOForMMPWithMoreThan1Video
{
  [self _testValidateShareContent:[FBSDKShareModelTestUtility multiVideoMediaContent]
                      expectValid:NO
                       expectShow:NO
                             mode:FBSDKShareDialogModeShareSheet
               nonSupportedScheme:nil];
}

#pragma mark - Helpers

- (void)_testValidateShareContent:(id<FBSDKSharingContent>)shareContent
                      expectValid:(BOOL)expectValid
                       expectShow:(BOOL)expectShow
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
  FBSDKShareDialog *const dialog = [FBSDKShareDialog new];
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
  XCTAssertEqual(expectShow, [dialog show]);

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

- (void)_showNativeDialog:(FBSDKShareDialog *)dialog
       nonSupportedScheme:(NSString *)nonSupportedScheme
      expectRequestScheme:(NSString *)scheme
               methodName:(NSString *)methodName
{
  id mockApplication = [OCMockObject niceMockForClass:[UIApplication class]];
  [[[mockApplication stub] andReturn:mockApplication] sharedApplication];
  [[[mockApplication stub] andReturnValue:@YES] canOpenURL:[OCMArg checkWithBlock:^BOOL(NSURL *url) {
    return ![url.absoluteString isEqualToString:nonSupportedScheme];
  }]];
  id settingsClassMock = [OCMockObject niceMockForClass:[FBSDKSettings class]];
  [[[settingsClassMock stub] andReturn:@"AppID"] appID];
  id mockInternalUtility = [OCMockObject niceMockForClass:[FBSDKInternalUtility class]];
  [[mockInternalUtility stub] validateURLSchemes];

  id mockSDKBridgeAPI = [OCMockObject niceMockForClass:[FBSDKBridgeAPI class]];
  [[[mockSDKBridgeAPI stub] andReturn:mockSDKBridgeAPI] sharedInstance];
  // Check API bridge request
  [[mockSDKBridgeAPI expect] openBridgeAPIRequest:[OCMArg checkWithBlock:^BOOL(FBSDKBridgeAPIRequest *request) {
    XCTAssertEqualObjects(request.scheme, scheme);
    XCTAssertEqualObjects(request.methodName, methodName);
    return YES;
  }]
                                    useSafariViewController:(BOOL)OCMOCK_ANY
                                         fromViewController:OCMOCK_ANY
                                            completionBlock:OCMOCK_ANY];

  UIViewController *vc = [UIViewController new];
  dialog.fromViewController = vc;
  XCTAssert([dialog show]);

  [mockSDKBridgeAPI stopMocking];
  [mockInternalUtility stopMocking];
  [settingsClassMock stopMocking];
  [mockApplication stopMocking];
}
- (void)_performBlockWithAccessToken:(dispatch_block_t)block
{
  FBSDKAccessToken *accessToken = [[FBSDKAccessToken alloc] initWithTokenString:@"FBSDKShareDialogTests" permissions:nil declinedPermissions:nil appID:nil userID:nil expirationDate:nil refreshDate:nil];
  [self _setCurrentAccessToken:accessToken andPerformBlock:block];
}

- (void)_performBlockWithNilAccessToken:(dispatch_block_t)block
{
  [self _setCurrentAccessToken:nil andPerformBlock:block];
}

- (void)_setCurrentAccessToken:(FBSDKAccessToken *)accessToken
               andPerformBlock:(dispatch_block_t)block
{
  if (block == NULL) {
    return;
  }
  FBSDKAccessToken *oldToken = [FBSDKAccessToken currentAccessToken];
  [FBSDKAccessToken setCurrentAccessToken:accessToken];
  block();
  [FBSDKAccessToken setCurrentAccessToken:oldToken];
}

@end
