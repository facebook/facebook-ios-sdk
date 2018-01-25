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

#import "RPSGameViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import <FBSDKLoginKit/FBSDKLoginKit.h>

#import <FBSDKShareKit/FBSDKShareKit.h>

#import "RPSAppDelegate.h"
#import "RPSCommonObjects.h"
#import "RPSFriendsViewController.h"

static NSString *callType[] = {
    @"unknown",
    @"rock",
    @"paper",
    @"scissors"
};

// Some constants for creating Open Graph objects.
static NSString *kResults[] = {
    @"won",
    @"lost",
    @"tied"
};

// We upload photos for games, but we'd like to reuse the same objects during a session.
static NSString *photoURLs[] = {
    nil,
    nil,
    nil
};

typedef void (^RPSBlock)(void);

@interface RPSGameViewController () <UIActionSheetDelegate, UIAlertViewDelegate, FBSDKSharingDelegate>
@end

@implementation RPSGameViewController {
    BOOL _needsInitialAnimation;
    BOOL _interestedInImplicitShare;
    RPSCall _lastPlayerCall, _lastComputerCall;
    UIImage *_rightImages[3];
    UIImage *_leftImages[3];
    UIImage *_imagesToPublish[3];
    RPSBlock _alertOkHandler;
    int _wins, _losses, _ties;
    NSDate *_lastAnimationStartTime;
    NSMutableSet *_activeConnections;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"You Rock!", @"You Rock!");
        self.tabBarItem.image = [UIImage imageNamed:@"first"];

        BOOL ipad = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);

        NSString *rockRight     = ipad ? @"right-rock-128.png"     : @"right-rock-88.png";
        NSString *paperRight    = ipad ? @"right-paper-128.png"    : @"right-paper-88.png";
        NSString *scissorsRight = ipad ? @"right-scissors-128.png" : @"right-scissors-88.png";

        NSString *rockLeft     = ipad ? @"left-rock-128.png"     : @"left-rock-88.png";
        NSString *paperLeft    = ipad ? @"left-paper-128.png"    : @"left-paper-88.png";
        NSString *scissorsLeft = ipad ? @"left-scissors-128.png" : @"left-scissors-88.png";

        _rightImages[RPSCallRock] = [UIImage imageNamed:rockRight];
        _rightImages[RPSCallPaper] = [UIImage imageNamed:paperRight];
        _rightImages[RPSCallScissors] = [UIImage imageNamed:scissorsRight];

        _leftImages[RPSCallRock] = [UIImage imageNamed:rockLeft];
        _leftImages[RPSCallPaper] = [UIImage imageNamed:paperLeft];
        _leftImages[RPSCallScissors] = [UIImage imageNamed:scissorsLeft];

        _imagesToPublish[RPSCallRock] = [UIImage imageNamed:@"left-rock-128.png"];
        _imagesToPublish[RPSCallPaper] = [UIImage imageNamed:@"left-paper-128.png"];
        _imagesToPublish[RPSCallScissors] = [UIImage imageNamed:@"left-scissors-128.png"];

        _lastPlayerCall = _lastComputerCall = RPSCallNone;
        _wins = _losses = _ties = 0;
        _alertOkHandler = nil;
        _needsInitialAnimation = YES;
        _interestedInImplicitShare = YES;

        _activeConnections = [[NSMutableSet alloc] init];

    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    UIColor *fontColor = self.rockLabel.textColor;
    [self.rockButton.layer setCornerRadius:8.0];
    [self.rockButton.layer setBorderWidth:4.0];
    [self.rockButton.layer setBorderColor:fontColor.CGColor];
    self.rockButton.clipsToBounds = YES;
    self.rockButton.tag = RPSCallRock;

    [self.paperButton.layer setCornerRadius:8.0];
    [self.paperButton.layer setBorderWidth:4.0];
    [self.paperButton.layer setBorderColor:fontColor.CGColor];
    self.paperButton.clipsToBounds = YES;
    self.paperButton.tag = RPSCallPaper;

    [self.scissorsButton.layer setCornerRadius:8.0];
    [self.scissorsButton.layer setBorderWidth:4.0];
    [self.scissorsButton.layer setBorderColor:fontColor.CGColor];
    self.scissorsButton.clipsToBounds = YES;
    self.scissorsButton.tag = RPSCallScissors;

    [self.againButton.layer setCornerRadius:8.0];
    [self.againButton.layer setBorderWidth:4.0];
    [self.againButton.layer setBorderColor:fontColor.CGColor];

    [self.computerHand.layer setCornerRadius:8.0];
    self.computerHand.layer.shadowColor = [UIColor blackColor].CGColor;
    self.computerHand.layer.shadowOpacity = 0.5;
    self.computerHand.layer.shadowRadius = 8;
    self.computerHand.layer.shadowOffset = CGSizeMake(12.0f, 12.0f);
    self.computerHand.clipsToBounds = YES;

    [self.playerHand.layer setCornerRadius:8.0];
    self.playerHand.layer.shadowColor = [UIColor blackColor].CGColor;
    self.playerHand.layer.shadowOpacity = 0.5;
    self.playerHand.layer.shadowRadius = 8;
    self.playerHand.layer.shadowOffset = CGSizeMake(12.0f, 12.0f);
    self.playerHand.clipsToBounds = YES;

    [self.facebookButton.layer setCornerRadius:8.0];
    [self.facebookButton.layer setBorderWidth:4.0];
    [self.facebookButton.layer setBorderColor:fontColor.CGColor];
    self.facebookButton.clipsToBounds = YES;

    [self updateScoreLabel];
    [self resetField];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (_needsInitialAnimation) {
        // get things rolling
        _needsInitialAnimation = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, .5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self animateField];
        });
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = NO;
}

