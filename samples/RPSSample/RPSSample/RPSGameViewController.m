/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "RPSGameViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>

@import FBSDKCoreKit;
@import FBSDKLoginKit;
@import FBSDKShareKit;

#import "RPSAppDelegate.h"
#import "RPSCommonObjects.h"
#import "RPSFriendsViewController.h"

static NSString *callType[] = {
  @"unknown",
  @"rock",
  @"paper",
  @"scissors"
};

static NSString *kResults[] = {
  @"won",
  @"lost",
  @"tied"
};

typedef void (^RPSBlock)(void);

@interface RPSGameViewController () <UIActionSheetDelegate, UIAlertViewDelegate, FBSDKSharingDelegate>
@end

@implementation RPSGameViewController
{
  BOOL _needsInitialAnimation;
  RPSCall _lastPlayerCall, _lastComputerCall;
  UIImage *_rightImages[3];
  UIImage *_leftImages[3];
  RPSBlock _alertOkHandler;
  int _wins, _losses, _ties;
  NSDate *_lastAnimationStartTime;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.title = NSLocalizedString(@"You Rock!", @"You Rock!");
    self.tabBarItem.image = [UIImage imageNamed:@"first"];

    BOOL ipad = ([UIDevice.currentDevice userInterfaceIdiom] == UIUserInterfaceIdiomPad);

    NSString *rockRight = ipad ? @"right-rock-128.png" : @"right-rock-88.png";
    NSString *paperRight = ipad ? @"right-paper-128.png" : @"right-paper-88.png";
    NSString *scissorsRight = ipad ? @"right-scissors-128.png" : @"right-scissors-88.png";

    NSString *rockLeft = ipad ? @"left-rock-128.png" : @"left-rock-88.png";
    NSString *paperLeft = ipad ? @"left-paper-128.png" : @"left-paper-88.png";
    NSString *scissorsLeft = ipad ? @"left-scissors-128.png" : @"left-scissors-88.png";

    _rightImages[RPSCallRock] = [UIImage imageNamed:rockRight];
    _rightImages[RPSCallPaper] = [UIImage imageNamed:paperRight];
    _rightImages[RPSCallScissors] = [UIImage imageNamed:scissorsRight];

    _leftImages[RPSCallRock] = [UIImage imageNamed:rockLeft];
    _leftImages[RPSCallPaper] = [UIImage imageNamed:paperLeft];
    _leftImages[RPSCallScissors] = [UIImage imageNamed:scissorsLeft];

    _lastPlayerCall = _lastComputerCall = RPSCallNone;
    _wins = _losses = _ties = 0;
    _alertOkHandler = nil;
    _needsInitialAnimation = YES;
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  // Check for a 15 digit FB App ID. If the FB App ID is less than 15 digits, display an alert.

  NSString *strFbAppId = [FBSDKSettings.sharedSettings appID];
  NSString *strEmptyFBId = @"{your-facebook-app-id}";

  if ([strFbAppId isEqualToString:strEmptyFBId]) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Missing the Facebook App ID" message:@"The RPSSample-info.plist is missing the Facebook App ID in the FacebookAppID key.\r\n\nPlease close the app, add your Facebook App ID to FacebookAppID key in RPSSample-info.plist, and then restart the app.\r\n\nFor more information, see ReadMe.txt." preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:^(UIAlertAction *_Nonnull action) {
      [alert dismissViewControllerAnimated:YES completion:nil];
    }];

    [alert addAction:cancel];

    [self presentViewController:alert animated:YES completion:nil];
  } else {
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
    self.computerHand.layer.shadowColor = UIColor.blackColor.CGColor;
    self.computerHand.layer.shadowOpacity = 0.5;
    self.computerHand.layer.shadowRadius = 8;
    self.computerHand.layer.shadowOffset = CGSizeMake(12.0f, 12.0f);
    self.computerHand.clipsToBounds = YES;

    [self.playerHand.layer setCornerRadius:8.0];
    self.playerHand.layer.shadowColor = UIColor.blackColor.CGColor;
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
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.navigationController.navigationBarHidden = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  if (_needsInitialAnimation) {
    // get things rolling
    _needsInitialAnimation = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, .5 * NSEC_PER_SEC),
      dispatch_get_main_queue(), ^{
        [self animateField];
      });
  }
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  self.navigationController.navigationBarHidden = NO;
}

