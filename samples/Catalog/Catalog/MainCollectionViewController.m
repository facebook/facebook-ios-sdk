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

#import "MainCollectionViewController.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import <FBSDKLoginKit/FBSDKLoginKit.h>

#import "CollectionViewCell.h"
#import "MenuItem.h"

@implementation MainCollectionViewController
{
  NSArray *_iconArray;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self.navigationController.navigationBar setHidden:YES];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  _iconArray = [self _createIconArray];
}

- (void)viewWillDisappear: (BOOL)animated
{
  [super viewWillDisappear:animated];
  [self.navigationController.navigationBar setHidden:NO];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
  return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
  return _iconArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  CollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"itemCell" forIndexPath:indexPath];

  cell.textLabel.text = [[_iconArray objectAtIndex:indexPath.row] iconText];
  cell.iconImage.image = [UIImage imageNamed:[[_iconArray objectAtIndex:indexPath.row] iconImageName]];

  return cell;
}

#pragma mark <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
  [self performSegueWithIdentifier:[[_iconArray objectAtIndex:indexPath.row] iconText] sender:self];
}

#pragma mark - Helper Method

- (NSArray *)_createIconArray
{
  NSMutableArray *array = [[NSMutableArray alloc] init];
  [array addObject:[[MenuItem alloc] initWithIconText:@"Login" iconImage:@"LoginIcon"]];
  [array addObject:[[MenuItem alloc] initWithIconText:@"Share" iconImage:@"ShareIcon"]];
  [array addObject:[[MenuItem alloc] initWithIconText:@"App Events" iconImage:@"AppEventsIcon"]];
  [array addObject:[[MenuItem alloc] initWithIconText:@"App Invites" iconImage:@"AppInvitesIcon"]];
  [array addObject:[[MenuItem alloc] initWithIconText:@"App Links" iconImage:@"AppLinksIcon"]];
  [array addObject:[[MenuItem alloc] initWithIconText:@"Graph API" iconImage:@"GraphAPIIcon"]];
  return array;
}

@end
