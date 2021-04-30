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

 #import "FBSDKContextCreateAsyncContent.h"

 #import "FBSDKCoreKitInternalImport.h"

 #define FBSDK_APP_REQUEST_CONTENT_PLAYER_ID_KEY @"playerID"
@interface FBSDKContextCreateAsyncContent () <FBSDKCopying>
@end

@implementation FBSDKContextCreateAsyncContent

 #pragma mark - FBSDKSharingValidation

- (BOOL)validateWithError:(NSError *__autoreleasing *)errorRef
{
  BOOL hasPlayerID = self.playerID.length > 0;
  if (!hasPlayerID) {
    if (errorRef != NULL) {
      NSString *message = @"The playerID is required.";
      *errorRef = [FBSDKError requiredArgumentErrorWithDomain:FBSDKErrorDomain
                                                         name:@"playerID"
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
    self.playerID.hash,
  };
  return [FBSDKMath hashWithIntegerArray:subhashes count:1];
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:[FBSDKContextCreateAsyncContent class]]) {
    return NO;
  }
  return [self isEqualToContextCreateAsyncContent:(FBSDKContextCreateAsyncContent *)object];
}

- (BOOL)isEqualToContextCreateAsyncContent:(FBSDKContextCreateAsyncContent *)content
{
  return (content
    && [FBSDKInternalUtility object:self.playerID isEqualToObject:content.playerID]);
}

 #pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  if ((self = [self init])) {
    self.playerID = [decoder decodeObjectOfClass:[NSString class] forKey:FBSDK_APP_REQUEST_CONTENT_PLAYER_ID_KEY];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:self.playerID forKey:FBSDK_APP_REQUEST_CONTENT_PLAYER_ID_KEY];
}

 #pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  FBSDKContextCreateAsyncContent *contentCopy = [FBSDKContextCreateAsyncContent new];
  contentCopy.playerID = [self.playerID copy];
  return contentCopy;
}

@end

#endif
