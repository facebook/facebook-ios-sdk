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

#import "SCProfilePictureButton.h"

@interface SCProfilePictureButton ()
@property (nonatomic, strong, readonly) FBProfilePictureView *profilePictureView;
@end

@implementation SCProfilePictureButton
{
    FBProfilePictureView *_profilePictureView;
}

- (FBProfilePictureCropping)pictureCropping
{
    return self.profilePictureView.pictureCropping;
}

- (void)setPictureCropping:(FBProfilePictureCropping)pictureCropping
{
    self.profilePictureView.pictureCropping = pictureCropping;
}

- (NSString *)profileID
{
    return self.profilePictureView.profileID;
}

- (void)setProfileID:(NSString *)profileID
{
    self.profilePictureView.profileID = profileID;
}

- (FBProfilePictureView *)profilePictureView
{
    // lazy load the profilePictureView
    if (!_profilePictureView) {
        _profilePictureView = [[FBProfilePictureView alloc] initWithFrame:self.bounds];
        _profilePictureView.userInteractionEnabled = NO;
        [self insertSubview:_profilePictureView atIndex:0];
    }
    return _profilePictureView;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _profilePictureView.frame = self.bounds;
}

@end
