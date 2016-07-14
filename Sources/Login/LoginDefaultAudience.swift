// Copyright (c) 2016-present, Facebook, Inc. All rights reserved.
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

import Foundation

import FBSDKLoginKit

/**
 Indicates which default audience to use for sessions that post data to Facebook.

 Certain operations such as publishing a status or publishing a photo require an audience.
 When the user grants an application permission to perform a publish operation,
 a default audience is selected as the publication ceiling for the application.
 This enumerated value allows the application to select which audience to ask the user to grant publish permission for.
 */
public enum LoginDefaultAudience {
  /// Indicates that the user's friends are able to see posts made by the application.
  case Friends
  /// Indicates that only the user is able to see posts made by the application.
  case OnlyMe
  /// Indicates that all Facebook users are able to see posts made by the application.
  case Everyone
}

extension LoginDefaultAudience {
  internal var sdkAudience: FBSDKDefaultAudience {
    switch self {
    case .Friends: return .Friends
    case .OnlyMe: return .OnlyMe
    case .Everyone: return .Everyone
    }
  }
}
