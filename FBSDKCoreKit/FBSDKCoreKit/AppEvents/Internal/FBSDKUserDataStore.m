/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKUserDataStore.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKAppEventUserDataType.h"

static NSString *const FBSDKUserDataKey = @"com.facebook.appevents.UserDataStore.userData";
static NSString *const FBSDKInternalUserDataKey = @"com.facebook.appevents.UserDataStore.internalUserData";

static NSMutableDictionary<NSString *, NSString *> *hashedUserData;
static NSMutableDictionary<NSString *, NSString *> *internalHashedUserData;
static NSMutableSet<NSString *> *enabledRules;

static dispatch_queue_t serialQueue;

@implementation FBSDKUserDataStore

+ (void)initialize
{
  serialQueue = dispatch_queue_create("com.facebook.appevents.UserDataStore", DISPATCH_QUEUE_SERIAL);
  hashedUserData = [FBSDKUserDataStore initializeUserData:FBSDKUserDataKey];
  internalHashedUserData = [FBSDKUserDataStore initializeUserData:FBSDKInternalUserDataKey];
  enabledRules = [NSMutableSet new];
}

- (void)setUserEmail:(nullable NSString *)email
           firstName:(nullable NSString *)firstName
            lastName:(nullable NSString *)lastName
               phone:(nullable NSString *)phone
         dateOfBirth:(nullable NSString *)dateOfBirth
              gender:(nullable NSString *)gender
                city:(nullable NSString *)city
               state:(nullable NSString *)state
                 zip:(nullable NSString *)zip
             country:(nullable NSString *)country
          externalId:(nullable NSString *)externalId
{
  NSMutableDictionary<NSString *, NSString *> *ud = [NSMutableDictionary new];
  if (email) {
    [FBSDKTypeUtility dictionary:ud setObject:[self encryptData:email type:FBSDKAppEventEmail] forKey:FBSDKAppEventEmail];
  }
  if (firstName) {
    [FBSDKTypeUtility dictionary:ud setObject:[self encryptData:firstName type:FBSDKAppEventFirstName] forKey:FBSDKAppEventFirstName];
  }
  if (lastName) {
    [FBSDKTypeUtility dictionary:ud setObject:[self encryptData:lastName type:FBSDKAppEventLastName] forKey:FBSDKAppEventLastName];
  }
  if (phone) {
    [FBSDKTypeUtility dictionary:ud setObject:[self encryptData:phone type:FBSDKAppEventPhone] forKey:FBSDKAppEventPhone];
  }
  if (dateOfBirth) {
    [FBSDKTypeUtility dictionary:ud setObject:[self encryptData:dateOfBirth type:FBSDKAppEventDateOfBirth] forKey:FBSDKAppEventDateOfBirth];
  }
  if (gender) {
    [FBSDKTypeUtility dictionary:ud setObject:[self encryptData:gender type:FBSDKAppEventGender] forKey:FBSDKAppEventGender];
  }
  if (city) {
    [FBSDKTypeUtility dictionary:ud setObject:[self encryptData:city type:FBSDKAppEventCity] forKey:FBSDKAppEventCity];
  }
  if (state) {
    [FBSDKTypeUtility dictionary:ud setObject:[self encryptData:state type:FBSDKAppEventState] forKey:FBSDKAppEventState];
  }
  if (zip) {
    [FBSDKTypeUtility dictionary:ud setObject:[self encryptData:zip type:FBSDKAppEventZip] forKey:FBSDKAppEventZip];
  }
  if (country) {
    [FBSDKTypeUtility dictionary:ud setObject:[self encryptData:country type:FBSDKAppEventCountry] forKey:FBSDKAppEventCountry];
  }
  if (externalId) {
    [FBSDKTypeUtility dictionary:ud setObject:[self encryptData:externalId type:FBSDKAppEventExternalId] forKey:FBSDKAppEventExternalId];
  }

  dispatch_async(serialQueue, ^{
    hashedUserData = ud.mutableCopy;
    [NSUserDefaults.standardUserDefaults setObject:[self stringByHashedData:hashedUserData]
                                            forKey:FBSDKUserDataKey];
  });
}

- (void)setUserData:(nullable NSString *)data
            forType:(FBSDKAppEventUserDataType)type
{
  [self setHashData:[self encryptData:data type:type]
            forType:type];
}

