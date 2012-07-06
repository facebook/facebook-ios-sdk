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

#import "SCViewController.h"
#import "SCAppDelegate.h"
#import "SCLoginViewController.h"
#import "SCMealViewController.h"
#import "SCPhotoViewController.h"
#import "SCProtocols.h"
#import <FBiOSSDK/FBRequest.h>
#import <AddressBook/AddressBook.h>
#import "TargetConditionals.h"

@interface SCViewController() < UITableViewDataSource, 
                                UIImagePickerControllerDelegate,
                                FBFriendPickerDelegate,
                                UINavigationControllerDelegate,
                                FBPlacePickerDelegate,
                                CLLocationManagerDelegate,
                                UIActionSheetDelegate>

@property (strong, nonatomic) FBFriendPickerViewController *friendPickerController;
@property (strong, nonatomic) FBPlacePickerViewController *placePickerController;
@property (strong, nonatomic) IBOutlet FBProfilePictureView *userProfileImage;
@property (strong, nonatomic) IBOutlet UILabel *userNameLabel;
@property (strong, nonatomic) IBOutlet UIButton *announceButton;
@property (strong, nonatomic) IBOutlet UITableView *menuTableView;
@property (strong, nonatomic) UIImagePickerController *imagePicker;
@property (strong, nonatomic) UIActionSheet *imagePickerActionSheet;

@property (strong, nonatomic) NSObject<FBGraphPlace> *selectedPlace;
@property (strong, nonatomic) NSString *selectedMeal;
@property (strong, nonatomic) NSArray *selectedFriends;
@property (strong, nonatomic) UIImage *selectedPhoto;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) UIPopoverController *popover;
@property (strong, nonatomic) SCMealViewController *mealViewController;
@property (strong, nonatomic) SCPhotoViewController *photoViewController;
@property (nonatomic) CGRect popoverFromRect;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;

- (IBAction)announce:(id)sender;
- (void)populateUserDetails;
- (void)updateSelections;
- (void)updateCellIndex:(int)index withSubtitle:(NSString *)subtitle;
- (id<SCOGMeal>)mealObjectForMeal:(NSString *)meal;
- (void)postPhotoThenOpenGraphAction;
- (void)postOpenGraphActionWithPhotoURL:(NSString *)photoID;
- (void)centerAndShowActivityIndicator;

@end

@implementation SCViewController
@synthesize userNameLabel = _userNameLabel;
@synthesize userProfileImage = _userProfileImage;
@synthesize selectedPlace = _selectedPlace;
@synthesize selectedMeal = _selectedMeal;
@synthesize selectedFriends = _selectedFriends;
@synthesize announceButton = _announceButton;
@synthesize selectedPhoto = _selectedPhoto;
@synthesize imagePicker = _imagePicker;
@synthesize placePickerController = _placePickerController;
@synthesize friendPickerController = _friendPickerController;
@synthesize mealViewController = _mealViewController;
@synthesize photoViewController = _photoViewController;
@synthesize menuTableView = _menuTableView;
@synthesize locationManager = _locationManager;
@synthesize popover = _popover;
@synthesize imagePickerActionSheet = _imagePickerActionSheet;
@synthesize popoverFromRect = _popoverFromRect;
@synthesize activityIndicator = _activityIndicator;

#pragma mark open graph


// FBSample logic
// Creates an Open Graph object using a simple repeater app that just echoes its
// input back as the properties of the OG object.
- (id<SCOGMeal>)mealObjectForMeal:(NSString *)meal {
    // This URL is specific to this sample, and can be used to create arbitrary
    // OG objects for this app; your OG objects will have URLs hosted by your server.
    NSString *format =  
        @"http://fbsdkog.herokuapp.com/repeater.php?"
        @"fb:app_id=233936543368280&og:type=%@&"
        @"og:title=%@&og:description=%%22%@%%22&"
        @"og:image=https://s-static.ak.fbcdn.net/images/devsite/attachment_blank.png&"
        @"body=%@";
    
    // We create an FBGraphObject object, but we can treat it as an SCOGMeal with typed
    // properties, etc. See <FBiOSSDK/FBGraphObject.h> for more details.
    id<SCOGMeal> result = (id<SCOGMeal>)[FBGraphObject graphObject];
    
    // Give it a URL that will echo back the name of the meal as its title, description, and body.
    result.url = [NSString stringWithFormat:format, @"fb_sample_scrumps:meal", meal, meal, meal];
    
    return result;
}

