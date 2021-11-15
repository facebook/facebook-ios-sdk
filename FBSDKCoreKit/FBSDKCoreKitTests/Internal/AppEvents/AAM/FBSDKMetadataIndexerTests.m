/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <XCTest/XCTest.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKMetadataIndexer.h"
#import "FBSDKMetadataIndexer+Testing.h"

@interface FBSDKMetadataIndexerTests : XCTestCase

@property (nonatomic) FBSDKMetadataIndexer *metadataIndexer;
@property (nonatomic) UITextField *emailField;
@property (nonatomic) UITextView *emailView;
@property (nonatomic) UITextField *phoneField;
@property (nonatomic) UITextView *phoneView;
@property (nonatomic) UITextField *pwdField;
@property (nonatomic) UITextView *pwdView;
@property (nonatomic) TestUserDataStore *userDataStore;
@property (nonatomic) NSDictionary<NSString *, id> *rules;

@end

@implementation FBSDKMetadataIndexerTests

- (void)setUp
{
  self.userDataStore = [TestUserDataStore new];
  self.metadataIndexer = [[FBSDKMetadataIndexer alloc] initWithUserDataStore:self.userDataStore
                                                                    swizzler:TestSwizzler.class];
  self.rules = @{
    @"r1" : @{
      @"k" : @"email,e-mail,em,electronicmail",
      @"v" : @"^([A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,})$",
    },
    @"r2" : @{
      @"k" : @"phone,mobile,contact",
      @"v" : @"^([0-9]{5,15})$",
    },
    @"r3" : @{
      @"k" : @"gender,gen,sex",
      @"v" : @"^(male|boy|man|female|girl|woman)$",
    },
    @"r4" : @{
      @"k" : @"city",
      @"v" : @"",
    },
    @"r5" : @{
      @"k" : @"state,province",
      @"v" : @"",
    },
    @"r6" : @{
      @"k" : @"zip,zcode,pincode,pcode,postalcode,postcode",
      @"v" : @"(^\\d{5}$)|(^\\d{9}$)|(^\\d{5}-\\d{4}$)",
    },
    @"r7" : @{
      @"k" : @"firstname,first name,fn,fname,givenname,forename",
      @"v" : @"",
    },
    @"r8" : @{
      @"k" : @"lastname,last name,ln,lname,surname,sname,familyname",
      @"v" : @"",
    },
  };
  [self.metadataIndexer constructRules:self.rules];
  [self.metadataIndexer initStore];

  // clear store
  for (NSString *key in self.rules) {
    [FBSDKTypeUtility dictionary:self.metadataIndexer.store setObject:[NSMutableArray new] forKey:key];
  }

  self.emailField = [UITextField new];
  self.emailField.placeholder = NSLocalizedString(@"Enter your email", nil);
  self.emailField.keyboardType = UIKeyboardTypeEmailAddress;

  self.emailView = [UITextView new];
  self.emailView.keyboardType = UIKeyboardTypeEmailAddress;

  self.phoneField = [UITextField new];
  self.phoneField.placeholder = NSLocalizedString(@"Enter your phone", nil);
  self.phoneField.keyboardType = UIKeyboardTypePhonePad;

  self.pwdField = [UITextField new];
  self.pwdField.placeholder = NSLocalizedString(@"Enter your password", nil);
  self.pwdField.secureTextEntry = YES;

  self.pwdView = [UITextView new];
  self.pwdView.secureTextEntry = YES;
}

- (void)tearDown
{
  [TestSwizzler reset];

  [super tearDown];
}

- (void)testCreatingWithDependencies
{
  XCTAssertEqualObjects(
    self.metadataIndexer.userDataStore,
    self.userDataStore,
    "Should use the provided user data store"
  );
  XCTAssertEqualObjects(
    self.metadataIndexer.swizzler,
    TestSwizzler.class,
    "Should use the provided swizzler"
  );
}

- (void)testInitStore
{
  XCTAssertEqual(
    self.userDataStore.getInternalHashedDataForTypeCallCount,
    self.rules.count,
    "Should request the internal hashed data for each rule"
  );
}

- (void)testSetupWithMissingRules
{
  [self.metadataIndexer setupWithRules:nil];

  XCTAssertNil(
    self.userDataStore.capturedEnableRules,
    "Should not invoke the user data store when there are missing rules"
  );
}

