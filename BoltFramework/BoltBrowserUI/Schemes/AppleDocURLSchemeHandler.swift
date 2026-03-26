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
import WebKit

import IssueReporting

import BoltDocsets
import BoltURLSchemes
import BoltUtils

public class AppleDocURLSchemeHandler: BaseURLSchemeHandler<AppleDocURLScheme>, LoggerProvider {

  private let renderAssetsPath: String? = {
    let path = Bundle.module.resourcePath?.appendingPathComponent("Assets/swift-docc-render")
    if path == nil || FileManager.default.fileExistsAndIsDirectory(atPath: path!).1 != true {
      reportIssue("AppleDocURLSchemeHandler: renderAssetsPath does not exist: \(path, default: "nil")")
      return nil
    }
    return path
  }()

  override public func parseScheme(fromURL url: URL) -> AppleDocURLScheme? {
    guard url.scheme == AppleDocURLScheme.scheme else {
      return nil
    }
    return AppleDocURLScheme(url: url)
  }

  override public func load(forURL url: URL, scheme: AppleDocURLScheme) async -> (URLResponse, Data)? {
    let path = scheme.path

    if !path.isEmpty, path != "/" {
      if let data = fileDataForRenderAsset(atPath: path) {
        let response = URLResponse(
          url: url,
          mimeType: url.mimeType(),
          expectedContentLength: -1,
          textEncodingName: nil
        )
        Self.logger.debug("AppleDocURLSchemeHandler: serving file for path: \(path)")
        return (response, data)
      }
    }

    do {
      // FIXME: add support for switching source language
      if let documentationData = try await AppleAPIDocumentationLoader.loadAppleDocumentationContent(
        scheme: scheme,
        language: .swift
      ) {
        let response = URLResponse(
          url: url,
          mimeType: url.mimeType(),
          expectedContentLength: -1,
          textEncodingName: nil
        )
        return (response, documentationData)
      }
    } catch {
      Self.logger.error("AppleDocURLSchemeHandler: failed to load content from scheme: \(scheme), error: \(error)")
    }

    guard let indexPageData = fileDataForRenderAsset(atPath: "index.html") else {
      reportIssue("AppleDocURLSchemeHandler: render index page not found")
      return nil
    }

    Self.logger.debug("AppleDocURLSchemeHandler: serving index.html for path: \(path)")

    let response = URLResponse(
      url: url,
      mimeType: "text/html",
      expectedContentLength: -1,
      textEncodingName: nil
    )
    return (response, indexPageData)
  }

  private func fileDataForRenderAsset(atPath path: String) -> Data? {
    guard let renderAssetsPath = renderAssetsPath else {
      return nil
    }

    let filePath = renderAssetsPath.appendingPathComponent(path).standardizingPath

    guard filePath.hasPrefix(renderAssetsPath) else {
      return nil
    }

    if FileManager.default.fileExists(atPath: filePath) {
      return try? Data(contentsOf: URL(filePath: filePath))
    }

    return nil
  }

}
