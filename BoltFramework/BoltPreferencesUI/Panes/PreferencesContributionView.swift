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

import SwiftUI

import BetterSafariView

import BoltUIFoundation
import BoltUtils

struct PreferencesContributionView: View {

  struct ContributionListItem: View {
    var title: String
    var version: String?
    var url: URL

    #if !targetEnvironment(macCatalyst)
    @State private var presentingSafariView = false
    #endif

    @ViewBuilder
    private func defaultSafariView(withURL url: URL) -> SafariView {
      SafariView(
        url: url,
        configuration: SafariView.Configuration(
          entersReaderIfAvailable: false,
          barCollapsingEnabled: true
        )
      )
      .dismissButtonStyle(.done)
    }

    var body: some View {
      let listItem = Button(action: {
        #if targetEnvironment(macCatalyst)
        UIApplication.shared.open(url)
        #else
        presentingSafariView = true
        #endif
      }, label: {
        HStack {
          Text(title)
            .lineLimit(1)
          Spacer()
          if let version = version, !version.isEmpty {
            Text(version)
          }
        }
      })
      // `.safariView` does not work properly for Mac Catalyst,
      // so we have to directly open the URL in the browser.
      // https://github.com/stleamist/BetterSafariView/issues/49
      #if targetEnvironment(macCatalyst)
      listItem
      #else
      listItem
        .safariView(isPresented: $presentingSafariView) {
          defaultSafariView(withURL: url)
        }
      #endif
    }
  }

  var body: some View {
    List {
      Section("Preferences-About-Contribute-localizationTitle".boltLocalized) {
        ContributionListItem(
          title: "Preferences-About-Contribute-helpTranslateButtonTitle".boltLocalized,
          url: URL(string: "https://github.com/BoltDocs/BoltLocalizations")!
        )
      }
      Section(
        header: Text("Preferences-About-Contribute-openSourceRepositoryTitle".boltLocalized)
      ) {
        ContributionListItem(
          title: "BoltOSS",
          url: URL(string: "https://github.com/BoltDocs/BoltOSS")!
        )
      }
      Section(
        header: Text("Preferences-About-Contribute-openSourceLibrariesTitle".boltLocalized),
        footer: Text("Preferences-About-Contribute-openSourceFooter".boltLocalized)
          .textCase(.none)
      ) {
        ContributionListItem(
          title: "RoutableNavigation",
          url: URL(string: "https://github.com/BoltDocs/RoutableNavigation")!
        )
        ContributionListItem(
          title: "ObjectAssociationHelper",
          url: URL(string: "https://github.com/BoltDocs/ObjectAssociationHelper")!
        )
      }
    }
    .navigationTitle("Preferences-About-contributeTitle".boltLocalized)
    .navigationBarTitleDisplayMode(.inline)
  }

}
