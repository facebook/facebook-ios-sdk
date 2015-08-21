/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "FBPeoplePickerViewController.h"
#import "FBPeoplePickerViewController+Internal.h"

#import "FBError.h"
#import "FBFriendPickerViewDefaultPNG.h"
#import "FBGraphObjectPickerViewController+Internal.h"
#import "FBGraphObjectTableCell.h"
#import "FBGraphObjectTableSelection.h"
#import "FBGraphPerson.h"
#import "FBRequest.h"
#import "FBUtility.h"

@interface FBPeoplePickerViewController () <FBGraphObjectViewControllerDelegate>
@end

@implementation FBPeoplePickerViewController

@dynamic allowsMultipleSelection;

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self initializePeoplePicker];
    }

    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (self) {
        [self initializePeoplePicker];
    }

    return self;
}

- (void)initializePeoplePicker {
    // Self
    self.allowsMultipleSelection = YES;
    self.userID = @"me";
    self.sortOrdering = FBFriendSortByFirstName;
    self.displayOrdering = FBFriendDisplayByFirstName;
}

- (void)dealloc {
    [_userID release];

    [super dealloc];
}

#pragma mark - Custom Properties

- (NSArray *)selection {
    // There might be bogus items set via setSelection, so we need to check against
    // datasource and filter them out.
    NSMutableArray *validSelection = [[[NSMutableArray alloc] init] autorelease];
    for (FBGraphObject *item in self.selectionManager.selection) {
        NSIndexPath *indexPath = [self.dataSource indexPathForItem:item];
        if (indexPath != nil) {
            [validSelection addObject:item];
        }
    }
    return validSelection;
}

#pragma mark - internal members

+ (NSString *)graphAPIName {
    return nil;
}

+ (FBRequest *)requestWithUserID:(NSString *)userID
                          fields:(NSSet *)fields
                      dataSource:(FBGraphObjectTableDataSource *)datasource
                         session:(FBSession *)session {

    NSString *graphAPIName = [self graphAPIName];
    if (graphAPIName == nil) {
        [[NSException exceptionWithName:FBInvalidOperationException
                                 reason:@"FBPeoplePickerViewController: An attempt was made to create "
          @"an FBRequest using the abstract class. Send the message to the appropriate subclass instead."
                               userInfo:nil]
         raise];
    }

    FBRequest *request = [FBRequest requestForGraphPath:[NSString stringWithFormat:@"%@/%@", userID, graphAPIName]];
    [request setSession:session];

    // Use field expansion to fetch a 100px wide picture if we're on a retina device.
    NSString *pictureField = ([FBUtility isRetinaDisplay]) ? @"picture.width(100).height(100)" : @"picture";

    NSString *allFields = [datasource fieldsForRequestIncluding:fields,
                           @"id",
                           @"name",
                           @"first_name",
                           @"middle_name",
                           @"last_name",
                           pictureField,
                           nil];
    [request.parameters setObject:allFields forKey:@"fields"];

    return request;
}

+ (NSString *)cacheIdentity {
    return nil;
}

- (void)configureDataSource:(FBGraphObjectTableDataSource *)dataSource {
    [super configureDataSource:dataSource];
    dataSource.defaultPicture = [FBFriendPickerViewDefaultPNG image];
    dataSource.controllerDelegate = self;
    dataSource.itemTitleSuffixEnabled = YES;
}

#pragma mark - private members

