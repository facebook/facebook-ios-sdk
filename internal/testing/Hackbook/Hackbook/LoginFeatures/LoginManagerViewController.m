// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "LoginManagerViewController.h"
#import <AppTrackingTransparency/AppTrackingTransparency.h>

@import FBSDKLoginKit;

@interface LoginManagerViewController ()

@property (nonatomic, strong) IBOutlet UIButton *stateAgnosticLoginButton;
@property (nonatomic, strong) IBOutlet UIButton *loginButton;
@property (nonatomic, strong) IBOutlet UILabel *attLabel;
@property (nonatomic, strong) IBOutlet UISwitch *trackingLimitedSwitch;
@property (nonatomic, strong) IBOutlet UISwitch *fastAppSwitchSwitch;
@property (nonatomic, strong) IBOutlet UITextField *nonceTextField;
@property (nonatomic, strong) IBOutlet UIButton *defaultAudienceButton;
@property (nonatomic) FBSDKDefaultAudience defaultAudience;

@end

@implementation LoginManagerViewController

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  [self updateLoginButton];

  [self configureDefaultAudienceButton];

  [self setATTLabelText];
}

- (FBSDKLoginTracking)tracking
{
  return self.trackingLimitedSwitch.isOn ? FBSDKLoginTrackingLimited : FBSDKLoginTrackingEnabled;
}

- (FBSDKAppSwitch)appSwitch
{
  return self.fastAppSwitchSwitch.isOn ? FBSDKAppSwitchEnabled : FBSDKAppSwitchDisabled;
}

- (NSString *)nonce
{
  return self.nonceTextField.text;
}

- (FBSDKLoginConfiguration *)configuration
{
  if (self.nonce && self.nonce.length > 0) {
    return [[FBSDKLoginConfiguration alloc] initWithPermissions:self.selectedPermissions
                                                       tracking:self.tracking
                                                          nonce:self.nonce
                                                  messengerPageId:nil
                                                       authType:FBSDKLoginAuthTypeRerequest
                                                      appSwitch:self.appSwitch];
  } else {
    return [[FBSDKLoginConfiguration alloc] initWithPermissions:self.selectedPermissions
                                                       tracking:self.tracking
                                                  messengerPageId:nil
                                                       authType:FBSDKLoginAuthTypeRerequest
                                                      appSwitch:self.appSwitch];
  }
}

- (void)configureDefaultAudienceButton {
    if (@available(iOS 14.0, *)) {
        NSMutableArray* children = [[NSMutableArray alloc] init];
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

- (IBAction)toggleLoginState:(id)sender
{
  FBSDKLoginManager *loginManager = [FBSDKLoginManager new];
  loginManager.defaultAudience = self.defaultAudience;

  if ([self isLoggedIn]) {
    [loginManager logOut];
    [self updateLoginButton];
    return;
  }

  [loginManager logInFromViewController:self configuration:self.configuration completion:^(FBSDKLoginManagerLoginResult *_Nullable result, NSError *_Nullable error) {
    if (result && result.isCancelled) {
      return ConsoleLog(@"Login Cancelled");
    }
    if (error) {
      return ConsoleError(error, @"Login Error");
    }
    [self updateLoginButton];
    [self showLoginDetailsForResult:result
               requestedPermissions:self.selectedPermissions];
  }];
}

- (IBAction)stateAgnosticLogin
{
  FBSDKLoginManager *loginManager = [FBSDKLoginManager new];

  [loginManager logInFromViewController:self configuration:self.configuration completion:^(FBSDKLoginManagerLoginResult *_Nullable result, NSError *_Nullable error) {
    if (result && result.isCancelled) {
      return ConsoleLog(@"Login Cancelled");
    }
    if (error) {
      return ConsoleError(error, @"Login Error");
    }
    [self showLoginDetailsForResult:result
               requestedPermissions:self.selectedPermissions];
  }];
}

- (void)updateLoginButton
{
  NSString *title = self.isLoggedIn ? @"Log Out" : @"Log In With Facebook";
  [self.loginButton setTitle:title forState:UIControlStateNormal];
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
