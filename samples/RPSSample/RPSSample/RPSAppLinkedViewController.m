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

#import "RPSAppLinkedViewController.h"

#import "RPSCommonObjects.h"

@interface RPSAppLinkedViewController ()
@property (nonatomic, assign) RPSCall             call;
@property (nonatomic, weak) IBOutlet UIImageView *callImageView;
@property (nonatomic, weak) IBOutlet UIButton    *playButton;
@end

@implementation RPSAppLinkedViewController

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
    [super viewDidLoad];

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
