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

import IssueReporting

import BoltLocalizations
import BoltServices
import BoltUIFoundation

struct DocsetInfoView: View {

  @Environment(\.dismiss)
  private var dismiss: DismissAction

  var docset: Docset

  var body: some View {
    // TODO: support for docset keywords
    NavigationView {
      Form {
        // basic info
        Section {
          // icon and display name
          Label {
            Text(docset.displayName)
          } icon: {
            Image(uiImage: docset.iconImage)
          }
          .labelStyle(ListItemLabelStyle(spacing: 8, iconSize: CGSize(width: 30, height: 30)))
          // identifier
          HStack {
            Text("Identifier")
            Spacer()
            Text(docset.name)
          }
          HStack {
            Text("Version")
            Spacer()
            Text(docset.version)
          }
          HStack {
            BoltToggle(
              "Auto Updates",
              isOn: .constant(docset.installedAsLatestVersion)
            )
            .disabled(true)
          }
        }
        // feed
        Section {
          HStack {
            Text("Installed From")
            Spacer()
            switch docset.repository {
            case .main:
              Text("Main")
            case .cheatsheet:
              Text("Cheatsheet")
            case .userContributed:
              Text("User Contributed")
            case .custom:
              Text("Custom")
            case let repository:
              let _ = reportIssue("Unhandled repository type: \(repository)")
            }
          }
        }
      }
      .listStyle(.insetGrouped)
      .navigationTitle(docset.displayName)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(UIKitLocalizations.done) {
            dismiss()
          }
        }
      }
    }
  }

}
