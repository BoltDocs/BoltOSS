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

import RxCocoa
import RxSwift

/// - SeeAlso: https://github.com/ReactiveX/RxSwift/blob/master/RxExample/RxExample/Services/ActivityIndicator.swift

private struct ActivityToken<E>: ObservableConvertibleType, Disposable {
  private let _source: Observable<E>
  private let _dispose: Cancelable

  init(source: Observable<E>, disposeAction: @escaping () -> Void) {
    _source = source
    _dispose = Disposables.create(with: disposeAction)
  }

  func dispose() {
    _dispose.dispose()
  }

  func asObservable() -> Observable<E> {
    return _source
  }
}

/**
Enables monitoring of sequence computation.
If there is at least one sequence computation in progress, `true` will be sent.
When all activities complete `false` will be sent.
*/
public class ActivityIndicator: SharedSequenceConvertibleType {
  public typealias Element = Bool
  public typealias SharingStrategy = DriverSharingStrategy

  private let _lock = NSRecursiveLock()
  private let _relay = BehaviorRelay(value: 0)
  private let _loading: SharedSequence<SharingStrategy, Bool>

  public init() {
    _loading = _relay.asDriver()
      .map {
        $0 > 0
      }
      .distinctUntilChanged()
  }

  fileprivate func trackActivityOfObservable<Source: ObservableConvertibleType>(_ source: Source) -> Observable<Source.Element> {
    return Observable.using({ () -> ActivityToken<Source.Element> in
      self.increment()
      return ActivityToken(source: source.asObservable(), disposeAction: self.decrement)
    }, observableFactory: { t in
      return t.asObservable()
    })
  }

  private func increment() {
    _lock.lock()
    _relay.accept(_relay.value + 1)
    _lock.unlock()
  }

  private func decrement() {
    _lock.lock()
    _relay.accept(_relay.value - 1)
    _lock.unlock()
  }

  public func asSharedSequence() -> SharedSequence<SharingStrategy, Element> {
    return _loading
  }
}

public extension ObservableConvertibleType {
  func trackActivity(_ activityIndicator: ActivityIndicator) -> Observable<Element> {
    return activityIndicator.trackActivityOfObservable(self)
  }
}
