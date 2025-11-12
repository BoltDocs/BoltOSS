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

import UIKit

import BoltBrowserUI
import BoltModuleExports
import BoltRxSwift
import BoltUIFoundation

import Overture
import SnapKit

public final class LookupContentViewController: UIViewController, HasDisposeBag {

  private let sceneState: SceneState

  private let browserViewController: BrowserViewController

  private var toolbarManager: ToolbarManager!

  public init(sceneState: SceneState) {
    self.sceneState = sceneState
    browserViewController = BrowserViewController(sceneState: sceneState)
    super.init(nibName: nil, bundle: nil)
    toolbarManager = ToolbarManager(viewController: self)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("\(#function) not implemented")
  }

  override public func viewDidLoad() {
    super.viewDidLoad()

    with(navigationItem) {
      $0.largeTitleDisplayMode = .never
      $0.scrollEdgeAppearance = update(UINavigationBarAppearance()) {
        $0.configureWithDefaultBackground()
        $0.shadowColor = .clear
      }
    }

    addChild(browserViewController) {
      view.addSubview($0)
      $0.snp.makeConstraints {
        $0.edges.equalToSuperview()
      }
    }

    browserViewController.canGoBackDriver
      .drive(toolbarManager.backButtonEnabled)
      .disposed(by: disposeBag)

    browserViewController.canGoForwardDriver
      .drive(toolbarManager.forwardButtonEnabled)
      .disposed(by: disposeBag)

    sceneState.lookupListVisible
      .drive(with: self) { owner, lookupListVisible in
        owner.navigationController?.setToolbarHidden(lookupListVisible, animated: true)
        owner.updateNavigationBarAppearance(forLookupListVisible: lookupListVisible)
      }
      .disposed(by: disposeBag)

    // If current URL matches homePageURL, or URL is blank, display title from Docset
    Driver.combineLatest(
      browserViewController.titleDriver,
      browserViewController.currentURLDriver,
      sceneState.currentScope
    )
    .map { pageTitle, currentURL, currentScope -> String in
      guard case let .docset(docset) = currentScope else {
        return "Browser-BrowserController-defaultTitle".boltLocalized
      }
      guard let currentURL = currentURL else {
        return docset.displayName
      }
      if currentURL.isBlank || currentURL == docset.indexPageURL {
        return docset.displayName
      }
      return pageTitle
    }
    .drive(rx.title)
    .disposed(by: disposeBag)
  }

  // MARK: - Private

  private func updateNavigationBarAppearance(forLookupListVisible lookupVisible: Bool) {
    let navigationBar = navigationController?.navigationBar
    if lookupVisible {
      navigationBar?.standardAppearance.configureWithOpaqueBackground()
    } else {
      navigationBar?.standardAppearance.configureWithDefaultBackground()
    }
  }

}

extension LookupContentViewController: ToolbarManagerDelegate {

  func toolbarManagerDidTapGoBack(_ toolbarManager: ToolbarManager) {
    browserViewController.goBack()
  }

  func toolbarManagerDidTapGoForward(_ toolbarManager: ToolbarManager) {
    browserViewController.goForward()
  }

  func toolbarManagerDidTapZoomIn(_ toolbarManager: ToolbarManager) {
    browserViewController.zoomIn()
  }

  func toolbarManagerDidTapZoomOut(_ toolbarManager: ToolbarManager) {
    browserViewController.zoomOut()
  }

  func toolbarManagerDidTapShare(_ toolbarManager: ToolbarManager) {
    browserViewController.shareCurrentPage()
  }

}
