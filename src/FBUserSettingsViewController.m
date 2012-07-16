/*
 * Copyright 2010 Facebook
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
#import "FBRequest.h"

@interface FBUserSettingsViewController ()

@property (nonatomic, retain) FBProfilePictureView *profilePicture;
@property (nonatomic, retain) UILabel *connectedStateLabel;
@property (nonatomic, retain) id<FBGraphUser> me;
@property (nonatomic, retain) UIButton *loginLogoutButton;
@property (nonatomic) BOOL attemptingLogin;

- (void)loginLogoutButtonPressed:(id)sender;
- (void)sessionStateChanged:(FBSession *)session 
                      state:(FBSessionState)state
                      error:(NSError *)error;
- (void)openSession;

@end

@implementation FBUserSettingsViewController

@synthesize profilePicture = _profilePicture;
@synthesize connectedStateLabel = _connectedStateLabel;
@synthesize me = _me;
@synthesize loginLogoutButton = _loginLogoutButton;
@synthesize permissions = _permissions;
@synthesize attemptingLogin = _attemptingLogin;

#pragma mark View controller lifecycle

- (id)init {
    self = [super init];
    if (self) {
        self.cancelButton = nil;
        self.attemptingLogin = NO;
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.cancelButton = nil;
        self.attemptingLogin = NO;
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
    
    [_profilePicture release];
    [_connectedStateLabel release];
    [_me release];
    [_loginLogoutButton release];
    [_permissions release];
}

#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // If we are not being presented modally, we don't need a Done button.
    if (self.presentingViewController == nil) {
        self.doneButton = nil;
    }
    
    UIColor *facebookBlue = [UIColor colorWithRed:(59.0 / 255.0) 
                                            green:(89.0 / 255.0) 
                                             blue:(152.0 / 255.0) 
                                            alpha:1.0];

    self.view.backgroundColor = facebookBlue;
        
    // TODO autoresizing, constants for margins, etc.
    const CGFloat kSideMargin = 20.0;
    const CGFloat kInternalMarginX = 20.0;
    const CGFloat kInternalMarginY = 20.0;
    
    CGRect usableBounds = self.canvasView.bounds;
    
    // We want the profile picture control and label to be grouped together when autoresized,
    // so we put them in a subview.
    UIView *containerView = [[[UIView alloc] init] autorelease];
    containerView.frame = CGRectMake(kSideMargin, 
                                     80, 
                                     usableBounds.size.width - kSideMargin * 2,
                                     64);
    [containerView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];

    // Add profile picture control
    self.profilePicture = [[[FBProfilePictureView alloc] initWithProfileID:nil
                                                        pictureCropping:FBProfilePictureCroppingSquare]
                           autorelease];
    self.profilePicture.frame = CGRectMake(0, 0, 64, 64);
    [containerView addSubview:self.profilePicture];

    // Add connected state/name control
    self.connectedStateLabel = [[[UILabel alloc] init] autorelease];
    self.connectedStateLabel.frame = CGRectMake(64 + kInternalMarginX, 
                                                0, 
                                                containerView.frame.size.width - 64 - kInternalMarginX,
                                                64);
    self.connectedStateLabel.backgroundColor = facebookBlue;
    self.connectedStateLabel.textColor = [UIColor whiteColor];
    self.connectedStateLabel.textAlignment = UITextAlignmentCenter;
    self.connectedStateLabel.numberOfLines = 0;
    // TODO font
    [containerView addSubview:self.connectedStateLabel];
    [self.canvasView addSubview:containerView];
    
    // Add the login/logout button
    self.loginLogoutButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.loginLogoutButton.frame = CGRectMake(kSideMargin,
                                              CGRectGetMaxY(containerView.frame) + kInternalMarginY,
                                              CGRectGetWidth(usableBounds) - 2 * kSideMargin,
                                              32);
    [self.loginLogoutButton addTarget:self
                               action:@selector(loginLogoutButtonPressed:)
                     forControlEvents:UIControlEventTouchUpInside];
    [self.loginLogoutButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
    [self.canvasView addSubview:self.loginLogoutButton];
    
    /* TODO figure out where, if anywhere, to put the logo
    UIImageView *logo = [[UIImageView alloc] 
                                        initWithImage:[UIImage imageNamed:@"FacebookSDKResources.bundle/FBLoginView/images/f_logo.png"]]; // TODO autorelease
    logo.frame = CGRectMake(bounds.size.width - 64 - 10, 10 + yOffset, 64, 64);
    
    [self.view addSubview:logo];
    */
    
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

- (void)viewDidUnload {
    [super viewDidUnload];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
#pragma mark Implementation

- (void)updateControls {
    if (FBSession.activeSession.isOpen) {
        NSString *loginLogoutText = NSLocalizedString(@"Log Out", @"Log Out");
        [self.loginLogoutButton setTitle:loginLogoutText forState:UIControlStateNormal];
        
        // Do we know the user's name? If not, request it.
        if (self.me != nil) {
            NSString *format = NSLocalizedString(@"Logged in as: %@", @"Logged in as: %@");
            self.connectedStateLabel.text = [NSString stringWithFormat:format, self.me.name];
            self.profilePicture.profileID = [self.me objectForKey:@"id"];
        } else {
            self.connectedStateLabel.text = NSLocalizedString(@"Logged in", @"Logged in");
            self.profilePicture.profileID = nil;

            [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                if (result) {
                    self.me = result;
                    [self updateControls];
                }
            }];
        }
    } else {
        self.me = nil;
        self.connectedStateLabel.text = NSLocalizedString(@"Not connected to Facebook", @"Not connected to Facebook");
        self.profilePicture.profileID = nil;
        NSString *loginLogoutText = NSLocalizedString(@"Connect", @"Connect");
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

- (void)openSession {
    if ([self.delegate respondsToSelector:@selector(loginViewControllerWillAttemptToLogUserIn:)]) {
        [(id)self.delegate loginViewControllerWillAttemptToLogUserIn:self];
    }

    self.attemptingLogin = YES;

    [FBSession sessionOpenWithPermissions:self.permissions completionHandler:
     ^(FBSession *session, FBSessionState state, NSError *error) {
         [self sessionStateChanged:session state:state error:error];
     }];
}

#pragma mark Handlers

- (void)loginLogoutButtonPressed:(id)sender {
    if (FBSession.activeSession.isOpen) {
        if ([self.delegate respondsToSelector:@selector(loginViewControllerWillLogUserOut:)]) {
            [(id)self.delegate loginViewControllerWillLogUserOut:self];
        }

        [FBSession.activeSession closeAndClearTokenInformation];

        if ([self.delegate respondsToSelector:@selector(loginViewControllerDidLogUserOut:)]) {
            [(id)self.delegate loginViewControllerDidLogUserOut:self];
        }
    } else {
        [self openSession];
    }
}

- (void)handleActiveSessionStateChanged:(NSNotification *)notification {
    [self updateControls];
}

@end
