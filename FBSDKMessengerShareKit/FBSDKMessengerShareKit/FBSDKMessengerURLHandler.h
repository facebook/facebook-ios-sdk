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

@class FBSDKMessengerURLHandler,
FBSDKMessengerURLHandlerReplyContext,
FBSDKMessengerURLHandlerOpenFromComposerContext,
FBSDKMessengerURLHandlerCancelContext;

@protocol FBSDKMessengerURLHandlerDelegate <NSObject>

@optional

/**
  This is called after FBSDKMessengerURLHandler has received a reply from messenger

 @param messengerURLHandler The handler that handled the URL
 @param context The data passed from Messenger
 */
- (void)messengerURLHandler:(FBSDKMessengerURLHandler *)messengerURLHandler
  didHandleReplyWithContext:(FBSDKMessengerURLHandlerReplyContext *)context;

/**
  This is called after a user tapped this app from the composer in Messenger

 @param messengerURLHandler The handler that handled the URL
 @param context The data passed from Messenger
 */
- (void)          messengerURLHandler:(FBSDKMessengerURLHandler *)messengerURLHandler
 didHandleOpenFromComposerWithContext:(FBSDKMessengerURLHandlerOpenFromComposerContext *)context;

/**
  This is called after a user canceled a share and Messenger redirected here

 @param messengerURLHandler The handler that handled the URL
 @param context The data passed from Messenger
 */
- (void)messengerURLHandler:(FBSDKMessengerURLHandler *)messengerURLHandler
 didHandleCancelWithContext:(FBSDKMessengerURLHandlerCancelContext *)context;

@end

/**

  FBSDKMessengerURLHandler is used to handle incoming URLs from Messenger.
 */
@interface FBSDKMessengerURLHandler : NSObject

/**
    Determines whether an incoming URL can be handled by this class

  @param url The URL passed in from the source application
  @param sourceApplication The bundle id representing the source application

  @return YES if this URL can be handled
 */
- (BOOL)canOpenURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication;

/**
    Attempts to handle the Messenger URL and returns YES if and only if successful.
  This should be called from the AppDelegate's -openURL: method

  @param url The URL passed in from the source application
  @param sourceApplication The bundle id representing the source application

   @return YES if this successfully handled the URL
 */
- (BOOL)openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication;

@property (nonatomic, weak) id<FBSDKMessengerURLHandlerDelegate> delegate;

@end
