/*
 * Copyright 2010-present Facebook.
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

#import "FBViewController.h"
#import "FBViewController+Internal.h"
#import "FBLogger.h"
#import "FBSettings.h"

@interface FBViewController ()

@property (nonatomic, retain) UIToolbar *toolbar;
@property (nonatomic, retain) UIView *canvasView;
@property (nonatomic, retain) UIBarButtonItem *titleLabel;
@property (nonatomic, copy) FBModalCompletionHandler handler;
@property (nonatomic) BOOL autoDismiss;
@property (nonatomic) BOOL dismissAnimated;

- (void)cancelButtonPressed:(id)sender;
- (void)doneButtonPressed:(id)sender;
- (void)updateBarForPresentedMode;
- (void)updateBarForNavigationMode;
- (void)updateBar;

@end

@implementation FBViewController

@synthesize cancelButton = _cancelButton;
@synthesize doneButton = _doneButton;
@synthesize delegate = _delegate;
@synthesize toolbar = _toolbar;
@synthesize canvasView = _canvasView;
@synthesize titleLabel = _titleLabel;
@synthesize handler = _handler;
@synthesize autoDismiss = _autoDismiss;
@synthesize dismissAnimated = _dismissAnimated;

#pragma mark View controller lifecycle

- (void) commonInit {
    // We do this at init-time rather than in viewDidLoad so the caller can change the buttons if
    // they want prior to the view loading.
    self.cancelButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                       target:self
                                                                       action:@selector(cancelButtonPressed:)]
                         autorelease];
    self.doneButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                     target:self
                                                                     action:@selector(doneButtonPressed:)]
                       autorelease];

}

- (id)init {
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self commonInit];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self commonInit];
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
    
    [_cancelButton release];
    [_doneButton release];
    [_toolbar release];
    [_canvasView release];
    [_titleLabel release];
    [_handler release];
}

#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.autoresizesSubviews = YES;
    
    self.canvasView = [[[UIView alloc] init] autorelease];
    [self.canvasView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];

    self.canvasView.frame = self.view.bounds;
    [self.view addSubview:self.canvasView];
    [self.view sendSubviewToBack:self.canvasView];
    
    self.autoDismiss = NO;

    self.doneButton.target = self;
    self.doneButton.action = @selector(doneButtonPressed:);
    self.cancelButton.target = self;
    self.cancelButton.action = @selector(cancelButtonPressed:);
    
    [self updateBar];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    // If the view goes away for any reason, nil out the handler to avoid a retain cycle.
    self.handler = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark Public methods

- (void)presentModallyFromViewController:(UIViewController*)viewController
                                animated:(BOOL)animated
                                 handler:(FBModalCompletionHandler)handler {
    self.handler = handler;
    // Assumption: we want to dismiss with the same animated-ness as we present.
    self.dismissAnimated = animated;
    
    if ([viewController respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        [viewController presentViewController:self animated:animated completion:nil];
    } else {
        [viewController presentModalViewController:self animated:animated];
    }
    
    // Set this here because we always revert to NO in viewDidLoad.
    self.autoDismiss = YES;
}

#pragma mark Implementation

- (void)updateBar {
    if (self.compatiblePresentingViewController != nil) {
        [self updateBarForPresentedMode];
    } else if (self.navigationController != nil) {
        [self updateBarForNavigationMode];
    }
}

- (void)updateBarForPresentedMode {
    BOOL needBar = (self.doneButton != nil) || (self.cancelButton != nil);
    if (needBar) {
        // If we need a bar but don't have one, create it.
        if (self.toolbar == nil) {
            self.toolbar = [[[UIToolbar alloc] init] autorelease];
            self.toolbar.barStyle = UIBarStyleDefault;
            
            [self.toolbar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
            
            [self.view addSubview:self.toolbar];
        }
    } else {
        // If we have a bar but don't need one, get rid of it.
        if (self.toolbar != nil) {
            [self.toolbar removeFromSuperview];
            self.toolbar = nil;
            
            self.canvasView.frame = self.view.bounds;
        }
        return;
    }
    
    NSMutableArray *buttons = [NSMutableArray array];
    if (self.cancelButton != nil) {
        [buttons addObject:self.cancelButton];
    } else {
        // No cancel button, but if we have a done and a title, add some space at the beginning to help center the title.
        if (self.doneButton != nil && self.title.length > 0) {
            UIBarButtonItem *space = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
                                                                                    target:nil
                                                                                    action:nil] 
                                      autorelease];
            [buttons addObject:space];
        }
    }
    if (self.title.length > 0) {
        UIBarButtonItem *space = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
                                                                                target:nil
                                                                                action:nil] 
                                  autorelease];
        [buttons addObject:space];
        
        if (self.titleLabel == nil) {
            UILabel *label = [[[UILabel alloc] init] autorelease];
            label.font = [UIFont fontWithName:@"Helvetica-Bold" size:20];
            label.backgroundColor = [UIColor clearColor];
            label.textColor = [UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0];
            label.textAlignment = UITextAlignmentCenter;
            label.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];

            self.titleLabel = [[[UIBarButtonItem alloc] initWithCustomView:label] autorelease];
        }
        [(UILabel*)self.titleLabel.customView setText:self.title];
        [self.titleLabel.customView sizeToFit];
        
        [buttons addObject:self.titleLabel];
        
        space = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
                                                               target:nil
                                                               action:nil] 
                                  autorelease];
        [buttons addObject:space];
        
    }

    if (self.doneButton != nil) {
        // If no title, we need a space to right-align
        if (self.title.length == 0) {
            UIBarButtonItem *space = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
                                                                                    target:nil
                                                                                    action:nil] 
                                      autorelease];
            [buttons addObject:space];
        }
        [buttons addObject:self.doneButton];
    } else {
        // No done button, but if we have a cancel and a title, add some space at the end to help center the title.
        if (self.cancelButton != nil && self.title.length > 0) {
            UIBarButtonItem *space = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
                                                                                    target:nil
                                                                                    action:nil] 
                                      autorelease];
            [buttons addObject:space];
        }
    }

    [self.toolbar sizeToFit];
    CGRect bounds = self.toolbar.bounds;
    bounds = CGRectMake(0, 0, self.view.bounds.size.width, bounds.size.height);
    self.toolbar.bounds = bounds;

    // Make the canvas shorter to account for the toolbar.
    bounds = self.view.bounds;
    CGFloat toolbarHeight = self.toolbar.bounds.size.height;
    bounds.origin.y += toolbarHeight;
    bounds.size.height -= toolbarHeight;
    self.canvasView.frame = bounds;

    self.toolbar.items = buttons;
}

- (void)updateBarForNavigationMode {
    self.navigationItem.rightBarButtonItem = self.doneButton;
}

- (void)setCancelButton:(UIBarButtonItem *)cancelButton {
    if (_cancelButton != cancelButton) {
        [_cancelButton release];
        _cancelButton = [cancelButton retain];
        [self updateBar];
    }
}

- (void)setDoneButton:(UIBarButtonItem *)doneButton {
    if (_doneButton != doneButton) {
        [_doneButton release];
        _doneButton = [doneButton retain];
        [self updateBar];
    }
}

- (void)setTitle:(NSString *)title {
    [super setTitle:title];
    [self updateBar];
}

- (UIViewController *)compatiblePresentingViewController {
    if ([self respondsToSelector:@selector(presentingViewController)]) {
        return [self presentingViewController];
    } else {
        UIViewController *parentViewController = [self parentViewController];
        if (self == [parentViewController modalViewController]) {
            return parentViewController;
        }
    }
    return nil;
}

#pragma mark Handlers

- (void)cancelButtonPressed:(id)sender {
    if ([self.delegate respondsToSelector:@selector(facebookViewControllerCancelWasPressed:)]) {
        [self.delegate facebookViewControllerCancelWasPressed:self];
    }
    
    UIViewController *presentingViewController = [self compatiblePresentingViewController];
    if (self.autoDismiss && presentingViewController) {
        if ([presentingViewController respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
            [presentingViewController dismissViewControllerAnimated:self.dismissAnimated completion:nil];
        } else {
            [presentingViewController dismissModalViewControllerAnimated:self.dismissAnimated];
        }
        
        [self logInsights:YES];
        if (self.handler) {
            self.handler(self, NO);
        }
    }
}

- (void)doneButtonPressed:(id)sender {
    if ([self.delegate respondsToSelector:@selector(facebookViewControllerDoneWasPressed:)]) {
        [self.delegate facebookViewControllerDoneWasPressed:self];
    }
    
    UIViewController *presentingViewController = [self compatiblePresentingViewController];
    if (self.autoDismiss && presentingViewController) {
        if ([presentingViewController respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
            [presentingViewController dismissViewControllerAnimated:self.dismissAnimated completion:nil];
        } else {
            [presentingViewController dismissModalViewControllerAnimated:self.dismissAnimated];
        }
        
        [self logInsights:NO];
        if (self.handler) {
            self.handler(self, YES);
        }
    }
}

- (void)logInsights:(BOOL)cancelled {
    // Internal subclasses that will implicitly log Insights will do so here.
}


@end
