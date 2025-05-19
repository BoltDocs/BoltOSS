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

/// - SeeAlso: https://www.swiftbysundell.com/articles/unit-testing-combine-based-swift-code/

import Combine
import Testing
import XCTest

public extension XCTestCase {

  func awaitPublisher<T: Publisher>(
    _ publisher: T,
    timeout: TimeInterval = 10,
    file: StaticString = #filePath,
    line: UInt = #line
  ) async throws -> T.Output {
    // This time, we use Swift's Result type to keep track
    // of the result of our Combine pipeline:
    var result: Result<T.Output, Error>?
    let expectation = self.expectation(description: "Awaiting publisher")

    let cancellable = publisher.sink(
      receiveCompletion: { completion in
        switch completion {
        case .failure(let error):
          result = .failure(error)
        case .finished:
          break
        }

        expectation.fulfill()
      },
      receiveValue: { value in
        result = .success(value)
      }
    )

    // Just like before, we await the expectation that we
    // created at the top of our test, and once done, we
    // also cancel our cancellable to avoid getting any
    // unused variable warnings:
    await fulfillment(of: [expectation], timeout: timeout)
    cancellable.cancel()

    // Here we pass the original file and line number that
    // our utility was called at, to tell XCTest to report
    // any encountered errors at that original call site:
    let unwrappedResult = try XCTUnwrap(
      result,
      "Awaited publisher did not produce any output",
      file: file,
      line: line
    )

    return try unwrappedResult.get()
  }

}

public func awaitPublisherForSwiftTesting<T: Publisher>(
  _ publisher: T,
  sourceLocation: SourceLocation = #_sourceLocation
) async throws -> T.Output {
  var result: Result<T.Output, Error>?

  await confirmation(
    "Awaiting publisher",
    sourceLocation: sourceLocation
  ) { confirmation in
    var cancellable: Cancellable?
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      cancellable = publisher.sink { completion in
        switch completion {
        case .failure(let error):
          result = .failure(error)
        case .finished:
          break
        }
        continuation.resume()
      } receiveValue: { value in
        result = .success(value)
      }
    }
    confirmation.confirm()
    cancellable?.cancel()
  }

  let unwrappedResult = try #require(
    result,
    "Awaited publisher did not produce any output",
    sourceLocation: sourceLocation
  )

  return try unwrappedResult.get()
}
