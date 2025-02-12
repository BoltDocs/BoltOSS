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

import Combine

// https://stackoverflow.com/questions/63926305/combine-previous-value-using-combine

public extension Publisher {

  /// Includes the current element as well as the previous element from the upstream publisher in a tuple where the previous element is optional.
  /// The first time the upstream publisher emits an element, the previous element will be `nil`.
  ///
  ///     let range = (1...5)
  ///     cancellable = range.publisher
  ///         .withPrevious()
  ///         .sink { print ("(\($0.previous), \($0.current))", terminator: " ") }
  ///      // Prints: "(nil, 1) (Optional(1), 2) (Optional(2), 3) (Optional(3), 4) (Optional(4), 5) ".
  ///
  /// - Returns: A publisher of a tuple of the previous and current elements from the upstream publisher.
  func withPrevious() -> AnyPublisher<(previous: Output?, current: Output), Failure> {
    scan(Optional<(Output?, Output)>.none) { ($0?.1, $1) }
      .compactMap { $0 }
      .eraseToAnyPublisher()
  }

  /// Includes the current element as well as the previous element from the upstream publisher in a tuple where the previous element is not optional.
  /// The first time the upstream publisher emits an element, the previous element will be the `initialPreviousValue`.
  ///
  ///     let range = (1...5)
  ///     cancellable = range.publisher
  ///         .withPrevious(0)
  ///         .sink { print ("(\($0.previous), \($0.current))", terminator: " ") }
  ///      // Prints: "(0, 1) (1, 2) (2, 3) (3, 4) (4, 5) ".
  ///
  /// - Parameter initialPreviousValue: The initial value to use as the "previous" value when the upstream publisher emits for the first time.
  /// - Returns: A publisher of a tuple of the previous and current elements from the upstream publisher.
  func withPrevious(_ initialPreviousValue: Output) -> AnyPublisher<(previous: Output, current: Output), Failure> {
    scan((initialPreviousValue, initialPreviousValue)) { ($0.1, $1) }.eraseToAnyPublisher()
  }

}
