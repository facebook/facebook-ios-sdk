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
@class UIImage;

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
 The `FBRequest` object is used to setup and manage requests to Facebook Graph
 and REST APIs. This class provides helper methods that simplify the connection
 and response handling.

 @discussion
 An <FBSession> object is required for all authenticated uses of `FBRequest`.
 Requests that do not require an unauthenticated user are also supported and
 do not require an <FBSession> object to be passed in.

 An instance of `FBRequest` represents the arguments and setup for a connection
 to Facebook. After creating an `FBRequest` object it can be used to setup a
 connection to Facebook through the <FBRequestConnection> object. The
 <FBRequestConnection> object is created to manage a single connection. To
 cancel a connection use the instance method in the <FBRequestConnection> class.

 An `FBRequest` object may be reused to issue multiple connections to Facebook.
 However each <FBRequestConnection> instance will manage one connection.

 Class and instance methods prefixed with **start* ** can be used to perform the
 request setup and initiate the connection in a single call.

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
 Calls <initWithSession:graphPath:parameters:HTTPMethod:> with the default parameters.
*/
- (id)init;

/*!
 @method
 Calls <initWithSession:graphPath:parameters:HTTPMethod:> with default parameters
 except for the ones provided to this method.

 @param session     The session object representing the identity of the Facebook user making
 the request. A nil value indicates a request that requires no token; to
 use the active session pass `[FBSession activeSession]`.

 @param graphPath   The Graph API endpoint to use for the request, for example "me".
*/
- (id)initWithSession:(FBSession*)session
            graphPath:(NSString *)graphPath;

/*!
 @method

 @abstract
 Initializes an `FBRequest` object for a Graph API request call.

 @discussion
 Note that this only sets properties on the `FBRequest` object.

 To send the request, initialize an <FBRequestConnection> object, add this request,
 and send <[FBRequestConnection start]>.  See other methods on this
 class for shortcuts to simplify this process.

 @param session          The session object representing the identity of the Facebook user making
 the request. A nil value indicates a request that requires no token; to
 use the active session pass `[FBSession activeSession]`.

 @param graphPath        The Graph API endpoint to use for the request, for example "me".

 @param parameters       The parameters for the request. A value of nil sends only the automatically handled
 parameters, for example, the access token. The default is nil.

 @param HTTPMethod       The HTTP method to use for the request. The default is value of nil implies a GET.
*/
- (id)initWithSession:(FBSession*)session
            graphPath:(NSString *)graphPath
           parameters:(NSDictionary *)parameters
           HTTPMethod:(NSString *)HTTPMethod;

/*!
 @method
 @abstract
 Initialize a `FBRequest` object that will do a graph request.

 @discussion
 Note that this only sets properties on the `FBRequest`.

 To send the request, initialize a <FBRequestConnection>, add this request,
 and send <[FBRequestConnection start]>.  See other methods on this
 class for shortcuts to simplify this process.

 @param session          The session object representing the identity of the Facebook user making
 the request. A nil value indicates a request that requires no token; to
 use the active session pass `[FBSession activeSession]`.

 @param graphPath        The Graph API endpoint to use for the request, for example "me".

 @param graphObject      An object or open graph action to post.
*/
- (id)initForPostWithSession:(FBSession*)session
                   graphPath:(NSString *)graphPath
                 graphObject:(id<FBGraphObject>)graphObject;

/*!
 @method
 @abstract
 Initialize a `FBRequest` object that will do a rest API request.

 @discussion
 Prefer to use graph requests instead of this where possible.

 Note that this only sets properties on the `FBRequest`.

 To send the request, initialize a <FBRequestConnection>, add this request,
 and send <[FBRequestConnection start]>.  See other methods on this
 class for shortcuts to simplify this process.

 @param session          The session object representing the identity of the Facebook user making
 the request. A nil value indicates a request that requires no token; to
 use the active session pass `[FBSession activeSession]`.

 @param restMethod        A valid REST API method.

 @param parameters       The parameters for the request. A value of nil sends only the automatically handled
 parameters, for example, the access token. The default is nil.

 @param HTTPMethod       The HTTP method to use for the request. The default is value of nil implies a GET.

*/
- (id)initWithSession:(FBSession*)session
           restMethod:(NSString *)restMethod
           parameters:(NSDictionary *)parameters
           HTTPMethod:(NSString *)HTTPMethod;

