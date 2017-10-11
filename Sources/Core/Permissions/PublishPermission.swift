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

/**
 Enum that represents a Graph API publish permission.
 Each permission has its own set of requirements and suggested use cases.
 See a full list at https://developers.facebook.com/docs/facebook-login/permissions
 */
public enum PublishPermission {
  /**
   Provides access to publish Posts, Open Graph actions, achievements,
   scores and other activity on behalf of a person using your app.
   */
  case publishActions
  /// Enables your app to retrieve Page Access Tokens for the Pages and Apps that the person administrates.
  case managePages
  /**
   When you also have the manage_pages permission, gives your app the ability to post, comment and like as any of the Pages managed by a person using your app.
   Apps need both manage_pages and publish_pages to be able to publish as a Page.
  */
  case publishPages
  /// Provides the ability to set a person's attendee status on Facebook Events (e.g. attending, maybe, or declined).
  case rsvpEvent
  /**
   Permission with a custom string value.
   See https://developers.facebook.com/docs/facebook-login/permissions for full list of available permissions.
   */
  case custom(String)
}

extension PublishPermission: PermissionRepresentable {
  internal var permissionValue: Permission {
    switch self {
    case .publishActions: return "publish_actions"
    case .managePages: return "manage_pages"
    case .publishPages: return "publish_pages"
    case .rsvpEvent: return "rsvp_event"
    case .custom(let string): return Permission(name: string)
    }
  }
}
