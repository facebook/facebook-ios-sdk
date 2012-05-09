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
#import "FBPlacesPickerViewController.h"
#import "FBRequestConnection.h"
#import "FBRequest.h"
#import "FBError.h"

static const NSInteger defaultResultsLimit = 100;
static const NSInteger defaultRadius = 1000; // 1km
static NSString *defaultImageName =
@"FBiOSSDKResources.bundle/FBPlacesPickerView/images/fb_generic_place.png";

@interface FBPlacesPickerViewController () <FBPlacesPickerDelegate,
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

@implementation FBPlacesPickerViewController {
    FBRequestConnection *_connection;
    FBGraphObjectTableDataSource *_dataSource;
    id<FBPlacesPickerDelegate> _delegate;
    NSSet *_fieldsForRequest;
    CLLocationCoordinate2D _locationCoordinate;
    NSInteger _radius;
    NSInteger _resultsLimit;
    NSString *_searchText;
    UITextField *_searchTextField;
    BOOL _searchTextEnabled;
    FBGraphObjectTableSelection *_selectionManager;
    FBSession *_session;
    UIActivityIndicatorView *_spinner;
    UITableView *_tableView;
}

@synthesize connection = _connection;
@synthesize dataSource = _dataSource;
@synthesize delegate = _delegate;
@synthesize fieldsForRequest = _fieldsForRequest;
@synthesize locationCoordinate = _locationCoordinate;
@synthesize radius = _radius;
@synthesize resultsLimit = _resultsLimit;
@synthesize searchText = _searchText;
@synthesize searchTextEnabled = _searchTextEnabled;
@synthesize searchTextField = _searchTextField;
@synthesize selectionManager = _selectionManager;
@synthesize session = _session;
@synthesize spinner = _spinner;
@synthesize tableView = _tableView;

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
    dataSource.itemSubtitleEnabled = YES;
    self.dataSource = dataSource;

    // Selection Manager
    FBGraphObjectTableSelection *selectionManager = [[FBGraphObjectTableSelection alloc]
                                                     initWithDataSource:dataSource];
    selectionManager.delegate = self;

    // Self
    self.dataSource = dataSource;
    self.delegate = self;
    self.selectionManager = selectionManager;
    self.searchTextEnabled = YES;
    self.resultsLimit = defaultResultsLimit;
    self.radius = defaultRadius;
    self.itemPicturesEnabled = YES;

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
    [_searchText release];
    [_searchTextField release];
    [_selectionManager release];
    [_session release];
    [_spinner release];
    [_tableView release];
    
    [super dealloc];
}

#pragma mark - Custom Properties

- (BOOL)itemPicturesEnabled
{
    return self.dataSource.itemPicturesEnabled;
}

- (void)setItemPicturesEnabled:(BOOL)itemPicturesEnabled
{
    self.dataSource.itemPicturesEnabled = itemPicturesEnabled;
}

- (id<FBGraphPlace>)selection
{
    NSArray *selection = self.selectionManager.selection;
    if ([selection count]) {
        return [selection objectAtIndex:0];
    } else {
        return nil;
    }
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
        tableView.allowsMultipleSelection = NO;
        tableView.autoresizingMask =
            UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        self.tableView = tableView;
        [self.view addSubview:tableView];
        [tableView release];
    }

    if (!self.spinner) {
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithFrame:bounds];
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
    NSString *fields = [self.dataSource fieldsForRequestIncluding:self.fieldsForRequest,
                        @"id", @"name", @"location", @"category", @"picture", nil];
    NSString *limit = [NSString stringWithFormat:@"%d", self.resultsLimit];
    NSString *center = [NSString stringWithFormat:@"%lf,%lf",
                        self.locationCoordinate.latitude,
                        self.locationCoordinate.longitude];
    NSString *distance = [NSString stringWithFormat:@"%d", self.radius];

    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:@"place" forKey:@"type"];
    [parameters setObject:fields forKey:@"fields"];
    [parameters setObject:limit forKey:@"limit"];
    [parameters setObject:center forKey:@"center"];
    [parameters setObject:distance forKey:@"distance"];

    if ([self.searchText length]) {
        [parameters setObject:self.searchText forKey:@"q"];
    }

    FBRequest *request = [[FBRequest alloc] initWithSession:self.session
                                                  graphPath:@"search"
                                                 parameters:parameters
                                                 HTTPMethod:@"GET"];
    [parameters release];

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
        if ([self.delegate respondsToSelector:@selector(placesPickerViewController:handleError:)]) {
            [self.delegate placesPickerViewController:self handleError:error];
        }
    } else {
        [self.dataSource setViewData:data];
    }
    
    [self updateView];
}

- (void)searchTextChanged:(UITextField *)textField
{
    if (textField == self.searchTextField) {
        self.searchText = textField.text;
        [self loadData];
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
         @selector(placesPickerViewControllerSelectionDidChange:)]) {
        [self.delegate placesPickerViewControllerSelectionDidChange:self];
    }
}

#pragma mark - FBGraphObjectViewControllerDelegate

- (BOOL)graphObjectTableDataSource:(FBGraphObjectTableDataSource *)dataSource
                filterIncludesItem:(id<FBGraphObject>)item
{
    id<FBGraphPlace> place = (id<FBGraphPlace>)item;

    if ([self.delegate
         respondsToSelector:@selector(placesPickerViewController:shouldIncludePlace:)]) {
        return [self.delegate placesPickerViewController:self
                                      shouldIncludePlace:place];
    } else {
        return YES;
    }
}

- (NSString *)graphObjectTableDataSource:(FBGraphObjectTableDataSource *)dataSource
                             titleOfItem:(id<FBGraphObject>)graphObject
{
    return [graphObject objectForKey:@"name"];
}

- (NSString *)graphObjectTableDataSource:(FBGraphObjectTableDataSource *)dataSource
                          subtitleOfItem:(id<FBGraphObject>)graphObject
{
    id<FBGraphPlace> place = (id<FBGraphPlace>)graphObject;
    id<FBGraphLocation> location = place.location;
    NSString *street = location.street;
    if (street) {
        return street;
    }
    return location.city;
}

- (UIImage *)graphObjectTableDataSource:(FBGraphObjectTableDataSource *)dataSource
                       pictureUrlOfItem:(id<FBGraphObject>)graphObject
{
    return [graphObject objectForKey:@"picture"];
}

@end

