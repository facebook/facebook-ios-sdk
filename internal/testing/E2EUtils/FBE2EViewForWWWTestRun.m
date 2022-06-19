// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "FBE2EViewForWWWTestRun.h"

#if TARGET_OS_SIMULATOR

 #import <WebKit/WebKit.h>

 #import <E2EUtils/E2EUtils-Swift.h>

@implementation FBE2EViewForWWWTestRun
{
  CADisplayLink *_displayLink;
  FBE2EWebViewDumpHelper *_webViewDumpHelper;
}

+ (void)load
{
  NSDictionary *environment = NSProcessInfo.processInfo.environment;
  if (environment[@"IS_TESTING"]) {
    [self sharedInstance];
  }
}

+ (instancetype)sharedInstance
{
  static FBE2EViewForWWWTestRun *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [FBE2EViewForWWWTestRun new];
    sharedInstance.isAccessibilityElement = YES;
    [sharedInstance _ensureHelperOverlayOnTopOfWindow];
  });
  return sharedInstance;
}

- (void)_ensureHelperOverlayOnTopOfWindow
{
  _webViewDumpHelper = FBE2EWebViewDumpHelper.sharedInstance;
  _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(_bringOverlayToFrontIfNecessary)];
  [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)_bringOverlayToFrontIfNecessary
{
  UIWindow *const window = [UIApplication sharedApplication].delegate.window;

  UIViewController *vc = window.rootViewController.presentedViewController;
  if ([vc isKindOfClass:[UIAlertController class]]) {
    self.rootView = vc.view;
    self.rootView.accessibilityElements = @[self];
  } else {
    UIView *const rootView = window.subviews.lastObject;
    self.rootView = rootView;
    rootView.accessibilityElements = @[self];
  }
}

// We use the accessibility hint to mark the view that describes the view hierarchy.
- (NSString *)accessibilityHint
{
  return @"View Hierarchy";
}

// We use the accessivility label to describe the view hierarchy
- (NSString *)accessibilityLabel
{
  NSMutableString *output = [[NSMutableString alloc] initWithCapacity:1000];

  [output appendString:[NSString stringWithFormat:@"    TASK %@:\n", [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:(NSString *)kCFBundleIdentifierKey]]];
  [output appendString:@"    View Hierarchy:\n"];

  [self printViewHierarchy:self.rootView withDepth:3 withOutput:output];

  return output;
}

- (void)printViewHierarchy:(UIView *)view withDepth:(int)depth withOutput:(NSMutableString *)output
{
  if (view == nil) {
    return;
  }

  for (int i = 0; i < depth; i++) {
    [output appendString:@"  "];
  }

  [output appendString:NSStringFromClass([view class])];

  int x = [view frame].origin.x - [view superview].bounds.origin.x;
  int y = [view frame].origin.y - [view superview].bounds.origin.y;

  int width = [view bounds].size.width;
  int height = [view bounds].size.height;

  BOOL isVisible = NO;
  BOOL isNotHidden = !view.isHidden && view.alpha > 0 && view.window != nil;
  if (isNotHidden) {
    BOOL intersectsWindow = CGRectIntersectsRect([view.window convertRect:view.bounds fromView:view], view.window.bounds);
    isVisible = isNotHidden && intersectsWindow;
  }

  BOOL isEnabled = view.isUserInteractionEnabled;
  if ([view isKindOfClass:[UIControl class]]) {
    isEnabled = isEnabled && [(UIControl *)view isEnabled];
  }

  /*
   It's difficult to truly tell if a view is clickable:
   there could be a gesture recognizer, it can handle touches
   or it could be subclass of UIControl.
   Erring on the permissive side.
  */
  const BOOL isClickable = isVisible && isEnabled;
  const BOOL isFocused = view.isFirstResponder;

  NSString *const visibleLetter = isVisible ? @"V" : @".";
  NSString *const enabledLetter = isEnabled ? @"E" : @".";
  NSString *const clickableLetter = isClickable ? @"C" : @".";
  NSString *const focusedLetter = isFocused ? @"F" : @".";
  NSString *const statusString = [NSString stringWithFormat:@"%@.%@.%@... %@.", visibleLetter, enabledLetter, clickableLetter, focusedLetter];

  [output
   appendString:[NSString stringWithFormat:@"{00000000 %@ %d,%d-%d,%d", statusString, x, y, x + width, y + height]];

  NSString *const testID = view.accessibilityIdentifier;
  if ([testID length] > 0) {
    [output appendString:[NSString stringWithFormat:@" fb-e2e:id/%@", testID]];
  }

  NSInteger const tag = view.tag;
  if (tag > 0) {
    [output appendString:[NSString stringWithFormat:@" fb-e2e:tag/%ld", (long)tag]];
  }

  if ([view respondsToSelector:@selector(text)]) {
    NSString *const text = [view performSelector:@selector(text)];
    if (text.length > 0) {
      [output appendString:[NSString stringWithFormat:@" text=\"%@\"", text]];
    }
  }

  if ([view isKindOfClass:[WKWebView class]]) {
    WKWebView *webView = (WKWebView *)view;
    [_webViewDumpHelper extractHtmlFrom:webView];
    if ([_webViewDumpHelper hasContent]) {
      [output appendString:@"WebView HTML\n"];
      [output appendString:_webViewDumpHelper.content];
    }
  }

  [output appendString:@"}\n"];

  for (UIView *subView in [view subviews]) {
    [self printViewHierarchy:subView withDepth:depth + 1 withOutput:output];
  }
}

@end

#endif
