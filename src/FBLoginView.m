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

#import "FBLoginView.h"
#import "FBProfilePictureView.h"
#import "FBRequest.h"
#import "FBRequestConnection+Internal.h"
#import "FBSession.h"
#import "FBGraphUser.h"
#import "FBUtility.h"
#import "FBSession+Internal.h"

static NSString *const FBLoginViewCacheIdentity = @"FBLoginView";
const int kButtonLabelX = 46;

CGSize g_imageSize;

@interface FBLoginView() <UIActionSheetDelegate>

- (void)initialize;
- (void)buttonPressed:(id)sender;
- (void)configureViewForStateLoggedIn:(BOOL)isLoggedIn;
- (void)wireViewForSession:(FBSession *)session;
- (void)wireViewForSessionWithoutOpening:(FBSession *)session;
- (void)unwireViewForSession ;
- (void)fetchMeInfo;
- (void)informDelegate:(BOOL)userOnly;
- (void)informDelegateOfError:(NSError *)error;
- (void)handleActiveSessionSetNotifications:(NSNotification *)notification;
- (void)handleActiveSessionUnsetNotifications:(NSNotification *)notification;

@property (retain, nonatomic) UILabel *label;
@property (retain, nonatomic) UIButton *button;
@property (retain, nonatomic) FBSession *session;
@property (retain, nonatomic) FBRequestConnection *request;
@property (retain, nonatomic) id<FBGraphUser> user;
@property (copy, nonatomic) FBSessionStateHandler sessionStateHandler;
@property (copy, nonatomic) FBRequestHandler requestHandler;
// lastObservedStateWasOpen is essentially a nullable bool to track if the
// the session state was open when the inform delegate is called. This is
// to prevent messaging the delegate again in state transfers that are
// not important (e.g., tokenextended, or createdopening).
@property (copy) NSNumber *lastObservedStateWasOpen;

@end

@implementation FBLoginView

@synthesize delegate = _delegate,
    label = _label,
    button = _button,
    session = _session,
    request = _request,
    user = _user,
    permissions = _permissions,
    readPermissions = _readPermissions,
    publishPermissions = _publishPermissions,
    defaultAudience = _defaultAudience,
    lastObservedStateWasOpen = _lastObservedStateWasOpen,
    sessionStateHandler = _sessionStateHandler,
    requestHandler = _requestHandler;


