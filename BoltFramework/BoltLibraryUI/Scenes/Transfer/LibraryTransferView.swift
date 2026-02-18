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
import UniformTypeIdentifiers

import BoltAppKitBridge
import BoltLocalizations
import BoltServices
import BoltUIFoundation
import BoltUtils

import Factory

private extension ErrorMessageEntity {

  static let importDocsetFailed = ErrorMessageEntity(description: "Failed to import docset")

}

@MainActor
private final class LibraryTransferViewModel: ObservableObject, LoggerProvider {

  struct ListItem: Identifiable {

    let docsetPath: String
    let docsetFileName: String

    var id: String { docsetPath }

  }

  @LazyInjected(\.libraryDocsetsManager)
  private var docsetManager: LibraryDocsetsManager

  @LazyInjected(\.localDocsetImporter)
  private var docsetImporter: LocalDocsetImporter

  @LazyInjected(\.appKitBridge)
  private var appKitBridge: AppKitBridgeProtocol?

  @Published var docsetItems = [ListItem]()

  @Published var safariSheetURL: URL?

  private lazy var folderMonitor: FolderMonitor = {
    return FolderMonitor(
      url: LocalFileSystem.applicationDocumentsURL
    ) { [weak self] in
      guard let self = self else {
        return
      }
      Task { @MainActor in
        Self.logger.debug("folder monitor received change")
        self.refresh()
      }
    }
  }()

  func startFolderMonitoring() {
    Self.logger.debug("start folder monitor at url: \(self.folderMonitor.url)")
    folderMonitor.startMonitoring()
  }

  func refresh() {
    let documentsPath = LocalFileSystem.applicationDocumentsAbsolutePath
    let pathAndFileNames = FileManager.default.contentsOfDirectory(
      atPath: documentsPath,
      ofExtension: "docset"
    )
    .map { path -> (String, String) in
      let docsetPath = documentsPath.appendingPathComponent(path)
      let fileName = URL(fileURLWithPath: path).lastPathComponent
      return (docsetPath, fileName)
    }
    .sorted { lhs, rhs in
      return lhs.1.caseInsensitiveCompare(rhs.1) == .orderedDescending
    }
    docsetItems = pathAndFileNames.map { docsetPath, fileName in
      return ListItem(docsetPath: docsetPath, docsetFileName: fileName)
    }
  }

  func showFileImporterForCatalyst() {
    let urls = appKitBridge?.showOpenPanel(
      allowedContentTypes: [.docset],
      canChooseFiles: true,
      canChooseDirectories: false,
      allowsMultipleSelection: false
    )
    if let url = urls?.first {
      handleImportedDocsetFile(url)
    }
  }

  func installDocset(forItem item: ListItem) {
    let docsetPath = item.docsetPath
    let docsetFileName = item.docsetFileName
    guard let feedEntry = FeedEntry.localFeedEntryFromDocsetFile(docsetPath) else {
      GlobalUI.presentAlertController(
        UIAlertController.alert(
          withTitle: "Library-Transfer-UnrecognizableDocsetAlert-title".boltLocalized,
          message: "Library-Transfer-UnrecognizableDocsetAlert-message".boltLocalized(docsetFileName),
          confirmAction: (
            BoltLocalizations.confirm,
            UIAlertAction.Style.default,
            { [weak self] in
              self?.removeDocset(forItem: item)
            }
          ),
          cancelAction: (UIKitLocalizations.cancel, nil)
        )
      )
      return
    }
    do {
      Self.logger.info("start installing local docset: \(docsetPath)")
      try docsetManager.installLocalDocset(forFeedEntry: feedEntry, atPath: docsetPath)
    } catch {
      Self.logger.error("failed to install local docset: \(docsetPath), error: \(error.localizedDescription)")
      showError(nestedError: error)
    }
  }

  func removeDocset(forItem item: ListItem) {
    do {
      try FileManager.default.removeItem(atPath: item.docsetPath)
    } catch {
      Self.logger.error("failed to remove local docset at path: \(item.docsetPath)")
    }
  }

