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

public extension FileManager {

  func contentsOfDirectory(atPath path: String, ofExtension expectedExtension: String, caseSensitive: Bool = false) -> [String] {
    guard let paths = try? self.contentsOfDirectory(atPath: path) else {
      return []
    }

    var extensions = expectedExtension.split(separator: ".").map { String($0) }
    return paths.filter { path in
      // For matching files like 'file.tar.gz'
      let candidateExtensions = URL(fileURLWithPath: path).pathExtensions
      if !caseSensitive {
        extensions = extensions.map { $0.lowercased() }
        return extensions == candidateExtensions.map { $0.lowercased() }
      } else {
        return extensions == candidateExtensions
      }
    }
  }

  func fileExistsAndIsDirectory(atPath path: String) -> (Bool, isDirectory: Bool) {
    var isDirectory: ObjCBool = false
    let fileExists = self.fileExists(atPath: path, isDirectory: &isDirectory)
    return (fileExists, isDirectory.boolValue)
  }

}
