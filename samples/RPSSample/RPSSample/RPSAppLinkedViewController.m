/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "RPSAppLinkedViewController.h"

#import "RPSCommonObjects.h"

@interface RPSAppLinkedViewController ()
@property (nonatomic, assign) RPSCall call;
@property (nonatomic, weak) IBOutlet UIImageView *callImageView;
@property (nonatomic, weak) IBOutlet UIButton *playButton;
@end

@implementation RPSAppLinkedViewController

#pragma mark - Lifecycle

- (instancetype)initWithCall:(RPSCall)call
{
  NSParameterAssert(call != RPSCallNone);

  self = [super init];

  if (self) {
    self.call = call;
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
  }

  return self;
}

#pragma mark - Methods

- (IBAction)play:(id)sender
{
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.playButton.layer.cornerRadius = 8.0;
  self.playButton.layer.borderWidth = 4.0;
  self.playButton.layer.borderColor = self.playButton.titleLabel.textColor.CGColor;

  UIImage *callImage = nil;
  switch (self.call) {
    case RPSCallPaper:
      callImage = [UIImage imageNamed:@"right-paper-128.png"];
      break;
    case RPSCallRock:
      callImage = [UIImage imageNamed:@"right-rock-128.png"];
      break;
    case RPSCallScissors:
      callImage = [UIImage imageNamed:@"right-scissors-128.png"];
      break;

    default:
      break;
  }

  [self.callImageView setImage:callImage];
}

@end
