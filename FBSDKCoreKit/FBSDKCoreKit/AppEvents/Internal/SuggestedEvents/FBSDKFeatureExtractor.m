/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKFeatureExtractor.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKModelManager.h"
#import "FBSDKRulesFromKeyProvider.h"
#import "FBSDKViewHierarchy.h"
#import "FBSDKViewHierarchyMacros.h"

#define REGEX_CR_PASSWORD_FIELD @"password"
#define REGEX_CR_HAS_CONFIRM_PASSWORD_FIELD @"(?i)(confirm.*password)|(password.*(confirmation|confirm)|confirmation)"
#define REGEX_CR_HAS_LOG_IN_KEYWORDS @"(?i)(sign in)|login|signIn"
#define REGEX_CR_HAS_SIGN_ON_KEYWORDS \
  @"(?i)(sign.*(up|now)|registration|" \
  @"register|(create|apply).*(profile|account)|open.*account|" \
  @"account.*(open|creation|application)|enroll|join.*now)"
#define REGEX_ADD_TO_CART_BUTTON_TEXT @"(?i)add to(\\s|\\Z)|update(\\s|\\Z)|cart"
#define REGEX_ADD_TO_CART_PAGE_TITLE @"(?i)add to(\\s|\\Z)|update(\\s|\\Z)|cart|shop|buy"

static NSDictionary<NSString *, id> *_languageInfo;
static NSDictionary<NSString *, id> *_eventInfo;
static NSDictionary<NSString *, id> *_textTypeInfo;
static NSDictionary<NSString *, id> *_rules;

void sum(float *val0, float *val1);

@implementation FBSDKFeatureExtractor

static id<FBSDKRulesFromKeyProvider> _rulesFromKeyProvider;

+ (nullable id<FBSDKRulesFromKeyProvider>)rulesFromKeyProvider
{
  return _rulesFromKeyProvider;
}

+ (void)setRulesFromKeyProvider:(nullable id<FBSDKRulesFromKeyProvider>)rulesFromKeyProvider
{
  _rulesFromKeyProvider = rulesFromKeyProvider;
}

+ (void)configureWithRulesFromKeyProvider:(id<FBSDKRulesFromKeyProvider>)rulesFromKeyProvider
{
  if (self == FBSDKFeatureExtractor.class) {
    self.rulesFromKeyProvider = rulesFromKeyProvider;
  }
}

+ (void)initialize
{
  _languageInfo = @{
    @"ENGLISH" : @"1",
    @"GERMAN" : @"2",
    @"SPANISH" : @"3",
    @"JAPANESE" : @"4"
  };
  _eventInfo = @{
    @"VIEW_CONTENT" : @"0",
    @"SEARCH" : @"1",
    @"ADD_TO_CART" : @"2",
    @"ADD_TO_WISHLIST" : @"3",
    @"INITIATE_CHECKOUT" : @"4",
    @"ADD_PAYMENT_INFO" : @"5",
    @"PURCHASE" : @"6",
    @"LEAD" : @"7",
    @"COMPLETE_REGISTRATION" : @"8"
  };
  _textTypeInfo = @{
    @"BUTTON_TEXT" : @"1",
    @"PAGE_TITLE" : @"2",
    @"RESOLVED_DOCUMENT_LINK" : @"3",
    @"BUTTON_ID" : @"4"
  };
}

+ (void)loadRulesForKey:(NSString *)useCaseKey
{
  BOOL isValid = [useCaseKey isKindOfClass:NSString.class];
  if (isValid) {
    _rules = [self.rulesFromKeyProvider getRulesForKey:useCaseKey];
  }
}

+ (NSString *)getTextFeature:(NSString *)text
              withScreenName:(NSString *)screenName
{
  // use "|" and "," to separate different text based on the rule of how text processed during training
  NSString *appName = [FBSDKTypeUtility dictionary:[NSBundle.mainBundle infoDictionary] objectForKey:(NSString *)kCFBundleNameKey ofType:NSObject.class];
  return [[NSString stringWithFormat:@"%@ | %@, %@", appName, screenName, text] lowercaseString];
}

