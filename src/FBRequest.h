/*
 * Copyright 2012 Facebook
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "FBRequestConnection.h"
#import "FBGraphObject.h"

/*! The base URL used for graph requests */
extern NSString* const FBGraphBasePath;

// up-front decl's
@protocol FBRequestDelegate;
@class FBSession;

/*!
 @typedef FBRequestState

 @abstract
 Deprecated - do not use in new code.

 @discussion
 FBRequestState is retained from earlier versions of the SDK to give existing
 apps time to remove dependency on this.

 @deprecated
*/
typedef NSUInteger FBRequestState __attribute__((deprecated));

/*!
 @class FBRequest

 @abstract
 FBRequest object is used to construct requests, and provides helper
 methods which make it simple to connect, and fetch responses
 from Facebook's graph and rest APIs.

 @discussion
 An FBSession object is required
 for all authenticated uses of FBRequest, but unauthenticated requests 
 are also supported.

 An instance of FBRequest represents the arguments and setup for a connection 
 to Facebook. At connection time, an FBRequestConnection object is created to
 manage a single connection. Class and instance methods prefixed with start*
 can be used to connect and setup with a single method. An FBRequest object
 may be used to issue multiple connections to Facebook. To cancel a connection
 use the instance method on FBRequestConnection.

 @unsorted
*/
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

/*!
 @methodgroup Creating a request

 @method

 @seealso initWithSession:graphPath:parameters:HTTPMethod:
*/
- (id)init;

/*!
 @method

 @seealso initWithSession:graphPath:parameters:HTTPMethod:
*/
- (id)initWithSession:(FBSession*)session
            graphPath:(NSString *)graphPath;

/*!
 @method

 @abstract
 Initialize a FBRequest object that will do a graph request.

 @discussion
 Note that this only sets properties on the FBRequest.

 To send the request, initialize a FBRequestConnection, add this request,
 and send start to the FBRequestConnection.  See other methods on this
 class for shortcuts to simplify this process.

 @param session          the session object representing the identity of the
                         Facebook user making the request; nil implies an
                         unauthenticated request; default=nil

 @param graphPath        specifies a path for a graph request, as well as
                         indicates to the object to use the graph subdomain; 
                         before start is one of graphPath or restMethod
                         must be non-nil and the other must be nil

 @param parameters       specifies url parameters for the request; nil
                         implies that automatically handled parameters such as
                         access_token should be set, but no additional
                         parameters will be set; default=nil

 @param HTTPMethod       indicates the HTTP method to use; nil implies GET;
                         default=nil
*/
- (id)initWithSession:(FBSession*)session
            graphPath:(NSString *)graphPath
           parameters:(NSDictionary *)parameters
           HTTPMethod:(NSString *)HTTPMethod;

/*!
 @method
 @abstract
 Initialize a FBRequest object that will do a graph request.

 @discussion
 Note that this only sets properties on the FBRequest.

 To send the request, initialize a FBRequestConnection, add this request,
 and send start to the FBRequestConnection.  See other methods on this
 class for shortcuts to simplify this process.

 @param session          the session object representing the identity of the
                         Facebook user making the request; nil implies an
                         unauthenticated request; default=nil

 @param graphPath        specifies a path for a graph request, as well as
                         indicates to the object to use the graph subdomain; 
                         before start is one of graphPath or restMethod
                         must be non-nil and the other must be nil

 @param graphObject      an object or open graph action to post
*/
- (id)initForPostWithSession:(FBSession*)session
                   graphPath:(NSString *)graphPath
                 graphObject:(id<FBGraphObject>)object;

/*!
 @method
 @abstract
 Initialize a FBRequest object that will do a rest API request.

 @discussion
 Prefer to use graph requests instead of this where possible.

 Note that this only sets properties on the FBRequest.

 To send the request, initialize a FBRequestConnection, add this request,
 and send start to the FBRequestConnection.  See other methods on this
 class for shortcuts to simplify this process.

 @param session          the session object representing the identity of the
                         Facebook user making the request; nil implies an
                         unauthenticated request; default=nil

 @param restMethod       restMethod specifies the method for a request
                         to the deprecated Facebook rest API

 @param parameters       specifies url parameters for the request; nil
                         implies that automatically handled parameters such as
                         access_token should be set, but no additional
                         parameters will be set; default=nil

 @param HTTPMethod       indicates the HTTP method to use; nil implies GET;
                         default=nil
*/
- (id)initWithSession:(FBSession*)session
           restMethod:(NSString *)restMethod
           parameters:(NSDictionary *)parameters
           HTTPMethod:(NSString *)HTTPMethod;

