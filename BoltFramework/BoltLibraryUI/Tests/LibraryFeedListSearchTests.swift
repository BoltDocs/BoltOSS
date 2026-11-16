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
// Created by Ethan Wong on 2026/11/16.

import Combine
import Testing
import UIKit

@testable import BoltLibraryUI
import BoltServices

@MainActor
struct LibraryFeedListSearchTests {

  private let model = TestFeedListViewModel()

  nonisolated private static let searchCases: [(searchText: String, expectedFeedIDs: [String])] = [
    ("aCtIoNsCrIpT", ["ActionScript"]),
    ("ADOBE FLASH", ["ActionScript"]),
    ("adobe flash", ["ActionScript"]),
    ("adobe  flash", []),
    ("  adobe flash  ", ["ActionScript"]),
    ("flash as3", []),
  ]

  @Test(arguments: searchCases) func filtersFeeds(searchText: String, expectedFeedIDs: [String]) {
    let results = model.filteredFeeds(searchText: searchText)
    #expect(results.map { $0.id } == expectedFeedIDs)
  }

}

private final class TestFeedListViewModel: LibraryFeedListViewModel {

  static let title = ""
  static let emptyStateImage = UIImage()
  static let allowsRefresh = false
  static let userGuide: LibraryFeedListUserGuide? = nil

  var feeds: [Feed] = [
    StubFeed(
      repository: .main,
      id: "ActionScript",
      displayName: "ActionScript",
      aliases: ["adobe flash", "as3"],
      author: nil,
      shouldHideVersions: false,
      supportsArchiveIndex: false,
      icon: .providerDefault
    ),
  ]

  @MainActor
  func refreshFeeds() {}

}
