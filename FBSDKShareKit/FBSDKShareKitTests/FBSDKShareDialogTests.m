/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

@import TestTools;
@import FBSDKCoreKit_Basics;
@import FBSDKCoreKit;

#import "FBSDKHashtag.h"
#import "FBSDKShareBridgeAPIRequestFactory.h"
#import "FBSDKShareCameraEffectContent+Testing.h"
#import "FBSDKShareDefines.h"
#import "FBSDKShareDialog+Testing.h"
#import "FBSDKShareKitTestUtility.h"
#import "FBSDKShareKitTests-Swift.h"
#import "FBSDKShareModelTestUtility.h"
#import "FBSDKShareUtility.h"
#import "FBSDKSocialComposeViewControllerFactory.h"

@interface FBSDKShareDialogTests : XCTestCase

@property (nonnull, nonatomic) TestInternalURLOpener *internalURLOpener;
@property (nonnull, nonatomic) TestInternalUtility *internalUtility;
@property (nonnull, nonatomic) TestSettings *settings;
@property (nonnull, nonatomic) TestBridgeAPIRequestFactory *bridgeAPIRequestFactory;
@property (nonnull, nonatomic) TestBridgeAPIRequestOpener *bridgeAPIRequestOpener;
@property (nonnull, nonatomic) TestSocialComposeViewControllerFactory *socialComposeViewControllerFactory;
@property (nonnull, nonatomic) TestWindowFinder *windowFinder;

@end

@implementation FBSDKShareDialogTests

- (void)setUp
{
  [super setUp];

  [FBSDKShareDialog resetClassDependencies];
  [FBSDKShareCameraEffectContent resetClassDependencies];

  self.internalURLOpener = [TestInternalURLOpener new];
  self.internalUtility = [TestInternalUtility new];
  self.settings = [TestSettings new];
  self.bridgeAPIRequestFactory = [TestBridgeAPIRequestFactory new];
  self.bridgeAPIRequestOpener = [TestBridgeAPIRequestOpener new];
  self.socialComposeViewControllerFactory = [TestSocialComposeViewControllerFactory new];
  self.windowFinder = [TestWindowFinder new];

  [FBSDKShareDialog configureWithInternalURLOpener:self.internalURLOpener
                                   internalUtility:self.internalUtility
                                          settings:self.settings
                                      shareUtility:TestShareUtility.class
                           bridgeAPIRequestFactory:self.bridgeAPIRequestFactory
                            bridgeAPIRequestOpener:self.bridgeAPIRequestOpener
                socialComposeViewControllerFactory:self.socialComposeViewControllerFactory
                                      windowFinder:self.windowFinder];

  [FBSDKShareCameraEffectContent configureWithInternalUtility:self.internalUtility];
}

- (void)tearDown
{
  [FBSDKShareDialog resetClassDependencies];
  [TestShareUtility reset];
  [FBSDKShareCameraEffectContent resetClassDependencies];

  [super tearDown];
}

#pragma mark - Native

- (void)testDefaultClassDependencies
{
  [FBSDKShareDialog resetClassDependencies];
  [self createEmptyDialog];

  XCTAssertEqualObjects(
    FBSDKShareDialog.internalURLOpener,
    UIApplication.sharedApplication,
    @"FBSDKShareDialog should use the shared application for its default internal URL opener dependency"
  );
  XCTAssertEqualObjects(
    FBSDKShareDialog.internalUtility,
    FBSDKInternalUtility.sharedUtility,
    @"FBSDKShareDialog should use the shared utility for its default internal utility dependency"
  );
  XCTAssertEqualObjects(
    FBSDKShareDialog.settings,
    FBSDKSettings.sharedSettings,
    @"FBSDKShareDialog should use the shared settings for its default settings dependency"
  );
  XCTAssertEqualObjects(
    FBSDKShareDialog.shareUtility,
    FBSDKShareUtility.self,
    @"FBSDKShareDialog should use the share utility class for its default share utility dependency"
  );
  XCTAssertTrue(
    [(NSObject *)FBSDKShareDialog.bridgeAPIRequestFactory isMemberOfClass:FBSDKShareBridgeAPIRequestFactory.class],
    @"FBSDKShareDialog should create a new factory for its default bridge API request factory dependency"
  );
  XCTAssertEqualObjects(
    FBSDKShareDialog.bridgeAPIRequestOpener,
    FBSDKBridgeAPI.sharedInstance,
    @"FBSDKShareDialog should use the shared bridge API for its default bridge API request opening dependency"
  );
  XCTAssertTrue(
    [(NSObject *)FBSDKShareDialog.socialComposeViewControllerFactory isMemberOfClass:FBSDKSocialComposeViewControllerFactory.class],
    @"FBSDKShareDialog should create a new factory for its social compose view controller factory dependency by default"
  );
  XCTAssertEqualObjects(
    FBSDKShareDialog.windowFinder,
    FBSDKInternalUtility.sharedUtility,
    @"FBSDKShareDialog should use the shared internal utility for its default window finding dependency"
  );
}

