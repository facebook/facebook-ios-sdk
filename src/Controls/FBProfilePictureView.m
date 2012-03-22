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
#import "FBAsyncDataLoader.h"
#import "FBRequest.h"

@interface FBProfilePictureView()

@property (readonly, nonatomic) NSURL* imageGraphURL;
@property (readonly, nonatomic) NSString* imageType;

@property (retain, nonatomic) FBAsyncDataLoader* loader;
@property (retain, nonatomic) UIImageView* imageView;

- (void)refreshImage;

@end

@implementation FBProfilePictureView

@synthesize userID = _userID;
@synthesize pictureSize = _pictureSize;
@synthesize loader = _loader;
@synthesize imageView = _imageView;

#pragma mark -
#pragma mark Lifecycle

- (void)dealloc
{
    self.imageView = nil;
    self.loader = nil;

    [super dealloc];
}

- (id)init 
{
    self = [super init];
    if (self) {
        UIImageView* imageView = 
            [[UIImageView alloc] initWithFrame:self.bounds];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.autoresizingMask = 
            UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.imageView = imageView;
        [imageView release];

        self.autoresizesSubviews = true;
        self.clipsToBounds = true;
        [self addSubview:self.imageView];
    }
    
    return self;
}

- (id)initWithUserID:(NSString*)userID 
      andPictureSize:(FBProfilePictureSize)pictureSize 
{
    self = [self init];
    if (self) {
        self.pictureSize = pictureSize;
        self.userID = userID;
    }
    
    return self;
}

#pragma mark -

- (NSURL*)imageGraphURL
{
    NSString* template = @"%@/%@/picture?type=%@";     
    NSString* urlString = 
        [NSString stringWithFormat:template, 
            FBGraphBasePath,
            self.userID, 
            self.imageType];
    NSURL* url = [NSURL URLWithString:urlString];
    return url;
}

- (NSString*)imageType 
{
    switch (self.pictureSize) {
        case FBProfilePictureSizeSmall:
            return @"small";
            
        case FBProfilePictureSizeNormal:
            return @"normal";
            
        case FBProfilePictureSizeLarge:
            return @"large";
        
        default:
            return @"square";
    }
}

- (void)refreshImage 
{
    if (self.userID) {
        [self.loader cancel];
        
        FBAsyncDataHandler loadHandler = 
            ^(FBAsyncDataLoader* loader, NSError* error, NSData* data) {
                NSAssert(self.loader == loader, @"Inconsistent loader state");

                self.loader = nil;
                if (!error) {
                    self.imageView.image = [UIImage imageWithData:data];
                }
            };

        NSURL* url = self.imageGraphURL;
        FBAsyncDataLoader* loader = 
            [FBAsyncDataLoader 
                loaderWithURL:url
                handler:loadHandler
            ];
        self.loader = loader;
        [loader start];
    } else {
        NSString* blankImageName = 
            [NSString stringWithFormat:@"fb_blank_profile_%@", self.imageType];

        self.imageView.image = [UIImage imageNamed:blankImageName];
    }
}

- (void)setUserID:(NSString*)userID 
{
    if (!_userID || ![_userID isEqualToString:userID]) {
        [_userID release];
        _userID = [userID copy];
        [self refreshImage];
    }
}

- (void)setPictureSize:(FBProfilePictureSize)pictureSize 
{
    if (_pictureSize != pictureSize) {
        _pictureSize = pictureSize;
        [self refreshImage];
    }
}

@end
