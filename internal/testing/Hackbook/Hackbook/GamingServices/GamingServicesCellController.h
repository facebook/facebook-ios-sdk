// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#ifndef RELEASED_SDK_ONLY
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, GamingServicesCellRow) {
  GamingServicesCellRowFriendFinder,
  GamingServicesCellRowUploadPhoto,
  GamingServicesCellRowUploadVideo,
  GamingServicesCellRowOpenGamingGroup,
  GamingServicesCellRowCustomUpdate,
  GamingServicesCellRowTournaments,
  // Adding a row? You should increment GamingServicesCellCount
};
static const int GamingServicesCellCount = 6;
void LaunchCreateContextDialog(NSString *playerID);
void GamingServicesRegisterCells(UITableView *tableView);
UITableViewCell *GamingServicesConfiguredCell(NSIndexPath *indexPath, UITableView *tableView);
void GamingServicesDidSelectCell(GamingServicesCellRow row);
#endif