- (void)viewDidUnload
{
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  // Return YES for supported orientations
  if ([UIDevice.currentDevice userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
  } else {
    return YES;
  }
}

- (void)resetField
{
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

- (void)setFieldForPlayAgain
{
  self.shootLabel.hidden =
  self.rockButton.hidden =
  self.paperButton.hidden =
  self.scissorsButton.hidden = YES;

  self.playerHand.hidden =
  self.againButton.hidden = NO;
}

- (void)animateField
{
  // rock
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, .5 * NSEC_PER_SEC),
    dispatch_get_main_queue(), ^{
      self.rockLabel.hidden = NO;
      self.rockButton.hidden = NO;

      // paper
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC),
        dispatch_get_main_queue(), ^{
          self.paperLabel.hidden = NO;
          self.paperButton.hidden = NO;

          // scissors
          dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC),
            dispatch_get_main_queue(), ^{
              self.scissorsLabel.hidden = NO;
              self.scissorsButton.hidden = NO;

              // shoot!
              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC),
                dispatch_get_main_queue(), ^{
                  self.shootLabel.hidden =
                  self.computerHand.hidden = NO;
                  self.rockButton.enabled =
                  self.paperButton.enabled =
                  self.scissorsButton.enabled = YES;

                  self.computerHand.animationImages = @[_rightImages[RPSCallRock], _rightImages[RPSCallPaper], _rightImages[RPSCallScissors]];
                  self.computerHand.animationDuration = .4;
                  self.computerHand.animationRepeatCount = 0;
                  [self.computerHand startAnimating];
                  _lastAnimationStartTime = [NSDate date];
                });
            });
        });
    });
}

- (RPSCall)callViaRandom
{
  return (RPSCall)(arc4random() % 3);
}

- (RPSResult)resultForPlayerCall:(RPSCall)playerCall
                    computerCall:(RPSCall)computerCall
{
  static RPSResult results[3][3] = {
    {RPSResultTie, RPSResultLoss, RPSResultWin},
    {RPSResultWin, RPSResultTie, RPSResultLoss},
    {RPSResultLoss, RPSResultWin, RPSResultTie}
  };
  return results[playerCall][computerCall];
}

- (void)callGame:(RPSCall)playerCall
{
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
}

- (void)updateScoreLabel
{
  self.scoreLabel.text = [NSString stringWithFormat:@"W = %d   L = %d   T = %d", _wins, _losses, _ties];
}

- (IBAction)clickRPSButton:(id)sender
{
  UIButton *button = sender;
  RPSCall choice = (RPSCall)button.tag;
  self.playerHand.image = _leftImages[choice];
  [self callGame:choice];
  [self setFieldForPlayAgain];
}

- (IBAction)clickAgainButton:(id)sender
{
  [self resetField];
  [self animateField];
}

- (IBAction)clickFacebookButton:(id)sender
{
  UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil
                                                     delegate:self
                                            cancelButtonTitle:@"Cancel"
                                       destructiveButtonTitle:nil
                                            otherButtonTitles:@"Share on Facebook",
                          @"Share on Messenger",
                          @"Friends' Activity",
                          FBSDKAccessToken.currentAccessToken ? @"Log out" : @"Log in",
                          nil];
  // Show the sheet
  [sheet showInView:sender];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if (buttonIndex != 0) { // ok
    if (_alertOkHandler) {
      _alertOkHandler();
      _alertOkHandler = nil;
    }
  }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  switch (buttonIndex) {
    case 0: { // Share on Facebook
      FBSDKShareDialog *shareDialog = [[FBSDKShareDialog alloc] initWithViewController:self content:[self getGameLinkShareContent] delegate:self];
      if (![shareDialog show]) {
        [self displayInstallAppWithAppName:@"Facebook"];
      }
      break;
    }
    case 1: { // Share on Messenger
      id<FBSDKSharingContent> content = [self getGameLinkShareContent];
      FBSDKMessageDialog *messageDialog = [[FBSDKMessageDialog alloc] initWithContent:content delegate:self];
      if (![messageDialog show]) {
        [self displayInstallAppWithAppName:@"Messenger"];
      }
      break;
    }
    case 2: { // See Friends
      UIViewController *friends;
      if ([UIDevice.currentDevice userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        friends = [[RPSFriendsViewController alloc] initWithNibName:@"RPSFriendsViewController_iPhone" bundle:nil];
      } else {
        friends = [[RPSFriendsViewController alloc] initWithNibName:@"RPSFriendsViewController_iPad" bundle:nil];
      }
      [self.navigationController pushViewController:friends
                                           animated:YES];
      break;
    }
    case 3: { // Login and logout
      if (FBSDKAccessToken.currentAccessToken) {
        FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
        [login logOut];
      } else {
        FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
        [login logInWithPermissions:@[@"public_profile"]
                 fromViewController:self
                            handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
                              if (error) {
                                NSLog(@"Error: %@", error.description);
                              }
                            }];
      }
    }
  }
}

