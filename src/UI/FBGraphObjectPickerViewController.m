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

#import "FBGraphObjectPickerViewController+Internal.h"

#import "FBGraphObjectPagingLoader.h"
#import "FBGraphObjectTableDataSource.h"
#import "FBGraphObjectTableSelection.h"
#import "FBLogger.h"
#import "FBSession+Internal.h"
#import "FBSettings.h"
#import "FBUtility.h"

@interface FBGraphObjectPickerViewController () <FBGraphObjectSelectionChangedDelegate,
FBGraphObjectPagingLoaderDelegate>

@property (nonatomic, retain) FBGraphObjectTableDataSource *dataSource;
@property (nonatomic, retain) FBGraphObjectTableSelection *selectionManager;
@property (nonatomic, retain) FBGraphObjectPagingLoader *loader;

@end

@implementation FBGraphObjectPickerViewController {
    FBSession *_session;
    BOOL _allowsMultipleSelection;
    BOOL _implicitSession;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self initializeGraphObjectPicker];
    }

    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];


    if (self) {
        [self initializeGraphObjectPicker];
    }

    return self;
}

- (void)initializeGraphObjectPicker
{
    self.itemPicturesEnabled = YES;
}

- (void)dealloc
{
    _loader.delegate = nil;
    [_loader cancel];
    [_loader release];

    _dataSource.controllerDelegate = nil;

    [_dataSource release];
    [_fieldsForRequest release];
    [_selectionManager release];
    [_spinner release];
    [_tableView release];

    [self _removeSessionObserver:_session];
    [_session release];

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

- (FBSession *)session
{
    if (!_session || _implicitSession) {
        [self setSession:[FBSession activeSessionIfOpen] implicit:YES];
    }
    return _session;
}

- (void)setSession:(FBSession *)session
{
    [self setSession:session implicit:NO];
}

- (void)setSession:(FBSession *)session implicit:(BOOL)isImplicit
{
    if (session != _session) {
        [self _removeSessionObserver:_session];

        [_session release];
        _session = [session retain];
        _implicitSession = isImplicit;

        [self _addSessionObserver:session];

        self.loader.session = session;
    }
}

#pragma mark - Public Methods

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

- (void)loadData
{
    [self loadDataThrottledSkippingRoundTripIfCached:[NSNumber numberWithBool:YES]];
}

- (void)updateView
{
    [self.dataSource update];
    [self.tableView reloadData];
}

- (void)clearSelection
{
    [self.selectionManager clearSelectionInTableView:self.tableView];
}

#pragma mark - internal methods

+ (FBGraphObjectPagingMode)graphObjectPagingMode
{
    return FBGraphObjectPagingModeImmediate;
}

+ (NSTimeInterval)cacheRefreshDelay
{
    return 0.0;
}

+ (NSString *)firstRenderLogString
{
    return nil;
}

- (FBGraphObjectTableDataSource *)dataSource
{
    if (_dataSource == nil) {
        _dataSource = [[FBGraphObjectTableDataSource alloc] init];
        [self configureDataSource:_dataSource];
    }
    return _dataSource;
}

- (FBGraphObjectTableSelection *)selectionManager
{
    if (_selectionManager == nil) {
        _selectionManager = [[FBGraphObjectTableSelection alloc] initWithDataSource:self.dataSource];
        _selectionManager.delegate = self;
        _selectionManager.allowsMultipleSelection = NO;
    }
    return _selectionManager;
}

- (FBGraphObjectPagingLoader *)loader
{
    if (_loader == nil) {
        _loader = [[FBGraphObjectPagingLoader alloc] initWithDataSource:self.dataSource
                                                             pagingMode:[[self class] graphObjectPagingMode]];
        _loader.delegate = self;
    }
    return _loader;
}

- (void)configureDataSource:(FBGraphObjectTableDataSource *)dataSource
{
}

- (void)loadDataThrottledSkippingRoundTripIfCached:(NSNumber *)skipRoundTripIfCached
{
    [self loadDataSkippingRoundTripIfCached:skipRoundTripIfCached];
}

- (void)loadDataSkippingRoundTripIfCached:(NSNumber *)skipRoundTripIfCached
{
    [[NSException exceptionWithName:NSInternalInconsistencyException
                             reason:@"FBGraphObjectPickerViewController: Invalid call to "
      @"-loadDataSkippingRoundTripIfCached:. This method must be implemented by a "
      @"subclass, which must not call super."
                           userInfo:nil]
     raise];
}

- (void)notifyDelegateDataDidChange
{
    id<FBGraphObjectPickerDelegate> delegate = (id)self.delegate;
    if ([delegate respondsToSelector:@selector(graphObjectPickerViewControllerDataDidChange:)]) {
        [delegate graphObjectPickerViewControllerDataDidChange:self];
    }
}

- (void)notifyDelegateSelectionDidChange
{
    id<FBGraphObjectPickerDelegate> delegate = (id)self.delegate;
    if ([delegate respondsToSelector:@selector(graphObjectPickerViewControllerSelectionDidChange:)]) {
        [delegate graphObjectPickerViewControllerSelectionDidChange:self];
    }
}

- (void)notifyDelegateOfError:(NSError *)error
{
    id<FBGraphObjectPickerDelegate> delegate = (id)self.delegate;
    if ([delegate respondsToSelector:@selector(graphObjectPickerViewController:handleError:)]) {
        [delegate graphObjectPickerViewController:self handleError:error];
    }
}

- (BOOL)delegateIncludesGraphObject:(id<FBGraphObject>)graphObject
{
    BOOL includesGraphObject = YES;
    id<FBGraphObjectPickerDelegate> delegate = (id)self.delegate;
    if ([delegate respondsToSelector:@selector(graphObjectPickerViewController:shouldIncludeGraphObject:)]) {
        includesGraphObject = [delegate graphObjectPickerViewController:self shouldIncludeGraphObject:graphObject];
    }
    return includesGraphObject;
}

#pragma mark - private methods

static char kFBGraphObjectPickerViewControllerSessionStateKVOContext;

- (void)_centerAndStartSpinner
{
    [FBUtility centerView:self.spinner tableView:self.tableView];
    [self.spinner startAnimating];
}

- (void)_addSessionObserver:(FBSession *)session
{
    [session addObserver:self
              forKeyPath:@"state"
                 options:NSKeyValueObservingOptionNew
                 context:&kFBGraphObjectPickerViewControllerSessionStateKVOContext];
}

- (void)_removeSessionObserver:(FBSession *)session
{
    [session removeObserver:self
                 forKeyPath:@"state"
                    context:&kFBGraphObjectPickerViewControllerSessionStateKVOContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context == &kFBGraphObjectPickerViewControllerSessionStateKVOContext) {
        if (self.session.isOpen == NO) {
            [self _clearData];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)_clearData
{
    [self.dataSource clearGraphObjects];
    [self.selectionManager clearSelectionInTableView:self.tableView];
    [self.tableView reloadData];
    [self.loader reset];
}

#pragma mark - FBGraphObjectSelectionChangedDelegate

- (void)graphObjectTableSelectionDidChange:(FBGraphObjectTableSelection *)selection
{
    [self notifyDelegateSelectionDidChange];
}

#pragma mark FBGraphObjectPagingLoaderDelegate members

- (void)pagingLoader:(FBGraphObjectPagingLoader *)pagingLoader willLoadURL:(NSString *)url
{
    // We only want to display our spinner when loading the first page when using as
    // needed paging and display the spinner when loading using immediate paging. After
    // the first page, is loading when using as needed paging, a spinner will display in
    // the last cell to indicate to the user that data is loading.
    if (([[self class] graphObjectPagingMode] != FBGraphObjectPagingModeAsNeeded) ||
        [self.dataSource numberOfSectionsInTableView:self.tableView] == 0) {
        [self _centerAndStartSpinner];
    }
}

- (void)pagingLoader:(FBGraphObjectPagingLoader *)pagingLoader didLoadData:(NSDictionary *)results
{
    if ([[self class] graphObjectPagingMode] == FBGraphObjectPagingModeAsNeeded) {
        [self.spinner stopAnimating];
    }

    // This logging currently goes here because we're effectively complete with our initial view when
    // the first page of results come back.  In the future, when we do caching, we will need to move
    // this to a more appropriate place (e.g., after the cache has been brought in).
    NSString *firstRenderLogString = [[self class] firstRenderLogString];
    if (firstRenderLogString) {
        [FBLogger singleShotLogEntry:FBLoggingBehaviorPerformanceCharacteristics
                        timestampTag:self
                        formatString:@"%@", firstRenderLogString];  // logger will append "%d msec"
    }

    [self notifyDelegateDataDidChange];
}

- (void)pagingLoaderDidFinishLoading:(FBGraphObjectPagingLoader *)pagingLoader
{
    // No more results, stop spinner
    [self.spinner stopAnimating];

    // Call the delegate from here as well, since this might be the first response of a query
    // that has no results.
    [self notifyDelegateDataDidChange];

    // if our current display is from cache, then kick-off a near-term refresh
    if (pagingLoader.isResultFromCache) {
        NSTimeInterval cacheRefreshDelay = 0.0;
        if (cacheRefreshDelay == 0.0) {
            [self loadDataSkippingRoundTripIfCached:[NSNumber numberWithBool:NO]];
        } else {
            [self performSelector:@selector(loadDataSkippingRoundTripIfCached:)
                       withObject:[NSNumber numberWithBool:NO]
                       afterDelay:cacheRefreshDelay];
        }
    }
}

- (void)pagingLoader:(FBGraphObjectPagingLoader *)pagingLoader handleError:(NSError *)error
{
    [self notifyDelegateOfError:error];
}

- (void)pagingLoaderWasCancelled:(FBGraphObjectPagingLoader *)pagingLoader
{
    [self.spinner stopAnimating];
}

@end
