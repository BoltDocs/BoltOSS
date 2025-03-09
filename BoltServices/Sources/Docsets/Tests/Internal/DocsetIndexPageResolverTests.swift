//
// Copyright (C) 2024 Bolt Contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import XCTest

@testable import BoltDocsets

import BoltTypes

final class DocsetIndexPageResolverTests: XCTestCase {

  func testResolveIndexPagePathWithHash() throws {
    let resolvedPath1 = DocsetIndexPageResolver._resolveIndexPagePath(
      forPurposedIndexPagePath: "https://example.com/#foo=bar",
      platformFamily: .mainOrOther(name: "main"),
      generatorFamily: nil,
      matcher: StubPathMatcher(paths: [])
    )
    XCTAssertEqual(resolvedPath1, "https://example.com/#foo=bar")

    let resolvedPath2 = DocsetIndexPageResolver._resolveIndexPagePath(
      forPurposedIndexPagePath: "index.html#foo=bar",
      platformFamily: .mainOrOther(name: "main"),
      generatorFamily: "doxygen",
      matcher: StubPathMatcher(paths: ["Stub.docset/Contents/Resources/Documents/index.html"])
    )
    XCTAssertEqual(resolvedPath2, "index.html#foo=bar")
  }

  func testResolveOnlineIndexPagePath() throws {
    let resolvedPath = DocsetIndexPageResolver._resolveIndexPagePath(
      forPurposedIndexPagePath: "https://example.com/",
      platformFamily: .mainOrOther(name: "main"),
      generatorFamily: nil,
      matcher: StubPathMatcher(paths: [])
    )
    XCTAssertEqual(resolvedPath, "https://example.com/")
  }

}
