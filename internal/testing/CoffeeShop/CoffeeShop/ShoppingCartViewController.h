// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "Coffee.h"

NS_ASSUME_NONNULL_BEGIN

@interface ShoppingCartViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;

+ (void)appendItem:(Coffee *)item;

@end

NS_ASSUME_NONNULL_END
