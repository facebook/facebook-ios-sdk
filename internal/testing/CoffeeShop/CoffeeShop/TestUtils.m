// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "TestUtils.h"

#import <UIKit/UIKit.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>
#import <objc/message.h>

#import "UIMotionEventProxy.h"

typedef void (*send_type)(Class, SEL, SEL, Class, id, id);

void dispatch_on_main_thread(dispatch_block_t block)
{
  if (block != nil) {
    if ([NSThread isMainThread]) {
      block();
    } else {
      dispatch_async(dispatch_get_main_queue(), block);
    }
  }
}

typedef void (^FBSDKFeatureManagerBlock)(BOOL enabled);

static NSMutableArray<NSString *> *logs;

@implementation TestUtils

+ (void)initialize
{
  logs = [[NSMutableArray alloc] init];
}

#pragma mark - Codeless helper methods

+ (void)generateUITreeFile
{
  UIWindow *window = [[UIApplication sharedApplication].delegate window];
  Class FBSDKCodelessIndexer = NSClassFromString(@"FBSDKCodelessIndexer");
  NSDictionary *uiTree = [FBSDKCodelessIndexer performSelector:NSSelectorFromString(@"recursiveCaptureTree:")
                                                    withObject:window];

  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"uiTree.txt"];

  NSError *writeError = nil;
  NSData *data;
  data = [NSJSONSerialization dataWithJSONObject:uiTree options:NSJSONWritingPrettyPrinted error:&writeError];
  [data writeToFile:filePath atomically:YES];

  NSLog(@"Written ui tree to filepath: %@", filePath);
}

+ (void)simulateShake
{
  UIMotionEventProxy *m = [[NSClassFromString(@"UIMotionEvent") alloc] _init];

  [m setShakeState:1];
  [m _setSubtype:UIEventSubtypeMotionShake];

  [[UIApplication sharedApplication] sendEvent:m];
  [[[UIApplication sharedApplication] keyWindow] motionBegan:UIEventSubtypeMotionShake withEvent:m];
  [[[UIApplication sharedApplication] keyWindow] motionEnded:UIEventSubtypeMotionShake withEvent:m];
}

#pragma mark - CrashReport helper methods

+ (int)getCSignalToBeRaised
{
  return SIGSEGV;
}

+ (void)raiseCSignal
{
  raise([[self class] getCSignalToBeRaised]);
}

+ (void)raiseFBSDKError
{
  id<FBSDKErrorCreating> errorFactory = [FBSDKErrorFactory new];
  [errorFactory errorWithCode:0
                     userInfo:nil
                      message:@"Failed to construct oauth browser url"
              underlyingError:nil];
}

+ (void)showAlert:(NSString *)message
{
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                 message:message
                                                          preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *cancel = [UIAlertAction
                           actionWithTitle:@"cancel"
                           style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction *action) {
                             [alert dismissViewControllerAnimated:YES completion:nil];
                           }];
  [alert addAction:cancel];
  [[self topMostViewController] presentViewController:alert animated:YES completion:nil];
}

#pragma mark - E2E helper methods

+ (void)swizzleLogger
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    Class aClass = NSClassFromString(@"FBSDKSwizzler");
    SEL aSelector = NSSelectorFromString(@"swizzleSelector:onClass:withBlock:named:");
    if (![aClass respondsToSelector:aSelector]) {
      return;
    }

    Class swizzledClass = NSClassFromString(@"FBSDKLogger");
    SEL swizzledSelector = NSSelectorFromString(@"appendString:");
    void (^block)(id target, SEL cmd, NSString *entry) =
    ^(id target, SEL cmd, NSString *entry) {
      [logs addObject:entry];
    };
    NSString *name = @"E2ETest";
    send_type msgSend = (send_type)objc_msgSend;
    msgSend(aClass, aSelector, swizzledSelector, swizzledClass, block, name);
  });
}

+ (void)performBlock:(void (^)(void))block
          afterDelay:(NSTimeInterval)delay
{
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * delay), dispatch_get_main_queue(), block);
}

