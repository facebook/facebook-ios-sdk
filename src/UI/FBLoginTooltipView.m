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

#import "FBLoginTooltipView.h"

#import "FBSettings.h"
#import "FBUtility.h"


@interface FBLoginTooltipView ()
@end

@implementation FBLoginTooltipView

- (instancetype)init
{
    NSString *tooltipMessage =
    [FBUtility localizedStringForKey:@"FBLV:LogInButtonTooltipMessage"
                         withDefault:@"New! You're in control - choose what info you want to share with apps."];
    return [super initWithTagline:nil message:tooltipMessage colorStyle:FBTooltipColorStyleFriendlyBlue];
}

- (void)presentInView:(UIView *)view withArrowPosition:(CGPoint)arrowPosition direction:(FBTooltipViewArrowDirection)arrowDirection {
    if (self.forceDisplay) {
        [super presentInView:view withArrowPosition:arrowPosition direction:arrowDirection];
    } else {
        [FBUtility fetchAppSettings:[FBSettings defaultAppID] callback:^(FBFetchedAppSettings *settings, NSError *error) {
            self.message = settings.loginTooltipContent;
            BOOL shouldDisplay = settings.enableLoginTooltip && ![FBSettings isPlatformCompatibilityEnabled];
            if ([self.delegate respondsToSelector:@selector(loginTooltipView:shouldAppear:)]) {
                shouldDisplay = [self.delegate loginTooltipView:self shouldAppear:shouldDisplay];
            }
            if (shouldDisplay) {
                [super presentInView:view withArrowPosition:arrowPosition direction:arrowDirection];
                if ([self.delegate respondsToSelector:@selector(loginTooltipViewWillAppear:)]) {
                    [self.delegate loginTooltipViewWillAppear:self];
                }
            } else {
                if ([self.delegate respondsToSelector:@selector(loginTooltipViewWillNotAppear:)]) {
                    [self.delegate loginTooltipViewWillNotAppear:self];
                }
            }
        }];
    }
}
@end
