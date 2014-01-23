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

#import "SCViewController.h"

#import <AddressBook/AddressBook.h>

#import "SCAppDelegate.h"
#import "SCLoginViewController.h"
#import "SCPhotoViewController.h"
#import "SCProtocols.h"
#import "TargetConditionals.h"

#define DEFAULT_IMAGE_URL @"http://facebooksampleapp.com/scrumptious/static/images/logo.png"

@interface SCViewController() < UITableViewDataSource,
                                UIImagePickerControllerDelegate,
                                FBFriendPickerDelegate,
                                UINavigationControllerDelegate,
                                FBPlacePickerDelegate,
                                CLLocationManagerDelegate,
                                UIActionSheetDelegate> {
 @private int _retryCount;
}

@property (strong, nonatomic) FBUserSettingsViewController *settingsViewController;
@property (strong, nonatomic) IBOutlet FBProfilePictureView *userProfileImage;
@property (strong, nonatomic) IBOutlet UILabel *userNameLabel;
@property (strong, nonatomic) IBOutlet UIButton *announceButton;
@property (strong, nonatomic) IBOutlet UITableView *menuTableView;
@property (strong, nonatomic) UIActionSheet *mealPickerActionSheet;
@property (retain, nonatomic) NSArray *mealTypes;

@property (strong, nonatomic) NSObject<FBGraphPlace> *selectedPlace;
@property (strong, nonatomic) NSString *selectedMeal;
@property (strong, nonatomic) NSArray *selectedFriends;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) FBCacheDescriptor *placeCacheDescriptor;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;

@property (strong, nonatomic) UIImagePickerController *imagePicker;
@property (strong, nonatomic) UIActionSheet *imagePickerActionSheet;
@property (strong, nonatomic) UIImage *selectedPhoto;
@property (strong, nonatomic) UIPopoverController *popover;
@property (strong, nonatomic) SCPhotoViewController *photoViewController;
@property (nonatomic) CGRect popoverFromRect;

@end

@implementation SCViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.navigationItem.hidesBackButton = YES;
    }
    return self;
}

#pragma mark - Open Graph Helpers

// This is a helper function that returns an FBGraphObject representing a meal
- (id<SCOGMeal>)mealObjectForMeal:(NSString *)meal {

    // We create an FBGraphObject object, but we can treat it as an SCOGMeal with typed
    // properties, etc. See <FacebookSDK/FBGraphObject.h> for more details.
    id<SCOGMeal> result = (id<SCOGMeal>)[FBGraphObject graphObject];

    // Give it a URL of sample data that contains the object's name, title, description, and body.
    // These OG object URLs were created using the edit open graph feature of the graph tool
    // at https://www.developers.facebook.com/apps/
    if ([meal isEqualToString:@"Cheeseburger"]) {
        result.url = @"http://samples.ogp.me/314483151980285";
    } else if ([meal isEqualToString:@"Pizza"]) {
        result.url = @"http://samples.ogp.me/314483221980278";
    } else if ([meal isEqualToString:@"Hotdog"]) {
        result.url = @"http://samples.ogp.me/314483265313607";
    } else if ([meal isEqualToString:@"Italian"]) {
        result.url = @"http://samples.ogp.me/314483348646932";
    } else if ([meal isEqualToString:@"French"]) {
        result.url = @"http://samples.ogp.me/314483375313596";
    } else if ([meal isEqualToString:@"Chinese"]) {
        result.url = @"http://samples.ogp.me/314483421980258";
    } else if ([meal isEqualToString:@"Thai"]) {
        result.url = @"http://samples.ogp.me/314483451980255";
    } else if ([meal isEqualToString:@"Indian"]) {
        result.url = @"http://samples.ogp.me/314483491980251";
    } else {
        return nil;
    }
    return result;
}

- (void)enableUserInteraction:(BOOL) enabled {
    if (enabled) {
        [self.activityIndicator stopAnimating];
    } else {
        [self centerAndShowActivityIndicator];
    }

    self.announceButton.enabled = enabled;
    [self.view setUserInteractionEnabled:enabled];
}

