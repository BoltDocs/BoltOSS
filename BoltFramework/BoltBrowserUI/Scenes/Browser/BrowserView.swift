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

import BoltRxSwift
import BoltServices
import BoltUtils

final class BrowserView: UIView, LoggerProvider, HasDisposeBag {

  lazy var url: Binder<URL> = {
    Binder<URL>(webView) { target, url in
      target.load(URLRequest(url: url))
    }
  }()

  lazy var canGoBack: Driver<Bool> = {
    return webView.rx.canGoBack
  }()

  lazy var canGoForward: Driver<Bool> = {
    return webView.rx.canGoForward
  }()

  var currentURL: URL? {
    return webView.url
  }

  lazy var currentURLDriver: Driver<URL?> = {
    return webView.rx.currentURL
  }()

  lazy var title: Driver<String> = {
    return webView.rx.title
      .map { return $0 ?? "" }
  }()

  lazy var estimatedProgress: Driver<Double> = {
    return webView.rx.estimatedProgressObservable
  }()

  private let findInPageCurrentIndexSubject = PublishRelay<Int>()
  lazy var findInPageCurrentIndex: Signal<Int> = { findInPageCurrentIndexSubject.asSignal() }()

  private let findInPageTotalResultsSubject = PublishRelay<Int>()
  lazy var findInPageTotalResults: Signal<Int> = { findInPageTotalResultsSubject.asSignal() }()

  private var webView: WKWebView!
  private var scaleFactor: CGFloat = 1.0 {
    didSet {
      updatePageZoom(scaleFactor)
    }
  }

  init(initialURL: URL, enablesJavaScript: Bool) {
    super.init(frame: .zero)

    let configuration = update(WKWebViewConfiguration()) {
      let pagePreferences = update(WKWebpagePreferences()) {
        $0.allowsContentJavaScript = enablesJavaScript
        $0.preferredContentMode = UserDefaults.standard.enablesDesktopMode ? .desktop : .recommended
      }

      let userContentController = update(WKUserContentController()) {
        if
          let scriptPath = Bundle.module.path(forResource: "Assets/FindInPage", ofType: "js"),
          let script = try? String(contentsOfFile: scriptPath, encoding: .utf8)
        {
          $0.addUserScript(
            WKUserScript(
              source: script,
              injectionTime: .atDocumentEnd,
              forMainFrameOnly: true
            )
          )
        }
        let findInPageHandler = FindInPageMessageHandler(delegate: self)
        $0.add(findInPageHandler, name: findInPageHandler.name)
      }

      $0.websiteDataStore = UserDefaults.standard.disablesPrivateBrowsing ? .default() : .nonPersistent()
      $0.defaultWebpagePreferences = pagePreferences
      $0.setURLSchemeHandler(TarixURLSchemeHandler(), forURLScheme: DocsetFileURLScheme.scheme)
      $0.userContentController = userContentController
    }

    webView = WKWebView(frame: .zero, configuration: configuration)

    if UserDefaults.standard.webViewInspectable {
      webView.isInspectable = true
    }

    webView.allowsBackForwardNavigationGestures = false

    addSubview(webView)
    webView.snp.makeConstraints {
      $0.edges.equalTo(self)
    }

    webView.load(URLRequest(url: initialURL))
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("\(#function) is not implemented")
  }

  // MARK: - Methods

  func goBack() {
    webView.goBack()
  }

  func goForward() {
    webView.goForward()
  }

  func zoomIn() {
    scaleFactor += 0.25
  }

  func zoomOut() {
    scaleFactor -= 0.25
  }

  func findInPage(query: String) {
    Self.logger.debug("find in page with query: \(query)")
    let escapedQuery = query.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
    webView.evaluateJavaScript("window.__bolt__.find(\"\(escapedQuery)\")")
  }

  func findPreviousInPage() {
    webView.evaluateJavaScript("window.__bolt__.findPrevious()")
  }

  func findNextInPage() {
    webView.evaluateJavaScript("window.__bolt__.findNext()")
  }

  private func updatePageZoom(_ scaleFactor: CGFloat) {
    // Use the private `viewScale` property to properly handle page zooming.
    // See also: https://github.com/mozilla-mobile/firefox-ios/blob/a4d5dbf/BrowserKit/Sources/WebEngine/WKWebview/WKEngineSession.swift#L295
    webView.setValue(scaleFactor, forKey: "viewScale")
  }

}

extension BrowserView: FindInPageMessageHandlerDelegate {

  func findInPageHelper(
    _: FindInPageMessageHandler,
    didUpdateCurrentResult currentResult: Int
  ) {
    findInPageCurrentIndexSubject.accept(currentResult)
  }

  func findInPageHelper(
    _: FindInPageMessageHandler,
    didUpdateTotalResults totalResults: Int
  ) {
    findInPageTotalResultsSubject.accept(totalResults)
  }

}
