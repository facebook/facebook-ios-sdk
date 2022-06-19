// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#define CUSTOM_EVENTS_KEY               @"custom_events"
#define EVENT_NAME_KEY                  @"_eventName"
#define ON_DEVICE_PARAMS_KEY            @"_onDeviceParams"
#define RESTRICTED_PARAMS_KEY           @"_restrictedParams"

#define USERDATA_STORE_KEY              @"ud"
#define ADVANCED_MATCHING_EMAIL         @"appSignals@fb.com"
#define ADVANCED_MATCHING_FIRST_NAME    @"App"
#define ADVANCED_MATCHING_LAST_NAME     @"Signals"
#define ADVANCED_MATCHING_PHONE         @"12345674444"
#define ADVANCED_MATCHING_DATE_OF_BIRTH @"20200101"
#define ADVANCED_MATCHING_GENDER        @"f"
#define ADVANCED_MATCHING_CITY          @"menlopark"
#define ADVANCED_MATCHING_STATE         @"CA"
#define ADVANCED_MATCHING_ZIP           @"94025"
#define ADVANCED_MATCHING_EXTERNAL_ID   @"testuserid"
#define ADVANCED_MATCHING_PWD           @"Test123"

void dispatch_on_main_thread(dispatch_block_t block);

@interface TestUtils : NSObject

+ (void)generateUITreeFile;
+ (void)simulateShake;
+ (void)throwUncaughtException;
+ (int)getCSignalToBeRaised;
+ (void)raiseCSignal;
+ (void)raiseFBSDKError;

+ (void)swizzleLogger;
+ (void)performBlock:(void (^)(void))block
          afterDelay:(NSTimeInterval)delay;
+ (NSArray<NSDictionary *> *)getEvents;
+ (NSArray<NSDictionary *> *)getUserData;
+ (void)showAlert:(NSString *)message;
+ (NSString *)encryptData:(NSString *)data type:(FBSDKAppEventUserDataType)type;

@end
