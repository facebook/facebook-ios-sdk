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

#import "FBLoginView.h"

#import "FBAppEvents+Internal.h"
#import "FBGraphUser.h"
#import "FBLoginTooltipView.h"
#import "FBLoginViewButtonPNG.h"
#import "FBLoginViewButtonPressedPNG.h"
#import "FBProfilePictureView.h"
#import "FBRequest.h"
#import "FBRequestConnection+Internal.h"
#import "FBSession+Internal.h"
#import "FBSession.h"
#import "FBUtility.h"

static NSString *const FBLoginViewCacheIdentity = @"FBLoginView";
// The design calls for 16 pixels of space on the right edge of the button
static const float kButtonEndCapWidth = 16.0;
// The button has a 12 pixel buffer to the right of the f logo
static const float kButtonPaddingWidth = 12.0;

static CGSize g_buttonSize;

// Forward declare our label wrapper that provides shadow blur
@interface FBShadowLabel : UILabel

@end

@interface FBLoginView () <UIActionSheetDelegate>

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
@property (assign, nonatomic) BOOL hasShownTooltipBubble;

@end

@implementation FBLoginView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithPermissions:(NSArray *)permissions {
    self = [super init];
    if (self) {
        self.permissions = permissions;
        [self initialize];
    }
    return self;
}

- (instancetype)initWithReadPermissions:(NSArray *)readPermissions {
    self = [super init];
    if (self) {
        self.readPermissions = readPermissions;
        [self initialize];
    }
    return self;
}

- (instancetype)initWithPublishPermissions:(NSArray *)publishPermissions
                           defaultAudience:(FBSessionDefaultAudience)defaultAudience {
    self = [super init];
    if (self) {
        self.publishPermissions = publishPermissions;
        self.defaultAudience = defaultAudience;
        [self initialize];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)aRect {
    self = [super initWithFrame:aRect];
    if (self) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
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
    [self wireViewForSession:FBSession.activeSession userInfo:nil];

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

    // We want to make sure that when we stretch the image, it includes the curved edges and drop shadow
    // We inset enough pixels to make sure that happens
    UIEdgeInsets imageInsets = UIEdgeInsetsMake(4.0, 40.0, 4.0, 4.0);

    UIImage *image = [[FBLoginViewButtonPNG image] resizableImageWithCapInsets:imageInsets];
    [self.button setBackgroundImage:image forState:UIControlStateNormal];

    image = [[FBLoginViewButtonPressedPNG image] resizableImageWithCapInsets:imageInsets];
    [self.button setBackgroundImage:image forState:UIControlStateHighlighted];

    [self addSubview:self.button];

    // Compute the text size to figure out the overall size of the button
    UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14.0];
    float textSizeWidth = MAX([[self logInText] sizeWithFont:font].width, [[self logOutText] sizeWithFont:font].width);

    // We make the button big enough to hold the image, the text, the padding to the right of the f and the end cap
    g_buttonSize = CGSizeMake(image.size.width + textSizeWidth + kButtonPaddingWidth + kButtonEndCapWidth, image.size.height);

    // add a label that will appear over the button
    self.label = [[[FBShadowLabel alloc] init] autorelease];
    self.label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
#ifdef __IPHONE_6_0
    self.label.textAlignment = NSTextAlignmentCenter;
#else
    self.label.textAlignment = UITextAlignmentCenter;
#endif
    self.label.backgroundColor = [UIColor clearColor];
    self.label.font = font;
    self.label.textColor = [UIColor whiteColor];
    [self addSubview:self.label];

    // We force our height to be the same as the image, but we will let someone make us wider
    // than the default image.
    CGFloat width = MAX(self.frame.size.width, g_buttonSize.width);
    CGRect frame = CGRectMake(self.frame.origin.x, self.frame.origin.y,
                              width, image.size.height);
    self.frame = frame;

    CGRect buttonFrame = CGRectMake(0, 0, width, image.size.height);
    self.button.frame = buttonFrame;

    // This needs to start at an x just to the right of the f in the image, the -1 on both x and y is to account for shadow in the image
    self.label.frame = CGRectMake(image.size.width - kButtonPaddingWidth - 1, -1, width - (image.size.width - kButtonPaddingWidth) - kButtonEndCapWidth, image.size.height);

    self.backgroundColor = [UIColor clearColor];

    if (self.session.isOpen) {
        [self fetchMeInfo];
        [self configureViewForStateLoggedIn:YES];
    } else {
        [self configureViewForStateLoggedIn:NO];
    }

    self.loginBehavior = FBSessionLoginBehaviorWithFallbackToWebView;
}
#pragma GCC diagnostic warning "-Wdeprecated-declarations"

