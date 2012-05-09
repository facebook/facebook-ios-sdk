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

#import "FBGraphObjectTableCell.h"

static const CGFloat titleFontHeight = 16;
static const CGFloat subtitleFontHeight = 12;
static const CGFloat pictureEdge = 40;
static const CGFloat pictureMargin = 1;
static const CGFloat horizontalMargin = 4;
static const CGFloat titleTopNoSubtitle = 11;
static const CGFloat titleTopWithSubtitle = 3;
static const CGFloat subtitleTop = 23;
static const CGFloat titleHeight = titleFontHeight * 1.25;
static const CGFloat subtitleHeight = subtitleFontHeight * 1.25;

@interface FBGraphObjectTableCell()

@property (nonatomic, retain) UIImageView *pictureView;
@property (nonatomic, retain) UILabel* subtitleLabel;
@property (nonatomic, retain) UILabel* titleLabel;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;

@end

@implementation FBGraphObjectTableCell {
@private
    UIImageView *_pictureView;
    UILabel *_subtitleLabel;
    UILabel *_titleLabel;
}

@synthesize pictureView = _pictureView;
@synthesize titleLabel = _titleLabel;
@synthesize subtitleLabel = _subtitleLabel;
@synthesize activityIndicator = _activityIndicator;

#pragma mark - Lifecycle

- (id)initWithStyle:(UITableViewCellStyle)style 
    reuseIdentifier:(NSString*)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Picture
        UIImageView *pictureView = [[UIImageView alloc] init];
        pictureView.clipsToBounds = YES;
        pictureView.contentMode = UIViewContentModeScaleAspectFill;
        
        self.pictureView = pictureView;
        [self.contentView addSubview:pictureView];
        [pictureView release];
        
        // Subtitle
        UILabel *subtitleLabel = [[UILabel alloc] init];
        subtitleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        subtitleLabel.textColor = [UIColor colorWithRed:0.4 green:0.6 blue:0.8 alpha:1.0];
        subtitleLabel.font = [UIFont systemFontOfSize:subtitleFontHeight];
        
        self.subtitleLabel = subtitleLabel;
        [self.contentView addSubview:subtitleLabel];
        [subtitleLabel release];
        
        // Title
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        titleLabel.font = [UIFont systemFontOfSize:titleFontHeight];
        
        self.titleLabel = titleLabel;
        [self.contentView addSubview:titleLabel];
        [titleLabel release];
        
        // Content View
        self.contentView.clipsToBounds = YES;
    }
    
    return self;
}

- (void)dealloc
{
    [_titleLabel release];
    [_subtitleLabel release];
    [_pictureView release];
    
    [super dealloc];
}

#pragma mark -

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    BOOL hasPicture = (self.picture != nil);
    BOOL hasSubtitle = (self.subtitle != nil);
    
    CGFloat pictureWidth = hasPicture ? pictureEdge : 0;
    CGSize cellSize = self.contentView.bounds.size;
    CGFloat textLeft = (hasPicture ? ((2 * pictureMargin) + pictureWidth) : 0) + horizontalMargin;
    CGFloat textWidth = cellSize.width - (textLeft + horizontalMargin);
    CGFloat titleTop = hasSubtitle ? titleTopWithSubtitle : titleTopNoSubtitle;
    
    self.pictureView.frame = CGRectMake(pictureMargin, pictureMargin, pictureEdge, pictureWidth);
    self.subtitleLabel.frame = CGRectMake(textLeft, subtitleTop, textWidth, subtitleHeight);
    self.titleLabel.frame = CGRectMake(textLeft, titleTop, textWidth, titleHeight);
    
    [self.pictureView setHidden:!(hasPicture)];
    [self.subtitleLabel setHidden:!(hasSubtitle)];
}

+ (CGFloat)rowHeight
{
    return pictureEdge + (2 * pictureMargin) + 1;
}

- (void)startAnimatingActivityIndicator {
    if (!self.activityIndicator) {
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:self.bounds];
        activityIndicator.hidesWhenStopped = YES;
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        activityIndicator.autoresizingMask =
            UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        self.activityIndicator = activityIndicator;
        [self addSubview:activityIndicator];
        [activityIndicator release];        
    }
    [self.activityIndicator startAnimating];
}

- (void)stopAnimatingActivityIndicator {
    if (self.activityIndicator) {
        [self.activityIndicator stopAnimating];
    }
}

#pragma mark - Properties

- (UIImage *)picture
{
    return self.pictureView.image;
}

- (void)setPicture:(UIImage *)picture
{
    self.pictureView.image = picture;
    [self setNeedsLayout];
}

- (NSString*)subtitle
{
    return self.subtitleLabel.text;
}

- (void)setSubtitle:(NSString *)subtitle
{
    self.subtitleLabel.text = subtitle;
    [self setNeedsLayout];
}

- (NSString*)title
{
    return self.titleLabel.text;
}

- (void)setTitle:(NSString *)title
{
    self.titleLabel.text = title;
    [self setNeedsLayout];
}

@end
