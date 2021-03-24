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

#import "FBSDKUnarchiverProvider.h"

#import "FBSDKObjectDecoder.h"

@implementation FBSDKUnarchiverProvider

+ (NSKeyedUnarchiver *)_unarchiverFor:(NSData *)data
{
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_11_0
  NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:data error:NULL];
#else
  NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
#endif
  return unarchiver;
}

+ (id<FBSDKObjectDecoding>)createSecureUnarchiverFor:(NSData *)data
{
  NSKeyedUnarchiver *unarchiver = [FBSDKUnarchiverProvider _unarchiverFor:data];
  unarchiver.requiresSecureCoding = YES;
  return [[FBSDKObjectDecoder alloc]initWith:unarchiver];
}

+ (id<FBSDKObjectDecoding>)createInsecureUnarchiverFor:(NSData *)data
{
  NSKeyedUnarchiver *unarchiver = [FBSDKUnarchiverProvider _unarchiverFor:data];
  unarchiver.requiresSecureCoding = NO;
  return [[FBSDKObjectDecoder alloc]initWith:unarchiver];
}

@end
