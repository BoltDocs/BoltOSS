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

public struct BoltContentUnavailableViewConfiguration {

  public var image: UIImage
  public var imageSize: CGSize?
  public var message: String
  public var shouldDisplayIndicator: Bool
  public var showsMessage: Bool
  public var showsDetailButton: Bool
  public var showsRetryButton: Bool

  public init(
    image: UIImage,
    imageSize: CGSize? = nil,
    message: String,
    shouldDisplayIndicator: Bool,
    showsMessage: Bool,
    showsDetailButton: Bool,
    showsRetryButton: Bool
  ) {
    self.image = image
    self.imageSize = imageSize
    self.message = message
    self.shouldDisplayIndicator = shouldDisplayIndicator
    self.showsMessage = showsMessage
    self.showsDetailButton = showsDetailButton
    self.showsRetryButton = showsRetryButton
  }

}

public struct BoltContentUnavailableView: View {

  public var configuration: BoltContentUnavailableViewConfiguration

  public private(set) var detailAction: (() -> Void)?
  public private(set) var retryAction: (() -> Void)?

  public init(
    configuration: BoltContentUnavailableViewConfiguration,
    detailAction: (() -> Void)? = nil,
    retryAction: (() -> Void)? = nil
  ) {
    self.configuration = configuration
    self.detailAction = detailAction
    self.retryAction = retryAction
  }

  public var body: some View {
    VStack(alignment: .center, spacing: 16) {
      Image(uiImage: configuration.image)
        .if(configuration.imageSize != nil) {
          $0.resizable()
            .aspectRatio(1, contentMode: .fit)
            .frame(
              width: configuration.imageSize!.width,
              height: configuration.imageSize!.height
            )
        }
        .foregroundColor(Color("overlay", bundle: kFoundationBundle))
      if configuration.showsMessage {
        HStack(spacing: 8) {
          Text(configuration.message)
            .foregroundColor(.secondary)
          if let detailAction = detailAction, configuration.showsDetailButton {
            Button {
              detailAction()
            } label: {
              Image(systemName: "info.circle")
                .foregroundColor(.secondary)
            }
          }
          if configuration.shouldDisplayIndicator {
            ProgressView()
              .progressViewStyle(.circular)
          }
        } // HStack
      }
      if let retryAction = retryAction, configuration.showsRetryButton {
        Button {
          retryAction()
        } label: {
          Text("Retry")
        } // Button
      }
    } // VStack
  }

}

@available(iOS 17.0, *)
#Preview(traits: .fixedLayout(width: 300, height: 300)) {

  BoltContentUnavailableView(
    configuration: BoltContentUnavailableViewConfiguration(
      image: UIImage(systemName: "exclamationmark.triangle")!,
      message: "An error occurred",
      shouldDisplayIndicator: true,
      showsMessage: true,
      showsDetailButton: true,
      showsRetryButton: true
    ),
    detailAction: { },
    retryAction: { }
  )

}
