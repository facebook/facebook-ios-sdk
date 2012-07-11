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

#import "FBError.h"
#import "FBFriendPickerViewController.h"
#import "FBFriendPickerViewController+Internal.h"
#import "FBFriendPickerCacheDescriptor.h"
#import "FBGraphObjectPagingLoader.h"
#import "FBGraphObjectTableDataSource.h"
#import "FBGraphObjectTableSelection.h"
#import "FBGraphObjectTableCell.h"
#import "FBLogger.h"
#import "FBRequest.h"
#import "FBRequestConnection.h"
#import "FBUtility.h"
#import "FBSession+Internal.h"

NSString *const FBFriendPickerCacheIdentity = @"FBFriendPicker";
static NSString *defaultImageName = @"FBiOSSDKResources.bundle/FBFriendPickerView/images/default.png";

int const FBRefreshCacheDelaySeconds = 2;

@interface FBFriendPickerViewController () <FBGraphObjectSelectionChangedDelegate, 
                                            FBGraphObjectViewControllerDelegate,
                                            FBGraphObjectPagingLoaderDelegate>

@property (nonatomic, retain) FBGraphObjectTableDataSource *dataSource;
@property (nonatomic, retain) FBGraphObjectTableSelection *selectionManager;
@property (nonatomic, retain) FBGraphObjectPagingLoader *loader;

- (void)initialize;
- (void)centerAndStartSpinner;
- (void)loadDataSkippingRoundTripIfCached:(NSNumber*)skipRoundTripIfCached;
- (FBRequest*)requestForLoadData;

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
@synthesize sortOrdering = _sortOrdering;
@synthesize displayOrdering = _displayOrdering;

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
    dataSource.itemTitleSuffixEnabled = YES;
    self.dataSource = dataSource;

    // Selection Manager
    FBGraphObjectTableSelection *selectionManager = [[FBGraphObjectTableSelection alloc]
                                                     initWithDataSource:dataSource];
    selectionManager.delegate = self;

    // Paging loader
    self.loader = [[FBGraphObjectPagingLoader alloc] initWithDataSource:self.dataSource
                                                             pagingMode:FBGraphObjectPagingModeImmediate];
    [_loader release];
    self.loader.delegate = self;

    // Self
    self.allowsMultipleSelection = YES;
    self.dataSource = dataSource;
    self.delegate = nil;
    self.itemPicturesEnabled = YES;
    self.selectionManager = selectionManager;
    self.userID = @"me";
    self.sortOrdering = FBFriendSortByFirstName;
    self.displayOrdering = FBFriendDisplayByFirstName;
    
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
    if (self.selectionManager) {
        self.selectionManager.allowsMultipleSelection = allowsMultipleSelection;
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
    [FBLogger registerCurrentTime:FBLogBehaviorPerformanceCharacteristics
                          withTag:self];
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
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        spinner.hidesWhenStopped = YES;
        // We want user to be able to scroll while we load.
        spinner.userInteractionEnabled = NO;
        
        self.spinner = spinner;
        [self.view addSubview:spinner];
        [spinner release];
    }

    self.selectionManager.allowsMultipleSelection = self.allowsMultipleSelection;
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

- (void)configureUsingCachedDescriptor:(FBCacheDescriptor*)cacheDescriptor {
    if (![cacheDescriptor isKindOfClass:[FBFriendPickerCacheDescriptor class]]) {
        [[NSException exceptionWithName:FBInvalidOperationException
                                 reason:@"FBFriendPickerViewController: An attempt was made to configure "
                                        @"an instance with a cache descriptor object that was not created "
                                        @"by the FBFriendPickerViewController class"
                               userInfo:nil]
         raise];
    }
    FBFriendPickerCacheDescriptor *cd = (FBFriendPickerCacheDescriptor*)cacheDescriptor;
    self.userID = cd.userID;
    self.fieldsForRequest = cd.fieldsForRequest;
}

- (void)loadData {
    // when the app calls loadData,
    // if we don't have a session and there is 
    // an open active session, use that
    if (!self.session) {
        self.session = [FBSession activeSessionIfOpen];
    }
    [self loadDataSkippingRoundTripIfCached:[NSNumber numberWithBool:YES]];
}

- (void)updateView
{
    [self.dataSource update];
    [self.tableView reloadData];
}

#pragma mark - public class members

+ (FBCacheDescriptor*)cacheDescriptor {
    return [[[FBFriendPickerCacheDescriptor alloc] init] autorelease];
}

+ (FBCacheDescriptor*)cacheDescriptorWithUserID:(NSString*)userID fieldsForRequest:(NSSet*)fieldsForRequest {
    return [[[FBFriendPickerCacheDescriptor alloc] initWithUserID:userID
                                                 fieldsForRequest:fieldsForRequest]
            autorelease];
}


#pragma mark - private members

- (FBRequest*)requestForLoadData {
    
    // Respect user settings in case they have changed.
    NSMutableArray *sortFields = [NSMutableArray array];
    NSString *groupByField = nil;
    if (self.sortOrdering == FBFriendSortByFirstName) {
        [sortFields addObject:@"first_name"];
        [sortFields addObject:@"middle_name"];
        [sortFields addObject:@"last_name"];
        groupByField = @"first_name";
    } else {
        [sortFields addObject:@"last_name"];
        [sortFields addObject:@"first_name"];
        [sortFields addObject:@"middle_name"];
        groupByField = @"last_name";
    }
    [self.dataSource setSortingByFields:sortFields ascending:YES];
    self.dataSource.groupByField = groupByField;
    
    // me or one of my friends that also uses the app
    NSString *user = self.userID;
    if (!user) {
        user = @"me";
    }
    
    // create the request and start the loader
    FBRequest *request = [FBFriendPickerViewController requestWithUserID:user
                                                                  fields:self.fieldsForRequest
                                                              dataSource:self.dataSource
                                                                 session:self.session];
    return request;
}

