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

#import <UIKit/UIKit.h>

#import "SCViewController.h"

typedef void(^ConfirmCallback)(id sender, bool confirm);

@interface SCPhotoViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (copy, nonatomic) ConfirmCallback confirmCallback;
@property (strong, readonly) UIImage* image;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil image:(UIImage *)anImage;
- (IBAction)confirm:(id)sender;
- (IBAction)cancel:(id)sender;

@end
