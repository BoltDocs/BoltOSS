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

private struct ListItemView<Content: View>: View {

  private let title: String
  private let content: () -> Content

  init(_ title: String, @ViewBuilder content: @escaping () -> Content) {
    self.title = title
    self.content = content
  }

  var body: some View {
    HStack {
      Text(title)
        .foregroundStyle(.secondary)
      Spacer()
      content()
    }
  }

}

struct DocsetInfoView: View {

  @Environment(\.dismiss)
  private var dismiss: DismissAction

  var docset: Docset

  @State private var isDiagnosticsModeOn = false

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Label {
          Text(docset.displayName)
            .font(.headline)
        } icon: {
          Image(uiImage: docset.iconImage)
            .resizable()
        }
        .labelStyle(ListItemLabelStyle(spacing: 8, iconSize: CGSize(width: 24, height: 24)))
        Spacer()
        Button(
          action: { dismiss() },
          label: {
            Image(systemName: "xmark.circle.fill")
              .foregroundStyle(.gray.opacity(0.5))
              .font(.title2)
          }
        )
      }
      .padding()
      // TODO: support for docset keywords
      List {
        // basic info
        Section {
          ListItemView("Version") {
            Text(docset.version)
          }
          ListItemView("Auto Updates") {
            BoltToggle(
              "",
              isOn: .constant(docset.installedAsLatestVersion)
            )
            .disabled(true)
          }
        }
        // feed
        Section {
          ListItemView("Installed From") {
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
        // diagnostics
        Section {
          if isDiagnosticsModeOn {
            // identifier
            ListItemView("Identifier") {
              Text(docset.name)
            }
          }
        }
      }
      .listStyle(.plain)
      Button("Diagnostics") {
        isDiagnosticsModeOn.toggle()
      }
      .padding()
    }
  }

}
