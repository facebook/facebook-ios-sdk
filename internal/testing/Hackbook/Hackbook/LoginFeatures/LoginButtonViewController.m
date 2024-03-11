// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "LoginButtonViewController.h"
#import <AppTrackingTransparency/AppTrackingTransparency.h>

@import FBSDKLoginKit;

@interface LoginButtonViewController () <FBSDKLoginButtonDelegate>

@property (nonatomic, strong) IBOutlet FBSDKLoginButton *loginButton;
@property (nonatomic, strong) IBOutlet UISwitch *trackingLimitedSwitch;
@property (nonatomic, strong) IBOutlet UITextField *nonceTextField;
@property (nonatomic, strong) IBOutlet UIButton *defaultAudienceButton;
@property (nonatomic, strong) IBOutlet UILabel *attLabel;
@property (nonatomic) FBSDKDefaultAudience defaultAudience;

@end

@implementation LoginButtonViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.loginButton.delegate = self;

  [self configureDefaultAudienceButton];
  
  [self setATTLabelText];
}

- (BOOL)loginButtonWillLogin:(FBSDKLoginButton *)loginButton
{
  self.loginButton.permissions = self.selectedPermissions;
  self.loginButton.loginTracking = self.trackingLimitedSwitch.isOn ? FBSDKLoginTrackingLimited : FBSDKLoginTrackingEnabled;

  NSString *nonce = self.nonceTextField.text;

  if (nonce && nonce.length > 0) {
    self.loginButton.nonce = nonce;
  }

  self.loginButton.defaultAudience = self.defaultAudience;

  return YES;
}

- (void)    loginButton:(FBSDKLoginButton *)loginButton
  didCompleteWithResult:(FBSDKLoginManagerLoginResult *)result
                  error:(NSError *)error
{
  if (error) {
    ConsoleError(error, @"Login Error");
    return;
  }

  if (result && result.isCancelled) {
    ConsoleLog(@"Login Cancelled");
    return;
  }

  [self showLoginDetailsForResult:result
             requestedPermissions:self.selectedPermissions];
}

- (void)loginButtonDidLogOut:(FBSDKLoginButton *)loginButton
{
  ConsoleLog(@"Logged out");
}

- (void)configureDefaultAudienceButton {
    if (@available(iOS 14.0, *)) {
        NSMutableArray* children = [NSMutableArray new];
        [children addObject:[UIAction actionWithTitle:@"Friends" image:nil identifier:nil handler:^(__kindof UIAction* _Nonnull action) {
            self.defaultAudience = FBSDKDefaultAudienceFriends;
        }]];
        [children addObject:[UIAction actionWithTitle:@"Everyone" image:nil identifier:nil handler:^(__kindof UIAction* _Nonnull action) {
                self.defaultAudience = FBSDKDefaultAudienceEveryone;
        }]];
        [children addObject:[UIAction actionWithTitle:@"Only Me" image:nil identifier:nil handler:^(__kindof UIAction* _Nonnull action) {
                self.defaultAudience = FBSDKDefaultAudienceOnlyMe;
        }]];
        UIMenu* menu = [UIMenu menuWithTitle:@"" children:children];

        self.defaultAudienceButton.menu = menu;
        self.defaultAudienceButton.showsMenuAsPrimaryAction = YES;
        if (@available(iOS 15, *)) {
            self.defaultAudienceButton.changesSelectionAsPrimaryAction = true;
        }
    }
}

- (void)setATTLabelText
{
  NSString *attLabelText = @"Not Authorized";
  if (@available(iOS 14, *)) {
    if (ATTrackingManager.trackingAuthorizationStatus == ATTrackingManagerAuthorizationStatusAuthorized) {
      attLabelText = @"Authorized";
    }
  } else {
    // Previous iOS versions will go thorugh the regular FB Login flow by default, which is the case
    // for the Authorized status
    attLabelText = @"Authorized";
  }
  
  [self.attLabel setText:[NSString stringWithFormat:@"ATT Status: %@", attLabelText]];
}


@end