- (void)viewDidUnload {
    [self setRockLabel:nil];
    [self setPaperLabel:nil];
    [self setScissorsLabel:nil];
    [self setRockButton:nil];
    [self setRockButton:nil];
    [self setPaperButton:nil];
    [self setScissorsButton:nil];
    [self setShootLabel:nil];
    [self setComputerHand:nil];
    [self setAgainButton:nil];
    [self setPlayerHand:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void)resetField {
    self.rockButton.hidden =
    self.paperButton.hidden =
    self.scissorsButton.hidden =
    self.rockLabel.hidden =
    self.paperLabel.hidden =
    self.scissorsLabel.hidden =
    self.shootLabel.hidden =
    self.computerHand.hidden =
    self.playerHand.hidden =
    self.againButton.hidden = YES;

    self.rockButton.enabled =
    self.paperButton.enabled =
    self.scissorsButton.enabled = NO;

    self.resultLabel.text = @"";
}

- (void)setFieldForPlayAgain {
    self.shootLabel.hidden =
    self.rockButton.hidden =
    self.paperButton.hidden =
    self.scissorsButton.hidden = YES;

    self.playerHand.hidden =
    self.againButton.hidden = NO;
}

- (void)animateField {
    // rock
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, .5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        self.rockLabel.hidden = NO;
        self.rockButton.hidden = NO;

        // paper
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            self.paperLabel.hidden = NO;
            self.paperButton.hidden = NO;

            // scissors
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                self.scissorsLabel.hidden = NO;
                self.scissorsButton.hidden = NO;

                // shoot!
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    self.shootLabel.hidden =
                    self.computerHand.hidden = NO;
                    self.rockButton.enabled =
                    self.paperButton.enabled =
                    self.scissorsButton.enabled = YES;

                    self.computerHand.animationImages = @[ _rightImages[RPSCallRock], _rightImages[RPSCallPaper], _rightImages[RPSCallScissors]];
                    self.computerHand.animationDuration = .4;
                    self.computerHand.animationRepeatCount = 0;
                    [self.computerHand startAnimating];
                    _lastAnimationStartTime = [NSDate date];
                });
            });
        });
    });
}

- (RPSCall)callViaRandom {
    return (RPSCall)(arc4random() % 3);
}

- (RPSResult)resultForPlayerCall:(RPSCall)playerCall
                    computerCall:(RPSCall)computerCall {
    static RPSResult results[3][3] = {
        {RPSResultTie, RPSResultLoss, RPSResultWin},
        {RPSResultWin, RPSResultTie, RPSResultLoss},
        {RPSResultLoss, RPSResultWin, RPSResultTie}
    };
    return results[playerCall][computerCall];
}

