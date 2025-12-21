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

import BoltModuleExports
import BoltRxSwift

final class LookupTableOfContentsViewController: UINavigationController, HasDisposeBag {

  private var sceneState: SceneState
  private var routingState: LookupRoutingState

  private var listViewController: LookupListViewController<LookupTableOfContentsViewModel>?

  init(sceneState: SceneState, routingState: LookupRoutingState) {
    self.sceneState = sceneState
    self.routingState = routingState
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("\(#function) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    configureNavigationBarAppearance(enforceLargeTitle: false)

    sceneState.currentScope
      .drive(with: self) { owner, scope in
        switch scope {
        case .none:
          break
        case let .docset(docset):
          let listViewController = LookupListViewController<LookupTableOfContentsViewModel>(
            sceneState: owner.sceneState,
            viewModel: LookupTableOfContentsViewModel(
              routingState: owner.routingState,
              docset: docset
            )
          )
          owner.viewControllers = [listViewController]
          owner.listViewController = listViewController
        case .history:
          break
        case .favorites:
          break
        }
      }
      .disposed(by: disposeBag)
  }

}
