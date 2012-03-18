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


#import "FBDialog.h"
#import "Facebook.h"
#import "FBFrictionlessRequestSettings.h"
#import "JSON.h"

#if TARGET_OS_IPHONE
int const FBFlexibleWidth = UIViewAutoresizingFlexibleWidth;
int const FBFlexibleHeight = UIViewAutoresizingFlexibleHeight;
#elif TARGET_OS_MAC && !TARGET_OS_IPHONE
int const FBFlexibleWidth = NSViewWidthSizable;
int const FBFlexibleHeight = NSViewHeightSizable;
#endif

///////////////////////////////////////////////////////////////////////////////////////////////////
// global

static CGFloat kBorderGray[4] = {0.3, 0.3, 0.3, 0.8};
static CGFloat kBorderBlack[4] = {0.3, 0.3, 0.3, 1};
#if TARGET_OS_IPHONE
static CGFloat kTransitionDuration = 0.3;
#endif
static CGFloat kPadding = 0;
static CGFloat kBorderWidth = 10;

///////////////////////////////////////////////////////////////////////////////////////////////////

static BOOL FBIsDeviceIPad() {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    }
#endif
    return NO;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation FBDialog

@synthesize delegate = _dialogDelegate,
params   = _params;

///////////////////////////////////////////////////////////////////////////////////////////////////
// private

- (void)addRoundedRectToPath:(CGContextRef)context rect:(CGRect)rect radius:(float)radius {
    CGContextBeginPath(context);
    CGContextSaveGState(context);
    
    if (radius == 0) {
        CGContextTranslateCTM(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
        CGContextAddRect(context, rect);
    } else {
        rect = CGRectOffset(CGRectInset(rect, 0.5, 0.5), 0.5, 0.5);
        CGContextTranslateCTM(context, CGRectGetMinX(rect)-0.5, CGRectGetMinY(rect)-0.5);
        CGContextScaleCTM(context, radius, radius);
        float fw = CGRectGetWidth(rect) / radius;
        float fh = CGRectGetHeight(rect) / radius;
        
        CGContextMoveToPoint(context, fw, fh/2);
        CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);
        CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1);
        CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1);
        CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1);
    }
    
    CGContextClosePath(context);
    CGContextRestoreGState(context);
}

- (void)drawRect:(CGRect)rect fill:(const CGFloat*)fillColors radius:(CGFloat)radius {
#if TARGET_OS_IPHONE    
    CGContextRef context = UIGraphicsGetCurrentContext();
#elif TARGET_OS_MAC && !TARGET_OS_IPHONE
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
#endif
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    
    if (fillColors) {
        CGContextSaveGState(context);
        CGContextSetFillColor(context, fillColors);
        if (radius) {
            [self addRoundedRectToPath:context rect:rect radius:radius];
            CGContextFillPath(context);
        } else {
            CGContextFillRect(context, rect);
        }
        CGContextRestoreGState(context);
    }
    
    CGColorSpaceRelease(space);
}

- (void)strokeLines:(CGRect)rect stroke:(const CGFloat*)strokeColor {
#if TARGET_OS_IPHONE    
    CGContextRef context = UIGraphicsGetCurrentContext();
#elif TARGET_OS_MAC && !TARGET_OS_IPHONE
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
#endif
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    
    CGContextSaveGState(context);
    CGContextSetStrokeColorSpace(context, space);
    CGContextSetStrokeColor(context, strokeColor);
    CGContextSetLineWidth(context, 1.0);
    
    {
        CGPoint points[] = {{rect.origin.x+0.5, rect.origin.y-0.5},
            {rect.origin.x+rect.size.width, rect.origin.y-0.5}};
        CGContextStrokeLineSegments(context, points, 2);
    }
    {
        CGPoint points[] = {{rect.origin.x+0.5, rect.origin.y+rect.size.height-0.5},
            {rect.origin.x+rect.size.width-0.5, rect.origin.y+rect.size.height-0.5}};
        CGContextStrokeLineSegments(context, points, 2);
    }
    {
        CGPoint points[] = {{rect.origin.x+rect.size.width-0.5, rect.origin.y},
            {rect.origin.x+rect.size.width-0.5, rect.origin.y+rect.size.height}};
        CGContextStrokeLineSegments(context, points, 2);
    }
    {
        CGPoint points[] = {{rect.origin.x+0.5, rect.origin.y},
            {rect.origin.x+0.5, rect.origin.y+rect.size.height}};
        CGContextStrokeLineSegments(context, points, 2);
    }
    
    CGContextRestoreGState(context);
    
    CGColorSpaceRelease(space);
}
#if TARGET_OS_IPHONE
- (BOOL)shouldRotateToOrientation:(UIInterfaceOrientation)orientation {
    if (orientation == _orientation) {
        return NO;
    } else {
        return orientation == UIInterfaceOrientationPortrait
        || orientation == UIInterfaceOrientationPortraitUpsideDown
        || orientation == UIInterfaceOrientationLandscapeLeft
        || orientation == UIInterfaceOrientationLandscapeRight;
    }
}

