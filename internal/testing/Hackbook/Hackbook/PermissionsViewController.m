// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "PermissionsViewController.h"

#import "Utilities.h"

#define APP_SECRET_SECTION 0
#define PERMISSIONS_SETTINGS_SECTION 1

#define APP_SECRET_TEXTFIELD_TAG 7

@interface PermissionsViewController () <UITextFieldDelegate>
@end

@implementation PermissionsViewController
{
  NSMutableSet *_selectedOptions;
  NSDictionary *_settingsData;
  NSSet<NSString *> *_singleSelectSections;
}

#pragma mark - Properties

- (NSSet *)selectedPermissions
{
  return [_selectedOptions copy];
}

- (void)setSelectedPermissions:(NSSet *)selectedOptions
{
  if (![_selectedOptions isEqualToSet:selectedOptions]) {
    _selectedOptions = [[NSMutableSet alloc] initWithSet:selectedOptions];
  }
}

#pragma mark - View Management

- (void)viewDidLoad
{
  self.title = @"Permission Setting";
  [super viewDidLoad];

  if (!_selectedOptions) {
    _selectedOptions = [[NSMutableSet alloc] init];
  }

  if (!_singleSelectSections) {
    _singleSelectSections = [NSSet setWithArray:@[@"Login Behavior", @"Write Privacy"]];
  }

  if (!_settingsData) {
    NSURL *URL = [[NSBundle mainBundle] URLForResource:@"settings" withExtension:@"plist"];
    _settingsData = [[NSDictionary alloc] initWithContentsOfURL:URL];
    NSMutableDictionary<NSString *, id> *sortedSettings = [[NSMutableDictionary alloc] initWithDictionary:_settingsData];

    for (NSString *section in _settingsData) {
      if ([_singleSelectSections containsObject:section]) {
        // Don't alphabetize these sections
        continue;
      }

      // Alphabetically sort the settings
      NSArray<NSString *> *settings = _settingsData[section];
      sortedSettings[section] = [settings sortedArrayUsingSelector:
                                 @selector(localizedCaseInsensitiveCompare:)];
    }

    _settingsData = sortedSettings;
  }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return [_settingsData count] + 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  if (section == APP_SECRET_SECTION) {
    return @"App Secret";
  }
  return [_settingsData allKeys][section - 1];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  if (section == APP_SECRET_SECTION) {
    return 1;
  }
  NSString *type = [self tableView:tableView titleForHeaderInSection:section];
  return [_settingsData[type] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.section == APP_SECRET_SECTION) {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"appSecretCell"];
    if (!cell) {
      cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"appSecretCell"];
      UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 200, 34)];
      cell.textLabel.text = @"App Secret";
      cell.accessoryView = textField;
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    UITextField *appSecretTextField = (UITextField *)cell.accessoryView;
    appSecretTextField.text = GetAppSecret();
    appSecretTextField.delegate = self;
    return cell;
  } else {
    static NSString *const CellIdentifier = @"permissionCell";

    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                   reuseIdentifier:CellIdentifier];
    NSString *option = [self _tableView:tableView optionForRowAtIndexPath:indexPath];
    cell.textLabel.text = option;
    if ([_selectedOptions containsObject:option]) {
      cell.accessoryType = UITableViewCellAccessoryCheckmark;
      cell.selected = YES;
    } else {
      cell.accessoryType = UITableViewCellAccessoryNone;
      cell.selected = NO;
    }

    return cell;
  }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITextField *appSecretTextField = (UITextField *)[self.view viewWithTag:APP_SECRET_TEXTFIELD_TAG];

  if (indexPath.section == APP_SECRET_SECTION) {
    [appSecretTextField becomeFirstResponder];
  } else {
    [self _tableView:tableView toggleOptionForRowAtIndexPath:indexPath];
    [appSecretTextField resignFirstResponder];
  }

  [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{}

#pragma mark - UITextField delegate

- (void)textFieldDidEndEditing:(UITextField *)textField
{
  SetAppSecret(textField.text);
}

#pragma mark - Helper Methods

- (void)_tableView:(UITableView *)tableView deselectPermission:(NSString *)permission forRowAtIndexPath:(NSIndexPath *)indexPath
{
  [_selectedOptions removeObject:permission];
  UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
  cell.accessoryType = UITableViewCellAccessoryNone;
  cell.selected = NO;
  [_delegate permissionsViewController:self didDeselectPermission:permission];
}

- (NSString *)_tableView:(UITableView *)tableView optionForRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSString *type = [self tableView:tableView titleForHeaderInSection:indexPath.section];
  return _settingsData[type][indexPath.row];
}

- (void)_tableView:(UITableView *)tableView selectPermission:(NSString *)permission forRowAtIndexPath:(NSIndexPath *)indexPath
{
  [_selectedOptions addObject:permission];
  UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
  cell.accessoryType = UITableViewCellAccessoryCheckmark;
  cell.selected = YES;
  [_delegate permissionsViewController:self didSelectPermission:permission];

  NSString *sectionTitle = [self tableView:tableView titleForHeaderInSection:indexPath.section];
  // The 2 sections below should be single select. Everything else - multi-select.
  if ([_singleSelectSections containsObject:sectionTitle]) {
    NSUInteger count = [self tableView:tableView numberOfRowsInSection:indexPath.section];
    for (NSUInteger i = 0; i < count; ++i) {
      if (i != indexPath.row) {
        NSIndexPath *checkIndexPath = [NSIndexPath indexPathForRow:i inSection:indexPath.section];
        NSString *checkOption = [self _tableView:tableView optionForRowAtIndexPath:checkIndexPath];
        if ([_selectedOptions containsObject:checkOption]) {
          [self _tableView:tableView deselectPermission:checkOption forRowAtIndexPath:checkIndexPath];
        }
      }
    }
  }
}

- (void)_tableView:(UITableView *)tableView toggleOptionForRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSString *option = [self _tableView:tableView optionForRowAtIndexPath:indexPath];
  NSString *type = [self tableView:tableView titleForHeaderInSection:indexPath.section];
  NSUInteger numberOfRows = [_settingsData[type] count];

  if ([_selectedOptions containsObject:option] && numberOfRows > 1) {
    [self _tableView:tableView deselectPermission:option forRowAtIndexPath:indexPath];
  } else {
    [self _tableView:tableView selectPermission:option forRowAtIndexPath:indexPath];
  }
}

@end
