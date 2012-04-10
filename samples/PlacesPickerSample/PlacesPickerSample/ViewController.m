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

@interface ViewController () <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager* locationManager;

- (void)refresh;

@end

@implementation ViewController

@synthesize placesPickerView = _placesPickerView;
@synthesize locationManager = _locationManager;

- (void)refresh
{
    AppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    if (appDelegate.session.isValid) {
        self.placesPickerView.session = appDelegate.session;

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

- (IBAction)onClickManual:(id)sender 
{
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;

    [self.locationManager startUpdatingLocation];
}

- (IBAction)onClickSanFrancisco:(id)sender 
{
    self.placesPickerView.locationCoordinate = 
        CLLocationCoordinate2DMake(37.7750, -122.4183);
    [self.placesPickerView loadData];
}

- (IBAction)onClickSeattle:(id)sender 
{
    self.placesPickerView.locationCoordinate = 
        CLLocationCoordinate2DMake(47.6097, -122.3331);
    [self.placesPickerView loadData];
}

- (IBAction)filterNone:(id)sender 
{
    self.placesPickerView.searchText = nil;
    [self.placesPickerView loadData];
}

- (IBAction)filterRestaurants:(id)sender 
{
    self.placesPickerView.searchText = @"restaurant";
    [self.placesPickerView loadData];
}

- (IBAction)filterLocalBusinesses:(id)sender 
{
    self.placesPickerView.searchText = @"business";
    [self.placesPickerView loadData];
}

- (IBAction)filterHotels:(id)sender 
{
    self.placesPickerView.searchText = @"hotel";
    [self.placesPickerView loadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self refresh];
}

- (void)viewDidUnload
{
    [self setPlacesPickerView:nil];
    [super viewDidUnload];
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
        
        self.placesPickerView.locationCoordinate = newLocation.coordinate;
        [self.placesPickerView loadData];
    }
}

@end
