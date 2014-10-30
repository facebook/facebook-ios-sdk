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

#import "SIPhoto.h"

@implementation SIPhoto

+ (instancetype)photoWithObjectURL:(NSURL *)objectURL
                             title:(NSString *)title
                            rating:(NSUInteger)rating
                             image:(UIImage *)image
{
  SIPhoto *photo = [[self alloc] init];
  photo.objectURL = objectURL;
  photo.title = title;
  photo.rating = rating;
  photo.image = image;
  return photo;
}

@end