- (id<SCOGEatMealAction>)actionFromMealInfo {
    // Create an Open Graph eat action with the meal, our location, and the people we were with.
    id<SCOGEatMealAction> action = (id<SCOGEatMealAction>)[FBGraphObject graphObject];

    if (self.selectedPlace) {
        // Facebook SDK * pro-tip *
        // We don't use the action.place syntax here because, unfortunately, setPlace:
        // and a few other selectors may be flagged as reserved selectors by Apple's App Store
        // validation tools. While this doesn't necessarily block App Store approval, it
        // could slow down the approval process. Falling back to the setObject:forKey:
        // selector is a useful technique to avoid such naming conflicts.
        [action setObject:self.selectedPlace forKey:@"place"];
    }

    if (self.selectedFriends.count > 0) {
        [action setObject:self.selectedFriends forKey:@"tags"];
    }

    return action;
}

// Creates the Open Graph Action.
- (void)postOpenGraphAction {
    [self enableUserInteraction:NO];

    FBRequestConnection *requestConnection = [[FBRequestConnection alloc] init];
    requestConnection.errorBehavior = FBRequestConnectionErrorBehaviorRetry
                                    | FBRequestConnectionErrorBehaviorReconnectSession;
    if (self.selectedPhoto) {
        self.selectedPhoto = [self normalizedImage:self.selectedPhoto];
        FBRequest *stagingRequest = [FBRequest requestForUploadStagingResourceWithImage:self.selectedPhoto];
        [requestConnection addRequest:stagingRequest
                    completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                            if (error) {
                                                [self enableUserInteraction:YES];
                                                [self handlePostOpenGraphActionError:error];
                                            }
                                        }
                       batchEntryName:@"stagedphoto"];
    }

    // Create an Open Graph eat action with the meal, our location, and the people we were with.
    id<SCOGEatMealAction> action = [self actionFromMealInfo];

    id image = DEFAULT_IMAGE_URL;
    if (self.selectedPhoto) {
        image = @[@{@"url":@"{result=stagedphoto:$.uri}", @"user_generated":@"true"}];
        action.image = image;
    }

    // create the Open Graph meal object for the meal we ate.
    id<SCOGMeal> mealObject = [self mealObjectForMeal:self.selectedMeal];
    if (mealObject) {
        action.meal = mealObject;
    } else {
        // Facebook SDK * Object API *
        id object = [FBGraphObject openGraphObjectForPostWithType:@"fb_sample_scrumps:meal"
                                                            title:self.selectedMeal
                                                            image:image
                                                              url:nil
                                                      description:[@"Delicious " stringByAppendingString:self.selectedMeal]];
        FBRequest *createObject = [FBRequest requestForPostOpenGraphObject:object];

        // We'll add the object creaction to the batch, and set the action's meal accordingly.
        [requestConnection addRequest:createObject
                    completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                            if (error) {
                                                [self enableUserInteraction:YES];
                                                [self handlePostOpenGraphActionError:error];
                                            }
                                        }
                       batchEntryName:@"createobject"];

        action[@"meal"] = @"{result=createobject:$.id}";
    }

    // Create the request and post the action to the "me/fb_sample_scrumps:eat" path.
    FBRequest *actionRequest = [FBRequest requestForPostWithGraphPath:@"me/fb_sample_scrumps:eat"
                                                          graphObject:action];
    [requestConnection addRequest:actionRequest
                    completionHandler:^(FBRequestConnection *connection,
                         id result,
                         NSError *error) {

         [self enableUserInteraction:YES];
         if (result) {
             [[[UIAlertView alloc] initWithTitle:@"Result"
                                         message:[NSString stringWithFormat:@"Posted Open Graph action, id: %@",
                                                  [result objectForKey:@"id"]]
                                        delegate:nil
                               cancelButtonTitle:@"Thanks!"
                               otherButtonTitles:nil]
              show];

             // start over
             [self resetMealInfo];
         } else if (error) {
             [self handlePostOpenGraphActionError:error];
         }
     }];
    [requestConnection start];
}

- (void)resetMealInfo {
    // start over
    self.selectedMeal = nil;
    self.selectedPlace = nil;
    self.selectedFriends = nil;
    self.selectedPhoto = nil;
    _retryCount = 0;
    [self updateSelections];
}

