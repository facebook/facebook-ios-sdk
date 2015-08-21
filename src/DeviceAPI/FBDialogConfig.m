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

#import "FBDialogConfig.h"

#import "FBSettings.h"
#import "FBUtility.h"

NSString *const FBDialogConfigurationNameDefault = @"default";
NSString *const FBDialogConfigurationNameLogin = @"login";
NSString *const FBDialogConfigurationNameSharing = @"sharing";
NSString *const FBDialogConfigurationNameLike = @"like";
NSString *const FBDialogConfigurationNameMessage = @"message";
NSString *const FBDialogConfigurationNameShare = @"share";

NSString *const FBDialogConfigurationFeatureUseNativeFlow = @"use_native_flow";
NSString *const FBDialogConfigurationFeatureUseSafariViewController = @"use_safari_vc";

@interface FBDialogConfig ()
@property (nonatomic, copy, readwrite) NSString *name;
@property (nonatomic, copy, readwrite) NSURL *URL;
@property (nonatomic, copy, readwrite) NSArray *versions;
@end

@implementation FBDialogConfig

#pragma mark - Class Methods

static NSDictionary *g_dialogFlows = nil;
static NSString *const FBDialogFlowsKey = @"com.facebook.sdk:dialogFlows%@";

+ (void)initialize
{
    if (self == [FBDialogConfig class]) {
        [self updateDialogFlows];
    }
}

+ (void)updateDialogFlows
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        void(^block)() = ^{
            // while this map is stored globally in FBFetchedAppSettings, we need to serialize it to disk so that it is
            // persistent, so we will be storing it in another global here, and then replacing it once
            // FBFetchedAppSettings has been loaded so that we always have something to read from once it has been
            // loaded at least once.
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSString *appID = [FBSettings defaultAppID];
            NSString *dialogFlowsKey = [NSString stringWithFormat:FBDialogFlowsKey, appID];
            NSData *flowsData = [defaults objectForKey:dialogFlowsKey];
            if ([flowsData isKindOfClass:[NSData class]]) {
                NSDictionary *dialogFlows = [NSKeyedUnarchiver unarchiveObjectWithData:flowsData];
                if ([dialogFlows isKindOfClass:[NSDictionary class]]) {
                    g_dialogFlows = [dialogFlows copy];
                }
            }
            if (g_dialogFlows == nil) {
                BOOL useNative = ![FBUtility isRunningOnOrAfter:FBIOSVersion_9_0];
                g_dialogFlows = [@{
                                   FBDialogConfigurationNameDefault: @{
                                           FBDialogConfigurationFeatureUseNativeFlow: @(useNative),
                                           FBDialogConfigurationFeatureUseSafariViewController: @YES,
                                           },
                                   } copy];
            }
            [FBUtility fetchAppSettings:appID callback:^(FBFetchedAppSettings *settings, NSError *error) {
                NSDictionary *dialogFlows = settings.dialogFlows;
                if (error || !dialogFlows) {
                    return;
                }
                [g_dialogFlows autorelease];
                g_dialogFlows = [dialogFlows copy];
                NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dialogFlows];
                [defaults setObject:data forKey:dialogFlowsKey];
            }];
        };
        if ([NSThread isMainThread]) {
            block();
        } else {
            dispatch_async(dispatch_get_main_queue(), block);
        }
    });
}

+ (BOOL)useNativeDialogForDialogName:(NSString *)dialogName
{
    return [self _useFeatureWithKey:FBDialogConfigurationFeatureUseNativeFlow dialogName:dialogName];
}

+ (BOOL)useSafariViewControllerForDialogName:(NSString *)dialogName
{
    return [self _useFeatureWithKey:FBDialogConfigurationFeatureUseSafariViewController dialogName:dialogName];
}

+ (BOOL)_useFeatureWithKey:(NSString *)key dialogName:(NSString *)dialogName
{
    if ([dialogName isEqualToString:FBDialogConfigurationNameLogin]) {
        return [(NSNumber *)(g_dialogFlows[dialogName][key] ?:
                             g_dialogFlows[FBDialogConfigurationNameDefault][key]) boolValue];
    } else {
        return [(NSNumber *)(g_dialogFlows[dialogName][key] ?:
                             g_dialogFlows[FBDialogConfigurationNameSharing][key] ?:
                             g_dialogFlows[FBDialogConfigurationNameDefault][key]) boolValue];
    }
}

+ (instancetype)dialogConfigWithDictionary:(NSDictionary *)dictionary
{
    FBDialogConfig *config = [[[FBDialogConfig alloc] init] autorelease];
    id temp;
    temp = dictionary[@"name"];
    if ([temp isKindOfClass:[NSString class]]) {
        config.name = (NSString *)temp;
    } else {
        return nil;
    }
    temp = dictionary[@"url"];
    if ([temp isKindOfClass:[NSString class]]) {
        config.URL = [NSURL URLWithString:(NSString *)temp];
    }
    temp = dictionary[@"versions"];
    if ([temp isKindOfClass:[NSArray class]]) {
        config.versions = (NSArray *)temp;
    }
    return config;
}

#pragma mark - Object Lifecycle

- (void)dealloc
{
    [_name release];
    [_URL release];
    [_versions release];
    [super dealloc];
}

#pragma mark - NSCoding

static NSString *const FBDialogConfigNameKey = @"name";
static NSString *const FBDialogConfigURLKey = @"url";
static NSString *const FBDialogConfigVersionKey = @"version";
static NSString *const FBDialogConfigVersionsKey = @"versions";
static NSInteger const FBDialogConfigCodingVersion = 1;

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init])) {
        if ([decoder decodeIntegerForKey:FBDialogConfigVersionKey] != FBDialogConfigCodingVersion) {
            [self release];
            return nil;
        }

        _name = [[decoder decodeObjectOfClass:[NSString class] forKey:FBDialogConfigNameKey] retain];
        _URL = [[decoder decodeObjectOfClass:[NSURL class] forKey:FBDialogConfigURLKey] retain];
        _versions = [[decoder decodeObjectOfClass:[NSArray class] forKey:FBDialogConfigVersionsKey] retain];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeInteger:FBDialogConfigCodingVersion forKey:FBDialogConfigVersionKey];
    [coder encodeObject:_name forKey:FBDialogConfigNameKey];
    [coder encodeObject:_URL forKey:FBDialogConfigURLKey];
    [coder encodeObject:_versions forKey:FBDialogConfigVersionsKey];
}

@end
