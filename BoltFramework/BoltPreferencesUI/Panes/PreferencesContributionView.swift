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

import SwiftUI

import BetterSafariView

import BoltUIFoundation
import BoltUtils

struct PreferencesContributionView: View {

  struct ContributionListItem: View {
    var title: String
    var version: String
    var buttonAction: () -> Void

    var body: some View {
      Button(action: {
        buttonAction()
      }, label: {
        HStack {
          Text(title)
            .lineLimit(1)
          Spacer()
          Text(version)
        }
      })
    }
  }

  @State private var presentingSafariView = false

  @ViewBuilder
  func defaultSafariView(withURL url: URL) -> SafariView {
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
    List {
      Section("Preferences-About-Contribute-localizationTitle".boltLocalized) {
        Button("Preferences-About-Contribute-helpTranslateButtonTitle".boltLocalized) {
          presentingSafariView = true
        }
        .safariView(isPresented: $presentingSafariView) {
          defaultSafariView(withURL: URL(string: "https://github.com/orgs/BoltDocs/BoltLocalizations")!)
        }
      }
      Section(
        header: Text("Preferences-About-Contribute-openSourceTitle".boltLocalized),
        footer: Text("Preferences-About-Contribute-openSourceFooter".boltLocalized)
          .textCase(.none)
      ) {
        ContributionListItem(
          title: "ObjectAssociationHelper",
          version: "1.0.0"
        ) {
          presentingSafariView = true
        }
        .safariView(isPresented: $presentingSafariView) {
          defaultSafariView(withURL: URL(string: "https://github.com/BoltDocs/ObjectAssociationHelper/")!)
        }
      }
    }
    .navigationTitle("Preferences-About-contributeTitle".boltLocalized)
    .navigationBarTitleDisplayMode(.inline)
  }

}
