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

#import "FBAsyncDataLoader.h"

@interface FBAsyncDataLoader () <NSURLConnectionDelegate> {

@private
    BOOL _objectUsed;
}

@property (retain, nonatomic) NSMutableData* data;
@property (retain, nonatomic) NSURLConnection* connection;
@property (copy, nonatomic) FBAsyncDataHandler handler;
@property (retain, nonatomic) NSURL* url;

- (void)cleanupState;

@end

@implementation FBAsyncDataLoader

@synthesize data = _data;
@synthesize connection = _connection;
@synthesize handler = _handler;
@synthesize url = _url;

#pragma mark -
#pragma mark Lifecycle

- (void)dealloc 
{
    [_connection release];
    [_handler release];
    [_data release];
    [_url release];
    [super dealloc];
}

- (id)initWithURL:(NSURL*)URL 
    handler:(FBAsyncDataHandler)handler
{    
    self = [super init];
    if (self) {
        self.url = URL;
        self.handler = handler;
    }

    return self;
}

#pragma mark -

- (void)cancel 
{
    [self cleanupState];
}

- (void)cleanupState 
{
    self.connection = nil;
    self.handler = nil;
    self.data = nil;
    self.url = nil;
}

- (void)setConnection:(NSURLConnection*)connection 
{
    if (connection != _connection) {
        [_connection cancel];
        [_connection release];
        _connection = [connection retain];
    }
}

- (void)start
{
    // TODO: Implement file caching here
    if (_objectUsed) {
        // This is a single use object - it's never okay to call this multiple
        // times.
        [NSException 
            raise:NSInternalInconsistencyException 
            format:@"Start can be called only once on this object."];
    }
    _objectUsed = YES;

    NSURLRequest* request = [[NSURLRequest alloc]initWithURL:_url];
    NSURLConnection* connection = 
        [[NSURLConnection alloc] 
            initWithRequest:request 
            delegate:self];
    self.connection = connection;
    [connection release];
    [request release];

    NSMutableData* data = [[NSMutableData alloc] init];
    self.data = data;
    [data release];
}

+ (FBAsyncDataLoader*)loaderWithURL:(NSURL*)URL
    handler:(FBAsyncDataHandler)handler 
{
    FBAsyncDataLoader* loader = 
        [[FBAsyncDataLoader alloc] 
            initWithURL:URL
            handler:handler];
    
    return [loader autorelease];
}


#pragma mark NSURLConnection[Data]Delegate

- (void)connection:(NSURLConnection*)connection 
    didFailWithError:(NSError*)error 
{    
    if (self.handler) {
        self.handler(self, error, nil);
    }
    
    [self cleanupState];
}

- (NSURLRequest*)connection:(NSURLConnection*)connection 
    willSendRequest:(NSURLRequest*)request 
    redirectResponse:(NSURLResponse*)response 
{    
    // Redirecting - reset data
    self.data.length = 0;
    return request;
}

- (void)connection:(NSURLConnection*)connection 
    didReceiveData:(NSData*)data 
{    
    [self.data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection 
{
    if (self.handler) {
        self.handler(self, nil, _data);
    }
    
    [self cleanupState];    
}

@end
