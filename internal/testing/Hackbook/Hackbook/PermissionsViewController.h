// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <UIKit/UIKit.h>

@protocol PermissionsViewControllerDelegate;

@interface PermissionsViewController : UITableViewController

@property (nonatomic, weak) id<PermissionsViewControllerDelegate> delegate;
@property (nonatomic, copy) NSSet *selectedPermissions;

@end

@protocol PermissionsViewControllerDelegate <NSObject>

- (void)permissionsViewController:(PermissionsViewController *)settingsViewController didDeselectPermission:(NSString *)permission;
- (void)permissionsViewController:(PermissionsViewController *)settingsViewController didSelectPermission:(NSString *)permission;

@end
