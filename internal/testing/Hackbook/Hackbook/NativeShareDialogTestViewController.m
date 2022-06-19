// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "NativeShareDialogTestViewController.h"

// @lint-ignore CLANGTIDY
#import "Hackbook-Swift.h"
#import "Utilities.h"

NSString *const kFBSDKShareDialogMode = @"FBSDKShareDialogMode";

const FBSDKShareDialogMode _shareDialogModeItems[] = {
  FBSDKShareDialogModeAutomatic,
  FBSDKShareDialogModeNative,
  FBSDKShareDialogModeShareSheet,
  FBSDKShareDialogModeBrowser,
  FBSDKShareDialogModeWeb,
  FBSDKShareDialogModeFeedBrowser,
  FBSDKShareDialogModeFeedWeb,
};
const size_t _shareDialogModeCount = sizeof(_shareDialogModeItems) / sizeof(_shareDialogModeItems[0]);

@implementation NativeShareDialogTestViewController
{
  FBSDKShareDialogMode _mode;
}

- (FBSDKShareDialogMode)mode
{
  return _mode;
}

- (void)setMode:(FBSDKShareDialogMode)mode
{
  _mode = mode;
}

#pragma mark - View Management

- (void)viewDidLoad
{
  [super viewDidLoad];

  _mode = _shareDialogModeItems[0];
  NSInteger defaultMode = [[NSUserDefaults standardUserDefaults] integerForKey:kFBSDKShareDialogMode];
  for (size_t i = 0; i < _shareDialogModeCount; i++) {
    if (_shareDialogModeItems[i] == defaultMode) {
      _mode = defaultMode;
      break;
    }
  }
  [[self modeButton] setTitle:[ShareDialogModeHelper descriptionForMode:self.mode]];
  [[self modeButton] setAccessibilityIdentifier:@"mode-button"];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  [self.navigationController setToolbarHidden:NO animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];

  [self.navigationController setToolbarHidden:YES animated:YES];
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
  UIView *const subview = cell.contentView.subviews.firstObject;
  if ([subview isKindOfClass:[UIButton class]]) {
    NSString *const title = [(UIButton *)subview titleForState:UIControlStateNormal];
    NSString *const truncatedTitle = AsciiString(title);
    NSString *const selectorName = [NSString stringWithFormat:@"canShare%@", truncatedTitle];
    const SEL selector = NSSelectorFromString(selectorName);
    if ([self respondsToSelector:selector]) {
      const IMP imp = [self methodForSelector:selector];
      BOOL (*invoke)(id, SEL) = (void *)imp;
      const BOOL canShare = invoke(self, selector);
      UIColor *const titleColor = (canShare
        ? [truncatedTitle hasPrefix:@"OpenGraph"] ? [UIColor redColor] : tableView.tintColor
        : [UIColor lightGrayColor]);
      [(UIButton *)subview setTitleColor:titleColor forState:UIControlStateNormal];
    }
  }
}

#pragma mark - SharingDialogViewController Methods

- (NSString *)appEventsPrefix
{
  return @"Share_Native";
}

- (id<FBSDKSharingDialog>)buildDialog
{
  FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] initWithViewController:self
                                                                      content:nil
                                                                     delegate:nil];
  dialog.mode = _mode;
  return dialog;
}

#pragma mark - Actions

- (IBAction)selectMode:(id)sender
{
  UIAlertController *alertController = [UIAlertController
                                        alertControllerWithTitle:nil
                                        message:nil
                                        preferredStyle:UIAlertControllerStyleActionSheet];

  __weak typeof(self) weakSelf = self;

  for (size_t i = 0; i < _shareDialogModeCount; i++) {
    FBSDKShareDialogMode mode = _shareDialogModeItems[i];
    NSString *title = [ShareDialogModeHelper descriptionForMode:mode];
    UIAlertAction *modeAction =
    [UIAlertAction actionWithTitle:title
                             style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction *alertAction) {
                             __strong typeof(self) strongSelf = weakSelf;
                             if (strongSelf
                                 && [strongSelf mode] != mode) {
                               [strongSelf setMode:mode];
                               [[strongSelf modeButton] setTitle:title]; // update title of mode button

                               // update enabled/disabled state of options
                               [self.tableView beginUpdates];
                               [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
                               [self.tableView endUpdates];

                               [[NSUserDefaults standardUserDefaults] setInteger:mode forKey:kFBSDKShareDialogMode]; // track the selection
                             }
                           }];
    [alertController addAction:modeAction];
  }

  UIAlertAction *cancelAction = [UIAlertAction
                                 actionWithTitle:@"Cancel"
                                 style:UIAlertActionStyleCancel
                                 handler:nil];
  [alertController addAction:cancelAction];

  UIPopoverPresentationController *popoverPresentationController = [alertController popoverPresentationController];
  popoverPresentationController.barButtonItem = (UIBarButtonItem *)sender;
  popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionDown;

  [self presentViewController:alertController animated:YES completion:nil];
}

@end
