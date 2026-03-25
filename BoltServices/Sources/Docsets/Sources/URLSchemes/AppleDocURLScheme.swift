//
// Copyright (C) 2026 Bolt Contributors
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

import BoltURLSchemes

public struct AppleDocURLScheme: URLScheme {

  public var docsetUUID: String
  public var docsetFileName: String
  public var path: String
  public var hash: String?

  public static var scheme = "bolt-apple-doc"

  public var url: URL? {
    var components = URLComponents()
    components.scheme = Self.scheme
    components.host = docsetUUID

    var componentsPath = path
    if !componentsPath.isEmpty, !componentsPath.starts(with: "/") {
      componentsPath = "/" + componentsPath
    }

    components.path = componentsPath
    components.fragment = hash

    return components.url
  }

  public init(
    docsetUUID: String,
    path: String,
    hash: String? = nil
  ) {
    self.docsetUUID = docsetUUID
    self.docsetFileName = ""
    self.path = path
    self.hash = hash
  }

  public init?(url: URL) {
    // bolt-apple-doc://UUID/path#anchor
    guard
      let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
      components.scheme == Self.scheme,
      !components.path.isEmpty,
      let id = components.host,
      let docsetFileName = LibraryDocsetsFileSystemBridge.docsetFileName(forInstallationId: id)
    else {
      return nil
    }

    self.docsetUUID = id
    self.docsetFileName = docsetFileName

    self.path = components.path
    self.hash = components.fragment
  }

  public init?(urlString: String) {
    guard let url = URL(string: urlString) else {
      return nil
    }
    self.init(url: url)
  }

}