- (void)displayInstallAppWithAppName:(NSString *)appName
{
  NSString *message = [NSString stringWithFormat:
                       @"Install or upgrade the %@ application on your device and "
                       @"get cool new sharing features for this application. "
                       @"What do you want to do?", appName];
  [self alertWithMessage:message
                      ok:@"Install or Upgrade Now"
                  cancel:@"Decide Later"
              completion:^{
                [UIApplication.sharedApplication
                 openURL:[NSURL URLWithString:[NSString stringWithFormat:@"itms-apps://itunes.com/apps/%@", appName]]];
              }];
}

- (FBSDKShareLinkContent *)getGameLinkShareContent
{
  FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
  content.contentURL = [NSURL URLWithString:@"https://developers.facebook.com/"];
  return content;
}

- (void)alertWithMessage:(NSString *)message
                      ok:(NSString *)ok
                  cancel:(NSString *)cancel
              completion:(RPSBlock)completion
{
  UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Share with Facebook"
                                                      message:message
                                                     delegate:self
                                            cancelButtonTitle:cancel
                                            otherButtonTitles:ok, nil];
  _alertOkHandler = [completion copy];
  [alertView show];
}

#pragma mark - FBSDKSharingDelegate

- (void)sharer:(id<FBSDKSharing>)sharer didCompleteWithResults:(NSDictionary *)results
{
  NSLog(@"Posted OG action with id: %@", results[@"postId"]);
}

- (void)sharer:(id<FBSDKSharing>)sharer didFailWithError:(NSError *)error
{
  NSLog(@"Error: %@", error.description);
}

- (void)sharerDidCancel:(id<FBSDKSharing>)sharer
{
  NSLog(@"Canceled share");
}

#pragma mark - Logging App Event

- (void)logCurrentPlayerCall:(RPSCall)playerCall
              lastPlayerCall:(RPSCall)lastPlayerCall
            lastComputerCall:(RPSCall)lastComputerCall
{
  // log the user's choice while comparing it against the result of their last throw
  if (lastComputerCall != RPSCallNone && lastComputerCall != RPSCallNone) {
    RPSResult lastResult = [self resultForPlayerCall:lastPlayerCall
                                        computerCall:lastComputerCall];

    NSString *transitionalWord = (lastResult == RPSResultWin ? @"against"
      : lastResult == RPSResultTie ? @"with" : @"to");
    NSString *previousResult = [NSString stringWithFormat:@"%@ %@ %@",
                                kResults[lastResult],
                                transitionalWord,
                                callType[lastPlayerCall + 1]];
    [FBSDKAppEvents.shared logEvent:@"Throw Based on Last Result"
                         parameters:@{callType[playerCall + 1] : previousResult}];
  }
}

- (void)logPlayerCall:(RPSCall)playerCall result:(RPSResult)result timeTaken:(NSTimeInterval)timeTaken
{
  // log the user's choice and the respective result
  NSString *playerChoice = callType[playerCall + 1];
  [FBSDKAppEvents.shared logEvent:@"Round End"
                       valueToSum:timeTaken
                       parameters:@{@"roundResult" : kResults[result], @"playerChoice" : playerChoice}];
}

- (void)logTimeTaken:(NSTimeInterval)timeTaken
{
  // logs the time a user takes to make a choice in a round
  NSString *timeTakenStr = (timeTaken < 0.5f ? @"< 0.5s"
    : timeTaken < 1.0f ? @"0.5s <= t < 1.0s"
      : timeTaken < 1.5f ? @"1.0s <= t < 1.5s"
        : timeTaken < 2.0f ? @"1.5s <= t < 2.0s"
          : timeTaken < 2.5f ? @"2.0s <= t < 2.5s" : @" >= 2.5s");
  [FBSDKAppEvents.shared logEvent:@"Time Taken"
                       valueToSum:timeTaken
                       parameters:@{@"Time Taken" : timeTakenStr}];
}

@end
