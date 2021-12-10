/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@import XCTest;
@import TestTools;
@import FBSDKGamingServicesKit;

@interface FBSDKSwitchContextDialogTests : XCTestCase <FBSDKContextDialogDelegate>
@end

@implementation FBSDKSwitchContextDialogTests

- (void)testCreating
{
  FBSDKSwitchContextContent *content = [[FBSDKSwitchContextContent alloc] initDialogContentWithContextID:@"12345"];
  id<FBSDKWindowFinding> windowFinder = [TestWindowFinder new];

  FBSDKSwitchContextDialog *dialog = [FBSDKSwitchContextDialog dialogWithContent:content
                                                                    windowFinder:windowFinder
                                                                        delegate:self];

  XCTAssertNotNil(dialog, "The existing objc interface for creating a dialog should be available");
}

// MARK: - Delegate conformance

- (void)contextDialog:(nonnull FBSDKContextWebDialog *)contextDialog didFailWithError:(nonnull NSError *)error {}

- (void)contextDialogDidCancel:(nonnull FBSDKContextWebDialog *)contextDialog {}

- (void)contextDialogDidComplete:(nonnull FBSDKContextWebDialog *)contextDialog {}

@end
