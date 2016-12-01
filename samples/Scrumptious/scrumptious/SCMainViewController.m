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

#import "SCMainViewController.h"

#import <AddressBook/AddressBook.h>
#import <CoreLocation/CoreLocation.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "SCImagePicker.h"
#import "SCMealPicker.h"
#import "SCPickerViewController.h"
#import "SCSettings.h"
#import "SCShareUtility.h"

@interface SCMainViewController () <CLLocationManagerDelegate, SCImagePickerDelegate, SCMealPickerDelegate, SCShareUtilityDelegate>
@property (nonatomic, strong) UIView *activityOverlayView;
@property (nonatomic, strong) SCImagePicker *imagePicker;
@property (nonatomic, strong, readonly) CLLocationManager *locationManager;
@property (nonatomic, strong) SCMealPicker *mealPicker;
@property (nonatomic, copy) NSString *selectedMeal;
@property (nonatomic, strong) UIImage *selectedPhoto;
@property (nonatomic, strong) SCShareUtility *shareUtility;
@end

static int const MIN_USER_GENERATED_PHOTO_DIMENSION = 480;

@implementation SCMainViewController
{
    CLLocationManager *_locationManager;
    CLLocationCoordinate2D _currentLocationCoordinate;
    NSString *_lastSegueIdentifier;
    NSString *_selectedPlace;
    NSArray *_selectedFriends;
}

#pragma mark - Properties

- (void)setActivityOverlayView:(UIView *)activityOverlayView
{
    if (_activityOverlayView != activityOverlayView) {
        [_activityOverlayView removeFromSuperview];
        _activityOverlayView = activityOverlayView;
    }
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
        [self updateShareContent];
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    _currentLocationCoordinate = CLLocationCoordinate2DMake(48.857875, 2.294635);
    self.profilePictureButton.profileID = @"me";
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.profilePictureButton.pictureCropping = FBSDKProfilePictureModeSquare;

    if ([FBSDKAccessToken currentAccessToken]) {
        self.locationButton.enabled = YES;
        self.friendsButton.enabled = YES;
    } else {
        self.locationButton.enabled = NO;
        self.friendsButton.enabled = NO;
    }
    self.shareButton.enabled = (self.selectedMeal != nil);
    self.shareButton.hidden = ![FBSDKAccessToken currentAccessToken];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if ([FBSDKAccessToken currentAccessToken]) {
        [self.locationManager startUpdatingLocation];
    }

    [self updateShareContent];
}

#pragma mark - Actions

- (IBAction)pickImage:(UIView *)sender
{
    SCImagePicker *imagePicker = [[SCImagePicker alloc] init];
    self.imagePicker = imagePicker;
    imagePicker.delegate = self;
    CGRect senderFrame = [self.view convertRect:sender.bounds fromView:sender];
    [imagePicker presentFromRect:senderFrame withViewController:self];
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
    //the SDK expects user generated images to be at least 480px in height and width.
    //photos with the user generated flag set to false can be smaller but this sample app assumes the photo to be user generated
    if (self.selectedPhoto && ([self.selectedPhoto size].height < MIN_USER_GENERATED_PHOTO_DIMENSION || [self.selectedPhoto size].width < MIN_USER_GENERATED_PHOTO_DIMENSION)) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:[NSString stringWithFormat:@"%@%d%@", @"This photo is too small. Choose a photo with dimensions larger than ", MIN_USER_GENERATED_PHOTO_DIMENSION, @"px."]
                              message:nil
                              delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        [alert show];
        return;
    }

    SCShareUtility *shareUtility = [[SCShareUtility alloc] initWithMealTitle:self.selectedMeal
                                                                       place:_selectedPlace
                                                                     friends:_selectedFriends
                                                                       photo:self.selectedPhoto];
    self.shareUtility = shareUtility;
    shareUtility.delegate = self;
    [shareUtility start];
}

