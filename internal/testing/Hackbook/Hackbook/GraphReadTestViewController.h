// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <UIKit/UIKit.h>

#import "TestListViewController.h"

@interface GraphReadTestViewController : TestListViewController

- (IBAction)fetchFriends:(id)sender;
- (IBAction)fetchMe:(id)sender;
- (IBAction)fetchPermissions:(id)sender;
- (IBAction)fetchDeprecatedUserInfo:(id)sender;
- (IBAction)makeTestBatchRequest:(id)sender;

@end
