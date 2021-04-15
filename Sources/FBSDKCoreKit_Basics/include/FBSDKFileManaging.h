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

/// An internal protocol used to describe a file manager
NS_SWIFT_NAME(FileManaging)
@protocol FBSDKFileManaging

- (nullable NSURL *)URLForDirectory:(NSSearchPathDirectory)directory
                  inDomain:(NSSearchPathDomainMask)domain
         appropriateForURL:(NSURL *)url
                    create:(BOOL)shouldCreate
                     error:(NSError * _Nullable *)error;

- (BOOL)createDirectoryAtPath:(NSString *)path
  withIntermediateDirectories:(BOOL)createIntermediates
                   attributes:(NSDictionary<NSFileAttributeKey, id> * _Nullable)attributes
                        error:(NSError * _Nullable *)error;

- (BOOL)fileExistsAtPath:(NSString *)path;

- (BOOL)removeItemAtPath:(NSString *)path
                   error:(NSError * _Nullable *)error;

- (NSArray<NSString *> *)contentsOfDirectoryAtPath:(NSString *)path
                                             error:(NSError * _Nullable *)error;

@end

@interface NSFileManager (FBSDKFileManaging) <FBSDKFileManaging>
@end

NS_ASSUME_NONNULL_END
