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

#import "FBRequest.h"
#import "FBRequestConnection.h"
#import "FBGraphObjectTests.h"
#import "FBGraphObject.h"
#import "FBGraphUser.h"
#import "FBGraphPlace.h"
#import "FBGraphLocation.h"
#import "FBTestBlocker.h"
#import "FBTests.h"

#if defined(FACEBOOKSDK_SKIP_GRAPH_OBJECT_TESTS)

#pragma message ("warning: Skipping FBGraphObjectTests")

#else

@protocol TestGraphProtocolTooManyArgs<FBGraphObject>
- (int)thisMethod:(int)has too:(int)many args:(int)yikes;
@end

@protocol TestGraphProtocolOptionalMethod<FBGraphObject>
@optional
- (NSString*)name;
@end

@protocol TestGraphProtocolVeryFewMethods<FBGraphObject>
@end

@protocol T1<FBGraphObject>
- (NSString*)name;
@end

@protocol T2
@end

@protocol TestGraphProtocolBoooBadLineage
- (NSString*)name;
@end

@protocol TestGraphProtocolBoooBadLineage2<TestGraphProtocolTooManyArgs>
- (NSString*)title;
@end

@protocol TestGraphProtocolGoodLineage3<T1, T2>
- (NSString*)title;
@end

@protocol TestGraphProtocolGoodLineage<TestGraphProtocolVeryFewMethods>
- (NSString*)title;
@end

@protocol TestGraphProtocolGoodLineage2<TestGraphProtocolVeryFewMethods, T1>
- (NSString*)title;
@end

@implementation FBGraphObjectTests

- (void)testWrapWithGraphObject
{
    // construct a dictionary with an array and object as values
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    [d setObject:[NSArray arrayWithObjects:@"one", [NSMutableDictionary dictionary], @"three", nil] 
          forKey:@"array"];
    [d setObject:[NSMutableDictionary dictionary] forKey:@"object"];
    
    // make sure we got the object we expected when FBGraphObject-ifying it
    id obj = [FBGraphObject graphObjectWrappingDictionary:d];
    STAssertTrue([obj class] == [FBGraphObject class], @"Wrong class for resulting graph object");
        
    // make sure we don't double-wrap
    id obj2 = [FBGraphObject graphObjectWrappingDictionary:obj];
    STAssertTrue(obj == obj2, @"Different object implies faulty double-wrap");
    
    // use inferred implementation to fetch obj.array
    NSMutableArray *arr = [obj performSelector:@selector(array)];
    
    // did we get our array?
    STAssertTrue([arr isKindOfClass:[NSMutableArray class]], @"Wrong class for resulting graph object array");
    
    // make sure we don't double-wrap arrays
    obj2 = [FBGraphObject performSelector:@selector(graphObjectWrappingObject:) withObject:arr];
    STAssertTrue(arr == obj2, @"Different object implies faulty double-wrap");
    
    // is the first object the expected object?
    STAssertTrue([[arr objectAtIndex:0] isEqual:@"one"], @"Wrong array contents");
    
    // is the second index in the array wrapped?
    STAssertTrue([[arr objectAtIndex:1] class] == [FBGraphObject class], @"Wrong class for array element");
    
    // is the second object in the dictionary wrapped?
    STAssertTrue([[obj objectForKey:@"object"] class] == [FBGraphObject class], @"Wrong class for object item");
    
    // nil case?
    STAssertNil([FBGraphObject graphObjectWrappingDictionary:nil], @"Wrong result for nil wrapper");
}

