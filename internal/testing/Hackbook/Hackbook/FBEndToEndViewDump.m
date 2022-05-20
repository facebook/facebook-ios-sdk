// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "FBEndToEndViewDump.h"

static NSArray<UIView *> *subviews(UIView *view);

@implementation FBEndToEndViewDump

NSCharacterSet *notDigitsCharacterSet = nil;

// We use the accessibility hint to mark the view that describes the view hierarchy.
- (NSString *)accessibilityHint
{
  return @"View Hierarchy";
}

// We use the accessivility label to describe the view hierarchy
- (NSString *)accessibilityLabel
{
  NSMutableString *output = [[NSMutableString alloc] initWithCapacity:2000];

  [output appendString:[NSString stringWithFormat:@"    TASK %@:\n", [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:(NSString *)kCFBundleIdentifierKey]]];
  [output appendString:@"    View Hierarchy:\n"];

  for (UIWindow *window in self.rootViews) {
    [self printViewHierarchy:window withDepth:3 withOutput:output withParentFocused:NO];
    [output appendString:@"\n"];
  }

  return [output stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
}

- (void)printViewHierarchy:(UIView *)view withDepth:(int)depth withOutput:(NSMutableString *)output withParentFocused:(BOOL)parentFocused
{
  if (view == nil) {
    return;
  }

  if (view.superview == nil) {
    for (UIView *subView in subviews(view)) {
      [self printViewHierarchy:subView withDepth:depth withOutput:output withParentFocused:parentFocused];
    }
    return;
  }

  CGFloat x = [view frame].origin.x - [view superview].bounds.origin.x;
  CGFloat y = [view frame].origin.y - [view superview].bounds.origin.y;

  CGFloat width = CGRectGetWidth(view.bounds);
  CGFloat height = CGRectGetHeight(view.bounds);

  BOOL isVisible = NO;
  BOOL isNotHidden = !view.isHidden && view.alpha > 0 && view.window != nil;
  isNotHidden = isNotHidden && view.frame.size.width > 0 && view.frame.size.height > 0;
  if (isNotHidden) {
    BOOL intersectsWindow = CGRectIntersectsRect([view.window convertRect:view.bounds fromView:view], view.window.bounds);
    isVisible = isNotHidden && intersectsWindow;
  }

  NSString *label = view.accessibilityLabel;

  // accessibility elements may not be marked as user interaction but we
  // need them to be marked as enabled for tests
  BOOL forceEnableClicking = false;
  BOOL isEnabled = [label length] > 0 || view.isUserInteractionEnabled;
  // We need to exclude certain views that have isEnabled property but it's not related to clicking
  if (![view isKindOfClass:[UILabel class]] && ![view isKindOfClass:[UIImageView class]] && [view respondsToSelector:@selector(isEnabled)]) {
    isEnabled = isEnabled && (BOOL)[(id)view isEnabled];
    if (!isEnabled) {
      // This is an ugly hack due to how view hierarchy parsing works at jest level
      // enabled = !clickable, so if we are really sure to disable the element
      // we need to also force clicking enabled
      forceEnableClicking = true;
    }
  }

  /*
   It's difficult to truly tell if a view is clickable:
   there could be a gesture recognizer, it can handle touches
   or it could be subclass of UIControl.
   Erring on the permissive side.
  */
  const BOOL isClickable = isVisible && (isEnabled || forceEnableClicking);
  const BOOL isFocused = parentFocused || view.isFirstResponder;

  BOOL isHorizontallyScrollable = NO;
  BOOL isVerticallyScrollable = NO;

  if ([view isKindOfClass:[UIScrollView class]] && [(UIScrollView *)view isScrollEnabled]) {
    if ([(UIScrollView *)view contentSize].width > view.frame.size.width) {
      isHorizontallyScrollable = YES;
    }
    if ([(UIScrollView *)view contentSize].height > view.frame.size.height) {
      isVerticallyScrollable = YES;
    }
  }

  // Prevent invisibile cells from polluting the hierarchy
  if (!isVisible && ([view isKindOfClass:[UITableViewCell class]] || [view isKindOfClass:[UICollectionViewCell class]])) {
    return;
  }

  for (int i = 0; i < depth; i++) {
    [output appendString:@"  "];
  }

  [output appendString:NSStringFromClass([view class])];

  NSString *const visibleLetter = isVisible ? @"V" : @".";
  NSString *const enabledLetter = isEnabled ? @"E" : @".";
  NSString *const clickableLetter = isClickable ? @"C" : @".";
  NSString *const horScrollLetter = isHorizontallyScrollable ? @"H" : @".";
  NSString *const verScrollLetter = isVerticallyScrollable ? @"V" : @".";
  NSString *const focusedLetter = isFocused ? @"F" : @".";
  NSString *const statusString = [NSString stringWithFormat:@"%@.%@.%@%@%@. %@.", visibleLetter, enabledLetter, horScrollLetter, verScrollLetter, clickableLetter, focusedLetter];

  [output
   appendString:[NSString stringWithFormat:@"{00000000 %@ %.2f,%.2f-%.2f,%.2f", statusString, x, y, x + width, y + height]];

  NSString *const testID = view.accessibilityIdentifier;
  if ([testID length] > 0) {
    if (notDigitsCharacterSet == nil) {
      notDigitsCharacterSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    }
    if ([testID rangeOfCharacterFromSet:notDigitsCharacterSet].location != NSNotFound) {
      // don't add test ids that are only numbers, created by accessibility and useless for testing
      [output appendString:[NSString stringWithFormat:@" fb-e2e:id/%@", testID]];
    }
  }

  BOOL didAppendText = NO;
  // Including UIFieldEditor will lead to the text duplication
  // Since both UITextField and UIFieldEditor implement it
  if ([view respondsToSelector:@selector(text)]
      && ![NSStringFromClass([view class]) isEqualToString:@"UIFieldEditor"]) {
    NSString *const text = [view performSelector:@selector(text)];
    if (([text isKindOfClass:NSString.class]) && text.length > 0) {
      NSString *stringToAppend = [NSString stringWithFormat:@" text=\"%@\"", text];
      stringToAppend = [stringToAppend stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
      [output appendString:stringToAppend];
      didAppendText = YES;
    }
  }
  if (!didAppendText && label.length > 0) {
    [output appendString:[NSString stringWithFormat:@" text=\"%@\"", label]];
  }
  [output appendString:@"}\n"];

  // Treat _UIAlertControllerActionView as a terminal node to prevent the internal
  // label to be picked up instead of an action view itself
#if PROFILE || !__UNSAFE__FB_IS_EXTERNAL_BUILD__
  if ([NSStringFromClass([view class]) isEqualToString:@"_UIAlertControllerActionView"]) {
    return;
  }
#endif

  for (UIView *subView in subviews(view)) {
    [self printViewHierarchy:subView withDepth:depth + 1 withOutput:output withParentFocused:isFocused];
  }
}

@end

NSArray<UIView *> *subviews(UIView *view)
{
  // Subviews should be enumerated bottom to top because the front facing views are on the bottom
  // However, collection and table views should list their cells from the top cell to the bottom cell
  // Therefore we need to preserve the order in this case
  NSArray<UIView *> *subviews;
  if ([view isKindOfClass:[UITableView class]] || [view isKindOfClass:[UICollectionView class]]) {
    subviews = view.subviews;
  } else {
    subviews = [[view.subviews reverseObjectEnumerator] allObjects];
  }

  return subviews;
}