- (void)loadDataSkippingRoundTripIfCached:(NSNumber*)skipRoundTripIfCached {
    [self.loader startLoadingWithRequest:[self requestForLoadData]
                           cacheIdentity:FBFriendPickerCacheIdentity
                   skipRoundtripIfCached:skipRoundTripIfCached.boolValue];
}

+ (FBRequest*)requestWithUserID:(NSString*)userID
                         fields:(NSSet*)fields
                     dataSource:(FBGraphObjectTableDataSource*)datasource
                        session:(FBSession*)session {
    
    FBRequest *request = [FBRequest requestForGraphPath:[NSString stringWithFormat:@"%@/friends", userID]];
    [request setSession:session];
    
    NSString *allFields = [datasource fieldsForRequestIncluding:fields,
                           @"id", 
                           @"name", 
                           @"first_name", 
                           @"middle_name",
                           @"last_name", 
                           @"picture", 
                           nil];
    [request.parameters setObject:allFields forKey:@"fields"];
    
    return request;
}

- (void)centerAndStartSpinner
{
    [FBUtility centerView:self.spinner tableView:self.tableView];
    [self.spinner startAnimating];    
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
                             titleOfItem:(id<FBGraphUser>)graphUser
{
    // Title is either "First Middle" or "Last" depending on display order.
    if (self.displayOrdering == FBFriendDisplayByFirstName) {
        if (graphUser.middle_name) {
            return [NSString stringWithFormat:@"%@ %@", graphUser.first_name, graphUser.middle_name];
        } else {
            return graphUser.first_name;
        }
    } else {
        return graphUser.last_name;
    }
}

- (NSString *)graphObjectTableDataSource:(FBGraphObjectTableDataSource *)dataSource
                       titleSuffixOfItem:(id<FBGraphUser>)graphUser
{
    // Title suffix is either "Last" or "First Middle" depending on display order.
    if (self.displayOrdering == FBFriendDisplayByLastName) {
        if (graphUser.middle_name) {
            return [NSString stringWithFormat:@"%@ %@", graphUser.first_name, graphUser.middle_name];
        } else {
            return graphUser.first_name;
        }
    } else {
        return graphUser.last_name;
    }
    
}

- (UIImage *)graphObjectTableDataSource:(FBGraphObjectTableDataSource *)dataSource
                       pictureUrlOfItem:(id<FBGraphObject>)graphObject
{
    return [graphObject objectForKey:@"picture"];
}

- (void)graphObjectTableDataSource:(FBGraphObjectTableDataSource*)dataSource
                customizeTableCell:(FBGraphObjectTableCell*)cell
{
    // We want to bold whichever part of the name we are sorting on.
    cell.boldTitle = (self.sortOrdering == FBFriendSortByFirstName && self.displayOrdering == FBFriendDisplayByFirstName) ||
        (self.sortOrdering == FBFriendSortByLastName && self.displayOrdering == FBFriendDisplayByLastName);
    cell.boldTitleSuffix = (self.sortOrdering == FBFriendSortByFirstName && self.displayOrdering == FBFriendDisplayByLastName) ||
        (self.sortOrdering == FBFriendSortByLastName && self.displayOrdering == FBFriendDisplayByFirstName);    
}

#pragma mark FBGraphObjectPagingLoaderDelegate members

- (void)pagingLoader:(FBGraphObjectPagingLoader*)pagingLoader willLoadURL:(NSString*)url {
    [self centerAndStartSpinner];
}

- (void)pagingLoader:(FBGraphObjectPagingLoader*)pagingLoader didLoadData:(NSDictionary*)results {
    // This logging currently goes here because we're effectively complete with our initial view when 
    // the first page of results come back.  In the future, when we do caching, we will need to move
    // this to a more appropriate place (e.g., after the cache has been brought in).
    [FBLogger singleShotLogEntry:FBLogBehaviorPerformanceCharacteristics
                    timestampTag:self
                    formatString:@"Friend Picker: first render "];  // logger will append "%d msec"
    
    
    if ([self.delegate respondsToSelector:@selector(friendPickerViewControllerDataDidChange:)]) {
        [self.delegate friendPickerViewControllerDataDidChange:self];
    }
}

- (void)pagingLoaderDidFinishLoading:(FBGraphObjectPagingLoader *)pagingLoader {
    // finished loading, stop animating
    [self.spinner stopAnimating];
    
    // if our current display is from cache, then kick-off a near-term refresh
    if (pagingLoader.isResultFromCache) {
        [self performSelector:@selector(loadDataSkippingRoundTripIfCached:) 
                   withObject:[NSNumber numberWithBool:NO]
                   afterDelay:FBRefreshCacheDelaySeconds];
    }    
}

- (void)pagingLoader:(FBGraphObjectPagingLoader*)pagingLoader handleError:(NSError*)error {
    if ([self.delegate
         respondsToSelector:@selector(friendPickerViewController:handleError:)]) {
        [self.delegate friendPickerViewController:self handleError:error];
    }
}

- (void)pagingLoaderWasCancelled:(FBGraphObjectPagingLoader*)pagingLoader {
    [self.spinner stopAnimating];
}

@end
