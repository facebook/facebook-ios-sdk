// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "MainViewController.h"

@import FBSDKCoreKit;
@import FBSDKGamingServicesKit;
@import FBSDKLoginKit;

#import "Console.h"
#import "DeviceLoginViewController.h"
#import "GamingServicesTestTableViewController.h"
// @lint-ignore CLANGTIDY
#import "Hackbook-Swift.h"
#import "LoginFeatures/LoginViewController.h"
#import "NavigationController.h"
#import "PermissionsViewController.h"
#import "Utilities.h"
#import <AppTrackingTransparency/AppTrackingTransparency.h>

static NSString *GetVersionInfo(NSBundle *bundle)
{
  NSString *const buildBranchName = [bundle objectForInfoDictionaryKey:@"FBBuildBranchName"];
  NSString *versionInfo = (buildBranchName.length == 0) ? @"Local" : buildBranchName;

  NSString *const appVersion = [bundle objectForInfoDictionaryKey:@"FBAppVersion"]; // Try loading the new-style app version
  NSString *const displayVersion = (appVersion.length == 0)
  ? [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] // Fallback to old-style app version
  : appVersion;
  if (displayVersion.length > 0) {
    versionInfo = [versionInfo stringByAppendingFormat:@" v%@", displayVersion];
  }

  NSString *buildNumber = [bundle objectForInfoDictionaryKey:@"FBBuildNumber"];
  if (buildNumber) {
    if (![buildNumber isKindOfClass:[NSString class]]) {
      buildNumber = [NSString stringWithFormat:@"%@", buildNumber];
    }
  }
  if (buildNumber.length > 0) {
    versionInfo = [versionInfo stringByAppendingFormat:@" (%@)", buildNumber];
  }

  return versionInfo; // Master v4.0 (117046164)
}

static NSString *kGamingLoginKey = @"should_use_gaming_login";
static NSString *kCurrentSelectedApp = @"current_selected_app";
static const NSInteger kFacebookDomainRowIndex = 3;
static const NSInteger kGraphAPIRowIndex = 4;
static const CGFloat marginXForBanner = 15;
static const CGFloat marginYForBanner = 0;

@interface MainViewController () <PermissionsViewControllerDelegate, FBSDKLoginButtonDelegate, UITextFieldDelegate, FBSDKGamingPayloadDelegate>
@property (nonatomic, strong) FBSDKGamingPayloadObserver *payloadObserver;
@end

@implementation MainViewController
{
  NSMutableSet *_selectedPermissions;
  NSDictionary *_settingsData;
  NSDictionary *_appsData;
  __weak IBOutlet UITextField *_domainEditorTextField;
  __weak IBOutlet UITextField *_graphAPIVersionEditorTextField;
  FBSDKLoginManager *_loginManager;
  UIView *_tableFooter;
  NSURL *_deeplinkURL;
}

#pragma mark - View Management

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  UIView *tableHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 80)];
  loginButton = [[FBSDKLoginButton alloc] initWithFrame:CGRectMake(0, 0, 220, 30)];
  [tableHeader addSubview:loginButton];

  loginButton.center = CGPointMake(tableHeader.frame.size.width / 2, tableHeader.frame.size.height / 2);
  loginButton.delegate = self;
  
  self.tableView.tableHeaderView = tableHeader;
  self.title = [[NSUserDefaults standardUserDefaults] stringForKey:kCurrentSelectedApp];

  _loginManager = [[FBSDKLoginManager alloc] init];

  NSBundle *const bundle = [NSBundle mainBundle];
  NSURL *const URL = [bundle URLForResource:@"settings" withExtension:@"plist"];
  _settingsData = [[NSDictionary alloc] initWithContentsOfURL:URL];
  _appsData = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Apps" ofType:@"plist"]];
  _selectedPermissions = [[NSMutableSet alloc] init];
  [_selectedPermissions addObjectsFromArray:@[@"Browser", @"Everyone"]];
  loginButton.delegate = self;
  [_domainEditorTextField setDelegate:self];
  _domainEditorTextField.text = FBSDKSettings.sharedSettings.facebookDomainPart ?: FacebookBaseDomain;
  [_graphAPIVersionEditorTextField setDelegate:self];
  _graphAPIVersionEditorTextField.text = FBSDKSettings.sharedSettings.graphAPIVersion;
  versionButton = [[UIBarButtonItem alloc] initWithTitle:@"Version" style:UIBarButtonItemStylePlain target:self action:@selector(selectVersion:)];
  [versionButton setTitle:GetVersionInfo(bundle)];
  NSDictionary<NSString *, id> *const titleTextAttributes = @{
    NSForegroundColorAttributeName : [UIColor darkGrayColor],
    NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote],
  };
  [versionButton setTitleTextAttributes:titleTextAttributes forState:UIControlStateNormal];
  [versionButton setTitleTextAttributes:titleTextAttributes forState:UIControlStateHighlighted];

  self.toolbarItems = @[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], versionButton, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];

  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[[FBSDKProfilePictureView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)]];

  self.payloadObserver = [[FBSDKGamingPayloadObserver alloc] initWithDelegate:self];
  
  [self createDeepLinkBanner];
  if (_deeplinkURL != nil) {
    [self updateDeepLinkLabel:_deeplinkURL];
  }
  
  if (![[NSUserDefaults standardUserDefaults] stringForKey:kCurrentSelectedApp]) {
    [[NSUserDefaults standardUserDefaults] setValue:@"Hackbook Default" forKey:kCurrentSelectedApp];
  } else {
    NSDictionary *newAppData = _appsData[[[NSUserDefaults standardUserDefaults] stringForKey:kCurrentSelectedApp]];
    [[FBSDKSettings sharedSettings] setAppID:newAppData[@"App_ID"]];
  }
}

