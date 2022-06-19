// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "TestListViewController.h"

@import FBSDKCoreKit;
@import FBSDKLoginKit;

#import "Console.h"
#import "Utilities.h"

@implementation TestListViewController

#pragma mark - Public API

- (void)ensureReadPermission:(NSString *)permission usingBlock:(void (^)(void))block
{
  [self _ensurePermission:permission isPublishPermission:NO usingBlock:block];
}

- (void)ensurePublishPermission:(NSString *)permission usingBlock:(void (^)(void))block
{
  [self _ensurePermission:permission isPublishPermission:YES usingBlock:block];
}

- (void)executeGraphRequest:(FBSDKGraphRequest *)request completionBlock:(void (^)(NSDictionary *result))completionBlock
{
  [request startWithCompletion:^(id<FBSDKGraphRequestConnecting> connection, NSDictionary *result, NSError *error) {
    if (error) {
      ConsoleError(error, @"Error fetching graph data.");
      return;
    }
    if (![result isKindOfClass:[NSDictionary class]]) {
      ConsoleReportBug(@"Expected a dictionary response, but got %@.", [result class]);
      return;
    }
    completionBlock(result);
  }];
}

- (void)loadFriendsWithCompletionBlock:(void (^)(void))completionBlock force:(BOOL)force
{
  if (_friends) {
    if (completionBlock != NULL) {
      completionBlock();
    }
    return;
  }
  if (!force && ![FBSDKAccessToken currentAccessToken]) {
    return;
  }
  [self ensureReadPermission:@"user_friends" usingBlock:^{
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"/me/friends" parameters:@{@"fields" : @"id,name", @"limit" : @10}];
    [self executeGraphRequest:request completionBlock:^(NSDictionary *result) {
      NSArray *data = result[@"data"];
      if (![data isKindOfClass:[NSArray class]]) {
        ConsoleReportBug(@"Expected an array for data in response, but got %@.", [data class]);
        return;
      }
      if (!force) {
        if ([data count]) {
          ConsoleLog(@"Friends successfully loaded: %@", [data componentsJoinedByString:@", "]);
        } else {
          ConsoleLog(@"No friends found");
        }
      }
      self->_friends = [data copy];
      if (completionBlock != NULL) {
        completionBlock();
      }
    }];
  }];
}

- (void)markTestCompleteWithSender:(id)sender
{
  if (![sender isKindOfClass:[UIView class]]) {
    return;
  }
  UIView *view = (UIView *)sender;
  UITableViewCell *cell = nil;
  while (view && !cell) {
    if ([view isKindOfClass:[UITableViewCell class]]) {
      cell = (UITableViewCell *)view;
    } else {
      view = view.superview;
    }
  }
  cell.accessoryType = UITableViewCellAccessoryCheckmark;
}

- (void)markTestIncompleteWithSender:(id)sender
{
  if (![sender isKindOfClass:[UIView class]]) {
    return;
  }
  UIView *view = (UIView *)sender;
  UITableViewCell *cell = nil;
  while (view && !cell) {
    if ([view isKindOfClass:[UITableViewCell class]]) {
      cell = (UITableViewCell *)view;
    } else {
      view = view.superview;
    }
  }
  cell.accessoryType = UITableViewCellAccessoryNone;
}

#pragma mark - Helper Methods

- (void)_ensurePermission:(NSString *)permission
      isPublishPermission:(BOOL)isPublishPermission
               usingBlock:(void (^)(void))block
{
  if ([[FBSDKAccessToken currentAccessToken].permissions containsObject:permission]) {
    if (block) {
      block();
    }
  } else {
    FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
    FBSDKLoginManagerLoginResultBlock logInHandler = ^(FBSDKLoginManagerLoginResult *result, NSError *error) {
      if (error) {
        ConsoleError(error, @"Error authorizing user for %@ permission.", permission);
        return;
      }
      if (result.isCancelled) {
        ConsoleLog(@"User cancelled permissions dialog.");
        return;
      }
      if ([result.declinedPermissions containsObject:permission]) {
        ConsoleLog(@"User declined %@ permission.", permission);
        return;
      }
      if (![result.grantedPermissions containsObject:permission]) {
        ConsoleReportBug(
          @"Expected to find %@ permission granted, but only found %@",
          permission,
          [[result.grantedPermissions allObjects] componentsJoinedByString:@", "]
        );
        return;
      }
      block();
    };

    [loginManager logInWithPermissions:@[permission] fromViewController:self handler:logInHandler];
  }
}

@end
