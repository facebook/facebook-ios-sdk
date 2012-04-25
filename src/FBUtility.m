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

@end