- (void)handlePostOpenGraphActionError:(NSError *) error{
    // Facebook SDK * error handling *
    // Some Graph API errors are retriable. For this sample, we will have a simple
    // retry policy of one additional attempt. Please refer to
    // https://developers.facebook.com/docs/reference/api/errors/ for more information.
    _retryCount++;
    FBErrorCategory errorCategory = [FBErrorUtility errorCategoryForError:error];
    if (errorCategory == FBErrorCategoryThrottling) {
        // We also retry on a throttling error message. A more sophisticated app
        // should consider a back-off period.
        if (_retryCount < 2) {
            NSLog(@"Retrying open graph post");
            [self postOpenGraphAction];
            return;
        } else {
            NSLog(@"Retry count exceeded.");
        }
    }

    // Facebook SDK * pro-tip *
    // Users can revoke post permissions on your app externally so it
    // can be worthwhile to request for permissions again at the point
    // that they are needed. This sample assumes a simple policy
    // of re-requesting permissions.
    if (errorCategory == FBErrorCategoryPermissions) {
        NSLog(@"Re-requesting permissions");
        [self requestPermissionAndPost];
        return;
    }

    // Facebook SDK * error handling *
    [self presentAlertForError:error];
}
// Helper method to request publish permissions and post.
- (void)requestPermissionAndPost {
    [FBSession.activeSession requestNewPublishPermissions:[NSArray arrayWithObject:@"publish_actions"]
                                          defaultAudience:FBSessionDefaultAudienceFriends
                                        completionHandler:^(FBSession *session, NSError *error) {
                                            if (!error && [FBSession.activeSession.permissions indexOfObject:@"publish_actions"] != NSNotFound) {
                                                // Now have the permission
                                                [self postOpenGraphAction];
                                            } else if (error){
                                                // Facebook SDK * error handling *
                                                // if the operation is not user cancelled
                                                if ([FBErrorUtility errorCategoryForError:error] != FBErrorCategoryUserCancelled) {
                                                    [self presentAlertForError:error];
                                                }
                                            }
                                        }];
}

