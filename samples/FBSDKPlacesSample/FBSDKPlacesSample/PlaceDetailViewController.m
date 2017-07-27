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

#import "PlaceDetailViewController.h"

#import <FBSDKPlacesKit/FBSDKPlacesKit.h>

#import "UIImageView+Web.h"

@interface PlaceDetailViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *coverPhotoImageView;

@property (weak, nonatomic) IBOutlet UILabel *placeTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *categoriesLabel;
@property (weak, nonatomic) IBOutlet UILabel *aboutLabel;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet UIButton *websiteButton;
@property (weak, nonatomic) IBOutlet UILabel *hoursLabel;

@property (weak, nonatomic) IBOutlet UILabel *currentlyAtPlaceLabel;
@property (weak, nonatomic) IBOutlet UIButton *yesButton;
@property (weak, nonatomic) IBOutlet UIButton *noButton;

@end

@implementation PlaceDetailViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.title = self.place.title;

  [self refreshUI];
  [self loadAdditionalPlaceData];
}

#pragma mark - FBSDKPlacesKit calls

- (void)loadAdditionalPlaceData
{
  FBSDKGraphRequest *request = [self.placesManager
                                placeInfoRequestForPlaceID:self.place.placeID
                                fields:@[FBSDKPlacesFieldKeyName, FBSDKPlacesFieldKeyAbout, FBSDKPlacesFieldKeyHours, FBSDKPlacesFieldKeyCoverPhoto, FBSDKPlacesFieldKeyWebsite, FBSDKPlacesFieldKeyLocation, FBSDKPlacesFieldKeyOverallStarRating, FBSDKPlacesFieldKeyPhone, FBSDKPlacesFieldKeyProfilePhoto]];
  [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
    if (result) {
      self.place = [[Place alloc] initWithDictionary:result];
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self refreshUI];
      }];
    }
  }];
}

- (void)provideLocationFeedbackWasAtPlace:(BOOL)wasAtPlace
{
  FBSDKGraphRequest *request = [self.placesManager
                                currentPlaceFeedbackRequestForPlaceID:self.place.placeID
                                tracking:self.currentPlacesTrackingID
                                wasHere:wasAtPlace];

  [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {}];
}

#pragma mark - Button Actions

- (IBAction)websiteButtonClicked:(id)sender {
  if (self.place.website) {
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(openURL:options:completionHandler:)]) { // Only available on iOS 10+
      [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.place.website] options:@{} completionHandler:NULL];
    }
    else {
      [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.place.website]];
    }
  }
}

- (IBAction)yesButtonClicked:(id)sender
{
  [self showFeedbackAlertWithMessage:[NSString stringWithFormat:@"Thanks for confirming you're at %@!", self.place.title]];
  [self provideLocationFeedbackWasAtPlace:YES];
}

- (IBAction)noButtonClicked:(id)sender
{
  [self showFeedbackAlertWithMessage:[NSString stringWithFormat:@"Thanks for letting us know you're not at %@!", self.place.title]];
  [self provideLocationFeedbackWasAtPlace:NO];
}

- (void)showFeedbackAlertWithMessage:(NSString *)message
{
  UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Feedback Submitted"
                                                                 message:message
                                                          preferredStyle:UIAlertControllerStyleAlert];

  UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                        handler:NULL];

  [alert addAction:defaultAction];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)refreshUI
{
  if (self.currentPlacesTrackingID) {
    self.currentlyAtPlaceLabel.hidden = NO;
    self.yesButton.hidden = NO;
    self.noButton.hidden = NO;
  }
  else {
    self.currentlyAtPlaceLabel.hidden = YES;
    self.yesButton.hidden = YES;
    self.noButton.hidden = YES;
  }

  self.placeTitleLabel.text = self.place.title;
  self.categoriesLabel.text = [self.place.categories componentsJoinedByString:@", "];
  self.aboutLabel.text = self.place.subTitle;
  self.addressLabel.text = [NSString stringWithFormat:@"%@\n%@, %@ %@", self.place.street, self.place.city, self.place.state, self.place.zip];
  self.phoneLabel.text = self.place.phone;
  [self.websiteButton setTitle:self.place.website forState:UIControlStateNormal];

  if (self.place.coverPhotoURL) {
    [self.coverPhotoImageView fb_setImageWithURL:self.place.coverPhotoURL];
  }
  else {
    [self.coverPhotoImageView fb_setImageWithURL:self.place.profilePictureURL];
  }

  if (self.place.hours) {
    NSMutableArray *hourStrings = [NSMutableArray new];
    for (Hours *hours in self.place.hours) {
      [hourStrings addObject:[hours displayString]];
    }
    self.hoursLabel.text = [hourStrings componentsJoinedByString:@"\n"];
  }
  else {
    self.hoursLabel.text = nil;
  }

}

@end
