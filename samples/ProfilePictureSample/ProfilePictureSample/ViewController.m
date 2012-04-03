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
    // Generate a random number between 100000 & 400000 and use that as id
    u_int32_t randomId = 100000 + arc4random_uniform(300000);
    profilePictureView.userID = [NSString stringWithFormat:@"%u", randomId];
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

    profilePictureView.pictureSize = FBProfilePictureSizeLarge;
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
