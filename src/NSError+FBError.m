/*
 * Copyright 2012 Facebook
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

#import "NSError+FBError.h"
#import "FBErrorUtility.h"
#import "FBError.h"

@implementation NSError (FBError)

- (FBErrorCategory) fberrorCategory {
    int code = 0, subcode = 0;
    
    [FBErrorUtility fberrorGetCodeValueForError:self
                                          index:0
                                           code:&code
                                        subcode:&subcode];
    
    return [FBErrorUtility fberrorCategoryFromError:self
                                               code:code
                                            subcode:subcode
                               returningUserMessage:nil
                                andShouldNotifyUser:nil];
}

- (NSString *) fberrorUserMessage {
    NSString *message = nil;
    int code = 0, subcode = 0;
    [FBErrorUtility fberrorGetCodeValueForError:self
                                          index:0
                                           code:&code
                                        subcode:&subcode];
    
    [FBErrorUtility fberrorCategoryFromError:self
                                        code:code
                                     subcode:subcode
                        returningUserMessage:&message
                         andShouldNotifyUser:nil];
    return message;
}

- (BOOL) fberrorShouldNotifyUser {
    BOOL shouldNotifyUser = NO;
    int code = 0, subcode = 0;
    
    [FBErrorUtility fberrorGetCodeValueForError:self
                                          index:0
                                           code:&code
                                        subcode:&subcode];
    
    [FBErrorUtility fberrorCategoryFromError:self
                                        code:code
                                     subcode:subcode
                        returningUserMessage:nil
                         andShouldNotifyUser:&shouldNotifyUser];
    return shouldNotifyUser;
}

@end