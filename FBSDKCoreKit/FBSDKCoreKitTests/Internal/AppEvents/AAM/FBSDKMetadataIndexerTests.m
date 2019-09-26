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

#import <OCMock/OCMock.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKMetadataIndexer.h"

extern FBSDKAppEventUserDataType FBSDKAppEventRule1;
extern FBSDKAppEventUserDataType FBSDKAppEventRule2;

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

@interface FBSDKMetadataIndexerTests : XCTestCase {
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
                                        @"r1": @{
                                                @"k": @"email,e-mail,em,electronicmail",
                                                @"v": @"^([A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,})$",
                                                },
                                        @"r2": @{
                                                @"k": @"phone,mobile,contact",
                                                @"v": @"^([0-9]{5,15})$",
                                                }
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
    XCTAssertFalse([FBSDKMetadataIndexer checkSecureTextEntry:_emailField],
                   @"test for UITextField without secure text");

    // with secure text
    XCTAssertTrue([FBSDKMetadataIndexer checkSecureTextEntry:_pwdField],
                  @"test for UITextField with secure text");
}

// test for geting secure text entry in UITextView
- (void)testCheckSecureTextEntryOfTextView
{
    // without secure text
    XCTAssertFalse([FBSDKMetadataIndexer checkSecureTextEntry:_emailView],
                   @"test for UITextView without secure text");

    // with secure text
    XCTAssertTrue([FBSDKMetadataIndexer checkSecureTextEntry:_pwdView], @"test for UITextView with secure text");
}

// test for geting keyboard type from UITextField
- (void)testGetKeyboardTypeOfTextField
{
    XCTAssertEqual(_emailField.keyboardType,
                   [FBSDKMetadataIndexer getKeyboardType:_emailField],
                   @"test for geting keyboard type from UITextField");
}

// test for geting keyboard type from UITextView
- (void)testGetKeyboardTypeOfTextView
{
    XCTAssertEqual(_emailView.keyboardType,
                   [FBSDKMetadataIndexer getKeyboardType:_emailView],
                   @"test for geting keyboard type from UITextView");
}

// test for geting metadata with valid email
- (void)testGetMetadataWithEmail
{
    NSString *text = @"test@fb.com";
    [FBSDKMetadataIndexer getMetadataWithText:text
                                  placeholder:@"enter your email"
                                       labels:nil
                              secureTextEntry:NO
                                    inputType:UIKeyboardTypeEmailAddress];
    OCMVerify([_mockMetadataIndexer checkAndAppendData:text forKey:FBSDKAppEventRule1]);
    OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:FBSDKAppEventRule2]);
}

// test for geting metadata with valid phone number
- (void)testGetMetadataWithPhoneNumber
{
    NSString *text = @"1112223333";
    [FBSDKMetadataIndexer getMetadataWithText:text
                                  placeholder:@"enter your phone number"
                                       labels:nil
                              secureTextEntry:NO
                                    inputType:UIKeyboardTypePhonePad];
    OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:FBSDKAppEventRule1]);
    OCMVerify([_mockMetadataIndexer checkAndAppendData:text forKey:FBSDKAppEventRule2]);
}

// test for geting metadata with secure text
- (void)testGetMetadataWithSecureText
{
    NSString *text = @"dfjald1314";
    [FBSDKMetadataIndexer getMetadataWithText:text
                                  placeholder:@"enter your password"
                                       labels:nil
                              secureTextEntry:YES
                                    inputType:UIKeyboardTypeDefault];
    OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:FBSDKAppEventRule1]);
    OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:FBSDKAppEventRule2]);
}

// test for geting metadata with invalid email
- (void)testGetMetadataWithInvalidEmail
{
    NSString *text = @"test";
    [FBSDKMetadataIndexer getMetadataWithText:text
                                  placeholder:@"enter your email"
                                       labels:nil
                              secureTextEntry:NO
                                    inputType:UIKeyboardTypeEmailAddress];
    OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:FBSDKAppEventRule1]);
    OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:FBSDKAppEventRule2]);
}

// test for geting metadata with invalid email placeholder
- (void)testGetMetadataWithInvalidEmailPlaceholder
{
    NSString *text = @"test@fb.com";
    [FBSDKMetadataIndexer getMetadataWithText:text
                                  placeholder:@"enter your"
                                       labels:nil
                              secureTextEntry:NO
                                    inputType:UIKeyboardTypeEmailAddress];
    OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:FBSDKAppEventRule1]);
    OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:FBSDKAppEventRule2]);
}

// test for geting metadata with invalid phone number
- (void)testGetMetadataWithInvalidPhoneNumber
{
    NSString *text = @"1234";
    [FBSDKMetadataIndexer getMetadataWithText:text
                                  placeholder:@"enter your phone number"
                                       labels:nil
                              secureTextEntry:NO
                                    inputType:UIKeyboardTypePhonePad];
    OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:FBSDKAppEventRule1]);
    OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:FBSDKAppEventRule2]);
}

// test for geting metadata with invalid phone number placeholder
- (void)testGetMetadataWithInvalidPhoneNumberPlaceholder
{
    NSString *text = @"1112223333";
    [FBSDKMetadataIndexer getMetadataWithText:text
                                  placeholder:@"enter your"
                                       labels:nil
                              secureTextEntry:NO
                                    inputType:UIKeyboardTypePhonePad];
    OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:FBSDKAppEventRule1]);
    OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:FBSDKAppEventRule2]);
}

// test for geting metadata with text which is neither email nor phone number
- (void)testGetMetadataWithTextNotEmailAndPhone
{
    NSString *text = @"Facebook";
    [FBSDKMetadataIndexer getMetadataWithText:text
                                  placeholder:@"enter your name"
                                       labels:nil
                              secureTextEntry:NO
                                    inputType:UIKeyboardTypeAlphabet];
    OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:FBSDKAppEventRule1]);
    OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:FBSDKAppEventRule2]);
}

// test for geting metadata with no text
- (void)testGetMetadataWithNoText
{
    NSString *text = @"";
    [FBSDKMetadataIndexer getMetadataWithText:text
                                  placeholder:@"enter your email"
                                       labels:nil
                              secureTextEntry:NO
                                    inputType:UIKeyboardTypeEmailAddress];
    OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:FBSDKAppEventRule1]);
    OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:FBSDKAppEventRule2]);
}

// test for geting metadata with too long text
- (void)testGetMetadataWithTooLongText
{
    NSString *text = [NSString stringWithFormat:@"%@%@", [@"" stringByPaddingToLength:1000 withString: @"a" startingAtIndex:0], @"@fb.com"];
    [FBSDKMetadataIndexer getMetadataWithText:text
                                  placeholder:@"enter your email"
                                       labels:nil
                              secureTextEntry:NO
                                    inputType:UIKeyboardTypeEmailAddress];
    OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:FBSDKAppEventRule1]);
    OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:FBSDKAppEventRule2]);
}

// test for geting metadata with too long placeholder
- (void)testGetMetadataWithTooLongPlaceholder
{
    NSString *text = @"test@fb.com";
    NSString *indicator = [NSString stringWithFormat:@"%@", [@"" stringByPaddingToLength:1000 withString: @"enter your email " startingAtIndex:0]];
    [FBSDKMetadataIndexer getMetadataWithText:text
                                  placeholder:indicator
                                       labels:nil
                              secureTextEntry:NO
                                    inputType:UIKeyboardTypeEmailAddress];
    OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:FBSDKAppEventRule1]);
    OCMReject([_mockMetadataIndexer checkAndAppendData:[OCMArg any] forKey:FBSDKAppEventRule2]);
}

@end
