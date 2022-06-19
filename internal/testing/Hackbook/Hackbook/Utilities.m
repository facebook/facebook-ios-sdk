// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "Utilities.h"

#import <Security/Security.h>

#import "Console.h"

#define KEYCHAIN_APP_SECRET_KEY @"com.facebook.hackbook.appsecret"

NSString *const FacebookBaseDomain = @"facebook.com";
static NSString *_appSecret;

NSString *AsciiString(NSString *string)
{
  NSMutableArray<NSString *> *const asciiChars = [NSMutableArray array];
  [string enumerateSubstringsInRange:NSMakeRange(0, [string length])
                             options:NSStringEnumerationByComposedCharacterSequences
                          usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                            if (substring.length == 1) {
                              const char *subchar = [substring UTF8String];
                              if (subchar != nil) {
                                if (((*subchar >= 'a') && (*subchar <= 'z'))
                                    || ((*subchar >= 'A') && (*subchar <= 'Z'))
                                    || ((*subchar >= '0') && (*subchar <= '9'))) {
                                  [asciiChars addObject:substring];
                                } else if (*subchar == '+') {
                                  [asciiChars addObject:@"Plus"];
                                }
                              }
                            }
                          }];
  return [asciiChars componentsJoinedByString:@""];
}

NSString *StringForJSONObject(id JSONObject)
{
  if (![NSJSONSerialization isValidJSONObject:JSONObject]) {
    ConsoleReportBug(@"Invalid JSON object: %@", JSONObject);
    return nil;
  }
  NSError *error;
  NSData *resultData = [NSJSONSerialization dataWithJSONObject:JSONObject options:0 error:&error];
  if (!resultData) {
    ConsoleError(error, @"Error serializing result to JSON: %@", JSONObject);
    return nil;
  }
  return [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
}

void SetAppSecret(NSString *appSecret)
{
  _appSecret = appSecret;
  NSDictionary *keychainQuery = @{
    (__bridge id)kSecAttrAccount : KEYCHAIN_APP_SECRET_KEY,
    (__bridge id)kSecValueData : [appSecret dataUsingEncoding:NSUTF8StringEncoding],
    (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
    (__bridge id)kSecAttrAccessible : (__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
  };
  SecItemAdd((__bridge CFDictionaryRef)keychainQuery, nil);
}

NSString *GetAppSecret(void)
{
  if (_appSecret == nil) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      NSDictionary *keychainQuery = @{
        (__bridge id)kSecAttrAccount : KEYCHAIN_APP_SECRET_KEY,
        (__bridge id)kSecReturnData : (__bridge id)kCFBooleanTrue,
        (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword
      };

      CFDataRef dataRef;
      OSStatus result = SecItemCopyMatching((__bridge CFDictionaryRef)keychainQuery, (CFTypeRef *)&dataRef);
      if (result == noErr) {
        NSData *data = (__bridge_transfer NSData *)dataRef;
        if (data) {
          _appSecret = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
      }
    });
  }
  return _appSecret;
}
