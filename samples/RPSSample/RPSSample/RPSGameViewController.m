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

#import "RPSGameViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>

#import <FacebookSDK/FacebookSDK.h>

#import "OGProtocols.h"
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

@interface RPSGameViewController () <UIActionSheetDelegate, UIAlertViewDelegate>
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
    }
    return self;
}

- (void)viewDidLoad {
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

    if (FBSession.activeSession.isOpen && _interestedInImplicitShare) {
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
                                              otherButtonTitles:@"Share on Facebook", @"See Friends", @"Check Settings",  nil];
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

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0: { // Share on Facebook
            BOOL didDialog = NO;
            if (self.hasPlayedAtLeastOnce) {
                didDialog = [self shareGameActivity];
            } else {
                didDialog = [self shareGameLink];
            }
            if (!didDialog) {
                [self alertWithMessage:
                 @"Upgrade the Facebook application on your device and "
                 @"get cool new sharing features for this application. "
                 @"What do you want to do?"
                                    ok:@"Upgrade Now"
                                cancel:@"Decide Later"
                            completion:^{
                                // launch itunes to get the Facebook application installed/upgraded
                                [[UIApplication sharedApplication]
                                 openURL:[NSURL URLWithString:@"itms-apps://itunes.com/apps/Facebook"]];
                            }];
            }
            break;
        }
        case 1: { // See Friends
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
        case 2: // Check Settings
            [self.navigationController pushViewController:[[FBUserSettingsViewController alloc] init]
                                                 animated:YES];
            break;
    }
}

- (BOOL)hasPlayedAtLeastOnce {
    return _lastPlayerCall != RPSCallNone && _lastComputerCall != RPSCallNone;
}

- (BOOL)shareGameActivity {
    id<FBOpenGraphAction> action = (id<FBOpenGraphAction>)[FBGraphObject openGraphActionForPost];
    action[@"gesture"] = builtInOpenGraphObjects[_lastPlayerCall]; // set action's gesture property
    action[@"opposing_gesture"] = builtInOpenGraphObjects[_lastComputerCall]; // set action's opposing_gesture property

    FBOpenGraphActionShareDialogParams *params = [[FBOpenGraphActionShareDialogParams alloc] init];
    params.action = action;
    params.actionType = @"fb_sample_rps:throw";
    params.previewPropertyName = @"gesture";

    return ([FBDialogs presentShareDialogWithOpenGraphActionParams:params
                                                       clientState:nil
                                                           handler:NULL] != nil);
}

- (BOOL)shareGameLink {
    FBShareDialogParams *params = [[FBShareDialogParams alloc] init];
    params.link = [NSURL URLWithString:@"https://developers.facebook.com/"];
    params.name = @"Rock, Papers, Scissors Sample Application";

    return ([FBDialogs presentShareDialogWithParams:params
                                        clientState:nil
                                            handler:NULL] != nil);
}

- (NSMutableDictionary<FBOpenGraphObject> *)createGameObject {
    RPSResult result = [self resultForPlayerCall:_lastPlayerCall
                                    computerCall:_lastComputerCall];

    NSString *resultName = kResults[result];

    NSMutableDictionary<FBOpenGraphObject> *game = [FBGraphObject openGraphObjectForPost];
    game[@"type"] = @"fb_sample_rps:game";
    game[@"title"] = @"an awesome game of Rock, Paper, Scissors";
    game[@"data"][@"player_gesture"] = builtInOpenGraphObjects[_lastPlayerCall];
    game[@"data"][@"opponent_gesture"] = builtInOpenGraphObjects[_lastComputerCall];
    game[@"data"][@"result"] = resultName;

    return game;
}

- (NSMutableDictionary<FBOpenGraphAction> *)createPlayActionWithGame:(id)game {
    NSMutableDictionary<FBOpenGraphAction> *action = [FBGraphObject openGraphActionForPost];
    action[@"game"] = game;
    return action;
}

