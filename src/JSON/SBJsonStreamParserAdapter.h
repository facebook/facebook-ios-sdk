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
#import "SBJsonStreamParser.h"

typedef enum {
	SBJsonStreamParserAdapterNone,
	SBJsonStreamParserAdapterArray,
	SBJsonStreamParserAdapterObject,
} SBJsonStreamParserAdapterType;

/**
 @brief Delegate for getting objects & arrays from the stream parser adapter
 
 You will most likely find it much more convenient to implement this
 than the raw SBJsonStreamParserDelegate protocol.
 
 @see The TwitterStream example project.
 */
@protocol SBJsonStreamParserAdapterDelegate

/// Called when a JSON array is found
- (void)parser:(SBJsonStreamParser*)parser foundArray:(NSArray*)array;

/// Called when a JSON object is found
- (void)parser:(SBJsonStreamParser*)parser foundObject:(NSDictionary*)dict;

@end


@interface SBJsonStreamParserAdapter : NSObject <SBJsonStreamParserDelegate> {
	id<SBJsonStreamParserAdapterDelegate> delegate;
	NSUInteger skip, depth;
	__weak NSMutableArray *array;
	__weak NSMutableDictionary *dict;
	NSMutableArray *keyStack;
	NSMutableArray *stack;
	
	SBJsonStreamParserAdapterType currentType;
}

/**
 @brief How many levels to skip
 
 This is useful for parsing HUGE JSON documents, particularly if it consists of an
 outer array and multiple objects.
 
 If you set this to N it will skip the outer N levels and call the -parser:foundArray:
 or -parser:foundObject: methods for each of the inner objects, as appropriate.
 
 @see The StreamParserIntegrationTest.m file for examples
*/
@property NSUInteger skip;

/// Set this to the object you want to receive messages
@property (assign) id<SBJsonStreamParserAdapterDelegate> delegate;

@end
