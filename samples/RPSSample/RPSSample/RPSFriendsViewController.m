/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "RPSFriendsViewController.h"

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <FBSDKShareKit/FBSDKShareKit.h>

@interface RPSFriendsViewController () <UIAlertViewDelegate, UITableViewDelegate, UITableViewDataSource>
@end

@implementation RPSFriendsViewController
{
  NSMutableArray *_tableData;
  BOOL _isPerformingLogin;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    _isPerformingLogin = NO;
    self.title = NSLocalizedString(@"Rock w/Friends", @"Rock w/Friends");
  }

  return self;
}

#pragma mark - View lifecycle

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];

  if (!_isPerformingLogin) {
    // Login with read permssions
    FBSDKAccessToken *accessToken = FBSDKAccessToken.currentAccessToken;
    if (![accessToken.permissions containsObject:@"user_friends"]) {
      FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
      _isPerformingLogin = YES;
      [loginManager logInWithPermissions:@[@"user_friends"]
                      fromViewController:self
                                 handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
                                   _isPerformingLogin = NO;
                                   if (error) {
                                     NSLog(@"Failed to login:%@", error);
                                     return;
                                   }

                                   FBSDKAccessToken *newToken = FBSDKAccessToken.currentAccessToken;
                                   if (![newToken.permissions containsObject:@"user_friends"]) {
                                     // Show alert
                                     UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Login Failed"
                                                                                         message:@"You must login and grant access to your friends list to use this feature"
                                                                                        delegate:self
                                                                               cancelButtonTitle:@"OK"
                                                                               otherButtonTitles:nil];
                                     [alertView show];
                                     [self.navigationController popToRootViewControllerAnimated:YES];
                                     return;
                                   }
                                   [self updateFriendsTable];
                                 }];
    } else {
      [self updateFriendsTable];
    }
  }
}

#pragma makr - InvitFriends Button

- (IBAction)tapChallengeFriends:(id)sender
{
  FBSDKGameRequestDialog *gameRequestDialog = [[FBSDKGameRequestDialog alloc] init];
  FBSDKGameRequestContent *content = [[FBSDKGameRequestContent alloc] init];
  content.title = @"Challenge a Friend";
  content.message = @"Please come play RPS with me!";
  gameRequestDialog.content = content;
  [gameRequestDialog show];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return [_tableData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *const simpleTableIdentifier = @"SimpleTableItem";

  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];

  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
  }

  // Don't have the cell highlighted since we use the checkmark instead
  cell.selectionStyle = UITableViewCellSelectionStyleNone;

  NSDictionary *data = [_tableData objectAtIndex:indexPath.row];
  cell.textLabel.text = data[@"name"];
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
  cell.accessoryType = UITableViewCellAccessoryCheckmark;

  self.activityTextView.text = @"Loading...";
  NSDictionary *user = [_tableData objectAtIndex:[indexPath row]];
  [self updateActivityForID:user[@"id"]];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
}

#pragma mark - private methods

- (void)updateFriendsTable
{
  // We limit the friends list to only 50 results for this sample. In production you should
  // use paging to dynamically grab more users.
  NSDictionary *parameters = @{
    @"fields" : @"name",
    @"limit" : @"50"
  };
  // This will only return the list of friends who have this app installed
  FBSDKGraphRequest *friendsRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me/friends"
                                                                        parameters:parameters];
  FBSDKGraphRequestConnection *connection = [[FBSDKGraphRequestConnection alloc] init];
  [connection addRequest:friendsRequest
       completionHandler:^(FBSDKGraphRequestConnection *innerConnection, NSDictionary *result, NSError *error) {
         if (error) {
           NSLog(@"%@", error);
           return;
         }

         if (result) {
           NSArray *data = result[@"data"];
           _tableData = [data copy];
           [_tableView reloadData];
         }
       }];
  // start the actual request
  [connection start];
}