- (void)callGame:(RPSCall)playerCall {
    NSTimeInterval timeTaken = fabs([_lastAnimationStartTime timeIntervalSinceNow]);
    [self logTimeTaken:timeTaken];
    [self logCurrentPlayerCall:playerCall lastPlayerCall:_lastPlayerCall lastComputerCall:_lastComputerCall];

    // stop animating and identify each opponent's call
    [self.computerHand stopAnimating];
    _lastPlayerCall = playerCall;
    _lastComputerCall = [self callViaRandom];
    self.computerHand.image = _rightImages[_lastComputerCall];

    // update UI and counts based on result
    RPSResult result = [self resultForPlayerCall:_lastPlayerCall
                                    computerCall:_lastComputerCall];

    switch (result) {
        case RPSResultWin:
            _wins++;
            self.resultLabel.text = @"Win!";
            [self logPlayerCall:playerCall result:RPSResultWin timeTaken:timeTaken];
            break;
        case RPSResultLoss:
            _losses++;
            self.resultLabel.text = @"Loss.";
            [self logPlayerCall:playerCall result:RPSResultLoss timeTaken:timeTaken];
            break;
        case RPSResultTie:
            _ties++;
            self.resultLabel.text = @"Tie...";
            [self logPlayerCall:playerCall result:RPSResultTie timeTaken:timeTaken];
            break;
    }
    [self updateScoreLabel];

    if (_interestedInImplicitShare) {
        [self publishResult];
    }

}

- (void)updateScoreLabel {
    self.scoreLabel.text = [NSString stringWithFormat:@"W = %d   L = %d   T = %d", _wins, _losses, _ties];
}

- (IBAction)clickRPSButton:(id)sender {
    UIButton *button = sender;
    RPSCall choice = (RPSCall)button.tag;
    self.playerHand.image = _leftImages[choice];
    [self callGame:choice];
    [self setFieldForPlayAgain];
}

- (IBAction)clickAgainButton:(id)sender {
    [self resetField];
    [self animateField];
}

- (IBAction)clickFacebookButton:(id)sender {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"Share on Facebook",
                            @"Share on Messenger",
                            @"Friends' Activity",
                            [FBSDKAccessToken currentAccessToken] ? @"Log out" : @"Log in",
                            nil];
    // Show the sheet
    [sheet showInView:sender];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != 0) { // ok
        if (_alertOkHandler) {
            _alertOkHandler();
            _alertOkHandler = nil;
        }
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0: { // Share on Facebook
            FBSDKShareDialog *shareDialog = [[FBSDKShareDialog alloc] init];
            shareDialog.fromViewController = self;
            if (![self shareWith:shareDialog content:[self getGameShareContent:NO]]) {
                [self displayInstallAppWithAppName:@"Facebook"];
            }
            break;
        }
        case 1: { // Share on Messenger
            if (![self shareWith:[[FBSDKMessageDialog alloc] init] content:[self getGameShareContent:YES]]) {
                [self displayInstallAppWithAppName:@"Messenger"];
            }
            break;
        }
        case 2: { // See Friends
            UIViewController *friends;
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
                friends = [[RPSFriendsViewController alloc] initWithNibName:@"RPSFriendsViewController_iPhone" bundle:nil];
            } else {
                friends = [[RPSFriendsViewController alloc] initWithNibName:@"RPSFriendsViewController_iPad" bundle:nil];
            }
            [self.navigationController pushViewController:friends
                                                 animated:YES];
            break;
        }
        case 3: { // Login and logout
            if ([FBSDKAccessToken currentAccessToken]) {
                FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
                [login logOut];
            } else {
                // Try to login with permissions
                [self loginAndRequestPermissionsWithSuccessHandler:nil
                                         declinedOrCanceledHandler:^{
                                             // If the user declined permissions tell them why we need permissions
                                             // and ask for permissions again if they want to grant permissions.
                                             [self alertDeclinedPublishActionsWithCompletion:^{
                                                 [self loginAndRequestPermissionsWithSuccessHandler:nil
                                                                          declinedOrCanceledHandler:nil
                                                                                       errorHandler:^(NSError * error) {
                                                                                           NSLog(@"Error: %@", error.description);
                                                                                       }];
                                             }];
                                         }
                                                      errorHandler:^(NSError * error) {
                                                          NSLog(@"Error: %@", error.description);
                                                      }];
            }
        }
    }
}

- (BOOL)hasPlayedAtLeastOnce {
    return _lastPlayerCall != RPSCallNone && _lastComputerCall != RPSCallNone;
}

- (id<FBSDKSharingContent>) getGameShareContent:(BOOL)isShareForMessenger {
    return (self.hasPlayedAtLeastOnce && !isShareForMessenger) ? [self getGameActivityShareContent] : [self getGameLinkShareContent];
}

- (FBSDKShareOpenGraphContent *) getGameActivityShareContent {
    // set action's gesture property
    FBSDKShareOpenGraphAction *action = [FBSDKShareOpenGraphAction actionWithType:@"fb_sample_rps:throw"
                                                                         objectID:builtInOpenGraphObjects[_lastPlayerCall]
                                                                              key:@"fb_sample_rps:gesture"];
    // set action's opposing_gesture property
    [action setString:builtInOpenGraphObjects[_lastComputerCall] forKey:@"fb_sample_rps:opposing_gesture"];

    FBSDKShareOpenGraphContent *content = [[FBSDKShareOpenGraphContent alloc] init];
    content.action = action;
    content.previewPropertyName = @"fb_sample_rps:gesture";
    return content;
}

