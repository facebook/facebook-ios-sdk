// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "DismissSegue.h"

@implementation DismissSegue

- (void)perform
{
  [(UIViewController *)self.sourceViewController dismissViewControllerAnimated:YES completion:NULL];
}

@end
