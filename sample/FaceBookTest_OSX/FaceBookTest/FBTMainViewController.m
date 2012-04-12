//
//  FBTMainViewController.m
//  FaceBookTest
//
//  Created by David Bitton on 3/15/12.
//  Copyright (c) 2012 Code No Evil LLC. All rights reserved.
//

#import "FBTMainViewController.h"
#import "FBTAppDelegate.h"

@interface FBTMainViewController ()
- (void)showLoggedIn;
- (void)showLoggedOut;
- (void)storeAuthData:(NSString *)accessToken expiresAt:(NSDate *)expiresAt;
@end

@implementation FBTMainViewController 

@synthesize permissions;
@synthesize loginButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    DLog(@"%@", self);
    return self;
}

-(void)awakeFromNib {
    permissions = [[NSArray alloc] initWithObjects:@"offline_access", nil]; 
    [[[self view] window] setDefaultButtonCell:[loginButton cell]];     
}

- (void)login {
    FBTAppDelegate *delegate = (FBTAppDelegate *)[NSApp delegate];
    if (![[delegate facebook] isSessionValid]) {
        [[delegate facebook] authorize:permissions];
    } else {
        [self showLoggedIn];
    }
}

- (void)logout {
    FBTAppDelegate *delegate = (FBTAppDelegate *)[NSApp delegate];
    [[delegate facebook] logout];
}

- (void)toggleState:(id)sender {
    FBTAppDelegate *delegate = (FBTAppDelegate *)[NSApp delegate];
    if([delegate loggedIn]) {
        [self logout];
    } else {
        [self login];
    }
}

#pragma mark -
#pragma mark FBTMainViewController ()

-(void)showLoggedIn {
    FBTAppDelegate *delegate = (FBTAppDelegate *)[[NSApplication sharedApplication] delegate];
    [delegate setLoggedIn:YES];
    
    DLog(@"Logged in");
    [[self loginButton] setTitle:@"Logout"];
}

-(void)showLoggedOut {
    FBTAppDelegate *delegate = (FBTAppDelegate *)[[NSApplication sharedApplication] delegate];
    [delegate setLoggedIn:NO];
    
    DLog(@"Logged out");
    [[self loginButton] setTitle:@"Login"];
}

- (void)storeAuthData:(NSString *)accessToken expiresAt:(NSDate *)expiresAt {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:accessToken forKey:@"FBAccessTokenKey"];
    [defaults setObject:expiresAt forKey:@"FBExpirationDateKey"];
    [defaults synchronize];
}

#pragma mark -
#pragma mark FBSessionDelegate

- (void)fbDidLogin {
    [self showLoggedIn];
    
    FBTAppDelegate *delegate = (FBTAppDelegate *)[[NSApplication sharedApplication] delegate];
    [self storeAuthData:[[delegate facebook] accessToken] expiresAt:[[delegate facebook] expirationDate]]; 
}

- (void)fbDidLogout {
    // Remove saved authorization information if it exists and it is
    // ok to clear it (logout, session invalid, app unauthorized)
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"FBAccessTokenKey"];
    [defaults removeObjectForKey:@"FBExpirationDateKey"];
    [defaults synchronize];   
    
    [self showLoggedOut];
}

- (void)fbDidNotLogin:(BOOL)cancelled {
    DLog(@"Not logged in: %i", cancelled);
}

- (void)fbDidExtendToken:(NSString *)accessToken expiresAt:(NSDate *)expiresAt {
    
}

- (void)fbSessionInvalidated {
    
}

#pragma mark -
#pragma mark - FBRequestDelegate Methods

- (void)request:(FBRequest *)request didReceiveResponse:(NSURLResponse *)response {
    
}

- (void)request:(FBRequest *)request didLoad:(id)result {
    
}

- (void)request:(FBRequest *)request didFailWithError:(NSError *)error {
    
}

@end