- (void)viewWillAppear:(BOOL)animated
{
  [self.navigationController setToolbarHidden:NO animated:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];

  NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
  [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
  
  if (@available(iOS 14, *)) {
    [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status){}];
  }
}

- (void)viewWillDisappear:(BOOL)animated
{
  [self.navigationController setToolbarHidden:YES animated:YES];
}

- (NSArray<NSString *> *)cellTitles
{
  return @[
    @"Re-authorize Data Access",
    @"De-authorize App",
    @"App ID:",
    @"Facebook Domain",
    @"Graph API Version",
    @"Settings",
    @"Permission Setting",
    @"Share",
    @"Game Request",
    @"Game Services",
    @"Privacy Toggles",
    @"Graph API",
    @"Camera",
    @"Access Token",
    @"Device Login",
    @"App Link",
    @"Login Features",
    @"AEM",
    @"SKAN",
    @"IAB",
  ];
}

#pragma mark - UITableView Data Source & Delegate
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *identifier = @"MainCell";
  NSArray *titles = [self cellTitles];

  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
  }
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  UILabel *centerLabel = [cell.contentView viewWithTag:100];
  if (!centerLabel) {
    centerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 36)];
    centerLabel.tag = 100;
    centerLabel.font = [UIFont systemFontOfSize:15];
    centerLabel.textAlignment = NSTextAlignmentCenter;
    centerLabel.textColor = [UIColor systemBlueColor];
    [cell.contentView addSubview:centerLabel];
  }

  if (indexPath.row < 2) {
    cell.textLabel.text = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = nil;
    centerLabel.hidden = NO;
    centerLabel.text = titles[indexPath.row];
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
  } else {
    centerLabel.hidden = YES;
    cell.textLabel.text = titles[indexPath.row];
  }
  cell.accessibilityIdentifier = nil;

  switch (indexPath.row) {
    case 2: {
      NSString *currentApp = [[NSUserDefaults standardUserDefaults] stringForKey:kCurrentSelectedApp];
      self.title = currentApp;
      NSString *currentAppID = _appsData[currentApp][@"App_ID"];
      cell.accessoryType = UITableViewCellAccessoryNone;
      cell.accessoryView = nil;
      cell.selectionStyle = UITableViewCellSelectionStyleDefault;
      cell.textLabel.text = [NSString stringWithFormat:@"App ID: %@", currentAppID];
      break;
    }
    case kFacebookDomainRowIndex:
    case kGraphAPIRowIndex: {
      UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 150, 30)];
      textField.borderStyle = UITextBorderStyleRoundedRect;
      textField.delegate = self;
      textField.tag = indexPath.row;
      textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
      cell.accessoryView = textField;
      cell.accessoryType = UITableViewCellAccessoryNone;
      [textField addTarget:self action:@selector(onEditorEditingStart:) forControlEvents:UIControlEventEditingDidBegin];
      [textField addTarget:self action:@selector(onEditorEditingStart:) forControlEvents:UIControlEventTouchUpInside];
      if (kFacebookDomainRowIndex == indexPath.row) {
        textField.placeholder = @"ie: unixname.sb";
        textField.text = FBSDKSettings.sharedSettings.facebookDomainPart ?: @"facebook.com";
      } else {
        textField.placeholder = @"ie: v3.3";
        textField.text = FBSDKSettings.sharedSettings.graphAPIVersion;
      }
      break;
    }
    case 10: {
      // Set accessibility ID for privacy toggle
      cell.accessibilityIdentifier = @"cell_privacy_toggle";
      break;
    }
    case 16: {
      cell.accessibilityIdentifier = @"cell_login_features";
      break;
    }
    case 17: {
      // Set accessibility ID for AEM
      cell.accessibilityIdentifier = @"cell_aem";
      break;
    }
    case 18: {
      // Set accessibility ID for SKAN
      cell.accessibilityIdentifier = @"cell_skan";
      break;
    }
    case 19: {
      // Set accessibility ID for IAB
      cell.accessibilityIdentifier = @"cell_iab";
      break;
    }
    default: {
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      cell.accessoryView = nil;
    }
  }

  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  switch (indexPath.row) {
    case 0: {
      [self reauthorizeDataAccess];
      [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
      break;
    }
    case 1: {
      [self deauthorizeApp];
      [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
      break;
    }
    case 2: {
      CGFloat x = CGRectGetMidX(tableView.window.frame) - 150;
      CGFloat y = CGRectGetMidY(tableView.window.frame) - 200;
      AppSelectorPicker *appPicker = [[AppSelectorPicker alloc] initWithFrame:CGRectMake(x, y, 300, 400)];
      NSUInteger row = [_appsData.allKeys indexOfObject:[NSUserDefaults.standardUserDefaults stringForKey:kCurrentSelectedApp]];
      [appPicker selectRow:row inComponent:0 animated:false];
      appPicker.table = tableView;
      [self.view addSubview:appPicker];
      break;
    }
    case 5: {
      UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Settings" bundle:nil];
      UIViewController *vc = [storyboard instantiateInitialViewController];
      [self.navigationController pushViewController:vc animated:YES];
      break;
    }
    case 6: {
      PermissionsViewController *permissionsViewController = [[PermissionsViewController alloc] init];
      permissionsViewController.delegate = self;
      permissionsViewController.selectedPermissions = _selectedPermissions;
      [self.navigationController pushViewController:permissionsViewController animated:YES];
      break;
    }
    case 7: {
      ShareViewController *shareVC = [[ShareViewController alloc] init];
      [self.navigationController pushViewController:shareVC animated:YES];
      break;
    }
    case 14: {
      UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Hackbook" bundle:nil];
      DeviceLoginViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"Passwordless"];
      viewController.selectedPermissions = loginButton.permissions;
      [self.navigationController pushViewController:viewController animated:YES];
      break;
    }
    case 10: {
      PrivacyToggleViewController *privacyToggleVC = [[PrivacyToggleViewController alloc] init];
      [self.navigationController pushViewController:privacyToggleVC animated:YES];
      break;
    }
    case 16: {
      UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"LoginFeatures" bundle:nil];
      LoginViewController *viewController = [storyboard instantiateInitialViewController];

      viewController.selectedPermissions = [self normalizedPermissionsForLoginFeatures];
      [self.navigationController pushViewController:viewController animated:YES];
      break;
    }
    case 17: {
      AEMViewController *AEMVC = [[AEMViewController alloc] init];
      [self.navigationController pushViewController:AEMVC animated:YES];
      break;
    }
    case 18: {
      SKANViewController *SKANVC = [[SKANViewController alloc] init];
      [self.navigationController pushViewController:SKANVC animated:YES];
      break;
    }
    case 19: {
      UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"TestWKWebView" bundle:nil];
      UIViewController *vc = [storyboard instantiateInitialViewController];
      [self.navigationController pushViewController:vc animated:YES];
      break;
    }
    default: {
      if (indexPath.row > 7) {
        NSArray<NSString *> *identifiers = @[@"GameRequest", @"GamingServices", @"", @"GraphAPI", @"Camera", @"AccessToken", @"", @"AppLink"];
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Hackbook" bundle:nil];
        UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:identifiers[indexPath.row - 8]];
        [self.navigationController pushViewController:vc animated:YES];
      }
      break;
    }
  }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return [self cellTitles].count;
}

