/*
 * Copyright 2012 Facebook
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *    http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "FBGraphObjectTableView.h"

@interface FBGraphObjectTableView () {
    UIActivityIndicatorView *_spinner;
    UITableView *_tableView;
}

- (void)initializeWithTableView:(UITableView *)tableView
                        spinner:(UIActivityIndicatorView *)spinner;

@end

@implementation FBGraphObjectTableView

@synthesize spinner = _spinner;
@synthesize tableView = _tableView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        UITableView *tableView = [[UITableView alloc] initWithFrame:frame];
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]
                                            initWithFrame:frame];
        [self initializeWithTableView:tableView spinner:spinner];
        [spinner release];
        [tableView release];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        UITableView *tableView = [[UITableView alloc] initWithCoder:aDecoder];
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]
                                            initWithCoder:aDecoder];
        [self initializeWithTableView:tableView spinner:spinner];
        [spinner release];
        [tableView release];
    }
    
    return self;
}

- (void)initializeWithTableView:(UITableView *)tableView
                        spinner:(UIActivityIndicatorView *)spinner
{
    // Table
    tableView.autoresizingMask =
    UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tableView.autoresizesSubviews = YES;
    tableView.clipsToBounds = YES;
    self.tableView = tableView;
    
    // Spinner
    spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    spinner.hidesWhenStopped = YES;
    spinner.autoresizingMask =
    UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.spinner = spinner;
    
    // Self
    self.autoresizingMask =
    UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.autoresizesSubviews = YES;
    self.clipsToBounds = YES;
    
    [self addSubview:self.tableView];
    [self addSubview:self.spinner];
}

- (void)dealloc
{
    [_spinner release];

    _tableView.delegate = nil;
    _tableView.dataSource = nil;
    [_tableView release];

    [super dealloc];
}
@end
