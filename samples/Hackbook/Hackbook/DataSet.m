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

#import "DataSet.h"


@implementation DataSet

@synthesize apiConfigData = _apiConfigData;

/*
 * This class that defines the UI data for the app. The main menu, sub menus, and
 methods each menu calls are defined here.
 */
- (id)init {
    self = [super init];
    if (self) {

        _apiConfigData = [[NSMutableArray alloc] initWithCapacity:1];

        // Initialize the menu items

        // Login and Permissions
        NSDictionary *authMenu1 = [[NSDictionary alloc] initWithObjectsAndKeys:
                                   @"Logging the user out", @"title",
                                   @"You should include a button to enable the user to log out.", @"description",
                                   @"Logout", @"button",
                                   @"apiLogout", @"method",
                                   nil];
        NSDictionary *authMenu2 = [[NSDictionary alloc] initWithObjectsAndKeys:
                                   @"Uninstall app", @"title",
                                   @"You can include a button so that the user can uninstall your app.", @"description",
                                   @"Uninstall app", @"button",
                                   @"apiGraphUserPermissionsDelete", @"method",
                                   nil];

        NSDictionary *authMenu3 = [[NSDictionary alloc] initWithObjectsAndKeys:
                                   @"Asking for extended permissions", @"title",
                                   @"If your app needs more than this basic information to function, you must request specific permissions from the user. For example, you might prompt the user to access their Likes in order to recommend related content for them automatically.", @"description",
                                   @"Grant the 'user_likes' permission", @"button",
                                   @"apiPromptExtendedPermissions", @"method",
                                   nil];


        NSArray *authMenuItems = [[NSArray alloc] initWithObjects:
                                  authMenu1,
                                  authMenu2,
                                  authMenu3,
                                  nil];

        NSDictionary *authConfigData = [[NSDictionary alloc] initWithObjectsAndKeys:
                                        @"Login and Permissions", @"title",
                                        @"Facebook Platform uses the OAuth 2.0 protocol for logging a user into your app. The Login button at the start of this app is a good example.", @"description",
                                        @"http://developers.facebook.com/docs/authentication/", @"link",
                                        authMenuItems, @"menu",
                                        nil];

        [_apiConfigData addObject:authConfigData];

        [authMenu1 release];
        [authMenu2 release];
        [authMenu3 release];
        [authMenuItems release];
        [authConfigData release];

        // Requests
        NSDictionary *requestMenu1 = [[NSDictionary alloc] initWithObjectsAndKeys:
                                      @"Request", @"title",
                                      @"If you show the request dialog with no friend suggestions, it will automatically show friends that are using your app, as well as friends that have already used your app. ", @"description",
                                      @"Send request", @"button",
                                      @"apiDialogRequestsSendToMany", @"method",
                                      nil];
        NSDictionary *requestMenu2 = [[NSDictionary alloc] initWithObjectsAndKeys:
                                      @"Invite friends not using app", @"title",
                                      @"The user can invite their friends that have not started using your application yet. This will help grow your mobile website virally.", @"description",
                                      @"Send invite", @"button",
                                      @"getAppUsersFriendsNotUsing", @"method",
                                      nil];
        NSDictionary *requestMenu3 = [[NSDictionary alloc] initWithObjectsAndKeys:
                                      @"Request to app friends", @"title",
                                      @"If a friend of the active user needs to take an action in your mobile web app, you can prompt them to send a request. This can be used for re-engagement, like telling a friend it's their turn in a board game.", @"description",
                                      @"Send request", @"button",
                                      @"getAppUsersFriendsUsing", @"method",
                                      nil];
        NSDictionary *requestMenu4 = [[NSDictionary alloc] initWithObjectsAndKeys:
                                      @"Request to targeted friend", @"title",
                                      @"If the user's friends need to take an action in your mobile website, you can prompt them to send a request. This can be used for things like telling a friend it is their turn in a board game.", @"description",
                                      @"Send request", @"button",
                                      @"getUserFriendTargetDialogRequest", @"method",
                                      nil];
        NSDictionary *requestMenu5 = [[NSDictionary alloc] initWithObjectsAndKeys:
                                      @"Enable frictionless requests", @"title",
                                      @"To enable a no-prompt request and invite experience, enable frictionless requests.", @"description",
                                      @"Enable frictionless", @"button",
                                      @"enableFrictionlessAppRequests", @"method",
                                      nil];

        NSArray *requestMenuItems = [[NSArray alloc] initWithObjects:
                                     requestMenu1,
                                     requestMenu2,
                                     requestMenu3,
                                     requestMenu4,
                                     requestMenu5,
                                     nil];

        NSDictionary *requestConfigData = [[NSDictionary alloc] initWithObjectsAndKeys:
                                        @"Requests", @"title",
                                        @"Requests allows the user to invite their friends to the app, or to re-engage their friends so they come back to your app. Friends receive requests in Notifications on Facebook.", @"description",
                                        @"http://developers.facebook.com/docs/reference/dialogs/requests/", @"link",
                                        requestMenuItems, @"menu",
                                        nil];

        [_apiConfigData addObject:requestConfigData];

        [requestMenu1 release];
        [requestMenu2 release];
        [requestMenu3 release];
        [requestMenu4 release];
        [requestMenu5 release];
        [requestMenuItems release];
        [requestConfigData release];

        // News Feed
        NSDictionary *newsMenu1 = [[NSDictionary alloc] initWithObjectsAndKeys:
                                   @"Publish to the user's wall", @"title",
                                   @"This allows a user to post something to their own Wall, which means it will also appear in all of their friends' News Feeds on Facebook.", @"description",
                                   @"Publish to your wall", @"button",
                                   @"apiDialogFeedUser", @"method",
                                   nil];
        NSDictionary *newsMenu2 = [[NSDictionary alloc] initWithObjectsAndKeys:
                                   @"Publish to a friend's Wall", @"title",
                                   @"This allows a user to post something to their friend's Wall, which means it will also appear in all of their mutual friends' News Feeds on Facebook.", @"description",
                                   @"Publish to friend's wall", @"button",
                                   @"getFriendsCallAPIDialogFeed", @"method",
                                   nil];

        NSArray *newsMenuItems = [[NSArray alloc] initWithObjects:
                        newsMenu1,
                        newsMenu2,
                        nil];

        NSDictionary *newsConfigData = [[NSDictionary alloc] initWithObjectsAndKeys:
                                        @"News Feed", @"title",
                                        @"Your app can prompt users to share on their own wall or their friend's wall.", @"description",
                                        @"http://developers.facebook.com/docs/channels/", @"link",
                                        newsMenuItems, @"menu",
                                        nil];

        [_apiConfigData addObject:newsConfigData];

        [newsMenu1 release];
        [newsMenu2 release];
        [newsMenuItems release];
        [newsConfigData release];

        // Graph API
        NSDictionary *graphMenu1 = [[NSDictionary alloc] initWithObjectsAndKeys:
                                      @"Get user's basic information", @"title",
                                      @"You can fetch the user's profile picture and name in order to personalize the experience for them. ", @"description",
                                      @"Get your information", @"button",
                                      @"apiGraphMe", @"method",
                                      nil];
        NSDictionary *graphMenu2 = [[NSDictionary alloc] initWithObjectsAndKeys:
                                      @"Get user's friends", @"title",
                                      @"To make your mobile web app social, you can fetch their friends' information like profile pictures and names.", @"description",
                                      @"Get your friends", @"button",
                                      @"getUserFriends", @"method",
                                      nil];
        NSDictionary *graphMenu3 = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    @"Get user's recent check-ins", @"title",
                                    @"You can fetch fetch their previous Facebook Places check-ins. If necessary, first ask for the required permissions.", @"description",
                                    @"Get past check-ins", @"button",
                                    @"getPermissionsCallUserCheckins", @"method",
                                    nil];
        NSDictionary *graphMenu4 = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    @"Check the user into a place", @"title",
                                    @"You can fetch Places near the user's current location and check the user in. If necessary, first ask for the required permissions.", @"description",
                                    @"Find nearby locations", @"button",
                                    @"getPermissionsCallNearby", @"method",
                                    nil];
        NSDictionary *graphMenu5 = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    @"Upload a photo", @"title",
                                    @"You can upload a photo to the application's album.", @"description",
                                    @"Upload photo", @"button",
                                    @"apiGraphUserPhotosPost", @"method",
                                    nil];
        NSDictionary *graphMenu6 = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    @"Upload a video", @"title",
                                    @"You can upload a video to the user's wall. The video may take a little time to show up on the profile.", @"description",
                                    @"Upload video", @"button",
                                    @"apiGraphUserVideosPost", @"method",
                                    nil];


        NSArray *graphMenuItems = [[NSArray alloc] initWithObjects:
                                   graphMenu1,
                                   graphMenu2,
                                   graphMenu3,
                                   graphMenu4,
                                   graphMenu5,
                                   graphMenu6,
                                   nil];

        NSDictionary *graphConfigData = [[NSDictionary alloc] initWithObjectsAndKeys:
                                           @"Graph API", @"title",
                                           @"The Graph API enables you to read and write data to Facebook. You can utilize what the user has liked, friends, photos, events, as well as most of the data that's available on Facebook.", @"description",
                                           @"http://developers.facebook.com/docs/reference/api/", @"link",
                                           graphMenuItems, @"menu",
                                           nil];

        [_apiConfigData addObject:graphConfigData];

        [graphMenu1 release];
        [graphMenu2 release];
        [graphMenu3 release];
        [graphMenu4 release];
        [graphMenu5 release];
        [graphMenu6 release];
        [graphMenuItems release];
        [graphConfigData release];

    }
    return self;
}

- (void)dealloc {
    [_apiConfigData release];
    [super dealloc];
}

@end
