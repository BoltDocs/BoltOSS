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

import Combine
import SwiftUI

import Factory

import BoltDatabase
import BoltServices
import BoltTypes
import BoltUtils

@MainActor
private class LibraryDownloadDetailViewModel: ObservableObject {

  @Injected(\.downloadManager)
  private var downloadManager: DownloadManager

  @Published var feedEntry: FeedEntry?

  let taskEntity: DownloadTaskEntity

  init(taskEntity: DownloadTaskEntity) {
    self.taskEntity = taskEntity
  }

  func fetchFeedEntry() async {
    feedEntry = try? await downloadManager.feedEntry(forDownloadTaskEntity: taskEntity)
  }

}

public struct LibraryDownloadDetailView: View {

  @ObservedObject private var model: LibraryDownloadDetailViewModel

  init(taskEntity: DownloadTaskEntity) {
    self.model = LibraryDownloadDetailViewModel(taskEntity: taskEntity)
  }

  public var body: some View {
    Group {
      if let feedEntry = model.feedEntry {
        DownloadConfirmationView(feedEntry: feedEntry)
      } else {
        Group {
          ProgressView()
            .progressViewStyle(.circular)
        }
        .navigationTitle(model.taskEntity.displayName)
        .navigationBarTitleDisplayMode(.inline)
      }
    }
    .onAppear {
      Task {
        await model.fetchFeedEntry()
      }
    }
  }

}
