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

public extension Docset {

  func url(forPagePath pagePath: String) -> URL? {
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

  var indexPageURL: URL? {
    // FIXME: resolution result should be cached
    if let path = DocsetIndexPageResolver.resolveIndexPagePath(
      forPurposedIndexPagePath: indexPagePath,
      platformFamily: platformFamily,
      generatorFamily: generatorFamily,
      docsetPath: path
    ) {
      if path.isHTTPURL() {
        return URL(string: path)
      } else {
        return url(forPagePath: path)
      }
    }
    return nil
  }

}
