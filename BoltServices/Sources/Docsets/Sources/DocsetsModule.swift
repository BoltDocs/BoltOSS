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

import Factory

import BoltTypes
import BoltUtils

private struct DocsetsModule {

  private static let logger = Loggers.forCategory("BoltServices")

  fileprivate static func setupLocalStorage() {
    logger.info("Library path: \(LocalFileSystem.applicationLibraryAbsolutePath)")
    LibraryDocsetsFileSystemBridge.setupDocsetsDirectory()
  }

}

public extension Container {

  private static var initialize: PerformOnce = {
    DocsetsModule.setupLocalStorage()
    let _ = Container.shared.downloadManager()
    return {}
  }()

  var docsetsModuleInitializer: Factory<() -> Void> {
    return self { {
      Self.initialize()
      // swiftlint:disable:next closure_end_indentation
    } }
  }

}
