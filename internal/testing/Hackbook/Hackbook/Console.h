// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <Foundation/Foundation.h>

extern NSString *const ConsoleDidAddMessageNotification;
extern NSString *const ConsoleDidReportBugNotification;
extern NSString *const ConsoleDidSucceedNotification;
extern NSString *const ConsoleMessageKey;
extern NSString *const FacebookDomainPart;
extern NSString *const GraphAPIVersion;

extern void ConsoleError(NSError *error, NSString *message, ...) NS_FORMAT_FUNCTION(2, 3);
extern void ConsoleLog(NSString *message, ...) NS_FORMAT_FUNCTION(1, 2);
extern void ConsoleReportBug(NSString *message, ...) NS_FORMAT_FUNCTION(1, 2);
extern void ConsoleReportBugWithFormattedMessage(NSString *message);
extern void ConsoleSucceed(NSString *message, ...) NS_FORMAT_FUNCTION(1, 2);
extern void ConsoleSucceedWithFormattedMessage(NSString *message);

@protocol ConsoleMessage <NSObject>

@property (nonatomic, readonly, copy) NSString *message;
@property (nonatomic, readonly, copy) NSDate *timestamp;

@end

@interface Console : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, readonly, copy) NSArray *allMessages;

- (void)addMessage:(NSString *)message notificationName:(NSString *)notificationName;
- (void)clear;
- (BOOL)isEmpty;

@end
