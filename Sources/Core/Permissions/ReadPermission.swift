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
 Enum that represents a Graph API read permission.
 Each permission has its own set of requirements and suggested use cases.
 See a full list at https://developers.facebook.com/docs/facebook-login/permissions
 */
public enum ReadPermission: PermissionRepresentable {
  /// Provides access to a subset of items that are part of a person's public profile.
  case publicProfile
  /// Provides access the list of friends that also use your app.
  case userFriends
  /// Provides access to the person's primary email address.
  case email
  /// Provides access to a person's personal description (the 'About Me' section on their Profile)
  case userAboutMe
  /// Provides access to all common books actions published by any app the person has used.
  /// This includes books they've read, want to read, rated or quoted.
  case userActionsBooks
  /// Provides access to all common Open Graph fitness actions published by any app the person has used.
  /// This includes runs, walks and bikes actions.
  case userActionsFitness
  /// Provides access to all common Open Graph music actions published by any app the person has used.
  /// This includes songs they've listened to, and playlists they've created.
  case userActionsMusic
  /// Provides access to all common Open Graph news actions published by any app the person
  /// has used which publishes these actions.
  /// This includes news articles they've read or news articles they've published.
  case userActionsNews
  /// Provides access to all common Open Graph video actions published by any app the person
  /// has used which publishes these actions.
  case userActionsVideo
  /// Access the date and month of a person's birthday. This may or may not include the person's year of birth,
  /// dependent upon their privacy settings and the access token being used to query this field.
  case userBirthday
  /// Provides access to a person's education history through the education field on the User object.
  case userEducationHistory
  /// Provides read-only access to the Events a person is hosting or has RSVP'd to.
  case userEvents
  /// Provides access to read a person's game activity (scores, achievements) in any game the person has played.
  case userGamesActivity
  /// Provides access to a person's gender.
  case userGender
  /// Provides access to a person's hometown location through the hometown field on the User object.
  case userHometown
  /// Provides access to the list of all Facebook Pages and Open Graph objects that a person has liked.
  case userLikes
  /// Provides access to a person's current city through the location field on the User object.
  case userLocation
  /// Lets your app read the content of groups a person is an admin of through the Groups edge on the User object.
  case userManagedGroups
  /// Provides access to the photos a person has uploaded or been tagged in.
  case userPhotos
  /// Provides access to the posts on a person's Timeline. Includes their own posts, posts they are tagged in,
  /// and posts other people make on their Timeline.
  case userPosts
  /// Provides access to a person's relationship status,
  /// significant other and family members as fields on the User object.
  case userRelationships
  /// Provides access to a person's relationship interests as the interested_in field on the User object.
  case userRelationshipDetails
  /// Provides access to a person's religious and political affiliations.
  case userReligionPolitics
  /// Provides access to the Places a person has been tagged at in photos, videos, statuses and links.
  case userTaggedPlaces
  /// Provides access to the videos a person has uploaded or been tagged in.
  case userVideos
  /// Provides access to the person's personal website URL via the website field on the User object.
  case userWebsite
  /// Provides access to a person's work history and list of employers via the work field on the User object.
  case userWorkHistory
  /// Provides access to the names of custom lists a person has created to organize their friends.
  case readCustomFriendlists
  /// Provides read-only access to the Insights data for Pages, Apps and web domains the person owns.
  case readInsights
  /// Provides read-only access to the Audience Network Insights data for Apps the person owns.
  case readAudienceNetworkInsights
  /// Provides the ability to read from the Page Inboxes of the Pages managed by a person.
  case readPageMailboxes
  /// Provides the access to show the list of the Pages that you manage.
  case pagesShowList
  /// Provides the access to manage call to actions of the Pages that you manage.
  case pagesManageCta
  /// Lets your app manage Instant Articles on behalf of Facebook Pages administered by people using your app.
  case pagesManageInstantArticles
  /// Provides the access to Ads Insights API to pull ads report information for ad accounts you have access to.
  case adsRead
  /**
   Permission with a custom string value.
   See https://developers.facebook.com/docs/facebook-login/permissions for full list of available permissions.
   */
  case custom(String)

  // MARK: PermissionRepresentable
  internal var permissionValue: Permission {
    switch self {
    case .publicProfile: return "public_profile"
    case .userFriends: return "user_friends"
    case .email: return "email"
    case .userAboutMe: return "user_about_me"
    case .userActionsBooks: return "user_actions.books"
    case .userActionsFitness: return "user_action.fitness"
    case .userActionsMusic: return "user_actions.music"
    case .userActionsNews: return "user_actions.news"
    case .userActionsVideo: return "user_actions.video"
    case .userBirthday: return "user_birthday"
    case .userEducationHistory: return "user_education_history"
    case .userEvents: return "user_events"
    case .userGamesActivity: return "user_games_activity"
    case .userGender: return "user_gender"
    case .userHometown: return "user_hometown"
    case .userLikes: return "user_likes"
    case .userLocation: return "user_location"
    case .userManagedGroups: return "user_managed_groups"
    case .userPhotos: return "user_photos"
    case .userPosts: return "user_posts"
    case .userRelationships: return "user_relationships"
    case .userRelationshipDetails: return "user_relationship_details"
    case .userReligionPolitics: return "user_religion_politics"
    case .userTaggedPlaces: return "user_tagged_places"
    case .userVideos: return "user_videos"
    case .userWebsite: return "user_website"
    case .userWorkHistory: return "user_work_history"
    case .readCustomFriendlists: return "read_custom_friendlists"
    case .readInsights: return "read_insights"
    case .readAudienceNetworkInsights: return "read_audience_network_insights"
    case .readPageMailboxes: return "read_page_mailboxes"
    case .pagesShowList: return "pages_show_list"
    case .pagesManageCta: return "pages_manage_cta"
    case .pagesManageInstantArticles: return "pages_manage_instant_articles"
    case .adsRead: return "ads_read"
    case .custom(let string): return Permission(name: string)
    }
  }
}
