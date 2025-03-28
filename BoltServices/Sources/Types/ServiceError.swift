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

open class ServiceError: LocalizedError, Equatable {

  public init() { }

  // https://forums.swift.org/t/protocol-default-implementations-and-class-inheritance/11720

  open var errorDescription: String? { nil }

  open var failureReason: String? { nil }

  open var recoverySuggestion: String? { nil }

  open var helpAnchor: String? { nil }

  public static func == (lhs: ServiceError, rhs: ServiceError) -> Bool {
    return lhs === rhs
  }

}