// FBSample logic
// Creates the Open Graph Action with an optional photo URL.
- (void)postOpenGraphActionWithPhotoURL:(NSString *)photoURL {
    // First create the Open Graph meal object for the meal we ate.
    id<SCOGMeal> mealObject = [self mealObjectForMeal:self.selectedMeal];
    
    // Now create an Open Graph eat action with the meal, our location, and the people we were with.
    id<SCOGEatMealAction> action = (id<SCOGEatMealAction>)[FBGraphObject graphObject];
    action.meal = mealObject;
    if (self.selectedPlace) {
        // FBSample logic
        // We don't use the action.place syntax here because, unfortunately, because setPlace:
        // and a few other selectors may be flagged as reserved selectors by Apple's App Store
        // validation tools. While this doesn't necessarily block App Store approval, it
        // could slow down the approval process. Falling back to the setObjec:forKey:
        // selector is a useful technique to avoid such naming conflicts.
        [action setObject:self.selectedPlace forKey:@"place"];
    }
    if (self.selectedFriends.count > 0) {
        [action setObject:self.selectedFriends forKey:@"tags"];
    }
    if (photoURL) {
        NSMutableDictionary *image = [[NSMutableDictionary alloc] init];
        [image setObject:photoURL forKey:@"url"];
        
        NSMutableArray *images = [[NSMutableArray alloc] init];
        [images addObject:image];
        
        action.image = images;
    }

    // Create the request and post the action to the "me/fb_sample_scrumps:eat" path.
    [FBRequest startForPostWithGraphPath:@"me/fb_sample_scrumps:eat"
                             graphObject:action
                       completionHandler:
     ^(FBRequestConnection *connection, id result, NSError *error) {
         [self.activityIndicator stopAnimating];
         [self.view setUserInteractionEnabled:YES];

         NSString *alertText;
         if (!error) {
             alertText = [NSString stringWithFormat:@"Posted Open Graph action, id: %@",
                          [result objectForKey:@"id"]];
         } else {
             alertText = [NSString stringWithFormat:@"error: domain = %@, code = %d",
                          error.domain, error.code];
         }
         [[[UIAlertView alloc] initWithTitle:@"Result" 
                                     message:alertText 
                                    delegate:nil 
                           cancelButtonTitle:@"Thanks!" 
                           otherButtonTitles:nil] 
          show];
     }];
}

// FBSample logic
// Creates an Open Graph Action using the user-specified properties, optionally first
// uploading a photo to Facebook and attaching it to the action. 
- (void)postPhotoThenOpenGraphAction {
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];

    // First request uploads the photo.
    FBRequest *request1 = [FBRequest requestForUploadPhoto:self.selectedPhoto];
    [connection addRequest:request1
        completionHandler:
        ^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
            }
        }
            batchEntryName:@"photopost"
    ];

    // Second request retrieves photo information for just-created photo so we can grab its source.
    FBRequest *request2 = [FBRequest requestForGraphPath:@"{result=photopost:$.id}"];
    [connection addRequest:request2
         completionHandler:
        ^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error &&
                result) {
                NSString *source = [result objectForKey:@"source"];
                [self postOpenGraphActionWithPhotoURL:source];
            }
        }
    ];

    [connection start];
}

// FBSample logic
// Handles the user clicking the Announce button, by either creating an Open Graph Action
// or first uploading a photo and then creating the action.
- (IBAction)announce:(id)sender {
    [self centerAndShowActivityIndicator];
    [self.view setUserInteractionEnabled:NO];
    
    if (self.selectedPhoto) {
        self.selectedPhoto = [self normalizedImage:self.selectedPhoto];
        [self postPhotoThenOpenGraphAction];
    } else {
        [self postOpenGraphActionWithPhotoURL:nil];
    }
}

