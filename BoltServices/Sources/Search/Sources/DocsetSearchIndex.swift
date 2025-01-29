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

@preconcurrency import RxCocoa
@preconcurrency import RxRelay

import BoltRxSwift
import BoltTypes
import BoltUtils

public final class DocsetSearchIndex: Sendable, CustomStringConvertible, LoggerProvider {

  public var description: String {
    return "DocsetSearchIndex(identifier: \(identifier))"
  }

  public enum Status: Equatable {
    case uninitialized
    case indexing(progress: Double)
    case ready
    case error
  }

  let status = BehaviorRelay<Status>(value: .uninitialized)
  public let statusDriver: Driver<Status>

  let docsetPath: String
  let identifier: String

  convenience init(docset: Docset) {
    self.init(docsetPath: docset.path, identifier: docset.identifier)
  }

  init(docsetPath: String, identifier: String) {
    self.docsetPath = docsetPath
    self.identifier = identifier
    statusDriver = status.asDriverOnErrorJustIgnore()
  }

}