/*!
 @abstract
 Parameters to the request

 @discussion
 May be used to read values automatically set during initialization,
 as well as to set or make modifications prior to sending the request.

 NSString parameters are used to generate URL parameter values or JSON
 parameters.  NSData and UIImage parameters are added as attachments
 to the HTTP body and referenced by name in the URL and/or JSON.
*/
@property(nonatomic, retain, readonly) NSMutableDictionary *parameters;

/*!
 @abstract
 Session to use for the request

 @discussion
 May be used to read values automatically set during initialization,
 as well as to set or make modifications prior to sending the request.
*/
@property(nonatomic, retain) FBSession *session;

/*!
 @abstract
 URL suffix to use for the graph request, such as "me".

 @discussion
 May be used to read values automatically set during initialization,
 as well as to set or make modifications prior to sending the request.
*/
@property(nonatomic, copy) NSString *graphPath;

/*!
 @abstract
 URL suffix to use for the rest request.

 @discussion
 May be used to read values automatically set during initialization,
 as well as to set or make modifications prior to sending the request.

 Prefer graphPath where possible.
*/
@property(nonatomic, copy) NSString *restMethod;

/*!
 @abstract
 HTTPMethod to use for the request, such as "GET" or "POST".

 @discussion
 May be used to read values automatically set during initialization,
 as well as to set or make modifications prior to sending the request.
*/
@property(nonatomic, copy) NSString *HTTPMethod;

/*!
 @abstract
 Graph object to post in the request.

 @discussion
 May be used to read values automatically set during initialization,
 as well as to set or make modifications prior to sending the request.
*/
@property(nonatomic, retain) id<FBGraphObject> graphObject;

/*!
 @methodgroup Instance methods
*/

/*!
 @method

 @abstract
 initiates a connection with Facebook

 @discussion
 Used to create a ready-to-start connection. The block is called in all three
 completion cases: success, error, & cancel.

 @param completionHandler   handler block, called when the request completes
                            with success, error, or cancel
*/
- (FBRequestConnection*)connectionWithCompletionHandler:(FBRequestHandler)handler;

/*!
 @methodgroup FBRequestConnection factory methods

 @abstract
 These methods initialize a FBRequestConnection.  All that remains is to call start.

 @discussion
 These simplify the process of preparing a request to send.  These
 handle the steps of initializing a FBRequest, initializing a
 FBRequestConnection, and adding the FBRequest to the
 FBRequestConnection.

 Note that these methods do not call start on the returned
 FBRequestConnection.  The application must still call start to send
 the request.
*/

/*!
 @method

 @abstract
 Creates and links a FBRequest and FBRequestConnection, ready to start.

 @seealso connectionWithSession:graphPath:parameters:HTTPMethod:handler:
*/
+ (FBRequestConnection*)connectionWithGraphPath:(NSString*)graphPath
                                completionHandler:(FBRequestHandler)handler;

/*!
 @method

 @abstract
 Creates and links a FBRequest and FBRequestConnection, ready to start.

 @seealso connectionWithSession:graphPath:parameters:HTTPMethod:handler:
*/
+ (FBRequestConnection*)connectionWithSession:(FBSession*)session
                                      graphPath:(NSString*)graphPath
                              completionHandler:(FBRequestHandler)handler;

/*!
 @method

 @abstract
 Creates and links a FBRequest and FBRequestConnection, ready to start.


 @param session          the session object representing the identity of the
                         Facebook user making the request; nil implies an
                         unauthenticated request; default=nil

 @param graphPath        specifies a path for a graph request, as well as
                         indicates to the object to use the graph subdomain; 
                         before start is one of graphPath or restMethod
                         must be non-nil and the other must be nil

 @param graphObject      an object or open graph action to post

 @param handler          handler block, called when the request completes
                         with success, error, or cancel
*/
+ (FBRequestConnection*)connectionForPostWithSession:(FBSession*)session
                                           graphPath:(NSString*)graphPath
                                         graphObject:(id<FBGraphObject>)object
                                   completionHandler:(FBRequestHandler)handler;