/*!
 @abstract
 The parameters for the request.

 @discussion
 May be used to read the parameters that were automatically set during
 the object initiliazation. Make any required modifications prior to
 sending the request.

 `NSString` parameters are used to generate URL parameter values or JSON
 parameters.  `NSData` and `UIImage` parameters are added as attachments
 to the HTTP body and referenced by name in the URL and/or JSON.
*/
@property(nonatomic, retain, readonly) NSMutableDictionary *parameters;

/*!
 @abstract
 The <FBSession> session object to use for the request.

 @discussion
 May be used to read the session that was automatically set during
 the object initiliazation. Make any required modifications prior to
 sending the request.
*/
@property(nonatomic, retain) FBSession *session;

/*!
 @abstract
 The Graph API endpoint to use for the request, for example "me".

 @discussion
 May be used to read the Graph API endpoint that was automatically set during
 the object initiliazation. Make any required modifications prior to
 sending the request.
*/
@property(nonatomic, copy) NSString *graphPath;

/*!
 @abstract
 A valid REST API method.

 @discussion
 May be used to read the REST method that was automatically set during
 the object initiliazation. Make any required modifications prior to
 sending the request.

 Use the Graph API equivalent of the API if it exists as the REST API
 method is deprecated if there is a Graph API equivalent.
*/
@property(nonatomic, copy) NSString *restMethod;

/*!
 @abstract
 The HTTPMethod to use for the request, for example "GET" or "POST".

 @discussion
 May be used to read the HTTP method that was automatically set during
 the object initiliazation. Make any required modifications prior to
 sending the request.
*/
@property(nonatomic, copy) NSString *HTTPMethod;

/*!
 @abstract
 The graph object to post with the request.

 @discussion
 May be used to read the graph object that was automatically set during
 the object initiliazation. Make any required modifications prior to
 sending the request.
*/
@property(nonatomic, retain) id<FBGraphObject> graphObject;

/*!
 @methodgroup Instance methods
*/

/*!
 @method

 @abstract
 Starts a connection to the Facebook API.

 @discussion
 This is used to start an API call to Facebook and call the block when the
 request completes with a success, error, or cancel.

 @param handler   The handler block to call when the request completes with a success, error, or cancel action.
*/
- (FBRequestConnection*)startWithCompletionHandler:(FBRequestHandler)handler;

/*!
 @methodgroup FBRequestConnection start methods

 @abstract
 These methods start an <FBRequestConnection>.

 @discussion
 These methods simplify the process of preparing a request and starting
 the connection.  The methods handle initializing an `FBRequest` object,
 initializing a <FBRequestConnection> object, adding the `FBRequest`
 object to the to the <FBRequestConnection>, and finally starting the
 connection.
*/

/*!
 @methodgroup FBRequest factory methods

 @abstract
 These methods initialize a `FBRequest` for common scenarios.

 @discussion
 These simplify the process of preparing a request to send.  These
 initialize a `FBRequest` based on strongly typed parameters that are
 specific to the scenario.

 These method do not initialize an <FBRequestConnection> object. To initiate the API
 call first instantiate an <FBRequestConnection> object, add the request to this object,
 then call the `start` method on the connection instance.
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
 Creates a request representing a Graph API call to the "me" endpoint, using the active session.

 @discussion
 Simplifies preparing a request to retrieve the user's identity.

 This method does not initialize an <FBRequestConnection> object. To initiate the API
 call first instantiate an <FBRequestConnection> object, add the request to this object,
 then call the `start` method on the connection instance.

 A successful Graph API call will return an <FBGraphUser> object representing the
 user's identity.

 Note you may change the session property after construction if a session other than
 the active session is preferred.
*/
+ (FBRequest*)requestForMe;

/*!
 @method

 @abstract
 Creates a request representing a Graph API call to the "me/friends" endpoint using the active session.

 @discussion
 Simplifies preparing a request to retrieve the user's friends.

 This method does not initialize an <FBRequestConnection> object. To initiate the API
 call first instantiate an <FBRequestConnection> object, add the request to this object,
 then call the `start` method on the connection instance.

 A successful Graph API call will return an array of <FBGraphUser> objects representing the
 user's friends.
*/
+ (FBRequest*)requestForMyFriends;

