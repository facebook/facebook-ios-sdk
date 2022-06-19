// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#ifndef RELEASED_SDK_ONLY
#import "GameRequestDialogTestViewController.h"

@import FBSDKGamingServicesKit;
@import FBSDKShareKit;

@import FBSDKCoreKit;

#import "Console.h"
#import "Utilities.h"

@interface GameRequestDialogTestViewController () <FBSDKGameRequestDialogDelegate>
@end

@implementation GameRequestDialogTestViewController

#pragma mark - View Management

- (void)viewDidLoad
{
  [super viewDidLoad];

  [self loadFriendsWithCompletionBlock:NULL force:NO];
}

#pragma mark - Actions

- (void)gameRequestSuggestedFriends:(id)sender
{
  [FBSDKAppEvents.shared logEvent:@"click_Request_Suggested_Friends"];
  [self loadFriendsWithCompletionBlock:^{
          NSArray *friends = self.friends;
          NSUInteger friendCount = friends.count;
          if (!friendCount) {
            ConsoleSucceed(@"User has no friends!  Go make a few.");
            return;
          }
          FBSDKGameRequestContent *content = [[FBSDKGameRequestContent alloc] init];
          content.message = @"Learn how to make your iOS apps social.";
          content.recipientSuggestions = [[friends subarrayWithRange:NSMakeRange(0, MIN(friendCount, 5))] valueForKey:@"id"];
          content.title = @"App Request: Suggested List";
          [FBSDKGameRequestDialog showWithContent:content delegate:self];
        } force:YES];
}

- (void)gameRequestNoSuggestedFriends:(id)sender
{
  [FBSDKAppEvents.shared logEvent:@"click_Request_No_Suggested_Friends"];
  FBSDKGameRequestContent *content = [[FBSDKGameRequestContent alloc] init];
  content.message = @"Learn how to make your iOS apps social.";
  content.title = @"App Request: No Suggested List";
  content.filters = FBSDKGameRequestFilterEverybody;
  [FBSDKGameRequestDialog showWithContent:content delegate:self];
}

- (void)frictionlessRequest:(id)sender
{
  [FBSDKAppEvents.shared logEvent:@"click_Frictionless_Request"];
  [self loadFriendsWithCompletionBlock:^{
          NSUInteger friendCount = self.friends.count;
          if (!friendCount) {
            ConsoleSucceed(@"User has no friends!  Go make a few.");
            return;
          }

          FBSDKGameRequestContent *content = [[FBSDKGameRequestContent alloc] init];
          content.message = @"Learn how to make your iOS apps social.";
          content.title = @"Check this out";
          content.recipients = @[[self.friends[0] valueForKey:@"id"]];
          FBSDKGameRequestDialog *dialog = [FBSDKGameRequestDialog dialogWithContent:content delegate:self];
          dialog.isFrictionlessRequestsEnabled = YES;
          [dialog show];
        } force:YES];
}

#pragma mark - FBSDKGameRequestDialogDelegate

- (void)gameRequestDialog:(FBSDKGameRequestDialog *)gameRequestDialog didCompleteWithResults:(NSDictionary *)results
{
  ConsoleSucceed(@"Success: %@", StringForJSONObject(results));
}

- (void)gameRequestDialog:(FBSDKGameRequestDialog *)gameRequestDialog didFailWithError:(NSError *)error
{
  ConsoleError(error, @"Error");
}

- (void)gameRequestDialogDidCancel:(FBSDKGameRequestDialog *)gameRequestDialog
{
  ConsoleLog(@"Dialog cancelled");
}

@end
#endif
