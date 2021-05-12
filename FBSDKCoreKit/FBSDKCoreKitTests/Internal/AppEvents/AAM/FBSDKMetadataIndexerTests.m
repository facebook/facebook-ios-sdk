// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <XCTest/XCTest.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKCoreKitBasicsImport.h"
#import "FBSDKMetadataIndexer.h"

@interface FBSDKMetadataIndexer ()
@property (nonnull, nonatomic, readonly) NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *store;

- (void)constructRules:(NSDictionary<NSString *, id> *)rules;

- (void)initStore;

- (BOOL)checkSecureTextEntry:(UIView *)view;

- (UIKeyboardType)getKeyboardType:(UIView *)view;

- (void)getMetadataWithText:(NSString *)text
                placeholder:(NSString *)placeholder
                     labels:(NSArray<NSString *> *)labels
            secureTextEntry:(BOOL)secureTextEntry
                  inputType:(UIKeyboardType)inputType;

- (void)checkAndAppendData:(NSString *)data forKey:(NSString *)key;

@end

@interface FBSDKMetadataIndexerTests : XCTestCase
{
  FBSDKMetadataIndexer *_metadataIndexer;
  UITextField *_emailField;
  UITextView *_emailView;
  UITextField *_phoneField;
  UITextView *_phoneView;
  UITextField *_pwdField;
  UITextView *_pwdView;
}
@end

@implementation FBSDKMetadataIndexerTests