- (void)testGraphObjectProtocolImplInference
{
    // get an object
    NSMutableDictionary *obj = [NSMutableDictionary dictionary];
    obj = [FBGraphObject graphObjectWrappingDictionary:obj];
    
    // assert its ability to be used with graph protocols (Note: new graph protocols should get a new line here
    STAssertTrue([obj conformsToProtocol:@protocol(FBGraphUser)], @"protocol inference is broken");
    STAssertTrue([obj conformsToProtocol:@protocol(FBGraphPlace)], @"protocol inference is broken");
    STAssertTrue([obj conformsToProtocol:@protocol(FBGraphLocation)], @"protocol inference is broken");
    
    // prove to ourselves we aren't always getting a yes
    STAssertFalse([obj conformsToProtocol:@protocol(TestGraphProtocolTooManyArgs)], @"protocol should not be inferrable");
    STAssertFalse([obj conformsToProtocol:@protocol(TestGraphProtocolOptionalMethod)], @"protocol should not be inferrable");
    STAssertFalse([obj conformsToProtocol:@protocol(TestGraphProtocolBoooBadLineage)], @"protocol should not be inferrable");
    STAssertFalse([obj conformsToProtocol:@protocol(TestGraphProtocolBoooBadLineage2)], @"protocol should not be inferrable");

    // some additional yes cases
    STAssertTrue([obj conformsToProtocol:@protocol(TestGraphProtocolGoodLineage)], @"protocol inference is broken");
    STAssertTrue([obj conformsToProtocol:@protocol(TestGraphProtocolGoodLineage2)], @"protocol inference is broken");
    STAssertTrue([obj conformsToProtocol:@protocol(TestGraphProtocolVeryFewMethods)], @"protocol should be inferrable");
    STAssertTrue([obj conformsToProtocol:@protocol(TestGraphProtocolGoodLineage3)], @"protocol should be inferrable");
}

- (void)testGraphObjectTypedRequest
{
    FBTestBlocker *blocker = [[[FBTestBlocker alloc] init] autorelease];
    [FBRequestConnection startWithGraphPath:@"4" // Zuck
                          completionHandler:^(FBRequestConnection *connection, id<FBGraphUser> zuck, NSError *error) {
                              STAssertTrue([zuck.first_name isEqualToString:@"Mark"], @"zuck != zuck");
                              STAssertTrue([zuck.last_name isEqualToString:@"Zuckerberg"], @"zuck != zuck");
                              [blocker signal];
                          }];
    
    [blocker wait];
    
    blocker = [[[FBTestBlocker alloc] init] autorelease];
    [FBRequestConnection startWithGraphPath:@"100902843288017" // great fried chicken
                          completionHandler:^(FBRequestConnection *connection, id<FBGraphPlace> chicken, NSError *error) {
                              STAssertTrue([chicken.name isEqualToString:@"Ezell's Famous Chicken"], @"name wrong");
                              STAssertTrue([chicken.location.city isEqualToString:@"Woodinville"], @"city wrong");
                              STAssertTrue([chicken.location.state isEqualToString:@"WA"], @"state wrong");
                              [blocker signal];
                          }];
    
    [blocker wait];
}

- (void)testGraphObjectTypedRequest2
{
    FBTestBlocker *blocker = [[[FBTestBlocker alloc] init] autorelease];
    [FBRequestConnection startWithGraphPath:@"4" // Zuck
                          completionHandler:^(FBRequestConnection *connection, id<FBGraphUser> zuck, NSError *error) {
                              STAssertTrue([zuck.first_name isEqualToString:@"Mark"], @"zuck != zuck");
                              STAssertTrue([zuck.last_name isEqualToString:@"Zuckerberg"], @"zuck != zuck");
                              [blocker signal];
                          }];
    
    [blocker wait];
}

