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

@interface SCViewController()<UITableViewDataSource, UIImagePickerControllerDelegate, FBFriendPickerDelegate,
    UINavigationControllerDelegate, FBPlacesPickerDelegate,
    CLLocationManagerDelegate> {
}

@property (strong, nonatomic) FBFriendPickerViewController *friendPickerController;
@property (strong, nonatomic) FBPlacesPickerViewController *placesPickerController;
@property (strong, nonatomic) IBOutlet FBProfilePictureView* userProfileImage;
@property (strong, nonatomic) IBOutlet UILabel* userNameLabel;
@property (strong, nonatomic) IBOutlet UIButton* announceButton;
@property (strong, nonatomic) IBOutlet UITableView *menuTableView;
@property (strong, nonatomic) UIImagePickerController* imagePicker;

@property (strong, nonatomic) NSObject<FBGraphPlace>* selectedPlace;
@property (strong, nonatomic) NSString* selectedMeal;
@property (strong, nonatomic) NSArray* selectedFriends;
@property (strong, nonatomic) NSMutableDictionary* selectedPhoto;
@property (strong, nonatomic) CLLocationManager *locationManager;

@property (strong, nonatomic) SCMealViewController *mealViewController;

- (IBAction)announce:(id)sender;
- (void)populateUserDetails;
- (void)updateSelections;
- (void)updateCellIndex:(int)index withSubtitle:(NSString*)subtitle;
- (id<SCOGMeal>)mealObjectForMeal:(NSString*)meal;

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
@synthesize placesPickerController = _placesPickerController;
@synthesize friendPickerController = _friendPickerController;
@synthesize mealViewController = _mealViewController;
@synthesize menuTableView = _menuTableView;
@synthesize locationManager = _locationManager;

#pragma mark open graph

- (id<SCOGMeal>)mealObjectForMeal:(NSString*)meal {
    // This URL is specific to this sample, and can be used to create arbitrary
    // OG objects for this app; your OG objects will have URLs hosted by your server.
    NSString *format =  
        @"http://fbsdkog.herokuapp.com/repeater.php?"
        @"fb:app_id=233936543368280&og:type=%@&"
        @"og:title=%@&og:description=%%22%@%%22&"
        @"og:image=https://s-static.ak.fbcdn.net/images/devsite/attachment_blank.png&"
        @"body=%@";
    
    // We create an FBGraphObject object, but we can treat it as an CGOGMeal with typed
    // properties, etc. See <FBiOSSDK/FBGraphObject.h> for more details.
    id<SCOGMeal> result = (id<SCOGMeal>)[FBGraphObject graphObject];
    
    // Give it a URL that will echo back the name of the meal as its title, description, and body.
    result.url = [NSString stringWithFormat:format, @"scrumps:meal", meal, meal, meal];
    
    return result;
}

- (IBAction)announce:(id)sender
{
    // First create the Open Graph meal object for the meal we ate.
    id<SCOGMeal> mealObject = [self mealObjectForMeal:self.selectedMeal];
    
    // Now create an Open Graph eat action with the meal, our location, and the people we were with.
    id<SCOGEatMealAction> action = (id<SCOGEatMealAction>)[FBGraphObject graphObject];
    action.meal = mealObject;
    action.place = self.selectedPlace;
    action.tags = self.selectedFriends;

    // Create the request and post the action to the "me/scrumps:eat" path.
    SCAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    FBRequestConnection *conn = [FBRequest connectionWithSession:appDelegate.session
                                                       graphPath:@"me/scrumps:eat"
                                                     graphObject:action
                                               completionHandler:
        ^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                // successful post, do something with the action id    
            } 
        }
    ];
    
    [conn start];
}

