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
import SwiftUI
import UIKit

import Overture
import RxCocoa
import RxRelay
import RxSwift

import BoltBrowserUI
import BoltHomeUI
import BoltLookupUI
import BoltModuleExports
import BoltUIFoundation

public final class SceneManager {

  weak var window: UIWindow!

  private lazy var doubleColumnSplitViewController: DoubleColumnSplitViewController = {
    return update(DoubleColumnSplitViewController()) {
      $0.delegate = self
    }
  }()
  private lazy var homeCompactNavigationController = UINavigationController(rootViewController: homeViewControllerCompact)
  private lazy var homePrimaryNavigationController = UINavigationController(rootViewController: homeViewControllerRegular)
  private lazy var homeViewControllerCompact = HomeViewController(sceneState: state, isForCollapsedSidebar: true)
  private lazy var homeViewControllerRegular = HomeViewController(sceneState: state, isForCollapsedSidebar: false)

  private lazy var lookupSearchController = LookupSearchController(sceneState: state)

  private lazy var secondaryNavigationController = UINavigationController()

  private lazy var welcomeViewController = WelcomeViewController()
  private lazy var browserViewController = BrowserViewController(sceneState: state)

  private let state = SceneState()
  private let disposeBag = DisposeBag()

  public init(_ window: UIWindow) {
    self.window = window

    // swiftlint:disable:next trailing_closure
    state.onPresentLibrary
      .emit(onNext: {
        BoltAppNavigator.presentLibrary()
      })
      .disposed(by: disposeBag)

    // swiftlint:disable:next trailing_closure
    state.onPresentPreferences
      .emit(onNext: {
        BoltAppNavigator.presentPreferences()
      })
      .disposed(by: disposeBag)

    with(browserViewController) {
      $0.navigationItem.searchController = lookupSearchController
      $0.navigationItem.hidesSearchBarWhenScrolling = false
      if #available(iOS 16.0, *) {
        $0.navigationItem.preferredSearchBarPlacement = .stacked
      }
    }

    with(doubleColumnSplitViewController) {
      $0.setViewController(homePrimaryNavigationController, for: .primary)
      $0.setViewController(homeCompactNavigationController, for: .compact)
      $0.setViewController(secondaryNavigationController, for: .secondary)
    }

    state.currentScope
      .drive(with: self) { owner, scope in
        if owner.doubleColumnSplitViewController.isCollapsed {
          if scope != nil {
            owner.homeCompactNavigationController.setViewControllers(
              [
                owner.homeViewControllerCompact,
                owner.browserViewController,
              ],
              animated: true
            )
          } else {
            owner.homeCompactNavigationController.setViewControllers(
              [
                owner.homeViewControllerCompact,
                owner.welcomeViewController,
              ],
              animated: true
            )
          }
        } else {
          if scope != nil {
            owner.secondaryNavigationController.viewControllers = [owner.browserViewController]
          } else {
            owner.secondaryNavigationController.viewControllers = [owner.welcomeViewController]
          }
        }
      }
      .disposed(by: disposeBag)

    window.rootViewController = doubleColumnSplitViewController
  }

}

extension SceneManager: UISplitViewControllerDelegate {

  public func splitViewController(
    _ splitViewController: UISplitViewController,
    topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column
  ) -> UISplitViewController.Column {
    if splitViewController == doubleColumnSplitViewController {
      // prepare viewControllers to move
      let viewControllers = [homeViewControllerCompact] +
        secondaryNavigationController.viewControllers.filter {
          $0 != welcomeViewController
        }
      // move viewControllers
      secondaryNavigationController.setViewControllers([], animated: true)
      homeCompactNavigationController.setViewControllers(viewControllers, animated: true)
    }
    return .compact
  }

  public func splitViewController(
    _ splitViewController: UISplitViewController,
    displayModeForExpandingToProposedDisplayMode proposedDisplayMode: UISplitViewController.DisplayMode
  ) -> UISplitViewController.DisplayMode {
    if splitViewController == doubleColumnSplitViewController {
      // prepare viewControllers to move
      var viewControllers = homeCompactNavigationController.viewControllers.filter {
        $0 != homeViewControllerCompact
      }
      if viewControllers.isEmpty {
        viewControllers = [welcomeViewController]
      }
      // move viewControllers
      homeCompactNavigationController.setViewControllers([], animated: true)
      secondaryNavigationController.setViewControllers(viewControllers, animated: true)
    }
    return proposedDisplayMode
  }

}