+ (NSArray<NSDictionary *> *)getEvents
{
  NSMutableArray *events = [[NSMutableArray alloc] init];
  for (NSString *entry in logs) {
    if (entry.length == 0) {
      continue;
    }
    int startIdx;
    int endIdx;
    NSRange range = [entry rangeOfString:@"{"];
    startIdx = (int)range.location;
    if (range.location == NSNotFound || startIdx > entry.length - 1 || startIdx < 0) {
      continue;
    }
    range = [entry rangeOfString:@"}" options:NSBackwardsSearch];
    endIdx = (int)range.location;
    if (range.location == NSNotFound || endIdx > entry.length - 1 || endIdx < 0) {
      continue;
    }
    if (startIdx < endIdx) {
      NSString *str = [entry substringWithRange:NSMakeRange(startIdx, endIdx - startIdx + 1)];
      NSMutableDictionary *dict = [NSJSONSerialization JSONObjectWithData:[[self JSONString:str] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
      if (dict) {
        [events addObject:dict];
      }
    }
  }
  [logs removeAllObjects];
  return events;
}

+ (NSArray<NSDictionary *> *)getUserData
{
  NSMutableArray *flushLogs = [[NSMutableArray alloc] init];
  for (NSString *entry in logs) {
    if (entry.length == 0) {
      continue;
    }
    int startIdx;
    int endIdx;
    NSString *startStr = @"ud:";
    startIdx = (int)([entry rangeOfString:startStr].location);
    if (startIdx == NSNotFound || startIdx > entry.length - 1 || startIdx < 0) {
      continue;
    }
    endIdx = (int)entry.length;
    startIdx += startStr.length;
    if (startIdx < endIdx) {
      NSString *str = [entry substringWithRange:NSMakeRange(startIdx, endIdx - startIdx)];
      NSMutableDictionary *dict = [NSJSONSerialization JSONObjectWithData:[str dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
      if (dict) {
        [flushLogs addObject:dict];
      }
    }
  }
  [logs removeAllObjects];
  return flushLogs;
}

+ (NSString *)encryptData:(NSString *)data type:(FBSDKAppEventUserDataType)type
{
  if (data.length == 0 || [self maybeSHA256Hashed:data]) {
    return data;
  }
  return [FBSDKBasicUtility SHA256Hash:[self normalizeData:data type:type]];
}

+ (NSString *)normalizeData:(NSString *)data
                       type:(FBSDKAppEventUserDataType)type
{
  NSString *normalizedData = @"";
  NSSet<FBSDKAppEventUserDataType> *set = [NSSet setWithArray:
                                           @[FBSDKAppEventEmail, FBSDKAppEventFirstName, FBSDKAppEventLastName, FBSDKAppEventCity, FBSDKAppEventState, FBSDKAppEventCountry]];
  if ([set containsObject:type]) {
    normalizedData = [data stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    normalizedData = normalizedData.lowercaseString;
  } else if ([type isEqualToString:FBSDKAppEventPhone]) {
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[^0-9]"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error
    ];
    normalizedData = [regex stringByReplacingMatchesInString:data
                                                     options:0
                                                       range:NSMakeRange(0, data.length)
                                                withTemplate:@""
    ];
  } else if ([type isEqualToString:FBSDKAppEventGender]) {
    NSString *temp = [data stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    temp = temp.lowercaseString;
    normalizedData = temp.length > 0 ? [temp substringToIndex:1] : @"";
  } else if ([type isEqualToString:FBSDKAppEventExternalId]) {
    normalizedData = data;
  }
  return normalizedData;
}

+ (BOOL)maybeSHA256Hashed:(NSString *)data
{
  NSRange range = [data rangeOfString:@"[A-Fa-f0-9]{64}" options:NSRegularExpressionSearch];
  return (data.length == 64) && (range.location != NSNotFound);
}

+ (NSString *)JSONString:(NSString *)aString
{
  NSMutableString *s = [NSMutableString stringWithString:aString];
  [s replaceOccurrencesOfString:@"=" withString:@":" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
  [s replaceOccurrencesOfString:@";" withString:@"," options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
  [s replaceOccurrencesOfString:@"\n" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
  // a specific case for test page
  [s replaceOccurrencesOfString:@" UITabBarController" withString:@"\"UITabBarController\"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
  [s replaceOccurrencesOfString:@" event " withString:@"\"event\"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
  [s replaceOccurrencesOfString:@" extinfo " withString:@"\"extinfo\"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
  [s replaceOccurrencesOfString:@" ud " withString:@"\"ud\"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
  return [NSString stringWithString:s];
}

+ (UIWindow *)findWindow
{
  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Wdeprecated-declarations"
  UIWindow *topWindow = [UIApplication sharedApplication].keyWindow;
  #pragma clang diagnostic pop
  if (topWindow == nil || topWindow.windowLevel < UIWindowLevelNormal) {
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
      if (window.windowLevel >= topWindow.windowLevel && !window.isHidden) {
        topWindow = window;
      }
    }
  }

  if (topWindow != nil) {
    return topWindow;
  }

  // Find active key window from UIScene
  if (@available(iOS 13.0, *)) {
    NSSet *scenes = [[UIApplication sharedApplication] valueForKey:@"connectedScenes"];
    for (id scene in scenes) {
      id activationState = [scene valueForKeyPath:@"activationState"];
      BOOL isActive = activationState != nil && [activationState integerValue] == 0;
      if (isActive) {
        Class WindowScene = NSClassFromString(@"UIWindowScene");
        if ([scene isKindOfClass:WindowScene]) {
          NSArray<UIWindow *> *windows = [scene valueForKeyPath:@"windows"];
          for (UIWindow *window in windows) {
            if (window.isKeyWindow) {
              return window;
            } else if (window.windowLevel >= topWindow.windowLevel && !window.isHidden) {
              topWindow = window;
            }
          }
        }
      }
    }
  }

  if (topWindow == nil) {
    NSLog(@"Unable to find a valid UIWindow");
  }
  return topWindow;
}

+ (UIViewController *)topMostViewController
{
  UIWindow *keyWindow = [self findWindow];
  // SDK expects a key window at this point, if it is not, make it one
  if (keyWindow != nil && !keyWindow.isKeyWindow) {
    NSString *msg = [NSString stringWithFormat:@"Unable to obtain a key window, marking %@ as keyWindow", keyWindow.description];
    NSLog(@"%@", msg);
    [keyWindow makeKeyWindow];
  }

  UIViewController *topController = keyWindow.rootViewController;
  while (topController.presentedViewController) {
    topController = topController.presentedViewController;
  }
  return topController;
}

@end
