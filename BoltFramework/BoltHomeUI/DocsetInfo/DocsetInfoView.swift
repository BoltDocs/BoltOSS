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

import Factory
import IssueReporting

import BoltDatabase
import BoltLocalizations
import BoltServices
import BoltUIFoundation
import BoltUtils

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

private struct ListItemStringContentView: View {

  private let content: Binding<String>
  private let editable: Bool

  init(content: Binding<String>, editable: Bool) {
    self.content = content
    self.editable = editable
  }

  var body: some View {
    HStack {
      if editable {
        TextField("", text: content)
          .multilineTextAlignment(.trailing)
      } else {
        Text(content.wrappedValue)
      }
    }
  }

}

private struct ListItemBoolContentView: View {

  private let value: Binding<Bool>
  private let editable: Bool

  init(value: Binding<Bool>, editable: Bool) {
    self.value = value
    self.editable = editable
  }

  var body: some View {
    HStack {
      if editable {
        Picker("", selection: value) {
          Text("Localizations-General-yes".boltLocalized).tag(true)
          Text("Localizations-General-no".boltLocalized).tag(false)
        }
      } else {
        Text(
          value.wrappedValue ?
            "Localizations-General-yes".boltLocalized :
            "Localizations-General-no".boltLocalized
        )
      }
    }
  }

}

public class DocsetInfoViewModel: ObservableObject, LoggerProvider {

  @Injected(\.libraryDocsetsManager)
  private var libraryDocsetManager: LibraryDocsetsManager

  private let docset: Docset

  @Published private(set) var isDiagnosticsModeOn: Bool = false

  @Published var version: String
  @Published var installedAsLatestVersion: Bool

  var identifier: String { docset.name }

  var displayName: String { docset.displayName }

  var iconImage: IdentifiableImage { docset.iconImage }

  var repository: String {
    switch docset.repository {
    case .main:
      return "Library-Home-Items-mainDocsetsTitle".boltLocalized
    case .cheatsheet:
      return "Library-Home-Items-cheatsheetsTitle".boltLocalized
    case .userContributed:
      return "Library-Home-Items-userContributedTitle".boltLocalized
    case .custom:
      return "Library-Home-Items-customFeedsTitle".boltLocalized
    case let repository:
      reportIssue("Unhandled repository type: \(repository)")
      return "Home-DocsetInfo-InstalledFrom-unknown".boltLocalized
    }
  }

  public init(docset: Docset) {
    self.docset = docset
    self.version = docset.version
    self.installedAsLatestVersion = docset.installedAsLatestVersion
  }

  func toggleDiagnosticsMode() {
    isDiagnosticsModeOn.toggle()
    if !isDiagnosticsModeOn {
      let update = DocsetInstallationUpdate(
        uuid: docset.uuid,
        version: version,
        installedAsLatestVersion: installedAsLatestVersion
      )
      do {
        try libraryDocsetManager.updateDocsetInstallation(update)
      } catch {
        Self.logger.error("failed to save docset update, error: \(error)")
      }
    }
  }

}

struct DocsetInfoView: View {

  @Environment(\.dismissCurrentSheetModal)
  private var dismissCurrentSheetModal: DismissAction?

  @StateObject private var viewModel: DocsetInfoViewModel

  init(docset: Docset) {
    _viewModel = StateObject(wrappedValue: DocsetInfoViewModel(docset: docset))
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Label {
          Text(viewModel.displayName)
            .font(.headline)
        } icon: {
          Image(uiImage: viewModel.iconImage.image)
            .resizable()
        }
        .labelStyle(ListItemLabelStyle(spacing: 8, iconSize: CGSize(width: 24, height: 24)))
        Spacer()
        Button(
          action: { dismissCurrentSheetModal?() },
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
          ListItemView("Home-DocsetInfo-SectionTitles-version".boltLocalized) {
            ListItemStringContentView(
              content: $viewModel.version,
              editable: viewModel.isDiagnosticsModeOn
            )
          }
          ListItemView("Home-DocsetInfo-SectionTitles-autoUpdates".boltLocalized) {
            ListItemBoolContentView(
              value: $viewModel.installedAsLatestVersion,
              editable: viewModel.isDiagnosticsModeOn
            )
          }
        }
        // feed
        Section {
          ListItemView("Home-DocsetInfo-SectionTitles-installedFrom".boltLocalized) {
            Text(viewModel.repository)
          }
        }
        // diagnostics
        Section {
          if viewModel.isDiagnosticsModeOn {
            // identifier
            ListItemView("Home-DocsetInfo-SectionTitles-identifier".boltLocalized) {
              Text(viewModel.identifier)
            }
          }
        }
      }
      .listStyle(.plain)
      if RuntimeEnvironment.isInternalBuild {
        Button("Localizations-General-diagnostics".boltLocalized) {
          viewModel.toggleDiagnosticsMode()
        }
        .padding()
      }
    }
  }

}
