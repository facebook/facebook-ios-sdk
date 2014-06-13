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

#import <OCMock/OCMock.h>

#import "FBInternalSettings.h"
#import "FBLikeActionController.h"
#import "FBLikeControl.h"
#import "FBSnapshotTestCase.h"
#import "FBViewImpressionTracker.h"

static NSMutableDictionary *_mockLikeActionControllers = nil;

static id FBLikeControlTestsGetMockLikeActionController(NSString *objectID)
{
    return _mockLikeActionControllers[objectID];
}

static void FBLikeControlTestsSetMockLikeActionController(NSString *objectID, id mockLikeActionController)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _mockLikeActionControllers = [[NSMutableDictionary alloc] init];
    });
    if (mockLikeActionController) {
        _mockLikeActionControllers[objectID] = mockLikeActionController;
    } else {
        [_mockLikeActionControllers removeObjectForKey:objectID];
    }
}

static void FBLikeControlTestsForEach(void(^block)(id object, BOOL *stop), id object, ...) {
    va_list argumentList;
    va_start(argumentList, object);
    BOOL stop = (object == nil);
    do {
        block(object, &stop);
    } while (!stop && ((object = va_arg(argumentList, id)) != nil));
    va_end(argumentList);
}

static void FBLikeControlTestsSwapClassMethod(Class klass, SEL selector1, SEL selector2)
{
    Method realMethod = class_getClassMethod(klass, selector1);
    Method mockMethod = class_getClassMethod(klass, selector2);
    method_exchangeImplementations(realMethod, mockMethod);
}

@interface FBViewImpressionTracker (FBLikeControlTests)
+ (instancetype)mockImpressionTrackerWithEventName:(NSString *)eventName;
@end

@implementation FBViewImpressionTracker (FBLikeControlTests)
+ (instancetype)mockImpressionTrackerWithEventName:(NSString *)eventName
{
    return nil;
}
@end

@interface FBLikeActionController (FBLikeControlTests)
+ (instancetype)mockLikeActionControllerForObjectID:(NSString *)objectID;
@end

@implementation FBLikeActionController (FBLikeControlTests)
+ (instancetype)mockLikeActionControllerForObjectID:(NSString *)objectID
{
    return FBLikeControlTestsGetMockLikeActionController(objectID);
}
@end

@interface FBLikeControlTests : FBSnapshotTestCase
@end

@implementation FBLikeControlTests

- (void)setUp
{
    [super setUp];

    [FBSettings enableBetaFeature:FBBetaFeaturesLikeButton];

    FBLikeControlTestsSwapClassMethod([FBViewImpressionTracker class],
                                      @selector(impressionTrackerWithEventName:),
                                      @selector(mockImpressionTrackerWithEventName:));
    FBLikeControlTestsSwapClassMethod([FBLikeActionController class],
                                      @selector(likeActionControllerForObjectID:),
                                      @selector(mockLikeActionControllerForObjectID:));
}

- (void)tearDown
{
    [super tearDown];

    FBLikeControlTestsSwapClassMethod([FBViewImpressionTracker class],
                                      @selector(impressionTrackerWithEventName:),
                                      @selector(mockImpressionTrackerWithEventName:));
    FBLikeControlTestsSwapClassMethod([FBLikeActionController class],
                                      @selector(likeActionControllerForObjectID:),
                                      @selector(mockLikeActionControllerForObjectID:));
}

