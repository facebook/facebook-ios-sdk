
#import "FBRequestConnection.h"

// Internal only factory class to curry FBRequestHandlers to provide various
// error handling behaviors. See `FBRequestConnection.errorBehavior`
// and `FBRequestConnectionRetryManager` for details.

// Essentially this currying approach offers the flexibility of chaining work internally while
// maintaining the existing surface area of request handlers. In the future this could easily
// be replaced by an actual Promises/Deferred framework (or even provide a responder object param
// to the FBRequestHandler callback for even more extensibility)
@interface FBRequestHandlerFactory : NSObject

+(FBRequestHandler) handlerThatRetries:(FBRequestHandler )handler forRequest:(FBRequest* )request;
+(FBRequestHandler) handlerThatReconnects:(FBRequestHandler )handler forRequest:(FBRequest* )request;
+(FBRequestHandler) handlerThatAlertsUser:(FBRequestHandler )handler forRequest:(FBRequest* )request;

@end