- (void)testCanShowNativeDialogWithoutShareContent
{
  FBSDKShareDialog *const dialog = [self createEmptyDialog];
  dialog.mode = FBSDKShareDialogModeNative;
  self.internalURLOpener.canOpenURL = YES;
  self.internalUtility.isFacebookAppInstalled = YES;

  XCTAssertTrue(
    [dialog canShow],
    @"A dialog without share content should be showable on a native dialog"
  );
}

- (void)testCanShowNativeLinkContent
{
  FBSDKShareDialog *const dialog = [self createEmptyDialog];
  dialog.mode = FBSDKShareDialogModeNative;
  dialog.shareContent = [FBSDKShareModelTestUtility linkContent];
  XCTAssertTrue(
    [dialog canShow],
    @"A dialog with valid link content should be showable on a native dialog"
  );
}

- (void)testCanShowNativePhotoContent
{
  FBSDKShareDialog *const dialog = [self createEmptyDialog];
  dialog.mode = FBSDKShareDialogModeNative;
  dialog.shareContent = [FBSDKShareModelTestUtility photoContent];
  TestShareUtility.stubbedValidateShareShouldThrow = YES;

  XCTAssertFalse(
    [dialog canShow],
    @"Photo content with photos that have web urls should not be showable on a native dialog"
  );
}

- (void)testCanShowNativePhotoContentWithFileURL
{
  FBSDKShareDialog *const dialog = [self createEmptyDialog];
  dialog.mode = FBSDKShareDialogModeNative;
  dialog.shareContent = [FBSDKShareModelTestUtility photoContentWithFileURLs];
  XCTAssertTrue(
    [dialog canShow],
    @"Photo content with photos that have file urls should be showable on a native dialog"
  );
}

- (void)testCanShowNativeVideoContentWithoutPreviewPhoto
{
  FBSDKShareDialog *const dialog = [self createEmptyDialog];
  dialog.mode = FBSDKShareDialogModeNative;
  self.internalURLOpener.canOpenURL = YES;
  dialog.shareContent = [FBSDKShareModelTestUtility videoContentWithoutPreviewPhoto];

  XCTAssertTrue(
    [dialog canShow],
    @"Video content without a preview photo should be showable on a native dialog"
  );
}

- (void)testCanShowNative
{
  FBSDKShareDialog *const dialog = [self createEmptyDialog];
  dialog.mode = FBSDKShareDialogModeNative;

  XCTAssertFalse(
    [dialog canShow],
    @"A native dialog should not be showable if the application is unable to open a url, this can also occur if the api scheme is not whitelisted in the third party app or if the application cannot handle the share API scheme"
  );
}

- (void)testShowNativeDoesValidate
{
  FBSDKShareDialog *const dialog = [self createEmptyDialog];
  dialog.mode = FBSDKShareDialogModeNative;
  dialog.shareContent = [FBSDKShareModelTestUtility photoContent];
  self.internalURLOpener.canOpenURL = YES;

  XCTAssertFalse([dialog show]);
}

#pragma mark - Share sheet

- (void)testValidateShareSheet
{
  FBSDKShareDialog *const dialog = [self createEmptyDialog];
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
  dialog.shareContent = [FBSDKShareModelTestUtility videoContentWithoutPreviewPhoto];
  XCTAssertFalse([dialog validateWithError:&error]);
  XCTAssertNil(error);
}

#pragma mark - Browser