- (void)centerAndShowActivityIndicator {
    CGRect frame = self.view.frame;
    CGPoint center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
    self.activityIndicator.center = center;
    [self.activityIndicator startAnimating];
}
#pragma mark UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker 
        didFinishPickingImage:(UIImage *)image
                  editingInfo:(NSDictionary *)editingInfo {
    
    if (!self.photoViewController) {
        __block SCViewController *myself = self;
        self.photoViewController = [[SCPhotoViewController alloc]initWithNibName:@"SCPhotoViewController" bundle:nil image:image];
        self.photoViewController.confirmCallback = ^(id sender, bool confirm) {
            if(confirm) {
                myself.selectedPhoto = image;
            }
            [myself updateSelections];
        };
    }
    [self.navigationController pushViewController:self.photoViewController animated:true];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.popover dismissPopoverAnimated:YES];
    } else {
        [self dismissModalViewControllerAnimated:YES];
    }
}

#pragma mark -

#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    //If user presses cancel, do nothing
    if (buttonIndex == 2)
        return;
    
    if (!self.imagePicker) {
        self.imagePicker = [[UIImagePickerController alloc] init];
        self.imagePicker.delegate = self;
    }
    
    //Set the source type of the imagePicker to the users selection
    if (buttonIndex == 0) {
        //if its the simulator, camera is no good
        if(TARGET_IPHONE_SIMULATOR){
            [[[UIAlertView alloc] initWithTitle:@"Camera not supported in simulator." 
                              message:@"(>'_')>" 
                              delegate:nil 
                              cancelButtonTitle:@"Ok" 
                              otherButtonTitles:nil] show];
             return;
        }
        self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    } else if (buttonIndex == 1) {
        self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // Can't use presentModalViewController for image picker on iPad
        if (!self.popover) {
            self.popover = [[UIPopoverController alloc] initWithContentViewController:self.imagePicker];
        }
        [self.popover presentPopoverFromRect:self.popoverFromRect 
                                      inView:self.view 
                    permittedArrowDirections:UIPopoverArrowDirectionAny 
                                    animated:YES];
    } else {
        [self presentModalViewController:self.imagePicker animated:YES];
    }
}


#pragma mark -

#pragma mark Data fetch

- (void)updateCellIndex:(int)index withSubtitle:(NSString *)subtitle {
    UITableViewCell *cell = (UITableViewCell *)[self.menuTableView cellForRowAtIndexPath:
                                                [NSIndexPath indexPathForRow:index inSection:0]];
    cell.detailTextLabel.text = subtitle;
}

- (void)updateSelections {
    [self updateCellIndex:0 withSubtitle:(self.selectedMeal ?
                                          self.selectedMeal : 
                                          @"Select One")];
    [self updateCellIndex:1 withSubtitle:(self.selectedPlace ?
                                          self.selectedPlace.name :
                                          @"Select One")];
    
    NSString *friendsSubtitle = @"Select friends";
    int friendCount = self.selectedFriends.count;
    if (friendCount > 2) {
        // Just to mix things up, don't always show the first friend.
        id<FBGraphUser> randomFriend = [self.selectedFriends objectAtIndex:arc4random() % friendCount];
        friendsSubtitle = [NSString stringWithFormat:@"%@ and %d others", 
            randomFriend.name,
            friendCount - 1];
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
    [self updateCellIndex:2 withSubtitle:friendsSubtitle];
    
    [self updateCellIndex:3 withSubtitle:(self.selectedPhoto ? @"Ready" : @"Take one")];
    
    self.announceButton.enabled = (self.selectedMeal != nil);
}

// FBSample logic
// Displays the user's name and profile picture so they are aware of the Facebook
// identity they are logged in as.
- (void)populateUserDetails {
    if (FBSession.activeSession.isOpen) {
        [[FBRequest requestForMe] startWithCompletionHandler:
         ^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
             if (!error) {
                 self.userNameLabel.text = user.name;
                 self.userProfileImage.userID = [user objectForKey:@"id"];
             }
         }];   
    }
}

