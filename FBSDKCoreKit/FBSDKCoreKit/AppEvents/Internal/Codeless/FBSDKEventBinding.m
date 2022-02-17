/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKEventBinding.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKCodelessPathComponent.h"
#import "FBSDKEventLogging.h"
#import "FBSDKInternalUtility+Internal.h"
#import "FBSDKSwizzler.h"
#import "FBSDKUtility.h"
#import "FBSDKViewHierarchy.h"
#import "FBSDKViewHierarchyMacros.h"

#define CODELESS_PATH_TYPE_ABSOLUTE  @"absolute"
#define CODELESS_PATH_TYPE_RELATIVE  @"relative"
#define CODELESS_CODELESS_EVENT_KEY  @"_is_fb_codeless"
#define PARAMETER_NAME_PRICE          @"_valueToSum"

@interface FBSDKEventBinding ()

@property (nonnull, nonatomic) id<FBSDKEventLogging> eventLogger;

@end

@implementation FBSDKEventBinding

static id<FBSDKNumberParsing> _numberParser;

+ (id<FBSDKNumberParsing>)numberParser
{
  return _numberParser;
}

+ (void)setNumberParser:(id<FBSDKNumberParsing>)numberParser
{
  _numberParser = numberParser;
}

+ (void)initialize
{
  _numberParser = [[FBSDKAppEventsNumberParser alloc] initWithLocale:NSLocale.currentLocale];
}

- (FBSDKEventBinding *)initWithJSON:(nullable NSDictionary<NSString *, id> *)dict
                        eventLogger:(id<FBSDKEventLogging>)eventLogger
{
  if ((self = [super init])) {
    _eventLogger = eventLogger;

    _eventName = [dict[CODELESS_MAPPING_EVENT_NAME_KEY] copy];
    _eventType = [dict[CODELESS_MAPPING_EVENT_TYPE_KEY] copy];
    _appVersion = [dict[CODELESS_MAPPING_APP_VERSION_KEY] copy];
    _pathType = [dict[CODELESS_MAPPING_PATH_TYPE_KEY] copy];

    NSArray<NSDictionary<NSString *, id> *> *pathComponents = dict[CODELESS_MAPPING_PATH_KEY];
    NSMutableArray<FBSDKCodelessPathComponent *> *mut = [NSMutableArray array];
    for (NSDictionary<NSString *, id> *info in pathComponents) {
      FBSDKCodelessPathComponent *component = [[FBSDKCodelessPathComponent alloc] initWithJSON:info];
      [FBSDKTypeUtility array:mut addObject:component];
    }
    _path = [mut copy];

    NSArray<NSDictionary<NSString *, id> *> *parameters = dict[CODELESS_MAPPING_PARAMETERS_KEY];
    mut = [NSMutableArray array];
    for (NSDictionary<NSString *, id> *info in parameters) {
      FBSDKCodelessParameterComponent *component = [[FBSDKCodelessParameterComponent alloc] initWithJSON:info];
      [FBSDKTypeUtility array:mut addObject:component];
    }
    _parameters = [mut copy];
  }
  return self;
}

- (void)trackEvent:(nullable id)sender
{
  UIView *sourceView = [sender isKindOfClass:UIView.class] ? (UIView *)sender : nil;
  NSMutableDictionary<FBSDKAppEventParameterName, id> *params = [NSMutableDictionary dictionary];
  [FBSDKTypeUtility dictionary:params setObject:@"1" forKey:CODELESS_CODELESS_EVENT_KEY];
  for (FBSDKCodelessParameterComponent *component in self.parameters) {
    NSString *text = component.value;
    if (!text || text.length == 0) {
      text = [FBSDKEventBinding findParameterOfPath:component.path
                                           pathType:component.pathType
                                         sourceView:sourceView];
    }
    if (text.length > 0) {
      if ([component.name isEqualToString:PARAMETER_NAME_PRICE]) {
        NSNumber *value = [self.class.numberParser parseNumberFrom:text];
        [FBSDKTypeUtility dictionary:params setObject:value forKey:component.name];
      } else {
        [FBSDKTypeUtility dictionary:params setObject:text forKey:component.name];
      }
    }
  }

  [self.eventLogger logEvent:_eventName parameters:[params copy]];
}

