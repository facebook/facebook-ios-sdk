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

/*! 
 @typedef FBProfilePictureSize enum
 
 @abstract 
 Type used to specify the size and format of the profile picture
 
 @discussion
 */
typedef enum {
    /*! Square (default) */
    FBProfilePictureSizeSquare      = 0,
    
    /*! Small */
    FBProfilePictureSizeSmall       = 1,
    
    /*! Normal */
    FBProfilePictureSizeNormal      = 2,
    
    /*! Large */
    FBProfilePictureSizeLarge       = 3
} FBProfilePictureSize;

/*!
 @class
 @abstract
 View used to display a profile picture
 */
@interface FBProfilePictureView : UIView

/*!
 @abstract
 Specifies the fbid for the user, place or object for which a picture should be fetched and displayed
 */
@property (copy, nonatomic) NSString* userID;

/*!
 @abstract
 Specifies the format and size of the picture displayed
 */
@property (nonatomic) FBProfilePictureSize pictureSize;

/*!
 @abstract
 Initializes and returns a ProfilePictureView
 */
- (id)init;

/*!
 @abstract
 Initializes and returns a ProfilePictureView
 
 @param userID          Specifies the fbid for the object for which a picture should be fetched and displayed
 @param pictureSize     Specifies the format and size of the picture displayed; picture size 
                        can be one of FBProfilePictureSize enum.
 */
- (id)initWithUserID:(NSString*)userID 
      andPictureSize:(FBProfilePictureSize)pictureSize;

@end