- (void)dealloc {
    _locationManager.delegate = nil;
    _placePickerController.delegate = nil;
    _friendPickerController.delegate = nil;
    _imagePicker.delegate = nil;
    _imagePickerActionSheet.delegate = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Scrumptious";

    // Get the CLLocationManager going.
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    // We don't want to be notified of small changes in location, preferring to use our
    // last cached results, if any.
    self.locationManager.distanceFilter = 50;
    [self.locationManager startUpdatingLocation];
    
    // This avoids a gray background in the table view on iPad.
    if ([self.menuTableView respondsToSelector:@selector(backgroundView)]) {
        self.menuTableView.backgroundView = nil;
    }
    
    // We want a Logout button in the upper-right.
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] 
                                              initWithTitle:@"Logout" 
                                                style:UIBarButtonItemStyleBordered 
                                              target:self 
                                              action:@selector(logoutButtonWasPressed:)];

    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.activityIndicator];

    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(sessionStateChanged:) 
                                                 name:SCSessionStateChangedNotification
                                               object:nil];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if (FBSession.activeSession.isOpen) {
        [self populateUserDetails];
    }
}

// FBSample logic
// Closes the user's session, which will cause the login screen to be displayed by the
// [SCAppDelegate sessionStateChanged:state:error:] handler.
-(void)logoutButtonWasPressed:(id)sender {
    [FBSession.activeSession closeAndClearTokenInformation];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    // Release any retained subviews of the main view.
    self.placePickerController = nil;
    self.friendPickerController = nil;
    self.mealViewController = nil;
    self.photoViewController = nil;
    self.imagePicker = nil;
    self.popover = nil;
    self.imagePickerActionSheet = nil;
}

- (void)sessionStateChanged:(NSNotification*)notification {
    // A more complex app might check the state to see what the appropriate course of
    // action is, but our needs are simple, so just make sure our idea of the session is
    // up to date and repopulate the user's name and picture (which will fail if the session
    // has become invalid).
    [self populateUserDetails];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        cell.textLabel.font = [UIFont systemFontOfSize:16];
        cell.textLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
        cell.textLabel.lineBreakMode = UILineBreakModeTailTruncation;
        cell.textLabel.clipsToBounds = YES;

        cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
        cell.detailTextLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
        cell.detailTextLabel.textColor = [UIColor colorWithRed:0.4 green:0.6 blue:0.8 alpha:1];
        cell.detailTextLabel.lineBreakMode = UILineBreakModeTailTruncation;
        cell.detailTextLabel.clipsToBounds = YES;
    }
    
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"What are you eating?";
            cell.detailTextLabel.text = @"Select one";
            cell.imageView.image = [UIImage imageNamed:@"action-eating.png"];
            break;
            
        case 1:
            cell.textLabel.text = @"Where are you?";
            cell.detailTextLabel.text = @"Select one";
            cell.imageView.image = [UIImage imageNamed:@"action-location.png"];
            break;
            
        case 2:
            cell.textLabel.text = @"With whom?";
            cell.detailTextLabel.text = @"Select friends";
            cell.imageView.image = [UIImage imageNamed:@"action-people.png"];
            break;
            
        case 3:
            cell.textLabel.text = @"Got a picture?";
            cell.detailTextLabel.text = @"Take one";
            cell.imageView.image = [UIImage imageNamed:@"action-photo.png"];
            break;
            
        default:
            break;
    }

    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIViewController *target;
    
    switch (indexPath.row) {
        case 0:
            if (!self.mealViewController) {
                __block SCViewController *myself = self;
                self.mealViewController = [[SCMealViewController alloc]initWithNibName:@"SCMealViewController" bundle:nil];
                self.mealViewController.selectItemCallback = ^(id sender, id selectedItem) {
                    myself.selectedMeal = selectedItem;
                    [myself updateSelections];
                };
            }
            target = self.mealViewController;
            break;
        
        case 1:
            if (!self.placePickerController) {
                self.placePickerController = [[FBPlacePickerViewController alloc] initWithNibName:nil bundle:nil];
                self.placePickerController.delegate = self;
                self.placePickerController.title = @"Select a restaurant";
            }
            self.placePickerController.locationCoordinate = self.locationManager.location.coordinate;
            self.placePickerController.radiusInMeters = 1000;
            self.placePickerController.resultsLimit = 50;
            self.placePickerController.searchText = @"restaurant";
            
            // SIMULATOR BUG:
            // See http://stackoverflow.com/questions/7003155/error-server-did-not-accept-client-registration-68
            // at times the simulator fails to fetch a location; when that happens rather than fetch a
            // a meal near 0,0 -- let's see if we can find something good in Paris
            if (!(self.placePickerController.locationCoordinate.latitude || 
                  self.placePickerController.locationCoordinate.longitude)) {
                self.placePickerController.locationCoordinate = CLLocationCoordinate2DMake(48.857875, 2.294635);
            }
            
            [self.placePickerController loadData];
            target = self.placePickerController;
            break;
            
        case 2:
            if (!self.friendPickerController) {
                self.friendPickerController = [[FBFriendPickerViewController alloc] initWithNibName:nil bundle:nil];
                self.friendPickerController.delegate = self;
                self.friendPickerController.title = @"Select friends";
            }

            // Set up the friend picker to sort and display names the same way as the
            // iOS Address Book does.
            
            // Need to call ABAddressBookCreate in order for the next two calls to do anything.
            ABAddressBookCreate();
            ABPersonSortOrdering sortOrdering = ABPersonGetSortOrdering();
            ABPersonCompositeNameFormat nameFormat = ABPersonGetCompositeNameFormat();
            
            self.friendPickerController.sortOrdering = (sortOrdering == kABPersonSortByFirstName) ? FBFriendSortByFirstName : FBFriendSortByLastName;
            self.friendPickerController.displayOrdering = (nameFormat == kABPersonCompositeNameFormatFirstNameFirst) ? FBFriendDisplayByFirstName : FBFriendDisplayByLastName;

            [self.friendPickerController loadData];
            target = self.friendPickerController;
            break;
            
        case 3:            
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                self.popoverFromRect = [tableView rectForRowAtIndexPath:indexPath];
            }
            if(!self.imagePickerActionSheet) {
                self.imagePickerActionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                                                          delegate:self
                                                                 cancelButtonTitle:@"Cancel"
                                                            destructiveButtonTitle:nil
                                                                 otherButtonTitles:@"Take Photo", @"Choose Existing", nil];
            }
            
            [self.imagePickerActionSheet showInView:self.view];
            // Return rather than execute below code
            return;
    }
    
    [self.navigationController pushViewController:target animated:YES];
}

