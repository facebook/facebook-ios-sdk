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
 @protocol 
 
 @abstract
 The `FBViewControllerDelegate` protocol defines the methods called when the Cancel or Done
 buttons are pressed in a <FBViewController>.
 */
@protocol FBViewControllerDelegate <NSObject>

@optional

/*!
 @abstract
 Called when the Cancel button is pressed on a modally-presented <FBViewController>.
 
 @param sender          The view controller sending the message.
 */
- (void)facebookViewControllerCancelWasPressed:(id)sender;

/*!
 @abstract
 Called when the Done button is pressed on a modally-presented <FBViewController>.

 @param sender          The view controller sending the message.
 */
- (void)facebookViewControllerDoneWasPressed:(id)sender;

@end


/*!
 @class FBViewController
 
 @abstract
 The `FBViewController` class is a base class encapsulating functionality common to several
 other view controller classes. Specifically, it provides UI when a view controller is presented
 modally, in the form of optional Cancel and Done buttons.
 */
@interface FBViewController : UIViewController

/*!
 @abstract
 The Cancel button to display when presented modally. If nil, no Cancel button is displayed.
 */
@property (nonatomic, retain) UIBarButtonItem *cancelButton;

/*!
 @abstract
 The Done button to display when presented modally. If nil, no Done button is displayed.
 */
@property (nonatomic, retain) UIBarButtonItem *doneButton;

/*!
 @abstract
 The delegate that will be called when Cancel or Done is pressed. Derived classes may specify
 derived types for their delegates that provide additional functionality.
 */
@property (nonatomic, assign) id<FBViewControllerDelegate> delegate;

/*!
 @abstract
 The view into which derived classes should put their subviews. This view will be resized correctly
 depending on whether or not a toolbar is displayed.
 */
@property (nonatomic, readonly, retain) UIView *canvasView;

@end

