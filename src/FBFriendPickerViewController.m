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
#import "FBFriendPickerViewController.h"
#import "FBRequestConnection.h"
#import "FBRequest.h"
#import "FBError.h"

static NSString *defaultImageName =
@"FBiOSSDKResources.bundle/FBFriendPickerView/images/default.png";

@interface FBFriendPickerViewController () <FBFriendPickerDelegate,
                                            FBGraphObjectSelectionChangedDelegate, 
                                            FBGraphObjectViewControllerDelegate>

@property (nonatomic, retain) FBRequestConnection *connection;
@property (nonatomic, retain) FBGraphObjectTableDataSource *dataSource;
@property (nonatomic, retain) FBGraphObjectTableSelection *selectionManager;

- (void)initialize;

- (void)requestCompleted:(FBRequestConnection *)connection
                  result:(id)result
                   error:(NSError *)error;

- (void)searchTextChanged:(UITextField *)textField;
- (void)searchTextEndedEdit:(UITextField *)textField;

@end

@implementation FBFriendPickerViewController {
    BOOL _allowsMultipleSelection;
    FBRequestConnection *_connection;
    FBGraphObjectTableDataSource *_dataSource;
    id<FBFriendPickerDelegate> _delegate;
    BOOL _searchTextEnabled;
    NSSet *_fieldsForRequest;
    UITextField *_searchTextField;
    FBGraphObjectTableSelection *_selectionManager;
    FBSession *_session;
    UIActivityIndicatorView *_spinner;
    UITableView *_tableView;
    NSString *_userID;
}

@synthesize connection = _connection;
@synthesize dataSource = _dataSource;
@synthesize delegate = _delegate;
@synthesize searchTextEnabled = _searchTextEnabled;
@synthesize fieldsForRequest = _fieldsForRequest;
@synthesize searchTextField = _searchTextField;
@synthesize selectionManager = _selectionManager;
@synthesize session = _session;
@synthesize spinner = _spinner;
@synthesize tableView = _tableView;
@synthesize userID = _userID;

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
    self.dataSource = dataSource;

    // Selection Manager
    FBGraphObjectTableSelection *selectionManager = [[FBGraphObjectTableSelection alloc]
                                                     initWithDataSource:dataSource];
    selectionManager.delegate = self;

    // Self
    self.allowsMultipleSelection = YES;
    self.dataSource = dataSource;
    self.delegate = self;
    self.itemPicturesEnabled = YES;
    self.selectionManager = selectionManager;
    self.searchTextEnabled = YES;
    self.userID = @"me";

    // cleanup
    [selectionManager release];
    [dataSource release];
}

- (void)dealloc
{
    [_connection cancel];
    _dataSource.controllerDelegate = nil;
    
    [_connection release];
    [_dataSource release];
    [_fieldsForRequest release];
    [_searchTextField release];
    [_selectionManager release];
    [_session release];
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

#pragma mark - Public Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    CGRect bounds = self.view.bounds;

    if (self.searchTextEnabled && !self.searchTextField) {
        CGRect frame = bounds;
        frame.size.height = 32;

        UITextField *searchTextField = [[UITextField alloc] initWithFrame:frame];
        searchTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth;

        self.searchTextField = searchTextField;
        [self.view addSubview:searchTextField];
        [searchTextField release];
    }

    if (!self.tableView) {
        CGRect frame = bounds;
        if (self.searchTextEnabled) {
            frame.size.height -= 40;
            frame.origin.y += 40;
        }

        UITableView *tableView = [[UITableView alloc] initWithFrame:frame];
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

        self.spinner = spinner;
        [self.view addSubview:spinner];
        [spinner release];
    }

    [self.searchTextField addTarget:self
                             action:@selector(searchTextChanged:)
                   forControlEvents:UIControlEventEditingChanged];
    [self.searchTextField addTarget:self
                             action:@selector(searchTextEndedEdit:)
                   forControlEvents:(UIControlEventEditingDidEnd |
                                     UIControlEventEditingDidEndOnExit)];

    self.tableView.allowsMultipleSelection = self.allowsMultipleSelection;
    self.tableView.delegate = self.selectionManager;
    [self.dataSource bindTableView:self.tableView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    [self.dataSource cancelPendingRequests];

    self.searchTextField = nil;
    self.tableView = nil;
    self.spinner = nil;
}

- (void)loadData
{
    NSMutableString *graphPath = [[NSMutableString alloc] initWithString:self.userID];
    [graphPath appendString:@"/friends"];

    NSString *fields = [self.dataSource fieldsForRequestIncluding:self.fieldsForRequest,
                        @"id", @"name", @"first_name", @"last_name", @"picture", nil];

    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:fields forKey:@"fields"];

    FBRequest *request = [[FBRequest alloc] initWithSession:self.session
                                                  graphPath:graphPath
                                                 parameters:parameters
                                                 HTTPMethod:@"GET"];
    [parameters release];
    [graphPath release];

    [self.connection cancel];
    self.connection = [request connectionWithCompletionHandler:
                       ^(FBRequestConnection *connection, id result, NSError *error) {
                           [self requestCompleted:connection result:result error:error];
                       }];
    [request release];

    [self updateView];
    [self.connection start];
}

- (void)updateView
{
    if (self.connection) {
        [self.spinner startAnimating];
    } else {
        [self.spinner stopAnimating];
    }

    [self.dataSource update];
    [self.tableView reloadData];
}

#pragma mark - private methods

// Handles the completion of a request to FB service.
- (void)requestCompleted:(FBRequestConnection *)connection
                  result:(id)result
                   error:(NSError *)error
{
    self.connection = nil;
    NSArray *data = nil;

    if (!error && [result isKindOfClass:[NSDictionary class]]) {
        id rawData = [((NSDictionary *)result) objectForKey:@"data"];
        if ([rawData isKindOfClass:[NSArray class]]) {
            data = (NSArray *)rawData;
        }
    }

    if (!error && !data) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:result
                                                             forKey:FBErrorParsedJSONResponseKey];
        error = [[[NSError alloc] initWithDomain:FBiOSSDKDomain
                                            code:FBErrorProtocolMismatch
                                        userInfo:userInfo]
                 autorelease];
    }

    if (error) {
        if ([self.delegate
             respondsToSelector:@selector(friendPickerViewController:handleError:)]) {
            [self.delegate friendPickerViewController:self handleError:error];
        }
    } else {
        [self.dataSource setViewData:data];
    }

    [self updateView];
}

- (void)searchTextChanged:(UITextField *)textField
{
    if (textField == self.searchTextField) {
        [self updateView];
    }
}
- (void)searchTextEndedEdit:(UITextField *)textField
{
    if ((textField = self.searchTextField) && ([textField isFirstResponder])) {
        [textField resignFirstResponder];
    }
}

#pragma mark - FBGraphObjectSelectionChangedDelegate

- (void)graphObjectTableSelectionDidChange:
(FBGraphObjectTableSelection *)selection
{
    if ([self.searchTextField isFirstResponder]) {
        [self.searchTextField resignFirstResponder];
    }

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

    if (self.searchTextEnabled && [self.searchTextField.text length]) {
        NSRange range = [user.name rangeOfString:self.searchTextField.text
                                         options:NSCaseInsensitiveSearch];
        return (range.location != NSNotFound);
    } else if ([self.delegate
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

@end
