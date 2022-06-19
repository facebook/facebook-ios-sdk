// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#ifndef RELEASED_SDK_ONLY
#import <UIKit/UIKit.h>

#import "TestListViewController.h"

@interface GameRequestDialogTestViewController : TestListViewController

- (IBAction)gameRequestSuggestedFriends:(id)sender;
- (IBAction)gameRequestNoSuggestedFriends:(id)sender;
- (IBAction)frictionlessRequest:(id)sender;

@end
#endif
