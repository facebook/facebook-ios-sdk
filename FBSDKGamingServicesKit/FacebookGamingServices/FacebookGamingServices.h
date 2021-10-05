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

#import <FacebookGamingServices/FBSDKChooseContextDialog.h>
#import <FacebookGamingServices/FBSDKContextWebDialog.h>
#import <FacebookGamingServices/FBSDKCreateContextContent.h>
#import <FacebookGamingServices/FBSDKCreateContextDialog.h>
#import <FacebookGamingServices/FBSDKDialogProtocol.h>
#import <FacebookGamingServices/FBSDKFriendFinderDialog.h>
#import <FacebookGamingServices/FBSDKGamingContext.h>
#import <FacebookGamingServices/FBSDKGamingGroupIntegration.h>
#import <FacebookGamingServices/FBSDKGamingImageUploader.h>
#import <FacebookGamingServices/FBSDKGamingImageUploaderConfiguration.h>
#import <FacebookGamingServices/FBSDKGamingPayload.h>
#import <FacebookGamingServices/FBSDKGamingPayloadObserver.h>
#import <FacebookGamingServices/FBSDKGamingServiceCompletionHandler.h>
#import <FacebookGamingServices/FBSDKGamingVideoUploader.h>
#import <FacebookGamingServices/FBSDKGamingVideoUploaderConfiguration.h>
#import <FacebookGamingServices/FBSDKSwitchContextContent.h>

// The headers below need to be public since they're used in the Swift files
// but they probably shouldn't be actually public.
// Not sure what the correct approach here is...

#import <FacebookGamingServices/FBSDKChooseContextDialogFactory.h>
#import <FacebookGamingServices/FBSDKContextDialogFactoryProtocols.h>
#import <FacebookGamingServices/FBSDKContextDialogs+Showable.h>
#import <FacebookGamingServices/FBSDKCreateContextDialogFactory.h>
#import <FacebookGamingServices/FBSDKShowable.h>
