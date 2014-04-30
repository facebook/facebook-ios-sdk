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

#import "SCMainViewController.h"

#import <AddressBook/AddressBook.h>
#import <CoreLocation/CoreLocation.h>

#import <FacebookSDK/FacebookSDK.h>

#import "SCErrorHandler.h"
#import "SCImagePicker.h"
#import "SCMealPicker.h"
#import "SCSettings.h"
#import "SCShareUtility.h"

@interface SCMainViewController () <CLLocationManagerDelegate, FBFriendPickerDelegate, FBPlacePickerDelegate, SCImagePickerDelegate, SCMealPickerDelegate, SCShareUtilityDelegate>
@property (nonatomic, strong) UIView *activityOverlayView;
@property (nonatomic, strong, readonly) FBCacheDescriptor *friendsCacheDescriptor;
@property (nonatomic, strong) SCImagePicker *imagePicker;
@property (nonatomic, strong, readonly) CLLocationManager *locationManager;
@property (nonatomic, strong) SCMealPicker *mealPicker;
@property (nonatomic, strong) FBCacheDescriptor *placeCacheDescriptor;
@property (nonatomic, copy) NSArray *selectedFriends;
@property (nonatomic, copy) NSString *selectedMeal;
@property (nonatomic, strong) UIImage *selectedPhoto;
@property (nonatomic, strong) id<FBGraphPlace> selectedPlace;
@property (nonatomic, strong) SCShareUtility *shareUtility;
@end

@implementation SCMainViewController
{
    FBCacheDescriptor *_friendsCacheDescriptor;
    CLLocationManager *_locationManager;
}

#pragma mark - Properties

- (void)setActivityOverlayView:(UIView *)activityOverlayView
{
    if (_activityOverlayView != activityOverlayView) {
        [_activityOverlayView removeFromSuperview];
        _activityOverlayView = activityOverlayView;
    }
}

- (FBCacheDescriptor *)friendsCacheDescriptor
{
    if (!_friendsCacheDescriptor) {
        _friendsCacheDescriptor = [FBFriendPickerViewController cacheDescriptor];
    }
    return _friendsCacheDescriptor;
}

- (void)setImagePicker:(SCImagePicker *)imagePicker
{
    if (_imagePicker != imagePicker) {
        _imagePicker.delegate = nil;
        _imagePicker = imagePicker;
    }
}

- (CLLocationManager *)locationManager
{
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        // We don't want to be notified of small changes in location, preferring to use our
        // last cached results, if any.
        _locationManager.distanceFilter = 50;
    }
    return _locationManager;
}

- (void)setMealPicker:(SCMealPicker *)mealPicker
{
    if (_mealPicker != mealPicker) {
        _mealPicker.delegate = nil;
        _mealPicker = mealPicker;
    }
}

- (FBCacheDescriptor *)placeCacheDescriptor
{
    if (!_placeCacheDescriptor) {
        // Lazily create a default descriptor if location has not been detected.  This can happen if the user has
        // declined access to location data.
        _placeCacheDescriptor = [self _placeCacheDescriptorWithLocationCoordinate:CLLocationCoordinate2DMake(48.857875, 2.294635)];
    }
    return _placeCacheDescriptor;
}

- (void)setSelectedFriends:(NSArray *)selectedFriends
{
    if (![_selectedFriends isEqualToArray:selectedFriends]) {
        _selectedFriends = [selectedFriends copy];

        NSString *friendsSubtitle;
        NSUInteger friendCount = _selectedFriends.count;
        if (friendCount > 2) {
            // Just to mix things up, don't always show the first friend.
            id<FBGraphUser> randomFriend = [self.selectedFriends objectAtIndex:arc4random() % friendCount];
            friendsSubtitle = [NSString stringWithFormat:@"%@ and %lu others",
                               randomFriend.name,
                               (unsigned long)friendCount - 1];
        } else if (friendCount == 2) {
            id<FBGraphUser> friend1 = [self.selectedFriends objectAtIndex:0];
            id<FBGraphUser> friend2 = [self.selectedFriends objectAtIndex:1];
            friendsSubtitle = [NSString stringWithFormat:@"%@ and %@",
                               friend1.name,
                               friend2.name];
        } else if (friendCount == 1) {
            id<FBGraphUser> friend = [self.selectedFriends objectAtIndex:0];
            friendsSubtitle = friend.name;
        }
        self.friendsLabel.text = friendsSubtitle;
    }
}