- (void)setUp
{
  _metadataIndexer = [FBSDKMetadataIndexer new];
  NSDictionary<NSString *, id> *rules = @{
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
  [_metadataIndexer constructRules:rules];
  [_metadataIndexer initStore];

  // clear store
  for (NSString *key in rules) {
    [FBSDKTypeUtility dictionary:_metadataIndexer.store setObject:[NSMutableArray new] forKey:key];
  }

  _emailField = [UITextField new];
  _emailField.placeholder = NSLocalizedString(@"Enter your email", nil);
  _emailField.keyboardType = UIKeyboardTypeEmailAddress;

  _emailView = [UITextView new];
  _emailView.keyboardType = UIKeyboardTypeEmailAddress;

  _phoneField = [UITextField new];
  _phoneField.placeholder = NSLocalizedString(@"Enter your phone", nil);
  _phoneField.keyboardType = UIKeyboardTypePhonePad;

  _pwdField = [UITextField new];
  _pwdField.placeholder = NSLocalizedString(@"Enter your password", nil);
  _pwdField.secureTextEntry = YES;

  _pwdView = [UITextView new];
  _pwdView.secureTextEntry = YES;
}

// test for geting secure text entry in UITextField
- (void)testCheckSecureTextEntryOfTextField
{
  // without secure text
  XCTAssertFalse(
    [_metadataIndexer checkSecureTextEntry:_emailField],
    @"test for UITextField without secure text"
  );

  // with secure text
  XCTAssertTrue(
    [_metadataIndexer checkSecureTextEntry:_pwdField],
    @"test for UITextField with secure text"
  );
}

// test for geting secure text entry in UITextView
- (void)testCheckSecureTextEntryOfTextView
{
  // without secure text
  XCTAssertFalse(
    [_metadataIndexer checkSecureTextEntry:_emailView],
    @"test for UITextView without secure text"
  );

  // with secure text
  XCTAssertTrue([_metadataIndexer checkSecureTextEntry:_pwdView], @"test for UITextView with secure text");
}

// test for geting keyboard type from UITextField
- (void)testGetKeyboardTypeOfTextField
{
  XCTAssertEqual(
    _emailField.keyboardType,
    [_metadataIndexer getKeyboardType:_emailField],
    @"test for geting keyboard type from UITextField"
  );
}

// test for geting keyboard type from UITextView
- (void)testGetKeyboardTypeOfTextView
{
  XCTAssertEqual(
    _emailView.keyboardType,
    [_metadataIndexer getKeyboardType:_emailView],
    @"test for geting keyboard type from UITextView"
  );
}

// test for geting metadata with valid email
- (void)testGetMetadataWithEmail
{
  NSString *text = @"test@fb.com";
  [_metadataIndexer getMetadataWithText:text
                            placeholder:@"Enter your Email"
                                 labels:nil
                        secureTextEntry:NO
                              inputType:UIKeyboardTypeEmailAddress];
  XCTAssertEqualObjects(
    [[_metadataIndexer.store valueForKey:@"r1"] firstObject],
    [FBSDKUtility SHA256Hash:text],
    "Getting metadata with a valid email should check rules related to emails."
  );
  XCTAssertEqual(
    [[_metadataIndexer.store valueForKey:@"r2"] count],
    0,
    "Getting metadata with a valid email should not check rules related to phone numbers."
  );
}

// test for geting metadata with valid phone number
- (void)testGetMetadataWithPhoneNumber
{
  NSString *text = @"1112223333";
  [_metadataIndexer getMetadataWithText:text
                            placeholder:@"Enter your Phone Number"
                                 labels:nil
                        secureTextEntry:NO
                              inputType:UIKeyboardTypePhonePad];
  XCTAssertEqualObjects(
    [[_metadataIndexer.store valueForKey:@"r2"] firstObject],
    [FBSDKUtility SHA256Hash:text],
    "Getting metadata with a valid phone number should check rules related to phone numbers."
  );
  XCTAssertEqual(
    [[_metadataIndexer.store valueForKey:@"r1"] count],
    0,
    "Getting metadata with a valid phone number should not check rules related to emails."
  );
}

// test for geting metadata with valid phone number or zipcode with labels
- (void)testGetMetadataWithPhoneNumberWithLabels
{
  NSString *text = @"11122";
  [_metadataIndexer getMetadataWithText:text
                            placeholder:@""
                                 labels:@[@"phone", @"zipcode"]
                        secureTextEntry:NO
                              inputType:UIKeyboardTypePhonePad];
  XCTAssertEqualObjects(
    [[_metadataIndexer.store valueForKey:@"r2"] firstObject],
    [FBSDKUtility SHA256Hash:text],
    "Getting metadata with a phone number or zipcode with label should check rules related to phone numbers."
  );
  XCTAssertEqualObjects(
    [[_metadataIndexer.store valueForKey:@"r6"] firstObject],
    [FBSDKUtility SHA256Hash:text],
    "Getting metadata with a phone number or zipcode with label should check rules related to zipcodes."
  );
}

// test for geting metadata with secure text
- (void)testGetMetadataWithSecureText
{
  NSString *text = @"dfjald1314";
  [_metadataIndexer getMetadataWithText:text
                            placeholder:@"Enter your Pass-word"
                                 labels:nil
                        secureTextEntry:YES
                              inputType:UIKeyboardTypeDefault];
  XCTAssertEqual(
    [[_metadataIndexer.store valueForKey:@"r1"] count],
    0,
    "Getting metadata with a secret text should not check rules related to emails."
  );
  XCTAssertEqual(
    [[_metadataIndexer.store valueForKey:@"r2"] count],
    0,
    "Getting metadata with a secret text should not check rules related to phone numbers."
  );
}

// test for geting metadata with invalid email
- (void)testGetMetadataWithInvalidEmail
{
  NSString *text = @"test";
  [_metadataIndexer getMetadataWithText:text
                            placeholder:@"Enter your Email"
                                 labels:nil
                        secureTextEntry:NO
                              inputType:UIKeyboardTypeEmailAddress];
  XCTAssertEqual(
    [[_metadataIndexer.store valueForKey:@"r1"] count],
    0,
    "Getting metadata with an invalid email should not check rules related to emails."
  );
  XCTAssertEqual(
    [[_metadataIndexer.store valueForKey:@"r2"] count],
    0,
    "Getting metadata with an invalid email should not check rules related to phone numbers."
  );
}

// test for geting metadata with invalid email placeholder
- (void)testGetMetadataWithInvalidEmailPlaceholder
{
  NSString *text = @"test@fb.com";
  [_metadataIndexer getMetadataWithText:text
                            placeholder:@"Enter your"
                                 labels:nil
                        secureTextEntry:NO
                              inputType:UIKeyboardTypeEmailAddress];
  XCTAssertEqual(
    [[_metadataIndexer.store valueForKey:@"r1"] count],
    0,
    "Getting metadata with an invalid email placeholder should not check rules related to emails."
  );
  XCTAssertEqual(
    [[_metadataIndexer.store valueForKey:@"r2"] count],
    0,
    "Getting metadata with an invalid email placeholder should not check rules related to phone numbers."
  );
}

// test for getting metadata with valid phone number containing +-().
- (void)testGetMetadataWithValidPhoneNumberWithPunctuations
{
  NSString *text = @"+1(222)-333-444";
  [_metadataIndexer getMetadataWithText:text
                            placeholder:@"Enter your Phone Number"
                                 labels:nil
                        secureTextEntry:NO
                              inputType:UIKeyboardTypePhonePad];
  XCTAssertTrue(
    [[_metadataIndexer.store valueForKey:@"r2"] containsObject:[FBSDKUtility SHA256Hash:@"1222333444"]],
    "Getting metadata with a phone number with punctuations should check rules related to phone numbers with pure numbers."
  );
  XCTAssertFalse(
    [[_metadataIndexer.store valueForKey:@"r2"] containsObject:[FBSDKUtility SHA256Hash:text]],
    "Getting metadata with a phone number with punctuations should not check rules related to phone numbers with the original text."
  );
}

// test for geting metadata with invalid phone number
- (void)testGetMetadataWithInvalidPhoneNumber
{
  [_metadataIndexer getMetadataWithText:@"1234"
                            placeholder:@"Enter your Phone Number"
                                 labels:nil
                        secureTextEntry:NO
                              inputType:UIKeyboardTypePhonePad];

  [_metadataIndexer getMetadataWithText:@"1234567891011121314"
                            placeholder:@"Mobile Number"
                                 labels:nil
                        secureTextEntry:NO
                              inputType:UIKeyboardTypePhonePad];
  XCTAssertEqual(
    [[_metadataIndexer.store valueForKey:@"r2"] count],
    0,
    "Getting metadata with an invalid phone number should not check rules related to phone numbers."
  );
}

// test for geting metadata with invalid phone number placeholder
- (void)testGetMetadataWithInvalidPhoneNumberPlaceholder
{
  NSString *text = @"1112223333";
  [_metadataIndexer getMetadataWithText:text
                            placeholder:@"Enter your"
                                 labels:nil
                        secureTextEntry:NO
                              inputType:UIKeyboardTypePhonePad];
  XCTAssertEqual(
    [[_metadataIndexer.store valueForKey:@"r1"] count],
    0,
    "Getting metadata with an invalid phone number placeholder should not check rules related to emails."
  );
  XCTAssertEqual(
    [[_metadataIndexer.store valueForKey:@"r2"] count],
    0,
    "Getting metadata with an invalid phone number placeholder should not check rules related to phone numbers."
  );
}

// test for geting metadata with text which is neither email nor phone number
- (void)testGetMetadataWithTextNotEmailAndPhone
{
  NSString *text = @"facebook";
  [_metadataIndexer getMetadataWithText:text
                            placeholder:@"Enter your Name"
                                 labels:nil
                        secureTextEntry:NO
                              inputType:UIKeyboardTypeAlphabet];
  XCTAssertEqual(
    [[_metadataIndexer.store valueForKey:@"r1"] count],
    0,
    "Getting metadata with a plain text (not email nor phone number) should not check rules related to emails."
  );
  XCTAssertEqual(
    [[_metadataIndexer.store valueForKey:@"r2"] count],
    0,
    "Getting metadata with a plain text (not email nor phone number) should not check rules related to phone numbers."
  );
}

// test for geting metadata with no text
- (void)testGetMetadataWithNoText
{
  NSString *text = @"";
  [_metadataIndexer getMetadataWithText:text
                            placeholder:@"Enter your Email"
                                 labels:nil
                        secureTextEntry:NO
                              inputType:UIKeyboardTypeEmailAddress];
  XCTAssertEqual(
    [[_metadataIndexer.store valueForKey:@"r1"] count],
    0,
    "Getting metadata with an empty string should not check rules related to emails."
  );
  XCTAssertEqual(
    [[_metadataIndexer.store valueForKey:@"r2"] count],
    0,
    "Getting metadata with an empty string should not check rules related to phone numbers."
  );
}

// test for geting metadata with too long text
- (void)testGetMetadataWithTooLongText
{
  NSString *text = [NSString stringWithFormat:@"%@%@", [@"" stringByPaddingToLength:1000 withString:@"a" startingAtIndex:0], @"@fb.com"];
  [_metadataIndexer getMetadataWithText:text
                            placeholder:@"Enter your Email"
                                 labels:nil
                        secureTextEntry:NO
                              inputType:UIKeyboardTypeEmailAddress];
  XCTAssertEqual(
    [[_metadataIndexer.store valueForKey:@"r1"] count],
    0,
    "Getting metadata with a too long text should not check rules related to emails."
  );
  XCTAssertEqual(
    [[_metadataIndexer.store valueForKey:@"r2"] count],
    0,
    "Getting metadata with a too long text should not check rules related to phone numbers."
  );
}

// test for geting metadata with too long placeholder
- (void)testGetMetadataWithTooLongPlaceholder
{
  NSString *text = @"test@fb.com";
  NSString *indicator = [NSString stringWithFormat:@"%@", [@"" stringByPaddingToLength:1000 withString:@"enter your email " startingAtIndex:0]];
  [_metadataIndexer getMetadataWithText:text
                            placeholder:indicator
                                 labels:nil
                        secureTextEntry:NO
                              inputType:UIKeyboardTypeEmailAddress];
  XCTAssertEqual(
    [[_metadataIndexer.store valueForKey:@"r1"] count],
    0,
    "Getting metadata with a too long placeholder should not check rules related to emails."
  );
  XCTAssertEqual(
    [[_metadataIndexer.store valueForKey:@"r2"] count],
    0,
    "Getting metadata with a too long placeholder should not check rules related to phone numbers."
  );
}

// test for getting metadata with gender
- (void)testGetMetadataWithValidGender
{
  NSString *text = @"male";
  NSString *indicator = @"gender";
  [_metadataIndexer getMetadataWithText:text
                            placeholder:indicator
                                 labels:nil
                        secureTextEntry:NO
                              inputType:UIKeyboardTypeDefault];
  XCTAssertEqualObjects(
    [[_metadataIndexer.store valueForKey:@"r3"] firstObject],
    [FBSDKUtility SHA256Hash:@"m"],
    "Getting metadata with a valid gender should check rules related genders."
  );
}

- (void)testGetMetadataWithInvalidGender
{
  NSString *text = @"test";
  NSString *indicator = @"gender";
  [_metadataIndexer getMetadataWithText:text
                            placeholder:indicator
                                 labels:nil
                        secureTextEntry:NO
                              inputType:UIKeyboardTypeDefault];
  XCTAssertEqual(
    [[_metadataIndexer.store valueForKey:@"r3"] count],
    0,
    "Getting metadata with an invalid gender should not check rules related to genders."
  );
}

- (void)testGetMetadataWithInvalidGenderIndicator
{
  NSString *text = @"female";
  NSString *indicator = @"test";
  [_metadataIndexer getMetadataWithText:text
                            placeholder:indicator
                                 labels:nil
                        secureTextEntry:NO
                              inputType:UIKeyboardTypeDefault];
  XCTAssertEqual(
    [[_metadataIndexer.store valueForKey:@"r3"] count],
    0,
    "Getting metadata with an invalid gender indicator should not check rules related to genders."
  );
}

// test for getting meta with city
- (void)testGetMetadataWithValidCity
{
  NSString *text = @"Menlo Park";
  NSString *indicator = @"city";
  [_metadataIndexer getMetadataWithText:text
                            placeholder:indicator
                                 labels:nil
                        secureTextEntry:NO
                              inputType:UIKeyboardTypeDefault];
  XCTAssertEqualObjects(
    [[_metadataIndexer.store valueForKey:@"r4"] firstObject],
    [FBSDKUtility SHA256Hash:@"menlopark"],
    "Getting metadata with a valid city name should check rules related cities."
  );
}

- (void)testGetMetadataWithInvalidCity
{
  // Although rule_V for city is @"", but should not accept empty text case
  NSString *text = @"";
  NSString *indicator = @"city";
  [_metadataIndexer getMetadataWithText:text
                            placeholder:indicator
                                 labels:nil
                        secureTextEntry:NO
                              inputType:UIKeyboardTypeDefault];
  XCTAssertEqual(
    [[_metadataIndexer.store valueForKey:@"r4"] count],
    0,
    "Getting metadata with an invalid city name should not check rules related to cities."
  );
}

- (void)testGetMetadataWithInvalidCityIndicator
{
  NSString *text = @"Menlo Park";
  NSString *indicator = @"test";
  [_metadataIndexer getMetadataWithText:text
                            placeholder:indicator
                                 labels:nil
                        secureTextEntry:NO
                              inputType:UIKeyboardTypeDefault];
  XCTAssertEqual(
    [[_metadataIndexer.store valueForKey:@"r4"] count],
    0,
    "Getting metadata with an invalid city indicator should not check rules related to cities."
  );
}

// test for getting meta with state
- (void)testGetMetadataWithValidState
{
  NSString *text = @"CA";
  NSString *indicator = @"province";
  [_metadataIndexer getMetadataWithText:text
                            placeholder:indicator
                                 labels:nil
                        secureTextEntry:NO
                              inputType:UIKeyboardTypeDefault];
  XCTAssertEqualObjects(
    [[_metadataIndexer.store valueForKey:@"r5"] firstObject],
    [FBSDKUtility SHA256Hash:@"ca"],
    "Getting metadata with a valid state/province name should check rules related to states."
  );
}

- (void)testGetMetadataWithInvalidState
{
  // Although rule_V for state is @"", but should not accept empty text case
  NSString *text = @"";
  NSString *indicator = @"state";
  [_metadataIndexer getMetadataWithText:text
                            placeholder:indicator
                                 labels:nil
                        secureTextEntry:NO
                              inputType:UIKeyboardTypeDefault];
  XCTAssertEqual(
    [[_metadataIndexer.store valueForKey:@"r5"] count],
    0,
    "Getting metadata with an invalid state/province name should not check rules related to states."
  );
}

- (void)testGetMetadataWithInvalidStateIndicator
{
  NSString *text = @"CA";
  NSString *indicator = @"test";
  [_metadataIndexer getMetadataWithText:text
                            placeholder:indicator
                                 labels:nil
                        secureTextEntry:NO
                              inputType:UIKeyboardTypeDefault];
  XCTAssertEqual(
    [[_metadataIndexer.store valueForKey:@"r5"] count],
    0,
    "Getting metadata with an invalid state/province indicator should not check rules related to states."
  );
}

// test for getting meta with zip
- (void)testGetMetadataWithValidZip
{
  NSString *text = @"94025";
  NSString *indicator = @"zcode";
  [_metadataIndexer getMetadataWithText:text
                            placeholder:indicator
                                 labels:nil
                        secureTextEntry:NO
                              inputType:UIKeyboardTypeDefault];
  XCTAssertEqualObjects(
    [[_metadataIndexer.store valueForKey:@"r6"] firstObject],
    [FBSDKUtility SHA256Hash:text],
    "Getting metadata with a valid zipcode should check rules related to zipcodes."
  );
}

// test for getting metadata with valid zipcode containing "-" (will also be regarded as phone number)
- (void)testGetMetadataWithValidZipWithPunctuations
{
  NSString *text = @"94025-1234";
  [_metadataIndexer getMetadataWithText:text
                            placeholder:@""
                                 labels:@[@"zcode", @"phone"]
                        secureTextEntry:NO
                              inputType:UIKeyboardTypePhonePad];
  XCTAssertEqualObjects(
    [[_metadataIndexer.store valueForKey:@"r6"] firstObject],
    [FBSDKUtility SHA256Hash:@"94025"],
    "Getting metadata with a valid zipcode with punctuations should check rules related to zipcodes."
  );
  XCTAssertEqualObjects(
    [[_metadataIndexer.store valueForKey:@"r2"] firstObject],
    [FBSDKUtility SHA256Hash:@"940251234"],
    "Getting metadata with a valid zipcode with punctuations should check rules related to phone numbers."
  );
  XCTAssertFalse(
    [[_metadataIndexer.store valueForKey:@"r6"] containsObject:[FBSDKUtility SHA256Hash:text]],
    "Getting metadata with a valid zipcode with punctuations should not check rules related related to zipcodes with original text."
  );
}

- (void)testGetMetadataWithInvalidZip
{
  // the rule for zip code should be 5-digit number
  NSString *text = @"9402";
  NSString *indicator = @"zcode";
  [_metadataIndexer getMetadataWithText:text
                            placeholder:indicator
                                 labels:nil
                        secureTextEntry:NO
                              inputType:UIKeyboardTypeDefault];
  XCTAssertEqual(
    [[_metadataIndexer.store valueForKey:@"r6"] count],
    0,
    "Getting metadata with an invalid zipcode should not check rules related to zipcodes."
  );
}

- (void)testGetMetadataWithInvalidZipIndicator
{
  NSString *text = @"94025";
  NSString *indicator = @"test";
  [_metadataIndexer getMetadataWithText:text
                            placeholder:indicator
                                 labels:nil
                        secureTextEntry:NO
                              inputType:UIKeyboardTypeDefault];
  XCTAssertEqual(
    [[_metadataIndexer.store valueForKey:@"r6"] count],
    0,
    "Getting metadata with an invalid zipcode indicator should not check rules related to zipcodes."
  );
}

// test for getting meta with first name
- (void)testGetMetadataWithValidFn
{
  NSString *text = @"David";
  NSString *indicator = @"fn";
  [_metadataIndexer getMetadataWithText:text
                            placeholder:indicator
                                 labels:nil
                        secureTextEntry:NO
                              inputType:UIKeyboardTypeDefault];
  XCTAssertEqualObjects(
    [[_metadataIndexer.store valueForKey:@"r7"] firstObject],
    [FBSDKUtility SHA256Hash:@"david"],
    "Getting metadata with a valid first name should check rules related to first names."
  );
}

- (void)testGetMetadataWithInvalidFn
{
  // Although rule_V for first name is @"", but should not accept empty text case
  NSString *text = @"";
  NSString *indicator = @"fn";
  [_metadataIndexer getMetadataWithText:text
                            placeholder:indicator
                                 labels:nil
                        secureTextEntry:NO
                              inputType:UIKeyboardTypeDefault];
  XCTAssertEqual(
    [[_metadataIndexer.store valueForKey:@"r7"] count],
    0,
    "Getting metadata with an empty string should check rules related to first names."
  );
}

- (void)testGetMetadataWithInvalidFnIndicator
{
  NSString *text = @"David";
  NSString *indicator = @"test";
  [_metadataIndexer getMetadataWithText:text
                            placeholder:indicator
                                 labels:nil
                        secureTextEntry:NO
                              inputType:UIKeyboardTypeDefault];
  XCTAssertEqual(
    [[_metadataIndexer.store valueForKey:@"r7"] count],
    0,
    "Getting metadata with an invalid first name indicator should check rules related to first names."
  );
}

// test for getting meta with last name
- (void)testGetMetadataWithValidLn
{
  NSString *text = @"Taylor";
  NSString *indicator = @"ln";
  [_metadataIndexer getMetadataWithText:text
                            placeholder:indicator
                                 labels:nil
                        secureTextEntry:NO
                              inputType:UIKeyboardTypeDefault];
  XCTAssertEqualObjects(
    [[_metadataIndexer.store valueForKey:@"r8"] firstObject],
    [FBSDKUtility SHA256Hash:@"taylor"],
    "Getting metadata with a valid last name should check rules related to last names."
  );
}

- (void)testGetMetadataWithInvalidLn
{
  // Although rule_V for last name is @"", but should not accept empty text case
  NSString *text = @"";
  NSString *indicator = @"ln";
  [_metadataIndexer getMetadataWithText:text
                            placeholder:indicator
                                 labels:nil
                        secureTextEntry:NO
                              inputType:UIKeyboardTypeDefault];
  XCTAssertEqual(
    [[_metadataIndexer.store valueForKey:@"r8"] count],
    0,
    "Getting metadata with an invalid last name should check rules related to last names."
  );
}

- (void)testGetMetadataWithInvalidLnIndicator
{
  NSString *text = @"Taylor";
  NSString *indicator = @"test";
  [_metadataIndexer getMetadataWithText:text
                            placeholder:indicator
                                 labels:nil
                        secureTextEntry:NO
                              inputType:UIKeyboardTypeDefault];
  XCTAssertEqual(
    [[_metadataIndexer.store valueForKey:@"r8"] count],
    0,
    "Getting metadata with an invalid last name indicator should check rules related to last names."
  );
}

// test for getting meta with first name with labels (will also be regarded as last name, state, city
- (void)testGetMetadataWithFirstNameWithLabels
{
  NSString *text = @"Taylor";
  [_metadataIndexer getMetadataWithText:text
                            placeholder:@""
                                 labels:@[@"fn", @"ln", @"state", @"city"]
                        secureTextEntry:NO
                              inputType:UIKeyboardTypeDefault];
  XCTAssertTrue(
    [[_metadataIndexer.store valueForKey:@"r4"] containsObject:[FBSDKUtility SHA256Hash:@"taylor"]],
    "Getting metadata with a first name with city label should check rules related to cities."
  );
  XCTAssertTrue(
    [[_metadataIndexer.store valueForKey:@"r5"] containsObject:[FBSDKUtility SHA256Hash:@"taylor"]],
    "Getting metadata with a first name with state label should check rules related to states."
  );
  XCTAssertTrue(
    [[_metadataIndexer.store valueForKey:@"r7"] containsObject:[FBSDKUtility SHA256Hash:@"taylor"]],
    "Getting metadata with a first name with fn label should check rules related to first names."
  );
  XCTAssertTrue(
    [[_metadataIndexer.store valueForKey:@"r8"] containsObject:[FBSDKUtility SHA256Hash:@"taylor"]],
    "Getting metadata with a first name with ln label should check rules related to last names."
  );
}

@end
