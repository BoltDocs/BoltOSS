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

import BoltRxSwift
import BoltServices
import BoltUIFoundation
import RoutableNavigation

final class LookupTypeFilteringViewModel: LookupListViewModel {

  let itemSelected = PublishRelay<LookupListCellItem>()

  private let _results = BehaviorRelay<Result<[LookupListCellItem], Error>>(value: .success([]))
  var results: Driver<Result<[LookupListCellItem], Error>> {
    return _results.asDriver()
  }

  private let _title = BehaviorRelay<String>(value: "")
  var title: Driver<String> {
    return _title.asDriver()
  }

  private let _showsLoadingIndicator = BehaviorRelay<Bool>(value: false)
  var showsLoadingIndicator: Driver<Bool> {
    return _showsLoadingIndicator
      .asDriver()
  }

  private weak var routingState: LookupRoutingState!
  private let type: EntryType
  private let docset: Docset

  private let activityIndicator = ActivityIndicator()
  private let disposeBag = DisposeBag()

  init(routingState: LookupRoutingState, type: EntryType, docset: Docset) {
    self.routingState = routingState
    self.type = type
    self.docset = docset

    itemSelected
      .asSignal()
      .emit(with: routingState) { state, item in
        if let item = item as? LookupListEntryItem {
          state.selectEntry(docset: item.docset, entry: item.entry)
        }
      }
      .disposed(by: disposeBag)

    Observable.just(type.plural)
      .bind(to: _title)
      .disposed(by: disposeBag)

    activityIndicator
      .asObservable()
      .bind(to: _showsLoadingIndicator)
      .disposed(by: disposeBag)

    routingState.searchQuery
      .flatMapLatest { query -> Observable<Result<[LookupListCellItem], Error>> in
        if query.isEmpty {
          return Single<[Entry]>.create {
            return try await DocsetSearcher.allEntries(forDocset: self.docset, type: self.type)
          }
          .map { entries -> [LookupListCellItem] in
            return entries.map { entry in
              return LookupListEntryItem(docset: self.docset, entry: entry)
            }
          }
          .asObservable()
          .mapToResult()
          .trackActivity(self.activityIndicator)
        } else {
          return Single<[Entry]>.create {
            return try await DocsetSearcher.entries(forDocset: self.docset, rawQuery: query, type: self.type)
          }
          .map { entries -> [LookupListCellItem] in
            return entries.map { entry in
              return LookupListEntryItem(docset: self.docset, entry: entry)
            }
          }
          .asObservable()
          .mapToResult()
          .trackActivity(self.activityIndicator)
        }
      }
      .startWith(.success([]))
      .bind(to: _results)
      .disposed(by: disposeBag)
  }

}