- (void)testSetupWithEmptyRules
{
  [self.metadataIndexer setupWithRules:@{}];

  XCTAssertNil(
    self.userDataStore.capturedEnableRules,
    "Should not invoke the user data store when there are empty rules"
  );
}

- (void)testSetupWithRules
{
  [self.metadataIndexer setupWithRules:self.rules];

  XCTAssertEqualObjects(
    self.userDataStore.capturedEnableRules,
    self.rules.allKeys,
    "Should enable all of the rules passed to the setup"
  );
}

- (void)testCheckAndAppendDataForKeyWithUnknownKey
{
  [self.metadataIndexer checkAndAppendData:self.name forKey:@"foo"];

  XCTAssertNil(
    self.userDataStore.capturedInternalHashedDataForTypeData,
    "Should not set data for a key that is not in the known rules"
  );
  XCTAssertNil(
    self.userDataStore.capturedInternalHashedDataForTypeType,
    "Should not set data for a key that is not in the known rules"
  );
}

- (void)testCheckAndAppendDataForKeyWithKeyMatchingRule
{
  /* Assumes the indexer is set up with the rule:
   @"r1" : @{
     @"k" : @"email,e-mail,em,electronicmail",
     @"v" : @"^([A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,})$",
   },
   */
  NSString *expected = [FBSDKBasicUtility SHA256Hash:self.name];
  [self.metadataIndexer checkAndAppendData:self.name forKey:@"r1"];

  XCTAssertEqualObjects(
    self.userDataStore.capturedInternalHashedDataForTypeData,
    expected,
    "Should hash and set the provided data"
  );
}

- (void)testCheckAndAppendDataForKeyWithEmptyData
{
  [self.metadataIndexer checkAndAppendData:@"" forKey:@"key"];

  XCTAssertNil(
    self.userDataStore.capturedInternalHashedDataForTypeData,
    "Shouldn't set empty hashed data"
  );
}

// test for geting secure text entry in UITextField
- (void)testCheckSecureTextEntryOfTextField
{
  // without secure text
  XCTAssertFalse(
    [self.metadataIndexer checkSecureTextEntry:self.emailField],
    @"test for UITextField without secure text"
  );

  // with secure text
  XCTAssertTrue(
    [self.metadataIndexer checkSecureTextEntry:self.pwdField],
    @"test for UITextField with secure text"
  );
}

// test for geting secure text entry in UITextView
- (void)testCheckSecureTextEntryOfTextView
{
  // without secure text
  XCTAssertFalse(
    [self.metadataIndexer checkSecureTextEntry:self.emailView],
    @"test for UITextView without secure text"
  );

  // with secure text
  XCTAssertTrue([self.metadataIndexer checkSecureTextEntry:self.pwdView], @"test for UITextView with secure text");
}

// test for geting keyboard type from UITextField
- (void)testGetKeyboardTypeOfTextField
{
  XCTAssertEqual(
    self.emailField.keyboardType,
    [self.metadataIndexer getKeyboardType:self.emailField],
    @"test for geting keyboard type from UITextField"
  );
}

// test for geting keyboard type from UITextView
- (void)testGetKeyboardTypeOfTextView
{
  XCTAssertEqual(
    self.emailView.keyboardType,
    [self.metadataIndexer getKeyboardType:self.emailView],
    @"test for geting keyboard type from UITextView"
  );
}

// test for geting metadata with valid email
- (void)testGetMetadataWithEmail
{
  NSString *text = @"test@fb.com";
  [self.metadataIndexer getMetadataWithText:text
                                placeholder:@"Enter your Email"
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeEmailAddress];
  XCTAssertEqualObjects(
    [[self.metadataIndexer.store valueForKey:@"r1"] firstObject],
    [FBSDKUtility SHA256Hash:text],
    "Getting metadata with a valid email should check rules related to emails."
  );
  XCTAssertEqual(
    [[self.metadataIndexer.store valueForKey:@"r2"] count],
    0,
    "Getting metadata with a valid email should not check rules related to phone numbers."
  );
}

// test for geting metadata with valid phone number
- (void)testGetMetadataWithPhoneNumber
{
  NSString *text = @"1112223333";
  [self.metadataIndexer getMetadataWithText:text
                                placeholder:@"Enter your Phone Number"
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypePhonePad];
  XCTAssertEqualObjects(
    [[self.metadataIndexer.store valueForKey:@"r2"] firstObject],
    [FBSDKUtility SHA256Hash:text],
    "Getting metadata with a valid phone number should check rules related to phone numbers."
  );
  XCTAssertEqual(
    [[self.metadataIndexer.store valueForKey:@"r1"] count],
    0,
    "Getting metadata with a valid phone number should not check rules related to emails."
  );
}

