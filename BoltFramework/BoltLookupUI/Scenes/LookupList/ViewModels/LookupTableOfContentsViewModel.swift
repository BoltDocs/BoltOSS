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

import Foundation

import Factory

import BoltRxSwift
import BoltSearch
import BoltTypes
import BoltUIFoundation
import BoltUtils

final class LookupTableOfContentsViewModel: LookupListViewModel, HasDisposeBag, LoggerProvider {

  @Injected(\.searchService)
  private var searchService: SearchService

  let itemSelected = PublishRelay<LookupListCellItem>()

  private let unfilteredResults = BehaviorRelay<Result<[Entry], Error>>(value: .success([]))

  lazy var results: Driver<Result<[LookupListCellItem], Error>> = {
    Driver.combineLatest(
      unfilteredResults.asDriver(),
      routingState.searchQuery
    )
    .map { [docset] results, searchQuery -> Result<[LookupListCellItem], Error> in
      switch results {
      case let .success(entries):
        let items = entries.filter {
          guard !searchQuery.isEmpty else {
            return true
          }
          return $0.name.contains(searchQuery)
        }
        .map { [docset] entry in
          return LookupListEntryItem(docset: docset, entry: entry)
        }
        return .success(items)
      case let .failure(error):
        return .failure(error)
      }
    }
  }()

  var title: Driver<String> { routingState.sceneTitle }

  private let _hasSearchConstraints = BehaviorRelay<Bool>(value: false)
  lazy var hasSearchConstraints: Driver<Bool> = { _hasSearchConstraints.asDriver() }()

  private let _showsLoadingIndicator = BehaviorRelay<Bool>(value: false)
  lazy var showsLoadingIndicator: Driver<Bool> = { _showsLoadingIndicator.asDriver() }()

  private let routingState: LookupRoutingState

  private let docset: Docset

  private let activityIndicator = ActivityIndicator()

  init(routingState: LookupRoutingState, docset: Docset) {
    self.routingState = routingState
    self.docset = docset
    setupObservations()
  }

  private func setupObservations() {
    itemSelected
      .asSignal()
      .emit(with: routingState) { state, item in
        if let item = item as? LookupListEntryItem {
          state.selectEntry(docset: item.docset, entry: item.entry)
        }
      }
      .disposed(by: disposeBag)

    Driver.combineLatest(
      routingState.searchQuery,
      routingState.searchTokens
    )
    .map { query, tokens in
      return !query.isEmpty || !tokens.isEmpty
    }
    .drive(_hasSearchConstraints)
    .disposed(by: disposeBag)

    activityIndicator
      .asObservable()
      .bind(to: _showsLoadingIndicator)
      .disposed(by: disposeBag)

    Observable.combineLatest(
      routingState.docPageCurrentURL.asObservable(),
      routingState.presentsLookupListDriver.asObservable(),
      routingState.searchScope.asObservable()
    )
    .filter { _, presentsLookupList, searchScope in
      return presentsLookupList && searchScope == .tableOfContents
    }
    .flatMapLatest { [searchService, docset, activityIndicator] currentPageURL, _, _ -> Observable<Result<[Entry], Error>> in
      guard let currentPageURL = currentPageURL else {
        return Observable.just(.success([]))
      }
      return Single<[Entry]>.create {
        var basePath = currentPageURL.relativePath
        if basePath.starts(with: "/") {
          basePath.removeFirst()
        }
        let docsetSearchIndex = await searchService.searchIndex(forDocset: docset)
        let entries = try await docsetSearchIndex.fetchEntries(forBasePath: basePath)
        Self.logger.debug("fetched \(entries.count) entries for basePath: \(basePath)")
        return entries
      }
      .asObservable()
      .mapToResult()
      .trackActivity(activityIndicator)
    }
    .bind(to: unfilteredResults)
    .disposed(by: disposeBag)
  }

  func onClickCancel() {
    routingState.dismissSearch()
  }

}
