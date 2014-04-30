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

#import "FBAudioResourceLoader.h"

#import "FBDynamicFrameworkLoader.h"
#import "FBLogger.h"
#import "FBSettings.h"

@implementation FBAudioResourceLoader
{
    NSFileManager *_fileManager;
    NSURL *_fileURL;
    SystemSoundID _systemSoundID;
}

#pragma mark - Class Methods

+ (instancetype)sharedLoader
{
    static NSMutableDictionary *_loaderCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _loaderCache = [[NSMutableDictionary alloc] init];
    });

    NSString *name = [self name];
    FBAudioResourceLoader *loader;
    @synchronized(_loaderCache) {
        loader = _loaderCache[name];
        if (!loader) {
            loader = [[[self alloc] init] autorelease];
            NSError *error = nil;
            if ([loader loadSound:&error]) {
                _loaderCache[name] = loader;
            } else {
                [FBLogger singleShotLogEntry:FBLoggingBehaviorDeveloperErrors
                                formatString:@"%@ error: %@", self, error];
            }
        }
    }

    return loader;
}

#pragma mark - Object Lifecycle

- (instancetype)init
{
    if ((self = [super init])) {
        _fileManager = [[NSFileManager alloc] init];
    }
    return self;
}

- (void)dealloc
{
    fbdfl_AudioServicesDisposeSystemSoundID(_systemSoundID);

    [_fileManager release];
    [_fileURL release];
    [super dealloc];
}

#pragma mark - Public API

- (BOOL)loadSound:(NSError **)errorRef
{
    NSURL *fileURL = [self _fileURL:errorRef];

    if (![_fileManager fileExistsAtPath:[fileURL path]]) {
        NSData *data = [[self class] data];
        if (![data writeToURL:fileURL options:NSDataWritingAtomic error:errorRef]) {
            return NO;
        }
    }

    OSStatus status = fbdfl_AudioServicesCreateSystemSoundID((__bridge CFURLRef)fileURL, &_systemSoundID);
    return (status == kAudioServicesNoError);
}

- (void)playSound
{
    if ((_systemSoundID == 0) && ![self loadSound:NULL]) {
        return;
    }
    fbdfl_AudioServicesPlaySystemSound(_systemSoundID);
}

#pragma mark - Helper Methods

- (NSURL *)_fileResourceURL
{
    NSString *resourceBundleName = [FBSettings resourceBundleName];
    if (!resourceBundleName) {
        return nil;
    }

    NSURL *resourceBundleURL = [[NSBundle mainBundle] URLForResource:resourceBundleName withExtension:@"bundle"];
    if (!resourceBundleURL) {
        return nil;
    }

    NSBundle *resourceBundle = [NSBundle bundleWithURL:resourceBundleURL];
    if (!resourceBundle) {
        return nil;
    }

    NSString *name = [[self class] name];
    return [resourceBundle URLForResource:[name stringByDeletingPathExtension] withExtension:[name pathExtension]];
}

- (NSURL *)_fileURL:(NSError **)errorRef
{
    if (_fileURL) {
        return _fileURL;
    }

    _fileURL = [[self _fileResourceURL] copy];
    if (_fileURL) {
        return _fileURL;
    }

    NSURL *baseURL = [_fileManager URLForDirectory:NSCachesDirectory
                                          inDomain:NSUserDomainMask
                                 appropriateForURL:nil
                                            create:YES
                                             error:errorRef];
    if (!baseURL) {
        return nil;
    }

    NSURL *directoryURL = [baseURL URLByAppendingPathComponent:@"fb_audio" isDirectory:YES];
    NSURL *versionURL = [directoryURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%lu", (unsigned long)[[self class] version]]
                                                      isDirectory:YES];
    if (![_fileManager createDirectoryAtURL:versionURL withIntermediateDirectories:YES attributes:nil error:errorRef]) {
        return nil;
    }

    _fileURL = [[versionURL URLByAppendingPathComponent:[[self class] name]] copy];

    return _fileURL;
}

@end

@implementation FBAudioResourceLoader (Subclass)

#pragma mark - Subclass Methods

+ (NSString *)name
{
    return nil;
}

+ (NSUInteger)version
{
    return 0;
}

+ (NSData *)data
{
    return nil;
}

@end
