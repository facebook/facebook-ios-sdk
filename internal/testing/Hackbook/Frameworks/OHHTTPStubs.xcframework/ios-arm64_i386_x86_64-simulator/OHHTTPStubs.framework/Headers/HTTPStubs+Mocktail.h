/***********************************************************************************
 *
 * Copyright (c) 2015 Jinlian (Sunny) Wang
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

#import "Compatibility.h"
#import "HTTPStubs.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Error codes for the OHHTTPStubs Mocktail category
 */
typedef NS_ENUM(NSInteger, OHHTTPStubsMocktailError) {
  /** The specified path does not exist */
  OHHTTPStubsMocktailErrorPathDoesNotExist = 1,
  /** The specified path was not readable */
  OHHTTPStubsMocktailErrorPathFailedToRead,
  /** The specified path is not a directory */
  OHHTTPStubsMocktailErrorPathIsNotFolder,
  /** The specified file is not a valid Mocktail file */
  OHHTTPStubsMocktailErrorInvalidFileFormat,
  /** The specified Mocktail file has invalid headers */
  OHHTTPStubsMocktailErrorInvalidFileHeader,
  /** An unexpected internal error occured */
  OHHTTPStubsMocktailErrorInternalError,
};

extern NSString *const MocktailErrorDomain;

@interface HTTPStubs (Mocktail)

/**
 * Add a stub given a file in the format of Mocktail as defined at https://github.com/square/objc-mocktail.
 *
 * This method will split the HTTP method Regex, the absolute URL Regex, the headers, the HTTP status code and
 * response body, and use them to add a stub.
 *
 * @param fileName The name of the mocktail file (without extension of '.tail') in the Mocktail format.
 * @param bundleOrNil The bundle in which the mocktail file is located. If `nil`, the `[NSBundle bundleForClass:self.class]` will be used.
 * @param error An out value that returns any error encountered during stubbing. Returns an NSError object if any error; otherwise returns nil.
 *
 * @return a stub descriptor that uniquely identifies the stub and can be later used to remove it with
 * `removeStub:`.
 */
+ (id<HTTPStubsDescriptor>)stubRequestsUsingMocktailNamed:(NSString *)fileName inBundle:(nullable NSBundle *)bundleOrNil error:(NSError **)error;

/**
 * Add a stub given a file URL in the format of Mocktail as defined at https://github.com/square/objc-mocktail.
 *
 * This method will split the HTTP method Regex, the absolute URL Regex, the headers, the HTTP status code and
 * response body, and use them to add a stub.
 *
 * @param fileURL The URL pointing to the file in the Mocktail format.
 * @param error An out value that returns any error encountered during stubbing. Returns an NSError object if any error; otherwise returns nil.
 *
 * @return a stub descriptor that uniquely identifies the stub and can be later used to remove it with
 * `removeStub:`.
 */
+ (id<HTTPStubsDescriptor>)stubRequestsUsingMocktail:(NSURL *)fileURL error:(NSError **)error;

/**
 * Add stubs using files under a folder in the format of Mocktail as defined at https://github.com/square/objc-mocktail.
 *
 * This method will retrieve all the files under the folder; for each file with surfix of ".tail", it will split the HTTP method Regex, the absolute URL Regex, the headers, the HTTP status code and response body, and use them to add a stub.
 *
 * @param path The name of the folder containing files in the Mocktail format.
 * @param bundleOrNil The bundle in which the path is located. If `nil`, the `[NSBundle bundleForClass:self.class]` will be used.
 * @param error An out value that returns any error encountered during stubbing. Returns an NSError object if any error; otherwise returns nil.
 *
 * @return an array of stub descriptor that uniquely identifies the stub and can be later used to remove it with
 * `removeStub:`.
 */
+ (NSArray *)stubRequestsUsingMocktailsAtPath:(NSString *)path inBundle:(nullable NSBundle *)bundleOrNil error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
