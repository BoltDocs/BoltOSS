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
import BoltSearch
import BoltTypes

import Factory
import SnapKit

final class LookupSearchResultsController: UIViewController {

  @Injected(\.searchService)
  private var searchService: SearchService

  private var sceneState: SceneState

  private var navigationViewController: LookupNavigationViewController

  private var currentSearchIndexRelay = BehaviorRelay<DocsetSearchIndex?>(value: nil)

  private var disposeBag = DisposeBag()
  private var searchUnavailableViewDisposeBag = DisposeBag()

  private var searchUnavailableView: LookupSearchUnavailableUIView?

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("\(#function) has not been implemented")
  }

  init(
    sceneState: SceneState,
    routingState: LookupRoutingState
  ) {
    self.sceneState = sceneState
    navigationViewController = LookupNavigationViewController(routingState: routingState)
    super.init(nibName: nil, bundle: nil)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    sceneState.currentScope
      .distinctUntilChanged()
      .map { [searchService] scope -> DocsetSearchIndex? in
        switch scope {
        case let .docset(docset):
          return searchService.searchIndex(forDocset: docset)
        default:
          return nil
        }
      }
      .drive(currentSearchIndexRelay)
      .disposed(by: disposeBag)

    currentSearchIndexRelay
      .subscribe(with: self) { owner, index in
        owner.searchUnavailableViewDisposeBag = DisposeBag()

        owner.searchUnavailableView?.removeFromSuperview()
        owner.searchUnavailableView = nil

        guard let index = index else {
          return
        }

        let searchUnavailableView = LookupSearchUnavailableUIView(searchIndex: index)

        index.statusDriver
          .map { status -> Bool in
            if case .ready = status {
              return true
            } else {
              return false
            }
          }
          .drive { hidden in
            searchUnavailableView.isHidden = hidden
          }
          .disposed(by: owner.searchUnavailableViewDisposeBag)

        owner.searchUnavailableView = searchUnavailableView

        owner.view.addSubview(searchUnavailableView)
        searchUnavailableView.snp.makeConstraints { make in
          make.edges.equalToSuperview()
        }
      }
      .disposed(by: disposeBag)

    addChild(navigationViewController) {
      view.insertSubview($0, at: 0)
      $0.snp.makeConstraints { make in
        make.edges.equalToSuperview()
      }
    }
  }

}
