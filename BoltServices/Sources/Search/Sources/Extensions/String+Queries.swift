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

extension String {

  func makeQueryPerfect() -> String {
    // ASCII tokenization, quoting with '`'
    var res = ""
    for chr in self {
      if chr.isWhitespace {
        continue
      }
      if let ascii = chr.asciiValue {
        // only ASCII values are accepted
        if (ascii >= 97 && ascii <= 122) || (ascii >= 48 && ascii <= 57) {
          res.append(chr)
        } else if ascii >= 65 && ascii <= 90 {
          res.append(Character(UnicodeScalar(UInt8(ascii) + 32)))
        } else {
          res.append("`\(ascii)`")
        }
      }
    }
    return res
  }

  func makeQueryPrefix() -> String {
    if self.isEmpty {
      return ""
    }
    var prefix = self
    prefix.removeLast()
    return prefix.makeQueryPerfect()
  }

  func makeQuerySuffixesString() -> String {
    if self.isEmpty {
      return ""
    }
    var suffix = self
    suffix.removeFirst()
    var res = [String]()
    while !suffix.isEmpty {
      res.append(suffix.makeQueryPerfect())
      suffix.removeFirst()
    }
    return res.joined(separator: " ")
  }

}
