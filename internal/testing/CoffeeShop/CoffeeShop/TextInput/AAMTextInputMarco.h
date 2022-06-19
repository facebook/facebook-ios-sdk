// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#ifndef AAMTextInputMarco_h
#define AAMTextInputMarco_h

typedef NS_ENUM(NSUInteger, AutomaticMatchingPIIType) {
  AutomaticMatchingPhone = 0,
  AutomaticMatchingEmail,
  AutomaticMatchingFullName,
  AutomaticMatchingLastName,
  AutomaticMatchingFirstName,
  AutomaticMatchingAddress,
  // password is in the blacklist and is used to test whether it's mistakenly crawled
  AutomaticMatchingPassword,
};

typedef NS_ENUM(NSUInteger, TextInputType) {
  TextInputUIKit = 0,
  TextInputRCT,
};

#endif /* AAMTextInputMarco_h */
