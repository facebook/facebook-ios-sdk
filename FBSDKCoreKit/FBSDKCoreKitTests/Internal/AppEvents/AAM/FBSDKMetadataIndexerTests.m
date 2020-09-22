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

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKMetadataIndexer.h"

@interface FBSDKMetadataIndexer ()
+ (void)constructRules:(NSDictionary<NSString *, id> *)rules;

+ (void)initStore;

+ (BOOL)checkSecureTextEntry:(UIView *)view;

+ (UIKeyboardType)getKeyboardType:(UIView *)view;

+ (void)getMetadataWithText:(NSString *)text
                placeholder:(NSString *)placeholder
                     labels:(NSArray<NSString *> *)labels
            secureTextEntry:(BOOL)secureTextEntry
                  inputType:(UIKeyboardType)inputType;

+ (void)checkAndAppendData:(NSString *)data forKey:(NSString *)key;
@end

@interface FBSDKMetadataIndexerTests : XCTestCase
{
  id _mockMetadataIndexer;
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
  _mockMetadataIndexer = OCMClassMock([FBSDKMetadataIndexer class]);
  [FBSDKMetadataIndexer initStore];
  [FBSDKMetadataIndexer constructRules:@{
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
   }];

  _emailField = [[UITextField alloc] init];
  _emailField.placeholder = @"Enter your email";
  _emailField.keyboardType = UIKeyboardTypeEmailAddress;

  _emailView = [[UITextView alloc] init];
  _emailView.keyboardType = UIKeyboardTypeEmailAddress;

  _phoneField = [[UITextField alloc] init];
  _phoneField.placeholder = @"Enter your phone";
  _phoneField.keyboardType = UIKeyboardTypePhonePad;

  _pwdField = [[UITextField alloc] init];
  _pwdField.placeholder = @"Enter your password";
  _pwdField.secureTextEntry = YES;

  _pwdView = [[UITextView alloc] init];
  _pwdView.secureTextEntry = YES;
}

- (void)tearDown
{
  [_mockMetadataIndexer stopMocking];
}

// test for geting secure text entry in UITextField
- (void)testCheckSecureTextEntryOfTextField
{
  // without secure text
  XCTAssertFalse(
    [FBSDKMetadataIndexer checkSecureTextEntry:_emailField],
    @"test for UITextField without secure text"
  );

  // with secure text
  XCTAssertTrue(
    [FBSDKMetadataIndexer checkSecureTextEntry:_pwdField],
    @"test for UITextField with secure text"
  );
}

// test for geting secure text entry in UITextView
- (void)testCheckSecureTextEntryOfTextView
{
  // without secure text
  XCTAssertFalse(
    [FBSDKMetadataIndexer checkSecureTextEntry:_emailView],
    @"test for UITextView without secure text"
  );

  // with secure text
  XCTAssertTrue([FBSDKMetadataIndexer checkSecureTextEntry:_pwdView], @"test for UITextView with secure text");
}

// test for geting keyboard type from UITextField
- (void)testGetKeyboardTypeOfTextField
{
  XCTAssertEqual(
    _emailField.keyboardType,
    [FBSDKMetadataIndexer getKeyboardType:_emailField],
    @"test for geting keyboard type from UITextField"
  );
}

// test for geting keyboard type from UITextView
- (void)testGetKeyboardTypeOfTextView
{
  XCTAssertEqual(
    _emailView.keyboardType,
    [FBSDKMetadataIndexer getKeyboardType:_emailView],
    @"test for geting keyboard type from UITextView"
  );
}

// test for geting metadata with valid email
- (void)testGetMetadataWithEmail
{
  NSString *text = @"test@fb.com";
  [FBSDKMetadataIndexer getMetadataWithText:text
                                placeholder:@"Enter your Email"
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeEmailAddress];
  OCMVerify([_mockMetadataIndexer checkAndAppendData:text forKey:@"r1"]);
  OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:@"r2"]);
}

// test for geting metadata with valid phone number
- (void)testGetMetadataWithPhoneNumber
{
  NSString *text = @"1112223333";
  [FBSDKMetadataIndexer getMetadataWithText:text
                                placeholder:@"Enter your Phone Number"
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypePhonePad];
  OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:@"r1"]);
  OCMVerify([_mockMetadataIndexer checkAndAppendData:text forKey:@"r2"]);
}

// test for geting metadata with valid phone number or zipcode with labels
- (void)testGetMetadataWithPhoneNumberWithLabels
{
  NSString *text = @"11122";
  [FBSDKMetadataIndexer getMetadataWithText:text
                                placeholder:@""
                                     labels:@[@"phone", @"zipcode"]
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypePhonePad];
  OCMVerify([_mockMetadataIndexer checkAndAppendData:text forKey:@"r2"]);
  OCMVerify([_mockMetadataIndexer checkAndAppendData:text forKey:@"r6"]);
}

