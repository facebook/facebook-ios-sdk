/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if BUCK
import FacebookCore
#else
import FBSDKCoreKit
#endif

import XCTest

final class PermissionTests: XCTestCase {
  struct PermissionMapping {
    let permission: Permission
    let name: String
  }

  let mappings = [
    PermissionMapping(permission: .publicProfile, name: "public_profile"),
    PermissionMapping(permission: .userFriends, name: "user_friends"),
    PermissionMapping(permission: .email, name: "email"),
    PermissionMapping(permission: .userAboutMe, name: "user_about_me"),
    PermissionMapping(permission: .userActionsBooks, name: "user_actions.books"),
    PermissionMapping(permission: .userActionsFitness, name: "user_action.fitness"),
    PermissionMapping(permission: .userActionsMusic, name: "user_actions.music"),
    PermissionMapping(permission: .userActionsNews, name: "user_actions.news"),
    PermissionMapping(permission: .userActionsVideo, name: "user_actions.video"),
    PermissionMapping(permission: .userBirthday, name: "user_birthday"),
    PermissionMapping(permission: .userEducationHistory, name: "user_education_history"),
    PermissionMapping(permission: .userEvents, name: "user_events"),
    PermissionMapping(permission: .userGamesActivity, name: "user_games_activity"),
    PermissionMapping(permission: .userGender, name: "user_gender"),
    PermissionMapping(permission: .userHometown, name: "user_hometown"),
    PermissionMapping(permission: .userLikes, name: "user_likes"),
    PermissionMapping(permission: .userLocation, name: "user_location"),
    PermissionMapping(permission: .userManagedGroups, name: "user_managed_groups"),
    PermissionMapping(permission: .userPhotos, name: "user_photos"),
    PermissionMapping(permission: .userPosts, name: "user_posts"),
    PermissionMapping(permission: .userRelationships, name: "user_relationships"),
    PermissionMapping(permission: .userRelationshipDetails, name: "user_relationship_details"),
    PermissionMapping(permission: .userReligionPolitics, name: "user_religion_politics"),
    PermissionMapping(permission: .userTaggedPlaces, name: "user_tagged_places"),
    PermissionMapping(permission: .userVideos, name: "user_videos"),
    PermissionMapping(permission: .userWebsite, name: "user_website"),
    PermissionMapping(permission: .userWorkHistory, name: "user_work_history"),
    PermissionMapping(permission: .readCustomFriendlists, name: "read_custom_friendlists"),
    PermissionMapping(permission: .readInsights, name: "read_insights"),
    PermissionMapping(permission: .readAudienceNetworkInsights, name: "read_audience_network_insights"),
    PermissionMapping(permission: .readPageMailboxes, name: "read_page_mailboxes"),
    PermissionMapping(permission: .pagesShowList, name: "pages_show_list"),
    PermissionMapping(permission: .pagesManageCta, name: "pages_manage_cta"),
    PermissionMapping(permission: .pagesManageInstantArticles, name: "pages_manage_instant_articles"),
    PermissionMapping(permission: .adsRead, name: "ads_read"),
    PermissionMapping(permission: .custom("test_permission"), name: "test_permission"),
  ]

  func testCases() {
    for mapping in mappings {
      switch mapping.permission {
      // If the compiler tells that this switch must be exhaustive, then a new
      // permission has been added.  You must add a new test mapping above
      // if you are adding a new case here.
      case
        .publicProfile,
        .userFriends,
        .email,
        .userAboutMe,
        .userActionsBooks,
        .userActionsFitness,
        .userActionsMusic,
        .userActionsNews,
        .userActionsVideo,
        .userBirthday,
        .userEducationHistory,
        .userEvents,
        .userGamesActivity,
        .userGender,
        .userHometown,
        .userLikes,
        .userLocation,
        .userManagedGroups,
        .userPhotos,
        .userPosts,
        .userRelationships,
        .userRelationshipDetails,
        .userReligionPolitics,
        .userTaggedPlaces,
        .userVideos,
        .userWebsite,
        .userWorkHistory,
        .readCustomFriendlists,
        .readInsights,
        .readAudienceNetworkInsights,
        .readPageMailboxes,
        .pagesShowList,
        .pagesManageCta,
        .pagesManageInstantArticles,
        .adsRead,
        .custom:
        break
      @unknown default:
        break
      }
    }
  }

  func testCreatingFromStringLiteral() {
    for mapping in mappings {
      XCTAssertEqual(
        Permission(stringLiteral: mapping.name),
        mapping.permission,
        "Should be able to create the \(mapping.permission) permission with the string literal \"\(mapping.name)\""
      )
    }

    XCTAssertEqual(
      Permission(stringLiteral: ""),
      .custom(""),
      "Should be able to create the custom permission with an empty string"
    )
  }

  func testNames() {
    for mapping in mappings {
      XCTAssertEqual(
        mapping.permission.name,
        mapping.name,
        "The name of the \(mapping.permission) permission should be \"\(mapping.name)\""
      )
    }

    XCTAssertEqual(
      Permission.custom("").name,
      "",
      "The name of the custom permission created with an empty string should be an empty string"
    )
  }
}
