/*
 * Copyright 2010 Facebook
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

#import <UIKit/UIKit.h>

typedef enum _FBProfilePictureSize {
    FBProfilePictureSizeSquare      = 0,
    FBProfilePictureSizeSmall       = 1,
    FBProfilePictureSizeNormal      = 2,
    FBProfilePictureSizeLarge       = 3
} FBProfilePictureSize;

@interface FBProfilePictureView : UIView

@property (copy, nonatomic) NSString* userID;
@property (nonatomic) FBProfilePictureSize pictureSize;

// inits and returns a ProfilePictureView
//
// Summary:
//  Initializes the profile view with the specified user id and picture size.
//  Picture size can be one of FBProfilePictureSize enum.
- (id)init;
- (id)initWithUserID:(NSString*)userID 
      andPictureSize:(FBProfilePictureSize)pictureSize;

@end
