/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKScreenTitleObserver+Testing.h"

@interface FBSDKScreenTitleObserverTests : XCTestCase
@end

@implementation FBSDKScreenTitleObserverTests

- (void)setUp
{
  [super setUp];
  // Required: metadata collection is off by default, so without this the observer stores nil
  // and the title assertions below pass vacuously.
  [FBSDKScreenTitleObserver shared].settings = [TestSettingsFactory settingsWithMetaDataCollectionEnabled];
}

- (void)tearDown
{
  // The swizzle is installed once for the process lifetime and cannot be reversed, so only the
  // cached title needs clearing to keep later tests from seeing a stale value.
  [[FBSDKScreenTitleObserver shared] setScreenTitle:nil];
  [FBSDKScreenTitleObserver shared].settings = FBSDKSettings.sharedSettings;
  [super tearDown];
}

// Invoking viewDidAppear: previously crashed (EXC_BAD_ACCESS 0x1) because the BOOL
// argument was forwarded through an ARC-managed id. The method-exchange swizzle keeps
// the BOOL typed, so this must run without crashing and still capture the title.
- (void)testViewDidAppearCapturesScreenTitle
{
  [[FBSDKScreenTitleObserver shared] startObserving];

  UIViewController *viewController = [UIViewController new];
  viewController.title = @"My Screen";
  [viewController viewDidAppear:YES];

  XCTAssertEqualObjects(
    [[FBSDKScreenTitleObserver shared] currentScreenTitle],
    @"My Screen",
    "Should capture the view controller's title on viewDidAppear:"
  );
}

- (void)testViewDidAppearFallsBackToLargeContentTitle
{
  [[FBSDKScreenTitleObserver shared] startObserving];

  UIViewController *viewController = [UIViewController new];
  viewController.title = nil;
  UIView *labeledView = [UIView new];
  labeledView.largeContentTitle = @"Large Title";
  [viewController.view addSubview:labeledView];

  [viewController viewDidAppear:NO];

  XCTAssertEqualObjects(
    [[FBSDKScreenTitleObserver shared] currentScreenTitle],
    @"Large Title",
    "Should fall back to a subview's largeContentTitle when the title is empty"
  );
}

@end
