// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "Console.h"

NSString *const ConsoleDidAddMessageNotification = @"ConsoleDidAddMessageNotification";
NSString *const ConsoleDidReportBugNotification = @"ConsoleDidReportBugNotification";
NSString *const ConsoleDidSucceedNotification = @"ConsoleDidSucceedNotification";
NSString *const ConsoleMessageKey = @"message";
NSString *const FacebookDomainPart = @"facebookDomainPart";
NSString *const GraphAPIVersion = @"graphAPIVersion";

void ConsoleError(NSError *error, NSString *message, ...)
{
  if (!error) {
    return;
  }
  NSString *formattedMessage = nil;
  if (message) {
    va_list arguments;
    va_start(arguments, message);
    formattedMessage = [[NSString alloc] initWithFormat:message arguments:arguments];
    va_end(arguments);
  }
  ConsoleReportBug(
    @"%@%@%@%@",
    formattedMessage ?: @"",
    (formattedMessage ? @": " : @""),
    error,
    error.userInfo[NSUnderlyingErrorKey]
  );
}

void ConsoleLog(NSString *message, ...)
{
  if (!message) {
    return;
  }
  va_list arguments;
  va_start(arguments, message);
  NSString *formattedMessage = [[NSString alloc] initWithFormat:message arguments:arguments];
  va_end(arguments);
  [[Console sharedInstance] addMessage:formattedMessage notificationName:ConsoleDidAddMessageNotification];
}

void ConsoleReportBug(NSString *message, ...)
{
  if (!message) {
    return;
  }
  NSString *formattedMessage = nil;
  va_list arguments;
  va_start(arguments, message);
  formattedMessage = [[NSString alloc] initWithFormat:message arguments:arguments];
  va_end(arguments);
  formattedMessage = [[NSString alloc] initWithFormat:@"Please report bug:\n%@", formattedMessage];
  [[Console sharedInstance] addMessage:formattedMessage notificationName:ConsoleDidReportBugNotification];
}

void ConsoleReportBugWithFormattedMessage(NSString *message)
{
  if (!message) {
    return;
  }
  [[Console sharedInstance] addMessage:message notificationName:ConsoleDidReportBugNotification];
}

NS_SWIFT_NAME(ConsoleSucceed(message:))
void ConsoleSucceed(NSString *message, ...)
{
  if (!message) {
    return;
  }
  va_list arguments;
  va_start(arguments, message);
  NSString *formattedMessage = [[NSString alloc] initWithFormat:message arguments:arguments];
  va_end(arguments);
  [[Console sharedInstance] addMessage:formattedMessage notificationName:ConsoleDidSucceedNotification];
}

void ConsoleSucceedWithFormattedMessage(NSString *message)
{
  if (!message) {
    return;
  }
  [[Console sharedInstance] addMessage:message notificationName:ConsoleDidSucceedNotification];
}

@interface ConsoleMessageImpl : NSObject <ConsoleMessage>

- (instancetype)initWithMessage:(NSString *)message NS_DESIGNATED_INITIALIZER;

@end

@implementation ConsoleMessageImpl

- (instancetype)init NS_UNAVAILABLE
{
  assert(0);
  return nil;
}

- (instancetype)initWithMessage:(NSString *)message
{
  if ((self = [super init])) {
    _message = [message copy];
    _timestamp = [[NSDate alloc] init];
  }
  return self;
}

@synthesize message = _message;
@synthesize timestamp = _timestamp;

@end

@implementation Console
{
  NSMutableArray *_messages;
}

#pragma mark - Class Methods

static Console *_sharedInstance;

+ (void)initialize
{
  if ([self class] == [Console class]) {
    _sharedInstance = [[self alloc] init];
  }
}

+ (instancetype)sharedInstance
{
  return _sharedInstance;
}

#pragma mark - Object Lifecycle

- (instancetype)init
{
  if ((self = [super init])) {
    _messages = [[NSMutableArray alloc] init];
  }
  return self;
}

#pragma mark - Properties

- (NSArray *)allMessages
{
  @synchronized(_messages) {
    return [_messages copy];
  }
}

#pragma mark - Public Methods

- (void)addMessage:(NSString *)message notificationName:(NSString *)notificationName
{
  if (!message) {
    return;
  }
  NSLog(@"%@", message);
  ConsoleMessageImpl *consoleMessage = [[ConsoleMessageImpl alloc] initWithMessage:message];
  [_messages addObject:consoleMessage];
  [[NSNotificationCenter defaultCenter] postNotificationName:notificationName
                                                      object:self
                                                    userInfo:@{ConsoleMessageKey : consoleMessage}];
}

- (void)clear
{
  @synchronized(_messages) {
    [_messages removeAllObjects];
  }
}

- (BOOL)isEmpty
{
  return [_messages count] == 0;
}

@end
