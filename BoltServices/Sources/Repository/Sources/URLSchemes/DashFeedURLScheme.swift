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
    guard let lastURLComponents = feedURL.deletingPathExtension().pathComponents.last else {
      return ""
    }
    return lastURLComponents
      .trimmingCharacters(in: ["/"])
      .replacingOccurrences(of: "_", with: " ")
  }

  public static var scheme = "dash-feed"

  public var url: URL? {
    let escapedFeedURL = feedURL.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
    return URL(string: "\(Self.scheme)://\(escapedFeedURL)")
  }

  public init?(urlString: String) {
    guard let url = URL(string: urlString) else {
      return nil
    }
    self.init(url: url)
  }

  public init?(url: URL) {
    var feedURL = url
    if let _feedURL = Self.feedURL(fromDashFeedURL: url) {
      feedURL = _feedURL
    }
    self.init(feedURL: feedURL)
  }

  private init?(feedURL: URL) {
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

  private static func feedURL(fromDashFeedURL dashFeedURL: URL) -> URL? {
    // dash-feed://xxxxxxx
    guard
      let scheme = dashFeedURL.scheme,
      scheme == Self.scheme,
      let host = dashFeedURL.host,
      let feedURL = URL(string: host)
    else {
      return nil
    }
    return feedURL
  }

}
