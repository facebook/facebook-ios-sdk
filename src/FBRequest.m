/*
 * Copyright 2010 Facebook
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

#import "Facebook.h"
#import "JSON.h"
#import "FBUtility.h"
#import "FBSession+Internal.h"

// constants
NSString *const FBGraphBasePath = @"https://graph." FB_BASE_URL;

static NSString *const kGetHTTPMethod = @"GET";
static NSString *const kPostHTTPMethod = @"POST";

// ----------------------------------------------------------------------------
// FBRequest

@implementation FBRequest

@synthesize parameters = _parameters;
@synthesize session = _session;
@synthesize graphPath = _graphPath;
@synthesize restMethod = _restMethod;
@synthesize HTTPMethod = _HTTPMethod; 

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
        
        _parameters = [[NSMutableDictionary alloc] init];
        if (parameters) {
            [self.parameters addEntriesFromDictionary:parameters];
        }
    }
    return self;
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
    if (self = [super init]) {
        // set default for nil
        if (!HTTPMethod) {
            HTTPMethod = kGetHTTPMethod;
        }
        
        self.session = session;
        self.restMethod = restMethod;
        self.HTTPMethod = HTTPMethod;
        
        _parameters = [[NSMutableDictionary alloc] init];
        if (parameters) {
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
    FBRequestConnection *connection = [[[FBRequestConnection alloc] init] autorelease];
    [connection addRequest:self completionHandler:handler];
    [connection start];
    return connection;
}

+ (FBRequestConnection*)startWithGraphPath:(NSString*)graphPath
                         completionHandler:(FBRequestHandler)handler
{
    return [FBRequest startWithGraphPath:graphPath
                              parameters:nil
                              HTTPMethod:nil
                       completionHandler:handler];
}

+ (FBRequestConnection*)startForPostWithGraphPath:(NSString*)graphPath
                                      graphObject:(id<FBGraphObject>)graphObject
                                completionHandler:(FBRequestHandler)handler
{
    FBRequest *request = [[[FBRequest alloc] initForPostWithSession:[FBSession activeSessionIfOpen]
                                                          graphPath:graphPath
                                                        graphObject:graphObject]
                          autorelease];
    
    return [request startWithCompletionHandler:handler];
}

+ (FBRequestConnection*)startWithGraphPath:(NSString*)graphPath
                                parameters:(NSDictionary*)parameters
                                HTTPMethod:(NSString*)HTTPMethod
                         completionHandler:(FBRequestHandler)handler
{
    FBRequest *request = [[[FBRequest alloc] initWithSession:[FBSession activeSessionIfOpen]
                                                   graphPath:graphPath
                                                  parameters:parameters
                                                  HTTPMethod:HTTPMethod]
                          autorelease];
    
    return [request startWithCompletionHandler:handler];
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

+ (FBRequest*)requestForPlacesSearchAtCoordinate:(CLLocationCoordinate2D)coordinate
                                  radiusInMeters:(NSInteger)radius
                                    resultsLimit:(NSInteger)limit
                                      searchText:(NSString*)searchText
{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:@"place" forKey:@"type"];
    [parameters setObject:[NSString stringWithFormat:@"%d", limit] forKey:@"limit"];
    [parameters setObject:[NSString stringWithFormat:@"%lf,%lf", coordinate.latitude, coordinate.longitude]
                   forKey:@"center"];
    [parameters setObject:[NSString stringWithFormat:@"%d", radius] forKey:@"distance"];
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
    
    NSURL* parsedURL = [NSURL URLWithString:baseUrl];
    NSString* queryPrefix = parsedURL.query ? @"&" : @"?";
    
    NSMutableArray* pairs = [NSMutableArray array];
    for (NSString* key in [params keyEnumerator]) {
        id value = [params objectForKey:key];
        if ([value isKindOfClass:[UIImage class]]
            || [value isKindOfClass:[NSData class]]) {
            if ([httpMethod isEqualToString:kGetHTTPMethod]) {
                NSLog(@"can not use GET to upload a file");
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
