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

import BoltUIFoundation

struct EmptyFeedsView: View {

  private(set) var image: UIImage
  private(set) var message: String
  private(set) var shouldDisplayIndicator: Bool
  private(set) var showsMessage: Bool
  private(set) var showsRetry: Bool

  private(set) var retryAction: (() -> Void)?

  var body: some View {
    VStack(alignment: .center, spacing: 16) {
      Image(uiImage: image)
        .resizable()
        .aspectRatio(1, contentMode: .fit)
        .frame(width: 142, height: 142, alignment: .center)
        .foregroundColor(Color("overlay", bundle: kFoundationBundle))
      if showsMessage {
        HStack(spacing: 8) {
          Text(message)
            .foregroundColor(.secondary)
          if shouldDisplayIndicator {
            ProgressView()
              .progressViewStyle(.circular)
          }
        } // HStack
      }
      if showsRetry {
        Button(action: {
          retryAction?()
        }, label: {
          Text("Retry")
        }) // Button
      }
    } // VStack
  }

}
