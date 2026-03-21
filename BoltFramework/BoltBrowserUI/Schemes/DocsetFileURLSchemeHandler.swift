//
// Copyright (C) 2023 Bolt Contributors
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

import BoltArchives
import BoltServices
import BoltUtils

// - SeeAlso: https://stackoverflow.com/questions/69216563/how-to-enable-wkurlschemehandler-to-do-work-off-main-thread

public class TarixURLSchemeHandler: BaseURLSchemeHandler<DocsetFileURLScheme> {

  static let queue = DispatchQueue(label: "app.BoltDocs.Bolt.TarixURLSchemeHandler", qos: .userInitiated)

  override public func parseScheme(fromURL url: URL) -> DocsetFileURLScheme? {
    guard url.scheme == DocsetFileURLScheme.scheme else {
      return nil
    }
    return DocsetFileURLScheme(url: url)
  }

  override public func load(forURL url: URL, scheme: DocsetFileURLScheme) async -> (URLResponse, Data)? {
    let mimeType = url.mimeType() ?? "text/html"
    let response = URLResponse(
      url: url,
      mimeType: mimeType,
      expectedContentLength: -1,
      textEncodingName: nil
    )
    if let data = await Self.loadTarix(fromScheme: scheme) {
      return (response, data)
    } else if let data = Self.loadFile(fromScheme: scheme) {
      return (response, data)
    }
    return nil
  }

}

private extension TarixURLSchemeHandler {

  nonisolated static func loadTarix(fromScheme scheme: DocsetFileURLScheme) async -> Data? {
    let docsetPath = LocalFileSystem.docsetsAbsolutePath
      .appendingPathComponent(scheme.docsetUUID)
      .appendingPathComponent(scheme.docsetFileName)

    let tarFilePath = docsetPath.appendingPathComponent("/Contents/Resources/tarix.tgz")
    let tarixDBPath = docsetPath.appendingPathComponent("/Contents/Resources/tarixIndex.db")

    if !FileManager.default.fileExists(atPath: tarFilePath) {
      return nil
    }

    guard let (_, data) = try? await TarixUnarchiver.dataFromIndexedTar(
      tarFilePath: tarFilePath,
      tarixDBPath: tarixDBPath,
      atPath: "\(scheme.docsetFileName)/Contents/Resources/Documents\(scheme.path)",
      usingQueue: queue
    ) else {
      return nil
    }

    return data
  }

  nonisolated static func loadFile(fromScheme scheme: DocsetFileURLScheme) -> Data? {
    let docsetPath = LocalFileSystem.docsetsAbsolutePath
      .appendingPathComponent(scheme.docsetUUID)
      .appendingPathComponent(scheme.docsetFileName)
    let filePath = "\(docsetPath)/Contents/Resources/Documents\(scheme.path)"

    guard FileManager.default.fileExists(atPath: filePath) else {
      return nil
    }
    return try? Data(contentsOf: URL(fileURLWithPath: filePath))
  }

}
