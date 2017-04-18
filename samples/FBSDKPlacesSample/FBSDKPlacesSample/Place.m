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

#import "Place.h"

#import <FBSDKPlacesKit/FBSDKPlacesKitConstants.h>

@implementation Place

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
  self = [super init];
  if (self) {
    _title = dictionary[FBSDKPlacesFieldKeyName];
    _subTitle = dictionary[FBSDKPlacesFieldKeyAbout];

    _categories = dictionary[FBSDKPlacesFieldKeyCategories];

    NSDictionary *addressDict = dictionary[FBSDKPlacesFieldKeyLocation];
    if (addressDict) {
      _city = addressDict[FBSDKPlacesResponseKeyCity];
      _state = addressDict[FBSDKPlacesResponseKeyState];
      _street = addressDict[FBSDKPlacesResponseKeyStreet];
      _zip = addressDict[FBSDKPlacesResponseKeyZip];
      _coordinate = CLLocationCoordinate2DMake([addressDict[FBSDKPlacesResponseKeyLatitude] doubleValue],
                                               [addressDict[FBSDKPlacesResponseKeyLongitude] doubleValue]);
    }

    if (dictionary[FBSDKPlacesFieldKeyHours]) {
      _hours = [Hours hourRangesForDictionary:dictionary[FBSDKPlacesFieldKeyHours]];
    }
    _overallStarRating = dictionary[FBSDKPlacesFieldKeyOverallStarRating];
    _placeID = dictionary[FBSDKPlacesFieldKeyPlaceID];

    if (dictionary[FBSDKPlacesFieldKeyCoverPhoto]) {
      _coverPhotoURL = [NSURL URLWithString:dictionary[FBSDKPlacesFieldKeyCoverPhoto][FBSDKPlacesResponseKeyPhotoSource]];
    }

    if (dictionary[FBSDKPlacesFieldKeyProfilePhoto]) {
      _profilePictureURL = [NSURL URLWithString:dictionary[FBSDKPlacesFieldKeyProfilePhoto][FBSDKPlacesResponseKeyData][FBSDKPlacesResponseKeyUrl]];
    }

    _confidence = dictionary[FBSDKPlacesFieldKeyConfidence];
    _website = dictionary[FBSDKPlacesFieldKeyWebsite];
    _phone = dictionary[FBSDKPlacesFieldKeyPhone];
  }
  return self;
}

@end