- (void)viewDidLayoutSubviews
{
  [super viewDidLayoutSubviews];
  deepLinkURLLabel.frame  = CGRectInset(_tableFooter.bounds, marginXForBanner, marginYForBanner);
}

#pragma mark - Actions

- (void)reauthorizeDataAccess
{
  FBSDKLoginManagerLoginResultBlock completionHandler = ^(FBSDKLoginManagerLoginResult *result, NSError *error) {
    if (error) {
      ConsoleError(error, @"Error renewing data access.");
    } else {
      ConsoleLog(@"Successfully renewed data access.");
    }
  };
  [_loginManager reauthorizeDataAccess:self handler:completionHandler];
}

- (void)deauthorizeApp
{
  FBSDKGraphRequestCompletion completionHandler = ^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {
    if (error) {
      ConsoleError(error, @"Error de-authorizing app");
    } else {
      // Simulate a logout action
      FBSDKAccessToken.currentAccessToken = nil;
      FBSDKAuthenticationToken.currentAuthenticationToken = nil;
      FBSDKProfile.currentProfile = nil;
      ConsoleLog(@"Successfully de-authorized app");
    }
  };
  [[[FBSDKGraphRequest alloc] initWithGraphPath:@"/me/permissions"
                                     parameters:@{}
                                    tokenString:[FBSDKAccessToken currentAccessToken].tokenString
                                        version:nil
                                     HTTPMethod:FBSDKHTTPMethodDELETE] startWithCompletion:completionHandler];
  ConsoleLog(@"starting deauthorize");
}

