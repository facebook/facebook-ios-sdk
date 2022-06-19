// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "SettingsItemViewController.h"

#import "ManageDataSharingViewController.h"

@interface SettingsItemViewController ()

@end

@implementation SettingsItemViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  myArray = [[NSMutableArray alloc]initWithObjects:
             @"Profile", @"About Coffee Shop", @"Terms of Use",
             @"Privacy Policy", @"Manage Data Sharing", nil];
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
  CGSize resize = CGSizeMake(25, 25);
  UIImage *image = [self imageWithImage:[UIImage imageNamed:@"rightChevron"] scaledToSize:resize];
  UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
  cell.accessoryView = imageView;
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
  if ([cell.textLabel.text isEqual:@"Manage Data Sharing"]) {
    UIViewController *vc = [[ManageDataSharingViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
  }
  NSLog(
    @"Section:%ld Row:%ld selected and its data is %@",
    (long)indexPath.section,
    (long)indexPath.row,
    cell.textLabel.text
  );
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
  UIGraphicsBeginImageContext(newSize);
  [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
  UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return newImage;
}

@end
