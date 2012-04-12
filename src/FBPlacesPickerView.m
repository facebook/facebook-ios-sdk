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

#import "FBPlacesPickerView.h"
#import "FBRequest.h"
#import "FBURLConnection.h"
#import "SBJSON.h"
#import "FBSubtitledTableViewCell.h"
#import "FBGraphObject.h"

static const NSInteger FBPlacesDefaultMaxCount = 100;
static const NSInteger FBPlacesDefaultRadius = 1000; // 1km

static const NSString* FBPlacesQueryString = 
    @"%@/search?type=place&limit=%d&center=%lf,%lf&distance=%d&access_token=%@";

@interface FBPlacesPickerView() <UITableViewDataSource, UITableViewDelegate>
{
    BOOL _imageFetchedSynchronously;
    UIImage* _genericPinImage;
}

@property (retain, nonatomic) UITableView* tableView;
@property (retain, nonatomic) UIActivityIndicatorView* spinner;
@property (retain, nonatomic) NSMutableArray* placesList;
@property (retain, nonatomic) NSMutableDictionary* cdnURLMap;
@property (retain, nonatomic) FBURLConnection* outstandingConnection;

- (void)initialize;
- (void)gatherPlacesList;
- (void)assignPictureToCellForIndex:(NSIndexPath*)indexPath 
    tableCell:(UITableViewCell*)cell;

@end

@implementation FBPlacesPickerView

@synthesize session = _session;
@synthesize locationCoordinate = _locationCoordinate;
@synthesize maxCount = _maxCount;
@synthesize searchText = _searchText;
@synthesize radius = _radius;
@synthesize delegate = _delegate;

@synthesize tableView = _tableView;
@synthesize spinner = _spinner;
@synthesize placesList = _placesList;
@synthesize outstandingConnection = _outstandingConnection;
@synthesize cdnURLMap = _cdnURLMap;

#pragma mark - Lifecycle

- (void)dealloc
{
    [_spinner removeFromSuperview];
    [_tableView removeFromSuperview];
    
    [_session release];
    [_searchText release];
    [_tableView release];
    [_spinner release];
    [_placesList release];
    [_cdnURLMap release];
    [_genericPinImage release];
    
    [_outstandingConnection cancel]; // Okay to cancel even if not outstanding
    [_outstandingConnection release];

    [super dealloc];
}

- (id)init 
{
    self = [super init];
    if (self) {
        [self initialize];
    }
    
    return self;
}

- (id)initWithSession:(FBSession*)session 
{
    self = [self init];
    if (self) {
        self.session = session;
    }
    
    return self;
}

