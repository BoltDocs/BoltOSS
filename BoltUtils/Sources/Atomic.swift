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

import Foundation

public protocol AtomicProtocol {

  associatedtype T

  init(_ value: T)

  var value: T { get set }

  @discardableResult
  mutating func synced<U>(_ f: (inout T) throws -> U) rethrows -> U

}

public struct Atomic<T>: AtomicProtocol {

  private var lock = NSLock()
  private var _value: T

  public var value: T {
    get {
      lock.lock()
      let val = _value
      lock.unlock()
      return val
    }
    set {
      lock.lock()
      _value = newValue
      lock.unlock()
    }
  }

  public init(_ value: T) {
    _value = value
  }

  @discardableResult
  public mutating func synced<U>(_ f: (inout T) throws -> U) rethrows -> U {
    lock.lock()
    let e = try f(&_value)
    lock.unlock()
    return e
  }

}
