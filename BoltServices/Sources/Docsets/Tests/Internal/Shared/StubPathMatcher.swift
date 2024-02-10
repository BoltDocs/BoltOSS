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

@testable import BoltDocsets

struct StubPathMatcher: DocsetIndexPageResolverPathMatcher {

  private let paths: [String]

  init(paths: [String]) {
    self.paths = paths.map { path -> String? in
      let splitted = path.components(separatedBy: ".docset/Contents/Resources/Documents/")
      guard splitted.count >= 2 else {
        return nil
      }
      return String(splitted[1])
    }
    .compactMap { $0 }
  }

  func findFirstMatchInPaths(_ indexPaths: [String]) -> String? {
    for indexPath in indexPaths where paths.contains(indexPath) {
      return indexPath
    }
    return nil
  }

}
