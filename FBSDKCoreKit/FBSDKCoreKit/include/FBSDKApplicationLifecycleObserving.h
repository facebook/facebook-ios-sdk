/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_ApplicationLifecycleObserving)
@protocol FBSDKApplicationLifecycleObserving

- (void)startObservingApplicationLifecycleNotifications
  NS_SWIFT_NAME(startObservingApplicationLifecycleNotifications());

/**
 Registers only the observers that persist un-flushed App Events to disk when the app
 leaves the active state (resign-active / terminate). This is separated from
 `startObservingApplicationLifecycleNotifications` so it can be armed during the
 synchronous init phase — before SDK setup is deferred past the first frame — so that
 events logged early are persisted (and re-sent next launch) rather than lost if the app
 is closed before the deferred setup runs. Idempotent.
 */
- (void)startObservingApplicationStatePersistenceNotifications
  NS_SWIFT_NAME(startObservingApplicationStatePersistenceNotifications());

@end

NS_ASSUME_NONNULL_END
