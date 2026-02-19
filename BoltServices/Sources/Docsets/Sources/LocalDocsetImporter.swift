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

import BoltUtils

import Factory

public extension Container {

  var localDocsetImporter: Factory<LocalDocsetImporter> { self { LocalDocsetImporterImp() }.cached }

}

public protocol LocalDocsetImporter {

  func importLocalDocsetFile(withURL url: URL) throws

}

final class LocalDocsetImporterImp: LocalDocsetImporter, LoggerProvider {

  func importLocalDocsetFile(withURL url: URL) throws {
    guard url.startAccessingSecurityScopedResource() else {
      return
    }

    defer {
      url.stopAccessingSecurityScopedResource()
    }

    let fileManager = FileManager.default

    let (exists, isDirectory) = fileManager.fileExistsAndIsDirectory(atPath: url.path(percentEncoded: false))

    guard exists && isDirectory && url.pathExtension.lowercased() == "docset" else {
      Self.logger.error("importLocalDocsetFile(withURL:): skipping invalid docset at URL: \(url)")
      return
    }

    let destDirectory = LocalFileSystem.applicationDocumentsURL
    let destURL = fileManager.nextAvailableFileName(
      for: url.lastPathComponent,
      in: destDirectory
    )

    try fileManager.copyItem(at: url, to: destURL)
  }

}
