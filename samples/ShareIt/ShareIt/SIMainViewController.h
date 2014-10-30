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

#import <FacebookSDK/FacebookSDK.h>

@interface SIMainViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic, strong) IBOutlet FBLikeControl *pageLikeControl;

@property (nonatomic, strong) IBOutlet FBLoginView *loginView;
@property (nonatomic, strong) IBOutlet UIPageControl *pageControl;
@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;

- (IBAction)changePage:(id)sender;
- (IBAction)share:(id)sender;

@end
