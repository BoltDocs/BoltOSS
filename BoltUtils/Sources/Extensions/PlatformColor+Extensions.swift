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

import Foundation

public extension PlatformColor {

  convenience init?(hexString: String, alpha: CGFloat = 1.0) {
    // Convert hex string to an integer
    guard let hexInt = uInt32(fromHexString: hexString) else {
      return nil
    }

    let red = CGFloat((hexInt & 0xff0000) >> 16) / 255.0
    let green = CGFloat((hexInt & 0xff00) >> 8) / 255.0
    let blue = CGFloat((hexInt & 0xff) >> 0) / 255.0

    // Create the color object, specifying alpha as well
    self.init(red: red, green: green, blue: blue, alpha: alpha)
  }

}

private func uInt32(fromHexString hexStr: String) -> UInt32? {
  var hexInt: UInt64 = 0
  // Create the scanner
  let scanner = Scanner(string: hexStr)
  // Tell scanner to skip the # character
  scanner.charactersToBeSkipped = CharacterSet(charactersIn: "#")
  // Scan for hex value
  if scanner.scanHexInt64(&hexInt) {
    return UInt32(hexInt)
  } else {
    return nil
  }
}