  func handleImportedDocsetFile(_ url: URL) {
    do {
      try docsetImporter.importLocalDocsetFile(withURL: url)
    } catch {
      Self.logger.error("failed to import local docset file, error: \(error.localizedDescription)")
      showError(nestedError: error)
    }
  }

  func openUserGuide(_ guideLocation: UserGuideLocation) {
    if let guideURL = Container.shared.userGuideURLResolver()?(guideLocation) {
      safariSheetURL = guideURL
    }
  }

  func showError(nestedError: Error? = nil) {
    GlobalUI.showMessageToast(
      withErrorMessage: ErrorMessage(entity: ErrorMessageEntity.importDocsetFailed, nestedError: nestedError)
    )
  }

}

public struct LibraryTransferView: View {

  @Environment(\.dismissCurrentSheetModal)
  private var dismissCurrentSheetModal: DismissAction?

  @StateObject private var viewModel = LibraryTransferViewModel()

  @State private var showFileImporter = false

  public init() { }

  public var body: some View {
    Form {
      Section("Library-Transfer-SectionTitles-localDocsets".boltLocalized) {
        if !viewModel.docsetItems.isEmpty {
          ForEach(viewModel.docsetItems) { docsetItem in
            Button {
              viewModel.installDocset(forItem: docsetItem)
            } label: {
              LibraryFeedListItemView(
                image: PlatformImage(
                  systemName: "books.vertical",
                  withConfiguration: PlatformImage.SymbolConfiguration(
                    pointSize: 16
                  )
                ),
                title: docsetItem.docsetFileName,
                lineLimit: 1
              )
            }
            .tint(Color.primary)
            .swipeActions {
              Button(UIKitLocalizations.delete) {
                viewModel.removeDocset(forItem: docsetItem)
              }
              .tint(.red)
            }
          }
        } else {
          Text("Library-Transfer-LocalDocsetsSection-noDocsetHint".boltLocalized)
            .foregroundStyle(.secondary)
        }
      }
      Section("Library-Transfer-SectionTitles-importNewDocsets".boltLocalized) {
        Button {
          #if targetEnvironment(macCatalyst)
          viewModel.showFileImporterForCatalyst()
          #else
          showFileImporter = true
          #endif
        } label: {
          Label(
            "Library-Transfer-ImportSection-importFromFiles".boltLocalized,
            systemImage: "folder"
          )
        }
        #if !targetEnvironment(macCatalyst)
        Button {
          let guideLocation = UserGuideLocation(
            path: "transferring-local-docsets",
            fragment: "transfer-docsets-from-finder"
          )
          viewModel.openUserGuide(guideLocation)
        } label: {
          Label(
            "Library-Transfer-ImportSection-transferFromMac".boltLocalized,
            systemImage: "arrow.forward.folder"
          )
        }
        #endif
      }
    }
    .formStyle(.grouped)
    .navigationTitle("Library-Transfer-title".boltLocalized)
    .navigationBarTitleDisplayMode(.inline)
    .safariSheet(url: $viewModel.safariSheetURL)
    .onAppear {
      viewModel.refresh()
      viewModel.startFolderMonitoring()
    }
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button(action: {
          let guideLocation = UserGuideLocation(path: "transferring-local-docsets")
          viewModel.openUserGuide(guideLocation)
        }, label: {
          Label(
            "Library-FeedList-ToolBar-guideButtonTitle".boltLocalized,
            systemImage: "questionmark.circle"
          )
        })
        .labelStyle(.iconOnly)
      }
      if #available (iOS 26.0, *) {
        ToolbarSpacer(.fixed, placement: .topBarTrailing)
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
    #if !targetEnvironment(macCatalyst)
    .fileImporter(
      isPresented: $showFileImporter,
      allowedContentTypes: [UTType.docset],
      allowsMultipleSelection: false
    ) { result in
      switch result {
      case let .success(urls):
        guard let url = urls.first else {
          return
        }
        viewModel.handleImportedDocsetFile(url)
      case let .failure(error):
        viewModel.showError(nestedError: error)
      }
    }
    #endif
  }

}
