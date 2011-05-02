/*
 Copyright (C) 2009-2011 Stig Brautaset. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
 
 * Neither the name of the author nor the names of its contributors may be used
   to endorse or promote products derived from this software without specific
   prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 @mainpage A strict JSON parser and generator for Objective-C

 JSON (JavaScript Object Notation) is a lightweight data-interchange
 format. This framework provides two apis for parsing and generating
 JSON. One standard object-based and a higher level api consisting of
 categories added to existing Objective-C classes.

 This framework does its best to be as strict as possible, both in what
 it accepts and what it generates. For example, it does not support
 trailing commas in arrays or objects. Nor does it support embedded
 comments, or anything else not in the JSON specification. This is
 considered a feature. 
  
 @section Links

 @li <a href="http://stig.github.com/json-framework">Project home page</a>.
 @li Online version of the <a href="http://stig.github.com/json-framework/api">API documentation</a>. 
 
*/

// You should not include this header directly: you should include the
// JSON.h header instead. This hack is necessary to allow using the same
// header name for the Mac framework, the iOS static library and when
// someone just copies the classes into their project.

#if SBJSON_IS_LIBRARY

#import <JSON/SBJsonParser.h>
#import <JSON/SBJsonWriter.h>
#import <JSON/SBJsonStreamParser.h>
#import <JSON/SBJsonStreamParserAdapter.h>
#import <JSON/SBJsonStreamWriter.h>
#import <JSON/NSObject+JSON.h>

#else

#import "SBJsonParser.h"
#import "SBJsonWriter.h"
#import "SBJsonStreamWriter.h"
#import "SBJsonStreamParser.h"
#import "SBJsonStreamParserAdapter.h"
#import "NSObject+JSON.h"

#endif
