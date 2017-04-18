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

#import <Foundation/Foundation.h>
@import MapKit;
@import CoreLocation;

#import <FBSDKPlacesKit/FBSDKPlacesKitConstants.h>
#import "Hours.h"

@interface Place : NSObject <MKAnnotation>

@property (nonatomic, copy, readonly) NSString *placeID;

@property (nonatomic, copy, readonly) NSArray<NSString *> *categories;

@property (nonatomic, readonly) NSURL *coverPhotoURL;
@property (nonatomic, readonly) NSURL *profilePictureURL;

@property (nonatomic, copy, readonly) NSArray<Hours *> *hours;
@property (nonatomic, readonly) NSNumber *overallStarRating;


@property (nonatomic, copy, readonly) NSString *website;
@property (nonatomic, copy, readonly) NSString *phone;

@property (nonatomic, copy, readonly) NSString *city;
@property (nonatomic, copy, readonly) NSString *state;
@property (nonatomic, copy, readonly) NSString *street;
@property (nonatomic, copy, readonly) NSString *zip;

@property (nonatomic, copy, readonly) NSString *confidence;

// MKAnnotationFields
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subTitle;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end
