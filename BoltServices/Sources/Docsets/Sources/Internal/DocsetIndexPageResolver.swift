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

import BoltArchives
import BoltTypes

import BoltUtils

import GRDB

protocol DocsetIndexPageResolverPathMatcher {
  func findFirstMatchInPaths(_ paths: [String]) -> String?
}

package struct DocsetIndexPageResolver: LoggerProvider {

  struct PathMatcher: DocsetIndexPageResolverPathMatcher {

    let docsetPath: String

    func findFirstMatchInPaths(_ indexPaths: [String]) -> String? {
      let tarixDBPath = docsetPath.appendingPathComponent("/Contents/Resources/tarixIndex.db")
      guard FileManager.default.fileExists(atPath: tarixDBPath) else {
        logger.log(level: .info, "No tarIndex.db found, fall back to local file match")
        return indexPaths.first {
          let path = docsetPath
            .appendingPathComponent("/Contents/Resources/Documents")
            .appendingPathComponent($0)
          return FileManager.default.fileExists(atPath: path)
        }
      }
      do {
        // FIXME: optimize for filtering speed
        let dbQueue = try DatabaseQueue(path: tarixDBPath)
        return try dbQueue.read { db -> String? in
          for path in indexPaths {
            if let res = try? TarIndex.filter(Column("path").like("%.docset/Contents/Resources/Documents/\(path)")).fetchCount(db), res > 0 {
              return path
            }
          }
          return nil
        }
      } catch {
        logger.log(level: .info, "Index page matching failed with error: \(error)")
        return nil
      }
    }

  }

  private static let indexPathsToMatch = [
    "dash-browse-index.html",
    "prototypejs/index.html",
    "sqlite/index.html",
    "documentation/Cocoa/Reference/Foundation/ObjC_classic/_index.html",
    "documentation/ToolsLanguages/Conceptual/Xcode_User_Guide/000-About_Xcode/about.html",
    "documentation/IDEs/Conceptual/xcode_quick_start/index.html",
    "package-detail.html",
    "docs/reference/packages.html",
    "Arduino/index.html",
    "output/en.cppreference.com/w/cpp.html",
    "output/en/cpp.html",
    "clojure/api-index.html",
    "developer.anscamobile.com/reference/index.html",
    "docs.coronalabs.com/api/index.html",
    "developer.mozilla.org/en/CSS/CSS_Reference.html",
    "developer.mozilla.org/en-US/docs/CSS/CSS_Reference.html",
    "api/overview-summary.html",
    "haskell/index.html",
    "developer.mozilla.org/en/HTML/HTML5.html",
    "developer.mozilla.org/en/JavaScript/Reference.html",
    "developer.mozilla.org/en/JavaScript/Reference.html",
    "www.lua.org/manual/5.2/index.html",
    "www.lua.org/manual/5.1/index.html",
    "www.lua.org/manual/5.3/index.html",
    "nodejs/api/documentation.html",
    "nodejs/api/api/documentation.html",
    "perldoc-html/index-functions-by-cat.html",
    "res/index.html",
    "genindex-all.html",
    "topics/introduction.html",
    "introduction.html",
    "api.rubyonrails.org/files/RDOC_MAIN_rdoc.html",
    "akka/package.html",
    "docs/welcome.html",
    "developer.mozilla.org/en/XSLT/Elements.html",
    "developer.mozilla.org/en/XUL_Reference.html",
    "genindex.html",
    "html/classes.html",
    "html/qtdoc/classes.html",
    "api.jquery.com/index.html",
    "helphelp.html",
    "partials/guide/index.html",
    "elisp/index.html",
    "docs/right-pane.html",
    "doc/man_index.html",
    "docs.go-mono.com/monoroot.html",
    "api/index.html",
    "mongo/genindex.html",
    "HyperSpec/HyperSpec/Front/index.htm",
    "api.jqueryui.com/category/all/index.html",
    "golang.org/ref/index.html",
    "documentation/ToolsLanguages/Conceptual/Xcode_Overview/About_Xcode/about.html",
    "documentation/Cocoa/Reference/Foundation/ObjC_classic/index.html",
    "documentation/ToolsLanguages/Conceptual/Xcode_Overview/index.html",
  ]

  private static let firstIndexPlatforms = [
    "cappuccino",
    "cocos2dx",
    "underscore",
    "backbone",
    "coffee",
    "appledoc",
    "doxy",
    "doxygen",
    "gl2",
    "gl3",
    "gl4",
    "sparrow",
    "cocos2d",
    "codeigniter",
    "django",
    "joomla",
    "symfony",
    "kobold2d",
    "mysql",
    "psql",
    "typo3",
    "twisted",
    "zend",
    "glib",
  ]

  package static func resolveIndexPagePath(
    forPurposedIndexPagePath indexPagePath: String?,
    platformFamily: DocsetInfo.PlatformFamily,
    generatorFamily: String?,
    docsetPath: String
  ) -> String? {
    let matcher = PathMatcher(docsetPath: docsetPath)
    return resolveIndexPagePath(
      forPurposedIndexPagePath: indexPagePath,
      platformFamily: platformFamily,
      generatorFamily: generatorFamily,
      matcher: matcher
    )
  }

  private static func resolveIndexPagePath(
    forPurposedIndexPagePath indexPagePath: String?,
    platformFamily: DocsetInfo.PlatformFamily,
    generatorFamily: String?,
    matcher: DocsetIndexPageResolverPathMatcher
  ) -> String? {
    if let indexPagePath = indexPagePath {
      if indexPagePath.isHTTPURL() {
        return indexPagePath
      }
      if let url = URL(string: indexPagePath) {
        let path = url.path
        if matcher.findFirstMatchInPaths([path]) != nil {
          return indexPagePath
        }
      } else {
        if matcher.findFirstMatchInPaths([indexPagePath]) != nil {
          return indexPagePath
        }
      }
    }
    var matchList = indexPathsToMatch
    if firstIndexPlatforms.contains(platformFamily.rawValue) ||
      (generatorFamily != nil && firstIndexPlatforms.contains(generatorFamily!))
    {
      matchList.insert("index.html", at: 0)
    }
    return matcher.findFirstMatchInPaths(matchList)
  }

}

#if DEBUG

extension DocsetIndexPageResolver {

  static func _resolveIndexPagePath(
    forPurposedIndexPagePath indexPagePath: String?,
    platformFamily: DocsetInfo.PlatformFamily,
    generatorFamily: String?,
    matcher: DocsetIndexPageResolverPathMatcher
  ) -> String? {
    return resolveIndexPagePath(
      forPurposedIndexPagePath: indexPagePath,
      platformFamily: platformFamily,
      generatorFamily: generatorFamily,
      matcher: matcher
    )
  }

}

#endif
