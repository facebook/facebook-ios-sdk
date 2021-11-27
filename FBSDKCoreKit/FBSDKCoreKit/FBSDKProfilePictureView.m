/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKProfilePictureView.h"
#import "FBSDKProfilePictureView+Internal.h"

#import "FBSDKAccessToken.h"
#import "FBSDKHumanSilhouetteIcon.h"
#import "FBSDKInternalUtility+Internal.h"
#import "FBSDKMath.h"
#import "FBSDKProfile+Internal.h"

@interface FBSDKProfilePictureViewState : NSObject

- (instancetype)initWithProfileID:(NSString *)profileID
                             size:(CGSize)size
                            scale:(CGFloat)scale
                      pictureMode:(FBSDKProfilePictureMode)pictureMode
                   imageShouldFit:(BOOL)imageShouldFit;

@property (nonatomic, readonly, assign) BOOL imageShouldFit;
@property (nonatomic, readonly, assign) FBSDKProfilePictureMode pictureMode;
@property (nonatomic, readonly, copy) NSString *profileID;
@property (nonatomic, readonly, assign) CGFloat scale;
@property (nonatomic, readonly, assign) CGSize size;

- (BOOL)isEqualToState:(FBSDKProfilePictureViewState *)other;
- (BOOL)isValidForState:(FBSDKProfilePictureViewState *)other;

@end

@implementation FBSDKProfilePictureViewState

- (instancetype)initWithProfileID:(NSString *)profileID
                             size:(CGSize)size
                            scale:(CGFloat)scale
                      pictureMode:(FBSDKProfilePictureMode)pictureMode
                   imageShouldFit:(BOOL)imageShouldFit
{
  if ((self = [super init])) {
    _profileID = [profileID copy];
    _size = size;
    _scale = scale;
    _pictureMode = pictureMode;
    _imageShouldFit = imageShouldFit;
  }
  return self;
}

- (NSUInteger)hash
{
  NSUInteger subhashes[] = {
    (NSUInteger)_imageShouldFit,
    (NSUInteger)_size.width,
    (NSUInteger)_size.height,
    (NSUInteger)_scale,
    (NSUInteger)_pictureMode,
    _profileID.hash,
  };
  return [FBSDKMath hashWithIntegerArray:subhashes count:sizeof(subhashes) / sizeof(subhashes[0])];
}

- (BOOL)isEqual:(id)object
{
  if (![object isKindOfClass:FBSDKProfilePictureViewState.class]) {
    return NO;
  }
  FBSDKProfilePictureViewState *other = (FBSDKProfilePictureViewState *)object;
  return [self isEqualToState:other];
}

- (BOOL)isEqualToState:(FBSDKProfilePictureViewState *)other
{
  return ([self isValidForState:other]
    && CGSizeEqualToSize(_size, other->_size)
    && (_scale == other->_scale));
}

- (BOOL)isValidForState:(FBSDKProfilePictureViewState *)other
{
  return (other != nil
    && (_imageShouldFit == other->_imageShouldFit)
    && (_pictureMode == other->_pictureMode)
    && [FBSDKInternalUtility.sharedUtility object:_profileID isEqualToObject:other->_profileID]);
}

@end

@interface FBSDKProfilePictureView ()

@property (nonatomic) BOOL hasProfileImage;
@property (nonatomic) UIImageView *imageView;
@property (nonatomic) FBSDKProfilePictureViewState *lastState;
@property (nonatomic) BOOL needsImageUpdate;
@property (nonatomic) BOOL placeholderImageIsValid;

@end

@implementation FBSDKProfilePictureView

#pragma mark - Object Lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
  if ((self = [super initWithFrame:frame])) {
    [self configureProfilePictureView];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  if ((self = [super initWithCoder:decoder])) {
    [self configureProfilePictureView];
  }
  return self;
}

- (instancetype)initWithFrame:(CGRect)frame
                      profile:(FBSDKProfile *)profile
{
  if ((self = [super initWithFrame:frame])) {
    _profileID = [profile.userID copy];

    [self setNeedsImageUpdate];
  }
  return self;
}

- (instancetype)initWithProfile:(FBSDKProfile *)profile
{
  return [self initWithFrame:CGRectZero profile:profile];
}

#pragma mark - Properties

- (void)setBounds:(CGRect)bounds
{
  dispatch_async(dispatch_get_main_queue(), ^{
    CGRect currentBounds = self.bounds;
    if (!CGRectEqualToRect(currentBounds, bounds)) {
      super.bounds = bounds;
      if (!CGSizeEqualToSize(currentBounds.size, bounds.size)) {
        self->_placeholderImageIsValid = NO;
        [self setNeedsImageUpdate];
      }
    }
  });
}

