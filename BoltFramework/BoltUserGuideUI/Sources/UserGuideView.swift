//
// Copyright (C) 2026 Bolt Contributors
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

import SwiftUI
import WebKit

import Factory
import RxCocoa
import RxSwift
import RxWebKit

import BoltLocalizations
import BoltUIFoundation
import BoltUserGuide
import BoltUtils

private struct WebViewRepresentable: UIViewRepresentable {

  enum Actions {
    case goBack, goForward
  }

  final class Coordinator {

    var disposeBag = DisposeBag()

  }

  private let location: UserGuideLocation

  private let canGoBack: Binding<Bool>
  private let canGoForward: Binding<Bool>

  private let actionStream: ControlEvent<Actions>

  init(
    location: UserGuideLocation,
    canGoBack: Binding<Bool>,
    canGoForward: Binding<Bool>,
    actionStream: ControlEvent<Actions>
  ) {
    self.location = location
    self.canGoBack = canGoBack
    self.canGoForward = canGoForward
    self.actionStream = actionStream
  }

  func makeUIView(context: Context) -> WKWebView {
    let webView = WKWebView()

    if UserDefaults.standard.webViewInspectable {
      webView.isInspectable = true
    }

    let coordinator = context.coordinator

    coordinator.disposeBag = DisposeBag()

    webView.rx.canGoBack
      .subscribe {
        canGoBack.wrappedValue = $0
      }
      .disposed(by: coordinator.disposeBag)

    webView.rx.canGoForward
      .subscribe {
        canGoForward.wrappedValue = $0
      }
      .disposed(by: coordinator.disposeBag)

    actionStream
      .subscribe { [weak webView] action in
        switch action {
        case .goBack:
          webView?.goBack()
        case .goForward:
          webView?.goForward()
        }
      }
      .disposed(by: coordinator.disposeBag)

    if let url = Container.shared.userGuideOnlineURLResolver()?(location) {
      webView.load(URLRequest(url: url))
    }

    return webView
  }

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  func updateUIView(_ webView: WKWebView, context: Context) { }

}

struct UserGuideView: View {

  let location: UserGuideLocation

  @Environment(\.dismissCurrentSheetModal)
  private var dismissCurrentSheetModal: DismissAction?

  @State private var canGoBack = false
  @State private var canGoForward = false

  @State private var actionsRelay = PublishRelay<WebViewRepresentable.Actions>()

  var body: some View {
    NavigationView {
      WebViewRepresentable(
        location: location,
        canGoBack: $canGoBack,
        canGoForward: $canGoForward,
        actionStream: ControlEvent(events: actionsRelay)
      )
      .ignoresSafeArea()
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: { goBack() }, label: {
            Image(systemName: "chevron.left")
          })
          .disabled(!canGoBack)
        }
        ToolbarItem(placement: .topBarLeading) {
          Button(action: { goForward() }, label: {
            Image(systemName: "chevron.right")
          })
          .disabled(!canGoForward)
        }
        if RuntimeEnvironment.isOS26UIEnabled {
          ToolbarItem(placement: .topBarTrailing) {
            Button(UIKitLocalizations.close, systemImage: "xmark") {
              dismissCurrentSheetModal?()
            }
          }
        } else {
          ToolbarItem(placement: .confirmationAction) {
            Button(UIKitLocalizations.done) {
              dismissCurrentSheetModal?()
            }
          }
        }
      }
    }
    .navigationViewStyle(.stack)
  }

  private func goBack() {
    actionsRelay.accept(.goBack)
  }

  private func goForward() {
    actionsRelay.accept(.goForward)
  }

}
