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

#import "FBURLConnection.h"
#import "FBError.h"

@interface FBURLConnection ()

@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSMutableData *data;
@property (nonatomic, copy) FBURLConnectionHandler handler;
@property (nonatomic, retain) NSURLResponse *response;

@end

@implementation FBURLConnection

@synthesize connection = _connection;
@synthesize data = _data;
@synthesize handler = _handler;
@synthesize response = _response;

- (FBURLConnection *)initWithURL:(NSURL *)url
               completionHandler:(FBURLConnectionHandler)handler
{
    NSURLRequest *request = [[[NSURLRequest alloc] initWithURL:url] autorelease];
    return [self initWithRequest:request completionHandler:handler];
}

- (FBURLConnection *)initWithRequest:(NSURLRequest *)request
                   completionHandler:(FBURLConnectionHandler)handler
{
    if (self = [super init]) {
        _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        _data = [[NSMutableData alloc] init];
        self.handler = handler;
    }
    return self;
}

- (void)dealloc
{
    [_connection release];
    [_data release];
    [_handler release];
    [super dealloc];
}

- (void)cancel
{
    [self.connection cancel];

    NSError *error = [[NSError alloc] initWithDomain:FBiOSSDKDomain
                                                code:FBErrorOperationCancelled
                                            userInfo:nil];

    self.handler(self, error, nil, nil);
    self.handler = nil;
    [error release];
}

- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response
{
    self.response = response;
    [self.data setLength:0];
}

- (void)connection:(NSURLResponse *)connection
    didReceiveData:(NSData *)data
{
    [self.data appendData:data];
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    // TODO: translate well-known errors
    self.handler(self, error, nil, nil);
    self.handler = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    self.handler(self, nil, self.response, self.data);
    self.handler = nil;
}

@end
