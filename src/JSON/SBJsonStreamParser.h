/*
 Copyright (c) 2010, Stig Brautaset.
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are
 met:
 
   Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
  
   Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
 
   Neither the name of the the author nor the names of its contributors
   may be used to endorse or promote products derived from this software
   without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>

@class SBJsonTokeniser;
@class SBJsonStreamParser;
@class SBJsonStreamParserState;

typedef enum {
	SBJsonStreamParserComplete,
	SBJsonStreamParserWaitingForData,
	SBJsonStreamParserError,
} SBJsonStreamParserStatus;


/**
 @brief Delegate for interacting directly with the stream parser
 
 You will most likely find it much more convenient to implement the
 SBJsonStreamParserAdapterDelegate protocol instead.
 */
@protocol SBJsonStreamParserDelegate

/// Called when object start is found
- (void)parserFoundObjectStart:(SBJsonStreamParser*)parser;

/// Called when object key is found
- (void)parser:(SBJsonStreamParser*)parser foundObjectKey:(NSString*)key;

/// Called when object end is found
- (void)parserFoundObjectEnd:(SBJsonStreamParser*)parser;

/// Called when array start is found
- (void)parserFoundArrayStart:(SBJsonStreamParser*)parser;

/// Called when array end is found
- (void)parserFoundArrayEnd:(SBJsonStreamParser*)parser;

/// Called when a boolean value is found
- (void)parser:(SBJsonStreamParser*)parser foundBoolean:(BOOL)x;

/// Called when a null value is found
- (void)parserFoundNull:(SBJsonStreamParser*)parser;

/// Called when a number is found
- (void)parser:(SBJsonStreamParser*)parser foundNumber:(NSNumber*)num;

/// Called when a string is found
- (void)parser:(SBJsonStreamParser*)parser foundString:(NSString*)string;

@end


/**
 @brief JSON Stream-parser class
 
 */
@interface SBJsonStreamParser : NSObject {
	BOOL multi;
	id<SBJsonStreamParserDelegate> delegate;
	SBJsonTokeniser *tokeniser;
	SBJsonStreamParserState **states;
	NSUInteger depth, maxDepth;
	NSString *error;
}

/**
 @brief Expect multiple documents separated by whitespace

 If you set this property to true the parser will never return SBJsonStreamParserComplete.
 Once an object is completed it will expect another object to follow, separated only by whitespace.

 @see The TwitterStream example project.
 */
@property BOOL multi;

/// Set this to the object you want to receive messages
@property (assign) id<SBJsonStreamParserDelegate> delegate;

/// The current depth in the json document (each [ and { each count 1)
@property (readonly) NSUInteger depth;

/// The max depth to allow the parser to reach
@property NSUInteger maxDepth;

/// @internal
@property (readonly) SBJsonStreamParserState **states;

/// Holds the error after SBJsonStreamParserError was returned
@property (copy) NSString *error;

/**
 @brief Parse some JSON
 
 The JSON is assumed to be UTF8 encoded. This can be a full JSON document, or a part of one.
 
 @return 
 @li SBJsonStreamParserComplete if a full document was found
 @li SBJsonStreamParserWaitingForData if a partial document was found and more data is required to complete it
 @li SBJsonStreamParserError if an error occured. (See the error property for details in this case.)
 
 */
- (SBJsonStreamParserStatus)parse:(NSData*)data;

@end