- (void)testGraphObjectSameID
{
    NSString *anID = @"1234567890";

    id obj = [NSMutableDictionary dictionary];
    [obj setObject:anID forKey:@"id"];
    obj = [FBGraphObject graphObjectWrappingDictionary:obj];

    id objSameID = [NSMutableDictionary dictionary];
    [objSameID setObject:anID forKey:@"id"];
    objSameID = [FBGraphObject graphObjectWrappingDictionary:objSameID];

    id objDifferentID = [NSMutableDictionary dictionary];
    [objDifferentID setObject:@"999999" forKey:@"id"];
    objDifferentID = [FBGraphObject graphObjectWrappingDictionary:objDifferentID];

    id objNoID = [NSMutableDictionary dictionary];
    objNoID = [FBGraphObject graphObjectWrappingDictionary:objNoID];
    id objAnotherNoID = [NSMutableDictionary dictionary];
    objAnotherNoID = [FBGraphObject graphObjectWrappingDictionary:objAnotherNoID];
    
    STAssertTrue([FBGraphObject isGraphObjectID:obj sameAs:objSameID], @"same ID");
    STAssertTrue([FBGraphObject isGraphObjectID:obj sameAs:obj], @"same object");
    
    STAssertFalse([FBGraphObject isGraphObjectID:obj sameAs:objDifferentID], @"not same ID");
    
    // Objects with no ID should never match
    STAssertFalse([FBGraphObject isGraphObjectID:obj sameAs:objNoID], @"no ID");
    STAssertFalse([FBGraphObject isGraphObjectID:objNoID sameAs:obj], @"no ID");
    
    // Nil objects should never match an object with an ID
    STAssertFalse([FBGraphObject isGraphObjectID:obj sameAs:nil], @"nil object");
    STAssertFalse([FBGraphObject isGraphObjectID:nil sameAs:obj], @"nil object");
    
    // Having no ID is different than being a nil object
    STAssertFalse([FBGraphObject isGraphObjectID:objNoID sameAs:nil], @"nil object");
    
    // Two objects with no ID shouldn't match unless they are the same object.
    STAssertFalse([FBGraphObject isGraphObjectID:objNoID sameAs:objAnotherNoID], @"no IDs but different objects");
    STAssertTrue([FBGraphObject isGraphObjectID:objNoID sameAs:objNoID], @"no ID but same object");
}

- (id)graphObjectWithUnwrappedData 
{
    NSDictionary *rawDictionary1 = [NSDictionary dictionaryWithObjectsAndKeys:@"world", @"hello", nil];
    NSDictionary *rawDictionary2 = [NSDictionary dictionaryWithObjectsAndKeys:@"world", @"bye", nil];
    NSArray *rawArray1 = [NSArray arrayWithObjects:@"anda1", @"anda2", @"anda3", nil];
    NSArray *rawArray2 = [NSArray arrayWithObjects:@"anda1", @"anda2", @"anda3", nil];
    
    NSDictionary *rawObject = [NSDictionary dictionaryWithObjectsAndKeys:
                               rawDictionary1, @"dict1", 
                               rawDictionary2, @"dict2", 
                               rawArray1, @"array1",
                               rawArray2, @"array2",
                               nil];
    NSDictionary<FBGraphObject> *graphObject = [FBGraphObject graphObjectWrappingDictionary:rawObject];

    return graphObject;    
}

- (void)traverseGraphObject:(id)graphObject
{
    if ([graphObject isKindOfClass:[NSDictionary class]]) {
        for (NSString *key in graphObject) {
            id value = [graphObject objectForKey:key];
            STAssertNotNil(value, @"missing value");
            [self traverseGraphObject:value];
        }    
    } else if ([graphObject isKindOfClass:[NSArray class]]) {
        for (NSString *value in graphObject) {
            STAssertNotNil(value, @"missing value");
            [self traverseGraphObject:value];
        }            
    }
}

- (void)testSimpleGraphGet
{
    __block FBTestBlocker *blocker = [[FBTestBlocker alloc] init];
    [FBSession setActiveSession:self.defaultTestSession];
    [FBRequestConnection startWithGraphPath:@"TourEiffel"
                          completionHandler:[self handlerExpectingSuccessSignaling:blocker]];
    
    [blocker wait];
    [blocker release];

}

- (void)testSimpleGraphGetWithExpectedFailure
{
    __block FBTestBlocker *blocker = [[FBTestBlocker alloc] init];
    [FBSession setActiveSession:self.defaultTestSession];
    [FBRequestConnection startWithGraphPath:@"-1"
                          completionHandler:[self handlerExpectingFailureSignaling:blocker]];
    [blocker wait];
    [blocker release];
    
}

- (void)testFastEnumeration
{
    id graphObject = [self graphObjectWithUnwrappedData];
    [self traverseGraphObject:graphObject];
}

