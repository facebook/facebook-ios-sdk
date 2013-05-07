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

#import "SUProfileTableViewCell.h"
#import <FacebookSDK/FacebookSDK.h>

static const CGFloat leftMargin = 10;
static const CGFloat topMargin = 5;
static const CGFloat rightMargin = 30;
static const CGFloat pictureWidth = 50;
static const CGFloat pictureHeight = 50;

@interface SUProfileTableViewCell ()

// FBSample logic
// This view is used to display the profile pictures within the list of user accounts
@property (strong, nonatomic) FBProfilePictureView *profilePic;

- (void)initializeSubViews;

@end

@implementation SUProfileTableViewCell

@synthesize profilePic = _profilePic;

#pragma mark - Lifecycle

- (void)dealloc {
    [_profilePic removeFromSuperview];
}

- (id)init {
    self = [super init];
    if (self) {
        [self initializeSubViews];
    }
    
    return self;
}

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initializeSubViews];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark -

- (void)initializeSubViews {   
    FBProfilePictureView *profilePic = [[FBProfilePictureView alloc] 
        initWithFrame:CGRectMake(
            leftMargin,
            topMargin,
            pictureWidth,
            pictureHeight)];
    [self addSubview:profilePic];
    self.profilePic = profilePic;
    
    self.clipsToBounds = YES;
    self.autoresizesSubviews = YES;                                                                
}

- (void) layoutSubviews {
    [super layoutSubviews];

    CGSize size = self.bounds.size;
    
    self.textLabel.frame = CGRectMake(
        leftMargin * 2 + pictureWidth, 
        topMargin,
        size.width - leftMargin - pictureWidth - rightMargin, 
        size.height - topMargin);
}

#pragma mark - Properties

- (NSString*)userID {
    return self.profilePic.profileID;
}

- (void)setUserID:(NSString *)userID {
    // FBSample logic
    // Setting the profileID property of the profile picture view causes the view to fetch and display
    // the profile picture for the given user
    self.profilePic.profileID = userID;
}

- (NSString*)userName {
    return self.textLabel.text;
}

- (void)setUserName:(NSString *)userName {
    self.textLabel.text = userName;
}

- (CGFloat)desiredHeight {
    return topMargin * 2 + pictureHeight;
}

@end
