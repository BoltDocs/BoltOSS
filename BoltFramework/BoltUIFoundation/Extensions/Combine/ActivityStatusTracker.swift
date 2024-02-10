//
// Copyright (C) 2023 Bolt Contributors
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

public enum ActivityStatus<T, E: Error> {
  case idle
  case loading
  case result(result: Result<T, E>)
}

public class ActivityStatusTracker<T, E: Error> {

  // swiftlint:disable:next generic_type_name
  private struct ActivityStatusToken<_T, _E: Error> {

    let source: AnyPublisher<Result<_T, _E>, Never>

    let onSubscribeAction: () -> Void
    let onNextAction: (Result<_T, _E>) -> Void
    let onCompletedAction: () -> Void

    func asPublisher() -> AnyPublisher<Result<_T, _E>, Never> {
      source
        .receive(on: RunLoop.main)
        .handleEvents(
          receiveSubscription: { _ in
            onSubscribeAction()
          },
          receiveOutput: { output in
            onNextAction(output)
          }
        )
        .eraseToAnyPublisher()
    }

  }

  @Published private var _relay: ActivityStatus<T, E> = .idle

  private let _lock = NSRecursiveLock()
  private var _loadingCnt = 0

  public var status: AnyPublisher<ActivityStatus<T, E>, Never> {
    return $_relay
      .eraseToAnyPublisher()
  }

  public init() { }

  fileprivate func trackActivityStatus<Source: Publisher>(
    ofPublisher source: Source
  ) -> AnyPublisher<Source.Output, Source.Failure>
    where Source.Output == Result<T, E>, Source.Failure == Never
  {
    return ActivityStatusToken(
      source: source.eraseToAnyPublisher(),
      onSubscribeAction: {
        self._lock.lock()
        self._loadingCnt += 1
        if self._loadingCnt == 1 {
          self._relay = .loading
        }
        self._lock.unlock()
      },
      onNextAction: { output in
        self._lock.lock()

        if case .success = output {
          self._relay = .result(result: output)
        } else if case .failure = output {
          self._loadingCnt -= 1
          if self._loadingCnt == 0, case .loading = self._relay {
            self._relay = .result(result: output)
          }
        }

        self._lock.unlock()
      },
      onCompletedAction: {
        self._lock.lock()
        self._loadingCnt -= 1
        if self._loadingCnt == 0 {
          if case .loading = self._relay {
            self._relay = .idle
          }
        }
        self._lock.unlock()
      }
    )
    .asPublisher()
  }

}

public extension Publisher {

  func trackActivityStatus<T, E>(
    _ activityStatusTracker: ActivityStatusTracker<T, E>
  ) -> AnyPublisher<Output, Failure>
    where Output == Result<T, E>, Failure == Never
  {
    activityStatusTracker.trackActivityStatus(ofPublisher: self)
  }

}
