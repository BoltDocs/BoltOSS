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

import UIKit

import Overture
import RxCocoa

import BoltServices
import BoltUIFoundation
import BoltUtils
import RoutableNavigation

final class LookupNavigationViewController: RoutableNavigationController<LookupRouteElement> {

  private weak var routingState: LookupRoutingState!

  init(routingState: LookupRoutingState) {
    self.routingState = routingState
    super.init(coordinator: routingState.routingCoordinator)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("\(#function) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    configureNavigationBarAppearance(enforceLargeTitle: false)
    routingState.setupScopeRouting()
  }

  override func viewController(forRouteElement element: LookupRouteElement) -> UIViewController? {
    switch element.routingType {
    case .initial:
      return update(LookupInitialViewController()) {
        $0?.routeHash = element.routeHash
      }
    case .entries(let docset):
      return update(
        LookupListViewController(
          viewModel: LookupAllEntriesViewModel(
            routingState: routingState,
            docset: docset
          )
        )
      ) {
        $0.routeHash = element.routeHash
      }
    case let .types(docset, type):
      return update(
        LookupListViewController(
          viewModel: LookupTypeFilteringViewModel(
            routingState: routingState,
            type: type,
            docset: docset
          )
        )
      ) {
        $0.routeHash = element.routeHash
      }
    }
  }

}
