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

#import <FBSDKShareKit/FBSDKHashtag.h>

@interface FBSDKHashtagTests : XCTestCase

@end

@implementation FBSDKHashtagTests

- (void)testValidHashtag
{
  FBSDKHashtag *hashtag = [FBSDKHashtag hashtagWithString:@"#ValidHashtag"];
  XCTAssertTrue(hashtag.valid);
}

- (void)testInvalidHashtagWithSpaces
{
  FBSDKHashtag *leadingSpace = [FBSDKHashtag hashtagWithString:@" #LeadingSpaceIsInvalid"];
  XCTAssertFalse(leadingSpace.valid);
  FBSDKHashtag *trailingSpace = [FBSDKHashtag hashtagWithString:@"#TrailingSpaceIsInvalid "];
  XCTAssertFalse(trailingSpace.valid);
  FBSDKHashtag *embeddedSpace = [FBSDKHashtag hashtagWithString:@"#No spaces in hashtags"];
  XCTAssertFalse(embeddedSpace.valid);
}

- (void)testCopy
{
  FBSDKHashtag *hashtag = [FBSDKHashtag hashtagWithString:@"#ToCopy"];
  FBSDKHashtag *copied = [hashtag copy];
  XCTAssertEqualObjects(hashtag, copied);
  copied.stringRepresentation = @"#ModifiedCopy";
  XCTAssertNotEqualObjects(hashtag, copied);
}

- (void)testCoding
{
  FBSDKHashtag *hashtag = [FBSDKHashtag hashtagWithString:@"#Encoded"];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:hashtag];
  FBSDKHashtag *unarchivedHashtag = [NSKeyedUnarchiver unarchiveObjectWithData:data];
  XCTAssertEqualObjects(hashtag, unarchivedHashtag);
}

@end
