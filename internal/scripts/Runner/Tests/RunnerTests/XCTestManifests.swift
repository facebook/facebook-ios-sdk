// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    [
        testCase(RunnerTests.allTests),
    ]
}
#endif
