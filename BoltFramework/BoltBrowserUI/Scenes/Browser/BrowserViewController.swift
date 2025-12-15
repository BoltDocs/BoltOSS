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
import WebKit

import Overture
import RxCocoa
import RxSwift
import SnapKit

import BoltLocalizations
import BoltModuleExports
import BoltRxSwift
import BoltServices
import BoltUtils

public final class BrowserViewController: UIViewController, HasDisposeBag {

  private var browserView: BrowserView!
  private var progressView: UIProgressView!

  private let sceneState: SceneState

  private var docset: Docset?

  public var titleDriver: Driver<String> { browserView.title }
  public var currentURLDriver: Driver<URL?> { browserView.currentURLDriver }
  public var canGoBackDriver: Driver<Bool> { browserView.canGoBack }
  public var canGoForwardDriver: Driver<Bool> { browserView.canGoForward }

  public init(sceneState: SceneState) {
    self.sceneState = sceneState
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("\(#function) not implemented")
  }

  override public func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .systemBackground

    setupProgressView()

    sceneState.currentScope
      .drive(with: self) { owner, scope in
        owner.docset = nil
        guard let scope = scope else {
          return
        }
        switch scope {
        case let .docset(docset):
          owner.docset = docset
          owner.setupBrowserView(
            initialURL: docset.indexPageURL ?? URL.blank,
            enablesJavaScript: docset.isJavaScriptEnabled
          )
        case .history:
          break
        case .favorites:
          break
        }
      }
      .disposed(by: disposeBag)

    sceneState.findInPageQuery
      .emit(with: self) { owner, query in
        owner.browserView.findInPage(query: query)
      }
      .disposed(by: disposeBag)

    sceneState.findPreviousInPage
      .emit(with: self) { owner, _ in
        owner.browserView.findPreviousInPage()
      }
      .disposed(by: disposeBag)

    sceneState.findNextInPage
      .emit(with: self) { owner, _ in
        owner.browserView.findNextInPage()
      }
      .disposed(by: disposeBag)
  }

  private func setupBrowserView(initialURL: URL, enablesJavaScript: Bool) {
    browserView?.removeFromSuperview()

    browserView = BrowserView(initialURL: initialURL, enablesJavaScript: enablesJavaScript)

    sceneState.currentPageURL
      .emit(to: browserView.url)
      .disposed(by: browserView.disposeBag)

    browserView.estimatedProgress
      .map { Float($0) }
      .drive(progressView.rx.progress)
      .disposed(by: browserView.disposeBag)

    browserView.estimatedProgress
      .map { $0 == 1.0 }
      .drive(progressView.rx.isHidden)
      .disposed(by: browserView.disposeBag)

    browserView.findInPageCurrentIndex
      .emit(with: self) { owner, currentIndex in
        owner.sceneState.dispatch(action: .updateFindInPageCurrentIndex(currentIndex))
      }
      .disposed(by: browserView.disposeBag)

    browserView.findInPageTotalResults
      .emit(with: self) { owner, totalResults in
        owner.sceneState.dispatch(action: .updateFindInPageTotalResults(totalResults))
      }
      .disposed(by: browserView.disposeBag)

    view.insertSubview(browserView, belowSubview: progressView)
    browserView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }

}

extension BrowserViewController {

  private func setupProgressView() {
    progressView = UIProgressView(progressViewStyle: .bar)
    view.addSubview(progressView)
    progressView.snp.makeConstraints { make in
      make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
      make.height.equalTo(2)
    }
  }

  public func goBack() {
    browserView.goBack()
  }

  public func goForward() {
    browserView.goForward()
  }

  public func zoomIn() {
    browserView.zoomIn()
  }

  public func zoomOut() {
    browserView.zoomOut()
  }

  public func shareCurrentPage() {
    guard let currentURL = browserView.currentURL else {
      return
    }

    guard let fallbackURL = docset?.fallbackURL else {
      return
    }

    let url = fallbackURL.appendingPathComponent(currentURL.path)

    let activityViewController = UIActivityViewController(
      activityItems: [url],
      applicationActivities: [ SafariActivity() ]
    )

    present(activityViewController, animated: true)
  }

}
