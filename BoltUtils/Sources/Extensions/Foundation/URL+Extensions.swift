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

public extension URL {

  var pathExtensions: [String] {
    var tmpURL = self
    var res = [String]()
    while tmpURL.deletingPathExtension() != tmpURL {
      res.append(tmpURL.pathExtension)
      tmpURL.deletePathExtension()
    }
    return res.reversed()
  }

  static var blank: URL {
    return URL(string: "about:blank")!
  }

  var isBlank: Bool {
    return absoluteString.isEmpty || absoluteString == "about:blank"
  }

}
