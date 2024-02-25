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

import Alamofire
import Factory

import BoltServices
import BoltUtils

struct CacheCleaner: LoggerProvider {

  static func clearCache() async {
    try? FileManager.default.removeItem(atPath: LocalFileSystem.downloadsAbsolutePath)
    await Container.shared.downloadManager().clearCache()
    await AF.session.stopAllTasks()
    await AF.session.reset()
  }

  static func removeAllFiles(completionHandler: (() -> Void)?) {
    let directoriesToClear = [
      LocalFileSystem.documentsAbsolutePath,
      LocalFileSystem.libraryAbsolutePath,
      LocalFileSystem.tempAbsolutePath,
    ]
    directoriesToClear.forEach { directory in
      if let files = try? FileManager.default.contentsOfDirectory(atPath: directory) {
        for file in files {
          do {
            let path = directory.appendingPathComponent(file)
            try FileManager.default.removeItem(atPath: path)
          } catch {
            Self.logger.error("removeAllFiles(_:) failed with error: \(error.localizedDescription)")
          }
        }
      }
    }
    completionHandler?()
  }

}
