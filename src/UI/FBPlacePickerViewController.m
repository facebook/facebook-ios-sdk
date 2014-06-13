/*
 * Copyright 2010-present Facebook.
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
#import "FBGraphObjectPagingLoader.h"
#import "FBGraphObjectTableDataSource.h"
#import "FBGraphObjectTableSelection.h"
#import "FBAppEvents+Internal.h"
#import "FBInternalSettings.h"
#import "FBLogger.h"
#import "FBPlacePickerViewController.h"
#import "FBRequest.h"
#import "FBRequestConnection.h"
#import "FBUtility.h"
#import "FBPlacePickerCacheDescriptor.h"
#import "FBSession+Internal.h"
#import "FBPlacePickerViewGenericPlacePNG.h"

NSString *const FBPlacePickerCacheIdentity = @"FBPlacePicker";

static const NSInteger searchTextChangedTimerInterval = 2;
const NSInteger defaultResultsLimit = 100;
const NSInteger defaultRadius = 1000; // 1km

@interface FBPlacePickerViewController () <FBGraphObjectSelectionChangedDelegate,
FBGraphObjectViewControllerDelegate,
FBGraphObjectPagingLoaderDelegate>

@property (nonatomic, retain) FBGraphObjectTableDataSource *dataSource;
@property (nonatomic, retain) FBGraphObjectTableSelection *selectionManager;
@property (nonatomic, retain) FBGraphObjectPagingLoader *loader;
@property (nonatomic, retain) NSTimer *searchTextChangedTimer;
@property (nonatomic) BOOL trackActiveSession;

- (void)initialize;
- (void)loadDataPostThrottleSkippingRoundTripIfCached:(NSNumber *)skipRoundTripIfCached;
- (NSTimer *)createSearchTextChangedTimer;
- (void)updateView;
- (void)centerAndStartSpinner;
- (void)addSessionObserver:(FBSession *)session;
- (void)removeSessionObserver:(FBSession *)session;
- (void)clearData;

@end

@implementation FBPlacePickerViewController {
    BOOL _hasSearchTextChangedSinceLastQuery;
}

- (instancetype)init
{
    self = [super init];

    if (self) {
        [self initialize];
    }

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self initialize];
    }

    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];


    if (self) {
        [self initialize];
    }

    return self;
}

- (void)initialize
{
    // Data Source
    FBGraphObjectTableDataSource *dataSource = [[[FBGraphObjectTableDataSource alloc]
                                                 init]
                                                autorelease];
    dataSource.defaultPicture = [FBPlacePickerViewGenericPlacePNG image];
    dataSource.controllerDelegate = self;
    dataSource.itemSubtitleEnabled = YES;

    // Selection Manager
    FBGraphObjectTableSelection *selectionManager = [[[FBGraphObjectTableSelection alloc]
                                                      initWithDataSource:dataSource]
                                                     autorelease];
    selectionManager.delegate = self;

    // Paging loader
    id loader = [[[FBGraphObjectPagingLoader alloc] initWithDataSource:dataSource
                                                            pagingMode:FBGraphObjectPagingModeAsNeeded]
                 autorelease];
    self.loader = loader;
    self.loader.delegate = self;

    // Self
    self.dataSource = dataSource;
    self.delegate = nil;
    self.selectionManager = selectionManager;
    self.selectionManager.allowsMultipleSelection = NO;
    self.resultsLimit = defaultResultsLimit;
    self.radiusInMeters = defaultRadius;
    self.itemPicturesEnabled = YES;
    self.trackActiveSession = YES;
}

- (void)dealloc
{
    [_loader cancel];
    _loader.delegate = nil;
    [_loader release];

    _dataSource.controllerDelegate = nil;

    [_dataSource release];
    [_fieldsForRequest release];
    [_searchText release];
    [_searchTextChangedTimer release];
    [_selectionManager release];
    [_spinner release];
    [_tableView release];

    [self removeSessionObserver:_session];
    [_session release];

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

- (void)setSession:(FBSession *)session {
    if (session != _session) {
        [self removeSessionObserver:_session];

        [_session release];
        _session = [session retain];

        [self addSessionObserver:session];

        self.loader.session = session;

        self.trackActiveSession = (session == nil);
    }
}

#pragma mark - Public Methods

- (void)loadData
{
    // when the app calls loadData,
    // if we don't have a session and there is
    // an open active session, use that
    if (!self.session ||
        (self.trackActiveSession && ![self.session isEqual:[FBSession activeSessionIfOpen]])) {
        self.session = [FBSession activeSessionIfOpen];
        self.trackActiveSession = YES;
    }

    // Sending a request on every keystroke is wasteful of bandwidth. Send a
    // request the first time the user types something, then set up a 2-second timer
    // and send whatever changes the user has made since then. (If nothing has changed
    // in 2 seconds, we reset so the next change will cause an immediate re-query.)
    if (!self.searchTextChangedTimer) {
        self.searchTextChangedTimer = [self createSearchTextChangedTimer];
        [self loadDataPostThrottleSkippingRoundTripIfCached:[NSNumber numberWithBool:YES]];
    } else {
        _hasSearchTextChangedSinceLastQuery = YES;
    }
}

- (void)configureUsingCachedDescriptor:(FBCacheDescriptor *)cacheDescriptor {
    if (![cacheDescriptor isKindOfClass:[FBPlacePickerCacheDescriptor class]]) {
        [[NSException exceptionWithName:FBInvalidOperationException
                                 reason:@"FBPlacePickerViewController: An attempt was made to configure "
          @"an instance with a cache descriptor object that was not created "
          @"by the FBPlacePickerViewController class"
                               userInfo:nil]
         raise];
    }
    FBPlacePickerCacheDescriptor *cd = (FBPlacePickerCacheDescriptor *)cacheDescriptor;
    self.locationCoordinate = cd.locationCoordinate;
    self.radiusInMeters = cd.radiusInMeters;
    self.resultsLimit = cd.resultsLimit;
    self.searchText = cd.searchText;
    self.fieldsForRequest = cd.fieldsForRequest;
}

- (void)clearSelection {
    [self.selectionManager clearSelectionInTableView:self.tableView];
}

#pragma mark - Public Class Methods

+ (FBCacheDescriptor *)cacheDescriptorWithLocationCoordinate:(CLLocationCoordinate2D)locationCoordinate
                                              radiusInMeters:(NSInteger)radiusInMeters
                                                  searchText:(NSString *)searchText
                                                resultsLimit:(NSInteger)resultsLimit
                                            fieldsForRequest:(NSSet *)fieldsForRequest {

    return [[[FBPlacePickerCacheDescriptor alloc] initWithLocationCoordinate:locationCoordinate
                                                              radiusInMeters:radiusInMeters
                                                                  searchText:searchText
                                                                resultsLimit:resultsLimit
                                                            fieldsForRequest:fieldsForRequest]
            autorelease];
}

#pragma mark - private methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    [FBLogger registerCurrentTime:FBLoggingBehaviorPerformanceCharacteristics
                          withTag:self];
    CGRect bounds = self.canvasView.bounds;

    if (!self.tableView) {
        UITableView *tableView = [[[UITableView alloc] initWithFrame:bounds] autorelease];
        tableView.autoresizingMask =
        UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        self.tableView = tableView;
        [self.canvasView addSubview:tableView];
    }

    if (!self.spinner) {
        UIActivityIndicatorView *spinner = [[[UIActivityIndicatorView alloc]
                                             initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray]
                                            autorelease];
        spinner.hidesWhenStopped = YES;
        // We want user to be able to scroll while we load.
        spinner.userInteractionEnabled = NO;

        self.spinner = spinner;
        [self.canvasView addSubview:spinner];
    }

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

+ (FBRequest *)requestForPlacesSearchAtCoordinate:(CLLocationCoordinate2D)coordinate
                                   radiusInMeters:(NSInteger)radius
                                     resultsLimit:(NSInteger)resultsLimit
                                       searchText:(NSString *)searchText
                                           fields:(NSSet *)fieldsForRequest
                                       datasource:(FBGraphObjectTableDataSource *)datasource
                                          session:(FBSession *)session {

    FBRequest *request = [FBRequest requestForPlacesSearchAtCoordinate:coordinate
                                                        radiusInMeters:radius
                                                          resultsLimit:resultsLimit
                                                            searchText:searchText];
    [request setSession:session];

    // Use field expansion to fetch a 100px wide picture if we're on a retina device.
    NSString *pictureField = ([FBUtility isRetinaDisplay]) ? @"picture.width(100).height(100)" : @"picture";

    NSString *fields = [datasource fieldsForRequestIncluding:fieldsForRequest,
                        @"id",
                        @"name",
                        @"location",
                        @"category",
                        pictureField,
                        @"were_here_count",
                        nil];

    [request.parameters setObject:fields forKey:@"fields"];

    return request;
}

- (void)loadDataPostThrottleSkippingRoundTripIfCached:(NSNumber *)skipRoundTripIfCached {
    // Place queries require a session, so do nothing if we don't have one.
    if (self.session) {
        FBRequest *request = [FBPlacePickerViewController requestForPlacesSearchAtCoordinate:self.locationCoordinate
                                                                              radiusInMeters:self.radiusInMeters
                                                                                resultsLimit:self.resultsLimit
                                                                                  searchText:self.searchText
                                                                                      fields:self.fieldsForRequest
                                                                                  datasource:self.dataSource
                                                                                     session:self.session];
        _hasSearchTextChangedSinceLastQuery = NO;
        [self.loader startLoadingWithRequest:request
                               cacheIdentity:FBPlacePickerCacheIdentity
                       skipRoundtripIfCached:skipRoundTripIfCached.boolValue];
    }
}

- (void)updateView
{
    [self.dataSource update];
    [self.tableView reloadData];
}

- (NSTimer *)createSearchTextChangedTimer {
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:searchTextChangedTimerInterval
                                                      target:self
                                                    selector:@selector(searchTextChangedTimerFired:)
                                                    userInfo:nil
                                                     repeats:YES];
    return timer;
}

- (void)searchTextChangedTimerFired:(NSTimer *)timer
{
    if (_hasSearchTextChangedSinceLastQuery) {
        [self loadDataPostThrottleSkippingRoundTripIfCached:[NSNumber numberWithBool:YES]];
    } else {
        // Nothing has changed in 2 seconds. Invalidate and forget about this timer.
        // Next time the user types, we will fire a query immediately again.
        [self.searchTextChangedTimer invalidate];
        self.searchTextChangedTimer = nil;
    }
}

- (void)centerAndStartSpinner
{
    [FBUtility centerView:self.spinner tableView:self.tableView];
    [self.spinner startAnimating];
}

- (void)addSessionObserver:(FBSession *)session {
    [session addObserver:self
              forKeyPath:@"state"
                 options:NSKeyValueObservingOptionNew
                 context:nil];
}

- (void)removeSessionObserver:(FBSession *)session {
    [session removeObserver:self
                 forKeyPath:@"state"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([object isEqual:self.session] &&
        self.session.isOpen == NO) {
        [self clearData];
    }
}

- (void)clearData {
    [self.dataSource clearGraphObjects];
    [self.selectionManager clearSelectionInTableView:self.tableView];
    [self.tableView reloadData];
    [self.loader reset];
}

- (void)logAppEvents:(BOOL)cancelled {
    [FBAppEvents logImplicitEvent:FBAppEventNamePlacePickerUsage
                       valueToSum:nil
                       parameters:@{ FBAppEventParameterDialogOutcome : (cancelled
                                                                         ? FBAppEventsDialogOutcomeValue_Cancelled
                                                                         : FBAppEventsDialogOutcomeValue_Completed),
                                     @"num_places_picked" : [NSNumber numberWithUnsignedInteger:self.selection.count]
                                     }
                          session:self.session];
}

#pragma mark - FBGraphObjectSelectionChangedDelegate

- (void)graphObjectTableSelectionDidChange:
(FBGraphObjectTableSelection *)selection
{
    if ([self.delegate respondsToSelector:
         @selector(placePickerViewControllerSelectionDidChange:)]) {
        [(id)self.delegate placePickerViewControllerSelectionDidChange:self];
    }
}

#pragma mark - FBGraphObjectViewControllerDelegate

- (BOOL)graphObjectTableDataSource:(FBGraphObjectTableDataSource *)dataSource
                filterIncludesItem:(id<FBGraphObject>)item
{
    id<FBGraphPlace> place = (id<FBGraphPlace>)item;

    if ([self.delegate
         respondsToSelector:@selector(placePickerViewController:shouldIncludePlace:)]) {
        return [(id)self.delegate placePickerViewController:self
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
    NSString *category = [graphObject objectForKey:@"category"];
    NSNumber *wereHereCount = [graphObject objectForKey:@"were_here_count"];

    NSMutableArray *parts = [NSMutableArray array];

    if (category) {
        [parts addObject:[category capitalizedString]];
    }
    if (wereHereCount) {
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
        NSString *wereHere = [numberFormatter stringFromNumber:wereHereCount];
        [numberFormatter release];

        [parts addObject:[NSString stringWithFormat:[FBUtility localizedStringForKey:@"FBPPVC:NumWereHere"
                                                                         withDefault:@"%@ were here"], wereHere]];
    }
    return [parts componentsJoinedByString:@" • "];
}

- (NSString *)graphObjectTableDataSource:(FBGraphObjectTableDataSource *)dataSource
                        pictureUrlOfItem:(id<FBGraphObject>)graphObject
{
    id picture = [graphObject objectForKey:@"picture"];
    // Depending on what migration the app is in, we may get back either a string, or a
    // dictionary with a "data" property that is a dictionary containing a "url" property.
    if ([picture isKindOfClass:[NSString class]]) {
        return picture;
    }
    id data = [picture objectForKey:@"data"];
    return [data objectForKey:@"url"];
}

#pragma mark FBGraphObjectPagingLoaderDelegate members

- (void)pagingLoader:(FBGraphObjectPagingLoader *)pagingLoader willLoadURL:(NSString *)url {
    // We only want to display our spinner on loading the first page. After that,
    // a spinner will display in the last cell to indicate to the user that data is loading.
    if ([self.dataSource numberOfSectionsInTableView:self.tableView] == 0) {
        [self centerAndStartSpinner];
    }
}

- (void)pagingLoader:(FBGraphObjectPagingLoader *)pagingLoader didLoadData:(NSDictionary *)results {
    [self.spinner stopAnimating];

    // This logging currently goes here because we're effectively complete with our initial view when
    // the first page of results come back.  In the future, when we do caching, we will need to move
    // this to a more appropriate place (e.g., after the cache has been brought in).
    [FBLogger singleShotLogEntry:FBLoggingBehaviorPerformanceCharacteristics
                    timestampTag:self
                    formatString:@"Places Picker: first render "];  // logger will append "%d msec"

    if ([self.delegate respondsToSelector:@selector(placePickerViewControllerDataDidChange:)]) {
        [(id)self.delegate placePickerViewControllerDataDidChange:self];
    }
}

- (void)pagingLoaderDidFinishLoading:(FBGraphObjectPagingLoader *)pagingLoader {
    // No more results, stop spinner
    [self.spinner stopAnimating];

    // Call the delegate from here as well, since this might be the first response of a query
    // that has no results.
    if ([self.delegate respondsToSelector:@selector(placePickerViewControllerDataDidChange:)]) {
        [(id)self.delegate placePickerViewControllerDataDidChange:self];
    }

    // if our current display is from cache, then kick-off a near-term refresh
    if (pagingLoader.isResultFromCache) {
        [self loadDataPostThrottleSkippingRoundTripIfCached:[NSNumber numberWithBool:NO]];
    }
}

- (void)pagingLoader:(FBGraphObjectPagingLoader *)pagingLoader handleError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(placePickerViewController:handleError:)]) {
        [(id)self.delegate placePickerViewController:self handleError:error];
    }
    
}

- (void)pagingLoaderWasCancelled:(FBGraphObjectPagingLoader *)pagingLoader {
    [self.spinner stopAnimating];
}

@end