- (BOOL)shareWith:(id<FBSDKSharingDialog>)dialog content:(id<FBSDKSharingContent>)content{
    dialog.shareContent = content;
    dialog.delegate = self;
    return [dialog show];
}

- (void) displayInstallAppWithAppName:(NSString *)appName {
    NSString *message = [NSString stringWithFormat:
                         @"Install or upgrade the %@ application on your device and "
                         @"get cool new sharing features for this application. "
                         @"What do you want to do?" , appName];
    [self alertWithMessage:message
                        ok:@"Install or Upgrade Now"
                    cancel:@"Decide Later"
                completion:^{
                    [[UIApplication sharedApplication]
                     openURL:[NSURL URLWithString:[NSString stringWithFormat:@"itms-apps://itunes.com/apps/%@", appName]]];
                }];
}

- (FBSDKShareLinkContent *)getGameLinkShareContent {
    FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
    content.contentURL = [NSURL URLWithString:@"https://developers.facebook.com/"];
    return content;
}

- (FBSDKShareOpenGraphObject *)createGameObject {
    RPSResult result = [self resultForPlayerCall:_lastPlayerCall
                                    computerCall:_lastComputerCall];

    NSString *resultName = kResults[result];

    FBSDKShareOpenGraphObject *object = [[FBSDKShareOpenGraphObject alloc] init];
    [object setString:@"fb_sample_rps:game" forKey:@"og:type"];
    [object setString:@"an awesome game of Rock, Paper, Scissors" forKey:@"og:title"];
    [object setString:builtInOpenGraphObjects[_lastPlayerCall] forKey:@"fb_sample_rps:player_gesture"];
    [object setString:builtInOpenGraphObjects[_lastComputerCall] forKey:@"fb_sample_rps:opponent_gesture"];
    [object setString:resultName forKey:@"fb_sample_rps:result"];
    [object setString:photoURLs[_lastPlayerCall] forKey:@"og:image"];
    return object;
}

- (FBSDKShareOpenGraphAction *)createPlayActionWithGame:(FBSDKShareOpenGraphObject *)game {
    return [FBSDKShareOpenGraphAction actionWithType:@"fb_sample_rps:play" object:game key:@"fb_sample_rps:game"];
}

- (void)loginAndRequestPermissionsWithSuccessHandler:(RPSBlock) successHandler
                           declinedOrCanceledHandler:(RPSBlock) declinedOrCanceledHandler
                                        errorHandler:(void (^)(NSError *)) errorHandler{
    FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
    [login logInWithPublishPermissions:@[@"publish_actions"]
                    fromViewController:self
                               handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
                                   if (error) {
                                       if (errorHandler) {
                                           errorHandler(error);
                                       }
                                       return;
                                   }

                                   if ([FBSDKAccessToken currentAccessToken] &&
                                       [[FBSDKAccessToken currentAccessToken].permissions containsObject:@"publish_actions"]) {
                                       if (successHandler) {
                                           successHandler();
                                       }
                                       return;
                                   }

                                   if (declinedOrCanceledHandler) {
                                       declinedOrCanceledHandler();
                                   }
                               }];
}

- (void)alertDeclinedPublishActionsWithCompletion:(RPSBlock)completion {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Publish Permissions"
                                                        message:@"Publish permissions are needed to share game content automatically. Do you want to enable publish permissions?"
                                                       delegate:self
                                              cancelButtonTitle:@"No"
                                              otherButtonTitles:@"Ok", nil];
    _alertOkHandler = [completion copy];
    [alertView show];
}

- (void)alertWithMessage:(NSString *)message
                      ok:(NSString *)ok
                  cancel:(NSString *)cancel
              completion:(RPSBlock)completion {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Share with Facebook"
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:cancel
                                              otherButtonTitles:ok, nil];
    _alertOkHandler = [completion copy];
    [alertView show];
}

- (void)publishPhotoForGesture:(RPSCall)gesture {
    FBSDKGraphRequestConnection *conn = [[FBSDKGraphRequestConnection alloc] init];
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me/staging_resources"
                                                                   parameters:@{@"file":_imagesToPublish[gesture]}
                                                                  tokenString:[FBSDKAccessToken currentAccessToken].tokenString
                                                                      version:nil
                                                                   HTTPMethod:@"POST"];
    [conn addRequest:request completionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        if (error) {
            NSLog(@"%@", error);
        } else {
            photoURLs[gesture] = result[@"uri"];
            [self publishResult];
        }
    }];
    [conn start];
}