- (void)testCanShowBrowser
{
  FBSDKShareDialog *const dialog = [self createEmptyDialog];
  dialog.mode = FBSDKShareDialogModeBrowser;
  XCTAssertTrue(
    [dialog canShow],
    @"A dialog without share content should be showable in a browser"
  );
  dialog.shareContent = [FBSDKShareModelTestUtility linkContent];
  XCTAssertTrue(
    [dialog canShow],
    @"A dialog with link content should be showable in a browser"
  );
  [self _performBlockWithAccessToken:^{
    dialog.shareContent = [FBSDKShareModelTestUtility photoContentWithFileURLs];
    XCTAssertTrue(
      [dialog canShow],
      @"A dialog with photo content with file urls should be showable in a browser when there is a current access token"
    );

    dialog.shareContent = [FBSDKShareModelTestUtility videoContentWithoutPreviewPhoto];
    XCTAssertTrue(
      [dialog canShow],
      @"A dialog with video content without a preview photo should be showable in a browser when there is a current access token"
    );
  }];
}

- (void)testValidateBrowser
{
  FBSDKShareDialog *const dialog = [self createEmptyDialog];
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

  TestShareUtility.stubbedTestShareContainsPhotos = YES;
  [self _performBlockWithNilAccessToken:^{
    XCTAssertFalse([dialog validateWithError:&error]);
    XCTAssertNotNil(error);
  }];
  [TestShareUtility reset];

  TestShareUtility.stubbedTestShareContainsVideos = YES;
  dialog.shareContent = [FBSDKShareModelTestUtility videoContentWithoutPreviewPhoto];
  XCTAssertFalse([dialog validateWithError:&error]);
  XCTAssertNotNil(error);
}

#pragma mark - Web

- (void)testCanShowWeb
{
  FBSDKShareDialog *const dialog = [self createEmptyDialog];
  dialog.mode = FBSDKShareDialogModeWeb;
  XCTAssertTrue(
    [dialog canShow],
    @"A dialog without share content should be showable on web"
  );

  dialog.shareContent = [FBSDKShareModelTestUtility linkContent];
  XCTAssertTrue(
    [dialog canShow],
    @"A dialog with link content should be showable on web"
  );

  [self _performBlockWithAccessToken:^{
    TestShareUtility.stubbedTestShareContainsPhotos = YES;
    TestShareUtility.stubbedValidateShareShouldThrow = YES;
    dialog.shareContent = [FBSDKShareModelTestUtility photoContent];
    XCTAssertFalse(
      [dialog canShow],
      @"A dialog with photos should not be showable on web"
    );
    [TestShareUtility reset];

    dialog.shareContent = [FBSDKShareModelTestUtility videoContentWithoutPreviewPhoto];
    TestShareUtility.stubbedTestShareContainsMedia = YES;
    XCTAssertFalse(
      [dialog canShow],
      @"A dialog with content that contains local media should not be showable on web"
    );
    [TestShareUtility reset];
  }];
}

- (void)testValidateWeb
{
  FBSDKShareDialog *const dialog = [self createEmptyDialog];
  dialog.mode = FBSDKShareDialogModeWeb;
  __block NSError *error;
  dialog.shareContent = [FBSDKShareModelTestUtility linkContent];
  XCTAssertTrue([dialog validateWithError:&error]);
  XCTAssertNil(error);

  [self _performBlockWithAccessToken:^{
    dialog.shareContent = [FBSDKShareModelTestUtility photoContent];
    TestShareUtility.stubbedValidateShareShouldThrow = YES;
    XCTAssertFalse(
      [dialog validateWithError:&error],
      @"A dialog with photo content that points to remote urls should not be considered valid on web"
    );
    XCTAssertNotNil(
      error,
      @"Validating a dialog with photo content on web should provide a meaningful error"
    );
    [TestShareUtility reset];

    dialog.shareContent = [FBSDKShareModelTestUtility photoContentWithImages];
    TestShareUtility.stubbedTestShareContainsPhotos = YES;
    XCTAssertFalse(
      [dialog validateWithError:&error],
      @"A dialog with photo content that is already loaded should not be considered valid on web"
    );
    XCTAssertNotNil(
      error,
      @"Validating a dialog with photo content that is already loaded on web should provide a meaningful error"
    );
    [TestShareUtility reset];

    dialog.shareContent = [FBSDKShareModelTestUtility photoContentWithFileURLs];
    TestShareUtility.stubbedTestShareContainsPhotos = YES;
    XCTAssertFalse(
      [dialog validateWithError:&error],
      @"A dialog with photo content that points to file urls should not be considered valid on web"
    );
    XCTAssertNotNil(
      error,
      @"Validating a dialog with photo content that points to file urls on web should provide a meaningful error"
    );
    [TestShareUtility reset];

    dialog.shareContent = [FBSDKShareModelTestUtility videoContentWithoutPreviewPhoto];
    TestShareUtility.stubbedTestShareContainsMedia = YES;
    XCTAssertFalse(
      [dialog validateWithError:&error],
      @"A dialog that includes local media should not be considered valid on web"
    );
    XCTAssertNotNil(
      error,
      @"Validating a dialog that includes local media should provide a meaningful error"
    );
    [TestShareUtility reset];
  }];

  [self _performBlockWithNilAccessToken:^{
    TestShareUtility.stubbedTestShareContainsVideos = YES;
    XCTAssertFalse(
      [dialog validateWithError:&error],
      @"A dialog with content but no access token should not be considered valid on web"
    );
    XCTAssertNotNil(
      error,
      @"Validating a dialog with content but no access token should provide a meaningful error"
    );
    [TestShareUtility reset];
  }];
}