+ (BOOL)matchAnyView:(NSArray<NSObject *> *)views
       pathComponent:(FBSDKCodelessPathComponent *)component
{
  for (NSObject *view in views) {
    if ([self match:view pathComponent:component]) {
      return YES;
    }
  }
  return NO;
}

+ (BOOL)  match:(NSObject *)view
  pathComponent:(FBSDKCodelessPathComponent *)component
{
  if (!view) {
    return NO;
  }
  NSString *className = NSStringFromClass(view.class);
  if (![className isEqualToString:component.className]) {
    return NO;
  }

  if (component.index >= 0) {
    NSObject *parent = [FBSDKViewHierarchy getParent:view];
    if (parent) {
      NSArray<NSObject *> *children = [FBSDKViewHierarchy getChildren:parent];
      NSUInteger index = [children indexOfObject:view];
      if (index == NSNotFound || index != component.index) {
        return NO;
      }
    } else {
      if (0 != component.index) {
        return NO;
      }
    }
  }

  if ((component.matchBitmask & FBSDKCodelessMatchBitmaskFieldText) > 0) {
    NSString *text = [FBSDKViewHierarchy getText:view];
    BOOL match = ((text.length == 0 && component.text.length == 0)
      || [text isEqualToString:component.text]);
    if (!match) {
      return NO;
    }
  }

  if ((component.matchBitmask & FBSDKCodelessMatchBitmaskFieldTag) > 0
      && [view isKindOfClass:UIView.class]
      && component.tag != ((UIView *)view).tag) {
    return NO;
  }

  if ((component.matchBitmask & FBSDKCodelessMatchBitmaskFieldHint) > 0) {
    NSString *hint = [FBSDKViewHierarchy getHint:view];
    BOOL match = ((hint.length == 0 && component.hint.length == 0)
      || [hint isEqualToString:component.hint]);
    if (!match) {
      return NO;
    }
  }

  return YES;
}

+ (BOOL)isPath:(nullable NSArray<FBSDKCodelessPathComponent *> *)path matchViewPath:(nullable NSArray<FBSDKCodelessPathComponent *> *)viewPath
{
  if ((path.count == 0) || (viewPath.count == 0)) {
    return NO;
  }

  for (NSInteger i = 0; i < MIN(path.count, viewPath.count); i++) {
    NSInteger idxPath = path.count - i - 1;
    NSInteger idxViewPath = viewPath.count - i - 1;

    FBSDKCodelessPathComponent *pathComponent = [FBSDKTypeUtility array:path objectAtIndex:idxPath];
    FBSDKCodelessPathComponent *viewPathComponent = [FBSDKTypeUtility array:viewPath objectAtIndex:idxViewPath];

    if (![pathComponent.className isEqualToString:viewPathComponent.className]) {
      return NO;
    }

    if (pathComponent.index >= 0
        && pathComponent.index != viewPathComponent.index) {
      return NO;
    }

    if ((pathComponent.matchBitmask & FBSDKCodelessMatchBitmaskFieldText) > 0) {
      NSString *text = viewPathComponent.text;
      BOOL match = ((text.length == 0 && pathComponent.text.length == 0)
        || [text isEqualToString:pathComponent.text]
        || [[FBSDKUtility SHA256Hash:text] isEqualToString:pathComponent.text]);
      if (!match) {
        return NO;
      }
    }

    if ((pathComponent.matchBitmask & FBSDKCodelessMatchBitmaskFieldTag) > 0
        && pathComponent.tag != viewPathComponent.tag) {
      return NO;
    }

    if ((pathComponent.matchBitmask & FBSDKCodelessMatchBitmaskFieldHint) > 0) {
      NSString *hint = viewPathComponent.hint;
      BOOL match = ((hint.length == 0 && pathComponent.hint.length == 0)
        || [hint isEqualToString:pathComponent.hint]
        || [[FBSDKUtility SHA256Hash:hint] isEqualToString:pathComponent.hint]);
      if (!match) {
        return NO;
      }
    }
  }

  return YES;
}

