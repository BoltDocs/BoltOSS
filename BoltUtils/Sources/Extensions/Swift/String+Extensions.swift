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

public extension String {

  func appendingPathComponent(_ pathComponent: String) -> String {
    return (self as NSString).appendingPathComponent(pathComponent)
  }

  var deletingLastPathComponent: String {
    return (self as NSString).deletingLastPathComponent
  }

  func appendingPathExtension(_ pathExtension: String) -> String {
    return (self as NSString).appendingPathExtension(pathExtension) ?? self + pathExtension
  }

  var deletingPathExtension: String {
    return (self as NSString).deletingPathExtension
  }

  func replacingPrefix(_ prefix: String, with replacement: String) -> String {
    if hasPrefix(prefix) {
      return replacement + dropFirst(prefix.count)
    } else {
      return self
    }
  }

  func trimmingWhitespacesAndNewLines() -> String {
    return self.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  func localized() -> String {
    return NSLocalizedString(self, comment: "")
  }

  static func pluralRepresentation(forCount pluralCount: Int, singular: String, plural: String) -> String {
    if pluralCount == 0 {
      return "No \(plural)"
    } else if pluralCount == 1 {
      return "\(pluralCount) \(singular)"
    } else {
      return "\(pluralCount) \(plural) "
    }
  }

  func regexMatch(_ regex: String) -> [[String]] {
    let nsString = self as NSString
    return (try? NSRegularExpression(pattern: regex, options: []))?
      .matches(
        in: self,
        options: [],
        range: NSRange(location: 0, length: nsString.length)
      ).map { match in
        return (0..<match.numberOfRanges).map {
          match.range(at: $0).location == NSNotFound ? "" : nsString.substring(with: match.range(at: $0))
        }
      } ?? []
  }

  func isHTTPURL() -> Bool {
    guard let url = URL(string: self) else {
      return false
    }
    return ["http", "https"].contains(url.scheme)
  }

}