- (void) presentAlertForError:(NSError *)error {
    // Facebook SDK * error handling *
    // Error handling is an important part of providing a good user experience.
    // When shouldNotifyUser is YES, a userMessage can be
    // presented as a user-ready message
    if ([FBErrorUtility shouldNotifyUserForError:error]) {
        // The SDK has a message for the user, surface it.
        [[[UIAlertView alloc] initWithTitle:@"Something Went Wrong"
                                    message:[FBErrorUtility userMessageForError:error]
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    } else {
        NSLog(@"unexpected error:%@", error);
    }
}

#pragma mark - UI Behavior

-(void)settingsButtonWasPressed:(id)sender {
    [self presentLoginSettings];
}

-(void)presentLoginSettings {
    if (self.settingsViewController == nil) {
        self.settingsViewController = [[FBUserSettingsViewController alloc] init];
#ifdef __IPHONE_7_0
        if ([self.settingsViewController respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
            self.settingsViewController.edgesForExtendedLayout &= ~UIRectEdgeTop;
        }
#endif
        self.settingsViewController.delegate = self;
    }

    [self.navigationController pushViewController:self.settingsViewController animated:YES];
}

// Handles the user clicking the Announce button by creating an Open Graph Action
- (IBAction)announce:(id)sender {
    if (FBSession.activeSession.isOpen) {
        // Attempt to post immediately - note the error handling logic will request permissions
        // if they are needed.
        [self postOpenGraphAction];
    } else {
        // Facebook SDK * pro-tip *
        // Support sharing even if the user isn't logged in with Facebook, by using the share dialog
        [self presentShareDialogForMealInfo];
    }
}

- (void)presentShareDialogForMealInfo {
    id image = DEFAULT_IMAGE_URL;
    // Create an Open Graph eat action with the meal, our location, and the people we were with.
    id<SCOGEatMealAction> action = [self actionFromMealInfo];

    if (self.selectedPhoto) {
        self.selectedPhoto = [self normalizedImage:self.selectedPhoto];
        image = @[@{@"url":self.selectedPhoto, @"user_generated":@"true"}];
        action.image = image;
    }

    id object = [FBGraphObject openGraphObjectForPostWithType:@"fb_sample_scrumps:meal"
                                                        title:self.selectedMeal
                                                        image:image
                                                          url:nil
                                                  description:[@"Delicious " stringByAppendingString:self.selectedMeal]];
    action.meal = object;

    BOOL presentable = nil != [FBDialogs presentShareDialogWithOpenGraphAction:action
                                                                    actionType:@"fb_sample_scrumps:eat"
                                                           previewPropertyName:@"meal"
                                                                       handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
                                                                           if (!error) {
                                                                               [self resetMealInfo];
                                                                           } else {
                                                                               NSLog(@"%@", error);
                                                                           }
                                                                       }];
    if (!presentable) { // this means that the Facebook app is not installed or up to date
        // if the share dialog is not available, lets encourage a login so we can share directly
        [self presentLoginSettings];
    }
}

- (void)centerAndShowActivityIndicator {
    CGRect frame = self.view.frame;
    CGPoint center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
    self.activityIndicator.center = center;
    [self.activityIndicator startAnimating];
}

// Displays the user's name and profile picture so they are aware of the Facebook
// identity they are logged in as.
- (void)populateUserDetails {
    if (FBSession.activeSession.isOpen) {
        [[FBRequest requestForMe] startWithCompletionHandler:
         ^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
             if (!error) {
                 self.userNameLabel.text = user.name;
                 self.userProfileImage.profileID = [user objectForKey:@"id"];
             }
         }];
    }
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
    self.photoViewController = nil;
}

#pragma mark - UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {

    // If user presses cancel, do nothing
    if (buttonIndex == actionSheet.cancelButtonIndex)
        return;

    // One method handles the delegate action for two action sheets
    if (actionSheet == self.mealPickerActionSheet) {
        if (buttonIndex == 0) {
            // They chose manual entry so prompt the user for an entry.
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"What are you eating?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
            alert.alertViewStyle = UIAlertViewStylePlainTextInput;
            [alert textFieldAtIndex:0].autocapitalizationType = UITextAutocapitalizationTypeSentences;
            [alert show];
        } else {
            self.selectedMeal = [self.mealTypes objectAtIndex:buttonIndex];
            [self updateSelections];
        }
    } else { // self.imagePickerActionSheet
        NSAssert(actionSheet == self.imagePickerActionSheet, @"Delegate method's else-case should be for image picker");

        if (!self.imagePicker) {
            self.imagePicker = [[UIImagePickerController alloc] init];
            self.imagePicker.delegate = self;
        }

        // Set the source type of the imagePicker to the users selection
        if (buttonIndex == 0) {
            // If its the simulator, camera is no good
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
}

#pragma mark - Overrides

- (void)dealloc {
    _locationManager.delegate = nil;
    _mealPickerActionSheet.delegate = nil;
    _settingsViewController.delegate = nil;
    _imagePicker.delegate = nil;
    _imagePickerActionSheet.delegate = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Scrumptious";

    // Get the CLLocationManager going.
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    // We don't want to be notified of small changes in location, preferring to use our
    // last cached results, if any.
    self.locationManager.distanceFilter = 50;

    FBCacheDescriptor *cacheDescriptor = [FBFriendPickerViewController cacheDescriptor];
    [cacheDescriptor prefetchAndCacheForSession:FBSession.activeSession];

    // This avoids a gray background in the table view on iPad.
    if ([self.menuTableView respondsToSelector:@selector(backgroundView)]) {
        self.menuTableView.backgroundView = nil;
    }

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithTitle:@"Settings"
                                                style:UIBarButtonItemStyleBordered
                                              target:self
                                              action:@selector(settingsButtonWasPressed:)];

    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.activityIndicator];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (FBSession.activeSession.isOpen) {
        [self populateUserDetails];
        self.userProfileImage.hidden = NO;
    } else {
        self.userProfileImage.hidden = YES;
    }
}