#pragma mark - Feed browser

- (void)testCanShowFeedBrowser
{
  FBSDKShareDialog *const dialog = [self createEmptyDialog];
  dialog.mode = FBSDKShareDialogModeFeedBrowser;
  XCTAssertTrue(
    [dialog canShow],
    @"A dialog without content should be showable in a browser feed"
  );
  dialog.shareContent = [FBSDKShareModelTestUtility linkContent];
  XCTAssertTrue(
    [dialog canShow],
    @"A dialog with link content should be showable in a browser feed"
  );
  dialog.shareContent = [FBSDKShareModelTestUtility photoContent];
  XCTAssertFalse(
    [dialog canShow],
    @"A dialog with photo content should not be showable in a browser feed"
  );
  dialog.shareContent = [FBSDKShareModelTestUtility videoContentWithoutPreviewPhoto];
  XCTAssertFalse(
    [dialog canShow],
    @"A dialog with video content that has no preview photo should not be showable in a browser feed"
  );
}

- (void)testValidateFeedBrowser
{
  FBSDKShareDialog *const dialog = [self createEmptyDialog];
  dialog.mode = FBSDKShareDialogModeFeedBrowser;
  NSError *error;
  dialog.shareContent = [FBSDKShareModelTestUtility linkContent];
  XCTAssertTrue([dialog validateWithError:&error]);
  XCTAssertNil(error);
  dialog.shareContent = [FBSDKShareModelTestUtility photoContentWithImages];
  XCTAssertFalse([dialog validateWithError:&error]);
  XCTAssertNotNil(error);
  dialog.shareContent = [FBSDKShareModelTestUtility videoContentWithoutPreviewPhoto];
  XCTAssertFalse([dialog validateWithError:&error]);
  XCTAssertNotNil(error);
}

#pragma mark - Feed web

- (void)testCanShowFeedWeb
{
  FBSDKShareDialog *const dialog = [self createEmptyDialog];
  dialog.mode = FBSDKShareDialogModeFeedWeb;
  XCTAssertTrue(
    [dialog canShow],
    @"A dialog without content should be showable in a web feed"
  );
  dialog.shareContent = [FBSDKShareModelTestUtility linkContent];
  XCTAssertTrue(
    [dialog canShow],
    @"A dialog with link content should be showable in a web feed"
  );
  dialog.shareContent = [FBSDKShareModelTestUtility photoContent];
  XCTAssertFalse(
    [dialog canShow],
    @"A dialog with photo content should not be showable in a web feed"
  );
  dialog.shareContent = [FBSDKShareModelTestUtility videoContentWithoutPreviewPhoto];
  XCTAssertFalse(
    [dialog canShow],
    @"A dialog with video content and no preview photo should not be showable in a web feed"
  );
}