// test for geting metadata with valid phone number or zipcode with labels
- (void)testGetMetadataWithPhoneNumberWithLabels
{
  NSString *text = @"11122";
  [self.metadataIndexer getMetadataWithText:text
                                placeholder:@""
                                     labels:@[@"phone", @"zipcode"]
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypePhonePad];
  XCTAssertEqualObjects(
    [[self.metadataIndexer.store valueForKey:@"r2"] firstObject],
    [FBSDKUtility SHA256Hash:text],
    "Getting metadata with a phone number or zipcode with label should check rules related to phone numbers."
  );
  XCTAssertEqualObjects(
    [[self.metadataIndexer.store valueForKey:@"r6"] firstObject],
    [FBSDKUtility SHA256Hash:text],
    "Getting metadata with a phone number or zipcode with label should check rules related to zipcodes."
  );
}

// test for geting metadata with secure text
- (void)testGetMetadataWithSecureText
{
  NSString *text = @"dfjald1314";
  [self.metadataIndexer getMetadataWithText:text
                                placeholder:@"Enter your Pass-word"
                                     labels:nil
                            secureTextEntry:YES
                                  inputType:UIKeyboardTypeDefault];
  XCTAssertEqual(
    [[self.metadataIndexer.store valueForKey:@"r1"] count],
    0,
    "Getting metadata with a secret text should not check rules related to emails."
  );
  XCTAssertEqual(
    [[self.metadataIndexer.store valueForKey:@"r2"] count],
    0,
    "Getting metadata with a secret text should not check rules related to phone numbers."
  );
}

// test for geting metadata with invalid email
- (void)testGetMetadataWithInvalidEmail
{
  NSString *text = @"test";
  [self.metadataIndexer getMetadataWithText:text
                                placeholder:@"Enter your Email"
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeEmailAddress];
  XCTAssertEqual(
    [[self.metadataIndexer.store valueForKey:@"r1"] count],
    0,
    "Getting metadata with an invalid email should not check rules related to emails."
  );
  XCTAssertEqual(
    [[self.metadataIndexer.store valueForKey:@"r2"] count],
    0,
    "Getting metadata with an invalid email should not check rules related to phone numbers."
  );
}

// test for geting metadata with invalid email placeholder
- (void)testGetMetadataWithInvalidEmailPlaceholder
{
  NSString *text = @"test@fb.com";
  [self.metadataIndexer getMetadataWithText:text
                                placeholder:@"Enter your"
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeEmailAddress];
  XCTAssertEqual(
    [[self.metadataIndexer.store valueForKey:@"r1"] count],
    0,
    "Getting metadata with an invalid email placeholder should not check rules related to emails."
  );
  XCTAssertEqual(
    [[self.metadataIndexer.store valueForKey:@"r2"] count],
    0,
    "Getting metadata with an invalid email placeholder should not check rules related to phone numbers."
  );
}

// test for getting metadata with valid phone number containing +-().
- (void)testGetMetadataWithValidPhoneNumberWithPunctuations
{
  NSString *text = @"+1(222)-333-444";
  [self.metadataIndexer getMetadataWithText:text
                                placeholder:@"Enter your Phone Number"
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypePhonePad];
  XCTAssertTrue(
    [[self.metadataIndexer.store valueForKey:@"r2"] containsObject:[FBSDKUtility SHA256Hash:@"1222333444"]],
    "Getting metadata with a phone number with punctuations should check rules related to phone numbers with pure numbers."
  );
  XCTAssertFalse(
    [[self.metadataIndexer.store valueForKey:@"r2"] containsObject:[FBSDKUtility SHA256Hash:text]],
    "Getting metadata with a phone number with punctuations should not check rules related to phone numbers with the original text."
  );
}

// test for geting metadata with invalid phone number
- (void)testGetMetadataWithInvalidPhoneNumber
{
  [self.metadataIndexer getMetadataWithText:@"1234"
                                placeholder:@"Enter your Phone Number"
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypePhonePad];

  [self.metadataIndexer getMetadataWithText:@"1234567891011121314"
                                placeholder:@"Mobile Number"
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypePhonePad];
  XCTAssertEqual(
    [[self.metadataIndexer.store valueForKey:@"r2"] count],
    0,
    "Getting metadata with an invalid phone number should not check rules related to phone numbers."
  );
}

