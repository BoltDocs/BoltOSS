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

import Foundation

#if os(iOS)
import UIKit
#else
import AppKit
#endif

public extension PlatformImage {

  convenience init?(contentsOf url: URL) {
    if let data = try? Data(contentsOf: url) {
      self.init(data: data)
      return
    }
    return nil
  }

  func resized(to destSize: CGSize) -> PlatformImage {
    #if os(iOS)
    return UIGraphicsImageRenderer(size: destSize).image { _ in
      draw(in: CGRect(origin: .zero, size: destSize))
    }
    #else
    let image = NSImage(size: destSize)
    image.lockFocus()
    defer {
      image.unlockFocus()
    }
    if let ctx = NSGraphicsContext.current {
      ctx.imageInterpolation = .high
      draw(
        in: CGRect(origin: .zero, size: destSize),
        from: CGRect(origin: .zero, size: size),
        operation: .copy,
        fraction: 1
      )
    }
    return image
    #endif
  }

}
