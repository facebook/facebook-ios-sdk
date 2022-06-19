// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "ConsentFormViewController.h"

@interface ConsentFormViewController ()

@end

@implementation ConsentFormViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self showConsentForm];
}

- (void)showConsentForm
{
  UIView *consentFormView = [[UIView alloc] init];
  [self.view addSubview:consentFormView];

  consentFormView.backgroundColor = [UIColor whiteColor];
  consentFormView.layer.cornerRadius = 6.0f;
  consentFormView.translatesAutoresizingMaskIntoConstraints = NO;
  UIColor *transBlack = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
  self.view.backgroundColor = transBlack;

  UILabel *headline = [[UILabel alloc] init];
  headline.font = [UIFont systemFontOfSize:16];
  headline.text = @"Lorem ipsum dolor sit er elit lamet, consectetaur cillium";
  [consentFormView addSubview:headline];
  headline.numberOfLines = 0;

  UITextView *text = [[UITextView alloc] init];
  text.editable = NO;
  text.font = [UIFont systemFontOfSize:12];
  text.scrollEnabled = YES;
  text.text = @"uis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Nam liber te conscient to factor tum poen legum odioque civiuda.fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Nam liber te conscient to factor tum poen legum odioque civiuda.fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Nam liber te conscient to factor tum poen legum odioque civiuda.";
  [consentFormView addSubview:text];

  UIButton *firstButton = [UIButton buttonWithType:UIButtonTypeCustom];
  firstButton.titleLabel.font = [UIFont systemFontOfSize:12];
  [firstButton setTitle:@"Primary" forState:UIControlStateNormal];
  [firstButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  firstButton.backgroundColor = [UIColor colorWithRed:0.0 green:122.0 / 255.0 blue:1.0 alpha:1.0];
  firstButton.layer.cornerRadius = 6.0f;
  [firstButton addTarget:self action:@selector(showSuccessPage) forControlEvents:UIControlEventTouchUpInside];
  [consentFormView addSubview:firstButton];

  UIButton *secondButton = [UIButton buttonWithType:UIButtonTypeCustom];
  secondButton.titleLabel.font = [UIFont systemFontOfSize:12];
  [secondButton setTitle:@"Secondary" forState:UIControlStateNormal];
  [secondButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
  secondButton.layer.cornerRadius = 6.0f;
  secondButton.layer.borderWidth = 1.0f;
  secondButton.layer.borderColor = [UIColor darkGrayColor].CGColor;
  [secondButton addTarget:self action:@selector(showSuccessPage) forControlEvents:UIControlEventTouchUpInside];
  [consentFormView addSubview:secondButton];

  NSDictionary<NSString *, id> *views = @{@"consentFormView" : consentFormView, @"headline" : headline, @"text" : text, @"firstButton" : firstButton, @"secondButton" : secondButton};
  for (UIView *view in views.allValues) {
    view.translatesAutoresizingMaskIntoConstraints = NO;
  }

  [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-60-[consentFormView]-60-|" options:0 metrics:nil views:views]];
  [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[consentFormView(==400)]" options:0 metrics:nil views:views]];
  [self.view addConstraint:[NSLayoutConstraint constraintWithItem:consentFormView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];

  [consentFormView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-12-[headline]-12-[text(==227)]-12-[firstButton(==34)]-12-[secondButton(==34)]-12-|" options:0 metrics:nil views:views]];
  [consentFormView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-15-[headline]-15-|" options:0 metrics:nil views:views]];
  [consentFormView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-15-[text]-15-|" options:0 metrics:nil views:views]];
  [consentFormView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-15-[firstButton]-15-|" options:0 metrics:nil views:views]];
  [consentFormView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-15-[secondButton]-15-|" options:0 metrics:nil views:views]];
  self.currentView = consentFormView;
}

- (void)showSuccessPage
{
  self.currentView.hidden = true;
  UIView *feedbackView = [[UIView alloc] init];
  [self.view addSubview:feedbackView];
  feedbackView.backgroundColor = [UIColor whiteColor];
  feedbackView.layer.cornerRadius = 6.0f;
  feedbackView.translatesAutoresizingMaskIntoConstraints = NO;

  UIImage *checkMark = [UIImage imageNamed:@"checkmarkCircleBlue"];
  UIImageView *imageView = [[UIImageView alloc] initWithImage:checkMark];
  [feedbackView addSubview:imageView];
  UILabel *headline = [[UILabel alloc] init];
  headline.font = [UIFont systemFontOfSize:16];
  headline.textColor = [UIColor blackColor];
  headline.text = @"Lorem ipsum dolor sit dolor sit";
  [feedbackView addSubview:headline];
  headline.numberOfLines = 0;
  UITextView *text = [[UITextView alloc] init];
  text.editable = NO;
  text.font = [UIFont systemFontOfSize:12];
  text.scrollEnabled = YES;
  text.text = @"uis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit.";
  text.textAlignment = NSTextAlignmentCenter;
  [feedbackView addSubview:text];
  UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
  closeButton.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12];;
  [closeButton setTitle:@"Close" forState:UIControlStateNormal];
  [closeButton setTitleColor:[UIColor colorWithRed:0.0 green:122.0 / 255.0 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
  [closeButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
  [feedbackView addSubview:closeButton];

  NSDictionary *views = @{@"feedbackView" : feedbackView, @"headline" : headline, @"text" : text, @"closeButton" : closeButton, @"imageView" : imageView};
  for (UIView *view in views.allValues) {
    view.translatesAutoresizingMaskIntoConstraints = NO;
  }
  [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-60-[feedbackView]-60-|" options:0 metrics:nil views:views]];
  [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[feedbackView(==220)]" options:0 metrics:nil views:views]];
  [self.view addConstraint:[NSLayoutConstraint constraintWithItem:feedbackView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
  [feedbackView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-12-[imageView(==50)][headline(==30)][text(==80)]-12-[closeButton(==34)]-12-|" options:0 metrics:nil views:views]];
  [feedbackView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-100-[imageView(==50)]-100-|" options:0 metrics:nil views:views]];
  [feedbackView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-15-[headline]-15-|" options:0 metrics:nil views:views]];
  [feedbackView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-15-[text]-15-|" options:0 metrics:nil views:views]];
  [feedbackView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-15-[closeButton]-15-|" options:0 metrics:nil views:views]];
  self.currentView = feedbackView;
}

- (void)dismiss
{
  [self dismissViewControllerAnimated:NO completion:nil];
}

@end
