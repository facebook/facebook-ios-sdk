/*
 * Copyright 2010 Facebook
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <UIKit/UIKit.h>
#import "FBConnect.h"
#import <CoreLocation/CoreLocation.h>

typedef enum apiCall {
    kAPILogout,
    kAPIGraphUserPermissionsDelete,
    kDialogPermissionsExtended,
    kDialogRequestsSendToMany,
    kAPIGetAppUsersFriendsNotUsing,
    kAPIGetAppUsersFriendsUsing,
    kAPIFriendsForDialogRequests,
    kDialogRequestsSendToSelect,
    kAPIFriendsForTargetDialogRequests,
    kDialogRequestsSendToTarget,
    kDialogFeedUser,
    kAPIFriendsForDialogFeed,
    kDialogFeedFriend,
    kAPIGraphUserPermissions,
    kAPIGraphMe,
    kAPIGraphUserFriends,
    kDialogPermissionsCheckin,
    kDialogPermissionsCheckinForRecent,
    kDialogPermissionsCheckinForPlaces,
    kAPIGraphSearchPlace,
    kAPIGraphUserCheckins,
    kAPIGraphUserPhotosPost,
    kAPIGraphUserVideosPost,
} apiCall;

@interface APICallsViewController : UIViewController
<FBRequestDelegate,
FBDialogDelegate,
UITableViewDataSource,
UITableViewDelegate,
CLLocationManagerDelegate>{
    int currentAPICall;
    NSUInteger childIndex;
    UITableView *apiTableView;
    NSMutableArray *apiMenuItems;
    NSString *apiHeader;
    NSMutableArray *savedAPIResult;
    CLLocationManager *locationManager;
    CLLocation *mostRecentLocation;
    UIActivityIndicatorView *activityIndicator;
    UILabel *messageLabel;
    UIView *messageView;
}

@property (nonatomic, retain) UITableView *apiTableView;
@property (nonatomic, retain) NSMutableArray *apiMenuItems;
@property (nonatomic, retain) NSString *apiHeader;
@property (nonatomic, retain) NSMutableArray *savedAPIResult;
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, retain) CLLocation *mostRecentLocation;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) UILabel *messageLabel;
@property (nonatomic, retain) UIView *messageView;

- (id)initWithIndex:(NSUInteger)index;

- (void)userDidGrantPermission;

- (void)userDidNotGrantPermission;

@end
