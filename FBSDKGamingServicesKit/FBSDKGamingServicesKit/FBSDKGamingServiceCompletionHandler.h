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
#import <AvailabilityMacros.h>

/**
 Main completion handling of any Gaming Service (Friend Finder, Image/Video Upload).

 @param success whether the call to the service was considered a success.
 @param error the error that occured during the service call, if any.
 */
typedef void (^FBSDKGamingServiceCompletionHandler)(BOOL success, NSError * _Nullable error)
NS_SWIFT_NAME(GamingServiceCompletionHandler);

/**
Main completion handling of any Gaming Service (Friend Finder, Image/Video Upload).

@param success whether the call to the service was considered a success.
@param result the result that was returned by the service, if any.
@param error the error that occured during the service call, if any.
*/
typedef void (^FBSDKGamingServiceResultCompletionHandler)(BOOL success, NSString * _Nullable result, NSError * _Nullable error)
NS_SWIFT_NAME(GamingServiceCompletionHandler);

/**
Main completion handling of any Gaming Service (Friend Finder, Image/Video Upload).

@param bytesSent the number of bytes sent since the last invocation
@param totalBytesSent the total number of bytes sent
@param totalBytesExpectedToSend the number of bytes that remain to be sent
*/
typedef void (^FBSDKGamingServiceProgressHandler)(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend)
NS_SWIFT_NAME(GamingServiceProgressHandler);
