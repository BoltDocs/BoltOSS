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

public extension Future {

  static func awaiting<T>(_ asyncFunc: @escaping () async -> T) -> Future<T, Never> {
    return Future<T, Never> { promise in
      Task {
        let output = await asyncFunc()
        promise(.success(output))
      }
    }
  }

  static func awaitingThrowing<T>(_ asyncFunc: @escaping () async throws -> T) -> Future<T, Error> {
    return Future<T, Error> { promise in
      Task {
        do {
          let output = try await asyncFunc()
          promise(.success(output))
        } catch {
          promise(.failure(error))
        }
      }
    }
  }

}
