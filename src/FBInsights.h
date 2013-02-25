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

#import <Foundation/Foundation.h>
#import "FBSession.h"

/*!
 @typedef FBInsightsFlushBehavior enum
 
 @abstract
 Control when <FBInsights> sends log events to the server
 
 @discussion
 If an instance of an app doesn't send during its lifetime, or can't establish connectivity, the
 events will be stashed for the next run and sent then.
 */
typedef enum {
    
    /*! Flush automatically: periodically and always at app reactivation. */
    FBInsightsFlushBehaviorAuto,
    
    /*! Only flush when explicitFlush is called. When an app is moved to background/terminated, the
     events are persisted and re-established at activation, but they will only be written with an
     explicit flush. */
    FBInsightsFlushBehaviorExplicitOnly,
    
} FBInsightsFlushBehavior;

/*
 * Constant used by NSNotificationCenter for results of flushing Insights event logs
 */

/*! NSNotificationCenter name indicating a result of a log flush attempt */
extern NSString *const FBInsightsLoggingResultNotification;

/*!
 @class FBInsights
 
 @abstract
 Client-side event logging for specialized application analytics available through Facebook Insights 
 and Conversion Pixel conversion tracking for ads optimization.
 
 @discussion
 The `FBInsights` static class has a few related roles:
 
 + Logging predefined events to Facebook Application Insights with a
 numeric value to sum across a large number of events, and an optional set of key/value
 parameters that define "segments" for this event (e.g., 'purchaserStatus' : 'frequent', or
 'gamerLevel' : 'intermediate')
 
 + Logging 'purchase' events to later be used for ads optimization around lifetime value.
 
 + Logging 'conversion pixels' for use in ads conversion tracking and optimization.
 
 + Methods that control the way in which events are flushed out to the Facebook servers.
 
 Here are some important characteristics of the logging mechanism provided by `FBInsights`:
 
 + Events are not sent immediately when logged.  They're cached and flushed out to the Facebook servers
   in a number of situations:
   - when an event count threshold is passed.
   - when a time threshold is passed.
   - when an app has gone to background and is then brought back to the foreground.
 
 + Events will be accumulated when the app is in a disconnected state, and sent when the connection is
   restored and one of the above 'flush' conditions are met.
 
 + The `FBInsights` class in thread-safe in that events may be logged from any of the app's threads.
 
 Some things to note when logging events:
 
 + There is a limit to the number of unique parameter names in the provided parameters that can
 be used per event, on the order of 10.  This is not just for an individual call, but for all
 invocations for that eventName.
 + Event names and parameter names (the keys in the NSDictionary) must be between 2 and 40 characters
 + The length of each parameter value can be no more than on the order of 100 characters.
 
 */
@interface FBInsights : NSObject

/*
 * Global, session wide properties
 */

/*!
 @method
 
 @abstract
 Gets the application version to the provided string.  Insights allows breakdown of
 events by app version.
 */
+ (NSString *)appVersion;

/*!
 @method
 
 @abstract
 Sets the application version to the provided string.  Insights allows breakdown of
 events by app version.
 
 @param appVersion  The version identifier of the iOS app that events are being logged through.
 Enables analysis and breakdown of logged events by app version.
 */
+ (void)setAppVersion:(NSString *)appVersion;

/* 
 * Purchase logging 
 */

/*!
 @method
 
 @abstract
 Log a purchase of the specified amount, in the specified currency.  
 
 @param purchaseAmount    Purchase amount to be logged, as expressed in the specified currency.
 
 @param currency          Currency, is denoted as, e.g. "USD", "EUR", "GBP".  See ISO-4217 for 
 specific values.  One reference for these is <http://en.wikipedia.org/wiki/ISO_4217>.
 
 @discussion              This event immediately triggers a flush of the `FBInsights` event queue, unless the `flushBehavior` is set 
 to `FBInsightsFlushBehaviorExplicitOnly`.
 
 */
+ (void)logPurchase:(double)purchaseAmount
           currency:(NSString *)currency;

/*!
 @method
 
 @abstract
 Log a purchase of the specified amount, in the specified currency, also providing a set of 
 additional characteristics describing the purchase.
 
 @param purchaseAmount  Purchase amount to be logged, as expressed in the specified currency.
 
 @param currency        Currency, is denoted as, e.g. "USD", "EUR", "GBP".  See ISO-4217 for
 specific values.  One reference for these is <http://en.wikipedia.org/wiki/ISO_4217>.
 
 @param parameters      Arbitrary parameter dictionary of characteristics. The keys to this dictionary must
 be NSString's, and the values are expected to be NSString or NSNumber.  Limitations on the number of
 parameters and name construction are given in the `FBInsights` documentation.
 
 @discussion              This event immediately triggers a flush of the `FBInsights` event queue, unless the `flushBehavior` is set
 to `FBInsightsFlushBehaviorExplicitOnly`.

 */