// test for geting metadata with secure text
- (void)testGetMetadataWithSecureText
{
  NSString *text = @"dfjald1314";
  [FBSDKMetadataIndexer getMetadataWithText:text
                                placeholder:@"Enter your Pass-word"
                                     labels:nil
                            secureTextEntry:YES
                                  inputType:UIKeyboardTypeDefault];
  OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:@"r1"]);
  OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:@"r2"]);
}

// test for geting metadata with invalid email
- (void)testGetMetadataWithInvalidEmail
{
  NSString *text = @"test";
  [FBSDKMetadataIndexer getMetadataWithText:text
                                placeholder:@"Enter your Email"
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeEmailAddress];
  OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:@"r1"]);
  OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:@"r2"]);
}

// test for geting metadata with invalid email placeholder
- (void)testGetMetadataWithInvalidEmailPlaceholder
{
  NSString *text = @"test@fb.com";
  [FBSDKMetadataIndexer getMetadataWithText:text
                                placeholder:@"Enter your"
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeEmailAddress];
  OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:@"r1"]);
  OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:@"r2"]);
}

// test for getting metadata with valid phone number containing +-().
- (void)testGetMetadataWithValidPhoneNumberWithPunctuations
{
  NSString *text = @"+1(222)-333-444";
  [FBSDKMetadataIndexer getMetadataWithText:text
                                placeholder:@"Enter your Phone Number"
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypePhonePad];
  OCMVerify([_mockMetadataIndexer checkAndAppendData:@"1222333444" forKey:@"r2"]);
  OCMReject([_mockMetadataIndexer checkAndAppendData:text forKey:@"r2"]);
}

// test for geting metadata with invalid phone number
- (void)testGetMetadataWithInvalidPhoneNumber
{
  [FBSDKMetadataIndexer getMetadataWithText:@"1234"
                                placeholder:@"Enter your Phone Number"
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypePhonePad];

  [FBSDKMetadataIndexer getMetadataWithText:@"1234567891011121314"
                                placeholder:@"Mobile Number"
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypePhonePad];
  OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:@"r2"]);
}

// test for geting metadata with invalid phone number placeholder
- (void)testGetMetadataWithInvalidPhoneNumberPlaceholder
{
  NSString *text = @"1112223333";
  [FBSDKMetadataIndexer getMetadataWithText:text
                                placeholder:@"Enter your"
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypePhonePad];
  OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:@"r1"]);
  OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:@"r2"]);
}

// test for geting metadata with text which is neither email nor phone number
- (void)testGetMetadataWithTextNotEmailAndPhone
{
  NSString *text = @"facebook";
  [FBSDKMetadataIndexer getMetadataWithText:text
                                placeholder:@"Enter your Name"
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeAlphabet];
  OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:@"r1"]);
  OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:@"r2"]);
}

// test for geting metadata with no text
- (void)testGetMetadataWithNoText
{
  NSString *text = @"";
  [FBSDKMetadataIndexer getMetadataWithText:text
                                placeholder:@"Enter your Email"
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeEmailAddress];
  OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:@"r1"]);
  OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:@"r2"]);
}

// test for geting metadata with too long text
- (void)testGetMetadataWithTooLongText
{
  NSString *text = [NSString stringWithFormat:@"%@%@", [@"" stringByPaddingToLength:1000 withString:@"a" startingAtIndex:0], @"@fb.com"];
  [FBSDKMetadataIndexer getMetadataWithText:text
                                placeholder:@"Enter your Email"
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeEmailAddress];
  OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:@"r1"]);
  OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:@"r2"]);
}

// test for geting metadata with too long placeholder
- (void)testGetMetadataWithTooLongPlaceholder
{
  NSString *text = @"test@fb.com";
  NSString *indicator = [NSString stringWithFormat:@"%@", [@"" stringByPaddingToLength:1000 withString:@"enter your email " startingAtIndex:0]];
  [FBSDKMetadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeEmailAddress];
  OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:@"r1"]);
  OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:@"r2"]);
}

// test for getting meta with gender
- (void)testGetMetadataWithValidGender
{
  NSString *text = @"male";
  NSString *indicator = @"gender";
  [FBSDKMetadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  OCMVerify([_mockMetadataIndexer checkAndAppendData:@"m" forKey:@"r3"]);
}

- (void)testGetMetadataWithInvalidGender
{
  NSString *text = @"test";
  NSString *indicator = @"gender";
  [FBSDKMetadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:@"r3"]);
}

- (void)testGetMetadataWithInvalidGenderIndicator
{
  NSString *text = @"female";
  NSString *indicator = @"test";
  [FBSDKMetadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:@"r3"]);
}

// test for getting meta with city
- (void)testGetMetadataWithValidCity
{
  NSString *text = @"Menlo Park";
  NSString *indicator = @"city";
  [FBSDKMetadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  OCMVerify([_mockMetadataIndexer checkAndAppendData:@"menlopark" forKey:@"r4"]);
}

- (void)testGetMetadataWithInvalidCity
{
  // Although rule_V for city is @"", but should not accept empty text case
  NSString *text = @"";
  NSString *indicator = @"city";
  [FBSDKMetadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:@"r4"]);
}

