/**
 * (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.
 */

/**
 * @flow strict-local
 */
import { doesExist } from '../AppEvents.js';

describe('JS Utility Tests', () => {
  let nullVar;
  let undefinedVar;
  beforeAll(() => {
    nullVar = null;
    undefinedVar = undefined;
  })
  
  test('The undefined/null vars should be undefined or null', () => {
    expect(doesExist(nullVar)).toBe(false);
    expect(doesExist(undefinedVar)).toBe(false);
  });
});
