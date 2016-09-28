// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "Theme.h"

#import "ReverbTheme.h"

const NSUInteger ThemeTypeCount = 9;

@interface Theme ()

@property (nonatomic, assign, readwrite) ThemeType themeType;

@end

@implementation Theme

#pragma mark - Class Methods

+ (BOOL)isReverbTheme:(ThemeType)themeType
{
  switch (themeType) {
    case ThemeTypeDefault:
    case ThemeTypeSalmon:
    case ThemeTypeYellow:
    case ThemeTypeRed:
    case ThemeTypeDog:
    case ThemeTypeBicycle:
      return NO;
    case ThemeTypeReverbA:
    case ThemeTypeReverbB:
    case ThemeTypeReverbC:
      return YES;
  }
}

+ (NSString *)labelForThemeType:(ThemeType)themeType
{
  switch (themeType) {
    case ThemeTypeDefault:
      return @"Default";
    case ThemeTypeSalmon:
      return @"Salmon";
    case ThemeTypeYellow:
      return @"Yellow";
    case ThemeTypeRed:
      return @"Red";
    case ThemeTypeDog:
      return @"Dog";
    case ThemeTypeBicycle:
      return @"Bicycle";
    case ThemeTypeReverbA:
      return @"Reverb A";
    case ThemeTypeReverbB:
      return @"Reverb B";
    case ThemeTypeReverbC:
      return @"Reverb C";
  }
}

+ (instancetype)themeWithType:(ThemeType)themeType
{
  Theme *theme;
  switch (themeType) {
    case ThemeTypeDefault:
      theme = [self defaultTheme];
      break;
    case ThemeTypeSalmon:
      theme = [self _salmonTheme];
      break;
    case ThemeTypeYellow:
      theme = [self _yellowTheme];
      break;
    case ThemeTypeRed:
      theme = [self _redTheme];
      break;
    case ThemeTypeDog:
      theme = [self _dogTheme];
      break;
    case ThemeTypeBicycle:
      theme = [self _bicycleTheme];
      break;
    case ThemeTypeReverbA:
      theme = [self _reverbATheme];
      break;
    case ThemeTypeReverbB:
      theme = [self _reverbBTheme];
      break;
    case ThemeTypeReverbC:
      theme = [self _reverbCTheme];
      break;
  }
  theme.themeType = themeType;
  return theme;
}

#pragma mark - Helper Class Methods

+ (instancetype)_salmonTheme
{
  Theme *theme = [self themeWithPrimaryColor:[UIColor whiteColor]
                            primaryTextColor:[self _colorWithHex:0xff565a5c]
                              secondaryColor:[self _colorWithHex:0xccffe5e5]
                          secondaryTextColor:[self _colorWithHex:0xff565a5c]
                              statusBarStyle:UIStatusBarStyleDefault];
  theme.buttonBackgroundColor = [self _colorWithHex:0xffff5a5f];
  theme.buttonTextColor = [UIColor whiteColor];
  theme.iconColor = [self _colorWithHex:0xffff5a5f];
  theme.inputTextColor = [self _colorWithHex:0xff44566b];
  return theme;
}

+ (instancetype)_yellowTheme
{
  Theme *theme = [self outlineThemeWithPrimaryColor:[self _colorWithHex:0xfff4bf56]
                                   primaryTextColor:[UIColor whiteColor]
                                 secondaryTextColor:[self _colorWithHex:0xff44566b]
                                     statusBarStyle:UIStatusBarStyleDefault];
  theme.buttonTextColor = [UIColor whiteColor];
  return theme;
}

+ (instancetype)_redTheme
{
  Theme *theme = [self outlineThemeWithPrimaryColor:[self _colorWithHex:0xff333333]
                                   primaryTextColor:[UIColor whiteColor]
                                 secondaryTextColor:[self _colorWithHex:0xff151515]
                                     statusBarStyle:UIStatusBarStyleLightContent];
  theme.backgroundColor = [self _colorWithHex:0xfff7f7f7];
  theme.buttonBackgroundColor = [self _colorWithHex:0xffe02727];
  theme.buttonBorderColor = [self _colorWithHex:0xffe02727];
  theme.inputBorderColor = [self _colorWithHex:0xffe02727];
  return theme;
}

+ (instancetype)_dogTheme
{
  Theme *theme = [self themeWithPrimaryColor:[UIColor whiteColor]
                            primaryTextColor:[self _colorWithHex:0xff44566b]
                              secondaryColor:[self _colorWithHex:0xccffffff]
                          secondaryTextColor:[UIColor whiteColor]
                              statusBarStyle:UIStatusBarStyleDefault];
  theme.backgroundColor = [self _colorWithHex:0x994e7e24];
  theme.backgroundImage = [UIImage imageNamed:@"dog"];
  theme.inputTextColor = [self _colorWithHex:0xff44566b];
  return theme;
}