#pragma mark UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker 
        didFinishPickingImage:(UIImage *)image
                  editingInfo:(NSDictionary *)editingInfo
{
    if (!self.selectedPhoto) {
        self.selectedPhoto = [[NSMutableDictionary alloc] init];
    }
    [self.selectedPhoto setObject:image forKey:@"image"];
    [self dismissModalViewControllerAnimated:true];
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
    [self updateCellIndex:0 withSubtitle:(self.selectedPlace ? 
                                          self.selectedPlace.name :
                                          @"Select One")];
    [self updateCellIndex:1 withSubtitle:(self.selectedMeal ? 
                                          self.selectedMeal : 
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
    
    self.announceButton.enabled = self.selectedPlace && 
        self.selectedMeal && 
        (self.selectedFriends.count > 0);
}

- (void)populateUserDetails 
{
    SCAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    if (appDelegate.session.isValid) {
        FBRequestConnection *requestConnection = [FBRequest connectionWithSession:appDelegate.session
                                                                        graphPath:@"me"
                                                                completionHandler:
            ^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
            if (!error) {
                self.userNameLabel.text = user.name;
                self.userProfileImage.userID = user.id;
            }
        }];
        [requestConnection start];        
    }
}

- (void)showLoginView 
{
    SCLoginViewController* loginView = 
    [[SCLoginViewController alloc]initWithNibName:@"SCLoginViewController" bundle:nil];
    [self presentModalViewController:loginView animated:NO];
}

- (void)createViewControllers 
{
    __block SCViewController* myself = self;
    self.placesPickerController = [[FBPlacesPickerViewController alloc] initWithNibName:nil bundle:nil];
    self.placesPickerController.delegate = self;
    
    _mealViewController = [[SCMealViewController alloc]initWithNibName:@"SCMealViewController" bundle:nil];
    _mealViewController.selectItemCallback = ^(id sender, id selectedItem) {
        myself.selectedMeal = selectedItem;
        [myself updateSelections];
    };
    self.friendPickerController = [[FBFriendPickerViewController alloc] initWithNibName:nil bundle:nil];
    self.friendPickerController.delegate = self;
    
    self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.delegate = self;    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// Do any additional setup after loading the view, typically from a nib.
    self.title = @"Scrumptious";
    [self createViewControllers];

    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    [_locationManager startUpdatingLocation];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    SCAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    if (appDelegate.session && appDelegate.session.isValid) {
        [self populateUserDetails];
    } else {
        [self showLoginView];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.placesPickerController = nil;
    self.friendPickerController = nil;
    self.mealViewController = nil;
    self.imagePicker = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

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
            cell.textLabel.text = @"Where are you?";
            cell.detailTextLabel.text = @"Select one";
            cell.imageView.image = [UIImage imageNamed:@"house.png"];
            break;
            
        case 1:
            cell.textLabel.text = @"What are you eating?";
            cell.detailTextLabel.text = @"Select one";
            cell.imageView.image = [UIImage imageNamed:@"food.png"];
            break;
            
        case 2:
            cell.textLabel.text = @"With who?";
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
    SCAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    UIViewController* target;
    
    switch (indexPath.row) {
        case 0:
            self.placesPickerController.session = appDelegate.session;
            self.placesPickerController.title = @"Select a restaurant";
            [self.placesPickerController loadData];
            target = self.placesPickerController;
            break;
        
        case 1:
            target = _mealViewController;
            break;
            
        case 2:
            self.friendPickerController.session = appDelegate.session;
            self.friendPickerController.title = @"Select friends";
            [self.friendPickerController loadData];
            target = self.friendPickerController;
            break;
            
        case 3:
            [self presentModalViewController:_imagePicker animated:true];
            // Return rather than execute below code
            return;
    }
    
    [self.navigationController pushViewController:target animated:true];
}

#pragma mark FBFriendPickerDelegate methods

- (void)friendPickerViewControllerSelectionDidChange:
(FBFriendPickerViewController *)friendPicker
{
    self.selectedFriends = friendPicker.selection;
    [self updateSelections];
}

#pragma mark FBPlacesPickerDelegate methods

- (void)placesPickerViewControllerSelectionDidChange:
(FBPlacesPickerViewController *)placesPicker
{
    self.selectedPlace = placesPicker.selection;
    [self updateSelections];
}

#pragma mark LoginViewControllerDelegate methods

- (void)loginDidSucceed:(FBSession*)session {
    [self dismissModalViewControllerAnimated:true];
    [self populateUserDetails];
}

#pragma mark CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation 
{
    if (self.locationManager &&
        newLocation.horizontalAccuracy < 100) {
        // We wait for a precision of 100m and turn the GPS off
        [self.locationManager stopUpdatingLocation];
        self.locationManager = nil;
        
        self.placesPickerController.locationCoordinate = newLocation.coordinate;
        [self.placesPickerController loadData];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	NSLog(@"%@", error);
}

#pragma mark - 

@end