- (CGAffineTransform)transformForOrientation {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (orientation == UIInterfaceOrientationLandscapeLeft) {
        return CGAffineTransformMakeRotation(M_PI*1.5);
    } else if (orientation == UIInterfaceOrientationLandscapeRight) {
        return CGAffineTransformMakeRotation(M_PI/2);
    } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
        return CGAffineTransformMakeRotation(-M_PI);
    } else {
        return CGAffineTransformIdentity;
    }
}

- (void)sizeToFitOrientation:(BOOL)transform {
    if (transform) {
        self.transform = CGAffineTransformIdentity;
    }
    
    CGRect frame = [UIScreen mainScreen].applicationFrame;
    CGPoint center = CGPointMake(
                                 frame.origin.x + ceil(frame.size.width/2),
                                 frame.origin.y + ceil(frame.size.height/2));
    
    CGFloat scale_factor = 1.0f;
    if (FBIsDeviceIPad()) {
        // On the iPad the dialog's dimensions should only be 60% of the screen's
        scale_factor = 0.6f;
    }
    
    CGFloat width = floor(scale_factor * frame.size.width) - kPadding * 2;
    CGFloat height = floor(scale_factor * frame.size.height) - kPadding * 2;
    
    _orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UIInterfaceOrientationIsLandscape(_orientation)) {
        self.frame = CGRectMake(kPadding, kPadding, height, width);
    } else {
        self.frame = CGRectMake(kPadding, kPadding, width, height);
    }
    self.center = center;
    
    if (transform) {
        self.transform = [self transformForOrientation];
    }
}

- (void)updateWebOrientation {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        [_webView stringByEvaluatingJavaScriptFromString:
         @"document.body.setAttribute('orientation', 90);"];
    } else {
        [_webView stringByEvaluatingJavaScriptFromString:
         @"document.body.removeAttribute('orientation');"];
    }
}

- (void)bounce1AnimationStopped {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:kTransitionDuration/2];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(bounce2AnimationStopped)];
    self.transform = CGAffineTransformScale([self transformForOrientation], 0.9, 0.9);
    [UIView commitAnimations];
}

- (void)bounce2AnimationStopped {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:kTransitionDuration/2];
    self.transform = [self transformForOrientation];
    [UIView commitAnimations];
}
#endif
- (NSURL*)generateURL:(NSString*)baseURL params:(NSDictionary*)params {
    if (params) {
        NSMutableArray* pairs = [NSMutableArray array];
        for (NSString* key in params.keyEnumerator) {
            NSString* value = [params objectForKey:key];
            NSString* escaped_value = (NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                                          NULL, /* allocator */
                                                                                          (CFStringRef)value,
                                                                                          NULL, /* charactersToLeaveUnescaped */
                                                                                          (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                          kCFStringEncodingUTF8);
            
            [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, escaped_value]];
            [escaped_value release];
        }
        
        NSString* query = [pairs componentsJoinedByString:@"&"];
        NSString* url = [NSString stringWithFormat:@"%@?%@", baseURL, query];
        return [NSURL URLWithString:url];
    } else {
        return [NSURL URLWithString:baseURL];
    }
}

- (void)addObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceOrientationDidChange:)
                                                 name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:) name:@"UIKeyboardWillShowNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:) name:@"UIKeyboardWillHideNotification" object:nil];
}

- (void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"UIKeyboardWillShowNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"UIKeyboardWillHideNotification" object:nil];
}

- (void)postDismissCleanup {
    [self removeObservers];
#if TARGET_OS_IPHONE
    [self removeFromSuperview];
#endif
    [_modalBackgroundView removeFromSuperview];
}

