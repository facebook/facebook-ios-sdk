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

#import "ViewController.h"
#import "AppDelegate.h"

@interface ViewController () <CLLocationManagerDelegate, FBPlacesPickerDelegate>

@property (strong, nonatomic) CLLocationManager* locationManager;

- (IBAction)onClickManual:(id)sender;
- (IBAction)onClickSanFrancisco:(id)sender;
- (IBAction)onClickSeattle:(id)sender;

- (IBAction)filterNone:(id)sender;
- (IBAction)filterRestaurants:(id)sender;
- (IBAction)filterLocalBusinesses:(id)sender;
- (IBAction)filterHotels:(id)sender;

- (void)refresh;

@end

@implementation ViewController

@synthesize locationManager = _locationManager;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)refresh
{
    AppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    if (appDelegate.session.isValid) {
        self.session = appDelegate.session;

        // Default to Seattle
        [self onClickSeattle:nil];
    } else {
        [appDelegate.session loginWithCompletionHandler:
            ^(FBSession *session, FBSessionState status, NSError *error) 
            {
                if (!error) {
                    [self refresh];
                } else {
                    UIAlertView* alertView = 
                    [[UIAlertView alloc] initWithTitle:@"Error"
                        message:error.localizedDescription
                        delegate:nil
                        cancelButtonTitle:@"OK" 
                        otherButtonTitles:nil];
                    [alertView show];
                }
            }
        ];
    }
}

- (void)placesPickerViewControllerSelectionDidChange:(FBPlacesPickerViewController *)placesPicker
{
    id<FBGraphPlace> place = placesPicker.selection;

    // we'll use logging to show the simple typed property access to place and location info
    NSLog(@"place=%@, city=%@, state=%@, lat long=%@ %@", 
          place.name,
          place.location.city,
          place.location.state,
          place.location.latitude,
          place.location.longitude);
}

- (IBAction)onClickManual:(id)sender 
{
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;

    [self.locationManager startUpdatingLocation];
}

- (IBAction)onClickSanFrancisco:(id)sender 
{
    self.locationCoordinate = 
        CLLocationCoordinate2DMake(37.7750, -122.4183);
    [self loadData];
}

- (IBAction)onClickSeattle:(id)sender 
{
    self.locationCoordinate = 
        CLLocationCoordinate2DMake(47.6097, -122.3331);
    [self loadData];
}

- (IBAction)filterNone:(id)sender 
{
    self.searchText = nil;
    [self loadData];
}

- (IBAction)filterRestaurants:(id)sender 
{
    self.searchText = @"restaurant";
    [self loadData];
}

- (IBAction)filterLocalBusinesses:(id)sender 
{
    self.searchText = @"business";
    [self loadData];
}

- (IBAction)filterHotels:(id)sender 
{
    self.searchText = @"hotel";
    [self loadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self refresh];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
    (UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Location Manager delegate

- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
	fromLocation:(CLLocation *)oldLocation
{
    if (newLocation.horizontalAccuracy < 100) {
        // We wait for a precision of 100m and turn the GPS off
        [self.locationManager stopUpdatingLocation];
        self.locationManager = nil;
        
        self.locationCoordinate = newLocation.coordinate;
        [self loadData];
    }
}

@end
