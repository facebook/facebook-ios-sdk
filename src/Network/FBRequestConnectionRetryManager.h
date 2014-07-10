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

#import "FBRequestConnection.h"
#import "FBRequestMetadata.h"
#import "FBSession.h"

@class FBRequestConnectionRetryManager;

typedef enum {
    // The normal retry state where we will perform retries.
    FBRequestConnectionRetryManagerStateNormal,

    // Indicates retries are aborted, so the user supplied handlers should be invoked.
    FBRequestConnectionRetryManagerStateAbortRetries,

    // Indicates we are going to repair the session, which implies that retries are aborted
    // and supplied handlers are NOT invoked since they will be evaluated after the
    // repair operation is executed.
    FBRequestConnectionRetryManagerStateRepairSession
} FBRequestConnectionRetryManagerState;

@protocol FBRequestConnectionRetryManagerDelegate <NSObject>

@optional

- (void)retryManagerDidFinishWithNoRetries:(FBRequestConnectionRetryManager *)retryManager;

- (void)retryManagerDidFinishAbortingRetries:(FBRequestConnectionRetryManager *)retryManager;

- (void)          retryManager:(FBRequestConnectionRetryManager *)retryManager
willRetryWithRequestConnection:(FBRequestConnection *)retryRequestConnection;

@end

// Internal class for tracking retries for a given FBRequestConnection
//   Essentially this helps FBRequestConnection support a two phase approach
//   to processing its request handlers. The first pass is the normal
//   loop over the request handlers. The handlers then have the opportunity
//   to passage messages to this RetryManager (typically `addRequestMetadata`
//   to queue a request for the second phase, or update the state for more complex
//   scenarios like repairing a session).
// Then the second phase executes and will eventually (possibly after an
//   attempt to repair the session) invoke the queued handlers.
// Thus, this class has the unfortunate responsibility of keeping state
//   between handlers.
@interface FBRequestConnectionRetryManager : NSObject

// This is like a delegate pattern in that this is a weak reference to the
// "parent" FBRequestConnection since we expect the parent to have a strong
// reference to this RetryManager instance.
@property (nonatomic, unsafe_unretained) FBRequestConnection<FBRequestConnectionRetryManagerDelegate> *requestConnection;

// See above enum.
@property (nonatomic, assign) FBRequestConnectionRetryManagerState state;

// It's possible for a batch of FBRequests to use different session instances.
// For now, we only support reconnecting one session instance (especially since
// the UX would probably be broken to login twice). This property tracks the
// session that has been identified for reconnecting and is assigned at runtime
// when the first FBRequest with the reconnecting behavior is encountered
@property (nonatomic, retain) FBSession *sessionToReconnect;

// A message that can be shown to the user before executing the retry batch.
@property (nonatomic, copy) NSString *alertMessage;

- (instancetype)initWithFBRequestConnection:(FBRequestConnection<FBRequestConnectionRetryManagerDelegate> *)requestConnection;

// The main method to invoke the retry batch; it also checks alertMessage
// to possibly present an alertview.
- (void)performRetries;

// Add a request to the retry batch.
- (void)addRequestMetadata:(FBRequestMetadata *)metadata;

@end