+ (nullable NSObject *)findViewByPath:(NSArray<FBSDKCodelessPathComponent *> *)path parent:(NSObject *)parent level:(int)level
{
  if (level >= path.count) {
    return nil;
  }

  FBSDKCodelessPathComponent *pathComponent = [FBSDKTypeUtility array:path objectAtIndex:level];

  // If found parent, skip to next level
  if ([pathComponent.className isEqualToString:CODELESS_MAPPING_PARENT_CLASS_NAME]) {
    NSObject *nextParent = [FBSDKViewHierarchy getParent:parent];

    return [FBSDKEventBinding findViewByPath:path parent:nextParent level:level + 1];
  } else if ([pathComponent.className isEqualToString:CODELESS_MAPPING_CURRENT_CLASS_NAME]) {
    return parent;
  }

  NSArray<NSObject *> *children;
  if (parent) {
    children = [FBSDKViewHierarchy getChildren:parent];
  } else {
    UIWindow *window = [FBSDKInternalUtility.sharedUtility findWindow];
    if (window) {
      children = @[window];
    } else {
      return nil;
    }
  }

  if (path.count - 1 == level) {
    int index = pathComponent.index;
    if (index >= 0) {
      NSObject *child = index < children.count ? [FBSDKTypeUtility array:children objectAtIndex:index] : nil;
      if ([self match:child pathComponent:pathComponent]) {
        return child;
      }
    } else {
      for (NSObject *child in children) {
        if ([self match:child pathComponent:pathComponent]) {
          return child;
        }
      }
    }
  } else {
    for (NSObject *child in children) {
      NSObject *result = [self findViewByPath:path parent:child level:level + 1];
      if (result) {
        return result;
      }
    }
  }

  return nil;
}

- (BOOL)isEqualToBinding:(FBSDKEventBinding *)binding
{
  if (_path.count != binding.path.count
      || _parameters.count != binding.parameters.count) {
    return NO;
  }

  NSString *current = [NSString stringWithFormat:@"%@|%@|%@|%@",
                       _eventName ?: @"",
                       _eventType ?: @"",
                       _appVersion ?: @"",
                       _pathType ?: @""];
  NSString *compared = [NSString stringWithFormat:@"%@|%@|%@|%@",
                        binding.eventName ?: @"",
                        binding.eventType ?: @"",
                        binding.appVersion ?: @"",
                        binding.pathType ?: @""];
  if (![current isEqualToString:compared]) {
    return NO;
  }

  for (int i = 0; i < _path.count; i++) {
    if (![[FBSDKTypeUtility array:_path objectAtIndex:i] isEqualToPath:[FBSDKTypeUtility array:binding.path objectAtIndex:i]]) {
      return NO;
    }
  }

  for (int i = 0; i < _parameters.count; i++) {
    if (![[FBSDKTypeUtility array:_parameters objectAtIndex:i] isEqualToParameter:[FBSDKTypeUtility array:binding.parameters objectAtIndex:i]]) {
      return NO;
    }
  }

  return YES;
}

// MARK: - find event parameters via relative path
+ (nullable NSString *)findParameterOfPath:(NSArray<FBSDKCodelessPathComponent *> *)path
                                  pathType:(NSString *)pathType
                                sourceView:(UIView *)sourceView
{
  if (0 == path.count) {
    return nil;
  }

  UIView *rootView = sourceView;
  if (![pathType isEqualToString:CODELESS_PATH_TYPE_RELATIVE]) {
    rootView = nil;
  }

  NSObject *foundObj = [self findViewByPath:path parent:rootView level:0];

  return [FBSDKViewHierarchy getText:foundObj];
}

@end

#endif
