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

struct LibraryFeedListItemView<Trailing: View>: View {

  var image: UIImage?
  var title: String
  var lineLimit: Int?

  @ViewBuilder var trailing: () -> Trailing

  var body: some View {
    HStack {
      Label {
        Text(title)
          .bolt_lineHeight(
            factor: 1,
            systemFontSize: UIFont.labelFontSize
          )
      } icon: {
        Image(uiImage: image ?? UIImage())
          .if(image?.isSymbolImage ?? false) {
            $0.renderingMode(.template)
          }
      }
      .labelStyle(
        ListItemLabelStyle(
          spacing: 8,
          iconSize: CGSize(width: 30, height: 30),
          lineLimit: lineLimit
        )
      )
      Spacer()
      trailing()
    }
  }

}

extension LibraryFeedListItemView where Trailing == EmptyView {

  init(image: UIImage?, title: String, lineLimit: Int? = nil) {
    self.init(image: image, title: title, lineLimit: lineLimit, trailing: { EmptyView() })
  }

}
