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

#import "RPSAutoAppLinkBasicViewController.h"

static const int paddingLen = 10;

@interface RPSAutoAppLinkBasicViewController()

@property (strong, nonatomic) Coffee* product;
@property (nonatomic, copy) NSDictionary<NSString *, id> *data;

@end

@implementation RPSAutoAppLinkBasicViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    int stdWidth = scrollView.frame.size.width - paddingLen*2;

    UILabel *labelName = [[UILabel alloc] initWithFrame:CGRectMake(paddingLen, 50, stdWidth, 30)];
    labelName.font = [UIFont boldSystemFontOfSize:24];
    labelName.textColor = [UIColor grayColor];

    UILabel *labelDesc = [[UILabel alloc] initWithFrame:CGRectMake(paddingLen, 90, stdWidth, 20)];
    labelDesc.font = [UIFont systemFontOfSize:14];
    labelDesc.textColor = [UIColor lightGrayColor];

    UILabel *labelPrice = [[UILabel alloc] initWithFrame:CGRectMake(paddingLen, 130, stdWidth, 20)];
    labelPrice.font = [UIFont systemFontOfSize:20];
    labelPrice.textColor = [UIColor blackColor];

    if (self.product == nil) {
        self.product = [[Coffee alloc] initWithName:@"Coffee" desc:@"I am just a coffee" price:1];
    }
    labelName.text = self.product.name;
    labelDesc.text = [@"Description: " stringByAppendingString:self.product.desc];
    labelPrice.text = [@"Price: $" stringByAppendingString:[@(self.product.price) stringValue]];

    [scrollView addSubview: labelName];
    [scrollView addSubview: labelDesc];
    [scrollView addSubview: labelPrice];

    if (self.data != nil) {
        UILabel *labelData = [[UILabel alloc] init];
        labelData.font = [UIFont systemFontOfSize:20];
        labelData.textColor = [UIColor blueColor];
        labelData.text = [NSString stringWithFormat:@"data is: %@", self.data];
        labelData.numberOfLines = 0;
        CGSize size = [labelData.text boundingRectWithSize:CGSizeMake(stdWidth, 1000)
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                attributes:@{NSFontAttributeName:labelData.font}
                                                   context:nil].size;
        labelData.frame = CGRectMake(paddingLen, 180, size.width, size.height);
        [scrollView addSubview:labelData];
    }
    [self.view addSubview: scrollView];
}

#pragma mark - Auto App Link
- (void)setAutoAppLinkData:(NSDictionary<NSString *, id> *)data {
    NSString *productIndex = [@([data[@"product_id"] integerValue]) stringValue];
    NSString *name = [@"Coffee " stringByAppendingString:productIndex];
    NSString *description = [@"I am auto app link coffee " stringByAppendingString:productIndex];
    self.product = [[Coffee alloc] initWithName:name desc:description price:10];
    self.data = [data copy];
}

@end
