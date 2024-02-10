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

import UIKit

public extension UIImage {

  func roundedCorner(
    withSize destSize: CGSize,
    contentSize: CGSize,
    backgroundColor: UIColor,
    cornerRadius: CGFloat,
    borderWidth: CGFloat = 0,
    borderColor: UIColor = .clear
  ) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(destSize, false, 0)

    defer {
      UIGraphicsEndImageContext()
    }

    let rect = CGRect(
      x: borderWidth / 2,
      y: borderWidth / 2,
      width: destSize.width - borderWidth,
      height: destSize.height - borderWidth
    )

    let bezierPath = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)

    backgroundColor.setFill()
    bezierPath.fill()

    let imageRect = CGRect(
      origin: CGPoint(
        x: (destSize.width - contentSize.width) / 2,
        y: (destSize.height - contentSize.height) / 2
      ),
      size: contentSize
    )
    draw(in: imageRect)

    bezierPath.lineWidth = borderWidth
    borderColor.setStroke()
    bezierPath.stroke()

    let res = UIGraphicsGetImageFromCurrentImageContext()
    return res
  }

}
