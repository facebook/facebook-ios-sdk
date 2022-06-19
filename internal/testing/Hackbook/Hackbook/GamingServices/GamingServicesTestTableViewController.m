// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#ifndef RELEASED_SDK_ONLY
#import "GamingServicesTestTableViewController.h"

#import "GamingPayloadDelegate.h"
#import "GamingServicesCellController.h"

@interface GamingServicesTestTableViewController ()
@property (nonatomic, strong) id<FBSDKGamingPayloadDelegate> payloadDelegate;
@property (nonatomic, strong) FBSDKGamingPayloadObserver *payloadObserver;

@end

@implementation GamingServicesTestTableViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.title = @"Gaming Services";
  self.payloadDelegate = [GamingPayloadDelegate new];

  GamingServicesRegisterCells(self.tableView);
  self.payloadObserver = [[FBSDKGamingPayloadObserver alloc] initWithDelegate:self.payloadDelegate];
}

- (void)viewWillDisappear:(BOOL)animated
{
  self.payloadObserver.delegate = nil;
}

#pragma mark - Table view data source

- (NSInteger) tableView:(UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
  return GamingServicesCellCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return GamingServicesConfiguredCell(indexPath, tableView);
}

- (void)        tableView:(UITableView *)tableView
  didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.row == GamingServicesCellRowCustomUpdate) {
    [self performSegueWithIdentifier:@"contextAPISegue" sender:self];
  } else if (indexPath.row == GamingServicesCellRowTournaments) {
    [self performSegueWithIdentifier:@"tournamentSegue" sender:self];
  } else {
    GamingServicesDidSelectCell(indexPath.row);
  }
}

@end
#endif
