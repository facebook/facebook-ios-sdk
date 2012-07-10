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

#import "FBLoginView.h"
#import "FBProfilePictureView.h"
#import "FBRequest.h"
#import "FBRequestConnection+Internal.h"
#import "FBSession.h"
#import "FBGraphUser.h"

struct FBLoginViewArrangement {
    int width, height;
    int iconExtent;
    int iconX, iconY;
    int profileExtent;
    int profileX, profileY;
    int questionMarkSize;
    int textButtonWidth;
    int textButtonHorizMargin;
};

struct FBLoginViewArrangement arrangements[] = {
    {32, 32, 12, 0, 20, 32, 0, 0, 26, 80, 3},
    {48, 48, 16, 0, 32, 48, 0, 0, 32, 80, 3},
    {64, 32, 32, 32, 0, 32, 0, 0, 28, 80, 3},
};

NSString *const FBLoginViewCacheIdentity = @"FBLoginView";

@interface FBLoginView() <UIActionSheetDelegate>

- (void)initialize;
- (void)arrangeViews:(int)arrangement;
- (void)buttonPressed:(id)sender;
- (void)configureViewForStateLoggedIn:(BOOL)isLoggedIn;
- (void)wireViewForSession:(FBSession *)session;
- (void)wireViewForSessionWithoutOpening:(FBSession *)session;
- (void)unwireViewForSession ;
- (void)fetchMeInfo;
- (void)informDelegate:(BOOL)userOnly;
- (void)handleActiveSessionSetNotifications:(NSNotification *)notification;
- (void)handleActiveSessionUnsetNotifications:(NSNotification *)notification;

@property (retain, nonatomic) UIImageView *icon;
@property (retain, nonatomic) FBProfilePictureView *profilePicture;
@property (retain, nonatomic) UILabel *label;
@property (retain, nonatomic) UIButton *profileButton;
@property (retain, nonatomic) UIButton *textButton;
@property (retain, nonatomic) FBSession *session;
@property (retain, nonatomic) FBRequestConnection *request;
@property (retain, nonatomic) id<FBGraphUser> user;

@end

@implementation FBLoginView

@synthesize style = _style,
            delegate = _delegate,
            icon = _icon,
            profilePicture = _profilePicture,
            label = _label,
            profileButton = _profileButton,
            textButton = _textButton,
            session = _session,
            request = _request,
            user = _user,
            permissions = _permissions;

- (id)init {
    return [self initWithPermissions:nil];
}

- (id)initWithPermissions:(NSArray *)permissions {
    self = [super init];
    if (self) {
        self.permissions = permissions;
        [self initialize];
    }
    return self;
}

- (id)initWithFrame:(CGRect)aRect {
    self = [super initWithFrame:aRect];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)dealloc {
    
    // removes all observers for self
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // if we have an outstanding request, cancel
    [self.request cancel];
    
    self.request = nil;
    self.icon = nil;
    self.profilePicture = nil;
    self.label = nil;
    self.profileButton = nil;
    self.textButton = nil;
    self.session = nil;
    self.user = nil;
    self.permissions = nil;

    [super dealloc];
}

- (void)setStyle:(FBLoginViewStyle)style  {
    if (_style != style && style <= FBLoginViewStyleHorizontal) {
        _style = style;
        [self arrangeViews:_style];
        [self configureViewForStateLoggedIn:self.session.isOpen];
    }
}

- (void)setDelegate:(id<FBLoginViewDelegate>)newValue {
    if (_delegate != newValue) {
        _delegate = newValue;
        
        // whenever the delegate value changes, we schedule one initial call to inform the delegate
        // of our current state; we use a delay in order to avoid a callback in a setup or init method
        [self performSelector:@selector(informDelegate:)
                   withObject:nil
                   afterDelay:.01];
    }
}

