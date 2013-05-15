/*
 * Copyright 2010-present Facebook.
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

@property (nonatomic, retain) UIImageView *pictureView;\
@property (nonatomic, retain) UILabel* titleSuffixLabel;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;

- (void)updateFonts;

@end

@implementation FBGraphObjectTableCell

@synthesize pictureView = _pictureView;
@synthesize titleSuffixLabel = _titleSuffixLabel;
@synthesize activityIndicator = _activityIndicator;
@synthesize boldTitle = _boldTitle;
@synthesize boldTitleSuffix = _boldTitleSuffix;

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
        self.detailTextLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.detailTextLabel.textColor = [UIColor colorWithRed:0.4 green:0.6 blue:0.8 alpha:1.0];
        self.detailTextLabel.font = [UIFont systemFontOfSize:subtitleFontHeight];
                
        // Title
        self.textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.textLabel.font = [UIFont systemFontOfSize:titleFontHeight];
        
        // Content View
        self.contentView.clipsToBounds = YES;
    }
    
    return self;
}

- (void)dealloc
{
    [_titleSuffixLabel release];
    [_pictureView release];
    
    [super dealloc];
}

#pragma mark -

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self updateFonts];
    
    BOOL hasPicture = (self.picture != nil);
    BOOL hasSubtitle = (self.subtitle != nil);
    BOOL hasTitleSuffix = (self.titleSuffix != nil);
    
    CGFloat pictureWidth = hasPicture ? pictureEdge : 0;
    CGSize cellSize = self.contentView.bounds.size;
    CGFloat textLeft = (hasPicture ? ((2 * pictureMargin) + pictureWidth) : 0) + horizontalMargin;
    CGFloat textWidth = cellSize.width - (textLeft + horizontalMargin);
    CGFloat titleTop = hasSubtitle ? titleTopWithSubtitle : titleTopNoSubtitle;
    
    self.pictureView.frame = CGRectMake(pictureMargin, pictureMargin, pictureEdge, pictureWidth);
    self.detailTextLabel.frame = CGRectMake(textLeft, subtitleTop, textWidth, subtitleHeight);
    if (!hasTitleSuffix) {
        self.textLabel.frame = CGRectMake(textLeft, titleTop, textWidth, titleHeight);
    } else {
        CGSize titleSize = [self.textLabel.text sizeWithFont:self.textLabel.font];
        CGSize spaceSize = [@" " sizeWithFont:self.textLabel.font];
        CGFloat titleWidth = titleSize.width + spaceSize.width;
        self.textLabel.frame = CGRectMake(textLeft, titleTop, titleWidth, titleHeight);
        
        CGFloat titleSuffixLeft = textLeft + titleWidth;
        CGFloat titleSuffixWidth = textWidth - titleWidth;
        self.titleSuffixLabel.frame = CGRectMake(titleSuffixLeft, titleTop, titleSuffixWidth, titleHeight);
    }
    
    [self.pictureView setHidden:!(hasPicture)];
    [self.detailTextLabel setHidden:!(hasSubtitle)];
    [self.titleSuffixLabel setHidden:!(hasTitleSuffix)];
}

+ (CGFloat)rowHeight
{
    return pictureEdge + (2 * pictureMargin) + 1;
}

- (void)startAnimatingActivityIndicator {
    CGRect cellBounds = self.bounds;
    if (!self.activityIndicator) {
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        activityIndicator.hidesWhenStopped = YES;
        activityIndicator.autoresizingMask =
        (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
        
        self.activityIndicator = activityIndicator;
        [self addSubview:activityIndicator];
        [activityIndicator release];        
    }

    self.activityIndicator.center = CGPointMake(CGRectGetMidX(cellBounds), CGRectGetMidY(cellBounds));

    [self.activityIndicator startAnimating];
}

- (void)stopAnimatingActivityIndicator {
    if (self.activityIndicator) {
        [self.activityIndicator stopAnimating];
    }
}

- (void)updateFonts {
    if (self.boldTitle) {
        self.textLabel.font = [UIFont boldSystemFontOfSize:titleFontHeight];
    } else {
        self.textLabel.font = [UIFont systemFontOfSize:titleFontHeight];
    }

    if (self.boldTitleSuffix) {
        self.titleSuffixLabel.font = [UIFont boldSystemFontOfSize:titleFontHeight];
    } else {
        self.titleSuffixLabel.font = [UIFont systemFontOfSize:titleFontHeight];
    }
}

- (void)createTitleSuffixLabel {
    if (!self.titleSuffixLabel) {
        UILabel *titleSuffixLabel = [[UILabel alloc] init];
        titleSuffixLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self.contentView addSubview:titleSuffixLabel];

        self.titleSuffixLabel = titleSuffixLabel;
        [titleSuffixLabel release];
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
    return self.detailTextLabel.text;
}

- (void)setSubtitle:(NSString *)subtitle
{
    self.detailTextLabel.text = subtitle;
    [self setNeedsLayout];
}

- (NSString*)title
{
    return self.textLabel.text;
}

- (void)setTitle:(NSString *)title
{
    self.textLabel.text = title;
    [self setNeedsLayout];
}

- (NSString*)titleSuffix
{
    return self.titleSuffixLabel.text;
}

- (void)setTitleSuffix:(NSString *)titleSuffix
{
    if (titleSuffix) {
        [self createTitleSuffixLabel];
    }
    if (self.titleSuffixLabel) {
        self.titleSuffixLabel.text = titleSuffix;
    }
    [self setNeedsLayout];
}

@end
