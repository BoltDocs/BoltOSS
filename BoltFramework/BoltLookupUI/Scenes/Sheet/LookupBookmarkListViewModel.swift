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
// Created by Ethan Wong on 2026/11/17.
//

import Foundation

import Factory
import RxCombine

import BoltModuleExports
import BoltRxSwift
import BoltServices
import BoltUtils

final class LookupBookmarkListViewModel: HasDisposeBag {

  @Injected(\.libraryDatabase)
  private var libraryDatabase: LibraryDatabase

  private let context: LookupSheetContext

  private var bookmarkActionEnabled: Bool

  private let bookmarksRelay = BehaviorRelay<[Bookmark]>(value: [])
  lazy var bookmarks: Driver<[Bookmark]> = { bookmarksRelay.asDriver() }()
  var bookmarksValue: [Bookmark] { bookmarksRelay.value }

  private let currentPageBookmarkedRelay = BehaviorRelay<Bool>(value: false)
  lazy var currentPageBookmarked: Driver<Bool> = { currentPageBookmarkedRelay.asDriver() }()
  var canToggleBookmark: Bool { bookmarkActionEnabled }

  init(context: LookupSheetContext) {
    self.context = context

    if let page = context.currentPage {
      bookmarkActionEnabled = true
      bookmarks
        .map { bookmarks in bookmarks.contains { $0.path == page.path } }
        .distinctUntilChanged()
        .drive(currentPageBookmarkedRelay)
        .disposed(by: disposeBag)
    } else {
      bookmarkActionEnabled = false
    }

    libraryDatabase.bookmarks(forDocsetID: context.docset.versionIndependentIdentifier)
      .asInfallible()
      .asDriver()
      .drive(bookmarksRelay)
      .disposed(by: disposeBag)
  }

}