- (FBRequest *)requestForLoadData {

    // Respect user settings in case they have changed.
    NSMutableArray *sortFields = [NSMutableArray array];
    NSString *groupByField = nil;
    if (self.sortOrdering == FBFriendSortByFirstName) {
        [sortFields addObject:@"first_name"];
        [sortFields addObject:@"middle_name"];
        [sortFields addObject:@"last_name"];
        groupByField = @"first_name";
    } else {
        [sortFields addObject:@"last_name"];
        [sortFields addObject:@"first_name"];
        [sortFields addObject:@"middle_name"];
        groupByField = @"last_name";
    }
    [self.dataSource setSortingByFields:sortFields ascending:YES];
    self.dataSource.groupByField = groupByField;
    self.dataSource.useCollation = YES;

    // me or one of my friends that also uses the app
    NSString *user = self.userID;
    if (!user) {
        user = @"me";
    }

    // create the request and start the loader
    FBRequest *request = [[self class] requestWithUserID:user
                                                  fields:self.fieldsForRequest
                                              dataSource:self.dataSource
                                                 session:self.session];
    return request;
}

- (void)loadDataSkippingRoundTripIfCached:(NSNumber *)skipRoundTripIfCached {
    if (self.session) {
        [self.loader startLoadingWithRequest:[self requestForLoadData]
                               cacheIdentity:[[self class] cacheIdentity]
                       skipRoundtripIfCached:skipRoundTripIfCached.boolValue];
    }
}

#pragma mark - FBGraphObjectViewControllerDelegate

- (BOOL)graphObjectTableDataSource:(FBGraphObjectTableDataSource *)dataSource
                filterIncludesItem:(id<FBGraphObject>)item {
    return [self delegateIncludesGraphObject:item];
}

- (NSString *)graphObjectTableDataSource:(FBGraphObjectTableDataSource *)dataSource
                             titleOfItem:(id<FBGraphObject>)graphObject {
    // Title is either "First Middle" or "Last" depending on display order.
    id<FBGraphPerson> graphPerson = (id<FBGraphPerson>)graphObject;
    if (self.displayOrdering == FBFriendDisplayByFirstName) {
        if (graphPerson.middle_name) {
            return [NSString stringWithFormat:@"%@ %@", graphPerson.first_name, graphPerson.middle_name];
        } else {
            return graphPerson.first_name;
        }
    } else {
        return graphPerson.last_name;
    }
}

- (NSString *)graphObjectTableDataSource:(FBGraphObjectTableDataSource *)dataSource
                       titleSuffixOfItem:(id<FBGraphObject>)graphObject {
    // Title suffix is either "Last" or "First Middle" depending on display order.
    id<FBGraphPerson> graphPerson = (id<FBGraphPerson>)graphObject;
    if (self.displayOrdering == FBFriendDisplayByLastName) {
        if (graphPerson.middle_name) {
            return [NSString stringWithFormat:@"%@ %@", graphPerson.first_name, graphPerson.middle_name];
        } else {
            return graphPerson.first_name;
        }
    } else {
        return graphPerson.last_name;
    }

}

- (NSString *)graphObjectTableDataSource:(FBGraphObjectTableDataSource *)dataSource
                        pictureUrlOfItem:(id<FBGraphObject>)graphObject {
    id picture = [graphObject objectForKey:@"picture"];
    // Depending on what migration the app is in, we may get back either a string, or a
    // dictionary with a "data" property that is a dictionary containing a "url" property.
    if ([picture isKindOfClass:[NSString class]]) {
        return picture;
    }
    id data = [picture objectForKey:@"data"];
    return [data objectForKey:@"url"];
}

- (void)graphObjectTableDataSource:(FBGraphObjectTableDataSource *)dataSource
                customizeTableCell:(FBGraphObjectTableCell *)cell {
    // We want to bold whichever part of the name we are sorting on.
    cell.boldTitle = (self.sortOrdering == FBFriendSortByFirstName && self.displayOrdering == FBFriendDisplayByFirstName) ||
    (self.sortOrdering == FBFriendSortByLastName && self.displayOrdering == FBFriendDisplayByLastName);
    cell.boldTitleSuffix = (self.sortOrdering == FBFriendSortByFirstName && self.displayOrdering == FBFriendDisplayByLastName) ||
    (self.sortOrdering == FBFriendSortByLastName && self.displayOrdering == FBFriendDisplayByFirstName);
}

@end
