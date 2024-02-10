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

import BoltServices
import BoltUtils

private class DownloadProgressListItemViewModel: ObservableObject {

  @Injected(\.downloadManager)
  private var downloadManager: DownloadManager

  @Published var progress: DownloadProgress?
  @Published var progressSubtitle: String?

  private var identifier: String

  init(identifier: String) {
    self.identifier = identifier

    let progressPublisher = downloadManager.progress(forIdentifier: identifier)

    progressPublisher
      .map {  progress -> String? in
        switch progress {
        case .none:
          return nil
        case .pending:
          return "Waiting..."
        case let .downloading(receivedBytes, expectedBytes):
          return Self.formatDownloading(receivedBytes: receivedBytes, expectedBytes: expectedBytes)
        case .completed:
          return "Downloaded"
        case .failed:
          return "Download Fail"
        }
      }
      .assign(to: &$progressSubtitle)

    progressPublisher
      .assign(to: &$progress)
  }

  func cancelButtonTap() {
    Task {
      await downloadManager.cancelDownload(forIdentifier: identifier)
    }
  }

  private static func formatDownloading(receivedBytes: Int64, expectedBytes: Int64) -> String {
    if expectedBytes >= 0 {
      let percentage = Double(receivedBytes) / Double(expectedBytes) * 100
      let str = "\(String.formatBytes(bytes: Double(receivedBytes))) / \(String.formatBytes(bytes: Double(expectedBytes))) (\(String(format: "%.1f", percentage))%)"
      return str
    } else {
      return "\(String.formatBytes(bytes: Double(receivedBytes))) downloaded"
    }
  }

}

public struct DownloadProgressListItemView: View {

  var title: String
  var subtitle: String?

  private var preventsHighlight: Bool

  @ObservedObject private var model: DownloadProgressListItemViewModel

  init(identifier: String, title: String, subtitle: String? = nil, preventsHighlight: Bool = false) {
    self.model = DownloadProgressListItemViewModel(identifier: identifier)
    self.title = title
    self.subtitle = subtitle
    self.preventsHighlight = preventsHighlight
  }

  public var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
        if let subtitle = (model.progressSubtitle ?? subtitle) {
          Text(subtitle)
            .foregroundColor(.secondary)
            .font(.system(.caption))
        }
      }
      Spacer()
      switch model.progress {
      case .none:
        EmptyView()
      case .pending:
        ProgressView()
          .progressViewStyle(.circular)
      case let .downloading(receivedBytes, expectedBytes):
        CircleProgressIndicatorButton(
          progress: calculateProgress(receivedBytes: receivedBytes, expectedBytes: expectedBytes)
        ) {
          model.cancelButtonTap()
        }
      case .completed:
        Image(systemName: "checkmark.circle")
      case .failed:
        Image(systemName: "exclamationmark.triangle")
      }
    }
    .if(preventsHighlight) {
      $0.buttonStyle(.borderless)
    }
  }

  @inline(__always)
  private func calculateProgress(receivedBytes: Int64, expectedBytes: Int64) -> CGFloat? {
    if receivedBytes >= 0, expectedBytes >= 0 {
      return (CGFloat)(receivedBytes) / (CGFloat)(expectedBytes)
    }
    return nil
  }

}
