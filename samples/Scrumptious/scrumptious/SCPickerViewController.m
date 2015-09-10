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

#import "SCPickerViewController.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import <FBSDKLoginKit/FBSDKLoginKit.h>

@implementation SCPickerViewController
{
    NSArray *_results;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.allowsMultipleSelection = self.allowsMultipleSelection;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.requiredPermission && ![[FBSDKAccessToken currentAccessToken] hasGranted:self.requiredPermission])
    {
        FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
        [login logInWithReadPermissions:@[self.requiredPermission]
                     fromViewController:self
                                handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
            if ([result.grantedPermissions containsObject:self.requiredPermission]) {
                [self fetchData];
            } else {
                [self dismissViewControllerAnimated:YES completion:NULL];
            }
        }];
    } else {
        [self fetchData];
    }
}

- (void)fetchData
{
    [self.request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        if (error) {
            NSLog(@"Picker loading error:%@", error);
            if (!error.userInfo[FBSDKErrorLocalizedDescriptionKey]) {
                [[[UIAlertView alloc] initWithTitle:@"Oops"
                                            message:@"There was a problem fetching the list"
                                           delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
            }
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            _results = result[@"data"];
            [self.tableView reloadData];
        }
    }];
}
- (NSArray *)selection {
    NSMutableArray *result = [NSMutableArray array];
    for (NSIndexPath *index in self.tableView.indexPathsForSelectedRows) {
        [result addObject: @{
                             @"id" : _results[index.row][@"id"],
                             @"name" : _results[index.row][@"name"]
                             }];
    }

    return result;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _results.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    cell.textLabel.text = _results[indexPath.row][@"name"];
    NSString *pictureURL = _results[indexPath.row][@"picture"][@"data"][@"url"];
    if (pictureURL) {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            NSData *image = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:pictureURL]];

            //this will set the image when loading is finished
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.imageView.image = [UIImage imageWithData:image];
                [cell setNeedsLayout];
            });
        });
    }
    return cell;
}

#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
}

@end
