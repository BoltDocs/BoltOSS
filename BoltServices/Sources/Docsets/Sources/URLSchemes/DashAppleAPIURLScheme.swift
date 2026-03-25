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

public struct DashAppleAPIURLScheme: URLScheme {

  private static let languagePrefixes = ["lc", "ls", "ld"]

  public var requestKey: String?
  public var hash: String?

  public static var scheme = "dash-apple-api"

  public var docPath: String? {
    guard let requestKey = requestKey else {
      return nil
    }
    for prefix in Self.languagePrefixes where requestKey.hasPrefix(prefix) {
      return String(requestKey.dropFirst(prefix.count))
    }
    return requestKey
  }

  public var url: URL? {
    var components = URLComponents()
    components.scheme = Self.scheme
    components.host = "load"
    components.queryItems = [URLQueryItem(name: "request_key", value: requestKey)]
    components.fragment = hash
    return components.url
  }

  public init(requestKey: String, hash: String? = nil) {
    self.requestKey = requestKey
    self.hash = hash
  }

  public init?(url: URL) {
    // dash-apple-api://load?request_key=...#...
    guard
      let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
      components.scheme == Self.scheme,
      components.host == "load"
    else {
      return nil
    }
    // swiftlint:disable:next trailing_closure
    self.requestKey = components.queryItems?.first(where: { $0.name == "request_key" })?.value
    self.hash = components.fragment
  }

  public init?(urlString: String) {
    guard let url = URL(string: urlString) else {
      return nil
    }
    self.init(url: url)
  }

}