- (void)checkLikeControlWithObjectIsLiked:(BOOL)objectIsLiked
                                likeCount:(NSUInteger)likeCount
                           socialSentence:(NSString *)socialSentence
                                    style:(FBLikeControlStyle)style
                       auxiliaryPoisition:(FBLikeControlAuxiliaryPosition)auxiliaryPosition
                      horizontalAlignment:(FBLikeControlHorizontalAlignment)horizontalAlignment
                               identifier:(NSString *)identifier
{
    NSString *mockObjectID = [[NSUUID UUID] UUIDString];
    id mockLikeActionController = [OCMockObject niceMockForClass:[FBLikeActionController class]];
    FBLikeControlTestsSetMockLikeActionController(mockObjectID, mockLikeActionController);
    [[[mockLikeActionController stub] andReturn:mockObjectID] objectID];
    [[[mockLikeActionController stub] andReturnValue:OCMOCK_VALUE(objectIsLiked)] objectIsLiked];
    [[[mockLikeActionController stub] andReturnValue:OCMOCK_VALUE(likeCount)] likeCount];
    [[[mockLikeActionController stub] andReturn:socialSentence] socialSentence];

    FBLikeControl *likeControl = [[FBLikeControl alloc] init];
    likeControl.likeControlStyle = style;
    likeControl.likeControlAuxiliaryPosition = auxiliaryPosition;
    likeControl.likeControlHorizontalAlignment = horizontalAlignment;
    likeControl.objectID = mockObjectID;

    CGRect frame = CGRectZero;
    frame.size = [likeControl sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    likeControl.frame = frame;

    FBSnapshotVerifyView(likeControl, identifier);

    FBLikeControlTestsSetMockLikeActionController(mockObjectID, nil);
}

- (void)testStyleBoxCount
{
    // no like count all render the same
    NSUInteger likeCount = 0;
    FBLikeControlTestsForEach(^(NSNumber *horizontalAlignment, BOOL *horizontalAlignmentStop) {
        FBLikeControlTestsForEach(^(NSNumber *auxiliaryPosition, BOOL *auxiliaryPositionStop) {
            FBLikeControlTestsForEach(^(NSNumber *objectIsLiked, BOOL *objectIsLikedStop) {
                NSString *identifier = ([objectIsLiked boolValue] ? @"liked" : @"unliked");
                [self checkLikeControlWithObjectIsLiked:[objectIsLiked boolValue]
                                              likeCount:likeCount
                                         socialSentence:nil
                                                  style:FBLikeControlStyleButton
                                     auxiliaryPoisition:[auxiliaryPosition unsignedIntegerValue]
                                    horizontalAlignment:[horizontalAlignment unsignedIntegerValue]
                                             identifier:identifier];
            }, @NO, @YES, nil);
        }, @(FBLikeControlAuxiliaryPositionInline), @(FBLikeControlAuxiliaryPositionTop), @(FBLikeControlAuxiliaryPositionBottom), nil);
    }, @(FBLikeControlHorizontalAlignmentCenter), @(FBLikeControlHorizontalAlignmentLeft), @(FBLikeControlHorizontalAlignmentRight), nil);

    // a non-zero like count yields an auxiliary view
    likeCount = 123;
    FBLikeControlTestsForEach(^(NSNumber *horizontalAlignment, BOOL *horizontalAlignmentStop) {
        FBLikeControlTestsForEach(^(NSNumber *auxiliaryPosition, BOOL *auxiliaryPositionStop) {
            FBLikeControlTestsForEach(^(NSNumber *objectIsLiked, BOOL *objectIsLikedStop) {
                NSString *identifier = [NSString stringWithFormat:@"%@_%@_%@",
                                        objectIsLiked,
                                        auxiliaryPosition,
                                        horizontalAlignment];
                [self checkLikeControlWithObjectIsLiked:[objectIsLiked boolValue]
                                              likeCount:likeCount
                                         socialSentence:nil
                                                  style:FBLikeControlStyleBoxCount
                                     auxiliaryPoisition:[auxiliaryPosition unsignedIntegerValue]
                                    horizontalAlignment:[horizontalAlignment unsignedIntegerValue]
                                             identifier:identifier];
            }, @NO, @YES, nil);
        }, @(FBLikeControlAuxiliaryPositionInline), @(FBLikeControlAuxiliaryPositionTop), @(FBLikeControlAuxiliaryPositionBottom), nil);
    }, @(FBLikeControlHorizontalAlignmentCenter), @(FBLikeControlHorizontalAlignmentLeft), @(FBLikeControlHorizontalAlignmentRight), nil);
}

- (void)testStyleButton
{
    FBLikeControlTestsForEach(^(NSNumber *horizontalAlignment, BOOL *horizontalAlignmentStop) {
        FBLikeControlTestsForEach(^(NSNumber *auxiliaryPosition, BOOL *auxiliaryPositionStop) {
            FBLikeControlTestsForEach(^(NSNumber *objectIsLiked, BOOL *objectIsLikedStop) {
                FBLikeControlTestsForEach(^(NSNumber *likeCount, BOOL *likeCountStop) {
                    NSString *identifier = ([objectIsLiked boolValue] ? @"liked" : @"unliked");
                    [self checkLikeControlWithObjectIsLiked:[objectIsLiked boolValue]
                                                  likeCount:[likeCount unsignedIntegerValue]
                                             socialSentence:nil
                                                      style:FBLikeControlStyleButton
                                         auxiliaryPoisition:[auxiliaryPosition unsignedIntegerValue]
                                        horizontalAlignment:[horizontalAlignment unsignedIntegerValue]
                                                 identifier:identifier];
                }, @0, @123, nil);
            }, @NO, @YES, nil);
        }, @(FBLikeControlAuxiliaryPositionInline), @(FBLikeControlAuxiliaryPositionTop), @(FBLikeControlAuxiliaryPositionBottom), nil);
    }, @(FBLikeControlHorizontalAlignmentCenter), @(FBLikeControlHorizontalAlignmentLeft), @(FBLikeControlHorizontalAlignmentRight), nil);
}

- (void)testStyleStandard
{
    void(^test)(BOOL, NSUInteger, FBLikeControlAuxiliaryPosition, FBLikeControlHorizontalAlignment) =
    ^(BOOL objectIsLiked,
      NSUInteger likeCount,
      FBLikeControlAuxiliaryPosition auxiliaryPosition,
      FBLikeControlHorizontalAlignment horizontalAlignment) {
        NSString *identifier = [NSString stringWithFormat:@"%i_%lu_%lu_%lu",
                                (int)objectIsLiked,
                                (unsigned long)likeCount,
                                (unsigned long)auxiliaryPosition,
                                (unsigned long)horizontalAlignment];
        [self checkLikeControlWithObjectIsLiked:objectIsLiked
                                      likeCount:likeCount
                                 socialSentence:@"Social sentence goes here."
                                          style:FBLikeControlStyleStandard
                             auxiliaryPoisition:auxiliaryPosition
                            horizontalAlignment:horizontalAlignment
                                     identifier:identifier];
    };
    FBLikeControlTestsForEach(^(NSNumber *horizontalAlignment, BOOL *horizontalAlignmentStop) {
        FBLikeControlTestsForEach(^(NSNumber *auxiliaryPosition, BOOL *auxiliaryPositionStop) {
            FBLikeControlTestsForEach(^(NSNumber *objectIsLiked, BOOL *objectIsLikedStop) {
                FBLikeControlTestsForEach(^(NSNumber *likeCount, BOOL *likeCountStop) {
                    test([objectIsLiked boolValue],
                         [likeCount unsignedIntegerValue],
                         [auxiliaryPosition unsignedIntegerValue],
                         [horizontalAlignment unsignedIntegerValue]);
                }, @0, @123, nil);
            }, @NO, @YES, nil);
        }, @(FBLikeControlAuxiliaryPositionInline), @(FBLikeControlAuxiliaryPositionTop), @(FBLikeControlAuxiliaryPositionBottom), nil);
    }, @(FBLikeControlHorizontalAlignmentCenter), @(FBLikeControlHorizontalAlignmentLeft), @(FBLikeControlHorizontalAlignmentRight), nil);
}

@end
