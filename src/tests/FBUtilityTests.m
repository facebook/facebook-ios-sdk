/*
 * Copyright 2010-present Facebook.
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

#import <objc/runtime.h>

#import "FBTests.h"
#import "FBUtility+Private.h"
#import "FacebookSDK.h"

// FBFakeProcessInfo is never instantiated; it receives all messages as NSProcessInfo
@interface FBFakeProcessInfo : NSProcessInfo
+ (BOOL)instancesDoesNotRespondToOperatingSystemVersion:(SEL)aSelector;
+ (BOOL)instancesRespondToOperatingSystemVersion:(SEL)aSelector;
@end

static BOOL NSProcessInfoRespondsToOperatingSystemVersion;

@interface FBUtilityTests : FBTests
@end

@implementation FBUtilityTests

- (void)testUrlBuilding
{
    NSString *url;
    url = [FBUtility buildFacebookUrlWithPre:@"pre."
                                        post:@"/post"
                                     version:nil];
    assertThat(url, equalTo(@"pre.facebook.com/" FB_IOS_SDK_TARGET_PLATFORM_VERSION @"/post"));
    
    url = [FBUtility buildFacebookUrlWithPre:@"pre."
                                        post:@"/post"
                                     version:@"v0.1"];
    
    assertThat(url, equalTo(@"pre.facebook.com/v0.1/post"));
    
    url = [FBUtility buildFacebookUrlWithPre:@"pre."
                                        post:@"/v0.2/post"
                                     version:@"v0.1"];
    
    assertThat(url, equalTo(@"pre.facebook.com/v0.2/post"));
    
    url = [FBUtility buildFacebookUrlWithPre:@"pre."
                                        post:@"/v0.2/post"
                                     version:nil];
    
    assertThat(url, equalTo(@"pre.facebook.com/v0.2/post"));
    
    url = [FBUtility buildFacebookUrlWithPre:@"pre."
                                        post:@"/v987654321.2/post"
                                     version:nil];
    
    assertThat(url, equalTo(@"pre.facebook.com/v987654321.2/post"));
    
    url = [FBUtility buildFacebookUrlWithPre:@"pre."
                                        post:@"/v.2/post"
                                     version:@"v99.99"];
    
    assertThat(url, equalTo(@"pre.facebook.com/v99.99/v.2/post"));
    
    url = [FBUtility buildFacebookUrlWithPre:@"pre."
                                        post:@"/v2/post"
                                     version:@"v99.99"];
    
    assertThat(url, equalTo(@"pre.facebook.com/v99.99/v2/post"));
    
    url = [FBUtility buildFacebookUrlWithPre:@"pre."
                                        post:@"/v2/post"
                                     version:@"v99.99"];
    
    assertThat(url, equalTo(@"pre.facebook.com/v99.99/v2/post"));

}

- (void)testRunningOnOrAfter
{
    // Set up for -[FBUtilityTests testRunningOnOrAfter]. This isn't appropriate for
    // -[XCTest setUp] because it's not possible to tearDown. This irrevocably modifies
    // NSProcessInfo for OCMock and iOS 7 compatibility.
    static dispatch_once_t addMethodsOnce;
    dispatch_once(&addMethodsOnce, ^{
        // OCMock won't allow us to stub methods on NSObject so we have to add an override
        // of +[NSObject instancesRespondToSelector:] manually. If class_addMethod fails,
        // then NSProcessInfo already overrides the method and OCMock will be happy.
        Method method = class_getClassMethod([FBFakeProcessInfo class], @selector(instancesRespondToSelector:));
        class_addMethod(object_getClass([NSProcessInfo class]), @selector(instancesRespondToSelector:), method_getImplementation(method), method_getTypeEncoding(method));

        // If we're running on iOS 7, -[NSProcessInfo operatingSystemVersion] doesn't exist,
        // so we'll add it to the class to maintain consistency across OS versions.
        method = class_getInstanceMethod([FBFakeProcessInfo class], @selector(operatingSystemVersion));
        NSProcessInfoRespondsToOperatingSystemVersion =
            !class_addMethod([NSProcessInfo class], @selector(operatingSystemVersion), method_getImplementation(method), method_getTypeEncoding(method));
    });

    __block NSString *testType = nil;

    struct FBRunningOnOrAfterTestConfiguration {
        NSOperatingSystemVersion operatingSystemVersion;
        NSString *systemVersion;
        void (^tests)();
    } configs[] = {
    {
        .operatingSystemVersion = { 6, 0, 0 },
        .systemVersion = @"6.0",
        .tests = ^{
            XCTAssertTrue(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_6_0), @"%@ failed to validate iOS 6.0 is iOS 6.0 or later.", testType);
            XCTAssertFalse(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_6_1), @"%@ failed to validate iOS 6.0 isn't iOS 6.1 or later.", testType);
            XCTAssertFalse(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_7_0), @"%@ failed to validate iOS 6.0 isn't iOS 7.0 or later.", testType);
            XCTAssertFalse(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_7_1), @"%@ failed to validate iOS 6.0 isn't iOS 7.1 or later.", testType);
            XCTAssertFalse(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_8_0), @"%@ failed to validate iOS 6.0 isn't iOS 8.0 or later.", testType);
        }
    }, {
        .operatingSystemVersion = { 6, 0, 1 },
        .systemVersion = @"6.0.1",
        .tests = ^{
            XCTAssertTrue(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_6_0), @"%@ failed to validate iOS 6.0.1 is iOS 6.0 or later.", testType);
            XCTAssertFalse(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_6_1), @"%@ failed to validate iOS 6.0.1 isn't iOS 6.1 or later.", testType);
            XCTAssertFalse(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_7_0), @"%@ failed to validate iOS 6.0.1 isn't iOS 7.0 or later.", testType);
            XCTAssertFalse(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_7_1), @"%@ failed to validate iOS 6.0.1 isn't iOS 7.1 or later.", testType);
            XCTAssertFalse(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_8_0), @"%@ failed to validate iOS 6.0.1 isn't iOS 8.0 or later.", testType);
        }
    }, {
        .operatingSystemVersion = { 6, 1, 0 },
        .systemVersion = @"6.1",
      .tests = ^{
            XCTAssertTrue(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_6_0), @"%@ failed to validate iOS 6.1 is iOS 6.0 or later.", testType);
            XCTAssertTrue(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_6_1), @"%@ failed to validate iOS 6.1 is iOS 6.1 or later.", testType);
            XCTAssertFalse(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_7_0), @"%@ failed to validate iOS 6.1 isn't iOS 7.0 or later.", testType);
            XCTAssertFalse(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_7_1), @"%@ failed to validate iOS 6.1 isn't iOS 7.1 or later.", testType);
            XCTAssertFalse(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_8_0), @"%@ failed to validate iOS 6.1 isn't iOS 8.0 or later.", testType);
        }
    }, {
        .operatingSystemVersion = { 7, 0, 0 },
        .systemVersion = @"7.0.0",
        .tests = ^{
            XCTAssertTrue(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_6_0), @"%@ failed to validate iOS 7.0 is iOS 6.0 or later.", testType);
            XCTAssertTrue(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_6_1), @"%@ failed to validate iOS 7.0 is iOS 6.1 or later.", testType);
            XCTAssertTrue(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_7_0), @"%@ failed to validate iOS 7.0 is iOS 7.0 or later.", testType);
            XCTAssertFalse(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_7_1), @"%@ failed to validate iOS 7.0 isn't iOS 7.1 or later.", testType);
            XCTAssertFalse(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_8_0), @"%@ failed to validate iOS 7.0 isn't iOS 8.0 or later.", testType);
        }
    }, {
        .operatingSystemVersion = { 7, 1, 0 },
        .systemVersion = @"7.1",
        .tests = ^{
            XCTAssertTrue(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_6_0), @"%@ failed to validate iOS 7.1 is iOS 6.0 or later.", testType);
            XCTAssertTrue(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_6_1), @"%@ failed to validate iOS 7.1 is iOS 6.1 or later.", testType);
            XCTAssertTrue(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_7_0), @"%@ failed to validate iOS 7.1 is iOS 7.0 or later.", testType);
            XCTAssertTrue(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_7_1), @"%@ failed to validate iOS 7.1 is iOS 7.1 or later.", testType);
            XCTAssertFalse(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_8_0), @"%@ failed to validate iOS 7.1 isn't iOS 8.0 or later.", testType);
        }
    }, {
        .operatingSystemVersion = { 7, 2, 0 },
        .systemVersion = @"7.2.0",
        .tests = ^{
            XCTAssertTrue(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_6_0), @"%@ failed to validate iOS 7.2 is iOS 6.0 or later.", testType);
            XCTAssertTrue(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_6_1), @"%@ failed to validate iOS 7.2 is at least iOS 6.1 or later.", testType);
            XCTAssertTrue(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_7_0), @"%@ failed to validate iOS 7.2 is iOS 7.0 or later.", testType);
            XCTAssertTrue(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_7_1), @"%@ failed to validate iOS 7.2 is iOS 7.1 or later.", testType);
            XCTAssertFalse(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_8_0), @"%@ failed to validate iOS 7.2 isn't iOS 8.0 or later.", testType);
        }
    }, {
        .operatingSystemVersion = { 8, 0, 0 },
        .systemVersion = @"8",
        .tests = ^{
            XCTAssertTrue(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_6_0), @"%@ failed to validate iOS 8.0 is iOS 6.0 or later.", testType);
            XCTAssertTrue(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_6_1), @"%@ failed to validate iOS 8.0 is iOS 6.1 or later.", testType);
            XCTAssertTrue(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_7_0), @"%@ failed to validate iOS 8.0 is iOS 7.0 or later.", testType);
            XCTAssertTrue(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_7_1), @"%@ failed to validate iOS 8.0 is iOS 7.1 or later.", testType);
            XCTAssertTrue(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_8_0), @"%@ failed to validate iOS 8.0 is iOS 8.0 or later.", testType);
        }
    }, {
        .operatingSystemVersion = { 8, 1, 0 },
        .systemVersion = @"8.1.0",
        .tests = ^{
            XCTAssertTrue(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_6_0), @"%@ failed to validate iOS 8.1 is iOS 6.0 or later.", testType);
            XCTAssertTrue(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_6_1), @"%@ failed to validate iOS 8.1 is iOS 6.1 or later.", testType);
            XCTAssertTrue(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_7_0), @"%@ failed to validate iOS 8.1 is iOS 7.0 or later.", testType);
            XCTAssertTrue(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_7_1), @"%@ failed to validate iOS 8.1 is iOS 7.1 or later.", testType);
            XCTAssertTrue(FBUtilityIsSystemVersionIOSVersionOrLater(FBUtilityGetSystemVersion(), FBIOSVersion_8_0), @"%@ failed to validate iOS 8.1 is iOS 8.0 or later.", testType);
        }
    },
    };

    size_t configCount = sizeof(configs) / sizeof(configs[0]);
    for (size_t configIndex = 0; configIndex < configCount; configIndex++) {
        testType = @"-[UIDevice systemVersion]";
        [self mockSystemVersion:configs[configIndex].systemVersion withBlock:configs[configIndex].tests];

        testType = @"-[NSProcessInfo operatingSystemVersion]";
        [self mockOperatingSystemVersion:configs[configIndex].operatingSystemVersion withBlock:configs[configIndex].tests];
    }
}

- (void)mockSystemVersion:(NSString *)version withBlock:(void (^)())block {
    // Have -[UIDevice systemVersion] return `version` and ensure NSProcessInfo does not
    // respond to -operatingSystemVersion so we can exercise the string parsing path.
    @autoreleasepool {
        id mockProcessInfo = [OCMockObject niceMockForClass:[NSProcessInfo class]];
        [[[mockProcessInfo stub] andCall:@selector(instancesDoesNotRespondToOperatingSystemVersion:) onObject:[FBFakeProcessInfo class]] instancesRespondToSelector:@selector(operatingSystemVersion)];

        id mockDevice = [OCMockObject partialMockForObject:[UIDevice currentDevice]];
        [(UIDevice *)[[mockDevice stub] andReturn:version] systemVersion];

        block();

        [mockDevice stopMocking];
        [mockProcessInfo stopMocking];
    }
}

- (void)mockOperatingSystemVersion:(NSOperatingSystemVersion)operatingSystemVersion withBlock:(void (^)())block {
    // Ensure NSProcessInfo responds to -operatingSystemVersion so it can return
    // `operatingSystemVersion` and we can exercise the iOS 8+ path.
    @autoreleasepool {
        id mockProcessInfo = [OCMockObject partialMockForObject:[NSProcessInfo processInfo]];
        [[[[mockProcessInfo stub] classMethod] andCall:@selector(instancesRespondToOperatingSystemVersion:) onObject:[FBFakeProcessInfo class]] instancesRespondToSelector:@selector(operatingSystemVersion)];
        [[[mockProcessInfo stub] andReturnValue:[NSValue valueWithBytes:&operatingSystemVersion objCType:@encode(NSOperatingSystemVersion)]] operatingSystemVersion];

        block();

        [mockProcessInfo stopMocking];
    }
}

@end

@implementation FBFakeProcessInfo

+ (BOOL)instancesRespondToSelector:(SEL)aSelector
{
    // Don't make the placeholder implementation available if this is iOS 7 or earlier
    if (sel_isEqual(aSelector, @selector(operatingSystemVersion))) {
        return NSProcessInfoRespondsToOperatingSystemVersion;
    }
    return [super instancesRespondToSelector:aSelector];
}

+ (BOOL)instancesDoesNotRespondToOperatingSystemVersion:(SEL)aSelector
{
    return NO;
}

+ (BOOL)instancesRespondToOperatingSystemVersion:(SEL)aSelector
{
    return YES;
}

- (NSOperatingSystemVersion)operatingSystemVersion
{
    [[NSException exceptionWithName:NSInternalInconsistencyException
                             reason:@"-[FBFakeProcessInfo operatingSystem] should never be invoked."
                           userInfo:nil]
     raise];

    NSOperatingSystemVersion systemVersion = { 0 };
    return systemVersion;
}

@end
