// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "GraphReadTestViewController.h"

@import FBSDKCoreKit;
@import FBSDKLoginKit;

#import "Console.h"
#import "Utilities.h"

@implementation GraphReadTestViewController

#pragma mark - Actions

- (void)fetchFriends:(id)sender
{
  [FBSDKAppEvents.shared logEvent:@"click_get_friends"];
  [self loadFriendsWithCompletionBlock:^{
          ConsoleSucceed(@"Friends successfully fetched: %@", [self.friends componentsJoinedByString:@", "]);
          [self markTestCompleteWithSender:sender];
        } force:YES];
}

- (void)fetchMe:(id)sender
{
  [FBSDKAppEvents.shared logEvent:@"click_get_info"];
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"/me" parameters:@{}];
  [self executeGraphRequest:request completionBlock:^(NSDictionary *result) {
    ConsoleSucceed(@"User information successfully fetched: %@", StringForJSONObject(result));
    [self markTestCompleteWithSender:sender];
  }];
}

- (void)fetchPermissions:(id)sender
{
  [FBSDKAppEvents.shared logEvent:@"click_get_permissions"];
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"/me/permissions" parameters:@{}];
  [self executeGraphRequest:request completionBlock:^(NSDictionary *result) {
    ConsoleSucceed(@"User permissions successfully fetched: %@", StringForJSONObject(result));
    [self markTestCompleteWithSender:sender];
  }];
}

- (void)fetchDeprecatedUserInfo:(id)sender
{
  [FBSDKAppEvents.shared logEvent:@"click_get_permissions"];
  NSDictionary *parameters = @{@"fields" : @"cover,currency,devices,is_verified,third_party_id,updated_time,verified"};
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:parameters];
  [self executeGraphRequest:request completionBlock:^(NSDictionary *result) {
    ConsoleSucceed(@"Deprecated User permissions successfully fetched: %@", StringForJSONObject(result));
    [self markTestCompleteWithSender:sender];
  }];
}

- (void)makeTestBatchRequest:(id)sender
{
  FBSDKGraphRequest *meRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:@"/me" parameters:@{}];
  FBSDKGraphRequest *permissionsRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:@"/me/permissions" parameters:@{}];
  FBSDKGraphRequestConnectionFactory *connectionFactory = [FBSDKGraphRequestConnectionFactory new];
  id<FBSDKGraphRequestConnecting> connection = [connectionFactory createGraphRequestConnection];
  [connection addRequest:meRequest completion:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {
    if (error) {
      ConsoleError(error, @"Failed to fetch user information in non-app events batch request");
    } else {
      ConsoleSucceed(@"Successfully fetched user information in non-app events batch request");
    }
  }];
  [connection addRequest:permissionsRequest completion:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {
    if (error) {
      ConsoleError(error, @"Failed to fetch user permissions in non-app events batch request");
    } else {
      ConsoleSucceed(@"Successfully fetched user permissions in non-app events batch request");
    }
  }];
  [connection start];
}

@end
