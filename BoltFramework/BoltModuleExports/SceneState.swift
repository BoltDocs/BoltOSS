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

import Foundation

import Factory

import BoltRxSwift
import BoltServices
import BoltURLSchemes
import BoltUtils

public extension Container {

  var distributionService: Factory<DistributionService?> { self { nil }.cached }
  var analyticsService: Factory<AnalyticsService?> { self { nil }.cached }
  var crashesService: Factory<CrashesService?> { self { nil }.cached }

}

public protocol DistributionService {

  @MainActor
  func checkForUpdate()

}

public enum LookupScope: Sendable, Hashable {
  case docset(_: Docset)
  case history
  case favorites
}

public enum LookupSearchScope: Equatable {
  case types
  case docPage
  case tableOfContents
}

public enum SceneAction {

  case lookupListVisibilityChange(_: Bool)
  case updateLookupSearchScope(_: LookupSearchScope)
  case updateCurrentScope(_: LookupScope)
  case updateDocPageCurrentURL(_: URL?)
  case updateLookupSceneTitle(_: String)
  case docPageLoadURL(_: URL)
  case findInPage(query: String)
  case findPreviousInPage
  case findNextInPage
  case updateFindInPageCurrentIndex(_: Int)
  case updateFindInPageTotalResults(_: Int)

  case onPresentLibrary
  case onPresentPreferences
  case onPresentDownloads
  case onPresentUpdates

}

public class SceneState: HasDisposeBag {

  private let _onPresentLibrary = PublishRelay<Void>()
  public lazy var onPresentLibrary: Signal<Void> = { _onPresentLibrary.asSignal() }()

  private let _onPresentPreferences = PublishRelay<Void>()
  public lazy var onPresentPreferences: Signal<Void> = { _onPresentPreferences.asSignal() }()

  private let _onPresentDownloads = PublishRelay<Void>()
  public lazy var onPresentDownloads: Signal<Void> = { _onPresentDownloads.asSignal() }()

  private let _onPresentDocsetUpdates = PublishRelay<Void>()
  public lazy var onPresentDocsetUpdates: Signal<Void> = {
    return _onPresentDocsetUpdates.asSignal()
  }()

  private let _lookupListVisible = BehaviorRelay<Bool>(value: false)
  public lazy var lookupListVisible: Driver<Bool> = { _lookupListVisible.asDriver() }()

  private let _lookupSearchScope = BehaviorRelay<LookupSearchScope>(value: .types)
  public var lookupSearchScopeValue: LookupSearchScope { _lookupSearchScope.value }
  public lazy var lookupSearchScope: Driver<LookupSearchScope> = { _lookupSearchScope.asDriver() }()

  private let _currentScope = BehaviorRelay<LookupScope?>(value: nil)
  public lazy var currentScope: Driver<LookupScope?> = { _currentScope.asDriver() }()

  private let _docPageCurrentURL = BehaviorRelay<URL?>(value: nil)
  public lazy var docPageCurrentURL: Driver<URL?> = { _docPageCurrentURL.asDriver() }()

  private let _lookupSceneTitle = BehaviorRelay<String>(value: "")
  public lazy var lookupSceneTitle: Driver<String> = { _lookupSceneTitle.asDriver() }()

  private let _docPageLoadURL = PublishRelay<URL>()
  public lazy var docPageLoadURL: Signal<URL> = { _docPageLoadURL.asSignal() }()

  private let _findInPageQuery = PublishRelay<String>()
  public lazy var findInPageQuery: Signal<String> = { _findInPageQuery.asSignal() }()

  private let _findPreviousInPage = PublishRelay<Void>()
  public lazy var findPreviousInPage: Signal<Void> = { _findPreviousInPage.asSignal() }()

  private let _findNextInPage = PublishRelay<Void>()
  public lazy var findNextInPage: Signal<Void> = { _findNextInPage.asSignal() }()

  private let _findInPageCurrentIndex = PublishRelay<Int>()
  public lazy var findInPageCurrentIndex: Signal<Int> = { _findInPageCurrentIndex.asSignal() }()

  private let _findInPageTotalResults = PublishRelay<Int>()
  public lazy var findInPageTotalResults: Signal<Int> = { _findInPageTotalResults.asSignal() }()

  public let actions = PublishRelay<SceneAction>()

  public func dispatch(action: SceneAction) {
    switch action {
    case let .lookupListVisibilityChange(visibility):
      _lookupListVisible.accept(visibility)
    case let .updateLookupSearchScope(value):
      _lookupSearchScope.accept(value)
    case let .updateCurrentScope(scope):
      _currentScope.accept(scope)
    case let .updateDocPageCurrentURL(url):
      _docPageCurrentURL.accept(url)
    case let .updateLookupSceneTitle(title):
      _lookupSceneTitle.accept(title)
    case let .docPageLoadURL(url):
      _docPageLoadURL.accept(url)
    case let .findInPage(query: query):
      _findInPageQuery.accept(query)
    case .findPreviousInPage:
      _findPreviousInPage.accept(())
    case .findNextInPage:
      _findNextInPage.accept(())
    case let .updateFindInPageCurrentIndex(value):
      _findInPageCurrentIndex.accept(value)
    case let .updateFindInPageTotalResults(value):
      _findInPageTotalResults.accept(value)
    case .onPresentLibrary:
      _onPresentLibrary.accept(())
    case .onPresentPreferences:
      _onPresentPreferences.accept(())
    case .onPresentDownloads:
      _onPresentDownloads.accept(())
    case .onPresentUpdates:
      _onPresentDocsetUpdates.accept(())
    }
  }

  public init() {
    actions
      .subscribe(on: MainScheduler.instance)
      .subscribe(with: self) { owner, action in
        owner.dispatch(action: action)
      }
      .disposed(by: disposeBag)
  }

}
