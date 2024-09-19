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

import Combine
import SwiftUI

import Factory

import BoltDatabase
import BoltServices
import BoltUIFoundation
import BoltUtils

private class CompletedDownloadListItemViewModel: ObservableObject {

  @Injected(\.downloadManager)
  private var downloadManager: DownloadManager

  enum ActionButton {
    case delete
    case remove
    case more
  }

  let subtitle: String?
  var actionButtons = [ActionButton]()

  let taskEntity: DownloadTaskEntity
  private let localTarPath: String

  init(taskEntity: DownloadTaskEntity) {
    self.taskEntity = taskEntity

    self.localTarPath = FeedEntry.downloadAbsolutePath(forId: taskEntity.identifier, withExtension: "tgz")

    if FileManager.default.fileExists(atPath: localTarPath),
      let attributes = try? FileManager.default.attributesOfItem(atPath: localTarPath),
      let byteSize = attributes[.size] as? Int64,
      byteSize > 0
    {
      subtitle = String.formatBytes(bytes: Double(byteSize))
      actionButtons.append(contentsOf: [.delete, .more])
    } else {
      subtitle = "Removed"
      actionButtons.append(.remove)
    }
  }

  func deleteButtonTap() {
    try? FileManager.default.removeItem(atPath: localTarPath)
    downloadManager.removeTask(forIdentifier: taskEntity.identifier)
  }

  func removeButtonTap() {
    downloadManager.removeTask(forIdentifier: taskEntity.identifier)
  }

}

public struct CompletedDownloadListItemView: View {

  private let title: String
  private let subtitle: String?

  private var preventsHighlight: Bool

  @ObservedObject private var model: CompletedDownloadListItemViewModel

  init(taskEntity: DownloadTaskEntity, title: String, subtitle: String? = nil, preventsHighlight: Bool = false) {
    self.model = CompletedDownloadListItemViewModel(taskEntity: taskEntity)
    self.title = title
    self.subtitle = subtitle
    self.preventsHighlight = preventsHighlight
  }

  public var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
        if let subtitle = (model.subtitle ?? subtitle) {
          Text(subtitle)
            .foregroundColor(.secondary)
            .font(.system(.caption))
        }
      }
      Spacer()
      HStack(spacing: 8) {
        ForEach(model.actionButtons, id: \.self) { button in
          switch button {
          case .delete:
            Button {
              model.deleteButtonTap()
            } label: {
              Image(systemName: "trash")
            }
          case .remove:
            Button {
              model.removeButtonTap()
            } label: {
              Image(systemName: "xmark")
            }
          case .more:
            // https://stackoverflow.com/questions/66231181/hide-chevron-arrow-on-navigationlink-when-displaying-a-view-swiftui
            Button { } label: {
              Image(systemName: "ellipsis")
            }
            .overlay {
              NavigationLink(
                destination: { DeferredView { LibraryDownloadsFeedInfoView(taskEntity: model.taskEntity) } },
                label: { EmptyView() }
              )
              .opacity(0)
            }
          }
        }
      }
    }
    .if(preventsHighlight) {
      $0.buttonStyle(.borderless)
    }
  }

}
