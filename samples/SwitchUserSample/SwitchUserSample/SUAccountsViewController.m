// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "SUAccountsViewController.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import <FBSDKLoginKit/FBSDKLoginKit.h>

#import "SUCache.h"
#import "SUProfileTableViewCell.h"

@implementation SUAccountsViewController
{
    NSIndexPath *_currentIndexPath;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_accessTokenChanged:)
                                                 name:FBSDKAccessTokenDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_currentProfileChanged:)
                                                 name:FBSDKProfileDidChangeNotification
                                               object:nil];
    // It's generally important to check [FBSDKAccessToken currentAccessToken] at
    //  viewDidLoad to see if there is a token cached by the SDK or, resuming
    //  a login flow after eviction.
    // In this app, we want to see if there's a match with the local cache, and if
    //  not, clear the "current" user and token because that indicates either the
    //  SUCache version is incompatible.
    static const int kNumSlots = 4;
    BOOL foundToken = NO;
    for (int i = 0; i < kNumSlots; i++) {
        SUCacheItem *item = [SUCache itemForSlot:i];
        if ([item.token isEqualToAccessToken:[FBSDKAccessToken currentAccessToken]]) {
            foundToken = YES;
            break;
        }
    }
    if (!foundToken) {
        // Notably, this makes sure tableView:cellForRowAtIndexPath: doesn't flag a wrong cell.
        //  as selected.
        // Alternatively, we could have found an empty slot to save the "active token".
        [self _deselectRow];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSInteger)_userSlotFromIndexPath:(NSIndexPath *)indexPath
{
    // Since section 0 has 1 row, we can use this cheap trick
    // so that the "Primary User" cell is slot 0 and the rest
    // follow.
    return indexPath.row + indexPath.section;
}

// Observe a new token, so save it to our SUCache and update
// the cell.
- (void)_accessTokenChanged:(NSNotification *)notification
{
    FBSDKAccessToken *token = notification.userInfo[FBSDKAccessTokenChangeNewKey];

    if (!token) {
        [self _deselectRow];
    } else {
        SUProfileTableViewCell *cell = (SUProfileTableViewCell *)[self.tableView cellForRowAtIndexPath:_currentIndexPath];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        NSInteger slot = [self _userSlotFromIndexPath:_currentIndexPath];
        SUCacheItem *item = [SUCache itemForSlot:slot] ?: [[SUCacheItem alloc] init];
        if (![item.token isEqualToAccessToken:token]) {
            item.token = token;
            [SUCache saveItem:item slot:slot];
            cell.userID = token.userID;
        }
    }
}

// The profile information has changed, update the cell and cache.
- (void)_currentProfileChanged:(NSNotification *)notification
{
    NSInteger slot = [self _userSlotFromIndexPath:_currentIndexPath];

    FBSDKProfile *profile = notification.userInfo[FBSDKProfileChangeNewKey];
    if (profile) {
        SUCacheItem *cacheItem = [SUCache itemForSlot:slot];
        cacheItem.profile = profile;
        [SUCache saveItem:cacheItem slot:slot];

        SUProfileTableViewCell *cell = (SUProfileTableViewCell *)[self.tableView cellForRowAtIndexPath:_currentIndexPath];
        cell.userName = cacheItem.profile.name;
    }
}

- (void)_deselectRow
{
    [self.tableView cellForRowAtIndexPath:_currentIndexPath].accessoryType = UITableViewCellAccessoryNone;
    _currentIndexPath = nil;
    [FBSDKAccessToken setCurrentAccessToken:nil];
    [FBSDKProfile setCurrentProfile:nil];
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return (section == 0 ? @"Primary User:" : @"Guest Users:");
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (section == 0 ? 1 : 3);
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return ([SUCache itemForSlot:[self _userSlotFromIndexPath:indexPath]] != nil);
}

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSInteger slot = [self _userSlotFromIndexPath:indexPath];
        [SUCache deleteItemInSlot:slot];
        SUProfileTableViewCell *cell = (SUProfileTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
        cell.userName = @"Empty slot";
        cell.userID = nil;
        cell.accessoryType = UITableViewCellAccessoryNone;
        if ([_currentIndexPath compare:indexPath] == NSOrderedSame) {
            [self _deselectRow];
        }
        [tableView reloadData];
    }
}

#pragma mark - UITableViewDelegate methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SUProfileTableViewCell *cell = (SUProfileTableViewCell *)[tableView
                                                              dequeueReusableCellWithIdentifier:@"SUProfileTableViewCell"
                                                              forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    NSInteger slot = [self _userSlotFromIndexPath:indexPath];
    SUCacheItem *item = [SUCache itemForSlot:slot];
    cell.userName = item.profile.name ?: @"Empty slot";
    cell.userID = item.token.userID;
    if ([item.token isEqualToAccessToken:[FBSDKAccessToken currentAccessToken]]) {
        _currentIndexPath = indexPath;
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self _deselectRow];
    _currentIndexPath = indexPath;
    NSInteger slot = [self _userSlotFromIndexPath:indexPath];
    FBSDKAccessToken *token = [SUCache itemForSlot:slot].token;
    if (token) {
        // We have a saved token, issue a request to make sure it's still valid.
        [FBSDKAccessToken setCurrentAccessToken:token];
        FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:nil];
        if (indexPath.section == 1) {
            // Disable the error recovery for the slots that require the webview login,
            // since error recovery uses FBSDKLoginBehaviorNative
            [request setGraphErrorRecoveryDisabled:YES];
        }
        [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
            // Since we're only requesting /me, we make a simplifying assumption that any error
            // means the token is bad.
            if (error) {
                [[[UIAlertView alloc] initWithTitle:nil
                                            message:@"The user token is no longer valid."
                                           delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
                [SUCache deleteItemInSlot:slot];
                [self _deselectRow];
            }
        }];
    } else {
        FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
        if (indexPath.section == 1) {
            login.loginBehavior = FBSDKLoginBehaviorWeb;
        }
        SUProfileTableViewCell *cell = (SUProfileTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
        cell.userName = @"Loading ...";
        [login logInWithReadPermissions:nil
                     fromViewController:self
                                handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
            if (error || result.isCancelled) {
                cell.userName = @"Empty slot";
                [self _deselectRow];
            }
        }];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Forget";
}

@end
