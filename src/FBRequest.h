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

#import <Foundation/Foundation.h>
#import "FBRequestConnection.h"
#import "FBGraphObject.h"

// constants
extern NSString* const FBGraphBasePath;

// up-front decl's
@protocol FBRequestDelegate;
@class FBSession;

// FBRequestState is deprecated, use of it and related
// api is discouraged for new code
typedef NSUInteger FBRequestState DEPRECATED_ATTRIBUTE;

// FBRequest class
//
// Summary:
// FBRequest object is used to construct requests, and provides helper
// methods which make it simple to connect, and fetch responses
// from Facebook's graph and rest APIs. An FBSession object is required
// for all authenticated uses of FBRequest, but unauthenticated requests 
// are also supported.
// 
// Behavior notes:
// An instance of FBRequest represents the arguments and setup for a connection 
// to Facebook. At connection time, an FBRequestConnection object is created to
// manage a single connection. Class and instance methods prefixed with start*
// can be used to connect and setup with a single method. An FBRequest object
// may be used to issue multiple connections to Facebook. To cancel a connection
// use the instance method on FBRequestConnection.
//
@interface FBRequest : NSObject {
@private
    id<FBRequestDelegate> _delegate;
    NSString*             _url;
    NSURLConnection*      _connection;
    NSMutableData*        _responseText;
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
    FBRequestState        _state;
#pragma GCC diagnostic pop
    NSError*              _error;
    BOOL                  _sessionDidExpire;
    id<FBGraphObject>     _graphObject;
}

// creating a request

// init
//
// Summary:
// Following are the descriptions of the arguments along with 
// their defaults when ommitted.
//   session:              - the session object representing the identity of the
//                         Facebook user making the request; nil implies an
//                         unauthenticated request; default=nil
//   graphPath:            - specifies a path for a graph request, as well as
//                         indicates to the object to use the graph subdomain; 
//                         before start is one of graphPath or restMethod
//                         must be non-nil and the other must be nil
//   graphObject           - an object or open graph action to post
//   restMethod:           - restMethod specifies the method for a request
//                         to the deprecated Facebook rest API
//   parameters            - specifies url parameters for the request; nil
//                         implies that automatically handled parameters such as
//                         access_token should be set, but no additional
//                         parameters will be set; default=nil
//   HTTPMethod:           - indicates the HTTP method to use; nil implies GET;
//                         default=nil
//
- (id)init;

- (id)initWithSession:(FBSession*)session
            graphPath:(NSString *)graphPath;

- (id)initWithSession:(FBSession*)session
            graphPath:(NSString *)graphPath
           parameters:(NSDictionary *)parameters
           HTTPMethod:(NSString *)HTTPMethod;

- (id)initForPostWithSession:(FBSession*)session
                   graphPath:(NSString *)graphPath
                 graphObject:(id<FBGraphObject>)object;

- (id)initWithSession:(FBSession*)session
           restMethod:(NSString *)restMethod
           parameters:(NSDictionary *)parameters
           HTTPMethod:(NSString *)HTTPMethod;

// properties
//
// Summary:
// Properties may be used to read values automatically set by the object,
// as well as to set or make modifications prior to calls to start.

// instance readonly properties
@property(nonatomic, retain, readonly) NSMutableDictionary *parameters;

// instance readwrite properties
@property(nonatomic, retain) FBSession *session;
@property(nonatomic, copy) NSString *graphPath;
@property(nonatomic, copy) NSString *restMethod;
@property(nonatomic, copy) NSString *HTTPMethod;
@property(nonatomic, retain) id<FBGraphObject> graphObject;

// instance methods

// connectionWithCompletionHandler initiates a connection with Facebook
//
// Summary:
// Used to create a ready-to-start connection. The block is called in all three
// completion cases: success, error, & cancel.
//   completionHandler:    - handler block, called when the request completes
//                         with success, error, or cancel
//
- (FBRequestConnection*)connectionWithCompletionHandler:(FBRequestHandler)handler;

// class methods

// connection*
//
// Summary:
// Helper methods used to create a request and connection in a single method 
//
//   session:              - the session object representing the identity of the
//                         Facebook user making the request; nil implies an
//                         unauthenticated request; default=nil
//   graphPath:            - specifies a path for a graph request, as well as
//                         indicates to the object to use the graph subdomain; 
//                         before start is one of graphPath or restMethod
//                         must be non-nil and the other must be nil
//   parameters            - specifies url parameters for the request; nil
//                         implies that automatically handled parameters such as
//                         access_token should be set, but no additional
//                         parameters will be set; default=nil
//   HTTPMethod:           - indicates the HTTP method to use; nil implies GET;
//                         default=nil
//
+ (FBRequestConnection*)connectionWithGraphPath:(NSString*)graphPath
                                completionHandler:(FBRequestHandler)handler;

+ (FBRequestConnection*)connectionWithSession:(FBSession*)session
                                      graphPath:(NSString*)graphPath
                              completionHandler:(FBRequestHandler)handler;

+ (FBRequestConnection*)connectionForPostWithSession:(FBSession*)session
                                           graphPath:(NSString*)graphPath
                                         graphObject:(id<FBGraphObject>)object
                                   completionHandler:(FBRequestHandler)handler;

+ (FBRequestConnection*)connectionWithSession:(FBSession*)session
                                      graphPath:(NSString*)graphPath
                                     parameters:(NSDictionary*)parameters
                                     HTTPMethod:(NSString*)HTTPMethod
                              completionHandler:(FBRequestHandler)handler;

// request*
//
// Summary:
// Helper methods used to create common request objects which can be used to create single or batch connections
//
//   session:              - the session object representing the identity of the
//                         Facebook user making the request; nil implies an
//                         unauthenticated request; default=nil
+ (FBRequest*)requestForMeWithSession:(FBSession*)session;

+ (FBRequest*)requestForMyFriendsWithSession:(FBSession*)session;

+ (FBRequest *)requestForUploadPhoto:(UIImage *)photo
                             session:(FBSession *)session;

@end
