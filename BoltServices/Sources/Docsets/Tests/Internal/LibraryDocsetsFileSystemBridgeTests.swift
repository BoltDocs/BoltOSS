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

@testable import BoltDocsets

import BoltTypes

import Factory

final class LibraryDocsetsFileSystemBridgeTests: XCTestCase {

  @Injected(\.docsetInfoProcessor)
  private var docsetInfoProcessor: DocsetInfoProcessor

  func testResolveDocsetIcon() throws {
    XCTAssertEqual(
      LibraryDocsetsFileSystemBridge._docsetIcon(
        fromDocsetPath: "",
        installation: DocsetInstallation(
          name: "foobar",
          version: "1.0",
          installedAsLatestVersion: false,
          repository: .main
        ),
        docsetInfo: docsetInfoProcessor.docsetInfo(
          forInfoDictionary: [
            DocsetInfoKey.platformFamily.rawValue: "cpp",
          ]
        )
      ),
      EntryIcon.bundled(.docsetIcon(.cpp))
    )

    XCTAssertEqual(
      LibraryDocsetsFileSystemBridge._docsetIcon(
        fromDocsetPath: "",
        installation: DocsetInstallation(
          name: "cpp",
          version: "1.0",
          installedAsLatestVersion: false,
          repository: .main
        ),
        docsetInfo: docsetInfoProcessor.docsetInfo(
          forInfoDictionary: [
            DocsetInfoKey.platformFamily.rawValue: "foobar",
          ]
        )
      ),
      EntryIcon.bundled(.docsetIcon(.cpp))
    )

    let iconURL = try XCTUnwrap(Bundle.module.url(forResource: "TestResources/CustomIcon.docset/icon@2x.png"))
    let iconData = try Data(contentsOf: iconURL)
    XCTAssertEqual(
      LibraryDocsetsFileSystemBridge._docsetIcon(
        fromDocsetPath: Bundle.module.path(forResource: "TestResources/CustomIcon.docset")!,
        installation: DocsetInstallation(
          name: "cpp",
          version: "1.0",
          installedAsLatestVersion: false,
          repository: .main
        ),
        docsetInfo: docsetInfoProcessor.docsetInfo(
          forInfoDictionary: [
            DocsetInfoKey.platformFamily.rawValue: "cpp",
          ]
        )
      ),
      EntryIcon.data(iconData, identifier: iconURL.path())
    )

    XCTAssertEqual(
      LibraryDocsetsFileSystemBridge._docsetIcon(
        fromDocsetPath: "",
        installation: DocsetInstallation(
          name: "foobar",
          version: "1.0",
          installedAsLatestVersion: false,
          repository: .main
        ),
        docsetInfo: docsetInfoProcessor.docsetInfo(
          forInfoDictionary: [
            DocsetInfoKey.platformFamily.rawValue: "Other",
          ]
        )
      ),
      EntryIcon.providerDefault
    )
  }

}
