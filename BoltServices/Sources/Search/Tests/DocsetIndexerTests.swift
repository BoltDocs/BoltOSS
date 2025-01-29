//
// Copyright (C) 2025 Bolt Contributors
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

import XCTest

import UUIDShortener

import BoltRxSwift
import BoltTypes

@testable import BoltSearch

final class DocsetIndexerTests: XCTestCase {

  func testDocsetIndexerQueue() async throws {
    let fileManager = FileManager.default

    let tmpDir = NSTemporaryDirectory().appendingPathComponent(UUID().uuidString)

    try fileManager.createDirectory(atPath: tmpDir, withIntermediateDirectories: true)

    defer {
      try? fileManager.removeItem(atPath: tmpDir)
    }

    let numberOfIndicesToQueue = 5

    for i in 0..<numberOfIndicesToQueue {
      try fileManager.copyItem(
        atPath: XCTUnwrap(Bundle.module.path(forResource: "TestResources/Bash.docset")),
        toPath: tmpDir.appendingPathComponent("Bash_\(i).docset")
      )
    }

    var expectations = [XCTestExpectation]()

    let disposeBag = DisposeBag()

    let indices = (0..<numberOfIndicesToQueue).map { idx -> DocsetSearchIndex in
      let docsetPath = tmpDir.appendingPathComponent("Bash_\(idx).docset")
      let index = DocsetSearchIndex(docsetPath: docsetPath, identifier: "Bash_\(idx)")
      let expectation = XCTestExpectation(description: "index \(idx) completes")
      index.status
        .subscribe(on: MainScheduler.instance)
        .subscribe { status in
          if case .ready = status {
            expectation.fulfill()
          }
        }
        .disposed(by: disposeBag)
      expectations.append(expectation)
      return index
    }

    let docsetIndexer = DocsetIndexer(maxConcurrentTasks: 1)

    for index in indices {
      await docsetIndexer.addSearchIndexToQueue(index)
    }

    await fulfillment(of: expectations, timeout: 5, enforceOrder: true)
  }

}
