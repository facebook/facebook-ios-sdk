/**
 * (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.
 */

/**
 * @flow strict-local
 */
import { doesExist, clone, queryStringWithDictionary, GraphRequest } from '../AppEvents.js';

describe('GraphRequest Functionality', () => {
  let mock_params;
  let mock_urlParams;
  let graph_request;
  beforeAll(() => {
    mock_params = {
      graphPath: "/me?fields=calendar",
      params: {
        name: "Sarah",
        group: "1234",
        privacy: "OPEN",
        location: "San_Francisco",
        state: "California",
        color: "Red",
        instrument: "Guitarra"
      },
      tokenString: "m1v0qns90v923ond00AbakANDKhbIOQVG",
      version: "v2.0",
      method: "GET",
      currentAccessTokenString: "1m0zka9nd8nbd8fb92bn39vk",
      graphAPIVersion: "v12.9"
    };
    mock_urlParams = {
      baseUrl: "https://example.com?foo=1&bar=2&version=2.0",
      params: {
        name: "Joe",
        group: "4995",
        privacy: "PRIVACY",
        location: "Menlo_Park",
        state: "California",
        color: "Green",
        picture: "Guitar"
      },
      httpMethod: "GET"
    };
    graph_request = new GraphRequest(mock_params);
  })

  it('Testing Graph Request Class', () => {
    expect(graph_request).toBeInstanceOf(GraphRequest);
  });

  test('Check GraphRequest Fields - initWithParams(params)', () => {
    expect(graph_request._graphPath).toBe(mock_params.graphPath);
    expect(graph_request._httpMethod).toBe("GET");
    expect(graph_request._version).toBeTruthy();
    expect(graph_request._parameters).toBeTruthy();
  });
  
  test('Check queryStringWithDictionary(dictionary) return', () => {
    expect(queryStringWithDictionary(mock_params.params)).toBeTruthy();
    expect(queryStringWithDictionary(mock_params.params)).toBe(
    "&name=Sarah&group=1234&privacy=OPEN&location=San_Francisco&state=California&color=Red&instrument=Guitarra");
    expect(queryStringWithDictionary(mock_urlParams.params)).toBeTruthy();
    expect(queryStringWithDictionary(mock_urlParams.params)).toBe(
    "&name=Joe&group=4995&privacy=PRIVACY&location=Menlo_Park&state=California&color=Green&picture=Guitar");
    expect(queryStringWithDictionary(mock_urlParams)).toBeTruthy();
    expect(queryStringWithDictionary(mock_urlParams)).toBe(
    "&baseUrl=https://example.com?foo=1&bar=2&version=2.0&params=[object Object]&httpMethod=GET");
  });
  
  test('Check serializeURL(urlParams) return', () => {
    expect(GraphRequest.serializeURL(mock_urlParams)).toBeTruthy();
    expect(GraphRequest.serializeURL(mock_urlParams)).toBe(
    "https://example.comfoo=1&bar=2&version=2.0&name=Joe&group=4995&privacy=PRIVACY&location=Menlo_Park&state=California&color=Green&picture=Guitar");
  });
});
