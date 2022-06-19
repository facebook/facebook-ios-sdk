// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

@import FBSDKCoreKit;

#import "TestListViewController.h"

@interface TokenViewController : TestListViewController

@property (nonatomic, strong) IBOutlet UILabel *tokenStringLabel;
@property (nonatomic, strong) IBOutlet UILabel *dataAccessExpirationDateLabel;
@property (nonatomic, strong) IBOutlet UILabel *expirationDateLabel;
@property (nonatomic, strong) IBOutlet UILabel *grantedPermissionsLabel;
@property (nonatomic, strong) IBOutlet UILabel *declinedPermissionsLabel;
@property (nonatomic, strong) IBOutlet UILabel *expiredPermissionsLabel;
@property (nonatomic, strong) IBOutlet UILabel *graphDomainLabel;

- (IBAction)refreshToken:(id)sender;
- (IBAction)copyTokenToClipboard:(id)sender;

@end