+ (void)logPurchase:(double)purchaseAmount
           currency:(NSString *)currency
         parameters:(NSDictionary *)parameters;

/*!
 @method
 
 @abstract
 Log a purchase of the specified amount, in the specified currency, also providing a set of
 additional characteristics describing the purchase, as well as an <FBSession> to log to.
 
 @param purchaseAmount  Purchase amount to be logged, as expressed in the specified currency.
 
 @param currency        Currency, is denoted as, e.g. "USD", "EUR", "GBP".  See ISO-4217 for
 specific values.  One reference for these is <http://en.wikipedia.org/wiki/ISO_4217>.
 
 @param parameters      Arbitrary parameter dictionary of characteristics. The keys to this dictionary must
 be NSString's, and the values are expected to be NSString or NSNumber.  Limitations on the number of
 parameters and name construction are given in the `FBInsights` documentation.
 
 @param session         <FBSession> to direct the event logging to, and thus be logged with whatever user (if any)
 is associated with that <FBSession>.  A value of `nil` will use `[FBSession activeSession]`.
 
 @discussion            This event immediately triggers a flush of the `FBInsights` event queue, unless the `flushBehavior` is set
 to `FBInsightsFlushBehaviorExplicitOnly`.
 
 */
+ (void)logPurchase:(double)purchaseAmount
           currency:(NSString *)currency
         parameters:(NSDictionary *)parameters
            session:(FBSession *)session;

/*
 * Logging conversion pixels for Ads Optimization/Conversion Tracking.  See https://www.facebook.com/help/435189689870514 to learn more.
 */

/*!
 @method
 
 @abstract
 Log, or "Fire" a Conversion Pixel.  Conversion Pixels are used for Ads Conversion Tracking.  See https://www.facebook.com/help/435189689870514 to learn more.
 
 @param pixelID       Numeric ID for the conversion pixel to be logged.  See https://www.facebook.com/help/435189689870514 to learn how to create
 a conversion pixel.
 
 @param value         Value of what the logging of this pixel is worth to you.  The currency that this is expressed in doesn't matter, so long as it is consistent across all logging for this pixel.

 @discussion          This event immediately triggers a flush of the `FBInsights` event queue, unless the `flushBehavior` is set
 to `FBInsightsFlushBehaviorExplicitOnly`.
 */
+ (void)logConversionPixel:(NSString *)pixelID
              valueOfPixel:(double)value;

/*!
 @method
 
 @abstract
 Log, or "Fire" a Conversion Pixel.  Conversion Pixels are used for Ads Conversion Tracking.  See https://www.facebook.com/help/435189689870514 to learn more.
 
 @param pixelID       Numeric ID for the conversion pixel to be logged.  See https://www.facebook.com/help/435189689870514 to learn how to create
 a conversion pixel.
 
 @param value         Value of what the logging of this pixel is worth to you.  The currency that this is expressed in doesn't matter, so long as it is consistent across all logging for this pixel.
 
 @param session       <FBSession> to direct the event logging to, and thus be logged with whatever user (if any)
 is associated with that <FBSession>.  A value of `nil` will use `[FBSession activeSession]`.
 
 @discussion          This event immediately triggers a flush of the `FBInsights` event queue, unless the `flushBehavior` is set
 to `FBInsightsFlushBehaviorExplicitOnly`.
 
 */
+ (void)logConversionPixel:(NSString *)pixelID
              valueOfPixel:(double)value
                   session:(FBSession *)session;


/*
 * Control over event batching/flushing
 */


/*!
 @method
 
 @abstract
 Get the current event flushing behavior specifying when events are sent back to Facebook servers.
 */
+ (FBInsightsFlushBehavior)flushBehavior;

/*!
 @method
 
 @abstract
 Set the current event flushing behavior specifying when events are sent back to Facebook servers.
 
 @param flushBehavior   The desired `FBInsightsFlushBehavior` to be used.
 */
+ (void)setFlushBehavior:(FBInsightsFlushBehavior)flushBehavior;


/*!
 @method
 
 @abstract
 Explicitly kick off flushing of events to Facebook.  This is an asynchronous method, but it does initiate an immediate
 kick off.  Server failures will be reported through the NotificationCenter with notification ID `FBInsightsLoggingResultNotification`.
 */
+ (void)flush;


@end