- (id)init {
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithPermissions:(NSArray *)permissions {
    self = [super init];
    if (self) {
        self.permissions = permissions;
        [self initialize];
    }
    return self;
}

- (id)initWithReadPermissions:(NSArray *)readPermissions {
    self = [super init];
    if (self) {
        self.readPermissions = readPermissions;
        [self initialize];
    }
    return self;
}

- (id)initWithPublishPermissions:(NSArray *)publishPermissions
                 defaultAudience:(FBSessionDefaultAudience)defaultAudience {
    self = [super init];
    if (self) {
        self.publishPermissions = publishPermissions;
        self.defaultAudience = defaultAudience;
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
    // As noted in `initializeBlocks`, if we are being dealloc'ed, we
    // need to let our handlers know with the sentinel value of nil
    // to prevent EXC_BAD_ACCESS errors.
    self.sessionStateHandler(nil, FBSessionStateClosed, nil);
    [_sessionStateHandler release];
    [_requestHandler release];
    
    // removes all observers for self
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // if we have an outstanding request, cancel
    [self.request cancel];
    
    // unwire the session to release KVO.
    [self unwireViewForSession];
    
    [_request release];
    [_label release];
    [_button release];
    [_session release];
    [_user release];
    [_permissions release];
    
    [super dealloc];
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

- (void)initializeBlocks {
    // Set up our block handlers in a way that supports nil'ing out the weak self reference to
    // prevent EXC_BAD_ACCESS errors if the session invokes the handler after the FBLoginView
    // has been deallocated. Note the handlers are declared as a `copy` property so that
    // the block lives on the heap.
    __block FBLoginView *weakSelf = self;
    self.sessionStateHandler = ^(FBSession *session, FBSessionState status, NSError *error) {
        if (session == nil) {
            // The nil sentinel value for session indicates both blocks should no-op thereafter.
            weakSelf = nil;
        } else if (error) {
            [weakSelf informDelegateOfError:error];
        }
    };
    self.requestHandler = ^(FBRequestConnection *connection, NSMutableDictionary<FBGraphUser> *result, NSError *error) {
        if (result) {
            weakSelf.user = result;
            [weakSelf informDelegate:YES];
        } else {
            weakSelf.user = nil;
            if (weakSelf.session.isOpen) {
                // Only inform the delegate of errors if the session remains open;
                // since session closure errors will surface through the openActiveSession
                // block.
                [weakSelf informDelegateOfError:error];
            }
        }
        weakSelf.request = nil;
    };
}
- (void)initialize {
    // the base class can cause virtual recursion, so
    // to handle this we make initialize idempotent
    if (self.button) {
        return;
    }
    
    // setup view
    self.autoresizesSubviews = YES;
    self.clipsToBounds = YES;
    
    [self initializeBlocks];
    
    if ([FBSession activeSessionIfOpen] == nil) {
        // if our session has a cached token ready, we open it; note that it is important
        // that we open the session before notification wiring is in place
        [FBSession openActiveSessionWithReadPermissions:nil
                                           allowLoginUI:NO
                                      completionHandler:self.sessionStateHandler];
    }

    // wire-up the current session to the login view, before adding global session-change handlers
    [self wireViewForSession:FBSession.activeSession];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(handleActiveSessionSetNotifications:) 
                                                 name:FBSessionDidSetActiveSessionNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(handleActiveSessionUnsetNotifications:) 
                                                 name:FBSessionDidUnsetActiveSessionNotification
                                               object:nil]; 
    
    // setup button
    self.button = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.button addTarget:self
                    action:@selector(buttonPressed:)
          forControlEvents:UIControlEventTouchUpInside];
    self.button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
    self.button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    UIImage *image = [[UIImage imageNamed:@"FacebookSDKResources.bundle/FBLoginView/images/login-button-small.png"] 
                      stretchableImageWithLeftCapWidth:kButtonLabelX topCapHeight:0];
    g_imageSize = image.size;
    [self.button setBackgroundImage:image forState:UIControlStateNormal];
    
    image = [[UIImage imageNamed:@"FacebookSDKResources.bundle/FBLoginView/images/login-button-small-pressed.png"]
             stretchableImageWithLeftCapWidth:kButtonLabelX topCapHeight:0];
    [self.button setBackgroundImage:image forState:UIControlStateHighlighted];
    
    [self addSubview:self.button];
    
    // add a label that will appear over the button
    self.label = [[[UILabel alloc] init] autorelease];
    self.label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.label.textAlignment = UITextAlignmentCenter;
    self.label.backgroundColor = [UIColor clearColor];
    self.label.font = [UIFont boldSystemFontOfSize:16.0];
    self.label.textColor = [UIColor whiteColor];
    self.label.shadowColor = [UIColor blackColor];
    self.label.shadowOffset = CGSizeMake(0.0, -1.0);
    [self addSubview:self.label];
    
    // We force our height to be the same as the image, but we will let someone make us wider
    // than the default image.
    CGFloat width = MAX(self.frame.size.width, g_imageSize.width);
    CGRect frame = CGRectMake(self.frame.origin.x, self.frame.origin.y,
                              width, image.size.height);
    self.frame = frame;
    
    CGRect buttonFrame = CGRectMake(0, 0, width, image.size.height);
    self.button.frame = buttonFrame;
    
    self.label.frame = CGRectMake(kButtonLabelX, 0, width - kButtonLabelX, image.size.height);    
    
    self.backgroundColor = [UIColor clearColor];
    
    if (self.session.isOpen) {
        [self fetchMeInfo];
        [self configureViewForStateLoggedIn:YES];
    } else {
        [self configureViewForStateLoggedIn:NO];
    }
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize logInSize = [[self logInText] sizeWithFont:self.label.font];
    CGSize logOutSize = [[self logOutText] sizeWithFont:self.label.font];
    
    // Leave at least a small margin around the label.
    CGFloat desiredWidth = kButtonLabelX + 20 + MAX(logInSize.width, logOutSize.width);
    // Never get smaller than the image
    CGFloat width = MAX(desiredWidth, g_imageSize.width);
    
    return CGSizeMake(width, g_imageSize.height);
}

- (NSString *)logInText {
    return [FBUtility localizedStringForKey:@"FBLV:LogInButton" withDefault:@"Log In"];
}

- (NSString *)logOutText {
    return [FBUtility localizedStringForKey:@"FBLV:LogOutButton" withDefault:@"Log Out"];
}

- (void)configureViewForStateLoggedIn:(BOOL)isLoggedIn {
    if (isLoggedIn) {
        self.label.text = [self logOutText];
    } else {
        self.label.text = [self logInText];
        self.user = nil;
    }
}

- (void)fetchMeInfo {
    FBRequest *request = [FBRequest requestForMe];
    [request setSession:self.session];
    self.request = [[[FBRequestConnection alloc] init] autorelease];
    [self.request addRequest:request
           completionHandler:self.requestHandler];
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
        if (![self.lastObservedStateWasOpen isEqualToNumber:@1]) {
            self.lastObservedStateWasOpen = @1;
            
            if ([self.delegate respondsToSelector:@selector(loginViewShowingLoggedInUser:)]) {
                [self.delegate loginViewShowingLoggedInUser:self];
            }
            // any time we inform/reinform of isOpen event, we want to be sure 
            // to repass the user if we have it
            if (self.user) {
                [self informDelegate:YES];
            }
        }
    } else {
        if (![self.lastObservedStateWasOpen isEqualToNumber:@0]) {
            self.lastObservedStateWasOpen = @0;
            
            if ([self.delegate respondsToSelector:@selector(loginViewShowingLoggedOutUser:)]) {
                [self.delegate loginViewShowingLoggedOutUser:self];
            }
        }
    }
}

