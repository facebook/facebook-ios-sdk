//
//  FBGraphObjectBasicTests.m
//  facebook-ios-sdk
//
//  Created by Jason Clark on 4/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FBRequest.h"
#import "FBRequestConnection.h"
#import "FBGraphObjectTests.h"
#import "FBGraphObject.h"
#import "FBGraphPerson.h"
#import "FBGraphPlace.h"
#import "FBGraphLocation.h"
#import "FBTestBlocker.h"

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
    STAssertTrue([arr objectAtIndex:0] == @"one", @"Wrong array contents");
    
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
    STAssertTrue([obj conformsToProtocol:@protocol(FBGraphPerson)], @"protocol inference is broken");
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
    [[FBRequest connectionWithGraphPath:@"4" // Zuck
                     completionHandler:^(FBRequestConnection *connection, id<FBGraphPerson> zuck, NSError *error) {
                         STAssertTrue([zuck.first_name isEqualToString:@"Mark"], @"zuck != zuck");
                         STAssertTrue([zuck.last_name isEqualToString:@"Zuckerberg"], @"zuck != zuck");
                         [blocker wait];
                     }] start];
    
    [blocker signal];
    
    blocker = [[[FBTestBlocker alloc] init] autorelease];
    [[FBRequest connectionWithGraphPath:@"100902843288017" // great fried chicken
                      completionHandler:^(FBRequestConnection *connection, id<FBGraphPlace> chicken, NSError *error) {
                          STAssertTrue([chicken.name isEqualToString:@"Ezell's Famous Chicken"], @"name wrong");
                          STAssertTrue([chicken.location.city isEqualToString:@"Woodinville"], @"city wrong");
                          STAssertTrue([chicken.location.state isEqualToString:@"WA"], @"state wrong");
                          [blocker wait];
                      }] start];
    
    [blocker signal];
}

@end
