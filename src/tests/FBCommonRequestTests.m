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
#import <UIKit/UIKit.h>

#import "FBCommonRequestTests.h"
#import "FBSession.h"
#import "FBRequest.h"
#import "FBGraphUser.h"
#import "FBGraphPlace.h"
#import "FBTestBlocker.h"
#import "FBUtility.h"
#import "FBTests.h"

#if defined(FBIOSSDK_SKIP_COMMON_REQUEST_TESTS)

#pragma message ("warning: Skipping FBCommonRequestTests")

#else

@interface FBCommonRequestTests ()

- (FBSession *)loginTestUserWithPermissions:(NSString *)firstPermission, ...;
- (FBSession *)loginSession:(FBSession *)session;
- (NSArray *)sendRequests:(FBRequest *)firstRequest, ...;
- (NSArray *)sendRequestArray:(NSArray *)requests;
- (UIImage *)imageForTest;

@end

@implementation FBCommonRequestTests

 - (void)testRequestMe
{
    FBSession *session = [self loginTestUserWithPermissions:nil];
    FBRequest *requestMe = [FBRequest requestForMeWithSession:session];
    NSArray *results = [self sendRequests:requestMe, nil];

    STAssertNotNil(results, @"results");
    STAssertTrue([results isKindOfClass:[NSArray class]],
                 @"[results isKindOfClass:[NSArray class]]");
    STAssertTrue([results count] == 1, @"[results count] == 1");
    STAssertTrue(![[results objectAtIndex:0] isKindOfClass:[NSError class]],
                 @"![[results objectAtIndex:0] isKindOfClass:[NSError class]]");
    STAssertTrue([[results objectAtIndex:0] isKindOfClass:[NSDictionary class]],
                 @"![[results objectAtIndex:0] isKindOfClass:[NSError class]]");

    id<FBGraphUser> me = [results objectAtIndex:0];
    STAssertNotNil(me.id, @"me.id");
    STAssertNotNil(me.name, @"me.name");
}

- (void)testRequestUploadPhoto
{
    FBSession *session = [self loginTestUserWithPermissions:nil];

    FBRequest *uploadRequest = [FBRequest requestForUploadPhoto:[self imageForTest]
                                                        session:session];
    NSArray *responses = [self sendRequests:uploadRequest, nil];

    STAssertNotNil(responses, @"responses");
    STAssertTrue([responses isKindOfClass:[NSArray class]],
                 @"[responses isKindOfClass:[NSArray class]]");
    STAssertTrue([responses count] == 1, @"[responses count] == 1");
    STAssertTrue(![[responses objectAtIndex:0] isKindOfClass:[NSError class]],
                 @"![[responses objectAtIndex:0] isKindOfClass:[NSError class]]");
    STAssertTrue([[responses objectAtIndex:0] isKindOfClass:[NSDictionary class]],
                 @"[[responses objectAtIndex:0] isKindOfClass:[NSDictionary class]]");

    NSDictionary *replyData = (NSDictionary *)[responses objectAtIndex:0];
    STAssertNotNil([replyData objectForKey:@"id"],
                   @"[replyData objectForKey:id]");
    STAssertNotNil([replyData objectForKey:@"post_id"],
                   @"[replyData objectForKey:post_id]");
}

- (void)testRequestPlaceSearchWithNoSearchText
{
    FBSession *session = [self loginTestUserWithPermissions:nil];

    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(38.889468, -77.03524);
    FBRequest *searchRequest = [FBRequest requestForPlacesSearchAtCoordinate:coordinate 
                                                              radiusInMeters:100 
                                                                resultsLimit:100 
                                                                  searchText:nil 
                                                                     session:session];
    NSArray *response = [self sendRequests:searchRequest, nil];

    STAssertNotNil(response, @"response");
    STAssertTrue([response isKindOfClass:[NSArray class]],
                 @"[response isKindOfClass:[NSArray class]]");
    STAssertTrue([response count] == 1, @"[response count] == 1");
    STAssertTrue(![[response objectAtIndex:0] isKindOfClass:[NSError class]],
                 @"![[response objectAtIndex:0] isKindOfClass:[NSError class]]");
    STAssertTrue([[response objectAtIndex:0] isKindOfClass:[NSDictionary class]],
                 @"[[response objectAtIndex:0] isKindOfClass:[NSDictionary class]]");

    NSDictionary *firstResponse = (NSDictionary *)[response objectAtIndex:0];
    NSArray *data = (NSArray*)[firstResponse objectForKey:@"data"];
    
    id<FBGraphPlace> targetPlace = (id<FBGraphPlace>)[FBGraphObject graphObject];
    targetPlace.id = @"131308453580417";
    targetPlace.name = @"Washington Monument National Monument";
    
    id<FBGraphObject> foundPlace = [FBUtility graphObjectInArray:data withSameIDAs:targetPlace];
    STAssertNotNil(foundPlace, @"didn't find Washington Monument");
}

