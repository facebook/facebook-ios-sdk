/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>

@interface RPSFriendsViewController : UIViewController

@property (nonatomic, weak) IBOutlet UITextView *activityTextView;

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, weak) IBOutlet UIButton *challengeButton;

- (IBAction)tapChallengeFriends:(id)sender;

@end
