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

import Factory

public protocol DocPageURLConverter: AnyObject {

  func url(forPagePath pagePath: String, docsetUUID uuidString: String) -> URL?

  func pagePath(forURL url: URL) -> String?

}

public extension Container {

  var docPageURLConverter: Factory<DocPageURLConverter> { self { DocPageURLConverterImp() }.cached }

}

final class DocPageURLConverterImp: DocPageURLConverter {

  func url(forPagePath pagePath: String, docsetUUID uuidString: String) -> URL? {
    if let url = URL(string: pagePath), let scheme = url.scheme, !scheme.isEmpty {
      if
        let dashAppleAPIScheme = DashAppleAPIURLScheme(url: url),
        let docPath = dashAppleAPIScheme.docPath,
        !docPath.isEmpty
      {
        return AppleDocURLScheme(
          docsetUUID: uuidString,
          path: docPath,
          hash: dashAppleAPIScheme.hash
        ).url
      }
      return url
    } else if let docsetFileURL = DocsetFileURLScheme(docsetUUID: uuidString, path: pagePath).url {
      return docsetFileURL
    }
    return nil
  }

  func pagePath(forURL url: URL) -> String? {
    // FIXME: properly handle hash and queries and add related tests
    if let docsetFileScheme = DocsetFileURLScheme(url: url) {
      return docsetFileScheme.path
    } else if let appleDocScheme = AppleDocURLScheme(url: url) {
      return appleDocScheme.path
    }
    return nil
  }

}