- (id)initWithSession:(FBSession*)session 
             location:(CLLocationCoordinate2D)location
           searchText:(NSString*)searchText
{
    self = [self init];
    if (self) {
        self.session = session;
        self.searchText = searchText;
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame 
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

#pragma mark -

- (void)initialize
{
    // Default values
    _genericPinImage = [[UIImage imageNamed:@"FBiOSSDKResources.bundle/FBPlacesPickerView/images/fb_generic_place.png"] retain];
    self.cdnURLMap = [[[NSMutableDictionary alloc] init] autorelease];
    self.placesList = [[[NSMutableArray alloc] init] autorelease];
    self.maxCount = FBPlacesDefaultMaxCount;
    self.radius = FBPlacesDefaultRadius;
    self.locationCoordinate = CLLocationCoordinate2DMake(0, 181);        
    
    UITableView* tableView = 
        [[UITableView alloc] initWithFrame:self.bounds];
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.autoresizingMask = 
        UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
    self.tableView = tableView;
    [tableView release];
    
    UIActivityIndicatorView* spinner = 
        [[UIActivityIndicatorView alloc] initWithFrame:self.bounds];
    spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    spinner.hidesWhenStopped = YES;
    spinner.autoresizingMask = 
        UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.spinner = spinner;
    [spinner release];

    self.autoresizesSubviews = true;
    self.clipsToBounds = true;
    [self addSubview:self.tableView];
    [self addSubview:self.spinner];
}

- (void)gatherPlacesList
{
    // TODO: Use FBRequest here instead
    [self.spinner startAnimating];
    
    NSString* accessToken = self.session.accessToken;
    NSString* url = [NSString stringWithFormat:(NSString*)FBPlacesQueryString,
        FBGraphBasePath,
        self.maxCount,
        self.locationCoordinate.latitude,
        self.locationCoordinate.longitude,
        self.radius,
        accessToken];
    if (self.searchText) {
        // TODO: we need to urlencode the search text.  This will be 
        // superseded by FBRequest
        url = [url stringByAppendingFormat:@"&q=%@", self.searchText];
    }
     
    FBURLConnectionHandler connHandler = 
        ^(FBURLConnection* connection, 
            NSError* error, 
            NSURLResponse* response, 
            NSData* responseData) 
        {
            self.outstandingConnection = nil;

            [self.spinner stopAnimating];
            [self.placesList removeAllObjects];
            
            if (error) {
                NSLog(@"FBPlacesPicker Error: %@", error.localizedDescription);
                [self.tableView reloadData];
                return;
            } 
            
            NSString* json = [[[NSString alloc] 
                initWithData:responseData encoding:NSUTF8StringEncoding]
                autorelease];
            SBJSON* parser = [[[SBJSON alloc] init] autorelease];
            
            NSError* parseError = nil;
            NSDictionary* outerObject = 
                [parser objectWithString:json error:&parseError];
            if (parseError) {
                NSLog(
                    @"FBPlacesPicker Error: %@", 
                    parseError.localizedDescription);
                [self.tableView reloadData];
                return;
            }
            
            if (![outerObject isKindOfClass:[NSDictionary class]]) {
                NSLog(
                    @"FBPlacesPicker Error: Data from server is not of "
                    @"expected format.");
                [self.tableView reloadData];
                return;
            }
            
            NSDictionary* errorObject =
                [outerObject objectForKey:@"error"];
            if (errorObject) {
                NSLog(
                    @"FBPlacesPicker Error: %@",
                    [errorObject objectForKey:@"message"]);
                [self.tableView reloadData];
                return;
            }
                
            NSArray* data = [outerObject objectForKey:@"data"];
            if (data && [data isKindOfClass:[NSArray class]]) {
                for (NSDictionary* p in data) {
                    if ([p isKindOfClass:[NSDictionary class]]) {
                        [self.placesList addObject:p];
                    }
                }
            }
            
            [self.tableView reloadData];
        };

    if (self.outstandingConnection) {
        [self.outstandingConnection cancel];
    }
    
    self.outstandingConnection = [[[FBURLConnection alloc] 
        initWithURL:[NSURL URLWithString:url]
        completionHandler:connHandler] autorelease];
}

- (void)loadData
{        
    NSAssert(
        self.locationCoordinate.latitude >= -90.0f && 
        self.locationCoordinate.latitude <= 90.0f &&
        self.locationCoordinate.longitude >= -180.0f &&
        self.locationCoordinate.longitude <= 180.0f,
        @"FBPlacesPicker: A valid Location must be set.");
    
    if (self.session.isValid) {    
        [self gatherPlacesList];
    } else {
        NSLog(@"FBPlacesPickerView error: Session is not valid.");
    }
}

- (void)assignPictureToCellForIndex:(NSIndexPath*)indexPath
    tableCell:(UITableViewCell*)cell
{
    static NSString* urlTemplate = @"%@/%@/picture";
    cell.imageView.image = _genericPinImage;
    
    NSDictionary* dataItem = [self.placesList objectAtIndex:indexPath.row];
    if (!dataItem) {
        return;
    }
    
    NSString* placeId = [dataItem objectForKey:@"id"];
    if (!placeId) {
        // Nothing to do here... move along
        return;
    }
    
    NSURL* url = [self.cdnURLMap objectForKey:placeId];
    if (!url) {
        NSString* urlStr = 
            [NSString stringWithFormat:urlTemplate, FBGraphBasePath, placeId];
        url = [NSURL URLWithString:urlStr];
    }
    
    // Let the FBURLConnection cache kick in here
    _imageFetchedSynchronously = YES;
    [[[FBURLConnection alloc] 
        initWithURL:url 
        completionHandler:^(FBURLConnection *connection, 
            NSError *error, 
            NSURLResponse *response, 
            NSData *responseData) 
        {
            if (!error) {
                if (![self.cdnURLMap objectForKey:placeId] && 
                    response != nil) {
                    [self.cdnURLMap setObject:response.URL forKey:placeId];
                }

                UIImage* image = [UIImage imageWithData:responseData];
                UITableViewCell* currentCell = cell;
                if (!_imageFetchedSynchronously) {
                    currentCell = 
                        [self.tableView cellForRowAtIndexPath:indexPath];
                }
                
                if (currentCell) {
                    // Only if the cell is still visible
                    currentCell.imageView.image = image;
                }
            }
        }] autorelease];
    _imageFetchedSynchronously = NO;
    
}

#pragma mark - Table View protocol implementation

- (NSInteger)tableView:(UITableView*)tableView 
    numberOfRowsInSection:(NSInteger)section
{
    return self.placesList.count;
}

- (BOOL)tableView:(UITableView*)tableView 
    canEditRowAtIndexPath:(NSIndexPath *)indexPath 
{
    return false;
}

- (void)tableView:(UITableView *)tableView 
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.delegate) {        
        NSDictionary<FBGraphPlace> *dataItem = (NSDictionary<FBGraphPlace> *)[FBGraphObject graphObjectWrappingDictionary:
                                                 [self.placesList objectAtIndex:indexPath.row]];
        [self.delegate placesPicker:self didPickPlace:dataItem];
    }
}

- (UITableViewCell*)tableView:(UITableView*)tableView 
    cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString *cellIdentifier = @"PlacesViewCell";

    NSDictionary* dataItem = [self.placesList objectAtIndex:indexPath.row];
    FBSubtitledTableViewCell *cell = 
        [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = 
            [[[FBSubtitledTableViewCell alloc] 
                initWithStyle:UITableViewCellStyleDefault 
                reuseIdentifier:cellIdentifier] autorelease];
    }
    
    NSDictionary* location = [dataItem objectForKey:@"location"];
    
    NSString* name = [dataItem objectForKey:@"name"];
    NSString* subtitle = [location objectForKey:@"street"];
    
    if (!subtitle) {
        // Try a different value for subtitle
        subtitle = [location objectForKey:@"city"];
    }
    
    cell.title = name;
    cell.subtitle = subtitle;

    [self assignPictureToCellForIndex:indexPath tableCell:cell];
    return cell;
}

@end