- (void)informDelegateOfError:(NSError *)error {
    if (error) {
        if ([self.delegate respondsToSelector:@selector(loginView:handleError:)]) {
            [self.delegate loginView:self
                         handleError:error];
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
        [self.session openWithBehavior:FBSessionLoginBehaviorUseSystemAccountIfPresent
                     completionHandler:self.sessionStateHandler];
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

#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
- (void)buttonPressed:(id)sender {
    if (self.session == FBSession.activeSession) {
        if (!self.session.isOpen) { // login
            
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
        } else { // logout action sheet
            NSString *name = self.user.name;
            NSString *title = nil;
            if (name) {
                title = [NSString stringWithFormat:[FBUtility localizedStringForKey:@"FBLV:LoggedInAs"
                                                                        withDefault:@"Logged in as %@"], name];
            } else {
                title = [FBUtility localizedStringForKey:@"FBLV:LoggedInUsingFacebook"
                                            withDefault:@"Logged in using Facebook"];
            }
            
            NSString *cancelTitle = [FBUtility localizedStringForKey:@"FBLV:CancelAction"
                                                         withDefault:@"Cancel"];
            NSString *logOutTitle = [FBUtility localizedStringForKey:@"FBLV:LogOutAction"
                                                         withDefault:@"Log Out"];
            UIActionSheet *sheet = [[[UIActionSheet alloc] initWithTitle:title
                                                                delegate:self
                                                       cancelButtonTitle:cancelTitle
                                                  destructiveButtonTitle:logOutTitle
                                                       otherButtonTitles:nil]
                                    autorelease];
            // Show the sheet
            [sheet showInView:self];
        }
    } else { // state of view out of sync with active session
        // so resync
        [self unwireViewForSession];
        [self wireViewForSession:FBSession.activeSession];
        [self configureViewForStateLoggedIn:self.session.isOpen];
        [self informDelegate:NO];
    }
}
#pragma GCC diagnostic warning "-Wdeprecated-declarations"
@end
