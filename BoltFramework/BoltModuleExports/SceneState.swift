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

public enum SceneAction {

  case lookupListVisibilityChange(_: Bool)
  case updateCurrentScope(_: LookupScope)
  case updateCurrentURL(_: URL)

  case onHomeViewTapMenuItemLibrary
  case onHomeViewTapMenuItemPreferences
  case onHomeViewTapMenuItemDownloads

}

public class SceneState: HasDisposeBag {

  private let _onPresentLibrary = PublishRelay<Void>()
  public lazy var onPresentLibrary: Signal<Void> = {
    return _onPresentLibrary.asSignal()
  }()

  private let _onPresentPreferences = PublishRelay<Void>()
  public lazy var onPresentPreferences: Signal<Void> = {
    return _onPresentPreferences.asSignal()
  }()

  private let _onPresentDownloads = PublishRelay<Void>()
  public lazy var onPresentDownloads: Signal<Void> = {
    return _onPresentDownloads.asSignal()
  }()

  private let _lookupListVisible = BehaviorRelay<Bool>(value: false)
  public lazy var lookupListVisible: Driver<Bool> = {
    return _lookupListVisible.asDriver()
  }()

  private let _currentScope = BehaviorRelay<LookupScope?>(value: nil)
  public lazy var currentScope: Driver<LookupScope?> = {
    return _currentScope.asDriver()
  }()

  private let _currentPageURL = PublishRelay<URL>()
  public lazy var currentPageURL: Signal<URL> = {
    return _currentPageURL.asSignal()
  }()

  private let _currentOnlinePageURL = PublishRelay<URL?>()
  public lazy var currentOnlinePageURL: Signal<URL?> = {
    return _currentOnlinePageURL.asSignal()
  }()

  public let actions = PublishRelay<SceneAction>()

  public func dispatch(action: SceneAction) {
    switch action {
    case let .lookupListVisibilityChange(visibility):
      _lookupListVisible.accept(visibility)
    case let .updateCurrentScope(scope):
      _currentScope.accept(scope)
    case let .updateCurrentURL(url):
      _currentPageURL.accept(url)
    case .onHomeViewTapMenuItemLibrary:
      _onPresentLibrary.accept(())
    case .onHomeViewTapMenuItemPreferences:
      _onPresentPreferences.accept(())
    case .onHomeViewTapMenuItemDownloads:
      _onPresentDownloads.accept(())
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
