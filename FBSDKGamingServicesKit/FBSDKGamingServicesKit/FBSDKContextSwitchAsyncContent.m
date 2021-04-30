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

#import "TargetConditionals.h"

#if !TARGET_OS_TV

 #import "FBSDKContextSwitchAsyncContent.h"

 #import "FBSDKCoreKitInternalImport.h"

 #define FBSDK_APP_REQUEST_CONTENT_CONTEXT_TOKEN_KEY @"contextToken"

@interface FBSDKContextSwitchAsyncContent () <FBSDKCopying>
@end

@implementation FBSDKContextSwitchAsyncContent

 #pragma mark - FBSDKSharingValidation

- (BOOL)validateWithError:(NSError *__autoreleasing *)errorRef
{
  BOOL hasContextToken = self.contextToken.length > 0;
  if (!hasContextToken) {
    if (errorRef != NULL) {
      NSString *message = @"The contextToken is required.";
      *errorRef = [FBSDKError requiredArgumentErrorWithDomain:FBSDKErrorDomain
                                                         name:@"contextToken"
                                                      message:message];
    }
    return NO;
  }
  return YES;
}

 #pragma mark - Equality

- (NSUInteger)hash
{
  NSUInteger subhashes[] = {
    self.contextToken.hash,
  };
  return [FBSDKMath hashWithIntegerArray:subhashes count:sizeof(subhashes) / sizeof(subhashes[0])];
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:[FBSDKContextSwitchAsyncContent class]]) {
    return NO;
  }
  return [self isEqualToContextSwitchAsyncContent:(FBSDKContextSwitchAsyncContent *)object];
}

- (BOOL)isEqualToContextSwitchAsyncContent:(FBSDKContextSwitchAsyncContent *)content
{
  return (content
    && [FBSDKInternalUtility object:self.contextToken isEqualToObject:content.contextToken]);
}

 #pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  if ((self = [self init])) {
    self.contextToken = [decoder decodeObjectOfClass:[NSString class] forKey:FBSDK_APP_REQUEST_CONTENT_CONTEXT_TOKEN_KEY];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:self.contextToken forKey:FBSDK_APP_REQUEST_CONTENT_CONTEXT_TOKEN_KEY];
}

 #pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  FBSDKContextSwitchAsyncContent *copy = [FBSDKContextSwitchAsyncContent new];
  copy.contextToken = [self.contextToken copy];
  return copy;
}

@end

#endif
