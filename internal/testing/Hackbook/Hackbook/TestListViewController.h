// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <UIKit/UIKit.h>

@import FBSDKCoreKit;

@interface TestListViewController : UITableViewController

@property (nonatomic, readonly, copy) NSArray *friends;

- (void)ensureReadPermission:(NSString *)permission usingBlock:(void (^)(void))block;
- (void)ensurePublishPermission:(NSString *)permission usingBlock:(void (^)(void))block;
- (void)executeGraphRequest:(FBSDKGraphRequest *)request completionBlock:(void (^)(NSDictionary *result))completionBlock;
- (void)loadFriendsWithCompletionBlock:(void (^)(void))completionBlock force:(BOOL)force;
- (void)markTestCompleteWithSender:(id)sender;
- (void)markTestIncompleteWithSender:(id)sender;

@end
