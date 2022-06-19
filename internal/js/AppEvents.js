/**
 * (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.
 */

/**
 * @flow strict-local
 */
'use_strict';
/** @description Constants */
/** @const {string} GET Request */
const FBSDKHTTPMethodGET = "GET";
/** @const {string} POST Request */
const FBSDKHTTPMethodPOST = "POST";
/** @const {string} DELETE Request */
const FBSDKHTTPMethodDELETE = "DELETE";
/** @const {string} Target Platform Version */
const FBSDK_TARGET_PLATFORM_VERSION = "v7.0";

/**
 * @function doesExist
 * Checks to see if parameter null or undefined (if it exists) by a truthy/falsey state.
 * @param {*} item -  The value to be checked for existence.
 * @returns {boolean) True if item exists, false if it does.
 */
let doesExist = item => !(item === null || item === undefined);

/**
 * Handles cloning an object or any type without the use of JQuery, which allows to do var b = $.extend(true, {}, a).
 * If the parameter obj is null, undefined, String, Boolean, or Number, it is returned. Else, it is copied if it is an object.
 * @param {*} obj - The object to be cloned and returned.
 * @returns {Object} Copy of the parameter.
 */
function clone(obj) {
  try {
    if (!doesExist(obj) || typeof obj === "" || typeof obj === false || typeof obj === 3) return obj;
    return JSON.parse(JSON.stringify(obj));
  }
  catch{e => console.log(e)}
}

/**
 * Formulates a query based on string-keys from the dictionary object, converting it into a URL parameters.
 * @param {Object} dictionary - The query parameters in the form of a dictionary of strings.
 * @returns {string} The query that was requested. If no query was made, returns null.
 */
function queryStringWithDictionary(dictionary) {
  /** @type {string} */
  let queryString = "";
  if (doesExist(dictionary)) {
    /** @type {Object} */
    let keys = clone(dictionary);
    /** @description Sort the keys so that the query string order is deterministic */
    Object.keys(keys).sort();
    /** @type {string} */
    let key = "";
    /** @type {boolean} */
    let firstQueryValue = true;
    for (key in keys){
      if (queryString.length > 0 || firstQueryValue) {
        queryString += "&";
        firstQueryValue = false;
      }
      queryString += key + "=" + keys[key];
    }
  }
  return doesExist(queryString.length) && queryString.length > 0 ? clone(queryString) : null;
}

/**
 * @classdesc Represents a request to the Facebook Graph API.
 *
 * `GraphRequest` encapsulates the components of a request (the
 * Graph API path, the parameters, error recovery behavior) and should be
 * used in conjunction with `GraphRequestConnection` to issue the request.
 *
 * We ignore batch values becuase we look at batch of events, not batch of requests.
 *
 * Nearly all Graph APIs require an access token. Unless specified, the
 * `currentAccessToken` is used.
 *
 * A `- start` method is provided for convenience for single requests.
 */
class GraphRequest {
  /**
   * Creates a new GraphRequest.
   * @class
   */
  constructor(params) {
    /**
     * @description The HTTPMethod to use for the request, for example "GET" or "POST".
     * @type {string}
     */
    this._httpMethod = FBSDKHTTPMethodGET;
    /**
     * @description The access token to be used by the request.
     * @type {string}
     */
    this._tokenString = "";
    /**
     * @description The current version  of the Graph API.
     * @type {string}
     */
    this._version = "";
    /**
     * @description The Graph API endpoint to use for the request (e.g. "me").
     * @type {string}
     */
    this._graphPath = "";
    /**
     * @description The optional parameters dictionary.
     * @type {Object}
     */
    this._parameters = {};
    this.initWithParams(params);
  }

  /**
   * Initializes a new GraphRequest instance.
   * @param {Object} params -  The dictionary parameters to create GraphRequest. Contains these key/value pairs:
   *    {string} graphPath - The Graph API endpoint to use for the request (e.g. "me"). This should be a mandatory value.
   *    {Object} parameters - The optional parameters dictionary.
   *    {string} tokenString - The access token string used by the request. Specifying null will cause no token to be used.
   *    {string} version - The optional Graph API version (e.g. "v2.0"). Null defaults to `graphAPIVersion`.
   *    {string} method - HTTP method. Empty String defaults to "GET".
   *    {string} currentAccessTokenString - The current access token value.
   *    {string} graphAPIVersion - The current version of the Graph API.
   * @returns {Object} GraphRequest instance.
   */
  initWithParams(params) {
    if(!doesExist(params.graphAPIVersion)) {
      params.graphAPIVersion = FBSDK_TARGET_PLATFORM_VERSION;
    }
    if(!doesExist(params.tokenString)) {
      params.tokenString = params.currentAccessTokenString;
    }
    /** @description It is important to note that currentAccessTokenString may be null or undefined, so we need to check if params.tokenString exists. */
    this._tokenString = doesExist(params.tokenString) && params.tokenString.length > 0 ? clone(params.tokenString) : null;
    this._version = doesExist(params.version) && params.version.length > 0 ? clone(params.version) : params.graphAPIVersion;
    this._graphPath = clone(params.graphPath);
    this._httpMethod = doesExist(params.method) && params.method.length > 0 ? clone(params.method) : FBSDKHTTPMethodGET;
    this._parameters = doesExist(params.parameters) && Object.keys(params.parameters).length > 0 ? clone(params.parameters) : {};
  }
  
