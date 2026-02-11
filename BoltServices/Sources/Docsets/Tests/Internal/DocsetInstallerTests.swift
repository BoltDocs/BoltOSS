//
// Copyright (C) 2025 Bolt Contributors
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

import XCTest

import BoltTypes
import BoltUtils

@testable import BoltDocsets

// swiftlint:disable:next balanced_xctest_lifecycle
final class DocsetInstallerTests: XCTestCase {

  override func setUp() {
    super.setUp()
    try? FileManager.default.createDirectory(at: LocalFileSystem.downloadsURL, withIntermediateDirectories: true)
    try? FileManager.default.createDirectory(at: LocalFileSystem.docsetsURL, withIntermediateDirectories: true)
  }

  func testInstallDocset_removesWALFiles() async throws {
    let fileManager = FileManager.default

    let downloadsPath = LocalFileSystem.downloadsAbsolutePath

    try fileManager.copyItem(
      atPath: Bundle.module.path(forResource: "TestResources/Flask.tgz")!,
      toPath: downloadsPath.appendingPathComponent("Flask-3.1.0-main.tgz")
    )

    let docsetsPathContentsBefore = Set(
      try fileManager.contentsOfDirectory(
        atPath: LocalFileSystem.docsetsAbsolutePath
      )
    )

    let _ = try await awaitPublisher(
      DocsetInstaller.shared.installDocset(
        forEntry: FeedEntry(
          feed: StubFeed(
            repository: .main,
            id: "Flask",
            displayName: "Flask",
            aliases: [],
            author: nil,
            shouldHideVersions: false,
            supportsArchiveIndex: false,
            icon: EntryIcon.bundled(.docsetIcon(.flask))
          ),
          version: "3.1.0",
          isTrackedAsLatest: false,
          isDocsetBundle: false,
          docsetLocation: ResourceLocations.stubbed
        ),
        usingTarix: false
      )
    )

    let docsetsPathContentsAfter = Set(
      try fileManager.contentsOfDirectory(
        atPath: LocalFileSystem.docsetsAbsolutePath
      )
    )

    let newDocsetPath = docsetsPathContentsAfter.subtracting(docsetsPathContentsBefore)

    XCTAssertEqual(newDocsetPath.count, 1)

    let resourcesPath = LocalFileSystem.docsetsAbsolutePath
      .appendingPathComponent(newDocsetPath.first!)
      .appendingPathComponent("Flask.docset/Contents/Resources")

    XCTAssert(fileManager.fileExists(atPath: resourcesPath.appendingPathComponent("docSet.dsidx"), isDirectory: nil))
    XCTAssert(!fileManager.fileExists(atPath: resourcesPath.appendingPathComponent("docSet.dsidx-wal"), isDirectory: nil))
    XCTAssert(!fileManager.fileExists(atPath: resourcesPath.appendingPathComponent("docSet.dsidx-shm"), isDirectory: nil))
  }

}