- (void)requestPermissionsWithCompletion:(RPSBlock)completion {
    [FBSession.activeSession requestNewPublishPermissions:[NSArray arrayWithObject:@"publish_actions"]
                                          defaultAudience:FBSessionDefaultAudienceEveryone
                                        completionHandler:^(FBSession *session, NSError *error) {
                                            if (!error) {
                                                // Now have the permission
                                                completion();
                                            } else {
                                                NSLog(@"Error: %@", error.description);
                                            }
                                        }];
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
    [FBRequestConnection startForUploadStagingResourceWithImage:_imagesToPublish[gesture]
                                              completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                                  if (error) {
                                                      NSLog(@"%@", error);
                                                      if (error.fberrorCategory == FBErrorCategoryPermissions) {
                                                          NSLog(@"Re-requesting permissions");
                                                          _interestedInImplicitShare = NO;
                                                          [self alertWithMessage:@"Share game activity with your friends?"
                                                                              ok:@"Yes"
                                                                          cancel:@"Maybe Later"
                                                                      completion:^{
                                                                          _interestedInImplicitShare = YES;
                                                                          [self requestPermissionsWithCompletion:^{
                                                                              [self publishPhotoForGesture:gesture];
                                                                          }];
                                                                      }];
                                                          return;
                                                      }
                                                  } else {
                                                      photoURLs[gesture] = result[@"uri"];
                                                      [self publishResult];
                                                  }
                                              }];
}

- (void)publishResult {
    // We want to upload a photo representing the gesture the player threw, and use it as the
    // image for our game OG object. But we optimize this and only upload one instance per session.
    // So if we already have the image URL, we use it, otherwise we'll initiate an upload and
    // publish the result once it finishes.
    if (!photoURLs[_lastPlayerCall]) {
        [self publishPhotoForGesture:_lastPlayerCall];
        return;
    }

    FBRequestConnection *connection = [[FBRequestConnection alloc] init];

    NSMutableDictionary<FBOpenGraphObject> *game = [self createGameObject];
    game[@"image"] = photoURLs[_lastPlayerCall];
    FBRequest *objectRequest = [FBRequest requestForPostOpenGraphObject:game];
    [connection addRequest:objectRequest
         completionHandler:^(FBRequestConnection *innerConnection, id result, NSError *error) {
             if (error) {
                 NSLog(@"Error: %@", error.description);
             }
         }
            batchEntryName:@"objectCreate"];


    NSMutableDictionary<FBGraphObject> *action = [self createPlayActionWithGame:@"{result=objectCreate:$.id}"];
    FBRequest *actionRequest = [FBRequest requestForPostWithGraphPath:@"me/fb_sample_rps:play"
                                                          graphObject:action];
    [connection addRequest:actionRequest
         completionHandler:^(FBRequestConnection *innerConnection, id result, NSError *error) {
             if (error) {
                 NSLog(@"Error: %@", error.description);
             } else {
                 NSLog(@"Posted OG action with id: %@", result[@"id"]);
             }
         }];

    [connection start];
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
        [FBAppEvents logEvent:@"Throw Based on Last Result"
                   parameters:@{callType[playerCall + 1] : previousResult}];
    }
}

- (void)logPlayerCall:(RPSCall)playerCall result:(RPSResult)result timeTaken:(NSTimeInterval)timeTaken {
    // log the user's choice and the respective result
    NSString *playerChoice = [NSString stringWithFormat:@"Throw %@", callType[playerCall + 1]];
    [FBAppEvents logEvent:playerChoice
               valueToSum:timeTaken
               parameters:@{@"Result": kResults[result]}];
}

- (void)logTimeTaken:(NSTimeInterval)timeTaken {
    // logs the time a user takes to make a choice in a round
    NSString *timeTakenStr = (timeTaken < 0.5f? @"< 0.5s" :
                              timeTaken < 1.0f? @"0.5s <= t < 1.0s" :
                              timeTaken < 1.5f? @"1.0s <= t < 1.5s" :
                              timeTaken < 2.0f? @"1.5s <= t < 2.0s" :
                              timeTaken < 2.5f? @"2.0s <= t < 2.5s" : @" >= 2.5s");
    [FBAppEvents logEvent:@"Time Taken"
               valueToSum:timeTaken
               parameters:@{@"Time Taken" : timeTakenStr}];
}

@end