+ (nullable float *)getDenseFeatures:(NSDictionary<NSString *, id> *)viewHierarchy
{
  if (!_rules) {
    return nil;
  }
  viewHierarchy = [FBSDKTypeUtility dictionaryValue:viewHierarchy];

  NSMutableArray<NSMutableDictionary<NSString *, id> *> *viewTree = [[FBSDKTypeUtility arrayValue:viewHierarchy[VIEW_HIERARCHY_VIEW_KEY]] mutableCopy];
  NSString *screenName = viewHierarchy[VIEW_HIERARCHY_SCREEN_NAME_KEY];
  NSMutableArray<NSMutableDictionary<NSString *, id> *> *siblings = [NSMutableArray array];

  [self pruneTree:[viewTree.firstObject mutableCopy] siblings:siblings];

  float *result = [self parseFeatures:viewTree.firstObject];

  NSMutableDictionary<NSString *, id> *interactedNode;
  for (NSMutableDictionary<NSString *, id> *node in siblings) {
    if ([[FBSDKTypeUtility dictionary:node objectForKey:VIEW_HIERARCHY_IS_INTERACTED_KEY ofType:NSObject.class] boolValue]) {
      interactedNode = node;
    }
  }

  NSString *viewTreeString;
  if ([NSJSONSerialization isValidJSONObject:viewTree]) {
    viewTreeString = [[NSString alloc] initWithData:[FBSDKTypeUtility dataWithJSONObject:viewTree options:0 error:nil] encoding:NSUTF8StringEncoding];
  }

  float *nonparseResult = [self nonparseFeatures:interactedNode siblings:siblings screenname:screenName viewTreeString:viewTreeString];
  sum(result, nonparseResult);
  free(nonparseResult);

  return result;
}

#pragma mark - Helper functions
+ (BOOL)pruneTree:(NSMutableDictionary<NSString *, id> *)node
         siblings:(NSMutableArray<NSMutableDictionary<NSString *, id> *> *)siblings
{
  // If it's interacted, don't prune away the children and just return.
  BOOL isInteracted = [[FBSDKTypeUtility dictionary:node
                                       objectForKey:VIEW_HIERARCHY_IS_INTERACTED_KEY
                                             ofType:NSNumber.class] boolValue];
  if (isInteracted) {
    return true;
  }

  NSMutableArray<NSMutableDictionary<NSString *, id> *> *newChildren = [NSMutableArray array];
  // If a child is interacted, we're at the right level and we want to grab everything
  BOOL isChildInteracted = NO;
  BOOL isDescendantInteracted = NO;

  NSMutableArray<NSMutableDictionary<NSString *, id> *> *childviews = [FBSDKTypeUtility dictionary:node objectForKey:VIEW_HIERARCHY_CHILD_VIEWS_KEY ofType:NSObject.class];
  for (NSMutableDictionary<NSString *, id> *child in childviews) {
    if ([[FBSDKTypeUtility dictionary:child
                         objectForKey:VIEW_HIERARCHY_IS_INTERACTED_KEY
                               ofType:NSNumber.class] boolValue]) {
      isChildInteracted = YES;
      isDescendantInteracted = YES;
    }
  }

  if (isChildInteracted) {
    [siblings addObjectsFromArray:childviews];
  } else {
    for (NSMutableDictionary<NSString *, id> *c in childviews) {
      NSMutableDictionary<NSString *, id> *child = [c mutableCopy];
      if ([self pruneTree:child siblings:siblings]) {
        isDescendantInteracted = YES;
        [FBSDKTypeUtility array:newChildren addObject:child];
      }
    }
    [FBSDKTypeUtility dictionary:node setObject:newChildren forKey:VIEW_HIERARCHY_CHILD_VIEWS_KEY];
  }

  return isDescendantInteracted;
}

