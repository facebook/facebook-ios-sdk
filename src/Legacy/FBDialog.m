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

#import "FBDialog.h"

#import "FBDialogClosePNG.h"
#import "FBFrictionlessRequestSettings.h"
#import "FBSettings+Internal.h"
#import "FBUtility.h"
#import "Facebook.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
// global

static CGFloat kBorderGray[4] = {0.3, 0.3, 0.3, 0.8};
static CGFloat kBorderBlack[4] = {0.3, 0.3, 0.3, 1};

static CGFloat kTransitionDuration = 0.3;

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

@implementation FBDialog {
    BOOL _everShown;
}

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

- (void)drawRect:(CGRect)rect fill:(const CGFloat *)fillColors radius:(CGFloat)radius {
    CGContextRef context = UIGraphicsGetCurrentContext();
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

- (void)strokeLines:(CGRect)rect stroke:(const CGFloat *)strokeColor {
    CGContextRef context = UIGraphicsGetCurrentContext();
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
        return CGAffineTransformMakeRotation(M_PI * 1.5);
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

- (NSURL *)generateURL:(NSString *)baseURL params:(NSDictionary *)params {
    if (params) {
        NSMutableArray *pairs = [NSMutableArray array];
        for (NSString *key in params.keyEnumerator) {
            NSString *value = [params objectForKey:key];
            NSString *escaped_value = [FBUtility stringByURLEncodingString:value];
            [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, escaped_value]];
        }

        NSString *query = [pairs componentsJoinedByString:@"&"];
        NSString *url = [NSString stringWithFormat:@"%@?%@", baseURL, query];
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
    [self removeFromSuperview];
    [_modalBackgroundView removeFromSuperview];

    // this method call could cause a self-cleanup, and needs to really happen "last"
    // If the dialog has been closed, then we need to cancel the order to open it.
    // This happens in the case of a frictionless request, see webViewDidFinishLoad for details
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(showWebView)
                                               object:nil];
}

- (void)dismiss:(BOOL)animated {
    [self dialogWillDisappear];

    [_loadingURL release];
    _loadingURL = nil;

    if (animated && _everShown) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:kTransitionDuration];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(postDismissCleanup)];
        self.alpha = 0;
        [UIView commitAnimations];
    } else {
        [self postDismissCleanup];
    }
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
        id recipients = [FBUtility simpleJSONDecode:recipientJson];

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

- (instancetype)init {
    if ((self = [super initWithFrame:CGRectZero])) {
        _delegate = nil;
        _loadingURL = nil;
        _showingKeyboard = NO;
        _everShown = NO;

        self.backgroundColor = [UIColor clearColor];
        self.autoresizesSubviews = YES;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.contentMode = UIViewContentModeRedraw;

        _webView = [[UIWebView alloc] initWithFrame:CGRectMake(kPadding, kPadding, 480, 480)];
        _webView.delegate = self;
        _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_webView];

        UIImage *closeImage = [FBDialogClosePNG image];

        UIColor *color = [UIColor colorWithRed:167.0/255 green:184.0/255 blue:216.0/255 alpha:1];
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
        [self addSubview:_closeButton];

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
        [self addSubview:_spinner];
        _modalBackgroundView = [[UIView alloc] init];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _webView.delegate = nil;
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
                                rect.size.width - kBorderWidth * 2, _webView.frame.size.height+1);

    [self strokeLines:webRect stroke:kBorderBlack];
}

// Display the dialog's WebView with a slick pop-up animation
- (void)showWebView {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (window.windowLevel != UIWindowLevelNormal) {
        for(window in [UIApplication sharedApplication].windows) {
            if (window.windowLevel == UIWindowLevelNormal)
                break;
        }
    }
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

    _everShown = YES;
    [self dialogWillAppear];
    [self addObservers];
}

// Show a spinner during the loading time for the dialog. This is designed to show
// on top of the webview but before the contents have loaded.
- (void)showSpinner {
    [_spinner sizeToFit];
    [_spinner startAnimating];
    _spinner.center = _webView.center;
}

