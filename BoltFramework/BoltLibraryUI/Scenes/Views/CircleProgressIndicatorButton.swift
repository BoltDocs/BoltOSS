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

public struct CircleProgressIndicatorButton: View {

  var progress: CGFloat?
  var onTapAction: (() -> Void)?

  @State private var rotationDegrees: CGFloat = 0

  public var body: some View {
    Button(
      action: {
        onTapAction?()
      }, label: {
        ZStack {
          Circle()
            .strokeBorder(Color.blue, lineWidth: 1)
            .frame(width: 23, height: 23, alignment: .center)

          if let progress = progress {
            Circle()
              .trim(from: 0, to: min(progress, 1))
              .rotation(.degrees(-90))
              .stroke(
                Color.blue,
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
              )
              .frame(width: 20, height: 20)
          } else {
            Circle()
              .trim(from: 0, to: 0.825)
              .rotation(.degrees(rotationDegrees))
              .stroke(
                Color.blue,
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
              )
              .frame(width: 20, height: 20)
              .onAppear {
                withAnimation(
                  .linear(duration: 1.5)
                  .repeatForever(autoreverses: false)
                ) {
                  rotationDegrees = 360.0
                }
              }
          }

          Rectangle()
            .fill(Color.blue)
            .cornerRadius(1)
            .frame(width: 6, height: 6, alignment: .center)
        }
        .frame(width: 24, height: 24)
      }
    )
  }

}

#if DEBUG

#Preview(traits: .fixedLayout(width: 200, height: 200)) {
  CircleProgressIndicatorButton(progress: 0)
}

#Preview(traits: .fixedLayout(width: 200, height: 200)) {
  CircleProgressIndicatorButton(progress: nil)
}

#endif
