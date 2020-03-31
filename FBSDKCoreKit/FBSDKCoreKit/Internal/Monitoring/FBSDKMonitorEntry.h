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

NS_ASSUME_NONNULL_BEGIN

/**
 Describes any object that can provide a dictionary representation of itself
 */
@protocol FBSDKDictionaryRepresentable <NSObject>

- (NSDictionary *)dictionaryRepresentation;

@end

/**
 Describes monitor entries.

 Usage: Conform a new type of entry that is specific to the information you'd like to capture.
 For example a PerformanceMonitorEntry will conform to this so that it is Codable and can be
 easily represented as a dictionary to aid with JSON serialization.
*/
@protocol FBSDKMonitorEntry <NSObject, NSCoding, FBSDKDictionaryRepresentable>

+ (instancetype)new NS_UNAVAILABLE;
- (NSString *)name;

@end

NS_ASSUME_NONNULL_END