// test for geting metadata with invalid phone number placeholder
- (void)testGetMetadataWithInvalidPhoneNumberPlaceholder
{
  NSString *text = @"1112223333";
  [self.metadataIndexer getMetadataWithText:text
                                placeholder:@"Enter your"
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypePhonePad];
  XCTAssertEqual(
    [[self.metadataIndexer.store valueForKey:@"r1"] count],
    0,
    "Getting metadata with an invalid phone number placeholder should not check rules related to emails."
  );
  XCTAssertEqual(
    [[self.metadataIndexer.store valueForKey:@"r2"] count],
    0,
    "Getting metadata with an invalid phone number placeholder should not check rules related to phone numbers."
  );
}

// test for geting metadata with text which is neither email nor phone number
- (void)testGetMetadataWithTextNotEmailAndPhone
{
  NSString *text = @"facebook";
  [self.metadataIndexer getMetadataWithText:text
                                placeholder:@"Enter your Name"
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeAlphabet];
  XCTAssertEqual(
    [[self.metadataIndexer.store valueForKey:@"r1"] count],
    0,
    "Getting metadata with a plain text (not email nor phone number) should not check rules related to emails."
  );
  XCTAssertEqual(
    [[self.metadataIndexer.store valueForKey:@"r2"] count],
    0,
    "Getting metadata with a plain text (not email nor phone number) should not check rules related to phone numbers."
  );
}

// test for geting metadata with no text
- (void)testGetMetadataWithNoText
{
  NSString *text = @"";
  [self.metadataIndexer getMetadataWithText:text
                                placeholder:@"Enter your Email"
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeEmailAddress];
  XCTAssertEqual(
    [[self.metadataIndexer.store valueForKey:@"r1"] count],
    0,
    "Getting metadata with an empty string should not check rules related to emails."
  );
  XCTAssertEqual(
    [[self.metadataIndexer.store valueForKey:@"r2"] count],
    0,
    "Getting metadata with an empty string should not check rules related to phone numbers."
  );
}

// test for geting metadata with too long text
- (void)testGetMetadataWithTooLongText
{
  NSString *text = [NSString stringWithFormat:@"%@%@", [@"" stringByPaddingToLength:1000 withString:@"a" startingAtIndex:0], @"@fb.com"];
  [self.metadataIndexer getMetadataWithText:text
                                placeholder:@"Enter your Email"
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeEmailAddress];
  XCTAssertEqual(
    [[self.metadataIndexer.store valueForKey:@"r1"] count],
    0,
    "Getting metadata with a too long text should not check rules related to emails."
  );
  XCTAssertEqual(
    [[self.metadataIndexer.store valueForKey:@"r2"] count],
    0,
    "Getting metadata with a too long text should not check rules related to phone numbers."
  );
}

// test for geting metadata with too long placeholder
- (void)testGetMetadataWithTooLongPlaceholder
{
  NSString *text = @"test@fb.com";
  NSString *indicator = [NSString stringWithFormat:@"%@", [@"" stringByPaddingToLength:1000 withString:@"enter your email " startingAtIndex:0]];
  [self.metadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeEmailAddress];
  XCTAssertEqual(
    [[self.metadataIndexer.store valueForKey:@"r1"] count],
    0,
    "Getting metadata with a too long placeholder should not check rules related to emails."
  );
  XCTAssertEqual(
    [[self.metadataIndexer.store valueForKey:@"r2"] count],
    0,
    "Getting metadata with a too long placeholder should not check rules related to phone numbers."
  );
}

