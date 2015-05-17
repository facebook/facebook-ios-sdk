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

#import "SUProfileTableViewCell.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

static const CGFloat leftMargin = 10;
static const CGFloat topMargin = 5;
static const CGFloat rightMargin = 30;
static const CGFloat pictureWidth = 50;
static const CGFloat pictureHeight = 50;

@interface SUProfileTableViewCell ()

@property (weak, nonatomic) FBSDKProfilePictureView *profilePic;

@end

@implementation SUProfileTableViewCell

#pragma mark - Lifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initializeSubViews];
    }

    return self;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initializeSubViews];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self initializeSubViews];
}

#pragma mark -

- (void)initializeSubViews {
    FBSDKProfilePictureView *profilePic = [[FBSDKProfilePictureView alloc]
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

- (void)layoutSubviews {
    [super layoutSubviews];

    CGSize size = self.bounds.size;

    self.textLabel.frame = CGRectMake(
                                      leftMargin * 2 + pictureWidth,
                                      topMargin,
                                      size.width - leftMargin - pictureWidth - rightMargin,
                                      size.height - topMargin);
}

#pragma mark - Properties

- (NSString *)userID {
    return self.profilePic.profileID;
}

- (void)setUserID:(NSString *)userID {
    self.profilePic.profileID = userID;
}

- (NSString *)userName {
    return self.textLabel.text;
}

- (void)setUserName:(NSString *)userName {
    self.textLabel.text = userName;
}

- (CGFloat)desiredHeight {
    return topMargin * 2 + pictureHeight;
}

@end
