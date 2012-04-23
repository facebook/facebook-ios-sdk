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
#import "FBGraphObjectTableView.h"
#import "FBFriendPickerViewController.h"
#import "FBRequestConnection.h"
#import "FBRequest.h"

static NSString *defaultImageName =
@"FBiOSSDKResources.bundle/FBFriendPickerView/images/default.png";

@interface FBFriendPickerViewController ()
<FBGraphObjectSelectionChangedDelegate,FBGraphObjectFilterDelegate>

@property (nonatomic, retain) FBRequestConnection *connection;
@property (nonatomic, retain) FBGraphObjectTableDataSource *dataSource;
@property (nonatomic, retain) FBGraphObjectTableView *graphView;
@property (nonatomic, retain) FBGraphObjectTableSelection *selectionManager;

- (void)initialize;

- (void)requestCompleted:(FBRequestConnection *)connection
                  result:(id)result
                   error:(NSError *)error;

@end

@implementation FBFriendPickerViewController {
    BOOL _allowsMultipleSelection;
    FBRequestConnection *_connection;
    FBGraphObjectTableDataSource *_dataSource;
    id<FBFriendPickerDelegate> _delegate;
    FBGraphObjectTableView *_graphView;
    NSSet *_propertiesForRequest;
    FBGraphObjectTableSelection *_selectionManager;
    FBSession *_session;
    NSString *_userID;
}

@synthesize dataSource = _dataSource;
@synthesize delegate = _delegate;
@synthesize connection = _connection;
@synthesize graphView = _graphView;
@synthesize propertiesForRequest = _propertiesForRequest;
@synthesize selectionManager = _selectionManager;
@synthesize session = _session;
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
    dataSource.filterDelegate = self;
    dataSource.groupByPropertyName = @"name";
    self.dataSource = dataSource;

    // Selection Manager
    FBGraphObjectTableSelection *selectionManager = [[FBGraphObjectTableSelection alloc]
                                                     initWithDataSource:dataSource];
    selectionManager.delegate = self;

    // Self
    self.dataSource = dataSource;
    self.selectionManager = selectionManager;
    self.allowsMultipleSelection = YES;
    self.includesPicture = YES;
    self.userID = @"me";

    // cleanup
    [selectionManager release];
    [dataSource release];
}

- (void)dealloc
{
    [_connection cancel];
    _dataSource.filterDelegate = nil;
    
    [_connection release];
    [_dataSource release];
    [_propertiesForRequest release];
    [_graphView release];
    [_selectionManager release];
    [_session release];
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
        self.graphView.tableView.allowsMultipleSelection = allowsMultipleSelection;
    }
}

- (BOOL)includesPicture
{
    return self.dataSource.displayPicturePropertyName != nil;
}

- (void)setIncludesPicture:(BOOL)includesPicture
{
    self.dataSource.displayPicturePropertyName = includesPicture ? @"picture" : nil;
}

- (NSArray *)selection
{
    return self.selectionManager.selection;
}

#pragma mark - Public Methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.autoresizesSubviews = YES;
    self.view.clipsToBounds = YES;
    self.view.autoresizingMask =
    UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    FBGraphObjectTableView *graphView = [[FBGraphObjectTableView alloc]
                                         initWithFrame:self.view.bounds];
    graphView.tableView.allowsMultipleSelection = self.allowsMultipleSelection;
    graphView.tableView.dataSource = self.dataSource;
    graphView.tableView.delegate = self.selectionManager;
    self.graphView = graphView;
    [self.view addSubview:graphView];

    if (self.connection) {
        [graphView.spinner startAnimating];
    }

    [graphView release];
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    self.graphView = nil;
    [self.dataSource cancelPendingRequests];
}

- (void)start
{
    [self.graphView.spinner startAnimating];

    NSMutableString *graphPath = [[NSMutableString alloc] initWithString:self.userID];
    [graphPath appendString:@"/friends"];

    NSMutableSet *properties = [[NSMutableSet alloc] initWithSet:self.propertiesForRequest];
    [properties addObject:@"id"];
    [properties addObject:@"name"];
    [properties addObject:@"first_name"];
    [properties addObject:@"last_name"];
    [self.dataSource addRequestPropertyNamesToSet:properties];

    NSMutableString *fields = [[NSMutableString alloc] init];
    for (NSString *field in properties) {
        if ([fields length]) {
            [fields appendString:@","];
        }
        [fields appendString:field];
    }

    [properties release];

    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:fields forKey:@"fields"];

    [fields release];

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

    [self.connection start];
}

- (void)updateView
{
    [self.dataSource update];
    [self.graphView.tableView reloadData];
}

#pragma mark - private methods

// Handles the completion of a request to FB service.
- (void)requestCompleted:(FBRequestConnection *)connection
                  result:(id)result
                   error:(NSError *)error
{
    self.connection = nil;
    
    if (error) {
        if ([self.delegate respondsToSelector:@selector(handleError:)]) {
            [self.delegate friendPickerViewController:self handleError:error];
        }
    } else {
        [self.graphView.spinner stopAnimating];
        self.dataSource.data = (NSArray *)[((NSDictionary *)result) objectForKey:@"data"];
        [self updateView];
    }
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

#pragma mark - FBGraphObjectFilterDelegate

- (BOOL)graphObjectTableDataSource:(FBGraphObjectTableDataSource *)dataSource
                filterIncludesItem:(id<FBGraphObject>)item
{
    if ([self.delegate respondsToSelector:@selector(shouldIncludeUser:)]) {
        return [self.delegate friendPickerViewController:self
                                       shouldIncludeUser:(id<FBGraphUser>)item];
    } else {
        return YES;
    }
}

@end