- (IBAction)onEditorEditingStart:(UITextField *)sender
{
  [sender setTextAlignment:NSTextAlignmentLeft];
}

- (IBAction)selectVersion:(id)sender
{
  NSString *const versionInfo = [NSString stringWithFormat:@"HBiOS %@", versionButton.title];
  ConsoleLog(@"%@", versionInfo);
  [[UIPasteboard generalPasteboard] setString:versionInfo];
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField
{
  [theTextField resignFirstResponder];
  [theTextField setTextAlignment:NSTextAlignmentRight];
  if (theTextField.tag == kFacebookDomainRowIndex) {
    return [self _updateDomain:theTextField];
  }
  if (theTextField.tag == kGraphAPIRowIndex) {
    return [self _updateGraphAPIVersion:theTextField];
  }
  return YES;
}

- (BOOL)_updateDomain:(UITextField *)theTextField
{
  NSString *text = [[theTextField.text lowercaseString]
                    stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  NSString *subdomain = NULL;
  NSRange searchResult = [text rangeOfString:FacebookBaseDomain];
  if (searchResult.location == NSNotFound) {
    subdomain = text;
  } else {
    subdomain = searchResult.location > 0 ? [text substringToIndex:searchResult.location - 1] : @"";
  }
  if (![subdomain length]) {
    subdomain = nil;
  }
  FBSDKSettings.sharedSettings.facebookDomainPart = subdomain;
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:subdomain forKey:FacebookDomainPart];

  theTextField.text = FBSDKSettings.sharedSettings.facebookDomainPart ?: FacebookBaseDomain;
  return YES;
}

- (BOOL)_updateGraphAPIVersion:(UITextField *)theTextField
{
  NSString *text = [[theTextField.text lowercaseString]
                    stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  NSString *graphAPIVersion = text.length > 0 ? text : nil;
  FBSDKSettings.sharedSettings.graphAPIVersion = graphAPIVersion;
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:graphAPIVersion forKey:GraphAPIVersion];
  theTextField.text = FBSDKSettings.sharedSettings.graphAPIVersion;
  return YES;
}

#pragma mark - PermissionsViewControllerDelegate

- (void)permissionsViewController:(PermissionsViewController *)permissionsViewController didDeselectPermission:(NSString *)permission
{
  [_selectedPermissions removeObject:permission];
  [self _configureSettings];
}

- (void)permissionsViewController:(PermissionsViewController *)permissionsViewController didSelectPermission:(NSString *)permission
{
  [_selectedPermissions addObject:permission];
  [self _configureSettings];
}

#pragma mark - Helper Methods

- (void)_configureSettings
{
  NSArray *publishPermissionOptions = _settingsData[@"Write"];
  NSArray *managedPublishPermissionOptions = _settingsData[@"Managed Write"];
  NSArray *privacyOptions = _settingsData[@"Write Privacy"];
  NSArray *blacklistedStrings = @[@"Browser"];

  FBSDKDefaultAudience defaultAudience = FBSDKDefaultAudienceEveryone;
  NSMutableArray *readPermissions = [[NSMutableArray alloc] init];
  NSMutableArray *publishPermissions = [[NSMutableArray alloc] init];
  for (NSString *optionValue in _selectedPermissions) {
    if ([blacklistedStrings containsObject:optionValue]) {
      continue;
    }

    if ([privacyOptions containsObject:optionValue]) {
      if ([optionValue isEqualToString:@"Only Me"]) {
        defaultAudience = FBSDKDefaultAudienceOnlyMe;
      } else if ([optionValue isEqualToString:@"Friends"]) {
        defaultAudience = FBSDKDefaultAudienceFriends;
      } else if ([optionValue isEqualToString:@"Everyone"]) {
        defaultAudience = FBSDKDefaultAudienceEveryone;
      } else {
        ConsoleLog(@"Invalid default audience found: %@", optionValue);
      }
    } else if ([publishPermissionOptions containsObject:optionValue]
               || [managedPublishPermissionOptions containsObject:optionValue]) {
      [publishPermissions addObject:optionValue];
    } else {
      [readPermissions addObject:optionValue];
    }
  }

  loginButton.permissions = [readPermissions arrayByAddingObjectsFromArray:publishPermissions];
  loginButton.defaultAudience = defaultAudience;
  NSString *messengerPageId = [loginButton.permissions containsObject:@"user_messenger_contact"] ? @"587694278589251" : NULL;
  if (messengerPageId) {
    loginButton.messengerPageId = messengerPageId;
  }
}

- (NSArray<NSString *> *)normalizedPermissionsForLoginFeatures
{
  NSArray *invalidOptions = @[
    @"Only Me",
    @"Friends",
    @"Everyone",
    @"Browser"
  ];
  NSMutableArray *permissions = [NSMutableArray array];
  for (NSString *permission in _selectedPermissions.allObjects) {
    if ([invalidOptions containsObject:permission]) {
      continue;
    }

    [permissions addObject:permission.lowercaseString];
  }
  return permissions;
}

#pragma mark - Deep links

- (void)createDeepLinkBanner
{
  _tableFooter = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 80)];
  _tableFooter.accessibilityIdentifier = @"deeplink_banner";
  deepLinkURLLabel = [[UILabel alloc] init];
  deepLinkURLLabel.accessibilityIdentifier = @"deeplink_link";
  deepLinkURLLabel.translatesAutoresizingMaskIntoConstraints = YES;
  deepLinkURLLabel.layer.borderWidth = 0.5;
  deepLinkURLLabel.layer.borderColor = UIColor.lightGrayColor.CGColor;
  deepLinkURLLabel.font = [UIFont systemFontOfSize:15];
  deepLinkURLLabel.textColor = [UIColor blackColor];
  deepLinkURLLabel.textAlignment = NSTextAlignmentCenter;
  deepLinkURLLabel.numberOfLines = 0;
  
  [_tableFooter addSubview:deepLinkURLLabel];

  self.tableView.tableFooterView = _tableFooter;
}

