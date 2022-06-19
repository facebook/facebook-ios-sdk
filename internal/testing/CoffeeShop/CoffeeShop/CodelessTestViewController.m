// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "CodelessTestViewController.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "Coffee.h"
#import "TestSuccessViewController.h"
#import "TestUtils.h"

static NSString *const alertTitle = @"Checkout success!";
static NSString *const alertMessage = @"Thank you for your purchase, we hope you enjoy our delicious coffee!";
static NSString *const alertBtn = @"OK!";

@interface CodelessTestViewController ()

@end

@implementation CodelessTestViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self.view setBackgroundColor:[UIColor whiteColor]];
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  [button addTarget:self
             action:@selector(confirmCheckout:)
   forControlEvents:UIControlEventTouchUpInside];
  [button setBackgroundColor:[UIColor blueColor]];
  [button setTitle:@"Check Out" forState:UIControlStateNormal];
  button.layer.cornerRadius = 6.0f;
  button.frame = CGRectMake(100.0, 210.0, 160.0, 40.0);
  [self.view addSubview:button];
}

- (void)confirmCheckout:(id)sender
{
  [TestUtils performBlock:^() {
               NSArray<NSDictionary *> *events = [TestUtils getEvents];
               for (NSDictionary *event in events) {
                 NSString *eventName = event[EVENT_NAME_KEY];
                 if ([eventName isEqualToString:@"fb_mobile_rate"] && event[@"_is_fb_codeless"] != nil) {
                   TestSuccessViewController *vc = [[TestSuccessViewController alloc] init];
                   [self.navigationController pushViewController:vc animated:YES];
                   return;
                 }
               }
               [TestUtils showAlert:@"Fail to send back codeless event"];
             }
               afterDelay:4];
}

@end