+ (float *)nonparseFeatures:(NSMutableDictionary<NSString *, id> *)node
                   siblings:(NSMutableArray<NSMutableDictionary<NSString *, id> *> *)siblings
                 screenname:(NSString *)screenname
             viewTreeString:(NSString *)viewTreeString
{
  float *densefeat = (float *)calloc(30, sizeof(float));

  densefeat[3] = MAX((float)siblings.count - 1, 0);

  densefeat[9] = [siblings filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL (id _Nullable evaluatedObject, NSDictionary<NSString *, id> *_Nullable bindings) {
    return [self isButton:evaluatedObject];
  }]].count;
  if ([self isButton:node]) {
    densefeat[9] -= 1;
  }

  densefeat[13] = -1;
  densefeat[14] = -1;

  NSString *pageTitle = screenname ?: @"";
  NSString *formFieldsJSON = viewTreeString;
  NSString *buttonID = @"";
  NSString *buttonText = @"";

  if ([self isButton:node]) {
    NSMutableString *buttonTextString = [NSMutableString string];
    NSMutableString *buttonHintString = [NSMutableString string];
    [self update:node text:buttonTextString hint:buttonHintString];
    buttonText = (NSString *)buttonTextString;
    buttonID = (NSString *)buttonHintString;
  }

  // Regex features
  densefeat[15] = [self regexMatch:@"ENGLISH" event:@"COMPLETE_REGISTRATION" textType:@"BUTTON_TEXT" matchText:buttonText];
  densefeat[16] = [self regexMatch:@"ENGLISH" event:@"COMPLETE_REGISTRATION" textType:@"PAGE_TITLE" matchText:pageTitle];
  densefeat[17] = [self regexMatch:@"ENGLISH" event:@"COMPLETE_REGISTRATION" textType:@"BUTTON_ID" matchText:buttonID];

  densefeat[18] = [formFieldsJSON containsString:REGEX_CR_PASSWORD_FIELD] ? 1.0 : 0.0;

  densefeat[19] = [self regextMatch:REGEX_CR_HAS_CONFIRM_PASSWORD_FIELD text:formFieldsJSON];
  densefeat[20] = [self regextMatch:REGEX_CR_HAS_LOG_IN_KEYWORDS text:formFieldsJSON];
  densefeat[21] = [self regextMatch:REGEX_CR_HAS_SIGN_ON_KEYWORDS text:formFieldsJSON];

  // Purchase specific features
  densefeat[22] = [self regexMatch:@"ENGLISH" event:@"PURCHASE" textType:@"BUTTON_TEXT" matchText:buttonText];
  densefeat[24] = [self regexMatch:@"ENGLISH" event:@"PURCHASE" textType:@"PAGE_TITLE" matchText:pageTitle];

  // AddToCart specific features
  densefeat[25] = [self regextMatch:REGEX_ADD_TO_CART_BUTTON_TEXT text:buttonText];
  densefeat[27] = [self regextMatch:REGEX_ADD_TO_CART_PAGE_TITLE text:pageTitle];

  // Lead specific features
  densefeat[28] = [self regexMatch:@"ENGLISH" event:@"LEAD" textType:@"BUTTON_TEXT" matchText:buttonText];
  densefeat[29] = [self regexMatch:@"ENGLISH" event:@"LEAD" textType:@"PAGE_TITLE" matchText:pageTitle];

  return densefeat;
}

+ (float *)parseFeatures:(NSMutableDictionary<NSString *, id> *)node
{
  float *densefeat = (float *)calloc(30, sizeof(float));

  NSString *validText = [FBSDKTypeUtility coercedToStringValue:node[VIEW_HIERARCHY_TEXT_KEY]];
  NSString *validHint = [FBSDKTypeUtility coercedToStringValue:node[VIEW_HIERARCHY_HINT_KEY]];
  NSString *validClassName = [FBSDKTypeUtility coercedToStringValue:node[VIEW_HIERARCHY_CLASS_NAME_KEY]];

  NSString *text = [validText lowercaseString] ?: @"";
  NSString *hint = [validHint lowercaseString] ?: @"";
  NSString *className = [validClassName lowercaseString] ?: @"";

  if ([self foundIndicators:[@"$,amount,price,total" componentsSeparatedByString:@","]
                   inValues:@[text, hint]]) {
    densefeat[0] += 1.0;
  }

  if ([self foundIndicators:[@"password,pwd" componentsSeparatedByString:@","]
                   inValues:@[text, hint]]) {
    densefeat[1] += 1.0;
  }

  if ([self foundIndicators:[@"phone,tel" componentsSeparatedByString:@","]
                   inValues:@[text, hint]]) {
    densefeat[2] += 1.0;
  }

  if ([self foundIndicators:@[@"search"]
                   inValues:@[text, hint]]) {
    densefeat[4] += 1.0;
  }

  // Input field with general text
  if ([className containsString:@"text"] && [className containsString:@"edit"]) {
    densefeat[5] += 1.0;
  }

  // Input field with number or phone
  if (([className containsString:@"num"] || [className containsString:@"phone"]) && [className containsString:@"edit"]) {
    densefeat[6] += 1.0;
  }

  if ([hint containsString:@"email"] || [text containsString:@"@"]) {
    densefeat[7] += 1.0;
  }

  // Check Box
  if ([className containsString:@"checkbox"]) {
    densefeat[8] += 1.0;
  }

  if ([self foundIndicators:[@"complete,confirm,done,submit" componentsSeparatedByString:@","]
                   inValues:@[text]]) {
    densefeat[10] += 1.0;
  }

  densefeat[11] = 0.0;

  // Radio Button
  if ([className containsString:@"radio"] && [className containsString:@"button"]) {
    densefeat[12] += 1.0;
  }

  NSMutableArray<NSMutableDictionary<NSString *, id> *> *childviews = node[VIEW_HIERARCHY_CHILD_VIEWS_KEY];

  for (int i = 0; i < childviews.count; i++) {
    sum(densefeat, [self parseFeatures:[FBSDKTypeUtility array:childviews objectAtIndex:i]]);
  }

  return densefeat;
}

