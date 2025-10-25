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
import XCTest

import BoltSearch
import BoltTestingUtils
import BoltTypes
import BoltUtils

import Factory

@testable import BoltDocsets

final class LibraryDocsetsManagerTests: XCTestCase {

  @LazyInjected(\.libraryDocsetsManager)
  private var libraryDocsetsManager: LibraryDocsetsManager

  override func setUpWithError() throws {
    try super.setUpWithError()

    Container.shared.docsetsModuleInitializer()()
    Container.shared.searchModuleInitializer()()

    try FileManager.default.createDirectory(atPath: LocalFileSystem.downloadsAbsolutePath, withIntermediateDirectories: true)
  }

  override func tearDownWithError() throws {
    try super.tearDownWithError()
    try FileManager.default.removeItem(atPath: LocalFileSystem.downloadsAbsolutePath)
  }

  func testInstallDocsetWithoutTarix() async throws {
    let fileManager = FileManager.default

    let downloadsPath = LocalFileSystem.downloadsAbsolutePath

    try fileManager.copyItem(
      atPath: Bundle.module.path(forResource: "TestResources/Vim.tgz")!,
      toPath: downloadsPath.appendingPathComponent("Vim-9.0-main.tgz")
    )

    let _ = try await awaitPublisher(
      libraryDocsetsManager.installOrUpdateDocset(
        forEntry: FeedEntry(
          feed: StubFeed(
            repository: .main,
            id: "Vim",
            displayName: "Vim",
            aliases: [],
            shouldHideVersions: false,
            supportsArchiveIndex: false,
            icon: EntryIcon.bundled(.docsetIcon(.vim))
          ),
          version: "9.0",
          isTrackedAsLatest: false,
          isDocsetBundle: false,
          docsetLocation: ResourceLocations.stubbed
        ),
        usingTarix: false
      )
    )

    XCTAssert(fileManager.fileExists(atPath: downloadsPath))
    XCTAssert(!(try fileManager.contentsOfDirectory(atPath: downloadsPath)).contains("Vim-9.0-main.tgz"))
  }

  func testInstallDocsetWithTarix() async throws {
    let fileManager = FileManager.default

    let downloadsPath = LocalFileSystem.downloadsAbsolutePath

    try fileManager.copyItem(
      atPath: Bundle.module.path(forResource: "TestResources/Vim.tgz")!,
      toPath: downloadsPath.appendingPathComponent("Vim-9.0-main.tgz")
    )

    try fileManager.copyItem(
      atPath: Bundle.module.path(forResource: "TestResources/Vim.tgz.tarix")!,
      toPath: downloadsPath.appendingPathComponent("Vim-9.0-main.tgz.tarix")
    )

    let _ = try await awaitPublisher(
      libraryDocsetsManager.installOrUpdateDocset(
        forEntry: FeedEntry(
          feed: StubFeed(
            repository: .main,
            id: "Vim",
            displayName: "Vim",
            aliases: [],
            shouldHideVersions: false,
            supportsArchiveIndex: false,
            icon: EntryIcon.bundled(.docsetIcon(.vim))
          ),
          version: "9.0",
          isTrackedAsLatest: false,
          isDocsetBundle: false,
          docsetLocation: ResourceLocations.stubbed
        ),
        usingTarix: true
      )
    )

    XCTAssert(fileManager.fileExists(atPath: downloadsPath))

    let downloadsPathContents = try fileManager.contentsOfDirectory(atPath: downloadsPath)
    XCTAssertFalse(downloadsPathContents.contains("Vim-9.0-main.tgz"))
    XCTAssertFalse(downloadsPathContents.contains("Vim-9.0-main.tgz.tarix"))
  }

  func testUpdateExistingDocset() async throws {
    try await installDocsetTrackedAsLatest(version: "/8")

    try await Task.sleep(for: .milliseconds(1000))

    let docsetsBeforeUpdate = libraryDocsetsManager.installedDocsets.filter { result in
      result.record.name == "Bash"
    }
    XCTAssertEqual(docsetsBeforeUpdate.count, 1)
    XCTAssertEqual(docsetsBeforeUpdate.first?.record.version, "/8")

    try await installDocsetTrackedAsLatest(version: "/9")

    try await Task.sleep(for: .milliseconds(1000))

    let docsetsAfterUpdate = libraryDocsetsManager.installedDocsets.filter { result in
      result.record.name == "Bash"
    }

    XCTAssertEqual(docsetsAfterUpdate.count, 1)
    XCTAssertEqual(docsetsAfterUpdate.first?.record.version, "/9")
  }

  private func installDocsetTrackedAsLatest(version: String) async throws {
    let fileManager = FileManager.default
    let downloadsPath = LocalFileSystem.downloadsAbsolutePath

    let identifier = "Bash-\(version.replacingOccurrences(of: "/", with: "_"))-latest-main"

    try fileManager.copyItem(
      atPath: try XCTUnwrap(Bundle.module.path(forResource: "TestResources/Bash.tgz")),
      toPath: downloadsPath.appendingPathComponent("\(identifier).tgz")
    )

    try fileManager.copyItem(
      atPath: try XCTUnwrap(Bundle.module.path(forResource: "TestResources/Bash.tgz.tarix")),
      toPath: downloadsPath.appendingPathComponent("\(identifier).tgz.tarix")
    )

    let _ = try await awaitPublisher(
      libraryDocsetsManager.installOrUpdateDocset(
        forEntry: FeedEntry(
          feed: StubFeed(
            repository: .main,
            id: "Bash",
            displayName: "Bash",
            aliases: [],
            shouldHideVersions: true,
            supportsArchiveIndex: true,
            icon: EntryIcon.bundled(.docsetIcon(.bash))
          ),
          version: version,
          isTrackedAsLatest: true,
          isDocsetBundle: false,
          docsetLocation: ResourceLocations.stubbed
        ),
        usingTarix: true
      )
    )
  }

}
