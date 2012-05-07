/*
 * Copyright 2012 Facebook
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
 
#import "FBSubtitledTableViewCell.h"

@interface FBSubtitledTableViewCell()

@property (retain, nonatomic) UILabel* titleLabel;
@property (retain, nonatomic) UILabel* subtitleLabel;

- (void)initializeSubViews;

@end

@implementation FBSubtitledTableViewCell

@synthesize titleLabel = _titleLabel;
@synthesize subtitleLabel = _subtitleLabel;

#pragma mark - Lifecycle

- (void)dealloc
{
    [_titleLabel removeFromSuperview];
    [_subtitleLabel removeFromSuperview];
    
    [_titleLabel release];
    [_subtitleLabel release];
    
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (self) {
        [self initializeSubViews];
    }
    
    return self;
}

- (id)initWithStyle:(UITableViewCellStyle)style 
    reuseIdentifier:(NSString*)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initializeSubViews];
    }
    
    return self;
}

#pragma mark -

- (void)initializeSubViews
{
    // Good defaults, that work for both iPad & iPhone
    static CGFloat leftOffset = 50;
    static CGFloat topOffset = 5;
    static CGFloat titleHeight = 19;
    static CGFloat subtitleHeight = 12;
    static CGFloat margin = 3;
    static CGFloat titleFontHeight = 16;
    static CGFloat subtitleFontHeight = 12;
        
    CGSize size = self.bounds.size;
    
    UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(
        leftOffset, 
        topOffset, 
        size.width - leftOffset - margin, 
        titleHeight)];
    titleLabel.autoresizingMask = 
        UIViewAutoresizingFlexibleBottomMargin | 
        UIViewAutoresizingFlexibleWidth;
    titleLabel.font = [UIFont systemFontOfSize:titleFontHeight];
    self.titleLabel = titleLabel;
    [titleLabel release];
    
    UILabel* subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(
        leftOffset, 
        topOffset + titleHeight + margin, 
        size.width - leftOffset - margin, 
        subtitleHeight)];
    subtitleLabel.autoresizingMask = 
        UIViewAutoresizingFlexibleBottomMargin |
        UIViewAutoresizingFlexibleWidth;
    subtitleLabel.font = [UIFont systemFontOfSize:subtitleFontHeight];
    subtitleLabel.textColor = 
        [UIColor colorWithRed:0.4 green:0.6 blue:0.8 alpha:1.0];
    self.subtitleLabel = subtitleLabel;
    [subtitleLabel release];
    
    [self.contentView addSubview:titleLabel];
    [self.contentView addSubview:subtitleLabel];

    self.clipsToBounds = YES;
    self.autoresizesSubviews = YES;
}

#pragma mark - Properties

- (NSString*)subtitle
{
    return self.subtitleLabel.text;
}

- (NSString*)title
{
    return self.titleLabel.text;
}

- (void)setSubtitle:(NSString *)subtitle
{
    self.subtitleLabel.text = subtitle;
}

- (void)setTitle:(NSString *)title
{
    self.titleLabel.text = title;
}


@end
