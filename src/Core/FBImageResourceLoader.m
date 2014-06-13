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

#import "FBImageResourceLoader.h"

#import "FBInternalSettings.h"
#import "FBUtility.h"

@implementation FBImageResourceLoader

+ (UIImage *)loadImageFromBytes:(const Byte *)bytes
                         length:(NSUInteger)length
                          scale:(CGFloat)scale {
    NSData *data = [NSData dataWithBytesNoCopy:(void *)bytes length:length freeWhenDone:NO];
    UIImage *image = [UIImage imageWithData:data scale:scale];
    return image;
}

+ (UIImage *)imageFromBytes:(const Byte *)bytes
                     length:(NSUInteger)length
            fromRetinaBytes:(const Byte *)retinaBytes
               retinaLength:(NSUInteger)retinaLength {
    if ([FBUtility isRetinaDisplay] && retinaBytes) {
        return [FBImageResourceLoader loadImageFromBytes:retinaBytes length:retinaLength scale:2.0];
    } else {
        return [FBImageResourceLoader loadImageFromBytes:bytes length:length scale:1.0];
    }
}

+ (UIImage *)imageNamed:(NSString *)imageName
              fromBytes:(const Byte *)bytes
                 length:(NSUInteger)length
        fromRetinaBytes:(const Byte *)retinaBytes
           retinaLength:(NSUInteger)retinaLength {
    NSString *bundleName = [FBSettings resourceBundleName];
    if (bundleName) {
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"%@.bundle/%@", bundleName, imageName]];
        if (image) {
            return image;
        }
    }
    return [FBImageResourceLoader imageFromBytes:bytes
                                          length:length
                                 fromRetinaBytes:retinaBytes
                                    retinaLength:retinaLength];
}

@end
