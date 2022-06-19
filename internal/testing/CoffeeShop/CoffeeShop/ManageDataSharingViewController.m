// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "ManageDataSharingViewController.h"

@interface ManageDataSharingViewController ()

@end

@implementation ManageDataSharingViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  myArray = [[NSMutableArray alloc]initWithObjects:
             @"nostrud exercitation", @"nostrud exercitation ullamco", nil];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

#pragma mark - Table View Data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:
  (NSInteger)section
{
  return [myArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:
  (NSIndexPath *)indexPath
{
  static NSString *cellId = @"SimpleTableId";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];

  if (cell == nil) {
    cell = [[UITableViewCell alloc]initWithStyle:
            UITableViewCellStyleDefault reuseIdentifier:cellId];
  }
  NSString *stringForCell = [myArray objectAtIndex:indexPath.row];
  [cell.textLabel setText:stringForCell];
  UISwitch *sw = [[UISwitch alloc] init];
  sw.onTintColor = [UIColor colorWithRed:0.0 green:122.0 / 255.0 blue:1.0 alpha:1.0];
  sw.on = YES;
  cell.accessoryView = sw;
  return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

#pragma mark - TableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:
  (NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
  NSLog(
    @"Section:%ld Row:%ld selected and its data is %@",
    (long)indexPath.section,
    (long)indexPath.row,
    cell.textLabel.text
  );
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
  UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, self.tableView.frame.size.width - 20, 180)];
  label.font = [UIFont boldSystemFontOfSize:15];
  label.textColor = [UIColor darkGrayColor];
  label.text = @"uis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Nam liber te conscient to factor tum poen legum odioque civiuda.";
  label.numberOfLines = 0;
  UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, self.tableView.frame.size.height)];
  [container addSubview:label];
  return container;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
  return 180;
}

@end
