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

public struct ListItemLabelStyle: LabelStyle {

  private var iconSize: CGSize?
  private var spacing: CGFloat

  public init(spacing: CGFloat = 8, iconSize: CGSize? = nil) {
    self.iconSize = iconSize
    self.spacing = spacing
  }

  public func makeBody(configuration: Configuration) -> some View {
    HStack(alignment: .center, spacing: spacing) {
      configuration.icon
        .foregroundColor(Color.primary)
        .if(iconSize != nil) {
          $0.frame(width: iconSize!.width, height: iconSize!.height)
        }
      configuration.title
        .lineLimit(1)
        .truncationMode(.middle)
    }
  }

}
