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
import UIKit

import RxCocoa
import RxSwift

import BoltModuleExports
import BoltRxSwift
import BoltServices
import BoltUtils
import RoutableNavigation

public struct LookupRouteElement: RouteElement {

  public enum RoutingType {
    case initial
    case types(docset: Docset, type: EntryType)
    case entries(docset: Docset)
  }

  public let routingType: RoutingType
  public let routeHash: String

  public init(type: RoutingType) {
    self.routingType = type
    self.routeHash = UUID().uuidString
  }

}

final class LookupRoutingState: HasDisposeBag {

  private let sceneState: SceneState
  let routingCoordinator = NavigationRouteCoordinator<LookupRouteElement>()

  private var preservedSearchQuery = ""

  init(sceneState: SceneState) {
    self.sceneState = sceneState

    sceneState.currentScope
      .drive(with: self) { owner, _ in
        owner.clearRoutingState()
      }
      .disposed(by: disposeBag)

    searchQuery
      .filter { _ in sceneState.lookupSearchScopeValue == .docPage }
      .drive(with: self) { owner, query in
        owner.sceneState.dispatch(action: .findInPage(query: query))
      }
      .disposed(by: disposeBag)
  }

  func setupScopeRouting() {
    sceneState.currentScope
      .drive(with: self) { owner, scope in
        switch scope {
        case .none:
          owner.routingCoordinator.changeRoute([LookupRouteElement(type: .initial)])
        case .docset(let docset):
          owner.routingCoordinator.changeRoute([LookupRouteElement(type: .entries(docset: docset))])
        case .history:
          break
        case .favorites:
          break
        }
      }
      .disposed(by: disposeBag)
  }

  var searchScope: Driver<SearchScope> { sceneState.lookupSearchScope }

  var docPageCurrentURL: Driver<URL?> { sceneState.docPageCurrentURL }

  var sceneTitle: Driver<String> { sceneState.lookupSceneTitle }

  private let searchQueryRelay = BehaviorRelay<String>(value: "")
  lazy var searchQuery: Driver<String> = { searchQueryRelay.asDriver() }()

  lazy var presentsLookupListDriver: Driver<Bool> = {
    Driver.combineLatest(
      sceneState.lookupListVisible,
      sceneState.lookupSearchScope
    )
    .map { lookupListVisible, searchScope in
      return lookupListVisible &&
        (searchScope == .types || searchScope == .tableOfContents)
    }
  }()
  var presentsLookupList: Bool { sceneState.lookupSearchScopeValue == .types }

  private let updateSearchTextRelay = PublishRelay<String>()
  lazy var updateSearchText: Signal<String> = { updateSearchTextRelay.asSignal() }()

  private let dismissSearchSubject = PublishSubject<Void>()
  lazy var dismissSearchDriver: Signal<Void> = { dismissSearchSubject.asSignalOnErrorJustIgnore() }()

  lazy var tokenColor: Driver<BoltColorResource?> = {
    return routingCoordinator.currentRoute
      .map { route -> BoltColorResource? in
        guard route.elements.count >= 2 else {
          return nil
        }

        let secondElement = route.elements[1]

        switch secondElement.routingType {
        case .initial:
          return nil
        case .entries:
          return nil
        case let .types(_, type):
          return type.colorResource
        }
      }
      .asDriver()
  }()

  lazy var searchTokens: Driver<[UISearchToken]> = {
    let routeTokens = routingCoordinator.currentRoute
      .map {
        return $0.elements.compactMap { element -> UISearchToken? in
          switch element.routingType {
          case .initial:
            return nil
          case .entries:
            return nil
          case let .types(_, type):
            // images should be manually resized for UISearchToken
            let image = type.iconImage.image.resized(to: CGSize(width: 16, height: 16))
            return UISearchToken(icon: image, text: type.plural)
          }
        }
      }

    let pageTokens = sceneState.lookupSearchScope
      .map { searchScope -> [UISearchToken] in
        switch searchScope {
        case .docPage:
          let tokenImage = UIImage(systemName: "doc.text")!
            .withTintColor(UIColor.white)
          return [UISearchToken.imageOnlyToken(withImage: tokenImage)]
        case .tableOfContents:
          let tokenImage = UIImage(systemName: "list.bullet")!
            .withTintColor(UIColor.white)
          return [UISearchToken.imageOnlyToken(withImage: tokenImage)]
        default:
          return []
        }
      }

    return Driver.combineLatest(routeTokens, pageTokens)
      .map { val1, val2 in
        return val1 + val2
      }
  }()

  // MARK: - Interfaces

  func updateSearchQuery(_ query: String) {
    searchQueryRelay.accept(query)
  }

  func dismissSearch() {
    dismissSearchSubject.onNext(())
  }

  func selectSearchScope(_ searchScope: SearchScope) {
    sceneState.dispatch(action: .updateLookupSearchScope(searchScope))
  }

  func selectEntry(docset: Docset, entry: Entry) {
    guard let url = docset.url(forPagePath: entry.path) else {
      return
    }

    preservedSearchQuery = searchQueryRelay.value
    updateSearchTextRelay.accept("")

    sceneState.dispatch(action: .docPageLoadURL(url))
    sceneState.dispatch(action: .updateLookupSearchScope(.docPage))
  }

  func deselectEntryOrPop() {
    switch sceneState.lookupSearchScopeValue {
    case .types:
      routingCoordinator.pop()
    case .docPage, .tableOfContents:
      sceneState.dispatch(action: .updateLookupSearchScope(.types))
      updateSearchTextRelay.accept(preservedSearchQuery)
      preservedSearchQuery = ""
    }
  }

  func onChangeSearchActive(_ active: Bool) {
    sceneState.dispatch(action: .lookupListVisibilityChange(active))
  }

  // MARK: - Private

  private func clearRoutingState() {
    preservedSearchQuery = ""
    updateSearchTextRelay.accept("")
    dismissSearchSubject.onNext(())
    sceneState.dispatch(action: .lookupListVisibilityChange(false))
    sceneState.dispatch(action: .updateLookupSearchScope(.types))
  }

}