/*!
 @method

 @abstract
 Creates a request representing a Graph API call to upload a photo to the app's album using the active session.

 @discussion
 Simplifies preparing a request to post a photo.

 To post a photo to a specific album, get the `FBRequest` returned from this method
 call, then modify the request parameters by adding the album ID to an "album" key.

 This method does not initialize an <FBRequestConnection> object. To initiate the API
 call first instantiate an <FBRequestConnection> object, add the request to this object,
 then call the `start` method on the connection instance.

 @param photo            A `UIImage` for the photo to upload.
*/
+ (FBRequest*)requestForUploadPhoto:(UIImage *)photo;

/*!
 @method
 
 @abstract
 Creates a request representing a status update.
 
 @discussion
 Simplifies preparing a request to post a status update.
 
 This method does not initialize an <FBRequestConnection> object. To initiate the API
 call first instantiate an <FBRequestConnection> object, add the request to this object,
 then call the `start` method on the connection instance.
 
 @param message         The message to post.
 */
+ (FBRequest *)requestForPostStatusUpdate:(NSString *)message;

/*!
 @method
 
 @abstract
 Creates a request representing a status update.
 
 @discussion
 Simplifies preparing a request to post a status update.
 
 This method does not initialize an <FBRequestConnection> object. To initiate the API
 call first instantiate an <FBRequestConnection> object, add the request to this object,
 then call the `start` method on the connection instance.
 
 @param message         The message to post.
 @param place           The place to checkin with, or nil. Place may be an fbid or a 
 graph object representing a place.
 @param tags            Array of friends to tag in the status update, each element 
 may be an fbid or a graph object representing a user.
 */
+ (FBRequest *)requestForPostStatusUpdate:(NSString *)message
                                    place:(id)place
                                     tags:(id<NSFastEnumeration>)tags;

/*!
 @method

 @abstract
 Creates a request representing a Graph API call to the "search" endpoint
 for a given location using the active session.

 @discussion
 Simplifies preparing a request to search for places near a coordinate.

 This method does not initialize an <FBRequestConnection> object. To initiate the API
 call first instantiate an <FBRequestConnection> object, add the request to this object,
 then call the `start` method on the connection instance.

 A successful Graph API call will return an array of <FBGraphPlace> objects representing
 the nearby locations.

 @param coordinate       The search coordinates.

 @param radius           The search radius in meters.

 @param limit            The maxiumum number of results to return.  It is
 possible to receive fewer than this because of the radius and because of server limits.

 @param searchText       The text to use in the query to narrow the set of places
 returned.
*/
+ (FBRequest*)requestForPlacesSearchAtCoordinate:(CLLocationCoordinate2D)coordinate
                                  radiusInMeters:(NSInteger)radius
                                    resultsLimit:(NSInteger)limit
                                      searchText:(NSString*)searchText;

/*!
 @method
 
 @abstract
 Returns a newly initialized request object that can be used to make a Graph API call for the active session.
 
 @discussion
 This method simplifies the preparation of a Graph API call.
 
 This method does not initialize an <FBRequestConnection> object. To initiate the API
 call first instantiate an <FBRequestConnection> object, add the request to this object,
 then call the `start` method on the connection instance.
 
 @param graphPath        The Graph API endpoint to use for the request, for example "me".
 */
+ (FBRequest*)requestForGraphPath:(NSString*)graphPath;

/*!
 @method
 
 @abstract
 Creates a request representing a POST for a graph object.
 
 @param graphPath        The Graph API endpoint to use for the request, for example "me".
 
 @param graphObject      An object or open graph action to post.
 */
+ (FBRequest*)requestForPostWithGraphPath:(NSString*)graphPath
                              graphObject:(id<FBGraphObject>)graphObject;

/*!
 @method
 
 @abstract
 Returns a newly initialized request object that can be used to make a Graph API call for the active session.
 
 @discussion
 This method simplifies the preparation of a Graph API call.
 
 This method does not initialize an <FBRequestConnection> object. To initiate the API
 call first instantiate an <FBRequestConnection> object, add the request to this object,
 then call the `start` method on the connection instance.
 
 @param graphPath        The Graph API endpoint to use for the request, for example "me".
 
 @param parameters       The parameters for the request. A value of nil sends only the automatically handled parameters, for example, the access token. The default is nil.
 
 @param HTTPMethod       The HTTP method to use for the request. A nil value implies a GET.
 */
+ (FBRequest*)requestWithGraphPath:(NSString*)graphPath
                        parameters:(NSDictionary*)parameters
                        HTTPMethod:(NSString*)HTTPMethod;
@end