- (void) viewDidAppear:(BOOL)animated {
    if (FBSession.activeSession.isOpen) {
        [self.locationManager startUpdatingLocation];
    }
}

- (void)viewDidUnload {
    [super viewDidUnload];

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    // Release any retained subviews of the main view.
    self.mealPickerActionSheet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (!alertView.cancelButtonIndex == buttonIndex) {
        self.selectedMeal = [alertView textFieldAtIndex:0].text;
        [self updateSelections];
    }
}

#pragma mark - FBUserSettingsDelegate methods

- (void)loginViewControllerDidLogUserOut:(id)sender {
    // Facebook SDK * login flow *
    // There are many ways to implement the Facebook login flow.
    // In this sample, the FBLoginView delegate (SCLoginViewController)
    // will already handle logging out so this method is a no-op.
}

- (void)loginViewController:(id)sender receivedError:(NSError *)error{
    // Facebook SDK * login flow *
    // There are many ways to implement the Facebook login flow.
    // In this sample, the FBUserSettingsViewController is only presented
    // as a log out option after the user has been authenticated, so
    // no real errors should occur. If the FBUserSettingsViewController
    // had been the entry point to the app, then this error handler should
    // be as rigorous as the FBLoginView delegate (SCLoginViewController)
    // in order to handle login errors.
    if (error) {
        NSLog(@"Unexpected error sent to the FBUserSettingsViewController delegate: %@", error);
    }
}

#pragma mark - UITableViewDataSource methods and related helpers

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryNone;
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
    switch (indexPath.row) {
        case 0: {
            // if we don't yet have an array of meal types, create one now
            if (!self.mealTypes) {
                self.mealTypes = [NSArray arrayWithObjects:
                                  @"< Write Your Own >",
                                  @"Cheeseburger",
                                  @"Pizza",
                                  @"Hotdog",
                                  @"Italian",
                                  @"French",
                                  @"Chinese",
                                  @"Thai",
                                  @"Indian",
                                  nil];
            }
            self.mealPickerActionSheet = [[UIActionSheet alloc] initWithTitle:@"Select a meal"
                                                                     delegate:self
                                                            cancelButtonTitle:nil
                                                       destructiveButtonTitle:nil
                                                            otherButtonTitles:nil];

            for( NSString *meal in self.mealTypes) {
                [self.mealPickerActionSheet addButtonWithTitle:meal];
            }

            self.mealPickerActionSheet.cancelButtonIndex = [self.mealPickerActionSheet addButtonWithTitle:@"Cancel"];
            [self.mealPickerActionSheet showFromToolbar:self.navigationController.toolbar];
            return;
        }

        case 1: {
            if (FBSession.activeSession.isOpen) {
                FBPlacePickerViewController *placePicker = [[FBPlacePickerViewController alloc] init];

                placePicker.title = @"Select a restaurant";

                // SIMULATOR BUG:
                // See http://stackoverflow.com/questions/7003155/error-server-did-not-accept-client-registration-68
                // at times the simulator fails to fetch a location; when that happens rather than fetch a
                // a meal near 0,0 -- let's see if we can find something good in Paris
                if (self.placeCacheDescriptor == nil) {
                    [self setPlaceCacheDescriptorForCoordinates:CLLocationCoordinate2DMake(48.857875, 2.294635)];
                }

                [placePicker configureUsingCachedDescriptor:self.placeCacheDescriptor];
                [placePicker loadData];
                [placePicker presentModallyFromViewController:self
                                                     animated:YES
                                                      handler:^(FBViewController *sender, BOOL donePressed) {
                                                          if (donePressed) {
                                                              self.selectedPlace = placePicker.selection;
                                                              [self updateSelections];
                                                          }
                                                      }];
            } else {
                // if not logged in, give the user the option to log in
                [self presentLoginSettings];
            }
            return;
        }

        case 2: {
            if (FBSession.activeSession.isOpen) {
                FBFriendPickerViewController *friendPicker = [[FBFriendPickerViewController alloc] init];

                // Set up the friend picker to sort and display names the same way as the
                // iOS Address Book does.

                // Need to call ABAddressBookCreate in order for the next two calls to do anything.
                ABAddressBookRef addressBook = ABAddressBookCreate();
                ABPersonSortOrdering sortOrdering = ABPersonGetSortOrdering();
                ABPersonCompositeNameFormat nameFormat = ABPersonGetCompositeNameFormat();

                friendPicker.sortOrdering = (sortOrdering == kABPersonSortByFirstName) ? FBFriendSortByFirstName : FBFriendSortByLastName;
                friendPicker.displayOrdering = (nameFormat == kABPersonCompositeNameFormatFirstNameFirst) ? FBFriendDisplayByFirstName : FBFriendDisplayByLastName;

                [friendPicker loadData];
                [friendPicker presentModallyFromViewController:self
                                                      animated:YES
                                                       handler:^(FBViewController *sender, BOOL donePressed) {
                                                           if (donePressed) {
                                                               self.selectedFriends = friendPicker.selection;
                                                               [self updateSelections];
                                                           }
                                                       }];
                CFRelease(addressBook);
            } else {
                // if not logged in, give the user the option to log in
                [self presentLoginSettings];
            }
            return;
        }

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
            return;
    }
}