- (CGSize)intrinsicContentSize {
    return self.bounds.size;
}

- (CGSize)sizeThatFits:(CGSize)size {
    return CGSizeMake(g_buttonSize.width, g_buttonSize.height);
}

- (NSString *)logInText {
    return [FBUtility localizedStringForKey:@"FBLV:LogInButton" withDefault:@"Log in with Facebook"];
}

- (NSString *)logOutText {
    return [FBUtility localizedStringForKey:@"FBLV:LogOutButton" withDefault:@"Log out"];
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

- (void)showTooltipIfNeeded {
    if (self.session.isOpen || self.tooltipBehavior == FBLoginViewTooltipBehaviorDisable){
        return;
    } else {
        FBLoginTooltipView *tooltipView = [[[FBLoginTooltipView alloc] init] autorelease];
        tooltipView.colorStyle = self.tooltipColorStyle;
        if (self.tooltipBehavior == FBLoginViewTooltipBehaviorForceDisplay) {
            tooltipView.forceDisplay = YES;
        }
        [tooltipView presentFromView:self];
    }
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];

    if (self.window &&
        (self.tooltipBehavior == FBLoginViewTooltipBehaviorForceDisplay || !self.hasShownTooltipBubble)) {
        [self performSelector:@selector(showTooltipIfNeeded) withObject:nil afterDelay:0];
        self.hasShownTooltipBubble = YES;
    }
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

- (void)wireViewForSession:(FBSession *)session userInfo:(NSDictionary *)userInfo {
    [self wireViewForSessionWithoutOpening:session];

    // anytime we find that our session is created with an available token
    // we open it on the spot
    if (self.session.state == FBSessionStateCreatedTokenLoaded && (![userInfo[FBSessionDidSetActiveSessionNotificationUserInfoIsOpening] isEqual:@YES])) {
        [self.session openWithBehavior:self.loginBehavior
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
        [self wireViewForSession:notification.object userInfo:notification.userInfo];
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
        BOOL loggingInLogFlag = NO;
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
                                              loginBehavior:self.loginBehavior
                                                     isRead:NO
                                            defaultAudience:self.defaultAudience
                                          completionHandler:self.sessionStateHandler];
            } else if (![self.publishPermissions count]) {
                [FBSession openActiveSessionWithPermissions:self.readPermissions
                                              loginBehavior:self.loginBehavior
                                                     isRead:YES
                                            defaultAudience:FBSessionDefaultAudienceNone
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
                [FBSession openActiveSessionWithPermissions:permissions
                                              loginBehavior:self.loginBehavior
                                                     isRead:NO
                                            defaultAudience:self.defaultAudience
                                          completionHandler:self.sessionStateHandler];
            }
            loggingInLogFlag = YES;
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
                                                         withDefault:@"Log out"];
            UIActionSheet *sheet = [[[UIActionSheet alloc] initWithTitle:title
                                                                delegate:self
                                                       cancelButtonTitle:cancelTitle
                                                  destructiveButtonTitle:logOutTitle
                                                       otherButtonTitles:nil]
                                    autorelease];
            // Show the sheet
            [sheet showInView:self];
        }
        [FBAppEvents logImplicitEvent:FBAppEventNameLoginViewUsage
                           valueToSum:nil
                           parameters:@{ @"logging_in" : [NSNumber numberWithBool:loggingInLogFlag] }
                              session:nil];
    } else { // state of view out of sync with active session
        // so resync
        [self unwireViewForSession];
        [self wireViewForSession:FBSession.activeSession userInfo:nil];
        [self configureViewForStateLoggedIn:self.session.isOpen];
        [self informDelegate:NO];
    }
}
#pragma GCC diagnostic warning "-Wdeprecated-declarations"
@end

@implementation FBShadowLabel

- (void)drawTextInRect:(CGRect)rect {
    CGSize myShadowOffset = CGSizeMake(0, -1);
    CGFloat myColorValues[] = {0, 0, 0, .3};

    CGContextRef myContext = UIGraphicsGetCurrentContext();
    CGContextSaveGState(myContext);

    CGColorSpaceRef myColorSpace = CGColorSpaceCreateDeviceRGB();
    CGColorRef myColor = CGColorCreate(myColorSpace, myColorValues);
    CGContextSetShadowWithColor (myContext, myShadowOffset, 1, myColor);

    [super drawTextInRect:rect];

    CGColorRelease(myColor);
    CGColorSpaceRelease(myColorSpace);

    CGContextRestoreGState(myContext);
}

@end
