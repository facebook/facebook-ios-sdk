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

// This deserves some explanation.
// Cocoapods - we define FBAEMKit as a subspec so to import it we need to use
// the name of the module produced by the podspec which is FBSDKCoreKit. To be able
// to reference it as <FBAEMKit> we need to publish a separate pod.
// Because of the way files in the subspec are made available to the pod, we do not need
// to use the bracket import syntax.
//
// BUCK - we define FBAEMKit as a separate library so we must import it as
// <FBAEMKit>
//
// Xcodeproj - we define FBAEMKit as a distinct module with its own project
// so that we can import it as <FBAEMKit>
//
// Swift Package Manager - it can be imported with `@import FBAEMKit` which allows us to reference
// public headers without bracket import syntax.

#if !TARGET_OS_TV

#import "FBAEMNetworking.h"
#import "FBAEMReporter.h"

#endif
