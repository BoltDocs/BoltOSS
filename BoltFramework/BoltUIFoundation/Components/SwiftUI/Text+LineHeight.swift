//
// Copyright (C) 2026 Bolt Contributors
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

struct LineHeightModifier: ViewModifier {

  var factor: CGFloat
  var fontSize: CGFloat

  func body(content: Content) -> some View {
    let uiFont = UIFont.systemFont(ofSize: fontSize)
    let lineSpacing = (factor - 1) * uiFont.lineHeight
    content
      .font(.system(size: fontSize))
      .lineSpacing(lineSpacing)
      .padding(.vertical, (lineSpacing / 2))
  }

}

public extension View {

  func bolt_lineHeight(factor: CGFloat, systemFontSize fontSize: CGFloat) -> some View {
    modifier(LineHeightModifier(factor: factor, fontSize: fontSize))
  }

}
