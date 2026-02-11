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

import BetterSafariView

@ViewBuilder
private func safariViewContent(url: URL) -> some View {
  SafariView(
    url: url,
    configuration: SafariView.Configuration(
      entersReaderIfAvailable: false,
      barCollapsingEnabled: true
    )
  )
  .dismissButtonStyle(.done)
}

private struct SafariSheetModifier: ViewModifier {

  let url: URL

  @Binding var isPresented: Bool

  func body(content: Content) -> some View {
    // `SafariView` does not work properly for Mac Catalyst,
    // so we have to directly open the URL in the browser.
    // https://github.com/stleamist/BetterSafariView/issues/49
    #if targetEnvironment(macCatalyst)
    content
      .onChange(of: isPresented) { _, newValue in
        if newValue {
          UIApplication.shared.open(url)
          isPresented = false
        }
      }
    #else
    content
      .sheet(isPresented: $isPresented) {
        safariViewContent(url: url)
      }
    #endif
  }

}

private struct SafariSheetURLModifier: ViewModifier {

  @Binding var url: URL?

  func body(content: Content) -> some View {
    #if targetEnvironment(macCatalyst)
    content
      .onChange(of: url) { _, newValue in
        if let newValue {
          UIApplication.shared.open(newValue)
          url = nil
        }
      }
    #else
    content
      .sheet(item: $url) {
        safariViewContent(url: $0)
      }
    #endif
  }

}

public extension View {

  func safariSheet(url: URL, isPresented: Binding<Bool>) -> some View {
    modifier(SafariSheetModifier(url: url, isPresented: isPresented))
  }

  func safariSheet(url: Binding<URL?>) -> some View {
    modifier(SafariSheetURLModifier(url: url))
  }

}
