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
import BoltUtils

import Overture
import SnapKit

public final class LookupContentViewController: UIViewController, HasDisposeBag {

  private let systemNavigationBarShadowColor: UIColor? = {
    let appearance = UINavigationBarAppearance()
    appearance.configureWithOpaqueBackground()
    return appearance.shadowColor
  }()

  private let sceneState: SceneState

  private let browserViewController: BrowserViewController

  private var toolbarManager: ToolbarManager!

  private lazy var toolbar = UIToolbar()

  private var toolbarMode: ToolbarMode = .normal {
    didSet {
      toolbarManager.mode = toolbarMode
    }
  }

  public init(sceneState: SceneState) {
    self.sceneState = sceneState
    browserViewController = BrowserViewController(sceneState: sceneState)

    super.init(nibName: nil, bundle: nil)

    let findInPageViewModel = FindInPageToolbarViewModel(sceneState: sceneState)
    toolbarManager = ToolbarManager(
      delegate: self,
      findInPageToolbarViewModel: findInPageViewModel
    )
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("\(#function) not implemented")
  }

  override public func viewDidLoad() {
    super.viewDidLoad()

    navigationController?.isToolbarHidden = false

    with(navigationItem) {
      $0.largeTitleDisplayMode = .never
    }

    addChild(browserViewController) {
      view.addSubview($0)
      if RuntimeEnvironment.isOS26UIEnabled {
        $0.snp.makeConstraints {
          $0.top.equalTo(view.safeAreaLayoutGuide)
          $0.leading.trailing.bottom.equalToSuperview()
        }
      } else {
        $0.snp.makeConstraints {
          $0.edges.equalToSuperview()
        }
      }
    }

    browserViewController.canGoBackDriver
      .drive(toolbarManager.backButtonEnabled)
      .disposed(by: disposeBag)

    browserViewController.canGoForwardDriver
      .drive(toolbarManager.forwardButtonEnabled)
      .disposed(by: disposeBag)

    if RuntimeEnvironment.isOS26UIEnabled {
      view.addSubview(toolbar)
      toolbar.snp.makeConstraints {
        $0.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        #if targetEnvironment(macCatalyst)
        $0.bottom.equalToSuperview().inset(20)
        #else
        $0.bottom.equalTo(view.safeAreaLayoutGuide)
        #endif
      }
    }

    Driver.combineLatest(
      sceneState.lookupListVisible,
      sceneState.lookupListShowsDocPage
    )
    .drive(with: self) { owner, value in
      let (lookupListVisible, lookupListShowsDocPage) = value
      owner.updateNavigationBarAppearance(
        forLookupListVisible: lookupListVisible,
        showsDocPage: lookupListShowsDocPage
      )
      let mode: ToolbarMode = {
        if lookupListVisible {
          return lookupListShowsDocPage ? .search(scope: .docPage) : .search(scope: .types)
        } else {
          return .normal
        }
      }()
      owner.toolbarMode = mode
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

  private func updateNavigationBarAppearance(
    forLookupListVisible lookupVisible: Bool,
    showsDocPage: Bool
  ) {
    if navigationItem.standardAppearance == nil {
      navigationItem.standardAppearance = UINavigationBarAppearance()
    }
    if navigationItem.scrollEdgeAppearance == nil {
      navigationItem.scrollEdgeAppearance = UINavigationBarAppearance()
    }

    if RuntimeEnvironment.isOS26UIEnabled {
      if lookupVisible, !showsDocPage {
        navigationItem.standardAppearance?.configureWithDefaultBackground()
        navigationItem.scrollEdgeAppearance?.configureWithDefaultBackground()
      } else {
        navigationItem.standardAppearance?.configureWithDefaultBackground()
        navigationItem.standardAppearance?.shadowColor = systemNavigationBarShadowColor
        navigationItem.scrollEdgeAppearance?.configureWithDefaultBackground()
      }
    } else {
      if lookupVisible, !showsDocPage {
        navigationItem.standardAppearance?.configureWithOpaqueBackground()
        navigationItem.scrollEdgeAppearance?.configureWithOpaqueBackground()
      } else {
        navigationItem.standardAppearance?.configureWithDefaultBackground()
        navigationItem.scrollEdgeAppearance?.configureWithDefaultBackground()
        navigationItem.scrollEdgeAppearance?.shadowColor = .clear
      }
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

  func toolbarManager(_ toolbarManager: ToolbarManager, updateToolbarItems items: [UIBarButtonItem]) {
    guard RuntimeEnvironment.isOS26UIEnabled else {
      toolbarItems = items
      return
    }
    if case .normal = toolbarMode {
      toolbarItems = items
      toolbar.items = []
    } else {
      toolbar.items = items
      toolbarItems = []
    }
  }

}
