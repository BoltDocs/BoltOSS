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

import Factory
import RxCocoa
import RxSwift

import BoltServices
import BoltUIFoundation
import RoutableNavigation

final class LookupAllEntriesViewModel: LookupListViewModel {

  @LazyInjected(\.searchService)
  private var searchService: SearchService

  let itemSelected = PublishRelay<LookupListCellItem>()

  private let _results = BehaviorRelay<Result<[LookupListCellItem], Error>>(value: .success([]))
  var results: Driver<Result<[LookupListCellItem], Error>> {
    return _results.asDriver()
  }

  private let _title = BehaviorRelay<String>(value: "")
  var title: Driver<String> {
    return _title.asDriver()
  }

  private let _hasSearchConstraints = BehaviorRelay<Bool>(value: false)
  var hasSearchConstraints: Driver<Bool> {
    return _hasSearchConstraints.asDriver()
  }

  private let _showsLoadingIndicator = BehaviorRelay<Bool>(value: false)
  var showsLoadingIndicator: Driver<Bool> {
    return _showsLoadingIndicator.asDriver()
  }

  private weak var routingState: LookupRoutingState!

  private let docset: Docset

  private let activityIndicator = ActivityIndicator()
  private let disposeBag = DisposeBag()

  init(routingState: LookupRoutingState, docset: Docset) {
    self.routingState = routingState
    self.docset = docset
    setupObservations()
  }

  private func setupObservations() {
    itemSelected
      .asSignal()
      .emit(with: routingState) { routingState, item in
        if let item = item as? LookupListTypeItem, let type = item.typeCountPair.type {
          routingState.routingCoordinator.push(
            LookupRouteElement(
              type: .types(docset: item.docset, type: type)
            )
          )
        } else if let item = item as? LookupListEntryItem {
          routingState.selectEntry(docset: item.docset, entry: item.entry)
        }
      }
      .disposed(by: disposeBag)

    Observable.just(docset.displayName)
      .bind(to: _title)
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
      routingState.searchQuery.asObservable(),
      routingState.presentsLookupListDriver.asObservable()
    )
    .filter { _, presentsLookupList in
      return presentsLookupList
    }
    .flatMapLatest { [docset, searchService, activityIndicator] queryString, _ -> Observable<Result<[LookupListCellItem], Error>> in
      if queryString.isEmpty {
        return Single<[TypeCountPair]>.create {
          let docsetSearchIndex = await searchService.searchIndex(forDocset: docset)
          return try await docsetSearchIndex.fetchTypeList()
        }
        .map { types -> [LookupListTypeItem] in
          return types.map { type in
            return LookupListTypeItem(typeCountPair: type, docset: docset)
          }
        }
        .asObservable()
        .mapToResult()
        .trackActivity(activityIndicator)
      } else {
        return Single<[Entry]>.create {
          let docsetSearchIndex = await searchService.searchIndex(forDocset: docset)
          return try await docsetSearchIndex.fetchEntries(forQuery: queryString, type: nil)
        }
        .map { entries -> [LookupListEntryItem] in
          return entries.map { entry in
            return LookupListEntryItem(docset: docset, entry: entry)
          }
        }
        .asObservable()
        .mapToResult()
        .trackActivity(activityIndicator)
      }
    }
    .startWith(.success([]))
    .bind(to: _results)
    .disposed(by: disposeBag)
  }

  func onClickCancel() {
    routingState.dismissSearch()
  }

}