- (void)testGetMetadataWithInvalidCityIndicator
{
  NSString *text = @"Menlo Park";
  NSString *indicator = @"test";
  [FBSDKMetadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:@"r4"]);
}

// test for getting meta with state
- (void)testGetMetadataWithValidState
{
  NSString *text = @"CA";
  NSString *indicator = @"province";
  [FBSDKMetadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  OCMVerify([_mockMetadataIndexer checkAndAppendData:@"ca" forKey:@"r5"]);
}

- (void)testGetMetadataWithInvalidState
{
  // Although rule_V for state is @"", but should not accept empty text case
  NSString *text = @"";
  NSString *indicator = @"state";
  [FBSDKMetadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:@"r5"]);
}

- (void)testGetMetadataWithInvalidStateIndicator
{
  NSString *text = @"CA";
  NSString *indicator = @"test";
  [FBSDKMetadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:@"r5"]);
}

// test for getting meta with zip
- (void)testGetMetadataWithValidZip
{
  NSString *text = @"94025";
  NSString *indicator = @"zcode";
  [FBSDKMetadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  OCMVerify([_mockMetadataIndexer checkAndAppendData:text forKey:@"r6"]);
}

// test for getting metadata with valid zipcode containing "-" (will also be regarded as phone number)
- (void)testGetMetadataWithValidZipWithPunctuations
{
  NSString *text = @"94025-1234";
  [FBSDKMetadataIndexer getMetadataWithText:text
                                placeholder:@""
                                     labels:@[@"zcode", @"phone"]
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypePhonePad];
  OCMVerify([_mockMetadataIndexer checkAndAppendData:@"94025" forKey:@"r6"]);
  OCMVerify([_mockMetadataIndexer checkAndAppendData:@"940251234" forKey:@"r2"]);
  OCMReject([_mockMetadataIndexer checkAndAppendData:text forKey:@"r6"]);
}

- (void)testGetMetadataWithInvalidZip
{
  // the rule for zip code should be 5-digit number
  NSString *text = @"9402";
  NSString *indicator = @"zcode";
  [FBSDKMetadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:@"r6"]);
}

- (void)testGetMetadataWithInvalidZipIndicator
{
  NSString *text = @"94025";
  NSString *indicator = @"test";
  [FBSDKMetadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:@"r6"]);
}

// test for getting meta with first name
- (void)testGetMetadataWithValidFn
{
  NSString *text = @"David";
  NSString *indicator = @"fn";
  [FBSDKMetadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  OCMVerify([_mockMetadataIndexer checkAndAppendData:@"david" forKey:@"r7"]);
}

- (void)testGetMetadataWithInvalidFn
{
  // Although rule_V for first name is @"", but should not accept empty text case
  NSString *text = @"";
  NSString *indicator = @"fn";
  [FBSDKMetadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:@"r7"]);
}

- (void)testGetMetadataWithInvalidFnIndicator
{
  NSString *text = @"David";
  NSString *indicator = @"test";
  [FBSDKMetadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:@"r7"]);
}

// test for getting meta with last name
- (void)testGetMetadataWithValidLn
{
  NSString *text = @"Taylor";
  NSString *indicator = @"ln";
  [FBSDKMetadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  OCMVerify([_mockMetadataIndexer checkAndAppendData:@"taylor" forKey:@"r8"]);
}

- (void)testGetMetadataWithInvalidLn
{
  // Although rule_V for last name is @"", but should not accept empty text case
  NSString *text = @"";
  NSString *indicator = @"ln";
  [FBSDKMetadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:@"r8"]);
}

- (void)testGetMetadataWithInvalidLnIndicator
{
  NSString *text = @"Taylor";
  NSString *indicator = @"test";
  [FBSDKMetadataIndexer getMetadataWithText:text
                                placeholder:indicator
                                     labels:nil
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:@"r8"]);
}

// test for getting meta with first name with labels (will also be regarded as last name, state, city
- (void)testGetMetadataWithFirstNameWithLabels
{
  NSString *text = @"Taylor";
  [FBSDKMetadataIndexer getMetadataWithText:text
                                placeholder:@""
                                     labels:@[@"fn", @"ln", @"state", @"city"]
                            secureTextEntry:NO
                                  inputType:UIKeyboardTypeDefault];
  OCMVerify([_mockMetadataIndexer checkAndAppendData:@"taylor" forKey:@"r4"]);
  OCMVerify([_mockMetadataIndexer checkAndAppendData:@"taylor" forKey:@"r5"]);
  OCMVerify([_mockMetadataIndexer checkAndAppendData:@"taylor" forKey:@"r7"]);
  OCMVerify([_mockMetadataIndexer checkAndAppendData:@"taylor" forKey:@"r8"]);
}

@end
