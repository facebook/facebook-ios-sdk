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

#import "FBProfilePictureView.h"
#import "FBURLConnection.h"
#import "FBRequest.h"

@interface FBProfilePictureView()

@property (readonly, nonatomic) NSString *imageSize;
@property (retain, nonatomic) NSString *previousImageSize;

@property (retain, nonatomic) FBURLConnection *connection;
@property (retain, nonatomic) UIImageView *imageView;

- (void)initialize;
- (void)refreshImage:(BOOL)forceRefresh;
- (void)ensureImageViewContentMode;

@end

@implementation FBProfilePictureView

@synthesize userID = _userID;
@synthesize pictureCropping = _pictureCropping;
@synthesize connection = _connection;
@synthesize imageView = _imageView;
@synthesize previousImageSize = _previousImageSize;

#pragma mark - Lifecycle

- (void)dealloc {
    [_userID release];
    [_imageView release];
    [_connection release];
    [_previousImageSize release];
    
    [super dealloc];
}

- (id)init {
    self = [super init];
    if (self) {
        [self initialize];
    }
    
    return self;
}

- (id)initWithUserID:(NSString *)userID 
     pictureCropping:(FBProfilePictureCropping)pictureCropping {
    self = [self init];
    if (self) {
        self.pictureCropping = pictureCropping;
        self.userID = userID;
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

#pragma mark -

- (NSString *)imageSize  {
    if (self.pictureCropping == FBProfilePictureCroppingSquare) {
        return @"square";
    } 
    
    // If we're choosing the profile picture size automatically, then
    // select an actual size to get based on the view dimensions.
    // Small profile picture is 50 pixels wide, normal is 100, and
    // large is about 200.
    CGFloat width = self.bounds.size.width;
    if (width <= 50) {
        return @"small";
    } else if (width <= 100) {
        return @"normal";
    } else {
        return @"large";
    }
}


- (void)initialize {    
    // the base class can cause virtual recursion, so
    // to handle this we make initialize idempotent
    if (self.imageView) {
        return;
    }
    
    UIImageView* imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.imageView = imageView;
    [imageView release];

    self.autoresizesSubviews = YES;
    self.clipsToBounds = YES;
        
    [self addSubview:self.imageView];
}

- (void)refreshImage:(BOOL)forceRefresh  {
    NSString *newImageSize = self.imageSize;
    
    if (self.userID) {
        
        // If not forcing refresh, check to see if the previous size we used would be the same
        // as what we'd request now, as this method could be called often on control bounds animation,
        // and we only want to fetch when needed.
        if (!forceRefresh && [self.previousImageSize isEqualToString:newImageSize]) {
            
            // But we still may need to adjust the contentMode.
            [self ensureImageViewContentMode];
            return;
        }        
        
        [self.connection cancel];

        FBURLConnectionHandler handler = 
            ^(FBURLConnection *connection, NSError *error, NSURLResponse *response, NSData *data) {
                NSAssert(self.connection == connection, @"Inconsistent connection state");

                self.connection = nil;
                if (!error) {
                    self.imageView.image = [UIImage imageWithData:data];
                    [self ensureImageViewContentMode];
                }
            };
                
        NSString *template = @"%@/%@/picture?type=%@";     
        NSString *urlString = [NSString stringWithFormat:template, 
                               FBGraphBasePath,
                               self.userID, 
                               newImageSize];
        NSURL *url = [NSURL URLWithString:urlString];
        
        self.connection = [[[FBURLConnection alloc]
                             initWithURL:url
                             completionHandler:handler] autorelease];
    } else {
        NSString *blankImageName = 
            [NSString 
                stringWithFormat:@"FBiOSSDKResources.bundle/FBProfilePictureView/images/fb_blank_profile_%@.png",
                newImageSize];

        self.imageView.image = [UIImage imageNamed:blankImageName];
        [self ensureImageViewContentMode];
    }
    
    self.previousImageSize = newImageSize;
}

- (void)ensureImageViewContentMode {
    // Set the image's contentMode such that if the image is larger than the control, we scale it down, preserving aspect 
    // ratio.  Otherwise, we center it.  This ensures that we never scale up, and pixellate, the image.
    CGSize viewSize = self.bounds.size;
    CGSize imageSize = self.imageView.image.size;
    UIViewContentMode contentMode;

    // If both of the view dimensions are larger than the image, we'll center the image to prevent scaling up.
    if (viewSize.width > imageSize.width && viewSize.height > imageSize.height) {
        contentMode = UIViewContentModeCenter;
    } else {
        contentMode = UIViewContentModeScaleAspectFit;
    }
    
    self.imageView.contentMode = contentMode;
}

- (void)setUserID:(NSString*)userID {
    if (!_userID || ![_userID isEqualToString:userID]) {
        [_userID release];
        _userID = [userID copy];
        [self refreshImage:YES];
    }
}

- (void)setPictureCropping:(FBProfilePictureCropping)pictureCropping  {
    if (_pictureCropping != pictureCropping) {
        _pictureCropping = pictureCropping;
        [self refreshImage:YES];
    }
}

// Lets us catch resizes of the control, or any outer layout, allowing us to potentially
// choose a different image.
- (void)layoutSubviews {
    [self refreshImage:NO];
    [super layoutSubviews];   
}


@end