#pragma mark -
#pragma mark FBFriendPickerDelegate methods

- (void)friendPickerViewControllerSelectionDidChange:(FBFriendPickerViewController *)friendPicker {
    self.selectedFriends = friendPicker.selection;
    [self updateSelections];
}

#pragma mark FBPlacePickerDelegate methods

- (void)placePickerViewControllerSelectionDidChange:(FBPlacePickerViewController *)placePicker {
    self.selectedPlace = placePicker.selection;
    [self updateSelections];
    if (self.selectedPlace.count > 0) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager 
    didUpdateToLocation:(CLLocation *)newLocation 
           fromLocation:(CLLocation *)oldLocation {
    if (!oldLocation ||
        (oldLocation.coordinate.latitude != newLocation.coordinate.latitude && 
         oldLocation.coordinate.longitude != newLocation.coordinate.longitude)) {
        // FBSample logic
        // If we already have a place picker, reload its data. If not, pre-fetch the
        // data so it is displayed quickly on first use of the place picker.
        if (self.placePickerController) {
            self.placePickerController.locationCoordinate = newLocation.coordinate;
            [self.placePickerController loadData];
        } else {
            FBCacheDescriptor *cacheDescriptor = 
            [FBPlacePickerViewController cacheDescriptorWithLocationCoordinate:newLocation.coordinate
                                                                radiusInMeters:1000
                                                                    searchText:nil 
                                                                  resultsLimit:50 
                                                              fieldsForRequest:nil];
            [cacheDescriptor prefetchAndCacheForSession:FBSession.activeSession];
            
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager 
       didFailWithError:(NSError *)error {
	NSLog(@"%@", error);
}

#pragma mark - 

// Rotates an image to the correct orientation, and removes the orientation EXIF data
// Uploaded photos ignore the orientation EXIF data, so we need to rotate before uploading
- (UIImage *)normalizedImage:(UIImage *)image {
    CGSize imageSize = image.size;
    CGSize newSize;
    switch (image.imageOrientation) {
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            newSize = CGSizeMake(imageSize.width, imageSize.height);
            break;
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            newSize = CGSizeMake(imageSize.height, imageSize.width);
            break;
    }
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0,0,newSize.width, newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
