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

#import "FBGraphObjectTableDataSource.h"
#import "FBGraphObjectTableSelection.h"
#import "FBGraphObjectPagingLoader.h"
#import "FBFriendPickerViewController.h"
#import "FBRequestConnection.h"
#import "FBRequest.h"
#import "FBError.h"

static NSString *defaultImageName =
@"FBiOSSDKResources.bundle/FBFriendPickerView/images/default.png";

@interface FBFriendPickerViewController () <FBFriendPickerDelegate,
                                            FBGraphObjectSelectionChangedDelegate, 
                                            FBGraphObjectViewControllerDelegate,
                                            FBGraphObjectPagingLoaderDelegate>

@property (nonatomic, retain) FBGraphObjectTableDataSource *dataSource;
@property (nonatomic, retain) FBGraphObjectTableSelection *selectionManager;
@property (nonatomic, retain) FBGraphObjectPagingLoader *loader;

- (void)initialize;

@end

@implementation FBFriendPickerViewController {
    BOOL _allowsMultipleSelection;
}

@synthesize dataSource = _dataSource;
@synthesize delegate = _delegate;
@synthesize fieldsForRequest = _fieldsForRequest;
@synthesize selectionManager = _selectionManager;
@synthesize spinner = _spinner;
@synthesize tableView = _tableView;
@synthesize userID = _userID;
@synthesize loader = _loader;

- (id)init
{
    [super init];

    if (self) {
        [self initialize];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    [super initWithCoder:aDecoder];
    
    if (self) {
        [self initialize];
    }
    
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (self) {
        [self initialize];
    }
    
    return self;
}

- (void)initialize
{
    // Data Source
    FBGraphObjectTableDataSource *dataSource = [[FBGraphObjectTableDataSource alloc]
                                                init];
    dataSource.defaultPicture = [UIImage imageNamed:defaultImageName];
    dataSource.controllerDelegate = self;
    dataSource.groupByField = @"name";
    [dataSource setSortingBySingleField:@"name" ascending:YES];
    self.dataSource = dataSource;

    // Selection Manager
    FBGraphObjectTableSelection *selectionManager = [[FBGraphObjectTableSelection alloc]
                                                     initWithDataSource:dataSource];
    selectionManager.delegate = self;

    // Paging loader
    self.loader = [[FBGraphObjectPagingLoader alloc] initWithDataSource:self.dataSource];
    self.loader.pagingMode = FBGraphObjectPagingModeImmediate;
    self.loader.delegate = self;

    // Self
    self.allowsMultipleSelection = YES;
    self.dataSource = dataSource;
    self.delegate = self;
    self.itemPicturesEnabled = YES;
    self.selectionManager = selectionManager;
    self.userID = @"me";

    // cleanup
    [selectionManager release];
    [dataSource release];
}

- (void)dealloc
{
    [_loader cancel];
    _loader.delegate = nil;
    [_loader release];

    _dataSource.controllerDelegate = nil;
    
    [_dataSource release];
    [_fieldsForRequest release];
    [_selectionManager release];
    [_spinner release];
    [_tableView release];
    [_userID release];
    
    [super dealloc];
}

#pragma mark - Custom Properties

- (BOOL)allowsMultipleSelection
{
    return _allowsMultipleSelection;
}

- (void)setAllowsMultipleSelection:(BOOL)allowsMultipleSelection
{
    _allowsMultipleSelection = allowsMultipleSelection;
    if (self.isViewLoaded) {
        self.tableView.allowsMultipleSelection = allowsMultipleSelection;
    }
}

- (BOOL)itemPicturesEnabled
{
    return self.dataSource.itemPicturesEnabled;
}

- (void)setItemPicturesEnabled:(BOOL)itemPicturesEnabled
{
    self.dataSource.itemPicturesEnabled = itemPicturesEnabled;
}

- (NSArray *)selection
{
    return self.selectionManager.selection;
}

// We don't really need to store session, let the loader hold it.
- (void)setSession:(FBSession *)session {
    self.loader.session = session;
}

- (FBSession*)session {
    return self.loader.session;
}

#pragma mark - Public Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    CGRect bounds = self.view.bounds;

    if (!self.tableView) {
        UITableView *tableView = [[UITableView alloc] initWithFrame:bounds];
        tableView.autoresizingMask =
            UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        self.tableView = tableView;
        [self.view addSubview:tableView];
        [tableView release];
    }

    if (!self.spinner) {
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithFrame:bounds];
        spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        spinner.hidesWhenStopped = YES;
        spinner.autoresizingMask =
            UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        // We want user to be able to scroll while we load.
        spinner.userInteractionEnabled = NO;
        
        self.spinner = spinner;
        [self.view addSubview:spinner];
        [spinner release];
    }

    self.tableView.allowsMultipleSelection = self.allowsMultipleSelection;
    self.tableView.delegate = self.selectionManager;
    [self.dataSource bindTableView:self.tableView];
    self.loader.tableView = self.tableView;
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    self.loader.tableView = nil;
    self.spinner = nil;
    self.tableView = nil;
}

