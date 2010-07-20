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

#import "RunViewCell.h"

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation RunViewCell

@synthesize primaryLabel = _primaryLabel,
            secondaryLabel = _secondaryLabel,
            runImageView = _runImageView;

///////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * initialization
 */
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
      // Initialization code
      _primaryLabel = [[UILabel alloc]init];
      _primaryLabel.textAlignment = UITextAlignmentLeft;
      _primaryLabel.font = [UIFont systemFontOfSize:14];
      
      _secondaryLabel = [[UILabel alloc]init];
      _secondaryLabel.textAlignment = UITextAlignmentLeft;
      _secondaryLabel.font = [UIFont systemFontOfSize:8];
      
      _runImageView = [[UIImageView alloc]init];
      
      [self.contentView addSubview:_primaryLabel];
      [self.contentView addSubview:_secondaryLabel];
      [self.contentView addSubview:_runImageView];
    }
    return self;
}

/**
 * Cell layout
 */
- (void)layoutSubviews {
  
  [super layoutSubviews];
  
  CGRect contentRect = self.contentView.bounds;
  CGFloat boundsX = contentRect.origin.x;
  
  CGRect frame;
  
  frame= CGRectMake(boundsX+10 ,0, 50, 50);
  _runImageView.frame = frame;
  
  frame= CGRectMake(boundsX+70 ,5, 200, 25);
  _primaryLabel.frame = frame;
  
  frame= CGRectMake(boundsX+70 ,30, 150, 15);
  _secondaryLabel.frame = frame;
  
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)dealloc {
  [_primaryLabel release];
  [_secondaryLabel release];
  [_runImageView release];
  [super dealloc];
}


@end