- (void)initialize {
    // the base class can cause virtual recursion, so
    // to handle this we make initialize idempotent
    if (self.profileButton) {
        return;
    }

    // setup view
    self.autoresizesSubviews = YES;
    self.clipsToBounds = YES;
    
    // if our session has a cached token ready, we open it; note that
    // it is important that we open it before wiring is in place to cause KVO, etc.
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
        [FBSession sessionOpenWithPermissions:self.permissions completionHandler:nil];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(handleActiveSessionSetNotifications:) 
                                                 name:FBSessionDidSetActiveSessionNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(handleActiveSessionUnsetNotifications:) 
                                                 name:FBSessionDidUnsetActiveSessionNotification
                                               object:nil]; 
        
    [self wireViewForSession:FBSession.activeSession];
    
    // setup icon view
    self.icon = [[[UIImageView alloc] 
                  initWithImage:[UIImage imageNamed:@"FBiOSSDKResources.bundle/FBLoginView/images/f_logo.png"]]
                 autorelease];
    
    // setup profile picture
    self.profilePicture = [[[FBProfilePictureView alloc] initWithUserID:nil
                                                        pictureCropping:FBProfilePictureCroppingSquare]
                           autorelease];
    
    // setup profile picture
    self.label = [[[UILabel alloc] init] autorelease];
    self.label.text = @"?";
    self.label.backgroundColor = [UIColor clearColor];
    self.label.textColor = [UIColor colorWithRed:59.0/255  // make the ? facebook blue
                                           green:89.0/255
                                            blue:152.0/255
                                           alpha:1];
    self.label.textAlignment = UITextAlignmentCenter;
    
    // setup profile button
    self.profileButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.profileButton setBackgroundImage:[UIImage imageNamed:@"FBiOSSDKResources.bundle/FBLoginView/images/bluetint.png"]
                           forState:UIControlStateHighlighted];
    [self.profileButton addTarget:self 
                           action:@selector(buttonPressed:) 
                 forControlEvents:UIControlEventTouchUpInside];
    
    // setup text button
    self.textButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.textButton addTarget:self
                        action:@selector(buttonPressed:)
              forControlEvents:UIControlEventTouchUpInside];
    
    [self arrangeViews:0];
    
    // adding the views that we need
    [self addSubview:self.profilePicture];
    [self addSubview:self.icon];
    [self addSubview:self.label];
    [self addSubview:self.profileButton];
    [self addSubview:self.textButton];
    
    if (self.session.isOpen) {
        [self fetchMeInfo];
        [self configureViewForStateLoggedIn:YES];
    } else {
        [self configureViewForStateLoggedIn:NO];
    }
}

- (void)arrangeViews:(int)arrangement {
    struct FBLoginViewArrangement a = arrangements[arrangement];
    
    self.frame = CGRectMake(0, 0, a.width + a.textButtonWidth + a.textButtonHorizMargin, a.height);
    self.profileButton.frame = CGRectMake(0, 0, a.width, a.height); 

    self.icon.frame = CGRectMake(a.iconX, a.iconY, a.iconExtent, a.iconExtent);
    self.profilePicture.frame = CGRectMake(a.profileX, a.profileY, a.profileExtent, a.profileExtent);
    self.label.frame = self.profilePicture.frame;
    self.label.font = [UIFont systemFontOfSize:a.questionMarkSize];
    self.textButton.frame = CGRectMake(a.width + a.textButtonHorizMargin, 0, a.textButtonWidth, a.height);
}

- (void)configureViewForStateLoggedIn:(BOOL)isLoggedIn {
    if (isLoggedIn) {
        // removing the views that we don't need
        [self.label removeFromSuperview];
        [self.icon removeFromSuperview];
        [self.textButton setTitle:@"Log Out" forState:UIControlStateNormal];
        
        // adjust profile view
        struct FBLoginViewArrangement a = arrangements[self.style];
        self.profilePicture.center = CGPointMake(a.width / 2, a.height / 2);
    } else {
        // adding the views that we need        
        [self insertSubview:self.icon
               belowSubview:self.profileButton];
        [self insertSubview:self.label
               belowSubview:self.profileButton];
        
        [self.textButton setTitle:@"Log In" forState:UIControlStateNormal];
             
        // adjust profile view
        struct FBLoginViewArrangement a = arrangements[self.style];
        self.profilePicture.frame = CGRectMake(a.profileX, 
                                               a.profileY, 
                                               a.profileExtent, 
                                               a.profileExtent);
        
        self.profilePicture.userID = nil;
        self.user = nil;
    }
}