- (void)testEnumeration
{
    id graphObject = [self graphObjectWithUnwrappedData];
    [self traverseGraphObject:graphObject];
}

- (id)postStatusUpdate
{
    id<FBGraphObject> status = [FBGraphObject graphObject];
    // Posting duplicate messages will generate an error.
    NSString *statusMessage = [NSString stringWithFormat:@"Check out my awesome new status update posted at %@.", [NSDate date]];
    [status setObject:statusMessage forKey:@"message"];
    
    return [self batchedPostAndGetWithSession:self.defaultTestSession
                                    graphPath:@"me/feed" 
                                  graphObject:status];
}

- (id)postComment:(id)comment toStatusID:(NSString*)statusID
{
    NSString *graphPath = [NSString stringWithFormat:@"%@/comments", statusID];
    return [self batchedPostAndGetWithSession:self.defaultTestSession
                                    graphPath:graphPath 
                                  graphObject:comment];
}

- (void)testCommentRoundTrip
{
    id createdStatus = [self postStatusUpdate];
    NSString *statusID = [createdStatus objectForKey:@"id"];
    id<FBGraphObject> comment = [FBGraphObject graphObject];
    NSString *commentMessage = @"It truly is a wonderful status update.";
    [comment setObject:commentMessage forKey:@"message"];

    id comment1 = [self postComment:comment toStatusID:statusID];
    NSString *comment1ID = [[[comment1 objectForKey:@"id"] retain] autorelease];
    NSString *comment1Message = [[[comment1 objectForKey:@"message"] retain] autorelease];

    // Try posting the same comment to the same status update. We need to clear its ID first.
    [comment1 removeObjectForKey:@"id"];
    id comment2 = [self postComment:comment1 toStatusID:statusID];
  
    NSString *comment2ID = [comment2 objectForKey:@"id"];
    NSString *comment2Message = [comment2 objectForKey:@"message"];
    
    STAssertFalse([comment1ID isEqualToString:comment2ID], @"ended up with the same comment");
    STAssertTrue([comment1Message isEqualToString:comment2Message], @"message not round-tripped");
}

- (id)postEvent
{
    id<FBGraphObject> event = [FBGraphObject graphObject];
   
    // The "Events Timezone" platform migration affects what date/time formats Facebook accepts and returns.
    // Apps created after 8/1/12 (or apps that have explicitly enabled the migration) should send/receive
    // dates in ISO-8601 format. Pre-migration apps can send as Unix timestamps. Since the future is ISO-8601,
    // that is what we support here. Apps that need pre-migration behavior can explicitly send these as
    // integer timestamps rather than NSDates.
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    id startTime = [NSDate dateWithTimeIntervalSinceNow:24 * 3600];
    id endTime = [dateFormatter stringFromDate:[NSDate dateWithTimeInterval:3600 sinceDate:startTime]];
    startTime = [dateFormatter stringFromDate:startTime];
    
    [event setObject:[NSString stringWithFormat:@"My event on %@", startTime]
              forKey:@"name"];
    [event setObject:@"This is a great event. You should all come."
              forKey:@"description"];
    [event setObject:startTime forKey:@"start_time"];
    [event setObject:endTime forKey:@"end_time"];
    [event setObject:@"My house" forKey:@"location"];

    return [self batchedPostAndGetWithSession:self.defaultTestSession
                                    graphPath:@"me/events"
                                  graphObject:event];
}

- (void)testEventRoundTrip
{
    id postedEvent = [self postEvent];
    STAssertNotNil(postedEvent, @"no event");
    
    [postedEvent removeObjectForKey:@"id"];

    id event2 = [self batchedPostAndGetWithSession:self.defaultTestSession
                                         graphPath:@"me/events"
                                       graphObject:postedEvent];
    STAssertNotNil(event2, @"no event");
}

- (NSArray*)permissionsForDefaultTestSession
{
    return [NSArray arrayWithObjects:@"email", 
            @"publish_actions",
            @"create_event",
            @"read_stream",
            nil];
}

@end

#endif

