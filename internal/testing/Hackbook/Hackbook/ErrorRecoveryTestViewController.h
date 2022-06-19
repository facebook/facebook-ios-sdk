// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <UIKit/UIKit.h>

#import "TestListViewController.h"

@interface ErrorRecoveryTestViewController : TestListViewController

- (IBAction)loginRecoverableRequest:(id)sender;
- (IBAction)retriableRequest:(id)sender;

@end