- (UIViewContentMode)contentMode
{
  return _imageView.contentMode;
}

- (void)setContentMode:(UIViewContentMode)contentMode
{
  if (_imageView.contentMode != contentMode) {
    _imageView.contentMode = contentMode;
    super.contentMode = contentMode;
    [self setNeedsImageUpdate];
  }
}

- (void)setMode:(FBSDKProfilePictureMode)pictureMode
{
  if (_pictureMode != pictureMode) {
    _pictureMode = pictureMode;
    [self setNeedsImageUpdate];
  }
}

- (void)setProfileID:(NSString *)profileID
{
  if (![FBSDKInternalUtility.sharedUtility object:_profileID isEqualToObject:profileID]) {
    _profileID = [profileID copy];
    _placeholderImageIsValid = NO;
    [self setNeedsImageUpdate];
  }
}

#pragma mark - Public Methods

- (void)setNeedsImageUpdate
{
  dispatch_async(dispatch_get_main_queue(), ^{
    if (!self->_imageView || CGRectIsEmpty(self.bounds)) {
      // we can't do anything with an empty view, so just bail out until we have a size
      return;
    }

    // ensure that we have an image.  do this here so we can draw the placeholder image synchronously if we don't have one
    if (!self->_placeholderImageIsValid && !self->_hasProfileImage) {
      [self _setPlaceholderImage];
    }

    // debounce calls to needsImage against the main runloop
    if (self->_needsImageUpdate) {
      return;
    }
    self->_needsImageUpdate = YES;
    [self _updateImage];
  });
}

#pragma mark - Internal Methods

- (void)configureProfilePictureView
{
  _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
  _imageView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
  [self addSubview:_imageView];

  _profileID = @"me";
  self.backgroundColor = UIColor.whiteColor;
  self.contentMode = UIViewContentModeScaleAspectFit;
  self.userInteractionEnabled = NO;
  [NSNotificationCenter.defaultCenter addObserver:self
                                         selector:@selector(_accessTokenDidChangeNotification:)
                                             name:FBSDKAccessTokenDidChangeNotification
                                           object:nil];
  [NSNotificationCenter.defaultCenter addObserver:self
                                         selector:@selector(_profileDidChangeNotification:)
                                             name:FBSDKProfileDidChangeNotification
                                           object:nil];
}

#pragma mark - Notifications

- (void)_accessTokenDidChangeNotification:(NSNotification *)notification
{
  if (![_profileID isEqualToString:@"me"] || !notification.userInfo[FBSDKAccessTokenDidChangeUserIDKey]) {
    return;
  }
  _lastState = nil;
  [self _updateImageWithAccessToken];
}

- (void)_profileDidChangeNotification:(NSNotification *)notification
{
  if (![_profileID isEqualToString:@"me"]) {
    return;
  }
  _lastState = nil;
  [self _updateImageWithProfile];
}

#pragma mark - Image Update

- (void)_updateImageWithProfile
{
  if (!_profileID) {
    if (!_placeholderImageIsValid) {
      [self _setPlaceholderImage];
    }
    return;
  }

  // if the current image is no longer representative of the current state, clear the current value out; otherwise,
  // leave the current value until the new resolution image is downloaded
  FBSDKProfilePictureViewState *state = [self _state];
  if (![_lastState isValidForState:state]) {
    [self _setPlaceholderImage];
  }

  FBSDKProfile *profile = FBSDKProfile.currentProfile;
  if (![state.profileID isEqualToString:@"me"] || !profile.imageURL) {
    return;
  }
  _lastState = state;

  [self _fetchAndSetImageWithURL:profile.imageURL state:state];
}

- (void)_updateImageWithAccessToken
{
  if (!_profileID) {
    if (!_placeholderImageIsValid) {
      [self _setPlaceholderImage];
    }
    return;
  }

  // if the current image is no longer representative of the current state, clear the current value out; otherwise,
  // leave the current value until the new resolution image is downloaded
  FBSDKProfilePictureViewState *state = [self _state];
  if (![_lastState isValidForState:state]) {
    [self _setPlaceholderImage];
  }

  if ([state.profileID isEqualToString:@"me"] && !FBSDKAccessToken.currentAccessTokenIsActive) {
    return;
  }
  _lastState = state;

  [self _fetchAndSetImageWithURL:[self _getProfileImageUrl:state] state:state];
}

