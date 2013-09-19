/*
 * Copyright 2010-present Facebook.
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

#import <Foundation/NSString.h>
#import "Facebook.h"
#import "FBAppEvents+Internal.h"
#import "FBLogger.h"
#import "FBUtility.h"
#import "FBSession+Internal.h"
#import "FBSDKVersion.h"
#import "FBGraphObject.h"
#import "FBRequest+Internal.h"

// constants
NSString *const FBGraphBasePath = @"https://graph." FB_BASE_URL;

static NSString *const kGetHTTPMethod = @"GET";
static NSString *const kPostHTTPMethod = @"POST";

// ----------------------------------------------------------------------------
// FBRequest
@interface FBRequest()

@property (assign, nonatomic) BOOL canCloseSessionOnError;

@end

@implementation FBRequest

- (id)init
{
    return [self initWithSession:nil
                       graphPath:nil
                      parameters:nil
                      HTTPMethod:nil];
}

- (id)initWithSession:(FBSession*)session
            graphPath:(NSString *)graphPath
{
    return [self initWithSession:session
                       graphPath:graphPath
                      parameters:nil
                      HTTPMethod:nil];
}

- (id)initForPostWithSession:(FBSession*)session
                   graphPath:(NSString *)graphPath
                 graphObject:(id<FBGraphObject>)graphObject {
    self = [self initWithSession:session
                       graphPath:graphPath
                      parameters:nil
                      HTTPMethod:kPostHTTPMethod];
    if (self) {
        self.graphObject = graphObject;
    }
    return self;
}

- (id)initWithSession:(FBSession*)session
           restMethod:(NSString *)restMethod
           parameters:(NSDictionary *)parameters
           HTTPMethod:(NSString *)HTTPMethod
{
    // reusing the more common initializer...
    self = [self initWithSession:session
                       graphPath:nil     // but assuring a nil graphPath for the rest case
                      parameters:parameters
                      HTTPMethod:HTTPMethod];
    if (self) {
        self.restMethod = restMethod;
    }
    return self;
}

- (id)initWithSession:(FBSession*)session
            graphPath:(NSString *)graphPath
           parameters:(NSDictionary *)parameters
           HTTPMethod:(NSString *)HTTPMethod
{
    if (self = [super init]) {
        // set default for nil
        if (!HTTPMethod) {
            HTTPMethod = kGetHTTPMethod;
        }
        
        self.session = session;
        self.graphPath = graphPath;
        self.HTTPMethod = HTTPMethod;
        self.canCloseSessionOnError = YES;
        
        // all request objects start life with a migration bundle set for the SDK
        _parameters = [[NSMutableDictionary alloc]
                       initWithObjectsAndKeys:FB_IOS_SDK_MIGRATION_BUNDLE, @"migration_bundle", nil];
        if (parameters) {
            // but the incoming dictionary's migration bundle trumps the default one, if present
            [self.parameters addEntriesFromDictionary:parameters];
        }
    }
    return self;
}

- (void)dealloc
{
    [_graphObject release];
    [_session release];
    [_graphPath release];
    [_restMethod release];
    [_HTTPMethod release];
    [_parameters release];
    [_url release];
    [_connection release];
    [_responseText release];
    [_error release];
    [super dealloc];
}

//@property(nonatomic,retain) id<FBGraphObject> graphObject;
- (id<FBGraphObject>)graphObject {
    return _graphObject;
}

- (void)setGraphObject:(id<FBGraphObject>)newValue {
    if (_graphObject != newValue) {
        [_graphObject release];
        _graphObject = [newValue retain];
    }
    
    // setting this property implies you want a post, if you really
    // want a get, reset the method to get after setting this property
    self.HTTPMethod = kPostHTTPMethod;
}

- (FBRequestConnection*)startWithCompletionHandler:(FBRequestHandler)handler
{
    FBRequestConnection *connection = [self createRequestConnection];
    [connection addRequest:self completionHandler:handler];
    [connection start];
    return connection;
}

- (FBRequestConnection *)createRequestConnection {
    return [[[FBRequestConnection alloc] init] autorelease];
}

+ (FBRequest*)requestForMe {
    return [[[FBRequest alloc] initWithSession:[FBSession activeSessionIfOpen]
                                     graphPath:@"me"]
            autorelease];
}

+ (FBRequest*)requestForMyFriends {
    return [[[FBRequest alloc] initWithSession:[FBSession activeSessionIfOpen]
                                     graphPath:@"me/friends"
                                    parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                                @"id,name,username,first_name,last_name", @"fields",
                                                nil]
                                    HTTPMethod:nil]
            autorelease];
}

+ (FBRequest *)requestForUploadPhoto:(UIImage *)photo
{
    NSString *graphPath = @"me/photos";
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:photo forKey:@"picture"];
    
    FBRequest *request = [[[FBRequest alloc] initWithSession:[FBSession activeSessionIfOpen]
                                                   graphPath:graphPath
                                                  parameters:parameters
                                                  HTTPMethod:@"POST"]
                          autorelease];
    
    [parameters release];
    
    return request;
}

+ (FBRequest*)requestForGraphPath:(NSString*)graphPath
{
    FBRequest *request = [[[FBRequest alloc] initWithSession:[FBSession activeSessionIfOpen]
                                                   graphPath:graphPath
                                                  parameters:nil
                                                  HTTPMethod:nil]
                          autorelease];
    return request;
}

+ (FBRequest*)requestForDeleteObject:(id)object
{
    FBRequest *request = [[[FBRequest alloc] initWithSession:[FBSession activeSessionIfOpen]
                                                   graphPath:[FBUtility stringFBIDFromObject:object]
                                                  parameters:nil
                                                  HTTPMethod:@"DELETE"]
                          autorelease];
    return request;
}


+ (FBRequest*)requestForPostWithGraphPath:(NSString*)graphPath
                              graphObject:(id<FBGraphObject>)graphObject {
    return [[[FBRequest alloc] initForPostWithSession:[FBSession activeSessionIfOpen]
                                            graphPath:graphPath
                                          graphObject:graphObject]
            autorelease];
}

+ (FBRequest *)requestForPostStatusUpdate:(NSString *)message {
    return [FBRequest requestForPostStatusUpdate:message
                                           place:nil
                                            tags:nil];
}

+ (FBRequest *)requestForPostStatusUpdate:(NSString *)message
                                    place:(id)place
                                     tags:(id<NSFastEnumeration>)tags {
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:message forKey:@"message"];
    // if we have a place object, use it
    if (place) {
        [params setObject:[FBUtility stringFBIDFromObject:place]
                   forKey:@"place"];
    }
    // ditto tags
    if (tags) {
        NSMutableString *tagsValue = [NSMutableString string];
        NSString *format = @"%@";
        for (id tag in tags) {
            [tagsValue appendFormat:format, [FBUtility stringFBIDFromObject:tag]];
            format = @",%@";
        }
        if ([tagsValue length]) {
            [params setObject:tagsValue
                       forKey:@"tags"];
        }
    }
    
    return [FBRequest requestWithGraphPath:@"me/feed"
                                parameters:params
                                HTTPMethod:@"POST"];
}

+ (FBRequest*)requestWithGraphPath:(NSString*)graphPath
                        parameters:(NSDictionary*)parameters
                        HTTPMethod:(NSString*)HTTPMethod {
    return [[[FBRequest alloc] initWithSession:[FBSession activeSessionIfOpen]
                                     graphPath:graphPath
                                    parameters:parameters
                                    HTTPMethod:HTTPMethod]
            autorelease];
}

+ (FBRequest*)requestForPlacesSearchAtCoordinate:(CLLocationCoordinate2D)coordinate
                                  radiusInMeters:(NSInteger)radius
                                    resultsLimit:(NSInteger)limit
                                      searchText:(NSString*)searchText
{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:@"place" forKey:@"type"];
    [parameters setObject:[NSString stringWithFormat:@"%ld", (long)limit] forKey:@"limit"];
    [parameters setObject:[NSString stringWithFormat:@"%lf,%lf", coordinate.latitude, coordinate.longitude]
                   forKey:@"center"];
    [parameters setObject:[NSString stringWithFormat:@"%ld", (long)radius] forKey:@"distance"];
    if ([searchText length]) {
        [parameters setObject:searchText forKey:@"q"];
    }
    
    FBRequest *request = [[[FBRequest alloc] initWithSession:[FBSession activeSessionIfOpen]
                                                   graphPath:@"search"
                                                  parameters:parameters
                                                  HTTPMethod:nil]
                          autorelease];
    [parameters release];
    
    return request;
}

+ (FBRequest *)requestForCustomAudienceThirdPartyID:(FBSession *)session {
    return [FBAppEvents customAudienceThirdPartyIDRequest:session];
}

+ (FBRequest *)requestForPostOpenGraphObject:(id<FBOpenGraphObject>)graphObject {
    if (graphObject) {
        graphObject.provisionedForPost = YES;
        NSMutableDictionary<FBGraphObject> *parameters = [FBGraphObject graphObject];
        NSString *graphPath = [NSString stringWithFormat:@"me/objects/%@", graphObject.type];
        [parameters setObject:graphObject forKey:@"object"];
        FBRequest *request = [[[FBRequest alloc] initForPostWithSession:[FBSession activeSessionIfOpen]
                                                              graphPath:graphPath
                                                            graphObject:parameters]
                              autorelease];
        return request;
    }
    return nil;
}

+ (FBRequest *)requestForPostOpenGraphObjectWithType:(NSString *)type
                                               title:(NSString *)title
                                               image:(id)image
                                                 url:(id)url
                                         description:(NSString *)description
                                    objectProperties:(NSDictionary *)objectProperties {
    NSMutableDictionary<FBOpenGraphObject> *object = [FBGraphObject openGraphObjectForPostWithType:type
                                                                                             title:title
                                                                                             image:image
                                                                                               url:url
                                                                                       description:description];
    if (objectProperties) {
        object.data = [FBGraphObject graphObjectWrappingDictionary:objectProperties];
    }
    return [FBRequest requestForPostOpenGraphObject:object];
}

+ (FBRequest *)requestForUpdateOpenGraphObject:(id<FBOpenGraphObject>)object {
    return [FBRequest requestForUpdateOpenGraphObjectWithId:object[@"id"] graphObject:object];
}

+ (FBRequest *)requestForUpdateOpenGraphObjectWithId:(id)objectId
                                               title:(NSString *)title
                                               image:(id)image
                                                 url:(id)url
                                         description:(NSString *)description
                                    objectProperties:(NSDictionary *)objectProperties {
    NSMutableDictionary<FBOpenGraphObject> *object = [FBGraphObject openGraphObjectForPostWithType:nil
                                                                                             title:title
                                                                                             image:image
                                                                                               url:url
                                                                                       description:description];
    object[@"id"] = [FBUtility stringFBIDFromObject:objectId];
    return [FBRequest requestForUpdateOpenGraphObject:object];
}

+ (FBRequest *)requestForUploadStagingResourceWithImage:(UIImage *)photo {
    return [FBRequest requestWithGraphPath:@"me/staging_resources"
                                parameters:@{@"file":photo}
                                HTTPMethod:@"POST"];
}

// ----------------------------------------------------------------------------
// Private statics

+ (FBRequest*)requestForUpdateOpenGraphObjectWithId:(NSString*)objectId
                                        graphObject:(id<FBGraphObject>)graphObject
{
    if (graphObject) {
        graphObject.provisionedForPost = YES;
        NSMutableDictionary<FBGraphObject> *parameters = [FBGraphObject graphObject];
        NSString *graphPath = objectId;
        [parameters setObject:graphObject forKey:@"object"];
        FBRequest *request = [[[FBRequest alloc] initForPostWithSession:[FBSession activeSessionIfOpen]
                                                              graphPath:graphPath
                                                            graphObject:parameters]
                              autorelease];
        return request;
    }
    return nil;
    
}

@end

// ----------------------------------------------------------------------------
// Deprecated FBRequest implementation

@implementation FBRequest (Deprecated)

// ----------------------------------------------------------------------------
// deprecated public properties

//@property(nonatomic,assign) id<FBRequestDelegate> delegate;
- (id<FBRequestDelegate>)delegate {
    return _delegate;
}

- (void)setDelegate:(id<FBRequestDelegate>)newValue {
    _delegate = newValue;
}

//@property(nonatomic,copy) NSString* url;
- (NSString*)url {
    return _url;
}

- (void)setUrl:(NSString*)newValue {
    if (_url != newValue) {
        [_url release];
        _url = [newValue copy];
    }
}

//@property(nonatomic,copy) NSString* httpMethod;
- (NSString*)httpMethod {
    return self.HTTPMethod;
}

- (void)setHttpMethod:(NSString*)newValue {
    self.HTTPMethod = newValue;
}

//@property(nonatomic,retain) NSMutableDictionary* params;
- (NSMutableDictionary*)params {
    return _parameters;
}

- (void)setParams:(NSMutableDictionary*)newValue {
    if (_parameters != newValue) {
        [_parameters release];
        _parameters = [newValue retain];
    }
}

//@property(nonatomic,retain) NSURLConnection*  connection;
- (NSURLConnection*)connection {
    return _connection;
}

- (void)setConnection:(NSURLConnection*)newValue {
    if (_connection != newValue) {
        [_connection release];
        _connection = [newValue retain];
    }
}

//@property(nonatomic,retain) NSMutableData* responseText;
- (NSMutableData*)responseText {
    return _responseText;
}

- (void)setResponseText:(NSMutableData*)newValue {
    if (_responseText != newValue) {
        [_responseText release];
        _responseText = [newValue retain];
    }
}

//@property(nonatomic,retain) NSError* error;
- (NSError*)error {
    return _error;
}

- (void)setError:(NSError*)newValue {
    if (_error != newValue) {
        [_error release];
        _error = [newValue retain];
    }
}

//@property(nonatomic,readonly+readwrite) FBRequestState state;
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
- (FBRequestState)state {
    return _state;
}

- (void)setState:(FBRequestState)newValue {
    _state = newValue;
}
#pragma GCC diagnostic pop

//@property(nonatomic,readonly+readwrite) BOOL sessionDidExpire;
- (BOOL)sessionDidExpire {
    return _sessionDidExpire;
}

- (void)setSessionDidExpire:(BOOL)newValue {
    _sessionDidExpire = newValue;
}

// ----------------------------------------------------------------------------
// deprecated public methods

- (BOOL)loading
{
    return (_state == kFBRequestStateLoading);
}

+ (NSString *)serializeURL:(NSString *)baseUrl
                    params:(NSDictionary *)params {
    return [self serializeURL:baseUrl params:params httpMethod:kGetHTTPMethod];
}

+ (NSString*)serializeURL:(NSString *)baseUrl
                   params:(NSDictionary *)params
               httpMethod:(NSString *)httpMethod {
    
    NSURL* parsedURL = [NSURL URLWithString:[baseUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSString* queryPrefix = parsedURL.query ? @"&" : @"?";
    
    NSMutableArray* pairs = [NSMutableArray array];
    for (NSString* key in [params keyEnumerator]) {
        id value = [params objectForKey:key];
        if ([value isKindOfClass:[UIImage class]]
            || [value isKindOfClass:[NSData class]]) {
            if ([httpMethod isEqualToString:kGetHTTPMethod]) {
                [FBLogger singleShotLogEntry:FBLoggingBehaviorDeveloperErrors logEntry:@"can not use GET to upload a file"];
            }
            continue;
        }
        
        NSString* escaped_value = [FBUtility stringByURLEncodingString:value];
        [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, escaped_value]];
    }
    NSString* query = [pairs componentsJoinedByString:@"&"];
    
    return [NSString stringWithFormat:@"%@%@%@", baseUrl, queryPrefix, query];
}

#pragma mark Debugging helpers

- (NSString*)description {
    NSMutableString *result = [NSMutableString stringWithFormat:@"<%@: %p, session: %p",
                               NSStringFromClass([self class]), 
                               self,
                               self.session];
    if (self.graphPath) {
        [result appendFormat:@", graphPath: %@", self.graphPath];
    }
    if (self.graphObject) {
        [result appendFormat:@", graphObject: %@", self.graphObject];
        NSString *graphObjectID = [self.graphObject objectForKey:@"id"];
        if (graphObjectID) {
            [result appendFormat:@" (id=%@)", graphObjectID];
        }
    }
    if (self.restMethod) {
        [result appendFormat:@", restMethod: %@", self.restMethod];
    }
    if (self.HTTPMethod) {
        [result appendFormat:@", HTTPMethod: %@", self.HTTPMethod];
    }
    [result appendFormat:@", parameters: %@>", [self.parameters description]];
    return result;
    
}

#pragma mark -

@end