+ (instancetype)_bicycleTheme
{
  Theme *theme = [self outlineThemeWithPrimaryColor:[self _colorWithHex:0xffff5a5f]
                                   primaryTextColor:[UIColor whiteColor]
                                 secondaryTextColor:[UIColor whiteColor]
                                     statusBarStyle:UIStatusBarStyleLightContent];
  theme.backgroundImage = [UIImage imageNamed:@"bicycle"];
  theme.backgroundColor = [self _colorWithHex:0x66000000];
  theme.buttonDisabledBackgroundColor = [UIColor clearColor];
  theme.buttonDisabledBorderColor = [UIColor whiteColor];
  theme.buttonDisabledTextColor = [UIColor whiteColor];
  theme.inputBackgroundColor = [self _colorWithHex:0x00000000];
  theme.inputBorderColor = [UIColor whiteColor];
  return theme;
}

+ (instancetype)_reverbATheme
{
  Theme *theme = [self _reverbTheme];
  theme.headerBackgroundColor = [UIColor whiteColor];
  theme.headerTextColor = theme.iconColor;
  return theme;
}

+ (instancetype)_reverbBTheme
{
  Theme *theme = [self _reverbTheme];
  theme.headerBackgroundColor = [self _colorWithHex:0xff7c7aa0];
  theme.headerTextColor = [UIColor whiteColor];
  theme.statusBarStyle = UIStatusBarStyleLightContent;

  if ([theme isKindOfClass:[ReverbTheme class]]) {
    ReverbTheme *reverbTheme = (ReverbTheme *)theme;
    reverbTheme.appIconImage = [UIImage imageNamed:@"reverb-app-icon"];
    reverbTheme.backArrowImage = [UIImage imageNamed:@"reverb-back-arrow-white"];
    reverbTheme.progressMode = ReverbThemeProgressModeDots;
    reverbTheme.textUppercase = YES;
  }

  return theme;
}

+ (instancetype)_reverbCTheme
{
  Theme *theme = [self _reverbTheme];
  theme.headerBackgroundColor = [UIColor whiteColor];
  theme.headerTextColor = theme.iconColor;

  if ([theme isKindOfClass:[ReverbTheme class]]) {
    ReverbTheme *reverbTheme = (ReverbTheme *)theme;
    reverbTheme.appIconImage = [UIImage imageNamed:@"reverb-app-icon"];
    reverbTheme.progressMode = ReverbThemeProgressModeDots;
    reverbTheme.textUppercase = YES;
  }

  return theme;
}

+ (UIColor *)_colorWithHex:(NSUInteger)hex
{
  CGFloat alpha = ((CGFloat)((hex & 0xff000000) >> 24)) / 255.0;
  CGFloat red = ((CGFloat)((hex & 0x00ff0000) >> 16)) / 255.0;
  CGFloat green = ((CGFloat)((hex & 0x0000ff00) >> 8)) / 255.0;
  CGFloat blue = ((CGFloat)((hex & 0x000000ff) >> 0)) / 255.0;
  return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

+ (Theme *)_reverbTheme
{
  UIColor *reverbDark = [self _colorWithHex:0xff262261];
  UIColor *reverbLight = [self _colorWithHex:0xffe9e8ef];
  UIColor *reverbText = [self _colorWithHex:0xff1d2129];
  Theme *theme = [self themeWithPrimaryColor:reverbLight
                            primaryTextColor:reverbText
                              secondaryColor:reverbLight
                          secondaryTextColor:reverbText
                              statusBarStyle:UIStatusBarStyleDefault];
  theme.buttonBackgroundColor = reverbDark;
  theme.buttonBorderColor = reverbDark;
  theme.buttonTextColor = [UIColor whiteColor];
  theme.contentBodyLayoutWeight = 1;
  theme.contentBottomLayoutWeight = 1;
  theme.contentFooterLayoutWeight = 0;
  theme.contentHeaderLayoutWeight = 1;
  theme.contentMarginLeft = 25.0;
  theme.contentMarginRight = 25.0;
  theme.contentMaxWidth = 360.0;
  theme.contentMinHeight = 340.0;
  theme.contentTextLayoutWeight = 1;
  theme.contentTopLayoutWeight = 1;
  theme.iconColor = reverbDark;

  if ([theme isKindOfClass:[ReverbTheme class]]) {
    ReverbTheme *reverbTheme = (ReverbTheme *)theme;
    reverbTheme.backArrowImage = [UIImage imageNamed:@"reverb-back-arrow-purple"];
    reverbTheme.progressActiveColor = reverbDark;
    reverbTheme.progressInactiveColor = reverbLight;
    reverbTheme.progressMode = ReverbThemeProgressModeBar;
  }

  return theme;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  Theme *copy = [super copyWithZone:zone];
  copy->_themeType = _themeType;
  return copy;
}

#pragma mark - Equality

- (NSUInteger)hash
{
  return [super hash] ^ _themeType;
}

- (BOOL)isEqualToTheme:(AKFTheme *)theme
{
  Theme *sampleTheme = (Theme *)theme;
  return ([super isEqualToTheme:theme] &&
          [theme isKindOfClass:[Theme class]] &&
          (_themeType == sampleTheme->_themeType));
}

@end
