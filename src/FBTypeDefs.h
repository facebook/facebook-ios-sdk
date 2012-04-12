//
//  FBTypeDefs.h
//  facebook-osx-sdk
//
//  Created by David Bitton on 3/11/12.
//  Copyright (c) 2012 Code No Evil LLC. All rights reserved.
//
#include <TargetConditionals.h>
#if TARGET_OS_IPHONE
typedef UIApplication FBApplication;
typedef UIWindow FBWindow;
typedef UIImage FBImage;
typedef UIView FBView;
typedef UIWebView FBWebView;
typedef UIColor FBColor;

extern int const FBFlexibleWidth;
extern int const FBFlexibleHeight;
#elif TARGET_OS_MAC && !TARGET_OS_IPHONE
#import <WebKit/WebKit.h>

typedef NSApplication FBApplication;
typedef NSWindow FBWindow;
typedef NSImage FBImage;
typedef NSView FBView;
typedef WebView FBWebView;
typedef NSColor FBColor;

extern int const FBFlexibleWidth;
extern int const FBFlexibleHeight;
#endif
