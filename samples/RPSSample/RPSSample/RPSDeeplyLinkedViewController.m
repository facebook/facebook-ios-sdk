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

#import "RPSDeeplyLinkedViewController.h"

#import "RPSCommonObjects.h"

@interface RPSDeeplyLinkedViewController ()
@property (nonatomic, assign) RPSCall             call;
@property (nonatomic, weak) IBOutlet UIImageView *callImageView;
@property (nonatomic, weak) IBOutlet UIButton    *playButton;
@end

@implementation RPSDeeplyLinkedViewController

#pragma mark - Lifecycle

- (instancetype)initWithCall:(RPSCall)call {
    NSParameterAssert(call != RPSCallNone);

    self = [super init];

    if (self) {
        self.call = call;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }

    return self;
}

#pragma mark - Methods

- (IBAction)play:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    self.playButton.layer.cornerRadius = 8.0;
    self.playButton.layer.borderWidth = 4.0;
    self.playButton.layer.borderColor = self.playButton.titleLabel.textColor.CGColor;

    UIImage *callImage = nil;
    switch (self.call) {
        case RPSCallPaper:
            callImage = [UIImage imageNamed:@"right-paper-128.png"];
            break;
        case RPSCallRock:
            callImage = [UIImage imageNamed:@"right-rock-128.png"];
            break;
        case RPSCallScissors:
            callImage = [UIImage imageNamed:@"right-scissors-128.png"];
            break;

        default:
            break;
    }

    [self.callImageView setImage:callImage];
}

@end