- (void)setHashData:(nullable NSString *)hashData
            forType:(FBSDKAppEventUserDataType)type
{
  dispatch_async(serialQueue, ^{
    if (!hashData) {
      [hashedUserData removeObjectForKey:type];
    } else {
      [FBSDKTypeUtility dictionary:hashedUserData setObject:hashData forKey:type];
    }
    [NSUserDefaults.standardUserDefaults setObject:[self stringByHashedData:hashedUserData]
                                            forKey:FBSDKUserDataKey];
  });
}

- (void)setInternalHashData:(nullable NSString *)hashData
                    forType:(FBSDKAppEventUserDataType)type
{
  dispatch_async(serialQueue, ^{
    if (!hashData) {
      [internalHashedUserData removeObjectForKey:type];
    } else {
      internalHashedUserData[type] = hashData;
    }
    [NSUserDefaults.standardUserDefaults setObject:[self stringByHashedData:internalHashedUserData]
                                            forKey:FBSDKInternalUserDataKey];
  });
}

- (void)setEnabledRules:(NSArray<NSString *> *)rules
{
  if (rules.count > 0) {
    [enabledRules addObjectsFromArray:rules];
  }
}

- (void)clearUserDataForType:(FBSDKAppEventUserDataType)type
{
  [self setUserData:nil forType:type];
}

- (nullable NSString *)getUserData
{
  return [self getHashedData];
}

- (NSString *)getHashedData
{
  __block NSString *hashedUserDataString;
  dispatch_sync(serialQueue, ^{
    NSMutableDictionary<NSString *, NSString *> *hashedUD = [NSMutableDictionary new];
    [hashedUD addEntriesFromDictionary:hashedUserData];
    for (NSString *key in enabledRules) {
      if (internalHashedUserData[key]) {
        hashedUD[key] = internalHashedUserData[key];
      }
    }
    hashedUserDataString = [self stringByHashedData:hashedUD];
  });
  return hashedUserDataString;
}

- (void)clearUserData
{
  [self setUserEmail:nil
           firstName:nil
            lastName:nil
               phone:nil
         dateOfBirth:nil
              gender:nil
                city:nil
               state:nil
                 zip:nil
             country:nil
          externalId:nil];
}

- (nullable NSString *)getInternalHashedDataForType:(FBSDKAppEventUserDataType)type
{
  __block NSString *hashedData;
  dispatch_sync(serialQueue, ^{
    hashedData = [FBSDKTypeUtility dictionary:internalHashedUserData objectForKey:type ofType:NSObject.class];
  });
  return hashedData;
}

+ (NSMutableDictionary<NSString *, NSString *> *)initializeUserData:(NSString *)userDataKey
{
  NSString *userData = [NSUserDefaults.standardUserDefaults stringForKey:userDataKey];
  NSMutableDictionary<NSString *, NSString *> *hashedUD = nil;
  if (userData) {
    hashedUD = (NSMutableDictionary<NSString *, NSString *> *)[FBSDKTypeUtility JSONObjectWithData:[userData dataUsingEncoding:NSUTF8StringEncoding]
                                                             options: NSJSONReadingMutableContainers
                                                             error: nil];
  }
  if (!hashedUD) {
    hashedUD = [NSMutableDictionary new];
  }
  return hashedUD;
}

- (NSString *)stringByHashedData:(id)hashedData
{
  NSError *error;
  NSData *jsonData = [FBSDKTypeUtility dataWithJSONObject:hashedData
                                                  options:0
                                                    error:&error];
  if (jsonData) {
    return [[NSString alloc] initWithData:jsonData
                                 encoding:NSUTF8StringEncoding];
  } else {
    return @"";
  }
}

- (NSString *)encryptData:(NSString *)data
                     type:(FBSDKAppEventUserDataType)type
{
  if (data.length == 0 || [self maybeSHA256Hashed:data]) {
    return data;
  }
  return [FBSDKBasicUtility SHA256Hash:[self normalizeData:data type:type]];
}

- (NSString *)normalizeData:(NSString *)data
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

- (BOOL)maybeSHA256Hashed:(NSString *)data
{
  NSRange range = [data rangeOfString:@"[A-Fa-f0-9]{64}" options:NSRegularExpressionSearch];
  return (data.length == 64) && (range.location != NSNotFound);
}

@end
