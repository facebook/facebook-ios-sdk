/*
 * Copyright 2012 Facebook
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

#import "SCMealViewController.h"

@interface SCMealViewController () {
    NSArray *_meals;
}

@property (strong, nonatomic) IBOutlet UITableView* tableView;

@end

@implementation SCMealViewController 

@synthesize selectItemCallback = _selectItemCallback;
@synthesize tableView = _tableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Select a meal";
        
        _meals = [NSArray arrayWithObjects:
            @"Cheeseburger", 
            @"Pizza",
            @"Hotdog",
            @"Italian",
            @"French",
            @"Chinese",
            @"Thai",
            @"Indian", nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // This avoids a gray background in the table view on iPad.
    if ([self.tableView respondsToSelector:@selector(backgroundView)]) {
        self.tableView.backgroundView = nil;
    }

}
- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.tableView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _meals.count;
}

- (UITableViewCell*)tableView:(UITableView *)tblView cellForRowAtIndexPath:(NSIndexPath *)indexPath  {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }    
    
    cell.textLabel.text = [_meals objectAtIndex:indexPath.row];
    cell.imageView.image = [UIImage imageNamed:@"action-eating.png"];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.selectItemCallback) {
        self.selectItemCallback(self, [_meals objectAtIndex:indexPath.row]);
    }
    [self.navigationController popViewControllerAnimated:YES];
}


@end
