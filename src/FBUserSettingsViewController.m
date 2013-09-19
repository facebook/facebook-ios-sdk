/*
 * Copyright 2010-present Facebook.
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

#import "FBUserSettingsViewController.h"
#import "FBProfilePictureView.h"
#import "FBGraphUser.h"
#import "FBSession.h"
#import "FBSession+Internal.h"
#import "FBRequest.h"
#import "FBViewController+Internal.h"
#import "FBUtility.h"
#import "FBAppEvents+Internal.h"

@interface FBUserSettingsViewController ()

@property (nonatomic, retain) FBProfilePictureView *profilePicture;
@property (nonatomic, retain) UIImageView *backgroundImageView;
@property (nonatomic, retain) UILabel *connectedStateLabel;
@property (nonatomic, retain) id<FBGraphUser> me;
@property (nonatomic, retain) UIButton *loginLogoutButton;
@property (nonatomic) BOOL attemptingLogin;
@property (nonatomic, retain) NSBundle *bundle;
@property (copy, nonatomic) FBSessionStateHandler sessionStateHandler;
@property (copy, nonatomic) FBRequestHandler requestHandler;

- (void)loginLogoutButtonPressed:(id)sender;
- (void)sessionStateChanged:(FBSession *)session 
                      state:(FBSessionState)state
                      error:(NSError *)error;
- (void)openSession;
- (void)updateControls;
- (void)updateBackgroundImage;

@end

@implementation FBUserSettingsViewController

@synthesize profilePicture = _profilePicture;
@synthesize connectedStateLabel = _connectedStateLabel;
@synthesize me = _me;
@synthesize loginLogoutButton = _loginLogoutButton;
@synthesize permissions = _permissions;
@synthesize readPermissions = _readPermissions;
@synthesize publishPermissions = _publishPermissions;
@synthesize defaultAudience = _defaultAudience;
@synthesize attemptingLogin = _attemptingLogin;
@synthesize backgroundImageView = _backgroundImageView;
@synthesize bundle = _bundle;
@synthesize sessionStateHandler = _sessionStateHandler;
@synthesize requestHandler = _requestHandler;

#pragma mark View controller lifecycle

- (void)initializeBlocks {
    // Set up our block handlers in a way that supports nil'ing out the weak self reference to
    // prevent EXC_BAD_ACCESS errors if the session invokes the handler after the FBUserSettingsViewController
    // has been deallocated. Note the handlers are declared as a `copy` property so that
    // the block lives on the heap.
    __block FBUserSettingsViewController *weakSelf = self;
    self.sessionStateHandler = ^(FBSession *session, FBSessionState status, NSError *error) {
        if (session == nil) {
            // The nil sentinel value for session indicates both blocks should no-op thereafter.
            weakSelf = nil;
        } else {
            [weakSelf sessionStateChanged:session state:status error:error];
        }
    };
    self.requestHandler = ^(FBRequestConnection *connection, id result, NSError *error) {
        if (result) {
            weakSelf.me = result;
            [weakSelf updateControls];
        }
    };
}

- (id)init {
    if (self = [super init]) {
        [self initializeBlocks];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]){
        [self initializeBlocks];
    }
    return self;
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.cancelButton = nil;
        self.attemptingLogin = NO;

        NSString *path = [[NSBundle mainBundle] pathForResource:@"FBUserSettingsViewResources"
                                                         ofType:@"bundle"];
        self.bundle = [NSBundle bundleWithPath:path];
        if (self.bundle == nil) {
            NSLog(@"WARNING: FBUserSettingsViewController could not find FBUserSettingsViewResources.bundle");
        }
        [self initializeBlocks];
    }
    return self;
}

- (void)dealloc {
    // As noted in `initializeBlocks`, if we are being dealloc'ed, we
    // need to let our handlers know with the sentinel value of nil
    // to prevent EXC_BAD_ACCESS errors.
    self.sessionStateHandler(nil, FBSessionStateClosed, nil);
    [_sessionStateHandler release];
    [_requestHandler release];
    
    [_profilePicture release];
    [_connectedStateLabel release];
    [_me release];
    [_loginLogoutButton release];
    [_permissions release];
    [_backgroundImageView release];
    [_bundle release];    
    [super dealloc];
}

#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // If we are not being presented modally, we don't need a Done button.
    if (self.presentingViewController == nil) {
        self.doneButton = nil;
    }
    
    // If you remove the background images from the resource bundle in order to save space,
    //  this allows the background to still be rendered in Facebook blue.
    UIColor *facebookBlue = [UIColor colorWithRed:(59.0 / 255.0)
                                            green:(89.0 / 255.0)
                                             blue:(152.0 / 255.0)
                                            alpha:1.0];
    self.view.backgroundColor = facebookBlue;

    CGRect usableBounds = self.canvasView.bounds;

    self.backgroundImageView = [[[UIImageView alloc] init] autorelease];
    self.backgroundImageView.frame = usableBounds;
    self.backgroundImageView.userInteractionEnabled = NO;
    self.backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.canvasView addSubview:self.backgroundImageView];
    [self updateBackgroundImage];
    
    UIImageView *logo = [[[UIImageView alloc] 
                         initWithImage:[UIImage imageNamed:@"FBUserSettingsViewResources.bundle/images/facebook-logo.png"]] autorelease];
    CGPoint center = CGPointMake(CGRectGetMidX(usableBounds), 68);
    logo.center = center;
    logo.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.canvasView addSubview:logo];
    
    // We want the profile picture control and label to be grouped together when autoresized,
    // so we put them in a subview.
    UIView *containerView = [[[UIView alloc] init] autorelease];
    containerView.frame = CGRectMake(0, 
                                     135,
                                     usableBounds.size.width,
                                     110);
    containerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;

    // Add profile picture control
    self.profilePicture = [[[FBProfilePictureView alloc] initWithProfileID:nil
                                                        pictureCropping:FBProfilePictureCroppingSquare]
                           autorelease];
    self.profilePicture.frame = CGRectMake(containerView.frame.size.width / 2 - 32, 0, 64, 64);
    [containerView addSubview:self.profilePicture];

    // Add connected state/name control
    self.connectedStateLabel = [[[UILabel alloc] init] autorelease];
    self.connectedStateLabel.frame = CGRectMake(0, 
                                                self.profilePicture.frame.size.height + 14.0,
                                                containerView.frame.size.width,
                                                20);
    self.connectedStateLabel.backgroundColor = [UIColor clearColor];
#ifdef __IPHONE_6_0
    self.connectedStateLabel.textAlignment = NSTextAlignmentCenter;
#else
    self.connectedStateLabel.textAlignment = UITextAlignmentCenter;
#endif
    self.connectedStateLabel.numberOfLines = 0;
    self.connectedStateLabel.font = [UIFont boldSystemFontOfSize:16.0];
    self.connectedStateLabel.shadowColor = [UIColor blackColor];
    self.connectedStateLabel.shadowOffset = CGSizeMake(0.0, -1.0);
    [containerView addSubview:self.connectedStateLabel];
    [self.canvasView addSubview:containerView];
    
    // Add the login/logout button
    self.loginLogoutButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *image = [UIImage imageNamed:@"FBUserSettingsViewResources.bundle/images/silver-button-normal.png"];
    [self.loginLogoutButton setBackgroundImage:image forState:UIControlStateNormal];
    image = [UIImage imageNamed:@"FBUserSettingsViewResources.bundle/images/silver-button-pressed.png"];
    [self.loginLogoutButton setBackgroundImage:image forState:UIControlStateHighlighted];
    self.loginLogoutButton.frame = CGRectMake((int)((usableBounds.size.width - image.size.width) / 2),
                                              285,
                                              image.size.width,
                                              image.size.height);
    [self.loginLogoutButton addTarget:self
                               action:@selector(loginLogoutButtonPressed:)
                     forControlEvents:UIControlEventTouchUpInside];
    self.loginLogoutButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    UIColor *loginTitleColor = [UIColor colorWithRed:75.0 / 255.0
                                               green:81.0 / 255.0
                                                blue:100.0 / 255.0
                                               alpha:1.0];
    [self.loginLogoutButton setTitleColor:loginTitleColor forState:UIControlStateNormal];
    self.loginLogoutButton.titleLabel.font = [UIFont boldSystemFontOfSize:18.0];

    UIColor *loginShadowColor = [UIColor colorWithRed:212.0 / 255.0
                                                green:218.0 / 255.0
                                                 blue:225.0 / 255.0
                                                alpha:1.0];
    [self.loginLogoutButton setTitleShadowColor:loginShadowColor forState:UIControlStateNormal];
    self.loginLogoutButton.titleLabel.shadowOffset = CGSizeMake(0.0, 1.0);
    [self.canvasView addSubview:self.loginLogoutButton];
    
    // We need to know when the active session changes state.
    // We use the same handler for both, because we don't actually care about distinguishing between them.
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(handleActiveSessionStateChanged:) 
                                                 name:FBSessionDidBecomeOpenActiveSessionNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(handleActiveSessionStateChanged:) 
                                                 name:FBSessionDidBecomeClosedActiveSessionNotification
                                               object:nil];

    [self updateControls];
}

- (void)updateBackgroundImage {
    NSString *orientation = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? @"Portrait" : @"Landscape";
    NSString *idiom = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ? @"IPhone" : @"IPad";
    NSString *imagePath = [NSString stringWithFormat:@"FBUserSettingsViewResources.bundle/images/loginBackground%@%@.jpg", idiom, orientation];
    self.backgroundImageView.image = [UIImage imageNamed:imagePath];
}

- (void)viewDidUnload {
    [super viewDidUnload];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self updateBackgroundImage];
}

- (NSUInteger)supportedInterfaceOrientations {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAll;
    } else {
        return UIInterfaceOrientationMaskPortrait;
    }
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [FBAppEvents logImplicitEvent:FBAppEventNameUserSettingsUsage
                       valueToSum:nil
                       parameters:@{ @"view_will_appear" : [NSNumber numberWithBool:YES] }
                          session:FBSession.activeSessionIfExists];
}
#pragma mark Implementation

- (void)updateControls {
    if (FBSession.activeSession.isOpen) {
        NSString *loginLogoutText = [FBUtility localizedStringForKey:@"FBUSVC:LogOut"
                                                         withDefault:@"Log Out"
                                                            inBundle:self.bundle];
        [self.loginLogoutButton setTitle:loginLogoutText forState:UIControlStateNormal];
        
        // Label should be white with a shadow
        self.connectedStateLabel.textColor = [UIColor whiteColor];
        self.connectedStateLabel.shadowColor = [UIColor blackColor];

        // Move the label back below the profile view and show the profile view
        self.connectedStateLabel.frame = CGRectMake(0, 
                                                    self.profilePicture.frame.size.height + 16.0, 
                                                    self.connectedStateLabel.frame.size.width,
                                                    20);
        self.profilePicture.hidden = NO;
        
        // Do we know the user's name? If not, request it.
        if (self.me != nil) {
            self.connectedStateLabel.text = self.me.name;
            self.profilePicture.profileID = [self.me objectForKey:@"id"];
        } else {
            self.connectedStateLabel.text = [FBUtility localizedStringForKey:@"FBUSVC:LoggedIn"
                                                                 withDefault:@"Logged in"
                                                                    inBundle:self.bundle];
            self.profilePicture.profileID = nil;

            [[FBRequest requestForMe] startWithCompletionHandler:self.requestHandler];
        }
    } else {
        self.me = nil;
        
        // Label should be gray and centered in its superview; hide the profile view
        self.connectedStateLabel.textColor = [UIColor colorWithRed:166.0 / 255.0
                                                             green:174.0 / 255.0
                                                              blue:215.0 / 255.0 
                                                             alpha:1.0];
        self.connectedStateLabel.shadowColor = nil;

        CGRect parentBounds = self.connectedStateLabel.superview.bounds;
        self.connectedStateLabel.center = CGPointMake(CGRectGetMidX(parentBounds),
                                                      CGRectGetMidY(parentBounds));
        self.profilePicture.hidden = YES;
        
        self.connectedStateLabel.text = [FBUtility localizedStringForKey:@"FBUSVC:NotLoggedIn"
                                                             withDefault:@"Not logged in"
                                                                inBundle:self.bundle];
        self.profilePicture.profileID = nil;
        NSString *loginLogoutText = [FBUtility localizedStringForKey:@"FBUSVC:LogIn"
                                                         withDefault:@"Log In..."
                                                            inBundle:self.bundle];
        [self.loginLogoutButton setTitle:loginLogoutText forState:UIControlStateNormal];
    }
}

- (void)sessionStateChanged:(FBSession *)session 
                      state:(FBSessionState)state
                      error:(NSError *)error
{
    if (error &&
        [self.delegate respondsToSelector:@selector(loginViewController:receivedError:)]) {
        [(id)self.delegate loginViewController:self receivedError:error];
    }

    if (self.attemptingLogin) {
        if (FB_ISSESSIONOPENWITHSTATE(state)) {
            self.attemptingLogin = NO;

            if ([self.delegate respondsToSelector:@selector(loginViewControllerDidLogUserIn:)]) {
                [(id)self.delegate loginViewControllerDidLogUserIn:self];
            }
        } else if (FB_ISSESSIONSTATETERMINAL(state)) {
            self.attemptingLogin = NO;
        }
    }
}

#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
- (void)openSession {
    if ([self.delegate respondsToSelector:@selector(loginViewControllerWillAttemptToLogUserIn:)]) {
        [(id)self.delegate loginViewControllerWillAttemptToLogUserIn:self];
    }

    self.attemptingLogin = YES;

    // the policy here is:
    // 1) if you provide unspecified permissions, then we fall back on legacy fast-app-switch
    // 2) if you provide only read permissions, then we call a read-based open method that will use integrated auth
    // 3) if you provide any publish permissions, then we combine the read-set and publish-set and call the publish-based
    //    method that will use integrated auth when availab le
    // 4) if you provide any publish permissions, and don't specify a valid audience, the control will throw an exception
    //    when the user presses login
    if (self.permissions) {
        [FBSession openActiveSessionWithPermissions:self.permissions
                                       allowLoginUI:YES
                                    defaultAudience:self.defaultAudience
                                  completionHandler:self.sessionStateHandler];
    } else if (![self.publishPermissions count]) {
        [FBSession openActiveSessionWithReadPermissions:self.readPermissions
                                           allowLoginUI:YES
                                      completionHandler:self.sessionStateHandler];
    } else {
        // combined read and publish permissions will usually fail, but if the app wants us to
        // try it here, then we will pass the aggregate set to the server
        NSArray *permissions = self.publishPermissions;
        if ([self.readPermissions count]) {
            NSMutableSet *set = [NSMutableSet setWithArray:self.publishPermissions];
            [set addObjectsFromArray:self.readPermissions];
            permissions = [set allObjects];
        }
        [FBSession openActiveSessionWithPublishPermissions:permissions
                                           defaultAudience:self.defaultAudience
                                              allowLoginUI:YES
                                         completionHandler:self.sessionStateHandler];
    }
}
#pragma GCC diagnostic warning "-Wdeprecated-declarations"

#pragma mark Handlers

- (void)loginLogoutButtonPressed:(id)sender {
    if (FBSession.activeSession.isOpen) {
        [FBAppEvents logImplicitEvent:FBAppEventNameUserSettingsUsage
                           valueToSum:nil
                           parameters:@{ @"logging_in" : @NO }
                              session:FBSession.activeSessionIfExists];
        if ([self.delegate respondsToSelector:@selector(loginViewControllerWillLogUserOut:)]) {
            [(id)self.delegate loginViewControllerWillLogUserOut:self];
        }

        [FBSession.activeSession closeAndClearTokenInformation];

        if ([self.delegate respondsToSelector:@selector(loginViewControllerDidLogUserOut:)]) {
            [(id)self.delegate loginViewControllerDidLogUserOut:self];
        }
    } else {
        [FBAppEvents logImplicitEvent:FBAppEventNameUserSettingsUsage
                           valueToSum:nil
                           parameters:@{ @"logging_in" : @YES }
                              session:FBSession.activeSessionIfExists];
        [self openSession];
    }
}

- (void)handleActiveSessionStateChanged:(NSNotification *)notification {
    [self updateControls];
}

@end
