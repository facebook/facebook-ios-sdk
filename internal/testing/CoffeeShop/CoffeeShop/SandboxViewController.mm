// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "SandboxViewController.h"

#include <array>

static NSString *const kSandboxNoOverride = @"No override specified.";
static NSString *const kSandboxesCacheKey = @"recentSandboxesCacheKey";

NSString *const kSandboxOverrideKey = @"sandboxOverrideKey";

typedef NS_ENUM(int, SandboxSectionType) {
  // This section should only have 1 element:
  //
  // A. A placeholder (if no override is specified)
  // B. The current sandbox (with a tap to remove button).
  SandboxSectionTypeSelectedOverride = 0,

  // Used Sandboxes
  SandboxSectionTypeHistory = 1,

  // Make sure this is last... always.
  SandboxSectionTypeCount = 2,
};

@interface SandboxViewController ()
<UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
@end

@implementation SandboxViewController
{
  UILabel *_label;
  UITextField *_textField;
  UITableView *_tableView;
  NSString *_currentSandbox;
  std::array<NSMutableOrderedSet<NSString *> *, SandboxSectionTypeCount> _dataSource;
}

- (instancetype)init
{
  if ((self = [super init])) {
    _dataSource[SandboxSectionTypeSelectedOverride] = [NSMutableOrderedSet new];
    _dataSource[SandboxSectionTypeHistory] = [NSMutableOrderedSet new];
    _currentSandbox = [[NSUserDefaults standardUserDefaults] stringForKey:kSandboxOverrideKey];
    if (_currentSandbox.length > 0) {
      [_dataSource[SandboxSectionTypeSelectedOverride] addObject:_currentSandbox];
    } else {
      [_dataSource[SandboxSectionTypeSelectedOverride] addObject:kSandboxNoOverride];
    }
    NSArray<NSString *> *const savedSandboxes =
    [[NSUserDefaults standardUserDefaults] stringArrayForKey:kSandboxesCacheKey];
    if (savedSandboxes.count > 0) {
      [_dataSource[SandboxSectionTypeHistory] addObjectsFromArray:savedSandboxes];
    }
  }

  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self setTitle:@"Set Sandbox"];
  self.view.backgroundColor = [UIColor whiteColor];

  _label = [[UILabel alloc] initWithFrame:CGRectZero];
  _label.text = @"If this is your first time connecting to sandbox, please do the following steps:\n1. Run 'Tools/install_simulator_certs.sh' in your terminal.\n2. Once your simulator is running, open Settings and navigate to General > About > Certificate Trust Settings to trust the certificates.";
  _label.textColor = [UIColor blackColor];
  _label.numberOfLines = 0;
  // [_label sizeToFit];
  [self.view addSubview:_label];

  _textField = [[UITextField alloc] initWithFrame:CGRectZero];
  _textField.delegate = self;
  _textField.borderStyle = UITextBorderStyleRoundedRect;
  _textField.placeholder = @"Enter a new sandbox...";
  [self.view addSubview:_textField];

  _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
  _tableView.showsVerticalScrollIndicator = NO;
  _tableView.showsHorizontalScrollIndicator = NO;
  _tableView.delegate = self;
  _tableView.dataSource = self;
  [self.view addSubview:_tableView];
}

- (void)viewDidLayoutSubviews
{
  [super viewDidLayoutSubviews];
  const CGSize viewSize = self.view.bounds.size;
  const CGSize labelSize = [_label sizeThatFits:self.view.bounds.size];
  const CGRect labelFrame = CGRectMake(5, self.view.safeAreaInsets.top + 5, viewSize.width, labelSize.height);
  const CGRect textFieldFrame = CGRectMake(0, CGRectGetMaxY(labelFrame) + 10, viewSize.width, 36);

  _label.frame = labelFrame;
  _textField.frame = textFieldFrame;
  _tableView.frame = CGRectMake(0, CGRectGetMaxY(textFieldFrame), viewSize.width, viewSize.height - CGRectGetMaxY(textFieldFrame));
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
  NSString *const text = [[textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] lowercaseString];
  textField.text = nil;
  if (text.length == 0) {
    return NO;
  }
  [self _mutateRecentCache:^(NSMutableArray *cache) {
    if ([cache containsObject:text]) {
      return;
    }
    [cache addObject:text];
    [self->_dataSource[SandboxSectionTypeHistory] addObject:text];
  }];

  [_dataSource[SandboxSectionTypeSelectedOverride] removeAllObjects];
  [_dataSource[SandboxSectionTypeSelectedOverride] addObject:text];
  [FBSDKSettings.sharedSettings setFacebookDomainPart:text];
  [[NSUserDefaults standardUserDefaults] setObject:text forKey:kSandboxOverrideKey];
  [_tableView reloadData];
  return YES;
}