  /**
   * Tries to do a query request on a URL if HTTPMethodGet is being used.
   * @static
   * @param {Object} urlParams - Parameters to create the URL. Contains:
   *    {string} baseUrl - The main URL component.
   *    {Object} params - The dictionary key/values to be converted into URL.
   *    {string} httpMethod - The HTTPMethod.
   * @returns String with the baseURL and the requested query added to it.
   */
  static serializeURL(urlParams) {
    try {
      if(!doesExist(urlParams.httpMethod) || urlParams.httpMethod !== FBSDKHTTPMethodGET) {
        return urlParams.baseUrl;
      }
      /** @type {string} Utilizing URLSearchParams API */
      let url = new URL(urlParams.baseUrl);
      let urlSearchQuery = new URLSearchParams(url.search.slice(1));
      /**
       * @description queryPrefix is the property from the url containing the initial query string
       * e.g. queryPrefix is "foo=1&bar=2" from https://example.com?foo=1&bar=2
       */
      let queryPrefix = urlSearchQuery.toString();
      let query = queryStringWithDictionary(urlParams.params);
      return url.origin + queryPrefix + query;
    }
    catch{e =>
      console.log(e);
      return null;
    }
  }
  
}

/**
 * @classdesc
 * The `GraphRequestConnection` represents a single connection to Facebook to service a request.
 */
class GraphRequestConnection {
  /**
   * Creates a new GraphRequestConnection
   * @class
   */
  constructor(graph_request) {
    /**
     * @description The GraphRequest instance that will be used to make the network request.
     * @type {GraphRequest}
     */
    this.graph_request = graph_request;
  }
  
  /**
   * @param appId - The application ID.
   * @param requestParams - The parameters that will send the URL to the Facebook servers. Contains body of network request. @see logEvents() for more info.
   * The network request will take three main parameters:
   *    {string} URL - The URL to send to the FB servers.
   *    {Object} body - The dictionary of key/values that can create the URL involving all the necessary queries.
   * @description The HTTP Method being used, e.g. "GET" or "POST", defaults to "POST".
   * @returns void. The callback function receives the Promise, response.json(), or the error.
   */
  sendNetworkRequest(appId, requestParams) {
    try {
      /** @type {string} The URL to send the request */
      let url = "https://graph.facebook.com/" + appId + "/activities";
      /** @type {string} Convert requestParams to JSON */
      let bodyString = JSON.stringify(requestParams);
      
      networkRequest(url,bodyString);
    }
    catch(error) {
      /** The JS Logging For Edge-Cases */
      log('JS Exception type: ', error.code);
      log('JS Exception message: ', error.message);
    }
  }
  
}

/**
 * @function logEvents
 * Logs the response from sending a GraphConnectionRequest to the Facebook servers.
 * Client-side event logging for specialized application analytics available through Facebook App Insights
 * and for use with Facebook Ads conversion tracking and optimization.
 * @param {string} params - The JSON String parameters to initialize GraphRequest instance and make a network request to the Facebook servers.
 *    {string} appId - ID of the application.
 *    {string} graphPath - The Graph API endpoint to use for the request (e.g. "me"). This should be a mandatory value.
 *    {Object} parameters - Optional parameter dictionary forthe  GraphRequest instance.
 *    {string} tokenString - The access token string used by the request. Specifying null will cause no token to be used.
 *    {string} version - The optional Graph API version (e.g. "v2.0"). Null defaults to `graphAPIVersion`.
 *    {string} currentAccessTokenString - The current access token value.
 *    {string} graphAPIVersion - The optional Graph API version.
 *    {Object} requestParams - The event structure to make a network request and log all events sent as part of a request. Contains:
 *        {string} event - The type of the event.
 *        {number} application_tracking_enabled - Says if the application tracking is enabled.
 *        {string} advertiser_id - The ID of the advertiser. Dealt by ObjectiveC.
 *        {string} anon_id - The ID of the anon. Dealt by iOS SDK.
 *        {Object[]} custom_events - Array of all associated events. This is the fetch body in GraphRequestConnection to send the URL to FB servers.
 *        {Object[]} exitinfo - Array of extensive information.
 * @returns void. The callback function receives the Promise, response.json(), or the error. @see GraphRequestConnection.sendNetworkRequest() for more info.
 */
function logEvents(stringParams) {
  /** Convert the JSON String to a JSON Object */
  const params = JSON.parse(stringParams);
  /** The dictionary that instantiates the GraphRequest class via initWithParams(params). In AppEvents, default HTTPMethod is "POST". */
  let graphParams = {
    graphPath: params.graphPath,
    parameters: params.parameters,
    tokenString: params.tokenString,
    version: params.version,
    method: FBSDKHTTPMethodPOST,
    currentAccessTokenString: params.currentAccessTokenString,
    graphAPIVersion: params.graphAPIVersion
  };
  let graph_request = new GraphRequest(graphParams);
  let graph_request_conn = new GraphRequestConnection(graph_request);

  /** @description Validation of params.requestParams */
  if(!doesExist(params.requestParams) || params.requestParams.constructor !== Object || Object.keys(params.requestParams).length === 0) {
    return;
  }
  
  graph_request_conn.sendNetworkRequest(params.appId, params.requestParams);
}
