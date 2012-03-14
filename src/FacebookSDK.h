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

#import "FBSession.h"

////////////////////////////////////////////////////////////////////////////////

/* 
 Summary: this diff summarizes changes to the Facebook iOS SDK that we are
 considering for the next few months. This is a header-only diff, and is not
 a complete description of our thinking, but is meant to provide context
 sufficient for review by others.
 
 Files:
 FacebookSDK.h   - this file, high-level description of the effort and goals
 FBSession.h     - example spec for FBSession class 
 
 Goals:
 * Leverage and work well with modern features of iOS (e.g. blocks, ARC, etc.)
 * Patterned after best of breed iOS frameworks (e.g. naming, pattern-use, etc.)
 * Light and/or commodity integration experience is painless & easy to describe
 * Deep support for at least one "key scenario" (e.g. publishing OG app)
 
 Notes on approaches:
 1) We are using our key scenario (owned by Eddie O'Neil) to drive 
    prioritization of work
 2) We will be building-atop/refactoring the existing iOS SDK implementation
 3) We have prototyped an incremental approach where we can choose to maintain
    as little or as much compatibility with the existing SDK needed
    3.a) and so we will be developing to this approach
    3.b) and then at push-time we will decide when/what to break on a
         feature by feature basis
 4) Some light but critical infrastructure is needed to support both the goals
    and the execution of this change (e.g. a build/package/deploy process)
 
 Design points:
 We will move to a more object-oriented approach, in order to facilitate the
 addition of a different class of objects, such as controls and visual helpers
 (e.g. FBLikeView, FBPersonView), as well as sub-frameworks to enable scenarios 
 such (e.g. FBOpenGraphEntity, FBLocalEntityCache, etc.)
 
 As we add features, it will no longer be appropriate to host all functionality
 in the Facebook class. We may (presently undecided) keep the Facebook class to 
 aid the ultra-simple use cases, and to perhaps preserve compatibility with the 
 existing SDK. However, it will cease to be the central design point of the 
 and will become a lighter-weight helper class, that wraps other public objects.
 
               *------------* *----------*  *----------------* *---*
  Scenario --> |FBPersonView| |FBLikeView|  |FBLocationFinder| | F |
               *------------* *----------*  *----------------* | a |
               *-------------------*  *----------*  *--------* | c |
 Component --> | FBOpenGraphEntity |  | FBDialog |  | FBView | | e |
               *-------------------*  *----------*  *--------* | b |
               *---------* *---------* *---------------------* | o |
      Core --> |FBSession| |FBRequest| |Utilities (e.g. JSON)| | o |
               *---------* *---------* *---------------------* * k *
                                                               
 The figure above describes three layers of functionality, with the existing
 Facebook on the side as a helper proxy to a subset of the overal SDK. The
 layers loosely organize the SDK into *Core Objects* necessary to interface 
 with Facebook, higher-level *Framework Components* that feel like natural
 extensions to existing frameworks such as UIKit and Foundation, but which
 reuse surface broadly applicable Facebook-specific behavior, and finally the
 *Scenario Objects*, which provide deeper turnkey capibilities for useful 
 mobile scenarios.
 
 Use example (low barrier use case):
 
 // log on to Facebook
 _fbsession = [[FBSession alloc] init];
 [_fbsession loginWithCompletionBlock:^(FBSession *session, 
                                        FBSessionStatus status, 
                                        NSError *error) {
     if (session.isValid) {
         // request basic information for the user
         [FBRequest requestWithGraphPath:@"me"
                              forSession:session
                   completeResultToBlock:^void(FBRequest *request, 
                                               FBRequestStatus status,
                                               id result) {
             if (status == FBRequestStatusSuccess) {
                 // get json from result
             }
         }];
     }
 }];

*/