void sum(float *val0, float *val1)
{
  for (int i = 0; i < 30; i++) {
    val0[i] += val1[i];
  }
}

+ (BOOL)isButton:(NSDictionary<NSString *, id> *)node
{
  NSDictionary<NSString *, id> *dictionary = node;
  if (!dictionary) {
    dictionary = [NSMutableDictionary new];
  }
  int classtypebitmask = [[FBSDKTypeUtility dictionary:dictionary
                                          objectForKey:VIEW_HIERARCHY_CLASS_TYPE_BITMASK_KEY
                                                ofType:NSString.class] intValue];
  return (classtypebitmask & FBCodelessClassBitmaskUIButton) > 0;
}

+ (void)update:(NSDictionary<NSString *, id> *)node
          text:(NSMutableString *)buttonTextString
          hint:(NSMutableString *)buttonHintString
{
  NSString *text = [[FBSDKTypeUtility dictionary:node
                                    objectForKey:VIEW_HIERARCHY_TEXT_KEY
                                          ofType:NSString.class] lowercaseString];
  NSString *hint = [[FBSDKTypeUtility dictionary:node
                                    objectForKey:VIEW_HIERARCHY_HINT_KEY
                                          ofType:NSString.class] lowercaseString];
  if (text.length > 0) {
    [buttonTextString appendFormat:@"%@ ", text];
  }
  if (hint.length > 0) {
    [buttonHintString appendFormat:@"%@ ", hint];
  }

  NSMutableArray<NSMutableDictionary<NSString *, id> *> *childviews = node[VIEW_HIERARCHY_CHILD_VIEWS_KEY];
  for (NSMutableDictionary<NSString *, id> *child in childviews) {
    [self update:child text:buttonTextString hint:buttonHintString];
  }
}

+ (BOOL)foundIndicators:(NSArray<NSString *> *)indicators inValues:(NSArray<NSString *> *)values
{
  for (NSString *indicator in indicators) {
    for (NSString *value in values) {
      if ([value containsString:indicator]) {
        return YES;
      }
    }
  }

  return NO;
}

+ (float)regextMatch:(NSString *)pattern text:(NSString *)text
{
  NSString *validText = [FBSDKTypeUtility coercedToStringValue:text];
  if (!validText) {
    return 0.0;
  }

  NSString *validPattern = [FBSDKTypeUtility coercedToStringValue:pattern];
  if (!validPattern) {
    return 0.0;
  }

  NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
  NSRange range = NSMakeRange(0, validText.length);
  NSArray<NSTextCheckingResult *> *matched = [re matchesInString:validText options:0 range:range];
  return matched.count > 0 ? 1.0 : 0.0;
}

+ (float)regexMatch:(NSString *)language
              event:(NSString *)event
           textType:(NSString *)textType
          matchText:(NSString *)matchText
{
  NSString *pattern = _rules[@"rulesForLanguage"][_languageInfo[language]]
  [@"rulesForEvent"][_eventInfo[event]]
  [@"positiveRules"][_textTypeInfo[textType]];
  return [self regextMatch:pattern text:matchText];
}

#if DEBUG && FBTEST

+ (void)reset
{
  self.rulesFromKeyProvider = nil;
}

#endif

@end

#endif