- (void)_fetchAndSetImageWithURL:(NSURL *)imageURL state:(FBSDKProfilePictureViewState *)state
{
  __weak FBSDKProfilePictureView *weakSelf = self;
  NSURLRequest *request = [[NSURLRequest alloc] initWithURL:imageURL];
  NSURLSession *session = NSURLSession.sharedSession;
  [[session
    dataTaskWithRequest:request
    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
      if (!error && data.length) {
        [weakSelf _updateImageWithData:data state:state];
      }
    }] resume];
}

- (void)_updateImage
{
  _needsImageUpdate = NO;
  if (![_profileID isEqualToString:@"me"] || FBSDKAccessToken.currentAccessTokenIsActive) {
    [self _updateImageWithAccessToken];
  } else if (FBSDKProfile.currentProfile.imageURL) {
    [self _updateImageWithProfile];
  }
}

- (BOOL)_imageShouldFit
{
  switch (self.contentMode) {
    case UIViewContentModeBottom:
    case UIViewContentModeBottomLeft:
    case UIViewContentModeBottomRight:
    case UIViewContentModeCenter:
    case UIViewContentModeLeft:
    case UIViewContentModeRedraw:
    case UIViewContentModeRight:
    case UIViewContentModeScaleAspectFit:
    case UIViewContentModeTop:
    case UIViewContentModeTopLeft:
    case UIViewContentModeTopRight:
      return YES;
    case UIViewContentModeScaleAspectFill:
    case UIViewContentModeScaleToFill:
      return NO;
  }
}

- (CGSize)_imageSize:(BOOL)imageShouldFit scale:(CGFloat)scale
{
  // get the image size based on the contentMode and pictureMode
  CGSize size = self.bounds.size;
  switch (_pictureMode) {
    case FBSDKProfilePictureModeSquare: {
      CGFloat imageSize;
      if (imageShouldFit) {
        imageSize = MIN(size.width, size.height);
      } else {
        imageSize = MAX(size.width, size.height);
      }
      size = CGSizeMake(imageSize, imageSize);
      break;
    }
    case FBSDKProfilePictureModeNormal:
    case FBSDKProfilePictureModeAlbum:
    case FBSDKProfilePictureModeSmall:
    case FBSDKProfilePictureModeLarge:
      // use the bounds size
      break;
  }

  // adjust for the screen scale
  size = CGSizeMake(size.width * scale, size.height * scale);

  return size;
}

- (FBSDKProfilePictureViewState *)_state
{
  BOOL imageShouldFit = [self _imageShouldFit];
  UIScreen *screen = self.window.screen ?: [UIScreen mainScreen];
  CGFloat scale = screen.scale;
  CGSize imageSize = [self _imageSize:imageShouldFit scale:scale];
  return [[FBSDKProfilePictureViewState alloc] initWithProfileID:_profileID
                                                            size:imageSize
                                                           scale:scale
                                                     pictureMode:_pictureMode
                                                  imageShouldFit:imageShouldFit];
}

- (NSURL *)_getProfileImageUrl:(FBSDKProfilePictureViewState *)state
{
  // If there's an existing profile, use that profile's image url handler
  if (FBSDKProfile.currentProfile != nil) {
    return [FBSDKProfile.currentProfile imageURLForPictureMode:self.pictureMode size:state.size];
  } else {
    return [FBSDKProfile imageURLForProfileID:state.profileID pictureMode:self.pictureMode size:state.size];
  }
}

- (void)_setPlaceholderImage
{
  UIColor *fillColor = [UIColor colorWithRed:157.0 / 255.0 green:177.0 / 255.0 blue:204.0 / 255.0 alpha:1.0];
  _placeholderImageIsValid = YES;
  _hasProfileImage = NO;

  dispatch_async(dispatch_get_main_queue(), ^{
    self->_imageView.image = [[FBSDKHumanSilhouetteIcon new] imageWithSize:self->_imageView.bounds.size
                                                                     color:fillColor];
  });
}

- (void)_updateImageWithData:(NSData *)data state:(FBSDKProfilePictureViewState *)state
{
  // make sure we haven't updated the state since we began fetching the image
  if (![state isValidForState:_lastState]) {
    return;
  }

  UIImage *image = [[UIImage alloc] initWithData:data scale:state.scale];
  if (image) {
    _hasProfileImage = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
      self->_imageView.image = image;
    });
  } else {
    _hasProfileImage = NO;
    _placeholderImageIsValid = NO;
    [self setNeedsImageUpdate];
  }
}

#pragma mark - Test Helpers

- (FBSDKProfilePictureViewState *)lastState
{
  return _lastState;
}

@end

#endif