/*!
 @method

 @abstract
 Creates and links a FBRequest and FBRequestConnection, ready to start.

 @param session          the session object representing the identity of the
                         Facebook user making the request; nil implies an
                         unauthenticated request; default=nil

 @param graphPath        specifies a path for a graph request, as well as
                         indicates to the object to use the graph subdomain; 
                         before start is one of graphPath or restMethod
                         must be non-nil and the other must be nil

 @param parameters       specifies url parameters for the request; nil
                         implies that automatically handled parameters such as
                         access_token should be set, but no additional
                         parameters will be set; default=nil

 @param HTTPMethod       indicates the HTTP method to use; nil implies GET;
                         default=nil

 @param handler          handler block, called when the request completes
                         with success, error, or cancel
*/
+ (FBRequestConnection*)connectionWithSession:(FBSession*)session
                                      graphPath:(NSString*)graphPath
                                     parameters:(NSDictionary*)parameters
                                     HTTPMethod:(NSString*)HTTPMethod
                              completionHandler:(FBRequestHandler)handler;

/*!
 @methodgroup FBRequest factory methods

 @abstract
 These methods initialize a FBRequest for common scenarios.

 @discussion
 These simplify the process of preparing a request to send.  These
 initialize a FBRequest based on strongly typed parameters that are
 specific to the scenario.

 They do not initialize a FBRequestConnection, so the app still needs
 to call connectionWithCompletionHandler: and then start on the result.
*/

// request*
//
// Summary:
// Helper methods used to create common request objects which can be used to create single or batch connections
//
//   session:              - the session object representing the identity of the
//                         Facebook user making the request; nil implies an
//                         unauthenticated request; default=nil

/*!
 @method

 @abstract
 Creates a request to get a FBGraphUser representing the session's identity.

 @discussion
 Simplifies preparing a request to retrieve "me".

 This does not initialize a FBRequestConnection, so the app still needs
 to call connectionWithCompletionHandler: and then start on the result.

 @param session          the session object representing the identity of the
                         Facebook user making the request; nil implies an
                         unauthenticated request; default=nil
*/
+ (FBRequest*)requestForMeWithSession:(FBSession*)session;

/*!
 @method

 @abstract
 Creates a request to get an array of FBGraphUser representing friends.

 @discussion
 Simplifies preparing a request to retrieve "me/friends".

 This does not initialize a FBRequestConnection, so the app still needs
 to call connectionWithCompletionHandler: and then start on the result.

 @param session          the session object representing the identity of the
                         Facebook user making the request; nil implies an
                         unauthenticated request; default=nil
*/
+ (FBRequest*)requestForMyFriendsWithSession:(FBSession*)session;

/*!
 @method

 @abstract
 Creates a request to upload a photo to the app album.

 @discussion
 Simplifies preparing a request to post a photo.

 To post a photo to a specific album, add a graph object representing
 the album to the parameters under the key @"album".

 This does not initialize a FBRequestConnection, so the app still needs
 to call connectionWithCompletionHandler: and then start on the result.

 @param photo            the UIImage to upload.

 @param session          the session object representing the identity of the
                         Facebook user making the request; nil implies an
                         unauthenticated request; default=nil
*/
+ (FBRequest*)requestForUploadPhoto:(UIImage *)photo
                             session:(FBSession *)session;

/*!
 @method
 
 @abstract
 Creates a request to get an arbitrary graph object or objects.
 
 @discussion
 Simplifies preparing a get graph objects.
 
 This does not initialize a FBRequestConnection, so the app still needs
 to call connectionWithCompletionHandler: and then start on the result.
 
 @param graphPath        the path to the graph object(s) to retrieve.
 
 @param session          the session object representing the identity of the
 Facebook user making the request; nil implies an
 unauthenticated request; default=nil
 */
+ (FBRequest*)requestForGraphPath:(NSString*)graphPath
                          session:(FBSession *)session;

/*!
 @method

 @abstract
 Creates a request to get an array of FBGraphPlace objects near a location.

 @discussion
 Simplifies preparing a request to search for places near a coordinate.

 This does not initialize a FBRequestConnection, so the app still needs
 to call connectionWithCompletionHandler: and then start on the result.

 @param coordinate       the coordinates to search near

 @param radius           the radius to search in meters

 @param limit            the maxiumum number of results to return.  It is
                         possible to receive fewer than this because of
                         the radius and because of server limits.

 @param searchText       text to use in the query to narrow the set of places
                         returned.

 @param session          the session object representing the identity of the
                         Facebook user making the request; nil implies an
                         unauthenticated request; default=nil
*/
+ (FBRequest*)requestForPlacesSearchAtCoordinate:(CLLocationCoordinate2D)coordinate
                                  radiusInMeters:(NSInteger)radius
                                    resultsLimit:(NSInteger)limit
                                      searchText:(NSString*)searchText
                                         session:(FBSession*)session;

@end
