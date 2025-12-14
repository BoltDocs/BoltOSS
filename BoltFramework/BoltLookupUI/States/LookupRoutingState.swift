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

  init(sceneState: SceneState) {
    self.sceneState = sceneState

    sceneState.currentScope
      .drive(with: self) { owner, _ in
        owner.sceneState.dispatch(action: .updateLookupListShowsDocPage(false))
      }
      .disposed(by: disposeBag)

    searchQuery
      .filter { _ in sceneState.lookupListShowsDocPageValue == true }
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

  private let searchQueryRelay = BehaviorRelay<String>(value: "")
  lazy var searchQuery: Driver<String> = { searchQueryRelay.asDriver() }()

  lazy var presentsLookupListDriver: Driver<Bool> = {
    return sceneState.lookupListShowsDocPage
      .map(!)
  }()
  var presentsLookupList: Bool { !(sceneState.lookupListShowsDocPageValue) }

  private let clearSearchTextSubject = PublishSubject<Void>()
  lazy var clearSearchText: Signal<Void> = { clearSearchTextSubject.asSignalOnErrorJustIgnore() }()

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

    let pageTokens = sceneState.lookupListShowsDocPage
      .map { showsDocumentationPage -> [UISearchToken] in
        if showsDocumentationPage {
          let tokenImage = UIImage(systemName: "doc.text")!
            .withTintColor(UIColor.white)
          return [UISearchToken.imageOnlyToken(withImage: tokenImage)]
        } else {
          return []
        }
      }

    return Driver.combineLatest(routeTokens, pageTokens)
      .map { val1, val2 in
        return val1 + val2
      }
  }()

  // MARK: - Interfaces

  func changeScope(_ scope: LookupScope) {
    sceneState.dispatch(action: .updateCurrentScope(scope))
  }

  func updateSearchQuery(_ query: String) {
    searchQueryRelay.accept(query)
  }

  func dismissSearch() {
    dismissSearchSubject.onNext(())
  }

  func selectEntry(docset: Docset, entry: Entry) {
    guard let url = docset.url(forPagePath: entry.path) else {
      return
    }

    clearSearchTextSubject.onNext(())

    sceneState.dispatch(action: .updateCurrentURL(url))
    sceneState.dispatch(action: .updateLookupListShowsDocPage(true))
  }

  func deselectEntryOrPop() {
    if sceneState.lookupListShowsDocPageValue {
      sceneState.dispatch(action: .updateLookupListShowsDocPage(false))
    } else {
      routingCoordinator.pop()
    }
  }

  func onChangeSearchActive(_ active: Bool) {
    sceneState.dispatch(action: .lookupListVisibilityChange(active))
  }

}