- (IBAction)showMain:(UIStoryboardSegue *)segue
{
    if ([_lastSegueIdentifier isEqualToString:@"showPlacePicker"]) {
        SCPickerViewController *vc = segue.sourceViewController;
        if (vc.selection.count) {
            _selectedPlace = vc.selection[0][@"id"];
            self.locationLabel.text = vc.selection[0][@"name"];
        } else {
            _selectedPlace = nil;
            self.locationLabel.text = nil;
        }

    } else if ([_lastSegueIdentifier isEqualToString:@"showFriendPicker"]) {
        SCPickerViewController *vc = segue.sourceViewController;
        _selectedFriends = [vc.selection valueForKeyPath:@"id"];
        NSString *subtitle = nil;
        if (_selectedFriends.count == 1) {
            subtitle = vc.selection[0][@"name"];
        } else if (_selectedFriends.count == 2) {
            subtitle = [NSString stringWithFormat:@"%@ and %@", vc.selection[0][@"name"], vc.selection[1][@"name"]];
        } else if (_selectedFriends.count > 2) {
            subtitle = [NSString stringWithFormat:@"%@ and %lu others", vc.selection[0][@"name"], (unsigned long) (_selectedFriends.count - 1)];
        } else if (_selectedFriends == 0) {
            subtitle = nil;
            _selectedFriends = nil;
        }
        self.friendsLabel.text = subtitle;
    }
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // NOTE: for simplicity, we are not paging the results of the request.
    _lastSegueIdentifier = segue.identifier;
    if ([_lastSegueIdentifier isEqualToString:@"showPlacePicker"]) {
        NSDictionary *params = @{ @"type": @"place",
                                  @"limit": @"100",
                                  @"center": [NSString stringWithFormat:@"%lf,%lf", _currentLocationCoordinate.latitude, _currentLocationCoordinate.longitude],
                                  @"distance": @"100",
                                  @"q" : @"restaurant",
                                  @"fields" : @"id,name,picture.width(100).height(100)" };
        SCPickerViewController *vc = segue.destinationViewController;
        vc.request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"search" parameters:params];
        vc.allowsMultipleSelection = NO;
    } else if ([_lastSegueIdentifier isEqualToString:@"showFriendPicker"]) {
        SCPickerViewController *vc = segue.destinationViewController;
        vc.requiredPermission = @"user_friends";
        vc.request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me/taggable_friends?limit=100"
                                                       parameters:@{ @"fields" : @"id,name,picture.width(100).height(100)"
                                                                     }];
        vc.allowsMultipleSelection = YES;
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
            _currentLocationCoordinate = newLocation.coordinate;
        }
    [self updateShareContent];
}

// unused, required delegate methods
- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region { }
- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region { }
- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error { }
- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager { }
- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager { }

#pragma mark - SCImagePickerDelegate

- (void)imagePicker:(SCImagePicker *)imagePicker didSelectImage:(UIImage *)image
{
    self.selectedPhoto = image;
    self.imagePicker = nil;
    self.photoViewPlaceholderLabel.hidden = YES;
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

    [self updateShareContent];
}

- (void)mealPickerDidCancel:(SCMealPicker *)mealPicker
{
    self.mealPicker = nil;
    [self updateShareContent];
}

#pragma mark - SCShareUtilityDelegate
- (void)shareUtilityWillShare:(SCShareUtility *)shareUtility {
    [self _startActivityIndicator];
}

- (void)shareUtility:(SCShareUtility *)shareUtility didFailWithError:(NSError *)error
{
    [self _stopActivityIndicator];
    // if there was a localized message, the automated error recovery will
    // display it. Otherwise display a fallback message.
    if (!error.userInfo[FBSDKErrorLocalizedDescriptionKey]) {
        NSLog(@"Unexpected error when sharing : %@", error);
        [[[UIAlertView alloc] initWithTitle:@"Oops"
                                    message:@"There was a problem sharing. Please try again later."
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
}

- (void)shareUtilityDidCompleteShare:(SCShareUtility *)shareUtility
{
    [self _stopActivityIndicator];
    [self _reset];
    [[[UIAlertView alloc] initWithTitle:nil message:@"Thanks for sharing!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

- (void)shareUtilityUserShouldLogin:(SCShareUtility *)shareUtility
{
    [self _stopActivityIndicator];
    [self performSegueWithIdentifier:@"showLogin" sender:nil];
}

#pragma mark - Helper Methods

- (void)updateShareContent
{
    SCShareUtility *shareUtility = [[SCShareUtility alloc] initWithMealTitle:self.selectedMeal
                                                                       place:_selectedPlace
                                                                     friends:_selectedFriends
                                                                       photo:self.selectedPhoto];
    FBSDKShareOpenGraphContent *content = [shareUtility contentForSharing];

    self.fbSendButton.shareContent = content;
    self.fbShareButton.shareContent = content;
}

- (void)_reset
{
    self.selectedMeal = nil;
    self.selectedPhoto = nil;
    self.photoViewPlaceholderLabel.hidden = NO;
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
