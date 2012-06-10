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
 @typedef FBProfilePictureCropping enum
 
 @abstract 
 Type used to specify the cropping treatment of the profile picture.
 
 @discussion
 */
typedef enum {
    /*! Original (default) - the original profile picture, as uploaded */
    FBProfilePictureCroppingOriginal    = 0,
    
    /*! Square - the square version that the Facebook user defined */
    FBProfilePictureCroppingSquare      = 1
    
} FBProfilePictureCropping;

/*!
 @class
 @abstract
 View used to display a profile picture.  Default behavior of this control centers the profile picture
 in the control and shrinks it, if necessary, to the controls bounds, preserving aspect ratio. The smallest
 possible image is downloaded to ensure that scaling up never happens.  Resizing the control may result in 
 a different size of the image being loaded.  Canonical image sizes are documented in the "Pictures" section
 of https://developers.facebook.com/docs/reference/api. 
 */
@interface FBProfilePictureView : UIView

/*!
 @abstract
 Specifies the fbid for the user, place or object for which a picture should be fetched and displayed
 */
@property (copy, nonatomic) NSString* userID;

/*!
 @abstract
 Specifies which cropping of the profile picture to use.
 */
@property (nonatomic) FBProfilePictureCropping pictureCropping;

/*!
 @abstract
 Initializes and returns a ProfilePictureView
 */
- (id)init;


/*!
 @abstract
 Initializes and returns a ProfilePictureView
 
 @param userID          Specifies the fbid for the object for which a picture should be fetched and displayed
 @param pictureCropping Specifies the cropping for the picture displayed.
 */
- (id)initWithUserID:(NSString*)userID 
  andPictureCropping:(FBProfilePictureCropping)pictureCropping;


@end
