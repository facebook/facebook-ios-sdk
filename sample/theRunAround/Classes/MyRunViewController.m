/*
 * Copyright 2010 Facebook
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *    http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "MyRunViewController.h"
#import "UserInfo.h"
#import "RunViewCell.h"

@implementation MyRunViewController


@synthesize userInfo = _userInfo,
            managedObjectContext = _managedObjectContext;

///////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark View lifecycle

- (void) dataFilter {
  
  NSEntityDescription *runEntity = [NSEntityDescription entityForName:@"Runs" 
                                               inManagedObjectContext:_managedObjectContext];
  
  
  NSPredicate * predicate; 
  NSDate *today = [NSDate date];
  NSDate *oneWeekeAgo = [today addTimeInterval: -604800.0];

  predicate = [NSPredicate predicateWithFormat:
               @"facebookUid == %@ AND date > %@", _userInfo.uid, oneWeekeAgo];
   
  NSSortDescriptor * sort = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:FALSE];
  NSArray * sortDescriptors = [NSArray arrayWithObject: sort]; 
  NSFetchRequest * fetch = [[NSFetchRequest alloc] init]; 
  [fetch setEntity: runEntity]; 
  [fetch setPredicate: predicate]; 
  [fetch setSortDescriptors: sortDescriptors]; 
  _data = [[_managedObjectContext executeFetchRequest:fetch error:nil] retain]; 
  [sort release]; 
  [fetch release]; 
  
}

- (void)viewDidLoad {
  [super viewDidLoad];

}


- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self dataFilter];  
  [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  // Return YES for supported orientations
  return YES;
}



#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

  return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

  if (section == 0) {
    return [_data count];
  } else {
    return [_userInfo.friendsInfo count];
  }

}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  
  if(section == 0)
    return @"My recent run:";
  else
    return @"Friends' activities:";
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
  static NSString *CellIdentifier = @"Cell";
    
  RunViewCell *cell = (RunViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[[RunViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                               reuseIdentifier:CellIdentifier] autorelease];
  }
    
    // Configure the cell...
  if (indexPath.section == 0) {
    NSMutableDictionary *cellValue = [_data objectAtIndex:indexPath.row];
    cell.primaryLabel.text = [cellValue valueForKey:@"location"];
    cell.runImageView.image = [UIImage imageNamed:@"FBConnect.bundle/images/runaround_image.jpg"];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    
    cell.secondaryLabel.text = [NSString stringWithFormat:@"%@ miles on %@", 
                                [[cellValue valueForKey:@"distance"] stringValue],
                                [dateFormatter stringFromDate:[cellValue valueForKey:@"date"]]
                                ];
                                
    [dateFormatter release];
  } else {
    NSMutableDictionary *cellValue = [_userInfo.friendsInfo objectAtIndex:indexPath.row];
    NSString *picURL = [cellValue objectForKey:@"pic"];
    if ((picURL != (NSString *) [NSNull null]) && (picURL.length !=0)) {
      NSData *imgData = [[[NSData dataWithContentsOfURL:
                           [NSURL URLWithString:
                            [cellValue objectForKey:@"pic"]]] autorelease] retain];
      cell.runImageView.image = [[UIImage alloc] initWithData:imgData];
    } else {
      cell.runImageView.image = nil;
    }


    cell.primaryLabel.text = [cellValue objectForKey:@"name"]; 
    
    
    NSEntityDescription *runEntity = [NSEntityDescription entityForName:@"Runs" 
                                                 inManagedObjectContext:_managedObjectContext];
    
    NSPredicate * predicate; 
    
    predicate = [NSPredicate predicateWithFormat:@"facebookUid == %@", 
                 [cellValue objectForKey:@"uid"]];
    
    NSSortDescriptor * sort = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:TRUE];
    NSArray * sortDescriptors = [NSArray arrayWithObject: sort]; 
    NSFetchRequest * fetch = [[NSFetchRequest alloc] init]; 
    [fetch setEntity: runEntity]; 
    [fetch setPredicate: predicate]; 
    [fetch setSortDescriptors: sortDescriptors]; 
    NSArray *friendsRunData= [[[_managedObjectContext executeFetchRequest:fetch error:nil] 
                               autorelease] retain]; 
    [sort release]; 
    [fetch release]; 
    
    if ([friendsRunData count] > 0) {
      NSDictionary *frendRecentRun = [friendsRunData lastObject];
      NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
      [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
      [dateFormatter setDateStyle:NSDateFormatterShortStyle];
      
      cell.secondaryLabel.text = [NSString stringWithFormat:@"%@ miles at %@ on %@", 
                                  [[frendRecentRun valueForKey:@"distance"] stringValue],
                                  [frendRecentRun valueForKey:@"location"],
                                  [dateFormatter stringFromDate:
                                   [frendRecentRun valueForKey:@"date"]]];                                 
      [dateFormatter release];
    } else {
      cell.secondaryLabel.text = @"not run yet";  
    }

  }
  return cell;
}

- (void)dealloc {
  [_data release];
  [_userInfo release];
  [super dealloc];
}


@end

