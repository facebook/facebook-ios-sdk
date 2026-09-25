/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "UIViewController+FBSDKMetadataCollection.h"

#import "FBSDKLogger.h"
#import "FBSDKScreenTitleObserver.h"

FB_LINK_CATEGORY_IMPLEMENTATION(UIViewController, FBSDKMetadataCollection)
@implementation UIViewController (FBSDKMetadataCollection)

- (void)fb_metadataCollectionViewDidAppear:(BOOL)animated
{
  IMP originalImp = [FBSDKScreenTitleObserver shared].originalViewDidAppearImplementation;
  if (originalImp) {
    void (*originalFunction)(id, SEL, BOOL) = (void (*)(id, SEL, BOOL))originalImp;
    originalFunction(self, @selector(viewDidAppear:), animated);
  } else {
    [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                           logEntry:@"fb_metadataCollectionViewDidAppear: original viewDidAppear: IMP is missing; skipping original call"];
  }

  // Clear rather than skip, and before the BFS so a gated-off SDK walks no view hierarchy.
  if (![FBSDKScreenTitleObserver shared].isCollectionPermitted) {
    [[FBSDKScreenTitleObserver shared] setScreenTitle:nil];
    return;
  }

  NSString *title = self.title;
  if (title.length == 0) {
    title = [FBSDKScreenTitleObserver findLargeContentTitleInView:self.view];
  }
  [[FBSDKScreenTitleObserver shared] setScreenTitle:title];
}

@end