- (void)updateCellIndex:(int)index withSubtitle:(NSString *)subtitle {
    UITableViewCell *cell = (UITableViewCell *)[self.menuTableView cellForRowAtIndexPath:
                                                [NSIndexPath indexPathForRow:index inSection:0]];
    cell.detailTextLabel.text = subtitle;
}

- (void)updateSelections {
    [self updateCellIndex:0 withSubtitle:(self.selectedMeal ?
                                          self.selectedMeal :
                                          @"Select one")];
    [self updateCellIndex:1 withSubtitle:(self.selectedPlace ?
                                          self.selectedPlace.name :
                                          @"Select one")];

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

#pragma mark - CLLocationManagerDelegate methods and related

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    if (!oldLocation ||
        (oldLocation.coordinate.latitude != newLocation.coordinate.latitude &&
         oldLocation.coordinate.longitude != newLocation.coordinate.longitude &&
         newLocation.horizontalAccuracy <= 100.0)) {
            // Fetch data at this new location, and remember the cache descriptor.
            [self setPlaceCacheDescriptorForCoordinates:newLocation.coordinate];
            [self.placeCacheDescriptor prefetchAndCacheForSession:FBSession.activeSession];
    }
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
    NSLog(@"%@", error);
}

- (void)setPlaceCacheDescriptorForCoordinates:(CLLocationCoordinate2D)coordinates {
    self.placeCacheDescriptor =
    [FBPlacePickerViewController cacheDescriptorWithLocationCoordinate:coordinates
                                                        radiusInMeters:1000
                                                            searchText:@"restaurant"
                                                          resultsLimit:50
                                                      fieldsForRequest:nil];
}

#pragma mark -

- (UIImage*) normalizedImage:(UIImage*)image {
    CGImageRef          imgRef = image.CGImage;
    CGFloat             width = CGImageGetWidth(imgRef);
    CGFloat             height = CGImageGetHeight(imgRef);
    CGAffineTransform   transform = CGAffineTransformIdentity;
    CGRect              bounds = CGRectMake(0, 0, width, height);
    CGSize              imageSize = bounds.size;
    CGFloat             boundHeight;
    UIImageOrientation  orient = image.imageOrientation;

    switch (orient) {
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;

        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;

        case UIImageOrientationLeft: //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;

        case UIImageOrientationRight: //EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;

        default:
            // image is not auto-rotated by the photo picker, so whatever the user
            // sees is what they expect to get. No modification necessary
            transform = CGAffineTransformIdentity;
            break;
    }

    UIGraphicsBeginImageContext(bounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();

    if ((image.imageOrientation == UIImageOrientationDown) ||
        (image.imageOrientation == UIImageOrientationRight) ||
        (image.imageOrientation == UIImageOrientationUp)) {
        // flip the coordinate space upside down
        CGContextScaleCTM(context, 1, -1);
        CGContextTranslateCTM(context, 0, -height);
    }

    CGContextConcatCTM(context, transform);
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageCopy;
}

@end