- (void)hideSpinner {
    [_spinner stopAnimating];
    _spinner.hidden = YES;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = request.URL;

    if ([url.scheme isEqualToString:@"fbconnect"]) {
        if ([[url.resourceSpecifier substringToIndex:8] isEqualToString:@"//cancel"]) {
            NSString *errorCode = [self getStringFromUrl:[url absoluteString] needle:@"error_code="];
            NSString *errorStr = [self getStringFromUrl:[url absoluteString] needle:@"error_msg="];
            if (errorCode) {
                NSDictionary *errorData = [NSDictionary dictionaryWithObject:errorStr forKey:@"error_msg"];
                NSError *error = [NSError errorWithDomain:@"facebookErrDomain"
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
        if ([_delegate respondsToSelector:@selector(dialog:shouldOpenURLInExternalBrowser:)]) {
            if (![_delegate dialog:self shouldOpenURLInExternalBrowser:url]) {
                return NO;
            }
        }

        [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    } else {
        return YES;
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if (_isViewInvisible) {
        // if our cache asks us to hide the view, then we do, but
        // in case of a stale cache, we will display the view in a moment
        // note that showing the view now would cause a visible white
        // flash in the common case where the cache is up to date
        [self performSelector:@selector(showWebView) withObject:nil afterDelay:.05];
    } else {
        [self hideSpinner];
    }
    [self updateWebOrientation];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    // 102 == WebKitErrorFrameLoadInterruptedByPolicyChange
    // NSURLErrorCancelled == "Operation could not be completed", note NSURLErrorCancelled occurs when
    // the user clicks away before the page has completely loaded, if we find cases where we want this
    // to result in dialog failure (usually this just means quick-user), then we should add something
    // more robust here to account for differences in application needs
    if (!(([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled) ||
          ([error.domain isEqualToString:@"WebKitErrorDomain"] && error.code == 102))) {
        [self dismissWithError:error animated:YES];
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// UIDeviceOrientationDidChangeNotification

- (void)deviceOrientationDidChange:(void *)object {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if ([self shouldRotateToOrientation:orientation]) {
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

- (void)keyboardWillShow:(NSNotification *)notification {

    _showingKeyboard = YES;

    if (FBIsDeviceIPad()) {
        // On the iPad the screen is large enough that we don't need to
        // resize the dialog to accomodate the keyboard popping up
        return;
    }

    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        _webView.frame = CGRectInset(_webView.frame,
                                     - (kPadding + kBorderWidth),
                                     - (kPadding + kBorderWidth));
    }
}

- (void)keyboardWillHide:(NSNotification *)notification {
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

//////////////////////////////////////////////////////////////////////////////////////////////////
// public

/**
 * Find a specific parameter from the url
 */
- (NSString *)getStringFromUrl:(NSString *)url needle:(NSString *)needle {
    NSString *str = nil;
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

- (id)      initWithURL:(NSString *)serverURL
                 params:(NSMutableDictionary *)params
        isViewInvisible:(BOOL)isViewInvisible
   frictionlessSettings:(FBFrictionlessRequestSettings *)frictionlessSettings
               delegate:(id<FBDialogDelegate>)delegate {

    self = [self init];
    _serverURL = [serverURL retain];
    _params = [params retain];
    _delegate = delegate;
    _isViewInvisible = isViewInvisible;
    _frictionlessSettings = [frictionlessSettings retain];

    return self;
}

- (void)load {
    [self loadURL:_serverURL get:_params];
}

- (void)loadURL:(NSString *)url get:(NSDictionary *)getParams {

    [_loadingURL release];
    _loadingURL = [[self generateURL:url params:getParams] retain];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_loadingURL];

    [_webView loadRequest:request];
}

- (void)show {
    if ([FBSettings restrictedTreatment] == FBRestrictedTreatmentYES) {
        if ([_delegate respondsToSelector:@selector(dialog:didFailWithError:)]) {
            NSError *error = [NSError errorWithDomain:FacebookSDKDomain
                                                 code:FBErrorOperationDisallowedForRestrictedTreatment
                                             userInfo:nil];
            [_delegate dialog:self didFailWithError:error];
        }
        return;
    }
    [self load];
    [self sizeToFitOrientation:NO];

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
                                self.frame.size.height - (1 + kBorderWidth * 2));

    if (!_isViewInvisible) {
        [self showSpinner];
        [self showWebView];
    }
}

- (void)dismissWithSuccess:(BOOL)success animated:(BOOL)animated {
    // retain self for the life of this method, in case we are released by a client
    id me = [self retain];

    @try {
        if (success) {
            if ([_delegate respondsToSelector:@selector(dialogDidComplete:)]) {
                [_delegate dialogDidComplete:self];
            }
        } else {
            if ([_delegate respondsToSelector:@selector(dialogDidNotComplete:)]) {
                [_delegate dialogDidNotComplete:self];
            }
        }

        [self dismiss:animated];
    } @finally {
        [me release];
    }
}

- (void)dismissWithError:(NSError *)error animated:(BOOL)animated {
    // retain self for the life of this method, in case we are released by a client
    id me = [self retain];

    @try {
        if ([_delegate respondsToSelector:@selector(dialog:didFailWithError:)]) {
            [_delegate dialog:self didFailWithError:error];
        }

        [self dismiss:animated];
    } @finally {
        [me release];
    }
}

- (void)dialogWillAppear {
}

- (void)dialogWillDisappear {
}

- (void)dialogDidSucceed:(NSURL *)url {
    // retain self for the life of this method, in case we are released by a client
    id me = [self retain];

    @try {
        // call into client code
        if ([_delegate respondsToSelector:@selector(dialogCompleteWithUrl:)]) {
            [_delegate dialogCompleteWithUrl:url];
        }

        [self dismissWithSuccess:YES animated:YES];
    } @finally {
        [me release];
    }
}

- (void)dialogDidCancel:(NSURL *)url {
    // retain self for the life of this method, in case we are released by a client
    id me = [self retain];

    @try {
        if ([_delegate respondsToSelector:@selector(dialogDidNotCompleteWithUrl:)]) {
            [_delegate dialogDidNotCompleteWithUrl:url];
        }
        [self dismissWithSuccess:NO animated:YES];
    } @finally {
        [me release];
    }
}

@end
