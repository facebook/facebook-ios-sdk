/***********************************************************************************
*
* Copyright (c) 2016 Sebastian Hagedorn, Felix Lamouroux
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*
***********************************************************************************/

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Imports

#import <Foundation/Foundation.h>

// This category is only useful when NSURLSession is present
#if defined(__IPHONE_7_0) || defined(__MAC_10_9)

////////////////////////////////////////////////////////////////////////////////
 #pragma mark - NSURLRequest+HTTPBodyTesting

@interface NSURLRequest (HTTPBodyTesting)
/**
 *   Unfortunately, when sending POST requests (with a body) using NSURLSession,
 *   by the time the request arrives at OHHTTPStubs, the HTTPBody of the
 *   NSURLRequest has been reset to nil.
 *
 *   You can use this method to retrieve the HTTPBody for testing and use it to
 *   conditionally stub your requests.
 */
- (NSData *)OHHTTPStubs_HTTPBody;
@end

#endif /* __IPHONE_7_0 || __MAC_10_9 */
