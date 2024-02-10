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

import BoltTypes
import BoltURLSchemes

public struct DocsetFileURLScheme: URLScheme {

  public var docsetUUID: String
  public var docsetFileName: String
  public var path: String

  public static var scheme = "bolt-doc-file"

  public var url: URL? {
    return URL(string: "\(Self.scheme)://\(docsetUUID)/\(path)")
  }

  public init?(docsetUUID: String, path: String) {
    self.docsetUUID = docsetUUID
    self.docsetFileName = ""
    self.path = path
  }

  public init?(url: URL) {
    // bolt-tarix://UUID/xxxxxx.html
    guard
      let scheme = url.scheme,
      scheme == Self.scheme,
      let id = url.host,
      let docsetFileName = LibraryDocsetsFileSystemBridge.docsetFileName(forInstallationId: id)
    else {
      return nil
    }

    self.docsetUUID = id
    self.docsetFileName = docsetFileName
    self.path = url.path
  }

  public init?(urlString: String) {
    guard let url = URL(string: urlString) else {
      return nil
    }
    self.init(url: url)
  }

}
