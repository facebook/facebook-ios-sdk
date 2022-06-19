// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SettingsItemViewController : UITableViewController
{
  IBOutlet UITableView *myTable;
  NSMutableArray *myArray;
}

@end
NS_ASSUME_NONNULL_END