- (void)loadData
{
    FBRequest *request = [FBRequest requestForMyFriendsWithSession:self.session];

    NSString *fields = [self.dataSource fieldsForRequestIncluding:self.fieldsForRequest,
                        @"id", @"name", @"first_name", @"last_name", @"picture", nil];
    [request.parameters setObject:fields forKey:@"fields"];
    
    [self.loader startLoadingWithRequest:request];
}

- (void)updateView
{
    [self.dataSource update];
    [self.tableView reloadData];
}

#pragma mark - FBGraphObjectSelectionChangedDelegate

- (void)graphObjectTableSelectionDidChange:
(FBGraphObjectTableSelection *)selection
{
    if ([self.delegate respondsToSelector:
         @selector(friendPickerViewControllerSelectionDidChange:)]) {
        [self.delegate friendPickerViewControllerSelectionDidChange:self];
    }
}

#pragma mark - FBGraphObjectViewControllerDelegate

- (BOOL)graphObjectTableDataSource:(FBGraphObjectTableDataSource *)dataSource
                filterIncludesItem:(id<FBGraphObject>)item
{
    id<FBGraphUser> user = (id<FBGraphUser>)item;

    if ([self.delegate
         respondsToSelector:@selector(friendPickerViewController:shouldIncludeUser:)]) {
        return [self.delegate friendPickerViewController:self
                                       shouldIncludeUser:user];
    } else {
        return YES;
    }
}

- (NSString *)graphObjectTableDataSource:(FBGraphObjectTableDataSource *)dataSource
                             titleOfItem:(id<FBGraphObject>)graphObject
{
    return [graphObject objectForKey:@"name"];
}

- (UIImage *)graphObjectTableDataSource:(FBGraphObjectTableDataSource *)dataSource
                       pictureUrlOfItem:(id<FBGraphObject>)graphObject
{
    return [graphObject objectForKey:@"picture"];
}

#pragma mark FBGraphObjectPagingLoaderDelegate members

- (void)pagingLoader:(FBGraphObjectPagingLoader*)pagingLoader willLoadURL:(NSString*)url {
    [self.spinner startAnimating];    
}

- (void)pagingLoader:(FBGraphObjectPagingLoader*)pagingLoader didLoadData:(NSDictionary*)results {
    [self.spinner stopAnimating];
    if ([self.delegate respondsToSelector:@selector(friendPickerViewControllerDataDidChange:)]) {
        [self.delegate friendPickerViewControllerDataDidChange:self];
    }
}

- (void)pagingLoader:(FBGraphObjectPagingLoader*)pagingLoader handleError:(NSError*)error {
    if ([self.delegate
         respondsToSelector:@selector(friendPickerViewController:handleError:)]) {
        [self.delegate friendPickerViewController:self handleError:error];
    }
}

@end
