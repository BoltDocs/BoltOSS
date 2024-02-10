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

import Factory

import BoltDatabase
import BoltServices
import BoltUIFoundation
import BoltUtils

private class LibraryDownloadsListViewModel: ObservableObject {

  @Injected(\.downloadManager)
  private var downloadManager: DownloadManager

  @Published var items = [Item]()

  struct Item: Identifiable {
    let title: String
    let taskEntity: DownloadTaskEntity
    let isCompleted: Bool
    var id: String {
      return taskEntity.identifier
    }
  }

  init() {
    downloadManager.allTasks()
      .map { tasks in
        return tasks.map { task in
          let completed = !task.isDownloading

          let title: String
          if task.installedAsLatestVersion {
            title = "\(task.displayName) (Latest)"
          } else {
            title = "\(task.displayName) (\(task.version))"
          }

          return Item(
            title: title,
            taskEntity: task,
            isCompleted: completed
          )
        }
      }
      .assign(to: &$items)
  }

}

struct LibraryDownloadsListView: View {

  enum Scope: Int {
    case all
    case completed
  }

  @State var currentScope: Scope = .all

  @ObservedObject private var model = LibraryDownloadsListViewModel()

  static let emptyStateImage: UIImage = BoltImageResource(named: "overview-icons/downloads", in: .module).platformImage!

  var body: some View {
    VStack {
      Picker("", selection: $currentScope) {
        Text("All").tag(Scope.all)
        Text("Completed").tag(Scope.completed)
      }
      .padding([.leading, .trailing], 8)
      .pickerStyle(.segmented)

      Group {
        if !model.items.isEmpty {
          List {
            ForEach(model.items, id: \.id) { item in
              if currentScope == .all || (currentScope == .completed && item.isCompleted) {
                if item.isCompleted {
                  CompletedDownloadListItemView(
                    taskEntity: item.taskEntity,
                    title: item.title,
                    preventsHighlight: true
                  )
                  .listRowBackground(Color.clear)
                } else {
                  DownloadProgressListItemView(
                    identifier: item.taskEntity.identifier,
                    title: item.title,
                    preventsHighlight: true
                  )
                  .listRowBackground(Color.clear)
                } // if
              } // if
            } // ForEach
          } // List
          .listStyle(.plain)
        } else {
          EmptyFeedsView(
            image: Self.emptyStateImage,
            message: "No Downloads",
            shouldDisplayIndicator: false,
            showsMessage: true,
            showsRetry: false
          )
        } // if
      } // Group
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .background(Color.systemGroupedBackground)
    .navigationTitle("Downloads")
    .navigationBarTitleDisplayMode(.inline)
  }

}
