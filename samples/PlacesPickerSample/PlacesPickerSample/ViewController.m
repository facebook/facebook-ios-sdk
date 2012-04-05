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

#pragma mark - Lifecycle

- (void)dealloc
{
    [_locationManager release];
    [_placesPickerView release];
    [super dealloc];
}

#pragma mark -

- (void)refresh
{
    AppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    if (appDelegate.session.isValid) {
        self.placesPickerView.session = appDelegate.session;
        
        self.locationManager = [[[CLLocationManager alloc] init] autorelease];
        self.locationManager.delegate = self;

        [self.locationManager startUpdatingLocation];
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
                    [alertView release];
                }
            }
        ];
    }
}

- (IBAction)onClickRefresh:(id)sender 
{
    [self refresh];
}

- (IBAction)filterNone:(id)sender 
{
    self.placesPickerView.searchText = nil;
    [self refresh];
}

- (IBAction)filterRestaurants:(id)sender 
{
    self.placesPickerView.searchText = @"restaurant";
    [self refresh];
}

- (IBAction)filterLocalBusinesses:(id)sender 
{
    self.placesPickerView.searchText = @"business";
    [self refresh];
}

- (IBAction)filterHotels:(id)sender 
{
    self.placesPickerView.searchText = @"hotel";
    [self refresh];
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
