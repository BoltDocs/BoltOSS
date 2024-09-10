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

import Dispatch
import Foundation

public extension DispatchQueue {

  func asyncSafe(
    group: DispatchGroup? = nil,
    qos: DispatchQoS = .unspecified,
    flags: DispatchWorkItemFlags = [],
    execute work: @escaping @Sendable  () -> Void
  ) {
    if Self.currentLabel == label {
      work()
    } else {
      async(group: group, qos: qos, flags: flags, execute: work)
    }
  }

  func syncSafe<T>(flags: DispatchWorkItemFlags? = nil, execute work: () throws -> T) rethrows -> T {
    if Self.currentLabel == self.label {
      return try work()
    } else if let flags = flags {
      return try self.sync(flags: flags, execute: work)
    } else {
      return try self.sync(execute: work)
    }
  }

}

extension DispatchQueue {

  class var currentLabel: String? {
    return String(validatingCString: __dispatch_queue_get_label(nil))
  }

}