- (void)publishResult {
    // Check if we have publish permissions and ask for them if we don't
    if (![FBSDKAccessToken currentAccessToken] ||
        ![[FBSDKAccessToken currentAccessToken].permissions containsObject:@"publish_actions"])
    {
        NSLog(@"Re-requesting permissions");
        _interestedInImplicitShare = NO;
        [self alertWithMessage:@"Share game activity with your friends?"
                            ok:@"Yes"
                        cancel:@"Maybe Later"
                    completion:^{
                        _interestedInImplicitShare = YES;
                        [self loginAndRequestPermissionsWithSuccessHandler:^{
                            [self publishResult];
                        }
                                                 declinedOrCanceledHandler:nil
                                                              errorHandler:^(NSError * error) {
                                                                  NSLog(@"Error: %@", error.description);
                                                              }];
                    }];
        return;
    }

    // We want to upload a photo representing the gesture the player threw, and use it as the
    // image for our game OG object. But we optimize this and only upload one instance per session.
    // So if we already have the image URL, we use it, otherwise we'll initiate an upload and
    // publish the result once it finishes.
    if (!photoURLs[_lastPlayerCall]) {
        [self publishPhotoForGesture:_lastPlayerCall];
        return;
    }

    FBSDKShareOpenGraphObject *game = [self createGameObject];
    FBSDKShareOpenGraphAction *action = [self createPlayActionWithGame:game];
    FBSDKShareOpenGraphContent *content = [[FBSDKShareOpenGraphContent alloc] init];
    content.action = action;
    content.previewPropertyName = @"fb_sample_rps:game";
    [FBSDKShareAPI shareWithContent:content delegate:self];
}

#pragma mark - FBSDKSharingDelegate

- (void)sharer:(id<FBSDKSharing>)sharer didCompleteWithResults:(NSDictionary *)results {
    NSLog(@"Posted OG action with id: %@", results[@"postId"]);
}

- (void)sharer:(id<FBSDKSharing>)sharer didFailWithError:(NSError *)error {
    NSLog(@"Error: %@", error.description);
}

- (void)sharerDidCancel:(id<FBSDKSharing>)sharer {
    NSLog(@"Canceled share");
}

#pragma mark - Logging App Event

- (void)logCurrentPlayerCall:(RPSCall)playerCall
              lastPlayerCall:(RPSCall)lastPlayerCall
            lastComputerCall:(RPSCall)lastComputerCall {
    // log the user's choice while comparing it against the result of their last throw
    if (lastComputerCall != RPSCallNone && lastComputerCall != RPSCallNone) {
        RPSResult lastResult = [self resultForPlayerCall:lastPlayerCall
                                            computerCall:lastComputerCall];

        NSString *transitionalWord = (lastResult == RPSResultWin? @"against" :
                                      lastResult == RPSResultTie? @"with" : @"to");
        NSString *previousResult = [NSString stringWithFormat:@"%@ %@ %@",
                                    kResults[lastResult],
                                    transitionalWord,
                                    callType[lastPlayerCall + 1]];
        [FBSDKAppEvents logEvent:@"Throw Based on Last Result"
                      parameters:@{callType[playerCall + 1] : previousResult}];
    }
}

- (void)logPlayerCall:(RPSCall)playerCall result:(RPSResult)result timeTaken:(NSTimeInterval)timeTaken {
    // log the user's choice and the respective result
    NSString *playerChoice = callType[playerCall + 1];
    [FBSDKAppEvents logEvent:@"Round End"
                  valueToSum:timeTaken
                  parameters:@{@"roundResult": kResults[result], @"playerChoice" : playerChoice}];
}

- (void)logTimeTaken:(NSTimeInterval)timeTaken {
    // logs the time a user takes to make a choice in a round
    NSString *timeTakenStr = (timeTaken < 0.5f? @"< 0.5s" :
                              timeTaken < 1.0f? @"0.5s <= t < 1.0s" :
                              timeTaken < 1.5f? @"1.0s <= t < 1.5s" :
                              timeTaken < 2.0f? @"1.5s <= t < 2.0s" :
                              timeTaken < 2.5f? @"2.0s <= t < 2.5s" : @" >= 2.5s");
    [FBSDKAppEvents logEvent:@"Time Taken"
                  valueToSum:timeTaken
                  parameters:@{@"Time Taken" : timeTakenStr}];
}
@end
