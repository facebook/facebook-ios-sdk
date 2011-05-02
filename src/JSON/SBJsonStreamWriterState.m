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

#import "SBJsonStreamWriterState.h"
#import "SBJsonStreamWriter.h"

// States
SBJsonStreamWriterStateStart *kSBJsonStreamWriterStateStart;
SBJsonStreamWriterStateComplete *kSBJsonStreamWriterStateComplete;
SBJsonStreamWriterStateError *kSBJsonStreamWriterStateError;

SBJsonStreamWriterStateObjectStart *kSBJsonStreamWriterStateObjectStart;
static SBJsonStreamWriterStateObjectKey *kSBJsonStreamWriterStateObjectKey;
static SBJsonStreamWriterStateObjectValue *kSBJsonStreamWriterStateObjectValue;

SBJsonStreamWriterStateArrayStart *kSBJsonStreamWriterStateArrayStart;
static SBJsonStreamWriterStateArrayValue *kSBJsonStreamWriterStateArrayValue;

@implementation SBJsonStreamWriterState
- (BOOL)isInvalidState:(SBJsonStreamWriter*)writer { return NO; }
- (void)appendSeparator:(SBJsonStreamWriter*)writer {}
- (BOOL)expectingKey:(SBJsonStreamWriter*)writer { return NO; }
- (void)transitionState:(SBJsonStreamWriter *)writer {}
- (void)appendWhitespace:(SBJsonStreamWriter*)writer {
	[writer appendBytes:"\n" length:1];
	for (NSUInteger i = 0; i < writer.depth; i++)
	    [writer appendBytes:"  " length:2];
}
@end

@implementation SBJsonStreamWriterStateObjectStart
- (void)transitionState:(SBJsonStreamWriter *)writer {
	writer.states[writer.depth] = kSBJsonStreamWriterStateObjectValue;
}
- (BOOL)expectingKey:(SBJsonStreamWriter *)writer {
	writer.error = @"JSON object key must be string";
	return YES;
}
@end

@implementation SBJsonStreamWriterStateObjectKey
- (void)appendSeparator:(SBJsonStreamWriter *)writer {
	[writer appendBytes:"," length:1];
}
@end

@implementation SBJsonStreamWriterStateObjectValue
- (void)appendSeparator:(SBJsonStreamWriter *)writer {
	[writer appendBytes:":" length:1];
}
- (void)transitionState:(SBJsonStreamWriter *)writer {
	writer.states[writer.depth] = kSBJsonStreamWriterStateObjectKey;
}
- (void)appendWhitespace:(SBJsonStreamWriter *)writer {
	[writer appendBytes:" " length:1];
}
@end

@implementation SBJsonStreamWriterStateArrayStart
- (void)transitionState:(SBJsonStreamWriter *)writer {
	writer.states[writer.depth] = kSBJsonStreamWriterStateArrayValue;
}
@end

@implementation SBJsonStreamWriterStateArrayValue
- (void)appendSeparator:(SBJsonStreamWriter *)writer {
	[writer appendBytes:"," length:1];
}
@end

@implementation SBJsonStreamWriterStateStart

+ (id)sharedInstance {
	if (!kSBJsonStreamWriterStateStart) {
		kSBJsonStreamWriterStateStart = [SBJsonStreamWriterStateStart new];
		kSBJsonStreamWriterStateComplete = [SBJsonStreamWriterStateComplete new];
		kSBJsonStreamWriterStateError = [SBJsonStreamWriterStateError new];
		kSBJsonStreamWriterStateObjectStart = [SBJsonStreamWriterStateObjectStart new];
		kSBJsonStreamWriterStateObjectKey = [SBJsonStreamWriterStateObjectKey new];
		kSBJsonStreamWriterStateObjectValue = [SBJsonStreamWriterStateObjectValue new];
		kSBJsonStreamWriterStateArrayStart = [SBJsonStreamWriterStateArrayStart new];
		kSBJsonStreamWriterStateArrayValue = [SBJsonStreamWriterStateArrayValue new];
	}
	return kSBJsonStreamWriterStateStart;
}

- (void)transitionState:(SBJsonStreamWriter *)writer {
	writer.states[writer.depth] = kSBJsonStreamWriterStateComplete;
}
- (void)appendSeparator:(SBJsonStreamWriter *)writer {
}
@end

@implementation SBJsonStreamWriterStateComplete
- (BOOL)isInvalidState:(SBJsonStreamWriter*)writer {
	writer.error = @"Stream is closed";
	return YES;
}
@end

@implementation SBJsonStreamWriterStateError
@end

