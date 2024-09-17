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

#if DEBUG

// https://forums.developer.apple.com/forums/thread/708427

public struct PreviewContainer<Content: View>: View {

  public init(@ViewBuilder content: @escaping () -> Content) {
    self.content = content
  }

  private let content: () -> Content

  public var body: some View {
    VStack(spacing: 24) {
      content()
    }
    .previewLayout(.sizeThatFits)
  }
}

public struct PreviewCase<Content: View>: View {

  public init(
    caption: String = "Preview Case",
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.caption = caption
    self.content = content
  }

  private let caption: String
  private let content: () -> Content

  public var body: some View {
    VStack(spacing: 6) {
      content()
      Text(caption)
        .font(.system(size: 13))
    }
  }
}

#endif
