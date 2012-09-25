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

#import "FBUtility.h"
#import "FBGraphObject.h"
#import "FBRequest.h"
#import "FBSBJSON.h"
#import "FBSession.h"
#include <sys/time.h>

@implementation FBUtility

// finishes the parsing job that NSURL starts
+ (NSDictionary*)dictionaryByParsingURLQueryPart:(NSString *)encodedString {
    
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    NSArray *parts = [encodedString componentsSeparatedByString:@"&"];
    
    for (NSString *part in parts) {
        if ([part length] == 0) {
            continue;
        }
        
        NSRange index = [part rangeOfString:@"="];
        NSString *key;
        NSString *value;
        
        if (index.location == NSNotFound) {
            key = part;
            value = @"";
        } else {
            key = [part substringToIndex:index.location];
            value = [part substringFromIndex:index.location + index.length];
        }
        
        if (key && value) {
            [result setObject:[FBUtility stringByURLDecodingString:value]
                       forKey:[FBUtility stringByURLDecodingString:key]];
        }
    }
    return result;
}

// the reverse of url encoding
+ (NSString*)stringByURLDecodingString:(NSString*)escapedString {
    return [[escapedString stringByReplacingOccurrencesOfString:@"+" withString:@" "]
            stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

+ (NSString*)stringByURLEncodingString:(NSString*)unescapedString {
    NSString* result = (NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                           kCFAllocatorDefault,
                                                                           (CFStringRef)unescapedString,
                                                                           NULL, // characters to leave unescaped
                                                                           (CFStringRef)@":!*();@/&?#[]+$,='%’\"",
                                                                           kCFStringEncodingUTF8);
    [result autorelease];
    return result;
}

+ (unsigned long)currentTimeInMilliseconds {
    struct timeval time; 
    gettimeofday(&time, NULL); 
    return (time.tv_sec * 1000) + (time.tv_usec / 1000);
}

+ (NSTimeInterval)randomTimeInterval:(NSTimeInterval)minValue withMaxValue:(NSTimeInterval)maxValue {
    return minValue + (maxValue - minValue) * (double)arc4random() / UINT32_MAX;
}

+ (id<FBGraphObject>)graphObjectInArray:(NSArray*)array withSameIDAs:(id<FBGraphObject>)item {
    for (id<FBGraphObject> obj in array) {
        if ([FBGraphObject isGraphObjectID:obj sameAs:item]) {
            return obj;
        }
    }
    return nil;
}

// The assumption here is that the view and the tableView share a common parent.
+ (void)centerView:(UIView*)view tableView:(UITableView*)tableView {
    // We want to center the view in the table  as much as possible, but we also want to center it
    // within a cell so it is visually appealing.
    CGRect bounds = tableView.bounds;
    CGPoint center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    
    CGFloat rowHeight = tableView.rowHeight;
    int numRows = bounds.size.height / rowHeight;
    int centerRow = numRows / 2;
    center.y = rowHeight * centerRow + rowHeight / 2;
    
    center = [view.superview convertPoint:center fromView:tableView];
    view.center = center;
}

+ (NSString *)stringFBIDFromObject:(id)object {
    if ([object isKindOfClass:[NSDictionary class]]) {
        id val = [object objectForKey:@"id"];
        if ([val isKindOfClass:[NSString class]]) {
            return val;
        }
    }
    return [object description];
}

+ (NSBundle *)facebookSDKBundle {
    static dispatch_once_t fetchBundleOnce;
    static NSBundle *bundle = nil;
    
    dispatch_once(&fetchBundleOnce, ^{
        NSString *path = [[NSBundle mainBundle] pathForResource:@"FacebookSDKResources"
                                                         ofType:@"bundle"];
        bundle = [NSBundle bundleWithPath:path];
    });
    return bundle;
}

+ (NSString *)localizedStringForKey:(NSString *)key
                        withDefault:(NSString *)value {
    return [self localizedStringForKey:key withDefault:value inBundle:FBUtility.facebookSDKBundle];
}

+ (NSString *)localizedStringForKey:(NSString *)key
                        withDefault:(NSString *)value
                           inBundle:(NSBundle *)bundle {
    NSString *result = value;
    if (bundle) {
        result = [bundle localizedStringForKey:key
                                         value:value
                                         table:nil];
    }
    return result;
}

@end
