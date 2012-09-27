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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class FBSession;

@protocol FBGraphObject;

@interface FBUtility : NSObject

+ (NSDictionary*)dictionaryByParsingURLQueryPart:(NSString *)encodedString;
+ (NSString *)stringByURLDecodingString:(NSString*)escapedString;
+ (NSString*)stringByURLEncodingString:(NSString*)unescapedString;
+ (id<FBGraphObject>)graphObjectInArray:(NSArray*)array withSameIDAs:(id<FBGraphObject>)item;

+ (unsigned long)currentTimeInMilliseconds;
+ (NSTimeInterval)randomTimeInterval:(NSTimeInterval)minValue withMaxValue:(NSTimeInterval)maxValue;
+ (void)centerView:(UIView*)view tableView:(UITableView*)tableView;
+ (NSString *)stringFBIDFromObject:(id)object;

+ (NSBundle *)facebookSDKBundle;
+ (NSString *)localizedStringForKey:(NSString *)key
                        withDefault:(NSString *)value;
+ (NSString *)localizedStringForKey:(NSString *)key
                        withDefault:(NSString *)value
                           inBundle:(NSBundle *)bundle;

@end
 
#define FBConditionalLog(condition, desc, ...) \
do { \
    if (!(condition)) {	\
        NSString *msg = [NSString stringWithFormat:(desc), ##__VA_ARGS__]; \
        NSLog(@"FBConditionalLog: %@", msg); \
    } \
} while(NO)
 
#define FB_BASE_URL @"facebook.com"



