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
@property (strong, nonatomic) IBOutlet FBProfilePictureView* userProfileImage;
@property (strong, nonatomic) IBOutlet UILabel* userNameLabel;
@property (strong, nonatomic) IBOutlet UIButton* announceButton;
@property (strong, nonatomic) IBOutlet UITableView *menuTableView;
@property (strong, nonatomic) UIImagePickerController* imagePicker;
@property (strong, nonatomic) UIActionSheet* imagePickerActionSheet;

@property (strong, nonatomic) NSObject<FBGraphPlace>* selectedPlace;
@property (strong, nonatomic) NSString* selectedMeal;
@property (strong, nonatomic) NSArray* selectedFriends;
@property (strong, nonatomic) UIImage* selectedPhoto;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) UIPopoverController *popover;
@property (strong, nonatomic) SCMealViewController *mealViewController;

- (IBAction)announce:(id)sender;
- (void)populateUserDetails;
- (void)updateSelections;
- (void)updateCellIndex:(int)index withSubtitle:(NSString*)subtitle;
- (id<SCOGMeal>)mealObjectForMeal:(NSString*)meal;
- (void)postPhotoThenOpenGraphAction;
- (void)postOpenGraphActionWithPhotoURL:(NSString*)photoID withUserGeneratedFlag:(BOOL)userGenerated;
- (FBSession*)session;

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
@synthesize menuTableView = _menuTableView;
@synthesize locationManager = _locationManager;
@synthesize popover = _popover;
@synthesize imagePickerActionSheet = _imagePickerActionSheet;
#pragma mark open graph

- (id<SCOGMeal>)mealObjectForMeal:(NSString*)meal 
{
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

- (void)postOpenGraphActionWithPhotoURL:(NSString*)photoURL withUserGeneratedFlag:(BOOL)userGenerated
{
    // First create the Open Graph meal object for the meal we ate.
    id<SCOGMeal> mealObject = [self mealObjectForMeal:self.selectedMeal];
    
    // Now create an Open Graph eat action with the meal, our location, and the people we were with.
    id<SCOGEatMealAction> action = (id<SCOGEatMealAction>)[FBGraphObject graphObject];
    action.meal = mealObject;
    if (self.selectedPlace) {
        action.place = self.selectedPlace;
    }
    if (self.selectedFriends.count > 0) {
        action.tags = self.selectedFriends;
    }
    if (photoURL) {
        NSMutableDictionary *image = [[NSMutableDictionary alloc] init];
        [image setObject:photoURL forKey:@"url"];
        if (userGenerated) {
            [image setObject:@"true" forKey:@"user_generated"];
        }
        
        NSMutableArray *images = [[NSMutableArray alloc] init];
        [images addObject:image];
        
        action.image = images;
    }

    // Create the request and post the action to the "me/fb_sample_scrumps:eat" path.
    [FBRequest startForPostWithSession:self.session
                             graphPath:@"me/fb_sample_scrumps:eat"
                           graphObject:action
                     completionHandler:
     ^(FBRequestConnection *connection, id result, NSError *error) {
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

- (void)postPhotoThenOpenGraphAction
{
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];

    // If the picture is big enough, we'd like to use the user_generated flag so it
    // appears larger than a thumbnail in the OG Action. (This flag is not allowed if
    // the picture is smaller than 520x520.)
    BOOL useUserGeneratedFlag = self.selectedPhoto.size.width >= 520 &&
        self.selectedPhoto.size.height >= 520;

    // First request uploads the photo.
    FBRequest *request1 = [FBRequest requestForUploadPhoto:self.selectedPhoto
                                                   session:self.session];
    [connection addRequest:request1
        completionHandler:
        ^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
            }
        }
            batchEntryName:@"photopost"
    ];

    // Second request retrieves photo information for just-created photo so we can grab its source.
    FBRequest *request2 = [FBRequest requestForGraphPath:@"{result=photopost:$.id}"
                                                 session:self.session];
    [connection addRequest:request2
         completionHandler:
        ^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error &&
                result) {
                NSString *source = [result objectForKey:@"source"];
                [self postOpenGraphActionWithPhotoURL:source withUserGeneratedFlag:useUserGeneratedFlag];
            }
        }
    ];

    [connection start];
}

- (IBAction)announce:(id)sender
{
    if (self.selectedPhoto) {
        [self postPhotoThenOpenGraphAction];
    } else {
        [self postOpenGraphActionWithPhotoURL:nil withUserGeneratedFlag:NO];
    }
}

#pragma mark UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker 
        didFinishPickingImage:(UIImage *)image
                  editingInfo:(NSDictionary *)editingInfo
{
    self.selectedPhoto = image;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.popover dismissPopoverAnimated:YES];
    } else {
        [self dismissModalViewControllerAnimated:true];
    }

    [self updateSelections];
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
    
    [self presentModalViewController:self.imagePicker animated:true];
}


#pragma mark -

#pragma mark Data fetch

