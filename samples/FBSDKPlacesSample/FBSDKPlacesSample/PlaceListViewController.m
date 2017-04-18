// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "PlaceListViewController.h"

#import <CoreLocation/CoreLocation.h>

#import <FBSDKPlacesKit/FBSDKPlacesKit.h>
@import MapKit;

#import "Place.h"
#import "PlaceDetailViewController.h"

#define placeFields @[FBSDKPlacesFieldKeyName, FBSDKPlacesFieldKeyAbout, FBSDKPlacesFieldKeyPlaceID, FBSDKPlacesFieldKeyLocation]
#define placeFieldsWithConfidence @[FBSDKPlacesFieldKeyName, FBSDKPlacesFieldKeyAbout, FBSDKPlacesFieldKeyPlaceID, FBSDKPlacesFieldKeyLocation, FBSDKPlacesFieldKeyConfidence]

static NSString *const ResultsCellIdentifier = @"ResultsCellIdentifier";

typedef NS_ENUM(NSInteger, PlacesMode) {
  PlacesModeSearch,
  PlacesModeCurrent
};

@interface PlaceListViewController () <UITableViewDelegate, UISearchBarDelegate, UITabBarDelegate>

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UITabBar *tabBar;

@property (nonatomic, strong) FBSDKPlacesManager *placesManager;
@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, strong) CLLocation *mostRecentLocation;

@property (nonatomic, copy) NSArray<Place *> *placeSearchResults;
@property (nonatomic, copy) NSArray<Place *> *currentPlaceCandidates;
@property (nonatomic, copy) NSString *currentPlacesTrackingID;

@property (nonatomic, assign) PlacesMode mode;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchBarTopConstraint;

@end

@implementation PlaceListViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedWhenInUse) {
    self.locationManager = [CLLocationManager new];
    [self.locationManager requestWhenInUseAuthorization];
  }

  self.placesManager = [FBSDKPlacesManager new];
  [self fetchCurrentPlaces];

  self.tabBar.selectedItem = self.tabBar.items[0];
  self.tabBar.delegate = self;

  self.searchBar.delegate = self;
  [self.searchBar becomeFirstResponder];

  [self refreshUI];
}

#pragma mark - FBSDKPlacesKit calls

- (void)fetchCurrentPlaces
{
  [self.placesManager
   generateCurrentPlaceRequestWithMinimumConfidenceLevel:FBSDKPlaceLocationConfidenceNotApplicable
   fields:placeFieldsWithConfidence
   completion:^(FBSDKGraphRequest * _Nullable graphRequest, NSError * _Nullable error) {
     if (graphRequest) {
       [graphRequest startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *requestError) {
         self.currentPlaceCandidates = [self parsePlacesJSON:result[FBSDKPlacesResponseKeyData]];
         self.currentPlacesTrackingID = result[FBSDKPlacesParameterKeySummary][FBSDKPlacesSummaryKeyTracking];
         [self refreshUI];
       }];
     }
   }];
}

- (void)performSearchForTerm:(NSString *)searchTerm
{
  void (^graphCompletionHandler)(FBSDKGraphRequestConnection *connection, id result, NSError *error) = ^void(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
    if (!error)  {
      self.placeSearchResults = [self parsePlacesJSON:result[FBSDKPlacesResponseKeyData]];
    }
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      [self refreshUI];
    }];
  };

  if (self.mostRecentLocation) {
    FBSDKGraphRequest *graphRequest = [self.placesManager
                                       placeSearchRequestForLocation:self.mostRecentLocation
                                       searchTerm:searchTerm
                                       categories:nil fields:placeFields
                                       distance:0
                                       cursor:nil];
    [graphRequest startWithCompletionHandler:graphCompletionHandler];
  }
  else {
    [self.placesManager
     generatePlaceSearchRequestForSearchTerm:searchTerm
     categories:nil
     fields:placeFields
     distance:0 cursor:nil
     completion:^(FBSDKGraphRequest * _Nullable graphRequest, CLLocation * _Nullable location, NSError * _Nullable error) {
       if (location) {
         self.mostRecentLocation = location;
       }

       if (graphRequest) {
         [graphRequest startWithCompletionHandler:graphCompletionHandler];
       }
       else {
         [self refreshUI];
       }
     }];
  }
}

#pragma mark - Search Bar Delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
  [searchBar resignFirstResponder];
  [self performSearchForTerm:searchBar.text];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
  [searchBar resignFirstResponder];
}

#pragma mark - Tableview Datasource/Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  if (self.mode == PlacesModeSearch) {
      return self.placeSearchResults.count;
  }
  else {
    return self.currentPlaceCandidates.count;
  }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  if (self.mode == PlacesModeSearch) {
    return @"Search Results";
  }
  else {
    return @"Current Place Candidates";
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ResultsCellIdentifier];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ResultsCellIdentifier];
  }

  Place *place = [self placeForRow:indexPath.row];

  cell.textLabel.text = place.title;
  cell.detailTextLabel.text = place.subTitle;

  if ([place.confidence isEqualToString:@"low"]) {
    cell.textLabel.textColor = [UIColor redColor];
  }
  else if ([place.confidence isEqualToString:@"medium"]) {
    cell.textLabel.textColor = [UIColor orangeColor];
  }
  else if ([place.confidence isEqualToString:@"high"]) {
    cell.textLabel.textColor = [UIColor greenColor];
  }
  else {
    cell.textLabel.textColor = [UIColor blackColor];
  }

  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:YES];

  UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
  PlaceDetailViewController *placeDetailVC = [storyboard instantiateViewControllerWithIdentifier:@"PlaceDetail"];
  placeDetailVC.place = [self placeForRow:indexPath.row];
  placeDetailVC.placesManger = self.placesManager;
  if (self.mode == PlacesModeCurrent) {
    placeDetailVC.currentPlacesTrackingID = self.currentPlacesTrackingID;
  }
  [self.navigationController pushViewController:placeDetailVC animated:YES];
}

#pragma mark - Tab Bar

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {

  self.mode = item.tag; // Tags have been set to reflect the modes
  [self refreshUI];
}

#pragma mark - Helper Methods

- (NSArray<Place *> *)parsePlacesJSON:(NSArray<NSDictionary *> *)placesJSON
{
  NSMutableArray *places = [NSMutableArray new];
  for (NSDictionary *placeDict in placesJSON) {
    [places addObject:[[Place alloc] initWithDictionary:placeDict]];
  }
  return [places copy];
}

- (void)refreshUI
{
  if (self.mode == PlacesModeSearch) {
    self.title = @"Search";
    self.searchBar.hidden = NO;
    self.searchBarTopConstraint.constant = 0;
  }
  else {
    self.title = @"Current Place";
    self.searchBar.hidden = YES;
    self.searchBarTopConstraint.constant = -44;
  }

  [self.tableView reloadData];

  NSArray *annotations = (self.mode == PlacesModeSearch) ? self.placeSearchResults : self.currentPlaceCandidates;

  [self.mapView removeAnnotations:self.mapView.annotations];
  [self.mapView addAnnotations:annotations];
  [self.mapView showAnnotations:annotations animated:YES];
}

- (Place *)placeForRow:(NSInteger)row
{
  return (self.mode == PlacesModeSearch) ? self.placeSearchResults[row] : self.currentPlaceCandidates[row];
}

@end
