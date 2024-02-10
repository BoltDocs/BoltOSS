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

import RxCocoa
import RxSwift

import BoltServices
import BoltUIFoundation
import RoutableNavigation

final class LookupAllEntriesViewModel: LookupListViewModel {

  let itemSelected = PublishRelay<LookupListCellItem>()

  private let _results = BehaviorRelay<[LookupListCellItem]>(value: [])
  var results: Driver<[LookupListCellItem]> {
    return _results.asDriver()
  }

  private let _title = BehaviorRelay<String>(value: "")
  var title: Driver<String> {
    return _title.asDriver()
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

    activityIndicator
      .asObservable()
      .bind(to: _showsLoadingIndicator)
      .disposed(by: disposeBag)

    routingState.searchQuery
      .flatMapLatest { queryString -> Observable<[LookupListCellItem]> in
        if queryString.isEmpty {
          return Single<[TypeCountPair]>.create {
            return try await DocsetSearcher.typeList(forDocset: self.docset)
          }
          .map { types -> [LookupListTypeItem] in
            return types.map { type in
              return LookupListTypeItem(typeCountPair: type, docset: self.docset)
            }
          }
          .trackActivity(self.activityIndicator)
        } else {
          return Single<[TypeCountPair]>.create {
            return try await DocsetSearcher.entries(forDocset: self.docset, rawQuery: queryString, type: nil)
          }
          .map { entries -> [LookupListEntryItem] in
            return entries.map { entry in
              return LookupListEntryItem(docset: self.docset, entry: entry)
            }
          }
          .trackActivity(self.activityIndicator)
        }
      }
      .startWith([])
      .bind(to: _results)
      .disposed(by: disposeBag)
  }

}
