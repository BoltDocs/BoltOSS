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

  private lazy var backButton = UIBarButtonItem(
    image: UIImage(systemName: "chevron.left"),
    style: .plain,
    target: self,
    action: #selector(backButtonTapped(_:))
  )

  private lazy var forwardButton = UIBarButtonItem(
    image: UIImage(systemName: "chevron.right"),
    style: .plain,
    target: self,
    action: #selector(forwardButtonTapped(_:))
  )

  private lazy var tableOfContentsButton = UIBarButtonItem(
    image: UIImage(systemName: "list.bullet"),
    style: .plain,
    target: self,
    action: #selector(tableOfContentsButtonTapped(_:))
  )

  private lazy var bookmarkButton = UIBarButtonItem(
    image: UIImage(systemName: "bookmark"),
    style: .plain,
    target: self,
    action: #selector(bookmarkButtonTapped(_:))
  )

  private lazy var shareButton = UIBarButtonItem(
    image: UIImage(systemName: "square.and.arrow.up"),
    style: .plain,
    target: self,
    action: #selector(shareButtonTapped(_:))
  )

  private var docset: Docset?

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

    navigationItem.largeTitleDisplayMode = .never

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

    sceneState.lookupListVisible
      .drive(with: self) { owner, isShown in
        owner.navigationController?.setToolbarHidden(isShown, animated: true)
        owner.updateNavigationBarAppearance(forLookupListVisible: isShown)
      }
      .disposed(by: disposeBag)

    setupToolbarItems()
  }

  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.navigationBar.scrollEdgeAppearance?.configureWithOpaqueBackground()
    navigationController?.navigationBar.scrollEdgeAppearance?.shadowColor = .clear
  }

  override public func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.navigationBar.scrollEdgeAppearance = UINavigationBar.appearance().scrollEdgeAppearance
    navigationController?.navigationBar.standardAppearance = UINavigationBar.appearance().standardAppearance
  }

  private func setupBrowserView(initialURL: URL, enablesJavaScript: Bool) {
    browserView?.removeFromSuperview()

    browserView = BrowserView(initialURL: initialURL, enablesJavaScript: enablesJavaScript)

    sceneState.currentPageURL
      .emit(to: browserView.url)
      .disposed(by: browserView.disposeBag)

    // If current URL matches homePageURL, or URL is blank, display title from Docset
    Driver.combineLatest(
      browserView.title,
      browserView.currentURLDriver,
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
    .disposed(by: browserView.disposeBag)

    browserView.canGoBack
      .drive(backButton.rx.isEnabled)
      .disposed(by: browserView.disposeBag)

    browserView.canGoForward
      .drive(forwardButton.rx.isEnabled)
      .disposed(by: browserView.disposeBag)

    browserView.estimatedProgress
      .map { Float($0) }
      .drive(progressView.rx.progress)
      .disposed(by: browserView.disposeBag)

    browserView.estimatedProgress
      .map { $0 == 1.0 }
      .drive(progressView.rx.isHidden)
      .disposed(by: browserView.disposeBag)

    view.insertSubview(browserView, belowSubview: progressView)
    browserView.snp.makeConstraints { make in
      make.top.equalTo(view.safeAreaLayoutGuide)
      make.leading.equalToSuperview()
      make.trailing.equalToSuperview()
      make.bottom.equalTo(view.safeAreaLayoutGuide)
    }
  }

}

extension BrowserViewController {

  private func setupProgressView() {
    progressView = UIProgressView(progressViewStyle: .bar)
    view.addSubview(progressView)
    progressView.snp.makeConstraints { make in
      make.top.equalTo(view.safeAreaLayoutGuide)
      make.leading.equalToSuperview()
      make.trailing.equalToSuperview()
      make.height.equalTo(2)
    }
  }

  private func setupToolbarItems() {
    let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

    let moreButton = UIBarButtonItem(
      image: UIImage(systemName: "textformat.size"),
      menu: UIMenu(
        title: "",
        children: [
          UIAction(title: "Smaller Text", image: UIImage(systemName: "textformat.size.smaller")) { [weak self] _ in
            self?.browserView.zoomOut()
          },
          UIAction(title: "Larger Text", image: UIImage(systemName: "textformat.size.larger")) { [weak self] _ in
            self?.browserView.zoomIn()
          },
        ]
      )
    )

    toolbarItems = [
      backButton,
      flexibleSpace,
      forwardButton,
      flexibleSpace,
      tableOfContentsButton,
      flexibleSpace,
      bookmarkButton,
      flexibleSpace,
      shareButton,
      flexibleSpace,
      moreButton,
    ]
  }

  func updateNavigationBarAppearance(forLookupListVisible lookupVisible: Bool) {
    let navigationBar = navigationController?.navigationBar
    if lookupVisible {
      navigationBar?.standardAppearance.configureWithOpaqueBackground()
    } else {
      navigationBar?.standardAppearance.configureWithDefaultBackground()
    }
  }

  @objc func backButtonTapped(_ sender: Any?) {
    browserView.goBack()
  }

  @objc func forwardButtonTapped(_ sender: Any?) {
    browserView.goForward()
  }

  @objc func tableOfContentsButtonTapped(_ sender: Any?) {

  }

  @objc func bookmarkButtonTapped(_ sender: Any?) {

  }

  @objc func shareButtonTapped(_ sender: Any?) {
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

  @objc func moreButtonTapped(_ sender: Any?) {

  }

}
