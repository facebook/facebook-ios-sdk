/*
 * Copyright 2010 Facebook
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

#import "APIResultsViewController.h"
#import "HackbookAppDelegate.h"

@implementation APIResultsViewController

@synthesize myData;
@synthesize myAction;
@synthesize messageLabel;
@synthesize messageView;

- (id)initWithTitle:(NSString *)title data:(NSArray *)data action:(NSString *)action {
    self = [super init];
    if (self) {
        if (nil != data) {
            myData = [[NSMutableArray alloc] initWithArray:data copyItems:YES];
        }
        self.navigationItem.title = [title retain];
        self.myAction = [action retain];
    }
    return self;
}

- (void)dealloc {
    [myData release];
    [myAction release];
    [messageLabel release];
    [messageView release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)loadView {
    UIView *view = [[UIView alloc] initWithFrame:[UIScreen
                                                  mainScreen].applicationFrame];
    [view setBackgroundColor:[UIColor whiteColor]];
    self.view = view;
    [view release];

    // Main Menu Table
    UITableView *myTableView = [[UITableView alloc] initWithFrame:self.view.bounds
                                                            style:UITableViewStylePlain];
    [myTableView setBackgroundColor:[UIColor whiteColor]];
    myTableView.dataSource = self;
    myTableView.delegate = self;
    myTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    if ([self.myAction isEqualToString:@"places"]) {
        UILabel *headerLabel = [[[UILabel alloc]
                                 initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 30)] autorelease];
        headerLabel.text = @"  Tap selection to check in";
        headerLabel.font = [UIFont fontWithName:@"Helvetica" size:14.0];
        headerLabel.backgroundColor = [UIColor colorWithRed:255.0/255.0
                                                      green:248.0/255.0
                                                       blue:228.0/255.0
                                                      alpha:1];
        myTableView.tableHeaderView = headerLabel;
    }
    [self.view addSubview:myTableView];
    [myTableView release];

    // Message Label for showing confirmation and status messages
    CGFloat yLabelViewOffset = self.view.bounds.size.height-self.navigationController.navigationBar.frame.size.height-30;
    messageView = [[UIView alloc]
                   initWithFrame:CGRectMake(0, yLabelViewOffset, self.view.bounds.size.width, 30)];
    messageView.backgroundColor = [UIColor lightGrayColor];

    UIView *messageInsetView = [[UIView alloc] initWithFrame:CGRectMake(1, 1, self.view.bounds.size.width-1, 28)];
    messageInsetView.backgroundColor = [UIColor colorWithRed:255.0/255.0
                                                       green:248.0/255.0
                                                        blue:228.0/255.0
                                                       alpha:1];
    messageLabel = [[UILabel alloc]
                    initWithFrame:CGRectMake(4, 1, self.view.bounds.size.width-10, 26)];
    messageLabel.text = @"";
    messageLabel.font = [UIFont fontWithName:@"Helvetica" size:14.0];
    messageLabel.backgroundColor = [UIColor colorWithRed:255.0/255.0
                                                   green:248.0/255.0
                                                    blue:228.0/255.0
                                                   alpha:0.6];
    [messageInsetView addSubview:messageLabel];
    [messageView addSubview:messageInsetView];
    [messageInsetView release];
    messageView.hidden = YES;
    [self.view addSubview:messageView];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark - Facebook API Calls
/*
 * Graph API: Check in a user to the location selected in the previous view.
 */
- (void)apiGraphUserCheckins:(NSUInteger)index {
    HackbookAppDelegate *delegate = (HackbookAppDelegate *)[[UIApplication sharedApplication] delegate];
    FBSBJSON *jsonWriter = [[FBSBJSON new] autorelease];

    NSDictionary *coordinates = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [[[myData objectAtIndex:index] objectForKey:@"location"] objectForKey:@"latitude"],@"latitude",
                                  [[[myData objectAtIndex:index] objectForKey:@"location"] objectForKey:@"longitude"],@"longitude",
                                  nil];

    NSString *coordinatesStr = [jsonWriter stringWithObject:coordinates];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [[myData objectAtIndex:index] objectForKey:@"id"], @"place",
                                   coordinatesStr, @"coordinates",
                                   @"", @"message",
                                   nil];
    [[delegate facebook] requestWithGraphPath:@"me/checkins"
                                    andParams:params
                                andHttpMethod:@"POST"
                                  andDelegate:self];
}


#pragma mark - Private Methods
/*
 * Helper method to return the picture endpoint for a given Facebook
 * object. Useful for displaying user, friend, or location pictures.
 */