- (void)setSelectedMeal:(NSString *)selectedMeal
{
    if (![_selectedMeal isEqualToString:selectedMeal]) {
        _selectedMeal = [selectedMeal copy];
        self.mealLabel.text = _selectedMeal;
        self.shareButton.enabled = (selectedMeal != nil);
    }
}

- (void)setSelectedPhoto:(UIImage *)selectedPhoto
{
    if (![_selectedPhoto isEqual:selectedPhoto]) {
        _selectedPhoto = selectedPhoto;
        self.photoView.image = selectedPhoto;
    }
}

- (void)setSelectedPlace:(id<FBGraphPlace>)selectedPlace
{
    if (![_selectedPlace isEqual:selectedPlace]) {
        _selectedPlace = selectedPlace;
        self.locationLabel.text = _selectedPlace.name;
    }
}

- (void)setShareUtility:(SCShareUtility *)shareUtility
{
    if (![_shareUtility isEqual:shareUtility]) {
        _shareUtility.delegate = nil;
        _shareUtility = shareUtility;
    }
}

#pragma mark - View Management

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.profilePictureButton.pictureCropping = FBProfilePictureCroppingSquare;

    if ([FBSession activeSession].isOpen) {
        self.locationButton.enabled = YES;
        self.friendsButton.enabled = YES;
        self.profilePictureButton.profileID = @"me";
    } else {
        self.locationButton.enabled = NO;
        self.friendsButton.enabled = NO;
        self.profilePictureButton.profileID = nil;
    }
    self.shareButton.enabled = (self.selectedMeal != nil);

    [self.friendsCacheDescriptor prefetchAndCacheForSession:[FBSession activeSession]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if ([FBSession activeSession].isOpen) {
        [self.locationManager startUpdatingLocation];
    }
}

#pragma mark - Actions

- (IBAction)pickImage:(id)sender
{
    SCImagePicker *imagePicker = [[SCImagePicker alloc] init];
    self.imagePicker = imagePicker;
    imagePicker.delegate = self;
    if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) && [sender isKindOfClass:[UIView class]]) {
        UIView *senderView = (UIView *)sender;
        UIView *view = self.view;
        [imagePicker presentFromRect:[view convertRect:senderView.bounds fromView:senderView] inView:self.view];
    } else {
        [imagePicker presentWithViewController:self];
    }
}

- (IBAction)pickMeal:(id)sender
{
    SCMealPicker *mealPicker = [[SCMealPicker alloc] init];
    self.mealPicker = mealPicker;
    mealPicker.delegate = self;
    [mealPicker presentInView:self.view];
}

- (IBAction)share:(id)sender
{
    SCShareUtility *shareUtility = [[SCShareUtility alloc] initWithMealTitle:self.selectedMeal
                                                                       place:self.selectedPlace
                                                                     friends:self.selectedFriends
                                                                       photo:self.selectedPhoto];
    self.shareUtility = shareUtility;
    shareUtility.delegate = self;
    [shareUtility start];
}

