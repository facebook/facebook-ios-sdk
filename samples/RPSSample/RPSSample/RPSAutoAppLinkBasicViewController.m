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

    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(paddingLen, 50, stdWidth, 30)];
    nameLabel.font = [UIFont boldSystemFontOfSize:24];
    nameLabel.textColor = [UIColor grayColor];

    UILabel *descLabel = [[UILabel alloc] initWithFrame:CGRectMake(paddingLen, 90, stdWidth, 20)];
    descLabel.font = [UIFont systemFontOfSize:14];
    descLabel.textColor = [UIColor lightGrayColor];

    UILabel *priceLabel = [[UILabel alloc] initWithFrame:CGRectMake(paddingLen, 130, stdWidth, 20)];
    priceLabel.font = [UIFont systemFontOfSize:20];
    priceLabel.textColor = [UIColor blackColor];

    if (self.product == nil) {
        self.product = [[Coffee alloc] initWithName:@"Coffee" desc:@"I am just a coffee" price:1];
    }
    nameLabel.text = self.product.name;
    descLabel.text = [@"Description: " stringByAppendingString:self.product.desc];
    priceLabel.text = [@"Price: $" stringByAppendingString:[@(self.product.price) stringValue]];

    [scrollView addSubview: nameLabel];
    [scrollView addSubview: descLabel];
    [scrollView addSubview: priceLabel];

    if (self.data != nil) {
        UILabel *dataLabel = [[UILabel alloc] init];
        dataLabel.font = [UIFont systemFontOfSize:20];
        dataLabel.textColor = [UIColor blueColor];
        dataLabel.text = [NSString stringWithFormat:@"data is: %@", self.data];
        dataLabel.numberOfLines = 0;
        CGSize size = [dataLabel.text boundingRectWithSize:CGSizeMake(stdWidth, 1000)
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                attributes:@{NSFontAttributeName:dataLabel.font}
                                                   context:nil].size;
        dataLabel.frame = CGRectMake(paddingLen, 180, size.width, size.height);
        [scrollView addSubview:dataLabel];
    }
    [self.view addSubview: scrollView];
}

@end
