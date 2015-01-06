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
#import "FBTask.h"

@interface FBTask (Private)

/*!
 Waits until this operation is completed, then returns its value.
 This method is inefficient and consumes a thread resource while
 its running. It should be avoided. This method logs an warning
 message if it is used on the main thread. If this task is cancelled,
 nil is returned.
 */
- (id)waitForResult:(NSError **)error;

@end