- (void)dismiss:(BOOL)animated {
    [self dialogWillDisappear];
    
    // If the dialog has been closed, then we need to cancel the order to open it.	
    // This happens in the case of a frictionless request, see webViewDidFinishLoad for details	
    [NSObject cancelPreviousPerformRequestsWithTarget:self 
                                             selector:@selector(showWebView)
                                               object:nil];
    
    [_loadingURL release];
    _loadingURL = nil;
#if TARGET_OS_IPHONE    
    if (animated) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:kTransitionDuration];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(postDismissCleanup)];
        self.alpha = 0;
        [UIView commitAnimations];
    } else {
#endif
        [self postDismissCleanup];
#if TARGET_OS_IPHONE
    }
#elif TARGET_OS_MAC && !TARGET_OS_IPHONE
    [NSApp endSheet:_sheet];
#endif
}

- (void)cancel {
    [self dialogDidCancel:nil];
}

- (BOOL)testBoolUrlParam:(NSURL *)url param:(NSString *)param {
    NSString *paramVal = [self getStringFromUrl: [url absoluteString] 
                                         needle: param];
    return [paramVal boolValue];
}

- (void)dialogSuccessHandleFrictionlessResponses:(NSURL *)url {
    // did we receive a recipient list?
    NSString *recipientJson = [self getStringFromUrl:[url absoluteString]
                                              needle:@"frictionless_recipients="];
    if (recipientJson) {
        // if value parses as an array, treat as set of fbids
        SBJsonParser *parser = [[[SBJsonParser alloc]
                                 init]
                                autorelease];
        id recipients = [parser objectWithString:recipientJson];
        
        // if we got something usable, copy the ids out and update the cache
        if ([recipients isKindOfClass:[NSArray class]]) { 
            NSMutableArray *ids = [[[NSMutableArray alloc]
                                    initWithCapacity:[recipients count]]
                                   autorelease];
            for (id recipient in recipients) {
                NSString *fbid = [NSString stringWithFormat:@"%@", recipient];
                [ids addObject:fbid];
            }
            // we may be tempted to terminate outstanding requests before this
            // point, but that would cause problems if the user cancelled a dialog
            [_frictionlessSettings updateRecipientCacheWithRecipients:ids];
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// NSObject

- (id)init {
    if ((self = [super initWithFrame:CGRectZero])) {
        _dialogDelegate = nil;
        _loadingURL = nil;
        _showingKeyboard = NO;
#if TARGET_OS_IPHONE
        self.backgroundColor = [UIColor clearColor];
        self.contentMode = UIViewContentModeRedraw;
#endif
        self.autoresizesSubviews = YES;
        self.autoresizingMask = FBFlexibleWidth | FBFlexibleHeight;
        
        _webView = [[FBWebView alloc] initWithFrame:CGRectMake(kPadding, kPadding, 480, 480)];
#if TARGET_OS_IPHONE
        _webView.delegate = self;
#elif TARGET_OS_MAC && !TARGET_OS_IPHONE
        _webView.resourceLoadDelegate = self;
        _webView.frameLoadDelegate = self;
#endif
        _webView.autoresizingMask = FBFlexibleWidth | FBFlexibleHeight;
        [self addSubview:_webView];
        
        FBImage* closeImage = [FBImage imageNamed:@"FBDialog.bundle/images/close.png"];
        
#if TARGET_OS_IPHONE
        UIColor* color = [UIColor colorWithRed:167.0/255 green:184.0/255 blue:216.0/255 alpha:1];
        _closeButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        [_closeButton setImage:closeImage forState:UIControlStateNormal];
        [_closeButton setTitleColor:color forState:UIControlStateNormal];
        [_closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [_closeButton addTarget:self action:@selector(cancel)
               forControlEvents:UIControlEventTouchUpInside];
        
        // To be compatible with OS 2.x
#if __IPHONE_OS_VERSION_MAX_ALLOWED <= __IPHONE_2_2
        _closeButton.font = [UIFont boldSystemFontOfSize:12];
#else
        _closeButton.titleLabel.font = [UIFont boldSystemFontOfSize:12];
#endif
        
        _closeButton.showsTouchWhenHighlighted = YES;
        _closeButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin
        | UIViewAutoresizingFlexibleBottomMargin;
        
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
                    UIActivityIndicatorViewStyleWhiteLarge];
        if ([_spinner respondsToSelector:@selector(setColor:)]) {
            [_spinner setColor:[UIColor grayColor]];
        } else {
            [_spinner setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
        }
        _spinner.autoresizingMask =
        UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin
        | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
#elif TARGET_OS_MAC && !TARGET_OS_IPHONE
        NSColor* color = [NSColor colorWithCalibratedRed:167.0/255 green:184.0/255 blue:216.0/255 alpha:1];
        _closeButton = [[[NSButton alloc] init] retain];
        [_closeButton setImage:closeImage];
        NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys:color, NSForegroundColorAttributeName, nil];
        NSAttributedString *attrString = [[NSAttributedString alloc]
                                          initWithString:@"Close" attributes:attributes];
        [_closeButton setAttributedTitle:attrString];
        [_closeButton setTarget:self];
        [_closeButton setAction:@selector(cancel)];
        [_closeButton setFont:[NSFont boldSystemFontOfSize:12]];
        
        _spinner = [[NSProgressIndicator alloc] init];
        [_spinner setStyle:NSProgressIndicatorSpinningStyle];
        
#endif
        [self addSubview:_closeButton];
        [self addSubview:_spinner];
#if TARGET_OS_IPHONE
        _modalBackgroundView = [[UIView alloc] init];
#endif
    }
    return self;
}

- (void)dealloc {
#if TARGET_OS_IPHONE
    _webView.delegate = nil;
#elif TARGET_OS_MAC && !TARGET_OS_IPHONE
    _webView.resourceLoadDelegate = nil;
    [_sheet release];
#endif
    [_webView release];
    [_params release];
    [_serverURL release];
    [_spinner release];
    [_closeButton release];
    [_loadingURL release];
    [_modalBackgroundView release];
    [_frictionlessSettings release];
    [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// UIView

- (void)drawRect:(CGRect)rect {
    [self drawRect:rect fill:kBorderGray radius:0];
    
    CGRect webRect = CGRectMake(
                                ceil(rect.origin.x + kBorderWidth), ceil(rect.origin.y + kBorderWidth)+1,
                                rect.size.width - kBorderWidth*2, _webView.frame.size.height+1);
    
    [self strokeLines:webRect stroke:kBorderBlack];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
}

// Display the dialog's WebView with a slick pop-up animation	
- (void)showWebView {	
    
    FBWindow* window = [FBApplication sharedApplication].keyWindow;	
    if (!window) {	
        window = [[FBApplication sharedApplication].windows objectAtIndex:0];	
    }
#if TARGET_OS_IPHONE	
    _modalBackgroundView.frame = window.frame;	
    [_modalBackgroundView addSubview:self];	
    [window addSubview:_modalBackgroundView];	
    
    self.transform = CGAffineTransformScale([self transformForOrientation], 0.001, 0.001);	
    [UIView beginAnimations:nil context:nil];	
    [UIView setAnimationDuration:kTransitionDuration/1.5];	
    [UIView setAnimationDelegate:self];	
    [UIView setAnimationDidStopSelector:@selector(bounce1AnimationStopped)];	
    self.transform = CGAffineTransformScale([self transformForOrientation], 1.1, 1.1);	
    [UIView commitAnimations];
#endif    
    [self dialogWillAppear];	
    [self addObservers];
#if TARGET_OS_MAC
    _sheet = [[NSWindow alloc] init];
    [_sheet setFrame:CGRectMake(kPadding, kPadding, 480, 520) display:YES];
    [_sheet setContentView:self];
    [_sheet setDefaultButtonCell:[_closeButton cell]];
    [NSApp beginSheet:_sheet modalForWindow:window modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];
#endif
}	

// Show a spinner during the loading time for the dialog. This is designed to show	
// on top of the webview but before the contents have loaded.	
- (void)showSpinner {	
    [_spinner sizeToFit];
#if TARGET_OS_IPHONE
    [_spinner startAnimating];	
    _spinner.center = _webView.center;
#elif TARGET_OS_MAC && !TARGET_OS_IPHONE
    [_spinner startAnimation:self];
#endif
}	

- (void)hideSpinner {	
#if TARGET_OS_IPHONE
    [_spinner stopAnimating];	
#elif TARGET_OS_MAC && !TARGET_OS_IPHONE
    [_spinner stopAnimation:self];
#endif
    _spinner.hidden = YES;	
}	

///////////////////////////////////////////////////////////////////////////////////////////////////
// UIWebViewDelegate
#if TARGET_OS_IPHONE
- (BOOL)webView:(FBWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    BOOL begin = NO;
    NSURL* url = request.URL;
    
    if ([url.scheme isEqualToString:@"fbconnect"]) {
        if ([[url.resourceSpecifier substringToIndex:8] isEqualToString:@"//cancel"]) {
            NSString * errorCode = [self getStringFromUrl:[url absoluteString] needle:@"error_code="];
            NSString * errorStr = [self getStringFromUrl:[url absoluteString] needle:@"error_msg="];
            if (errorCode) {
                NSDictionary * errorData = [NSDictionary dictionaryWithObject:errorStr forKey:@"error_msg"];
                NSError * error = [NSError errorWithDomain:@"facebookErrDomain"
                                                      code:[errorCode intValue]
                                                  userInfo:errorData];
                [self dismissWithError:error animated:YES];
            } else {
                [self dialogDidCancel:url];
            }
        } else {
            if (_frictionlessSettings.enabled) {
                [self dialogSuccessHandleFrictionlessResponses:url];
            }
            [self dialogDidSucceed:url];
        }
        return NO;
    } else if ([_loadingURL isEqual:url]) {
        return YES;
    } else if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        if ([_dialogDelegate respondsToSelector:@selector(dialog:shouldOpenURLInExternalBrowser:)]) {
            if (![_dialogDelegate dialog:self shouldOpenURLInExternalBrowser:url]) {
                return NO;
            }
        }
        
        [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    } else {
        return YES;
    }
}
#elif TARGET_OS_MAC && !TARGET_OS_IPHONE
-(NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource {
    return request;
}
-(void)webView:(WebView *)sender willPerformClientRedirectToURL:(NSURL *)URL delay:(NSTimeInterval)seconds fireDate:(NSDate *)date forFrame:(WebFrame *)frame {
    NSLog(@"Redirect URL: %@", URL);
}
#endif    
#if TARGET_OS_IPHONE
- (void)webViewDidFinishLoad:(FBWebView *)webView {
#elif TARGET_OS_MAC && !TARGET_OS_IPHONE
- (void)webView:(FBWebView *)webView resource:(id)identifier didFinishLoadingFromDataSource:(WebDataSource *)dataSource {
#endif
    if (_isViewInvisible) {
        // if our cache asks us to hide the view, then we do, but
        // in case of a stale cache, we will display the view in a moment
        // note that showing the view now would cause a visible white
        // flash in the common case where the cache is up to date
        [self performSelector:@selector(showWebView) withObject:nil afterDelay:.05]; 	
    } else {
        [self hideSpinner];	
    }
#if TARGET_OS_IPHONE
    [self updateWebOrientation];
#endif
}
        
#if TARGET_OS_IPHONE
- (void)webView:(FBWebView *)webView didFailLoadWithError:(NSError *)error {
#elif TARGET_OS_MAC && !TARGET_OS_IPHONE
- (void)webView:(WebView *)webView resource:(id)identifier didFailLoadingWithError:(NSError *)error fromDataSource:(WebDataSource *)dataSource {
#endif
    // 102 == WebKitErrorFrameLoadInterruptedByPolicyChange
    if (!([error.domain isEqualToString:@"WebKitErrorDomain"] && error.code == 102)) {
        [self dismissWithError:error animated:YES];
    }
}
#if TARGET_OS_IPHONE
///////////////////////////////////////////////////////////////////////////////////////////////////
// UIDeviceOrientationDidChangeNotification

- (void)deviceOrientationDidChange:(void*)object {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (!_showingKeyboard && [self shouldRotateToOrientation:orientation]) {
        [self updateWebOrientation];
        
        CGFloat duration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:duration];
        [self sizeToFitOrientation:YES];
        [UIView commitAnimations];
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// UIKeyboardNotifications

- (void)keyboardWillShow:(NSNotification*)notification {
    
    _showingKeyboard = YES;
    
    if (FBIsDeviceIPad()) {
        // On the iPad the screen is large enough that we don't need to
        // resize the dialog to accomodate the keyboard popping up
        return;
    }
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        _webView.frame = CGRectInset(_webView.frame,
                                     -(kPadding + kBorderWidth),
                                     -(kPadding + kBorderWidth));
    }
}

- (void)keyboardWillHide:(NSNotification*)notification {
    _showingKeyboard = NO;
    
    if (FBIsDeviceIPad()) {
        return;
    }
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        _webView.frame = CGRectInset(_webView.frame,
                                     kPadding + kBorderWidth,
                                     kPadding + kBorderWidth);
    }
}
#endif
//////////////////////////////////////////////////////////////////////////////////////////////////
// public

/**
 * Find a specific parameter from the url
 */
- (NSString *) getStringFromUrl: (NSString*) url needle:(NSString *) needle {
    NSString * str = nil;
    NSRange start = [url rangeOfString:needle];
    if (start.location != NSNotFound) {
        // confirm that the parameter is not a partial name match
        unichar c = '?';
        if (start.location != 0) {
            c = [url characterAtIndex:start.location - 1];
        }
        if (c == '?' || c == '&' || c == '#') {        
            NSRange end = [[url substringFromIndex:start.location+start.length] rangeOfString:@"&"];
            NSUInteger offset = start.location+start.length;
            str = end.location == NSNotFound ?
            [url substringFromIndex:offset] : 
            [url substringWithRange:NSMakeRange(offset, end.location)];
            str = [str stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
    }    
    return str;
}
            
- (id)initWithURL: (NSString *) serverURL
    params: (NSMutableDictionary *) params
    isViewInvisible: (BOOL)isViewInvisible
    frictionlessSettings: (FBFrictionlessRequestSettings*) frictionlessSettings
    delegate: (id <FBDialogDelegate>) delegate {

    self = [self init];
    _serverURL = [serverURL retain];
    _params = [params retain];    
    _dialogDelegate = delegate;
    _isViewInvisible = isViewInvisible;
    _frictionlessSettings = [frictionlessSettings retain];

    return self;
}

- (void)load {
    [self loadURL:_serverURL get:_params];
}

- (void)loadURL:(NSString*)url get:(NSDictionary*)getParams {
    NSLog(@"URL: %@", url);
    [_loadingURL release];
    _loadingURL = [[self generateURL:url params:getParams] retain];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:_loadingURL];
                
#if TARGET_OS_IPHONE
    [_webView loadRequest:request];
#elif TARGET_OS_MAC && !TARGET_OS_IPHONE
    [[_webView mainFrame] loadRequest:request];
#endif
}
            
- (void)show {
    [self load];
#if TARGET_OS_IPHONE
    [self sizeToFitOrientation:NO];
#endif
    CGFloat innerWidth = self.frame.size.width - (kBorderWidth+1)*2;
    [_closeButton sizeToFit];
    
    _closeButton.frame = CGRectMake(
                                    2,
                                    2,
                                    29,
                                    29);
    
    _webView.frame = CGRectMake(
                                kBorderWidth+1,
                                kBorderWidth+1,
                                innerWidth,
                                self.frame.size.height - (1 + kBorderWidth*2));
    
    if (!_isViewInvisible) {	
        [self showSpinner];	
        [self showWebView];
    }
}

- (void)dismissWithSuccess:(BOOL)success animated:(BOOL)animated {
    if (success) {
        if ([_dialogDelegate respondsToSelector:@selector(dialogDidComplete:)]) {
            [_dialogDelegate dialogDidComplete:self];
        }
    } else {
        if ([_dialogDelegate respondsToSelector:@selector(dialogDidNotComplete:)]) {
            [_dialogDelegate dialogDidNotComplete:self];
        }
    }
    
    [self dismiss:animated];
}

- (void)dismissWithError:(NSError*)error animated:(BOOL)animated {
    if ([_dialogDelegate respondsToSelector:@selector(dialog:didFailWithError:)]) {
        [_dialogDelegate dialog:self didFailWithError:error];
    }
    
    [self dismiss:animated];
}

- (void)dialogWillAppear {
}

- (void)dialogWillDisappear {
}

- (void)dialogDidSucceed:(NSURL *)url {
    
    if ([_dialogDelegate respondsToSelector:@selector(dialogCompleteWithUrl:)]) {
        [_dialogDelegate dialogCompleteWithUrl:url];
    }
    [self dismissWithSuccess:YES animated:YES];
}

- (void)dialogDidCancel:(NSURL *)url {
    if ([_dialogDelegate respondsToSelector:@selector(dialogDidNotCompleteWithUrl:)]) {
        [_dialogDelegate dialogDidNotCompleteWithUrl:url];
    }
    [self dismissWithSuccess:NO animated:YES];
}

@end