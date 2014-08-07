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
#import "FBGraphObjectPickerViewController+Internal.h"
#import "FBGraphObjectTableSelection.h"
#import "FBAppEvents+Internal.h"
#import "FBPlacePickerViewController.h"
#import "FBRequest.h"
#import "FBUtility.h"
#import "FBPlacePickerCacheDescriptor.h"
#import "FBPlacePickerViewGenericPlacePNG.h"

NSString *const FBPlacePickerCacheIdentity = @"FBPlacePicker";

static const NSInteger searchTextChangedTimerInterval = 2;
const NSInteger defaultResultsLimit = 100;
const NSInteger defaultRadius = 1000; // 1km

@interface FBPlacePickerViewController () <FBGraphObjectViewControllerDelegate>

@property (nonatomic, retain) NSTimer *searchTextChangedTimer;

- (NSTimer *)createSearchTextChangedTimer;

@end

@implementation FBPlacePickerViewController {
    BOOL _hasSearchTextChangedSinceLastQuery;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self initializePlacePicker];
    }

    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (self) {
        [self initializePlacePicker];
    }

    return self;
}

- (void)initializePlacePicker
{
    // Self
    self.resultsLimit = defaultResultsLimit;
    self.radiusInMeters = defaultRadius;
}

- (void)dealloc
{
    [_searchText release];
    [_searchTextChangedTimer release];

    [super dealloc];
}

#pragma mark - Custom Properties

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

#pragma mark - internal methods

+ (FBGraphObjectPagingMode)graphObjectPagingMode
{
    return FBGraphObjectPagingModeAsNeeded;
}

+ (NSString *)firstRenderLogString
{
    return @"Places Picker: first render ";
}

- (void)configureDataSource:(FBGraphObjectTableDataSource *)dataSource
{
    [super configureDataSource:dataSource];
    dataSource.defaultPicture = [FBPlacePickerViewGenericPlacePNG image];
    dataSource.controllerDelegate = self;
    dataSource.itemSubtitleEnabled = YES;
}

- (void)loadDataThrottledSkippingRoundTripIfCached:(NSNumber *)skipRoundTripIfCached
{
    // Sending a request on every keystroke is wasteful of bandwidth. Send a
    // request the first time the user types something, then set up a 2-second timer
    // and send whatever changes the user has made since then. (If nothing has changed
    // in 2 seconds, we reset so the next change will cause an immediate re-query.)
    if (!self.searchTextChangedTimer) {
        self.searchTextChangedTimer = [self createSearchTextChangedTimer];
        [self loadDataSkippingRoundTripIfCached:skipRoundTripIfCached];
    } else {
        _hasSearchTextChangedSinceLastQuery = YES;
    }
}

- (void)notifyDelegateDataDidChange
{
    [super notifyDelegateDataDidChange];

    id<FBPlacePickerDelegate> delegate = (id)self.delegate;
    if ([delegate respondsToSelector:@selector(placePickerViewControllerDataDidChange:)]) {
        [delegate placePickerViewControllerDataDidChange:self];
    }
}

- (void)notifyDelegateSelectionDidChange
{
    [super notifyDelegateSelectionDidChange];

    id<FBPlacePickerDelegate> delegate = (id)self.delegate;
    if ([delegate respondsToSelector:@selector(placePickerViewControllerSelectionDidChange:)]) {
        [delegate placePickerViewControllerSelectionDidChange:self];
    }
}

- (void)notifyDelegateOfError:(NSError *)error
{
    [super notifyDelegateOfError:error];

    id<FBPlacePickerDelegate> delegate = (id)self.delegate;
    if ([delegate respondsToSelector:@selector(placePickerViewController:handleError:)]) {
        [delegate placePickerViewController:self handleError:error];
    }
}

- (BOOL)delegateIncludesGraphObject:(id<FBGraphObject>)graphObject
{
    BOOL includesGraphObject = [super delegateIncludesGraphObject:graphObject];

    id<FBPlacePickerDelegate> delegate = (id)self.delegate;
    if (includesGraphObject && [delegate respondsToSelector:@selector(placePickerViewController:shouldIncludePlace:)]) {
        id<FBGraphPlace> place = (id<FBGraphPlace>)graphObject;
        includesGraphObject = [delegate placePickerViewController:self shouldIncludePlace:place];
    }
    return includesGraphObject;
}

#pragma mark - private methods

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

- (void)loadDataSkippingRoundTripIfCached:(NSNumber *)skipRoundTripIfCached {
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
        [self loadDataSkippingRoundTripIfCached:[NSNumber numberWithBool:YES]];
    } else {
        // Nothing has changed in 2 seconds. Invalidate and forget about this timer.
        // Next time the user types, we will fire a query immediately again.
        [self.searchTextChangedTimer invalidate];
        self.searchTextChangedTimer = nil;
    }
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

#pragma mark - FBGraphObjectViewControllerDelegate

- (BOOL)graphObjectTableDataSource:(FBGraphObjectTableDataSource *)dataSource
                filterIncludesItem:(id<FBGraphObject>)item
{
    return [self delegateIncludesGraphObject:item];
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

@end