- (void)updateDeepLinkLabel:(NSURL *)url
{
  if (url != nil) {
    _deeplinkURL = url;
  }
  if (_deeplinkURL != nil) {
    deepLinkURLLabel.text = _deeplinkURL.absoluteString;
  }
}

#pragma mark - FBSDKLoginButtonDelegate

- (BOOL)loginButtonWillLogin:(FBSDKLoginButton *)loginButton
{
  ConsoleLog(@"Started login request");
  return YES;
}

- (void)loginButton:(FBSDKLoginButton *)loginButton didCompleteWithResult:(FBSDKLoginManagerLoginResult *)result error:(NSError *)error
{
  ConsoleLog(@"login request completed");
  ConsoleError(error, @"Login error");
}

- (void)loginButtonDidLogOut:(FBSDKLoginButton *)loginButton
{
  ConsoleLog(@"user logged out");
}

#pragma mark - FBSDKGamingPayloadDelegate

- (void)parsedGameRequestURLContaining:(FBSDKGamingPayload *)payload
                         gameRequestID:(NSString *_Nonnull)gameRequestID
{
  ConsoleLog(@"Parsed Gaming payload returned the following:\npayload: %@\ngameRequestID: %@", payload.payload, gameRequestID);
}

- (void)parsedTournamentURLContaining:(FBSDKGamingPayload *)payload
                         tournamentID:(NSString *_Nonnull)tournamentiD
{
  ConsoleLog(@"Parsed Gaming payload returned the following payload: %@, tournamentID: %@", payload.payload, tournamentiD);
}

@end
