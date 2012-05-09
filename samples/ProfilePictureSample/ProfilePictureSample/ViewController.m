/*
 * Copyright 2012 Facebook
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
 
#import "ViewController.h"

const char* interestingIDs[] = {
    "zuck",
    // Recent Presidents and nominees
    "barackobama",
    "mittromney",
    "johnmccain",
    "johnkerry",
    "georgewbush",
    "algore",
    // Places too!
    "Disneyland",
    "SpaceNeedle",
    "TourEiffel",
    "sydneyoperahouse",
    // A selection of 1986 Mets
    "166020963458360",
    "108084865880237",
    "40885519486",
    "111825495501392",
    // The cast of Saved by the Bell
    "108168249210849",
    "TiffaniThiessen",
    "108126672542534",
    "112886105391693",
    "MarioLopezExtra",
    "108504145837165",
    "dennishaskins",
};
const int kNumInterestingIDs = sizeof(interestingIDs) / sizeof(interestingIDs[0]);

@interface ViewController ()

@end

@implementation ViewController
@synthesize profilePictureView;

- (IBAction)showJasonProfile:(id)sender 
{
    // Notice how you can supply either the user's alias or their profile id
    profilePictureView.userID = @"jascla";
}

- (IBAction)showMichaelProfile:(id)sender 
{
    profilePictureView.userID = @"michael.marucheck";
}

- (IBAction)showVijayeProfile:(id)sender 
{
    profilePictureView.userID = @"vijaye";
}

- (IBAction)showRandomProfile:(id)sender
{
    int index = arc4random() % kNumInterestingIDs;
    profilePictureView.userID = [NSString stringWithCString:interestingIDs[index]
                                               encoding:NSASCIIStringEncoding];
}

- (IBAction)makePictureSmall:(id)sender 
{
    profilePictureView.pictureSize = FBProfilePictureSizeSmall;
    profilePictureView.bounds = CGRectMake(0, 0, 40, 40);
}

- (IBAction)makePictureNormal:(id)sender 
{
    profilePictureView.pictureSize = FBProfilePictureSizeNormal;
    profilePictureView.bounds = CGRectMake(0, 0, 80, 80);
}

- (IBAction)makePictureLarge:(id)sender 
{
    profilePictureView.pictureSize = FBProfilePictureSizeLarge;
    profilePictureView.bounds = CGRectMake(0, 0, 130, 130);
}


#pragma mark -
#pragma mark Template generated code

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self makePictureLarge:self];
    profilePictureView.userID = @"45963418107"; // Hello world
}

- (void)viewDidUnload
{
    self.profilePictureView.userID = nil;
    self.profilePictureView = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void)dealloc {
    profilePictureView.userID = nil;
    [profilePictureView release];
    [super dealloc];
}

@end
