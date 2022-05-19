//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import XCTest
@testable import ArgumentParser

final class StringWrappingTests: XCTestCase {}

let shortSample = """
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Lectus proin nibh nisl condimentum id. Semper feugiat nibh sed pulvinar proin gravida hendrerit. Massa id neque aliquam vestibulum morbi blandit cursus risus at. Iaculis urna id volutpat lacus laoreet. Netus et malesuada fames ac turpis egestas sed tempus urna.
"""

let longSample = """
Pretium vulputate sapien nec sagittis aliquam malesuada bibendum. Ut diam quam nulla porttitor.

Egestas egestas fringilla phasellus faucibus. Amet dictum sit amet justo donec enim diam. Consectetur adipiscing elit duis tristique.

Enim lobortis scelerisque fermentum dui.

Et leo duis ut diam quam.

Integer eget aliquet nibh praesent tristique magna sit. Faucibus turpis in eu mi bibendum neque egestas congue quisque.       Risus nec feugiat in fermentum posuere urna nec tincidunt.
"""

let jsonSample = """
{
  "level1": {
    "level2": {
      "level3": true
    }
  }
}
"""

// MARK: -

extension StringWrappingTests {
  func testShort() {
    XCTAssertEqual(shortSample.wrapped(to: 40), """
            Lorem ipsum dolor sit amet, consectetur
            adipiscing elit, sed do eiusmod tempor
            incididunt ut labore et dolore magna
            aliqua. Lectus proin nibh nisl
            condimentum id. Semper feugiat nibh sed
            pulvinar proin gravida hendrerit. Massa
            id neque aliquam vestibulum morbi
            blandit cursus risus at. Iaculis urna
            id volutpat lacus laoreet. Netus et
            malesuada fames ac turpis egestas sed
            tempus urna.
            """)
    
    XCTAssertEqual(shortSample.wrapped(to: 80), """
            Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor
            incididunt ut labore et dolore magna aliqua. Lectus proin nibh nisl condimentum
            id. Semper feugiat nibh sed pulvinar proin gravida hendrerit. Massa id neque
            aliquam vestibulum morbi blandit cursus risus at. Iaculis urna id volutpat
            lacus laoreet. Netus et malesuada fames ac turpis egestas sed tempus urna.
            """)
  }
  
  func testShortWithIndent() {
    XCTAssertEqual(shortSample.wrapped(to: 60, wrappingIndent: 10), """
                      Lorem ipsum dolor sit amet, consectetur
                      adipiscing elit, sed do eiusmod tempor incididunt
                      ut labore et dolore magna aliqua. Lectus proin
                      nibh nisl condimentum id. Semper feugiat nibh sed
                      pulvinar proin gravida hendrerit. Massa id neque
                      aliquam vestibulum morbi blandit cursus risus at.
                      Iaculis urna id volutpat lacus laoreet. Netus et
                      malesuada fames ac turpis egestas sed tempus urna.
            """)
  }
  
  func testLong() {
    XCTAssertEqual(longSample.wrapped(to: 40), """
            Pretium vulputate sapien nec sagittis
            aliquam malesuada bibendum. Ut diam
            quam nulla porttitor.

            Egestas egestas fringilla phasellus
            faucibus. Amet dictum sit amet justo
            donec enim diam. Consectetur adipiscing
            elit duis tristique.

            Enim lobortis scelerisque fermentum
            dui.

            Et leo duis ut diam quam.

            Integer eget aliquet nibh praesent
            tristique magna sit. Faucibus turpis in
            eu mi bibendum neque egestas congue
            quisque.       Risus nec feugiat in
            fermentum posuere urna nec tincidunt.
            """)
    
    XCTAssertEqual(longSample.wrapped(to: 80), """
            Pretium vulputate sapien nec sagittis aliquam malesuada bibendum. Ut diam quam
            nulla porttitor.

            Egestas egestas fringilla phasellus faucibus. Amet dictum sit amet justo donec
            enim diam. Consectetur adipiscing elit duis tristique.

            Enim lobortis scelerisque fermentum dui.

            Et leo duis ut diam quam.

            Integer eget aliquet nibh praesent tristique magna sit. Faucibus turpis in eu
            mi bibendum neque egestas congue quisque.       Risus nec feugiat in fermentum
            posuere urna nec tincidunt.
            """)
  }
  
  func testLongWithIndent() {
    XCTAssertEqual(longSample.wrapped(to: 60, wrappingIndent: 10), """
                      Pretium vulputate sapien nec sagittis aliquam
                      malesuada bibendum. Ut diam quam nulla porttitor.

                      Egestas egestas fringilla phasellus faucibus.
                      Amet dictum sit amet justo donec enim diam.
                      Consectetur adipiscing elit duis tristique.

                      Enim lobortis scelerisque fermentum dui.

                      Et leo duis ut diam quam.

                      Integer eget aliquet nibh praesent tristique
                      magna sit. Faucibus turpis in eu mi bibendum
                      neque egestas congue quisque.       Risus nec
                      feugiat in fermentum posuere urna nec tincidunt.
            """)
    
  }

  func testJSON() {
    XCTAssertEqual(jsonSample.wrapped(to: 80), """
            {
              "level1": {
                "level2": {
                  "level3": true
                }
              }
            }
            """)
  }

  func testJSONWithIndent() {
    XCTAssertEqual(jsonSample.wrapped(to: 80, wrappingIndent: 10), """
                      {
                        "level1": {
                          "level2": {
                            "level3": true
                          }
                        }
                      }
            """)
  }
}