- (void)fetchMeInfo {
    FBRequest *request = [FBRequest requestForMe];
    [request setSession:self.session];
    self.request = [[[FBRequestConnection alloc] init] autorelease];
    [self.request addRequest:request
           completionHandler:^(FBRequestConnection *connection, NSMutableDictionary<FBGraphUser> *result, NSError *error) {
               if (result) {
                   self.profilePicture.userID = [result objectForKey:@"id"];
                   self.user = result;
                   [self informDelegate:YES];
               } else {
                   self.profilePicture.userID = nil;
                   self.user = nil;
               }
               self.request = nil;
           }];
    [self.request startWithCacheIdentity:FBLoginViewCacheIdentity
                   skipRoundtripIfCached:YES];

}

- (void)informDelegate:(BOOL)userOnly {
    if (userOnly) {
        if ([self.delegate respondsToSelector:@selector(loginViewFetchedUserInfo:user:)]) {
            [self.delegate loginViewFetchedUserInfo:self
                                               user:self.user];
        }
    } else if (FBSession.activeSession.isOpen) {
        if ([self.delegate respondsToSelector:@selector(loginViewShowingLoggedInUser:)]) {
            [self.delegate loginViewShowingLoggedInUser:self];
        }
        // any time we inform/reinform of isOpen event, we want to be sure 
        // to repass the user if we have it
        if (self.user) {
            [self informDelegate:YES];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(loginViewShowingLoggedOutUser:)]) {
            [self.delegate loginViewShowingLoggedOutUser:self];
        }
    }
}

- (void)wireViewForSessionWithoutOpening:(FBSession *)session {
    // if there is an outstanding request for the previous session, cancel
    [self.request cancel];
    self.request = nil;
    
    self.session = session;
    
    // register a KVO observer
    [self.session addObserver:self
                   forKeyPath:@"state"
                      options:NSKeyValueObservingOptionNew
                      context:nil];
}

- (void)wireViewForSession:(FBSession *)session {
    [self wireViewForSessionWithoutOpening:session];
    
    // anytime we find that our session is created with an available token
    // we open it on the spot
    if (self.session.state == FBSessionStateCreatedTokenLoaded) {
        [FBSession sessionOpenWithPermissions:self.permissions completionHandler:nil];
    }
}

- (void)unwireViewForSession {
    // this line of code is the main reason we need to hold on 
    // to the session object at all
    [self.session removeObserver:self
                      forKeyPath:@"state"];
     self.session = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (self.session.isOpen) {
        [self fetchMeInfo];
        [self configureViewForStateLoggedIn:YES];
    } else {
        [self configureViewForStateLoggedIn:NO];        
    }
    [self informDelegate:NO];
}

- (void)handleActiveSessionSetNotifications:(NSNotification *)notification {
    // NSNotificationCenter is a global channel, so we guard against
    // unexpected uses of this notification the best we can
    if ([notification.object isKindOfClass:[FBSession class]]) {
        [self wireViewForSession:notification.object];
    }
}

- (void)handleActiveSessionUnsetNotifications:(NSNotification *)notification {
    [self unwireViewForSession];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) { // logout
        [FBSession.activeSession closeAndClearTokenInformation];
    }
}

- (void)buttonPressed:(id)sender {
    if (self.session == FBSession.activeSession) {
        if (!self.session.isOpen) { // login
            [FBSession sessionOpenWithPermissions:self.permissions completionHandler:nil];
        } else { // logout action sheet
            NSString *name = self.user.name;
            UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"Logged in %@",
                                                                         name ? [NSString stringWithFormat:@"as %@", name] : @"using Facebook"]
                                                               delegate:self
                                                      cancelButtonTitle:@"Cancel"
                                                 destructiveButtonTitle:@"Log Out"
                                                      otherButtonTitles:nil];                
            // Show the sheet
            [sheet showInView:self];
            [sheet release];
        }
    } else { // state of view out of sync with active session
        // so resync
        [self unwireViewForSession];
        [self wireViewForSession:FBSession.activeSession];
        [self configureViewForStateLoggedIn:self.session.isOpen];
        [self informDelegate:NO];
    }
}

@end
