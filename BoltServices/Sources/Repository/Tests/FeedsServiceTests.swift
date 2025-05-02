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

import Combine
import Foundation
import XCTest

import Factory

import BoltDatabase
import BoltNetworkingTestStubs
import BoltTypes
import BoltUtils

@testable import BoltRepository

final class FeedsServiceTests: NetworkingStubbedTestCase {

  @LazyInjected(\.feedsService)
  private var feedsService: FeedsService

  func testFetchCustomFeeds() throws {
    let testFeed = CustomFeed(entity: CustomFeedEntity(name: "Test1", urlString: "https://boltdocs.app/feed"))

    try feedsService.insertCustomFeed(testFeed)

    let expectation = XCTestExpectation()

    DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .microseconds(500))) {
      Task {
        let fetchedFeeds = try await self.feedsService.fetchAllFeeds(forRepository: .custom, cacheIfPossible: true)
        XCTAssertEqual(try XCTUnwrap(fetchedFeeds as? [CustomFeed]), [testFeed])
        expectation.fulfill()
      }
    }

    wait(for: [expectation], timeout: 5)
  }

  func testCustomFeedsOperations() throws {
    var cancellableBag = Set<AnyCancellable>()

    let expectation = XCTestExpectation()

    let testFeed = CustomFeed(entity: CustomFeedEntity(name: "Test1", urlString: "https://boltdocs.app/feed"))

    // force the observation to start first
    feedsService.customFeedsObservable()
      .sink { _ in }
      .cancel()

    let expectedResult: [[String]] = [[], [testFeed.id], []]

    var results = [[String]]()

    feedsService.customFeedsObservable()
      .prefix(expectedResult.count)
      .eraseToAnyPublisher()
      .sink(receiveCompletion: { _ in
        XCTAssertEqual(results, expectedResult)
        expectation.fulfill()
      }, receiveValue: { val in
        results.append(val.map { $0.id })
      })
      .store(in: &cancellableBag)

    do {
      try feedsService.insertCustomFeed(testFeed)
      try feedsService.deleteCustomFeeds(testFeed)
    } catch {
      XCTFail("error thrown: \(error)")
    }

    wait(for: [expectation], timeout: 5)
  }

}
