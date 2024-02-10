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

import BoltURLSchemes

public struct DashFeedURLScheme: URLScheme {

  public var feedURL: URL
  public var feedFileName: String {
    return feedURL.pathComponents.last ?? ""
  }

  public static var scheme = "dash-feed"

  public var url: URL? {
    let escapedFeedURL = feedURL.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
    return URL(string: "\(Self.scheme)://\(escapedFeedURL)")
  }

  public init?(feedURLString: String) {
    if let feedURL = URL(string: feedURLString) {
      self.init(feedURL: feedURL)
    } else {
      return nil
    }
  }

  public init?(feedURL: URL) {
    guard
      var feedURLComponents = URLComponents(url: feedURL, resolvingAgainstBaseURL: true),
      feedURLComponents.scheme == "http" || feedURLComponents.scheme == "https"
    else {
      return nil
    }

    feedURLComponents.fragment = nil
    feedURLComponents.query = nil

    if let sensitizedURL = feedURLComponents.url {
      self.feedURL = sensitizedURL
    } else {
      return nil
    }
  }

  public init?(url: URL) {
    // dash-feed://xxxxxxx
    guard
      let scheme = url.scheme,
      scheme == Self.scheme,
      let host = url.host,
      let feedURL = URL(string: host)
    else {
      return nil
    }
    self.init(feedURL: feedURL)
  }

  public init?(urlString: String) {
    guard let url = URL(string: urlString) else {
      return nil
    }
    self.init(url: url)
  }

}
