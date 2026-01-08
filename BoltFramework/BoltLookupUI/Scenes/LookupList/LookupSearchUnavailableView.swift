//
// Copyright (C) 2025 Bolt Contributors
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

import RxCombine

import BoltLocalizations
import BoltSearch
import BoltUIFoundation
import BoltUtils

public final class LookupSearchUnavailableUIView: UIView {

  private var hostingController: UIHostingController<LookupSearchUnavailableView>

  public init(searchIndex: DocsetSearchIndex) {
    hostingController = UIHostingController(
      rootView: LookupSearchUnavailableView(
        searchIndex: searchIndex
      )
    )
    super.init(frame: .zero)

    hostingController.view.frame = bounds
    hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    addSubview(hostingController.view)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}

struct LookupSearchUnavailableView: View {

  @State private var indexStatus: DocsetSearchIndex.Status = .uninitialized

  private let statusPublisher: AnyPublisher<DocsetSearchIndex.Status, Never>

  init(searchIndex: DocsetSearchIndex) {
    let statusPublisher = searchIndex.statusDriver.asPublisher()
      .ignoreFailure()
      .eraseToAnyPublisher()
    self.init(statusPublisher: statusPublisher)
  }

  fileprivate init(statusPublisher: AnyPublisher<DocsetSearchIndex.Status, Never>) {
    self.statusPublisher = statusPublisher
  }

  var body: some View {
    VStack(spacing: 12) {
      if case let .error(error) = indexStatus {
        BoltContentUnavailableView(
          configuration: BoltContentUnavailableViewConfiguration(
            image: BoltImageResource(named: "search-index-error", in: kFoundationBundle).platformImage!,
            imageSize: CGSize(width: 142, height: 142),
            message: "Search isn't available because the index couldn't be created.".boltLocalized,
            shouldDisplayIndicator: false,
            showsMessage: true,
            showsDetailButton: true,
            showsRetryButton: false
          ),
          // swiftlint:disable:next trailing_closure
          detailAction: {
            GlobalUI.presentAlertController(
              UIAlertController.alert(
                withTitle: "Failed to Create Search Index",
                message: error.localizedDescription,
                confirmAction: (UIKitLocalizations.ok, .default, nil)
              )
            )
          }
        )
      } else {
        BoltContentUnavailableView(
          configuration: BoltContentUnavailableViewConfiguration(
            image: BoltImageResource(named: "search-index", in: kFoundationBundle).platformImage!,
            imageSize: CGSize(width: 142, height: 142),
            message: "Search will be available after indexing complete.".boltLocalized,
            shouldDisplayIndicator: false,
            showsMessage: true,
            showsDetailButton: false,
            showsRetryButton: false
          )
        )
        if case .indexing(let progress) = indexStatus {
          if let progress = progress {
            ProgressView(value: progress)
              .progressViewStyle(.linear)
              .frame(width: 240)
          } else {
            HStack {
              ProgressView()
                .progressViewStyle(.circular)
              Text("Waiting for other docsets to finish indexing…")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }
        }
      }
    }
    .onReceive(statusPublisher) { status in
      indexStatus = status
    }
  }

}

#if DEBUG

#Preview(traits: .sizeThatFitsLayout) {

  struct StubbedError: Error { }

  let statuses: [(String, DocsetSearchIndex.Status)] = [
    (".uninitialized", .uninitialized),
    (".indexingWithNilProgress", .indexing(progress: nil)),
    (".indexing", .indexing(progress: 0.5)),
    (".ready", .ready),
    (".error", .error(SearchServiceError(underlyingError: StubbedError()))),
  ]

  return PreviewContainer {
    ForEach(statuses.indices, id: \.self) { index in
      PreviewCase(caption: statuses[index].0) {
        LookupSearchUnavailableView(
          statusPublisher: Just(statuses[index].1).eraseToAnyPublisher()
        )
      }
      .frame(width: 480)
    }
    .padding()
  }

}

#endif