// This is the workhorse method of this view. It updates the textView with the activity of a given user. It
// accomplishes this by fetching the "throw" actions for the selected user.
- (void)getActivityForID:(NSString *)fbid callback:(void (^)(NSMutableArray *))callback
{
  NSInteger __block pendingRequestCount = 0;
  NSMutableArray *selectedUserActiviy = [NSMutableArray array];
  FBSDKGraphRequestConnection *connection = [[FBSDKGraphRequestConnection alloc] init];

  // Get the results for plays posted to Facebook explicitly.
  FBSDKGraphRequest *playActivityRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:[NSString stringWithFormat:@"%@/fb_sample_rps:throw", fbid]
                                                                             parameters:@{
                                              @"fields" : @"data,publish_time",
                                              @"limit" : @"10",
                                              @"date_format" : @"U"
                                            }];
  ++pendingRequestCount;
  [connection addRequest:playActivityRequest
       completionHandler:^(FBSDKGraphRequestConnection *innerConnection, id playActivity, NSError *error) {
         if (error) {
           NSLog(@"Failed get fb_sample_rps:throw activities for user '%@': %@", fbid, error);
         } else if (playActivity) {
           for (id entry in playActivity[@"data"]) {
             NSString *gesture = entry[@"data"][@"gesture"][@"title"];
             NSString *opposing_gesture = entry[@"data"][@"opposing_gesture"][@"title"];
             [selectedUserActiviy addObject:@{
                @"publish_date" : [self getDateFromEpochTime:entry[@"publish_time"]],
                @"player_gesture" : gesture,
                @"opponent_gesture" : opposing_gesture
              }];
           }
         }
         if (--pendingRequestCount == 0) {
           callback(selectedUserActiviy);
         }
       }];

  FBSDKGraphRequest *gameActivityRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:[NSString stringWithFormat:@"%@/fb_sample_rps:play", fbid]
                                                                             parameters:@{
                                              @"fields" : @"data,publish_time",
                                              @"limit" : @"10",
                                              @"date_format" : @"U",
                                            }];
  ++pendingRequestCount;
  [connection addRequest:gameActivityRequest
          batchEntryName:@"games-post"
       completionHandler:^(FBSDKGraphRequestConnection *innerConnection, id result, NSError *error) {
         if (error) {
           NSLog(@"Failed to get game activity %@:", error);
         }
         if (--pendingRequestCount == 0) {
           callback(selectedUserActiviy);
         }
       }
  ];
  // A batch request that id dependent on the previous result
  FBSDKGraphRequest *gameData = [[FBSDKGraphRequest alloc] initWithGraphPath:@"?ids={result=games-post:$.data.*.data.game.id}"
                                                                  parameters:@{
                                   @"fields" : @"data,created_time",
                                   @"date_format" : @"U",
                                 }];
  ++pendingRequestCount;
  [connection addRequest:gameData completionHandler:^(FBSDKGraphRequestConnection *innerConnection, id games, NSError *innerError) {
    if (innerError) {
      // ignore code 2500 errors since that indicates the parent games-post error was empty.
      if ([innerError.userInfo[FBSDKGraphRequestErrorGraphErrorCodeKey] integerValue] != 2500) {
        NSLog(@"Failed to get detailed game data for 'play' objects: %@", innerError);
      }
    } else if (games) {
      for (id gameKey in games) {
        NSDictionary *game = games[gameKey];
        NSString *player_gesture = game[@"data"][@"player_gesture"][@"title"];
        NSString *opponent_gesture = game[@"data"][@"opponent_gesture"][@"title"];
        [selectedUserActiviy addObject:@{
           @"publish_date" : [self getDateFromEpochTime:game[@"created_time"]],
           @"player_gesture" : player_gesture,
           @"opponent_gesture" : opponent_gesture
         }];
      }
    }
    if (--pendingRequestCount == 0) {
      callback(selectedUserActiviy);
    }
  }];

  [connection start];
}

- (NSDate *)getDateFromEpochTime:(NSString *)time
{
  NSInteger publishTime = [time integerValue];
  return [NSDate dateWithTimeIntervalSince1970:publishTime];
}

- (void)updateActivityForID:(NSString *)fbid
{
  if (!fbid) {
    self.activityTextView.text = @"No User Selected";
    return;
  }

  // keep track of the selction
  [self getActivityForID:fbid callback:^(NSMutableArray *activity) {
    // sort the array by date
    [activity sortUsingComparator:^NSComparisonResult (id obj1,
                                                       id obj2) {
                                                         NSDate *obj1Date = obj1[@"publish_date"];
                                                         NSDate *obj2Date = obj2[@"publish_date"];
                                                         if (obj1Date && obj2Date) {
                                                           return [obj2Date compare:obj1Date];
                                                         }
                                                         return NSOrderedSame;
                                                       }];

    NSMutableString *output = [NSMutableString string];
    for (id entry in activity) {
      NSDateComponents *c = [NSCalendar.currentCalendar
                             components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear
                             fromDate:entry[@"publish_date"]];
      NSString *gesture = entry[@"player_gesture"];
      NSString *opposing_gesture = entry[@"opponent_gesture"];
      [output appendFormat:@"%02li/%02li/%02li - %@ %@ %@\n",
       (long)c.month,
       (long)c.day,
       (long)c.year,
       gesture,
       @"vs",
       opposing_gesture];
    }
    self.activityTextView.text = output;
  }];
}

@end