- (void)testValidateFeedWeb
{
  FBSDKShareDialog *const dialog = [self createEmptyDialog];
  dialog.mode = FBSDKShareDialogModeFeedWeb;
  NSError *error;
  dialog.shareContent = [FBSDKShareModelTestUtility linkContent];
  XCTAssertTrue([dialog validateWithError:&error]);
  XCTAssertNil(error);
  dialog.shareContent = [FBSDKShareModelTestUtility photoContentWithImages];
  XCTAssertFalse([dialog validateWithError:&error]);
  XCTAssertNotNil(error);
  dialog.shareContent = [FBSDKShareModelTestUtility videoContentWithoutPreviewPhoto];
  XCTAssertFalse([dialog validateWithError:&error]);
  XCTAssertNotNil(error);
}

- (void)testThatInitialTextIsSetCorrectlyWhenShareExtensionIsAvailable
{
  FBSDKShareDialog *const dialog = [self createEmptyDialog];
  FBSDKShareLinkContent *content = [FBSDKShareModelTestUtility linkContent];
  content.hashtag = [FBSDKHashtag hashtagWithString:@"#hashtag"];
  TestShareUtility.stubbedHashtagString = @"#hashtag";
  content.quote = @"a quote";
  dialog.shareContent = content;
  self.internalUtility.isFacebookAppInstalled = YES;

  NSDictionary<NSString *, id> *expectedJSON = @{@"app_id" : @"appID", @"hashtags" : @[@"#hashtag"], @"quotes" : @[@"a quote"]};
  [self _showDialog:dialog
                 appID:@"appID"
   expectedPreJSONtext:@"fb-app-id:appID #hashtag"
          expectedJSON:expectedJSON];
}

#pragma mark - Camera Share

- (void)testCameraShareModesWhenNativeAvailable
{
  FBSDKShareDialog *const dialog = [self createEmptyDialog];
  dialog.shareContent = [FBSDKShareModelTestUtility cameraEffectContent];
  self.internalURLOpener.canOpenURL = YES;
  self.internalUtility.isFacebookAppInstalled = YES;

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
}

- (void)testCameraShareModesWhenNativeUnavailable
{
  FBSDKShareDialog *const dialog = [self createEmptyDialog];
  dialog.shareContent = [FBSDKShareModelTestUtility cameraEffectContent];

  NSError *error;
  dialog.mode = FBSDKShareDialogModeAutomatic;
  XCTAssertFalse([dialog validateWithError:&error]);
  XCTAssertNotNil(error);
}

#pragma mark - FullyCompatible Validation

- (void)testThatValidateWithErrorReturnsYESForLinkQuoteIfAValidShareExtensionVersionIsAvailable
{
  self.internalUtility.isFacebookAppInstalled = YES;

  [self _testValidateShareContent:[FBSDKShareModelTestUtility linkContent]
                      expectValid:YES
                       expectShow:YES
                             mode:FBSDKShareDialogModeShareSheet
               nonSupportedScheme:nil];
}

- (void)testThatValidateWithErrorReturnsNOForMMPIfAValidShareExtensionVersionIsNotAvailable
{
  TestShareUtility.stubbedValidateShareShouldThrow = YES;

  [self _testValidateShareContent:[FBSDKShareModelTestUtility mediaContent]
                      expectValid:NO
                       expectShow:NO
                             mode:FBSDKShareDialogModeShareSheet
               nonSupportedScheme:@"fbapi20160328:/"];
}