- (void)testRequestPlaceSearchWithSearchText
{
    FBSession *session = [self loginTestUserWithPermissions:nil];
    
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(38.889468, -77.03524);
    FBRequest *searchRequest = [FBRequest requestForPlacesSearchAtCoordinate:coordinate 
                                                              radiusInMeters:100 
                                                                resultsLimit:100 
                                                                  searchText:@"Lincoln Memorial" 
                                                                     session:session];
    NSArray *response = [self sendRequests:searchRequest, nil];

    STAssertNotNil(response, @"response");
    STAssertTrue([response isKindOfClass:[NSArray class]],
                 @"[response isKindOfClass:[NSArray class]]");
    STAssertTrue([response count] == 1, @"[response count] == 1");
    STAssertTrue(![[response objectAtIndex:0] isKindOfClass:[NSError class]],
                 @"![[response objectAtIndex:0] isKindOfClass:[NSError class]]");
    STAssertTrue([[response objectAtIndex:0] isKindOfClass:[NSDictionary class]],
                 @"[[response objectAtIndex:0] isKindOfClass:[NSDictionary class]]");

    NSDictionary *firstResponse = (NSDictionary *)[response objectAtIndex:0];
    NSArray *data = (NSArray*)[firstResponse objectForKey:@"data"];
    
    id<FBGraphPlace> targetPlace = (id<FBGraphPlace>)[FBGraphObject graphObject];
    targetPlace.id = @"154981434517851";
    targetPlace.name = @"Lincoln Memorial";
    
    STAssertEquals((int)data.count, 1, @"should only have one response");
    id<FBGraphObject> foundPlace = [FBUtility graphObjectInArray:data withSameIDAs:targetPlace];
    STAssertNotNil(foundPlace, @"didn't find Lincoln Memorial");
}

- (FBSession *)loginTestUserWithPermissions:(NSString *)firstPermission, ...
{
    NSMutableArray *permissions = [[[NSMutableArray alloc] init] autorelease];

    if (firstPermission) {
        [permissions addObject:firstPermission];

        id vaPermission;
        va_list vaArguments;
        va_start(vaArguments, firstPermission);
        while ((vaPermission = va_arg(vaArguments, id))) {
            [permissions addObject:vaPermission];
        }
        va_end(vaArguments);
    }

    FBSession *session = [FBSession sessionForUnitTestingWithPermissions:permissions];
    return [self loginSession:session];
}

- (FBSession *)loginSession:(FBSession *)session
{
    __block FBTestBlocker *blocker = [[[FBTestBlocker alloc] init] autorelease];

    FBSessionStatusHandler handler = ^(FBSession *session,
                                       FBSessionState status,
                                       NSError *error) {
        STAssertTrue(!error, @"!error");
        
        [blocker signal];
    };

    [session loginWithCompletionHandler:handler];

    [blocker wait];
    STAssertTrue(session.isValid, @"session.isValid");

    return session;
}

- (NSArray *)sendRequests:(FBRequest *)firstRequest, ...
{
    NSMutableArray *requests = [[[NSMutableArray alloc] init] autorelease];

    [requests addObject:firstRequest];

    id vaRequest;
    va_list vaArguments;
    va_start(vaArguments, firstRequest);
    while ((vaRequest = va_arg(vaArguments, id))) {
        [requests addObject:vaRequest];
    }
    va_end(vaArguments);

    return [self sendRequestArray:requests];
}

- (NSArray *)sendRequestArray:(NSArray *)requests
{
    NSMutableArray *results = [[[NSMutableArray alloc] init] autorelease];
    FBTestBlocker *blocker = [[[FBTestBlocker alloc] init] autorelease];
    FBRequestConnection *connection = [[[FBRequestConnection alloc] init] autorelease];
    FBRequestHandler handler =
        ^(FBRequestConnection *connection, id result, NSError *error) {
            // Validate that we can assume in unit test that errors and results
            // are disjoint.
            STAssertTrue(![result isKindOfClass:[NSError class]],
                         @"![result isKindOfClass:[NSError class]]");
            [results addObject:(error ? error : result)];
            [blocker signal];
        };

    for (FBRequest *request in requests) {
        [connection addRequest:request completionHandler:handler];
    }

    [connection start];

    // FBRequestConnection sends its callbacks on the UI thread (this thread).
    // This code further assumes that all callbacks are sent in a loop on that
    // thread.  That is not guaranteed in the contract, and code anywhere other
    // than an SDK unit test should have a while loop to wait for the full set
    // of results.
    [blocker wait];
    STAssertTrue([results count] == [requests count],
                 @"[results count] == [requests count]");

    return results;
}

size_t getBlackPixels(void *info, void *buffer, size_t count) {
    memset(buffer, 0x00, count);
    return count;
}

- (UIImage *)imageForTest
{
    CGDataProviderSequentialCallbacks providerCallbacks;
    memset(&providerCallbacks, 0, sizeof(providerCallbacks));
    providerCallbacks.getBytes = getBlackPixels;

    CGDataProviderRef provider = CGDataProviderCreateSequential(NULL, &providerCallbacks);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();

    int width = 12;
    int height = 16;
    int bitsPerComponent = 8;
    int bitsPerPixel = 8;
    int bytesPerRow = width * (bitsPerPixel/8);

    CGImageRef cgImage = CGImageCreate(width,
                                       height,
                                       bitsPerComponent,
                                       bitsPerPixel,
                                       bytesPerRow,
                                       colorSpace,
                                       kCGBitmapByteOrderDefault,
                                       provider,
                                       NULL,
                                       NO,
                                       kCGRenderingIntentDefault);

    UIImage *image = [UIImage imageWithCGImage:cgImage];

    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(provider);
    CGImageRelease(cgImage);

    return image;
}

@end

#endif
