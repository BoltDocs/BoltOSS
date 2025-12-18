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

import Foundation

import BoltLocalizations
import BoltModuleExports

typealias SearchScope = LookupSearchScope

extension SearchScope {

  static var allCases: [Self] {
    [.types, .docPage, .tableOfContents]
  }

  init?(index: Int) {
    guard 0..<Self.allCases.count ~= index else {
      return nil
    }
    self = Self.allCases[index]
  }

  var index: Int {
    return Self.allCases.firstIndex(of: self) ?? 0
  }

  var displayTitle: String {
    switch self {
    case .types:
      return "Lookup-SearchScope-Index".boltLocalized
    case .docPage:
      return "Lookup-SearchScope-Reference".boltLocalized
    case .tableOfContents:
      return "Lookup-SearchScope-Contents".boltLocalized
    }
  }

}