- (void)testThatValidateWithErrorReturnsYESForMMPIfAValidShareExtensionVersionIsAvailable
{
  self.internalUtility.isFacebookAppInstalled = YES;

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

- (void)_testValidateShareContent:(id<FBSDKSharingContent>)shareContent
                      expectValid:(BOOL)expectValid
                       expectShow:(BOOL)expectShow
                             mode:(FBSDKShareDialogMode)mode
               nonSupportedScheme:(NSString *)nonSupportedScheme
{
  self.internalURLOpener.computeCanOpenURL = ^BOOL (NSURL *url) {
    return ![url.absoluteString isEqualToString:nonSupportedScheme];
  };
  self.socialComposeViewControllerFactory.canMakeSocialComposeViewController = YES;
  self.socialComposeViewControllerFactory.stubbedSocialComposeViewController = [TestSocialComposeViewController new];

  UIViewController *vc = [UIViewController new];
  FBSDKShareDialog *const dialog = [self createEmptyDialog];
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
}

- (void)  _showDialog:(FBSDKShareDialog *)dialog
                appID:(NSString *)appID
  expectedPreJSONtext:(NSString *)expectedPreJSONText
         expectedJSON:(NSDictionary<NSString *, id> *)expectedJSON
{
  self.internalURLOpener.canOpenURL = YES;
  self.settings.appID = appID;
  TestSocialComposeViewController *socialComposeViewController = [TestSocialComposeViewController new];
  self.socialComposeViewControllerFactory.stubbedSocialComposeViewController = socialComposeViewController;
  self.socialComposeViewControllerFactory.canMakeSocialComposeViewController = YES;

  UIViewController *vc = [UIViewController new];
  dialog.fromViewController = vc;
  dialog.mode = FBSDKShareDialogModeShareSheet;
  XCTAssertTrue([dialog show]);

  BOOL (^checkInitialText)(NSString *) = ^BOOL (NSString *text) {
    NSRange JSONDelimiterRange = [text rangeOfString:@"|"];
    NSString *preJSONText;
    NSDictionary<NSString *, id> *json;
    if (JSONDelimiterRange.location == NSNotFound) {
      preJSONText = text;
    } else {
      preJSONText = [text substringToIndex:JSONDelimiterRange.location];
      NSString *jsonText = [text substringFromIndex:JSONDelimiterRange.location + 1];
      json = [FBSDKTypeUtility JSONObjectWithData:[jsonText dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    }
    return ((expectedPreJSONText == nil && preJSONText == nil) || [expectedPreJSONText isEqualToString:preJSONText])
    && ((expectedJSON == nil && json == nil) || [expectedJSON isEqual:json]);
  };
  XCTAssertTrue(checkInitialText(socialComposeViewController.capturedInitialText));
}

- (void)_showNativeDialog:(FBSDKShareDialog *)dialog
       nonSupportedScheme:(nullable NSString *)nonSupportedScheme
      expectRequestScheme:(nonnull NSString *)scheme
               methodName:(nonnull NSString *)methodName
{
  self.internalURLOpener.computeCanOpenURL = ^BOOL (NSURL *url) {
    return ![url.absoluteString isEqualToString:nonSupportedScheme];
  };
  self.settings.appID = @"AppID";
  id<FBSDKBridgeAPIRequest> stubbedRequest = [[TestBridgeAPIRequest alloc] initWithUrl:nil
                                                                          protocolType:FBSDKBridgeAPIProtocolTypeNative
                                                                                scheme:@"1"];
  self.bridgeAPIRequestFactory.stubbedBridgeAPIRequest = stubbedRequest;

  UIViewController *vc = [UIViewController new];
  dialog.fromViewController = vc;
  XCTAssertTrue([dialog show]);

  // Ensure that the request was created with the correct parameters
  XCTAssertEqualObjects(self.bridgeAPIRequestFactory.capturedMethodName, methodName);

  if (scheme) {
    XCTAssertEqualObjects(self.bridgeAPIRequestFactory.capturedScheme, scheme);
  } else {
    XCTAssertNil(self.bridgeAPIRequestFactory.capturedScheme);
  }

  // Ensure that the created request was passed to the opener
  XCTAssertEqualObjects(self.bridgeAPIRequestOpener.capturedRequest, stubbedRequest);
}

- (void)_performBlockWithAccessToken:(dispatch_block_t)block
{
  FBSDKAccessToken *accessToken = [[FBSDKAccessToken alloc] initWithTokenString:@"FBSDKShareDialogTests"
                                                                    permissions:@[]
                                                            declinedPermissions:@[]
                                                             expiredPermissions:@[]
                                                                          appID:@""
                                                                         userID:@""
                                                                 expirationDate:nil
                                                                    refreshDate:nil
                                                       dataAccessExpirationDate:nil];
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
  FBSDKAccessToken *oldToken = FBSDKAccessToken.currentAccessToken;
  FBSDKAccessToken.currentAccessToken = accessToken;
  block();
  FBSDKAccessToken.currentAccessToken = oldToken;
}

- (FBSDKShareDialog *)createEmptyDialog
{
  return [[FBSDKShareDialog alloc] initWithViewController:nil content:nil delegate:nil];
}

@end
