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
import BoltUIFoundation
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
    setupPublishers(progressPublisher: progressPublisher)
  }

  init(
    identifier: String,
    progressPublisher: AnyPublisher<DownloadProgress?, Never>
  ) {
    self.identifier = identifier
    setupPublishers(progressPublisher: progressPublisher)
  }

  private func setupPublishers(progressPublisher: AnyPublisher<DownloadProgress?, Never>) {
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
    let model = DownloadProgressListItemViewModel(identifier: identifier)
    self.init(
      model: model,
      title: title,
      subtitle: subtitle,
      preventsHighlight: preventsHighlight
    )
  }

  fileprivate init(
    model: DownloadProgressListItemViewModel,
    title: String,
    subtitle: String? = nil,
    preventsHighlight: Bool = false
  ) {
    self.model = model
    self.title = title
    self.subtitle = subtitle
    self.preventsHighlight = preventsHighlight
  }

  public var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
        switch model.progress {
        case .pending:
          ProgressView()
            .progressViewStyle(.linear)
        case let .downloading(receivedBytes, expectedBytes):
          ProgressView(value: calculateProgress(receivedBytes: receivedBytes, expectedBytes: expectedBytes))
            .progressViewStyle(.linear)
        default:
          EmptyView()
        }
        if let subtitle = (model.progressSubtitle ?? subtitle) {
          Text(subtitle)
            .foregroundColor(.secondary)
            .font(.system(.caption))
        }
      }
      Spacer()
      switch model.progress {
      case .completed:
        Image(systemName: "checkmark.circle")
      case .failed:
        Image(systemName: "exclamationmark.triangle")
      default:
        EmptyView()
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

#if DEBUG

#Preview {

  struct StubbedError: Error { }

  let progresses: [(String, DownloadProgress?)] = [
    (".none", .none),
    (".pending", .pending),
    (".downloading", .downloading(receivedBytes: 1024, expectedBytes: 10240)),
    (".completed", .completed),
    (".failed", .failed(StubbedError())),
  ]

  return PreviewContainer {
    ForEach(progresses.indices, id: \.self) { index in
      PreviewCase(caption: progresses[index].0) {
        DownloadProgressListItemView(
          model: DownloadProgressListItemViewModel(
            identifier: "",
            progressPublisher: Just<DownloadProgress?>(progresses[index].1)
              .eraseToAnyPublisher()
          ),
          title: "Download Title"
        )
        .frame(width: 480)
      }
    }
  }

}

#endif
