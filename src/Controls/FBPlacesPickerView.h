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

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "FBSession.h"

@class FBPlacesPickerView;

@protocol FBPlacesPickerActionDelegate <NSObject>

@required

// Informs the delegate that a place has been picked
- (void) placesPicker:(FBPlacesPickerView*)placesPicker
    didPickPlace:(NSDictionary*)place;

@end


@interface FBPlacesPickerView : UIView

@property (retain, nonatomic) FBSession* session;
@property (copy, nonatomic) NSString* searchText;
@property (assign, nonatomic) NSInteger maxCount;
@property (assign, nonatomic) NSInteger radius;
@property (assign, nonatomic) CLLocationCoordinate2D locationCoordinate;

@property (assign, nonatomic) id<FBPlacesPickerActionDelegate> delegate;

// inits and returns a FBPlacesPickerView
//
// Summary:
//  Initializes the Places picker with a valid session, a location coordinate
//  and a search text that will be used to filter the places.
- (id)init;
- (id)initWithSession:(FBSession*)session;
- (id)initWithSession:(FBSession*)session
             location:(CLLocationCoordinate2D)location
           searchText:(NSString*)searchText;

- (void)loadData;

@end