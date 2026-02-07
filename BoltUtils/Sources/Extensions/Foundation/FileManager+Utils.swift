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
    guard let paths = try? contentsOfDirectory(atPath: path) else {
      return []
    }

    var extensions = expectedExtension.split(separator: ".").map { String($0) }
    return paths.filter { path in
      // For matching files like 'file.tar.gz'
      var candidateExtensions = URL(fileURLWithPath: path).pathExtensions
      if !caseSensitive {
        extensions = extensions.map { $0.lowercased() }
        candidateExtensions = candidateExtensions.map { $0.lowercased() }
      }
      return candidateExtensions.reversed().starts(with: extensions.reversed())
    }
  }

  func fileExistsAndIsDirectory(atPath path: String) -> (Bool, isDirectory: Bool) {
    var isDirectory: ObjCBool = false
    let fileExists = fileExists(atPath: path, isDirectory: &isDirectory)
    return (fileExists, isDirectory.boolValue)
  }

  static func directoryByteSize(at url: URL) async -> Int64? {
    // declared as static here due to FileManager is not sendable
    return await withCheckedContinuation { continuation in
      DispatchQueue.global(qos: .background).async {
        var totalSize: Int64 = 0

        guard let enumerator = FileManager.default.enumerator(
          at: url,
          includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey]
        ) else {
          continuation.resume(with: .success(nil))
          return
        }

        let allItems = Array(enumerator)

        for case let fileURL as URL in allItems {
          guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]) else {
            continue
          }
          if resourceValues.isRegularFile == true {
            totalSize += Int64(resourceValues.fileSize ?? 0)
          }
        }

        continuation.resume(with: .success(totalSize))
      }
    }
  }

}