- (IBAction)showMain:(UIStoryboardSegue *)segue
{
    // This method exists in order to create an unwind segue to this controller.
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *identifier = segue.identifier;
    if ([identifier isEqualToString:@"showPlacePicker"]) {
        FBPlacePickerViewController *placePickerViewController = segue.destinationViewController;
        [placePickerViewController configureUsingCachedDescriptor:self.placeCacheDescriptor];
        [placePickerViewController loadData];
        placePickerViewController.delegate = self;
    } else if ([identifier isEqualToString:@"showFriendPicker"]) {
        FBFriendPickerViewController *friendPickerViewController = segue.destinationViewController;
        // Set up the friend picker to sort and display names the same way as the
        // iOS Address Book does.

        // Need to call ABAddressBookCreate in order for the next two calls to do anything.
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        friendPickerViewController.sortOrdering = (ABPersonGetSortOrdering() == kABPersonSortByFirstName ? FBFriendSortByFirstName : FBFriendSortByLastName);
        friendPickerViewController.displayOrdering = (ABPersonGetCompositeNameFormat() == kABPersonCompositeNameFormatFirstNameFirst ? FBFriendDisplayByFirstName : FBFriendDisplayByLastName);
        CFRelease(addressBook);

        [friendPickerViewController configureUsingCachedDescriptor:self.friendsCacheDescriptor];
        [friendPickerViewController loadData];
        friendPickerViewController.selection = self.selectedFriends;
        friendPickerViewController.delegate = self;
    }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
    NSLog(@"CLLocationManager error: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *newLocation = [locations lastObject];
    NSUInteger locationCount = locations.count;
    CLLocation *oldLocation = (locationCount > 1 ? locations[locationCount - 2] : nil);

    if (!oldLocation ||
        ((oldLocation.coordinate.latitude != newLocation.coordinate.latitude) &&
         (oldLocation.coordinate.longitude != newLocation.coordinate.longitude) &&
         (newLocation.horizontalAccuracy <= 100.0))) {
            // Fetch data at this new location, and remember the cache descriptor.
            self.placeCacheDescriptor = [self _placeCacheDescriptorWithLocationCoordinate:newLocation.coordinate];
            [self.placeCacheDescriptor prefetchAndCacheForSession:[FBSession activeSession]];
        }
}

// unused, required delegate methods
- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region { }
- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region { }
- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error { }
- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager { }
- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager { }

#pragma mark - FBViewControllerDelegate

- (void)facebookViewControllerCancelWasPressed:(FBViewController *)sender
{
    [sender performSegueWithIdentifier:@"dismiss" sender:sender];
}

- (void)facebookViewControllerDoneWasPressed:(FBViewController *)sender
{
    if ([sender isKindOfClass:[FBPlacePickerViewController class]]) {
        self.selectedPlace = ((FBPlacePickerViewController *)sender).selection;
    } else if ([sender isKindOfClass:[FBFriendPickerViewController class]]) {
        self.selectedFriends = ((FBFriendPickerViewController *)sender).selection;
    }
    [sender performSegueWithIdentifier:@"dismiss" sender:sender];
}

#pragma mark - SCImagePickerDelegate

- (void)imagePicker:(SCImagePicker *)imagePicker didSelectImage:(UIImage *)image
{
    self.selectedPhoto = image;
    self.imagePicker = nil;
}

- (void)imagePickerDidCancel:(SCImagePicker *)imagePicker
{
    self.imagePicker = nil;
}

#pragma mark - SCMealPickerDelegate

- (void)mealPicker:(SCMealPicker *)mealPicker didSelectMealType:(NSString *)mealType
{
    self.selectedMeal = mealType;
    self.mealPicker = nil;
}

- (void)mealPickerDidCancel:(SCMealPicker *)mealPicker
{
    self.mealPicker = nil;
}

#pragma mark - SCShareUtilityDelegate
- (void)shareUtilityWillShare:(SCShareUtility *)shareUtility {
    [self _startActivityIndicator];
}

- (void)shareUtility:(SCShareUtility *)shareUtility didFailWithError:(NSError *)error
{
    [self _stopActivityIndicator];
    SCHandleError(error);
}

- (void)shareUtilityDidCompleteShare:(SCShareUtility *)shareUtility
{
    [self _stopActivityIndicator];
    [self _reset];
}

- (void)shareUtilityUserShouldLogin:(SCShareUtility *)shareUtility
{
    [self _stopActivityIndicator];
    [self performSegueWithIdentifier:@"showLogin" sender:nil];
}

#pragma mark - Helper Methods

- (FBCacheDescriptor *)_placeCacheDescriptorWithLocationCoordinate:(CLLocationCoordinate2D)locationCoordinate
{
    return [FBPlacePickerViewController cacheDescriptorWithLocationCoordinate:locationCoordinate
                                                               radiusInMeters:1000
                                                                   searchText:@"restaurant"
                                                                 resultsLimit:50
                                                             fieldsForRequest:nil];
}

- (void)_reset
{
    self.selectedMeal = nil;
    self.selectedPlace = nil;
    self.selectedFriends = nil;
    self.selectedPhoto = nil;
}

- (void)_startActivityIndicator
{
    UIView *view = self.view;
    CGRect bounds = view.bounds;
    UIView *activityOverlayView = [[UIView alloc] initWithFrame:bounds];
    activityOverlayView.backgroundColor = [UIColor colorWithWhite:0.65 alpha:0.5];
    activityOverlayView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    self.activityOverlayView = activityOverlayView;
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityIndicatorView.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    activityIndicatorView.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin |
                                              UIViewAutoresizingFlexibleRightMargin |
                                              UIViewAutoresizingFlexibleBottomMargin |
                                              UIViewAutoresizingFlexibleLeftMargin);
    [activityOverlayView addSubview:activityIndicatorView];
    [view addSubview:activityOverlayView];
    [activityIndicatorView startAnimating];
}

- (void)_stopActivityIndicator
{
    self.activityOverlayView = nil;
}

@end