- (UIImage *)imageForObject:(NSString *)objectID {
    // Get the object image
    NSString *url = [[NSString alloc] initWithFormat:@"https://graph.facebook.com/%@/picture",objectID];
    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:url]]];
    [url release];
    return image;
}

/*
 * This method is used to display API confirmation and
 * error messages to the user.
 */
- (void)showMessage:(NSString *)message {
    CGRect labelFrame = messageView.frame;
    labelFrame.origin.y = [UIScreen mainScreen].bounds.size.height - self.navigationController.navigationBar.frame.size.height - 20;
    messageView.frame = labelFrame;
    messageLabel.text = message;
    messageView.hidden = NO;

    // Use animation to show the message from the bottom then
    // hide it.
    [UIView animateWithDuration:0.5
                          delay:1.0
                        options: UIViewAnimationCurveEaseOut
                     animations:^{
                         CGRect labelFrame = messageView.frame;
                         labelFrame.origin.y -= labelFrame.size.height;
                         messageView.frame = labelFrame;
                     }
                     completion:^(BOOL finished){
                         if (finished) {
                             [UIView animateWithDuration:0.5
                                                   delay:3.0
                                                 options: UIViewAnimationCurveEaseOut
                                              animations:^{
                                                  CGRect labelFrame = messageView.frame;
                                                  labelFrame.origin.y += messageView.frame.size.height;
                                                  messageView.frame = labelFrame;
                                              }
                                              completion:^(BOOL finished){
                                                  if (finished) {
                                                      messageView.hidden = YES;
                                                      messageLabel.text = @"";
                                                  }
                                              }];
                         }
                     }];
}

/*
 * This method hides the message, only needed if view closed
 * and animation still going on.
 */
- (void)hideMessage {
    messageView.hidden = YES;
    messageLabel.text = @"";
}

/*
 * This method handles any clean up needed if the view
 * is about to disappear.
 */
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self hideMessage];
}

#pragma mark - UITableView Datasource and Delegate Methods
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80.0;
}

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [myData count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
        // Show disclosure only if this view is related to showing nearby places, thus allowing
        // the user to check-in.
        if ([self.myAction isEqualToString:@"places"]) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }

    cell.textLabel.text = [[myData objectAtIndex:indexPath.row] objectForKey:@"name"];
    cell.textLabel.font = [UIFont boldSystemFontOfSize:14.0];
    cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
    cell.textLabel.numberOfLines = 2;
    // If extra information available then display this.
    if ([[myData objectAtIndex:indexPath.row] objectForKey:@"details"]) {
        
        id details = [[myData objectAtIndex:indexPath.row] objectForKey:@"details"];
        if (![details isKindOfClass:[NSString class]]) {
            // If details isn't a string, it's the return data for an image request, and we pull
            // the url for it.
            details = [[details objectForKey:@"data"] objectForKey:@"url"];
        }
        cell.detailTextLabel.text = details;
        cell.detailTextLabel.font = [UIFont fontWithName:@"Helvetica" size:12.0];
        cell.detailTextLabel.lineBreakMode = UILineBreakModeCharacterWrap;
        cell.detailTextLabel.numberOfLines = 2;
    }
    // The object's image
    cell.imageView.image = [self imageForObject:[[myData objectAtIndex:indexPath.row] objectForKey:@"id"]];
    // Configure the cell.
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Only handle taps if the view is related to showing nearby places that
    // the user can check-in to.
    if ([self.myAction isEqualToString:@"places"]) {
        [self apiGraphUserCheckins:indexPath.row];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - FBRequestDelegate Methods
/**
 * Called when the Facebook API request has returned a response. This callback
 * gives you access to the raw response. It's called before
 * (void)request:(FBRequest *)request didLoad:(id)result,
 * which is passed the parsed response object.
 */
- (void)request:(FBRequest *)request didReceiveResponse:(NSURLResponse *)response {
    //NSLog(@"received response");
}

/**
 * Called when a request returns and its response has been parsed into
 * an object. The resulting object may be a dictionary, an array, a string,
 * or a number, depending on the format of the API response. If you need access
 * to the raw response, use:
 *
 * (void)request:(FBRequest *)request
 *      didReceiveResponse:(NSURLResponse *)response
 */
- (void)request:(FBRequest *)request didLoad:(id)result {
    [self showMessage:@"Checked in successfully"];
}

/**
 * Called when an error prevents the Facebook API request from completing
 * successfully.
 */
- (void)request:(FBRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"Error message: %@", [[error userInfo] objectForKey:@"error_msg"]);
    [self showMessage:@"Oops, something went haywire."];
}

@end