#pragma mark - UITableView

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *const cellID = @"sandboxCell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellID];
  }
  NSString *const text = _dataSource[indexPath.section][indexPath.row];
  cell.textLabel.text = text;
  cell.textLabel.numberOfLines = 1;

  if (indexPath.section == 0) {
    cell.textLabel.textColor = [UIColor redColor];
    cell.detailTextLabel.text = [text isEqualToString:kSandboxNoOverride]
    ? nil
    : @"Tap to Remove";
  } else {
    cell.textLabel.textColor = nil;
    cell.detailTextLabel.text = nil;
  }

  const BOOL isPlaceholder = [text isEqualToString:kSandboxNoOverride];
  cell.userInteractionEnabled = !isPlaceholder;

  return cell;
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView
                  editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSString *const text = _dataSource[indexPath.section][indexPath.row];
  if (indexPath.section == 1 && ![text isEqualToString:_currentSandbox]) {
    UITableViewRowAction *const a =
    [UITableViewRowAction
     rowActionWithStyle:UITableViewRowActionStyleDestructive
     title:@"delete"
     handler:^(UITableViewRowAction *_Nonnull action, NSIndexPath *_Nonnull deletedPath) {
       NSString *const deletedText = self->_dataSource[deletedPath.section][deletedPath.row];

       // Remove from DataSource
       [self->_dataSource[deletedPath.section] removeObjectAtIndex:deletedPath.row];

       // Remove from Cache
       [self _mutateRecentCache:^(NSMutableArray *cache) {
         [cache removeObject:deletedText];
       }];

       [tableView reloadSections:[NSIndexSet indexSetWithIndex:deletedPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
     }];
    return @[a];
  }
  return @[];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSString *const text = _dataSource[indexPath.section][indexPath.row];
  [_dataSource[SandboxSectionTypeSelectedOverride] removeAllObjects];
  NSUserDefaults *const defaults = [NSUserDefaults standardUserDefaults];

  BOOL sameAsCurrentOverride = [text isEqualToString:_currentSandbox];
  [_dataSource[SandboxSectionTypeSelectedOverride] addObject:sameAsCurrentOverride ? kSandboxNoOverride : text];
  [FBSDKSettings.sharedSettings setFacebookDomainPart:sameAsCurrentOverride ? @"" : text];
  [defaults setObject:sameAsCurrentOverride ? @"" : text forKey:kSandboxOverrideKey];
  _currentSandbox = sameAsCurrentOverride ? @"" : text;
  [tableView
   reloadSections:[NSIndexSet indexSetWithIndex:0]
   withRowAnimation:UITableViewRowAnimationAutomatic];

  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return _dataSource[section].count;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  if (section == 0) {
    return _dataSource[SandboxSectionTypeSelectedOverride].count > 0 ? @"Sandbox Override" : nil;
  } else if (section == 1) {
    return _dataSource[SandboxSectionTypeHistory].count > 0 ? @"History" : nil;
  }

  return nil;
}

#pragma mark - Private

- (void)_mutateRecentCache:(void (^)(NSMutableArray *cache))mutationBlock
{
  if (!mutationBlock) {
    return;
  }

  NSUserDefaults *const defaults = [NSUserDefaults standardUserDefaults];
  NSMutableArray<NSString *> *const recents =
  [[defaults stringArrayForKey:kSandboxesCacheKey] mutableCopy] ?: [NSMutableArray array];

  if (mutationBlock) {
    mutationBlock(recents);
  }
  [defaults setObject:recents forKey:kSandboxesCacheKey];
}

@end