// test for getting metadata with gender
- (void)testGetMetadataWithValidGender
{
  NSString *text = @"male";
  NSString *indicator = @"gender";
  [self.metadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  XCTAssertEqualObjects(
    [[self.metadataIndexer.store valueForKey:@"r3"] firstObject],
    [FBSDKUtility SHA256Hash:@"m"],
    "Getting metadata with a valid gender should check rules related genders."
  );
}

- (void)testGetMetadataWithInvalidGender
{
  NSString *text = @"test";
  NSString *indicator = @"gender";
  [self.metadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  XCTAssertEqual(
    [[self.metadataIndexer.store valueForKey:@"r3"] count],
    0,
    "Getting metadata with an invalid gender should not check rules related to genders."
  );
}

- (void)testGetMetadataWithInvalidGenderIndicator
{
  NSString *text = @"female";
  NSString *indicator = @"test";
  [self.metadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  XCTAssertEqual(
    [[self.metadataIndexer.store valueForKey:@"r3"] count],
    0,
    "Getting metadata with an invalid gender indicator should not check rules related to genders."
  );
}

// test for getting meta with city
- (void)testGetMetadataWithValidCity
{
  NSString *text = @"Menlo Park";
  NSString *indicator = @"city";
  [self.metadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  XCTAssertEqualObjects(
    [[self.metadataIndexer.store valueForKey:@"r4"] firstObject],
    [FBSDKUtility SHA256Hash:@"menlopark"],
    "Getting metadata with a valid city name should check rules related cities."
  );
}

- (void)testGetMetadataWithInvalidCity
{
  // Although rule_V for city is @"", but should not accept empty text case
  NSString *text = @"";
  NSString *indicator = @"city";
  [self.metadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  XCTAssertEqual(
    [[self.metadataIndexer.store valueForKey:@"r4"] count],
    0,
    "Getting metadata with an invalid city name should not check rules related to cities."
  );
}

- (void)testGetMetadataWithInvalidCityIndicator
{
  NSString *text = @"Menlo Park";
  NSString *indicator = @"test";
  [self.metadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  XCTAssertEqual(
    [[self.metadataIndexer.store valueForKey:@"r4"] count],
    0,
    "Getting metadata with an invalid city indicator should not check rules related to cities."
  );
}

// test for getting meta with state
- (void)testGetMetadataWithValidState
{
  NSString *text = @"CA";
  NSString *indicator = @"province";
  [self.metadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  XCTAssertEqualObjects(
    [[self.metadataIndexer.store valueForKey:@"r5"] firstObject],
    [FBSDKUtility SHA256Hash:@"ca"],
    "Getting metadata with a valid state/province name should check rules related to states."
  );
}

- (void)testGetMetadataWithInvalidState
{
  // Although rule_V for state is @"", but should not accept empty text case
  NSString *text = @"";
  NSString *indicator = @"state";
  [self.metadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  XCTAssertEqual(
    [[self.metadataIndexer.store valueForKey:@"r5"] count],
    0,
    "Getting metadata with an invalid state/province name should not check rules related to states."
  );
}

- (void)testGetMetadataWithInvalidStateIndicator
{
  NSString *text = @"CA";
  NSString *indicator = @"test";
  [self.metadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  XCTAssertEqual(
    [[self.metadataIndexer.store valueForKey:@"r5"] count],
    0,
    "Getting metadata with an invalid state/province indicator should not check rules related to states."
  );
}

// test for getting meta with zip
- (void)testGetMetadataWithValidZip
{
  NSString *text = @"94025";
  NSString *indicator = @"zcode";
  [self.metadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  XCTAssertEqualObjects(
    [[self.metadataIndexer.store valueForKey:@"r6"] firstObject],
    [FBSDKUtility SHA256Hash:text],
    "Getting metadata with a valid zipcode should check rules related to zipcodes."
  );
}

// test for getting metadata with valid zipcode containing "-" (will also be regarded as phone number)
- (void)testGetMetadataWithValidZipWithPunctuations
{
  NSString *text = @"94025-1234";
  [self.metadataIndexer getMetadataWithText:text
                                placeholder:@""
                                     labels:@[@"zcode", @"phone"]
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypePhonePad];
  XCTAssertEqualObjects(
    [[self.metadataIndexer.store valueForKey:@"r6"] firstObject],
    [FBSDKUtility SHA256Hash:@"94025"],
    "Getting metadata with a valid zipcode with punctuations should check rules related to zipcodes."
  );
  XCTAssertEqualObjects(
    [[self.metadataIndexer.store valueForKey:@"r2"] firstObject],
    [FBSDKUtility SHA256Hash:@"940251234"],
    "Getting metadata with a valid zipcode with punctuations should check rules related to phone numbers."
  );
  XCTAssertFalse(
    [[self.metadataIndexer.store valueForKey:@"r6"] containsObject:[FBSDKUtility SHA256Hash:text]],
    "Getting metadata with a valid zipcode with punctuations should not check rules related related to zipcodes with original text."
  );
}

- (void)testGetMetadataWithInvalidZip
{
  // the rule for zip code should be 5-digit number
  NSString *text = @"9402";
  NSString *indicator = @"zcode";
  [self.metadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  XCTAssertEqual(
    [[self.metadataIndexer.store valueForKey:@"r6"] count],
    0,
    "Getting metadata with an invalid zipcode should not check rules related to zipcodes."
  );
}

- (void)testGetMetadataWithInvalidZipIndicator
{
  NSString *text = @"94025";
  NSString *indicator = @"test";
  [self.metadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  XCTAssertEqual(
    [[self.metadataIndexer.store valueForKey:@"r6"] count],
    0,
    "Getting metadata with an invalid zipcode indicator should not check rules related to zipcodes."
  );
}

// test for getting meta with first name
- (void)testGetMetadataWithValidFn
{
  NSString *text = @"David";
  NSString *indicator = @"fn";
  [self.metadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  XCTAssertEqualObjects(
    [[self.metadataIndexer.store valueForKey:@"r7"] firstObject],
    [FBSDKUtility SHA256Hash:@"david"],
    "Getting metadata with a valid first name should check rules related to first names."
  );
}

- (void)testGetMetadataWithInvalidFn
{
  // Although rule_V for first name is @"", but should not accept empty text case
  NSString *text = @"";
  NSString *indicator = @"fn";
  [self.metadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  XCTAssertEqual(
    [[self.metadataIndexer.store valueForKey:@"r7"] count],
    0,
    "Getting metadata with an empty string should check rules related to first names."
  );
}

- (void)testGetMetadataWithInvalidFnIndicator
{
  NSString *text = @"David";
  NSString *indicator = @"test";
  [self.metadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  XCTAssertEqual(
    [[self.metadataIndexer.store valueForKey:@"r7"] count],
    0,
    "Getting metadata with an invalid first name indicator should check rules related to first names."
  );
}

// test for getting meta with last name
- (void)testGetMetadataWithValidLn
{
  NSString *text = @"Taylor";
  NSString *indicator = @"ln";
  [self.metadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  XCTAssertEqualObjects(
    [[self.metadataIndexer.store valueForKey:@"r8"] firstObject],
    [FBSDKUtility SHA256Hash:@"taylor"],
    "Getting metadata with a valid last name should check rules related to last names."
  );
}

- (void)testGetMetadataWithInvalidLn
{
  // Although rule_V for last name is @"", but should not accept empty text case
  NSString *text = @"";
  NSString *indicator = @"ln";
  [self.metadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  XCTAssertEqual(
    [[self.metadataIndexer.store valueForKey:@"r8"] count],
    0,
    "Getting metadata with an invalid last name should check rules related to last names."
  );
}

- (void)testGetMetadataWithInvalidLnIndicator
{
  NSString *text = @"Taylor";
  NSString *indicator = @"test";
  [self.metadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  XCTAssertEqual(
    [[self.metadataIndexer.store valueForKey:@"r8"] count],
    0,
    "Getting metadata with an invalid last name indicator should check rules related to last names."
  );
}

// test for getting meta with first name with labels (will also be regarded as last name, state, city
- (void)testGetMetadataWithFirstNameWithLabels
{
  NSString *text = @"Taylor";
  [self.metadataIndexer getMetadataWithText:text
                                placeholder:@""
                                     labels:@[@"fn", @"ln", @"state", @"city"]
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  XCTAssertTrue(
    [[self.metadataIndexer.store valueForKey:@"r4"] containsObject:[FBSDKUtility SHA256Hash:@"taylor"]],
    "Getting metadata with a first name with city label should check rules related to cities."
  );
  XCTAssertTrue(
    [[self.metadataIndexer.store valueForKey:@"r5"] containsObject:[FBSDKUtility SHA256Hash:@"taylor"]],
    "Getting metadata with a first name with state label should check rules related to states."
  );
  XCTAssertTrue(
    [[self.metadataIndexer.store valueForKey:@"r7"] containsObject:[FBSDKUtility SHA256Hash:@"taylor"]],
    "Getting metadata with a first name with fn label should check rules related to first names."
  );
  XCTAssertTrue(
    [[self.metadataIndexer.store valueForKey:@"r8"] containsObject:[FBSDKUtility SHA256Hash:@"taylor"]],
    "Getting metadata with a first name with ln label should check rules related to last names."
  );
}

@end
