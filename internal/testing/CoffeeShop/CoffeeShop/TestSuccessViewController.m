// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "TestSuccessViewController.h"

@interface TestSuccessViewController ()

@end

@implementation TestSuccessViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.view.backgroundColor = UIColor.whiteColor;
  UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(10, 100, 100, 100)];
  textView.text = @"Success";
  [self.view addSubview:textView];
}

@end
