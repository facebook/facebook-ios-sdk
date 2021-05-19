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
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT s OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE."

NS_ASSUME_NONNULL_BEGIN

typedef void (^FBSDKAuthenticationTokenBlock)(FBSDKAuthenticationToken *_Nullable token)
NS_SWIFT_NAME(AuthenticationTokenBlock);

NS_SWIFT_NAME(AuthenticationTokenCreating)
@protocol FBSDKAuthenticationTokenCreating

- (void)createTokenFromTokenString:(NSString *)tokenString
                             nonce:(NSString *)nonce
                       graphDomain:(NSString *)graphDomain
                        completion:(FBSDKAuthenticationTokenBlock)completion
NS_SWIFT_NAME(createToken(tokenString:nonce:graphDomain:completion:));

@end

NS_ASSUME_NONNULL_END