- (void)updateCellIndex:(int)index withSubtitle:(NSString*)subtitle {
    UITableViewCell *cell = (UITableViewCell *)[self.menuTableView 
        cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    cell.detailTextLabel.text = subtitle;
}

- (void)updateSelections 
{
    [self updateCellIndex:0 withSubtitle:(self.selectedMeal ?
                                          self.selectedMeal : 
                                          @"Select One")];
    [self updateCellIndex:1 withSubtitle:(self.selectedPlace ?
                                          self.selectedPlace.name :
                                          @"Select One")];
    
    NSString* friendsSubtitle = @"Select friends";
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

- (void)populateUserDetails 
{
    if (self.session.isOpen) {
        [[FBRequest requestForMeWithSession:self.session] startWithCompletionHandler:
         ^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
             if (!error) {
                 self.userNameLabel.text = user.name;
                 self.userProfileImage.userID = user.id;
             }
         }];   
    }
}

- (void)showLoginView 
{
    SCLoginViewController* loginView = 
    [[SCLoginViewController alloc]initWithNibName:@"SCLoginViewController" bundle:nil];
    [self presentModalViewController:loginView animated:NO];
}

- (void)dealloc
{
    _locationManager.delegate = nil;
    _placePickerController.delegate = nil;
    _friendPickerController.delegate = nil;
    _imagePicker.delegate = nil;
    _imagePickerActionSheet.delegate = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Scrumptious";

    // Get the CLLocationManager going.
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
    
    // We want a Logout button in the upper-right.
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] 
                                              initWithTitle:@"Logout" 
                                                style:UIBarButtonItemStyleBordered 
                                              target:self 
                                              action:@selector(logoutButtonWasPressed:)];

    // Keep tabs on what's going on with the session so we can repopulate data if it changes.
    SCAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate addObserver:self
              forKeyPath:@"session.state"
                 options:NSKeyValueObservingOptionNew
                 context:NULL];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.session && self.session.isOpen) {
        [self populateUserDetails];
    }
}

-(void)logoutButtonWasPressed:(id)sender {
    SCAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate closeSession];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    SCAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate removeObserver:self forKeyPath:@"session.state"];
    
    // Release any retained subviews of the main view.
    self.placePickerController = nil;
    self.friendPickerController = nil;
    self.mealViewController = nil;
    self.imagePicker = nil;
    self.popover = nil;
    self.imagePickerActionSheet = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqual:@"session.state"]) {
        // A more complex app might check the state to see what the appropriate course of
        // action is, but our needs are simple, so just make sure our idea of the session is
        // up to date and repopulate the user's name and picture (which will fail if the session
        // has become invalid).
        [self populateUserDetails];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (FBSession*)session 
{
    SCAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    return appDelegate.session;
}

#pragma mark UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
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
        cell.textLabel.clipsToBounds = true;

        cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
        cell.detailTextLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
        cell.detailTextLabel.textColor = [UIColor colorWithRed:0.4 green:0.6 blue:0.8 alpha:1];
        cell.detailTextLabel.lineBreakMode = UILineBreakModeTailTruncation;
        cell.detailTextLabel.clipsToBounds = true;
    }
    
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"What are you eating?";
            cell.detailTextLabel.text = @"Select one";
            cell.imageView.image = [UIImage imageNamed:@"food.png"];
            break;
            
        case 1:
            cell.textLabel.text = @"Where are you?";
            cell.detailTextLabel.text = @"Select one";
            cell.imageView.image = [UIImage imageNamed:@"house.png"];
            break;
            
        case 2:
            cell.textLabel.text = @"With whom?";
            cell.detailTextLabel.text = @"Select friends";
            cell.imageView.image = [UIImage imageNamed:@"users.png"];
            break;
            
        case 3:
            cell.textLabel.text = @"Got a picture?";
            cell.detailTextLabel.text = @"Take one";
            cell.imageView.image = [UIImage imageNamed:@"pictures.png"];
            break;
            
        default:
            break;
    }

    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 1;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath 
{
    return false;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIViewController* target;
    
    switch (indexPath.row) {
        case 0:
            if (!self.mealViewController) {
                __block SCViewController* myself = self;
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
            self.placePickerController.session = self.session;
            
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

            self.friendPickerController.session = self.session;
            [self.friendPickerController loadData];
            target = self.friendPickerController;
            break;
            
        case 3:            
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                // Can't use presentModalViewController for image picker on iPad
                if (!self.popover) {
                    self.popover = [[UIPopoverController alloc] initWithContentViewController:self.imagePicker];
                }
                CGRect rect = [tableView rectForRowAtIndexPath:indexPath];
                [self.popover presentPopoverFromRect:rect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            } else {
                if(! self.imagePickerActionSheet){
                    self.imagePickerActionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                           delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           destructiveButtonTitle:nil
                                           otherButtonTitles:@"Take Photo", @"Choose Existing", nil];
                }
                
                [self.imagePickerActionSheet showInView:self.view];
            }
            // Return rather than execute below code
            return;
    }
    
    [self.navigationController pushViewController:target animated:true];
}

#pragma mark -
#pragma mark FBFriendPickerDelegate methods

- (void)friendPickerViewControllerSelectionDidChange:
(FBFriendPickerViewController *)friendPicker
{
    self.selectedFriends = friendPicker.selection;
    [self updateSelections];
}

#pragma mark FBPlacePickerDelegate methods

- (void)placePickerViewControllerSelectionDidChange:
(FBPlacePickerViewController *)placePicker
{
    self.selectedPlace = placePicker.selection;
    [self updateSelections];
    if (self.selectedPlace.count > 0) {
        [self.navigationController popViewControllerAnimated:true];
    }
}

#pragma mark CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation 
{
    if (self.locationManager &&
        newLocation.horizontalAccuracy < 100) {
        // We wait for a precision of 100m and turn the GPS off
        [self.locationManager stopUpdatingLocation];
        
        self.placePickerController.locationCoordinate = newLocation.coordinate;
        if (self.placePickerController.session) {
            [self.placePickerController loadData];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	NSLog(@"%@", error);
}

#pragma mark - 

@end
