// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <UIKit/UIKit.h>

@import FBSDKLoginKit;

NS_ASSUME_NONNULL_BEGIN

@interface DeviceLoginViewController : UITableViewController <FBSDKDeviceLoginManagerDelegate>

@property (nonatomic, copy) NSArray<NSString *> *selectedPermissions;

@end

NS_ASSUME_NONNULL_END
