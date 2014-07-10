/*
 * Copyright 2010-present Facebook.
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


#import "SCTaggableFriendsViewController.h"

@interface SCTaggableFriendsViewController () {
    UITableView *_tableView;
    NSArray *_taggableFriends;
    NSMutableArray *_selection;
    UIActivityIndicatorView *_spinner;
}

@end

@implementation SCTaggableFriendsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _selection = [NSMutableArray array];

    CGRect tableViewFrame, remainder;
    CGRectDivide(self.view.bounds, &remainder, &tableViewFrame, CGRectGetMinY(self.canvasView.frame), CGRectMinYEdge);
    _tableView = [[UITableView alloc] initWithFrame:tableViewFrame];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];

    [self _loadData];
}

- (NSArray *)selection {
    return [_selection copy];
}

#pragma mark - Private implementation
- (void)_loadData {
    [self _startSpinner];
    [[FBRequest requestForGraphPath:@"me/taggable_friends?fields=id,name,picture"] startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        [self _stopSpinner];
        if (result && [result[@"data"] isKindOfClass:[NSArray class]]) {
            _taggableFriends = result[@"data"];
            [_tableView reloadData];
        } else {
            NSLog(@"ERROR: loading taggable friends:%@", error);
            [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Unable to load friends. Try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
    }];
}

- (void)_startSpinner {
    if (_spinner == nil) {
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _spinner.center = CGPointMake(CGRectGetWidth(self.view.bounds) / 2, 100);
    }

    [self.view addSubview:_spinner];
    [_spinner startAnimating];
}

- (void)_stopSpinner {
    [_spinner stopAnimating];
    [_spinner removeFromSuperview];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"default"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"default"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.textLabel.text = _taggableFriends[indexPath.row][@"name"];
    NSURL *url = [NSURL URLWithString:_taggableFriends[indexPath.row][@"picture"][@"data"][@"url"]];
    if (url) {
        cell.imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
    }
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_taggableFriends count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id<FBGraphObject> graphUser = [FBGraphObject graphObject];
    graphUser[@"id"] = _taggableFriends[indexPath.row][@"id"];
    graphUser[@"name"] = _taggableFriends[indexPath.row][@"name"];
    [_selection addObject:graphUser];

    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
}

@end
